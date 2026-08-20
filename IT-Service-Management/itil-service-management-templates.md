# 📋 ITIL & IT Service Management — Templates & Process Documentation

Νέα ενότητα στο knowledge base, ξεχωριστή από το τεχνικό Windows/Azure υλικό. Καλύπτει τις **διαδικασίες** (process) που πλαισιώνουν τη δουλειά ενός sysadmin — κάτι που ζητείται συχνά σε εταιρικό περιβάλλον και δείχνει επαγγελματική ωριμότητα πέρα από τις καθαρά τεχνικές δεξιότητες.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Τι είναι το ITIL — Σύντομη Εισαγωγή](#-1-τι-είναι-το-itil--σύντομη-εισαγωγή)
2. [Incident Management — Process & Template](#-2-incident-management--process--template)
3. [Problem Management — Process & Template](#-3-problem-management--process--template)
4. [Change Management — RFC Template](#-4-change-management--rfc-template)
5. [Service Request Template](#-5-service-request-template)
6. [Runbook / SOP Template](#-6-runbook--sop-template)
7. [Post-Incident Review (RCA) Template](#-7-post-incident-review-rca-template)
8. [Escalation Matrix](#-8-escalation-matrix)
9. [SLA / KPI Παραδείγματα](#-9-sla--kpi-παραδείγματα)
10. [Παράδειγμα Πλήρους Ροής — Από Ticket σε RCA](#-10-παράδειγμα-πλήρους-ροής--από-ticket-σε-rca)

---

## 📖 1. Τι είναι το ITIL — Σύντομη Εισαγωγή

Το **ITIL (Information Technology Infrastructure Library)** είναι ένα πλαίσιο best practices για IT Service Management (ITSM). Δεν είναι εργαλείο ή λογισμικό — είναι **τρόπος οργάνωσης διαδικασιών**.

### Οι βασικές διαδικασίες που αφορούν έναν sysadmin
| Process | Σκοπός |
|---|---|
| **Incident Management** | Γρήγορη αποκατάσταση υπηρεσίας μετά από διακοπή |
| **Problem Management** | Εντοπισμός root cause ώστε να μην ξανασυμβεί το incident |
| **Change Management** | Ελεγχόμενη εφαρμογή αλλαγών στο IT περιβάλλον |
| **Service Request Management** | Διεκπεραίωση τυποποιημένων αιτημάτων (πχ νέος χρήστης, νέο laptop) |
| **Configuration Management (CMDB)** | Καταγραφή όλων των assets/relationships στο IT περιβάλλον |

### Διαφορά Incident vs Problem vs Change
- **Incident** = κάτι έσπασε *τώρα*, θέλει άμεση λύση (ακόμα και προσωρινή/workaround).
- **Problem** = γιατί έσπασε, ώστε να μην ξανασυμβεί (root cause analysis).
- **Change** = οποιαδήποτε σκόπιμη τροποποίηση σε production σύστημα (ακόμα κι αν είναι θετική, πχ νέο update).

---

## 🚨 2. Incident Management — Process & Template

### Ροή διαδικασίας
```
Detection/Report → Logging → Categorization → Prioritization →
Diagnosis → Escalation (αν χρειάζεται) → Resolution → Closure
```

### Priority Matrix (Impact × Urgency)
| | Urgency: Low | Urgency: Medium | Urgency: High |
|---|---|---|---|
| **Impact: Low** | P4 | P3 | P3 |
| **Impact: Medium** | P3 | P2 | P2 |
| **Impact: High** | P2 | P1 | P1 |

| Priority | Target Response | Target Resolution |
|---|---|---|
| P1 — Critical | 15 λεπτά | 4 ώρες |
| P2 — High | 30 λεπτά | 8 ώρες |
| P3 — Medium | 2 ώρες | 2 εργάσιμες ημέρες |
| P4 — Low | 8 ώρες | 5 εργάσιμες ημέρες |

### 📝 Incident Ticket Template
```markdown
## Incident Report

**Ticket ID:** INC-2026-0142
**Reported by:** [Όνομα χρήστη / σύστημα]
**Date/Time reported:** 2026-08-20 09:15
**Assigned to:** [Τεχνικός]

### Περιγραφή
[Τι ανέφερε ο χρήστης — verbatim αν είναι δυνατόν]

### Επηρεαζόμενη υπηρεσία/σύστημα
[πχ File Server SRV01, Exchange, VPN]

### Impact
- [ ] Single user
- [ ] Department
- [ ] Site-wide
- [ ] Organization-wide

### Urgency
- [ ] Low  - [ ] Medium  - [ ] High

### Priority (Impact × Urgency)
P1 / P2 / P3 / P4

### Βήματα διάγνωσης
1. ...
2. ...

### Root cause (αν γνωστό)
[...]

### Λύση / Workaround
[Τι έγινε για να λυθεί]

### Status
Open / In Progress / Escalated / Resolved / Closed

### Χρόνος επίλυσης
[Ώρα κλεισίματος] — [Total time to resolve]
```

---

## 🔍 3. Problem Management — Process & Template

### Πότε ανοίγει ένα Problem record
- Επαναλαμβανόμενα incidents με το ίδιο pattern.
- Major incident (P1) που χρειάζεται βαθιά ανάλυση root cause.
- Proactive εντόπιση πιθανού μελλοντικού προβλήματος (πχ disk space trend).

### 📝 Problem Record Template
```markdown
## Problem Record

**Problem ID:** PRB-2026-0031
**Related Incidents:** INC-2026-0140, INC-2026-0142, INC-2026-0145
**Opened by:** [Όνομα]
**Date opened:** 2026-08-20

### Σύμπτωμα (τι παρατηρείται επαναλαμβανόμενα)
[πχ "Ο DHCP server σταματά να απαντά κάθε Δευτέρα πρωί"]

### Root Cause Analysis
[Ανάλυση — μπορεί να χρησιμοποιηθεί 5 Whys ή Fishbone diagram]

**5 Whys παράδειγμα:**
1. Γιατί σταμάτησε ο DHCP; → Η υπηρεσία crash-άρισε.
2. Γιατί crash-άρισε; → Out of memory.
3. Γιατί out of memory; → Memory leak σε συγκεκριμένο process.
4. Γιατί υπάρχει memory leak; → Παλιά έκδοση του DHCP role, γνωστό bug.
5. Γιατί δεν είχε γίνει update; → Δεν υπήρχε scheduled patching για αυτόν τον server.

### Root Cause (τελικό)
[Καθαρή δήλωση της αιτίας]

### Known Error
- [ ] Ναι — καταχωρήθηκε στο Known Error Database (KEDB)
- [ ] Όχι

### Προτεινόμενη μόνιμη λύση
[πχ "Ενημέρωση σε νέα build + ένταξη σε scheduled patching cycle"]

### Σχετικό Change Request
CHG-2026-0087
```

---

## 🔄 4. Change Management — RFC Template

### Change Categories
| Κατηγορία | Περιγραφή | Έγκριση |
|---|---|---|
| **Standard** | Προκαθορισμένη, χαμηλού ρίσκου, επαναλαμβανόμενη | Pre-approved |
| **Normal** | Χρειάζεται αξιολόγηση | CAB (Change Advisory Board) |
| **Emergency** | Επείγουσα, για αποκατάσταση κρίσιμου incident | Emergency CAB / retroactive |

### 📝 Request for Change (RFC) Template
```markdown
## Request for Change (RFC)

**Change ID:** CHG-2026-0087
**Requested by:** [Όνομα]
**Date submitted:** 2026-08-18
**Category:** Standard / Normal / Emergency
**Risk Level:** Low / Medium / High

### Περιγραφή αλλαγής
[Τι θα γίνει — πχ "Αναβάθμιση DHCP server role σε SRV02 στην τελευταία build"]

### Λόγος αλλαγής
[Σύνδεση με Problem ID αν υπάρχει: PRB-2026-0031]

### Επηρεαζόμενα συστήματα
[Λίστα servers/services]

### Πλάνο υλοποίησης
1. Backup τρέχουσας κατάστασης (system state / snapshot)
2. [Βήμα εφαρμογής]
3. [Βήμα validation]

### Πλάνο rollback
[Τι θα γίνει αν κάτι πάει στραβά — ακριβή βήματα]

### Παράθυρο υλοποίησης (Change Window)
[πχ Κυριακή 02:00–04:00, εκτός ωρών λειτουργίας]

### Testing plan
[Πώς θα επιβεβαιωθεί ότι η αλλαγή δούλεψε]

### Έγκριση
- [ ] Technical review — [Όνομα]
- [ ] CAB approval — [Ημερομηνία]

### Post-implementation review
[Συμπληρώνεται μετά — δούλεψε όπως αναμενόταν; χρειάστηκε rollback;]
```

---

## 🎫 5. Service Request Template

Για τυποποιημένα, μη-επείγοντα αιτήματα (διαφορετικά από incidents).

```markdown
## Service Request

**Request ID:** SR-2026-0210
**Requested by:** [Όνομα / Τμήμα]
**Type:** New User Account / Hardware Request / Access Request / Software Install

### Λεπτομέρειες αιτήματος
[πχ "Νέος υπάλληλος στο Λογιστήριο, χρειάζεται AD account + email + πρόσβαση σε shared folder Finance"]

### Approval required
- [ ] Manager approval — [Όνομα]
- [ ] IT approval

### Checklist εκτέλεσης (παράδειγμα: New Hire)
- [ ] Δημιουργία AD account (σωστό OU, group memberships)
- [ ] Δημιουργία mailbox
- [ ] Πρόσβαση σε απαραίτητα shared drives
- [ ] Provisioning laptop/desktop
- [ ] VPN access (αν χρειάζεται)
- [ ] Ενημέρωση χρήστη με credentials (secure delivery)

### Ολοκλήρωση
Date completed: [...]  Completed by: [...]
```

---

## 📘 6. Runbook / SOP Template

Ένα **Runbook** (ή Standard Operating Procedure) είναι επαναχρησιμοποιήσιμο βήμα-προς-βήμα έγγραφο για μια συγκεκριμένη, επαναλαμβανόμενη εργασία.

```markdown
## Runbook: [Τίτλος — πχ "Domain Controller Reboot Procedure"]

**Owner:** [Όνομα/Ρόλος]
**Last reviewed:** 2026-08-20
**Applies to:** [Συστήματα/περιβάλλον]

### Προαπαιτούμενα
- [ ] Δικαιώματα: [πχ Domain Admin]
- [ ] Change Request εγκεκριμένο (αν production)
- [ ] Backup επιβεβαιωμένο

### Βήματα
1. **Ειδοποίηση stakeholders** — email/ticket ενημέρωσης πριν το maintenance window.
2. **Pre-check:**
   ```powershell
   repadmin /replsummary
   Get-Service ntds,dns,netlogon
   ```
3. **Εκτέλεση ενέργειας:**
   ```powershell
   Restart-Computer -ComputerName DC01 -Force
   ```
4. **Post-check (μετά το reboot):**
   ```powershell
   Test-Connection DC01
   dcdiag /s:DC01
   repadmin /replsummary
   ```
5. **Επιβεβαίωση με stakeholders** ότι όλα λειτουργούν κανονικά.

### Rollback plan
[Τι κάνεις αν κάτι δεν επανέλθει σωστά]

### Γνωστά ζητήματα / σημειώσεις
[πχ "Αν το AD replication δεν επανέλθει σε 10 λεπτά, έλεγξε event log 1311"]
```

---

## 🔬 7. Post-Incident Review (RCA) Template

Χρησιμοποιείται μετά από **Major Incident (P1)** για δομημένη ανάλυση.

```markdown
## Post-Incident Review

**Incident ID:** INC-2026-0142
**Severity:** P1 — Critical
**Duration of outage:** 09:15 – 13:20 (4h 5min)
**Services affected:** File Server, DHCP (site-wide)

### Timeline
| Ώρα | Γεγονός |
|---|---|
| 09:15 | Πρώτη αναφορά χρήστη |
| 09:20 | Επιβεβαίωση — DHCP service down σε SRV02 |
| 09:35 | Escalation σε Senior Sysadmin |
| 10:10 | Root cause εντοπίστηκε — memory leak |
| 11:00 | Workaround εφαρμόστηκε (restart service) |
| 13:20 | Μόνιμη λύση — patch εφαρμόστηκε, incident κλειστό |

### Root Cause
[Σύνδεση με Problem Record PRB-2026-0031]

### Τι πήγε καλά
- Γρήγορη escalation
- Καλή επικοινωνία με χρήστες κατά τη διάρκεια

### Τι θα μπορούσε να βελτιωθεί
- Δεν υπήρχε monitoring alert για memory usage στο DHCP process
- Καθυστέρηση στο αρχικό escalation (15 λεπτά αντί για 5)

### Action Items
| Ενέργεια | Owner | Deadline |
|---|---|---|
| Προσθήκη monitoring alert για memory threshold | [Όνομα] | 2026-08-27 |
| Ένταξη DHCP role σε scheduled patching | [Όνομα] | 2026-09-05 |
| Ενημέρωση escalation runbook | [Όνομα] | 2026-08-25 |
```

---

## 📞 8. Escalation Matrix

| Επίπεδο | Ρόλος | Πότε ενεργοποιείται | SLA response |
|---|---|---|---|
| **Tier 1** | Helpdesk / Junior Sysadmin | Πρώτη επαφή, βασικό troubleshooting | 15 λεπτά |
| **Tier 2** | Sysadmin | Δεν λύθηκε σε Tier 1, ή απαιτεί admin rights | 30 λεπτά |
| **Tier 3** | Senior Sysadmin / Infra Engineer | Πολύπλοκο, architecture-level, ή P1 incident | 1 ώρα |
| **Tier 4** | Vendor Support / External | Hardware failure, licensing, vendor-specific bug | Ανάλογα με SLA προμηθευτή |

### Κανόνας escalation
> Αν δεν υπάρχει πρόοδος εντός του **50% του target resolution time** για το priority level, αυτόματο escalation στο επόμενο tier.

---

## 📊 9. SLA / KPI Παραδείγματα

### Service Level Agreement (SLA) — δείγμα πίνακα
| Metric | Target |
|---|---|
| P1 Incident response time | 15 λεπτά |
| P1 Incident resolution time | 4 ώρες |
| Service uptime (critical systems) | 99.9% |
| First Call Resolution rate | ≥ 70% |
| Customer satisfaction (CSAT) | ≥ 4.5/5 |

### KPIs για αναφορά προς management
- **MTTR** (Mean Time To Resolve) ανά priority level
- **Number of incidents** ανά κατηγορία/μήνα (trend analysis)
- **Change success rate** (% changes χωρίς rollback)
- **Repeat incidents** (δείκτης αποτελεσματικότητας Problem Management)

---

## 🔗 10. Παράδειγμα Πλήρους Ροής — Από Ticket σε RCA

```
1. Χρήστης αναφέρει: "Δεν παίρνω IP address"
   → Incident Ticket INC-2026-0142 ανοίγει (P2)

2. Tier 1 diagnosis: DHCP service down σε SRV02
   → Escalation σε Tier 2 (δεν έχει admin rights)

3. Tier 2: Restart service, δουλεύει προσωρινά
   → Ticket closed ως "Resolved" με workaround

4. Το ίδιο συμβαίνει 3 φορές μέσα σε μια εβδομάδα
   → Sysadmin ανοίγει Problem Record PRB-2026-0031

5. Root Cause Analysis (5 Whys) → memory leak σε παλιά build

6. Δημιουργείται Request for Change CHG-2026-0087
   → CAB approval → scheduled maintenance window

7. Αλλαγή εφαρμόζεται (patch update)
   → Post-Implementation Review: επιτυχές, καμία επανεμφάνιση

8. Problem Record κλείνει
   → Knowledge base ενημερώνεται με το known issue + λύση
```

Αυτή η ροή δείχνει πώς **Incident → Problem → Change → Knowledge Base** συνδέονται σε μια πλήρη, ώριμη διαδικασία IT operations — ακριβώς αυτό που ψάχνουν οι employers σε ένα portfolio.

---

*Μέρος του [Infrastructure Knowledge Base](https://github.com/Dimitriskatsanos42/Infrastructure-Knowledge-Base) — ενότητα IT Service Management, συμπληρωματική στο τεχνικό υλικό Windows/Azure.*
