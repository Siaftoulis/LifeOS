## LifeOS v1.6.6 (Build #86)

### 1. Οριστική Εξάλειψη Αυτόματης Εμφάνισης Πληκτρολογίου σε Xiaomi & Android (MIUI / HyperOS)
* **stateAlwaysHidden στο AndroidManifest**: Ρύθμιση του android:windowSoftInputMode σε "adjustResize|stateAlwaysHidden" τόσο στο AndroidManifest.xml όσο και στο MainActivity.kt (SOFT_INPUT_STATE_ALWAYS_HIDDEN). Το λειτουργικό σύστημα Android δεν εμφανίζει πλέον ποτέ αυτόματα το εικονικό πληκτρολόγιο κατά την εκκίνηση της εφαρμογής ή την επαναφορά εστίασης.
* **Απενεργοποίηση autoFocus στο AppFlowy Editor**: Αλλαγή του autoFocus σε false στο widget του AppFlowyEditor. Το πληκτρολόγιο εμφανίζεται αποκλειστικά και μόνο όταν ο χρήστης πατήσει ενεργά πάνω σε ένα μπλοκ κειμένου.
* **Κατάργηση Αυτόματης Εστίασης κατά το Φόρτωμα Σημειώσεων**: Αφαίρεση του programmatic requestFocus() και της αυτόματης επιλογής κέρσορα στο πρώτο μπλοκ κατά το αρχικό άνοιγμα αρχείου στο ZenWorkspace, εξαλείφοντας το πάγωμα και την άσκοπη εμφάνιση του πληκτρολογίου κατά την εκκίνηση του καμβά.
* **Υπό Συνθήκη Focus στο LifeOSMainStack**: Περιορισμός του autofocus του κεντρικού Focus widget αποκλειστικά σε Desktop περιβάλλοντα (Windows/macOS/Linux) για τα συντομεύσεις πληκτρολογίου, αποτρέποντας την προσκόλληση του IME σε Android και iOS συσκευές.
* **Αυτόματο Unfocus κατά τη Μετακίνηση στον Χωρικό Καμβά**: Κατά τη μετάβαση ανάμεσα στα πλακίδια του SpatialEngine (navigateTo), εκτελείται άμεση απόσυρση εστίασης (primaryFocus?.unfocus()) για καθαρή και ομαλή πλοήγηση χωρίς ενεργό πληκτρολόγιο.

---

### English Summary
* **Permanently Prevent Soft Keyboard Auto-Popup on Startup (Xiaomi HyperOS / Android)**: Configured windowSoftInputMode to "adjustResize|stateAlwaysHidden" in AndroidManifest.xml and MainActivity.kt to strictly prevent Android IME from auto-opening on activity launch or resume.
* **Disabled autoFocus in AppFlowy Editor**: Set autoFocus to false on the AppFlowyEditor widget so the virtual keyboard only appears when an input block is explicitly tapped by the user.
* **Removed Auto-Focus on Note Open in ZenWorkspace**: Eliminated programmatic requestFocus() and initial collapsed selection on document load, preventing screen freezing and unwanted keyboard invocation on startup.
* **Desktop-Only Focus on Main Stack**: Restricted root Focus autofocus to desktop platforms (Windows/Linux/macOS) for global keyboard shortcuts, keeping mobile IME disconnected on launch.
* **Automatic IME Dismissal on Spatial Navigation**: Primary focus is automatically unfocused when navigating between spatial grid tiles in SpatialEngine.
