# 🖨️ Print Server Management — Deep Dive & Real-World Runbook
> Συνοδευτικό αρχείο στη σειρά Active Directory. Φαίνεται "απλό" θέμα, αλλά το printing είναι από τα πιο συχνά αιτήματα helpdesk σε κάθε εταιρεία — και ένας σωστά στημένος print server γλιτώνει δεκάδες tickets το μήνα.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Γιατί Print Server και όχι Direct IP Printing](#-1-γιατί-print-server-και-όχι-direct-ip-printing)
2. [Αρχιτεκτονική — Πώς Δουλεύει το Printing](#-2-αρχιτεκτονική--πώς-δουλεύει-το-printing)
3. [Σενάριο — Το Ticket](#-3-σενάριο--το-ticket)
4. [Runbook: Εγκατάσταση Print Server Role](#-4-runbook-εγκατάσταση-print-server-role)
5. [Προσθήκη Εκτυπωτή & Driver Management](#-5-προσθήκη-εκτυπωτή--driver-management)
6. [Deployment στους Χρήστες](#-6-deployment-στους-χρήστες)
7. [Permissions σε Printers](#-7-permissions-σε-printers)
8. [Print Queue Management](#-8-print-queue-management)
9. [High Availability — Printer Cluster/Migration](#-9-high-availability--printer-clustermigration)
10. [Monitoring](#-10-monitoring)
11. [Troubleshooting](#-11-troubleshooting)
12. [Checklist — Go-Live](#-12-checklist--go-live)

---

## 🤔 1. Γιατί Print Server και όχι Direct IP Printing

| | Direct IP Printing | Print Server |
|---|---|---|
| **Setup ανά client** | Κάθε PC χρειάζεται δικό του driver install + IP config | Ένα "add printer" — όλα τα άλλα κεντρικά |
| **Driver updates** | Χειροκίνητα σε κάθε μηχάνημα | Μία φορά στον server, διαδίδεται αυτόματα |
| **Queue visibility** | Δεν βλέπεις τι στέλνουν όλοι στον εκτυπωτή | Κεντρική προβολή queue, μπορείς να διαγράψεις stuck jobs |
| **Deployment σε μαζικά PCs** | Χειροκίνητα, ή scripting per-machine | Group Policy (βλέπε [`group-policy-deep-dive.md`](./group-policy-deep-dive.md#-7-runbook-3-αυτόματη-εγκατάσταση-εκτυπωτή)) |
| **Permissions/auditing** | Δύσκολο να ελέγξεις ποιος τυπώνει τι | Κεντρικό logging, permissions ανά printer |

> 💡 Direct IP printing έχει νόημα μόνο σε πολύ μικρά γραφεία (2-3 άτομα, 1 εκτυπωτής). Από τη στιγμή που έχεις πάνω από ~10 χρήστες ή πάνω από 1 εκτυπωτή, ο print server σου γλιτώνει πολλαπλάσιο χρόνο helpdesk.

---

## 🏗️ 2. Αρχιτεκτονική — Πώς Δουλεύει το Printing

```
Χρήστης πατάει "Print" στο Word
    ↓
Print Spooler (τοπικά στο PC) στέλνει το job
    ↓
Print Server (π.χ. PRINT01) — λαμβάνει, κάνει queue, spooling
    ↓
Print Server στέλνει στον φυσικό εκτυπωτή (μέσω TCP/IP port, π.χ. 9100 - RAW ή LPR)
    ↓
Ο εκτυπωτής τυπώνει
```

**Βασικά συστατικά:**

| Όρος | Τι είναι |
|---|---|
| **Print Spooler** | Το Windows service που διαχειρίζεται print jobs (queue, ordering, retry) |
| **Printer Driver** | Software που μεταφράζει το document σε γλώσσα που καταλαβαίνει ο εκτυπωτής (PCL, PostScript) |
| **Printer Port** | Πώς επικοινωνεί ο server με τον φυσικό εκτυπωτή (Standard TCP/IP Port, πάντα με static IP/reservation) |
| **Print Queue** | Η λίστα με τα jobs που περιμένουν να τυπωθούν |
| **Shared Printer** | Ο εκτυπωτής γίνεται διαθέσιμος στο δίκτυο μέσω `\\PRINT01\PrinterName` |

---

## 🎫 3. Σενάριο — Το Ticket

> **Ticket #4610** — *"Αγοράσαμε νέο εκτυπωτή Konica Minolta για το Accounting. Θέλουμε μόνο το Accounting team να μπορεί να τυπώνει, οι Team Leads να μπορούν επιπλέον να διαγράφουν stuck jobs άλλων, και να στήνεται αυτόματα σε όλα τα PCs τους χωρίς να χρειάζεται να κάνουν οτιδήποτε."*

Αυτό χρειάζεται: printer installation στον server → permissions (restrict σε group) → deployment (Group Policy) → escalated permissions για Team Leads (queue management).

---

## 🛠️ 4. Runbook: Εγκατάσταση Print Server Role

```powershell
# Βήμα 1: Εγκατάσταση του Print Server role (αν δεν υπάρχει ήδη σε αυτόν τον server)
Install-WindowsFeature Print-Server -IncludeManagementTools

# Βήμα 2: Επιβεβαίωση ότι το service τρέχει
Get-Service Spooler

# Βήμα 3: (Προαιρετικό αλλά σύνηθες) Print and Document Services role με επιπλέον features
#          όπως LPD Service (αν χρειάζεσαι συμβατότητα με Unix/Linux clients)
Install-WindowsFeature Print-Server, LPD-Service -IncludeManagementTools
```

---

## 🖨️ 5. Προσθήκη Εκτυπωτή & Driver Management

```powershell
# Βήμα 1: Δημιουργία του TCP/IP port (ο εκτυπωτής χρειάζεται ΣΤΑΘΕΡΗ IP -
# βλέπε dns-dhcp-administration.md §7 για DHCP reservation)
Add-PrinterPort -Name "IP_10.10.5.200" -PrinterHostAddress "10.10.5.200"

# Βήμα 2: Εγκατάσταση του driver
# Καλύτερα να κατεβάσεις τον επίσημο driver από τον κατασκευαστή (π.χ. Konica Minolta site)
# παρά να χρησιμοποιήσεις γενικό Windows driver - λιγότερα προβλήματα συμβατότητας
Add-PrinterDriver -Name "KONICA MINOLTA C4050 PCL"

# Αν ο driver δεν είναι ήδη στο driver store, πρόσθεσέ τον πρώτα
Add-PrinterDriver -Name "KONICA MINOLTA C4050 PCL" -InfPath "C:\Drivers\konica\km4050.inf"

# Βήμα 3: Δημιουργία και share του printer
Add-Printer -Name "Accounting-Konica-C4050" `
    -DriverName "KONICA MINOLTA C4050 PCL" `
    -PortName "IP_10.10.5.200" `
    -Shared -ShareName "Accounting-Konica"

# Επαλήθευση
Get-Printer -Name "Accounting-Konica-C4050"
Get-PrinterPort -Name "IP_10.10.5.200"
```

> 💡 **Real-world tip:** Πάντα δοκίμασε ένα **test print** αμέσως μετά (`Get-Printer | Test-Print` σε PowerShell 7+, ή απλά μια δοκιμαστική σελίδα από Devices & Printers GUI) πριν προχωρήσεις στο deployment. Πολύ πιο εύκολο να διορθώσεις driver/port issues τώρα παρά αφού το έχεις ήδη στείλει σε 30 μηχανήματα.

### Driver Isolation (Σταθερότητα)

Παλιοί/κακογραμμένοι drivers μπορούν να κρασάρουν το Print Spooler service — και όταν κρασάρει σε server με 50 εκτυπωτές, **όλοι** σταματούν να τυπώνουν, όχι μόνο ο προβληματικός.

```powershell
# Ενεργοποίηση Driver Isolation - ο driver τρέχει σε ξεχωριστή διεργασία, δεν "τραβάει" τον spooler μαζί του αν κρασάρει
Set-PrinterDriver -Name "KONICA MINOLTA C4050 PCL" -DriverIsolation Isolated
```

---

## 📤 6. Deployment στους Χρήστες

Το ticket ζητάει "αυτόματα σε όλα τα PCs τους χωρίς να κάνουν τίποτα" — αυτό σημαίνει **Group Policy Deployed Printers**, ακριβώς όπως περιγράφεται στο [`group-policy-deep-dive.md`](./group-policy-deep-dive.md#-7-runbook-3-αυτόματη-εγκατάσταση-εκτυπωτή):

```
1. Group Policy Management → νέο GPO "Accounting-Printer-Deployment"
   Linked στο: OU=Accounting-Computers,OU=Athens,DC=company,DC=local

2. Edit →
   Computer Configuration → Policies → Windows Settings → Deployed Printers
   → Deploy Printer → \\PRINT01\Accounting-Konica

3. gpupdate /force σε test μηχάνημα, επαλήθευση ότι εμφανίστηκε αυτόματα
```

> 💡 Εναλλακτικά, αν οι υπολογιστές του Accounting **δεν** είναι όλοι στο ίδιο OU (π.χ. είναι σκορπισμένοι), χρησιμοποίησε **Security Filtering** πάνω στο GPO με στόχο ένα user ή computer group αντί να βασιστείς αποκλειστικά στο OU-based linking (βλέπε `group-policy-deep-dive.md` §8).

---

## 🔐 7. Permissions σε Printers

Οι printer permissions δουλεύουν παρόμοια με τα NTFS permissions (βλέπε [`file-permissions-ntfs.md`](./file-permissions-ntfs.md)) — ACL-based, με 3 βασικά επίπεδα:

| Permission Level | Τι επιτρέπει |
|---|---|
| **Print** | Στέλνει jobs, βλέπει/διαγράφει ΜΟΝΟ τα ΔΙΚΑ ΤΟΥ jobs |
| **Manage this printer** | Αλλαγή printer settings/properties, permissions |
| **Manage documents** | Βλέπει/διαγράφει/παύει τα jobs **ΟΛΩΝ** — αυτό χρειάζονται οι Team Leads |

```powershell
# Βήμα 1: Αφαίρεση default "Everyone" access
$printerName = "Accounting-Konica-C4050"

# Χρησιμοποιούμε Set-Printer με security descriptor, ή πιο απλά μέσω GUI:
# Devices and Printers → δεξί κλικ στον εκτυπωτή → Printer Properties → Security tab

# Μέσω PowerShell (χρησιμοποιώντας το .NET printing namespace για fine control):
# Στην πράξη, το πιο αξιόπιστο σε production είναι το GUI Security tab για αυτό το βήμα -
# το πλήρες ACL model των printers δεν έχει τόσο ώριμα cmdlets όσο το NTFS.

# GUI βήματα:
# 1. Security tab → Remove "Everyone"
# 2. Add "Accounting-Team" (AD group) → Allow: Print
# 3. Add "Accounting-TeamLeads" (AD group) → Allow: Print + Manage Documents
```

> ⚠️ **Ίδιο pattern με τα NTFS permissions** — ΠΟΤΕ direct σε individual user, πάντα μέσω AD security groups (AGDLP - βλέπε [`active-directory.md`](./active-directory.md#-3-διαχείριση-users--groups)). Το `Accounting-TeamLeads` group χρειάζεται να υπάρχει ήδη ή να δημιουργηθεί πρώτα.

---

## 📊 8. Print Queue Management

```powershell
# Προβολή όλων των jobs σε queue
Get-PrintJob -PrinterName "Accounting-Konica-C4050"

# Διαγραφή συγκεκριμένου stuck job
Remove-PrintJob -PrinterName "Accounting-Konica-C4050" -ID 42

# Διαγραφή ΟΛΩΝ των jobs (π.χ. μετά από jam/παρατεταμένο πρόβλημα)
Get-PrintJob -PrinterName "Accounting-Konica-C4050" | Remove-PrintJob

# Παύση/συνέχιση printer (χρήσιμο κατά τη διάρκεια maintenance)
Set-Printer -Name "Accounting-Konica-C4050" -Shared $false   # προσωρινή απόκρυψη
Set-Printer -Name "Accounting-Konica-C4050" -Shared $true    # επαναφορά
```

**Το κλασικό "stuck print job" fix:**

```powershell
# Όταν ένα job "κολλάει" και μπλοκάρει ολόκληρη την queue
Stop-Service Spooler
Remove-Item "C:\Windows\System32\spool\PRINTERS\*" -Force
Start-Service Spooler
```

> 💡 Αυτό είναι από τα πιο συχνά helpdesk fixes που θα κάνεις — άξιζε να το έχεις σαν **γρήγορο one-liner** έτοιμο, γιατί συμβαίνει σχεδόν κάθε εβδομάδα σε οποιαδήποτε εταιρεία με αρκετούς εκτυπωτές.

---

## 🔁 9. High Availability — Printer Cluster/Migration

Σε πραγματική δουλειά, ο print server μπορεί να χρειαστεί migration (νέο hardware, OS upgrade) χωρίς να "χαθούν" όλα τα printer configs από τα clients.

```powershell
# Export όλων των printers + drivers + ports + settings από τον παλιό server
Export-PrinterConfiguration -Path "C:\Temp\printserver-backup.printerExport"

# Import στον νέο server
Import-PrinterConfiguration -Path "C:\Temp\printserver-backup.printerExport"
```

Για πραγματικό **failover** (όχι απλή migration), οι επιλογές είναι:
- **Print Server Clustering** (Windows Failover Clustering) — παλιότερη προσέγγιση, πολύπλοκη
- **DFS-N style trick**: DNS CNAME ("PRINT" → όποιος server είναι ενεργός) — πιο απλή προσέγγιση σε μικρότερες εταιρείες
- **Cloud print solutions** (π.χ. Universal Print) — σύγχρονη λύση, αφαιρεί εντελώς την ανάγκη για on-prem print server

> 💡 Στην πράξη, οι περισσότερες μικρομεσαίες εταιρείες **δεν** κάνουν full clustering για printing — το θεωρούν "χαμηλού ρίσκου" (αν πέσει ο print server για 10 λεπτά, δεν είναι catastrophic όπως αν πέσει ένα DC). Investment σε HA γίνεται μόνο αν το printing είναι business-critical (π.χ. logistics/warehouse label printing).

---

## 📈 10. Monitoring

```powershell
# Event log - print operations (ενεργοποίησε αν χρειάζεσαι audit trail ποιος τύπωσε τι)
wevtutil sl Microsoft-Windows-PrintService/Operational /e:true

Get-WinEvent -LogName "Microsoft-Windows-PrintService/Operational" -MaxEvents 50 |
    Where-Object {$_.Id -eq 307}   # Event 307 = document printed

# Health του spooler service σε πολλαπλούς servers ταυτόχρονα
Invoke-Command -ComputerName PRINT01,PRINT02 -ScriptBlock { Get-Service Spooler }

# Queue length monitoring (alerting αν κολλήσει queue με πολλά jobs)
(Get-PrintJob -PrinterName "Accounting-Konica-C4050").Count
```

---

## 🔧 11. Troubleshooting

| Πρόβλημα | Πιθανή Αιτία | Λύση |
|---|---|---|
| Job μένει "stuck" στην queue, τίποτα δεν τυπώνεται | Spooler service issue, ή driver crash | Restart spooler + clear queue (§8) |
| "Access Denied" όταν χρήστης προσπαθεί να τυπώσει | Δεν είναι μέλος του σωστού group (§7) | `Get-ADPrincipalGroupMembership`, έλεγξε printer Security tab |
| Ο εκτυπωτής δεν εμφανίζεται στο PC μετά το GPO deployment | `gpupdate` δεν έτρεξε ακόμα, ή λάθος OU/targeting | `gpupdate /force`, `gpresult /r` (βλέπε group-policy-deep-dive.md §11) |
| Print ποιότητα/formatting λάθος | Λάθος/παλιός driver | Ενημέρωσε driver στον server (διαδίδεται αυτόματα σε clients) |
| Spooler κρασάρει επαναλαμβανόμενα | Προβληματικός driver χωρίς isolation | Ενεργοποίησε Driver Isolation (§5) |
| Team Lead δεν μπορεί να διαγράψει jobs άλλων | Δεν έχει "Manage Documents" permission | Έλεγξε printer Security tab, πρόσθεσε permission |
| Printer offline παρόλο που είναι physically online | Λάθος IP στο port (άλλαξε μέσω DHCP χωρίς reservation) | Έλεγξε IP, βεβαιώσου ότι υπάρχει DHCP reservation (dns-dhcp-administration.md §7) |

```powershell
# Γρήγορη διάγνωση connectivity προς τον εκτυπωτή
Test-NetConnection -ComputerName 10.10.5.200 -Port 9100

# Restart spooler σε remote print server
Invoke-Command -ComputerName PRINT01 -ScriptBlock { Restart-Service Spooler -Force }
```

---

## ✅ 12. Checklist — Go-Live

```
☐ Ο εκτυπωτής έχει static IP ή DHCP reservation (ΠΟΤΕ dynamic χωρίς reservation)
☐ Driver εγκατεστημένος - επίσημος από κατασκευαστή, με Driver Isolation ενεργό
☐ Printer port δημιουργήθηκε σωστά, test print επιτυχές
☐ Printer shared στον server
☐ Security permissions ρυθμίστηκαν (Print/Manage Documents ανά group)
☐ ΠΟΤΕ direct σε individual user - πάντα μέσω AD security groups
☐ GPO deployment ρυθμίστηκε (ή documented αν είναι manual install)
☐ Test print από test client μετά το deployment
☐ Team Leads (ή όποιος χρειάζεται) επαληθεύτηκε ότι έχει Manage Documents
☐ Documentation - printer name, IP, driver version, permissions, ticket reference
☐ Backup/export της τρέχουσας print server config (Export-PrinterConfiguration)
```

---

## 📚 Σχετικά αρχεία

- [`active-directory.md`](./active-directory.md) — Users/Groups, OUs, GPO βασικά
- [`active-directory-advanced.md`](./active-directory-advanced.md) — FSMO, Replication, Security Tiering
- [`file-permissions-ntfs.md`](./file-permissions-ntfs.md) — NTFS/Share permissions θεωρία (ίδιο permission μοντέλο)
- [`file-server-implementation-runbook.md`](./file-server-implementation-runbook.md) — Real-world file share deployment
- [`dns-dhcp-administration.md`](./dns-dhcp-administration.md) — DHCP reservations για εκτυπωτές
- [`group-policy-deep-dive.md`](./group-policy-deep-dive.md) — Deployed Printers μέσω GPO
- Αυτό το αρχείο (`print-server-management.md`) — Print server setup, permissions, troubleshooting
