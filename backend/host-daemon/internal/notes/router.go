package notes

import (
	"encoding/json"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

type Note struct {
	ID      string `json:"id"`
	Title   string `json:"title"`
	Path    string `json:"path"`
	Snippet string `json:"snippet,omitempty"`
}

func RegisterRoutes(mux *http.ServeMux, vaultPath string) {
	mux.HandleFunc("/api/v1/notes", handleList(vaultPath))
	mux.HandleFunc("/api/v1/notes/{path...}", handleGet(vaultPath))
}

// vaultRelPath resolves a raw note id to an absolute path inside the vault,
// rejecting anything that escapes it. The id is the vault-relative path
// without the .md extension.
func vaultRelPath(vaultPath, raw string) (string, error) {
	clean := filepath.Clean(filepath.FromSlash(raw))
	if clean == "." || filepath.IsAbs(clean) || strings.HasPrefix(clean, "..") {
		return "", os.ErrNotExist
	}
	if filepath.Ext(clean) != ".md" {
		clean += ".md"
	}
	abs := filepath.Join(vaultPath, clean)
	if !strings.HasPrefix(abs, filepath.Clean(vaultPath)) {
		return "", os.ErrNotExist
	}
	return abs, nil
}

func handleList(vaultPath string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		q := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("q")))

		var notes []Note
		filepath.WalkDir(vaultPath, func(path string, d os.DirEntry, err error) error {
			if err != nil {
				return nil
			}
			if d.IsDir() {
				if strings.HasPrefix(d.Name(), ".") && path != vaultPath {
					return filepath.SkipDir
				}
				return nil
			}
			if !strings.HasSuffix(d.Name(), ".md") {
				return nil
			}
			rel, _ := filepath.Rel(vaultPath, path)
			title := strings.TrimSuffix(d.Name(), ".md")
			if q != "" && !strings.Contains(strings.ToLower(title), q) &&
				!strings.Contains(strings.ToLower(rel), q) {
				return nil
			}
			notes = append(notes, Note{
				ID:    strings.TrimSuffix(filepath.ToSlash(rel), ".md"),
				Title: title,
				Path:  filepath.ToSlash(rel),
			})
			return nil
		})

		sort.Slice(notes, func(i, j int) bool { return notes[i].Title < notes[j].Title })
		if notes == nil {
			notes = []Note{}
		}
		json.NewEncoder(w).Encode(notes)
	}
}

func handleGet(vaultPath string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		abs, err := vaultRelPath(vaultPath, r.PathValue("path"))
		if err != nil {
			http.Error(w, "Note not found", http.StatusNotFound)
			return
		}
		data, err := os.ReadFile(abs)
		if err != nil {
			http.Error(w, "Note not found", http.StatusNotFound)
			return
		}

		rel, _ := filepath.Rel(vaultPath, abs)
		note := Note{
			ID:    strings.TrimSuffix(filepath.ToSlash(rel), ".md"),
			Title: strings.TrimSuffix(filepath.Base(rel), ".md"),
			Path:  filepath.ToSlash(rel),
		}
		inFrontmatter := false
		for _, line := range strings.Split(string(data), "\n") {
			line = strings.TrimSpace(line)
			if strings.HasPrefix(line, "---") {
				inFrontmatter = !inFrontmatter
				continue
			}
			if inFrontmatter || line == "" || strings.HasPrefix(line, "#") {
				continue
			}
			note.Snippet = line
			break
		}
		json.NewEncoder(w).Encode(note)
	}
}
