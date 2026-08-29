# 📋 IT Service Management — RACI, Release Management & Asset Lifecycle

Τέταρτο αρχείο της ενότητας **IT-Service-Management**, συμπληρωματικό στα `itil-service-management-templates.md`, `itsm-additional-templates.md` και `itsm-major-incidents-cab-csi.md`. Εστιάζει σε **ρόλους/ευθύνες, διαχείριση releases, κύκλο ζωής assets και ετοιμότητα για audit** — κομμάτια governance που ολοκληρώνουν το ITSM portfolio.

---

## 🗺️ Πίνακας Περιεχομένων

1. [RACI Matrix για ITSM Processes](#-1-raci-matrix-για-itsm-processes)
2. [Service Level Management — SLA vs OLA vs UC](#-2-service-level-management--sla-vs-ola-vs-uc)
3. [Release & Deployment Management](#-3-release--deployment-management)
4. [IT Asset Lifecycle Management](#-4-it-asset-lifecycle-management)
5. [Self-Service Portal & Automation Ιδέες](#-5-self-service-portal--automation-ιδέες)
6. [Audit Readiness Checklist](#-6-audit-readiness-checklist)
7. [Chargeback / Cost Allocation — Βασικά](#-7-chargeback--cost-allocation--βασικά)
8. [Πλήρες Παράδειγμα — Release Deployment End-to-End](#-8-πλήρες-παράδειγμα--release-deployment-end-to-end)

---

## 🧭 1. RACI Matrix για ITSM Processes

Το **RACI** (Responsible, Accountable, Consulted, Informed) ξεκαθαρίζει ποιος κάνει τι σε κάθε διαδικασία — αποφεύγει το "νόμιζα ότι το έκανες εσύ".

| Ρόλος | Σημασία |
|---|---|
| **R — Responsible** | Εκτελεί την εργασία |
| **A — Accountable** | Τελικά υπεύθυνος/λογοδοτεί για το αποτέλεσμα (ένας μόνο ανά task) |
| **C — Consulted** | Ερωτάται πριν την ενέργεια (2-way επικοινωνία) |
| **I — Informed** | Ενημερώνεται μετά την ενέργεια (1-way επικοινωνία) |

### RACI Matrix — Βασικές ITSM Διαδικασίες

| Δραστηριότητα | Service Desk | Sysadmin | IT Manager | Application Owner | CAB |
|---|:---:|:---:|:---:|:---:|:---:|
| Καταγραφή Incident | R | I | I | I | — |
| Διάγνωση/Επίλυση Incident | C | R | I | C | — |
| Έγκριση Emergency Change | I | R | A | C | I |
| Έγκριση Normal Change | I | R | C | C | A |
| Root Cause Analysis (Problem) | I | R | A | C | — |
| Onboarding νέου χρήστη | R | R | A | I | — |
| Disaster Recovery ενεργοποίηση | I | R | A | C | I |
| Ανασκόπηση Monthly Service Report | I | C | A | I | — |

> Κανόνας: κάθε γραμμή πρέπει να έχει **ακριβώς ένα A** — αν έχει παραπάνω από ένα, δεν είναι ξεκάθαρο ποιος λογοδοτεί τελικά.

---

## 📐 2. Service Level Management — SLA vs OLA vs UC

Τρεις διαφορετικοί τύποι συμφωνιών που συχνά μπερδεύονται:

| Τύπος | Μεταξύ ποιων | Παράδειγμα |
|---|---|---|
| **SLA** (Service Level Agreement) | IT ↔ Business/Πελάτης | "Το IT εγγυάται 99.9% uptime για το ERP σύστημα" |
| **OLA** (Operational Level Agreement) | Εσωτερικά τμήματα IT | "Η ομάδα Network εγγυάται response σε 15 λεπτά προς την ομάδα Servers για network-related incidents" |
| **UC** (Underpinning Contract) | IT ↔ Εξωτερικός Προμηθευτής | "Ο ISP εγγυάται 99.5% uptime σύνδεσης, με penalty clause αν δεν τηρηθεί" |

### Γιατί έχει σημασία η διάκριση
Αν το SLA προς τον πελάτη υπόσχεται **4ωρη αποκατάσταση** αλλά το UC με τον ISP προβλέπει μόνο **8ωρο response**, το IT δεν μπορεί ρεαλιστικά να τηρήσει το SLA του — τα OLA/UC πρέπει να είναι **πιο αυστηρά** από το τελικό SLA.

### 📝 SLA Document Template (σκελετός)
```markdown
## Service Level Agreement — [Υπηρεσία]

**Πάροχος:** IT Department
**Πελάτης:** [Τμήμα/Business Unit]
**Περίοδος ισχύος:** [Ημερομηνίες]

### Πεδίο εφαρμογής
[Ποια υπηρεσία καλύπτεται]

### Δεσμεύσεις
| Metric | Δέσμευση |
|---|---|
| Uptime | 99.9% |
| P1 Response | 15 λεπτά |
| P1 Resolution | 4 ώρες |

### Εξαιρέσεις
[πχ scheduled maintenance windows δεν προσμετρώνται στο downtime]

### Penalty/Escalation αν δεν τηρηθεί
[...]

### Review cycle
Ανασκόπηση κάθε 6 μήνες
```

---

## 🚀 3. Release & Deployment Management

Διαφορά από το Change Management: το **Change Management** εγκρίνει *ότι* μπορεί να γίνει μια αλλαγή· το **Release Management** οργανώνει *πώς* πολλαπλές αλλαγές συσκευάζονται και παραδίδονται μαζί.

### Τύποι Release

| Τύπος | Περιγραφή |
|---|---|
| **Major Release** | Σημαντική νέα λειτουργικότητα, μεγάλο scope |
| **Minor Release** | Μικρές βελτιώσεις/fixes, μαζεμένες |
| **Emergency Release** | Επείγον fix (security patch, critical bug) |

### Release Pipeline (τυπική ροή)
```
Dev → Testing/QA → Staging (UAT) → Production
```

### 📝 Release Plan Template
```markdown
## Release Plan — [Όνομα Release, π.χ. "v2.4 — Finance Module Update"]

**Release Manager:** [Όνομα]
**Ημερομηνία deployment:** 2026-09-05, 02:00-05:00
**Σχετικά Changes:** CHG-0095, CHG-0096, CHG-0098

### Περιεχόμενο release
- [ ] Feature A: [περιγραφή]
- [ ] Bug fix B: [περιγραφή]
- [ ] Security patch C: [περιγραφή]

### Pre-deployment checklist
- [ ] Όλα τα tests πέρασαν σε staging
- [ ] Backup ολοκληρώθηκε
- [ ] Rollback plan έτοιμο και testαρισμένο
- [ ] Stakeholders ενημερωμένοι

### Deployment steps
1. [...]
2. [...]

### Post-deployment validation
- [ ] Smoke test βασικών λειτουργιών
- [ ] Monitoring για 24 ώρες μετά

### Rollback trigger criteria
[πχ "Αν >5% των requests αποτυγχάνουν μέσα στην πρώτη ώρα, rollback"]
```

### Deployment strategies — σύγκριση

| Στρατηγική | Περιγραφή | Risk |
|---|---|:---:|
| **Big Bang** | Όλα ταυτόχρονα, σε όλους | Υψηλό |
| **Phased Rollout** | Σταδιακά, ανά ομάδα/site | Μεσαίο |
| **Canary/Pilot** | Πρώτα σε μικρή ομάδα χρηστών | Χαμηλό |
| **Blue-Green** | Δύο πανομοιότυπα περιβάλλοντα, switch traffic | Χαμηλό |

---

## 🔄 4. IT Asset Lifecycle Management

Κάθε asset (hardware/software) περνά από συγκεκριμένα στάδια — η καλή διαχείριση lifecycle μειώνει κόστος και ρίσκο.

### Στάδια lifecycle

| Στάδιο | Δραστηριότητες |
|---|---|
| **1. Planning** | Ανάλυση ανάγκης, budget approval |
| **2. Procurement** | Αγορά, παραλαβή, καταχώρηση σε CMDB |
| **3. Deployment** | Provisioning, configuration, παράδοση σε χρήστη |
| **4. Maintenance** | Patching, support, warranty tracking |
| **5. Retirement** | Απόσυρση, data wiping, ασφαλής διάθεση (disposal) |

### 📝 Asset Retirement Checklist
```markdown
## Asset Retirement — [Asset ID]

- [ ] Επιβεβαίωση ότι δεν χρησιμοποιείται πλέον (έλεγχος dependencies στο CMDB)
- [ ] Backup τυχόν απαραίτητων δεδομένων
- [ ] Secure data wipe (σύμφωνα με πολιτική — πχ DoD 5220.22-M ή NIST 800-88)
- [ ] Αφαίρεση από domain/monitoring/inventory συστήματα
- [ ] Ενημέρωση CMDB status → "Retired"
- [ ] Φυσική διάθεση (recycling/e-waste partner) με certificate of destruction αν απαιτείται
- [ ] Ενημέρωση asset register/λογιστηρίου (depreciation, write-off)
```

### Λόγοι που η κακή διαχείριση lifecycle κοστίζει
- **Ghost assets**: εξοπλισμός στο inventory που δεν υπάρχει πια στην πραγματικότητα.
- **Unlicensed software**: risk σε audit από vendor.
- **Security risk**: data breach από μη σωστά wiped δίσκους σε αποσυρμένο εξοπλισμό.

---

## 🤖 5. Self-Service Portal & Automation Ιδέες

Στόχος: μείωση Tier 1 φόρτου μέσω αυτοματοποίησης επαναλαμβανόμενων αιτημάτων.

### Καλά candidates για self-service
| Αίτημα | Γιατί ταιριάζει για αυτοματοποίηση |
|---|---|
| Password reset | Υψηλός όγκος, τυποποιημένο, χαμηλό risk |
| Πρόσβαση σε κοινό shared drive | Τυποποιημένο, με προκαθορισμένο approval flow |
| Software installation (από εγκεκριμένη λίστα) | Μπορεί να γίνει μέσω software catalog/portal |
| Νέο distribution list | Απλό, τυποποιημένο |
| Status ερώτημα υπάρχοντος ticket | Δεν χρειάζεται καθόλου ανθρώπινη παρέμβαση |

### Παράδειγμα απλού automation script (PowerShell — password reset με έλεγχο ταυτότητας)
```powershell
param(
    [string]$Username,
    [string]$ManagerApprovalTicket
)

if (-not $ManagerApprovalTicket) {
    Write-Error "Απαιτείται ticket έγκρισης."
    exit 1
}

$newPassword = ConvertTo-SecureString -String (New-Guid).Guid.Substring(0,12) -AsPlainText -Force
Set-ADAccountPassword -Identity $Username -NewPassword $newPassword -Reset
Set-ADUser -Identity $Username -ChangePasswordAtLogon $true

Write-Output "Password reset ολοκληρώθηκε για $Username. Ref: $ManagerApprovalTicket"
```

### Metrics για να μετρήσεις επιτυχία self-service
- % αιτημάτων που διεκπεραιώνονται χωρίς ανθρώπινη παρέμβαση
- Μείωση Tier 1 ticket volume μετά την εισαγωγή αυτοματοποίησης
- Χρόνος διεκπεραίωσης (πριν/μετά automation)

---

## 🔍 6. Audit Readiness Checklist

Χρήσιμο πριν από εσωτερικό ή εξωτερικό audit (ISO 27001, SOC 2, ή απλή εταιρική επιθεώρηση).

```markdown
## Audit Readiness Checklist

### Documentation
- [ ] Όλες οι πολιτικές (security, acceptable use, data retention) είναι ενημερωμένες
- [ ] CMDB/Asset Register είναι ενημερωμένο και ακριβές
- [ ] Change/Incident/Problem records είναι πλήρη και προσβάσιμα

### Access Control
- [ ] Λίστα users με admin δικαιώματα είναι ενημερωμένη και δικαιολογημένη
- [ ] Offboarded χρήστες έχουν πράγματι απενεργοποιηθεί (spot check)
- [ ] MFA ενεργοποιημένο σε κρίσιμα συστήματα

### Backup & DR
- [ ] Backup logs δείχνουν επιτυχή, τακτικά tests
- [ ] Τελευταίο DR test documentation διαθέσιμο

### Change Management
- [ ] Δείγμα Changes έχει πλήρη approval trail
- [ ] Κανένα undocumented change σε κρίσιμα συστήματα

### Licensing/Compliance
- [ ] Software licenses ταιριάζουν με πραγματικές εγκαταστάσεις (no over-deployment)
- [ ] Contracts/renewal dates ενημερωμένα στο Vendor Tracker
```

---

## 💰 7. Chargeback / Cost Allocation — Βασικά

Πρακτική όπου το κόστος IT υπηρεσιών κατανέμεται πίσω στα τμήματα που τις χρησιμοποιούν — βοηθά τα τμήματα να κατανοήσουν το πραγματικό κόστος IT και ενθαρρύνει υπεύθυνη χρήση πόρων.

### Απλό μοντέλο κατανομής

| Υπηρεσία | Μονάδα μέτρησης | Κόστος/μονάδα |
|---|---|---:|
| Email/M365 seat | Ανά χρήστη/μήνα | €12 |
| VM hosting (Azure) | Ανά VM/μήνα (ανάλογα size) | €50–€200 |
| Helpdesk support | Ανά ticket | €8 (μέσο κόστος) |
| File storage | Ανά GB/μήνα | €0.05 |

> Ακόμα κι αν η εταιρεία δεν κάνει επίσημο chargeback, το να **ξέρεις** το κόστος ανά υπηρεσία βοηθά στη λήψη αποφάσεων (πχ "αξίζει να αναβαθμίσουμε αυτό το σύστημα;").

---

## 🔗 8. Πλήρες Παράδειγμα — Release Deployment End-to-End

```
1. Business ζητά νέα λειτουργικότητα στο Finance σύστημα
   → Change Requests CHG-0095, CHG-0096, CHG-0098 δημιουργούνται

2. Release Manager ομαδοποιεί τα 3 changes σε ένα Release (v2.4)
   → Release Plan συντάσσεται με πλήρες pre/post-deployment checklist

3. CAB εγκρίνει το release ως σύνολο (RACI: A = IT Manager, R = Release Manager)

4. Testing σε staging environment (UAT από Application Owner)
   → Όλα τα tests περνούν

5. Deployment window: Παρασκευή 02:00-05:00 (χαμηλή χρήση)
   → Phased rollout: πρώτα pilot ομάδα (10 χρήστες), μετά όλοι

6. Post-deployment validation: smoke tests OK, monitoring 24ωρο ενεργό

7. Καμία επίπτωση εντοπίζεται → Release θεωρείται επιτυχές
   → Ενημέρωση CMDB (νέα version του Finance module)
   → Ενημέρωση Service Catalog αν άλλαξε κάτι στο SLA
   → CSI entry αν εντοπίστηκε κάποια ευκαιρία βελτίωσης της διαδικασίας
```

Αυτό δείχνει πώς **Change → Release → CAB → Testing → Deployment → CMDB update** συνδέονται σε μια πλήρη, ελεγχόμενη ροή — ακριβώς η δομή που αναζητούν οι employers σε πιο ώριμα IT περιβάλλοντα.

---

*Μέρος του [Infrastructure Knowledge Base](https://github.com/Dimitriskatsanos42/Infrastructure-Knowledge-Base) — ενότητα IT-Service-Management, συμπληρωματικό στα `itil-service-management-templates.md`, `itsm-additional-templates.md` και `itsm-major-incidents-cab-csi.md`.*
