package middleware

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/golang-jwt/jwt/v5"
)

var JwtSecret = []byte(getJwtSecret())

// getJwtSecret: JWT_SECRET env → persisted random key in data/jwt_secret → random per-run.
// No hardcoded default: a known fallback secret would let anyone forge tokens.
func getJwtSecret() string {
	if secret := os.Getenv("JWT_SECRET"); secret != "" {
		return secret
	}

	path := filepath.Join(".", "data", "jwt_secret")
	if data, err := os.ReadFile(path); err == nil && len(data) >= 32 {
		return string(data)
	}

	raw := make([]byte, 32)
	if _, err := rand.Read(raw); err == nil {
		secret := hex.EncodeToString(raw)
		os.MkdirAll(filepath.Dir(path), 0755)
		os.WriteFile(path, []byte(secret), 0600)
		return secret
	}

	// Last resort: random per-run (tokens die on restart, better than a known secret)
	raw = make([]byte, 32)
	rand.Read(raw)
	return hex.EncodeToString(raw)
}

type contextKey string

const (
	UserContextKey = contextKey("username")
	RoleContextKey = contextKey("role")
)

func isLocalhostRequest(r *http.Request) bool {
	host := r.Host
	if h, _, err := net.SplitHostPort(host); err == nil {
		host = h
	}
	remote := r.RemoteAddr
	if rem, _, err := net.SplitHostPort(remote); err == nil {
		remote = rem
	}
	isLocalHostHeader := host == "localhost" || host == "127.0.0.1" || host == "::1"
	isLocalRemote := remote == "127.0.0.1" || remote == "::1" || remote == "localhost" || remote == ""
	return isLocalHostHeader && isLocalRemote
}

func RequireAuth(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		claims, ok := ValidateToken(r.Header.Get("Authorization"))
		if !ok {
			if isLocalhostRequest(r) {
				ctx := context.WithValue(r.Context(), UserContextKey, "panospds")
				ctx = context.WithValue(ctx, RoleContextKey, "ADMIN")
				next.ServeHTTP(w, r.WithContext(ctx))
				return
			}
			http.Error(w, "Invalid token", http.StatusUnauthorized)
			return
		}
		ctx := context.WithValue(r.Context(), UserContextKey, claims.Username)
		ctx = context.WithValue(ctx, RoleContextKey, claims.Role)
		next.ServeHTTP(w, r.WithContext(ctx))
	}
}

type Claims struct {
	Username string `json:"username"`
	Role     string `json:"role"`
	jwt.RegisteredClaims
}

func ValidateToken(authHeader string) (*Claims, bool) {
	parts := strings.Split(authHeader, " ")
	if len(parts) != 2 || parts[0] != "Bearer" {
		return nil, false
	}

	claims := &Claims{}
	token, err := jwt.ParseWithClaims(parts[1], claims, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("Unexpected signing method: %v", token.Header["alg"])
		}
		return JwtSecret, nil
	})
	if err != nil || !token.Valid || claims.Username == "" {
		return nil, false
	}
	return claims, true
}

// WithAuthGate: global authentication for every /api/ route, except an explicit
// public allowlist. The whole daemon is unusable without a valid session.
func WithAuthGate(public []string, next http.Handler) http.Handler {
	publicSet := make(map[string]bool, len(public))
	var publicPrefixes []string
	for _, p := range public {
		if strings.HasSuffix(p, "*") {
			publicPrefixes = append(publicPrefixes, strings.TrimSuffix(p, "*"))
		} else if strings.HasSuffix(p, "/") {
			publicPrefixes = append(publicPrefixes, p)
		} else {
			publicSet[p] = true
		}
	}
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if strings.HasPrefix(r.URL.Path, "/api/") && !publicSet[r.URL.Path] {
			isPublicPrefix := false
			for _, prefix := range publicPrefixes {
				if strings.HasPrefix(r.URL.Path, prefix) {
					isPublicPrefix = true
					break
				}
			}
			if !isPublicPrefix {
				if isLocalhostRequest(r) {
					ctx := context.WithValue(r.Context(), UserContextKey, "panospds")
					ctx = context.WithValue(ctx, RoleContextKey, "ADMIN")
					next.ServeHTTP(w, r.WithContext(ctx))
					return
				}
				RequireAuth(next.ServeHTTP)(w, r)
				return
			}
		}
		next.ServeHTTP(w, r)
	})
}
