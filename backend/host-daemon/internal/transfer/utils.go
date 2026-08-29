package transfer

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"io"
	"os"
)

func hashBytes(data []byte) string {
	sum := sha256.Sum256(data)
	return hex.EncodeToString(sum[:])
}

func hashFile(path string) string {
	file, err := os.Open(path)
	if err != nil {
		return ""
	}
	defer file.Close()

	hasher := sha256.New()
	io.Copy(hasher, file)
	return hex.EncodeToString(hasher.Sum(nil))
}

func getReceivedChunks(transferID string) []int {
	var jsonStr string
	err := DB.QueryRow(`SELECT received_chunks FROM transfers WHERE transfer_id = ?`, transferID).Scan(&jsonStr)
	if err != nil {
		return []int{}
	}
	return fromJSON(jsonStr)
}

func getVerifiedChunks(transferID string) []int {
	var jsonStr string
	err := DB.QueryRow(`SELECT verified_chunks FROM transfers WHERE transfer_id = ?`, transferID).Scan(&jsonStr)
	if err != nil {
		return []int{}
	}
	return fromJSON(jsonStr)
}

func clamp(v, min, max int) int {
	if v < min {
		return min
	}
	if v > max {
		return max
	}
	return v
}

func calculateChunkSize(fileSize int64, preferred int, networkQuality int) int {
	chunkSize := preferred
	if chunkSize <= 0 {
		chunkSize = defaultChunkSize
	}

	if fileSize <= 1<<20 {
		chunkSize = int(fileSize)
	} else if fileSize <= 10<<20 {
		chunkSize = clamp(chunkSize/2, minChunkSize, maxChunkSize)
	} else if fileSize <= 100<<20 {
		chunkSize = clamp(chunkSize, minChunkSize, maxChunkSize)
	} else {
		chunkSize = clamp(chunkSize*2, minChunkSize, maxChunkSize)
	}

	return chunkSize
}

func toJSON(v any) string {
	b, _ := json.Marshal(v)
	return string(b)
}

func fromJSON(s string) []int {
	if s == "" {
		return []int{}
	}
	var out []int
	json.Unmarshal([]byte(s), &out)
	return out
}
