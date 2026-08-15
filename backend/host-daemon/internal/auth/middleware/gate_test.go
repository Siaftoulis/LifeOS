package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

func makeToken(role string) string {
	tok := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"username": "tester",
		"role":     role,
		"exp":      time.Now().Add(time.Hour).Unix(),
	})
	s, _ := tok.SignedString(JwtSecret)
	return s
}

func TestWithAuthGate(t *testing.T) {
	next := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(200)
	})
	gate := WithAuthGate([]string{
		"/api/v1/auth/login", "/api/v1/auth/register",
		"/api/v1/auth/oauth/providers",
		"/api/v1/auth/oauth/github/start", "/api/v1/auth/oauth/github/callback",
		"/api/v1/auth/oauth/google/start", "/api/v1/auth/oauth/google/callback",
	}, next)

	cases := []struct {
		name       string
		path       string
		header     string
		wantStatus int
	}{
		{"private without token", "/api/v1/points/leaderboard", "", 401},
		{"private with garbage token", "/api/v1/points/leaderboard", "Bearer garbage", 401},
		{"private with valid token", "/api/v1/points/leaderboard", "Bearer " + makeToken("USER"), 200},
		{"login is public", "/api/v1/auth/login", "", 200},
		{"register is public", "/api/v1/auth/register", "", 200},
		{"oauth providers is public", "/api/v1/auth/oauth/providers", "", 200},
		{"oauth github start is public", "/api/v1/auth/oauth/github/start", "", 200},
		{"oauth google callback is public", "/api/v1/auth/oauth/google/callback", "", 200},
		{"ws live radar requires auth now", "/api/v1/radar/live", "", 401},
		{"markdown collab requires auth now", "/api/markdown/collab", "", 401},
		{"ws live radar works with token", "/api/v1/radar/live", "Bearer " + makeToken("USER"), 200},
		{"non-api path bypasses gate", "/", "", 200},
		{"static web assets", "/index.html", "", 200},
	}
	for _, c := range cases {
		req := httptest.NewRequest("GET", c.path, nil)
		if c.header != "" {
			req.Header.Set("Authorization", c.header)
		}
		rec := httptest.NewRecorder()
		gate.ServeHTTP(rec, req)
		if rec.Code != c.wantStatus {
			t.Errorf("%s: got %d, want %d", c.name, rec.Code, c.wantStatus)
		}
	}
}
