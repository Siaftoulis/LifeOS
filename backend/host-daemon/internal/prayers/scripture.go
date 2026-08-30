package prayers

import (
	"embed"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"
)

//go:embed data/nt_raw.json
var scriptureFS embed.FS

type ScriptureVerse struct {
	Number int    `json:"number"`
	Text   string `json:"text"`
}

type ScriptureChapter struct {
	Number int             `json:"number"`
	Verses []ScriptureVerse `json:"verses"`
}

type ScriptureBook struct {
	Number    int               `json:"number"`
	NameGreek string            `json:"nameGreek"`
	NameEnglish string          `json:"nameEnglish"`
	Chapters  []ScriptureChapter `json:"chapters"`
}

type ScriptureData struct {
	Source  string         `json:"source"`
	License string         `json:"license"`
	Books   []ScriptureBook `json:"books"`
}

// Lightweight book list for navigation
type ScriptureBookSummary struct {
	Number       int    `json:"number"`
	NameGreek    string `json:"nameGreek"`
	NameEnglish string `json:"nameEnglish"`
	ChapterCount int   `json:"chapter_count"`
	VerseCount   int   `json:"verse_count"`
}

var scriptureCache *ScriptureData

func loadScripture() (*ScriptureData, error) {
	if scriptureCache != nil {
		return scriptureCache, nil
	}

	data, err := scriptureFS.ReadFile("data/nt_raw.json")
	if err != nil {
		return nil, fmt.Errorf("failed to read scripture data: %w", err)
	}

	var scripture ScriptureData
	if err := json.Unmarshal(data, &scripture); err != nil {
		return nil, fmt.Errorf("failed to parse scripture data: %w", err)
	}

	scriptureCache = &scripture
	return scriptureCache, nil
}

func RegisterScriptureRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/prayers/scripture", handleScriptureBooks)
	mux.HandleFunc("/api/v1/prayers/scripture/chapter", handleScriptureChapter)
	mux.HandleFunc("/api/v1/prayers/scripture/search", handleScriptureSearch)
	mux.HandleFunc("/api/v1/prayers/scripture/service", handleScriptureAsService)
}

func handleScriptureBooks(w http.ResponseWriter, r *http.Request) {
	scripture, err := loadScripture()
	if err != nil {
		http.Error(w, `{"error":"failed to load scripture"}`, http.StatusInternalServerError)
		return
	}

	summaries := make([]ScriptureBookSummary, len(scripture.Books))
	for i, book := range scripture.Books {
		verseCount := 0
		for _, ch := range book.Chapters {
			verseCount += len(ch.Verses)
		}
		summaries[i] = ScriptureBookSummary{
			Number:       book.Number,
			NameGreek:    book.NameGreek,
			NameEnglish: book.NameEnglish,
			ChapterCount: len(book.Chapters),
			VerseCount:   verseCount,
		}
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"source":  scripture.Source,
		"license": scripture.License,
		"total_books": len(scripture.Books),
		"total_verses": func() int {
			total := 0
			for _, b := range summaries {
				total += b.VerseCount
			}
			return total
		}(),
		"books": summaries,
	})
}

func handleScriptureChapter(w http.ResponseWriter, r *http.Request) {
	scripture, err := loadScripture()
	if err != nil {
		http.Error(w, `{"error":"failed to load scripture"}`, http.StatusInternalServerError)
		return
	}

	bookStr := r.URL.Query().Get("book")
	chapterStr := r.URL.Query().Get("chapter")
	if bookStr == "" || chapterStr == "" {
		http.Error(w, `{"error":"missing book and chapter parameters"}`, http.StatusBadRequest)
		return
	}

	bookNum, err := strconv.Atoi(bookStr)
	if err != nil {
		http.Error(w, `{"error":"invalid book number"}`, http.StatusBadRequest)
		return
	}

	chapterNum, err := strconv.Atoi(chapterStr)
	if err != nil {
		http.Error(w, `{"error":"invalid chapter number"}`, http.StatusBadRequest)
		return
	}

	for _, book := range scripture.Books {
		if book.Number == bookNum {
			for _, ch := range book.Chapters {
				if ch.Number == chapterNum {
					resp := map[string]interface{}{
						"book_number":    book.Number,
						"book_name_greek": book.NameGreek,
						"book_name_english": book.NameEnglish,
						"chapter":        ch.Number,
						"verse_count":    len(ch.Verses),
						"verses":         ch.Verses,
					}
					w.Header().Set("Content-Type", "application/json; charset=utf-8")
					json.NewEncoder(w).Encode(resp)
					return
				}
			}
			http.Error(w, `{"error":"chapter not found"}`, http.StatusNotFound)
			return
		}
	}

	http.Error(w, `{"error":"book not found"}`, http.StatusNotFound)
}

func handleScriptureSearch(w http.ResponseWriter, r *http.Request) {
	scripture, err := loadScripture()
	if err != nil {
		http.Error(w, `{"error":"failed to load scripture"}`, http.StatusInternalServerError)
		return
	}

	q := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("q")))
	if q == "" {
		http.Error(w, `{"error":"missing q parameter"}`, http.StatusBadRequest)
		return
	}

	type SearchResult struct {
		BookNumber    int    `json:"book_number"`
		BookGreek     string `json:"book_greek"`
		BookEnglish   string `json:"book_english"`
		Chapter       int    `json:"chapter"`
		Verse         int    `json:"verse"`
		Snippet       string `json:"snippet"`
	}

	var results []SearchResult
	maxResults := 50

	for _, book := range scripture.Books {
		for _, ch := range book.Chapters {
			for _, v := range ch.Verses {
				lowerText := strings.ToLower(v.Text)
				if idx := strings.Index(lowerText, q); idx != -1 {
					start := idx - 40
					if start < 0 {
						start = 0
					}
					end := idx + len(q) + 60
					if end > len(v.Text) {
						end = len(v.Text)
					}
					snippet := v.Text[start:end]
					if start > 0 {
						snippet = "..." + snippet
					}
					if end < len(v.Text) {
						snippet = snippet + "..."
					}

					results = append(results, SearchResult{
						BookNumber:  book.Number,
						BookGreek:   book.NameGreek,
						BookEnglish: book.NameEnglish,
						Chapter:     ch.Number,
						Verse:       v.Number,
						Snippet:     snippet,
					})

					if len(results) >= maxResults {
						goto done
					}
				}
			}
		}
	}
done:

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"query":   q,
		"results": results,
		"count":   len(results),
	})
}

func handleScriptureAsService(w http.ResponseWriter, r *http.Request) {
	scripture, err := loadScripture()
	if err != nil {
		http.Error(w, `{"error":"failed to load scripture"}`, http.StatusInternalServerError)
		return
	}

	bookStr := r.URL.Query().Get("book")
	chapterStr := r.URL.Query().Get("chapter")
	if bookStr == "" || chapterStr == "" {
		http.Error(w, `{"error":"missing book and chapter parameters"}`, http.StatusBadRequest)
		return
	}

	bookNum, err := strconv.Atoi(bookStr)
	if err != nil {
		http.Error(w, `{"error":"invalid book number"}`, http.StatusBadRequest)
		return
	}

	chapterNum, err := strconv.Atoi(chapterStr)
	if err != nil {
		http.Error(w, `{"error":"invalid chapter number"}`, http.StatusBadRequest)
		return
	}

	for _, book := range scripture.Books {
		if book.Number == bookNum {
			for _, ch := range book.Chapters {
				if ch.Number == chapterNum {
					// Build content string with verse numbers
					var content strings.Builder
					for _, v := range ch.Verses {
						content.WriteString(fmt.Sprintf("%d %s\n\n", v.Number, v.Text))
					}

					resp := map[string]interface{}{
						"id":          fmt.Sprintf("scripture_%d_%d", bookNum, chapterNum),
						"title":       fmt.Sprintf("%s %d", book.NameEnglish, chapterNum),
						"category":    "Καινή Διαθήκη",
						"subtitle":    fmt.Sprintf("%s · Κεφάλαιο %d", book.NameGreek, chapterNum),
						"estimated_min": len(ch.Verses) / 5, // rough estimate
						"sections": []map[string]interface{}{
							{
								"header":    fmt.Sprintf("%s %d", book.NameEnglish, chapterNum),
								"content":   content.String(),
								"is_rubric": false,
								"is_dynamic": false,
							},
						},
					}
					w.Header().Set("Content-Type", "application/json; charset=utf-8")
					json.NewEncoder(w).Encode(resp)
					return
				}
			}
			http.Error(w, `{"error":"chapter not found"}`, http.StatusNotFound)
			return
		}
	}

	http.Error(w, `{"error":"book not found"}`, http.StatusNotFound)
}
