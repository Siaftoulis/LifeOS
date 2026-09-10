package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestWithCORSPreflight(t *testing.T) {
	dummy := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusTeapot)
	})

	handler := withCORS(dummy)

	// Preflight OPTIONS should be handled with 200 OK and CORS headers
	req := httptest.NewRequest(http.MethodOptions, "/api/v1/music/tracks", nil)
	req.Header.Set("Origin", "http://localhost:3000")
	req.Header.Set("Access-Control-Request-Method", "GET")
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200 for OPTIONS preflight, got %d", rec.Code)
	}

	if origin := rec.Header().Get("Access-Control-Allow-Origin"); origin != "*" {
		t.Errorf("expected Access-Control-Allow-Origin: *, got %q", origin)
	}
	if methods := rec.Header().Get("Access-Control-Allow-Methods"); methods == "" {
		t.Errorf("expected Access-Control-Allow-Methods to be present")
	}
	if headers := rec.Header().Get("Access-Control-Allow-Headers"); headers == "" {
		t.Errorf("expected Access-Control-Allow-Headers to be present")
	}
}

func TestWithCORSStandardRequest(t *testing.T) {
	dummy := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("ok"))
	})

	handler := withCORS(dummy)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/music/tracks", nil)
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", rec.Code)
	}
	if origin := rec.Header().Get("Access-Control-Allow-Origin"); origin != "*" {
		t.Errorf("expected Access-Control-Allow-Origin: *, got %q", origin)
	}
}
