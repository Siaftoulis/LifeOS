package gallery

import (
	"bytes"
	"encoding/json"
	"image/png"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"testing"
)

// newUploadRouter inits a temp DB and chdirs so the handler's "./data" writes
// land in temp, then returns a router with the gallery routes registered.
func newUploadRouter(t *testing.T) *http.ServeMux {
	t.Helper()
	if err := InitDB(t.TempDir()); err != nil {
		t.Fatalf("InitDB: %v", err)
	}
	t.Cleanup(func() { DB.Close() })
	t.Chdir(t.TempDir())

	mux := http.NewServeMux()
	RegisterRoutes(mux)
	return mux
}

func multipartUpload(t *testing.T, mux *http.ServeMux, assetID string, pngBytes []byte) (int, map[string]interface{}) {
	t.Helper()

	var body bytes.Buffer
	w := multipart.NewWriter(&body)
	w.WriteField("user_id", "u-test")
	w.WriteField("device_id", "dev-test")
	w.WriteField("asset_id", assetID)
	w.WriteField("type", "PHOTO")
	part, err := w.CreateFormFile("file", "photo.png")
	if err != nil {
		t.Fatalf("CreateFormFile: %v", err)
	}
	part.Write(pngBytes)
	w.Close()

	req := httptest.NewRequest("POST", "/api/v1/gallery/upload", &body)
	req.Header.Set("Content-Type", w.FormDataContentType())
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	var data map[string]interface{}
	json.Unmarshal(rec.Body.Bytes(), &data)
	return rec.Code, data
}

// TestUploadDedupe: identical content uploaded twice must return the first
// asset id as duplicate_of and store exactly one row.
func TestUploadDedupe(t *testing.T) {
	mux := newUploadRouter(t)

	var pngBytes bytes.Buffer
	if err := png.Encode(&pngBytes, testImg()); err != nil {
		t.Fatalf("png encode: %v", err)
	}

	code, first := multipartUpload(t, mux, "asset-1", pngBytes.Bytes())
	if code != http.StatusCreated {
		t.Fatalf("first upload: got %d (body %v), want 201", code, first)
	}
	if first["duplicate_of"] != "" {
		t.Fatalf("first upload: unexpected duplicate_of %v", first["duplicate_of"])
	}

	code, second := multipartUpload(t, mux, "asset-2", pngBytes.Bytes())
	if code != http.StatusOK {
		t.Fatalf("second upload: got %d (body %v), want 200", code, second)
	}
	if second["duplicate_of"] != "asset-1" {
		t.Fatalf("second upload: duplicate_of = %v, want asset-1", second["duplicate_of"])
	}

	var count int
	if err := DB.QueryRow("SELECT COUNT(*) FROM assets").Scan(&count); err != nil {
		t.Fatalf("count: %v", err)
	}
	if count != 1 {
		t.Fatalf("assets rows = %d, want 1", count)
	}

	req := httptest.NewRequest("GET", "/api/v1/gallery/asset?id=asset-1", nil)
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("asset by id: got %d, want 200", rec.Code)
	}
	if rec.Body.String() == "" || !bytes.Contains(rec.Body.Bytes(), []byte("asset-1")) {
		t.Fatalf("asset by id: unexpected body %s", rec.Body.String())
	}

	req = httptest.NewRequest("GET", "/api/v1/gallery/asset?id=missing", nil)
	rec = httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusNotFound {
		t.Fatalf("asset missing: got %d, want 404", rec.Code)
	}
}
