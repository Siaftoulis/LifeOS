package transfer

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"
)

func handleChunk(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	if err := r.ParseMultipartForm(maxChunkSize + 1<<20); err != nil {
		http.Error(w, "Failed to parse form", http.StatusBadRequest)
		return
	}

	transferID := r.FormValue("transfer_id")
	chunkIndexStr := r.FormValue("chunk_index")
	offsetStr := r.FormValue("offset")
	lengthStr := r.FormValue("length")
	hash := r.FormValue("hash")

	if transferID == "" || chunkIndexStr == "" || offsetStr == "" || lengthStr == "" {
		http.Error(w, "Missing required fields", http.StatusBadRequest)
		return
	}

	chunkIndex, _ := strconv.Atoi(chunkIndexStr)
	offset, _ := strconv.ParseInt(offsetStr, 10, 64)
	length, _ := strconv.Atoi(lengthStr)

	if length > maxChunkSize {
		http.Error(w, "Chunk too large", http.StatusBadRequest)
		return
	}

	file, _, err := r.FormFile("chunk")
	if err != nil {
		http.Error(w, "Missing chunk file", http.StatusBadRequest)
		return
	}
	defer file.Close()

	data, err := io.ReadAll(file)
	if err != nil {
		http.Error(w, "Failed to read chunk", http.StatusInternalServerError)
		return
	}

	if int64(len(data)) != offset && len(data) != length {
		if int64(len(data)) != offset && int64(len(data)) != int64(length) {
			log.Printf("Chunk size mismatch: expected %d, got %d", length, len(data))
		}
	}

	computedHash := hashBytes(data)
	if hash != "" && computedHash != hash {
		log.Printf("Chunk %d hash mismatch: expected %s, got %s", chunkIndex, hash, computedHash)
		respondChunk(w, false, false, "Hash mismatch")
		return
	}

	var transferExists bool
	err = DB.QueryRow(`SELECT 1 FROM transfers WHERE transfer_id = ?`, transferID).Scan(&transferExists)
	if err == sql.ErrNoRows {
		respondChunk(w, false, false, "Transfer not found")
		return
	}

	chunkPath := filepath.Join(dataDir, transferID, fmt.Sprintf("chunk_%d", chunkIndex))
	out, err := os.Create(chunkPath)
	if err != nil {
		log.Printf("Failed to create chunk file: %v", err)
		respondChunk(w, false, false, "Failed to save chunk")
		return
	}
	_, err = out.Write(data)
	out.Close()
	if err != nil {
		respondChunk(w, false, false, "Failed to write chunk")
		return
	}

	now := time.Now().UnixMilli()
	_, err = DB.Exec(
		`UPDATE transfer_chunks SET state = 'UPLOADED', filepath = ?, hash = ?, uploaded_at = ?, retry_count = retry_count + 1 WHERE transfer_id = ? AND chunk_index = ?`,
		chunkPath, computedHash, now, transferID, chunkIndex,
	)
	if err != nil {
		log.Printf("Failed to update chunk: %v", err)
	}

	receivedChunks := getReceivedChunks(transferID)
	_, _ = DB.Exec(
		`UPDATE transfers SET received_chunks = ?, updated_at = ? WHERE transfer_id = ?`,
		toJSON(receivedChunks), now, transferID,
	)

	verified := false
	if hash != "" && computedHash == hash {
		verified = true
		verifiedChunks := getVerifiedChunks(transferID)
		found := false
		for _, v := range verifiedChunks {
			if v == chunkIndex {
				found = true
				break
			}
		}
		if !found {
			verifiedChunks = append(verifiedChunks, chunkIndex)
			_, _ = DB.Exec(
				`UPDATE transfer_chunks SET state = 'VERIFIED', verified_at = ? WHERE transfer_id = ? AND chunk_index = ?`,
				now, transferID, chunkIndex,
			)
			_, _ = DB.Exec(
				`UPDATE transfers SET verified_chunks = ?, updated_at = ? WHERE transfer_id = ?`,
				toJSON(verifiedChunks), now, transferID,
			)
		}
	}

	respondChunk(w, true, verified, "")
}

func respondChunk(w http.ResponseWriter, success, verified bool, errMsg string) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(chunkResponse{
		Success:  success,
		Verified: verified,
		Error:    errMsg,
	})
}

func handleStream(w http.ResponseWriter, r *http.Request) {
	transferID := r.URL.Query().Get("transfer_id")
	if transferID == "" {
		http.Error(w, "Missing transfer_id", http.StatusBadRequest)
		return
	}

	var filepath string
	err := DB.QueryRow(`SELECT filepath FROM transfers WHERE transfer_id = ? AND state = 'COMPLETED'`, transferID).Scan(&filepath)
	if err == sql.ErrNoRows {
		http.Error(w, "Transfer not found or not completed", http.StatusNotFound)
		return
	}
	if err != nil {
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	http.ServeFile(w, r, filepath)
}
