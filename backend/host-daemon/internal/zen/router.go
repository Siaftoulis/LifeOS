package zen

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"strings"
	"time"
)

type nodePush struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Path        string `json:"path"`
	IsDirectory int    `json:"is_directory"`
	ParentID    string `json:"parent_id"`
	CreatedAt   int64  `json:"created_at"`
	UpdatedAt   int64  `json:"updated_at"`
}

type docPush struct {
	ID        string `json:"id"`
	NodeID    string `json:"node_id"`
	Text      string `json:"text_content"`
	UpdatedAt int64  `json:"updated_at"`
}

type syncRequest struct {
	PushNodes     []nodePush `json:"push_nodes"`
	PushDocuments []docPush  `json:"push_documents"`
	DeletePaths   []string   `json:"delete_paths"`
	Since         int64      `json:"since"`
}

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/zen/sync", handleSync)
	mux.HandleFunc("/api/v1/zen/fs/list", handleFSList)
	mux.HandleFunc("/api/v1/zen/fs/write", handleFSWrite)
	mux.HandleFunc("/api/v1/zen/fs/mkdir", handleFSMkdir)
	mux.HandleFunc("/api/v1/zen/fs/delete", handleFSDelete)
	mux.HandleFunc("/api/v1/zen/fs/rename", handleFSRename)
	mux.HandleFunc("/api/v1/zen/fs/copy", handleFSCopy)
}

// The web client has no local disk: these endpoints make zen.db the server's
// source of truth so web can create/rename/move/delete folders, files and
// workspaces exactly like native devices. Paths are relative, '/'-separated,
// and never escape the vault tree. Tombstones are recorded so native clients
// prune the same rows via /sync.
func cleanPath(p string) (string, error) {
	p = strings.Trim(p, "/")
	if p == "" {
		return "", errors.New("empty path")
	}
	for _, seg := range strings.Split(p, "/") {
		if seg == "" || seg == "." || seg == ".." || strings.ContainsAny(seg, "\\:") {
			return "", errors.New("bad path segment")
		}
	}
	return p, nil
}

func newZenID() string {
	b := make([]byte, 16)
	rand.Read(b)
	return hex.EncodeToString(b)
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(v)
}

func writeErr(w http.ResponseWriter, status int, msg string) {
	http.Error(w, msg, status)
}

// GET /api/v1/zen/fs/list?path=... → {nodes, documents} for the vault
// (optionally a subtree). documents are keyed by node path so the web cache
// can rebuild the whole tree in one round-trip.
func handleFSList(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeErr(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	if DB == nil {
		writeErr(w, http.StatusInternalServerError, "Zen DB not initialized")
		return
	}
	prefix := ""
	if raw := r.URL.Query().Get("path"); raw != "" {
		p, err := cleanPath(raw)
		if err != nil {
			writeErr(w, http.StatusBadRequest, err.Error())
			return
		}
		prefix = p
	}

	nodes := []map[string]any{}
	rows, err := DB.Query(
		`SELECT id, name, path, is_directory, parent_id, created_at, updated_at
		 FROM zen_nodes
		 WHERE ? = '' OR path = ? OR substr(path, 1, length(?) + 1) = ? || '/'
		 ORDER BY path`, prefix, prefix, prefix, prefix)
	if err != nil {
		writeErr(w, http.StatusInternalServerError, "Query failed")
		return
	}
	for rows.Next() {
		var n nodePush
		if err := rows.Scan(&n.ID, &n.Name, &n.Path, &n.IsDirectory, &n.ParentID, &n.CreatedAt, &n.UpdatedAt); err == nil {
			nodes = append(nodes, map[string]any{
				"id": n.ID, "name": n.Name, "path": n.Path,
				"is_directory": n.IsDirectory, "parent_id": n.ParentID,
				"created_at": n.CreatedAt, "updated_at": n.UpdatedAt,
			})
		}
	}
	rows.Close()

	docs := []map[string]any{}
	rows, err = DB.Query(
		`SELECT n.path, d.text_content FROM zen_documents d
		 JOIN zen_nodes n ON n.id = d.node_id
		 WHERE ? = '' OR n.path = ? OR substr(n.path, 1, length(?) + 1) = ? || '/'`,
		prefix, prefix, prefix, prefix)
	if err == nil {
		for rows.Next() {
			var path, text string
			if rows.Scan(&path, &text) == nil {
				docs = append(docs, map[string]any{"path": path, "text_content": text})
			}
		}
		rows.Close()
	}

	writeJSON(w, map[string]any{"nodes": nodes, "documents": docs})
}

type fsPathReq struct {
	Path string `json:"path"`
}

type fsWriteReq struct {
	Path    string `json:"path"`
	Content string `json:"content"`
}

type fsMoveReq struct {
	From string `json:"from"`
	To   string `json:"to"`
}

func upsertNode(p string, isDir int, now int64) {
	name := p
	if i := strings.LastIndex(p, "/"); i >= 0 {
		name = p[i+1:]
	}
	if _, err := DB.Exec(
		`INSERT INTO zen_nodes(id, name, path, is_directory, parent_id, created_at, updated_at)
		 VALUES(?, ?, ?, ?, '', ?, ?)
		 ON CONFLICT(path) DO UPDATE SET
		   name=excluded.name, updated_at=excluded.updated_at`, newZenID(), name, p, isDir, now, now,
	); err != nil {
		log.Printf("zen fs upsert node %s: %v", p, err)
	}
}

// POST /api/v1/zen/fs/write {"path","content"} — create or overwrite a file.
func handleFSWrite(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeErr(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	var req fsWriteReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeErr(w, http.StatusBadRequest, "Bad request")
		return
	}
	p, err := cleanPath(req.Path)
	if err != nil {
		writeErr(w, http.StatusBadRequest, err.Error())
		return
	}
	if DB == nil {
		writeErr(w, http.StatusInternalServerError, "Zen DB not initialized")
		return
	}
	now := time.Now().UnixMilli()
	upsertNode(p, 0, now)

	var id string
	if err := DB.QueryRow(`SELECT id FROM zen_nodes WHERE path = ?`, p).Scan(&id); err != nil {
		writeErr(w, http.StatusInternalServerError, "node lookup failed")
		return
	}
	if _, err := DB.Exec(
		`INSERT INTO zen_documents(id, node_id, text_content, updated_at)
		 VALUES(?, ?, ?, ?)
		 ON CONFLICT(id) DO UPDATE SET
		   text_content=excluded.text_content, updated_at=excluded.updated_at`,
		newZenID(), id, req.Content, now,
	); err != nil {
		writeErr(w, http.StatusInternalServerError, "doc write failed")
		return
	}
	writeJSON(w, map[string]any{"ok": true})
}

// POST /api/v1/zen/fs/mkdir {"path"} — idempotent.
func handleFSMkdir(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeErr(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	var req fsPathReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeErr(w, http.StatusBadRequest, "Bad request")
		return
	}
	p, err := cleanPath(req.Path)
	if err != nil {
		writeErr(w, http.StatusBadRequest, err.Error())
		return
	}
	if DB == nil {
		writeErr(w, http.StatusInternalServerError, "Zen DB not initialized")
		return
	}
	now := time.Now().UnixMilli()
	upsertNode(p, 1, now)
	writeJSON(w, map[string]any{"ok": true})
}

// POST /api/v1/zen/fs/delete {"path"} — recursive; tombstones the root.
func handleFSDelete(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeErr(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	var req fsPathReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeErr(w, http.StatusBadRequest, "Bad request")
		return
	}
	p, err := cleanPath(req.Path)
	if err != nil {
		writeErr(w, http.StatusBadRequest, err.Error())
		return
	}
	if DB == nil {
		writeErr(w, http.StatusInternalServerError, "Zen DB not initialized")
		return
	}
	if _, err := DB.Exec(
		`DELETE FROM zen_documents WHERE node_id IN (
			SELECT id FROM zen_nodes
			WHERE path = ? OR substr(path, 1, length(?) + 1) = ? || '/')`,
		p, p, p,
	); err != nil {
		writeErr(w, http.StatusInternalServerError, "delete docs failed")
		return
	}
	if _, err := DB.Exec(
		`DELETE FROM zen_nodes WHERE path = ? OR substr(path, 1, length(?) + 1) = ? || '/'`,
		p, p, p,
	); err != nil {
		writeErr(w, http.StatusInternalServerError, "delete nodes failed")
		return
	}
	now := time.Now().UnixMilli()
	DB.Exec(`INSERT OR REPLACE INTO zen_tombstones(path, at) VALUES(?, ?)`, p, now)
	writeJSON(w, map[string]any{"ok": true})
}

// POST /api/v1/zen/fs/rename {"from","to"} — file rename or folder move.
func handleFSRename(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeErr(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	var req fsMoveReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeErr(w, http.StatusBadRequest, "Bad request")
		return
	}
	from, err := cleanPath(req.From)
	if err != nil {
		writeErr(w, http.StatusBadRequest, err.Error())
		return
	}
	to, err := cleanPath(req.To)
	if err != nil {
		writeErr(w, http.StatusBadRequest, err.Error())
		return
	}
	if DB == nil {
		writeErr(w, http.StatusInternalServerError, "Zen DB not initialized")
		return
	}
	var exists int
	if err := DB.QueryRow(`SELECT 1 FROM zen_nodes WHERE path = ?`, to).Scan(&exists); err == nil {
		writeErr(w, http.StatusConflict, "target path already exists")
		return
	}
	now := time.Now().UnixMilli()

	name := to
	if i := strings.LastIndex(to, "/"); i >= 0 {
		name = to[i+1:]
	}
	if _, err := DB.Exec(
		`UPDATE zen_nodes SET path = ?, name = ?, updated_at = ? WHERE path = ?`,
		to, name, now, from,
	); err != nil {
		writeErr(w, http.StatusInternalServerError, "rename failed")
		return
	}
	if _, err := DB.Exec(
		`UPDATE zen_nodes SET path = ? || substr(path, length(?) + 1), updated_at = ?
		 WHERE substr(path, 1, length(?) + 1) = ? || '/'`,
		to, from, now, from, from,
	); err != nil {
		writeErr(w, http.StatusInternalServerError, "rename children failed")
		return
	}
	DB.Exec(`INSERT OR REPLACE INTO zen_tombstones(path, at) VALUES(?, ?)`, from, now)
	writeJSON(w, map[string]any{"ok": true})
}

// POST /api/v1/zen/fs/copy {"from","to"} — duplicate a file or folder subtree.
func handleFSCopy(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeErr(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	var req fsMoveReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeErr(w, http.StatusBadRequest, "Bad request")
		return
	}
	from, err := cleanPath(req.From)
	if err != nil {
		writeErr(w, http.StatusBadRequest, err.Error())
		return
	}
	to, err := cleanPath(req.To)
	if err != nil {
		writeErr(w, http.StatusBadRequest, err.Error())
		return
	}
	if DB == nil {
		writeErr(w, http.StatusInternalServerError, "Zen DB not initialized")
		return
	}
	now := time.Now().UnixMilli()

	type row struct {
		id, name, path string
		isDir          int
	}
	rows, err := DB.Query(
		`SELECT id, name, path, is_directory FROM zen_nodes
		 WHERE path = ? OR substr(path, 1, length(?) + 1) = ? || '/'`, from, from, from)
	if err != nil {
		writeErr(w, http.StatusInternalServerError, "copy read failed")
		return
	}
	var src []row
	for rows.Next() {
		var n row
		if rows.Scan(&n.id, &n.name, &n.path, &n.isDir) == nil {
			src = append(src, n)
		}
	}
	rows.Close()
	if len(src) == 0 {
		writeErr(w, http.StatusNotFound, "source not found")
		return
	}

	oldToNew := map[string]string{}
	for _, n := range src {
		newPath := to + strings.TrimPrefix(n.path, from)
		oldToNew[n.id] = newPath
		newID := newZenID()
		if _, err := DB.Exec(
			`INSERT INTO zen_nodes(id, name, path, is_directory, parent_id, created_at, updated_at)
			 VALUES(?, ?, ?, ?, '', ?, ?)`,
			newID, n.name, newPath, n.isDir, now, now,
		); err != nil {
			log.Printf("zen fs copy node %s: %v", newPath, err)
			continue
		}
		// clone the doc (single node per copy target)
		var content string
		if err := DB.QueryRow(`SELECT text_content FROM zen_documents WHERE node_id = ?`, n.id).Scan(&content); err == nil {
			DB.Exec(`INSERT INTO zen_documents(id, node_id, text_content, updated_at) VALUES(?, ?, ?, ?)`,
				newZenID(), newID, content, now)
		}
	}
	writeJSON(w, map[string]any{"ok": true})
}

// handleSync is a single push+pull endpoint: client uploads its dirty rows
// (last-write-wins by updated_at) and deletions, and gets back everything the
// server has that changed after `since`. Path is the identity for tombstones.
func handleSync(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var req syncRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Bad request", http.StatusBadRequest)
		return
	}
	if DB == nil {
		http.Error(w, "Zen DB not initialized", http.StatusInternalServerError)
		return
	}

	now := time.Now().UnixMilli()

	// 1. Deletions first: remove rows (and children of dirs), record tombstones.
	for _, p := range req.DeletePaths {
		if p == "" {
			continue
		}
		// ponytail: substr() match instead of LIKE so % in names can't wildcard.
		_, err := DB.Exec(
			`DELETE FROM zen_documents WHERE node_id IN (
				SELECT id FROM zen_nodes
				WHERE path = ? OR substr(path, 1, length(?) + 1) = ? || '/')`,
			p, p, p,
		)
		if err != nil {
			log.Printf("zen delete docs %s: %v", p, err)
			continue
		}
		if _, err := DB.Exec(
			`DELETE FROM zen_nodes WHERE path = ? OR substr(path, 1, length(?) + 1) = ? || '/'`,
			p, p, p,
		); err != nil {
			log.Printf("zen delete nodes %s: %v", p, err)
			continue
		}
		if _, err := DB.Exec(
			`INSERT OR REPLACE INTO zen_tombstones(path, at) VALUES(?, ?)`, p, now,
		); err != nil {
			log.Printf("zen tombstone %s: %v", p, err)
		}
	}

	// 2. Upsert pushed nodes/docs, keeping the newer copy on conflict.
	for _, n := range req.PushNodes {
		if n.ID == "" || n.Path == "" {
			continue
		}
		var old int64
		err := DB.QueryRow(`SELECT updated_at FROM zen_nodes WHERE id = ?`, n.ID).Scan(&old)
		if err == nil && old > n.UpdatedAt {
			continue // server copy is newer
		}
		if _, err := DB.Exec(
			`INSERT INTO zen_nodes(id, name, path, is_directory, parent_id, created_at, updated_at)
			 VALUES(?, ?, ?, ?, ?, ?, ?)
			 ON CONFLICT(id) DO UPDATE SET
			   name=excluded.name, path=excluded.path, is_directory=excluded.is_directory,
			   parent_id=excluded.parent_id, updated_at=excluded.updated_at`,
			n.ID, n.Name, n.Path, n.IsDirectory, n.ParentID, n.CreatedAt, n.UpdatedAt,
		); err != nil {
			log.Printf("zen upsert node %s: %v", n.Path, err)
		}
	}

	for _, d := range req.PushDocuments {
		if d.ID == "" || d.NodeID == "" {
			continue
		}
		var old int64
		err := DB.QueryRow(`SELECT updated_at FROM zen_documents WHERE id = ?`, d.ID).Scan(&old)
		if err == nil && old > d.UpdatedAt {
			continue
		}
		if _, err := DB.Exec(
			`INSERT INTO zen_documents(id, node_id, text_content, updated_at)
			 VALUES(?, ?, ?, ?)
			 ON CONFLICT(id) DO UPDATE SET
			   node_id=excluded.node_id, text_content=excluded.text_content, updated_at=excluded.updated_at`,
			d.ID, d.NodeID, d.Text, d.UpdatedAt,
		); err != nil {
			log.Printf("zen upsert doc %s: %v", d.NodeID, err)
		}
	}

	// 3. Pull: everything changed after since.
	nodes := []map[string]any{}
	rows, err := DB.Query(
		`SELECT id, name, path, is_directory, parent_id, created_at, updated_at
		 FROM zen_nodes WHERE updated_at > ? ORDER BY updated_at`, req.Since)
	if err != nil {
		http.Error(w, "Query failed", http.StatusInternalServerError)
		return
	}
	for rows.Next() {
		var n nodePush
		if err := rows.Scan(&n.ID, &n.Name, &n.Path, &n.IsDirectory, &n.ParentID, &n.CreatedAt, &n.UpdatedAt); err == nil {
			nodes = append(nodes, map[string]any{
				"id": n.ID, "name": n.Name, "path": n.Path,
				"is_directory": n.IsDirectory, "parent_id": n.ParentID,
				"created_at": n.CreatedAt, "updated_at": n.UpdatedAt,
			})
		}
	}
	rows.Close()

	docs := []map[string]any{}
	rows, err = DB.Query(
		`SELECT id, node_id, text_content, updated_at FROM zen_documents WHERE updated_at > ? ORDER BY updated_at`,
		req.Since)
	if err != nil {
		http.Error(w, "Query failed", http.StatusInternalServerError)
		return
	}
	for rows.Next() {
		var d docPush
		if err := rows.Scan(&d.ID, &d.NodeID, &d.Text, &d.UpdatedAt); err == nil {
			docs = append(docs, map[string]any{
				"id": d.ID, "node_id": d.NodeID, "text_content": d.Text, "updated_at": d.UpdatedAt,
			})
		}
	}
	rows.Close()

	tombstones := []string{}
	rows, err = DB.Query(`SELECT path FROM zen_tombstones WHERE at > ?`, req.Since)
	if err == nil {
		for rows.Next() {
			var p string
			if rows.Scan(&p) == nil {
				tombstones = append(tombstones, p)
			}
		}
		rows.Close()
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"nodes":         nodes,
		"documents":     docs,
		"deleted_paths": tombstones,
	})
}
