package music

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"testing"
	"time"
)

// TestHelperProcess serves as the mock executable invoked during unit testing.
func TestHelperProcess(t *testing.T) {
	if os.Getenv("GO_WANT_HELPER_PROCESS") != "1" {
		return
	}

	args := os.Args
	for len(args) > 0 {
		if args[0] == "--" {
			args = args[1:]
			break
		}
		args = args[1:]
	}
	if len(args) == 0 {
		os.Exit(0)
	}

	cmd := args[0]
	switch cmd {
	case "sleep":
		time.Sleep(2 * time.Second)
		os.Exit(0)
	case "fail":
		fmt.Fprintln(os.Stderr, "ERROR: [youtube] vid_fail: Private video")
		os.Exit(1)
	case "success-search":
		fmt.Println(`{"entries":[{"id":"vid1","title":"Song 1","uploader":"Artist 1","duration":200}]}`)
		os.Exit(0)
	case "success-download":
		fmt.Println("test/saved.mp3\nSong Title\nArtist Name\nAlbum Name\n180.5\nUploader Name\nhttps://i.ytimg.com/vi/vid1/hqdefault.jpg")
		os.Exit(0)
	default:
		os.Exit(0)
	}
}

func mockCommandRunner(mode string) func(context.Context, string, ...string) *exec.Cmd {
	return func(ctx context.Context, name string, args ...string) *exec.Cmd {
		cmd := exec.CommandContext(ctx, os.Args[0], "-test.run=TestHelperProcess", "--", mode)
		cmd.Env = append(os.Environ(), "GO_WANT_HELPER_PROCESS=1")
		return cmd
	}
}

func TestYtDlpConfigResolution(t *testing.T) {
	// Test environment override
	t.Setenv("YTDLP_PATH", "/custom/bin/yt-dlp")
	if got := resolveYtDlpPath(); got != "/custom/bin/yt-dlp" {
		t.Fatalf("resolveYtDlpPath: got %q, want /custom/bin/yt-dlp", got)
	}

	// Test default fallback
	t.Setenv("YTDLP_PATH", "")
	got := resolveYtDlpPath()
	if got == "" {
		t.Fatalf("resolveYtDlpPath: got empty string")
	}

	// Test JS runtime argument override
	t.Setenv("YTDLP_JS_RUNTIMES", "custom_node")
	if got := jsRuntimesArg(); got != "custom_node" {
		t.Fatalf("jsRuntimesArg: got %q, want custom_node", got)
	}
}

func TestExtractStderrSummary(t *testing.T) {
	raw := "line 1\nline 2\nERROR: Video unavailable\nPlease check network\n"
	summary := extractStderrSummary(raw)
	if !strings.Contains(summary, "ERROR: Video unavailable") || !strings.Contains(summary, "Please check network") {
		t.Fatalf("extractStderrSummary: unexpected summary %q", summary)
	}

	if empty := extractStderrSummary(""); empty != "" {
		t.Fatalf("extractStderrSummary empty: got %q, want empty", empty)
	}
}

func TestExecYtDlpSuccess(t *testing.T) {
	oldRunner := commandRunner
	defer func() { commandRunner = oldRunner }()
	commandRunner = mockCommandRunner("success-search")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	out, err := ExecYtDlp(ctx, "search", "test_query", []string{})
	if err != nil {
		t.Fatalf("ExecYtDlp failed: %v", err)
	}
	if !strings.Contains(string(out), "vid1") {
		t.Fatalf("ExecYtDlp output mismatch: %s", string(out))
	}
}

func TestExecYtDlpFailureWithStderrDiagnostics(t *testing.T) {
	oldRunner := commandRunner
	defer func() { commandRunner = oldRunner }()
	commandRunner = mockCommandRunner("fail")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := ExecYtDlp(ctx, "download", "vid_fail", []string{})
	if err == nil {
		t.Fatalf("ExecYtDlp expected error, got nil")
	}

	ytErr, ok := err.(*YtDlpError)
	if !ok {
		t.Fatalf("expected *YtDlpError, got %T (%v)", err, err)
	}
	if !strings.Contains(ytErr.Stderr, "Private video") {
		t.Fatalf("expected stderr to contain 'Private video', got %q", ytErr.Stderr)
	}
	if !strings.Contains(ytErr.Error(), "vid_fail") {
		t.Fatalf("expected error string to mention target vid_fail, got %q", ytErr.Error())
	}
}

func TestExecYtDlpContextCancellation(t *testing.T) {
	oldRunner := commandRunner
	defer func() { commandRunner = oldRunner }()
	commandRunner = mockCommandRunner("sleep")

	ctx, cancel := context.WithCancel(context.Background())
	// Cancel immediately
	cancel()

	_, err := ExecYtDlp(ctx, "stream", "vid_slow", []string{})
	if err == nil {
		t.Fatalf("expected cancellation error, got nil")
	}
}
