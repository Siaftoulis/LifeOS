package music

import (
	"testing"
	"time"
)

func TestStreamCacheLRU(t *testing.T) {
	cache := NewStreamCache(2)

	item1 := StreamCacheItem{URL: "https://stream1", StreamType: "opus", Bitrate: 160000, ExpiresAt: time.Now().Add(1 * time.Hour)}
	item2 := StreamCacheItem{URL: "https://stream2", StreamType: "aac", Bitrate: 128000, ExpiresAt: time.Now().Add(1 * time.Hour)}
	item3 := StreamCacheItem{URL: "https://stream3", StreamType: "opus", Bitrate: 160000, ExpiresAt: time.Now().Add(1 * time.Hour)}

	cache.Set("v1", item1)
	cache.Set("v2", item2)

	if val, ok := cache.Get("v1"); !ok || val.URL != "https://stream1" {
		t.Fatalf("Expected v1 to be in cache")
	}

	// Adding v3 should evict v2 (since v1 was accessed recently)
	cache.Set("v3", item3)

	if _, ok := cache.Get("v2"); ok {
		t.Errorf("Expected v2 to be evicted from cache")
	}

	if _, ok := cache.Get("v1"); !ok {
		t.Errorf("Expected v1 to still be in cache")
	}

	if _, ok := cache.Get("v3"); !ok {
		t.Errorf("Expected v3 to be in cache")
	}
}

func TestStreamCacheExpiry(t *testing.T) {
	cache := NewStreamCache(10)
	expired := StreamCacheItem{
		URL:        "https://expired",
		StreamType: "opus",
		ExpiresAt:  time.Now().Add(-10 * time.Second),
	}
	cache.Set("vexp", expired)

	if _, ok := cache.Get("vexp"); ok {
		t.Errorf("Expected expired item to be evicted on Get")
	}
}
