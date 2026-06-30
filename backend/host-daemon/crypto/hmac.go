package crypto

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"os"
)

func getHmacSecret() []byte {
	secret := os.Getenv("HMAC_SECRET")
	if secret == "" {
		return []byte("default_hmac_secret_change_me")
	}
	return []byte(secret)
}

func VerifyHMAC(message, providedSignature string) bool {
	mac := hmac.New(sha256.New, getHmacSecret())
	mac.Write([]byte(message))
	expectedSignature := hex.EncodeToString(mac.Sum(nil))
	return hmac.Equal([]byte(expectedSignature), []byte(providedSignature))
}
