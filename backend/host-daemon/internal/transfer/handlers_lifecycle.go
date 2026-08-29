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
	"time"

	"github.com/google/uuid"
)

func handleInit(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req initRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	if req.FileID == "" || req.Filename == "" || req.FileSize <= 0 || req.FileHash == "" {
		http.Error(w, "Missing required fields", http.StatusBadRequest)
		return
	}

	chunkSize := req.ChunkSize
	if chunkSize <= 0 {
		chunkSize = calculateChunkSize(req.FileSize, chunkSize, 0)
	}
	chunkSize = clamp(chunkSize, minChunkSize, maxChunkSize)

	totalChunks := int((req.FileSize + int64(chunkSize) - 1) / int64(chunkSize))
	if totalChunks > 10000 {
		http.Error(w, "Too many chunks (max 10000)", http.StatusBadRequest)
		return
	}

	transferID := uuid.New().String()
	now := time.Now().UnixMilli()

	transferDir := filepath.Join(dataDir, transferID)
	if err := os.MkdirAll(transferDir, 0755); err != nil {
		http.Error(w, "Failed to create transfer directory", http.StatusInternalServerError)
		return
	}

	chunksJSON, _ := json.Marshal([]int{})
	verifiedJSON, _ := json.Marshal([]int{})

	_, err := DB.Exec(
		`INSERT INTO transfers (transfer_id, file_id, filename, file_size, file_hash, chunk_size, total_chunks, received_chunks, verified_chunks, state, mime_type, metadata, filepath, created_at, updated_at)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'PREPARING', ?, ?, ?, ?, ?)`,
		transferID, req.FileID, req.Filename, req.FileSize, req.FileHash, chunkSize, totalChunks,
		string(chunksJSON), string(verifiedJSON), req.MimeType, toJSON(req.Metadata), transferDir, now, now,
	)
	if err != nil {
		log.Printf("Failed to insert transfer: %v", err)
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	for i := 0; i < totalChunks; i++ {
		offset := int64(i) * int64(chunkSize)
		length := chunkSize
		if offset+int64(length) > req.FileSize {
			length = int(req.FileSize - offset)
		}
		_, err := DB.Exec(
			`INSERT INTO transfer_chunks (transfer_id, chunk_index, offset, length, hash, state) VALUES (?, ?, ?, ?, '', 'PENDING')`,
			transferID, i, offset, length,
		)
		if err != nil {
			log.Printf("Failed to insert chunk %d: %v", i, err)
		}
	}

	_, _ = DB.Exec(`UPDATE transfers SET state = 'TRANSFERRING', updated_at = ? WHERE transfer_id = ?`, time.Now().UnixMilli(), transferID)

	resp := initResponse{
		TransferID:      transferID,
		ChunkSize:       chunkSize,
		TotalChunks:     totalChunks,
		MissingChunks:   []int{},
		ProtocolVersion: protocolVersion,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

func handleStatus(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost && r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	transferID := r.URL.Query().Get("transfer_id")
	if transferID == "" {
		var req statusRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err == nil {
			transferID = req.TransferID
		}
	}

	if transferID == "" {
		http.Error(w, "Missing transfer_id", http.StatusBadRequest)
		return
	}

	var state, fileHash string
	var totalChunks int
	var receivedJSON, verifiedJSON string
	err := DB.QueryRow(
		`SELECT state, total_chunks, received_chunks, verified_chunks, file_hash FROM transfers WHERE transfer_id = ?`,
		transferID,
	).Scan(&state, &totalChunks, &receivedJSON, &verifiedJSON, &fileHash)

	if err == sql.ErrNoRows {
		http.Error(w, "Transfer not found", http.StatusNotFound)
		return
	}
	if err != nil {
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	received := fromJSON(receivedJSON)
	verified := fromJSON(verifiedJSON)

	allIndices := make([]int, totalChunks)
	for i := 0; i < totalChunks; i++ {
		allIndices[i] = i
	}

	missing := []int{}
	receivedSet := make(map[int]bool)
	for _, rec := range received {
		receivedSet[rec] = true
	}
	for _, idx := range allIndices {
		if !receivedSet[idx] {
			missing = append(missing, idx)
		}
	}

	resp := statusResponse{
		TransferID:     transferID,
		State:          state,
		TotalChunks:    totalChunks,
		ReceivedChunks: received,
		MissingChunks:  missing,
		VerifiedChunks: verified,
		FileHash:       fileHash,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

func handleResume(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req resumeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	if req.TransferID == "" {
		http.Error(w, "Missing transfer_id", http.StatusBadRequest)
		return
	}

	var chunkSize, totalChunks int
	var state string
	err := DB.QueryRow(
		`SELECT chunk_size, total_chunks, state FROM transfers WHERE transfer_id = ?`,
		req.TransferID,
	).Scan(&chunkSize, &totalChunks, &state)
	if err == sql.ErrNoRows {
		http.Error(w, "Transfer not found", http.StatusNotFound)
		return
	}
	if err != nil {
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	if state == "COMPLETED" {
		http.Error(w, "Transfer already completed", http.StatusConflict)
		return
	}

	received := getReceivedChunks(req.TransferID)
	missing := []int{}
	receivedSet := make(map[int]bool)
	for _, rec := range received {
		receivedSet[rec] = true
	}
	for i := 0; i < totalChunks; i++ {
		if !receivedSet[i] {
			missing = append(missing, i)
		}
	}

	_, _ = DB.Exec(
		`UPDATE transfers SET state = 'TRANSFERRING', updated_at = ? WHERE transfer_id = ?`,
		time.Now().UnixMilli(), req.TransferID,
	)

	resp := resumeResponse{
		TransferID:      req.TransferID,
		ChunkSize:       chunkSize,
		TotalChunks:     totalChunks,
		MissingChunks:   missing,
		ProtocolVersion: protocolVersion,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

func handleVerify(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req verifyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	if req.TransferID == "" || req.ExpectedHash == "" {
		http.Error(w, "Missing required fields", http.StatusBadRequest)
		return
	}

	var transferDir, fileHash string
	var fileSize int64
	var totalChunks int
	err := DB.QueryRow(
		`SELECT filepath, file_size, file_hash, total_chunks FROM transfers WHERE transfer_id = ?`,
		req.TransferID,
	).Scan(&transferDir, &fileSize, &fileHash, &totalChunks)
	if err == sql.ErrNoRows {
		respondVerify(w, false, false, "", "Transfer not found")
		return
	}
	if err != nil {
		respondVerify(w, false, false, "", "Database error")
		return
	}

	verifiedChunks := getVerifiedChunks(req.TransferID)
	if len(verifiedChunks) != totalChunks {
		respondVerify(w, false, false, "", fmt.Sprintf("Not all chunks verified: %d/%d", len(verifiedChunks), totalChunks))
		return
	}

	finalPath := transferDir + "_final"
	out, err := os.Create(finalPath)
	if err != nil {
		respondVerify(w, false, false, "", "Failed to create final file")
		return
	}

	for i := 0; i < totalChunks; i++ {
		chunkPath := transferDir + fmt.Sprintf("/chunk_%d", i)
		chunkFile, err := os.Open(chunkPath)
		if err != nil {
			out.Close()
			os.Remove(finalPath)
			respondVerify(w, false, false, "", fmt.Sprintf("Missing chunk %d", i))
			return
		}
		_, err = io.Copy(out, chunkFile)
		chunkFile.Close()
		if err != nil {
			out.Close()
			os.Remove(finalPath)
			respondVerify(w, false, false, "", "Failed to assemble file")
			return
		}
	}
	out.Close()

	finalHash := hashFile(finalPath)
	hashesMatch := finalHash == req.ExpectedHash

	if !hashesMatch {
		os.Remove(finalPath)
		respondVerify(w, false, false, finalHash, "Final hash mismatch")
		return
	}

	finalName := filepath.Base(transferDir)
	finalDir := filepath.Dir(transferDir)
	finalFilePath := filepath.Join(finalDir, finalName)
	os.Rename(finalPath, finalFilePath)

	_, _ = DB.Exec(
		`UPDATE transfers SET state = 'VERIFIED', filepath = ?, updated_at = ? WHERE transfer_id = ?`,
		finalFilePath, time.Now().UnixMilli(), req.TransferID,
	)

	respondVerify(w, true, true, finalHash, "")
}

func respondVerify(w http.ResponseWriter, success, hashesMatch bool, actualHash, errMsg string) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(verifyResponse{
		Success:     success,
		HashesMatch: hashesMatch,
		ActualHash:  actualHash,
		Error:       errMsg,
	})
}

func handleComplete(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req completeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	var state, filepath string
	err := DB.QueryRow(`SELECT state, filepath FROM transfers WHERE transfer_id = ?`, req.TransferID).Scan(&state, &filepath)
	if err == sql.ErrNoRows {
		http.Error(w, "Transfer not found", http.StatusNotFound)
		return
	}

	if state != "VERIFIED" {
		respondComplete(w, false, "", "Transfer not verified")
		return
	}

	_, _ = DB.Exec(`UPDATE transfers SET state = 'COMPLETED', updated_at = ? WHERE transfer_id = ?`, time.Now().UnixMilli(), req.TransferID)

	respondComplete(w, true, filepath, "")
}

func respondComplete(w http.ResponseWriter, success bool, filePath, errMsg string) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(completeResponse{Success: success, FilePath: filePath, Error: errMsg})
}

func handleCancel(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req cancelRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	if req.TransferID == "" {
		http.Error(w, "Missing transfer_id", http.StatusBadRequest)
		return
	}

	_, _ = DB.Exec(`UPDATE transfers SET state = 'CANCELLED', updated_at = ? WHERE transfer_id = ?`, time.Now().UnixMilli(), req.TransferID)

	transferDir := filepath.Join(dataDir, req.TransferID)
	os.RemoveAll(transferDir)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{"success": true, "transfer_id": req.TransferID})
}
