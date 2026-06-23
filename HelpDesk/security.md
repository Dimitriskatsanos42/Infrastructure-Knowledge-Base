# 🛡️ Windows Security & Incident Response Reference

### *Cybersecurity Auditing, Incident Response & System Hardening Guide*

Ο παρών οδηγός επικεντρώνεται σε εντολές (CMD/PowerShell) που χρησιμοποιούνται από αναλυτές ασφάλειας (Security Analysts) και μηχανικούς συστημάτων για τον εντοπισμό απειλών, τον έλεγχο δικαιωμάτων πρόσβασης και τη θωράκιση του λειτουργικού συστήματος Windows.

---

## 🔍 1. Ανίχνευση Κακόβουλης Δραστηριότητας (Malware & Persistence Triage)

Όταν ένα σύστημα είναι ύποπτο για μόλυνση, οι παρακάτω εντολές βοηθούν στον εντοπισμό μη εξουσιοδοτημένων διεργασιών ή μηχανισμών σταθερότητας (persistence).

| Εντολή | Ανάλυση | Security Use Case |
| :--- | :--- | :--- |
| `wmic process get name,executablepath,processid` | Εμφανίζει όλες τις τρέχουσες διεργασίες μαζί με την ακριβή τοποθεσία του αρχείου `.exe` στον δίσκο. | Οι επιτιθέμενοι συχνά ονομάζουν κακόβουλα αρχεία ως `svchost.exe` για να κρυφτούν. Αν ένα τέτοιο αρχείο τρέχει από το `C:\Users\...\Downloads`, πρόκειται για malware. |
| `schtasks /query /fo TABLE /nh` | Καταγράφει όλες τις Προγραμματισμένες Εργασίες (Scheduled Tasks) στο σύστημα. | Εντοπισμός malware που δημιουργούν εργασίες για να εκτελούνται αυτόματα μετά από επανεκκίνηση. |
| `fltmc filters` | Εμφανίζει τους οδηγούς φιλτραρίσματος συστήματος αρχείων (File System Filter Drivers). | Επιβεβαίωση ότι το Antivirus/EDR (π.χ. Defender) είναι ενεργό στο File System Layer, ή ανίχνευση ύποπτων rootkits. |

---

## 🔐 2. Έλεγχος Πρόσβασης & Δικαιωμάτων (Access Control & Privilege Audit)

Ένα από τα βασικότερα βήματα στην ασφάλεια είναι η αρχή του ελάχιστου δικαιώματος (Principle of Least Privilege).

| Εντολή | Ανάλυση | Security Use Case |
| :--- | :--- | :--- |
| `icacls "C:\κρίσιμος_φάκελος" /inheritance:r` | Διαχειρίζεται τα Windows ACLs. Η παράμετρος `/inheritance:r` αφαιρεί τα κληρονομούμενα δικαιώματα από γονικούς φακέλους. | Hardening ευαίσθητων δεδομένων ώστε να έχουν πρόσβαση μόνο συγκεκριμένοι εγκεκριμένοι χρήστες. |
| `net session` | Εμφανίζει τις ενεργές απομακρυσμένες συνδέσεις που έχουν ανοίξει άλλοι υπολογιστές προς το μηχάνημα (μέσω SMB/Shared Folders). | Άμεσος έλεγχος για "Lateral Movement" από άλλο μολυνμένο υπολογιστή του δικτύου. |
| `cmdkey /list` | Εμφανίζει τις αποθηκευμένες ταυτότητες και κωδικούς (Credentials) που έχει αποθηκεύσει ο χρήστης. | Έλεγχος για κακή πρακτική αποθήκευσης κρίσιμων κωδικών (Credential Harvesting Risk). |

---

## 🧱 3. Αμυντική Θωράκιση Δικτύου (Host-Based Firewall Hardening)

Διαχείριση του Windows Defender Firewall για τον περιορισμό της επιφάνειας επίθεσης (Attack Surface Reduction).

| Εντολή | Ανάλυση | Security Use Case |
| :--- | :--- | :--- |
| `netsh advfirewall show allprofiles` | Εμφανίζει την κατάσταση του Firewall και για τα 3 προφίλ (Domain, Private, Public). | Επιβεβαίωση ότι το τοπικό Firewall είναι ενεργοποιημένο (`ON`) και δεν έχει απενεργοποιηθεί κακόβουλα. |
| `netsh advfirewall firewall add rule name="Block inbound RDP" dir=in action=block protocol=TCP localport=3389` | Δημιουργεί κανόνα που μπλοκάρει καθολικά όλες τις εισερχόμενες συνδέσεις Remote Desktop (θύρα 3389). | Άμεση προστασία ενός endpoint από επιθέσεις brute-force στο δίκτυο. |

---

## 🪵 4. Έλεγχος Αρχείων Καταγραφής (Security Event Log Auditing)

Οι επιτιθέμενοι προσπαθούν συχνά να σβήσουν τα ίχνη τους. Ο έλεγχος των Logs είναι απαραίτητος στο Incident Response.

| Εντολή | Ανάλυση | Security Use Case |
| :--- | :--- | :--- |
| `wevtutil qe Security /f:text /c:5 /rd:true` | Επιστρέφει τα 5 πιο πρόσφατα συμβάντα ασφαλείας από το Security Event Log σε μορφή κειμένου. | Γρήγορος έλεγχος για αποτυχημένες προσπάθειες σύνδεσης (Event ID 4625) ή δημιουργία νέων χρηστών (Event ID 4720). |
| `wevtutil cl Security` | Καθαρίζει (διαγράφει) το αρχείο καταγραφής ασφαλείας. | **⚠️ Critical Indicator of Compromise (IoC):** Αν το log βρεθεί άδειο, σημαίνει ότι ο επιτιθέμενος διέγραψε τα ίχνη του. |

---

## 🛡️ 5. Κρυπτογράφηση & Ακεραιότητα (Data Protection & Cryptography)

| Εντολή | Ανάλυση | Security Use Case |
| :--- | :--- | :--- |
| `manage-bde -status` | Εμφανίζει την κατάσταση της κρυπτογράφησης BitLocker στους σκληρούς δίσκους. | Επιβεβαίωση προστασίας "Data-at-Rest". Αν το laptop κλαπεί και είναι `Fully Encrypted`, τα δεδομένα είναι ασφαλή. |
| `certutil -hashfile [path_to_file] SHA256` | Υπολογίζει το κρυπτογραφικό αποτύπωμα (Hash value) ενός αρχείου με τον αλγόριθμο SHA256. | Επιβεβαίωση ακεραιότητας. Σύγκριση του hash στο VirusTotal για να διαπιστωθεί αν το αρχείο είναι γνωστό malware. |




