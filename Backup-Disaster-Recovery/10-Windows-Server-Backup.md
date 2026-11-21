# 12. Windows Server Backup

### 12.1 Τι είναι
Το **Windows Server Backup (WSB)** είναι ενσωματωμένο χαρακτηριστικό των Windows Server. Είναι ιδανικό για μικρά περιβάλλοντα, εκπαίδευση και backup του **System State** (π.χ. Active Directory).

### 12.2 Δυνατότητες και περιορισμοί

| ✅ Δυνατότητες | ⚠️ Περιορισμοί |
|---|---|
| Δωρεάν (μέρος των Windows Server) | Δεν έχει κεντρική κονσόλα διαχείρισης πολλών servers |
| Full volume, System State, Bare Metal Recovery | Περιορισμένο off-site/cloud (χωρίς εξωτερικό εργαλείο) |
| Χρήση VSS, application-aware για SQL/Exchange/AD | Όχι πραγματικά incremental restore chains όπως σε enterprise εργαλεία |
| GUI, `wbadmin` (CLI), PowerShell | Περιορισμένες δυνατότητες retention και reporting |
| Backup σε τοπικό δίσκο ή δικτυακό share | Όταν χρησιμοποιείς ολόκληρο δίσκο ως προορισμό, **μορφοποιείται και αφιερώνεται** στο backup |
| System State για AD | Δεν υποστηρίζει ταινίες |

> Το WSB ΔΕΝ υποστηρίζει backup σε ταινίες. Το μέγιστο μέγεθος ενός VHD backup είναι περιορισμένο (πρακτικά 2 TB ανά volume σε παλαιότερες εκδόσεις). Δες την επίσημη τεκμηρίωση της έκδοσης που χρησιμοποιείς.

### 12.3 Εγκατάσταση

**GUI:** Server Manager → Manage → Add Roles and Features → Features → ✅ *Windows Server Backup*.

**PowerShell:**
```powershell
Install-WindowsFeature -Name Windows-Server-Backup -IncludeManagementTools
Get-WindowsFeature Windows-Server-Backup
```

Άνοιγμα κονσόλας: `wbadmin.msc`

### 12.4 Επιλογές προορισμού (target)

| Προορισμός | Πλεονέκτημα | Μειονέκτημα |
|---|---|---|
| **Αφιερωμένος εσωτερικός/εξωτερικός δίσκος** | Αυτοματοποιημένο schedule, πολλαπλά σημεία | Ο δίσκος μορφοποιείται και δεν φαίνεται στον Explorer |
| **Volume (π.χ. E:\)** | Μπορεί να έχει και άλλα δεδομένα, δεν φαίνεται κρυμμένο | Επηρεάζει απόδοση |
| **Δικτυακός φάκελος (\\\\server\\share)** | Κεντρικό, χωρίς επιπλέον δίσκο | Κρατάει **μόνο την τελευταία** έκδοση (κάθε νέο backup αντικαθιστά το προηγούμενο) σε one-time backup |

### 12.5 Backup με GUI (Scheduled)

1. `Windows Server Backup` → **Local Backup** → **Backup Schedule…**
2. **Full server** (προτείνεται για DR) ή **Custom** (επιλογή volumes, System State, Bare Metal Recovery)
3. Επιλογή ώρας (π.χ. 21:00) ή πολλές ώρες την ημέρα
4. Επιλογή προορισμού (δίσκος ή volume)
5. Επιβεβαίωση → **Finish**

### 12.6 Backup με `wbadmin` (CLI)

```cmd
:: Δες βοήθεια
wbadmin /?

:: Άμεσο full backup του C: με Bare Metal Recovery (allCritical) στον E:
wbadmin start backup -backupTarget:E: -include:C: -allCritical -quiet

:: Backup μόνο του System State
wbadmin start systemstatebackup -backupTarget:E: -quiet

:: Backup συγκεκριμένων φακέλων
wbadmin start backup -backupTarget:E: -include:D:\Shares,D:\Data -quiet

:: Backup σε δικτυακό share (με διαπιστευτήρια)
wbadmin start backup -backupTarget:\\NAS01\backups -include:C: -allCritical -user:DOMAIN\svc_backup -password:******** -quiet

:: Προγραμματισμένο καθημερινό backup στις 21:00 στον δίσκο με ID (βρες με "diskpart > list disk")
wbadmin enable backup -addtarget:{DISK-IDENTIFIER} -schedule:21:00 -include:C: -allCritical -quiet

:: Δες υπάρχοντα backups
wbadmin get versions

:: Δες τι περιέχει ένα backup
wbadmin get items -version:10/30/2026-21:00

:: Δες την κατάσταση τρέχουσας εργασίας
wbadmin get status

:: Διαγραφή παλαιών backups, κράτα τα 7 τελευταία
wbadmin delete backup -keepVersions:7

:: Διαγραφή backup System State, κράτα τα 3 τελευταία
wbadmin delete systemstatebackup -keepVersions:3
```

> Το όνομα έκδοσης (version) έχει τη μορφή `MM/DD/YYYY-HH:MM`, ανάλογα με τις τοπικές ρυθμίσεις. Αντίγραψέ το ακριβώς από το `wbadmin get versions`.

### 12.7 Backup με PowerShell (cmdlets)

```powershell
# Δημιουργία νέας πολιτικής
$policy = New-WBPolicy

# Προσθήκη volumes (C:)
$vol = Get-WBVolume -VolumePath "C:"
Add-WBVolume -Policy $policy -Volume $vol

# Προσθήκη System State και Bare Metal Recovery
Add-WBSystemState      -Policy $policy
Add-WBBareMetalRecovery -Policy $policy

# Προορισμός
$target = New-WBBackupTarget -VolumePath "E:"
Add-WBBackupTarget -Policy $policy -Target $target

# VSS full backup (ώστε να ενημερώνεται το backup history των εφαρμογών)
Set-WBVssBackupOptions -Policy $policy -VssFullBackup

# Schedule στις 21:00
Set-WBSchedule -Policy $policy -Schedule ([datetime]"21:00")

# Ενεργοποίηση πολιτικής
Set-WBPolicy -Policy $policy -Force

# Έλεγχος
Get-WBPolicy
Get-WBSummary
Get-WBBackupSet
```

### 12.8 Restore

**Επαναφορά αρχείων/φακέλων (GUI):**
`Windows Server Backup` → **Recover…** → This server → Επιλογή ημερομηνίας → *Files and folders* → επιλογή → *Original location* ή *Another location* → Recover.

**Επαναφορά αρχείων/φακέλων (CLI):**
```cmd
wbadmin start recovery -version:10/30/2026-21:00 -itemType:File -items:D:\Data\report.xlsx -recoveryTarget:D:\Restore -recursive
```

**Επαναφορά volume:**
```cmd
wbadmin start recovery -version:10/30/2026-21:00 -itemType:Volume -items:D: -recoveryTarget:D:
```

**Επαναφορά System State (μη-DC):**
```cmd
wbadmin start systemstaterecovery -version:10/30/2026-21:00 -quiet
```
Ακολουθεί επανεκκίνηση.

**Bare Metal Recovery (BMR) – ολική επαναφορά σε νέο/κενό hardware:**
1. Εκκίνηση από **Windows Server installation media** (USB/ISO).
2. Επιλογή γλώσσας → **Repair your computer** → *Troubleshoot* → **System Image Recovery**.
3. Επιλογή backup (από δίσκο/δικτυακό share) και σημείου.
4. Επιβεβαίωση, ολοκλήρωση, επανεκκίνηση.

> Για BMR χρειάζεται backup με επιλεγμένο **Bare Metal Recovery** (`-allCritical`).

### 12.9 Active Directory: backup και restore

**Προτεινόμενο backup:** System State του Domain Controller (τουλάχιστον ένας ανά domain, κατά προτίμηση 2, σε διαφορετικά sites).

```cmd
wbadmin start systemstatebackup -backupTarget:E: -quiet
```

**Δύο τύποι restore του AD:**

| Τύπος | Πότε | Τι κάνει |
|---|---|---|
| **Non-authoritative restore** | Βλάβη DC, ξανακαταλήγει στο domain και συγχρονίζεται από άλλους DCs | Ο DC επανέρχεται και λαμβάνει τις **νεότερες** αλλαγές από τους άλλους DCs (replication) |
| **Authoritative restore** | Διαγράφηκαν κατά λάθος αντικείμενα (OU, χρήστες) | Τα επαναφερόμενα αντικείμενα **επικρατούν** στην αντιγραφή και ξαναγίνονται παντού |

**Διαδικασία (περίληψη):**
1. Επανεκκίνηση σε **Directory Services Restore Mode (DSRM)** (`F8` ή `bcdedit /set safeboot dsrepair` και restart).
2. Σύνδεση με τον κωδικό **DSRM** (τον όρισες κατά το promote του DC – **φύλαξέ τον!**).
3. Εκτέλεση `wbadmin start systemstaterecovery -version:... -quiet`.
4. (Μόνο για authoritative) πριν τη επανεκκίνηση:
```cmd
ntdsutil
activate instance ntds
authoritative restore
restore object "CN=John Doe,OU=Users,DC=lab,DC=local"
restore subtree "OU=Sales,DC=lab,DC=local"
quit
quit
```
5. Επανεκκίνηση σε κανονική λειτουργία.

> 💡 **Σύγχρονη εναλλακτική:** Το **AD Recycle Bin** (να είναι ενεργοποιημένο!) επαναφέρει διαγραμμένα αντικείμενα χωρίς authoritative restore.
> ```powershell
> Enable-ADOptionalFeature 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target 'lab.local'
> Get-ADObject -Filter 'isDeleted -eq $true -and Name -like "*John*"' -IncludeDeletedObjects | Restore-ADObject
> ```

### 12.10 Αυτοματοποίηση και παρακολούθηση

**Έλεγχος αποτυχιών μέσω Event Log:**
`Event Viewer → Applications and Services Logs → Microsoft → Windows → Backup → Operational`.

| Event ID | Σημασία |
|---|---|
| **4** | Backup ολοκληρώθηκε με επιτυχία |
| **5** | Backup απέτυχε |
| **14** | Backup ολοκληρώθηκε (σε ορισμένες εκδόσεις) |
| **517** | Backup απέτυχε (παλαιότερα) |
| **521** | Αποτυχία δημιουργίας shadow copy |

Για ακριβή IDs της έκδοσής σου έλεγξε το Event Viewer.

**PowerShell script ελέγχου με email:**
```powershell
$summary = Get-WBSummary
if ($summary.LastBackupResultHR -ne 0) {
    Send-MailMessage -From "backup@lab.local" -To "admin@lab.local" `
        -Subject "WSB FAILED on $env:COMPUTERNAME" `
        -Body "Last result HR: $($summary.LastBackupResultHR)  Time: $($summary.LastSuccessfulBackupTime)" `
        -SmtpServer "smtp.lab.local"
}
```

### 12.11 Best practices για WSB

- ✅ Χρήση **ξεχωριστού δίσκου** για backup (όχι ο ίδιος με το OS).
- ✅ Backup **System State** κάθε DC.
- ✅ Πάντα και **off-site** αντίγραφο (WSB μόνο του δεν καλύπτει το "1" του 3-2-1).
- ✅ Τακτικό **test restore** (π.χ. μηνιαία).
- ✅ Αποθήκευση του DSRM κωδικού.
- ❌ Όχι μόνο δικτυακό share χωρίς ιστορικό (κρατά μόνο το τελευταίο backup).

---

[⬅️ Προηγούμενο](09-Disaster-Recovery-Plan.md) | [📚 Περιεχόμενα](README.md) | [Επόμενο ➡️](11-Veeam-Backup-Replication.md)
