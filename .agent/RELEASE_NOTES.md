## LifeOS v1.6.2 (Build #82)

### 1. Διαχείριση Χρηστών & Admin Console
* **Πλήρες Σύστημα Multi-User**: Υποστήριξη πολλαπλών χρηστών στη βάση δεδομένων του host daemon, με απομονωμένες λίστες αναπαραγωγής (playlists) και ρυθμίσεις ανά λογαριασμό.
* **Κονσόλα Διαχειριστή (Admin Console)**: Νέο περιβάλλον διαχείρισης με δυνατότητες δημιουργίας νέων χρηστών, ανάθεσης ρόλων (ADMIN / USER), επεξεργασίας στοιχείων και επαναφοράς κωδικών πρόσβασης.
* **Προστασία & Αυτοματοποιημένη Σύνδεση**: Ενσωμάτωση ασφαλούς ελέγχου ταυτότητας μέσω JWT tokens με εξαίρεση των αξιόπιστων τοπικών κόμβων (mesh/Tailscale) από τους περιορισμούς του rate limiter.

### 2. Προφίλ Χρήστη, Custom Frames & Live Online Presence
* **Προσαρμογή Προφίλ & Avatar Frames**: Προσθήκη επιλογής custom πλαισίων γύρω από το avatar (Neon, Gold, Cyber, Minimal, Retro) και διαμόρφωση στο προφίλ χρήστη.
* **Παρακολούθηση Ενεργών Χρηστών (Live Presence)**: Υλοποίηση μηχανισμού heartbeat στο backend και προβολή των συνδεδεμένων χρηστών σε πραγματικό χρόνο στις ρυθμίσεις.

### 3. Καθολική Αναζήτηση & Συντομεύσεις
* **Συντομεύσεις Πληκτρολογίου**: Άνοιγμα του Global Search με το πάτημα του backtick (`) ή tilde (~) πέραν του κλασικού Ctrl+K.
* **Smart Focus Detection**: Αυτόματη ανίχνευση εστίασης σε πεδία κειμένου (EditableText, TextField, AppFlowy) ώστε οι συντομεύσεις να μην διακόπτουν την πληκτρολόγηση σημειώσεων ή εντολών.
* **Χειρονομία Mobile**: Ενεργοποίηση της αναζήτησης με παρατεταμένο πάτημα (long press) σε κενό σημείο του καμβά.
* **Επανασχεδιασμός Θέσης**: Αφαίρεση του παλαιού κουμπιού από την επάνω αριστερή γωνία και μετατροπή του σε κεντρικό omnibar κάτω από το ρολόι στην αρχική οθόνη.

### 4. Βελτιστοποίηση Web Έκδοσης (Zero-Lag Startup)
* **Προ-συμπίεση Gzip**: Όλα τα στατικά αρχεία Web (.js, .wasm, .html, .css) συμπιέζονται σε επίπεδο build, μειώνοντας δραστικά τους χρόνους μεταφοράς.
* **Εξάλειψη Καθυστέρησης Service Worker**: Αφαίρεση του προεπιλεγμένου timeout 4 δευτερολέπτων κατά την εκκίνηση του Flutter loader.
* **Τοπικό CanvasKit**: Εξαναγκασμός φόρτωσης του CanvasKit απευθείας από τον τοπικό διακομιστή αντί για εξωτερικά CDNs (gstatic), επιτυγχάνοντας πλήρη λειτουργία εκτός σύνδεσης.

### 5. Mobile OTA & CI/CD Pipeline
* **Universal APK για OTA**: Ενοποίηση σε ενιαίο Universal APK αντί για διαχωρισμένα ABI splits, διασφαλίζοντας απρόσκοπτη εγκατάσταση ενημερώσεων σε οποιαδήποτε συσκευή Android.
* **Επιδιόρθωση CI Testing**: Προσθήκη προπαρασκευαστικού βήματος (patch appflowy) στους runners του GitHub Actions για αποφυγή false-positive αποτυχιών κατά την εκτέλεση των δοκιμών.

---

### English Summary
* **Multi-User & Admin Console**: Multi-tenant database support, per-user playlists/settings, administrative user management console (role assignment, password resets, user creation), and Tailscale-aware rate-limiting.
* **Profile Customization & Live Presence**: Custom avatar frames (Neon, Gold, Cyber, Minimal, Retro) and real-time backend heartbeat session tracking showing live connected peers.
* **Global Search Shortcuts**: Global search activation via backtick (`) and tilde (~), smart input-field focus detection to prevent accidental activation while typing, canvas long-press on mobile, and centered home screen omnibar.
* **Web Zero-Lag Startup**: Build-time Gzip pre-compression of static assets, removal of 4-second service worker initialization freeze, and forced local CanvasKit bundling.
* **Mobile OTA & CI/CD Pipeline**: Universal release APK packaging for reliable OTA installs across all architectures, and AppFlowy editor pre-patching in CI runner test workflows.
