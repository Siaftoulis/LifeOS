package books

import (
	"archive/zip"
	"io"
	"os"
	"regexp"
	"sort"
	"strings"
)

// EPUB is a zip of XHTML docs. We extract chapter text per content file, in
// zip order (good enough for progress/context purposes; spine parsing is
// overkill here). ponytail: zip-order chapter splitting; a proper spine
// reader (epub2/3 order) only matters if chapter order is wrong in practice.

var (
	tagRe     = regexp.MustCompile(`<[^>]+>`)
	scriptRe  = regexp.MustCompile(`(?is)<script[^>]*>.*?</script>`)
	styleRe   = regexp.MustCompile(`(?is)<style[^>]*>.*?</style>`)
	wsRe      = regexp.MustCompile(`\s+`)
)

// chapter is one content file's text.
type chapter struct {
	Title string
	Text  string
}

// extractEpubChapters returns the text of each XHTML content file.
func extractEpubChapters(path string) ([]chapter, error) {
	zr, err := zip.OpenReader(path)
	if err != nil {
		return nil, err
	}
	defer zr.Close()

	var chapters []chapter
	for _, f := range zr.File {
		name := strings.ToLower(f.Name)
		if !strings.HasSuffix(name, ".xhtml") && !strings.HasSuffix(name, ".html") && !strings.HasSuffix(name, ".htm") {
			continue
		}
		rc, err := f.Open()
		if err != nil {
			continue
		}
		buf, err := io.ReadAll(io.LimitReader(rc, 4<<20))
		rc.Close()
		if err != nil {
			continue
		}
		text := cleanText(string(buf))
		if len(text) < 40 {
			continue
		}
		chapters = append(chapters, chapter{
			Title: chapterTitle(name, text),
			Text:  text,
		})
	}
	sort.Slice(chapters, func(i, j int) bool { return len(chapters[i].Text) > len(chapters[j].Text) })
	return chapters, nil
}

func cleanText(html string) string {
	html = scriptRe.ReplaceAllString(html, "")
	html = styleRe.ReplaceAllString(html, "")
	html = tagRe.ReplaceAllString(html, " ")
	html = strings.ReplaceAll(html, "&nbsp;", " ")
	html = strings.ReplaceAll(html, "&amp;", "&")
	html = strings.ReplaceAll(html, "&lt;", "<")
	html = strings.ReplaceAll(html, "&gt;", ">")
	html = strings.ReplaceAll(html, "&quot;", "\"")
	return strings.TrimSpace(wsRe.ReplaceAllString(html, " "))
}

func chapterTitle(name, text string) string {
	t := strings.TrimSuffix(name, ".xhtml")
	t = strings.TrimSuffix(t, ".html")
	t = strings.TrimSuffix(t, ".htm")
	t = strings.ReplaceAll(t, "_", " ")
	t = strings.ReplaceAll(t, "-", " ")
	return strings.TrimSpace(t)
}

// bestChapter picks the chapter containing the most query tokens — the lazy
// RAG: no vector DB, chapter injection instead.
func bestChapter(chapters []chapter, query string) *chapter {
	tokens := strings.Fields(strings.ToLower(query))
	var best *chapter
	bestScore := -1
	for i := range chapters {
		score := 0
		lower := strings.ToLower(chapters[i].Text)
		for _, tok := range tokens {
			if len(tok) > 2 && strings.Contains(lower, tok) {
				score++
			}
		}
		if score > bestScore {
			bestScore = score
			best = &chapters[i]
		}
	}
	return best
}

// chapterForBook extracts chapters from the book's file on disk.
func chapterForBook(bookID string) ([]chapter, error) {
	var filePath string
	err := DB.QueryRow("SELECT file_path FROM books WHERE id = ?", bookID).Scan(&filePath)
	if err != nil {
		return nil, err
	}
	if !strings.HasSuffix(strings.ToLower(filePath), ".epub") {
		return nil, os.ErrNotExist
	}
	return extractEpubChapters(filePath)
}

// truncate keeps the first n runes of s (sane prompt size for a small local
// model).
func truncate(s string, n int) string {
	r := []rune(s)
	if len(r) <= n {
		return s
	}
	return string(r[:n]) + " […]"
}