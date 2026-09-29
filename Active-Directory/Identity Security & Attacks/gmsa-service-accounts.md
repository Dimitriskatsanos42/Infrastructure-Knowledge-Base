# 🔧 gMSA & Service Accounts — Deep Dive & Real-World Runbook
> Συνοδευτικό αρχείο στη σειρά Active Directory. Στο [`ad-security-hardening.md`](./ad-security-hardening.md#-4-επίθεση-1-kerberoasting) είδαμε γιατί τα service accounts με στατικά passwords είναι από τους πιο συχνούς στόχους επίθεσης. Εδώ βλέπουμε **πλήρως πώς** τα αντικαθιστάς σωστά.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Το Πρόβλημα με τα Παραδοσιακά Service Accounts](#-1-το-πρόβλημα-με-τα-παραδοσιακά-service-accounts)
2. [Οι Επιλογές — Σύγκριση](#-2-οι-επιλογές--σύγκριση)
3. [Πώς Δουλεύει Πραγματικά ένα gMSA](#-3-πώς-δουλεύει-πραγματικά-ένα-gmsa)
4. [Σενάριο — Το Ticket](#-4-σενάριο--το-ticket)
5. [Runbook: Πρώτη Εγκατάσταση gMSA Infrastructure](#-5-runbook-πρώτη-εγκατάσταση-gmsa-infrastructure)
6. [Runbook: Δημιουργία & Χρήση ενός gMSA](#-6-runbook-δημιουργία--χρήση-ενός-gmsa)
7. [gMSA σε IIS Application Pool](#-7-gmsa-σε-iis-application-pool)
8. [gMSA σε Scheduled Task](#-8-gmsa-σε-scheduled-task)
9. [Multi-Server Scenarios — Group-Based Access](#-9-multi-server-scenarios--group-based-access)
10. [dMSA — Το Επόμενο Βήμα (Windows Server 2025)](#-10-dmsa--το-επόμενο-βήμα-windows-server-2025)
11. [Migration Plan — Από Legacy σε gMSA](#-11-migration-plan--από-legacy-σε-gmsa)
12. [Troubleshooting](#-12-troubleshooting)
13. [Checklist](#-13-checklist)

---

## ⚠️ 1. Το Πρόβλημα με τα Παραδοσιακά Service Accounts

Ένα κλασικό service account (π.χ. `svc-sqlserver`) είναι απλά ένα **κανονικό user account** που χρησιμοποιείται από μια εφαρμογή/service αντί από άνθρωπο. Αυτό δημιουργεί προβλήματα:

| Πρόβλημα | Γιατί συμβαίνει |
|---|---|
| **Στατικό password** | Κάποιος το γράφει σε ένα config file/script μία φορά, και μετά κανείς δεν το αλλάζει ποτέ ξανά — "αν δεν είναι χαλασμένο, μην το αγγίζεις" |
| **Ο κωδικός "ξέρεται"** | Αποθηκευμένος σε plaintext σε config files, scripts, ή documentation — μεγάλο attack surface |
| **Kerberoastable** | Όπως είδαμε, οποιοσδήποτε authenticated user μπορεί να ζητήσει service ticket και να προσπαθήσει offline cracking |
| **Manual rotation = downtime risk** | Αλλαγή password σημαίνει να θυμηθείς ΚΑΘΕ μέρος που χρησιμοποιείται (μπορεί να ξεχάσεις ένα scheduled task κάπου) → service breaks |
| **Δεν "λήγει" ποτέ** | Συνήθως ρυθμίζεται "Password Never Expires" ώστε να μη σπάσει κάτι — αλλά αυτό σημαίνει ότι ένα κλεμμένο password μένει χρήσιμο επ' αόριστον |

> 💡 **Real-world αλήθεια:** Σχεδόν κάθε εταιρεία που δεν έχει ακόμα υιοθετήσει gMSA έχει τουλάχιστον έναν service account με password που δεν έχει αλλάξει **χρόνια**, και που ο κωδικός του είναι γνωστός σε πολύ περισσότερους ανθρώπους απ' όσους θα έπρεπε (πρώην υπάλληλοι που το είδαν κάποτε σε ένα script, κ.λπ.).

---

## ⚖️ 2. Οι Επιλογές — Σύγκριση

| | Standard User Account | MSA (Standalone) | **gMSA (Group)** | dMSA (Delegated, νέο) |
|---|---|---|---|---|
| **Password management** | Χειροκίνητο | Αυτόματο | Αυτόματο | Αυτόματο |
| **Rotation** | Ποτέ (στην πράξη) | Αυτόματο, ~30 μέρες | Αυτόματο, ~30 μέρες | Αυτόματο |
| **Χρήση σε πολλαπλά servers (π.χ. cluster)** | Ναι, αλλά χειροκίνητα | ❌ Όχι — μόνο 1 server | ✅ Ναι — αυτό είναι το "Group" | Ναι |
| **Kerberoasting risk** | Υψηλό | Χαμηλό | Πολύ χαμηλό (120-char password) | Πολύ χαμηλό |
| **Χρειάζεται interactive logon ποτέ;** | Ναι, δυνατό (κακή πρακτική) | Όχι | Όχι | Όχι |
| **Windows Server requirement** | Οποιοδήποτε | 2008 R2+ | 2012+ | 2025+ |

> 💡 Στην πράξη, **gMSA** είναι σχεδόν πάντα η σωστή επιλογή σήμερα — το MSA (standalone) είναι ξεπερασμένο (δεν υποστηρίζει πολλαπλά servers, το πιο κοινό real-world ανάγκη), και το dMSA είναι πολύ νέο (Windows Server 2025+) για να είναι ακόμα ευρέως διαθέσιμο σε production environments.

---

## 🔍 3. Πώς Δουλεύει Πραγματικά ένα gMSA

```
Παραδοσιακό service account:
  Password ορίζεται από τον admin → Μένει το ΙΔΙΟ μέχρι κάποιος να το αλλάξει χειροκίνητα
  Ο admin "ξέρει" το password (το έγραψε κάπου για να το θυμάται)

gMSA:
  Password = 120 χαρακτήρες, ΠΛΗΡΩΣ τυχαίο, ΔΕΝ το ξέρει ΚΑΝΕΙΣ (ούτε ο admin)
  → Αποθηκεύεται κρυπτογραφημένα στο AD (KDS Root Key-based encryption)
  → Αυτόματη εναλλαγή κάθε 30 μέρες (default, configurable)
  → ΜΟΝΟ τα computer accounts που είναι ΡΗΤΑ εξουσιοδοτημένα
    ("PrincipalsAllowedToRetrieveManagedPassword") μπορούν να το "διαβάσουν"
    - και το κάνουν αυτόματα, το OS το διαχειρίζεται, όχι ο admin
```

```
Server01 (εξουσιοδοτημένο)  →  Ζητάει το password αυτόματα από AD  →  ✅ Το παίρνει
Server02 (ΜΗ εξουσιοδοτημένο) →  Ζητάει το password                →  ❌ Access Denied

Ο ίδιος μηχανισμός λειτουργεί ΚΑΙ για πολλαπλά servers ταυτόχρονα
(π.χ. NLB/cluster) - αυτό είναι το "Group" στο όνομα gMSA.
```

**Το KDS Root Key** είναι το θεμέλιο πίσω από όλο αυτό — ένα key που αποθηκεύεται στο AD και χρησιμοποιείται από όλους τους DCs για να παράγουν (deterministically) το ίδιο password για ένα gMSA, χωρίς να χρειάζεται να το "στείλουν" μεταξύ τους μέσω δικτύου.

---

## 🎫 4. Σενάριο — Το Ticket

> **Ticket #4735** — *"Έχουμε ένα SQL Server cluster (2 nodes) που τρέχει με service account `svc-sql-legacy`, password δεν έχει αλλάξει από το 2021, και τον κωδικό τον ξέρουν 4 άτομα που έχουν φύγει ήδη από την εταιρεία. Χρειαζόμαστε migration σε κάτι πιο ασφαλές χωρίς downtime στο production SQL Server."*

Κλασικό real-world σενάριο — χρειάζεται gMSA migration (λύνει το "cluster" requirement, αφού το gMSA δουλεύει σε πολλαπλά servers ταυτόχρονα) με προσεκτικό planning για zero-downtime.

---

## 🛠️ 5. Runbook: Πρώτη Εγκατάσταση gMSA Infrastructure

Αυτό γίνεται **μία φορά** ανά forest/domain — μετά, η δημιουργία κάθε νέου gMSA είναι απλή.

```powershell
# Βήμα 1: Δημιουργία KDS Root Key (μία φορά ανά domain, ΠΟΤΕ ξανά μετά)
# ΠΡΟΣΟΧΗ: Default χρειάζεται να περιμένεις 10 ώρες για replication πριν
# μπορέσεις να δημιουργήσεις το πρώτο gMSA (ασφάλεια - διασφαλίζει ότι το
# key έχει διαδοθεί σε ΟΛΟΥΣ τους DCs πρώτα)

Add-KdsRootKey -EffectiveTime ((Get-Date).AddHours(-10))
# Το "-10 ώρες" trick χρησιμοποιείται ΜΟΝΟ σε lab/test environments για να
# παρακάμψεις την αναμονή - σε PRODUCTION, χρησιμοποίησε:
# Add-KdsRootKey -EffectiveImmediately
# (και περίμενε πραγματικά τις ~10 ώρες πριν φτιάξεις το πρώτο gMSA)

# Βήμα 2: Επαλήθευση
Get-KdsRootKey
```

> ⚠️ **Πολύ σημαντικό real-world detail:** Το `-EffectiveTime ((Get-Date).AddHours(-10))` trick (κάνει σαν να δημιουργήθηκε το key 10 ώρες πριν, ώστε να δουλέψει αμέσως) είναι **ΜΟΝΟ για lab/testing**. Σε πραγματικό production environment, κάνε το σωστά και περίμενε την πραγματική αναμονή — το replication delay υπάρχει για λόγο (διασφαλίζει ότι κάθε DC έχει το key πριν κάποιο gMSA το χρειαστεί).

---

## 🛠️ 6. Runbook: Δημιουργία & Χρήση ενός gMSA

```powershell
# Βήμα 1: Δημιουργία security group - ποια computers επιτρέπεται να χρησιμοποιήσουν το gMSA
New-ADGroup -Name "gMSA-SQL-Cluster-Hosts" -GroupScope DomainLocal -GroupCategory Security `
    -Path "OU=ServiceAccounts,DC=company,DC=local"

Add-ADGroupMember -Identity "gMSA-SQL-Cluster-Hosts" -Members "SQLNODE01$","SQLNODE02$"
# Σημείωση: το "$" στο τέλος δηλώνει computer account, όχι user account

# Βήμα 2: Δημιουργία του gMSA
New-ADServiceAccount -Name "gmsa-sql-cluster" `
    -DNSHostName "gmsa-sql-cluster.company.local" `
    -PrincipalsAllowedToRetrieveManagedPassword "gMSA-SQL-Cluster-Hosts" `
    -ServicePrincipalNames "MSSQLSvc/sql-cluster.company.local:1433"

# Βήμα 3: Εγκατάσταση του gMSA στα εξουσιοδοτημένα servers (τρέχεται σε ΚΑΘΕ node)
# (Στο SQLNODE01 και SQLNODE02, τοπικά):
Install-ADServiceAccount -Identity "gmsa-sql-cluster"

# Βήμα 4: Test ότι δουλεύει (τρέχεται τοπικά σε κάθε node)
Test-ADServiceAccount -Identity "gmsa-sql-cluster"
# Αναμενόμενο αποτέλεσμα: True
```

> 💡 **Γιατί χρειάζεται το group στο Βήμα 1;** Επειδή το gMSA ξέρει "ποιος επιτρέπεται" μέσω group membership, όχι μέσω individual computer entries — ακριβώς το ίδιο AGDLP pattern που είδαμε σε NTFS permissions ([`file-permissions-ntfs.md`](./file-permissions-ntfs.md)) και AD groups γενικά. Αν προσθέσεις τρίτο SQL node στο cluster αργότερα, απλά το προσθέτεις στο group — καμία αλλαγή στο ίδιο το gMSA χρειάζεται.

---

## 🌐 7. gMSA σε IIS Application Pool

```powershell
# Στον IIS server, μετά το Install-ADServiceAccount (§6, Βήμα 3):

Import-Module WebAdministration

Set-ItemProperty "IIS:\AppPools\HRPortalAppPool" -Name processModel.identityType -Value 3
Set-ItemProperty "IIS:\AppPools\HRPortalAppPool" -Name processModel.userName -Value "COMPANY\gmsa-hrportal$"
Set-ItemProperty "IIS:\AppPools\HRPortalAppPool" -Name processModel.password -Value ""
# Σημείωση: ΚΕΝΟ password - το IIS/Windows διαχειρίζεται αυτόματα την ανάκτηση
# του πραγματικού (120-char, rotating) password μέσω του gMSA μηχανισμού.
# Το "$" στο τέλος του username ΕΙΝΑΙ απαραίτητο για gMSA/computer accounts.

# Restart του application pool για να εφαρμοστεί
Restart-WebAppPool -Name "HRPortalAppPool"
```

---

## ⏰ 8. gMSA σε Scheduled Task

```powershell
# Δημιουργία scheduled task που τρέχει με gMSA identity
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Scripts\nightly-backup.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At "23:00"
$principal = New-ScheduledTaskPrincipal -UserId "COMPANY\gmsa-backup-task$" -LogonType Password -RunLevel Highest

Register-ScheduledTask -TaskName "Nightly-File-Backup" -Action $action -Trigger $trigger -Principal $principal
```

> 💡 Παρατήρησε ότι **δεν χρειάζεται καν να δώσεις password** στο `Register-ScheduledTask` — αυτό είναι το σημείο, το Windows το διαχειρίζεται αυτόματα μέσω του gMSA μηχανισμού.

---

## 👥 9. Multi-Server Scenarios — Group-Based Access

Αυτό είναι το feature που κάνει το gMSA να "λύνει" το ticket #4735 (SQL cluster, 2 nodes) — κάτι που το παλιότερο standalone MSA **δεν** μπορούσε να κάνει καθόλου.

```powershell
# Προσθήκη τρίτου node στο cluster αργότερα (π.χ. scale-out)
Add-ADGroupMember -Identity "gMSA-SQL-Cluster-Hosts" -Members "SQLNODE03$"

# Στο νέο node:
Install-ADServiceAccount -Identity "gmsa-sql-cluster"
Test-ADServiceAccount -Identity "gmsa-sql-cluster"

# Αυτό είναι όλο - το gMSA "δουλεύει" ήδη στο νέο node, ΚΑΝΕΝΑ password
# δεν χρειάστηκε να μεταφερθεί/αντιγραφεί χειροκίνητα
```

---

## 🚀 10. dMSA — Το Επόμενο Βήμα (Windows Server 2025)

Μια πολύ πρόσφατη εξέλιξη που αξίζει να ξέρεις ότι υπάρχει (ακόμα κι αν δεν το χρησιμοποιήσεις άμεσα σε production):

```
dMSA (Delegated Managed Service Account):
  → Σχεδιασμένο ΕΙΔΙΚΑ για να αντικαταστήσει PΑΛΙΟΥΣ, ήδη-υπάρχοντες
    standard service accounts χωρίς να χρειάζεται να ξαναγράψεις
    configuration σε εφαρμογές
  → Migration tool: "μεταμορφώνει" ένα standard account σε dMSA,
    διατηρώντας το ίδιο SID history (οι εφαρμογές δεν "καταλαβαίνουν" καν
    ότι άλλαξε κάτι)
  → Απαιτεί Windows Server 2025 Domain Functional Level

  Requires: Windows Server 2025+ DCs
```

> 💡 Αν η εταιρεία δεν έχει ακόμα Windows Server 2025 DCs, το **gMSA** παραμένει η σωστή, ώριμη επιλογή σήμερα. Το dMSA αξίζει να το ξέρεις για το μέλλον/για συνέντευξη, αλλά δεν είναι ακόμα το mainstream production standard στα περισσότερα environments.

---

## 📋 11. Migration Plan — Από Legacy σε gMSA

Έτσι θα προσέγγιζες πραγματικά το ticket #4735 (zero-downtime migration του SQL cluster):

```
Βήμα 1: Planning
  → Καταγραφή ΟΛΩΝ των σημείων που χρησιμοποιείται το svc-sql-legacy
    (SQL Server service, SQL Agent, linked servers, scheduled jobs, κ.λπ.)
  → Δημιουργία test/staging environment αν είναι εφικτό

Βήμα 2: Δημιουργία gMSA παράλληλα (§6) - ΔΕΝ αγγίζεις ακόμα το production

Βήμα 3: Testing σε non-production πρώτα
  → Test-ADServiceAccount σε staging server
  → Επιβεβαίωση ότι το SQL Server μπορεί να ξεκινήσει με το νέο gMSA

Βήμα 4: Maintenance window (ΝΑΙ, χρειάζεται μικρό restart - το "zero-downtime"
  σημαίνει "ελάχιστο planned downtime", όχι "καθόλου")
  → Αλλαγή του SQL Server service "Log On As" σε νέο gMSA
  → Restart SQL Server service
  → Επαλήθευση ότι όλα τα databases/jobs δουλεύουν κανονικά

Βήμα 5: Επανάληψη σε δεύτερο node (SQLNODE02)
  → Ξεχωριστό, μικρότερο maintenance window - ο cluster failover
    καλύπτει τη διαθεσιμότητα ενώ γίνεται restart στο ένα node

Βήμα 6: Cleanup
  → Disable (ΟΧΙ delete αμέσως) το παλιό svc-sql-legacy account
  → Παρακολούθηση για 2-4 εβδομάδες - βεβαιώσου ότι τίποτα δεν "έσπασε"
    λόγω κάποιου ξεχασμένου reference στο παλιό account
  → Μετά, delete το παλιό account
```

> 💡 **Το "Disable πρώτα, Delete μετά" pattern** είναι πολύ σημαντικό real-world habit — αν κάτι ξεχάστηκε (π.χ. ένα linked server σε άλλον SQL instance που ακόμα χρησιμοποιεί το παλιό account), το disable σου δίνει immediate, ασφαλή "rollback" (re-enable) χωρίς να χρειαστεί να ξαναφτιάξεις το account από την αρχή.

---

## 🔧 12. Troubleshooting

| Πρόβλημα | Πιθανή Αιτία | Λύση |
|---|---|---|
| `Test-ADServiceAccount` επιστρέφει False | Server δεν είναι στο σωστό authorized group, ή δεν πέρασε αρκετός χρόνος από KDS Root Key creation | Έλεγξε group membership, περίμενε replication (§5) |
| "Access Denied" όταν το service προσπαθεί να ξεκινήσει | Ξεχασμένο `Install-ADServiceAccount` σε αυτό το συγκεκριμένο server | Τρέξε `Install-ADServiceAccount` τοπικά σε ΑΥΤΟ το server |
| gMSA δουλεύει σε ένα node του cluster αλλά όχι στο δεύτερο | Το δεύτερο node δεν προστέθηκε στο authorized group, ή δεν έγινε `Install-ADServiceAccount` εκεί | Έλεγξε §9 βήματα, επανάλαβε σε κάθε node |
| Service δεν ξεκινάει μετά από migration σε gMSA | Λάθος format username (πρέπει να έχει `$` στο τέλος) | `COMPANY\gmsa-name$`, ΟΧΙ `COMPANY\gmsa-name` |
| KDS Root Key creation error | Δεν υπάρχουν επαρκή δικαιώματα (χρειάζεται Domain Admin) | Έλεγξε permissions, τρέξε ως Domain Admin |

```powershell
# Διαγνωστικά
Get-ADServiceAccount -Identity "gmsa-sql-cluster" -Properties *
Get-ADServiceAccount -Identity "gmsa-sql-cluster" -Properties PrincipalsAllowedToRetrieveManagedPassword |
    Select -ExpandProperty PrincipalsAllowedToRetrieveManagedPassword

# Event log που ελέγχεις σε gMSA-related προβλήματα
Get-WinEvent -LogName "Microsoft-Windows-GroupManagedServiceAccounts/Operational" -MaxEvents 30
```

---

## ✅ 13. Checklist

```
☐ KDS Root Key υπάρχει και έχει replikαριστεί (Get-KdsRootKey)
☐ Security group δημιουργήθηκε για authorized hosts (AGDLP pattern)
☐ gMSA δημιουργήθηκε με σωστό SPN
☐ Install-ADServiceAccount τρέχτηκε σε ΚΑΘΕ server που θα το χρησιμοποιήσει
☐ Test-ADServiceAccount επιστρέφει True σε κάθε server
☐ Migration πλάνο υπάρχει (αν αντικαθιστάς legacy account) - §11
☐ Testing σε non-production πριν το production migration
☐ Παλιό service account DISABLED (όχι αμέσως deleted) μετά τη migration
☐ Monitoring period 2-4 εβδομάδων πριν το τελικό cleanup
☐ Documentation - ποιο gMSA χρησιμοποιείται για ποιο service, ποιο group το εξουσιοδοτεί
```

---

## 📚 Σχετικά αρχεία

- [`active-directory.md`](./active-directory.md) — Users/Groups, AGDLP pattern
- [`ad-security-hardening.md`](./ad-security-hardening.md) — Kerberoasting §4 — το πρόβλημα που λύνει το gMSA
- [`kerberos-deep-dive.md`](./kerberos-deep-dive.md) — SPNs, πώς λειτουργούν τα service tickets
- [`file-permissions-ntfs.md`](./file-permissions-ntfs.md) — Ίδιο AGDLP group-based access pattern
- Αυτό το αρχείο (`gmsa-service-accounts.md`) — gMSA setup, IIS/Scheduled Task χρήση, migration plan
