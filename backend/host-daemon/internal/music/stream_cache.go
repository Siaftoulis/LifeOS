package music

import (
	"container/list"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"sync"
	"time"
)

// StreamCacheItem holds direct audio stream URL and playback metadata.
type StreamCacheItem struct {
	URL        string    `json:"url"`
	StreamType string    `json:"stream_type"`
	Bitrate    int       `json:"bitrate"`
	Itag       int       `json:"itag"`
	ExpiresAt  time.Time `json:"expires_at"`
}

func (s StreamCacheItem) IsExpired() bool {
	return time.Now().After(s.ExpiresAt)
}

// StreamCache implements an in-memory thread-safe LRU cache for audio streams.
type StreamCache struct {
	mu       sync.RWMutex
	capacity int
	items    map[string]*list.Element
	evictList *list.List
}

type lruEntry struct {
	key   string
	value StreamCacheItem
}

func NewStreamCache(capacity int) *StreamCache {
	if capacity <= 0 {
		capacity = 500
	}
	return &StreamCache{
		capacity:  capacity,
		items:     make(map[string]*list.Element),
		evictList: list.New(),
	}
}

var GlobalStreamCache = NewStreamCache(500)

func (c *StreamCache) Get(videoID string) (StreamCacheItem, bool) {
	c.mu.Lock()
	defer c.mu.Unlock()

	elem, exists := c.items[videoID]
	if !exists {
		return StreamCacheItem{}, false
	}

	entry := elem.Value.(*lruEntry)
	if entry.value.IsExpired() {
		c.evictList.Remove(elem)
		delete(c.items, videoID)
		return StreamCacheItem{}, false
	}

	c.evictList.MoveToFront(elem)
	return entry.value, true
}

func (c *StreamCache) Set(videoID string, item StreamCacheItem) {
	c.mu.Lock()
	defer c.mu.Unlock()

	if elem, exists := c.items[videoID]; exists {
		c.evictList.MoveToFront(elem)
		entry := elem.Value.(*lruEntry)
		entry.value = item
		return
	}

	if c.evictList.Len() >= c.capacity {
		oldest := c.evictList.Back()
		if oldest != nil {
			c.evictList.Remove(oldest)
			kv := oldest.Value.(*lruEntry)
			delete(c.items, kv.key)
		}
	}

	entry := &lruEntry{key: videoID, value: item}
	elem := c.evictList.PushFront(entry)
	c.items[videoID] = elem
}

const bridgePort = "18785"
const bridgeURL = "http://127.0.0.1:" + bridgePort

var (
	bridgeLaunchMu sync.Mutex
	bridgeCmd      *exec.Cmd
)

func isBridgeAlive() bool {
	client := &http.Client{Timeout: 600 * time.Millisecond}
	resp, err := client.Get(bridgeURL + "/health")
	if err != nil {
		return false
	}
	defer resp.Body.Close()
	return resp.StatusCode == http.StatusOK
}

// ensureNewPipeBridge verifies that the in-memory JVM bridge is listening on port 18785.
func ensureNewPipeBridge() error {
	if isBridgeAlive() {
		return nil
	}
	bridgeLaunchMu.Lock()
	defer bridgeLaunchMu.Unlock()
	if isBridgeAlive() {
		return nil
	}

	jarPath := os.Getenv("NEWPIPE_BRIDGE_JAR")
	if jarPath == "" {
		candidates := []string{
			"backend/newpipe-bridge/build/libs/newpipe-bridge.jar",
			"../newpipe-bridge/build/libs/newpipe-bridge.jar",
			"newpipe-bridge.jar",
		}
		for _, c := range candidates {
			if _, err := os.Stat(c); err == nil {
				jarPath = c
				break
			}
		}
	}

	if jarPath == "" {
		return fmt.Errorf("newpipe-bridge jar not found; set NEWPIPE_BRIDGE_JAR")
	}

	javaBin := "java"
	for _, candidate := range []string{"/usr/lib/jvm/java-17-openjdk-amd64/bin/java", "/usr/bin/java", "java"} {
		if _, err := os.Stat(candidate); err == nil {
			javaBin = candidate
			break
		}
	}

	log.Printf("music: starting in-memory newpipe-bridge: %s -jar %s --port %s", javaBin, jarPath, bridgePort)
	cmd := exec.Command(javaBin, "-jar", jarPath, "--port", bridgePort)
	if err := cmd.Start(); err != nil {
		return fmt.Errorf("spawn newpipe-bridge failed: %w", err)
	}
	bridgeCmd = cmd

	for i := 0; i < 35; i++ {
		time.Sleep(150 * time.Millisecond)
		if isBridgeAlive() {
			log.Printf("music: newpipe-bridge is online on port %s", bridgePort)
			return nil
		}
	}

	return fmt.Errorf("newpipe-bridge did not report healthy within 5s")
}

type bridgeStreamsResponse struct {
	ID           string `json:"id"`
	Title        string `json:"title"`
	AudioURL     string `json:"audio_url"`
	AudioCodec   string `json:"audio_codec"`
	AudioBitrate int    `json:"audio_bitrate"`
	AudioItag    int    `json:"audio_itag"`
	MP4          string `json:"mp4"`
}

// ResolveAudioStream resolves the direct signed streaming URL without any CLI subprocesses,
// utilizing the in-memory LRU cache and the in-memory bridge.
func ResolveAudioStream(ctx context.Context, videoID string) (StreamCacheItem, error) {
	if cached, ok := GlobalStreamCache.Get(videoID); ok {
		return cached, nil
	}

	if err := ensureNewPipeBridge(); err != nil {
		return StreamCacheItem{}, fmt.Errorf("bridge unavailable: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, bridgeURL+"/streams?id="+videoID, nil)
	if err != nil {
		return StreamCacheItem{}, err
	}

	client := &http.Client{Timeout: 8 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return StreamCacheItem{}, fmt.Errorf("bridge query failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return StreamCacheItem{}, fmt.Errorf("bridge returned HTTP %d", resp.StatusCode)
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return StreamCacheItem{}, fmt.Errorf("read bridge response: %w", err)
	}

	var bResp bridgeStreamsResponse
	if err := json.Unmarshal(data, &bResp); err != nil {
		return StreamCacheItem{}, fmt.Errorf("unmarshal bridge response: %w", err)
	}

	targetURL := bResp.AudioURL
	if targetURL == "" {
		targetURL = bResp.MP4
	}

	if targetURL == "" {
		return StreamCacheItem{}, fmt.Errorf("no valid audio or progressive stream found for video %s", videoID)
	}

	streamType := bResp.AudioCodec
	if streamType == "" {
		streamType = "opus"
	}
	bitrate := bResp.AudioBitrate
	if bitrate <= 0 {
		bitrate = 160000
	}
	itag := bResp.AudioItag
	if itag <= 0 {
		itag = 251
	}

	item := StreamCacheItem{
		URL:        targetURL,
		StreamType: streamType,
		Bitrate:    bitrate,
		Itag:       itag,
		ExpiresAt:  time.Now().Add(5*time.Hour + 30*time.Minute), // YouTube signed links valid 6h
	}

	GlobalStreamCache.Set(videoID, item)
	return item, nil
}
