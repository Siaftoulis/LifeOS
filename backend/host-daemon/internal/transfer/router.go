package transfer

import (
	"net/http"
)

// RegisterRoutes registers all transfer protocol endpoints.
// Handlers and models have been modularized into:
// - models.go: Request/response types and constants
// - utils.go: Hashing, chunk calculation, and DB array parsing
// - handlers_chunk.go: Chunk upload and streaming handlers
// - handlers_lifecycle.go: Transfer init, status, resume, verify, complete, cancel handlers
func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/transfer/init", handleInit)
	mux.HandleFunc("/api/v1/transfer/chunk", handleChunk)
	mux.HandleFunc("/api/v1/transfer/status", handleStatus)
	mux.HandleFunc("/api/v1/transfer/resume", handleResume)
	mux.HandleFunc("/api/v1/transfer/verify", handleVerify)
	mux.HandleFunc("/api/v1/transfer/complete", handleComplete)
	mux.HandleFunc("/api/v1/transfer/cancel", handleCancel)
	mux.HandleFunc("/api/v1/transfer/stream", handleStream)
}