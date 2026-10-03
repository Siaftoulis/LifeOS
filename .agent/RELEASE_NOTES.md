## LifeOS v1.6.4 (Build #84)

### 1. Android Home Screen Widget & Native Media Actions
* **Αξιόπιστη Λειτουργία Widget & Remote Actions**: Πλήρης επανασχεδιασμός των LifeOSWidgetProvider και MediaActionReceiver. Η αναπαραγωγή, η παύση και η εναλλαγή κομματιών λειτουργούν ακαριαία από το widget της αρχικής οθόνης ακόμα και όταν η εφαρμογή είναι πλήρως κλειστή (cold start) μέσω ασφαλούς ουράς ενεργειών (pendingMediaAction).
* **Αισιόδοξη Απόκριση 0ms**: Άμεση οπτική εναλλαγή του εικονιδίου Play/Pause στο widget με το πάτημα του χρήστη, πριν από την ολοκλήρωση της ασύγχρονης επικοινωνίας με το Flutter engine.
* **Προστασία Ορίων Συστήματος (Binder Limit Safe)**: Αυτόματη κλιμάκωση (downsampling) των εικόνων εξωφύλλων ώστε να μην υπερβαίνουν το όριο συναλλαγών του Android IPC (TransactionTooLargeException), εξαλείφοντας οριστικά το κρασάρισμα του widget.
* **Ανάκτηση Ενσωματωμένων Εξωφύλλων (ID3 APIC & MediaStore)**: Υποστήριξη εξαγωγής ενσωματωμένων εξωφύλλων από τοπικά αρχεία ήχου (.mp3, .m4a, .flac, .wav) και τραγούδια συσκευής (phone_<id>) μέσω MediaMetadataRetriever τόσο για το home widget όσο και για τις ειδοποιήσεις συστήματος.
* **Στρογγυλεμένα Background Drawables**: Χρήση διανυσματικών σχεδίων παρασκηνίου με ακτίνα 20dp και φωτεινά περιγράμματα (glass, oled, accent, border) που διατηρούνται άψογα σε όλους τους launchers χωρίς απώλεια καμπυλότητας.
* **Αυτόματη Επαναφορά Ουράς**: Αποθήκευση του τελευταίου κομματιού στο SharedPreferences και αυτόματη επαναφορά κατά την εκκίνηση, επιτρέποντας την άμεση συνέχιση αναπαραγωγής από το widget χωρίς κενή ουρά.

### 2. Ανακάλυψη Μουσικής & Ενσωματωμένη Αναζήτηση (YouTube Music & Spotify Hybrid)
* **Δυναμικό Feed στην Αναζήτηση**: Τοποθέτηση της κεντρικής ροής Feed απευθείας στην οθόνη αναζήτησης. Όταν το πεδίο αναζήτησης είναι κενό, εμφανίζεται η πλήρης ροή ανακάλυψης με φίλτρα διάθεσης (All, Energize, Relax, Workout, Focus, Greek Hits, Daily Mix), Quick Picks, Made For You και Listen Again.
* **Άμεση Μετάβαση σε Live Αποτελέσματα**: Με την πληκτρολόγηση οποιουδήποτε όρου, η προβολή μεταβαίνει ακαριαία στα κατηγοριοποιημένα αποτελέσματα (YouTube Music Online, Τοπική Βιβλιοθήκη, Άλμπουμ, Καλλιτέχνες) και επιστρέφει ομαλά στο Feed με τον καθαρισμό του πεδίου.
* **Αναπαραγωγή Πλήρους Μίξης**: Το πάτημα σε κάρτες του Feed ξεκινά πλέον ολόκληρη τη σχετική λίστα αναπαραγωγής από το επιλεγμένο σημείο αντί για μεμονωμένο κομμάτι.

### 3. Έξυπνο Ραδιόφωνο Χωρίς Επαναλήψεις (Anti-Repeat Smart Radio)
* **Αποτροπή Βρόχου Remix**: Αυστηρός έλεγχος αποδιπλασιασμού τίτλων και φιλτράρισμα ανεπιθύμητων remix, VIP edits, covers, karaoke και slowed/reverb εκδόσεων του ίδιου τραγουδιού στο Go backend (recommendations.go).
* **Ποικιλομορφία Καλλιτεχνών**: Επιβολή ανώτατου ορίου δύο κομματιών ανά καλλιτέχνη σε κάθε αυτόματη επέκταση ουράς ραδιοφώνου.
* **Έξυπνα Fallback Queries**: Αναζήτηση βάσει ύφους καλλιτέχνη και είδους αντί για τον τίτλο του κομματιού σε περιπτώσεις εφεδρικής αναζήτησης, αποτρέποντας τις συνεχόμενες επαναφορτώσεις της ίδιας σύνθεσης.

### 4. Διαχωρισμός Τοπικών Αρχείων & Λήψεων LifeOS
* **Αυτόνομες Καρτέλες Βιβλιοθήκης**: Πλήρης διαχωρισμός των τραγουδιών του τηλεφώνου (Phone Storage Audio μέσω MediaStore) και των λήψεων του LifeOS Offline Vault σε δύο ξεχωριστές καρτέλες.
* **Διαρκές Mini Player**: Διόρθωση του ελέγχου hasActivePlayback ώστε η μπάρα του mini player να παραμένει ορατή και λειτουργική κατά την επαναφορά της εφαρμογής.

### 5. Ισοσταθμιστής & Επεξεργασία Ήχου (Poweramp EQ)
* **Συνεχής Λειτουργία Equalizer**: Σωστή σύνδεση του ηχητικού pipeline DSP και στους δύο players της μηχανής αναπαραγωγής, εξασφαλίζοντας ότι τα εφέ EQ δεν διακόπτονται κατά τις εναλλαγές κομματιών και τα crossfades.
* **Επανασχεδιασμός UI με Ετικέτες**: Αντικατάσταση των απλών εικονιδίων με σαφείς καρτέλες κειμένου (Equalizer, Tone & Reverb, Spatial & Limiter) για ευκολότερη πλοήγηση.

### 6. Εξάλειψη Καθυστερήσεων σε Πληκτρολόγιο & Αλλαγή Μεγέθους Παραθύρου
* **Αποσύνδεση Insets από τον Χωρικό Καμβά**: Ορισμός resizeToAvoidBottomInset σε false στο βασικό Scaffold, αποτρέποντας τον υπολογισμό διαστάσεων 30+ modules σε κάθε καρέ της κίνησης του εικονικού πληκτρολογίου.
* **Άμεσος Συγχρονισμός Μετατόπισης**: Άμεση ενημέρωση του base offset κατά την αλλαγή διαστάσεων παραθύρου χωρίς καθυστέρηση post-frame callback, εξαλείφοντας κάθε τρέμουλο κατά την ελαχιστοποίηση, μεγιστοποίηση και επαναφορά παραθύρων σε desktop και mobile.

---

### English Summary
* **Android Home Screen Widget & Remote Actions**: Overhauled LifeOSWidgetProvider and MediaActionReceiver with 0ms optimistic playback toggling, pending action queuing for cold start execution, scaled album art rendering protecting against Android IPC Binder TransactionTooLargeException, ID3 embedded picture decoding from local audio files and MediaStore URIs, and persistent 20dp rounded background drawables.
* **Discovery Feed & Live Search Hybrid**: Integrated the dynamic music feed directly into the search destination with mood filter chips, Quick Picks, and Made For You carousels when the query is cleared, switching smoothly to categorized live search results when typing.
* **Anti-Repeat Smart Radio**: Upgraded Go recommendations daemon with strict seed title deduplication, remix and cover exclusion filters, artist diversity caps, and vibe-targeted fallback queries.
* **Separated Local Storage vs. Vault Downloads**: Created dedicated, independent library tabs for device phone storage audio and LifeOS offline vault downloads.
* **Equalizer Reliability & Modernized Tabs**: Ensured uninterrupted DSP pipeline across dual-player crossfade transitions and redesigned top selector tabs with explicit labels (Equalizer, Tone & Reverb, Spatial & Limiter).
* **Butter-Smooth Keyboard & Resize Transitions**: Disabled full canvas bottom inset resizing and synchronized layout offsets immediately, eliminating stutter during virtual keyboard appearance and window resizing.
