package accounting

import (
	"encoding/json"
	"net/http"
	"path/filepath"
)

type JsonRpcRequest struct {
	JsonRpc string          `json:"jsonrpc"`
	Method  string          `json:"method"`
	Params  json.RawMessage `json:"params"`
	Id      int             `json:"id"`
}

type JsonRpcResponse struct {
	JsonRpc string      `json:"jsonrpc"`
	Result  interface{} `json:"result,omitempty"`
	Error   interface{} `json:"error,omitempty"`
	Id      int         `json:"id"`
}

type Credential struct {
	Id             string `json:"id"`
	Label          string `json:"label"`
	DecryptedValue string `json:"decrypted_value"`
}

func RegisterRoutes(mux *http.ServeMux, storagePath string) {
	mux.HandleFunc("/api/accounting/rpc", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		var req JsonRpcRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "Bad request", http.StatusBadRequest)
			return
		}

		res := JsonRpcResponse{JsonRpc: "2.0", Id: req.Id}

		switch req.Method {
		case "Accounting.GetCredentials":
			// Stub: In a real scenario, this would query Drift/SQLite,
			// derive the key using crypto.DeriveKey and decrypt the value.
			res.Result = map[string]interface{}{
				"credentials": []Credential{
					{Id: "stub-id", Label: "Stub Credential", DecryptedValue: "stub-decrypted"},
				},
			}
		case "Accounting.DecryptDocument":
			// Stub: Read the encrypted file and return Base64 payload.
			res.Result = map[string]interface{}{
				"raw_bytes_base64": "stub-base64-content",
			}
		default:
			res.Error = "Method not found"
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(res)
	})

	// Also serve local documents safely (as requested in spec step 2: exposing table)
	docPath := filepath.Join(storagePath, "documents")
	mux.Handle("/api/accounting/docs/", http.StripPrefix("/api/accounting/docs/", http.FileServer(http.Dir(docPath))))
}
