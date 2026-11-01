# Backup & Disaster Recovery (DR)

> Πλήρης οδηγός από το μηδέν: έννοιες, στρατηγική, σχεδιασμός και πρακτική εφαρμογή με **Windows Server Backup**, **Veeam Backup & Replication**, **rsync** και **restic**.

Ο οδηγός είναι χωρισμένος σε θεματικά αρχεία. Διάβασέ τα **με τη σειρά** (01 → 18) και κάνε τα labs σε εικονικές μηχανές (VirtualBox / VMware / Hyper-V / Proxmox).

## Επίπεδα

| Επίπεδο | Για ποιον |
|---|---|
| 🟢 **Αρχάριος** | Δεν έχεις ξανακάνει backup ή θες να καταλάβεις τις βάσεις |
| 🟡 **Μεσαίος** | Ξέρεις τα βασικά και θέλεις να σχεδιάσεις σωστά |
| 🔴 **Προχωρημένος** | Θες πρακτική υλοποίηση, αυτοματοποίηση, ασφάλεια, DR |
| 🎯 **Εξάσκηση** | Labs, quiz, ερωτήσεις συνέντευξης, templates |

## Περιεχόμενα

| # | Επίπεδο | Αρχείο |
|---|---|---|
| 01 | 🟢 | [Εισαγωγή και βασικές έννοιες](01-Eisagogi-kai-Vasikes-Ennoies.md) |
| 02 | 🟢 | [RPO, RTO και συναφείς δείκτες](02-RPO-RTO.md) |
| 03 | 🟢 | [Η στρατηγική 3-2-1 και οι παραλλαγές της](03-Strategiki-3-2-1.md) |
| 04 | 🟢 | [Τύποι backup](04-Typoi-Backup.md) |
| 05 | 🟡 | [Retention και σχήμα GFS](05-Retention-GFS.md) |
| 06 | 🟡 | [Τι κάνουμε backup, μέσα αποθήκευσης και τοποθεσίες](06-Ti-Backup-kai-Apothikeusi.md) |
| 07 | 🟡 | [Ασφάλεια backup, immutability και ransomware](07-Asfaleia-Ransomware.md) |
| 08 | 🟡 | [Σχεδιασμός backup](08-Schediasmos-Backup.md) |
| 09 | 🔴 | [Disaster Recovery Plan](09-Disaster-Recovery-Plan.md) |
| 10 | 🔴 | [Windows Server Backup](10-Windows-Server-Backup.md) |
| 11 | 🔴 | [Veeam Backup & Replication](11-Veeam-Backup-Replication.md) |
| 12 | 🔴 | [rsync (Linux)](12-rsync.md) |
| 13 | 🔴 | [restic](13-restic.md) |
| 14 | 🔴 | [Σύγκριση εργαλείων](14-Sygkrisi-Ergaleion.md) |
| 15 | 🎯 | [Hands-on Labs](15-Labs.md) |
| 16 | 🎯 | [Troubleshooting](16-Troubleshooting.md) |
| 17 | 🎯 | [Quiz και ερωτήσεις συνέντευξης](17-Quiz-kai-Synentefxi.md) |
| 18 | 🎯 | [Templates, checklists, γλωσσάρι, πηγές](18-Templates-Checklists-Glossary.md) |

## Προτεινόμενη πορεία μελέτης

1. **Εβδομάδα 1 (🟢):** αρχεία 01–04 και Lab 1–2 από το [15-Labs.md](15-Labs.md)
2. **Εβδομάδα 2 (🟡):** αρχεία 05–08, σχεδίασε backup plan για ένα φανταστικό γραφείο
3. **Εβδομάδα 3 (🔴):** αρχεία 09–10 και Lab 3–4 (Windows Server Backup, AD restore)
4. **Εβδομάδα 4 (🔴):** αρχεία 11–13 και Lab 5–7 (rsync, restic, Veeam)
5. **Εβδομάδα 5 (🎯):** αρχεία 14–18, Lab 8 (DR drill), quiz και ερωτήσεις συνέντευξης

## Βασική αρχή

> **Ένα backup που δεν έχει δοκιμαστεί σε restore, δεν είναι backup. Είναι ελπίδα.**

> 📝 Οι εντολές και οι εκδόσεις μπορεί να διαφέρουν ανάλογα με το προϊόν. Έλεγχε πάντα την επίσημη τεκμηρίωση και δοκίμαζε σε lab πριν εφαρμόσεις σε παραγωγή.
