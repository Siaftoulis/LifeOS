package auth

import (
	"net/http/httptest"
	"testing"
	"time"
)

func TestLoginLimiter(t *testing.T) {
	l := &ipLimiter{fails: make(map[string][]time.Time)}

	if l.blocked("1.2.3.4") {
		t.Fatal("not blocked before any failures")
	}
	for i := 0; i < 5; i++ {
		l.fail("1.2.3.4")
	}
	if !l.blocked("1.2.3.4") {
		t.Fatal("expected block after 5 failures")
	}
	if l.blocked("9.9.9.9") {
		t.Fatal("different IP must not be blocked")
	}
	l.clear("1.2.3.4")
	if l.blocked("1.2.3.4") {
		t.Fatal("expected unblock after clear")
	}
}

func TestIsTrustedPeer(t *testing.T) {
	cases := []struct {
		remote string
		cfIP   string
		want   bool
	}{
		{"127.0.0.1:1234", "", true},
		{"192.168.1.50:1234", "", true},
		{"100.120.229.45:1234", "", true},
		{"100.64.0.1:1234", "", true},
		{"8.8.8.8:1234", "", false},
		{"8.8.8.8:1234", "203.0.113.7", false},
		{"127.0.0.1:1234", "203.0.113.7", false},
	}
	for _, c := range cases {
		req := httptest.NewRequest("POST", "/api/v1/auth/register", nil)
		req.RemoteAddr = c.remote
		if c.cfIP != "" {
			req.Header.Set("Cf-Connecting-Ip", c.cfIP)
		}
		if got := isTrustedPeer(req); got != c.want {
			t.Errorf("remote=%s cf=%q: got %v, want %v", c.remote, c.cfIP, got, c.want)
		}
	}
}
