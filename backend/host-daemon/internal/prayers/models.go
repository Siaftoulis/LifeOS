package prayers

import "time"

// FastingType represents the Orthodox fasting rule for a specific day
type FastingType string

const (
	FastNone       FastingType = "Ανηστεία"                       // Fast-free (e.g. Bright Week, After Nativity)
	FastWineOil    FastingType = "Κατάλυσις Οίνου και Ελαίου"     // Wine & Oil allowed
	FastFish       FastingType = "Κατάλυσις Ιχθύος"               // Fish, wine & oil allowed
	FastStrict     FastingType = "Νηστεία (Άνευ Ελαίου & Οίνου)"  // Strict fast / dry eating
	FastDairy      FastingType = "Κατάλυσις Τυρού και Ωών"        // Cheesefare week (dairy allowed)
)

// Saint represents a commemorated saint in the Synaxarion
type Saint struct {
	Name        string `json:"name"`
	Title       string `json:"title,omitempty"`       // e.g. "Ο Όσιος", "Ο Μεγαλομάρτυς", "Η Αγία"
	ShortLife   string `json:"short_life,omitempty"`  // Brief life summary
	FullLife    string `json:"full_life,omitempty"`   // Extended Synaxarion text
	Apolytikion string `json:"apolytikion,omitempty"` // Απολυτίκιον του Αγίου
	Kontakion   string `json:"kontakion,omitempty"`   // Κοντάκιον
	Megalynarion string `json:"megalynarion,omitempty"` // Μεγαλυνάριον
	IconURL     string `json:"icon_url,omitempty"`
}

// ScriptureReading represents daily Epistle or Gospel pericope
type ScriptureReading struct {
	Type      string `json:"type"`      // "Απόστολος" or "Ευαγγέλιον"
	Reference string `json:"reference"` // e.g. "Προς Ρωμαίους ιβ' 1-8"
	Text      string `json:"text"`      // Original Biblical text in Koine Greek
}

// DailyLiturgicalInfo encapsulates all liturgical data for a specific date
type DailyLiturgicalInfo struct {
	Date          string            `json:"date"`           // YYYY-MM-DD
	DateFormatted string            `json:"date_formatted"` // e.g. "Σάββατον, 29 Αυγούστου 2026"
	Tone          string            `json:"tone"`           // e.g. "Ήχος Πλ. Α'"
	Period        string            `json:"period"`         // e.g. "Οκτώηχος", "Τριώδιον", "Πεντηκοστάριον"
	FeastName     string            `json:"feast_name"`     // Primary feast of the day
	Fasting       FastingType       `json:"fasting"`        // Fasting description
	Saints        []Saint           `json:"saints"`         // Saints commemorated today
	Readings      []ScriptureReading `json:"readings"`      // Daily Epistle & Gospel
	MovableCycle  string            `json:"movable_cycle"`  // Relative day (e.g. "12η Εβδομάδα Ματθαίου")
}

// PrayerSection is a structured part of a prayer service
type PrayerSection struct {
	Header      string `json:"header,omitempty"`       // Rubric header, e.g. "Ιερεύς:", "Ψαλμός 50", "Τρισάγιον"
	Content     string `json:"content"`                // Prayer content
	IsRubric    bool   `json:"is_rubric,omitempty"`    // Instruction / rubrics in red/italic
	IsDynamic   bool   `json:"is_dynamic,omitempty"`   // True if injected from today's Typikon
	DynamicType string `json:"dynamic_type,omitempty"`// e.g. "apolytikion", "kontakion", "gospel"
}

// CommemorationOption provides a selectable Saint / Commemoration option
type CommemorationOption struct {
	Index int    `json:"index"`
	Name  string `json:"name"`
	Title string `json:"title,omitempty"`
}

// PrayerService represents an entire liturgical service or prayer rule
type PrayerService struct {
	ID                         string                `json:"id"`           // e.g. "morning_prayer", "small_compline", "matins"
	Title                      string                `json:"title"`        // e.g. "Πρωινή Προσευχή"
	Category                   string                `json:"category"`     // "Καθημερινές Ακολουθίες", "Θεία Μετάληψις", "Παρακλήσεις"
	Subtitle                   string                `json:"subtitle"`     // e.g. "Ακολουθία μετά την εξέγερσιν εκ του ύπνου"
	EstimatedMin               int                   `json:"estimated_min"`// e.g. 15
	Sections                   []PrayerSection       `json:"sections"`
	Commemorations             []CommemorationOption `json:"commemorations,omitempty"`
	SelectedCommemorationIndex int                   `json:"selected_commemoration_idx"`
}

// PrayerCategory represents a grouped collection of prayers
type PrayerCategory struct {
	ID       string   `json:"id"`
	Title    string   `json:"title"`
	Icon     string   `json:"icon"`
	Services []string `json:"service_ids"`
}

// FavoritePrayer represents a user bookmark
type FavoritePrayer struct {
	ID        string    `json:"id"`
	ServiceID string    `json:"service_id"`
	Note      string    `json:"note,omitempty"`
	CreatedAt time.Time `json:"created_at"`
}

// PrayerRuleItem represents an individual daily prayer objective
type PrayerRuleItem struct {
	ID          string `json:"id"`          // "morning_prayer", "gospel_reading", "jesus_prayer", "small_compline"
	Title       string `json:"title"`       // e.g. "Πρωινή Προσευχή"
	Description string `json:"description"` // e.g. "Εξέγερσις εκ του ύπνου & Τρισάγιον"
	Icon        string `json:"icon"`        // "sun", "book", "komboskini", "moon"
	Points      int    `json:"points"`      // e.g. 25
	Completed   bool   `json:"completed"`
	CompletedAt string `json:"completed_at,omitempty"`
}

// DailyPrayerRuleStatus encapsulates the user's prayer rule state and streak
type DailyPrayerRuleStatus struct {
	Date               string           `json:"date"`
	Items              []PrayerRuleItem `json:"items"`
	CompletedCount     int              `json:"completed_count"`
	TotalCount         int              `json:"total_count"`
	TotalPointsEarned  int              `json:"total_points_earned"`
	StreakDays         int              `json:"streak_days"`
}
