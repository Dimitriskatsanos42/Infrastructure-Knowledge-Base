# 🏢 Active Directory & Microsoft Entra ID

> Σημειώσεις, deep-dives και real-world runbooks από τη μελέτη μου στη διαχείριση ταυτοτήτων και υποδομής σε Windows περιβάλλοντα — από τα βασικά μέχρι security hardening και disaster recovery.

---

## 📋 Περιεχόμενα

### 🔑 [`Βασικά AD/`](./Βασικά%20AD) — Βασικά AD

| Αρχείο | Θέμα |
|---|---|
| [`active-directory.md`](./Βασικά%20AD/active-directory.md) | Users, Groups, OUs, GPO βασικά, Entra ID, PowerShell 101 |
| [`active-directory-advanced.md`](./Βασικά%20AD/active-directory-advanced.md) | FSMO Roles, Replication, Trusts, DNS Integration, Security Tiering |
| [`group-policy-deep-dive.md`](./Βασικά%20AD/group-policy-deep-dive.md) | GPO processing order (LSDOU), Fine-Grained Password Policies, Security/WMI Filtering, Loopback Processing, real-world runbooks |

### 🔐 [`Identity Security & Attacks/`](./Identity%20Security%20%26%20Attacks) — Identity Security & Attacks

| Αρχείο | Θέμα |
|---|---|
| [`kerberos-deep-dive.md`](./Identity%20Security%20%26%20Attacks/kerberos-deep-dive.md) | Πλήρες authentication flow, SPNs, Delegation, Time Sync, troubleshooting |
| [`ad-security-hardening.md`](./Identity%20Security%20%26%20Attacks/ad-security-hardening.md) | Kerberoasting, Pass-the-Hash, Golden/Silver Ticket, LAPS, Protected Users, Tiered Admin Model |
| [`ad-certificate-services-pki.md`](./Identity%20Security%20%26%20Attacks/ad-certificate-services-pki.md) | Two-Tier PKI setup, Certificate Templates, Autoenrollment, 802.1X WiFi, internal HTTPS |
| [`gmsa-service-accounts.md`](./Identity%20Security%20%26%20Attacks/gmsa-service-accounts.md) | Group Managed Service Accounts, migration από legacy static-password accounts |
| [`ad-auditing-siem.md`](./Identity%20Security%20%26%20Attacks/ad-auditing-siem.md) | Advanced Audit Policy, SACL auditing, log forwarding, SIEM integration, detection rules |

### 🗄️ [`Infrastructure Services/`](./Infrastructure%20Services) — Infrastructure Services

| Αρχείο | Θέμα |
|---|---|
| [`file-permissions-ntfs.md`](./Infrastructure%20Services/file-permissions-ntfs.md) | NTFS vs Share permissions, effective access, inheritance, ownership |
| [`file-server-implementation-runbook.md`](./Infrastructure%20Services/file-server-implementation-runbook.md) | Real-world file share deployment — AD groups, DFS, quotas, documentation |
| [`dns-dhcp-administration.md`](./Infrastructure%20Services/dns-dhcp-administration.md) | DNS records/zones, DHCP scopes/reservations, failover, troubleshooting |
| [`print-server-management.md`](./Infrastructure%20Services/print-server-management.md) | Print server setup, driver management, permissions, queue troubleshooting |

### 🛡️ [`Operations & Disaster Recovery/`](./Operations%20%26%20Disaster%20Recovery) — Operations & Disaster Recovery

| Αρχείο | Θέμα |
|---|---|
| [`backup-disaster-recovery.md`](./Operations%20%26%20Disaster%20Recovery/backup-disaster-recovery.md) | RPO/RTO, AD object recovery, Authoritative Restore, ransomware response |

---

## 📂 Δομή Repository

```
.
├── README.md
│
├── Βασικά AD/
│   ├── active-directory.md
│   ├── active-directory-advanced.md
│   └── group-policy-deep-dive.md
│
├── Identity Security & Attacks/
│   ├── kerberos-deep-dive.md
│   ├── ad-security-hardening.md
│   ├── ad-certificate-services-pki.md
│   ├── gmsa-service-accounts.md
│   └── ad-auditing-siem.md
│
├── Infrastructure Services/
│   ├── file-permissions-ntfs.md
│   ├── file-server-implementation-runbook.md
│   ├── dns-dhcp-administration.md
│   └── print-server-management.md
│
└── Operations & Disaster Recovery/
    └── backup-disaster-recovery.md
```

> ⚠️ **Σημείωση:** τα ονόματα φακέλων περιέχουν κενά και το σύμβολο `&`. Στα Markdown links αυτό γίνεται handle με URL-encoding (`%20` για κενό, `%26` για `&`) — τα links παραπάνω είναι ήδη σωστά encoded ώστε να δουλεύουν κανονικά στο GitHub.

---

## 🔑 Βασικές Έννοιες

- **Domain & Forest** — δομή AD, FSMO roles, replication
- **Users, Groups, OUs** — οργάνωση αντικειμένων, AGDLP μοντέλο
- **Group Policy (GPO)** — εφαρμογή ρυθμίσεων σε mass scale
- **Kerberos** — το authentication protocol πίσω από όλο το AD
- **NTFS/Share Permissions** — file system security model
- **PKI / AD CS** — internal certificate authority, 802.1X, HTTPS
- **Microsoft Entra ID** — cloud identity (Azure AD)
- **Hybrid Identity** — συνδυασμός on-prem + cloud
- **Security Hardening** — Kerberoasting, Golden Ticket, LAPS, tiered admin model
- **Backup & DR** — RPO/RTO, AD recovery, ransomware response
- **PowerShell για AD** — αυτοματοποίηση διαχείρισης

---

## 🔬 Labs

### Θεμελιώδη — `Βασικά AD/`
- [ ] Εγκατάσταση AD DS σε Windows Server (VirtualBox)
- [ ] Δημιουργία OU structure για εταιρεία
- [ ] Bulk δημιουργία users από CSV με PowerShell
- [ ] GPO για password policy + desktop lockdown
- [ ] Σύνδεση με Microsoft Entra ID (free tenant)

### Identity Security & Attacks — `Identity Security & Attacks/`
- [ ] Deploy LAPS σε test OU
- [ ] Δημιουργία Fine-Grained Password Policy
- [ ] Στήσιμο gMSA και χρήση σε scheduled task
- [ ] Two-Tier PKI lab (offline Root + online Subordinate CA)
- [ ] Kerberoasting demo σε isolated lab (εκπαιδευτικός σκοπός only)
- [ ] Advanced Audit Policy + SACL σε Domain Admins group

### Infrastructure Services — `Infrastructure Services/`
- [ ] Δημιουργία file share με AGDLP group structure
- [ ] Test effective permissions (NTFS + Share combined)
- [ ] Ρύθμιση DFS Namespace με 2+ servers
- [ ] FSRM quotas + file screening
- [ ] Στήσιμο DHCP scope με reservations + failover
- [ ] AD-integrated DNS zone με secure dynamic updates
- [ ] Print server με GPO-deployed printer

### Operations & Disaster Recovery — `Operations & Disaster Recovery/`
- [ ] AD Recycle Bin — restore διαγραμμένου OU
- [ ] Authoritative restore σε test DC
- [ ] Backup/restore GPO με `Backup-GPO`/`Restore-GPO`

---

## 🗺️ Πώς Συνδέονται τα Αρχεία

```
Βασικά AD/active-directory.md (βασικά)
    │
    └── Βασικά AD/active-directory-advanced.md (FSMO, Replication, Tiering)
            │
            ├── Identity Security & Attacks/kerberos-deep-dive.md ──── Identity Security & Attacks/ad-security-hardening.md
            │                 │                                                  │
            │        Identity Security & Attacks/ad-certificate-services-pki.md  │
            │                 │                                                  │
            │        Identity Security & Attacks/gmsa-service-accounts.md ───────┘
            │                                                          │
            └── Identity Security & Attacks/ad-auditing-siem.md ───────┘

Βασικά AD/group-policy-deep-dive.md
    (deployment μηχανισμός για πολλά από τα παραπάνω)

Infrastructure Services/file-permissions-ntfs.md
    └── Infrastructure Services/file-server-implementation-runbook.md

Infrastructure Services/dns-dhcp-administration.md
Infrastructure Services/print-server-management.md

Operations & Disaster Recovery/backup-disaster-recovery.md
    (τι κάνεις όταν κάτι πάει στραβά σε οτιδήποτε παραπάνω)
```

---

## 📌 Σημειώσεις

Όλα τα αρχεία περιλαμβάνουν θεωρία **και** πρακτικά PowerShell/CLI παραδείγματα βασισμένα σε ρεαλιστικά σενάρια (tickets, incidents) — όπως θα τα συναντούσε κανείς σε πραγματική IT/sysadmin θέση.
