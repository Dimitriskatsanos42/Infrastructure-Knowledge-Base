# 7. Τι κάνουμε backup (επίπεδα και workloads)

### 7.1 Επίπεδα προστασίας

| Επίπεδο | Περιεχόμενο | Πότε |
|---|---|---|
| **Αρχεία/φάκελοι** | Έγγραφα, home directories, shares | File servers, laptops |
| **Εικόνα συστήματος (image)** | Όλο το volume/δίσκο με OS, εφαρμογές, ρυθμίσεις | Bare-metal restore |
| **Εικονική μηχανή (VM)** | Όλα τα αρχεία VM (VMDK/VHDX) και config | VMware, Hyper-V, Proxmox |
| **Εφαρμογή / βάση δεδομένων** | SQL, Exchange, Oracle με application-aware τρόπο | Κρίσιμες υπηρεσίες |
| **Ρυθμίσεις (configs)** | Router, switch, firewall, αρχεία `/etc` | Ταχεία ανάκτηση υποδομής |
| **SaaS δεδομένα** | Microsoft 365, Google Workspace | **Ο πάροχος δεν εγγυάται πλήρες backup** (shared responsibility) |

### 7.2 Λίστα «τι δεν πρέπει να ξεχάσεις»

- Active Directory (**System State**)
- DNS, DHCP (ρυθμίσεις, εξαγωγή scopes)
- Group Policy Objects (GPO)
- Πιστοποιητικά / CA (Certification Authority) και ιδιωτικά κλειδιά
- Βάσεις δεδομένων και transaction logs
- Εγκατεστημένα configs (π.χ. nginx, apache, fstab, crontab)
- Κλειδιά κρυπτογράφησης (BitLocker recovery keys, restic password!)
- Δικτυακός εξοπλισμός (running-config)
- Τεκμηρίωση (το ίδιο το DR plan, σε εκτυπωμένη μορφή εκτός συστήματος)
- Κωδικοί/μυστικά (σε password manager με offline copy)

### 7.3 Το Shared Responsibility Model για cloud / SaaS

Ο πάροχος (Microsoft, AWS, Google) εγγυάται τη **διαθεσιμότητα της υποδομής**, **όχι** την προστασία των **δικών σου δεδομένων** από διαγραφή, ransomware ή λάθος. Γι' αυτό χρειάζεσαι backup του Microsoft 365 (Exchange Online, SharePoint, OneDrive, Teams) με εργαλεία όπως Veeam Backup for Microsoft 365.

---

# 8. Μέσα αποθήκευσης και τοποθεσίες

| Μέσο | Πλεονεκτήματα | Μειονεκτήματα | Χρήση |
|---|---|---|---|
| **Εξωτερικός δίσκος USB** | Φθηνό, φορητό, εύκολο | Μικρή αξιοπιστία, ανθρώπινος παράγοντας | Μικρά γραφεία, offline αντίγραφο |
| **NAS** | Κεντρικό, RAID, δικτυακά shares | Στο ίδιο δίκτυο = ευάλωτο σε ransomware | Τοπικό backup |
| **SAN / Disk array** | Υψηλή απόδοση | Κόστος, πολυπλοκότητα | Enterprise |
| **Ταινίες (LTO)** | Φθηνό ανά TB, offline, μακρά διάρκεια ζωής, ανθεκτικό σε ransomware | Αργό restore, εξοπλισμός | Archive, air-gap |
| **Cloud object storage (S3, Azure Blob, B2)** | Off-site, scalable, immutability | Κόστος εξόδου, εύρος ζώνης | Off-site αντίγραφο |
| **Cloud backup services** | Διαχειριζόμενο | Εξάρτηση από πάροχο | SMB |
| **Optical (BD-R/M-Disc)** | Μακρά ζωή | Μικρή χωρητικότητα | Ειδικές περιπτώσεις |

### Τοποθεσίες

| Τοποθεσία | Εξηγεί |
|---|---|
| **On-site** | Γρήγορο restore (τοπικά) |
| **Off-site (άλλο κτίριο)** | Προστασία από τοπική καταστροφή |
| **Cloud** | Γεωγραφικά ανεξάρτητη θέση |
| **Offline / Air-gap** | Προστασία από ransomware |

> **Κανόνας:** Ένα αντίγραφο πρέπει πάντα να είναι αρκετά μακριά ώστε να μην επηρεάζεται από το ίδιο συμβάν με την πηγή (πυρκαγιά, πλημμύρα, σεισμός).

---

[⬅️ Προηγούμενο](05-Retention-GFS.md) | [📚 Περιεχόμενα](README.md) | [Επόμενο ➡️](07-Asfaleia-Ransomware.md)
