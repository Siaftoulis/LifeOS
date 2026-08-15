package location

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func newTestRouter(t *testing.T) *http.ServeMux {
	t.Helper()
	t.Chdir(t.TempDir()) // keep geofences.json writes out of the repo
	mux := http.NewServeMux()
	RegisterRoutes(mux)
	return mux
}

func TestGeofenceSearchSingle(t *testing.T) {
	mux := newTestRouter(t)

	// Deterministic regardless of the seeded file: add unique pins first.
	AddGeofence(Geofence{ID: "pin-test-1", Name: "Test Pin Alpha", Type: "circle", Latitude: 40.0, Longitude: 22.0, Radius: 100, IsActive: true})
	AddGeofence(Geofence{ID: "pin-test-2", Name: "Test Pin Beta", Type: "polygon", IsActive: false})

	req := httptest.NewRequest("GET", "/api/v1/radar/geofences?q=alpha", nil)
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("search: got %d, want 200", rec.Code)
	}
	var list []Geofence
	if err := json.Unmarshal(rec.Body.Bytes(), &list); err != nil {
		t.Fatalf("decode: %v", err)
	}
	if len(list) != 1 || list[0].ID != "pin-test-1" {
		t.Fatalf("search: got %+v, want pin-test-1 only", list)
	}

	req = httptest.NewRequest("GET", "/api/v1/radar/geofences/pin-test-2", nil)
	rec = httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("get: got %d, want 200", rec.Code)
	}
	var pin Geofence
	if err := json.Unmarshal(rec.Body.Bytes(), &pin); err != nil {
		t.Fatalf("decode: %v", err)
	}
	if pin.Name != "Test Pin Beta" || pin.IsActive {
		t.Fatalf("get: got %+v, want Test Pin Beta inactive", pin)
	}

	req = httptest.NewRequest("GET", "/api/v1/radar/geofences/missing", nil)
	rec = httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusNotFound {
		t.Fatalf("get missing: got %d, want 404", rec.Code)
	}
}
