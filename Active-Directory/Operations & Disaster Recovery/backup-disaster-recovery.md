# 🛡️ Backup & Disaster Recovery — AD & File Servers Deep Dive
> Συνοδευτικό αρχείο στη σειρά Active Directory. Αν όλα τα προηγούμενα αρχεία αφορούν το "πώς χτίζεις" την υποδομή, αυτό αφορά το **"τι κάνεις όταν κάτι πάει στραβά"** — το πιο κρίσιμο skill ενός sysadmin, γιατί είναι αυτό που κρίνεται σε πραγματική κρίση.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Οι Δύο Μετρικές που Καθορίζουν Τα Πάντα — RPO & RTO](#-1-οι-δύο-μετρικές-που-καθορίζουν-τα-πάντα--rpo--rto)
2. [Domain Controller Backup Θεωρία](#-2-domain-controller-backup-θεωρία)
3. [Σενάριο — Το Incident](#-3-σενάριο--το-incident)
4. [Runbook #1: Backup Domain Controller](#-4-runbook-1-backup-domain-controller)
5. [Runbook #2: AD Object Recovery (Recycle Bin)](#-5-runbook-2-ad-object-recovery-recycle-bin)
6. [Runbook #3: Authoritative Restore](#-6-runbook-3-authoritative-restore)
7. [Runbook #4: Full DC Disaster Recovery (Bare Metal)](#-7-runbook-4-full-dc-disaster-recovery-bare-metal)
8. [File Server Backup — Shadow Copies (VSS)](#-8-file-server-backup--shadow-copies-vss)
9. [File Server Backup — Full/Incremental Strategy](#-9-file-server-backup--fullincremental-strategy)
10. [Ransomware Response — Ειδική Περίπτωση](#-10-ransomware-response--ειδική-περίπτωση)
11. [Testing Το Backup — Το Βήμα Που Όλοι Ξεχνάνε](#-11-testing-το-backup--το-βήμα-που-όλοι-ξεχνάνε)
12. [Disaster Recovery Documentation — Runbook Template](#-12-disaster-recovery-documentation--runbook-template)
13. [Checklist — DR Readiness](#-13-checklist--dr-readiness)

---

## ⏱️ 1. Οι Δύο Μετρικές που Καθορίζουν Τα Πάντα — RPO & RTO

Πριν αγγίξεις οποιοδήποτε backup tool, πρέπει να ξέρεις αυτούς τους δύο όρους — είναι αυτό που θα σε ρωτήσουν σε κάθε συνέντευξη senior θέσης, και αυτό που καθορίζει **πόσο συχνά** κάνεις backup και **πόσο γρήγορα** πρέπει να μπορείς να επανέλθεις.

| Όρος | Σημαίνει | Ερώτηση που απαντά |
|---|---|---|
| **RPO** (Recovery Point Objective) | Πόσα δεδομένα είναι αποδεκτό να χάσεις | "Πόσο παλιό backup είναι OK να restore;" |
| **RTO** (Recovery Time Objective) | Πόσος χρόνος είναι αποδεκτό να είσαι down | "Πόσο γρήγορα πρέπει να είμαστε ξανά online;" |

```
Παράδειγμα: File server με RPO = 4 ώρες, RTO = 2 ώρες

Σημαίνει:
  → Backup κάθε 4 ώρες (max), ώστε να μη χάνεις πάνω από 4 ώρες δουλειάς
  → Restore process πρέπει να ολοκληρώνεται μέσα σε 2 ώρες από το incident

Αυτό καθορίζει:
  → Τεχνολογία backup (snapshot-based αντί για tape, αν χρειάζεσαι γρήγορο RTO)
  → Συχνότητα (κάθε 4 ώρες, όχι μία φορά τη μέρα)
  → Πού αποθηκεύεται (local/fast storage για γρήγορο restore, όχι μόνο cloud/tape)
```

> 💡 **Real-world tip:** Το RPO/RTO **δεν** το αποφασίζεις εσύ μόνος σου ως IT — το αποφασίζει το business, μαζί με το IT. Ρώτα: "Αν χάσουμε το file server για μια μέρα, τι κοστίζει στην εταιρεία;" Η απάντηση καθορίζει πόσο investment αξίζει στο DR setup.

---

## 📖 2. Domain Controller Backup Θεωρία

### Γιατί το AD Backup είναι Διαφορετικό

Ένας DC **δεν** είναι απλά ένας server με αρχεία — είναι ένα **distributed database** που replikάρεται σε πολλαπλά μηχανήματα (βλέπε [`active-directory-advanced.md`](./active-directory-advanced.md#-2-replication)). Αυτό σημαίνει:

- Αν έχεις 2+ DCs, η **απώλεια ενός** δεν είναι καταστροφή — οι υπόλοιποι συνεχίζουν
- Το πρόβλημα είναι όταν χάνεις **δεδομένα που έχουν ήδη replikαριστεί παντού** (π.χ. accidental deletion ενός OU) — αυτό χρειάζεται ειδική διαδικασία, όχι απλό restore

### Tombstone Lifetime — Το "Ρολόι" του AD Backup

```
Όταν διαγράφεται ένα AD object:
    → Δεν εξαφανίζεται αμέσως, γίνεται "tombstoned" (marked for deletion)
    → Μένει σε αυτή την κατάσταση για το Tombstone Lifetime (default: 180 μέρες σε σύγχρονα AD)
    → Μετά, διαγράφεται οριστικά (garbage collection)

Συνέπεια: Ένα AD backup ΠΑΛΙΟΤΕΡΟ από το Tombstone Lifetime είναι ΑΧΡΗΣΤΟ
          (δεν μπορείς να το restore - το AD θα το απορρίψει ως "πολύ παλιό")
```

```powershell
# Έλεγχος του τρέχοντος Tombstone Lifetime
Get-ADObject "CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,DC=company,DC=local" `
    -Properties tombstoneLifetime | Select tombstoneLifetime
```

> ⚠️ **Πρακτικός κανόνας:** Το backup ενός DC είναι **άχρηστο** αν είναι παλιότερο από το tombstone lifetime (συνήθως 180 μέρες). Στην πράξη, κάνε backup **πολύ πιο συχνά** από αυτό — καθημερινά ή τουλάχιστον εβδομαδιαία — το tombstone lifetime είναι το απόλυτο ανώτατο όριο, όχι στόχος.

---

## 🚨 3. Σενάριο — Το Incident

> **Incident #INC-0091** — *"Ένας administrator διέγραψε κατά λάθος ολόκληρο το OU 'Sales' με 45 users μέσα, νομίζοντας ότι ήταν το test OU. Το replikαρίστηκε ήδη σε όλα τα DCs. Χρειαζόμαστε τους χρήστες πίσω ΤΩΡΑ — είναι μεσημέρι, όλοι στο Sales δεν μπορούν να κάνουν login."*

Αυτό είναι ένα από τα πιο κοινά real-world DR σενάρια — **όχι** hardware failure, αλλά **ανθρώπινο λάθος**. Δύο πιθανές λύσεις παρακάτω, ανάλογα με το πόσο πρόσφατη είναι η διαγραφή.

---

## ♻️ 4. Runbook #1: Backup Domain Controller

Πρώτα, το backup process που πρέπει να τρέχει **ήδη** πριν συμβεί οποιοδήποτε incident:

```powershell
# Windows Server Backup - System State backup (περιέχει AD database, SYSVOL, Registry)
# Εγκατάσταση του feature αν δεν υπάρχει
Install-WindowsFeature Windows-Server-Backup

# System State backup σε external/network target
wbadmin start systemstatebackup -backupTarget:E:\Backups -quiet

# Αυτοματοποίηση - scheduled daily backup
wbadmin enable backup -addtarget:E:\Backups -schedule:22:00 -systemState -quiet

# Επαλήθευση τελευταίου backup
wbadmin get versions
```

> 💡 **Real-world setup:** Οι περισσότερες εταιρείες **δεν** βασίζονται μόνο στο native `wbadmin` — χρησιμοποιούν enterprise backup λύσεις (Veeam, Commvault, Azure Backup) που κάνουν application-aware backup του AD, με πιο εύκολο granular restore. Το `wbadmin`/System State είναι καλό να το ξέρεις σαν baseline/fallback, αλλά σε πραγματική δουλειά συνήθως θα δουλεύεις πάνω σε κάποιο enterprise tool.

**Golden Rule: Backup τουλάχιστον 2 DCs**, ιδανικά σε διαφορετικά sites — αν ο DC που κάνεις backup είναι ο μόνος που χάνεις, δεν έχει νόημα.

---

## 🗑️ 5. Runbook #2: AD Object Recovery (Recycle Bin)

Αν το AD Recycle Bin είναι ενεργοποιημένο (πρέπει να είναι — δωρεάν feature, καμία δικαιολογία να μην είναι ενεργό), αυτό είναι **η πρώτη σου κίνηση**, πολύ πιο γρήγορη από full restore:

```powershell
# Έλεγχος αν είναι ενεργό (θα έπρεπε να έχει ενεργοποιηθεί ήδη πριν χρειαστεί)
Get-ADOptionalFeature -Filter "Name -eq 'Recycle Bin Feature'" | Select EnabledScopes

# Αν ΔΕΝ είναι ενεργό, ενεργοποίησέ το ΤΩΡΑ για το μέλλον (δεν σώζει το τρέχον incident αναδρομικά)
Enable-ADOptionalFeature "Recycle Bin Feature" `
    -Scope ForestOrConfigurationSet -Target "company.local"

# == Για το incident: restore του διαγραμμένου OU ==

# Βήμα 1: Εύρεση των deleted objects
Get-ADObject -Filter "isDeleted -eq `$true" -IncludeDeletedObjects |
    Where-Object { $_.DistinguishedName -like "*Sales*" }

# Βήμα 2: Restore του ίδιου του OU πρώτα (πρέπει να υπάρχει το container πριν τα objects μέσα του)
Get-ADObject -Filter "isDeleted -eq `$true" -IncludeDeletedObjects |
    Where-Object {$_.Name -eq "Sales"} |
    Restore-ADObject

# Βήμα 3: Restore όλων των users μέσα στο OU (μαζικά)
Get-ADObject -Filter "isDeleted -eq `$true" -IncludeDeletedObjects |
    Where-Object { $_.LastKnownParent -like "*OU=Sales*" } |
    Restore-ADObject

# Βήμα 4: Επαλήθευση
Get-ADUser -Filter * -SearchBase "OU=Sales,OU=Athens,DC=company,DC=local"
```

> ⚠️ **Σημαντικό detail:** Το AD Recycle Bin restore επαναφέρει το object **και τα περισσότερα attributes του** (συμπεριλαμβανομένου group memberships σε πολλές περιπτώσεις), αλλά **ΟΧΙ** πάντα το password hash με απόλυτη βεβαιότητα σε όλα τα σενάρια — πάντα επαλήθευσε ότι οι χρήστες μπορούν να κάνουν login μετά, και να είσαι έτοιμος για password reset αν χρειαστεί.

> 💡 Αυτό είναι γιατί το Recycle Bin είναι σχεδόν πάντα **γρηγορότερη** λύση από το Authoritative Restore (§6) — δεν χρειάζεται καθόλου reboot σε DSRM mode, δουλεύει live, μέσα σε λεπτά αντί για ώρες. Το authoritative restore χρειάζεται μόνο αν το Recycle Bin **δεν** ήταν ενεργό όταν έγινε η διαγραφή.

---

## 🔧 6. Runbook #3: Authoritative Restore

Χρησιμοποιείται όταν το Recycle Bin **δεν** ήταν ενεργό, ή όταν χρειάζεσαι να επαναφέρεις κατάσταση από **πολύ παλιότερο backup** (όχι απλή πρόσφατη διαγραφή).

```
⚠️ Αυτό το process ΣΤΑΜΑΤΑΕΙ τον DC από το να δέχεται live requests προσωρινά.
   Κάνε το ΜΟΝΟ αν το Recycle Bin restore (§5) δεν είναι διαθέσιμη επιλογή.
```

```powershell
# Βήμα 1: Reboot του DC σε Directory Services Restore Mode (DSRM)
bcdedit /set safeboot dsrepair
Restart-Computer

# Βήμα 2: Μετά το reboot σε DSRM, login με τον DSRM local administrator (ΟΧΙ domain account)

# Βήμα 3: Restore του System State backup
wbadmin start systemstaterecovery -version:09/23/2026-22:00 -backupTarget:E:\Backups -quiet

# Βήμα 4: Authoritative restore του συγκεκριμένου OU (μέσω ntdsutil)
ntdsutil
    activate instance ntds
    authoritative restore
        restore subtree "OU=Sales,OU=Athens,DC=company,DC=local"
    quit
quit

# Βήμα 5: Έξοδος από DSRM mode
bcdedit /deletevalue safeboot
Restart-Computer

# Βήμα 6: Επιβεβαίωση replication προς τα υπόλοιπα DCs (το authoritative restore "νικάει"
# το replication conflict - στέλνεται σε όλους τους άλλους DCs σαν πιο πρόσφατη αλλαγή)
repadmin /syncall /AdeP
```

> ⚠️ **Το πιο κρίσιμο σημείο σε authoritative restore:** Η λέξη "authoritative" σημαίνει ότι το restored data **θα αντικαταστήσει** ό,τι υπάρχει σε όλα τα άλλα DCs μέσω replication, ακόμα κι αν αυτά έχουν πιο "πρόσφατο" timestamp. Αν κάνεις λάθος OU/scope εδώ, μπορείς να προκαλέσεις **ΜΕΓΑΛΥΤΕΡΗ** ζημιά διαγράφοντας νεότερες αλλαγές που έγιναν μετά το backup. Πάντα διπλοέλεγξε το ακριβές distinguished name πριν εκτελέσεις το `restore subtree`.

---

## 💥 7. Runbook #4: Full DC Disaster Recovery (Bare Metal)

Όταν χάνεται **ολόκληρος** ο DC (hardware failure, corruption) και δεν είναι θέμα ενός object αλλά ολόκληρου server:

### Σενάριο Α: Υπάρχουν ΑΛΛΟΙ DCs στο domain

```powershell
# Η απλούστερη λύση - ΜΗΝ κάνεις restore τον παλιό DC. Απλά:

# Βήμα 1: Metadata cleanup - αφαίρεση των references του νεκρού DC από το AD
Get-ADDomainController -Filter *   # δες ποιοι υπάρχουν ακόμα

# Χρησιμοποίησε ntdsutil για metadata cleanup, ή:
Remove-ADComputer -Identity "DC02" -Confirm:$false   # αν το AD module το επιτρέπει καθαρά

# Βήμα 2: FSMO roles - αν ο νεκρός DC είχε FSMO roles, seize (όχι transfer, αφού είναι νεκρός)
# βλέπε active-directory-advanced.md §1 για πλήρη λίστα FSMO roles
Move-ADDirectoryServerOperationMasterRole -Identity "DC01" `
    -OperationMasterRole SchemaMaster,DomainNamingMaster,PDCEmulator,RIDMaster,InfrastructureMaster `
    -Force

# Βήμα 3: Promotion νέου server σε DC (καθαρό install, standard promotion process)
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
Install-ADDSDomainController -DomainName "company.local" -Credential (Get-Credential)

# Βήμα 4: Επαλήθευση replication υγείας
repadmin /replsummary
dcdiag /v
```

### Σενάριο Β: Ήταν ο ΤΕΛΕΥΤΑΙΟΣ DC (worst case)

```
Αυτό είναι το χειρότερο δυνατό σενάριο - ΔΕΝ υπάρχει άλλος DC να "ρωτήσεις".
Μόνη λύση: Non-authoritative restore από backup σε νέο hardware.

Βήμα 1: Νέο server, ίδιο hostname/IP όπως ο νεκρός DC (αν γίνεται)
Βήμα 2: Boot σε DSRM ή χρήση Windows Server Backup recovery environment
Βήμα 3: Full System State + full server restore από το τελευταίο backup
Βήμα 4: NON-authoritative restore (χωρίς ntdsutil authoritative restore βήμα -
         αφού δεν υπάρχει άλλος DC να κάνει conflict resolution)
Βήμα 5: Reboot κανονικά, επαλήθευση AD services
Βήμα 6: Fix FSMO roles (πιθανό να χρειαστούν seize αν ήταν πάνω σε αυτόν)
```

> ⚠️ **Γιατί "τελευταίος DC" είναι catastrophic:** Χωρίς κανέναν άλλο DC ζωντανό, δεν υπάρχει κανένα "authoritative" reference για να συγκρίνεις το backup — απλά ελπίζεις ότι το backup ήταν πρόσφατο και καλής ποιότητας. Αυτός είναι ο #1 λόγος που **κάθε** domain πρέπει να έχει τουλάχιστον 2 DCs, ιδανικά σε διαφορετικά sites/datacenters.

---

## 📸 8. File Server Backup — Shadow Copies (VSS)

Πριν φτάσεις σε "full restore από backup", το πρώτο επίπεδο άμυνας για file servers είναι το **Volume Shadow Copy Service (VSS)** — "Previous Versions", που επιτρέπει στους ίδιους τους χρήστες να κάνουν self-service restore χωρίς να χρειάζεται καν να ανοίξεις ticket.

```powershell
# Ενεργοποίηση Shadow Copies σε volume
Enable-Volume -DriveLetter E   # (ή μέσω vssadmin παλαιότερα)

vssadmin add shadowstorage /for=E: /on=E: /maxsize=20%

# Scheduled shadow copies (default 2x/μέρα, μπορείς να αλλάξεις)
vssadmin create shadow /for=E:

# Λίστα υπαρχόντων shadow copies
vssadmin list shadows /for=E:

# Ο χρήστης κάνει self-service restore:
# Δεξί κλικ στο file/folder → Properties → "Previous Versions" tab → Restore
```

> 💡 **Πραγματική επίπτωση:** Ένα σωστά ρυθμισμένο VSS σημαίνει ότι το **80%+ των "διέγραψα κατά λάθος ένα αρχείο"** tickets λύνονται από τον ίδιο τον χρήστη, χωρίς να χρειαστεί καν helpdesk ticket. Είναι μακράν το πιο αποδοτικό DR investment που μπορείς να κάνεις για file servers, με ελάχιστο effort setup.

---

## 💾 9. File Server Backup — Full/Incremental Strategy

| Τύπος | Τι κάνει | Πλεονέκτημα | Μειονέκτημα |
|---|---|---|---|
| **Full** | Backup ΟΛΩΝ των δεδομένων κάθε φορά | Restore = 1 βήμα, απλό | Αργό, μεγάλο σε storage |
| **Incremental** | Backup μόνο ό,τι άλλαξε από το ΤΕΛΕΥΤΑΙΟ backup (οποιουδήποτε τύπου) | Γρήγορο, μικρό σε storage | Restore = χρειάζεται ΟΛΗ την αλυσίδα (full + κάθε incremental) |
| **Differential** | Backup ό,τι άλλαξε από το ΤΕΛΕΥΤΑΙΟ full backup | Restore = μόνο 2 αρχεία (full + τελευταίο differential) | Μεγαλύτερο από incremental με τον καιρό |

```
Τυπικό real-world pattern (3-2-1 κανόνας):

3 αντίγραφα δεδομένων συνολικά (το πρωτότυπο + 2 backups)
2 διαφορετικά media/storage types (π.χ. local disk + cloud)
1 αντίγραφο OFF-SITE (διαφορετική τοποθεσία - προστασία από φωτιά/πλημμύρα/κλοπή)

Παράδειγμα εφαρμογής:
  Κυριακή:        Full backup       → Local NAS
  Δευτ-Σάβ:       Incremental       → Local NAS
  Κάθε βράδυ:     Replication       → Cloud (Azure Backup / AWS / off-site datacenter)
```

> ⚠️ Πολύ σημαντικό: **encryption** στα backups, ειδικά αυτά που πηγαίνουν off-site/cloud. Ένα backup που περιέχει ολόκληρο file server με ευαίσθητα δεδομένα, χωρίς encryption, είναι τεράστιο security risk αν κλαπεί το μέσο αποθήκευσης ή παραβιαστεί ο cloud λογαριασμός.

---

## 🦠 10. Ransomware Response — Ειδική Περίπτωση

Το πιο κρίσιμο real-world DR σενάριο σήμερα. Μερικά επιπλέον σημεία πέρα από το "κάνε restore":

| Βήμα | Γιατί |
|---|---|
| **1. Isolation πρώτα, restore μετά** | Αποσύνδεσε τα προσβεβλημένα μηχανήματα από το δίκτυο ΑΜΕΣΩΣ — το restore δεν έχει νόημα αν το ransomware εξακολουθεί να τρέχει και θα κρυπτογραφήσει ξανά |
| **2. ΠΟΤΕ restore πάνω από infected σύστημα** | Restore σε **καθαρό** hardware/VM, ποτέ πάνω από το μολυσμένο OS |
| **3. Backup immutability** | Αν τα backups είναι προσβάσιμα (write access) από το production δίκτυο, το ransomware μπορεί να τα κρυπτογραφήσει ΚΙ ΑΥΤΑ — γι' αυτό οι σύγχρονες λύσεις χρησιμοποιούν **immutable/air-gapped backups** |
| **4. Έλεγξε ΠΟΤΕ ξεκίνησε η μόλυνση** | Το restore σου πρέπει να είναι από backup **πριν** τη μόλυνση — αν κάνεις restore από μολυσμένο backup, ξεκινάς την κρίση από την αρχή |
| **5. Legal/Insurance/Authorities** | Σε πραγματικό incident, ενημέρωση management/legal/ασφαλιστικής είναι εξίσου σημαντικό με το τεχνικό restore |

> ⚠️ **Backup immutability δεν είναι προαιρετικό πλέον** — αν το backup account/storage είναι πλήρως προσβάσιμο (read/write) από το ίδιο δίκτυο που μπορεί να μολυνθεί, τότε δεν έχεις πραγματικό DR plan, έχεις απλά ένα δεύτερο target για το ransomware. Οι περισσότερες σύγχρονες λύσεις (Veeam, Azure Backup, AWS Backup Vault Lock) προσφέρουν immutable/WORM (Write Once Read Many) storage — ενεργοποίησέ το.

---

## 🧪 11. Testing Το Backup — Το Βήμα Που Όλοι Ξεχνάνε

```
Η πιο επικίνδυνη πρόταση στο IT: "Έχουμε backups" (χωρίς να τα έχεις δοκιμάσει ποτέ)
```

| Πρακτική | Συχνότητα |
|---|---|
| **Test restore** ενός τυχαίου αρχείου | Μηνιαία |
| **Full DR drill** — προσομοίωση απώλειας DC/server σε isolated test environment | Τουλάχιστον 2 φορές/χρόνο |
| **Verification** ότι τα backup jobs πράγματι έτρεξαν (όχι μόνο ότι είναι scheduled) | Καθημερινός έλεγχος (μπορεί να αυτοματοποιηθεί με alerting) |
| **Documentation update** μετά από κάθε αλλαγή υποδομής | Κάθε φορά που αλλάζει κάτι σημαντικό |

```powershell
# Automated check - στείλε alert αν το backup ΔΕΝ έτρεξε τις τελευταίες 24 ώρες
$lastBackup = wbadmin get versions | Select-String "Backup time"
# (Σε production, αυτό συνήθως γίνεται μέσω του backup tool's native monitoring/alerting,
#  ή μέσω PRTG/Nagios/Zabbix monitoring integration)
```

> 💡 **Πραγματική ιστορία που ακούς συχνά σε αυτόν τον κλάδο:** Εταιρεία έκανε backup για χρόνια, ποτέ δεν έκανε test restore, μέχρι που χρειάστηκε πραγματικά — και ανακάλυψε ότι τα backup αρχεία ήταν corrupted για μήνες. Το testing **δεν** είναι προαιρετικό βήμα, είναι το πιο σημαντικό μέρος ολόκληρης της διαδικασίας.

---

## 📝 12. Disaster Recovery Documentation — Runbook Template

Σε πραγματική εταιρεία, κατά τη διάρκεια ενός πραγματικού incident **δεν θέλεις να σκέφτεσαι** — θέλεις να ακολουθείς ήδη γραμμένο runbook. Έτσι μοιάζει ένα πραγματικό DR document entry:

```markdown
## DR Runbook: Domain Controller Failure

**Τελευταία ενημέρωση:** 2026-09-23
**Owner:** IT Infrastructure Team

### Πριν Ξεκινήσεις
- [ ] Επιβεβαίωσε ότι πραγματικά είναι DC failure (όχι network/connectivity issue)
- [ ] Ειδοποίησε IT Manager + άνοιξε incident ticket
- [ ] Έλεγξε αν υπάρχουν άλλοι healthy DCs: `Get-ADDomainController -Filter *`

### Αν Υπάρχουν Άλλοι Healthy DCs
1. Metadata cleanup του νεκρού DC (§7, Σενάριο Α)
2. Seize FSMO roles αν χρειάζεται
3. Provision νέου DC
4. Verify replication: `repadmin /replsummary`

### Αν ΔΕΝ Υπάρχουν Άλλοι Healthy DCs (Worst Case)
1. ⚠️ ΕΣΚΑΛΩΣΕ ΑΜΕΣΩΣ σε Senior/Manager - αυτό ΔΕΝ είναι solo-decision επίπεδο
2. Ακολούθησε §7 Σενάριο Β (full restore)
3. Estimated RTO: 4-6 ώρες

### Επικοινωνίες
- IT Manager: [τηλέφωνο/email]
- Backup vendor support: [ticket portal/τηλέφωνο]
- Business stakeholders που πρέπει να ενημερωθούν: [λίστα]

### Post-Incident
- [ ] Root cause analysis
- [ ] Ενημέρωση αυτού του runbook αν βρέθηκε κάτι νέο
- [ ] Incident report προς management
```

> 💡 Αυτού του τύπου documentation είναι αυτό που ξεχωρίζει junior από senior admin σε πραγματική κρίση — δεν προσπαθείς να θυμηθείς τα βήματα υπό πίεση, τα διαβάζεις από ένα ήδη δοκιμασμένο runbook.

---

## ✅ 13. Checklist — DR Readiness

```
☐ Τουλάχιστον 2 DCs, ιδανικά σε διαφορετικά physical sites
☐ AD Recycle Bin ενεργοποιημένο
☐ System State backup scheduled σε ΚΑΘΕ DC, τουλάχιστον καθημερινά
☐ File server backups ακολουθούν 3-2-1 κανόνα (3 αντίγραφα, 2 media types, 1 off-site)
☐ Backups είναι encrypted
☐ Backups είναι immutable/air-gapped (προστασία από ransomware)
☐ Shadow Copies (VSS) ενεργά σε file servers - self-service restore
☐ RPO/RTO καθορισμένα και συμφωνημένα με το business, όχι μόνο IT υπόθεση
☐ Test restore γίνεται τακτικά (μηνιαία για files, εξαμηνιαία για full DR drill)
☐ DR runbook documentation υπάρχει, ενημερωμένο, εύκολα προσβάσιμο ΚΑΙ offline
  (αν ο μόνος τρόπος πρόσβασης στο runbook είναι μέσω του συστήματος που μόλις κατέρρευσε, έχεις πρόβλημα)
☐ Ξεκάθαρη λίστα επικοινωνιών/escalation path για πραγματικό incident
☐ FSMO role locations τεκμηριωμένα (ποιος DC έχει τι - βλέπε active-directory-advanced.md §1)
```

---

## 📚 Σχετικά αρχεία

- [`active-directory.md`](./active-directory.md) — Users/Groups, OUs, GPO βασικά
- [`active-directory-advanced.md`](./active-directory-advanced.md) — FSMO Roles §1, Replication §2, Trusts
- [`file-permissions-ntfs.md`](./file-permissions-ntfs.md) — NTFS/Share permissions θεωρία
- [`file-server-implementation-runbook.md`](./file-server-implementation-runbook.md) — Real-world file share deployment
- [`dns-dhcp-administration.md`](./dns-dhcp-administration.md) — DNS/DHCP θεωρία + runbook
- [`group-policy-deep-dive.md`](./group-policy-deep-dive.md) — GPO processing, real-world runbooks
- [`print-server-management.md`](./print-server-management.md) — Print server setup, permissions
- Αυτό το αρχείο (`backup-disaster-recovery.md`) — RPO/RTO, AD recovery, ransomware response, DR documentation
