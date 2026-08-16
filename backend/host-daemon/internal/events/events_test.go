package events

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/gorilla/websocket"

	"lifeos/host-daemon/internal/auth/middleware"
	"lifeos/host-daemon/internal/bus"
	"lifeos/host-daemon/internal/movies"
)

// End-to-end: forged JWT → WS connect → bus publish → relayed JSON frame.
func TestRelayStreamsBusEvents(t *testing.T) {
	Start()
	srv := httptest.NewServer(http.HandlerFunc(HandleEvents))
	defer srv.Close()

	token, err := jwt.NewWithClaims(jwt.SigningMethodHS256, middleware.Claims{
		Username: "tester",
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour)),
		},
	}).SignedString(middleware.JwtSecret)
	if err != nil {
		t.Fatal(err)
	}

	wsURL := "ws" + strings.TrimPrefix(srv.URL, "http") + "/api/v1/events?token=" + token
	conn, _, err := websocket.DefaultDialer.Dial(wsURL, nil)
	if err != nil {
		t.Fatalf("dial: %v", err)
	}
	defer conn.Close()

	bus.Publish(bus.Event{
		Topic:   "movies:watched",
		UserID:  "tester",
		Payload: movies.WatchedEvent{MovieID: "m1", Title: "Dune", UserID: "tester"},
	})

	conn.SetReadDeadline(time.Now().Add(2 * time.Second))
	_, msg, err := conn.ReadMessage()
	if err != nil {
		t.Fatalf("read: %v", err)
	}
	var got struct {
		Topic   string          `json:"topic"`
		UserID  string          `json:"user_id"`
		Payload json.RawMessage `json:"payload"`
	}
	if err := json.Unmarshal(msg, &got); err != nil {
		t.Fatalf("bad relay frame: %v", err)
	}
	if got.Topic != "movies:watched" || got.UserID != "tester" {
		t.Fatalf("wrong relay: %s", msg)
	}
	if !strings.Contains(string(got.Payload), `"Title":"Dune"`) {
		t.Fatalf("payload not relayed: %s", got.Payload)
	}
}

func TestHandleEventsRejectsBadToken(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(HandleEvents))
	defer srv.Close()
	wsURL := "ws" + strings.TrimPrefix(srv.URL, "http") + "/api/v1/events?token=bogus"
	_, _, err := websocket.DefaultDialer.Dial(wsURL, nil)
	if err == nil {
		t.Fatal("expected dial to fail with bad token")
	}
}