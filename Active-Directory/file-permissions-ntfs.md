# 📂 NTFS & Share Permissions — File System Security Deep Dive
> Συνοδευτικό αρχείο στο [`active-directory.md`](./active-directory.md) — καλύπτει πώς το Windows filesystem (NTFS) συνδυάζεται με το AD για να αποφασίσει ποιος βλέπει τι σε ένα file server.
> Είναι από τα πιο συχνά ερωτήματα σε Helpdesk/Junior Sysadmin συνεντεύξεις: **"Ο χρήστης βλέπει το φάκελο αλλά δεν μπορεί να ανοίξει τα αρχεία — γιατί;"**

---

## 🗺️ Πίνακας Περιεχομένων

1. [Filesystems σε Windows — NTFS vs ReFS vs FAT32](#-1-filesystems-σε-windows--ntfs-vs-refs-vs-fat32)
2. [NTFS Permissions — Βασικά](#-2-ntfs-permissions--βασικά)
3. [Share Permissions vs NTFS Permissions](#-3-share-permissions-vs-ntfs-permissions)
4. [Πώς Υπολογίζεται το Effective Permission — Βήμα προς Βήμα](#-4-πώς-υπολογίζεται-το-effective-permission--βήμα-προς-βήμα)
5. [Inheritance & Propagation](#-5-inheritance--propagation)
6. [Ownership](#-6-ownership)
7. [ACL Internals — DACL, SACL, ACE](#-7-acl-internals--dacl-sacl-ace)
8. [PowerShell & CLI Εργαλεία](#-8-powershell--cli-εργαλεία)
9. [Σύνδεση με AD Groups — Το Μοντέλο AGDLP](#-9-σύνδεση-με-ad-groups--το-μοντέλο-agdlp)
10. [Auditing Πρόσβασης](#-10-auditing-πρόσβασης)
11. [Troubleshooting](#-11-troubleshooting)

---

## 💾 1. Filesystems σε Windows — NTFS vs ReFS vs FAT32

| Filesystem | Υποστηρίζει Permissions; | Typical χρήση |
|---|---|---|
| **NTFS** | ✅ Πλήρες ACL model | Default για system drives, file servers |
| **ReFS** | ✅ (πιο περιορισμένο σε κάποια features) | Storage Spaces, μεγάλα data volumes |
| **FAT32 / exFAT** | ❌ Καθόλου permissions στο επίπεδο αρχείου | USB sticks, συμβατότητα με άλλα OS |

> 💡 Αν ένας φάκελος είναι σε FAT32/exFAT δίσκο (π.χ. εξωτερικός σκληρός), **δεν υπάρχει καθόλου NTFS security tab** — ο,τιδήποτε έχει πρόσβαση στο δίσκο βλέπει τα πάντα. Αυτό είναι συχνή παγίδα σε ερωτήσεις συνέντευξης.

Το NTFS είναι αυτό που δίνει στο Windows τη δυνατότητα για **Access Control Lists (ACLs)** — δηλαδή λίστες που λένε "ποιος μπορεί να κάνει τι" πάνω σε κάθε αρχείο/φάκελο.

---

## 🔐 2. NTFS Permissions — Βασικά

### Standard Permissions

| Permission | Τι επιτρέπει |
|---|---|
| **Full Control** | Όλα τα παρακάτω + αλλαγή permissions + take ownership |
| **Modify** | Read + Write + Delete (αλλά όχι αλλαγή permissions) |
| **Read & Execute** | Read περιεχομένου + εκτέλεση προγραμμάτων |
| **List Folder Contents** | Μόνο σε φακέλους — βλέπει τα ονόματα μέσα |
| **Read** | Άνοιγμα/προβολή αρχείου, χωρίς αλλαγή |
| **Write** | Δημιουργία νέων αρχείων/φακέλων, αλλαγή attributes |

### Allow vs Deny

```
Allow  → Δίνει το δικαίωμα (προσθετικό — αν έχεις Allow από πολλά σημεία, αθροίζονται)
Deny   → Αφαιρεί ρητά το δικαίωμα (κερδίζει ΠΑΝΤΑ έναντι οποιουδήποτε Allow)
```

> ⚠️ **Κανόνας #1 που πρέπει να θυμάσαι:** Ένα **Deny** — έστω και από μία μόνο ομάδα στην οποία ανήκει ο χρήστης — υπερισχύει όλων των Allow, ανεξαρτήτως πόσα Allow υπάρχουν από αλλού. Γι' αυτό η καλή πρακτική είναι να **αποφεύγεις το Deny** όποτε γίνεται και να βασίζεσαι σε σωστό group design αντί για "patches" με Deny.

### Special Permissions (πίσω από τα Standard)

Κάθε Standard permission είναι στην ουσία ένα "bundle" από πιο λεπτομερή **Special Permissions** (π.χ. Traverse Folder, Read Attributes, Create Files, Delete Subfolders and Files, Change Permissions, Take Ownership). Τα βλέπεις πατώντας **Advanced** στο Security tab. Στην καθημερινή δουλειά σπάνια χρειάζεσαι να πειράξεις special permissions ξεχωριστά — αλλά είναι χρήσιμο να ξέρεις ότι υπάρχουν, για advanced troubleshooting.

---

## 🌐 3. Share Permissions vs NTFS Permissions

Αυτό είναι το πιο συχνό σημείο σύγχυσης. Υπάρχουν **δύο ξεχωριστά** επίπεδα permissions όταν κάποιος προσπελαύνει ένα αρχείο **μέσω δικτύου** (`\\server\share`):

| | Share Permissions | NTFS Permissions |
|---|---|---|
| **Πού εφαρμόζονται** | Μόνο στο "πόρτα εισόδου" — το network share | Στο ίδιο το filesystem, σε κάθε αρχείο/φάκελο |
| **Ισχύουν όταν...** | Ο χρήστης έρχεται **μέσω δικτύου** (`\\server\share`) | Πάντα — είτε τοπικά (local logon) είτε μέσω δικτύου |
| **Λεπτομέρεια** | Πιο "χοντροκομμένα" (Full Control, Change, Read) | Πολύ πιο λεπτομερή (standard + special permissions) |
| **Best practice** | Άφησε το σε **Everyone = Full Control** | Έλεγξε την πρόσβαση **εδώ**, με groups |

```
Local Access (κάθισμα μπροστά στο server)
    └── Ελέγχεται ΜΟΝΟ από NTFS permissions

Network Access (\\server\share)
    └── Ελέγχεται από Share permissions ΚΑΙ NTFS permissions
        → Κερδίζει το πιο ΑΥΣΤΗΡΟ (most restrictive) από τα δύο
```

> 💡 **Γιατί η best practice λέει "Share = Everyone Full Control";** Επειδή αν βάλεις περιορισμούς και στα δύο επίπεδα, γίνεται δύσκολο να θυμάσαι/διαχειρίζεσαι δύο ξεχωριστά συστήματα permissions. Βάζοντας το share ανοιχτό και ελέγχοντας τα πάντα στο NTFS επίπεδο, έχεις **ένα** σημείο αλήθειας — ό,τι φαίνεται στο Security tab, αυτό ισχύει.

---

## 🧮 4. Πώς Υπολογίζεται το Effective Permission — Βήμα προς Βήμα

Όταν ο χρήστης `d.katsanos` προσπαθεί να ανοίξει `\\FS01\Finance\budget.xlsx`, το Windows ακολουθεί αυτή τη σειρά:

```
ΒΗΜΑ 1 — Ταυτοποίηση (Authentication)
    Ο χρήστης έχει ήδη πιστοποιηθεί στο domain (Kerberos ticket)
    Το ticket περιέχει όλα τα groups στα οποία ανήκει (SID history)

ΒΗΜΑ 2 — Έλεγχος Share Permission
    Ελέγχεται: ποιο permission έχει ο χρήστης (ή τα groups του) πάνω στο SHARE "Finance"
    → Αν βρεθεί DENY σε οποιοδήποτε group → STOP, πρόσβαση αρνείται
    → Αλλιώς: υπολογίζεται το άθροισμα (union) όλων των ALLOW από όλα τα groups
    Αποτέλεσμα: effective SHARE permission (π.χ. "Change")

ΒΗΜΑ 3 — Έλεγχος NTFS Permission
    Ελέγχεται η ACL πάνω στο ίδιο το αρχείο/φάκελο budget.xlsx
    → Ξεκινά από explicit (ρητές) καταχωρήσεις πάνω στο ίδιο το αρχείο
    → Μετά προστίθενται inherited (κληρονομημένες) καταχωρήσεις από parent folders
    → DENY (explicit ή inherited) υπερισχύει πάντα οποιουδήποτε ALLOW
    → Αλλιώς: υπολογίζεται το άθροισμα (union) όλων των ALLOW από όλα τα groups
    Αποτέλεσμα: effective NTFS permission (π.χ. "Modify")

ΒΗΜΑ 4 — Συνδυασμός (μόνο για network access)
    effective permission = MIN(effective SHARE permission, effective NTFS permission)
    δηλαδή κερδίζει το πιο περιοριστικό από τα δύο

Παράδειγμα:
    Share permission  = Change (Read + Write + Delete, όχι permissions management)
    NTFS permission    = Read (μόνο ανάγνωση)
    ────────────────────────────────────────
    Effective result   = Read   (το πιο αυστηρό κερδίζει)
```

### Κανόνες προτεραιότητας — Σύνοψη

| Κανόνας | Εξήγηση |
|---|---|
| 1️⃣ Explicit Deny > Explicit Allow | Ρητή άρνηση πάντα κερδίζει ρητή αποδοχή |
| 2️⃣ Explicit > Inherited | Ό,τι έχεις ορίσει απευθείας πάνω στο αντικείμενο υπερισχύει αυτού που κληρονόμησε |
| 3️⃣ Inherited Deny > Inherited Allow | Ακόμα και κληρονομημένο, το Deny κερδίζει το Allow αν είναι στο ίδιο "επίπεδο" (και τα δύο inherited) |
| 4️⃣ Πολλαπλά Allow από διαφορετικά groups | Αθροίζονται (union) — ο χρήστης παίρνει το πιο "γενναιόδωρο" συνδυασμό |
| 5️⃣ Share + NTFS (μόνο δικτυακή πρόσβαση) | Κερδίζει το πιο περιοριστικό (intersection, όχι union) |

---

## 🌲 5. Inheritance & Propagation

Από default, ένας νέος φάκελος/αρχείο **κληρονομεί** τα permissions του parent folder. Αυτό φαίνεται στο Advanced Security Settings ως "Inherited from...".

```
D:\Shares\Finance                    (Allow: Finance-Users → Modify)
    ├── Budgets\                     (κληρονομεί: Finance-Users → Modify)
    │     └── budget.xlsx            (κληρονομεί: Finance-Users → Modify)
    └── Payroll\                     (Inheritance ΔΙΑΚΟΠΤΕΤΑΙ εδώ)
          └── (νέο explicit permission: μόνο Payroll-Admins → Full Control)
```

- **Disable Inheritance:** Σταματάς την αυτόματη κληρονομιά σε ένα σημείο. Το Windows σου ρωτάει αν θες να **"Convert"** (τα κληρονομημένα γίνονται explicit, μένουν όπως ήταν) ή **"Remove"** (τα σβήνει όλα, μένεις με καθαρό φύλλο).
- **Propagation:** Όταν αλλάζεις permission σε parent folder, μπορείς να επιλέξεις αν θα **εφαρμοστεί σε όλα τα subfolders/files** ("Replace all child object permissions") ή όχι.

> ⚠️ Το "Replace all child object permissions" είναι επικίνδυνο σε μεγάλα file shares — σβήνει **όλα** τα explicit permissions που έχουν οριστεί πιο "βαθιά". Πάντα κάνε export της υπάρχουσας ACL πριν (`icacls ... /save`) πριν κάνεις μαζική αλλαγή.

---

## 👤 6. Ownership

Κάθε αρχείο/φάκελο έχει έναν **Owner** — ο owner έχει πάντα το δικαίωμα να αλλάξει permissions, ακόμα κι αν δεν έχει ρητό Full Control στην ACL.

```powershell
# Ποιος είναι owner
Get-Acl "D:\Shares\Finance\budget.xlsx" | Select Owner

# Αλλαγή owner (χρειάζεται SeTakeOwnership δικαίωμα ή admin)
$acl = Get-Acl "D:\Shares\Finance\budget.xlsx"
$acl.SetOwner([System.Security.Principal.NTAccount]"COMPANY\d.katsanos")
Set-Acl "D:\Shares\Finance\budget.xlsx" $acl
```

> 💡 Κλασικό σενάριο: ένας χρήστης "κλειδώνει" ένα αρχείο (π.χ. έφυγε από την εταιρεία, ο λογαριασμός του disabled) και κανείς δεν μπορεί πλέον να αλλάξει permissions πάνω του. Λύση: **Take Ownership** ως Domain Admin, μετά διόρθωση της ACL κανονικά.

---

## 🧩 7. ACL Internals — DACL, SACL, ACE

Για πιο βαθιά κατανόηση (χρήσιμο σε advanced troubleshooting/scripting):

| Όρος | Τι είναι |
|---|---|
| **ACL** (Access Control List) | Η συνολική λίστα δικαιωμάτων πάνω σε ένα object |
| **DACL** (Discretionary ACL) | Το "who can do what" — αυτό βλέπεις στο Security tab |
| **SACL** (System ACL) | Το "τι θα καταγραφεί" — χρησιμοποιείται για auditing, όχι permissions |
| **ACE** (Access Control Entry) | Μία γραμμή μέσα στην DACL/SACL — ένα group/user + permission + Allow/Deny |

```
DACL του budget.xlsx:
  ACE 1: Allow  Finance-Users     Modify
  ACE 2: Allow  IT-Admins         Full Control
  ACE 3: Deny   Contractors       Full Control   ← explicit deny, κερδίζει ό,τι Allow υπάρχει
```

---

## 💻 8. PowerShell & CLI Εργαλεία

```powershell
# ====== Προβολή permissions ======

# Βασική προβολή ACL
Get-Acl "D:\Shares\Finance" | Format-List

# Πιο αναλυτική προβολή (κάθε ACE ξεχωριστά)
(Get-Acl "D:\Shares\Finance").Access | Format-Table IdentityReference, FileSystemRights, AccessControlType, IsInherited

# ====== Αλλαγή permissions με PowerShell ======

$path = "D:\Shares\Finance\Payroll"
$acl = Get-Acl $path
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "COMPANY\Payroll-Admins", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow"
)
$acl.SetAccessRule($rule)
Set-Acl $path $acl

# ====== icacls — πιο γρήγορο για scripting/bulk εργασίες ======

# Προβολή
icacls "D:\Shares\Finance"

# Προσθήκη δικαιώματος (M = Modify, F = Full, RX = Read&Execute)
icacls "D:\Shares\Finance\Payroll" /grant "COMPANY\Payroll-Admins:(OI)(CI)M"

# Αφαίρεση δικαιώματος
icacls "D:\Shares\Finance\Payroll" /remove "COMPANY\Contractors"

# Backup ACL πριν από μαζική αλλαγή (ΠΑΝΤΑ πριν)
icacls "D:\Shares\Finance" /save finance_acl_backup.txt /t

# Restore από backup
icacls "D:\Shares\Finance" /restore finance_acl_backup.txt

# Reset σε default inherited permissions (καθαρισμός "χαλασμένων" ACLs)
icacls "D:\Shares\Finance\Payroll" /reset /t /c

# ====== Share permissions (ξεχωριστά από NTFS) ======

Get-SmbShareAccess -Name "Finance"
Grant-SmbShareAccess -Name "Finance" -AccountName "COMPANY\Finance-Users" -AccessRight Change
```

---

## 🔗 9. Σύνδεση με AD Groups — Το Μοντέλο AGDLP

Όπως αναφέρεται στο [`active-directory.md`](./active-directory.md#-3-διαχείριση-users--groups), η σωστή πρακτική **δεν** είναι να δίνεις NTFS permissions απευθείας σε individual users, αλλά να ακολουθείς το **AGDLP** μοντέλο:

```
Accounts  →  Global Groups  →  Domain Local Groups  →  NTFS Permission

Παράδειγμα πλήρους chain:
  d.katsanos  (user)
      └── μέλος του "Finance-Team" (Global Group)
              └── "Finance-Team" είναι μέλος του "FinanceShare-Modify" (Domain Local Group)
                      └── Το "FinanceShare-Modify" έχει Allow: Modify πάνω στο D:\Shares\Finance
```

**Γιατί αυτό το layering;**
- Αλλάζεις ποιος έχει πρόσβαση **μία φορά** (προσθήκη/αφαίρεση από το Global Group), όχι σε κάθε file server ξεχωριστά.
- Το Domain Local Group ("FinanceShare-Modify") μένει σταθερό πάνω στο ACL — δεν χρειάζεται ποτέ να ξαναγγίξεις το ίδιο το security tab του φακέλου.
- Ονοματολογία `<Resource>-<PermissionLevel>` (π.χ. `FinanceShare-Modify`, `FinanceShare-ReadOnly`) κάνει το audit πολύ πιο εύκολο — βλέπεις αμέσως τι κάνει κάθε group.

> 🔬 **Lab:** Φτιάξε δομή `Finance-Team` (Global) → `FinanceShare-Modify` (Domain Local) → Allow Modify σε test φάκελο. Πρόσθεσε test user, κάνε logon, επαλήθευσε effective access με `Get-Acl` και με το tab **Effective Access** στο Advanced Security Settings (GUI).

---

## 🕵️ 10. Auditing Πρόσβασης

Το **SACL** (§7) επιτρέπει καταγραφή του **ποιος έκανε τι** πάνω σε ένα αρχείο — κρίσιμο για compliance (π.χ. GDPR) και forensics μετά από incident.

```powershell
# Βήμα 1: Ενεργοποίηση object access auditing μέσω GPO (ή τοπικά)
# Computer Configuration → Windows Settings → Security Settings →
#   Advanced Audit Policy Configuration → Object Access → Audit File System (Success/Failure)

# Βήμα 2: Ορισμός SACL πάνω στο συγκεκριμένο folder (GUI)
# Security tab → Advanced → Auditing tab → Add → επίλεξε group/user + ποια ενέργεια (π.χ. Delete)

# Βήμα 3: Ανάγνωση των events
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4663} -MaxEvents 50 |
    Select TimeCreated, Message
```

| Event ID | Σημασία |
|---|---|
| **4663** | Προσπάθεια πρόσβασης σε object (το πιο χρήσιμο για "ποιος άνοιξε/έσβησε αυτό το αρχείο") |
| **4656** | Handle σε object ζητήθηκε |
| **4670** | Άλλαξαν τα permissions ενός object |

> ⚠️ Auditing σε ολόκληρο file server με πολλά TBs δεδομένων μπορεί να δημιουργήσει τεράστιο όγκο logs — στόχευσε auditing μόνο σε ευαίσθητους φακέλους (π.χ. Payroll, HR), όχι σε ολόκληρο share.

---

## 🔧 11. Troubleshooting

| Πρόβλημα | Πιθανή Αιτία | Λύση |
|---|---|---|
| Ο χρήστης βλέπει το share αλλά "Access Denied" στα αρχεία | Share permission OK, αλλά NTFS permission πιο αυστηρό (§4) | Έλεγξε NTFS ACL με `Get-Acl` ή Advanced Security Settings |
| Ο χρήστης δεν βλέπει καν το share | Share permission = καμία πρόσβαση, ή Deny σε κάποιο group | `Get-SmbShareAccess`, έλεγξε group membership του χρήστη |
| "Access Denied" παρόλο που το group φαίνεται σωστό στην ACL | Παλιό Kerberos token — δεν έχει ανανεωθεί μετά την προσθήκη σε group | Log off/on, ή `klist purge` για refresh του ticket |
| Δεν μπορείς να αλλάξεις permissions σε αρχείο | Δεν είσαι owner, δεν έχεις Full Control | Take Ownership πρώτα (§6), μετά άλλαξε ACL |
| Permissions "κολλημένα" μετά από μαζική αλλαγή | Inheritance disabled σε ενδιάμεσο φάκελο | Advanced Security Settings → έλεγξε πού διακόπτεται η κληρονομιά |
| Effective Access tab δείχνει διαφορετικό αποτέλεσμα από ό,τι περιμένεις | Nested group membership δεν υπολογίστηκε σωστά | `Get-ADPrincipalGroupMembership` στον χρήστη για πλήρη recursive λίστα |

```powershell
# Γρήγορος έλεγχος: ποια effective NTFS δικαιώματα έχει συγκεκριμένος χρήστης σε φάκελο
# (χρειάζεται RSAT / SecurityCmdlets ή χρήση του GUI: Advanced → Effective Access tab)

# Εναλλακτικά μέσω icacls για γρήγορο οπτικό έλεγχο
icacls "D:\Shares\Finance\Payroll"

# Έλεγχος σε ποια groups ανήκει πραγματικά ο χρήστης (recursive, μαζί με nested)
Get-ADPrincipalGroupMembership -Identity "d.katsanos" | Select Name
```

> 🔬 **Lab:** Δημιούργησε δύο test groups — ένα με Allow Modify, ένα με Deny Full Control στο ίδιο φάκελο. Πρόσθεσε τον ίδιο test user και στα δύο. Επαλήθευσε ότι κερδίζει το Deny (§4, κανόνας 1). Μετά αφαίρεσε το Deny group και επιβεβαίωσε ότι επιστρέφει η κανονική πρόσβαση.

---

## 📚 Σχετικά αρχεία

- [`active-directory.md`](./active-directory.md) — Βασικά: Users/Groups, OUs, GPO, Entra ID, PowerShell 101
- [`active-directory-advanced.md`](./active-directory-advanced.md) — FSMO, Replication, Trusts, DNS, Security Tiering, Backup/Restore
- Αυτό το αρχείο (`file-permissions-ntfs.md`) — NTFS/Share permissions, effective access, inheritance, ownership, auditing
