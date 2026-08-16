// Package bus is the LifeOS nervous system: every domain publishes facts
// ("movies:watched", "location:enter"), subscribers react. Modules never
// import each other — they only know the bus (hub-and-spoke, Apple/Google
// style, not mesh). In-memory and stateless by design: modules persist their
// own data; the bus only routes.
//
// Fast by construction: topics in a map, handlers out, no serialization, no
// reflection, no network. One event ≈ a few microseconds.
package bus

import (
	"log"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"
)

// Event is a fact the ecosystem knows: something happened in some domain.
// Payload is a typed struct — JSON exists only at the HTTP/WS boundary.
type Event struct {
	ID      string // monotonic, for WS-relay dedup
	At      time.Time
	Topic   string // "domain:action", e.g. "movies:watched"
	UserID  string
	Payload any
}

type Handler func(Event)

// ErrorHandler is called when a subscriber panics — never let one module kill
// the daemon. Logged by default; override for telemetry.
var ErrorHandler = func(topic string, err any) {
	log.Printf("[bus] panic in subscriber for %s: %v", topic, err)
}

type Bus struct {
	mu      sync.RWMutex
	subs    map[string][]Handler // pattern -> handlers
	queue   chan Event
	once    sync.Once // workers start lazily on first Publish
	seq     atomic.Uint64
	pub     atomic.Uint64
	handled atomic.Uint64
}

var Default = New()

func New() *Bus {
	return &Bus{subs: make(map[string][]Handler), queue: make(chan Event, 1024)}
}

// Subscribe registers a handler for a pattern: exact ("movies:watched"),
// domain wildcard ("movies:*"), action wildcard ("*:watched"), all ("*:*").
func (b *Bus) Subscribe(pattern string, h Handler) {
	b.mu.Lock()
	b.subs[pattern] = append(b.subs[pattern], h)
	b.mu.Unlock()
}

// Subscribe wraps the default bus.
func Subscribe(pattern string, h Handler) { Default.Subscribe(pattern, h) }

// Publish enqueues the event for async fan-out (publisher never blocks on a
// slow subscriber). On queue saturation it dispatches inline in the caller
// instead of dropping — backpressure without loss.
func (b *Bus) Publish(e Event) {
	b.once.Do(b.start)
	e.ID = strconv.FormatUint(b.seq.Add(1), 10)
	if e.At.IsZero() {
		e.At = time.Now()
	}
	b.pub.Add(1)
	select {
	case b.queue <- e:
	default:
		b.dispatch(e)
	}
}

// Publish wraps the default bus.
func Publish(e Event) { Default.Publish(e) }

func (b *Bus) start() {
	n := runtime.NumCPU()
	if n > 4 {
		n = 4
	}
	for i := 0; i < n; i++ {
		go func() {
			for e := range b.queue {
				b.dispatch(e)
			}
		}()
	}
}

func (b *Bus) dispatch(e Event) {
	b.mu.RLock()
	var hs []Handler
	for pattern, handlers := range b.subs {
		if match(pattern, e.Topic) {
			hs = append(hs, handlers...)
		}
	}
	b.mu.RUnlock()
	for _, h := range hs {
		b.handled.Add(1)
		func() {
			defer func() {
				if err := recover(); err != nil {
					ErrorHandler(e.Topic, err)
				}
			}()
			h(e)
		}()
	}
}

// match supports two-segment topics with per-segment wildcards.
func match(pattern, topic string) bool {
	if pattern == topic {
		return true
	}
	ps, ts := strings.SplitN(pattern, ":", 2), strings.SplitN(topic, ":", 2)
	if len(ps) != 2 || len(ts) != 2 {
		return false
	}
	return (ps[0] == "*" || ps[0] == ts[0]) && (ps[1] == "*" || ps[1] == ts[1])
}

type Stats struct {
	Published uint64
	Handled   uint64
	Listeners int
}

func (b *Bus) Stats() Stats {
	b.mu.RLock()
	defer b.mu.RUnlock()
	n := 0
	for _, hs := range b.subs {
		n += len(hs)
	}
	return Stats{Published: b.pub.Load(), Handled: b.handled.Load(), Listeners: n}
}