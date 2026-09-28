# 📜 Active Directory Certificate Services (AD CS) — PKI Deep Dive
> Συνοδευτικό αρχείο στη σειρά Active Directory. Πολλές εταιρείες χρειάζονται internal PKI (Public Key Infrastructure) για 802.1X WiFi authentication, VPN, internal HTTPS sites, code signing, ή smart card login — και το AD CS είναι το built-in εργαλείο για να το στήσεις χωρίς να πληρώνεις εξωτερική CA για κάθε certificate.

---

## 🗺️ Πίνακας Περιεχομένων

1. [PKI Βασικά — Τι Λύνει Πραγματικά](#-1-pki-βασικά--τι-λύνει-πραγματικά)
2. [Τύποι CA — Root vs Subordinate, Enterprise vs Standalone](#-2-τύποι-ca--root-vs-subordinate-enterprise-vs-standalone)
3. [Σενάριο — Το Ticket](#-3-σενάριο--το-ticket)
4. [Runbook: Εγκατάσταση Two-Tier PKI](#-4-runbook-εγκατάσταση-two-tier-pki)
5. [Certificate Templates](#-5-certificate-templates)
6. [Autoenrollment μέσω GPO](#-6-autoenrollment-μέσω-gpo)
7. [Real-World Use Case: 802.1X WiFi Authentication](#-7-real-world-use-case-8021x-wifi-authentication)
8. [Real-World Use Case: Internal HTTPS (Web Server Certs)](#-8-real-world-use-case-internal-https-web-server-certs)
9. [Certificate Revocation — CRL & OCSP](#-9-certificate-revocation--crl--ocsp)
10. [Root CA Security — Γιατί Μένει Offline](#-10-root-ca-security--γιατί-μένει-offline)
11. [Troubleshooting](#-11-troubleshooting)
12. [Checklist — PKI Deployment](#-12-checklist--pki-deployment)

---

## 🔑 1. PKI Βασικά — Τι Λύνει Πραγματικά

Ένα certificate είναι ένας ψηφιακός τρόπος να αποδείξεις **ταυτότητα** — είτε ενός server ("αυτός ο server είναι πράγματι ο `intranet.company.local`"), είτε ενός χρήστη ("αυτός ο χρήστης είναι πράγματι ο `d.katsanos`"), είτε μιας συσκευής ("αυτό το laptop ανήκει πράγματι στην εταιρεία").

```
Public Certificate Authorities (π.χ. DigiCert, Let's Encrypt):
  → Χρησιμοποιούνται για ΔΗΜΟΣΙΑ sites (π.χ. www.company.com)
  → Οι browsers/OS τα εμπιστεύονται ΑΥΤΟΜΑΤΑ ("trusted by default")
  → Κοστίζουν (εκτός από Let's Encrypt) ή έχουν rate limits

Internal/Private CA (AD CS):
  → Χρησιμοποιείται για ΕΣΩΤΕΡΙΚΑ resources (intranet sites, WiFi, VPN)
  → Δωρεάν όσα certificates χρειάζεσαι
  → Οι browsers/OS ΔΕΝ τα εμπιστεύονται αυτόματα -
    χρειάζεται να "διδάξεις" στα domain-joined μηχανήματα να εμπιστεύονται
    το Root CA σου (γίνεται αυτόματα σε domain-joined μηχανήματα μέσω AD)
```

> 💡 Το κλειδί εδώ: επειδή τα domain-joined μηχανήματα εμπιστεύονται **αυτόματα** το internal Root CA (μέσω Group Policy, γίνεται από μόνο του όταν στήνεις AD CS integrated με AD), μπορείς να έχεις **πλήρες HTTPS/certificate-based authentication** σε όλο το εσωτερικό δίκτυο, χωρίς κανένα κόστος ανά certificate και χωρίς χειροκίνητο trust setup σε κάθε μηχάνημα.

---

## 🏗️ 2. Τύποι CA — Root vs Subordinate, Enterprise vs Standalone

### Root vs Subordinate (Issuing) CA

```
Root CA
  │  (Το "απόλυτο" σημείο εμπιστοσύνης - υπογράφει ΜΟΝΟ τα subordinate CA
  │   certificates, ΠΟΤΕ δεν εκδίδει certificates απευθείας σε users/computers -
  │   μένει OFFLINE τις περισσότερες φορές, βλέπε §10)
  │
  └── Subordinate/Issuing CA
        (Αυτός εκδίδει τα ΠΡΑΓΜΑΤΙΚΑ certificates σε users, computers, services -
         μένει online, integrated με το AD)
```

### Enterprise CA vs Standalone CA

| | Enterprise CA | Standalone CA |
|---|---|---|
| **AD Integration** | Πλήρης — διαβάζει/γράφει στο AD | Καμία |
| **Certificate Templates** | Ναι — GUI-based templates | Όχι — χειροκίνητο κάθε request |
| **Autoenrollment (§6)** | Ναι | Όχι |
| **Typical χρήση** | Issuing CA (online, εξυπηρετεί domain) | Root CA (offline, μέγιστη ασφάλεια) |

> 💡 Το πιο κοινό real-world pattern: **Standalone Root CA** (offline, μέγιστη ασφάλεια) + **Enterprise Subordinate/Issuing CA** (online, integrated, κάνει την πραγματική καθημερινή δουλειά). Αυτό λέγεται **Two-Tier PKI** — το πιο συχνό μοντέλο σε μεσαίες/μεγάλες εταιρείες.

---

## 🎫 3. Σενάριο — Το Ticket

> **Ticket #4720** — *"Θέλουμε να ρυθμίσουμε το εταιρικό WiFi ώστε οι υπάλληλοι να συνδέονται αυτόματα με τα domain credentials τους (χωρίς να πληκτρολογούν password κάθε φορά), και θέλουμε το internal HR portal (https://hr.company.local) να μην δείχνει προειδοποίηση 'μη έμπιστο certificate' στους browsers."*

Και τα δύο requirements λύνονται με **internal PKI**: το πρώτο με certificate-based 802.1X authentication (§7), το δεύτερο με internal web server certificate (§8) — και τα δύο χρειάζονται πρώτα ένα λειτουργικό CA.

---

## 🛠️ 4. Runbook: Εγκατάσταση Two-Tier PKI

### Βήμα 1: Root CA (σε ξεχωριστό, offline server/VM)

```powershell
# Σε server που ΔΕΝ θα είναι domain-joined (ή θα αποσυνδεθεί από δίκτυο μετά -
# βλέπε §10 για γιατί), εγκατάσταση Standalone Root CA

Install-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools

Install-AdcsCertificationAuthority `
    -CAType StandaloneRootCA `
    -CACommonName "Company-Root-CA" `
    -KeyLength 4096 `
    -HashAlgorithmName SHA256 `
    -ValidityPeriod Years `
    -ValidityPeriodUnits 20

# Export του Root CA certificate (χρειάζεται να διανεμηθεί στο Subordinate CA)
certutil -ca.cert C:\RootCACert\CompanyRootCA.crt
```

### Βήμα 2: Subordinate/Issuing CA (domain-joined, online server)

```powershell
Install-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools

Install-AdcsCertificationAuthority `
    -CAType EnterpriseSubordinateCA `
    -CACommonName "Company-Issuing-CA" `
    -KeyLength 2048 `
    -HashAlgorithmName SHA256

# Αυτό δημιουργεί ένα "certificate request" file - πρέπει να μεταφερθεί
# ΧΕΙΡΟΚΙΝΗΤΑ (π.χ. USB stick, ΟΧΙ δίκτυο - βλέπε §10) στο offline Root CA
# για να υπογραφεί, μετά επιστρέφει και εγκαθίσταται:

certutil -installcert C:\Temp\Company-Issuing-CA.crt
```

### Βήμα 3: Επαλήθευση Λειτουργίας

```powershell
# Έλεγχος υγείας CA service
Get-Service CertSvc

# Έλεγχος ότι το AD "βλέπει" το CA (Enterprise CA integration)
certutil -config "IssuingCA01\Company-Issuing-CA" -ping

# Λίστα εκδοθέντων certificates
certutil -view -restrict "Disposition=20"
```

> ⚠️ **Πολύ σημαντικό real-world detail:** Το Common Name (CN) του CA (π.χ. "Company-Root-CA") **δεν μπορεί να αλλάξει ποτέ** μετά την εγκατάσταση χωρίς πλήρες rebuild ολόκληρου του PKI. Σκέψου προσεκτικά το naming **πριν** τρέξεις το `Install-AdcsCertificationAuthority` — αυτό είναι decision που θα "κουβαλάς" για χρόνια.

---

## 📋 5. Certificate Templates

Τα templates καθορίζουν **τι είδους** certificates μπορεί να εκδώσει το CA, και **ποιος** μπορεί να τα ζητήσει.

```powershell
# Λίστα διαθέσιμων templates
Get-CertificateTemplate

# Δημιουργία custom template (πιο εύκολο μέσω GUI - certtmpl.msc)
# Certification Authority console → Certificate Templates → Manage
# → Δεξί κλικ σε υπάρχον template (π.χ. "User") → Duplicate Template
# → Προσάρμοσε: validity period, key usage, ποιος έχει "Enroll" permission

# Publishing ενός template στο CA (ώστε να είναι διαθέσιμο για issuing)
Add-CATemplate -Name "Company-WiFi-Auth"
```

| Built-in Template | Τυπική χρήση |
|---|---|
| **Computer** | Machine certificates — authentication μηχανημάτων |
| **User** | User certificates — email signing, authentication |
| **Web Server** | HTTPS certificates για internal sites |
| **Workstation Authentication** | Βάση για 802.1X device authentication |

> 💡 Στην πράξη, σχεδόν πάντα **duplicate** ένα built-in template και προσαρμόζεις (validity period, permissions) αντί να χρησιμοποιήσεις το built-in απευθείας — το πρωτότυπο built-in template δεν μπορεί να τροποποιηθεί πλήρως, και το duplicate σου δίνει πλήρη έλεγχο.

---

## ⚙️ 6. Autoenrollment μέσω GPO

Χωρίς autoenrollment, κάθε χρήστης/μηχάνημα θα χρειαζόταν **χειροκίνητο** certificate request — αδύνατο σε κλίμακα. Το autoenrollment κάνει τα πάντα αυτόματα, στο background.

```
1. Certificate Template → Security tab → πρόσθεσε το σωστό group
   (π.χ. "Domain Computers") με "Enroll" + "Autoenroll" permissions

2. Group Policy Management → νέο/υπάρχον GPO →
   Computer Configuration → Policies → Windows Settings → Security Settings
   → Public Key Policies → Certificate Services Client - Auto-Enrollment
   → Configuration Model: Enabled
   → ✅ Renew expired certificates
   → ✅ Update certificates that use certificate templates
```

```powershell
# Δημιουργία/link του GPO
New-GPO -Name "Certificate-Autoenrollment" | New-GPLink -Target "DC=company,DC=local"

# Force refresh σε test μηχάνημα για να δεις αν πήρε certificate
gpupdate /force
certutil -pulse   # force αμέσως το autoenrollment check, χωρίς αναμονή του κανονικού interval

# Επαλήθευση ότι το μηχάνημα πήρε certificate
Get-ChildItem Cert:\LocalMachine\My
```

> 💡 **Γιατί δουλεύει τόσο "αόρατα":** Μόλις γίνει enabled το autoenrollment GPO και δοθούν τα σωστά permissions στο template, **κάθε** domain-joined μηχάνημα/χρήστης που ταιριάζει στα κριτήρια παίρνει αυτόματα certificate, το renew-άρει αυτόματα πριν λήξει, χωρίς ΚΑΜΙΑ ενέργεια από τον χρήστη ή τον admin μετά το αρχικό setup.

---

## 📶 7. Real-World Use Case: 802.1X WiFi Authentication

Αυτό λύνει το πρώτο μέρος του ticket #4720 — "domain credentials, χωρίς password prompt κάθε φορά":

```
Παραδοσιακό WiFi (Pre-Shared Key):
  → Ένα password για ΟΛΟΥΣ, δύσκολο να το αλλάξεις όταν φεύγει υπάλληλος
  → Κανένας τρόπος να ξέρεις ΠΟΙΟΣ συνδέθηκε πραγματικά

802.1X με Certificate-Based Authentication:
  → Κάθε μηχάνημα/χρήστης έχει ΔΙΚΟ ΤΟΥ certificate (μέσω autoenrollment, §6)
  → Το certificate ΕΙΝΑΙ η απόδειξη ταυτότητας - καμία password δεν στέλνεται
  → Revocation (§9) ενός certificate = άμεση αποκοπή πρόσβασης, χωρίς να
    αλλάξεις "shared" password για όλους
```

**Βασική ροή setup:**

```
1. Certificate Template "Workstation Authentication" - autoenrollment ενεργό (§5-6)
2. NPS (Network Policy Server) role στον Windows server - λειτουργεί ως RADIUS server
3. Wireless Access Points/Controller ρυθμισμένα να χρησιμοποιούν το NPS ως RADIUS
4. GPO για wireless network profile settings (SSID, authentication method = EAP-TLS)
```

```powershell
# Εγκατάσταση NPS role
Install-WindowsFeature NPAS -IncludeManagementTools

# Registration του NPS server στο AD (χρειάζεται για να "βλέπει" τα computer/user certificates)
netsh nps add registeredserver

# Wireless network policy μέσω GPO
# Computer Configuration → Policies → Windows Settings → Security Settings
# → Wireless Network (IEEE 802.11) Policies → νέο policy
# → Security: WPA2-Enterprise, EAP-TLS (χρησιμοποιεί certificates, όχι password)
```

---

## 🌐 8. Real-World Use Case: Internal HTTPS (Web Server Certs)

Λύνει το δεύτερο μέρος του ticket — `https://hr.company.local` χωρίς browser warnings:

```powershell
# Βήμα 1: Certificate request από τον IIS/web server (μέσω IIS Manager, ή command line)
# Server Certificates → Create Domain Certificate

# Ή μέσω certreq (command-line, καλύτερο για automation/documentation)
# request.inf περιεχόμενο:
#   [NewRequest]
#   Subject = "CN=hr.company.local"
#   KeyLength = 2048
#   Exportable = TRUE
#   [RequestAttributes]
#   CertificateTemplate = WebServer

certreq -new request.inf request.csr
certreq -submit -config "IssuingCA01\Company-Issuing-CA" request.csr certnew.cer
certreq -accept certnew.cer

# Binding του certificate στο IIS site (μέσω GUI, ή:)
New-WebBinding -Name "HR-Portal" -Protocol https -Port 443
$cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -like "*hr.company.local*"}
$binding = Get-WebBinding -Name "HR-Portal" -Protocol https
$binding.AddSslCertificate($cert.Thumbprint, "My")
```

> 💡 **Γιατί δεν εμφανίζεται προειδοποίηση:** Επειδή το Root CA certificate (§4) διανέμεται **αυτόματα** σε όλα τα domain-joined μηχανήματα (μπαίνει στο "Trusted Root Certification Authorities" store κάθε μηχανήματος μέσω AD integration), κάθε certificate που εκδίδεται από αυτό το CA θεωρείται **αυτόματα trusted** από όλους τους domain-joined browsers/clients — καμία χειροκίνητη ενέργεια χρειάζεται ανά μηχάνημα.

---

## 🚫 9. Certificate Revocation — CRL & OCSP

Τι συμβαίνει όταν ένα certificate πρέπει να "ακυρωθεί" πριν τη φυσική του λήξη (π.χ. υπάλληλος έφυγε, μηχάνημα κλάπηκε, ή ένα private key εκτέθηκε);

| Μηχανισμός | Πώς δουλεύει |
|---|---|
| **CRL** (Certificate Revocation List) | Λίστα με ΟΛΑ τα ανακληθέντα certificates, δημοσιεύεται περιοδικά, οι clients την κατεβάζουν και ελέγχουν |
| **OCSP** (Online Certificate Status Protocol) | Real-time query — "είναι αυτό το συγκεκριμένο certificate ακόμα έγκυρο;" — πιο γρήγορο, πιο σύγχρονο |

```powershell
# Ανάκληση ενός certificate (π.χ. μηχάνημα κλάπηκε)
certutil -revoke <SerialNumber> 1   # 1 = "Key Compromise" reason code

# Δημοσίευση νέου CRL (χρειάζεται μετά από κάθε revocation, ή στο scheduled interval)
certutil -CRL

# Έλεγχος CRL publication interval (default: κάθε 1 εβδομάδα, configurable)
Get-CACrlDistributionPoint
```

> ⚠️ Αν ξεχάσεις να δημοσιεύσεις CRL μετά από ένα revocation, τα clients **δεν θα ξέρουν** ότι το certificate ανακλήθηκε μέχρι το επόμενο scheduled publish — σε κρίσιμα σενάρια (π.χ. κλεμμένο μηχάνημα), κάνε **χειροκίνητο** `certutil -CRL` αμέσως μετά το revocation, μην περιμένεις το schedule.

---

## 🔒 10. Root CA Security — Γιατί Μένει Offline

Αυτό είναι το πιο σημαντικό architectural decision σε ολόκληρο το PKI, και σίγουρη ερώτηση σε συνέντευξη:

```
Αν το Root CA compromised:
  → Ο επιτιθέμενος μπορεί να εκδώσει ΟΠΟΙΟΔΗΠΟΤΕ certificate, για ΟΠΟΙΟΝΔΗΠΟΤΕ,
    και θα είναι ΑΥΤΟΜΑΤΑ trusted από όλο το domain (§4, §8)
  → Μπορεί να "προσποιηθεί" οποιονδήποτε internal website, service, ή χρήστη
  → Η ΜΟΝΗ λύση είναι πλήρες rebuild ΟΛΟΥ του PKI - καταστροφικό, πολύμηνο έργο

Γι' αυτό:
  → Ο Root CA μένει OFFLINE (physically disconnected από δίκτυο) τις
    περισσότερες φορές - ενεργοποιείται ΜΟΝΟ για να υπογράψει το Subordinate
    CA certificate, ή να δημοσιεύσει νέο CRL (περιοδικά, π.χ. κάθε 6 μήνες)
  → Physical security (κλειδωμένο δωμάτιο/safe) εξίσου σημαντική με τεχνική
  → Το Subordinate/Issuing CA (§2, online) είναι αυτό που "εκτίθεται"
    καθημερινά - αν ΑΥΤΟ compromised, ο αντίκτυπος είναι μεγάλος αλλά
    περιορισμένος: revoke το subordinate CA certificate, re-issue από Root
```

> 💡 Αυτό είναι ακριβώς η ίδια λογική με το **Tiered Administration Model** από το [`ad-security-hardening.md`](./ad-security-hardening.md#-2-το-tiered-administration-model--η-βάση-όλης-της-άμυνας) — το πιο κρίσιμο, πιο ισχυρό component (Root CA / Tier 0 Domain Admin) μένει όσο το δυνατόν πιο απομονωμένο, ακριβώς επειδή ο αντίκτυπος compromise του είναι ο μεγαλύτερος δυνατός.

---

## 🔧 11. Troubleshooting

| Πρόβλημα | Πιθανή Αιτία | Λύση |
|---|---|---|
| Browser δείχνει "μη έμπιστο certificate" σε internal site | Root CA δεν έχει διανεμηθεί σε αυτό το μηχάνημα (π.χ. non-domain-joined) | Χειροκίνητο import του Root CA cert στο "Trusted Root" store |
| Autoenrollment δεν δουλεύει | GPO δεν έφτασε ακόμα, ή permissions λάθος στο template | `gpupdate /force`, `certutil -pulse`, έλεγξε template Security tab |
| "Access Denied" κατά το certificate request | Ο χρήστης/μηχάνημα δεν έχει "Enroll" permission στο template | Πρόσθεσε το σωστό group στο template permissions (§5) |
| Certificate εξέδωσε αλλά η εφαρμογή δεν το "βλέπει" | Certificate store λάθος (User vs Computer store) | Έλεγξε `Cert:\LocalMachine\My` vs `Cert:\CurrentUser\My` |
| CRL check αποτυγχάνει, service αργεί να απαντήσει | CRL Distribution Point unreachable (π.χ. firewall, ή CRL expired χωρίς republish) | Έλεγξε connectivity προς CDP URL, `certutil -CRL` |
| Subordinate CA δεν μπορεί να επικοινωνήσει με Root CA | Φυσιολογικό - ο Root CA είναι OFFLINE by design (§10) | Χρειάζεται χειροκίνητη μεταφορά (USB) για signing operations |

```powershell
# Γενικός έλεγχος υγείας PKI
certutil -verify -urlfetch <certificate-file>

# Έλεγχος chain of trust ενός certificate
certutil -verifystore -v My

# PKI health monitoring (built-in tool)
PKIView.msc   # δείχνει status όλων των CAs, CRL freshness, κ.λπ.
```

---

## ✅ 12. Checklist — PKI Deployment

```
☐ Two-Tier αρχιτεκτονική (Offline Root + Online Subordinate) για production
☐ Root CA CN καθορίστηκε προσεκτικά - δεν αλλάζει ποτέ μετά
☐ Root CA key length 4096-bit, validity 15-20 χρόνια
☐ Root CA physically secured, offline μετά το initial setup
☐ Subordinate CA integrated με AD (Enterprise CA)
☐ Certificate templates φτιαγμένα ως duplicates (όχι τροποποίηση built-in)
☐ Permissions στα templates σωστά (ποιος μπορεί να κάνει Enroll/Autoenroll)
☐ Autoenrollment GPO ενεργό και testαρισμένο
☐ CRL Distribution Points προσβάσιμα από όλα τα clients
☐ CRL publish schedule κατάλληλο (όχι πολύ σπάνιο)
☐ Documentation - CA hierarchy diagram, template list, ποιος χρησιμοποιεί τι certificate για τι
☐ Backup του CA database + private key (ΚΡΙΣΙΜΟ - χωρίς αυτό, χάνεις ΟΛΗ την υποδομή PKI αν χαθεί ο server)
```

```powershell
# Backup CA (κρίσιμο - ξεχωριστό από κανονικό server backup)
certutil -backup C:\CA-Backup
```

---

## 📚 Σχετικά αρχεία

- [`active-directory.md`](./active-directory.md) — Users/Groups, OUs, GPO βασικά
- [`active-directory-advanced.md`](./active-directory-advanced.md) — FSMO, Replication, Security Tiering
- [`ad-security-hardening.md`](./ad-security-hardening.md) — Tiered Administration Model — ίδια λογική με το Root CA isolation
- [`group-policy-deep-dive.md`](./group-policy-deep-dive.md) — GPO deployment για autoenrollment/wireless policies
- [`kerberos-deep-dive.md`](./kerberos-deep-dive.md) — Άλλο authentication protocol, συμπληρωματικό με certificate-based auth
- Αυτό το αρχείο (`ad-certificate-services-pki.md`) — Two-Tier PKI setup, templates, autoenrollment, 802.1X, HTTPS
