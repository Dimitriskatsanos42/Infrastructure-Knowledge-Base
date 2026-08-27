# 📋 IT Service Management — Major Incidents, CAB & Continual Improvement

Τρίτο αρχείο της ενότητας **IT-Service-Management**, συμπληρωματικό στα `itil-service-management-templates.md` και `itsm-additional-templates.md`. Εστιάζει σε **διαδικασίες υψηλής έντασης** (Major Incidents), **συλλογική λήψη αποφάσεων** (CAB) και **συνεχή βελτίωση** — κομμάτια που δείχνουν ωριμότητα σε operational και governance επίπεδο.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Major Incident Management — Process & Roles](#-1-major-incident-management--process--roles)
2. [Change Advisory Board (CAB) — Meeting Template](#-2-change-advisory-board-cab--meeting-template)
3. [Shift Handover Template](#-3-shift-handover-template)
4. [Continual Service Improvement (CSI) Register](#-4-continual-service-improvement-csi-register)
5. [Business Continuity Plan — Βασικά](#-5-business-continuity-plan--βασικά)
6. [Ticket Categorization / Taxonomy](#-6-ticket-categorization--taxonomy)
7. [Monthly Service Review Report](#-7-monthly-service-review-report)
8. [Security Incident Response — Mini Playbook](#-8-security-incident-response--mini-playbook)
9. [Πλήρες Παράδειγμα — Major Incident End-to-End](#-9-πλήρες-παράδειγμα--major-incident-end-to-end)

---

## 🔥 1. Major Incident Management — Process & Roles

Ένα **Major Incident** είναι ξεχωριστή διαδικασία από το κανονικό Incident Management — ενεργοποιείται όταν η επίπτωση είναι τόσο μεγάλη (site-wide outage, data breach, κρίσιμη εφαρμογή down) που χρειάζεται ειδική δομή συντονισμού.

### Κριτήρια ενεργοποίησης Major Incident
- Επίπτωση σε πολλαπλά τμήματα/sites ταυτόχρονα
- Πλήρης διακοπή κρίσιμης υπηρεσίας (P1 με site-wide ή organization-wide impact)
- Πιθανή οικονομική ή reputational ζημιά
- Media/customer-facing επίπτωση

### Ρόλοι κατά τη διάρκεια Major Incident

| Ρόλος | Ευθύνη |
|---|---|
| **Major Incident Manager (MIM)** | Συντονίζει όλη τη διαδικασία, λαμβάνει τελικές αποφάσεις |
| **Technical Lead** | Καθοδηγεί την τεχνική διερεύνηση/αποκατάσταση |
| **Communications Lead** | Ενημερώνει stakeholders/χρήστες σε τακτά διαστήματα |
| **Scribe** | Καταγράφει timeline, αποφάσεις, ενέργειες σε πραγματικό χρόνο |

### Διαδικασία (bridge call structure)
```
1. Declare Major Incident → ενεργοποίηση bridge call (Teams/Zoom/κλήση)
2. MIM συγκεντρώνει τους κατάλληλους τεχνικούς
3. Κάθε 15-30 λεπτά: status update στο bridge + επικοινωνία εκτός bridge
4. Τεχνική ομάδα εργάζεται παράλληλα σε πιθανές λύσεις
5. Μόλις αποκατασταθεί: επιβεβαίωση από business/χρήστες
6. Formal closure + προγραμματισμός Post-Incident Review
```

### 📝 Major Incident Status Update Template (κάθε 15-30 λεπτά)
```markdown
**MAJOR INCIDENT UPDATE #3 — 10:45**

**Incident:** Site-wide email outage
**Started:** 09:15  |  **Duration:** 1h 30min
**Impact:** Όλοι οι χρήστες, όλα τα sites
**Current status:** Root cause εντοπίστηκε (Exchange DB corruption) — εφαρμόζεται fix
**Next update:** 11:15 ή νωρίτερα αν υπάρξει εξέλιξη
**MIM:** [Όνομα]
```

---

## 🗳️ 2. Change Advisory Board (CAB) — Meeting Template

Το **CAB** είναι η ομάδα που εγκρίνει Normal Changes πριν εφαρμοστούν σε production.

### 📝 CAB Meeting Agenda Template
```markdown
## CAB Meeting — [Ημερομηνία]

**Συμμετέχοντες:** [IT Manager, Infra Lead, Security, Application Owner, κλπ.]

### Changes προς αξιολόγηση

| Change ID | Περιγραφή | Requestor | Risk | Προτεινόμενο Window | Απόφαση |
|---|---|---|:---:|---|:---:|
| CHG-0087 | Upgrade DHCP role σε SRV02 | Sysadmin A | Low | Κυριακή 02:00-04:00 | ✅ Approved |
| CHG-0091 | Migration file server σε νέο SAN | Sysadmin B | High | Σαββατοκύριακο (2 μέρες) | ⏸️ Χρειάζεται περισσότερες λεπτομέρειες |
| CHG-0093 | Firewall rule update για νέο vendor | Network Team | Medium | Τρίτη 22:00-23:00 | ✅ Approved με όρο: rollback test πριν |

### Σχόλια/Όροι έγκρισης
- CHG-0091: Χρειάζεται λεπτομερές πλάνο rollback πριν την επόμενη συνάντηση.
- CHG-0093: Έγκριση υπό τον όρο ότι θα γίνει δοκιμή σε staging πρώτα.

### Ημερομηνία επόμενης συνάντησης
[...]
```

### Ερωτήσεις που κάνει καλό CAB για κάθε Change
1. Ποιο είναι το business justification;
2. Τι μπορεί να πάει στραβά, και πόσο σοβαρό θα ήταν;
3. Υπάρχει tested rollback plan;
4. Έχει γίνει testing σε non-production περιβάλλον;
5. Ποιος θα είναι διαθέσιμος κατά το change window;
6. Επηρεάζει άλλα scheduled changes (conflict check);

---

## 🔄 3. Shift Handover Template

Κρίσιμο σε περιβάλλοντα με βάρδιες (24/7 support) — αποτρέπει απώλεια πληροφορίας μεταξύ shifts.

```markdown
## Shift Handover — [Ημερομηνία] — [Shift: Πρωί/Απόγευμα/Νύχτα]

**Από:** [Όνομα] → **Σε:** [Όνομα]
**Ώρα handover:** [...]

### Ανοιχτά Incidents σε εξέλιξη

| Ticket | Περιγραφή | Status | Επόμενο βήμα | Owner |
|---|---|---|---|---|
| INC-0142 | DHCP intermittent issue | Monitoring | Έλεγχος αν επανεμφανιστεί | Επόμενη βάρδια |
| INC-0145 | Χρήστης δεν βλέπει shared drive | Waiting on user | Χρήστης θα επιβεβαιώσει το πρωί | Επόμενη βάρδια |

### Scheduled activities κατά τη διάρκεια της επόμενης βάρδιας
- [ ] 02:00 — Scheduled backup job (επιβεβαίωση επιτυχίας το πρωί)
- [ ] 03:00 — Change CHG-0087 (DHCP upgrade) — bridge call αν χρειαστεί

### Γενικές σημειώσεις / ασυνήθιστη συμπεριφορά
[πχ "Ο server SRV-DB01 έδειξε στιγμιαία αύξηση CPU στις 14:20, χωρίς επίπτωση — παρακολούθηση"]

### Escalations που έγιναν κατά τη βάρδια
[...]
```

---

## 📊 4. Continual Service Improvement (CSI) Register

Καταγράφει ιδέες/ευκαιρίες βελτίωσης — δεν χρειάζεται να είναι reactive (μετά από incident), μπορεί να είναι proactive.

| CSI ID | Ευκαιρία βελτίωσης | Πηγή | Impact αν εφαρμοστεί | Effort | Priority | Status |
|---|---|---|---|:---:|:---:|:---:|
| CSI-001 | Αυτοματοποίηση onboarding checklist με script | Επαναλαμβανόμενο manual task | Εξοικονόμηση 2h/onboarding | Medium | High | 🔄 In Progress |
| CSI-002 | Monitoring alert για DHCP memory usage | Post-Incident Review INC-0142 | Πρόληψη μελλοντικού outage | Low | High | ✅ Completed |
| CSI-003 | Migration από legacy ticketing σε νέο σύστημα | Management directive | Καλύτερο reporting/SLA tracking | High | Medium | 📋 Backlog |
| CSI-004 | Δημιουργία KB άρθρων για top 10 συχνά tickets | Ανάλυση ticket trends | Μείωση MTTR, λιγότερα Tier 1 escalations | Medium | Medium | 📋 Backlog |

### Πηγές CSI ιδεών
- Post-Incident Reviews (τι θα μπορούσε να είχε αποτρέψει το incident)
- Παρατηρήσεις προσωπικού (repetitive manual tasks)
- Customer/user feedback
- Trend analysis (ίδιο πρόβλημα ξανά και ξανά)

---

## 🏢 5. Business Continuity Plan — Βασικά

Διαφορά από το DR Plan: το **DR Plan** αφορά IT systems recovery, ενώ το **BCP (Business Continuity Plan)** αφορά τη συνέχιση της **επιχειρηματικής λειτουργίας** συνολικά (ανθρώπους, διαδικασίες, εναλλακτικές τοποθεσίες).

### 📝 BCP Summary Template
```markdown
## Business Continuity Plan — [Τμήμα/Λειτουργία]

**Κρίσιμη λειτουργία:** [πχ "Εξυπηρέτηση πελατών μέσω τηλεφωνικού κέντρου"]
**Maximum Tolerable Downtime (MTD):** 8 ώρες

### Εναλλακτικές σε περίπτωση μη διαθεσιμότητας γραφείου
- [ ] Remote work setup (VPN, laptops, softphone)
- [ ] Εναλλακτικός χώρος εργασίας (αν προβλέπεται)

### Κρίσιμο προσωπικό & backup
| Ρόλος | Κύριος υπεύθυνος | Backup |
|---|---|---|
| IT Manager | [Όνομα] | [Όνομα] |
| Network Admin | [Όνομα] | [Όνομα] |

### Επικοινωνία σε κρίση
[Chain of communication — ποιος ενημερώνει ποιον]
```

---

## 🏷️ 6. Ticket Categorization / Taxonomy

Καλή κατηγοριοποίηση = καλύτερο reporting & trend analysis.

### Παράδειγμα δομής (Category → Subcategory → Item)

| Category | Subcategory | Item (παράδειγμα) |
|---|---|---|
| Hardware | Laptop/Desktop | Δεν ανάβει |
| Hardware | Peripherals | Εκτυπωτής δεν εκτυπώνει |
| Network | Connectivity | Δεν έχω internet |
| Network | VPN | Δεν συνδέεται το VPN |
| Account & Access | Password | Reset password |
| Account & Access | Permissions | Πρόσβαση σε shared folder |
| Application | Email | Δεν λαμβάνω emails |
| Application | Business App | Σφάλμα κατά την είσοδο |
| Security | Suspicious Activity | Phishing email αναφορά |

> Αυτή η δομή επιτρέπει reports όπως: *"Το 40% των tickets τον Αύγουστο ήταν Account & Access — ίσως χρειάζεται self-service password reset."*

---

## 📈 7. Monthly Service Review Report

Σύνοψη που παρουσιάζεται σε management — δείχνει την υγεία του IT service συνολικά.

**Monthly Service Review — Αύγουστος 2026**

| Metric | Target | Actual | Status |
|---|:---:|:---:|:---:|
| P1 Incidents | ≤ 2 | 1 | ✅ |
| P1 Avg Resolution Time | ≤ 4h | 3h 10min | ✅ |
| Total tickets | — | 342 | ℹ️ |
| First Call Resolution | ≥ 70% | 68% | ⚠️ Κάτω από στόχο |
| Change Success Rate | ≥ 95% | 97% | ✅ |
| Critical System Uptime | ≥ 99.9% | 99.95% | ✅ |
| CSAT | ≥ 4.5/5 | 4.6/5 | ✅ |

### Σχόλια
- Το First Call Resolution είναι ελαφρώς κάτω από στόχο — προτείνεται ανάλυση top αιτιών escalation στο Tier 2.

### Top 3 κατηγορίες tickets τον μήνα
| Category | # Tickets | % του συνόλου |
|---|:---:|:---:|
| Account & Access | 137 | 40% |
| Hardware | 89 | 26% |
| Network | 62 | 18% |

---

## 🛡️ 8. Security Incident Response — Mini Playbook

Ειδική περίπτωση Major Incident, με επιπλέον βήματα λόγω νομικών/compliance επιπτώσεων.

### Άμεσα βήματα σε πιθανό security incident (πχ ransomware, unauthorized access)
1. **Containment** — απομόνωση επηρεαζόμενου συστήματος από το δίκτυο (χωρίς να το κλείσεις — για forensics).
2. **Μην διαγράψεις τίποτα** — logs/evidence χρειάζονται για ανάλυση.
3. Ενημέρωση **Security Lead** και, ανάλογα με πολιτική, **Legal/Compliance**.
4. Καταγραφή timeline από την πρώτη στιγμή (ποιος το ανακάλυψε, πότε, πώς).
5. Αξιολόγηση αν χρειάζεται αναφορά σε αρχές (πχ GDPR data breach notification εντός 72 ωρών αν αφορά προσωπικά δεδομένα στην ΕΕ).
6. Μετά τον έλεγχο: επαναφορά από **καθαρό backup** (όχι απλά "καθαρισμός" του μολυσμένου συστήματος).

### Checklist πρώτης ώρας
- [ ] Απομόνωση επηρεαζόμενου συστήματος (network isolation, όχι shutdown)
- [ ] Ενημέρωση Security Lead
- [ ] Έναρξη incident log (timeline)
- [ ] Αναγνώριση scope (ποια άλλα συστήματα πιθανόν επηρεάζονται)
- [ ] Αξιολόγηση ανάγκης νομικής/κανονιστικής αναφοράς

---

## 🔗 9. Πλήρες Παράδειγμα — Major Incident End-to-End

```
09:15 — Πολλαπλές αναφορές: "Δεν έχω πρόσβαση σε κανένα shared drive"
09:20 — Tier 1 escalation σε Tier 2, εντοπισμός: File Server SRV-APP01 down
09:25 — Κριτήρια Major Incident πληρούνται (site-wide impact) → Declared
09:26 — MIM ενεργοποιεί bridge call, Technical Lead + Comms Lead join
09:30 — MAJOR INCIDENT UPDATE #1 σταλμένο σε όλη την εταιρεία
09:45 — Τεχνική ομάδα εντοπίζει: storage controller failure
10:00 — MAJOR INCIDENT UPDATE #2 — ETA αποκατάστασης: ~2 ώρες
10:00-11:30 — Failover σε backup storage / recovery procedure
11:30 — Υπηρεσία αποκαθίσταται, επιβεβαίωση από sample χρήστες
11:35 — MAJOR INCIDENT UPDATE #3 (final) — "Resolved"
11:40 — Formal closure, Scribe παραδίδει πλήρες timeline
      → Προγραμματισμός Post-Incident Review εντός 48 ωρών
      → Δημιουργία Problem Record για root cause του storage controller
      → CSI entry: "Χρειάζεται monitoring alert για storage controller health"
```

Αυτό το παράδειγμα δείχνει πώς **Major Incident Management, Post-Incident Review, Problem Management και CSI** συνδέονται σε έναν συνεχή κύκλο βελτίωσης — την ουσία ενός ώριμου ITSM περιβάλλοντος.

---

*Μέρος του [Infrastructure Knowledge Base](https://github.com/Dimitriskatsanos42/Infrastructure-Knowledge-Base) — ενότητα IT-Service-Management, συμπληρωματικό στα `itil-service-management-templates.md` και `itsm-additional-templates.md`.*
