package auth

type User struct {
	ID           string `json:"id"`
	Username     string `json:"username"`
	Email        string `json:"email"`
	PasswordHash string `json:"password_hash,omitempty"`
	Role         string `json:"role"` // ADMIN or USER
	AvatarAsset  string `json:"avatar_asset"`
	Frame        string `json:"frame"`
	DisplayName  string `json:"display_name"`
	Status       string `json:"status"`
	NameStyle    string `json:"name_style"`
	CreatedAt    int64  `json:"created_at"`
}

