package sources

import (
	"context"
	"net/url"
	"os"
	"regexp"
	"strings"
)

// Anna's Archive search page scraper. The search HTML hides results inside
// HTML comments; we strip comment markers and parse anchors + fields.
// ponytail: HTML scrape of a moving target; if Anna's API becomes public
// (or a member key is configured), swap this for fast_download.json.

var annasMirror = func() string {
	if m := os.Getenv("ANNAS_ARCHIVE_BASE"); m != "" {
		return m
	}
	return "https://annas-archive.gl"
}

var (
	annasLinkRe  = regexp.MustCompile(`<a[^>]*href="(/md5/[0-9a-f]{32})"[^>]*>`)
	annasH2Re    = regexp.MustCompile(`<h2[^>]*>(.*?)</h2>`)
	annasAuthorRe = regexp.MustCompile(`<p[^>]*class="[^"]*"[^>]*>(.*?)</p>`)
	annasSizeRe  = regexp.MustCompile(`([\d.,]+\s*(?:KB|MB|GB))\s*[^<]*<`)
)

func searchAnnas(ctx context.Context, query string) []Result {
	u := annasMirror() + "/search?q=" + url.QueryEscape(query)
	page, err := getPage(ctx, u)
	if err != nil {
		return nil
	}
	// Results live inside <!-- ... --> comment blocks.
	page = strings.ReplaceAll(page, "<!--", "")
	page = strings.ReplaceAll(page, "-->", "")

	links := annasLinkRe.FindAllStringSubmatch(page, -1)
	if len(links) == 0 {
		return nil
	}

	results := make([]Result, 0, len(links))
	// Each result block is a window after the md5 link up to the next link:
	// <a href="/md5/..."><h2>Title</h2></a><p>Author</p><p>epub, 2.3 MB</p>
	for i, m := range links {
		end := len(page)
		if i+1 < len(links) {
			end = strings.Index(page, links[i+1][0])
		}
		block := page[strings.Index(page, m[0]) : end]

		h2 := annasH2Re.FindStringSubmatch(block)
		if len(h2) < 2 {
			continue
		}
		title := strings.TrimSpace(stripTags(h2[1]))
		if title == "" {
			continue
		}
		r := Result{
			Source:      "annas",
			Title:       title,
			Format:      "ebook",
			DownloadURL: annasMirror() + m[1],
			Confidence:  80,
		}
		if author := annasAuthorRe.FindStringSubmatch(block); len(author) > 1 {
			r.Author = strings.TrimSpace(stripTags(author[1]))
		}
		if size := annasSizeRe.FindStringSubmatch(block); len(size) > 1 {
			r.Size = strings.TrimSpace(size[1])
		}
		results = append(results, r)
	}
	return results
}

var tagRe = regexp.MustCompile(`<[^>]+>`)

func stripTags(s string) string {
	return tagRe.ReplaceAllString(s, "")
}