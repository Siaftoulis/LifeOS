package prayers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
)

type OctoechosTone struct {
	ToneNumber string          `json:"tone_number"`
	ToneName   string          `json:"tone_name"`
	ToneNameGr string          `json:"tone_name_greek"`
	Services   []PrayerService `json:"services"`
}

type OctoechosData struct {
	Title       string          `json:"title"`
	TitleTrans  string          `json:"title_transliterated"`
	Description string          `json:"description"`
	Tones       []OctoechosTone `json:"tones"`
}

var octoechosCache *OctoechosData

func loadOctoechos() (*OctoechosData, error) {
	if octoechosCache != nil {
		return octoechosCache, nil
	}

	tones := make([]OctoechosTone, 0, 8)
	for i := 1; i <= 8; i++ {
		h, exists := OctoechosFullHymns[i]
		if !exists {
			continue
		}

		// 1. Vespers Service
		vespSecs := []PrayerSection{
			{
				Header: "Κεκραγάρια & Αναστάσιμα Στιχηρά",
				Content: fmt.Sprintf("Στιχηρὰ Κεκραγαρίων:\n\n1. %s\n\n2. %s\n\n3. %s\n\nΔογματικὸν Θεοτοκίον:\n%s",
					h.KekragariaStichera[0], h.KekragariaStichera[1], h.KekragariaStichera[2], h.Theotokion),
			},
			{
				Header: "Απόστιχα Αναστάσιμα",
				Content: fmt.Sprintf("Ἀπόστιχα Ἑσπερινοῦ:\n\n1. %s\n\n2. %s\n\n3. %s\n\nΘεοτοκίον Ἀποστίχων:\n%s",
					h.ApostichaVespers[0], h.ApostichaVespers[1], h.ApostichaVespers[2], h.Theotokion),
			},
			{
				Header: "Απολυτίκιον & Θεοτοκίον",
				Content: fmt.Sprintf("Ἀναστάσιμον Ἀπολυτίκιον:\n%s\n\nΘεοτοκίον Ἀπολυτικίου:\n%s",
					h.Apolytikion, h.Theotokion),
			},
		}

		vespSvc := PrayerService{
			ID:           fmt.Sprintf("octoechos_vespers_tone_%d", i),
			Title:        fmt.Sprintf("Αναστάσιμος Εσπερινός — %s", h.ToneName),
			Category:     "Οκτώηχος (Παρακλητική)",
			Subtitle:     fmt.Sprintf("Πλήρης Ἑσπερινὸς Σαββάτου (%s)", h.ToneName),
			EstimatedMin: 30,
			Sections:     vespSecs,
		}

		// 2. Matins Service
		matSecs := []PrayerSection{
			{
				Header: "Απολυτίκιον & Θεοτοκίον",
				Content: fmt.Sprintf("Ἀναστάσιμον Ἀπολυτίκιον:\n%s\n\nΘεοτοκίον:\n%s",
					h.Apolytikion, h.Theotokion),
			},
			{
				Header: "Αναστάσιμα Καθίσματα (Στιχολογίαι Α' & Β')",
				Content: fmt.Sprintf("ΣΤΙΧΟΛΟΓΙΑ Α':\n%s\n\nΣΤΙΧΟΛΟΓΙΑ Β':\n%s",
					h.Kathisma1, h.Kathisma2),
			},
			{
				Header: "Υπακοή, Αναβαθμοί & Προκείμενον",
				Content: fmt.Sprintf("Ἡ Ὑπακοή:\n%s\n\nΟἱ Ἀναβαθμοὶ (Ἀντίφωνον Α'):\n%s\n\nΠροκείμενον Ὄρθρου:\n%s\nΣτίχος: %s",
					h.Hypakoe, h.Anavathmoi, h.ProkeimenonMatins, h.ProkeimMatinsStich),
			},
			{
				Header: "Αναστάσιμοι Αίνοι & Στιχηρά",
				Content: fmt.Sprintf("Στιχηρὰ τῶν Αἴνων:\n\n1. %s\n\n2. %s\n\n3. %s",
					h.AinoiStichera[0], h.AinoiStichera[1], h.AinoiStichera[2]),
			},
			{
				Header: "Κοντάκιον του Ήχου",
				Content: fmt.Sprintf("Ἀναστάσιμον Κοντάκιον:\n%s", h.Kontakion),
			},
		}

		matSvc := PrayerService{
			ID:           fmt.Sprintf("octoechos_matins_tone_%d", i),
			Title:        fmt.Sprintf("Αναστάσιμος Όρθρος — %s", h.ToneName),
			Category:     "Οκτώηχος (Παρακλητική)",
			Subtitle:     fmt.Sprintf("Πλήρης Ὄρθρος Κυριακῆς (%s)", h.ToneName),
			EstimatedMin: 40,
			Sections:     matSecs,
		}

		tones = append(tones, OctoechosTone{
			ToneNumber: fmt.Sprintf("%d", i),
			ToneName:   h.ToneName,
			ToneNameGr: h.ToneName,
			Services:   []PrayerService{vespSvc, matSvc},
		})
	}

	octoechosCache = &OctoechosData{
		Title:       "Οκτώηχος (Παρακλητική)",
		TitleTrans:  "Octoechos",
		Description: "Η πλήρης υμνογραφία των οκτώ ήχων της Ορθοδόξου Εκκλησίας (Κεκραγάρια, Απόστιχα, Αίνοι, Καθίσματα, Αναβαθμοί, Εωθινά).",
		Tones:       tones,
	}

	return octoechosCache, nil
}

func RegisterOctoechosRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/prayers/octoechos", handleOctoechosList)
	mux.HandleFunc("/api/v1/prayers/octoechos/tone", handleOctoechosTone)
	mux.HandleFunc("/api/v1/prayers/octoechos/service", handleOctoechosService)
	mux.HandleFunc("/api/v1/prayers/eothina", handleEothinaList)
}

func handleOctoechosList(w http.ResponseWriter, r *http.Request) {
	oct, err := loadOctoechos()
	if err != nil {
		http.Error(w, `{"error":"failed to load octoechos"}`, http.StatusInternalServerError)
		return
	}
	type ToneSummary struct {
		ToneNumber   string `json:"tone_number"`
		ToneName     string `json:"tone_name"`
		ToneNameGr   string `json:"tone_name_greek"`
		ServiceCount int    `json:"service_count"`
		SectionCount int    `json:"section_count"`
	}
	var summaries []ToneSummary
	for _, t := range oct.Tones {
		secCount := 0
		for _, s := range t.Services {
			secCount += len(s.Sections)
		}
		summaries = append(summaries, ToneSummary{
			ToneNumber:   t.ToneNumber,
			ToneName:     t.ToneName,
			ToneNameGr:   t.ToneNameGr,
			ServiceCount: len(t.Services),
			SectionCount: secCount,
		})
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"title":       oct.Title,
		"description": oct.Description,
		"tones":       summaries,
	})
}

func handleOctoechosTone(w http.ResponseWriter, r *http.Request) {
	oct, err := loadOctoechos()
	if err != nil {
		http.Error(w, `{"error":"failed to load octoechos"}`, http.StatusInternalServerError)
		return
	}
	toneParam := r.URL.Query().Get("tone")
	if toneParam == "" {
		http.Error(w, `{"error":"missing tone parameter"}`, http.StatusBadRequest)
		return
	}

	for _, t := range oct.Tones {
		if t.ToneNumber == toneParam || t.ToneName == toneParam || t.ToneNameGr == toneParam {
			w.Header().Set("Content-Type", "application/json; charset=utf-8")
			json.NewEncoder(w).Encode(t)
			return
		}
	}
	http.Error(w, `{"error":"tone not found"}`, http.StatusNotFound)
}

func handleOctoechosService(w http.ResponseWriter, r *http.Request) {
	oct, err := loadOctoechos()
	if err != nil {
		http.Error(w, `{"error":"failed to load octoechos"}`, http.StatusInternalServerError)
		return
	}
	id := r.URL.Query().Get("id")
	if id == "" {
		http.Error(w, `{"error":"missing id parameter"}`, http.StatusBadRequest)
		return
	}
	for _, t := range oct.Tones {
		for _, s := range t.Services {
			if s.ID == id {
				w.Header().Set("Content-Type", "application/json; charset=utf-8")
				json.NewEncoder(w).Encode(s)
				return
			}
		}
	}
	http.Error(w, `{"error":"service not found"}`, http.StatusNotFound)
}

func handleEothinaList(w http.ResponseWriter, r *http.Request) {
	numParam := r.URL.Query().Get("num")
	if numParam != "" {
		n, err := strconv.Atoi(numParam)
		if err == nil && n >= 1 && n <= 11 {
			rec := EothinaTable[n]
			w.Header().Set("Content-Type", "application/json; charset=utf-8")
			json.NewEncoder(w).Encode(rec)
			return
		}
	}

	list := make([]EothinonRecord, 0, 11)
	for i := 1; i <= 11; i++ {
		list = append(list, EothinaTable[i])
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"title":       "Τα 11 Εωθινά Ευαγγέλια & Δοξαστικά (Λέοντος ΣΤ' του Σοφού)",
		"count":       len(list),
		"eothina":     list,
	})
}
