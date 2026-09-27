# 🛡️ Active Directory Security Hardening & Attacks
> Συνοδευτικό αρχείο στη σειρά Active Directory. Μέχρι τώρα μάθαμε πώς **στήνεις** AD — αυτό το αρχείο δείχνει πώς **επιτίθενται** σε ένα AD environment, και πώς αμύνεσαι. Είναι το θέμα που πραγματικά ξεχωρίζει ένα profile σήμερα, ακόμα κι αν δεν στοχεύεις καθαρά security role.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Γιατί το AD είναι το #1 Στόχος Επιτιθέμενων](#-1-γιατί-το-ad-είναι-το-1-στόχος-επιτιθέμενων)
2. [Το Tiered Administration Model — Η Βάση Όλης της Άμυνας](#-2-το-tiered-administration-model--η-βάση-όλης-της-άμυνας)
3. [Σενάριο — Το Security Audit](#-3-σενάριο--το-security-audit)
4. [Επίθεση #1: Kerberoasting](#-4-επίθεση-1-kerberoasting)
5. [Επίθεση #2: Pass-the-Hash & Pass-the-Ticket](#-5-επίθεση-2-pass-the-hash--pass-the-ticket)
6. [Επίθεση #3: Golden Ticket & Silver Ticket](#-6-επίθεση-3-golden-ticket--silver-ticket)
7. [Επίθεση #4: AS-REP Roasting](#-7-επίθεση-4-as-rep-roasting)
8. [Άμυνα #1: LAPS — Local Administrator Password Solution](#-8-άμυνα-1-laps--local-administrator-password-solution)
9. [Άμυνα #2: Protected Users Group](#-9-άμυνα-2-protected-users-group)
10. [Άμυνα #3: AdminSDHolder & Protected Accounts](#-10-άμυνα-3-adminsdholder--protected-accounts)
11. [Άμυνα #4: Break-Glass Emergency Account](#-11-άμυνα-4-break-glass-emergency-account)
12. [Detection — Τι Events Παρακολουθείς](#-12-detection--τι-events-παρακολουθείς)
13. [Runbook: Πλήρες Hardening Pass σε Υπάρχον AD](#-13-runbook-πλήρες-hardening-pass-σε-υπάρχον-ad)
14. [Checklist — Security Baseline](#-14-checklist--security-baseline)

---

## 🎯 1. Γιατί το AD είναι το #1 Στόχος Επιτιθέμενων

Το Active Directory είναι το **σημείο ελέγχου** ολόκληρου του δικτύου — αν κάποιος αποκτήσει Domain Admin, ελέγχει κυριολεκτικά τα πάντα: κάθε server, κάθε workstation, κάθε αρχείο. Γι' αυτό στο 90%+ των πραγματικών ransomware/breach περιστατικών, το AD compromise είναι το **κεντρικό βήμα** — όχι απλά ένα ακόμα σύστημα.

```
Τυπική αλυσίδα μιας πραγματικής επίθεσης:

1. Initial Access     → Phishing email, μολυσμένο PC ενός απλού χρήστη
2. Local Privilege    → Exploit, ή απλά local admin σε αυτό το PC
3. Credential Access  → Kerberoasting/Pass-the-Hash (§4-6) - "κλέβει" credentials από τη μνήμη/δίκτυο
4. Lateral Movement   → Χρήση των credentials για να φτάσει σε ΑΛΛΑ μηχανήματα
5. Privilege Escalation → Μέχρι να βρει/αποκτήσει Domain Admin credentials
6. Domain Dominance   → Golden Ticket (§6) - πλέον ελέγχει ΟΛΟΚΛΗΡΟ το domain, ακόμα κι αν
                         αλλάξεις όλους τους κωδικούς, το golden ticket συνεχίζει να δουλεύει
```

> 💡 Αυτό που κάνει τη δουλειά σου δύσκολη: οι περισσότερες από αυτές τις τεχνικές **δεν εκμεταλλεύονται bugs** — εκμεταλλεύονται **legitimate λειτουργίες** του Kerberos/AD. Δεν μπορείς να τις "κλείσεις" με ένα patch, χρειάζεται σωστό **architectural hardening**.

---

## 🏛️ 2. Το Tiered Administration Model — Η Βάση Όλης της Άμυνας

Αναφέρθηκε σύντομα στο [`active-directory-advanced.md`](./active-directory-advanced.md) — εδώ το αναλύουμε πλήρως, γιατί είναι η **θεμελιώδης αρχή** πίσω από όλα τα defenses παρακάτω.

```
Tier 0  → Domain Controllers, Domain Admins, οτιδήποτε ελέγχει το ίδιο το AD
Tier 1  → Servers (file servers, app servers, databases)
Tier 2  → Workstations, end-user devices

ΧΡΥΣΟΣ ΚΑΝΟΝΑΣ: Ένας λογαριασμός με πρόσβαση σε Tier X ΔΕΝ πρέπει ΠΟΤΕ
                να κάνει login σε μηχάνημα χαμηλότερου tier.

Παράδειγμα παραβίασης του κανόνα (πολύ συχνό σε πραγματικές εταιρείες):
  Domain Admin κάνει login στο δικό του καθημερινό PC (Tier 2) για να ελέγξει κάτι
    → Το password hash του Domain Admin μένει στη μνήμη αυτού του PC (Tier 2)
    → Αν το PC μολυνθεί (π.χ. phishing), ο επιτιθέμενος παίρνει credentials
       ΤΟΥ ΙΔΙΟΥ ΕΠΙΠΕΔΟΥ ΜΕ DOMAIN ADMIN — game over για ολόκληρο το domain
```

**Γιατί έχει σημασία εδώ:** Kerberoasting, Pass-the-Hash, Golden Ticket — όλα αυτά τα attacks γίνονται **εκθετικά πιο επικίνδυνα** όταν το tiering δεν τηρείται. Το tiering δεν σταματάει την αρχική μόλυνση, αλλά σταματάει την **κλιμάκωση** από "μολύνθηκε ένα απλό PC" σε "χάθηκε ολόκληρο το domain".

| Πρακτική εφαρμογή | Τι σημαίνει |
|---|---|
| **Privileged Access Workstations (PAW)** | Οι Domain Admins κάνουν sensitive εργασίες ΜΟΝΟ από ειδικά, sealed workstations — ποτέ από το καθημερινό τους PC |
| **Ξεχωριστοί λογαριασμοί** | `d.katsanos` (καθημερινός χρήστης) vs `admin-d.katsanos` (Domain Admin, χρησιμοποιείται ΜΟΝΟ σε Tier 0 tasks) |
| **Ποτέ RDP από Tier 2 σε Tier 0** | Log in σε DC απευθείας από Tier 0 machine, ποτέ jump από απλό PC |

---

## 🎫 3. Σενάριο — Το Security Audit

> **Ticket #SEC-2201** — *"Εξωτερικός security auditor έκανε assessment και βρήκε: (1) service accounts με SPNs και αδύναμους κωδικούς — ευάλωτα σε Kerberoasting. (2) Local Administrator password είναι το ΙΔΙΟ σε όλα τα workstations. (3) Δεν υπάρχει διαχωρισμός μεταξύ κανονικών και admin λογαριασμών. Χρειαζόμαστε remediation plan."*

Αυτά τα 3 ευρήματα είναι **εξαιρετικά κοινά** σε πραγματικά audits — και κάθε ένα έχει συγκεκριμένη λύση παρακάτω.

---

## ⚔️ 4. Επίθεση #1: Kerberoasting

### Πώς Δουλεύει (σε επίπεδο κατανόησης, όχι εκτέλεσης attack)

```
1. Οποιοσδήποτε authenticated domain user (ΑΚΟΜΑ ΚΙ ΕΝΑΣ ΑΠΛΟΣ USER, όχι admin) μπορεί
   να ζητήσει Kerberos service ticket για ΟΠΟΙΟΝΔΗΠΟΤΕ service που έχει SPN
   (Service Principal Name) καταχωρημένο

2. Το service ticket που επιστρέφεται είναι κρυπτογραφημένο με το PASSWORD HASH
   του service account (π.χ. ενός SQL Server service account)

3. Ο επιτιθέμενος παίρνει αυτό το ticket OFFLINE, και προσπαθεί να το "σπάσει"
   (brute-force/dictionary attack) χωρίς να χρειάζεται καν να ξαναεπικοινωνήσει
   με το δίκτυο - αργό αλλά αθόρυβο

4. Αν το password του service account είναι αδύναμο (π.χ. "Summer2023!"),
   σπάει μέσα σε ώρες/μέρες - και τώρα ο επιτιθέμενος έχει τα credentials
   ενός service account, που ΣΥΧΝΑ έχει υψηλά privileges
```

### Γιατί Είναι Τόσο Επικίνδυνο

Service accounts (π.χ. για SQL Server, IIS application pools) συχνά:
- Έχουν **παλιούς, ποτέ-δεν-άλλαξαν κωδικούς** (κανείς δεν θέλει να σπάσει το production service κάνοντας password reset)
- Έχουν **υψηλά privileges** (χρειάζονται πρόσβαση σε βάσεις δεδομένων, file shares, κ.λπ.)
- Ο κωδικός τους **δεν** ακολουθεί πάντα το ίδιο αυστηρό password policy με τους κανονικούς users

### Άμυνα

```powershell
# Βήμα 1: Εύρεση όλων των accounts με SPN (πιθανοί στόχοι Kerberoasting)
Get-ADUser -Filter {ServicePrincipalName -like "*"} -Properties ServicePrincipalName, PasswordLastSet |
    Select Name, ServicePrincipalName, PasswordLastSet

# Βήμα 2: Έλεγχος ΠΟΤΕ άλλαξε τελευταία φορά ο κωδικός (κόκκινη σημαία αν είναι χρόνια παλιός)
Get-ADUser -Filter {ServicePrincipalName -like "*"} -Properties PasswordLastSet |
    Where-Object {$_.PasswordLastSet -lt (Get-Date).AddDays(-365)} |
    Select Name, PasswordLastSet

# Η ΠΡΑΓΜΑΤΙΚΗ λύση: Migration σε gMSA (Group Managed Service Account) όπου γίνεται -
# αυτόματο, τυχαίο, 120-character password που αλλάζει μόνο του κάθε 30 μέρες,
# ΚΑΝΕΙΣ δεν ξέρει/χρειάζεται να ξέρει τον κωδικό

# Αν gMSA δεν είναι εφικτό (legacy app που δεν το υποστηρίζει):
# - Πολύ μεγάλος, τυχαίος κωδικός (25+ χαρακτήρες) - δύσκολο να σπάσει ακόμα κι offline
# - Regular rotation
# - AES encryption για τα Kerberos tickets (όχι RC4 - πιο αδύναμο)
Set-ADUser -Identity "svc-sqlserver" -KerberosEncryptionType AES256
```

> ⚠️ **Το πιο σημαντικό detail:** Kerberoasting **δεν χρειάζεται καθόλου admin rights** για να ξεκινήσει — οποιοσδήποτε authenticated user μπορεί να ζητήσει service tickets. Αυτό σημαίνει ότι **ένας απλός compromised user account** (π.χ. από phishing) είναι αρκετός για να ξεκινήσει αυτή την επίθεση. Δεν είναι θέμα "αν κάποιος πάρει admin" — είναι θέμα "από τη στιγμή που ΟΠΟΙΟΣΔΗΠΟΤΕ compromised."

---

## 🔑 5. Επίθεση #2: Pass-the-Hash & Pass-the-Ticket

```
Pass-the-Hash (PtH):
  Ο επιτιθέμενος αποκτά το NTLM password HASH (όχι το ίδιο το password) από τη
  μνήμη ενός μολυσμένου μηχανήματος (π.χ. μέσω εργαλείων σαν Mimikatz).
  Στο NTLM protocol, ΔΕΝ χρειάζεται να "σπάσει" το hash σε plaintext -
  μπορεί να το χρησιμοποιήσει ΑΠΕΥΘΕΙΑΣ για να κάνει authenticate σε άλλα μηχανήματα.

Pass-the-Ticket (PtT):
  Παρόμοιο, αλλά κλέβει ολόκληρο Kerberos ticket (όχι hash) από τη μνήμη,
  και το "ξαναχρησιμοποιεί" για να αυθεντικοποιηθεί σαν να ήταν ο νόμιμος χρήστης.
```

### Άμυνα

| Μέτρο | Πώς βοηθά |
|---|---|
| **Tiered admin model (§2)** | Αν Domain Admin ΠΟΤΕ δεν κάνει login σε Tier 2 μηχάνημα, το hash του δεν μπορεί ποτέ να "κλαπεί" από εκεί |
| **Local Admin Password διαφορετικός ανά μηχάνημα (§8, LAPS)** | Χωρίς αυτό, το ίδιο local admin hash δουλεύει ΠΑΝΤΟΥ — ένα compromised μηχάνημα = compromised όλα |
| **Credential Guard** (Windows feature) | Απομονώνει τα credentials σε virtualization-based security, δυσκολεύει πολύ το memory dumping |
| **Protected Users group (§9)** | Αποτρέπει καθόλου NTLM authentication και caching για sensitive accounts |

```powershell
# Ενεργοποίηση Credential Guard (μέσω GPO - Device Guard/Credential Guard policies)
# Computer Configuration → Administrative Templates → System → Device Guard
# → "Turn On Virtualization Based Security" → Enabled
# → Credential Guard Configuration: "Enabled with UEFI lock"
```

---

## 👑 6. Επίθεση #3: Golden Ticket & Silver Ticket

Αυτό είναι το **χειρότερο δυνατό σενάριο** — αν συμβεί, το AD θεωρείται πλήρως compromised, και η μόνη πραγματική λύση είναι rebuild.

```
Golden Ticket:
  Χρειάζεται το password hash του ειδικού λογαριασμού "krbtgt" (υπάρχει
  ΕΝΑΣ σε κάθε domain, χρησιμοποιείται εσωτερικά από το Kerberos για να
  υπογράφει ΟΛΑ τα tickets).

  Αν ο επιτιθέμενος αποκτήσει αυτό το hash (συνήθως μετά από ήδη Domain Admin
  compromise), μπορεί να φτιάξει tickets που:
    - Δουλεύουν για ΟΠΟΙΟΝΔΗΠΟΤΕ χρήστη (ακόμα και χρήστες που δεν υπάρχουν πια)
    - Δίνουν ΟΠΟΙΑΔΗΠΟΤΕ privileges θέλει (π.χ. Domain Admin, ακόμα κι αν αυτός
      ο λογαριασμός δεν είναι πραγματικά Domain Admin)
    - Είναι έγκυρα για ΧΡΟΝΙΑ (default: 10 χρόνια!)
    - ΣΥΝΕΧΙΖΟΥΝ ΝΑ ΔΟΥΛΕΥΟΥΝ ΑΚΟΜΑ ΚΙ ΑΝ αλλάξεις ΟΛΟΥΣ τους κανονικούς κωδικούς

Silver Ticket:
  Παρόμοιο αλλά πιο "περιορισμένο" - χρησιμοποιεί το hash ενός SPECIFIC
  service account αντί για το krbtgt, δίνει πρόσβαση μόνο σε αυτό το service,
  αλλά είναι πιο δύσκολο να ανιχνευθεί (δεν επικοινωνεί καν με τον DC).
```

### Γιατί Δεν Το "Διορθώνεις" Απλά Αλλάζοντας Κωδικούς

```
Λάθος αντίδραση: "Άλλαξα όλους τους κωδικούς, είμαστε ασφαλείς τώρα"
Πραγματικότητα: Το golden ticket ΔΕΝ βασίζεται σε κανέναν κανονικό user password -
                βασίζεται στο krbtgt hash, που ΔΕΝ αλλάζει με κανονικό password reset.

Σωστή αντίδραση σε επιβεβαιωμένο Golden Ticket compromise:
  1. Αλλαγή του krbtgt password ΔΥΟ φορές (χρειάζεται 2x - βλέπε γιατί παρακάτω)
  2. Πλήρες incident response investigation - πώς μπήκε ο επιτιθέμενος αρχικά
  3. Σε πολλές περιπτώσεις: πλήρες rebuild του forest θεωρείται απαραίτητο
```

```powershell
# Αλλαγή krbtgt password (χρειάζεται ΔΥΟ φορές με απόσταση, ΠΟΤΕ μία φορά)
# Γιατί δύο φορές: Το AD κρατάει το password history (τρέχον + προηγούμενο) για
# το krbtgt - αν αλλάξεις μόνο μία φορά, tickets φτιαγμένα με το ΠΑΛΙΟ password
# συνεχίζουν να δουλεύουν μέχρι να λήξουν φυσικά. Δύο αλλαγές invalidate και τα δύο.

# ΠΡΟΣΟΧΗ: Αυτό είναι disruptive operation - κάνε το με σωστό planning,
# ιδανικά με βοήθεια από Microsoft support σε production incident, όχι σαν πρώτη κίνηση solo.
$krbtgt = Get-ADUser -Identity krbtgt
Set-ADAccountPassword -Identity krbtgt -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "RandomComplexPassword1!" -Force)
# Περίμενε replication να ολοκληρωθεί σε όλα τα DCs (repadmin /replsummary)
# Μετά ΞΑΝΑ:
Set-ADAccountPassword -Identity krbtgt -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "AnotherRandomComplexPassword2!" -Force)
```

> ⚠️ Αυτό είναι το μόνο σημείο σε ολόκληρη τη σειρά αρχείων όπου λέμε ξεκάθαρα: **αν βρεθείς σε επιβεβαιωμένο Golden Ticket incident, μην το χειριστείς μόνος σου χωρίς escalation.** Είναι από τα πιο σοβαρά πιθανά AD incidents, και η σωστή αντιμετώπιση χρειάζεται συνήθως incident response ειδικούς, όχι μόνο έναν sysadmin.

---

## 🎟️ 7. Επίθεση #4: AS-REP Roasting

```
Παρόμοιο με Kerberoasting (§4), αλλά στοχεύει accounts που έχουν
"Do not require Kerberos preauthentication" ενεργό.

Χωρίς preauthentication, ο επιτιθέμενος μπορεί να ζητήσει AS-REP response
για ΟΠΟΙΟΝΔΗΠΟΤΕ τέτοιο λογαριασμό ΧΩΡΙΣ ΚΑΝ να χρειάζεται να κάνει authenticate
πρώτα - ακόμα πιο εύκολο/αθόρυβο από Kerberoasting.
```

```powershell
# Εύρεση accounts με αυτό το (επικίνδυνο) setting ενεργό
Get-ADUser -Filter {DoesNotRequirePreAuth -eq $true} -Properties DoesNotRequirePreAuth

# Αν βρεθεί κάποιο (σχεδόν πάντα legacy setting, σπάνια σκόπιμο) - απενεργοποίησέ το
Set-ADAccountControl -Identity "old-legacy-account" -DoesNotRequirePreAuth $false
```

> 💡 Αυτό το setting σχεδόν ποτέ δεν χρειάζεται πραγματικά σήμερα — αν το βρεις ενεργό σε audit, είναι σχεδόν σίγουρα κατάλοιπο από πολύ παλιά εφαρμογή/misconfiguration, όχι σκόπιμη ρύθμιση.

---

## 🔐 8. Άμυνα #1: LAPS — Local Administrator Password Solution

Λύνει ακριβώς το πρόβλημα του ticket: **"Local Administrator password είναι το ίδιο σε όλα τα workstations."** Αν έστω ένα μηχάνημα μολυνθεί, ο επιτιθέμενος έχει αμέσως local admin σε **όλα** τα υπόλοιπα.

```powershell
# Βήμα 1: Εγκατάσταση LAPS (Windows LAPS είναι πλέον built-in σε σύγχρονο Windows Server/11)
# Σε παλιότερα, χρειάζεται download το Microsoft LAPS tool

# Βήμα 2: Schema extension (μία φορά, χρειάζεται Schema Admin rights)
Update-LapsADSchema

# Βήμα 3: Ορισμός permissions - ποιοι μπορούν να ΔΙΑΒΑΣΟΥΝ τους αποθηκευμένους κωδικούς
Set-LapsADReadPasswordPermission -Identity "OU=Workstations,DC=company,DC=local" `
    -AllowedPrincipals "IT-Helpdesk"

Set-LapsADResetPasswordPermission -Identity "OU=Workstations,DC=company,DC=local" `
    -AllowedPrincipals "IT-Helpdesk"

# Βήμα 4: GPO configuration - ενεργοποίηση LAPS σε target OU
# Computer Configuration → Policies → Administrative Templates → LAPS
# → "Enable Windows LAPS" → Enabled
# → "Password Settings" → όρισε complexity, length (14+ χαρακτήρες), age (30 μέρες default)

# Βήμα 5: Ανάγνωση password ενός συγκεκριμένου μηχανήματος (όταν χρειάζεται πραγματικά)
Get-LapsADPassword -Identity "PC-MKT-042" -AsPlainText
```

**Πώς δουλεύει:**

```
Κάθε μηχάνημα → μοναδικός, τυχαίος local admin κωδικός → αποθηκευμένος
κρυπτογραφημένα στο AD → αυτόματη εναλλαγή κάθε 30 μέρες (default)

Αποτέλεσμα: Ακόμα κι αν ο επιτιθέμενος αποκτήσει local admin σε ΕΝΑ μηχάνημα,
ΔΕΝ έχει τίποτα χρήσιμο για τα υπόλοιπα - κάθε κωδικός είναι διαφορετικός.
```

> 💡 Αυτό είναι από τα **φθηνότερα σε effort, μεγαλύτερα σε αντίκτυπο** security improvements που μπορείς να κάνεις — δωρεάν, built-in feature, μπορεί να στηθεί σε ένα απόγευμα, και κλείνει ένα από τα πιο συχνά ευρήματα κάθε security audit.

---

## 🔒 9. Άμυνα #2: Protected Users Group

Ειδικό built-in security group που, όταν ένας λογαριασμός γίνει μέλος, εφαρμόζει αυτόματα πολλαπλά hardening μέτρα ταυτόχρονα — χωρίς να χρειάζεται να τα ρυθμίσεις ένα-ένα:

| Τι αλλάζει αυτόματα | Γιατί βοηθά |
|---|---|
| Απαγορεύεται εντελώς NTLM authentication | Το NTLM είναι πιο ευάλωτο σε Pass-the-Hash (§5) |
| Απαγορεύεται DES/RC4 encryption στο Kerberos | Πιο αδύναμη κρυπτογράφηση, ευκολότερο να σπάσει |
| Δεν επιτρέπεται credential caching/delegation | Λιγότερα "ίχνη" credentials σε μνήμη μηχανημάτων |
| Kerberos ticket lifetime μειωμένο σε 4 ώρες | Ακόμα κι αν κλαπεί ticket, λήγει γρήγορα |

```powershell
# Προσθήκη λογαριασμού (ΜΟΝΟ Tier 0 admin accounts - όχι κανονικοί χρήστες)
Add-ADGroupMember -Identity "Protected Users" -Members "admin-d.katsanos"
```

> ⚠️ **Πρόσεχε πριν προσθέσεις οποιονδήποτε εδώ:** Επειδή απενεργοποιεί εντελώς NTLM, μπορεί να **σπάσει** legacy εφαρμογές που ακόμα βασίζονται σε NTLM authentication. Πάντα δοκίμασε πρώτα σε test/non-production λογαριασμό, ποτέ απευθείας σε production Domain Admin χωρίς testing.

---

## 🛡️ 10. Άμυνα #3: AdminSDHolder & Protected Accounts

Το AD έχει ένα built-in μηχανισμό που **προστατεύει αυτόματα** τα permissions πάνω σε privileged accounts (Domain Admins, Enterprise Admins, κ.λπ.) — κάθε 60 λεπτά, ένα background process (SDProp) επαναφέρει τα permissions αυτών των accounts σε ένα "template" (AdminSDHolder object), ακόμα κι αν κάποιος (κακόβουλα ή κατά λάθος) τα άλλαξε.

```powershell
# Προβολή του AdminSDHolder template (το "μοτίβο" permissions που επιβάλλεται)
Get-ADObject "CN=AdminSDHolder,CN=System,DC=company,DC=local" -Properties nTSecurityDescriptor

# Εύρεση ποιοι λογαριασμοί προστατεύονται αυτόματα αυτή τη στιγμή
Get-ADUser -Filter {adminCount -eq 1} -Properties adminCount, MemberOf |
    Select Name, MemberOf
```

> 💡 **Πρακτικό detail:** Αν αφαιρέσεις έναν χρήστη από το Domain Admins group, το `adminCount=1` flag **ΔΕΝ** αφαιρείται αυτόματα — μένει "κολλημένο" πάνω του, μαζί με τα restrictive permissions. Αυτό είναι γνωστό quirk που μπερδεύει πολλούς admins ("γιατί δεν μπορώ να αλλάξω permissions σε αυτόν τον πρώην-admin user;") — χρειάζεται χειροκίνητο clean-up αν θες να "καθαρίσεις" πλήρως έναν πρώην privileged λογαριασμό.

---

## 🚨 11. Άμυνα #4: Break-Glass Emergency Account

Σε ένα πραγματικό incident (π.χ. ransomware, ή ακόμα και Golden Ticket §6), μπορεί να χρειαστείς πρόσβαση σε Domain Admin **όταν όλα τα υπόλοιπα admin accounts είναι πιθανώς compromised ή απενεργοποιημένα**. Γι' αυτό, κάθε σωστά σχεδιασμένο environment έχει έναν ή δύο **break-glass accounts**:

```
Χαρακτηριστικά ενός σωστού break-glass account:
  - Domain Admin (ή Enterprise Admin) rights
  - ΔΕΝ χρησιμοποιείται ΠΟΤΕ στην καθημερινότητα (μόνο σε πραγματικό emergency)
  - Password αποθηκευμένο σε ΦΥΣΙΚΟ, κλειδωμένο μέρος (π.χ. safe), ΟΧΙ σε password manager
    που μπορεί να είναι απρόσιτος αν το ίδιο το IT infrastructure είναι down
  - Εξαιρείται από MFA/Conditional Access policies που θα μπορούσαν να το κλειδώσουν έξω
    σε ένα πραγματικό outage (π.χ. αν το MFA provider είναι επίσης down)
  - Monitored - ΟΠΟΙΑΔΗΠΟΤΕ χρήση του δημιουργεί άμεσο alert (γιατί ΔΕΝ θα έπρεπε ποτέ
    να χρησιμοποιείται εκτός emergency)
```

```powershell
# Δημιουργία (μία φορά, με πολύ προσεκτικό process)
New-ADUser -Name "BreakGlass-Emergency-Admin" `
    -SamAccountName "svc-breakglass01" `
    -Enabled $true `
    -PasswordNeverExpires $true `
    -CannotChangePassword $true `
    -AccountPassword (ConvertTo-SecureString "VeryLongRandomPassword..." -AsPlainText -Force)

Add-ADGroupMember -Identity "Domain Admins" -Members "svc-breakglass01"

# Audit alerting - ΟΠΟΙΑΔΗΠΟΤΕ login με αυτό το account πρέπει να δημιουργεί άμεσο alert
# (ρυθμίζεται μέσω SIEM/monitoring στο event ID 4624 φιλτραρισμένο σε αυτό το account - §12)
```

---

## 👁️ 12. Detection — Τι Events Παρακολουθείς

| Event ID | Σημασία | Γιατί το παρακολουθείς |
|---|---|---|
| **4768** | Kerberos TGT requested | Ασυνήθιστος όγκος από ένα account → πιθανό Kerberoasting attempt |
| **4769** | Kerberos service ticket requested | Πολλαπλά ΔΙΑΦΟΡΕΤΙΚΑ SPNs από τον ίδιο χρήστη μέσα σε λίγο χρόνο → Kerberoasting |
| **4672** | Λογαριασμός με "special privileges" έκανε login | Επιβεβαίωση ΠΟΤΕ χρησιμοποιείται admin account — σύγκρινε με αναμενόμενο pattern |
| **4624** | Επιτυχές login | Filter για break-glass account (§11) - ΟΠΟΙΑΔΗΠΟΤΕ εμφάνιση = alert |
| **4625** | Αποτυχημένο login | Πολλαπλά σε σειρά → πιθανό brute-force |
| **4670** | Permissions άλλαξαν σε object | Ασυνήθιστες αλλαγές σε privileged accounts → πιθανό AdminSDHolder tampering |
| **5136** | AD object τροποποιήθηκε | Ευρύ, αλλά χρήσιμο για audit trail σε critical OUs |

```powershell
# Γρήγορη αναζήτηση για ύποπτο Kerberoasting pattern (πολλαπλά 4769 events από ίδιο user)
Get-WinEvent -LogName Security -FilterXPath "*[System[EventID=4769]]" -MaxEvents 500 |
    Group-Object {$_.Properties[0].Value} |
    Where-Object {$_.Count -gt 20} |
    Select Name, Count
```

> 💡 Σε πραγματική εταιρεία, αυτά τα logs **δεν** τα παρακολουθείς χειροκίνητα καθημερινά — τα στέλνεις σε SIEM (Splunk, Microsoft Sentinel, κ.λπ.) με ήδη φτιαγμένα detection rules/alerts για αυτά τα patterns. Το manual querying είναι χρήσιμο για investigation μετά από alert, όχι για day-to-day monitoring.

---

## 🛠️ 13. Runbook: Πλήρες Hardening Pass σε Υπάρχον AD

Έτσι θα προσέγγιζες το ticket #SEC-2201 στην πράξη, βήμα-βήμα:

```powershell
# ===== ΦΑΣΗ 1: Assessment - βρες το πραγματικό μέγεθος του προβλήματος =====

# Service accounts με SPN και παλιό password
Get-ADUser -Filter {ServicePrincipalName -like "*"} -Properties ServicePrincipalName, PasswordLastSet |
    Where-Object {$_.PasswordLastSet -lt (Get-Date).AddDays(-180)} |
    Export-Csv "C:\Audit\kerberoastable-accounts.csv"

# Accounts χωρίς preauthentication
Get-ADUser -Filter {DoesNotRequirePreAuth -eq $true} |
    Export-Csv "C:\Audit\asrep-roastable-accounts.csv"

# Λογαριασμοί με adminCount=1 (πρώην/τρέχοντες privileged - βλέπε §10)
Get-ADUser -Filter {adminCount -eq 1} -Properties adminCount |
    Export-Csv "C:\Audit\privileged-accounts.csv"

# ===== ΦΑΣΗ 2: Quick Wins (χαμηλό effort, μεγάλο αντίκτυπο) =====
# 1. Deploy LAPS (§8) - λύνει το "ίδιος local admin password παντού"
# 2. Fix AS-REP roasting accounts (§7) - συνήθως 1-2 λογαριασμοί, εύκολο fix
# 3. Rotate passwords των πιο "παλιών" service accounts από τη Φάση 1

# ===== ΦΑΣΗ 3: Structural Changes (μεγαλύτερο effort, μεγαλύτερος αντίκτυπος) =====
# 1. Migration service accounts σε gMSA όπου γίνεται
# 2. Ξεχωριστοί admin λογαριασμοί (admin-xxx) για ΟΛΟΥΣ τους IT admins
# 3. Protected Users group (§9) για Tier 0 accounts - ΜΕΤΑ από testing
# 4. Break-glass account setup (§11) αν δεν υπάρχει ήδη

# ===== ΦΑΣΗ 4: Ongoing =====
# 1. SIEM integration για τα event IDs του §12
# 2. Quarterly review των privileged accounts (ποιοι είναι πραγματικά ακόμα Domain Admin, γιατί)
# 3. Documentation update
```

---

## ✅ 14. Checklist — Security Baseline

```
☐ LAPS deployed σε ΟΛΑ τα workstations/servers (μοναδικός local admin κωδικός ανά μηχάνημα)
☐ Κανένα service account με SPN δεν έχει password παλιότερο από 180 μέρες
☐ Service accounts migrated σε gMSA όπου τεχνικά εφικτό
☐ Κανένας λογαριασμός δεν έχει "Do not require Kerberos preauthentication" χωρίς σαφή λόγο
☐ Ξεχωριστοί admin λογαριασμοί (admin-xxx) για κάθε IT admin, όχι χρήση καθημερινού λογαριασμού
☐ Tiered admin model τηρείται - Domain Admins ΔΕΝ κάνουν login σε Tier 2 μηχανήματα
☐ Protected Users group περιέχει τουλάχιστον τα Tier 0 admin accounts (μετά από testing)
☐ Break-glass account υπάρχει, testarισμένο, password σε φυσικό ασφαλές μέρος
☐ Credential Guard ενεργό σε σύγχρονα Windows μηχανήματα
☐ SIEM/monitoring στα key event IDs (4768, 4769, 4672, 4625, 4670)
☐ Quarterly review privileged accounts - ποιοι είναι πραγματικά ακόμα Domain Admin
☐ Documentation - πότε έγινε το τελευταίο security audit, τι βρέθηκε, τι διορθώθηκε
```

---

## 📚 Σχετικά αρχεία

- [`active-directory.md`](./active-directory.md) — Users/Groups, OUs, GPO βασικά
- [`active-directory-advanced.md`](./active-directory-advanced.md) — FSMO, Replication, Security Tiering (εισαγωγή)
- [`file-permissions-ntfs.md`](./file-permissions-ntfs.md) — NTFS/Share permissions θεωρία
- [`group-policy-deep-dive.md`](./group-policy-deep-dive.md) — GPO processing, δείχνει πώς deployάρεις LAPS/Protected Users μέσω GPO
- [`backup-disaster-recovery.md`](./backup-disaster-recovery.md) — Τι κάνεις ΜΕΤΑ από incident (π.χ. Golden Ticket recovery)
- Αυτό το αρχείο (`ad-security-hardening.md`) — Attacks (Kerberoasting, Pass-the-Hash, Golden Ticket), Defenses (LAPS, Protected Users, Tiering), Detection
