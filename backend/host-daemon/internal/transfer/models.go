package transfer

const (
	protocolVersion  = 1
	maxChunkSize     = 64 << 20
	minChunkSize     = 64 << 10
	defaultChunkSize = 4 << 20
	dataDir          = "./data/transfers"
)

type initRequest struct {
	FileID    string         `json:"file_id"`
	Filename  string         `json:"filename"`
	FileSize  int64          `json:"file_size"`
	FileHash  string         `json:"file_hash"`
	ChunkSize int            `json:"chunk_size"`
	MimeType  string         `json:"mime_type,omitempty"`
	Metadata  map[string]any `json:"metadata,omitempty"`
}

type initResponse struct {
	TransferID      string `json:"transfer_id"`
	ChunkSize       int    `json:"chunk_size"`
	TotalChunks     int    `json:"total_chunks"`
	MissingChunks   []int  `json:"missing_chunks"`
	ProtocolVersion int    `json:"protocol_version"`
}

type chunkRequest struct {
	TransferID string `json:"transfer_id"`
	ChunkIndex int    `json:"chunk_index"`
	Offset     int64  `json:"offset"`
	Length     int    `json:"length"`
	Hash       string `json:"hash"`
}

type chunkResponse struct {
	Success  bool   `json:"success"`
	Verified bool   `json:"verified"`
	Error    string `json:"error,omitempty"`
}

type statusRequest struct {
	TransferID string `json:"transfer_id"`
}

type statusResponse struct {
	TransferID     string `json:"transfer_id"`
	State          string `json:"state"`
	TotalChunks    int    `json:"total_chunks"`
	ReceivedChunks []int  `json:"received_chunks"`
	MissingChunks  []int  `json:"missing_chunks"`
	VerifiedChunks []int  `json:"verified_chunks"`
	FileHash       string `json:"file_hash,omitempty"`
	Error          string `json:"error,omitempty"`
}

type resumeRequest struct {
	TransferID string `json:"transfer_id"`
}

type resumeResponse struct {
	TransferID      string `json:"transfer_id"`
	ChunkSize       int    `json:"chunk_size"`
	TotalChunks     int    `json:"total_chunks"`
	MissingChunks   []int  `json:"missing_chunks"`
	ProtocolVersion int    `json:"protocol_version"`
}

type verifyRequest struct {
	TransferID       string `json:"transfer_id"`
	ExpectedHash     string `json:"expected_hash"`
}

type verifyResponse struct {
	Success     bool   `json:"success"`
	HashesMatch bool   `json:"hashes_match"`
	ActualHash  string `json:"actual_hash,omitempty"`
	Error       string `json:"error,omitempty"`
}

type completeRequest struct {
	TransferID string `json:"transfer_id"`
}

type completeResponse struct {
	Success  bool   `json:"success"`
	FilePath string `json:"file_path,omitempty"`
	Error    string `json:"error,omitempty"`
}

type cancelRequest struct {
	TransferID string `json:"transfer_id"`
}
