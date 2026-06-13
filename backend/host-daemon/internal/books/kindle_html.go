package books

import (
	"fmt"
	"net/http"
)

// KindleWebPortalHandler serves pure, high-contrast HTML readable on Kindle experimental browsers.
func KindleWebPortalHandler(w http.ResponseWriter, r *http.Request) {
	bookID := r.URL.Query().Get("book_id")
	page := r.URL.Query().Get("page")
	if page == "" {
		page = "1"
	}

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	
	html := fmt.Sprintf(`
		<!DOCTYPE html>
		<html>
		<head>
			<title>Kindle Reader</title>
			<style>
				body { background-color: white; color: black; font-family: serif; font-size: 24px; padding: 20px; }
				a { color: black; text-decoration: underline; }
				.controls { margin-top: 40px; font-size: 20px; }
			</style>
		</head>
		<body>
			<h1>Book %s</h1>
			<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>
			
			<div class="controls">
				<a href="?book_id=%s&page=prev">Previous Page</a> | 
				Page %s | 
				<a href="?book_id=%s&page=next">Next Page</a>
			</div>
		</body>
		</html>
	`, bookID, bookID, page, bookID)

	w.Write([]byte(html))
}
