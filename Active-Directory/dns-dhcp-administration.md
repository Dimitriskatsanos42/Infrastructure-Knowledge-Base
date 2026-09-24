# 🌐 DNS & DHCP Administration — Θεωρία & Real-World Runbook
> Συνοδευτικό αρχείο στη σειρά Active Directory — το AD **δεν λειτουργεί χωρίς σωστό DNS**, και κάθε domain-joined συσκευή χρειάζεται DHCP για να πάρει IP. Αυτά τα δύο services είναι από τα πρώτα πράγματα που θα διαχειριστείς σε πραγματική IT θέση.

---

## 🗺️ Πίνακας Περιεχομένων

1. [DNS — Βασική Θεωρία](#-1-dns--βασική-θεωρία)
2. [Τύποι DNS Records](#-2-τύποι-dns-records)
3. [DNS Zones & AD Integration](#-3-dns-zones--ad-integration)
4. [DHCP — Βασική Θεωρία](#-4-dhcp--βασική-θεωρία)
5. [Σενάριο — Το Ticket](#-5-σενάριο--το-ticket)
6. [Runbook: Νέο DHCP Scope για Νέο VLAN](#-6-runbook-νέο-dhcp-scope-για-νέο-vlan)
7. [DHCP Reservations & Options](#-7-dhcp-reservations--options)
8. [High Availability — DHCP Failover](#-8-high-availability--dhcp-failover)
9. [DNS Security — Βασικά](#-9-dns-security--βασικά)
10. [Monitoring & Logging](#-10-monitoring--logging)
11. [Troubleshooting](#-11-troubleshooting)
12. [Checklist — Go-Live](#-12-checklist--go-live)

---

## 📖 1. DNS — Βασική Θεωρία

Το **DNS (Domain Name System)** μεταφράζει ονόματα (`fs01.company.local`) σε IP διευθύνσεις (`10.10.5.20`). Χωρίς αυτό, κανένα domain-joined μηχάνημα δεν μπορεί να βρει Domain Controller, να κάνει authenticate, ή να βρει άλλο resource στο δίκτυο.

```
Client ζητάει: "Ποια είναι η IP του fs01.company.local;"
    ↓
DNS Server ελέγχει τη zone "company.local"
    ↓
Βρίσκει A record: fs01 → 10.10.5.20
    ↓
Επιστρέφει την IP στον client
    ↓
Ο client συνδέεται απευθείας στο 10.10.5.20
```

> 💡 Όπως αναφέρθηκε στο [`active-directory-advanced.md`](./active-directory-advanced.md#-5-dns-integration), το AD χρησιμοποιεί ειδικά **SRV records** για να βρίσκουν οι clients Domain Controllers — αυτό είναι ένα μόνο κομμάτι της συνολικής δουλειάς που κάνει το DNS σε ένα domain.

---

## 📋 2. Τύποι DNS Records

| Record Type | Τι κάνει | Παράδειγμα |
|---|---|---|
| **A** | Όνομα → IPv4 address | `fs01.company.local → 10.10.5.20` |
| **AAAA** | Όνομα → IPv6 address | `fs01.company.local → 2001:db8::1` |
| **CNAME** | Alias — όνομα → άλλο όνομα | `files.company.local → fs01.company.local` |
| **PTR** | Reverse lookup — IP → όνομα | `10.5.10.10.in-addr.arpa → fs01.company.local` |
| **MX** | Mail server για το domain | `company.local → mail.company.local (priority 10)` |
| **SRV** | Service location (π.χ. LDAP, Kerberos) | `_ldap._tcp.company.local → dc01.company.local:389` |
| **NS** | Ποιοι servers είναι authoritative για τη zone | `company.local → dc01.company.local` |
| **SOA** | Start of Authority — metadata για τη zone (serial number, refresh interval) | — |
| **TXT** | Ελεύθερο κείμενο — SPF, domain verification, κ.λπ. | `v=spf1 include:_spf.google.com ~all` |

```powershell
# Προβολή records μιας zone
Get-DnsServerResourceRecord -ZoneName "company.local"

# Δημιουργία A record
Add-DnsServerResourceRecordA -ZoneName "company.local" -Name "fs02" -IPv4Address "10.10.5.21"

# Δημιουργία CNAME
Add-DnsServerResourceRecordCName -ZoneName "company.local" -Name "files" -HostNameAlias "fs01.company.local"

# Διαγραφή record
Remove-DnsServerResourceRecord -ZoneName "company.local" -Name "old-server" -RRType A -Force
```

> ⚠️ **Πολύ συχνό λάθος:** Δημιουργείς A record για νέο server αλλά ξεχνάς το αντίστοιχο **PTR record** στη reverse lookup zone. Αποτέλεσμα: forward lookup δουλεύει (`server.company.local → IP`), αλλά reverse lookup αποτυγχάνει (`IP → όνομα`) — αυτό σπάει πράγματα όπως Kerberos (που κάνει reverse lookup σε ορισμένα σενάρια) και certain logging/security tools.

---

## 🗄️ 3. DNS Zones & AD Integration

| Τύπος Zone | Περιγραφή |
|---|---|
| **Primary Zone** | Το "master" αντίγραφο — εδώ γίνονται οι αλλαγές |
| **Secondary Zone** | Read-only αντίγραφο, "τραβάει" αλλαγές από το primary (zone transfer) |
| **Stub Zone** | Κρατάει μόνο NS records — ξέρει "ποιον να ρωτήσει", όχι όλη τη zone |
| **AD-Integrated Zone** | Η zone αποθηκεύεται *μέσα* στο AD database, replikάρεται αυτόματα σε κάθε DC που τρέχει DNS |

> 💡 Στα περισσότερα σύγχρονα περιβάλλοντα χρησιμοποιείς **AD-Integrated zones** — παίρνεις multi-master replication δωρεάν (κάθε DC μπορεί να δεχτεί αλλαγή), fault tolerance, και secure dynamic updates (μόνο domain-joined μηχανήματα με σωστά credentials μπορούν να κάνουν register).

```powershell
# Δημιουργία νέας AD-integrated forward lookup zone
Add-DnsServerPrimaryZone -Name "company.local" -ReplicationScope "Forest" -DynamicUpdate Secure

# Δημιουργία reverse lookup zone (ΠΑΝΤΑ ξέχασέ την λιγότερο, αλλά είναι εξίσου σημαντική)
Add-DnsServerPrimaryZone -NetworkID "10.10.5.0/24" -ReplicationScope "Forest" -DynamicUpdate Secure

# Έλεγχος replication scope μιας zone
Get-DnsServerZone -Name "company.local" | Select ZoneType, ReplicationScope, DynamicUpdate
```

**Dynamic Updates:**

| Ρύθμιση | Τι σημαίνει | Πότε χρησιμοποιείς |
|---|---|---|
| **None** | Κανείς δεν κάνει auto-register | Legacy/static περιβάλλον |
| **Nonsecure and secure** | Οποιοσδήποτε client μπορεί να γράψει record | ❌ Σχεδόν ποτέ — security risk |
| **Secure only** | Μόνο authenticated domain members | ✅ Standard σε AD-integrated zone |

---

## 📖 4. DHCP — Βασική Θεωρία

Το **DHCP (Dynamic Host Configuration Protocol)** δίνει αυτόματα IP address + network config (gateway, DNS servers, κ.λπ.) σε clients, ώστε να μη χρειάζεται χειροκίνητο static configuration σε κάθε μηχάνημα.

```
Client (μόλις συνδέθηκε στο δίκτυο)
    ↓ DHCP DISCOVER (broadcast: "υπάρχει DHCP server;")
DHCP Server
    ↓ DHCP OFFER ("να μια διαθέσιμη IP: 10.10.5.150")
Client
    ↓ DHCP REQUEST ("θέλω αυτή την IP")
DHCP Server
    ↓ DHCP ACK ("Εντάξει, δική σου για 8 ώρες" — το "lease")

(Γνωστό ως "DORA": Discover, Offer, Request, Acknowledge)
```

### Βασικές Έννοιες

| Όρος | Εξήγηση |
|---|---|
| **Scope** | Εύρος IPs που διαθέτει ο DHCP για ένα συγκεκριμένο subnet |
| **Lease** | Πόσο καιρό "κρατάει" ο client μια IP πριν χρειαστεί renewal |
| **Reservation** | Συγκεκριμένη IP πάντα για συγκεκριμένη συσκευή (βάσει MAC address) |
| **Exclusion** | Εύρος IPs μέσα στο scope που ΔΕΝ μοιράζονται (π.χ. κρατημένα για static servers) |
| **DHCP Options** | Επιπλέον config που στέλνεται μαζί με την IP (DNS servers, gateway, κ.λπ.) |

---

## 🎫 5. Σενάριο — Το Ticket

> **Ticket #4589** — *"Ανοίγουμε νέο όροφο γραφείων (2ος όροφος), θα μπουν 40 νέοι υπολογιστές + 5 εκτυπωτές δικτύου. Χρειαζόμαστε νέο VLAN και αυτόματη διανομή IPs. Οι εκτυπωτές πρέπει να έχουν πάντα την ίδια IP."*

Αυτό μεταφράζεται σε:
1. Νέο DHCP Scope για το νέο subnet/VLAN
2. Reservations για τους 5 εκτυπωτές
3. Exclusion range για static-assigned εξοπλισμό (π.χ. network switches, APs)
4. Σωστά DHCP Options (DNS servers = τα εσωτερικά DCs, όχι public DNS)

---

## 🛠️ 6. Runbook: Νέο DHCP Scope για Νέο VLAN

```powershell
# Βήμα 1: Επιβεβαίωση δικτυακού σχεδιασμού (πριν αγγίξεις οτιδήποτε)
# Networking team δίνει: VLAN 20, subnet 10.10.20.0/24, gateway 10.10.20.1

# Βήμα 2: Δημιουργία του scope
Add-DhcpServerv4Scope -Name "Floor2-VLAN20" `
    -StartRange 10.10.20.50 -EndRange 10.10.20.200 `
    -SubnetMask 255.255.255.0 `
    -Description "2ος όροφος - νέα γραφεία, ticket #4589"

# Βήμα 3: Exclusion range - κρατάμε 10.10.20.1-49 για static equipment (switches, APs, gateway)
Add-DhcpServerv4ExclusionRange -ScopeId 10.10.20.0 `
    -StartRange 10.10.20.1 -EndRange 10.10.20.49

# Βήμα 4: Βασικά DHCP Options - gateway + DNS servers (τα εσωτερικά DCs, ΠΟΤΕ public DNS)
Set-DhcpServerv4OptionValue -ScopeId 10.10.20.0 `
    -Router 10.10.20.1 `
    -DnsServer 10.10.5.10,10.10.5.11 `
    -DnsDomain "company.local"

# Βήμα 5: Lease duration - default 8 μέρες, εδώ πιο σύντομο γιατί laptop-heavy όροφος
Set-DhcpServerv4Scope -ScopeId 10.10.20.0 -LeaseDuration 1.00:00:00   # 1 μέρα

# Βήμα 6: Ενεργοποίηση του scope
Set-DhcpServerv4Scope -ScopeId 10.10.20.0 -State Active

# Βήμα 7: Authorization του DHCP server στο AD (χρειάζεται ΜΙΑ φορά ανά server, όχι ανά scope)
Add-DhcpServerInDC -DnsName "dhcp01.company.local" -IPAddress 10.10.5.15
```

> ⚠️ **Κρίσιμο σημείο:** Ένας Windows DHCP server **δεν διανέμει καθόλου IPs** αν δεν είναι **authorized** μέσα στο AD (`Add-DhcpServerInDC`). Αυτό είναι μια built-in προστασία ώστε rogue/unauthorized DHCP servers να μην μπορούν εύκολα να "μπερδέψουν" το δίκτυο — αλλά είναι επίσης το πιο συχνό "γιατί δεν παίρνουν IP οι clients" λάθος από νέους sysadmins.

---

## 📌 7. DHCP Reservations & Options

```powershell
# Reservation για printer - πάντα η ίδια IP, βάσει MAC address
Add-DhcpServerv4Reservation -ScopeId 10.10.20.0 `
    -IPAddress 10.10.20.10 `
    -ClientId "00-1B-63-84-45-E6" `
    -Description "Printer-Floor2-HP-LaserJet"

# Λίστα όλων των reservations σε ένα scope
Get-DhcpServerv4Reservation -ScopeId 10.10.20.0

# Scope-level option (αφορά ΜΟΝΟ αυτό το scope)
Set-DhcpServerv4OptionValue -ScopeId 10.10.20.0 -OptionId 15 -Value "company.local"

# Server-level option (αφορά ΟΛΑ τα scopes σε αυτόν τον DHCP server)
Set-DhcpServerv4OptionValue -OptionId 6 -Value 10.10.5.10,10.10.5.11   # DNS servers, όλα τα scopes
```

| Option ID | Τι είναι | Γιατί το χρειάζεσαι |
|---|---|---|
| **3** | Router (Gateway) | Χωρίς αυτό, ο client δεν βγαίνει έξω από το subnet |
| **6** | DNS Servers | Χωρίς αυτό, ο client δεν μπορεί να κάνει resolve domain names |
| **15** | DNS Domain Name | Auto-suffix σε unqualified queries |
| **44** | WINS Server | Legacy, σπάνια χρειάζεται σήμερα |
| **51** | Lease Time | Πόσο κρατάει η IP |
| **66/67** | Boot Server/Filename | PXE boot — χρήσιμο για OS deployment (π.χ. MDT/SCCM) |

> 💡 **Real-world tip:** Reservations για printers/εκτυπωτές είναι σχεδόν πάντα καλύτερη πρακτική από static IP configuration πάνω στη συσκευή — αν αλλάξει ποτέ το subnet design, αλλάζεις μόνο τη reservation στον DHCP server, όχι κάθε printer ξεχωριστά με physical/web access σε κάθε συσκευή.

---

## 🔁 8. High Availability — DHCP Failover

Αν ο DHCP server πέσει, κανείς νέος client δεν παίρνει IP (τα υπάρχοντα leases συνεχίζουν να δουλεύουν μέχρι να λήξουν). Σε πραγματική εταιρεία με uptime requirements, χρησιμοποιείς **DHCP Failover**.

```powershell
# Δημιουργία failover relationship μεταξύ δύο DHCP servers
Add-DhcpServerv4Failover -Name "Failover-FS-DHCP01-DHCP02" `
    -ScopeId 10.10.20.0 `
    -PartnerServer "dhcp02.company.local" `
    -Mode LoadBalance `
    -SharedSecret "P@ssw0rd!" `
    -MaxClientLeadTime 01:00:00

# Έλεγχος κατάστασης failover
Get-DhcpServerv4Failover
```

| Mode | Πώς δουλεύει |
|---|---|
| **Load Balance** | Και οι δύο servers απαντούν ενεργά, μοιράζονται το load (π.χ. 50/50) |
| **Hot Standby** | Ένας server είναι active, ο άλλος περιμένει σε standby μέχρι να χρειαστεί |

---

## 🔒 9. DNS Security — Βασικά

| Πρακτική | Γιατί |
|---|---|
| **Secure Dynamic Updates only** (§3) | Αποτρέπει unauthorized records από non-domain devices |
| **DNSSEC** | Κρυπτογραφική υπογραφή records — αποτρέπει DNS spoofing/cache poisoning |
| **Response Rate Limiting (RRL)** | Προστασία από DNS amplification attacks |
| **Restrict Zone Transfers** | Zone transfers (AXFR) μόνο σε authorized secondary servers, ποτέ "to any server" |
| **DNS Socket Pool** | Randomization των source ports για queries — δυσκολεύει το cache poisoning |

```powershell
# Έλεγχος ποιοι μπορούν να κάνουν zone transfer
Get-DnsServerZoneTransferPolicy -ZoneName "company.local"

# Restriction σε συγκεκριμένους secondary servers
Set-DnsServerPrimaryZone -Name "company.local" -SecureSecondaries TransferToZoneNameServer

# Ενεργοποίηση DNSSEC signing (advanced, χρειάζεται planning πριν)
# Καλύτερα μέσω DNS Manager GUI για wizard-guided setup σε production
```

> ⚠️ **Rogue DHCP servers:** Σε δίκτυα χωρίς port security/DHCP snooping στα switches, οποιοσδήποτε συνδέσει έναν μη-εξουσιοδοτημένο router/DHCP server (π.χ. φέρνει από το σπίτι) μπορεί να "μοιράσει" λάθος gateway/DNS σε clients — classic MITM vector. Αυτό αντιμετωπίζεται στο network layer (DHCP Snooping σε managed switches), όχι στο Windows DHCP server layer — καλό να το ξέρεις για coordination με το networking team.

---

## 📊 10. Monitoring & Logging

```powershell
# DHCP audit logging - ενεργό by default, εδώ βλέπεις πού αποθηκεύεται
Get-DhcpServerAuditLog

# DHCP statistics - πόσα leases, utilization ανά scope
Get-DhcpServerv4ScopeStatistics

# DNS analytical/debug logging (χρήσιμο ΜΟΝΟ προσωρινά - βαρύ σε performance)
Set-DnsServerDiagnostics -All $true
# ... reproduce το πρόβλημα ...
Set-DnsServerDiagnostics -All $false   # ΠΑΝΤΑ απενεργοποίησέ το μετά
```

| Τι παρακολουθείς | Γιατί |
|---|---|
| **Scope utilization %** | Αν πλησιάζει 90%+, χρειάζεσαι μεγαλύτερο range ή νέο scope πριν "τελειώσουν" οι IPs |
| **Lease/sec rate ασυνήθιστα υψηλό** | Πιθανό network loop ή malfunctioning device |
| **DNS query failures** | Πιθανό πρόβλημα connectivity με upstream/forwarders |

---

## 🔧 11. Troubleshooting

| Πρόβλημα | Πιθανή Αιτία | Λύση |
|---|---|---|
| Client δεν παίρνει καθόλου IP (APIPA 169.254.x.x) | DHCP server unreachable, scope εξαντλημένο, ή server unauthorized | `Get-DhcpServerv4Scope`, έλεγξε utilization, έλεγξε `Add-DhcpServerInDC` |
| Client παίρνει IP από λάθος scope | Relay agent config λάθος (αν cross-subnet) | Έλεγξε IP Helper στο router/L3 switch |
| "Cannot resolve hostname" σε domain-joined PC | Client έχει public DNS αντί για internal DC | `ipconfig /all`, βεβαιώσου DNS = εσωτερικά DCs (βλέπε `active-directory-advanced.md` §5) |
| Νέο record δεν φαίνεται σε άλλο DC | AD replication lag | `repadmin /syncall /AdeP`, περίμενε replication interval |
| "Trust relationship" errors μετά από DNS αλλαγές | Stale DNS cache στον client | `ipconfig /flushdns`, `ipconfig /registerdns` |
| Duplicate IP conflict | Static IP σε συσκευή μέσα στο DHCP range χωρίς exclusion | Πρόσθεσε exclusion range, ή reservation για static devices |
| Printer "χάνει" IP μετά από reboot | Δεν έγινε reservation, μόνο dynamic lease | `Add-DhcpServerv4Reservation` (§7) |

```powershell
# Γρήγορη διάγνωση client-side
ipconfig /all
ipconfig /release
ipconfig /renew
ipconfig /flushdns
ipconfig /registerdns

# Server-side - υγεία DHCP service
Get-Service DHCPServer
Get-DhcpServerv4Statistics

# Server-side - υγεία DNS service
Get-Service DNS
Get-DnsServerDiagnostics
Resolve-DnsName "fs01.company.local" -Server "dc01.company.local"
```

---

## ✅ 12. Checklist — Go-Live

```
☐ Επιβεβαιώθηκε subnet/VLAN design με networking team
☐ DHCP Scope δημιουργήθηκε με σωστό range
☐ Exclusion range για static equipment
☐ DHCP Options σωστά (Router, DNS Servers, Domain Name)
☐ Lease duration κατάλληλη για τον τύπο δικτύου (laptops vs desktops vs IoT)
☐ Reservations για εξοπλισμό που χρειάζεται σταθερή IP (printers, servers)
☐ DHCP server authorized στο AD
☐ Scope ενεργοποιήθηκε (State = Active)
☐ Failover ρυθμίστηκε (αν απαιτείται HA)
☐ Forward DNS record υπάρχει για κάθε νέο server/resource
☐ Reverse (PTR) DNS record υπάρχει επίσης
☐ Test: νέος client στο VLAN παίρνει σωστή IP + DNS + gateway
☐ Test: νέος client μπορεί να κάνει resolve internal hostname
☐ Documentation ενημερώθηκε (scope details, reservations, ticket reference)
```

---

## 📚 Σχετικά αρχεία

- [`active-directory.md`](./active-directory.md) — Users/Groups, OUs, GPO, Entra ID
- [`active-directory-advanced.md`](./active-directory-advanced.md) — FSMO, Replication, DNS Integration §5, Trusts
- [`file-permissions-ntfs.md`](./file-permissions-ntfs.md) — NTFS/Share permissions θεωρία
- [`file-server-implementation-runbook.md`](./file-server-implementation-runbook.md) — Real-world file share deployment
- Αυτό το αρχείο (`dns-dhcp-administration.md`) — DNS/DHCP θεωρία + real-world runbook
