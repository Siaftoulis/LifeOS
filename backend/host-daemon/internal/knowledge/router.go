package knowledge

import (
	"encoding/json"
	"net/http"
)

type Category struct {
	ID    string `json:"id"`
	Title string `json:"title"`
	Icon  string `json:"icon"`
	Color string `json:"color"`
}

type Article struct {
	ID       string `json:"id"`
	Title    string `json:"title"`
	Excerpt  string `json:"excerpt"`
	Date     string `json:"date"`
	Category string `json:"category"`
	Color    string `json:"color"`
}

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/knowledge/categories", handleGetCategories)
	mux.HandleFunc("/api/v1/knowledge/articles", handleGetArticles)
}

func handleGetCategories(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	
	w.Header().Set("Content-Type", "application/json")

	rows, err := DB.Query("SELECT id, title, icon, color FROM categories")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var categories []Category
	for rows.Next() {
		var c Category
		if err := rows.Scan(&c.ID, &c.Title, &c.Icon, &c.Color); err == nil {
			categories = append(categories, c)
		}
	}

	if categories == nil {
		categories = []Category{}
	}

	json.NewEncoder(w).Encode(categories)
}

func handleGetArticles(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	
	w.Header().Set("Content-Type", "application/json")

	rows, err := DB.Query("SELECT id, title, excerpt, date, category, color FROM articles ORDER BY rowid DESC")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var articles []Article
	for rows.Next() {
		var a Article
		if err := rows.Scan(&a.ID, &a.Title, &a.Excerpt, &a.Date, &a.Category, &a.Color); err == nil {
			articles = append(articles, a)
		}
	}

	if articles == nil {
		articles = []Article{}
	}

	json.NewEncoder(w).Encode(articles)
}
