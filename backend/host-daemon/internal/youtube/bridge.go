package youtube

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"sync"
	"time"
)

// Bridge to the NewPipeExtractor JVM service (backend/newpipe-bridge). The
// daemon spawns it lazily on first YouTube call and proxies everything.
const bridgeBase = "http://127.0.0.1:18785"

const bridgeUA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"

var (
	bridgeMu  sync.Mutex
	bridgeCmd *exec.Cmd
)

type searchResult struct {
	ID        string `json:"id"`
	Title     string `json:"title"`
	Uploader  string `json:"uploader"`
	Duration  int64  `json:"duration"`
	Thumbnail string `json:"thumbnail"`
	Live      bool   `json:"live"`
}

type streamMeta struct {
	ID        string `json:"id"`
	Title     string `json:"title"`
	Uploader  string `json:"uploader"`
	Thumbnail string `json:"thumbnail"`
	Duration  int64  `json:"duration"`
	Live      bool   `json:"live"`
	Hls       string `json:"hls"`
	Mp4       string `json:"mp4"`
}

// ensureBridge starts the JVM bridge if it isn't answering /health yet.
func ensureBridge() error {
	if bridgeHealthy() {
		return nil
	}
	bridgeMu.Lock()
	defer bridgeMu.Unlock()
	if bridgeHealthy() {
		return nil
	}
	jar := os.Getenv("NEWPIPE_BRIDGE_JAR")
	if jar == "" {
		jar = "newpipe-bridge.jar"
	}
	if _, err := os.Stat(jar); err != nil {
		return fmt.Errorf("newpipe-bridge: jar not found at %s (set NEWPIPE_BRIDGE_JAR)", jar)
	}
	log.Printf("Starting newpipe-bridge: java -jar %s", jar)
	cmd := exec.Command("java", "-jar", jar)
	cmd.Stdout = log.Writer()
	cmd.Stderr = log.Writer()
	if err := cmd.Start(); err != nil {
		return fmt.Errorf("newpipe-bridge: spawn failed: %v", err)
	}
	bridgeCmd = cmd
	for i := 0; i < 60; i++ {
		time.Sleep(500 * time.Millisecond)
		if bridgeHealthy() {
			return nil
		}
	}
	return fmt.Errorf("newpipe-bridge: not healthy after 30s")
}

func bridgeHealthy() bool {
	c := &http.Client{Timeout: 800 * time.Millisecond}
	res, err := c.Get(bridgeBase + "/health")
	if err != nil {
		return false
	}
	defer res.Body.Close()
	io.Copy(io.Discard, res.Body)
	return res.StatusCode == http.StatusOK
}

func bridgeSearch(query string) ([]searchResult, error) {
	var buf bytes.Buffer
	if err := json.NewEncoder(&buf).Encode(map[string]string{"query": query}); err != nil {
		return nil, err
	}
	var out struct {
		Results []searchResult `json:"results"`
	}
	if err := bridgeCall("POST", "/search", &buf, &out); err != nil {
		return nil, err
	}
	return out.Results, nil
}

func bridgeStreams(id string) (*streamMeta, error) {
	var out streamMeta
	if err := bridgeCall("GET", "/streams?id="+id, nil, &out); err != nil {
		return nil, err
	}
	return &out, nil
}

func bridgeCall(method, path string, body *bytes.Buffer, out any) error {
	if err := ensureBridge(); err != nil {
		return err
	}
	req, err := http.NewRequest(method, bridgeBase+path, body)
	if err != nil {
		return err
	}
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return fmt.Errorf("bridge %s: %v", path, err)
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("bridge %s: %s", path, res.Status)
	}
	return json.NewDecoder(res.Body).Decode(out)
}

// liveHlsFallback resolves the HLS manifest for live streams when the bridge
// cannot (same yt-dlp pattern as the music module).
func liveHlsFallback(id string) (string, error) {
	out, err := exec.Command("yt-dlp", "-f", "hls/live/best", "-g", "--no-playlist",
		"https://www.youtube.com/watch?v="+id).Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(out)), nil
}