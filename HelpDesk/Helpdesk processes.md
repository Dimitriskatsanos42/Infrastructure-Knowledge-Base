# 🖥️ HelpDesk Processes — ITIL Framework & Operations

> Πλήρης οδηγός διαδικασιών IT Support — από τη θεωρία ITIL μέχρι την καθημερινή πράξη του HelpDesk.

---

## 🗺️ Πίνακας Περιεχομένων
1. [Τι είναι το ITIL;](#-1-τι-είναι-το-itil)
2. [Incident Management](#-2-incident-management)
3. [Problem Management](#-3-problem-management)
4. [Change Management](#-4-change-management)
5. [SLA / SLO / SLI](#-5-sla--slo--sli)
6. [Escalation Tiers](#-6-escalation-tiers)
7. [Κύκλος Ζωής Ticket](#-7-κύκλος-ζωής-ticket)
8. [Επικοινωνία με Χρήστες](#-8-επικοινωνία-με-χρήστες)
9. [📚 Πηγές Μελέτης](#-πηγές-μελέτης)

---

## 📖 1. Τι είναι το ITIL;

Το **ITIL (Information Technology Infrastructure Library)** είναι ένα σύνολο βέλτιστων πρακτικών για τη διαχείριση IT υπηρεσιών. Δεν είναι εργαλείο ή λογισμικό — είναι **φιλοσοφία και μεθοδολογία**.

> *"Η IT δεν υπάρχει για να διαχειρίζεται servers — υπάρχει για να εξυπηρετεί την επιχείρηση."*

**Γιατί το χρησιμοποιούν οι εταιρείες:**
* **Κοινή γλώσσα** μεταξύ IT και business
* **Μετρήσιμη ποιότητα** υπηρεσιών μέσω SLA
* **Λιγότερα incidents** μέσω proactive διαχείρισης
* **Τυποποιημένες διαδικασίες** — λιγότερα λάθη

### Βασικές Διεργασίες ITIL:
```text
Service Desk (κεντρικό σημείο επαφής)
├── Incident Management      → Επίλυση διακοπών υπηρεσιών
├── Problem Management       → Εύρεση root cause
├── Change Management        → Ελεγχόμενες αλλαγές
├── Request Fulfillment      → Εξυπηρέτηση αιτημάτων (νέο laptop, πρόσβαση κτλ.)
├── Configuration Management → Καταγραφή assets (CMDB)
└── Knowledge Management     → Βάση γνώσης (Known Errors, Workarounds)
```

---

## 🚨 2. Incident Management

### Τι είναι Incident;
> **Incident** = οποιοδήποτε απρόβλεπτο γεγονός που διακόπτει ή υποβαθμίζει μια IT υπηρεσία.

| Παραδείγματα Incident | ΔΕΝ είναι Incident |
| :--- | :--- |
| Ο χρήστης δεν μπορεί να συνδεθεί στο VPN | Αίτημα για νέο laptop (= Service Request) |
| Ο server είναι down | Reset κωδικού (= Service Request) |
| Το email δεν λειτουργεί | Ερώτηση "Πώς να κάνω X;" (= Service Request) |
| BSOD σε workstation | Εγκατάσταση νέου software (= Change) |

### Διαδικασία Incident Management
```text
1. DETECTION       → Χρήστης καλεί / email / monitoring alert / walk-in
       ↓
2. LOGGING         → Δημιουργία ticket με όλες τις πληροφορίες
       ↓
3. CATEGORIZATION  → Hardware / Software / Network / Security / Access
       ↓
4. PRIORITIZATION  → Βάσει Impact × Urgency (Priority Matrix)
       ↓
5. DIAGNOSIS       → Tier 1: έως 30 λεπτά προσπάθεια
       ↓
6. ESCALATION      → Αν δεν λυθεί → Tier 2/3
       ↓
7. RESOLUTION      → Εφαρμογή λύσης + επιβεβαίωση από χρήστη
       ↓
8. CLOSURE         → Documentation + Knowledge Base update
```

### Priority Matrix
* **Impact** = Πόσοι χρήστες / επιχειρησιακές διεργασίες επηρεάζονται
* **Urgency** = Πόσο γρήγορα χρειάζεται λύση

| | Υψηλό Urgency | Χαμηλό Urgency |
| :--- | :--- | :--- |
| **Υψηλό Impact** | 🔴 **P1 — Critical** | 🟠 **P2 — High** |
| **Χαμηλό Impact** | 🟡 **P3 — Medium** | 🟢 **P4 — Low** |

### Χρόνοι Απόκρισης & Επίλυσης

| Priority | Παράδειγμα | Response Time | Resolution Time |
| :--- | :--- | :--- | :--- |
| **P1 Critical** | Ολόκληρο το δίκτυο down | 15 λεπτά | 4 ώρες |
| **P2 High** | Email server down | 30 λεπτά | 8 ώρες |
| **P3 Medium** | 1 χρήστης δεν εκτυπώνει | 2 ώρες | 24 ώρες |
| **P4 Low** | Αίτημα για νέο mouse | 8 ώρες | 72 ώρες |

### Major Incident (P1) — Διαδικασία
Όταν ανοίγει P1, ενεργοποιείται ειδική διαδικασία:
1. **Άμεση ειδοποίηση** IT Manager + Tier 2/3 + Business Owner.
2. **War Room** — dedicated Teams channel / conference call.
3. **Incident Commander** (συντονίζει — ΔΕΝ κάνει technical work).
4. **Updates κάθε 30 λεπτά** προς stakeholders.
5. **Post-Incident Review (PIR)** εντός 48 ωρών από την επίλυση.

---

## 🔍 3. Problem Management

### Incident vs Problem

| Χαρακτηριστικό | Incident | Problem |
| :--- | :--- | :--- |
| **Τι είναι** | Το σύμπτωμα | Η αιτία |
| **Στόχος** | Γρήγορη επίλυση | Εύρεση root cause |
| **Χρόνος** | Άμεσα | Μέρες / εβδομάδες |
| **Παράδειγμα** | "Ο server είναι down" | "Γιατί πέφτει κάθε Δευτέρα;" |

### Root Cause Analysis — 5 Whys
* **Incident:** Ο χρήστης δεν μπορεί να εκτυπώσει.
  * **Why 1:** → Ο printer spooler service είναι stopped.
  * **Why 2:** → Κατέρρευσε λόγω corrupt print job.
  * **Why 3:** → Ο χρήστης έστειλε 500MB PDF στον printer.
  * **Why 4:** → Δεν υπάρχει όριο μεγέθους print job στο GPO.
  * **Why 5:** → Ποτέ δεν ορίστηκε στην πολιτική.
* **Root Cause:** Έλλειψη GPO για max print job size.
* **Permanent Fix:** Νέο GPO → max print job = 50MB.

### Known Error Database (KEDB)
Όταν βρεθεί root cause αλλά δεν υπάρχει ακόμα permanent fix:

> **Known Error:** #KE-2025-047  
> **Τίτλος:** Printer spooler κολλάει με αρχεία > 100MB  
> **Workaround:** Restart Print Spooler service (`services.msc` → Spooler → Restart)  
> **Status:** Permanent fix σε εξέλιξη (GPO deployment Q3 2025)  

---

## 🔄 4. Change Management

### Γιατί Υπάρχει;
Στατιστικά, **70–80% των incidents** προκαλούνται από αλλαγές που δεν έγιναν σωστά.

### Τύποι Change

| Τύπος | Περιγραφή | Παράδειγμα | Έγκριση |
| :--- | :--- | :--- | :--- |
| **Standard** | Pre-approved, low risk, routine | Password reset, RAM upgrade | Δεν χρειάζεται |
| **Normal** | Απαιτεί CAB approval | Server upgrade, new firewall rule | CAB Meeting |
| **Emergency** | Urgent — για P1 incidents | Critical security patch | Emergency CAB |

* **CAB (Change Advisory Board)** = επιτροπή που εγκρίνει τα Normal Changes.

### Change Request Process
1. **RFC (Request for Change)** → Τι αλλάζει, γιατί, πότε
2. **Impact Assessment** → Τι μπορεί να σπάσει;
3. **Rollback Plan** → Πώς επιστρέφουμε αν αποτύχει;
4. **CAB Approval**
5. **Implementation** (σε maintenance window)
6. **Testing & Verification**
7. **Closure ή Rollback**

> 💡 **Maintenance Window:** Συνήθως βράδια (22:00–06:00) ή Σαββατοκύριακο — περίοδος χαμηλής χρήσης για αλλαγές.

---

## 📊 5. SLA / SLO / SLI

| Όρος | Τι είναι | Παράδειγμα |
| :--- | :--- | :--- |
| **SLA** *(Service Level Agreement)* | Επίσημη συμφωνία IT ↔ Business | "P1 incidents επιλύονται σε 4 ώρες" |
| **SLO** *(Service Level Objective)* | Εσωτερικός στόχος (πιο αυστηρός από SLA) | "P1 incidents να λύνονται σε 3 ώρες" |
| **SLI** *(Service Level Indicator)* | Η μέτρηση που αποδεικνύει αν πετύχαμε | "Μέσος χρόνος επίλυσης P1: 2.5 ώρες" |

### Βασικές Μετρήσεις HelpDesk

| Μέτρηση | Ορισμός | Benchmark |
| :--- | :--- | :--- |
| **MTTR** *(Mean Time To Resolve)* | Μέσος χρόνος επίλυσης | P1: <4h, P3: <24h |
| **MTTA** *(Mean Time To Acknowledge)* | Μέσος χρόνος πρώτης απόκρισης | < 15 λεπτά |
| **FCR** *(First Call Resolution)* | % tickets που λύνονται στην πρώτη επαφή | > 70% |
| **Backlog** | Αριθμός ανοιχτών tickets | < 10% εβδομαδιαίου volume |
| **CSAT** *(Customer Satisfaction)* | Βαθμολογία ικανοποίησης χρηστών | > 85% |
| **Reopen Rate** | % tickets που ανοίγουν ξανά | < 5% |

### SLA Breach — Τι Γίνεται;
```text
Ticket ανοιχτό → Timer ξεκινά
       │
       ├─ 50% SLA time  → Reminder notification στον technician
       ├─ 75% SLA time  → Warning + auto-escalation στον supervisor
       └─ 100% (breach) → Manager alert + escalation report
```

---

## 📈 6. Escalation Tiers

```text
┌──────────────────────────────────────────┐
│  Tier 0 — Self-Service                   │
│  FAQ, Knowledge Base, Password Portal    │
└──────────────────┬───────────────────────┘
                   │ αν δεν λυθεί
                   ▼
┌──────────────────────────────────────────┐
│  Tier 1 — HelpDesk                       │
│  Γενική υποστήριξη, συνηθισμένα issues   │
│  Στόχος: 70–80% resolution rate          │
└──────────────────┬───────────────────────┘
                   │ αν δεν λυθεί σε ~30 λεπτά
                   ▼
┌──────────────────────────────────────────┐
│  Tier 2 — Desktop Support / Sysadmin     │
│  Βαθύτερη τεχνική γνώση, on-site        │
│  AD, servers, complex networking         │
└──────────────────┬───────────────────────┘
                   │ αν χρειαστεί expertise
                   ▼
┌──────────────────────────────────────────┐
│  Tier 3 — Senior Engineers / Vendors     │
│  Infrastructure, bugs, vendor support    │
└──────────────────────────────────────────┘
```

### Πότε να Κάνεις Escalation από Tier 1
* ✓ Πέρασαν 30 λεπτά χωρίς επίλυση
* ✓ Επηρεάζει παραπάνω από 1 χρήστη
* ✓ Χρειάζεται on-site παρουσία
* ✓ Είναι server/infrastructure related
* ✓ Πιθανό security incident
* ✓ Κίνδυνος SLA breach

### Τι Περιλαμβάνεις στο Escalation
* ✓ Τι ανέφερε ο χρήστης (**αυτολεξεί**)
* ✓ Τι έχεις ήδη δοκιμάσει
* ✓ Αποτελέσματα diagnostics (*ping, ipconfig, event logs*)
* ✓ Screenshots / error messages
* ✓ Πότε άρχισε το πρόβλημα
* ✓ Αν επηρεάζει και άλλους χρήστες

---

## 🔄 7. Κύκλος Ζωής Ticket

```text
NEW → ASSIGNED → IN PROGRESS → PENDING → RESOLVED → CLOSED
                                   │
                      (αναμονή χρήστη ή 3rd party)
```

| Status | Σημαίνει | Ποιος ενεργεί |
| :--- | :--- | :--- |
| **New** | Μόλις δημιουργήθηκε | Auto-assign |
| **Assigned** | Έχει ανατεθεί σε technician | Technician |
| **In Progress** | Γίνεται ενεργή δουλειά | Technician |
| **Pending** | Αναμονή για χρήστη / vendor / approval | Χρήστης ή 3rd party |
| **Resolved** | Λύση εφαρμόστηκε, αναμονή επιβεβαίωσης | Χρήστης |
| **Closed** | Επιβεβαιώθηκε ή auto-close μετά 48-72h | System |

> ⚠️ **Ποτέ μην κλείνεις ticket χωρίς επιβεβαίωση.** Αν δεν απαντήσει ο χρήστης → auto-close με notification.

---

## 💬 8. Επικοινωνία με Χρήστες

### Βασικές Αρχές

* **Acknowledge γρήγορα — έστω και χωρίς λύση:**
  > *"Έλαβα το αίτημά σου και ασχολούμαι αμέσως. Θα σε ενημερώσω σε 15 λεπτά."*
* **Μίλα στη γλώσσα του χρήστη:**
  * ❌ *"Υπάρχει πρόβλημα στο DNS resolution του domain controller."*
  * ✅ *"Το σύστημα που βρίσκει τους πόρους του δικτύου δεν ανταποκρίνεται. Εργάζομαι να το φτιάξω τώρα."*
* **Ενημέρωσε για πρόοδο — ακόμα και αν δεν υπάρχει νέο:**
  > *"Δεν έχω ακόμα λύση, αλλά συνεχίζω να εργάζομαι πάνω σε αυτό. Θα σε ενημερώσω σε 30 λεπτά."*
* **Πριν κλείσεις ticket — πάντα επιβεβαίωσε:**
  > *"Έλυσα το πρόβλημα. Μπορείς να δοκιμάσεις και να μου επιβεβαιώσεις ότι όλα λειτουργούν κανονικά;"*

### Δύσκολες Καταστάσεις

| Κατάσταση | ❌ Λάθος | ✅ Σωστό |
| :--- | :--- | :--- |
| **Εκνευρισμένος χρήστης** | "Δεν φταίω εγώ" | "Καταλαβαίνω ότι αυτό σε δυσκολεύει. Ας το λύσουμε μαζί." |
| **"Δεν ήταν ποτέ πρόβλημα πριν"** | Άμυνα | "Έχεις δίκιο, ας δούμε τι άλλαξε." |
| **Εκτός πολιτικής αίτημα** | Απλό "Δεν γίνεται" | "Αυτό δεν το καλύπτει η πολιτική, αλλά μπορώ να σε βοηθήσω με [εναλλακτική]." |
| **Επαναλαμβανόμενο πρόβλημα** | Ξαναλύσε το ίδιο | Καταγραφή ως **Problem** — εύρεση root cause |

---

## 📚 Πηγές Μελέτης
* **ITIL 4 Foundation** — Επίσημη πιστοποίηση
* **ServiceNow Documentation** — Δημοφιλές ITSM tool
* **HDI Help Desk Institute** — Resources για Support professionals
