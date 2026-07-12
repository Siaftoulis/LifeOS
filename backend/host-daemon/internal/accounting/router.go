package accounting

import (
	"crypto/aes"
	"crypto/cipher"
	"encoding/base64"
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
			// In a real scenario, this would query Drift/SQLite,
			// derive the key using crypto.DeriveKey and decrypt the value.
			
			// Dummy encrypted string representing "stub-decrypted" (not really encrypted here, just base64 simulated)
			res.Result = map[string]interface{}{
				"credentials": []Credential{
					{Id: "1", Label: "Demo Bank", DecryptedValue: "demo_password_123"},
					{Id: "2", Label: "Demo Crypto", DecryptedValue: "wallet_seed_phrase"},
				},
			}
		case "Accounting.DecryptDocument":
			// Real AES decryption logic for a given payload
			var params struct {
				EncryptedBase64 string `json:"encrypted_base64"`
				KeyBase64       string `json:"key_base64"`
			}
			if err := json.Unmarshal(req.Params, &params); err == nil && params.KeyBase64 != "" {
				key, _ := base64.StdEncoding.DecodeString(params.KeyBase64)
				ciphertext, _ := base64.StdEncoding.DecodeString(params.EncryptedBase64)
				
				block, err := aes.NewCipher(key)
				if err == nil {
					aesgcm, err := cipher.NewGCM(block)
					if err == nil {
						nonceSize := aesgcm.NonceSize()
						if len(ciphertext) >= nonceSize {
							nonce, ciphertextArgs := ciphertext[:nonceSize], ciphertext[nonceSize:]
							plaintext, err := aesgcm.Open(nil, nonce, ciphertextArgs, nil)
							if err == nil {
								res.Result = map[string]interface{}{
									"raw_bytes_base64": base64.StdEncoding.EncodeToString(plaintext),
								}
							} else {
								res.Error = "Decryption failed"
							}
						}
					}
				}
			} else {
				// Fallback for demo purposes
				res.Result = map[string]interface{}{
					"raw_bytes_base64": "stub-base64-content",
				}
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
