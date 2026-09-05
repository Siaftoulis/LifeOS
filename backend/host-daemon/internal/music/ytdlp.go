package music

import (
	"bytes"
	"context"
	"fmt"
	"log"
	"os"
	"os/exec"
	"runtime"
	"strings"
	"time"
)

const (
	defaultSearchTimeout   = 30 * time.Second
	defaultStreamTimeout   = 2 * time.Minute
	defaultDownloadTimeout = 10 * time.Minute
)

// commandRunner provides an injection point for testing process execution without real external commands.
var commandRunner = func(ctx context.Context, name string, args ...string) *exec.Cmd {
	return exec.CommandContext(ctx, name, args...)
}

// YtDlpError captures structured failure details including summarized stderr.
type YtDlpError struct {
	Operation string
	Target    string
	Err       error
	Stderr    string
}

func (e *YtDlpError) Error() string {
	if e.Stderr != "" {
		return fmt.Sprintf("yt-dlp %s [%s] failed: %v: %s", e.Operation, e.Target, e.Err, e.Stderr)
	}
	return fmt.Sprintf("yt-dlp %s [%s] failed: %v", e.Operation, e.Target, e.Err)
}

func (e *YtDlpError) Unwrap() error {
	return e.Err
}

// resolveYtDlpPath resolves the yt-dlp binary from configuration or PATH.
func resolveYtDlpPath() string {
	if custom := strings.TrimSpace(os.Getenv("YTDLP_PATH")); custom != "" {
		return custom
	}
	if p, err := exec.LookPath("yt-dlp"); err == nil {
		return p
	}
	return "yt-dlp"
}

// jsRuntimesArg returns the appropriate --js-runtimes argument without hardcoded system paths.
func jsRuntimesArg() string {
	if custom := strings.TrimSpace(os.Getenv("YTDLP_JS_RUNTIMES")); custom != "" {
		return custom
	}
	if runtime.GOOS == "windows" {
		return "node"
	}
	return "node:/usr/bin/nodejs,node,bun"
}

// extractStderrSummary extracts the last relevant lines of stderr for logging.
func extractStderrSummary(raw string) string {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return ""
	}
	lines := strings.Split(trimmed, "\n")
	var excerpt []string
	for i := len(lines) - 1; i >= 0 && len(excerpt) < 3; i-- {
		line := strings.TrimSpace(lines[i])
		if line != "" {
			excerpt = append([]string{line}, excerpt...)
		}
	}
	return strings.Join(excerpt, "; ")
}

// ExecYtDlp executes yt-dlp with the given context and arguments, capturing stdout and stderr.
func ExecYtDlp(ctx context.Context, op string, target string, args []string) ([]byte, error) {
	bin := resolveYtDlpPath()
	cmd := commandRunner(ctx, bin, args...)

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	err := cmd.Run()
	if err != nil {
		stderrExcerpt := extractStderrSummary(stderr.String())
		ytErr := &YtDlpError{
			Operation: op,
			Target:    target,
			Err:       err,
			Stderr:    stderrExcerpt,
		}
		log.Printf("music %s error: %v", op, ytErr)
		return nil, ytErr
	}

	return stdout.Bytes(), nil
}
