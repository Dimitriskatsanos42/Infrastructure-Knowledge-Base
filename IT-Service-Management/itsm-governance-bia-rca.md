# 📋 IT Service Management — Governance, BIA & Root Cause Analysis Techniques

Έκτο αρχείο της ενότητας **IT-Service-Management**. Εστιάζει σε **στρατηγικό/governance επίπεδο** (πού εντάσσεται το ITIL μέσα σε ένα ευρύτερο πλαίσιο), **ανάλυση επιχειρησιακής επίπτωσης** και **δομημένες τεχνικές root cause analysis** πέρα από το βασικό 5 Whys.

---

## 🗺️ Πίνακας Περιεχομένων

1. [IT Governance — Πού Εντάσσεται το ITIL](#-1-it-governance--πού-εντάσσεται-το-itil)
2. [Business Impact Analysis (BIA)](#-2-business-impact-analysis-bia)
3. [Root Cause Analysis — Τεχνικές πέρα από 5 Whys](#-3-root-cause-analysis--τεχνικές-πέρα-από-5-whys)
4. [Emergency Change Process](#-4-emergency-change-process)
5. [Change Freeze / Blackout Periods](#-5-change-freeze--blackout-periods)
6. [Stakeholder Communication Plan](#-6-stakeholder-communication-plan)
7. [Trend Analysis & Problem Trend Report](#-7-trend-analysis--problem-trend-report)
8. [IT Strategy Roadmap — Template](#-8-it-strategy-roadmap--template)
9. [Πλήρες Παράδειγμα — BIA οδηγεί σε DR Investment](#-9-πλήρες-παράδειγμα--bia-οδηγεί-σε-dr-investment)

---

## 🏛️ 1. IT Governance — Πού Εντάσσεται το ITIL

Πολλοί μπερδεύουν **governance frameworks** με **process frameworks**. Χρήσιμη διάκριση:

| Framework | Τι απαντά | Επίπεδο |
|---|---|---|
| **COBIT** | "Πώς διασφαλίζουμε ότι το IT υποστηρίζει τους επιχειρηματικούς στόχους και είναι σωστά διακυβερνημένο;" | Στρατηγικό/Governance |
| **ITIL** | "Πώς οργανώνουμε τις καθημερινές λειτουργίες του IT (incidents, changes, κλπ.);" | Λειτουργικό/Operational |
| **ISO/IEC 27001** | "Πώς διαχειριζόμαστε την ασφάλεια πληροφοριών;" | Security Management |
| **PRINCE2 / PMBOK** | "Πώς διαχειριζόμαστε ένα IT project;" | Project Management |

### Σχέση μεταξύ τους (απλοποιημένα)
```
COBIT (governance: "κάνουμε τα σωστά πράγματα;")
   └── ITIL (management: "τα κάνουμε σωστά;")
          └── Καθημερινές διαδικασίες (Incident, Change, Problem...)
```

> Ένας sysadmin δουλεύει κυρίως στο επίπεδο **ITIL**, αλλά είναι χρήσιμο να ξέρει πού εντάσσεται αυτό μέσα στην ευρύτερη εικόνα — ειδικά σε συζητήσεις με management ή σε audits.

### Οι 4 διαστάσεις υπηρεσίας (ITIL 4 concept)
| Διάσταση | Περιγραφή |
|---|---|
| Organizations & People | Ρόλοι, δεξιότητες, κουλτούρα |
| Information & Technology | Συστήματα, δεδομένα, εργαλεία |
| Partners & Suppliers | Εξωτερικές σχέσεις (βλ. Supplier Management) |
| Value Streams & Processes | Οι ίδιες οι διαδικασίες (Incident, Change, κλπ.) |

---

## 💥 2. Business Impact Analysis (BIA)

Το **BIA** απαντά: *"Αν αυτό το σύστημα σταματήσει, τι πραγματικά χάνει η επιχείρηση, και πόσο γρήγορα γίνεται μη αναστρέψιμο;"* Είναι το θεμέλιο πάνω στο οποίο χτίζονται τα ρεαλιστικά RTO/RPO ενός DR Plan.

### 📝 BIA Template (ανά κρίσιμη λειτουργία/σύστημα)

```markdown
## Business Impact Analysis — [Σύστημα/Λειτουργία, π.χ. "ERP — Τιμολόγηση"]

**Business Owner:** [Όνομα/Τμήμα]
**Ημερομηνία ανάλυσης:** 2026-08-20

### Επίπτωση ανά χρονικό διάστημα διακοπής

| Διάρκεια διακοπής | Οικονομική επίπτωση | Λειτουργική επίπτωση | Reputational/Legal επίπτωση |
|---|---|---|---|
| 1 ώρα | Αμελητέα | Καθυστέρηση εργασιών | Καμία |
| 4 ώρες | ~€2,000 χαμένος τζίρος | Δεν εκδίδονται τιμολόγια | Καμία |
| 1 ημέρα | ~€12,000 | Καθυστέρηση παραδόσεων, δυσαρέσκεια πελατών | Πιθανά παράπονα πελατών |
| 3+ ημέρες | ~€40,000+ | Σοβαρή διατάραξη cash flow | Πιθανή απώλεια πελατών, ζημιά φήμης |

### Maximum Tolerable Downtime (MTD)
**24 ώρες** — πέρα από αυτό το όριο, η επίπτωση θεωρείται μη αποδεκτή.

### Απαιτούμενο RTO (βάσει MTD, με περιθώριο ασφαλείας)
**8 ώρες**

### Απαιτούμενο RPO (αποδεκτή απώλεια δεδομένων)
**1 ώρα** (βάσει συχνότητας καταχώρησης τιμολογίων)

### Εξαρτήσεις (τι άλλο χρειάζεται για να λειτουργήσει αυτό το σύστημα)
- Database server DB-001
- Active Directory (authentication)
- Δικτυακή σύνδεση με τραπεζικό gateway (πληρωμές)

### Συμπέρασμα / Σύσταση
Το τρέχον DR plan προβλέπει RTO 12 ωρών — **δεν καλύπτει** την απαίτηση των 8 ωρών. Χρειάζεται επένδυση σε [πχ ταχύτερο replication, hot standby].
```

### Γιατί το BIA προηγείται του DR Plan
Δεν έχει νόημα να σχεδιάσεις DR χωρίς πρώτα να ξέρεις **πόσο πραγματικά κοστίζει** η διακοπή — αλλιώς είτε ξοδεύεις υπερβολικά σε redundancy που δεν χρειάζεται, είτε επικίνδυνα λίγο σε κάτι κρίσιμο.

---

## 🔬 3. Root Cause Analysis — Τεχνικές πέρα από 5 Whys

Το `itil-service-management-templates.md` καλύπτει ήδη το **5 Whys**. Εδώ δύο επιπλέον τεχνικές, χρήσιμες για πιο πολύπλοκα προβλήματα.

### Fishbone Diagram (Ishikawa) — για προβλήματα με πολλαπλές πιθανές αιτίες

Οργανώνει πιθανές αιτίες σε κατηγορίες, χρήσιμο όταν το πρόβλημα δεν έχει μία προφανή γραμμική αιτία.

```
                    ΠΡΟΒΛΗΜΑ: "Αργή απόκριση εφαρμογής"
                                    |
    People -----------\            |            /----------- Process
    - Ανεπαρκής         \          |          /   - Δεν υπάρχει load testing
      εκπαίδευση          \        |        /     πριν από releases
                            \      |      /
    -------------------------\----+----/-------------------------
                              /    |    \
    Technology --------------/     |     \-------------- Environment
    - Παλιό hardware               |              - Δίκτυο με high latency
    - Μη βελτιστοποιημένα queries  |              - Πολλαπλά VPN hops
```

### Κατηγορίες που συνήθως χρησιμοποιούνται (6 M's, προσαρμοσμένο για IT)
| Κατηγορία | Παράδειγμα ερωτήσεων |
|---|---|
| **People** | Χρειάζεται εκπαίδευση; Λάθος χειρισμός; |
| **Process** | Λείπει βήμα ελέγχου; Λάθος διαδικασία; |
| **Technology** | Bug; Παλιό hardware/software; |
| **Environment** | Δίκτυο, θερμοκρασία server room, power; |
| **Data** | Λανθασμένα/ελλιπή δεδομένα; |
| **Management** | Λάθος προτεραιοποίηση, έλλειψη πόρων; |

### Pareto Analysis (80/20 rule) — για προτεραιοποίηση

Χρήσιμο όταν έχεις **πολλά** incidents και θέλεις να δεις ποιες λίγες αιτίες προκαλούν τα περισσότερα προβλήματα.

| Αιτία Incident | # Incidents | % του συνόλου | Αθροιστικό % |
|---|:---:|:---:|:---:|
| Password/Account issues | 145 | 38% | 38% |
| Network connectivity | 98 | 26% | 64% |
| Application errors | 67 | 18% | 82% |
| Hardware failures | 45 | 12% | 94% |
| Λοιπά | 23 | 6% | 100% |

> Το **Pareto principle** εδώ δείχνει: αν λύσουμε τα Password/Account issues (πχ με self-service reset — βλ. αρχείο 4) και τα Network issues, καλύπτουμε το **64% όλων των incidents** με μόλις 2 από τις 5 κατηγορίες.

### Πότε να χρησιμοποιήσεις ποια τεχνική
| Τεχνική | Χρήση όταν... |
|---|---|
| 5 Whys | Το πρόβλημα είναι σχετικά απλό, μία κύρια αιτιακή αλυσίδα |
| Fishbone | Πολλαπλές πιθανές αιτίες, χρειάζεται brainstorming σε ομάδα |
| Pareto | Έχεις πολλά δεδομένα/incidents και θέλεις να προτεραιοποιήσεις πού να επενδύσεις χρόνο |

---

## 🚨 4. Emergency Change Process

Διαφορετική (πιο γρήγορη) διαδρομή από το κανονικό Change Management — χρησιμοποιείται όταν η αλλαγή είναι απαραίτητη **άμεσα** για την αποκατάσταση κρίσιμης υπηρεσίας.

### Ροή Emergency Change

```
Major Incident σε εξέλιξη
        |
        v
Χρειάζεται άμεση αλλαγή για αποκατάσταση
        |
        v
Emergency CAB (μπορεί να είναι 1-2 άτομα, όχι πλήρες CAB)
   - Προφορική/γρήγορη έγκριση (πχ IT Manager + Technical Lead)
        |
        v
Εφαρμογή αλλαγής ΑΜΕΣΑ
        |
        v
Retroactive documentation (πλήρες CHG record συμπληρώνεται ΜΕΤΑ)
        |
        v
Παρουσίαση στο επόμενο κανονικό CAB για επισκόπηση
```

### 📝 Emergency Change Record (συμπληρώνεται κατά/μετά)
```markdown
## Emergency Change — CHG-2026-0099-E

**Σχετικό Major Incident:** INC-2026-0150
**Εγκρίθηκε προφορικά από:** [Όνομα IT Manager] — 10:15
**Εφαρμόστηκε από:** [Όνομα] — 10:20

### Τι έγινε
[πχ "Restart storage controller + failover σε secondary path"]

### Γιατί δεν ακολουθήθηκε κανονική διαδικασία
Κρίσιμη διακοπή site-wide, κάθε λεπτό καθυστέρησης αύξανε την επίπτωση.

### Αποτέλεσμα
Επιτυχές — υπηρεσία αποκαταστάθηκε στις 10:35.

### Retroactive review
Παρουσιάστηκε στο CAB της 2026-08-25 — εγκρίθηκε αναδρομικά, καμία ανησυχία.
```

> ⚠️ Emergency Change **δεν σημαίνει "χωρίς έλεγχο"** — σημαίνει ότι ο έλεγχος γίνεται *πιο γρήγορα και πιο μετά*, όχι ότι παραλείπεται.

---

## 🧊 5. Change Freeze / Blackout Periods

Περίοδοι όπου **δεν επιτρέπονται μη-επείγουσες αλλαγές** σε production, συνήθως γύρω από κρίσιμες επιχειρηματικές περιόδους.

### Παραδείγματα typical freeze periods
| Περίοδος | Λόγος |
|---|---|
| Black Friday / Χριστούγεννα (retail) | Μέγιστη χρήση συστημάτων, κάθε ρίσκο είναι απαράδεκτο |
| Τέλος οικονομικού έτους (Finance systems) | Κρίσιμες οικονομικές διαδικασίες σε εξέλιξη |
| Περίοδος payroll (κάθε μήνα, 2-3 μέρες πριν/μετά) | Καμία διακοπή στο σύστημα μισθοδοσίας |

### 📝 Change Freeze Announcement Template
```markdown
## Change Freeze Notice

**Περίοδος freeze:** 2026-12-15 έως 2027-01-05
**Λόγος:** Περίοδος εορτών — μέγιστη επιχειρηματική δραστηριότητα

### Τι επιτρέπεται
- Emergency Changes (με πλήρη retroactive documentation)
- Security patches κρίσιμης σοβαρότητας (CVSS ≥ 9) — με έγκριση CAB

### Τι ΔΕΝ επιτρέπεται
- Όλα τα Normal/Standard Changes σε production
- Ανανεώσεις/upgrades μη κρίσιμων συστημάτων

### Επικοινωνία
Ενημερώθηκαν όλα τα τμήματα IT και stakeholders στις [ημερομηνία].
```

---

## 📣 6. Stakeholder Communication Plan

Ορίζει **ποιος ενημερώνεται, πώς, και πότε** — ώστε να μην υπάρχει σύγχυση σε κρίσιμες στιγμές.

| Stakeholder Group | Κανάλι | Συχνότητα/Trigger | Υπεύθυνος |
|---|---|---|---|
| Όλοι οι χρήστες | Company-wide email | Major Incident, Scheduled Maintenance | Comms Lead |
| Department Managers | Email + Teams | Οποιαδήποτε επίπτωση στο τμήμα τους | IT Manager |
| Executive Team | Σύντομο briefing | Major Incident (P1) μόνο, ή business-critical DR event | IT Director |
| IT Team (εσωτερικά) | Teams channel / bridge call | Real-time κατά τη διάρκεια incident | MIM |
| Εξωτερικοί πελάτες (αν εφαρμόζεται) | Status page / email | Επίπτωση σε customer-facing υπηρεσίες | Comms Lead + Account Manager |

### Κανόνας: "No news is bad news" σε Major Incident
Ακόμα κι αν δεν υπάρχει πρόοδος, στέλνεται update στο προγραμματισμένο interval (πχ κάθε 30 λεπτά) — η σιωπή δημιουργεί ανησυχία και πολλαπλά ερωτήματα προς το helpdesk.

---

## 📉 7. Trend Analysis & Problem Trend Report

Πηγαίνει πέρα από το μεμονωμένο incident — ψάχνει **patterns σε βάθος χρόνου**.

### 📝 Quarterly Problem Trend Report

| Κατηγορία | Q1 | Q2 | Q3 | Trend |
|---|:---:|:---:|:---:|:---:|
| Network-related incidents | 45 | 38 | 52 | ↑ Αύξηση — χρειάζεται διερεύνηση |
| Account/Access incidents | 120 | 95 | 80 | ↓ Βελτίωση (self-service reset λειτούργησε) |
| Hardware failures | 20 | 22 | 19 | ↔ Σταθερό |
| Application errors | 30 | 45 | 41 | ↑ Χρειάζεται Problem Record |

### Ερμηνεία & ενέργειες
- **Network incidents αυξήθηκαν 37% στο Q3** → άνοιγμα proactive Problem Record για διερεύνηση κοινής αιτίας (πχ νέος εξοπλισμός, αλλαγή τοπολογίας).
- **Account/Access incidents μειώθηκαν 33%** μετά την εισαγωγή self-service password reset → επιβεβαίωση ότι το CSI-002 (από προηγούμενο αρχείο) είχε πραγματικό αντίκτυπο.

---

## 🗺️ 8. IT Strategy Roadmap — Template

Ανώτερου επιπέδου έγγραφο, δείχνει την κατεύθυνση του IT τμήματος πέρα από την καθημερινή λειτουργία.

```markdown
## IT Strategy Roadmap — 2026-2027

### Στρατηγικός στόχος 1: Βελτίωση Availability κρίσιμων συστημάτων
- Q3 2026: BIA για όλα τα κρίσιμα συστήματα
- Q4 2026: Υλοποίηση S2D cluster για file services
- Q1 2027: DR test με ενημερωμένα RTO/RPO

### Στρατηγικός στόχος 2: Μείωση χειροκίνητου φόρτου εργασίας
- Q3 2026: Self-service portal για password reset (ολοκληρώθηκε)
- Q4 2026: Αυτοματοποίηση onboarding/offboarding
- Q1 2027: Chatbot για Tier 1 FAQ

### Στρατηγικός στόχος 3: Μετάβαση σε Hybrid Cloud
- Q4 2026: Azure AD Connect deployment
- Q1 2027: Migration πρώτου workload σε Azure IaaS
- Q2 2027: Αξιολόγηση πλήρους cloud migration στρατηγικής

### Metrics επιτυχίας
- Availability κρίσιμων συστημάτων: 99.5% → 99.9%
- Tier 1 ticket volume: -25%
- Χρόνος onboarding νέου υπαλλήλου: 2 μέρες → 4 ώρες
```

---

## 🔗 9. Πλήρες Παράδειγμα — BIA οδηγεί σε DR Investment

```
1. Ετήσια BIA ανάλυση δείχνει: το ERP σύστημα έχει MTD 24 ωρών,
   αλλά το τρέχον DR plan προβλέπει RTO 12 ωρών... περιμένεις να είναι OK
   → Έλεγχος στην πράξη: το τελευταίο DR test (βλ. αρχείο 2) έδειξε
     πραγματικό RTO 3h 10min — άρα καλύπτεται με άνεση!

2. Ωστόσο, η BIA αποκαλύπτει ΝΕΟ κρίσιμο σύστημα (νέα εφαρμογή CRM)
   που δεν έχει καθόλου DR plan ακόμα

3. Δημιουργείται νέο BIA record για το CRM
   → MTD: 8 ώρες, RTO στόχος: 4 ώρες, RPO στόχος: 30 λεπτά

4. Η ανάλυση τροφοδοτεί το IT Strategy Roadmap
   → Νέο strategic item: "Q1 2027: DR plan + testing για CRM σύστημα"

5. Γίνεται Business Case προς management με βάση το BIA
   (οικονομική επίπτωση downtime vs κόστος DR investment)
   → Έγκριση budget

6. Sysadmin team υλοποιεί replication/backup στρατηγική
   → Πρώτο DR test προγραμματίζεται, ακολουθεί το ίδιο πρότυπο
     "DR Test Report" (βλ. αρχείο 2)
```

Αυτό δείχνει πώς το **BIA** συνδέει τη στρατηγική εικόνα (τι πραγματικά χρειάζεται η επιχείρηση) με τις καθημερινές τεχνικές διαδικασίες (DR testing, Change Management, Strategy Roadmap) — η "γέφυρα" μεταξύ governance και operations.

---

*Μέρος του [Infrastructure Knowledge Base](https://github.com/Dimitriskatsanos42/Infrastructure-Knowledge-Base) — ενότητα IT-Service-Management, συμπληρωματικό στα προηγούμενα 5 αρχεία της σειράς.*
