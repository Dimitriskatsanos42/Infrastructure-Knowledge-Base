# 📋 IT Service Management — Event Management, Availability & IT Policies

Πέμπτο αρχείο της ενότητας **IT-Service-Management**, συμπληρωματικό στα προηγούμενα 4 αρχεία. Εστιάζει σε **proactive monitoring, διαθεσιμότητα υπηρεσιών, διαχείριση γνωστών σφαλμάτων, προμηθευτές** και **βασικές πολιτικές IT** που κάθε ώριμο περιβάλλον χρειάζεται εγγράφως.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Event Management — Monitoring & Alerting](#-1-event-management--monitoring--alerting)
2. [Availability Management](#-2-availability-management)
3. [Known Error Database (KEDB)](#-3-known-error-database-kedb)
4. [Supplier / Third-Party Management](#-4-supplier--third-party-management)
5. [Demand Management — Βασικά](#-5-demand-management--βασικά)
6. [IT Policies — Έτοιμα Templates](#-6-it-policies--έτοιμα-templates)
7. [Service Desk Metrics Dashboard](#-7-service-desk-metrics-dashboard)
8. [Πλήρες Παράδειγμα — Από Event σε Known Error](#-8-πλήρες-παράδειγμα--από-event-σε-known-error)

---

## 📡 1. Event Management — Monitoring & Alerting

Το **Event Management** είναι η διαδικασία που ανιχνεύει, ερμηνεύει και αποφασίζει τι να κάνει με events — **πριν** αυτά γίνουν incidents. Η διαφορά με το Incident Management: το Event Management είναι *προληπτικό/παρακολουθητικό*, το Incident Management ξεκινά *μετά* τη διακοπή.

### Κατηγορίες Events

| Κατηγορία | Περιγραφή | Παράδειγμα | Ενέργεια |
|---|---|---|---|
| **Informational** | Φυσιολογική λειτουργία, καταγράφεται μόνο | "Backup ολοκληρώθηκε επιτυχώς" | Καμία — απλή καταγραφή |
| **Warning** | Ασυνήθιστο αλλά όχι ακόμα κρίσιμο | "Disk usage 82%" | Παρακολούθηση, πιθανή προληπτική ενέργεια |
| **Exception/Critical** | Κάτι λειτουργεί εκτός φυσιολογικών ορίων | "Service DHCP σταμάτησε" | Αυτόματο άνοιγμα Incident |

### Παράδειγμα alerting thresholds (σύνδεση με Capacity Management)

| Metric | Warning threshold | Critical threshold | Ενέργεια στο Critical |
|---|:---:|:---:|---|
| CPU utilization | 75% | 90% | Alert στην ομάδα Infra, αυτόματο ticket |
| Disk space | 80% | 90% | Alert + αυτόματο cleanup script αν υπάρχει |
| Service availability | — | Down >2 λεπτά | Αυτόματο P1 Incident |
| Certificate expiration | 30 μέρες πριν | 7 μέρες πριν | Email στον owner + ticket |

### 📝 Alert Rule Template (concept, ανεξάρτητο εργαλείου)
```markdown
## Alert Rule — [Όνομα]

**Metric:** Disk Free Space
**Scope:** Όλοι οι production file servers
**Warning:** <20% free
**Critical:** <10% free
**Notification channel:** Email + Teams webhook προς Infra team
**Auto-remediation:** Εκτέλεση cleanup script αν <10%
**Suppress during:** Scheduled maintenance windows (βλ. Change Calendar)
```

### Γιατί το Event Management μειώνει τα Incidents
Ένα καλά ρυθμισμένο σύστημα event management πιάνει το "disk στο 85%" *πριν* γίνει "ο server έμεινε χωρίς χώρο και το service κατέρρευσε" — τυπικό reactive→proactive shift.

---

## 📈 2. Availability Management

Στόχος: διασφάλιση ότι οι υπηρεσίες είναι διαθέσιμες στο επίπεδο που έχει συμφωνηθεί (SLA), με το κατάλληλο κόστος.

### Βασικοί υπολογισμοί διαθεσιμότητας

**Τύπος:**
```
Availability % = ((Total Time − Downtime) / Total Time) × 100
```

### Πίνακας "Nines" — τι σημαίνει κάθε επίπεδο uptime

| Availability | Επιτρεπόμενο downtime/έτος | Επιτρεπόμενο downtime/μήνα |
|---|---:|---:|
| 99% ("two nines") | 3.65 μέρες | 7.3 ώρες |
| 99.9% ("three nines") | 8.76 ώρες | 43.8 λεπτά |
| 99.95% | 4.38 ώρες | 21.9 λεπτά |
| 99.99% ("four nines") | 52.6 λεπτά | 4.4 λεπτά |
| 99.999% ("five nines") | 5.26 λεπτά | 26 δευτερόλεπτα |

> Κάθε επιπλέον "9" κοστίζει δραματικά περισσότερο σε redundancy/infrastructure — καλό να συζητιέται ρεαλιστικά με το business τι πραγματικά χρειάζεται.

### MTBF & MTTR — βασικές μετρικές

| Μετρική | Σημασία | Τύπος |
|---|---|---|
| **MTBF** (Mean Time Between Failures) | Πόσο συχνά αποτυγχάνει ένα σύστημα | Total uptime / # failures |
| **MTTR** (Mean Time To Repair/Resolve) | Πόσο γρήγορα αποκαθίσταται | Total downtime / # incidents |
| **MTTF** (Mean Time To Failure) | Αναμενόμενη ζωή πριν την πρώτη αστοχία (μη επισκευάσιμα assets) | — |

### 📝 Availability Report Template (μηνιαίο, ανά υπηρεσία)

| Υπηρεσία | SLA Target | Actual Availability | Downtime (λεπτά) | # Incidents | MTTR |
|---|:---:|:---:|:---:|:---:|:---:|
| Email/M365 | 99.9% | 99.97% | 13 | 1 | 13 λεπτά |
| File Server (SRV-APP01) | 99.5% | 99.2% | 210 | 2 | 105 λεπτά |
| ERP Application | 99.9% | 99.9% | 43 | 1 | 43 λεπτά |

> Το File Server είναι κάτω από στόχο (99.2% < 99.5%) — αυτό είναι input για Problem Management ή Availability improvement plan.

---

## 🗃️ 3. Known Error Database (KEDB)

Ένα **Known Error** είναι ένα Problem του οποίου η root cause έχει εντοπιστεί, αλλά **δεν έχει ακόμα μόνιμη λύση** (ίσως εκκρεμεί Change, ή η μόνιμη λύση δεν αξίζει το κόστος). Η KEDB κρατά **workarounds** διαθέσιμα ώστε το Tier 1/2 να λύνει γρήγορα κάτι που ήδη ξέρουμε.

### 📝 Known Error Record Template
```markdown
## Known Error — KE-2026-014

**Σχετικό Problem:** PRB-2026-0031
**Κατάσταση:** Active (δεν έχει μόνιμη λύση ακόμα)
**Ημερομηνία εντοπισμού:** 2026-08-10

### Σύμπτωμα
DHCP service σε SRV02 σταματά περιοδικά μετά από ~7 μέρες uptime.

### Root Cause
Memory leak σε παλιά build του DHCP role (γνωστό vendor bug KB-xxxxx).

### Workaround (μέχρι τη μόνιμη λύση)
```powershell
# Scheduled restart κάθε Κυριακή 03:00 πριν φτάσει το leak σε κρίσιμο επίπεδο
Restart-Service DHCPServer -Force
```

### Μόνιμη λύση (εκκρεμεί)
Αναβάθμιση σε νέα build — Change Request CHG-2026-0087, scheduled 2026-09-05.

### Ποιος μπορεί να εφαρμόσει το workaround
Tier 1 — δεν χρειάζεται escalation, βλ. KB-2026-0055.
```

### Πίνακας KEDB — γρήγορη επισκόπηση

| KE ID | Σύμπτωμα | Impact | Workaround διαθέσιμο; | Μόνιμη λύση ETA |
|---|---|---|:---:|---|
| KE-2026-014 | DHCP crash μετά από ~7 μέρες | Medium | ✅ Ναι (Tier 1) | 2026-09-05 |
| KE-2026-015 | Printer driver crash σε παλιά μοντέλα | Low | ✅ Ναι (Tier 1) | Δεν προγραμματίζεται (EOL εξοπλισμός) |
| KE-2026-016 | Slow login σε RDS όταν >50 ταυτόχρονοι χρήστες | High | ⚠️ Μερικό (restart broker) | Εκκρεμεί capacity upgrade |

---

## 🤝 4. Supplier / Third-Party Management

### Κατηγοριοποίηση προμηθευτών ανά κρισιμότητα

| Κατηγορία | Παράδειγμα | Επίπεδο παρακολούθησης |
|---|---|---|
| **Strategic** | Cloud provider (Azure/AWS), κύριος ISP | Τριμηνιαία business review, πλήρες SLA tracking |
| **Tactical** | Software vendor μεσαίας κρισιμότητας | Εξαμηνιαία επικοινωνία |
| **Commodity** | Προμηθευτής αναλωσίμων (toner, καλώδια) | Ελάχιστη — μόνο κατά την ανανέωση |

### 📝 Supplier Performance Review Template
```markdown
## Supplier Review — [Όνομα Προμηθευτή]

**Περίοδος:** Q3 2026
**Κατηγορία:** Strategic

### SLA Performance
| Metric | Target (UC) | Actual |
|---|---|---|
| Uptime | 99.5% | 99.7% |
| Support response time | 4h | 3.2h avg |

### Incidents σχετιζόμενα με τον προμηθευτή
[Λίστα tickets/αναφορές]

### Αξιολόγηση
- [ ] Τηρεί συμφωνηθέντα SLA
- [ ] Ικανοποιητική επικοινωνία
- [ ] Ανταγωνιστικό κόστος σε σχέση με εναλλακτικές

### Ενέργειες
[πχ "Διαπραγμάτευση βελτιωμένου response time στην ανανέωση συμβολαίου"]
```

---

## 📊 5. Demand Management — Βασικά

Στόχος: πρόβλεψη μελλοντικής ζήτησης σε IT resources ώστε το Capacity Management να προλαβαίνει, όχι να αντιδρά.

### Πηγές δεδομένων για demand forecasting
- Business roadmap (πχ "θα προσλάβουμε 30 άτομα το Q4" → νέα laptops, licenses, mailboxes)
- Ιστορικά trends χρήσης (growth rate αποθηκευτικού χώρου, αριθμού tickets)
- Προγραμματισμένα projects (νέα εφαρμογή → νέες απαιτήσεις server/DB)

### 📝 Demand Forecast Template (απλό)

| Τρίμηνο | Νέοι χρήστες (πρόβλεψη) | Επιπλέον storage | Επιπλέον licenses | Σχετικό Capacity item |
|---|:---:|---:|:---:|---|
| Q4 2026 | +30 | +150 GB | +30× M365 E3 | Mailbox storage, laptop provisioning |
| Q1 2027 | +10 | +50 GB | +10× M365 E3 | — |

---

## 📜 6. IT Policies — Έτοιμα Templates

### Acceptable Use Policy (AUP) — σκελετός
```markdown
## Πολιτική Αποδεκτής Χρήσης IT Πόρων

**Εφαρμόζεται σε:** Όλο το προσωπικό με πρόσβαση σε εταιρικά συστήματα

### Επιτρέπεται
- Χρήση εταιρικού εξοπλισμού/λογαριασμών για επαγγελματικούς σκοπούς
- Περιορισμένη προσωπική χρήση (εντός λογικών ορίων)

### Απαγορεύεται
- Εγκατάσταση μη εγκεκριμένου λογισμικού
- Κοινή χρήση credentials
- Πρόσβαση/αποθήκευση παράνομου ή ακατάλληλου περιεχομένου
- Παράκαμψη security controls (πχ VPN, firewall)

### Παρακολούθηση
Η εταιρεία διατηρεί το δικαίωμα παρακολούθησης χρήσης εταιρικών συστημάτων σύμφωνα με [σχετική νομοθεσία/GDPR].

### Συνέπειες μη συμμόρφωσης
[Πειθαρχική διαδικασία ανάλογα με σοβαρότητα]
```

### Password Policy — σκελετός
```markdown
## Πολιτική Κωδικών Πρόσβασης

- Ελάχιστο μήκος: 12 χαρακτήρες
- Απαιτείται συνδυασμός: κεφαλαία, πεζά, αριθμοί, σύμβολα
- Απαγορεύονται κοινοί/προηγούμενοι κωδικοί (password history: τελευταίοι 5)
- Λήξη κάθε: [ανάλογα πολιτική — πολλά σύγχρονα frameworks προτείνουν MFA αντί για συχνή αλλαγή]
- Υποχρεωτικό MFA για: VPN, email, admin accounts
- Lockout μετά από: 5 αποτυχημένες προσπάθειες, 15 λεπτά lockout
```

### Data Retention Policy — σκελετός
```markdown
## Πολιτική Διατήρησης Δεδομένων

| Τύπος δεδομένων | Περίοδος διατήρησης | Ενέργεια μετά τη λήξη |
|---|---|---|
| Email | 3 έτη | Αρχειοθέτηση, μετά διαγραφή |
| Incident/Change tickets | 5 έτη | Αρχειοθέτηση |
| Backup snapshots | 90 ημέρες (daily), 12 μήνες (monthly) | Αυτόματη διαγραφή |
| Offboarded user data | 90 ημέρες μετά την αποχώρηση | Οριστική διαγραφή |
| Security/audit logs | 1 έτος (ή σύμφωνα με compliance απαίτηση) | Αρχειοθέτηση |
```

---

## 📟 7. Service Desk Metrics Dashboard

Παράδειγμα δομής dashboard που θα έβλεπε ένας IT Manager καθημερινά.

| Metric | Τρέχουσα τιμή | Trend (7 ημέρες) |
|---|:---:|:---:|
| Open tickets | 47 | ↓ -12% |
| Tickets ανοιχτά >48h | 5 | ↑ +2 |
| Avg First Response Time | 22 λεπτά | ↔ Σταθερό |
| Tickets ανά τεχνικό (φόρτος) | 9.4 | ↓ -0.6 |
| Backlog aging (>7 ημέρες) | 3 tickets | ⚠️ Χρειάζεται προσοχή |
| CSAT (τελευταίες 50 απαντήσεις) | 4.6/5 | ↑ +0.1 |

### Ερωτήσεις που πρέπει να απαντά ένα καλό dashboard
1. Είμαστε σε καλό δρόμο σε σχέση με τα SLA;
2. Υπάρχει τεχνικός/ομάδα με υπερβολικό φόρτο;
3. Υπάρχουν tickets που "κολλάνε" (aging) και χρειάζονται παρέμβαση;
4. Βελτιώνεται ή χειροτερεύει η ικανοποίηση χρηστών;

---

## 🔗 8. Πλήρες Παράδειγμα — Από Event σε Known Error

```
1. Monitoring system καταγράφει: "Memory usage SRV02 στο 88%" (Warning threshold)
   → Event log entry, καμία άμεση ενέργεια ακόμα

2. Το ίδιο event επαναλαμβάνεται 3 φορές μέσα σε 2 εβδομάδες, πάντα στο DHCP process
   → Sysadmin το παρατηρεί στο μηνιαίο Capacity Report

3. Ανοίγει proactive Problem Record (πριν καν γίνει outage)
   → Root Cause Analysis: memory leak σε γνωστό vendor bug

4. Δημιουργείται Known Error KE-2026-014 με workaround
   (scheduled weekly restart) ενώ εκκρεμεί μόνιμη λύση

5. Tier 1/2 team ενημερώνεται μέσω KEDB — αν ξαναδούν το ίδιο σύμπτωμα,
   ξέρουν ήδη τι να κάνουν χωρίς escalation

6. Request for Change δημιουργείται για τη μόνιμη λύση (upgrade)
   → Μετά την εφαρμογή, το Known Error κλείνει
   → CSI entry: "Το proactive monitoring απέτρεψε πιθανό μελλοντικό outage"
```

Αυτό δείχνει την πλήρη **proactive** πλευρά του ITSM — Event Management που τροφοδοτεί Problem Management πριν καν συμβεί incident, κάτι που ξεχωρίζει ένα ώριμο IT operations περιβάλλον από ένα καθαρά reactive.

---

*Μέρος του [Infrastructure Knowledge Base](https://github.com/Dimitriskatsanos42/Infrastructure-Knowledge-Base) — ενότητα IT-Service-Management, συμπληρωματικό στα `itil-service-management-templates.md`, `itsm-additional-templates.md`, `itsm-major-incidents-cab-csi.md` και `itsm-raci-release-asset-lifecycle.md`.*
