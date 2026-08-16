package books

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"
)

// Zen Code AI layer: talks to any OpenAI-compatible endpoint (Ollama,
// llama.cpp, vLLM) via LLM_BASE_URL / LLM_MODEL / LLM_API_KEY. The planned
// small fine-tuned model drops in behind the same URL — nothing here
// changes when it lands.

func llmBase() string {
	if b := os.Getenv("LLM_BASE_URL"); b != "" {
		return strings.TrimSuffix(b, "/")
	}
	return "http://localhost:11434/v1" // Ollama default
}

func llmModel() string {
	if m := os.Getenv("LLM_MODEL"); m != "" {
		return m
	}
	return "llama3.2"
}

func llmKey() string { return os.Getenv("LLM_API_KEY") }

// LLMStatus reports whether the local LLM is reachable. Cached briefly so
// the UI poll doesn't hammer a cold Ollama on every panel open.
var (
	statusMu    sync.Mutex
	statusCache = struct {
		available bool
		model     string
		at        time.Time
	}{}
)

func LLMStatus() (available bool, model string) {
	statusMu.Lock()
	defer statusMu.Unlock()
	if time.Since(statusCache.at) < 10*time.Second {
		return statusCache.available, statusCache.model
	}
	available, model = probeLLM()
	statusCache.available, statusCache.model, statusCache.at = available, model, time.Now()
	return available, model
}

func probeLLM() (bool, string) {
	client := &http.Client{Timeout: 3 * time.Second}
	resp, err := client.Get(llmBase() + "/models")
	if err != nil {
		return false, ""
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return false, ""
	}
	var mr struct {
		Data []struct {
			ID string `json:"id"`
		} `json:"data"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&mr); err != nil {
		return false, ""
	}
	for _, m := range mr.Data {
		if strings.Contains(m.ID, llmModel()) {
			return true, m.ID
		}
	}
	return true, llmModel() // endpoint up; model name is a server default
}

type chatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type chatRequest struct {
	Model    string        `json:"model"`
	Messages []chatMessage `json:"messages"`
	Stream   bool          `json:"stream"`
}

type chatResponse struct {
	Choices []struct {
		Message chatMessage `json:"message"`
	} `json:"choices"`
}

// llmChat sends one non-streaming chat completion and returns the reply.
func llmChat(system, user string) (string, error) {
	body, _ := json.Marshal(chatRequest{
		Model: llmModel(),
		Messages: []chatMessage{
			{Role: "system", Content: system},
			{Role: "user", Content: user},
		},
	})
	req, err := http.NewRequest(http.MethodPost, llmBase()+"/chat/completions", bytes.NewReader(body))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")
	if k := llmKey(); k != "" {
		req.Header.Set("Authorization", "Bearer "+k)
	}

	client := &http.Client{Timeout: 2 * time.Minute}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		b, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
		return "", fmt.Errorf("llm status %d: %s", resp.StatusCode, string(b))
	}
	var cr chatResponse
	if err := json.NewDecoder(resp.Body).Decode(&cr); err != nil {
		return "", err
	}
	if len(cr.Choices) == 0 {
		return "", fmt.Errorf("llm returned no choices")
	}
	return strings.TrimSpace(cr.Choices[0].Message.Content), nil
}

const describeSystem = `You are a book librarian. Given a book title and author, write a short
description (2-3 sentences), 3-5 genre tags, and a suggested 1-5 rating.
Reply as JSON only: {"description": "...", "tags": ["..."], "rating": 4.5}`

// DescribeBook generates description + tags + rating via the local LLM.
func DescribeBook(title, author string) (map[string]any, error) {
	out, err := llmChat(describeSystem, fmt.Sprintf("Book: %s by %s", title, author))
	if err != nil {
		return nil, err
	}
	out = trimJSON(out)
	var m map[string]any
	if err := json.Unmarshal([]byte(out), &m); err != nil {
		return nil, fmt.Errorf("llm non-JSON reply: %s", truncate(out, 200))
	}
	return m, nil
}

const summarizeSystem = `You summarize book chapters in 3-4 sentences, plain text, no preamble.`

// SummarizeBook asks for a summary of the whole book from its first ~3k
// characters (lazy whole-book digest; per-chapter summaries come via chat).
func SummarizeBook(title, excerpt string) (string, error) {
	return llmChat(summarizeSystem, fmt.Sprintf("Book: %s\n\nBeginning of the book:\n%s",
		title, truncate(excerpt, 3000)))
}

const chatSystem = `You are a reading companion. Answer questions about the book using ONLY the
provided chapter text. If the chapter text does not contain the answer, say so.`

// ChatWithBook answers a question with the best-matching chapter as context
// (no vector DB — chapter injection).
func ChatWithBook(title, chapterTitle, chapterText, question string) (string, error) {
	return llmChat(chatSystem, fmt.Sprintf("Book: %s\nChapter: %s\n\nChapter text:\n%s\n\nQuestion: %s",
		title, chapterTitle, truncate(chapterText, 6000), question))
}

// trimJSON strips markdown fences around an LLM JSON reply.
func trimJSON(s string) string {
	s = strings.TrimSpace(s)
	if strings.HasPrefix(s, "```") {
		s = strings.TrimPrefix(s, "```json")
		s = strings.TrimPrefix(s, "```")
		s = strings.TrimSuffix(s, "```")
		s = strings.TrimSpace(s)
	}
	return s
}

// saveBookMetadata stores LLM-generated metadata on the book row.
func saveBookMetadata(bookID string, m map[string]any) {
	desc, _ := m["description"].(string)
	rating, _ := m["rating"].(float64)
	if rating == 0 {
		if r, ok := m["rating"].(json.Number); ok {
			rating, _ = r.Float64()
		}
	}
	_, err := DB.Exec("UPDATE books SET description = ?, rating = ? WHERE id = ?", desc, rating, bookID)
	if err != nil {
		log.Printf("books ai: save metadata: %v", err)
	}
}