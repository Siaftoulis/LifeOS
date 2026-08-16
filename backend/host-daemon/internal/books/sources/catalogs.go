package sources

import (
	"context"
	"fmt"
	"net/url"
	"strings"
)

// Project Gutenberg via the Gutendex community API (free, no key).

type gutendexBook struct {
	ID      int    `json:"id"`
	Title   string `json:"title"`
	Authors []struct {
		Name string `json:"name"`
	} `json:"authors"`
	Formats map[string]string `json:"formats"`
}

type gutendexResponse struct {
	Results []gutendexBook `json:"results"`
}

func searchGutenberg(ctx context.Context, query string) []Result {
	var resp gutendexResponse
	if err := getJSON(ctx, "https://gutendex.com/books?search="+url.QueryEscape(query), &resp); err != nil {
		return nil
	}
	results := make([]Result, 0, len(resp.Results))
	for _, b := range resp.Results {
		epub := b.Formats["application/epub+zip"]
		if epub == "" {
			epub = b.Formats["application/epub+zip.images"]
		}
		if epub == "" {
			continue
		}
		author := ""
		if len(b.Authors) > 0 {
			author = b.Authors[0].Name
		}
		results = append(results, Result{
			Source:      "gutenberg",
			Title:       b.Title,
			Author:      author,
			Format:      "epub",
			DownloadURL: epub,
			Confidence:  90,
		})
	}
	return results
}

// OpenLibrary search API (free, no key). DownloadURL only when an
// Internet Archive copy (ia) exists; otherwise browse-only.
type openLibraryDoc struct {
	Title      string   `json:"title"`
	AuthorName []string `json:"author_name"`
	CoverI     int      `json:"cover_i"`
	IA         []string `json:"ia"`
}

type openLibraryResponse struct {
	Docs []openLibraryDoc `json:"docs"`
}

func searchOpenLibrary(ctx context.Context, query string) []Result {
	var resp openLibraryResponse
	u := "https://openlibrary.org/search.json?q=" + url.QueryEscape(query) + "&limit=12&fields=title,author_name,cover_i,ia"
	if err := getJSON(ctx, u, &resp); err != nil {
		return nil
	}
	results := make([]Result, 0, len(resp.Docs))
	for _, d := range resp.Docs {
		if d.Title == "" {
			continue
		}
		author := ""
		if len(d.AuthorName) > 0 {
			author = d.AuthorName[0]
		}
		cover := ""
		if d.CoverI > 0 {
			cover = fmt.Sprintf("https://covers.openlibrary.org/b/id/%d-M.jpg", d.CoverI)
		}
		dl := ""
		format := "ebook"
		if len(d.IA) > 0 {
			// ponytail: IA id -> archive.org direct epub guess; borrow flow if missing.
			dl = fmt.Sprintf("https://archive.org/download/%s/%s.epub", d.IA[0], d.IA[0])
			format = "epub"
		}
		results = append(results, Result{
			Source:      "openlibrary",
			Title:       d.Title,
			Author:      author,
			Format:      format,
			Cover:       cover,
			DownloadURL: dl,
			Confidence:  70,
		})
	}
	return results
}

// MangaDex API v5 (free, no key). No download URL: manga is chapter-based;
// Phase 3 adds chapter fetching. Format "manga" lets the client route it
// to the comic reader instead of the EPUB reader.
type mangaDexManga struct {
	ID            string `json:"id"`
	Attributes    struct {
		Title map[string]string `json:"title"`
	} `json:"attributes"`
	Relationships []struct {
		Type       string `json:"type"`
		Attributes *struct {
			FileName string `json:"fileName"`
		} `json:"attributes"`
	} `json:"relationships"`
}

type mangaDexResponse struct {
	Data []mangaDexManga `json:"data"`
}

func searchMangaDex(ctx context.Context, query string) []Result {
	u := "https://api.mangadex.org/manga?title=" + url.QueryEscape(query) +
		"&limit=8&includes[]=cover_art&contentRating[]=safe&contentRating[]=suggestive"
	var resp mangaDexResponse
	if err := getJSON(ctx, u, &resp); err != nil {
		return nil
	}
	results := make([]Result, 0, len(resp.Data))
	for _, m := range resp.Data {
		title := m.Attributes.Title["en"]
		if title == "" {
			for _, t := range m.Attributes.Title {
				title = t
				break
			}
		}
		cover := ""
		for _, rel := range m.Relationships {
			if rel.Type == "cover_art" && rel.Attributes != nil {
				cover = fmt.Sprintf("https://uploads.mangadex.org/covers/%s/%s", m.ID, rel.Attributes.FileName)
			}
		}
		results = append(results, Result{
			Source:      "mangadex",
			Title:       strings.TrimSpace(title),
			Format:      "manga",
			Cover:       cover,
			DownloadURL: "",
			Confidence:  75,
		})
	}
	return results
}