# 🏢 Active Directory & Microsoft Entra ID

> Σημειώσεις, deep-dives και real-world runbooks από τη μελέτη μου στη διαχείριση ταυτοτήτων και υποδομής σε Windows περιβάλλοντα — από τα βασικά μέχρι security hardening και disaster recovery.

---

## 📋 Περιεχόμενα

### 🔑 Βασικά AD

| Αρχείο | Θέμα |
|---|---|
| [`active-directory.md`](./active-directory.md) | Users, Groups, OUs, GPO βασικά, Entra ID, PowerShell 101 |
| [`active-directory-advanced.md`](./active-directory-advanced.md) | FSMO Roles, Replication, Trusts, DNS Integration, Security Tiering |
| [`group-policy-deep-dive.md`](./group-policy-deep-dive.md) | GPO processing order (LSDOU), Fine-Grained Password Policies, Security/WMI Filtering, Loopback Processing, real-world runbooks |

### 🔐 Identity Security & Attacks

| Αρχείο | Θέμα |
|---|---|
| [`kerberos-deep-dive.md`](./kerberos-deep-dive.md) | Πλήρες authentication flow, SPNs, Delegation, Time Sync, troubleshooting |
| [`ad-security-hardening.md`](./ad-security-hardening.md) | Kerberoasting, Pass-the-Hash, Golden/Silver Ticket, LAPS, Protected Users, Tiered Admin Model |
| [`ad-certificate-services-pki.md`](./ad-certificate-services-pki.md) | Two-Tier PKI setup, Certificate Templates, Autoenrollment, 802.1X WiFi, internal HTTPS |
| [`gmsa-service-accounts.md`](./gmsa-service-accounts.md) | Group Managed Service Accounts, migration από legacy static-password accounts |
| [`ad-auditing-siem.md`](./ad-auditing-siem.md) | Advanced Audit Policy, SACL auditing, log forwarding, SIEM integration, detection rules |

### 🗄️ Infrastructure Services

| Αρχείο | Θέμα |
|---|---|
| [`file-permissions-ntfs.md`](./file-permissions-ntfs.md) | NTFS vs Share permissions, effective access, inheritance, ownership |
| [`file-server-implementation-runbook.md`](./file-server-implementation-runbook.md) | Real-world file share deployment — AD groups, DFS, quotas, documentation |
| [`dns-dhcp-administration.md`](./dns-dhcp-administration.md) | DNS records/zones, DHCP scopes/reservations, failover, troubleshooting |
| [`print-server-management.md`](./print-server-management.md) | Print server setup, driver management, permissions, queue troubleshooting |

### 🛡️ Operations & Disaster Recovery

| Αρχείο | Θέμα |
|---|---|
| [`backup-disaster-recovery.md`](./backup-disaster-recovery.md) | RPO/RTO, AD object recovery, Authoritative Restore, ransomware response |

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

### Θεμελιώδη
- [ ] Εγκατάσταση AD DS σε Windows Server (VirtualBox)
- [ ] Δημιουργία OU structure για εταιρεία
- [ ] Bulk δημιουργία users από CSV με PowerShell
- [ ] GPO για password policy + desktop lockdown
- [ ] Σύνδεση με Microsoft Entra ID (free tenant)

### File Services & Permissions
- [ ] Δημιουργία file share με AGDLP group structure
- [ ] Test effective permissions (NTFS + Share combined)
- [ ] Ρύθμιση DFS Namespace με 2+ servers
- [ ] FSRM quotas + file screening

### Networking Services
- [ ] Στήσιμο DHCP scope με reservations + failover
- [ ] AD-integrated DNS zone με secure dynamic updates
- [ ] Print server με GPO-deployed printer

### Security & Identity
- [ ] Deploy LAPS σε test OU
- [ ] Δημιουργία Fine-Grained Password Policy
- [ ] Στήσιμο gMSA και χρήση σε scheduled task
- [ ] Two-Tier PKI lab (offline Root + online Subordinate CA)
- [ ] Kerberoasting demo σε isolated lab (εκπαιδευτικός σκοπός only)
- [ ] Advanced Audit Policy + SACL σε Domain Admins group

### Disaster Recovery
- [ ] AD Recycle Bin — restore διαγραμμένου OU
- [ ] Authoritative restore σε test DC
- [ ] Backup/restore GPO με `Backup-GPO`/`Restore-GPO`

---

## 🗺️ Πώς Συνδέονται τα Αρχεία

```
active-directory.md (βασικά)
    │
    ├── active-directory-advanced.md (FSMO, Replication, Tiering)
    │       │
    │       ├── kerberos-deep-dive.md ──── ad-security-hardening.md
    │       │         │                           │
    │       │    ad-certificate-services-pki.md    │
    │       │         │                           │
    │       │    gmsa-service-accounts.md ─────────┘
    │       │                                      │
    │       └── ad-auditing-siem.md ────────────────┘
    │
    ├── group-policy-deep-dive.md (deployment μηχανισμός για πολλά από τα παραπάνω)
    │
    ├── file-permissions-ntfs.md
    │       └── file-server-implementation-runbook.md
    │
    ├── dns-dhcp-administration.md
    ├── print-server-management.md
    │
    └── backup-disaster-recovery.md (τι κάνεις όταν κάτι πάει στραβά σε οτιδήποτε παραπάνω)
```

---

## 📌 Σημειώσεις

Όλα τα αρχεία περιλαμβάνουν θεωρία **και** πρακτικά PowerShell/CLI παραδείγματα βασισμένα σε ρεαλιστικά σενάρια (tickets, incidents) — όπως θα τα συναντούσε κανείς σε πραγματική IT/sysadmin θέση.
