# ⚙️ Group Policy (GPO) — Deep Dive & Real-World Runbook
> Συνοδευτικό αρχείο στη σειρά Active Directory. Το GPO είναι το εργαλείο με το οποίο **επιβάλλεις config σε χιλιάδες μηχανήματα ταυτόχρονα** — από password policy μέχρι drive mappings και software deployment. Είναι το πιο "καθημερινό" εργαλείο ενός sysadmin μετά τα βασικά AD objects.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Τι Είναι Πραγματικά ένα GPO](#-1-τι-είναι-πραγματικά-ένα-gpo)
2. [Processing Order — LSDOU](#-2-processing-order--lsdou)
3. [Computer vs User Configuration](#-3-computer-vs-user-configuration)
4. [Σενάριο — Το Ticket](#-4-σενάριο--το-ticket)
5. [Runbook #1: Password Policy μέσω Fine-Grained Password Policies](#-5-runbook-1-password-policy-μέσω-fine-grained-password-policies)
6. [Runbook #2: Αυτόματο Drive Mapping](#-6-runbook-2-αυτόματο-drive-mapping)
7. [Runbook #3: Αυτόματη Εγκατάσταση Εκτυπωτή](#-7-runbook-3-αυτόματη-εγκατάσταση-εκτυπωτή)
8. [Security Filtering & WMI Filtering](#-8-security-filtering--wmi-filtering)
9. [Loopback Processing](#-9-loopback-processing)
10. [Central Store για ADMX Templates](#-10-central-store-για-admx-templates)
11. [Testing — RSOP & gpresult](#-11-testing--rsop--gpresult)
12. [Backup, Restore & Version Control](#-12-backup-restore--version-control)
13. [Troubleshooting](#-13-troubleshooting)
14. [Checklist — Πριν Κάνεις Deploy](#-14-checklist--πριν-κάνεις-deploy)

---

## 🧩 1. Τι Είναι Πραγματικά ένα GPO

Ένα **Group Policy Object** είναι ένα σύνολο ρυθμίσεων που:
1. **Δημιουργείται** μία φορά στο AD (αποθηκεύεται στο SYSVOL + AD database)
2. **Συνδέεται** (link) σε ένα ή περισσότερα containers: **Site, Domain, ή OU**
3. **Εφαρμόζεται** αυτόματα σε κάθε computer/user object μέσα σε αυτό το container, την επόμενη φορά που γίνεται refresh

```
GPO "Marketing-Printers"  (το ίδιο object)
    │
    ├── Linked στο OU "Marketing"        → εφαρμόζεται σε όλα τα Marketing computers
    └── Linked στο OU "Marketing-Laptops" → εφαρμόζεται ΚΑΙ εδώ (μπορείς να το κάνεις link πολλές φορές)
```

> 💡 Ένα GPO δεν "ζει" μέσα σε ένα OU — ζει ανεξάρτητα, και το OU απλά έχει έναν **σύνδεσμο (link)** προς αυτό. Αυτό σημαίνει ότι μπορείς να αλλάξεις το GPO μία φορά, και η αλλαγή διαδίδεται αυτόματα σε όλα τα σημεία όπου είναι linked.

---

## 🔢 2. Processing Order — LSDOU

Όταν ένα computer/user object ανήκει σε πολλαπλά GPOs (κάτι πολύ συνηθισμένο), η σειρά εφαρμογής είναι κρίσιμη — το **τελευταίο που εφαρμόζεται "κερδίζει"** σε περίπτωση conflict:

```
L → Local Group Policy (πάνω στο ίδιο το μηχάνημα)
S → Site-linked GPOs
D → Domain-linked GPOs
O → OU-linked GPOs (από το πιο "έξω" OU προς το πιο "μέσα")

Παράδειγμα:
DC=company,DC=local
  └── OU=Athens
        └── OU=Marketing
              └── OU=Marketing-Laptops
                    └── PC-MKT-042 (το μηχάνημα)

Σειρά εφαρμογής: Local → Site → Domain → Athens → Marketing → Marketing-Laptops
                                                                        ↑
                                                          Αυτό "κερδίζει" σε conflict
```

| Επιλογή | Τι κάνει |
|---|---|
| **Block Inheritance** | Σε ένα OU, μπλοκάρει GPOs από πιο πάνω (δεν εφαρμόζονται τα "γονικά") |
| **Enforced** (πρώην "No Override") | Ένα GPO με Enforced **δεν μπορεί να μπλοκαριστεί**, ούτε με Block Inheritance — κερδίζει πάντα |

```powershell
# Block inheritance σε ένα OU
Set-GPInheritance -Target "OU=Marketing-Laptops,OU=Marketing,OU=Athens,DC=company,DC=local" -IsBlocked Yes

# Enforced link (χρησιμοποιείται με φειδώ — π.χ. security baseline policies που ΔΕΝ πρέπει ποτέ να παρακαμφθούν)
Set-GPLink -Name "Corporate-Security-Baseline" -Target "DC=company,DC=local" -Enforced Yes
```

> ⚠️ **Πραγματικό λάθος που βλέπεις συχνά:** Κάποιος βάζει "Block Inheritance" σε ένα OU για να λύσει ένα πρόβλημα γρήγορα, και ξεχνάει ότι αυτό μπλοκάρει *ΟΛΑ* τα ανώτερα GPOs — συμπεριλαμβανομένου του security baseline. Αν χρειάζεσαι να αποκλείσεις μόνο ΕΝΑ συγκεκριμένο GPO, χρησιμοποίησε **Security Filtering** (§8) στο ίδιο το GPO, όχι Block Inheritance στο OU.

---

## 👤 3. Computer vs User Configuration

Κάθε GPO έχει δύο ξεχωριστά "μισά":

| | Computer Configuration | User Configuration |
|---|---|---|
| **Πότε εφαρμόζεται** | Στο boot, και κάθε 90-120 λεπτά (background refresh) | Στο logon, και κάθε 90-120 λεπτά |
| **Ισχύει βάσει** | Ποιο OU ανήκει το **computer object** | Ποιο OU ανήκει το **user object** |
| **Τυπικά settings** | Security policies, software installation, startup scripts | Drive mappings, desktop wallpaper, logon scripts, folder redirection |

> 💡 Αν ένα setting υπάρχει και στα δύο (σπάνιο, αλλά συμβαίνει), το **Computer Configuration συνήθως κερδίζει** — αλλά ο γενικός κανόνας είναι να βάζεις κάθε setting μόνο εκεί που ανήκει λογικά, ώστε να μην έχεις conflicts καν.

---

## 🎫 4. Σενάριο — Το Ticket

> **Ticket #4602** — *"Θέλουμε: (1) Οι κωδικοί στο Finance department να είναι πιο αυστηροί από τους υπόλοιπους. (2) Το Marketing team να παίρνει αυτόματα το network drive `\\FS01\Marketing` ως `M:` όταν κάνουν login. (3) Ο εκτυπωτής του 2ου ορόφου να εγκαθίσταται αυτόματα σε όλα τα PCs εκεί, χωρίς να χρειάζεται ο χρήστης να κάνει τίποτα."*

Τρία ξεχωριστά requirements → 3 διαφορετικά runbooks παρακάτω, το καθένα με διαφορετική τεχνική προσέγγιση.

---

## 🔐 5. Runbook #1: Password Policy μέσω Fine-Grained Password Policies

**Πρόβλημα:** Το Default Domain Policy password policy ισχύει για **ολόκληρο το domain** — δεν μπορείς να κάνεις "different password policy per OU" με απλό GPO. Χρειάζεσαι **Fine-Grained Password Policies (FGPP)**, που δεν είναι καν GPO — είναι ξεχωριστό AD object (PSO - Password Settings Object).

```powershell
# Βήμα 1: Δημιουργία PSO για το Finance department
New-ADFineGrainedPasswordPolicy -Name "Finance-Strict-Password-Policy" `
    -Precedence 10 `
    -MinPasswordLength 14 `
    -PasswordHistoryCount 24 `
    -MaxPasswordAge "60.00:00:00" `
    -MinPasswordAge "1.00:00:00" `
    -ComplexityEnabled $true `
    -LockoutThreshold 5 `
    -LockoutDuration "00:30:00" `
    -LockoutObservationWindow "00:30:00" `
    -ReversibleEncryptionEnabled $false

# Βήμα 2: Εφαρμογή σε group (ΠΑΝΤΑ σε group, ΠΟΤΕ απευθείας σε OU - τα PSOs δεν συνδέονται με OUs!)
Add-ADFineGrainedPasswordPolicySubject -Identity "Finance-Strict-Password-Policy" `
    -Subjects "Finance-Team"

# Βήμα 3: Επαλήθευση ποιο PSO ισχύει τελικά για συγκεκριμένο χρήστη
Get-ADUserResultantPasswordPolicy -Identity "m.oikonomou"
```

| Όρος | Εξήγηση |
|---|---|
| **Precedence** | Χαμηλότερος αριθμός = υψηλότερη προτεραιότητα (αν ένας χρήστης ανήκει σε 2+ PSOs) |
| **Εφαρμόζεται σε** | Users ή Global Security Groups — **ΠΟΤΕ** απευθείας σε OU |

> ⚠️ **Πολύ συχνή παρανόηση:** Τα PSOs **δεν** μπορούν να συνδεθούν (link) σε ένα OU όπως τα GPOs. Πρέπει να τα εφαρμόσεις σε group ή απευθείας σε users. Γι' αυτό, το πρώτο βήμα είναι πάντα να έχεις ήδη το σωστό security group (π.χ. "Finance-Team") — αν δεν υπάρχει, το φτιάχνεις πρώτα (βλέπε [`active-directory.md`](./active-directory.md#-3-διαχείριση-users--groups)).

---

## 💾 6. Runbook #2: Αυτόματο Drive Mapping

**Σωστός σύγχρονος τρόπος:** Group Policy **Preferences** (όχι Group Policy Preferences scripts παλιού τύπου — αυτό είναι GUI-based, πιο εύκολο να διαχειριστείς).

### Βήμα-βήμα (GUI, μέσα από Group Policy Management Console)

```
1. Group Policy Management → δεξί κλικ στο OU "Marketing" → "Create a GPO in this domain, and Link it here"
   Όνομα: "Marketing-DriveMapping"

2. Edit το GPO →
   User Configuration → Preferences → Windows Settings → Drive Maps

3. Δεξί κλικ → New → Mapped Drive
   Location:        \\FS01\Marketing
   Drive Letter:     M:
   Reconnect:        ✅ (ώστε να ξανασυνδέεται σε κάθε logon)
   Label as:         "Marketing Shared Drive"

4. Tab "Common" → Item-level targeting (προαιρετικό, αλλά χρήσιμο):
   → Targeting: "Security Group = Marketing-Team"
   (Έτσι, ακόμα κι αν το GPO γίνει link σε μεγαλύτερο OU αργότερα,
    ΜΟΝΟ τα μέλη του σωστού group παίρνουν το drive)
```

### Το ίδιο μέσω PowerShell (χρήσιμο για automation/documentation)

```powershell
# Δημιουργία του GPO
$gpo = New-GPO -Name "Marketing-DriveMapping" -Comment "Ticket #4602 - Auto M: drive για Marketing"

# Link στο σωστό OU
New-GPLink -Name "Marketing-DriveMapping" -Target "OU=Marketing,OU=Athens,DC=company,DC=local"

# Σημείωση: Τα Drive Maps preferences ΔΕΝ έχουν άμεσο native PowerShell cmdlet -
# το XML που δημιουργεί το GUI αποθηκεύεται στο SYSVOL. Σε πραγματική δουλειά,
# το drive mapping preference συνήθως φτιάχνεται μέσω GUI, αλλά το LINKING
# και το SCOPE (security filtering) μπορούν να scriptάρονται όπως πάνω.
```

> 💡 **Γιατί Preferences και όχι λογοff/logon script;** Τα παλιά logon scripts (`net use m: \\fs01\marketing`) δουλεύουν, αλλά είναι "dumb" — τρέχουν πάντα, δεν ελέγχουν αν το drive υπάρχει ήδη, δεν κάνουν clean error handling. Τα Group Policy Preferences drive maps είναι πιο "έξυπνα": ελέγχουν κατάσταση, κάνουν update μόνο αν χρειάζεται, και έχουν built-in item-level targeting χωρίς να γράφεις καθόλου scripting.

---

## 🖨️ 7. Runbook #3: Αυτόματη Εγκατάσταση Εκτυπωτή

```powershell
# Βήμα 1: Ο εκτυπωτής πρέπει πρώτα να είναι shared σε print server (βλέπε print server management)
# Print server: PRINT01, shared name: "Floor2-HP-LaserJet"

# Βήμα 2: Δημιουργία GPO
New-GPO -Name "Floor2-Printer-Deployment" -Comment "Ticket #4602"
New-GPLink -Name "Floor2-Printer-Deployment" -Target "OU=Floor2-Computers,OU=Athens,DC=company,DC=local"
```

```
Βήμα 3 (GUI - Deployed Printers χρειάζεται GUI, δεν έχει καθαρό PowerShell equivalent):

Edit το GPO →
Computer Configuration → Policies → Windows Settings → Deployed Printers
→ δεξί κλικ → "Deploy Printer"
→ Printer path: \\PRINT01\Floor2-HP-LaserJet
→ OK

(Σημείωση: Αυτό είναι Computer Configuration - το printer γίνεται install
 για ΟΛΟΥΣ τους users που κάνουν login σε αυτά τα PCs, όχι ανά χρήστη.
 Αν θες per-user targeting, χρησιμοποίησε User Configuration → Preferences → Printers)
```

> ⚠️ **Σημαντική επιλογή σχεδιασμού:** Deploy printer μέσω **Computer Configuration** = "όποιος καθίσει σε αυτό το PC παίρνει τον εκτυπωτή" (σωστό για shared/floor-based PCs). Deploy μέσω **User Configuration** = "ο χρήστης παίρνει τον εκτυπωτή όπου κι αν κάνει login" (σωστό για roaming users/laptops). Το ticket λέει "PCs εκεί" → Computer Configuration είναι η σωστή επιλογή εδώ.

---

## 🎯 8. Security Filtering & WMI Filtering

Πέρα από το "πού είναι linked" το GPO (OU-based), μπορείς να περιορίσεις **ποιος ακριβώς** μέσα σε αυτό το OU παίρνει το policy.

### Security Filtering

```powershell
# Default: "Authenticated Users" έχουν Read + Apply - δηλαδή εφαρμόζεται σε όλους στο OU
# Αφαίρεση του default, προσθήκη συγκεκριμένου group

Set-GPPermission -Name "Marketing-DriveMapping" -PermissionLevel None `
    -TargetName "Authenticated Users" -TargetType Group

Set-GPPermission -Name "Marketing-DriveMapping" -PermissionLevel GpoApply `
    -TargetName "Marketing-Team" -TargetType Group
```

### WMI Filtering

Επιτρέπει conditional εφαρμογή βάσει χαρακτηριστικών του μηχανήματος (OS version, RAM, manufacturer, κ.λπ.) — π.χ. "εφάρμοσε αυτό το GPO ΜΟΝΟ σε Windows 11 machines":

```sql
-- WMI Filter query (δημιουργείται στο Group Policy Management → WMI Filters)
SELECT * FROM Win32_OperatingSystem WHERE Version LIKE "10.0.22%"
```

```powershell
# Σύνδεση WMI filter σε GPO (μέσω GUI είναι πιο εύκολο, αλλά και εδώ το path)
# Group Policy Management → επίλεξε GPO → Scope tab → WMI Filtering dropdown → επίλεξε filter
```

> 💡 **Πότε Security Filtering, πότε WMI Filtering;** Security Filtering = "ποιος" (based on group membership). WMI Filtering = "τι είδους μηχάνημα" (based on hardware/OS χαρακτηριστικά). Πολύ συχνά τα combinάρεις — π.χ. "αυτό το policy πάει μόνο σε Marketing-Team (security filter) ΚΑΙ μόνο σε Windows 11 machines (WMI filter)".

> ⚠️ WMI Filtering προσθέτει **καθυστέρηση στο boot/logon** (κάθε φορά τρέχει το query). Σε μεγάλα environments με πολλά WMI-filtered GPOs, αυτό μπορεί να γίνει αισθητό. Χρησιμοποίησέ το με μέτρο, όχι για κάθε GPO default.

---

## 🔄 9. Loopback Processing

Κανονικά, το **User Configuration** εφαρμόζεται βάσει *πού ανήκει ο χρήστης* — ανεξάρτητα από ποιο PC κάθεται. Αυτό είναι πρόβλημα σε σενάρια όπως **Terminal Servers/RDS, kiosk PCs, ή δωμάτια συνεδριάσεων**: θέλεις ο ίδιος χρήστης να παίρνει *διαφορετικό* User Configuration ανάλογα με **ποιο μηχάνημα** χρησιμοποιεί.

```
Χωρίς Loopback:
  CEO κάνει login σε Kiosk PC στο lobby
    → Παίρνει το ΚΑΝΟΝΙΚΟ του desktop/settings (λάθος για kiosk context!)

Με Loopback Processing (Merge ή Replace):
  CEO κάνει login σε Kiosk PC στο lobby
    → Παίρνει τα ΠΕΡΙΟΡΙΣΜΕΝΑ kiosk settings, ανεξαρτήτως ποιος είναι
```

```powershell
# Ενεργοποίηση Loopback (μέσω GPO setting, εδώ το path στο Group Policy Editor)
# Computer Configuration → Policies → Administrative Templates → System → Group Policy
# → "Configure user Group Policy loopback processing mode" → Enabled

# Mode:
#   Merge   = User GPOs + το Loopback GPO's user settings (και τα δύο, με loopback να κερδίζει σε conflict)
#   Replace = ΜΟΝΟ το Loopback GPO's user settings (αγνοεί εντελώς τα κανονικά user GPOs)
```

> 💡 **Real-world χρήση:** Αίθουσες συνεδριάσεων, Citrix/RDS session hosts, εργαστήρια υπολογιστών σε εκπαιδευτικά ιδρύματα, kiosk μηχανήματα σε reception. Οπουδήποτε το "ποιο μηχάνημα" έχει σημασία περισσότερο από το "ποιος χρήστης".

---

## 🗃️ 10. Central Store για ADMX Templates

Όταν επεξεργάζεσαι ένα GPO, οι διαθέσιμες ρυθμίσεις (Administrative Templates) έρχονται από `.admx`/`.adml` αρχεία. Default, αυτά είναι τοπικά στο κάθε admin workstation — πρόβλημα αν δύο admins έχουν διαφορετικές εκδόσεις (π.χ. ένας δεν έχει τα πιο πρόσφατα Office ADMX templates).

**Λύση: Central Store** — μία κοινή τοποθεσία στο SYSVOL, ώστε όλοι οι admins να βλέπουν τα ίδια ακριβώς templates.

```powershell
# Βήμα 1: Δημιουργία της δομής στο SYSVOL (τρέχεται μία φορά, σε οποιοδήποτε DC - replikάρεται αυτόματα)
$sysvolPath = "\\company.local\SYSVOL\company.local\Policies"
New-Item -Path "$sysvolPath\PolicyDefinitions" -ItemType Directory
New-Item -Path "$sysvolPath\PolicyDefinitions\en-US" -ItemType Directory

# Βήμα 2: Αντιγραφή των τοπικών ADMX/ADML files (από C:\Windows\PolicyDefinitions ενός up-to-date μηχανήματος)
Copy-Item "C:\Windows\PolicyDefinitions\*.admx" -Destination "$sysvolPath\PolicyDefinitions"
Copy-Item "C:\Windows\PolicyDefinitions\en-US\*.adml" -Destination "$sysvolPath\PolicyDefinitions\en-US"

# Από εδώ και πέρα, το Group Policy Management Console χρησιμοποιεί ΑΥΤΟΜΑΤΑ τον Central Store
# αν υπάρχει - δεν χρειάζεται επιπλέον config.
```

> 💡 Αν η εταιρεία χρησιμοποιεί Office 365/Microsoft 365 Apps, θα κατεβάσεις επίσης τα **Office ADMX templates** ξεχωριστά (από Microsoft) και θα τα προσθέσεις στον ίδιο Central Store — δεν έρχονται built-in με τα Windows Server ADMX files.

---

## ✅ 11. Testing — RSOP & gpresult

**Ποτέ μην υποθέτεις ότι δούλεψε** — πάντα επαλήθευση, ειδικά όταν έχεις πολλαπλά GPOs με πιθανά conflicts.

```powershell
# Στο client machine - force refresh (χωρίς να περιμένεις το φυσικό 90-120 λεπτά interval)
gpupdate /force

# Πλήρης αναφορά - ποια GPOs εφαρμόστηκαν, ποια ΔΕΝ εφαρμόστηκαν και γιατί
gpresult /h C:\Temp\gpresult.html /f
# Άνοιξε το HTML - δείχνει winning GPO ανά setting, denied GPOs, WMI filter results

# Γρήγορη προβολή στο command line
gpresult /r

# Remote query σε άλλο μηχάνημα (χρήσιμο για troubleshooting από το desk σου)
gpresult /s PC-MKT-042 /r

# RSOP (Resultant Set of Policy) - πιο interactive GUI εργαλείο
rsop.msc
```

**Testing checklist πριν πεις "done":**

| Test | Πώς το κάνεις |
|---|---|
| Το GPO εφαρμόστηκε στο σωστό μηχάνημα/χρήστη | `gpresult /r` → ψάξε το GPO name στη λίστα "Applied GPOs" |
| Δεν υπάρχει conflict/override από άλλο GPO | `gpresult /h` HTML report → δες "Winning GPO" ανά setting |
| Security filtering δουλεύει σωστά | Login με test user ΕΝΤΟΣ του group, μετά με test user ΕΚΤΟΣ — επιβεβαίωσε διαφορά |
| Timing — πόσο παίρνει να εφαρμοστεί σε production χωρίς force | Default refresh: 90-120 λεπτά (client), background refresh για computer policies στο boot |

---

## 💾 12. Backup, Restore & Version Control

```powershell
# Backup ΟΛΩΝ των GPOs (καλή πρακτική: scheduled task, καθημερινά)
Backup-GPO -All -Path "\\FS01\GPO-Backups\$(Get-Date -Format 'yyyy-MM-dd')"

# Backup ενός συγκεκριμένου GPO πριν κάνεις ριψοκίνδυνη αλλαγή
Backup-GPO -Name "Marketing-DriveMapping" -Path "\\FS01\GPO-Backups\pre-change"

# Restore σε περίπτωση λάθους
Restore-GPO -Name "Marketing-DriveMapping" -Path "\\FS01\GPO-Backups\pre-change"

# Comparison πριν/μετά (export σε XML/HTML report για review)
Get-GPOReport -Name "Marketing-DriveMapping" -ReportType Html -Path "C:\Temp\before-change.html"
# ... κάνε την αλλαγή ...
Get-GPOReport -Name "Marketing-DriveMapping" -ReportType Html -Path "C:\Temp\after-change.html"
# Compare τα δύο HTML αρχεία χειροκίνητα ή με diff tool
```

> ⚠️ **Πραγματικό best practice:** Πάντα `Backup-GPO` **πριν** αλλάξεις οτιδήποτε σε production GPO — ειδικά σε GPOs που είναι ήδη linked και ενεργά (π.χ. Default Domain Policy, security baselines). Ένα λάθος σε GPO που αφορά χιλιάδες μηχανήματα μπορεί να προκαλέσει lockouts, boot loops, ή broken network config σε όλη την εταιρεία ταυτόχρονα — πολύ πιο επικίνδυνο από λάθος σε ένα μεμονωμένο server.

---

## 🔧 13. Troubleshooting

| Πρόβλημα | Πιθανή Αιτία | Λύση |
|---|---|---|
| GPO δεν εφαρμόζεται καθόλου | Δεν έγινε `gpupdate`, ή λάθος OU linking | `gpupdate /force`, επαλήθευσε linking με `Get-GPInheritance` |
| GPO εφαρμόζεται σε λάθος users | Security Filtering λάθος (π.χ. ξεχάστηκε "Authenticated Users" ακόμα εκεί) | `Get-GPPermission -Name "GPOName" -All` |
| Setting δεν "κολλάει" παρόλο που το GPO εφαρμόζεται | Άλλο GPO με υψηλότερη προτεραιότητα το κάνει override | `gpresult /h` → δες ποιο GPO "κερδίζει" σε αυτό το setting |
| Πολύ αργό boot/logon | Πάρα πολλά WMI filters, ή slow network link σε SYSVOL (π.χ. WAN link σε remote site) | Μείωσε WMI filters, έλεγξε site links/replication |
| Drive map δεν εμφανίζεται | Item-level targeting λάθος group, ή permissions στο target share | Έλεγξε targeting rules, test με `gpresult /r` |
| Αλλαγή σε GPO δεν φαίνεται σε remote site | SYSVOL replication lag (DFS-R) | Έλεγξε DFS-R health: `dfsrdiag replicationstate` |
| "Access Denied" όταν επεξεργάζεσαι GPO | Δεν έχεις τα σωστά delegated permissions | Έλεγξε delegation στο Group Policy Management → GPO → Delegation tab |

```powershell
# Διάγνωση SYSVOL replication (κρίσιμο αν αλλαγές δεν φτάνουν σε remote DCs/sites)
dfsrdiag replicationstate

# Event logs που πάντα ελέγχεις σε GPO troubleshooting
Get-WinEvent -LogName "Microsoft-Windows-GroupPolicy/Operational" -MaxEvents 50
```

---

## ✅ 14. Checklist — Πριν Κάνεις Deploy

```
☐ Το requirement μεταφράστηκε σωστά (Computer ή User configuration; Ποιο OU;)
☐ Backup του υπάρχοντος GPO πριν αλλαγές (αν επεξεργάζεσαι υπάρχον)
☐ Δοκιμή πρώτα σε ΜΙΚΡΟ test OU/test group, ΠΟΤΕ απευθείας σε production-wide OU
☐ Security Filtering ρυθμίστηκε σωστά (ποιος ακριβώς πρέπει να το πάρει)
☐ WMI Filtering αν χρειάζεται (μόνο αν πραγματικά χρειάζεται - επιβαρύνει)
☐ Enforced/Block Inheritance χρησιμοποιήθηκαν με προσοχή, όχι σαν "quick fix"
☐ gpupdate /force στο test μηχάνημα, επαλήθευση με gpresult
☐ Documentation - τι κάνει το GPO, σε ποιο ticket αναφέρεται, ποιος το έφτιαξε
☐ Rollout σε production OU μόνο μετά από επιτυχές testing
☐ Monitoring τις πρώτες ώρες μετά το rollout (helpdesk tickets που μπορεί να προκύψουν)
```

---

## 📚 Σχετικά αρχεία

- [`active-directory.md`](./active-directory.md) — Users/Groups, OUs, GPO βασικά, Entra ID
- [`active-directory-advanced.md`](./active-directory-advanced.md) — FSMO, Replication, Security Tiering
- [`file-permissions-ntfs.md`](./file-permissions-ntfs.md) — NTFS/Share permissions θεωρία
- [`file-server-implementation-runbook.md`](./file-server-implementation-runbook.md) — Real-world file share deployment
- [`dns-dhcp-administration.md`](./dns-dhcp-administration.md) — DNS/DHCP θεωρία + runbook
- Αυτό το αρχείο (`group-policy-deep-dive.md`) — GPO processing, real-world runbooks, troubleshooting
