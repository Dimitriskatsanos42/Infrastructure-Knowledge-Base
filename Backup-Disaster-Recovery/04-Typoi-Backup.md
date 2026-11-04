# 5. Τύποι backup

### 5.1 Τα τρία βασικά είδη

| Τύπος | Τι αντιγράφει | Μέγεθος | Ταχύτητα backup | Ταχύτητα restore | Απαιτούμενα αρχεία για restore |
|---|---|---|---|---|---|
| **Full (πλήρες)** | **Όλα** τα δεδομένα | Μεγάλο | Αργό | **Γρήγορο** | Μόνο το full |
| **Incremental (αυξητικό)** | Ό,τι άλλαξε από το **τελευταίο backup οποιουδήποτε τύπου** | Πολύ μικρό | **Γρήγορο** | Πιο αργό | Full + **όλα** τα incrementals μέχρι το σημείο |
| **Differential (διαφορικό)** | Ό,τι άλλαξε από το **τελευταίο full** | Μεσαίο (μεγαλώνει) | Μεσαίο | Μεσαίο | Full + **το τελευταίο** differential |

### Οπτικό παράδειγμα (εβδομάδα με full την Κυριακή)

```
Ημέρα:           Κυρ    Δευ    Τρι    Τετ    Πεμ    Παρ    Σαβ
Full:            [FULL]
Incremental:            [Δευ]  [Τρι]  [Τετ]  [Πεμ]  [Παρ]  [Σαβ]
  (κάθε ένα περιέχει μόνο τις αλλαγές της προηγούμενης ημέρας)

Differential:           [Δευ]  [Δευ+Τρι] [Δευ+Τρι+Τετ] ...
  (κάθε ένα περιέχει όλες τις αλλαγές από την Κυριακή)
```

**Restore την Πέμπτη:**
- Incremental: Full + Δευ + Τρι + Τετ + Πεμ (4 αλυσίδες· αν χαλάσει μία, χάνεται η αλυσίδα).
- Differential: Full + Differential Πέμπτης (2 κομμάτια).

### 5.2 Προχωρημένα είδη

| Τύπος | Περιγραφή |
|---|---|
| **Synthetic full** | Το σύστημα **συνθέτει** νέο full από το προηγούμενο full + incrementals στο repository, χωρίς να ξαναδιαβάσει την πηγή (μειώνει φόρτο στην παραγωγή). Χρησιμοποιείται από Veeam. |
| **Forever forward incremental** | Ένα full στην αρχή και μετά μόνο incrementals· τα παλαιότερα συγχωνεύονται στο full ώστε να μη μεγαλώνει η αλυσίδα. |
| **Reverse incremental** | Το πιο πρόσφατο σημείο είναι πάντα full, τα παλιά αποθηκεύονται ως «αντίστροφα» διαφορικά. Γρήγορο restore του τελευταίου σημείου, αργά backups. |
| **Block-level / CBT** | Αντιγράφονται μόνο τα **blocks** που άλλαξαν (Changed Block Tracking), όχι ολόκληρα αρχεία. Πολύ γρήγορο. |
| **Deduplication** | Αφαίρεση διπλότυπων blocks/chunks για εξοικονόμηση χώρου (restic, Veeam, Windows Server Dedup). |
| **CDP (Continuous Data Protection)** | Καταγραφή **κάθε** αλλαγής, RPO δευτερολέπτων. |
| **Image-based (εικόνα συστήματος)** | Backup **ολόκληρου** του δίσκου/volume/VM, επιτρέπει bare-metal restore. |
| **File-level** | Backup μεμονωμένων αρχείων και φακέλων. |

### 5.3 Application-consistent vs Crash-consistent

| Τύπος συνέπειας | Σημασία | Παράδειγμα |
|---|---|---|
| **Crash-consistent** | Σαν να τραβήχτηκε το καλώδιο ρεύματος. Η βάση δεδομένων συνήθως ανακάμπτει, αλλά όχι εγγυημένα. | Απλό snapshot δίσκου |
| **Application-consistent** | Η εφαρμογή «σταματά» για λίγο τις εγγραφές, αδειάζει buffers, και μετά τραβιέται το snapshot. Εγγυημένη συνέπεια. | **VSS** (Windows) για SQL Server, Exchange, AD |

> **VSS (Volume Shadow Copy Service)** είναι ο μηχανισμός των Windows που συντονίζει εφαρμογές, writers και providers ώστε να παραχθεί συνεπές snapshot. Το χρησιμοποιούν Windows Server Backup και Veeam.

### 5.4 Πότε επιλέγουμε τι

| Σενάριο | Πρόταση |
|---|---|
| Μικρός file server, χώρος αφθονεί | Weekly full + daily differential |
| Μεγάλος όγκος, μικρό παράθυρο backup | Forever incremental / CBT |
| Κρίσιμη εφαρμογή με βάση δεδομένων | Application-aware backup + συχνό log backup |
| Θες γρήγορο restore πρόσφατου σημείου | Reverse incremental ή synthetic full |

---

[⬅️ Προηγούμενο](03-Strategiki-3-2-1.md) | [📚 Περιεχόμενα](README.md) | [Επόμενο ➡️](05-Retention-GFS.md)
