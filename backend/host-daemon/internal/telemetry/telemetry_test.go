package telemetry

import (
	"encoding/base64"
	"encoding/json"
	"testing"
)

// encodeEvent mirrors the Dart client encoding (base64url(xor(json))) so the
// roundtrip test proves both sides speak the same wire format.
func encodeEvent(ev event) string {
	blob, _ := json.Marshal(ev)
	key := []byte(xorKey)
	for i := range blob {
		blob[i] ^= key[i%len(key)]
	}
	return base64.URLEncoding.EncodeToString(blob)
}

func TestDecodeRoundtrip(t *testing.T) {
	ev := event{Module: "home", Action: "device_toggled", Data: map[string]any{"device_id": "light.living_room"}, Ts: 1786818000}
	decoded, err := decodeEvent(encodeEvent(ev))
	if err != nil {
		t.Fatalf("decode failed: %v", err)
	}
	if decoded.Module != "home" || decoded.Action != "device_toggled" {
		t.Fatalf("wrong event: %+v", decoded)
	}
	if decoded.Data["device_id"] != "light.living_room" {
		t.Fatalf("wrong data: %+v", decoded.Data)
	}
}

func TestGarbageAndUnknownRejected(t *testing.T) {
	if _, err := decodeEvent("!!!not-base64!!!"); err == nil {
		t.Fatal("garbage should not decode")
	}
	if _, err := decodeEvent(encodeEvent(event{Module: "home", Action: "device_toggled"})); err != nil {
		t.Fatalf("valid event should decode: %v", err)
	}
	if _, ok := rules["unknown:action"]; ok {
		t.Fatal("unknown rules must not exist")
	}
}

func TestDedup(t *testing.T) {
	ev := event{Module: "movies", Action: "review_added", Data: map[string]any{"movie_id": "m1"}, Ts: 1786818000}
	key := dedupKey("panospds", ev)
	if !seen(key) {
		t.Fatal("first sighting should be seen")
	}
	if seen(key) {
		t.Fatal("replay must be rejected")
	}
	// Same activity on a different day is allowed again.
	ev.Ts += 86400
	if !seen(dedupKey("panospds", ev)) {
		t.Fatal("next day should be seen again")
	}
}