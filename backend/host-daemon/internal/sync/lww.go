package sync

import (
	"log"
)

// ResolveLWWConflict applies the Last-Write-Wins (LWW) mutation comparison algorithm
// with millisecond timestamp verification.
func ResolveLWWConflict(localRecord, remoteRecord map[string]any) (map[string]any, bool) {
	if localRecord == nil {
		return remoteRecord, true
	}
	if remoteRecord == nil {
		return localRecord, false
	}

	// Millisecond timestamp verification
	var localTs, remoteTs float64

	if val, ok := localRecord["updated_at"].(float64); ok {
		localTs = val
	}
	if val, ok := remoteRecord["updated_at"].(float64); ok {
		remoteTs = val
	}

	if remoteTs > localTs {
		log.Printf("LWW: Remote mutation wins (remote: %v > local: %v)", remoteTs, localTs)
		return remoteRecord, true
	}

	log.Printf("LWW: Local mutation wins or equal (local: %v >= remote: %v)", localTs, remoteTs)
	return localRecord, false
}
