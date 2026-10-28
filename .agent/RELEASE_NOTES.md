## LifeOS v1.6.7 (Build #87)

### 1. Εξάλειψη Καθυστερήσεων Φόρτωσης & Infinite Loading στο Music Player (Xiaomi / Android)
* **Πρόωρη Ενεργοποίηση playWhenReady (Eager Playback)**: Προσθήκη παραμέτρου autoPlay στο setUrl() του PlaybackEngine (τόσο σε Native ExoPlayer όσο και σε Web). Όταν ο χρήστης επιλέγει ένα τραγούδι, το σήμα αναπαραγωγής δίνεται άμεσα στον player πριν και κατά τη διάρκεια της φόρτωσης του stream, αποτρέποντας την είσοδο του ExoPlayer σε κατάσταση αδρανούς αναμονής (idle buffering) υπό τους επιθετικούς κανόνες εξοικονόμησης ενέργειας του Xiaomi HyperOS/MIUI.
* **Αποτροπή Κλειδώματος Ατέρμονης Φόρτωσης (Watchdog Hard-Timeout)**: Ο χρονοδιακόπτης επιτήρησης (_startWatchdog) ξεκινά πλέον ακαριαία με την έναρξη του _playAt() και ελέγχει την κατάσταση κάθε 250ms. Εάν ο player προχωρήσει στην αναπαραγωγή (>200ms), η ένδειξη φόρτωσης εξαφανίζεται αμέσως. Σε περίπτωση καθυστέρησης δικτύου (>3 δευτερόλεπτα), ο watchdog εξαναγκάζει επανεκκίνηση αναπαραγωγής και ακυρώνει το spinner φόρτωσης, εξαλείφοντας οριστικά το φαινόμενο infinite loading.
* **Κατάργηση Περιττού Συγχρονισμένου Stop**: Αφαίρεση της συγχρονισμένης κλήσης stop() πριν τη φόρτωση νέου κομματιού, η οποία κατέστρεφε την υπάρχουσα ηχητική συνεδρία και καθυστερούσε την εκκίνηση του επόμενου τραγουδιού κατά 500-1500ms. Το just_audio και το ExoPlayer αποδεσμεύουν αυτόματα την προηγούμενη πηγή κατά τη μετάβαση.
* **Ακαριαία Μετάβαση Επόμενου Τραγουδιού**: Στη συνάρτηση _performCrossfadeTransition(), εάν ο εφεδρικός player (standby) δεν έχει προφορτωθεί εγκαίρως, εκτελείται άμεση μετάβαση μέσω playAt() χωρίς αναμονή φόρτωσης στη μέση της αλλαγής κομματιού.
* **Αυτόματη Προφορτόωση σε Streams χωρίς Content-Length**: Προσθήκη μηχανισμού προφόρτωσης του επόμενου κομματιού στον standby player μετά από 45 δευτερόλεπτα αναπαραγωγής σε ζωντανές ροές ήχου όπου η συνολική διάρκεια δεν παρέχεται εξαρχής.

### 2. Άμεση Ροή Ήχου στο Backend (HTTP Flusher για ExoPlayer Headers)
* **Άμεση Αποστολή Κεφαλίδων Ήχου**: Στο HandleYTStream (proxyLiveAudio) του Go host-daemon, ενσωματώθηκε άμεση έκπλυση (http.Flusher) στο πρώτο πακέτο δεδομένων ροής. Οι κεφαλίδες του κοντέινερ ήχου (MP4/Opus) αποστέλλονται στον client σε πραγματικό χρόνο χωρίς να περιμένουν τη συσσώρευση του εσωτερικού buffer των 32KB, μειώνοντας δραστικά τον χρόνο έναρξης αποκωδικοποίησης στις φορητές συσκευές.

---

### English Summary
* **Eliminated Music Player Loading Delays and Infinite Loading on Xiaomi/Android**: Added eager autoPlay parameter in PlaybackEngine.setUrl() to set playWhenReady=true upfront, preventing ExoPlayer from stalling in STATE_BUFFERING under Xiaomi HyperOS battery throttling.
* **Watchdog Buffer-Stall Protection**: Started watchdog immediately on track selection (polling every 250ms), auto-clearing loading indicators on progress and enforcing a 3-second hard limit to prevent infinite loading spinners.
* **Removed Redundant Pre-Stop Overhead**: Eliminated blocking await stop() before loading new track URLs, allowing ExoPlayer to reuse audio session buffers and shaving 500-1500ms off track change latency.
* **Seamless Next-Track Transitions**: _performCrossfadeTransition now falls back instantly to eager playAt() if the standby track is not yet primed, preventing stalls between songs. Added standby preloading after 45s for live audio streams without fixed content lengths.
* **Backend Audio Stream Immediate Flushing**: Integrated http.Flusher in Go daemon proxyLiveAudio to flush the first audio header chunk immediately, allowing mobile ExoPlayer to parse codec headers in milliseconds.
