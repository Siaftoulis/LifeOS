## LifeOS v1.6.5 (Build #85)

### 1. Εξάλειψη Αναβοσβήματος Widget & Dropdown Ειδοποιήσεων (Huawei & Android MediaStyle)
* **Αποτροπή Επανειλημμένου Επανασχεδιασμού**: Εξάλειψη του φαινομένου αναβοσβήματος και συνεχούς εναλλαγής μεταξύ εξωφύλλου και εικονιδίου αναπαραγωγής (ic_music_play) κάθε δευτερόλεπτο κατά τη ροή των χρονικών θέσεων αναπαραγωγής.
* **Ενσωματωμένη Μνήμη Cache Bitmaps**: Προσθήκη τοπικής προσωρινής μνήμης εξωφύλλων (cachedBitmap, cachedRoundedBitmap) στα LifeOSWidgetProvider και MediaNotificationManager. Τα ήδη αποκωδικοποιημένα εξώφυλλα διατηρούνται άμεσα χωρίς ενδιάμεσο κενό εικονίδιο.
* **Διαχωρισμός Ενημερώσεων Θέσης από Μεταδεδομένα**: Οι τακτικές ενημερώσεις θέσης (positionMs) ανανεώνουν πλέον αποκλειστικά το PlaybackStateCompat του MediaSession για την ομαλή κίνηση της μπάρας προόδου στο Android 13+ και στο EMUI/Huawei, αποτρέποντας την περιττή αναδημοσίευση της ειδοποίησης και του widget.
* **Άμεση Εφαρμογή Εξωφύλλων Συσκευής (Phone Storage)**: Πλήρης υποστήριξη ανάκτησης ενσωματωμένων εξωφύλλων ID3/MediaStore από κομμάτια εξωτερικής αποθήκευσης τηλεφώνου για το widget και τη γραμμή ειδοποιήσεων.

### 2. Διόρθωση Ψυχρής Εκκίνησης (Cold Start) & Εμφάνισης Πληκτρολογίου / Μαύρης Οθόνης
* **Αφαίρεση Καθολικού onLongPress**: Κατάργηση της καθολικής χειρονομίας παρατεταμένου πατήματος από τον καμβά του SpatialEngineScaffold, η οποία προκαλούσε ακούσιο άνοιγμα του διαλόγου αναζήτησης και μαύρη οθόνη κατά την αλληλεπίδραση αφής στο κινητό.
* **Απόκριση Διαλόγου Αναζήτησης σε Mobile**: Προσαρμογή του πλάτους του GlobalSearchDialog στις διαστάσεις οθόνης κινητού και απενεργοποίηση του autofocus σε φορητές συσκευές, αποτρέποντας το αυτόματο πέταγμα του εικονικού πληκτρολογίου κατά την εκκίνηση.
* **Εγγυημένη Αναπαραγωγή Cold Start**: Πλήρης υποστήριξη εκκίνησης αναπαραγωγής με το πάτημα του κουμπιού Play ακόμα και όταν η εφαρμογή ξεκινά από το μηδέν (cold start) με κενή ουρά. Η μηχανή αναπαραγωγής αρχικοποιείται αυτόματα και ανακτά άμεσα το τελευταίο κομμάτι από τις ρυθμίσεις ή τις τοπικές λήψεις.

### 3. Πλήρης Εγγενής Λειτουργία DSP & Equalizer στο Κινητό (Android Hardware EQ)
* **Ακαριαία Σύνδεση Hardware Bands**: Άμεση καταγραφή των παραμέτρων του AndroidEqualizer κατά τη δημιουργία του audio session στο ExoPlayer μέσω ασύγχρονης σύνδεσης (.then()), εξαλείφοντας τις καθυστερήσεις και τα timeouts των 2 δευτερολέπτων κατά τη ρύθμιση των sliders.
* **Οριστική Αφαίρεση Παράκαμψης Hardware EQ**: Πλήρης κατάργηση των μηχανισμών _reinitWithoutPipeline και disableHardwareEq. Το εγγενές hardware Equalizer παραμένει ενεργό και λειτουργικό στο 100% τόσο για streaming μουσική όσο και για τοπικά αρχεία, χωρίς κανένα lag ή ακούσια απενεργοποίηση.
* **Χειριστήριο DJ Crossfade & Χρόνου Μίξης**: Ενσωμάτωση επιλογέα διάρκειας μίξης DJ Crossfade (1 έως 12 δευτερόλεπτα) και διακόπτη Studio Equal-Power μετάβασης απευθείας στην οθόνη του DSP Equalizer.

### 4. Καθαρός Διαχωρισμός Τριών Επιπέδων Αποθήκευσης Μουσικής
* **Server Vault**: Κεντρική αποθήκη τραγουδιών του διακομιστή (All Songs / Vault), λίστες αναπαραγωγής, καλλιτέχνες, είδη και έξυπνες μίξεις.
* **Local Storage (Λήψεις Εφαρμογής)**: Τραγούδια που έχουν κατέβει εντός της εφαρμογής LifeOS για offline αναπαραγωγή μέσω της τοπικής βάσης δεδομένων Drift.
* **Phone Storage (Αρχεία Συσκευής)**: Εξωτερικά αρχεία ήχου της συσκευής και της κάρτας SD με αναγνωριστικά τύπου αρχείου (MP3, FLAC, M4A) και άμεση υποστήριξη ουράς αναπαραγωγής και DJ crossfade.

---

### English Summary
* **Eliminated Widget and Media Notification Flickering**: Prevented cover art and controls from flashing to default play icon on periodic position ticks via memory bitmap caching (cachedBitmap, cachedRoundedBitmap) and metadata change detection in LifeOSWidgetProvider and MediaNotificationManager. Position ticks now exclusively update PlaybackStateCompat without rebuilding notifications.
* **Fixed Cold Start Playback and Mobile Search Overlay**: Removed aggressive global onLongPress on the spatial canvas that caused unwanted search popups and black screens on touch devices. Disabled virtual keyboard autofocus and added responsive width on mobile in GlobalSearchDialog. Cold start play button now auto-initializes audio engine and restores last played or offline tracks.
* **100% Reliable Native Android DSP Equalizer**: Attached hardware EQ parameters eagerly on audio session creation, eliminating 2-second slider IPC timeouts. Removed all hardware EQ bypass mechanisms (_reinitWithoutPipeline, disableHardwareEq) so native Android DSP remains active across both streaming and local audio. Added interactive DJ Crossfade duration slider (1-12s) directly into the DSP modal.
* **Three Distinct Storage Tiers**: Clearly categorized music library tabs into Server Vault, Local Storage (in-app offline downloads via Drift), and Phone Storage (device/SD card external files via MediaStore) with file format badges and embedded artwork extraction.
