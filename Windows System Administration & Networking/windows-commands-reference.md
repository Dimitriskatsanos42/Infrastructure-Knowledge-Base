# 🖧 Windows System & Networking Command Reference

> Πλήρης οδηγός εντολών CMD και PowerShell — με θεωρητικό υπόβαθρο πρωτοκόλλων, πρακτικές εντολές και σενάρια troubleshooting.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Δίκτυο & Συνδεσιμότητα](#-1-δίκτυο--συνδεσιμότητα)
2. [Διαχείριση Χρηστών & Ταυτοποίησης](#-2-διαχείριση-χρηστών--ταυτοποίησης)
3. [Διαχείριση Διεργασιών](#-3-διαχείριση-διεργασιών)
4. [Group Policy](#-4-group-policy)
5. [Ακεραιότητα & Επισκευή Συστήματος](#-5-ακεραιότητα--επισκευή-συστήματος)
6. [Quick Reference Cheat Sheet](#-6-quick-reference--cheat-sheet)

---

## 🌐 1. Δίκτυο & Συνδεσιμότητα

---

### `ipconfig` — IP Configuration

#### 📖 Θεωρία: Πώς αποκτά IP ένας υπολογιστής (DHCP Protocol)

Κάθε φορά που ένας υπολογιστής συνδέεται σε δίκτυο, εκτελείται αυτόματα η διαδικασία **DORA** για να πάρει IP διεύθυνση:

```ini
Client                              DHCP Server
  │                                      │
  │──── DISCOVER (broadcast) ───────────►│   "Υπάρχει DHCP server εδώ;"
  │                                      │
  │◄─── OFFER ──────────────────────────│   "Ναι! Σου προσφέρω 192.168.1.50"
  │                                      │
  │──── REQUEST (broadcast) ────────────►│   "Θέλω αυτή την IP"
  │                                      │
  │◄─── ACKNOWLEDGE ────────────────────│   "Εντάξει, είναι δική σου για 8 ώρες (Lease)"
  │                                      │
```

**Βασικές Έννοιες:**

| Όρος | Εξήγηση |
|------|---------|
| **DHCP Lease** | Χρονικό διάστημα που "νοικιάζει" ο client την IP — μετά πρέπει να ανανεωθεί |
| **APIPA** | Αν δεν βρεθεί DHCP server, ο υπολογιστής παίρνει αυτόματα IP `169.254.x.x` |
| **Scope** | Το εύρος IPs που μοιράζει ο DHCP server (π.χ. `192.168.1.100–200`) |
| **Reservation** | Δέσμευση συγκεκριμένης IP για συγκεκριμένο MAC address |
| **Gateway** | Η IP του router — η "πόρτα εξόδου" προς το internet |

**OSI Layer:** DHCP λειτουργεί στο **Layer 7 (Application)** αλλά μεταφέρεται μέσω **UDP** (Layer 4) — ports 67 (server) και 68 (client).

---

#### `ipconfig /all`

```cmd
ipconfig /all
```

**Τι εμφανίζει:**

| Πεδίο | Τι σημαίνει |
|-------|------------|
| `Physical Address` | MAC address — μοναδικό αναγνωριστικό της κάρτας δικτύου (Layer 2) |
| `DHCP Enabled` | Αν η IP δίνεται αυτόματα ή είναι static |
| `Lease Obtained/Expires` | Πότε πήρε και πότε λήγει η IP |
| `IPv4 Address` | Η τρέχουσα IP του υπολογιστή |
| `Subnet Mask` | Ορίζει ποιες IPs ανήκουν στο ίδιο δίκτυο |
| `Default Gateway` | IP του router — εκεί στέλνει πακέτα για εξωτερικούς προορισμούς |
| `DNS Servers` | Σε ποιους servers ρωτάει για μετατροπή domain → IP |

> ⚠️ IP `169.254.x.x` = **APIPA** = ο υπολογιστής δεν βρήκε DHCP server. Πρόβλημα δικτύου, όχι υπολογιστή.

---

#### `ipconfig /release` & `ipconfig /renew`

```cmd
ipconfig /release
ipconfig /renew
```

**Τι συμβαίνει από κάτω:**

- `/release` → Στέλνει **DHCPRELEASE** στον server: *"Δεν χρειάζομαι πλέον αυτή την IP"*
- `/renew` → Ξεκινά εκ νέου η διαδικασία DORA από το βήμα DISCOVER

**Πότε το χρησιμοποιείς:**

- IP conflict (δύο υπολογιστές με την ίδια IP)
- Ο DHCP server άλλαξε scope
- Ο χρήστης πήρε APIPA και θέλεις να ξαναδοκιμάσει

---

#### `ipconfig /flushdns`

```cmd
ipconfig /flushdns
```

**📖 Θεωρία: DNS Cache — Γιατί υπάρχει και τι κάνει**

Κάθε φορά που επισκέπτεσαι ένα site, ο υπολογιστής μετατρέπει το domain σε IP μέσω DNS. Για να μην επαναλαμβάνει αυτή τη διαδικασία συνεχώς, **αποθηκεύει προσωρινά** το αποτέλεσμα (cache) για κάποιο χρονικό διάστημα που ορίζεται από το **TTL (Time-to-Live)** της DNS εγγραφής.

```ini
Πρώτη επίσκεψη στο google.com:
Browser → DNS Cache (άδειο) → DNS Server → "142.250.185.46" → αποθηκεύεται στο cache

Δεύτερη επίσκεψη στο google.com:
Browser → DNS Cache (έχει την IP) → απευθείας σύνδεση (χωρίς να ρωτήσει DNS server)
```

**Πρόβλημα:** Αν ο server αλλάξει IP αλλά η παλιά είναι ακόμα στο cache, ο υπολογιστής δοκιμάζει να συνδεθεί στη λάθος IP.

**Λύση:** `ipconfig /flushdns` → σβήνει το cache → την επόμενη επίσκεψη ρωτάει ξανά τον DNS server → παίρνει τη νέα IP.

```cmd
ipconfig /displaydns    :: Δες τι υπάρχει στο cache πριν
ipconfig /flushdns      :: Εκκαθάριση
ipconfig /displaydns    :: Επιβεβαίωση ότι άδειασε
```

---

### `ping` — Packet Internet Groper

#### 📖 Θεωρία: Πρωτόκολλο ICMP

Το `ping` χρησιμοποιεί το **ICMP (Internet Control Message Protocol)** — ένα πρωτόκολλο του **Layer 3 (Network)** του OSI model που χρησιμοποιείται για διαγνωστικά μηνύματα δικτύου.

**Πώς λειτουργεί:**

```ini
Εσύ (192.168.1.10)                    Google (142.250.185.46)
       │                                        │
       │──── ICMP Echo Request ────────────────►│   "Είσαι εκεί;"
       │         (Type 8)                       │
       │                                        │
       │◄─── ICMP Echo Reply ──────────────────│   "Ναι, εδώ είμαι!"
       │         (Type 0)                       │
       │                                        │
       Μετράει χρόνο μετ/δοσης (RTT)
```

**RTT (Round-Trip Time):** Ο χρόνος από την αποστολή του request μέχρι τη λήψη του reply — μετριέται σε **milliseconds (ms)**.

| RTT | Αξιολόγηση |
|-----|-----------|
| `< 1ms` | Τοπικό δίκτυο — άριστο |
| `1–20ms` | Εξαιρετικό |
| `20–100ms` | Καλό — κανονικό για internet |
| `100–300ms` | Αισθητή καθυστέρηση |
| `> 300ms` | Προβληματικό — lag σε real-time εφαρμογές |
| `Request timed out` | Το πακέτο δεν έφτασε ή ο προορισμός δεν απαντά |

> ⚠️ **Σημαντικό:** Πολλά firewalls **μπλοκάρουν ICMP** για λόγους ασφαλείας. Αποτυχία ping ≠ αποτυχία σύνδεσης. Χρησιμοποίησε `Test-NetConnection` για να ελέγξεις συγκεκριμένες υπηρεσίες.

**Εντολές:**

```cmd
ping google.com              :: 4 πακέτα (default)
ping -t 192.168.1.1          :: Συνεχές ping (Ctrl+C για διακοπή)
ping -n 10 192.168.1.1       :: Συγκεκριμένος αριθμός πακέτων
ping -l 1000 192.168.1.1     :: Μεγαλύτερο packet size (test bandwidth)
ping -4 google.com           :: Αναγκαστικά IPv4
ping -6 google.com           :: Αναγκαστικά IPv6
```

**Λογική Διάγνωσης με ping (βήμα-βήμα):**

```ini
1. ping 127.0.0.1
   └─ ΟΚ = TCP/IP stack λειτουργεί
   └─ FAIL = πρόβλημα στο λογισμικό δικτύου → netsh winsock reset
         ↓
2. ping [Default Gateway, π.χ. 192.168.1.1]
   └─ ΟΚ = φτάνεις στον router
   └─ FAIL = πρόβλημα καλωδίου/Wi-Fi/adapter → ncpa.cpl
         ↓
3. ping 8.8.8.8
   └─ ΟΚ = έχεις internet σύνδεση (Layer 3)
   └─ FAIL = πρόβλημα στον router ή ISP
         ↓
4. ping google.com
   └─ ΟΚ = DNS λειτουργεί
   └─ FAIL = DNS πρόβλημα → ipconfig /flushdns ή αλλαγή DNS server
```

---

### `tracert` — Traceroute

#### 📖 Θεωρία: TTL (Time-to-Live) και πώς αποκαλύπτει τη διαδρομή

Κάθε IP πακέτο έχει ένα πεδίο **TTL** — ένας counter που μειώνεται κατά 1 σε κάθε router που περνά. Όταν φτάσει στο 0, ο router **απορρίπτει το πακέτο** και στέλνει πίσω μήνυμα **ICMP "Time Exceeded"**.

Το `tracert` εκμεταλλεύεται αυτό:

```ini
Αποστολή 1:  TTL=1  → Router 1 απορρίπτει → στέλνει "Time Exceeded" → αποκαλύπτεται ο Router 1
Αποστολή 2:  TTL=2  → Router 2 απορρίπτει → στέλνει "Time Exceeded" → αποκαλύπτεται ο Router 2
Αποστολή 3:  TTL=3  → Router 3 απορρίπτει → στέλνει "Time Exceeded" → αποκαλύπτεται ο Router 3
...
Αποστολή N:  TTL=N  → Φτάνει στον προορισμό → Reply → τέλος
```

Έτσι χαρτογραφείται η **πλήρης διαδρομή** από τον υπολογιστή μέχρι τον προορισμό.

**Εντολές:**

```cmd
tracert google.com
tracert -d google.com       :: Χωρίς DNS resolution (πιο γρήγορο)
tracert -h 30 google.com    :: Max 30 hops (default: 30)
```

**Ανάγνωση αποτελέσματος:**

```ini
Tracing route to google.com [142.250.185.46]
over a maximum of 30 hops:

  1    <1 ms   <1 ms   <1 ms   192.168.1.1         ← Τοπικός router
  2     5 ms    4 ms    5 ms   10.10.1.1            ← ISP gateway
  3    12 ms   11 ms   12 ms   62.x.x.x             ← ISP backbone
  4    13 ms   13 ms   13 ms   72.x.x.x             ← Internet backbone
  5     *       *       *      Request timed out.   ← Firewall μπλοκάρει ICMP
  6    20 ms   20 ms   21 ms   142.250.185.46       ← Προορισμός
```

| Σύμβολο | Σημαίνει |
|---------|---------|
| `<1 ms` | Εξαιρετικό latency — τοπικό δίκτυο |
| `* * *` | Ο router μπλοκάρει ICMP ή δεν απαντά — δεν σημαίνει απαραίτητα πρόβλημα |
| Αιφνίδια αύξηση ms | Bottleneck σε αυτό το hop |
| Όλα `* * *` μετά κάποιο hop | Εκεί κόπηκε η σύνδεση |

---

### `nslookup` — Name Server Lookup

#### 📖 Θεωρία: Πώς λειτουργεί το DNS

Το **DNS (Domain Name System)** είναι ο "τηλεφωνικός κατάλογος" του internet — μετατρέπει ονόματα (π.χ. `google.com`) σε IP διευθύνσεις.

**Ιεραρχία DNS:**

```ini
Ερώτηση: "Ποια είναι η IP του www.google.com;"

Browser
  │
  ▼
DNS Cache (τοπικά)  ──── Αν υπάρχει ──►  Απάντηση αμέσως
  │ (αν δεν υπάρχει)
  ▼
Recursive Resolver (ISP/8.8.8.8)
  │
  ▼
Root Name Server (.)  ──►  "Ρώτα τον .com server"
  │
  ▼
TLD Server (.com)     ──►  "Ρώτα τον google.com server"
  │
  ▼
Authoritative Server (google.com)  ──►  "142.250.185.46"
  │
  ▼
Απάντηση στον χρήστη + αποθήκευση στο cache (για TTL χρόνο)
```

**Τύποι DNS Records:**

| Record | Χρήση | Παράδειγμα |
|--------|-------|-----------|
| **A** | Domain → IPv4 | `google.com → 142.250.185.46` |
| **AAAA** | Domain → IPv6 | `google.com → 2a00:1450:...` |
| **MX** | Mail server | `gmail.com → smtp.google.com` |
| **CNAME** | Alias (ψευδώνυμο) | `www.company.com → company.com` |
| **NS** | Name Server | Ποιος server είναι authoritative |
| **PTR** | IP → Domain (reverse) | `142.250.185.46 → google.com` |
| **TXT** | Κείμενο (SPF, DKIM) | Email authentication |

**OSI Layer:** DNS λειτουργεί στο **Layer 7 (Application)** — χρησιμοποιεί **UDP port 53** (γρήγορα queries) και **TCP port 53** (μεγάλα responses/zone transfers).

**Εντολές:**

```cmd
:: Βασική αναζήτηση
nslookup google.com

:: Αναζήτηση σε συγκεκριμένο DNS server
nslookup google.com 8.8.8.8
nslookup google.com 1.1.1.1

:: Interactive mode — για πολλαπλά queries
nslookup
> server 8.8.8.8          :: Αλλαγή DNS server
> set type=A              :: IPv4 records
> google.com
> set type=MX             :: Mail server records
> gmail.com
> set type=NS             :: Name Server records
> set type=TXT            :: TXT records (SPF/DKIM)
> exit

:: Reverse lookup (IP → Domain)
nslookup 8.8.8.8
```

**Διάγνωση με nslookup:**

```cmd
:: Σύγκριση εταιρικού DNS vs εξωτερικού
nslookup intranet.company.local 192.168.1.10    :: Εταιρικός DC (πρέπει να απαντήσει)
nslookup intranet.company.local 8.8.8.8         :: Google DNS (δεν θα βρει internal domain)

:: Αν ο εταιρικός DNS δεν απαντά → πρόβλημα με τον Domain Controller
```

---

### `Test-NetConnection` — PowerShell Port Tester

#### 📖 Θεωρία: TCP Handshake και πώς ελέγχουμε ports

Το **TCP (Transmission Control Protocol)** είναι connection-oriented πρωτόκολλο του **Layer 4 (Transport)**. Πριν μεταφερθούν δεδομένα, γίνεται το **3-Way Handshake**:

```ini
Client                          Server (port 443)
  │                                  │
  │──── SYN ────────────────────────►│   "Θέλω να συνδεθώ"
  │                                  │
  │◄─── SYN-ACK ────────────────────│   "Εντάξει, έτοιμος"
  │                                  │
  │──── ACK ────────────────────────►│   "Άρχισε η σύνδεση"
  │                                  │
  │         [Μεταφορά δεδομένων]     │
```

Αν ο server **δεν αποκριθεί** στο SYN:

- **RST (Reset):** Η θύρα είναι κλειστή — δεν υπάρχει υπηρεσία εκεί
- **Timeout:** Το firewall απορρίπτει σιωπηλά (DROP) — η θύρα δεν απαντά καθόλου

Το `Test-NetConnection` εκτελεί αυτό το handshake και μας λέει αν πέτυχε.

**Γνωστές Θύρες:**

| Port | Protocol | Υπηρεσία |
|------|----------|---------|
| 20, 21 | TCP | FTP |
| 22 | TCP | SSH |
| 23 | TCP | Telnet (ανασφαλές) |
| 25 | TCP | SMTP (email αποστολή) |
| 53 | UDP/TCP | DNS |
| 80 | TCP | HTTP |
| 110 | TCP | POP3 (email λήψη) |
| 143 | TCP | IMAP |
| 389 | TCP | LDAP (Active Directory) |
| 443 | TCP | HTTPS |
| 445 | TCP | SMB (File Sharing) |
| 3389 | TCP | RDP (Remote Desktop) |
| 5985 | TCP | WinRM (PowerShell Remoting) |

**Εντολές:**

```powershell
:: Βασικός έλεγχος
Test-NetConnection google.com

:: Έλεγχος συγκεκριμένης θύρας
Test-NetConnection 192.168.1.50 -Port 3389    :: RDP
Test-NetConnection 192.168.1.50 -Port 445     :: SMB/File Sharing
Test-NetConnection 192.168.1.50 -Port 443     :: HTTPS
Test-NetConnection 192.168.1.50 -Port 389     :: LDAP/Active Directory

:: Αναλυτικό αποτέλεσμα
Test-NetConnection -ComputerName "server01" -Port 443 -InformationLevel Detailed
```

**Ανάγνωση αποτελέσματος:**

| Αποτέλεσμα | Σημαίνει |
|------------|---------|
| `TcpTestSucceeded: True` | 3-way handshake επιτυχές — υπηρεσία ακούει |
| `TcpTestSucceeded: False` + `PingSucceeded: True` | Server διαθέσιμος αλλά firewall μπλοκάρει τη θύρα |
| `TcpTestSucceeded: False` + `PingSucceeded: False` | Server δεν είναι διαθέσιμος ή ICMP blocked |

---

### `netstat` — Network Statistics

#### 📖 Θεωρία: TCP States και πώς διαβάζουμε συνδέσεις

Κάθε TCP σύνδεση περνά από διάφορες **καταστάσεις (states)** κατά τη διάρκεια ζωής της:

```ini
CLOSED ──► LISTEN ──► SYN_RECEIVED ──► ESTABLISHED ──► FIN_WAIT ──► TIME_WAIT ──► CLOSED
                          ▲                  │
                      (Server)           (Δεδομένα)
```

| State | Σημαίνει |
|-------|---------|
| `LISTENING` | Η εφαρμογή περιμένει εισερχόμενες συνδέσεις σε αυτή τη θύρα |
| `ESTABLISHED` | Ενεργή σύνδεση — δεδομένα μεταφέρονται |
| `TIME_WAIT` | Σύνδεση κλείνει — αναμονή για καθυστερημένα πακέτα |
| `CLOSE_WAIT` | Remote server έκλεισε, ο local process δεν αποκρίθηκε ακόμα |
| `SYN_SENT` | Έγινε SYN, αναμονή για SYN-ACK |

**Εντολές:**

```cmd
netstat -ano                          :: Όλες οι συνδέσεις + PIDs
netstat -ano | findstr :443           :: Φιλτράρισμα ανά θύρα
netstat -ano | findstr ESTABLISHED    :: Μόνο ενεργές συνδέσεις
netstat -ano | findstr LISTENING      :: Τι "ακούει" ο υπολογιστής
netstat -b                            :: Ποιο πρόγραμμα ανά σύνδεση (Admin)
```

**Security Use Case — Εντοπισμός ύποπτης σύνδεσης:**

```cmd
:: Βήμα 1: Βρες ύποπτες εξωτερικές ESTABLISHED συνδέσεις
netstat -ano | findstr ESTABLISHED

:: Αποτέλεσμα (παράδειγμα):
:: TCP  192.168.1.10:52341  185.220.101.45:4444  ESTABLISHED  4832
::                           ^^^^^^^^^^^^^^^^^^^              ^^^^
::                           Άγνωστη εξωτερική IP            PID

:: Βήμα 2: Βρες ποιο πρόγραμμα έχει το PID 4832
tasklist /FI "PID eq 4832"

:: Βήμα 3: Αν είναι ύποπτο → τερμάτισε
taskkill /PID 4832 /F

:: Βήμα 4: Ελέγξε αν η IP είναι γνωστή απειλή
:: (αναζήτηση σε VirusTotal, AbuseIPDB κτλ.)
```

---

### `ncpa.cpl` & `networkreset`

```cmd
ncpa.cpl        :: Άνοιγμα Network Connections GUI
networkreset    :: Πλήρης reset (τελευταία λύση)
```

**Στοχευμένο reset (προτιμότερο):**

```cmd
:: Reset μόνο TCP/IP stack
netsh int ip reset
netsh winsock reset

:: Reset μόνο DNS
ipconfig /flushdns

:: Reset ARP cache
arp -d *

:: Μετά από όλα τα παραπάνω → reboot
shutdown /r /t 0
```

> ⚠️ Το `networkreset` διαγράφει αποθηκευμένα Wi-Fi passwords και VPN ρυθμίσεις. Χρησιμοποίησέ το μόνο αν τα παραπάνω δεν βοηθήσουν.

---

## 👤 2. Διαχείριση Χρηστών & Ταυτοποίησης

#### 📖 Θεωρία: Windows Authentication — NTLM vs Kerberos

Τα Windows χρησιμοποιούν δύο πρωτόκολλα authentication:

**NTLM (NT LAN Manager)** — Παλαιό, για workgroup/local authentication:

```ini
Client ──► "Θέλω να συνδεθώ" ──► Server
Client ◄── Challenge (random number) ──── Server
Client ──► Response (hash του password + challenge) ──► Server
Server επαληθεύει → ΟΚ ή FAIL
```

**Kerberos** — Σύγχρονο, για Active Directory environments:

```ini
Client ──► "Θέλω TGT" ──────────────────────────► KDC (Domain Controller)
Client ◄── TGT (Ticket Granting Ticket) ◄────────
Client ──► "Θέλω πρόσβαση στον FileServer" ─────► KDC
Client ◄── Service Ticket ◄──────────────────────
Client ──► Service Ticket ──────────────────────► FileServer
FileServer επαληθεύει το ticket → πρόσβαση!
```

**Γιατί Kerberos > NTLM:**

- Password δεν ταξιδεύει ποτέ στο δίκτυο (μόνο tickets)
- Αμοιβαία authentication (client ΚΑΙ server αποδεικνύουν ταυτότητα)
- Υποστηρίζει delegation

---

### `net use` — Map Network Drives

```cmd
net use Z: \\ServerName\SharedFolder
net use Z: \\ServerName\SharedFolder /user:DOMAIN\username Password123
net use Z: \\ServerName\SharedFolder /persistent:yes    :: Παραμένει μετά reboot
net use                    :: Εμφάνιση όλων των συνδέσεων
net use Z: /delete         :: Αποσύνδεση
net use * /delete          :: Αποσύνδεση όλων
```

**📖 Θεωρία: SMB Protocol**

Το `net use` χρησιμοποιεί **SMB (Server Message Block)** — πρωτόκολλο κοινής χρήσης αρχείων που τρέχει στο **TCP port 445**.

```ini
Client ──► SMB Negotiate ──────────────────► File Server (port 445)
Client ──► Session Setup (authentication) ──► File Server
Client ──► Tree Connect (σύνδεση στο share) ► File Server
Client ◄──► Read/Write Files ◄──────────────► File Server
```

> ⚠️ **SMBv1 είναι επικίνδυνο** — εκμεταλλεύτηκε από WannaCry ransomware. Πάντα χρησιμοποίησε SMBv2/v3.

---

### `net user` & `net localgroup`

```cmd
net user                          :: Λίστα όλων των local users
net user [username]               :: Πληροφορίες χρήστη
net user NewUser P@ss123 /add     :: Δημιουργία
net user [username] NewPass123    :: Reset κωδικού
net user [username] /active:no    :: Disable
net user [username] /active:yes   :: Enable

net localgroup administrators               :: Ποιοι είναι Admins
net localgroup administrators [user] /add   :: Προσθήκη στους Admins
net localgroup administrators [user] /delete :: Αφαίρεση
```

**📖 Θεωρία: SAM Database & SID**

Οι τοπικοί χρήστες αποθηκεύονται στο **SAM (Security Accounts Manager)** database (`C:\Windows\System32\config\SAM`). Κάθε χρήστης έχει μοναδικό **SID (Security Identifier)**:

```ini
S-1-5-21-1234567890-1234567890-1234567890-1001
│ │ │  └──────────────────────────────────┘ └─ RID (χρήστης)
│ │ └── NT Authority
│ └── Revision
└── SID prefix
```

Γνωστά RIDs:

- `500` → Built-in Administrator
- `501` → Guest
- `1000+` → Κανονικοί χρήστες

> 💡 Ακόμα και αν μετονομάσεις τον Administrator, το SID-500 παραμένει το ίδιο — γι' αυτό το SID χρησιμοποιείται για permissions, όχι το όνομα.

---

### `whoami /all`

```cmd
whoami              :: Username
whoami /all         :: Groups + Privileges + SIDs
whoami /groups      :: Μόνο groups
whoami /priv        :: Μόνο privileges
```

**📖 Θεωρία: Access Tokens**

Όταν ο χρήστης κάνει logon, ο Domain Controller εκδίδει ένα **Access Token** που περιέχει:

- SID του χρήστη
- SIDs όλων των groups που ανήκει
- Privileges (π.χ. SeShutdownPrivilege, SeDebugPrivilege)

Αυτό το token "κολλάει" σε κάθε process που ανοίγει ο χρήστης και χρησιμοποιείται για κάθε απόφαση πρόσβασης.

> 💡 Γι' αυτό μετά από αλλαγή group membership στο AD, ο χρήστης **πρέπει να κάνει log out + log in** — για να εκδοθεί νέο token με τα ενημερωμένα groups.

```cmd
:: Επιβεβαίωση ότι ο χρήστης πήρε νέο group
whoami /groups | findstr "IT-Admins"
```

---

### `systeminfo`

```cmd
systeminfo
systeminfo | findstr /i "boot time"
systeminfo | findstr /i "OS Version"
systeminfo | findstr /i "Total Physical"
systeminfo | findstr /i "Hotfix"
```

**Γιατί το Boot Time είναι κρίσιμο για Helpdesk:**

> Windows 10/11 έχει **Fast Startup** — στο "Shutdown" δεν κλείνει πλήρως το σύστημα, αποθηκεύει την κατάσταση kernel στο disk. Αυτό σημαίνει ότι ένα "Shutdown + Power On" **ΔΕΝ είναι πλήρες reboot**. Μόνο το **Restart** κάνει πλήρη επανεκκίνηση.

```cmd
:: Αν ο χρήστης λέει "έκανα restart" αλλά το πρόβλημα δεν λύθηκε:
systeminfo | findstr /i "boot time"
:: Αν η ώρα είναι παλιά → έκανε Shutdown, όχι Restart
```

---

## ⚙️ 3. Διαχείριση Διεργασιών

#### 📖 Θεωρία: Processes, Threads και Virtual Memory

Κάθε εκτελούμενο πρόγραμμα είναι ένα **Process** — μια απομονωμένη "φούσκα" με:

- Δικό του **Virtual Address Space** (RAM)
- Ένα ή περισσότερα **Threads** (ροές εκτέλεσης)
- **Handles** (ανοιχτά αρχεία, registry keys, network connections)
- Ένα **Access Token** (ποιος το τρέχει)

```ini
Process: chrome.exe (PID: 1234)
├── Thread 1: Main UI
├── Thread 2: Network
├── Thread 3: Rendering
└── Virtual Memory: 500MB
```

Το **PID (Process ID)** είναι μοναδικό αναγνωριστικό κάθε process και αλλάζει σε κάθε εκτέλεση.

---

### `tasklist`

```cmd
tasklist                                       :: Όλα τα processes
tasklist /FI "MEMUSAGE gt 100000"              :: Πάνω από 100MB RAM
tasklist /FI "IMAGENAME eq chrome.exe"        :: Συγκεκριμένο πρόγραμμα
tasklist /SVC                                  :: Services ανά process
tasklist /V                                    :: Ποιος χρήστης τρέχει τι
```

**PowerShell — Πιο ισχυρό:**

```powershell
:: Top 10 ανά RAM
Get-Process | Sort-Object WorkingSet -Descending |
    Select-Object -First 10 Name, Id,
    @{N="RAM(MB)";E={[math]::Round($_.WorkingSet/1MB,1)}}

:: Processes ανά CPU
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10

:: Βρες process ανά PID
Get-Process -Id 1234 | Select-Object *
```

---

### `taskkill`

```cmd
taskkill /PID 1234 /F              :: Kill ανά PID (force)
taskkill /IM chrome.exe /F         :: Kill ανά όνομα
taskkill /IM notepad.exe /F /T     :: Kill + child processes
```

> ⚠️ `/F` (Force) = αναγκαστικός τερματισμός, αγνοεί unsaved data. Χρησιμοποίησέ το μόνο σε frozen processes.

---

## 🛡️ 4. Group Policy

#### 📖 Θεωρία: Πώς λειτουργούν τα GPOs

Τα **GPOs (Group Policy Objects)** είναι ρυθμίσεις που ο Domain Controller εφαρμόζει αυτόματα σε υπολογιστές και χρήστες.

**Πώς φτάνουν οι ρυθμίσεις στον υπολογιστή:**

```ini
Domain Controller (SYSVOL share)
         │
         │  Κάθε 90-120 λεπτά (ή με gpupdate /force)
         │
         ▼
Υπολογιστής κατεβάζει GPOs από \\domain\SYSVOL\...
         │
         ▼
Εφαρμογή ρυθμίσεων (registry, files, scripts)
```

**Σειρά Εφαρμογής — LSDOU** (το τελευταίο "κερδίζει"):

```ini
1. Local Policy       (τοπικές ρυθμίσεις υπολογιστή)
       ↓
2. Site Policy        (ανά physical location)
       ↓
3. Domain Policy      (ολόκληρο το domain)
       ↓
4. OU Policy          (συγκεκριμένο OU — υψηλότερη προτεραιότητα)
```

> 💡 Αν ένα GPO έχει **Enforce**, δεν μπορεί να παρακαμφθεί από κατώτερο OU.

---

### Εντολές GPO

```cmd
gpupdate /force                           :: Άμεση εφαρμογή
gpupdate /force /target:computer          :: Μόνο Computer settings
gpupdate /force /target:user              :: Μόνο User settings

gpresult /r                               :: Summary (text)
gpresult /r /user:d.katsanos             :: Για συγκεκριμένο user
gpresult /h C:\report.html /f            :: HTML αναφορά
start C:\report.html                     :: Άνοιγμα στον browser
```

**Troubleshooting: Γιατί ένα GPO δεν εφαρμόζεται;**

```ini
1. gpresult /r → Βλέπω "Filtered Out"
      ↓
2. Λόγοι φιλτραρίσματος:
   - Security Filtering: Ο χρήστης δεν ανήκει στο group
   - WMI Filter: Condition δεν ικανοποιείται (π.χ. λάθος OS)
   - Block Inheritance: Ανώτερο OU μπλοκάρει
      ↓
3. whoami /groups → Ελέγχω αν έχω το σωστό group
      ↓
4. gpupdate /force → Δοκιμάζω ξανά
```

---

## 🧰 5. Ακεραιότητα & Επισκευή Συστήματος

#### 📖 Θεωρία: Component Store και System File Protection

Τα Windows διατηρούν ένα **Component Store** (`C:\Windows\WinSxS`) — αποθήκη με **όλες τις εκδόσεις** κάθε system file. Αυτό επιτρέπει:

- Αναίρεση Windows Updates
- Επισκευή κατεστραμμένων αρχείων
- Side-by-side installation διαφορετικών εκδόσεων DLL

Το **SFC** χρησιμοποιεί αυτή την αποθήκη ως πηγή για αντικατάσταση. Αν η αποθήκη είναι κατεστραμμένη → το DISM τη διορθώνει → μετά το SFC μπορεί να δουλέψει.

**Ιεραρχία Επισκευής:**

```ini
┌─────────────────────────────────────────────────────┐
│                                                     │
│  ΒΗΜΑ 1: DISM                                      │
│  Κατεβάζει υγιή αρχεία από Microsoft servers       │
│  Επισκευάζει το Component Store (WinSxS)            │
│                       ↓                             │
│  ΒΗΜΑ 2: SFC                                       │
│  Σαρώνει system files                               │
│  Αντικαθιστά κατεστραμμένα από το WinSxS           │
│  (που μόλις επισκευάστηκε)                          │
│                       ↓                             │
│  REBOOT                                             │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

### Βήμα 1: `DISM`

```cmd
:: Γρήγορος έλεγχος (χωρίς αλλαγές — δευτερόλεπτα)
dism /online /cleanup-image /checkhealth

:: Πλήρης σάρωση (χωρίς αλλαγές — λεπτά)
dism /online /cleanup-image /scanhealth

:: Επισκευή (κατεβάζει από internet — 10-20 λεπτά)
dism /online /cleanup-image /restorehealth

:: Χωρίς internet — χρήση ISO ως πηγή
dism /online /cleanup-image /restorehealth /source:WIM:D:\sources\install.wim:1 /limitaccess
```

**Ανάγνωση αποτελέσματος:**

| Μήνυμα | Σημαίνει |
|--------|---------|
| `No component store corruption detected` | Όλα ΟΚ |
| `Component store corruption detected. The component store can be repaired` | Βρήκε και μπορεί να διορθώσει |
| `The restore operation completed successfully` | Επισκευή ολοκληρώθηκε |

---

### Βήμα 2: `SFC`

```cmd
:: Σάρωση + επισκευή (απαιτεί Admin — 5-15 λεπτά)
sfc /scannow

:: Μόνο σάρωση (χωρίς αλλαγές)
sfc /verifyonly

:: Offline (αν Windows δεν ξεκινά — από Recovery Environment)
sfc /scannow /offbootdir=C:\ /offwindir=C:\Windows
```

**Ανάγνωση αποτελέσματος:**

| Μήνυμα | Σημαίνει | Επόμενο Βήμα |
|--------|---------|-------------|
| `did not find any integrity violations` | Όλα ΟΚ | — |
| `found corrupt files and repaired them` | Διορθώθηκε | Reboot |
| `found corrupt files but was unable to fix some` | Μερική αποτυχία | Τρέξε DISM → SFC ξανά |

**Έλεγχος logs:**

```cmd
:: Λεπτομέρειες τι βρήκε και τι διόρθωσε
notepad C:\Windows\Logs\CBS\CBS.log

:: Φιλτράρισμα μόνο των σφαλμάτων
findstr /c:"[SR]" C:\Windows\Logs\CBS\CBS.log
```

---

### Πλήρης Διαδικασία Επισκευής

```cmd
:: ① Τρέξε ως Administrator

:: ② Γρήγορος έλεγχος DISM
dism /online /cleanup-image /checkhealth

:: ③ Επισκευή Component Store (αν χρειαστεί)
dism /online /cleanup-image /restorehealth

:: ④ Σάρωση & επισκευή system files
sfc /scannow

:: ⑤ Reboot
shutdown /r /t 0

:: ⑥ Μετά το reboot — αν το πρόβλημα παραμένει
:: τρέξε SFC ξανά (μερικές φορές χρειάζεται 2-3 φορές)
sfc /scannow
```

---

## 📋 6. Quick Reference — Cheat Sheet

### 🌐 Δίκτυο

| Εντολή | Χρήση | Protocol |
|--------|-------|---------|
| `ipconfig /all` | Λεπτομέρειες adapters | DHCP |
| `ipconfig /flushdns` | Εκκαθάριση DNS cache | DNS |
| `ipconfig /release && /renew` | Ανανέωση IP | DHCP (DORA) |
| `ping 8.8.8.8` | Έλεγχος internet | ICMP |
| `ping google.com` | Έλεγχος DNS | ICMP + DNS |
| `tracert google.com` | Εύρεση που "κολλάει" | ICMP TTL |
| `nslookup google.com` | DNS query | DNS (UDP 53) |
| `Test-NetConnection IP -Port X` | Έλεγχος firewall/port | TCP Handshake |
| `netstat -ano` | Ενεργές συνδέσεις + PIDs | TCP/UDP |

### 👤 Χρήστες

| Εντολή | Χρήση |
|--------|-------|
| `whoami /all` | User + groups + privileges + SIDs |
| `net user [user]` | Πληροφορίες χρήστη (SAM) |
| `net localgroup administrators` | Ποιοι είναι Admins |
| `net user [user] /active:no` | Disable account |
| `net use Z: \\server\share` | Map network drive (SMB) |

### ⚙️ Processes

| Εντολή | Χρήση |
|--------|-------|
| `tasklist` | Λίστα processes |
| `tasklist /FI "MEMUSAGE gt 100000"` | Processes >100MB RAM |
| `taskkill /PID X /F` | Kill process |
| `netstat -ano \| findstr ESTABLISHED` | Ενεργές συνδέσεις |

### 🛡️ GPO

| Εντολή | Χρήση |
|--------|-------|
| `gpupdate /force` | Άμεση εφαρμογή GPOs |
| `gpresult /r` | Ποια GPOs εφαρμόστηκαν |
| `gpresult /h report.html` | Αναλυτική HTML αναφορά |

### 🧰 Επισκευή

| Εντολή | Χρήση | Σειρά |
|--------|-------|-------|
| `dism /online /cleanup-image /checkhealth` | Γρήγορος έλεγχος | 1ο |
| `dism /online /cleanup-image /restorehealth` | Επισκευή Component Store | 2ο |
| `sfc /scannow` | Επισκευή system files | 3ο |

---

> 📝 **Σημείωση:** Οι εντολές `sfc`, `dism`, `taskkill /F`, `net user`, `net localgroup` απαιτούν εκτέλεση **ως Administrator** (δεξί κλικ → Run as administrator).
