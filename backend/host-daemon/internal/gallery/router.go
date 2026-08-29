package gallery

import (
	"bytes"
	"encoding/json"
	"image"
	"image/jpeg"
	_ "image/png"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"golang.org/x/image/draw"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/gallery/upload", handleUpload)
	mux.HandleFunc("/api/v1/gallery/analyze", handleAnalyze)
	mux.HandleFunc("/api/v1/gallery/assets", handleAssets)
	mux.HandleFunc("/api/v1/gallery/asset", handleAsset)
	mux.HandleFunc("/api/v1/gallery/duplicates", handleDuplicates)
	mux.HandleFunc("/api/v1/gallery/meta", handleMetaUpdate)
	mux.HandleFunc("/api/v1/gallery/thumbnail", handleThumbnail)
	mux.HandleFunc("/api/v1/gallery/stream", handleStream)
}

// analysis captures everything the "small AI model" derives from a file.
type analysis struct {
	Hash     string   `json:"hash"`
	Width    int      `json:"width"`
	Height   int      `json:"height"`
	Colors   []string `json:"colors"`
	Source   string   `json:"source"`
	Title    string   `json:"title"`
	Tags     []string `json:"tags"`
	Decodable bool    `json:"decodable"`
}

// analyzeFile runs hash/colors/source/title/tags over file bytes.
func analyzeFile(data []byte, filename, assetType, place string, takenAt time.Time) analysis {
	a := analysis{}
	a.Source = DetectSource(filename, assetType)

	img, _, err := image.Decode(bytes.NewReader(data))
	if err == nil {
		a.Decodable = true
		a.Width, a.Height = imageSize(img)
		a.Hash = DHash(img)
		a.Colors = DominantColors(img, 4)
	} else {
		// Videos and unsupported formats: content hash only.
		a.Hash = HashBytes(data)
	}

	if !a.Decodable {
		a.Colors = []string{}
	}
	a.Title = SuggestTitle(place, takenAt, a.Source)
	a.Tags = SuggestTags(place, takenAt, a.Source, a.Colors)
	return a
}

func handleUpload(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseMultipartForm(100 << 20); err != nil { // 100 MB max
		http.Error(w, "Failed to parse form", http.StatusBadRequest)
		return
	}

	userID := r.FormValue("user_id")
	deviceID := r.FormValue("device_id")
	assetID := r.FormValue("asset_id")
	assetType := r.FormValue("type") // PHOTO or VIDEO
	createdAt := r.FormValue("created_at")
	place := r.FormValue("place")

	if userID == "" || assetID == "" {
		http.Error(w, "Missing user_id or asset_id", http.StatusBadRequest)
		return
	}

	file, header, err := r.FormFile("file")
	if err != nil {
		http.Error(w, "Missing file", http.StatusBadRequest)
		return
	}
	defer file.Close()

	data, err := io.ReadAll(file)
	if err != nil {
		http.Error(w, "Failed to read file", http.StatusInternalServerError)
		return
	}

	var takenAt time.Time
	if t, err := time.Parse(time.RFC3339, createdAt); err == nil {
		takenAt = t
	}

	a := analyzeFile(data, header.Filename, assetType, place, takenAt)

	// ----- duplicate detection: keep the highest-resolution copy -----
	duplicateOf := ""
	if DB != nil && a.Hash != "" {
		var existingID, existingPath string
		var existingW, existingH int
		err := DB.QueryRow(
			`SELECT id, filepath, width, height FROM assets WHERE hash = ? AND user_id = ? LIMIT 1`,
			a.Hash, userID,
		).Scan(&existingID, &existingPath, &existingW, &existingH)

		if err == nil {
			duplicateOf = existingID
			newRes := a.Width * a.Height
			oldRes := existingW * existingH

			if newRes > oldRes {
				// New copy is better: replace file, update the existing row,
				// delete the old file.
				relPath, err := SaveAsset("./data", userID, deviceID, header.Filename, bytes.NewReader(data))
				if err == nil {
					if existingPath != "" {
						os.Remove(filepath.Join("./data", existingPath))
					}
					_, err = DB.Exec(
						`UPDATE assets SET filename = ?, size_bytes = ?, filepath = ?, width = ?, height = ?, hash = ?, source = ?, title = ?, tags = ?, colors = ?, place = ? WHERE id = ?`,
						header.Filename, len(data), relPath, a.Width, a.Height, a.Hash, a.Source, a.Title,
						toJSON(a.Tags), toJSON(a.Colors), place, existingID,
					)
					if err != nil {
						log.Printf("Failed to update asset after dedupe: %v", err)
					}
					assetID = existingID
				}
			} else {
				// Existing copy is equal or better: skip the new upload.
				respondUpload(w, http.StatusOK, assetID, duplicateOf, a)
				return
			}
		}
	}

	// ----- save + insert (only reached when not deduplicated) -----
	if duplicateOf == "" {
		relPath, err := SaveAsset("./data", userID, deviceID, header.Filename, bytes.NewReader(data))
		if err != nil {
			http.Error(w, "Failed to save file", http.StatusInternalServerError)
			return
		}

		if DB != nil {
			query := `INSERT INTO assets (id, user_id, device_id, filename, type, created_at, size_bytes, filepath, hash, width, height, source, title, tags, colors, place)
			          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
			_, err = DB.Exec(query, assetID, userID, deviceID, header.Filename, assetType, createdAt,
				len(data), relPath, a.Hash, a.Width, a.Height, a.Source, a.Title, toJSON(a.Tags), toJSON(a.Colors), place)
			if err != nil {
				log.Printf("Failed to insert asset into db: %v", err)
			}
		}
	}

	respondUpload(w, http.StatusCreated, assetID, duplicateOf, a)
}

func respondUpload(w http.ResponseWriter, status int, id, duplicateOf string, a analysis) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":        "success",
		"id":            id,
		"duplicate_of":  duplicateOf,
		"hash":          a.Hash,
		"width":         a.Width,
		"height":        a.Height,
		"colors":        a.Colors,
		"source":        a.Source,
		"title":         a.Title,
		"tags":          a.Tags,
	})
}

// handleAnalyze is the pure "smart picker" endpoint: it analyzes a file and
// returns suggested title/tags WITHOUT saving anything.
func handleAnalyze(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseMultipartForm(100 << 20); err != nil {
		http.Error(w, "Failed to parse form", http.StatusBadRequest)
		return
	}

	file, header, err := r.FormFile("file")
	if err != nil {
		http.Error(w, "Missing file", http.StatusBadRequest)
		return
	}
	defer file.Close()

	data, err := io.ReadAll(file)
	if err != nil {
		http.Error(w, "Failed to read file", http.StatusInternalServerError)
		return
	}

	assetType := r.FormValue("type")
	place := r.FormValue("place")
	var takenAt time.Time
	if t, err := time.Parse(time.RFC3339, r.FormValue("date")); err == nil {
		takenAt = t
	}

	a := analyzeFile(data, header.Filename, assetType, place, takenAt)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(a)
}

func handleAssets(w http.ResponseWriter, r *http.Request) {
	if DB == nil {
		http.Error(w, "Database not initialized", http.StatusInternalServerError)
		return
	}

	limit := 50
	offset := 0
	if l := r.URL.Query().Get("limit"); l != "" {
		if v, err := strconv.Atoi(l); err == nil && v > 0 && v <= 200 {
			limit = v
		}
	}
	if o := r.URL.Query().Get("offset"); o != "" {
		if v, err := strconv.Atoi(o); err == nil && v >= 0 {
			offset = v
		}
	}

	query := `SELECT id, user_id, device_id, filename, type, created_at, size_bytes,
		hash, width, height, source, title, tags, colors, lat, lng, place
		FROM assets ORDER BY created_at DESC LIMIT ? OFFSET ?`

	rows, err := DB.Query(query, limit, offset)
	if err != nil {
		http.Error(w, "Database query error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var results []map[string]interface{}
	for rows.Next() {
		var id, userID, deviceID, filename, assetType, createdAt string
		var sizeBytes int
		var hash, source, title, tags, colors, place string
		var width, height int
		var lat, lng float64
		if err := rows.Scan(&id, &userID, &deviceID, &filename, &assetType, &createdAt, &sizeBytes,
			&hash, &width, &height, &source, &title, &tags, &colors, &lat, &lng, &place); err != nil {
			continue
		}
		if q := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("q"))); q != "" &&
			!strings.Contains(strings.ToLower(title), q) &&
			!strings.Contains(strings.ToLower(filename), q) &&
			!strings.Contains(strings.ToLower(source), q) {
			continue
		}
		results = append(results, map[string]interface{}{
			"id":         id,
			"user_id":    userID,
			"device_id":  deviceID,
			"filename":   filename,
			"type":       assetType,
			"created_at": createdAt,
			"size_bytes": sizeBytes,
			"hash":       hash,
			"width":      width,
			"height":     height,
			"source":     source,
			"title":      title,
			"tags":       fromJSON(tags),
			"colors":     fromJSON(colors),
			"lat":        lat,
			"lng":        lng,
			"place":      place,
		})
	}

	if results == nil {
		results = []map[string]interface{}{}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"assets": results,
		"limit":  limit,
		"offset": offset,
		"count":  len(results),
	})
}

// handleAsset returns a single asset's metadata (embed card render).
func handleAsset(w http.ResponseWriter, r *http.Request) {
	id := r.URL.Query().Get("id")
	if DB == nil || id == "" {
		http.Error(w, "Missing ID", http.StatusBadRequest)
		return
	}

	row := DB.QueryRow(`SELECT id, user_id, device_id, filename, type, created_at, size_bytes,
		hash, width, height, source, title, tags, colors, lat, lng, place
		FROM assets WHERE id = ?`, id)
	var (
		assetID, userID, deviceID, filename, assetType, createdAt string
		sizeBytes, width, height, latI, lngI                     int
		hash, source, title, tags, colors, place                 string
		lat, lng                                                  float64
	)
	if err := row.Scan(&assetID, &userID, &deviceID, &filename, &assetType, &createdAt, &sizeBytes,
		&hash, &width, &height, &source, &title, &tags, &colors, &latI, &lngI, &place); err != nil {
		http.Error(w, "Not found", http.StatusNotFound)
		return
	}
	lat, lng = float64(latI), float64(lngI)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"id": assetID, "user_id": userID, "device_id": deviceID,
		"filename": filename, "type": assetType, "created_at": createdAt,
		"size_bytes": sizeBytes, "hash": hash, "width": width, "height": height,
		"source": source, "title": title, "tags": fromJSON(tags), "colors": fromJSON(colors),
		"lat": lat, "lng": lng, "place": place,
	})
}

// handleDuplicates groups assets by perceptual hash.
func handleDuplicates(w http.ResponseWriter, r *http.Request) {
	if DB == nil {
		http.Error(w, "Database not initialized", http.StatusInternalServerError)
		return
	}

	rows, err := DB.Query(`SELECT hash, id, filename, width, height, size_bytes, created_at
		FROM assets WHERE hash != '' ORDER BY hash, width DESC`)
	if err != nil {
		http.Error(w, "Database query error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	groups := []map[string]interface{}{}
	var curHash string
	cur := map[string]interface{}{}
	items := []map[string]interface{}{}
	for rows.Next() {
		var hash, id, filename, createdAt string
		var width, height, sizeBytes int
		if err := rows.Scan(&hash, &id, &filename, &width, &height, &sizeBytes, &createdAt); err != nil {
			continue
		}
		if hash != curHash && curHash != "" {
			if len(items) > 1 {
				cur["hash"] = curHash
				cur["items"] = items
				groups = append(groups, cur)
			}
			items = []map[string]interface{}{}
			cur = map[string]interface{}{}
		}
		curHash = hash
		items = append(items, map[string]interface{}{
			"id": id, "filename": filename, "width": width, "height": height,
			"size_bytes": sizeBytes, "created_at": createdAt,
		})
	}
	if curHash != "" && len(items) > 1 {
		cur["hash"] = curHash
		cur["items"] = items
		groups = append(groups, cur)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(groups)
}

// handleMetaUpdate updates title/tags/source/place for an asset.
func handleMetaUpdate(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut && r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	if DB == nil {
		http.Error(w, "Database not initialized", http.StatusInternalServerError)
		return
	}

	var body struct {
		ID     string   `json:"id"`
		Title  string   `json:"title"`
		Tags   []string `json:"tags"`
		Source string   `json:"source"`
		Place  string   `json:"place"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.ID == "" {
		http.Error(w, "Invalid body", http.StatusBadRequest)
		return
	}

	_, err := DB.Exec(
		`UPDATE assets SET title = ?, tags = ?, source = ?, place = ? WHERE id = ?`,
		body.Title, toJSON(body.Tags), body.Source, body.Place, body.ID,
	)
	if err != nil {
		http.Error(w, "Update failed", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "ok", "id": body.ID})
}

func toJSON(v interface{}) string {
	b, _ := json.Marshal(v)
	return string(b)
}

func fromJSON(s string) []string {
	if s == "" {
		return []string{}
	}
	var out []string
	if err := json.Unmarshal([]byte(s), &out); err != nil {
		return []string{}
	}
	return out
}

func handleThumbnail(w http.ResponseWriter, r *http.Request) {
	id := r.URL.Query().Get("id")
	if DB == nil || id == "" {
		http.Error(w, "Missing ID", http.StatusBadRequest)
		return
	}

	var relPath string
	err := DB.QueryRow("SELECT filepath FROM assets WHERE id = ?", id).Scan(&relPath)
	if err != nil {
		http.Error(w, "Not found", http.StatusNotFound)
		return
	}

	absPath := filepath.Join("./data", relPath)
	file, err := os.Open(absPath)
	if err != nil {
		http.Error(w, "Could not open file", http.StatusInternalServerError)
		return
	}
	defer file.Close()

	img, _, err := image.Decode(file)
	if err != nil {
		// Might be a video or unsupported image, just fallback to stream or error
		http.Error(w, "Unsupported format for thumbnail", http.StatusUnsupportedMediaType)
		return
	}

	// Calculate thumbnail size (e.g. max 300px)
	bounds := img.Bounds()
	width := bounds.Dx()
	height := bounds.Dy()
	var newWidth, newHeight int

	if width > height {
		newWidth = 300
		newHeight = (height * 300) / width
	} else {
		newHeight = 300
		newWidth = (width * 300) / height
	}

	dst := image.NewRGBA(image.Rect(0, 0, newWidth, newHeight))
	draw.CatmullRom.Scale(dst, dst.Bounds(), img, bounds, draw.Over, nil)

	var buf bytes.Buffer
	if err := jpeg.Encode(&buf, dst, &jpeg.Options{Quality: 75}); err != nil {
		http.Error(w, "Error generating thumbnail", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "image/jpeg")
	w.Header().Set("Cache-Control", "public, max-age=604800")
	w.Write(buf.Bytes())
}

func handleStream(w http.ResponseWriter, r *http.Request) {
	// Implement file serving
	id := r.URL.Query().Get("id")
	if DB == nil || id == "" {
		http.Error(w, "Missing ID", http.StatusBadRequest)
		return
	}

	var relPath string
	err := DB.QueryRow("SELECT filepath FROM assets WHERE id = ?", id).Scan(&relPath)
	if err != nil {
		http.Error(w, "Not found", http.StatusNotFound)
		return
	}

	absPath := filepath.Join("./data", relPath)
	http.ServeFile(w, r, absPath)
}
