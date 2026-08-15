package oauth

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"html"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"lifeos/host-daemon/internal/auth"
	"lifeos/host-daemon/internal/auth/middleware"
)

// Private-app OAuth login: family members sign in with their existing
// Google/GitHub account and are matched to a LifeOS user. No password
// management, invite-only (unknown identities are rejected).

var httpClient = &http.Client{Timeout: 10 * time.Second}

type stateEntry struct {
	provider string
	exp      time.Time
}

var (
	stateMu  sync.Mutex
	states   = map[string]stateEntry{}
)

func env(key string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	if b, err := os.ReadFile("./data/oauth.env"); err == nil {
		for _, line := range strings.Split(string(b), "\n") {
			line = strings.TrimSpace(line)
			if strings.HasPrefix(line, key+"=") {
				return strings.TrimSpace(strings.TrimPrefix(line, key+"="))
			}
		}
	}
	return ""
}

func creds(provider string) (clientID, clientSecret string) {
	p := strings.ToUpper(provider)
	return env(p + "_OAUTH_CLIENT_ID"), env(p + "_OAUTH_CLIENT_SECRET")
}

// EnabledProviders: providers with a full set of credentials.
func EnabledProviders() []string {
	out := []string{} // ponytail: explicit empty slice so the API returns [] not null
	for _, p := range []string{"github", "google"} {
		if id, secret := creds(p); id != "" && secret != "" {
			out = append(out, p)
		}
	}
	return out
}

func callbackPath(provider string) string {
	return "/api/v1/auth/oauth/" + provider + "/callback"
}

func redirectURI(provider string) string {
	base := env("OAUTH_BASE_URL")
	if base == "" {
		base = "http://localhost:50051"
	}
	return base + callbackPath(provider)
}

func newState() string {
	b := make([]byte, 16)
	rand.Read(b)
	return hex.EncodeToString(b)
}

// resolveLifeOSUser: mapping file data/oauth_users.json overrides auto-match:
//   {"github": {"adimopoulou1234": "anna"}, "google": {"me@gmail.com": "panospds"}}
// Auto-match: GitHub login == username, Google email prefix == username (case-insensitive).
func resolveLifeOSUser(provider, externalID string) (*auth.User, bool) {
	if b, err := os.ReadFile("./data/oauth_users.json"); err == nil {
		var m map[string]map[string]string
		if json.Unmarshal(b, &m) == nil {
			if u, ok := m[provider][externalID]; ok {
				return auth.GetUserByUsername(u)
			}
		}
	}

	username := externalID
	if provider == "google" {
		username = strings.Split(externalID, "@")[0]
	}
	return auth.GetUserByUsername(username)
}

func issueToken(w http.ResponseWriter, user *auth.User) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"username": user.Username,
		"role":     user.Role,
		"exp":      time.Now().Add(time.Hour * 24).Unix(),
	})
	tokenString, err := token.SignedString(middleware.JwtSecret)
	if err != nil {
		http.Error(w, "Token generation failed", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Write([]byte(`<!DOCTYPE html><script>localStorage.setItem('lifeos_token','` + tokenString + `');location.href='/';</script>`))
}

func deniedPage(w http.ResponseWriter, reason string) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Write([]byte(`<!DOCTYPE html><html lang="el"><body style="font-family:sans-serif;background:#0d1117;color:#e6edf3;display:flex;align-items:center;justify-content:center;height:100vh">
<div style="max-width:420px;text-align:center"><h1>Access denied</h1><p>` + html.EscapeString(reason) + `</p>
<p style="color:#8b949e">Ζήτα από τον διαχειριστή να σε προσθέσει στους χρήστες του LifeOS.</p></div></body></html>`))
}

func HandleStart(provider string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		clientID, _ := creds(provider)
		if clientID == "" {
			http.Error(w, "OAuth not configured for "+provider, http.StatusServiceUnavailable)
			return
		}

		state := newState()
		stateMu.Lock()
		states[state] = stateEntry{provider: provider, exp: time.Now().Add(10 * time.Minute)}
		stateMu.Unlock()
		http.SetCookie(w, &http.Cookie{
			Name: "oauth_state", Value: state, Path: "/",
			HttpOnly: true, SameSite: http.SameSiteLaxMode, MaxAge: 600,
		})

		q := url.Values{"redirect_uri": {redirectURI(provider)}, "state": {state}}
		var authURL string
		if provider == "github" {
			q.Set("client_id", clientID)
			q.Set("scope", "read:user")
			authURL = "https://github.com/login/oauth/authorize?" + q.Encode()
		} else {
			q.Set("client_id", clientID)
			q.Set("response_type", "code")
			q.Set("scope", "openid email profile")
			authURL = "https://accounts.google.com/o/oauth2/v2/auth?" + q.Encode()
		}
		http.Redirect(w, r, authURL, http.StatusFound)
	}
}

func HandleCallback(provider string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		clientID, clientSecret := creds(provider)
		if clientID == "" {
			http.Error(w, "OAuth not configured", http.StatusServiceUnavailable)
			return
		}

		// CSRF: state must match the cookie we issued
		state := r.URL.Query().Get("state")
		cookie, err := r.Cookie("oauth_state")
		if err != nil || cookie.Value != state {
			deniedPage(w, "Ανεπιτυχής επαλήθευση (state mismatch). Ξαναπροσπάθησε.")
			return
		}
		stateMu.Lock()
		entry, ok := states[state]
		delete(states, state)
		stateMu.Unlock()
		if !ok || entry.provider != provider || time.Now().After(entry.exp) {
			deniedPage(w, "Η σύνδεση έληξε. Ξαναπροσπάθησε.")
			return
		}

		code := r.URL.Query().Get("code")
		externalID, name := exchangeCode(provider, clientID, clientSecret, code, redirectURI(provider))
		if externalID == "" {
			deniedPage(w, "Δεν ταυτοποιήθηκε ο λογαριασμός σου.")
			return
		}

		user, ok := resolveLifeOSUser(provider, externalID)
		if !ok {
			deniedPage(w, "Ο λογαριασμός "+externalID+" δεν έχει πρόσβαση στο LifeOS.")
			return
		}

		// ponytail: no session store, access logged to daemon log
		log.Printf("[oauth] %s login: %s -> %s (%s)", provider, externalID, user.Username, name)
		issueToken(w, user)
	}
}

func exchangeCode(provider, clientID, clientSecret, code, redirectURI string) (externalID, displayName string) {
	form := url.Values{
		"client_id":     {clientID},
		"client_secret": {clientSecret},
		"code":          {code},
		"redirect_uri":  {redirectURI},
	}
	if provider == "google" {
		form.Set("grant_type", "authorization_code")
	}

	var tokenURL string
	if provider == "github" {
		tokenURL = "https://github.com/login/oauth/access_token"
	} else {
		tokenURL = "https://oauth2.googleapis.com/token"
	}

	req, _ := http.NewRequest("POST", tokenURL, strings.NewReader(form.Encode()))
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	req.Header.Set("Accept", "application/json")
	resp, err := httpClient.Do(req)
	if err != nil {
		return "", ""
	}
	defer resp.Body.Close()

	var tok struct {
		AccessToken string `json:"access_token"`
		Error       string `json:"error"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&tok); err != nil || tok.AccessToken == "" {
		return "", ""
	}

	var userURL string
	if provider == "github" {
		userURL = "https://api.github.com/user"
	} else {
		userURL = "https://openidconnect.googleapis.com/v1/userinfo"
	}
	req, _ = http.NewRequest("GET", userURL, nil)
	req.Header.Set("Authorization", "Bearer "+tok.AccessToken)
	req.Header.Set("User-Agent", "LifeOS")
	resp, err = httpClient.Do(req)
	if err != nil {
		return "", ""
	}
	defer resp.Body.Close()

	var ident struct {
		Login string `json:"login"`
		Email string `json:"email"`
		Name  string `json:"name"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&ident); err != nil {
		return "", ""
	}

	if provider == "github" {
		return strings.ToLower(ident.Login), ident.Name
	}
	return strings.ToLower(ident.Email), ident.Name
}
