# 🛠️ File Server Permissions — Real-World Implementation Runbook
> Συνοδευτικό αρχείο στο [`file-permissions-ntfs.md`](./file-permissions-ntfs.md) — εδώ δεν εξηγούμε **τι** είναι τα permissions, αλλά **πώς πραγματικά υλοποιείς** ένα σωστό file share σε πραγματική εταιρεία, βήμα-βήμα, σαν πραγματικό project/ticket.
> Στόχος: να μπορείς να πεις σε συνέντευξη *"έχω κάνει αυτό το ακριβές setup"* — όχι μόνο θεωρία.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Σενάριο — Το Ticket](#-1-σενάριο--το-ticket)
2. [Φάση 1: Planning & Requirements Gathering](#-2-φάση-1-planning--requirements-gathering)
3. [Φάση 2: Naming Conventions & Σχεδιασμός Δομής](#-3-φάση-2-naming-conventions--σχεδιασμός-δομής)
4. [Φάση 3: Δημιουργία AD Groups & OUs](#-4-φάση-3-δημιουργία-ad-groups--ous)
5. [Φάση 4: Δημιουργία Φακέλων & NTFS Permissions](#-5-φάση-4-δημιουργία-φακέλων--ntfs-permissions)
6. [Φάση 5: Δημιουργία του Share](#-6-φάση-5-δημιουργία-του-share)
7. [Φάση 6: DFS Namespace (Enterprise Scale)](#-7-φάση-6-dfs-namespace-enterprise-scale)
8. [Φάση 7: Quotas & File Screening (FSRM)](#-8-φάση-7-quotas--file-screening-fsrm)
9. [Φάση 8: Testing & Verification](#-9-φάση-8-testing--verification)
10. [Φάση 9: Documentation & Handover](#-10-φάση-9-documentation--handover)
11. [Το Καθημερινό Workflow — Change Requests](#-11-το-καθημερινό-workflow--change-requests)
12. [Πλήρες PowerShell Script — Όλο το Project σε Ένα](#-12-πλήρες-powershell-script--όλο-το-project-σε-ένα)
13. [Πραγματικά Λάθη που Βλέπεις σε Εταιρείες](#-13-πραγματικά-λάθη-που-βλέπεις-σε-εταιρείες)
14. [Checklist — Go-Live](#-14-checklist--go-live)

---

## 🎫 1. Σενάριο — Το Ticket

Έτσι φτάνει συνήθως το request σε πραγματική δουλειά — μέσω ticketing system (Jira, ServiceNow, κ.λπ.), όχι σαν καθαρή τεχνική προδιαγραφή:

> **Ticket #4521** — *"Χρειαζόμαστε νέο shared folder για το τμήμα Marketing. Θέλουμε όλοι στο Marketing να έχουν πρόσβαση, αλλά μόνο οι Team Leads να μπορούν να διαγράφουν αρχεία. Ο εξωτερικός συνεργάτης (freelancer) πρέπει να βλέπει μόνο τον φάκελο 'Campaigns-2026', όχι τα υπόλοιπα."*

Αυτό είναι το είδος ασαφούς αιτήματος που παίρνεις στην πραγματικότητα — δουλειά σου είναι να το μεταφράσεις σε τεχνική λύση.

---

## 📋 2. Φάση 1: Planning & Requirements Gathering

Πριν ανοίξεις οτιδήποτε GUI, καθορίζεις:

| Ερώτηση | Απάντηση (στο παράδειγμά μας) |
|---|---|
| Ποιοι χρήστες/groups χρειάζονται πρόσβαση; | Όλο το Marketing team + 1 freelancer |
| Τι επίπεδο πρόσβασης χρειάζεται ο καθένας; | Team = Modify χωρίς delete, Leads = Full Control, Freelancer = Read-only σε 1 subfolder |
| Πού θα ζει ο φάκελος; (ποιος server, ποιο volume) | `FS01`, `E:\Shares\` (data drive, όχι C:) |
| Πόσο χώρο αναμένεται να πιάσει; (για quota planning) | ~50GB αρχική εκτίμηση |
| Χρειάζεται versioning/backup ξεχωριστό; | Ναι — Shadow Copies + περιλαμβάνεται στο nightly backup job |
| Compliance/sensitivity; | Όχι PII, δεν χρειάζεται ειδικό auditing |

> 💡 **Πραγματικό tip:** Σε πραγματική δουλειά, το 80% της δουλειάς είναι να κάνεις τις **σωστές ερωτήσεις** στο ticket πριν φτιάξεις οτιδήποτε. Ένα ticket σαν το παραπάνω σχεδόν ποτέ δεν έχει όλες τις λεπτομέρειες — θα χρειαστεί follow-up email/Slack στον requester.

---

## 🏷️ 3. Φάση 2: Naming Conventions & Σχεδιασμός Δομής

### Γιατί έχει σημασία

Σε εταιρεία με 5 file shares, ό,τι όνομα κι αν βάλεις δουλεύει. Σε εταιρεία με 300 groups μετά από 5 χρόνια, αν δεν έχεις convention, **κανείς δεν ξέρει τι κάνει ποιο group**. Αυτό είναι το πιο underrated skill σε αυτή τη δουλειά.

### Standard Convention (πολύ κοινό pattern σε πραγματικές εταιρείες)

```
Security Group naming:  <Location>-<Department>-<Resource>-<PermissionLevel>

Παραδείγματα:
  ATH-Marketing-Share-Modify
  ATH-Marketing-Share-FullControl
  ATH-Marketing-Campaigns2026-Read

Folder naming:
  E:\Shares\Marketing\                  ← Root
  E:\Shares\Marketing\Campaigns-2026\   ← Subfolder με δικό του permission layer
```

| Στοιχείο | Γιατί το βάζεις |
|---|---|
| `<Location>` | Χρήσιμο σε multi-site εταιρείες — ξέρεις αμέσως ποιο site "ανήκει" το group |
| `<Department>` | Γρήγορο filtering/search στο ADUC |
| `<Resource>` | Τι ακριβώς προστατεύει (share/folder name) |
| `<PermissionLevel>` | Τι επίπεδο δίνει — ποτέ δεν μαντεύεις |

> ⚠️ Ποτέ μη χρησιμοποιείς ονόματα ατόμων ή "temporary" περιγραφές (π.χ. `Giorgos-Access` ή `TempGroup1`). Θα σου μείνει στο AD για χρόνια και κανείς δεν θα ξέρει γιατί υπάρχει.

---

## 👥 4. Φάση 3: Δημιουργία AD Groups & OUs

```powershell
# Βήμα 1: Βεβαιώσου ότι υπάρχει το σωστό OU (βλέπε active-directory.md §4)
# Αν όχι, δημιούργησέ το
New-ADOrganizationalUnit -Name "FileShareGroups" -Path "OU=Groups,DC=company,DC=local"

# Βήμα 2: Δημιουργία των Domain Local groups (αυτά μπαίνουν στην ACL)
New-ADGroup -Name "ATH-Marketing-Share-Modify" `
    -GroupScope DomainLocal -GroupCategory Security `
    -Path "OU=FileShareGroups,DC=company,DC=local" `
    -Description "Modify access στο Marketing share - χωρίς delete permissions"

New-ADGroup -Name "ATH-Marketing-Share-FullControl" `
    -GroupScope DomainLocal -GroupCategory Security `
    -Path "OU=FileShareGroups,DC=company,DC=local" `
    -Description "Full Control στο Marketing share - μόνο Team Leads"

New-ADGroup -Name "ATH-Marketing-Campaigns2026-Read" `
    -GroupScope DomainLocal -GroupCategory Security `
    -Path "OU=FileShareGroups,DC=company,DC=local" `
    -Description "Read-only στο Campaigns-2026 subfolder - εξωτερικοί συνεργάτες"

# Βήμα 3: Προσθήκη μελών (ακολουθώντας AGDLP - βλέπε active-directory.md §3)
# Το Global group "Marketing-Team" υποτίθεται ότι ήδη υπάρχει
Add-ADGroupMember -Identity "ATH-Marketing-Share-Modify" -Members "Marketing-Team"
Add-ADGroupMember -Identity "ATH-Marketing-Share-FullControl" -Members "Marketing-TeamLeads"

# Ο freelancer είναι external — δημιουργείται με δικό του λογαριασμό (π.χ. με expiry date!)
New-ADUser -Name "External - John Freelancer" `
    -SamAccountName "ext.jfreelancer" `
    -UserPrincipalName "ext.jfreelancer@company.local" `
    -Path "OU=External,DC=company,DC=local" `
    -AccountExpirationDate (Get-Date).AddMonths(3) `
    -Enabled $true `
    -AccountPassword (ConvertTo-SecureString "TempP@ss123!" -AsPlainText -Force) `
    -ChangePasswordAtLogon $true

Add-ADGroupMember -Identity "ATH-Marketing-Campaigns2026-Read" -Members "ext.jfreelancer"
```

> 💡 **Πραγματικό detail που ξεχνιέται συχνά:** Οι external/freelancer λογαριασμοί **πάντα** παίρνουν `-AccountExpirationDate`. Αν ξεχάσεις αυτό, σε 2 χρόνια θα βρεις 40 "ghost" accounts από πρώην συνεργάτες που ξεχάστηκαν — security risk σε κάθε audit.

---

## 📁 5. Φάση 4: Δημιουργία Φακέλων & NTFS Permissions

```powershell
# Βήμα 1: Δημιουργία της δομής φακέλων
New-Item -Path "E:\Shares\Marketing" -ItemType Directory
New-Item -Path "E:\Shares\Marketing\Campaigns-2026" -ItemType Directory

# Βήμα 2: Αφαίρεση inherited permissions από το "Users" group (default πολύ ανοιχτό)
$acl = Get-Acl "E:\Shares\Marketing"
$acl.SetAccessRuleProtection($true, $false)   # $false = μη διατηρείς τα inherited, καθάρισε
Set-Acl "E:\Shares\Marketing" $acl

# Βήμα 3: Ορισμός των σωστών ACEs στο root folder
$path = "E:\Shares\Marketing"
$acl = Get-Acl $path

# Πάντα κράτα Administrators + SYSTEM (ποτέ μην τα αφαιρείς — θα χαλάσεις backup/management access)
$rules = @(
    (New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administrators","FullControl","ContainerInherit,ObjectInherit","None","Allow")),
    (New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\SYSTEM","FullControl","ContainerInherit,ObjectInherit","None","Allow")),
    (New-Object System.Security.AccessControl.FileSystemAccessRule("COMPANY\ATH-Marketing-Share-Modify","Modify","ContainerInherit,ObjectInherit","None","Allow")),
    (New-Object System.Security.AccessControl.FileSystemAccessRule("COMPANY\ATH-Marketing-Share-FullControl","FullControl","ContainerInherit,ObjectInherit","None","Allow"))
)
foreach ($rule in $rules) { $acl.AddAccessRule($rule) }
Set-Acl $path $acl

# Βήμα 4: Ξεχωριστό permission layer στο subfolder (διακοπή inheritance εδώ)
$subPath = "E:\Shares\Marketing\Campaigns-2026"
$subAcl = Get-Acl $subPath
$subAcl.SetAccessRuleProtection($true, $false)   # Διέκοψε την κληρονομιά - ο freelancer ΔΕΝ πρέπει να βλέπει τίποτα άλλο

$subRules = @(
    (New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administrators","FullControl","ContainerInherit,ObjectInherit","None","Allow")),
    (New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\SYSTEM","FullControl","ContainerInherit,ObjectInherit","None","Allow")),
    (New-Object System.Security.AccessControl.FileSystemAccessRule("COMPANY\ATH-Marketing-Share-FullControl","FullControl","ContainerInherit,ObjectInherit","None","Allow")),
    (New-Object System.Security.AccessControl.FileSystemAccessRule("COMPANY\ATH-Marketing-Campaigns2026-Read","ReadAndExecute","ContainerInherit,ObjectInherit","None","Allow"))
)
foreach ($rule in $subRules) { $subAcl.AddAccessRule($rule) }
Set-Acl $subPath $subAcl
```

> ⚠️ **Γιατί το "Modify" group δεν έχει delete;** Το `Modify` standard permission στην πραγματικότητα *επιτρέπει* delete στο NTFS. Αν το ticket λέει ρητά "να μην μπορούν να διαγράφουν", χρειάζεσαι **Special Permissions** — αφαιρείς συγκεκριμένα το "Delete" και "Delete Subfolders and Files" από το bundle, κρατώντας τα υπόλοιπα Modify rights. Αυτό γίνεται μόνο μέσω Advanced Security Settings (GUI) ή custom `FileSystemRights` flags σε PowerShell — όχι με το απλό standard "Modify".

```powershell
# Custom permission - Modify ΧΩΡΙΣ delete (real-world συχνό αίτημα)
$rights = [System.Security.AccessControl.FileSystemRights]"Modify" -bxor `
          [System.Security.AccessControl.FileSystemRights]"Delete"
# Στην πράξη πιο καθαρό: όρισε explicit rights bundle χειροκίνητα
$customRights = [System.Security.AccessControl.FileSystemRights]::ReadAndExecute -bor `
                [System.Security.AccessControl.FileSystemRights]::Write -bor `
                [System.Security.AccessControl.FileSystemRights]::AppendData
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "COMPANY\ATH-Marketing-Share-Modify", $customRights, "ContainerInherit,ObjectInherit", "None", "Allow"
)
```

---

## 🌐 6. Φάση 5: Δημιουργία του Share

```powershell
# Δημιουργία SMB share - Share permissions ανοιχτά (best practice, βλέπε §3 στο βασικό αρχείο)
New-SmbShare -Name "Marketing" -Path "E:\Shares\Marketing" `
    -FullAccess "BUILTIN\Administrators" `
    -ChangeAccess "Authenticated Users"

# Απόκρυψη του share από το network browsing (προαιρετικό - "$" στο τέλος = hidden share)
New-SmbShare -Name "Marketing$" -Path "E:\Shares\Marketing" -ChangeAccess "Authenticated Users"

# Επαλήθευση
Get-SmbShare -Name "Marketing"
Get-SmbShareAccess -Name "Marketing"
```

> 💡 Πολλές εταιρείες χρησιμοποιούν **hidden shares** (`Marketing$`) για ευαίσθητα departments (HR, Finance) — δεν εμφανίζονται στο network browsing, μόνο όποιος ξέρει το ακριβές path (`\\FS01\Marketing$`) μπορεί να προσπαθήσει να συνδεθεί. Δεν είναι security measure από μόνο του (τα NTFS permissions είναι αυτά που πραγματικά προστατεύουν) — είναι απλά "security through obscurity" bonus layer.

---

## 🗂️ 7. Φάση 6: DFS Namespace (Enterprise Scale)

Σε εταιρεία με **πολλαπλούς file servers**, οι χρήστες δεν θέλεις να θυμούνται `\\FS01\Marketing`, `\\FS02\Finance`, `\\FS03\HR` — θέλεις ένα ενιαίο namespace.

```
Χωρίς DFS:                          Με DFS Namespace:
\\FS01\Marketing                    \\company.local\Departments\Marketing
\\FS02\Finance          →           \\company.local\Departments\Finance
\\FS03\HR                           \\company.local\Departments\HR

(3 διαφορετικά σημεία σύνδεσης)     (1 ενιαίο, ο χρήστης δεν ξέρει/νοιάζεται ποιος server)
```

```powershell
# Εγκατάσταση DFS Namespace role (σε server που θα φιλοξενήσει το namespace)
Install-WindowsFeature FS-DFS-Namespace -IncludeManagementTools

# Δημιουργία του namespace root
New-DfsnRoot -TargetPath "\\FS01\Departments" -Type DomainV2 -Path "\\company.local\Departments"

# Προσθήκη folder target που δείχνει στο πραγματικό share
New-DfsnFolder -Path "\\company.local\Departments\Marketing" -TargetPath "\\FS01\Marketing"
```

**Πλεονεκτήματα σε πραγματική δουλειά:**
- Μπορείς να **μετακινήσεις** το πραγματικό share σε άλλον server χωρίς να αλλάξει τίποτα για τον χρήστη (αλλάζεις μόνο το DFS target).
- Υποστηρίζει **DFS Replication** — αντίγραφο του share σε 2 sites, ο χρήστης πάει αυτόματα στο πλησιέστερο (tie-in με AD Sites, βλέπε `active-directory-advanced.md` §3).

---

## 📊 8. Φάση 7: Quotas & File Screening (FSRM)

Το **File Server Resource Manager (FSRM)** είναι το εργαλείο που χρησιμοποιείς σε πραγματικές εταιρείες για να αποτρέψεις έναν φάκελο να "φάει" όλο τον δίσκο.

```powershell
# Εγκατάσταση FSRM
Install-WindowsFeature FS-Resource-Manager -IncludeManagementTools

# Δημιουργία quota template (soft = προειδοποίηση, δεν μπλοκάρει)
New-FsrmQuotaTemplate -Name "Department-Soft-100GB" -Size 100GB -SoftLimit

# Εφαρμογή στο folder
New-FsrmQuota -Path "E:\Shares\Marketing" -Template "Department-Soft-100GB"

# File Screening - block ανεπιθύμητων τύπων αρχείων (π.χ. .mp3, .exe σε shared drives)
New-FsrmFileGroup -Name "Blocked-Media-Files" -IncludePattern "*.mp3","*.mp4","*.avi","*.exe"
New-FsrmFileScreen -Path "E:\Shares\Marketing" -IncludeGroup "Blocked-Media-Files" -Active

# Alert όταν πλησιάζει το quota - notification στον IT team
Set-FsrmQuotaTemplate -Name "Department-Soft-100GB" -Threshold @(
    New-FsrmQuotaThreshold -Percentage 85 -MailTo "it-alerts@company.local"
)
```

> 💡 **Πραγματικό σενάριο:** Χωρίς quotas, κάποιος στο Marketing ανεβάζει 200GB video assets σε shared drive που προοριζόταν για Excel/Word docs, ο δίσκος γεμίζει, και **ολόκληρος ο file server** σταματάει να δουλεύει για όλα τα departments. Αυτό συμβαίνει συχνότερα απ' όσο νομίζεις.

---

## ✅ 9. Φάση 8: Testing & Verification

Πριν πεις "done" στο ticket, **πάντα** ελέγχεις με πραγματικό test account, όχι μόνο θεωρητικά:

```powershell
# 1. Επαλήθευση ACL από το server
icacls "E:\Shares\Marketing"
icacls "E:\Shares\Marketing\Campaigns-2026"

# 2. Επαλήθευση group membership (recursive - βλέπε file-permissions-ntfs.md §9)
Get-ADPrincipalGroupMembership -Identity "ext.jfreelancer" | Select Name

# 3. Force replication αν μόλις έγιναν αλλαγές σε multi-DC περιβάλλον
repadmin /syncall /AdeP

# 4. ΠΑΝΤΑ κάνε πραγματικό test logon:
#    - Σαν "κανονικό" Marketing member: μπορεί modify, ΔΕΝ μπορεί delete
#    - Σαν Team Lead: μπορεί delete
#    - Σαν freelancer: βλέπει ΜΟΝΟ το Campaigns-2026, τίποτα άλλο
```

**Testing checklist ερωτήσεις που κάνεις πάντα:**

| Test | Αναμενόμενο αποτέλεσμα |
|---|---|
| Marketing member ανοίγει το share | ✅ Βλέπει root + subfolder |
| Marketing member προσπαθεί delete αρχείου | ❌ Access Denied |
| Team Lead προσπαθεί delete αρχείου | ✅ Επιτρέπεται |
| Freelancer προσπαθεί να δει `\Marketing\` root | ❌ Access Denied (βλέπει μόνο Campaigns-2026) |
| Non-Marketing employee | ❌ Δεν βλέπει καν το share |
| Νέο μέλος προστίθεται στο group, κάνει logon χωρίς logoff | ⚠️ Πιθανό να ΜΗΝ δουλέψει άμεσα (παλιό Kerberos ticket) — χρειάζεται νέο logon |

---

## 📝 10. Φάση 9: Documentation & Handover

Σε πραγματική εταιρεία, **αν δεν το τεκμηρίωσες, δεν έγινε** — ο επόμενος που θα δουλέψει πάνω σε αυτό (ίσως ο εαυτός σου σε 8 μήνες) πρέπει να καταλάβει τι υπάρχει χωρίς να ξανα-ανακαλύψει τα πάντα.

**Τυπικό documentation entry (π.χ. σε Confluence/SharePoint wiki):**

```markdown
## Marketing Share - E:\Shares\Marketing (FS01)

**Δημιουργήθηκε:** 2026-09-23 από D.Katsanos, Ticket #4521
**Path:** \\FS01\Marketing (και \\company.local\Departments\Marketing μέσω DFS)
**Owner department:** Marketing

### Permission Groups
| Group | Access | Μέλη |
|---|---|---|
| ATH-Marketing-Share-Modify | Modify (χωρίς delete) | Marketing-Team (Global Group) |
| ATH-Marketing-Share-FullControl | Full Control | Marketing-TeamLeads |
| ATH-Marketing-Campaigns2026-Read | Read-only, μόνο στο /Campaigns-2026 | ext.jfreelancer (expires 2026-12-23) |

### Ειδικά σημεία προσοχής
- Ο freelancer λογαριασμός λήγει 2026-12-23 — χρειάζεται renewal request αν συνεχιστεί η συνεργασία
- Quota: 100GB soft limit, alert στο 85% → it-alerts@company.local
- File screening: μπλοκαρισμένα media files (.mp3/.mp4/.avi/.exe)
```

> 💡 Αυτό το documentation entry είναι αυτό που θα σε σώσει σε 6 μήνες όταν κάποιος ρωτήσει "γιατί έχει πρόσβαση αυτός ο freelancer" — δεν χρειάζεται να ψάχνεις logs, το βλέπεις αμέσως.

---

## 🔄 11. Το Καθημερινό Workflow — Change Requests

Έτσι μοιάζει η **καθημερινή** δουλειά μετά το αρχικό setup — δεν ξαναφτιάχνεις permissions από το μηδέν, διαχειρίζεσαι αλλαγές:

```
1. Request φτάνει (ticket/email/Slack)
   "Πρόσθεσε τη Μαρία στο Marketing share"

2. Verification
   → Είναι η Μαρία πράγματι Marketing employee; (έλεγχος με manager/HR αν χρειάζεται approval)
   → Ποιο ακριβώς επίπεδο πρόσβασης χρειάζεται; (member ή lead;)

3. Εκτέλεση - ΠΑΝΤΑ μέσω group membership, ΠΟΤΕ απευθείας στο ACL
   Add-ADGroupMember -Identity "ATH-Marketing-Share-Modify" -Members "m.papadaki"

4. Documentation update
   → Ενημέρωση του wiki entry (ή αν έχεις IAM/ticketing system με audit trail, αυτό γίνεται αυτόματα)

5. Confirmation στον requester
   → "Η Μαρία έχει πλέον πρόσβαση, θα χρειαστεί logoff/logon για να ενεργοποιηθεί"
```

> ⚠️ **Ο #1 κανόνας σε πραγματική δουλειά:** Ποτέ μην προσθέτεις permission απευθείας πάνω στο file/folder ACL για μεμονωμένο χρήστη "για να κάνεις γρήγορα". Αυτό είναι το πράγμα που σε 2 χρόνια κανείς δεν θυμάται γιατί υπάρχει, δεν εμφανίζεται πουθενά στα groups, και κάνει κάθε security audit εφιάλτη. Πάντα μέσω group membership.

---

## 💻 12. Πλήρες PowerShell Script — Όλο το Project σε Ένα

Έτσι μοιάζει ένα πραγματικό deployment script που θα έγραφες/χρησιμοποιούσες σε production (με comments, ώστε να είναι reusable και για το επόμενο department):

```powershell
<#
.SYNOPSIS
    Δημιουργεί νέο department file share με σωστή δομή groups/permissions.
.NOTES
    Ticket: #4521 | Author: D.Katsanos | Date: 2026-09-23
#>

param(
    [string]$DeptName = "Marketing",
    [string]$SharePath = "E:\Shares\Marketing",
    [string]$OUPath = "OU=FileShareGroups,DC=company,DC=local",
    [string]$Domain = "COMPANY"
)

# 1. AD Groups
$groups = @(
    @{Name="ATH-$DeptName-Share-Modify"; Desc="Modify access - no delete"},
    @{Name="ATH-$DeptName-Share-FullControl"; Desc="Full Control - team leads"}
)
foreach ($g in $groups) {
    if (-not (Get-ADGroup -Filter "Name -eq '$($g.Name)'")) {
        New-ADGroup -Name $g.Name -GroupScope DomainLocal -GroupCategory Security `
            -Path $OUPath -Description $g.Desc
        Write-Host "✅ Δημιουργήθηκε group: $($g.Name)"
    } else {
        Write-Host "⏭️  Το group υπάρχει ήδη: $($g.Name)"
    }
}

# 2. Folder structure
if (-not (Test-Path $SharePath)) {
    New-Item -Path $SharePath -ItemType Directory | Out-Null
    Write-Host "✅ Δημιουργήθηκε folder: $SharePath"
}

# 3. NTFS Permissions
$acl = Get-Acl $SharePath
$acl.SetAccessRuleProtection($true, $false)
$rules = @(
    New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administrators","FullControl","ContainerInherit,ObjectInherit","None","Allow"),
    New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\SYSTEM","FullControl","ContainerInherit,ObjectInherit","None","Allow"),
    New-Object System.Security.AccessControl.FileSystemAccessRule("$Domain\ATH-$DeptName-Share-Modify","Modify","ContainerInherit,ObjectInherit","None","Allow"),
    New-Object System.Security.AccessControl.FileSystemAccessRule("$Domain\ATH-$DeptName-Share-FullControl","FullControl","ContainerInherit,ObjectInherit","None","Allow")
)
foreach ($rule in $rules) { $acl.AddAccessRule($rule) }
Set-Acl $SharePath $acl
Write-Host "✅ NTFS permissions εφαρμόστηκαν"

# 4. SMB Share
if (-not (Get-SmbShare -Name $DeptName -ErrorAction SilentlyContinue)) {
    New-SmbShare -Name $DeptName -Path $SharePath -ChangeAccess "Authenticated Users" | Out-Null
    Write-Host "✅ Share δημιουργήθηκε: \\$env:COMPUTERNAME\$DeptName"
}

# 5. Backup της νέας ACL για future reference
icacls $SharePath /save "$env:USERPROFILE\Desktop\$DeptName`_acl_$(Get-Date -Format 'yyyyMMdd').txt" /t

Write-Host "`n🎉 Deployment ολοκληρώθηκε για: $DeptName"
Write-Host "Επόμενο βήμα: πρόσθεσε μέλη με Add-ADGroupMember, μετά test logon."
```

---

## ⚠️ 13. Πραγματικά Λάθη που Βλέπεις σε Εταιρείες

| Λάθος | Γιατί συμβαίνει | Πραγματική επίπτωση |
|---|---|---|
| Permission δίνεται απευθείας σε user, όχι σε group | "Θα το φτιάξω σωστά μετά" (ποτέ δεν γίνεται) | Audit εφιάλτης, κανείς δεν ξέρει ποιος έχει πρόσβαση σε τι |
| `Everyone: Full Control` σε NTFS "για να δουλέψει γρήγορα" | Πίεση χρόνου, "θα το φτιάξω μετά" | Ολόκληρη εταιρεία βλέπει ευαίσθητα δεδομένα |
| Δεν υπάρχει naming convention | Ξεκίνησε μικρή εταιρεία, δεν χρειαζόταν τότε | 5 χρόνια μετά: 200 groups, κανείς δεν ξέρει τι κάνουν |
| Freelancer/external accounts χωρίς expiration date | Ξεχνιέται στο rush του onboarding | Ghost accounts, security risk σε κάθε audit |
| Καμία τεκμηρίωση | "Θα το θυμάμαι" | Ο επόμενος (ή ο ίδιος σε 8 μήνες) ξαναχτίζει τα πάντα από την αρχή |
| Deny χρησιμοποιείται αντί για σωστό group redesign | Γρήγορη "patch" λύση | Deny σε λάθος σημείο μπλοκάρει legitimate access, δύσκολο να εντοπιστεί γιατί |
| Δεν γίνεται test με πραγματικό test account | "Φαίνεται σωστό στο ACL" | Permission bugs ανακαλύπτονται από τον χρήστη, όχι από εσένα |

---

## ✅ 14. Checklist — Go-Live

```
☐ AD Groups δημιουργήθηκαν με σωστό naming convention
☐ Groups περιέχουν τα σωστά μέλη (μέσω AGDLP, όχι direct user permissions)
☐ Folder structure δημιουργήθηκε στο σωστό volume/path
☐ Inheritance διακόπηκε όπου χρειάζεται (π.χ. sensitive subfolders)
☐ NTFS permissions εφαρμόστηκαν σωστά (Administrators/SYSTEM πάντα παρόντα)
☐ Share δημιουργήθηκε, Share permissions = ανοιχτά (Authenticated Users)
☐ DFS target προστέθηκε (αν η εταιρεία χρησιμοποιεί DFS)
☐ Quota template εφαρμόστηκε
☐ File screening ενεργό (αν χρειάζεται)
☐ Backup ACL export έγινε (icacls /save)
☐ Testing με πραγματικό test account ολοκληρώθηκε (όλα τα scenarios του §9)
☐ Documentation γράφτηκε (wiki/Confluence entry)
☐ Requester ενημερώθηκε ότι είναι έτοιμο
☐ Ticket κλείνει με reference στο documentation entry
```

---

## 📚 Σχετικά αρχεία

- [`active-directory.md`](./active-directory.md) — Users/Groups, OUs, GPO, Entra ID
- [`active-directory-advanced.md`](./active-directory-advanced.md) — FSMO, Replication, Trusts, Security Tiering
- [`file-permissions-ntfs.md`](./file-permissions-ntfs.md) — Θεωρία: NTFS/Share permissions, effective access, inheritance
- Αυτό το αρχείο (`file-server-implementation-runbook.md`) — Real-world end-to-end υλοποίηση, σαν πραγματικό project
