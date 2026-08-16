package bus

import (
	"runtime"
	"sync/atomic"
	"testing"
	"time"
)

func waitFor(t *testing.T, want int64, got *atomic.Int64) {
	t.Helper()
	deadline := time.Now().Add(2 * time.Second)
	for got.Load() < want && time.Now().Before(deadline) {
		time.Sleep(time.Millisecond)
	}
	if got.Load() != want {
		t.Fatalf("expected %d handler calls, got %d", want, got.Load())
	}
}

func TestFanOutPatterns(t *testing.T) {
	b := New()
	var got atomic.Int64
	b.Subscribe("movies:*", func(Event) { got.Add(1) })
	b.Subscribe("*:watched", func(Event) { got.Add(1) })
	b.Subscribe("*:*", func(e Event) {
		if e.Topic != "movies:watched" || e.UserID != "kid1" {
			t.Errorf("bad event: %+v", e)
		}
		got.Add(1)
	})
	b.Subscribe("books:progress", func(Event) { t.Error("wrong wildcard match") })

	b.Publish(Event{Topic: "movies:watched", UserID: "kid1", Payload: 150})
	waitFor(t, 3, &got) // movies:*, *:watched, *:* — books:progress must not fire
}

func TestPanicIsolation(t *testing.T) {
	b := New()
	var got atomic.Int64
	b.Subscribe("a:b", func(Event) { panic("boom") })
	b.Subscribe("a:b", func(Event) { got.Add(1) })
	b.Publish(Event{Topic: "a:b"})
	waitFor(t, 1, &got) // the panicking handler must not stop the second one
}

func TestSaturationFallsBackInline(t *testing.T) {
	b := New()
	n := runtime.NumCPU()
	if n > 4 {
		n = 4
	}
	var got, wedged atomic.Int64
	b.Subscribe("a:b", func(Event) { got.Add(1) })
	block := make(chan struct{})
	b.Subscribe("x:y", func(Event) { wedged.Add(1); <-block })
	for i := 0; i < n; i++ { // wedge every worker
		b.Publish(Event{Topic: "x:y"})
	}
	deadline := time.Now().Add(2 * time.Second)
	for wedged.Load() < int64(n) && time.Now().Before(deadline) {
		time.Sleep(time.Millisecond)
	}
	if wedged.Load() != int64(n) {
		t.Fatalf("expected %d wedged workers, got %d", n, wedged.Load())
	}
	for i := 0; i < cap(b.queue); i++ { // fill the queue
		b.Publish(Event{Topic: "a:b"})
	}
	// Queue is now saturated and all workers blocked → inline dispatch is
	// the only path; it must complete synchronously.
	b.Publish(Event{Topic: "a:b"})
	if got.Load() != 1 {
		t.Fatalf("expected inline dispatch, got %d", got.Load())
	}
	close(block) // let the queued events drain so the test exits cleanly
}