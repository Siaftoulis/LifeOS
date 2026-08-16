package books

type Book struct {
	ID          string `json:"id"`
	Title       string `json:"title"`
	Author      string `json:"author"`
	CurrentPage int    `json:"current_page"`
	TotalPages  int    `json:"total_pages"`
	FilePath    string `json:"file_path"`
	Status      string `json:"status"`
	Cover       string `json:"cover"`
	Description string `json:"description"`
	Rating      float64 `json:"rating"`
}

type ReadingProgress struct {
	BookID  string `json:"book_id"`
	Page    int    `json:"page"`
	Seconds int    `json:"seconds"`
}

type BookHighlight struct {
	ID          string `json:"id"`
	BookID      string `json:"book_id"`
	TextContent string `json:"text_content"`
	NoteContent string `json:"note_content"`
	PageNumber  int    `json:"page_number"`
}
