# 🎫 Kerberos Authentication — Deep Dive & Real-World Runbook
> Συνοδευτικό αρχείο στη σειρά Active Directory. Το Kerberos είναι το protocol που κάνει authenticate ΚΑΘΕ login, κάθε file access, κάθε service request σε ένα AD environment. Το [`ad-security-hardening.md`](./ad-security-hardening.md) εξήγησε πώς επιτίθενται σε αυτό — εδώ εξηγούμε **πώς δουλεύει πραγματικά**, βήμα-βήμα, ώστε να καταλαβαίνεις τι ακριβώς προστατεύεις.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Γιατί Kerberos και όχι κάτι Απλούστερο](#-1-γιατί-kerberos-και-όχι-κάτι-απλούστερο)
2. [Τα Βασικά Συστατικά](#-2-τα-βασικά-συστατικά)
3. [Το Πλήρες Authentication Flow — Βήμα προς Βήμα](#-3-το-πλήρες-authentication-flow--βήμα-προς-βήμα)
4. [SPNs — Service Principal Names](#-4-spns--service-principal-names)
5. [Σενάριο — Το Ticket](#-5-σενάριο--το-ticket)
6. [Delegation — Τι Είναι και Γιατί Χρειάζεται](#-6-delegation--τι-είναι-και-γιατί-χρειάζεται)
7. [Runbook: Ρύθμιση Constrained Delegation](#-7-runbook-ρύθμιση-constrained-delegation)
8. [Kerberos Tickets σε Βάθος — Lifetime, Renewal, Flags](#-8-kerberos-tickets-σε-βάθος--lifetime-renewal-flags)
9. [Time Sync — Γιατί Έχει Τόση Σημασία](#-9-time-sync--γιατί-έχει-τόση-σημασία)
10. [Troubleshooting](#-10-troubleshooting)
11. [Εργαλεία Διάγνωσης](#-11-εργαλεία-διάγνωσης)
12. [Checklist — Kerberos Health](#-12-checklist--kerberos-health)

---

## 🤔 1. Γιατί Kerberos και όχι κάτι Απλούστερο

Πριν το Kerberos, τα Windows χρησιμοποιούσαν **NTLM** — πιο απλό protocol, αλλά με σημαντικά προβλήματα:

| | NTLM | Kerberos |
|---|---|---|
| **Mutual authentication** | Όχι — μόνο ο client αποδεικνύει ποιος είναι | Ναι — και οι δύο πλευρές αποδεικνύουν ταυτότητα |
| **Password hash στο δίκτυο** | Στέλνεται (challenge-response) — ευάλωτο σε relay attacks | Ποτέ δεν στέλνεται το password/hash απευθείας |
| **Performance σε μεγάλα δίκτυα** | Κάθε request χρειάζεται νέο round-trip στον DC | Το ticket "θυμάται" την authentication, λιγότερα round-trips |
| **Delegation support** | Πολύ περιορισμένο | Πλήρες, ελεγχόμενο delegation model (§6) |

> 💡 Το NTLM **ακόμα** χρησιμοποιείται σήμερα ως fallback (π.χ. σε workgroup/non-domain σενάρια, ή legacy εφαρμογές) — αλλά το Kerberos είναι το default και προτιμώμενο protocol για κάθε domain-joined επικοινωνία. Γι' αυτό στο [`ad-security-hardening.md`](./ad-security-hardening.md#-9-άμυνα-2-protected-users-group) το Protected Users group απενεργοποιεί εντελώς το NTLM — το θεωρεί το "αδύναμο κρίκο".

---

## 🧩 2. Τα Βασικά Συστατικά

| Όρος | Τι είναι |
|---|---|
| **KDC** (Key Distribution Center) | Service που τρέχει σε ΚΑΘΕ Domain Controller — εκδίδει tickets |
| **AS** (Authentication Service) | Το κομμάτι του KDC που επαληθεύει την αρχική ταυτότητα |
| **TGS** (Ticket Granting Service) | Το κομμάτι του KDC που εκδίδει tickets για συγκεκριμένα services |
| **TGT** (Ticket Granting Ticket) | Το "master ticket" — αποδεικνύει ότι έκανες ήδη authenticate, χρησιμοποιείται για να ζητήσεις άλλα tickets |
| **Service Ticket (TGS ticket)** | Ticket για ΣΥΓΚΕΚΡΙΜΕΝΟ service (π.χ. file server, SQL server) |
| **krbtgt account** | Ειδικός λογαριασμός — το password hash του χρησιμοποιείται για να "υπογράφει" όλα τα TGTs (βλέπε [`ad-security-hardening.md`](./ad-security-hardening.md#-6-επίθεση-3-golden-ticket--silver-ticket)) |

```
              ┌─────────────────────────┐
              │   Domain Controller      │
              │   ┌─────────────────┐    │
              │   │       KDC        │    │
              │   │  ┌─────┬──────┐  │    │
              │   │  │ AS  │ TGS  │  │    │
              │   │  └─────┴──────┘  │    │
              │   └─────────────────┘    │
              └─────────────────────────┘
```

---

## 🔄 3. Το Πλήρες Authentication Flow — Βήμα προς Βήμα

Ας δούμε τι ΠΡΑΓΜΑΤΙΚΑ συμβαίνει όταν ο χρήστης `d.katsanos` κάνει login στο PC του και μετά ανοίγει ένα αρχείο στο `\\FS01\Marketing`:

```
═══ ΦΑΣΗ 1: AS Exchange (Login) ═══

Βήμα 1 (AS-REQ):
  Client → KDC: "Είμαι ο d.katsanos, ώρα είναι X, εδώ είναι το timestamp μου
                  κρυπτογραφημένο με το password hash μου"
  (Αυτό είναι το "preauthentication" - βλέπε ad-security-hardening.md §7
   για τι συμβαίνει όταν ΛΕΙΠΕΙ αυτό το βήμα)

Βήμα 2 (AS-REP):
  KDC: Αποκρυπτογραφεί το timestamp χρησιμοποιώντας το ΔΙΚΟ ΤΟΥ αντίγραφο
       του password hash του d.katsanos (αποθηκευμένο στο AD database)
       → Αν ταιριάζει, ο client αποδείχθηκε ΝΟΜΙΜΟΣ
  KDC → Client: "Ορίστε το TGT σου" (κρυπτογραφημένο με το krbtgt hash -
                 ο client ΔΕΝ μπορεί να το διαβάσει, απλά το "κρατάει" και
                 το παρουσιάζει αργότερα)

  ✅ Αποτέλεσμα: Ο client έχει τώρα ένα TGT, έγκυρο συνήθως για 10 ώρες
     (βλέπε §8 για lifetime λεπτομέρειες)

═══ ΦΑΣΗ 2: TGS Exchange (Πρόσβαση σε Service) ═══

Βήμα 3 (TGS-REQ):
  Ο χρήστης προσπαθεί να ανοίξει \\FS01\Marketing
  Client → KDC: "Ορίστε το TGT μου (απόδειξη ότι έκανα ήδη login), θέλω
                  service ticket για το SPN: cifs/FS01.company.local"

Βήμα 4 (TGS-REP):
  KDC: Επαληθεύει το TGT (μπορεί να το αποκρυπτογραφήσει με το krbtgt hash
       που ήδη έχει), βλέπει ότι είναι έγκυρο
  KDC → Client: "Ορίστε service ticket για το FS01" (κρυπτογραφημένο με το
                 password hash ΤΟΥ FS01 service account - αυτό είναι το
                 σημείο που εκμεταλλεύεται το Kerberoasting)

═══ ΦΑΣΗ 3: AP Exchange (Πραγματική Πρόσβαση) ═══

Βήμα 5 (AP-REQ):
  Client → FS01: "Ορίστε το service ticket μου"

Βήμα 6:
  FS01: Αποκρυπτογραφεί το ticket με το ΔΙΚΟ ΤΟΥ password hash
        (το ξέρει γιατί είναι δικό του) → επιβεβαιώνει ότι είναι νόμιμο
        → Δίνει πρόσβαση στο file share

  ✅ Ο χρήστης βλέπει τώρα τα αρχεία - ΟΛΗ αυτή η διαδικασία έγινε
     μέσα σε milliseconds, αόρατη στον χρήστη
```

> 💡 **Το πιο σημαντικό detail που πρέπει να "κολλήσει":** Ο DC **ποτέ** δεν στέλνει το πραγματικό password ή hash μέσω δικτύου. Τα πάντα βασίζονται στο ότι **και οι δύο πλευρές ήδη ξέρουν** το ίδιο hash (client-side derived από το password, server-side αποθηκευμένο), και το χρησιμοποιούν μόνο για encrypt/decrypt — ποτέ δεν "ταξιδεύει" το ίδιο.

---

## 🏷️ 4. SPNs — Service Principal Names

Ένα **SPN** είναι το "όνομα" που χρησιμοποιεί το Kerberos για να αναγνωρίσει ΠΟΙΟ service ζητάει ο client — χωρίς σωστό SPN, το Kerberos authentication για αυτό το service αποτυγχάνει (και ξαναπέφτει σε NTLM, λιγότερο ασφαλές).

```powershell
# Μορφή: <ServiceClass>/<Host>:<Port>/<ServiceName>

# Παραδείγματα:
# HTTP/webapp01.company.local           → IIS web application
# MSSQLSvc/sql01.company.local:1433     → SQL Server
# cifs/fs01.company.local               → File server (SMB)
# HOST/dc01.company.local               → Γενικό host SPN

# Προβολή SPNs ενός account
Get-ADUser -Identity "svc-sqlserver" -Properties ServicePrincipalName |
    Select -ExpandProperty ServicePrincipalName

# Προσθήκη νέου SPN
Set-ADUser -Identity "svc-sqlserver" -ServicePrincipalNames @{Add="MSSQLSvc/sql01.company.local:1433"}

# ΚΡΙΣΙΜΟ: Εύρεση DUPLICATE SPNs (το #1 πιο συχνό Kerberos πρόβλημα σε πραγματικές εταιρείες)
setspn -X
```

> ⚠️ **Το πιο συχνό real-world πρόβλημα:** Δύο accounts με το **ίδιο SPN** καταχωρημένο (π.χ. επειδή κάποιος migration δεν καθάρισε το παλιό service account). Όταν συμβαίνει αυτό, το Kerberos authentication για αυτό το service **αποτυγχάνει απρόβλεπτα** — μερικές φορές δουλεύει, μερικές φορές όχι, ανάλογα με ποιο DC απαντάει. Το `setspn -X` είναι το πρώτο πράγμα που τρέχεις όταν κάποιος αναφέρει "ασταθές" authentication πρόβλημα σε ένα service.

---

## 🎫 5. Σενάριο — Το Ticket

> **Ticket #4677** — *"Έχουμε μια web εφαρμογή (IIS) που χρειάζεται να συνδεθεί σε SQL Server χρησιμοποιώντας τα credentials του ΣΥΝΔΕΔΕΜΕΝΟΥ χρήστη (όχι ένα generic service account) — γνωστό ως 'double-hop' σενάριο. Αυτή τη στιγμή παίρνουμε 'Login failed' errors όταν ο χρήστης προσπαθεί να τραβήξει δεδομένα."*

Αυτό είναι το κλασικό **"double-hop problem"** — και η λύση του είναι το επόμενο θέμα: **Delegation**.

---

## 🔀 6. Delegation — Τι Είναι και Γιατί Χρειάζεται

### Το "Double-Hop Problem"

```
Χωρίς Delegation:

Χρήστης → Browser → IIS Web Server → ❌ SQL Server
   (1ο hop: OK,          (2ο hop: ΑΠΟΤΥΓΧΑΝΕΙ)
    το TGT/ticket
    του χρήστη
    "σταματάει" εδώ)

Το πρόβλημα: Το service ticket που πήρε ο IIS server είναι φτιαγμένο
ΕΙΔΙΚΑ για το "IIS/webapp01" service - ΔΕΝ μπορεί να το "περάσει
παρακάτω" στο SQL Server σαν να ήταν ο ίδιος ο χρήστης, εκτός αν
το IIS server account έχει ρητή άδεια να κάνει "delegate" credentials.


Με Delegation:

Χρήστης → Browser → IIS Web Server → ✅ SQL Server
                     (Το IIS server account ΕΧΕΙ άδεια να ζητήσει
                      NEO service ticket "ΣΑΝ να ήταν ο χρήστης",
                      ειδικά για το SQL Server)
```

### Οι 3 Τύποι Delegation

| Τύπος | Πώς δουλεύει | Επίπεδο ρίσκου |
|---|---|---|
| **Unconstrained Delegation** | Ο IIS server μπορεί να "προσποιηθεί" τον χρήστη σε ΟΠΟΙΟΔΗΠΟΤΕ service σε ΟΛΟ το domain | 🔴 Πολύ υψηλό — αν το IIS server compromised, ο επιτιθέμενος μπορεί να κάνει impersonate ΟΠΟΙΟΝΔΗΠΟΤΕ χρήστη έκανε login εκεί, σε ΟΠΟΙΟΔΗΠΟΤΕ service |
| **Constrained Delegation** | Ο IIS server μπορεί να προσποιηθεί τον χρήστη **ΜΟΝΟ** για συγκεκριμένα, προκαθορισμένα services (π.χ. ΜΟΝΟ το SQL01) | 🟡 Μεσαίο — περιορισμένο scope, πολύ πιο ασφαλές |
| **Resource-Based Constrained Delegation (RBCD)** | Παρόμοιο με Constrained, αλλά η ρύθμιση γίνεται στο **target** (SQL server "επιτρέπει" ποιος μπορεί να του κάνει delegate), όχι στην πηγή | 🟢 Πιο ευέλικτο, σύγχρονη προσέγγιση, καλύτερο για cross-domain σενάρια |

> ⚠️ **Unconstrained Delegation θεωρείται σήμερα σοβαρό security risk** και αποφεύγεται σχεδόν πάντα σε νέα setups. Αν βρεις σε audit ότι υπάρχει server με unconstrained delegation, είναι σχεδόν σίγουρα κάτι που πρέπει να διορθωθεί σε Constrained ή RBCD.

---

## 🛠️ 7. Runbook: Ρύθμιση Constrained Delegation

```powershell
# Σενάριο: IIS server "webapp01" χρειάζεται να κάνει delegate credentials
# προς το SQL server "sql01", ΜΟΝΟ για το MSSQL service

# Βήμα 1: Βεβαιώσου ότι το SQL server account έχει σωστό SPN (§4)
Get-ADComputer -Identity "SQL01" -Properties ServicePrincipalName

# Βήμα 2: Ρύθμιση Constrained Delegation στο computer account του IIS server
# (Classic/Kerberos-only constrained delegation)
Set-ADComputer -Identity "WEBAPP01" `
    -Add @{"msDS-AllowedToDelegateTo" = "MSSQLSvc/sql01.company.local:1433"}

# Βήμα 3 (Εναλλακτικά, πιο σύγχρονο): Resource-Based Constrained Delegation
# Η ρύθμιση γίνεται στο SQL01 (το target), όχι στο WEBAPP01 (την πηγή)
$webapp01 = Get-ADComputer -Identity "WEBAPP01"
Set-ADComputer -Identity "SQL01" -PrincipalsAllowedToDelegateToAccount $webapp01

# Βήμα 4: Επαλήθευση
Get-ADComputer -Identity "WEBAPP01" -Properties msDS-AllowedToDelegateTo
Get-ADComputer -Identity "SQL01" -Properties PrincipalsAllowedToDelegateToAccount
```

**Στο IIS επίπεδο (Windows-side config, όχι AD):**

```
IIS Manager → Application Pool του webapp → Advanced Settings
→ "Identity" → βεβαιώσου ότι δεν είναι "ApplicationPoolIdentity" (default)
  αλλά domain account (χρειάζεται custom identity για να δουλέψει delegation)

Web.config → βεβαιώσου ότι υπάρχει <identity impersonate="true" />
             ή ότι η εφαρμογή χρησιμοποιεί Windows Authentication σωστά
```

> 💡 **Real-world tip:** Όταν βλέπεις "double-hop" προβλήματα, το πρώτο πράγμα που ελέγχεις είναι αν το authentication scheme είναι πράγματι **Kerberos** και όχι NTLM (το NTLM δεν υποστηρίζει delegation καθόλου). `klist` στο IIS server μετά από ένα request μπορεί να σου δείξει ποιο ticket χρησιμοποιήθηκε.

---

## ⏱️ 8. Kerberos Tickets σε Βάθος — Lifetime, Renewal, Flags

```powershell
# Προβολή των default lifetime ρυθμίσεων (μέσω Default Domain Policy - Account Policies)
# Computer Configuration → Policies → Windows Settings → Security Settings
# → Account Policies → Kerberos Policy

# Default values σε τυπικό AD:
#   Maximum lifetime for user ticket:        10 hours
#   Maximum lifetime for service ticket:      10 hours (ή "600 minutes")
#   Maximum lifetime for user ticket renewal: 7 days
#   Maximum tolerance for computer clock sync: 5 minutes  (§9!)
```

| Ticket Flag | Σημασία |
|---|---|
| **Forwardable** | Το ticket μπορεί να "περαστεί" σε άλλο μηχάνημα (χρειάζεται για κάποια delegation σενάρια) |
| **Renewable** | Το ticket μπορεί να ανανεωθεί χωρίς πλήρες re-authentication, μέχρι το renewal limit |
| **Proxiable** | Παρόμοιο με forwardable, πιο περιορισμένο |

```powershell
# Προβολή των τρεχόντων tickets σε ένα Windows μηχάνημα (client-side)
klist

# Καθαρισμός όλων των cached tickets (χρήσιμο σε troubleshooting - βλέπε §10)
klist purge
```

> 💡 **Γιατί το TGT λήγει σε 10 ώρες και όχι λιγότερο/περισσότερο;** Είναι μια ισορροπία — πολύ μικρό lifetime σημαίνει συχνά re-authentication prompts (ενοχλητικό για τους χρήστες), πολύ μεγάλο σημαίνει ότι ένα κλεμμένο ticket (§ad-security-hardening.md) παραμένει χρήσιμο για μεγαλύτερο διάστημα. 10 ώρες καλύπτει μια τυπική εργάσιμη μέρα χωρίς να χρειάζεται re-login.

---

## ⏰ 9. Time Sync — Γιατί Έχει Τόση Σημασία

Αυτό είναι το πιο **underrated** detail στο Kerberos, και η πηγή πολλών "μυστηριωδών" authentication προβλημάτων:

```
Το Kerberos βασίζεται σε timestamps για να αποτρέψει replay attacks
(κάποιος να "ξαναχρησιμοποιήσει" ένα παλιό, κλεμμένο ticket).

Αν η ώρα ενός client διαφέρει από τον DC πάνω από το "Maximum tolerance
for computer clock synchronization" (default: 5 λεπτά), το Kerberos
authentication ΑΠΟΤΥΓΧΑΝΕΙ ΕΝΤΕΛΩΣ - ακόμα κι αν το password είναι
100% σωστό.
```

```powershell
# Έλεγχος time sync source ενός μηχανήματος
w32tm /query /status

# Σε domain-joined μηχανήματα, η ιεραρχία είναι αυτόματη:
#   Workstations/Members → συγχρονίζονται με τον DC που τους εξυπηρετεί
#   DCs (non-PDC Emulator) → συγχρονίζονται με τον PDC Emulator
#   PDC Emulator → συγχρονίζεται με εξωτερική, αξιόπιστη πηγή (NTP)

# Ρύθμιση του PDC Emulator να συγχρονίζεται με εξωτερικό NTP source
w32tm /config /manualpeerlist:"time.windows.com,0x8 pool.ntp.org,0x8" /syncfromflags:manual /reliable:yes /update
Restart-Service w32time

# Force immediate resync σε client (χρήσιμο σε troubleshooting)
w32tm /resync /force
```

> ⚠️ **Πολύ συχνό real-world σενάριο:** VM που ήταν "παγωμένο" (suspended/paused) για ώρες και μετά ξαναξεκίνησε, ή VM σε hypervisor με λάθος ρυθμισμένο host time sync — ξαφνικά "authentication failures" παντού, χωρίς προφανή λόγο. Το πρώτο πράγμα που ελέγχεις σε οποιοδήποτε ασαφές, διάχυτο authentication πρόβλημα είναι **πάντα** το time sync.

---

## 🔧 10. Troubleshooting

| Πρόβλημα | Πιθανή Αιτία | Λύση |
|---|---|---|
| "Clock skew too great" / authentication αποτυγχάνει αναίτια | Time sync πρόβλημα (§9) | `w32tm /resync /force`, έλεγξε `w32tm /query /status` |
| Authentication δουλεύει τοπικά αλλά όχι μέσω δικτύου σε συγκεκριμένο service | Λάθος/λείπον SPN, ή duplicate SPN (§4) | `setspn -L <account>`, `setspn -X` για duplicates |
| "Double-hop" - δεδομένα δεν περνάνε σε δεύτερο service | Χρειάζεται Delegation, δεν είναι ρυθμισμένο (§6-7) | Ρύθμισε Constrained Delegation |
| Authentication fallback σε NTLM ενώ θα έπρεπε Kerberos | Λάθος SPN, ή client χρησιμοποιεί IP αντί για FQDN | Πάντα χρησιμοποίησε FQDN (`server.company.local`), όχι IP ή short name |
| Νέο μέλος group δεν παίρνει τα σωστά rights αμέσως | Παλιό TGT δεν περιέχει το νέο group membership | `klist purge`, νέο logon (νέο TGT περιλαμβάνει ενημερωμένα groups) |
| "KRB_AP_ERR_MODIFIED" | Το SPN account's password άλλαξε αλλά το service δεν το "ξέρει" ακόμα (π.χ. service account password reset χωρίς restart service) | Restart το service ώστε να πάρει νέο ticket με το νέο password |
| Kerberos δουλεύει σε ένα site αλλά όχι σε remote site | DC στο remote site down/unreachable, fallback σε μακρινό DC με λανθάνοντα χρόνο | Έλεγξε DC health στο site (βλέπε `active-directory-advanced.md` §3) |

---

## 🔍 11. Εργαλεία Διάγνωσης

```powershell
# klist - προβολή cached tickets στο τρέχον session
klist

# klist tickets για συγκεκριμένο session/logon
klist sessions

# setspn - SPN management
setspn -L "svc-sqlserver"        # λίστα SPNs ενός account
setspn -X                         # εύρεση duplicates (§4)
setspn -Q "MSSQLSvc/sql01*"       # αναζήτηση ποιος έχει συγκεκριμένο SPN

# Network capture για βαθύ debugging (advanced - χρειάζεται προσοχή σε production)
# Wireshark με φίλτρο "kerberos" δείχνει το πλήρες AS/TGS/AP exchange

# Kerberos event logging (client-side, πολύ χρήσιμο σε δύσκολα προβλήματα)
# Registry: HKLM\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters
# DWORD: LogLevel = 1  → ενεργοποιεί λεπτομερές logging στο System event log

# dcdiag - γενικός έλεγχος υγείας DC, περιλαμβάνει Kerberos-related tests
dcdiag /test:Kerberos
```

---

## ✅ 12. Checklist — Kerberos Health

```
☐ Time sync σωστά ρυθμισμένο - PDC Emulator συγχρονίζεται με αξιόπιστο εξωτερικό NTP
☐ Κανένα duplicate SPN στο domain (setspn -X καθαρό αποτέλεσμα)
☐ Όλα τα services έχουν σωστά καταχωρημένα SPNs (χρήση FQDN παντού, όχι IP/short names)
☐ Κανένα Unconstrained Delegation σε production servers (μόνο Constrained/RBCD)
☐ Service account passwords δεν είναι παλιά (βλέπε ad-security-hardening.md §4 - Kerberoasting)
☐ Kerberos ticket lifetime settings review (default 10h είναι OK για τους περισσότερους, αλλά επιβεβαίωσε)
☐ AES encryption ενεργό στα service accounts (όχι RC4/DES - πιο αδύναμα)
☐ Documentation - ποια services χρησιμοποιούν delegation, γιατί, ποιος το ενέκρινε
```

---

## 📚 Σχετικά αρχεία

- [`active-directory.md`](./active-directory.md) — Users/Groups, OUs, GPO βασικά
- [`active-directory-advanced.md`](./active-directory-advanced.md) — FSMO, Replication, DNS Integration
- [`ad-security-hardening.md`](./ad-security-hardening.md) — Kerberoasting, Golden Ticket attacks — τι κάνει κάποιος ΜΕ αυτά που μάθαμε εδώ
- [`group-policy-deep-dive.md`](./group-policy-deep-dive.md) — GPO για Kerberos policy settings
- Αυτό το αρχείο (`kerberos-deep-dive.md`) — Authentication flow, SPNs, Delegation, Time Sync, Troubleshooting
