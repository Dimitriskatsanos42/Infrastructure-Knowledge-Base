# 🏢 Active Directory — Deep Dive & Advanced Topics
> Συνέχεια του [`active-directory.md`](./active-directory.md) — FSMO Roles, Replication, Trusts, DNS Integration, Sites, Security Hardening, Backup/Restore.
> Στοχεύει σε πιο advanced/administrator-level γνώση, πέρα από τα βασικά της διαχείρισης users/groups/GPO.

---

## 🗺️ Πίνακας Περιεχομένων

1. [FSMO Roles](#-1-fsmo-roles)
2. [AD Replication](#-2-ad-replication)
3. [Sites & Subnets](#-3-sites--subnets)
4. [Trusts](#-4-trusts)
5. [DNS Integration](#-5-dns-integration)
6. [Fine-Grained Password Policies](#-6-fine-grained-password-policies)
7. [Domain & Forest Functional Levels](#-7-domain--forest-functional-levels)
8. [Security Hardening & Tiering](#-8-security-hardening--tiering)
9. [Κοινές Επιθέσεις σε AD (Awareness)](#-9-κοινές-επιθέσεις-σε-ad-awareness)
10. [Backup & Restore](#-10-backup--restore)
11. [Promotion/Demotion Domain Controller](#-11-promotiondemotion-domain-controller)
12. [Advanced PowerShell & LDAP Queries](#-12-advanced-powershell--ldap-queries)
13. [Advanced Troubleshooting](#-13-advanced-troubleshooting)

---

## 👑 1. FSMO Roles

### 📖 Θεωρία: Γιατί χρειάζονται

Το AD είναι κατά βάση **multi-master** — κάθε Domain Controller μπορεί να δεχτεί αλλαγές. Όμως υπάρχουν **5 λειτουργίες** που δεν μπορούν να γίνουν multi-master χωρίς κίνδυνο σύγκρουσης, οπότε ανατίθενται αποκλειστικά σε **έναν** DC κάθε φορά — τα **FSMO (Flexible Single Master Operations) Roles**.

| Role | Επίπεδο | Τι κάνει | Τι πάει στραβά αν λείψει |
|---|---|---|---|
| **Schema Master** | Forest (1 ανά forest) | Ελέγχει αλλαγές στο AD schema | Δεν μπορείς να επεκτείνεις schema (π.χ. Exchange install) |
| **Domain Naming Master** | Forest (1 ανά forest) | Προσθήκη/αφαίρεση domains στο forest | Δεν μπορείς να προσθέσεις νέο domain |
| **RID Master** | Domain (1 ανά domain) | Μοιράζει pools από RIDs στους DCs για νέα SIDs | Οι DCs εξαντλούν RIDs → αδυναμία δημιουργίας νέων objects |
| **PDC Emulator** | Domain (1 ανά domain) | Time sync, password changes, account lockout, GPO editing "authority" | Ασυγχρονισμός ρολογιού → Kerberos failures· password changes καθυστερούν να διαδοθούν |
| **Infrastructure Master** | Domain (1 ανά domain) | Ενημερώνει cross-domain object references (group memberships) | "Phantom" references σε multi-domain forests |

> 💡 Ο **PDC Emulator** είναι στην πράξη ο πιο κρίσιμος για καθημερινή λειτουργία — είναι η πηγή αλήθειας για time sync (κρίσιμο για Kerberos, που ανέχεται μόνο 5 λεπτά clock skew) και ο πρώτος που ενημερώνεται σε password changes.

### Εντολές

```powershell
# Ποιος DC κατέχει ποιο role
netdom query fsmo

# Ή σε PowerShell
Get-ADForest | Select SchemaMaster, DomainNamingMaster
Get-ADDomain | Select PDCEmulator, RIDMaster, InfrastructureMaster

# Μεταφορά role σε άλλον DC (graceful — ο τρέχων κάτοχος είναι online)
Move-ADDirectoryServerOperationMasterRole -Identity "DC02" -OperationMasterRole SchemaMaster,PDCEmulator

# Seizure — ΜΟΝΟ αν ο κάτοχος DC έχει χαθεί μόνιμα (disaster recovery)
Move-ADDirectoryServerOperationMasterRole -Identity "DC02" -OperationMasterRole PDCEmulator -Force
```

> ⚠️ Το **Seizure** (`-Force`) είναι μονόδρομος — ο παλιός κάτοχος **δεν πρέπει ποτέ** να ξαναμπεί online μετά, γιατί θα δημιουργήσει διπλότυπο role holder και corruption.

---

## 🔄 2. AD Replication

### 📖 Θεωρία: Multi-Master Replication

Κάθε DC κρατά πλήρες αντίγραφο της domain partition. Οι αλλαγές διαδίδονται μεταξύ DCs μέσω **Knowledge Consistency Checker (KCC)**, που δημιουργεί αυτόματα μια τοπολογία replication (**ring topology** εντός site).

**Replication μεταξύ sites** χρησιμοποιεί **RPC** (real-time, intra-site) ή **SMTP/IP** (scheduled, inter-site, πιο "φθηνό" σε bandwidth).

**USN (Update Sequence Number):** Κάθε DC κρατά έναν αριθμό που αυξάνεται σε κάθε αλλαγή· οι άλλοι DCs τον χρησιμοποιούν για να ξέρουν "τι έχω δει ήδη" — αποφεύγει διπλή αποστολή.

### Εντολές διάγνωσης

```
:: Γενική εικόνα replication health
repadmin /replsummary

:: Λεπτομέρειες replication ανά DC
repadmin /showrepl DC01

:: Force replication τώρα (μη περιμένεις το scheduled interval)
repadmin /syncall /AdeP

:: Έλεγχος για replication errors
repadmin /showrepl * /csv > replication_report.csv

:: Πλήρης health check (πολλά tests μαζί)
dcdiag /v
dcdiag /test:replications
```

**Ανάγνωση `repadmin /replsummary`:**

| Στήλη | Σημαίνει |
|---|---|
| `largest delta` | Πόσο παλιά είναι η πιο "καθυστερημένη" replication |
| `fails/total` | Αποτυχίες replication attempts |
| USN gaps | Πιθανό πρόβλημα connectivity ή permissions μεταξύ DCs |

> ⚠️ Αν ένας DC μείνει **εκτός replication πάνω από 60 μέρες** (default tombstone lifetime), θεωρείται "lingering" και μπορεί να χρειαστεί πλήρης reinstall — δεν μπορεί απλά να ξανασυγχρονιστεί με ασφάλεια.

---

## 🗺️ 3. Sites & Subnets

### 📖 Θεωρία

Ένα **Site** στο AD αντιπροσωπεύει μια φυσική τοποθεσία (π.χ. γραφείο Αθήνα vs γραφείο Θεσσαλονίκη) με καλή εσωτερική συνδεσιμότητα. Τα **Subnets** συνδέονται με Sites ώστε οι clients να βρίσκουν τον **πλησιέστερο DC** αντί να πάνε σε DC άλλης πόλης μέσω αργού WAN link.

```
Forest
 ├── Site: Athens
 │     ├── Subnet: 10.10.0.0/16
 │     └── DC: DC-ATH01
 └── Site: Thessaloniki
       ├── Subnet: 10.20.0.0/16
       └── DC: DC-THES01
```

**Γιατί έχει σημασία:**
- **Login speed** — client στη Θεσσαλονίκη κάνει authenticate στον τοπικό DC, όχι στην Αθήνα
- **Replication scheduling** — inter-site replication γίνεται σε προγραμματισμένα intervals (π.χ. κάθε 15 λεπτά) για εξοικονόμηση WAN bandwidth
- **DFS Namespace referrals** — παίρνεις τον πλησιέστερο file server

```powershell
Get-ADReplicationSite -Filter *
Get-ADReplicationSubnet -Filter *
New-ADReplicationSite -Name "Thessaloniki"
New-ADReplicationSubnet -Name "10.20.0.0/16" -Site "Thessaloniki"
```

---

## 🤝 4. Trusts

### 📖 Θεωρία: Γιατί χρειάζονται

Ένα **Trust** επιτρέπει σε χρήστες ενός domain να έχουν πρόσβαση σε πόρους άλλου domain — χρήσιμο σε συγχωνεύσεις εταιρειών, partner access, ή multi-forest αρχιτεκτονικές.

| Τύπος Trust | Περιγραφή |
|---|---|
| **Parent-Child** | Αυτόματο, μεταξύ domains στο ίδιο forest tree |
| **Tree-Root** | Αυτόματο, μεταξύ διαφορετικών trees στο ίδιο forest |
| **External** | Χειροκίνητο, με domain εκτός forest |
| **Forest Trust** | Χειροκίνητο, μεταξύ δύο ολόκληρων forests |
| **Shortcut** | Χειροκίνητο, "συντόμευση" μέσα σε πολύπλοκο forest για ταχύτερο authentication path |

**Direction:**
- **One-way:** Το Domain A εμπιστεύεται το Domain B (users του B μπορούν να μπουν στο A, όχι το αντίστροφο)
- **Two-way:** Αμοιβαία εμπιστοσύνη

```powershell
Get-ADTrust -Filter *
New-ADTrust -Name "partner.local" -Target "partner.local" -TrustType Forest -Direction Bidirectional
Get-ADTrust -Identity "partner.local" | Select Direction, TrustType, ForestTransitive
```

> ⚠️ Trust ≠ αυτόματα permissions — μόνο ανοίγει τον "δρόμο" authentication. Χρειάζεται ξεχωριστά να δοθούν δικαιώματα (π.χ. προσθήκη foreign users σε local groups).

---

## 🌐 5. DNS Integration

### 📖 Θεωρία: Γιατί το AD "ζει" μέσα στο DNS

Το AD **βασίζεται πλήρως** στο DNS για να λειτουργήσει — οι clients βρίσκουν Domain Controllers μέσω ειδικών **SRV records**, όχι μέσω static IPs.

```
_ldap._tcp.company.local          → Ποιος DC κάνει LDAP
_kerberos._tcp.company.local      → Ποιος DC κάνει Kerberos auth
_ldap._tcp.Athens._sites.company.local  → DC συγκεκριμένου site
```

**Active Directory-Integrated Zones:** Το DNS zone data αποθηκεύεται *μέσα* στο AD database και replικάρεται μαζί με τα υπόλοιπα AD data — πιο ανθεκτικό από standalone DNS server.

```
:: Επαλήθευση ότι το DNS "βλέπει" σωστά τους DCs
nslookup -type=SRV _ldap._tcp.company.local
nslookup -type=SRV _kerberos._tcp.company.local

:: Εύρεση DC μέσω domain locator
nltest /dsgetdc:company.local

:: Έλεγχος DNS server config του client
ipconfig /all | findstr "DNS Servers"
```

> 💡 Το πιο συχνό λάθος σε νέα περιβάλλοντα: ο client έχει ρυθμισμένο **public DNS** (π.χ. 8.8.8.8) αντί για τον **DC ως DNS server**. Αποτέλεσμα: authentication timeouts, "cannot find domain controller" errors. Ο DC πρέπει *πάντα* να είναι το DNS server των domain-joined μηχανημάτων.

---

## 🔐 6. Fine-Grained Password Policies

### 📖 Θεωρία

Παλιά, το AD επέτρεπε **μόνο μία** password policy ανά domain (Default Domain Policy). Οι **Fine-Grained Password Policies (FGPP / PSOs)** επιτρέπουν διαφορετικές πολιτικές για διαφορετικές ομάδες — π.χ. πιο αυστηρή πολιτική για Domain Admins, πιο χαλαρή για service accounts.

```powershell
# Δημιουργία PSO για admins — πιο αυστηρό
New-ADFineGrainedPasswordPolicy -Name "AdminPasswordPolicy" `
    -Precedence 10 `
    -MinPasswordLength 16 `
    -PasswordHistoryCount 24 `
    -LockoutThreshold 3 `
    -ComplexityEnabled $true `
    -ReversibleEncryptionEnabled $false

# Εφαρμογή στο group Domain Admins
Add-ADFineGrainedPasswordPolicySubject -Identity "AdminPasswordPolicy" -Subjects "Domain Admins"

# Έλεγχος ποια policy ισχύει τελικά για συγκεκριμένο χρήστη
Get-ADUserResultantPasswordPolicy -Identity "d.katsanos"
```

> 💡 **Precedence:** Χαμηλότερος αριθμός = υψηλότερη προτεραιότητα. Αν ένας χρήστης καλύπτεται από πολλά PSOs, κερδίζει αυτό με το μικρότερο Precedence number.

---

## 📶 7. Domain & Forest Functional Levels

### 📖 Θεωρία

Το **Functional Level** καθορίζει ποια features είναι διαθέσιμα, βάσει της **παλαιότερης** έκδοσης Windows Server DC που υποστηρίζεται. Ανεβάζοντας το level "κλειδώνεις" ότι δεν θα ξαναπροστεθεί DC παλιότερης έκδοσης — αλλά ξεκλειδώνεις νέα χαρακτηριστικά.

| Functional Level | Ξεκλειδώνει (ενδεικτικά) |
|---|---|
| Windows Server 2012 R2 | Baseline παλαιότερων features |
| Windows Server 2016 | Privileged Access Management, Kerberos armoring |
| Windows Server 2025 | Νεότερα security & performance features |

```powershell
Get-ADDomain | Select DomainMode
Get-ADForest | Select ForestMode

# Ανύψωση level (μη αναστρέψιμο σε ορισμένες περιπτώσεις — προσοχή!)
Set-ADDomainMode -Identity company.local -DomainMode Windows2016Domain
Set-ADForestMode -Identity company.local -ForestMode Windows2016Forest
```

> ⚠️ Πριν ανυψώσεις level, βεβαιώσου ότι **όλοι** οι DCs τρέχουν έκδοση Windows Server ίση ή νεότερη από το target level — αλλιώς αποτυγχάνει.

---

## 🛡️ 8. Security Hardening & Tiering

### 📖 Θεωρία: Tier Model

Το **Microsoft Tiering Model** χωρίζει τα assets σε επίπεδα εμπιστοσύνης, ώστε ένα compromised endpoint να μην μπορεί να "σκαρφαλώσει" σε critical infrastructure:

```
Tier 0 — Domain Controllers, AD, PKI, Identity systems (το πιο κρίσιμο)
Tier 1 — Servers, εφαρμογές
Tier 2 — Workstations, end-user devices
```

**Βασικός κανόνας:** Ένας Tier 0 λογαριασμός (π.χ. Domain Admin) **δεν πρέπει ποτέ** να κάνει login σε Tier 1/2 μηχανήματα — γιατί το credential "μένει" στη μνήμη εκεί και μπορεί να κλαπεί (π.χ. με Mimikatz) αν το endpoint έχει compromised.

**Βασικές πρακτικές:**

| Πρακτική | Γιατί |
|---|---|
| Ξεχωριστός λογαριασμός για Domain Admin tasks | Ποτέ καθημερινό email/browsing με admin account |
| **LAPS** (Local Administrator Password Solution) | Μοναδικός, rotating τοπικός admin κωδικός ανά μηχάνημα |
| Απενεργοποίηση NTLM όπου γίνεται | Kerberos είναι πιο ασφαλές |
| Protected Users group | Αποτρέπει caching credentials, NTLM fallback για ευαίσθητους λογαριασμούς |
| Regular privileged access review | Ποιος είναι πραγματικά Domain Admin — συχνά "ξεχνιούνται" άτομα εκεί |

```powershell
# Ποιοι είναι Domain Admins αυτή τη στιγμή — έλεγχος τακτικά
Get-ADGroupMember -Identity "Domain Admins" | Select Name, SamAccountName

# Προσθήκη ευαίσθητου λογαριασμού στο Protected Users group
Add-ADGroupMember -Identity "Protected Users" -Members "svc.backupadmin"
```

---

## ⚔️ 9. Κοινές Επιθέσεις σε AD (Awareness)

> 📌 Σκοπός αυτής της ενότητας είναι **αμυντική** κατανόηση (defender/blue-team perspective), όχι offensive χρήση.

| Επίθεση | Σε τι βασίζεται | Άμυνα |
|---|---|---|
| **Kerberoasting** | Service accounts με weak passwords + SPN → offline cracking του Kerberos ticket | Ισχυροί/random passwords σε service accounts, gMSA όπου γίνεται |
| **Pass-the-Hash** | Κλοπή NTLM hash από μνήμη, χρήση χωρίς να χρειάζεται plaintext password | Απενεργοποίηση NTLM όπου γίνεται, Credential Guard |
| **Golden Ticket** | Κλοπή του KRBTGT account hash → πλαστά Kerberos TGTs για απεριόριστη πρόσβαση | Rotation του KRBTGT password περιοδικά (2x, με χρονική απόσταση) |
| **DCSync** | Χρήση replication permissions για να "τραβηχτούν" password hashes σαν να ήσουν DC | Περιορισμός replication permissions, monitoring για ύποπτα replication requests |

**Monitoring σημεία:**

```
Event ID 4769  → Kerberos Service Ticket requests (ψάξε για ασυνήθιστο volume = πιθανό kerberoasting)
Event ID 4662  → Πρόσβαση σε object με ευαίσθητα δικαιώματα (πιθανό DCSync)
Event ID 4672  → Ανάθεση special privileges σε logon (ποιος γίνεται "ισχυρός")
```

---

## 💾 10. Backup & Restore

### 📖 Θεωρία: System State Backup

Το AD database (`ntds.dit`) δεν αντιγράφεται σαν κανονικό αρχείο ενώ ο DC τρέχει — χρειάζεται **System State Backup**, που περιλαμβάνει AD database, SYSVOL, Registry, Boot files.

```powershell
# Εγκατάσταση Windows Server Backup feature (αν λείπει)
Install-WindowsFeature Windows-Server-Backup

# System State backup σε external drive
wbadmin start systemstatebackup -backuptarget:E: -quiet

# Λίστα διαθέσιμων backups
wbadmin get versions
```

### AD Recycle Bin — "Μαλακή" διαγραφή

```powershell
# Ενεργοποίηση (μη αναστρέψιμο μόλις ενεργοποιηθεί)
Enable-ADOptionalFeature -Identity 'Recycle Bin Feature' `
    -Scope ForestOrConfigurationSet -Target company.local

# Εύρεση διαγραμμένου object
Get-ADObject -Filter {displayName -eq "Dimitris Katsanos"} -IncludeDeletedObjects

# Επαναφορά
Get-ADObject -Filter {displayName -eq "Dimitris Katsanos"} -IncludeDeletedObjects |
    Restore-ADObject
```

### Restore Modes (αν χαθεί DC ολόκληρα)

| Mode | Πότε |
|---|---|
| **Non-Authoritative Restore** | Ο DC επανέρχεται και μετά "τραβάει" τις πιο πρόσφατες αλλαγές από άλλους DCs |
| **Authoritative Restore** | Χρησιμοποιείται όταν θες το backup να "επικρατήσει" έναντι των άλλων DCs (π.χ. λάθος μαζική διαγραφή που ήδη replikαρίστηκε παντού) — γίνεται με `ntdsutil` σε Directory Services Restore Mode (DSRM) |

---

## 🖥️ 11. Promotion/Demotion Domain Controller

```powershell
# Εγκατάσταση AD DS role
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# Δημιουργία νέου forest (πρώτος DC ποτέ)
Install-ADDSForest -DomainName "company.local" `
    -DomainNetbiosName "COMPANY" `
    -InstallDNS `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "DSRM_P@ssw0rd!" -AsPlainText -Force)

# Προσθήκη επιπλέον DC σε υπάρχον domain
Install-ADDSDomainController -DomainName "company.local" `
    -InstallDNS `
    -Credential (Get-Credential) `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "DSRM_P@ssw0rd!" -AsPlainText -Force)

# Demotion (αφαίρεση DC role)
Uninstall-ADDSDomainController -DemoteOperationMasterRole -RemoveApplicationPartitions
```

> ⚠️ Πριν από demotion, βεβαιώσου ότι ο συγκεκριμένος DC **δεν** κατέχει κανένα FSMO role (§1) — αλλιώς πρέπει πρώτα να τα μεταφέρεις.

---

## 🔍 12. Advanced PowerShell & LDAP Queries

```powershell
# Custom LDAP filter — όλοι οι users με κενό μήνυμα κωδικού που δεν λήγει ποτέ
Get-ADUser -LDAPFilter "(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=65536))"

# Computers που δεν έχουν κάνει login πάνω από 90 μέρες (πιθανά "stale")
$cutoff = (Get-Date).AddDays(-90)
Get-ADComputer -Filter {LastLogonDate -lt $cutoff} -Properties LastLogonDate |
    Select Name, LastLogonDate

# Όλα τα groups και πόσα μέλη έχει το καθένα
Get-ADGroup -Filter * | ForEach-Object {
    [PSCustomObject]@{
        Group   = $_.Name
        Members = (Get-ADGroupMember -Identity $_.DistinguishedName -ErrorAction SilentlyContinue).Count
    }
} | Sort Members -Descending

# Nested group membership (recursive) — "σε ποια groups ανήκω στην πραγματικότητα"
Get-ADPrincipalGroupMembership -Identity "d.katsanos" | Select Name

# Export πλήρους οργανογράμματος OU structure
Get-ADOrganizationalUnit -Filter * | Select Name, DistinguishedName | Export-Csv ou_structure.csv
```

---

## 🩺 13. Advanced Troubleshooting

```
:: Πλήρες health check — τρέχει ΠΟΛΛΑ tests μαζί, καλό πρώτο βήμα
dcdiag /v /c /d /e /s:DC01 > dcdiag_report.txt

:: Έλεγχος secure channel (η "εμπιστοσύνη" μεταξύ PC και domain)
Test-ComputerSecureChannel -Verbose

:: Επισκευή secure channel αν έχει σπάσει ("Trust relationship failed" error)
Test-ComputerSecureChannel -Repair -Credential (Get-Credential)

:: Έλεγχος SYSVOL replication (DFSR σε νεότερα Windows Server)
dfsrdiag replicationstate
Get-DfsrState

:: Πλήρης λίστα των DCs στο domain
Get-ADDomainController -Filter * | Select Name, Site, IsGlobalCatalog, OperatingSystem

:: Έλεγχος Global Catalog διαθεσιμότητας
nltest /dsgetdc:company.local /GC
```

**Σενάριο: "Ο χρήστης λέει ότι δεν βλέπει σωστά group memberships μετά από αλλαγή"**

```powershell
# 1. Επιβεβαίωσε ότι η αλλαγή έγινε πράγματι
Get-ADGroupMember -Identity "IT-Admins"

# 2. Έλεγξε replication status — μήπως η αλλαγή δεν έχει φτάσει ακόμα σε όλους τους DCs
repadmin /showrepl

# 3. Force replication αν χρειάζεται
repadmin /syncall /AdeP

# 4. Θύμισε στον χρήστη: χρειάζεται LOG OFF + LOG ON για νέο Kerberos token (§ βασικό αρχείο, whoami/access tokens)
```

---

## 📚 Σχετικά αρχεία

- [`active-directory.md`](./active-directory.md) — Βασικά: Users/Groups, OUs, GPO, Entra ID, PowerShell 101, βασικό troubleshooting
- Αυτό το αρχείο (`active-directory-advanced.md`) — FSMO, Replication, Trusts, DNS, Security, Backup/Restore, Advanced Troubleshooting
