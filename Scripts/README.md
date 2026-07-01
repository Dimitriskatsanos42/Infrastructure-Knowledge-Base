# ⚙️ Scripts & Automation

> PowerShell και Bash scripts για αυτοματοποίηση καθημερινών IT εργασιών.

---

## 📋 Οργάνωση

```
Scripts/
├── PowerShell/
│   ├── system-health-check.ps1    — Έλεγχος κατάστασης Windows συστήματος
│   ├── ad-user-management.ps1     — Bulk δημιουργία/διαχείριση AD users
│   └── event-log-analyzer.ps1    — Ανίχνευση ύποπτης δραστηριότητας
└── Bash/
    ├── server-health-check.sh     — Έλεγχος κατάστασης Linux server
    └── backup-with-rsync.sh       — Αυτόματο backup με rsync
```

---

## 💡 Φιλοσοφία

Κάθε script εδώ:
- Έχει **header με περιγραφή και οδηγίες χρήσης**
- Χρησιμοποιεί **error handling** και logging
- Γράφτηκε για να λύσει **πραγματικό πρόβλημα**
- Συνοδεύεται από **παράδειγμα εκτέλεσης** στο README

---

## 🗂️ Scripts

| Script | Γλώσσα | Λειτουργία |
|--------|--------|------------|
| `system-health-check.ps1` | PowerShell | CPU, RAM, Disk, Services σε Windows |
| `ad-user-management.ps1` | PowerShell | Bulk AD users από CSV |
| `event-log-analyzer.ps1` | PowerShell | Ανίχνευση brute force (Event 4625) |
| `server-health-check.sh` | Bash | Health check Linux server |
| `backup-with-rsync.sh` | Bash | Automated backup |
