package player

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"

	"lifeos/host-daemon/internal/auth/middleware"
)

func TestMain(m *testing.M) {
	dir, err := os.MkdirTemp("", "player-test")
	if err != nil {
		os.Exit(1)
	}
	os.Chdir(dir)
	os.MkdirAll("./data", 0755)
	os.Exit(m.Run())
}

func withUser(r *http.Request, username, role string) *http.Request {
	ctx := context.WithValue(r.Context(), middleware.UserContextKey, username)
	ctx = context.WithValue(ctx, middleware.RoleContextKey, role)
	return r.WithContext(ctx)
}

func post(t *testing.T, handler http.HandlerFunc, user string, body string) *httptest.ResponseRecorder {
	t.Helper()
	req := httptest.NewRequest(http.MethodPost, "/", strings.NewReader(body))
	req = withUser(req, user, "USER")
	rec := httptest.NewRecorder()
	handler(rec, req)
	return rec
}

func addQuest(t *testing.T, handler http.HandlerFunc, title, due string) string {
	t.Helper()
	rec := post(t, handler, "admin", `{"title":"`+title+`","description":"test","xp_reward":50,"due_date":"`+due+`"}`)
	if rec.Code != http.StatusOK {
		t.Fatalf("add quest failed: %d %s", rec.Code, rec.Body.String())
	}
	var res map[string]string
	json.Unmarshal(rec.Body.Bytes(), &res)
	return res["id"]
}

func TestQuestFlow(t *testing.T) {
	if err := InitDB(t.TempDir()); err != nil {
		t.Fatalf("InitDB: %v", err)
	}
	t.Cleanup(func() { DB.Close() })
	// fresh points balance for the test user
	balanceBefore := GetPlayerState().XP

	qid := addQuest(t, handleAddQuest, "Clean the Car", "2026-08-08")

	// GET returns the new fields
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req = withUser(req, "alice", "USER")
	rec := httptest.NewRecorder()
	handleGetQuests(rec, req)
	var quests []Quest
	json.Unmarshal(rec.Body.Bytes(), &quests)
	found := false
	for _, q := range quests {
		if q.ID == qid && q.DueDate == "2026-08-08" && q.AcceptedBy == "" {
			found = true
		}
	}
	if !found {
		t.Fatalf("quest not returned with new fields: %s", rec.Body.String())
	}

	// accept as alice
	rec = post(t, handleAcceptQuest, "alice", `{"quest_id":"`+qid+`"}`)
	if rec.Code != http.StatusOK {
		t.Fatalf("accept failed: %d %s", rec.Code, rec.Body.String())
	}
	// double-accept is rejected
	rec = post(t, handleAcceptQuest, "bob", `{"quest_id":"`+qid+`"}`)
	if rec.Code != http.StatusConflict {
		t.Fatalf("double accept should conflict: %d", rec.Code)
	}

	// complete by a different user is forbidden
	rec = post(t, handleQuestComplete, "bob", `{"quest_id":"`+qid+`"}`)
	if rec.Code != http.StatusForbidden {
		t.Fatalf("foreign complete should be forbidden: %d", rec.Code)
	}

	// complete by alice awards XP + points
	rec = post(t, handleQuestComplete, "alice", `{"quest_id":"`+qid+`"}`)
	if rec.Code != http.StatusOK {
		t.Fatalf("complete failed: %d %s", rec.Code, rec.Body.String())
	}
	if xp := GetPlayerState().XP; xp != balanceBefore+50 {
		t.Fatalf("XP not awarded: got %d, want %d", xp, balanceBefore+50)
	}
	// completing again conflicts
	rec = post(t, handleQuestComplete, "alice", `{"quest_id":"`+qid+`"}`)
	if rec.Code != http.StatusConflict {
		t.Fatalf("double complete should conflict: %d", rec.Code)
	}

	// cancel path: accept, cancel -> penalty, quest returns to pool
	qid2 := addQuest(t, handleAddQuest, "Walk the Dog", "2026-08-08")
	post(t, handleAcceptQuest, "bob", `{"quest_id":"`+qid2+`"}`)
	rec = post(t, handleCancelQuest, "bob", `{"quest_id":"`+qid2+`"}`)
	if rec.Code != http.StatusOK {
		t.Fatalf("cancel failed: %d %s", rec.Code, rec.Body.String())
	}
	var cancelRes map[string]interface{}
	json.Unmarshal(rec.Body.Bytes(), &cancelRes)
	if penalty := int(cancelRes["penalty"].(float64)); penalty != 25 {
		t.Fatalf("expected half-reward penalty 25, got %d", penalty)
	}
	// someone else can now claim it
	rec = post(t, handleAcceptQuest, "alice", `{"quest_id":"`+qid2+`"}`)
	if rec.Code != http.StatusOK {
		t.Fatalf("re-claim after cancel failed: %d %s", rec.Code, rec.Body.String())
	}
}
