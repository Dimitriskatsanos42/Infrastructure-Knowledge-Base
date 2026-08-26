# 📋 IT Service Management — Additional Templates (CMDB, DR, Communications, Onboarding)

Δεύτερο αρχείο της ενότητας **IT-Service-Management**, συμπληρωματικό στο `itil-service-management-templates.md`. Ενώ το πρώτο αρχείο καλύπτει Incident/Problem/Change/Runbook, αυτό εστιάζει σε **asset tracking, disaster recovery, επικοινωνία με χρήστες, onboarding/offboarding και risk management** — κομμάτια που ολοκληρώνουν την εικόνα ενός ώριμου IT operations περιβάλλοντος.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Configuration Management (CMDB) — Asset Register Template](#-1-configuration-management-cmdb--asset-register-template)
2. [Knowledge Base Article Template](#-2-knowledge-base-article-template)
3. [Communication Templates — Outage & Maintenance](#-3-communication-templates--outage--maintenance)
4. [Onboarding / Offboarding Checklists](#-4-onboarding--offboarding-checklists)
5. [Disaster Recovery Plan Template](#-5-disaster-recovery-plan-template)
6. [Risk Assessment Matrix](#-6-risk-assessment-matrix)
7. [Service Catalog — Παράδειγμα](#-7-service-catalog--παράδειγμα)
8. [Capacity Management — Βασικά](#-8-capacity-management--βασικά)
9. [Vendor / Contract Tracker](#-9-vendor--contract-tracker)
10. [Πλήρες Παράδειγμα — DR Test Report](#-10-πλήρες-παράδειγμα--dr-test-report)

---

## 🗄️ 1. Configuration Management (CMDB) — Asset Register Template

Το **CMDB (Configuration Management Database)** καταγράφει όλα τα IT assets (Configuration Items - CIs) και τις σχέσεις μεταξύ τους. Χωρίς αυτό, το Incident/Change Management λειτουργεί "στα τυφλά".

### 📝 Asset Register Template (μπορεί να γίνει CSV/Excel)
```markdown
| Asset ID | Type | Name | Location | Owner | IP Address | OS/Version | Warranty End | Related CIs |
|---|---|---|---|---|---|---|---|---|
| SRV-001 | Physical Server | DC01 | Rack 3, HQ Datacenter | IT Infra | 192.168.10.10 | Windows Server 2022 | 2027-03-15 | AD, DNS |
| SRV-002 | VM | SRV-APP01 | Hyper-V Host HV01 | IT Infra | 192.168.10.20 | Windows Server 2022 | N/A | SQL DB-001 |
| NET-010 | Switch | SW-CORE01 | Rack 1, HQ Datacenter | Network Team | 192.168.1.1 | Cisco IOS 15.2 | 2026-11-01 | VLAN 10,20,30 |
| SW-045 | License | Microsoft 365 E3 | Cloud | IT Procurement | N/A | N/A | 2027-01-10 | 150 seats |
```

### Σχέσεις μεταξύ CIs (Configuration Item Relationships)
```
SRV-APP01 (VM)
   ├── Hosted on: HV01 (Hyper-V Host)
   ├── Depends on: DB-001 (SQL Server)
   ├── Depends on: SAN-01 (Storage)
   └── Serves: Finance Application
```
> Αυτές οι σχέσεις είναι κρίσιμες για **Impact Analysis** πριν από ένα Change — "αν κάνω restart στο SAN-01, τι άλλο επηρεάζεται;"

### Lifecycle status ενός CI
| Status | Περιγραφή |
|---|---|
| Planned | Έχει εγκριθεί αγορά/deployment |
| In Testing | Στο staging περιβάλλον |
| Live/Production | Ενεργό σε production |
| Retired | Αποσύρθηκε, δεν χρησιμοποιείται πια |

---

## 📚 2. Knowledge Base Article Template

Χρησιμοποιείται όταν ένα Problem λύνεται ή όταν εντοπίζεται συχνό ερώτημα, ώστε η επόμενη φορά να λύνεται γρηγορότερα (μειώνει MTTR).

```markdown
## KB Article: [Τίτλος — πχ "Πώς να λύσετε 'Δεν παίρνω IP address' σε Windows client"]

**KB ID:** KB-2026-0055
**Category:** Networking / DHCP
**Related Problem:** PRB-2026-0031
**Last updated:** 2026-08-20
**Author:** [Όνομα]

### Σύμπτωμα
[Τι αναφέρει ο χρήστης — verbatim αν είναι δυνατόν, ώστε να matchάρει με μελλοντικά search queries]

### Πιθανές αιτίες
1. DHCP server down ή unreachable
2. Εξαντλημένο DHCP scope (no available leases)
3. Network cable/switch port πρόβλημα
4. Client-side network adapter issue

### Βήματα διάγνωσης & επίλυσης
1. `ipconfig /all` στον client → έλεγχος αν έχει APIPA (169.254.x.x)
2. Αν ναι: `ipconfig /release` → `ipconfig /renew`
3. Αν συνεχίζει: έλεγχος DHCP server status (`Get-Service DHCPServer`)
4. Έλεγχος διαθέσιμων leases στο scope (`Get-DhcpServerv4ScopeStatistics`)

### Μόνιμη λύση (αν εφαρμόστηκε)
[Σύνδεση με Change Request αν υπάρχει]

### Tags
`dhcp` `networking` `windows-client` `ip-address`
```

---

## 📢 3. Communication Templates — Outage & Maintenance

### Προγραμματισμένη συντήρηση (πριν)
```markdown
Subject: [Προγραμματισμένη Συντήρηση] File Server — Κυριακή 24/08, 02:00-04:00

Αγαπητοί συνάδελφοι,

Την Κυριακή 24/08/2026, 02:00-04:00, θα πραγματοποιηθεί προγραμματισμένη
συντήρηση στον file server (SRV-APP01) για εφαρμογή security updates.

Αναμενόμενη επίπτωση: Προσωρινή διακοπή πρόσβασης σε shared drives.
Δεν απαιτείται καμία ενέργεια από εσάς.

Για ερωτήματα: helpdesk@contoso.com

IT Department
```

### Μη προγραμματισμένη διακοπή (κατά τη διάρκεια)
```markdown
Subject: [Ενημέρωση] Πρόβλημα πρόσβασης σε Email — Σε εξέλιξη

Έχουμε εντοπίσει πρόβλημα πρόσβασης στο email σύστημα από τις 09:15.
Η ομάδα IT εργάζεται ήδη για την αποκατάσταση.

Κατάσταση: Σε διερεύνηση
Εκτιμώμενος χρόνος αποκατάστασης: Θα ενημερωθείτε εντός 30 λεπτών

Θα σας κρατάμε ενήμερους. Ευχαριστούμε για την κατανόηση.

IT Department
```

### Αποκατάσταση (μετά)
```markdown
Subject: [Επιλύθηκε] Πρόβλημα πρόσβασης σε Email

Το πρόβλημα πρόσβασης στο email σύστημα επιλύθηκε στις 10:45.
Αιτία: [σύντομη, μη τεχνική εξήγηση]

Αν συνεχίζετε να αντιμετωπίζετε πρόβλημα, επικοινωνήστε με το helpdesk.

IT Department
```

---

## 👤 4. Onboarding / Offboarding Checklists

### Onboarding Checklist (νέος υπάλληλος)
```markdown
## Onboarding Checklist — [Όνομα Υπαλλήλου]

**Ημερομηνία έναρξης:** [...]
**Τμήμα:** [...]
**Manager:** [...]

### Πριν την πρώτη μέρα
- [ ] Δημιουργία AD account (σωστό OU + security groups)
- [ ] Δημιουργία mailbox + distribution list membership
- [ ] Provisioning laptop/desktop (imaging, software)
- [ ] Πρόσβαση σε shared drives/SharePoint ανάλογα με ρόλο
- [ ] VPN access (αν remote/hybrid)
- [ ] Δημιουργία badge/φυσική πρόσβαση (αν χρειάζεται)

### Πρώτη μέρα
- [ ] Παράδοση εξοπλισμού
- [ ] Αρχικό password reset / MFA setup
- [ ] Σύντομο IT orientation (πώς ανοίγει ticket, βασικές πολιτικές)

### Παρακολούθηση (πρώτη εβδομάδα)
- [ ] Επιβεβαίωση ότι όλες οι προσβάσεις λειτουργούν σωστά
- [ ] Κλείσιμο Service Request
```

### Offboarding Checklist (αποχώρηση υπαλλήλου)
```markdown
## Offboarding Checklist — [Όνομα Υπαλλήλου]

**Τελευταία ημέρα εργασίας:** [...]
**Λόγος αποχώρησης:** [...]

### Πριν/κατά την τελευταία μέρα
- [ ] Απενεργοποίηση AD account (**όχι διαγραφή** — για audit trail)
- [ ] Απενεργοποίηση/forward mailbox (ανάλογα με πολιτική)
- [ ] Ανάκληση VPN/remote access
- [ ] Ανάκληση όλων των shared drive/app permissions
- [ ] Ανάκληση MFA devices/tokens
- [ ] Παραλαβή εξοπλισμού (laptop, badge, κινητό εταιρείας)
- [ ] Αλλαγή shared passwords αν ο χρήστης είχε πρόσβαση (πχ admin accounts)

### Μετά (30-90 μέρες, ανάλογα με πολιτική διατήρησης)
- [ ] Οριστική διαγραφή account/mailbox (μετά την περίοδο διατήρησης)
- [ ] Κλείσιμο σχετικού Service Request με πλήρες audit trail
```

---

## 🆘 5. Disaster Recovery Plan Template

```markdown
## Disaster Recovery Plan — [Σύστημα/Υπηρεσία]

**Owner:** [Όνομα/Ρόλος]
**Last tested:** 2026-06-15
**RTO (Recovery Time Objective):** 4 ώρες
**RPO (Recovery Point Objective):** 1 ώρα

### Σενάρια καταστροφής που καλύπτονται
- [ ] Αστοχία hardware (server/storage)
- [ ] Ολική απώλεια datacenter (φωτιά, πλημμύρα)
- [ ] Ransomware/κακόβουλη επίθεση
- [ ] Ανθρώπινο λάθος (κατά λάθος διαγραφή δεδομένων)

### Πρωτόκολλο ενεργοποίησης
1. Επιβεβαίωση σοβαρότητας incident από [Ρόλος — πχ IT Manager]
2. Ενημέρωση DR team μέσω [κανάλι επικοινωνίας]
3. Ενεργοποίηση DR site/failover procedure

### Βήματα ανάκτησης
1. **Failover σε DR site:**
   ```powershell
   # Παράδειγμα: Azure Site Recovery failover
   Start-AzRecoveryServicesAsrPlannedFailoverJob -ReplicationProtectedItem $rpi
   ```
2. **Επαλήθευση λειτουργίας** κρίσιμων υπηρεσιών (AD, DNS, DB, εφαρμογή)
3. **Ενημέρωση DNS/routing** ώστε traffic να δρομολογείται στο DR site
4. **Επικοινωνία με stakeholders** ότι το DR site είναι ενεργό

### Roles & Responsibilities
| Ρόλος | Υπεύθυνος | Επικοινωνία |
|---|---|---|
| DR Coordinator | [Όνομα] | [τηλέφωνο/email] |
| Infrastructure Lead | [Όνομα] | [τηλέφωνο/email] |
| Communications Lead | [Όνομα] | [τηλέφωνο/email] |

### Failback procedure (επιστροφή στο primary site)
[Βήματα μετά την αποκατάσταση του primary site]

### Testing schedule
Το DR plan πρέπει να δοκιμάζεται τουλάχιστον **2 φορές/έτος**.
```

---

## ⚠️ 6. Risk Assessment Matrix

### Risk scoring (Likelihood × Impact)
| | Impact: Low | Impact: Medium | Impact: High |
|---|---|---|---|
| **Likelihood: Low** | Risk Score 1 | Risk Score 2 | Risk Score 3 |
| **Likelihood: Medium** | Risk Score 2 | Risk Score 4 | Risk Score 6 |
| **Likelihood: High** | Risk Score 3 | Risk Score 6 | Risk Score 9 |

| Score | Κατηγορία | Ενέργεια |
|---|---|---|
| 1-2 | Χαμηλό | Παρακολούθηση |
| 3-4 | Μέτριο | Mitigation plan μέσα σε 30 μέρες |
| 6-9 | Υψηλό | Άμεση ενέργεια, escalation σε management |

### 📝 Risk Register Template
```markdown
| Risk ID | Περιγραφή | Likelihood | Impact | Score | Mitigation | Owner |
|---|---|---|---|---|---|---|
| RSK-001 | Παλιό firmware σε core switch, γνωστές ευπάθειες | Medium | High | 6 | Scheduled firmware update Q3 | Network Team |
| RSK-002 | Δεν υπάρχει tested backup για SQL DB-002 | High | High | 9 | Backup test scheduled 2026-09-01 | DBA |
| RSK-003 | Single point of failure — ένας μόνο DC στο branch office | Medium | Medium | 4 | Αξιολόγηση δεύτερου DC | IT Infra |
```

---

## 🛍️ 7. Service Catalog — Παράδειγμα

```markdown
## Service Catalog — IT Department

| Υπηρεσία | Περιγραφή | SLA | Πώς να ζητηθεί |
|---|---|---|---|
| New User Account | Δημιουργία AD/email account | 2 εργάσιμες μέρες | Service Request Portal |
| Password Reset | Επαναφορά κωδικού | 1 ώρα | Helpdesk ticket/τηλέφωνο |
| New Laptop Request | Provisioning νέου εξοπλισμού | 5 εργάσιμες μέρες | Service Request Portal (χρειάζεται manager approval) |
| VPN Access | Ενεργοποίηση remote access | 1 εργάσιμη μέρα | Service Request Portal |
| Software Installation | Εγκατάσταση εγκεκριμένου λογισμικού | 1 εργάσιμη μέρα | Service Request Portal |
| Shared Drive Access | Πρόσβαση σε folder/SharePoint | 4 ώρες | Service Request Portal (χρειάζεται data owner approval) |
```

---

## 📈 8. Capacity Management — Βασικά

Στόχος: **προληπτική** παρακολούθηση resources ώστε να μην φτάνουμε σε incident.

### Metrics που παρακολουθούνται
| Resource | Threshold για ενέργεια | Ενέργεια |
|---|---|---|
| Disk space (server) | >80% χρήση | Cleanup ή επέκταση storage |
| CPU utilization (sustained) | >75% για >30 λεπτά | Ανάλυση workload / upgrade |
| Memory utilization | >85% | Ανάλυση memory leak / upgrade RAM |
| DHCP scope utilization | >80% διαθέσιμων leases | Επέκταση scope |
| Mailbox storage (per user) | >90% quota | Ενημέρωση χρήστη / αύξηση quota |

### 📝 Capacity Report Template (μηνιαίο)
```markdown
## Capacity Report — Αύγουστος 2026

| System | Current Usage | Trend (3mo) | Projected full in | Action needed |
|---|---|---|---|---|
| SRV-FILE01 (Storage) | 78% | +3%/μήνα | ~7 μήνες | Παρακολούθηση |
| SRV-DB01 (Storage) | 88% | +5%/μήνα | ~2 μήνες | Άμεση επέκταση απαιτείται |
| DHCP Scope 10.0.1.0/24 | 65% | Σταθερό | N/A | Καμία ενέργεια |
```

---

## 🤝 9. Vendor / Contract Tracker

```markdown
| Vendor | Υπηρεσία/Προϊόν | Contract Start | Contract End | Renewal Notice | Contact | Annual Cost |
|---|---|---|---|---|---|---|
| Microsoft | Microsoft 365 E3 (150 seats) | 2025-01-10 | 2027-01-10 | 90 μέρες πριν | [email] | €18,000 |
| Dell | Hardware Warranty (Servers) | 2024-03-15 | 2027-03-15 | 60 μέρες πριν | [email] | €4,500 |
| ISP Provider | Fiber Internet 500Mbps | 2023-06-01 | Αόριστο | N/A | [τηλέφωνο] | €3,600 |
```
> Χρήσιμο να έχεις **calendar reminders** για renewal notices, ώστε να μην "ξεχαστεί" ένα κρίσιμο συμβόλαιο μέχρι να λήξει.

---

## 🔬 10. Πλήρες Παράδειγμα — DR Test Report

```markdown
## DR Test Report

**Test date:** 2026-06-15
**System tested:** File Server (SRV-APP01) → Azure Site Recovery failover
**Test type:** Planned (test failover, χωρίς επίπτωση σε production)

### Στόχοι test
- Επιβεβαίωση ότι το RTO των 4 ωρών είναι εφικτό
- Επιβεβαίωση ακεραιότητας δεδομένων μετά το failover

### Αποτελέσματα
| Βήμα | Αναμενόμενος χρόνος | Πραγματικός χρόνος | Status |
|---|---|---|---|
| Ενεργοποίηση failover | 15 λεπτά | 12 λεπτά | ✅ |
| VM boot στο DR site | 10 λεπτά | 18 λεπτά | ⚠️ Καθυστέρηση |
| Επαλήθευση data integrity | 30 λεπτά | 25 λεπτά | ✅ |
| DNS update/routing | 15 λεπτά | 15 λεπτά | ✅ |
| **Συνολικός χρόνος** | 4 ώρες (target) | 3h 10min | ✅ Εντός RTO |

### Ευρήματα
- Η καθυστέρηση στο VM boot οφειλόταν σε χαμηλότερο VM size στο DR site από ό,τι στο production.

### Action Items
| Ενέργεια | Owner | Deadline |
|---|---|---|
| Upgrade DR VM size ώστε να ταιριάζει με production | [Όνομα] | 2026-07-01 |
| Επόμενο test | [Όνομα] | 2026-12-15 |
```

---

*Μέρος του [Infrastructure Knowledge Base](https://github.com/Dimitriskatsanos42/Infrastructure-Knowledge-Base) — ενότητα IT-Service-Management, συμπληρωματικό στο `itil-service-management-templates.md`.*
