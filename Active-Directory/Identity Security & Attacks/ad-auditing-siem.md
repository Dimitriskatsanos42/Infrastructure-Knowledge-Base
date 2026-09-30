# 🕵️ AD Auditing & SIEM Integration — Deep Dive & Real-World Runbook
> Συνοδευτικό αρχείο στη σειρά Active Directory. Τα προηγούμενα αρχεία έδειξαν πώς στήνεις και προστατεύεις AD — αυτό δείχνει πώς **βλέπεις τι πραγματικά συμβαίνει** μέσα του, κάτι κρίσιμο για compliance, incident response, και για να εντοπίσεις τα attacks που περιγράψαμε στο [`ad-security-hardening.md`](./ad-security-hardening.md) **πριν** γίνουν καταστροφή.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Γιατί Auditing Δεν Είναι Προαιρετικό](#-1-γιατί-auditing-δεν-είναι-προαιρετικό)
2. [Advanced Audit Policy — Θεωρία](#-2-advanced-audit-policy--θεωρία)
3. [Σενάριο — Το Ticket](#-3-σενάριο--το-ticket)
4. [Runbook: Ενεργοποίηση Advanced Audit Policy](#-4-runbook-ενεργοποίηση-advanced-audit-policy)
5. [Object-Level Auditing (SACL) σε AD Objects](#-5-object-level-auditing-sacl-σε-ad-objects)
6. [Τα Event IDs που Πραγματικά Έχουν Σημασία](#-6-τα-event-ids-που-πραγματικά-έχουν-σημασία)
7. [Log Forwarding — Από DCs σε Κεντρικό Σημείο](#-7-log-forwarding--από-dcs-σε-κεντρικό-σημείο)
8. [SIEM Integration](#-8-siem-integration)
9. [Detection Rules — Παραδείγματα](#-9-detection-rules--παραδείγματα)
10. [Log Retention & Compliance](#-10-log-retention--compliance)
11. [Troubleshooting](#-11-troubleshooting)
12. [Checklist — Auditing Baseline](#-12-checklist--auditing-baseline)

---

## 🤔 1. Γιατί Auditing Δεν Είναι Προαιρετικό

```
Χωρίς σωστό auditing:

Incident συμβαίνει → Κανείς δεν το προσέχει για ΜΕΡΕΣ/ΕΒΔΟΜΑΔΕΣ →
Όταν τελικά το ανακαλύπτεις, ΔΕΝ έχεις logs να καταλάβεις τι έγινε,
πότε ξεκίνησε, ή ΠΟΣΗ ζημιά έγινε → Investigation γίνεται μαντεψιά

Με σωστό auditing + monitoring:

Ύποπτη ενέργεια συμβαίνει → Alert μέσα σε λεπτά →
Investigation με ΠΛΗΡΗ audit trail (ποιος, τι, πότε, από πού) →
Γρήγορη containment, μικρότερος αντίκτυπος
```

> 💡 Πέρα από το security value, το AD auditing είναι συχνά **compliance requirement** — GDPR, ISO 27001, PCI-DSS, και άλλα frameworks απαιτούν ρητά την ικανότητα να αποδείξεις **ποιος είχε πρόσβαση σε τι, πότε**. Χωρίς αυτό, μια εταιρεία μπορεί να αποτύχει σε audit ακόμα κι αν τεχνικά δεν έχει συμβεί κανένα πραγματικό incident.

---

## 📖 2. Advanced Audit Policy — Θεωρία

Windows Server έχει δύο "γενιές" audit policy: την παλιά **Basic Audit Policy** (9 γενικές κατηγορίες) και την σύγχρονη **Advanced Audit Policy** (πάνω από 50 πολύ πιο συγκεκριμένες υποκατηγορίες). Στην πράξη, **πάντα** χρησιμοποιείς την Advanced — η Basic θεωρείται deprecated.

```
Advanced Audit Policy Categories (οι πιο σχετικές με AD):

Account Logon          → Kerberos authentication events (4768, 4769, 4771...)
Account Management     → Δημιουργία/διαγραφή/αλλαγή users, groups (4720, 4726, 4732...)
DS Access              → Πρόσβαση/αλλαγές σε AD objects (4662, 5136...)
Logon/Logoff           → Interactive/network logons (4624, 4625, 4634...)
Object Access           → Πρόσβαση σε files, registry (χρειάζεται ΚΑΙ SACL - §5)
Policy Change           → Αλλαγές σε GPO, audit policy, trust relationships (4719, 4739...)
Privilege Use           → Χρήση sensitive privileges (4672, 4673...)
```

> ⚠️ **Σημαντικό detail:** Advanced Audit Policy μπορεί να ρυθμιστεί μέσω GPO, αλλά αν συνυπάρχει με Basic Audit Policy στο ίδιο σύστημα, μπορεί να προκύψουν **conflicts** (η Basic "νικάει" σε ασυνέπειες). Πάντα ενεργοποίησε το GPO setting "Audit: Force audit policy subcategory settings to override audit policy category settings" ώστε να είσαι σίγουρος ότι μόνο η Advanced policy ισχύει.

---

## 🎫 3. Σενάριο — Το Ticket

> **Ticket #SEC-2245** — *"Μετά το προηγούμενο security audit, το compliance team ζητάει: (1) Πλήρη ικανότητα να απαντήσουμε 'ποιος πρόσβασε/άλλαξε αυτό το ευαίσθητο αρχείο/object' για τουλάχιστον 1 χρόνο πίσω. (2) Real-time alert αν κάποιος προστεθεί στο Domain Admins group. (3) Logs να είναι διαθέσιμα ΚΑΙ αν χαθεί/παραβιαστεί ένας DC."*

Τρία requirements → object-level auditing (§5) + real-time alerting (§9) + centralized log forwarding (§7), ώστε τα logs να επιζούν ακόμα κι αν ο πηγαίος DC χαθεί.

---

## 🛠️ 4. Runbook: Ενεργοποίηση Advanced Audit Policy

```powershell
# Μέσω GPO (σωστός τρόπος - εφαρμόζεται σε ΟΛΑ τα DCs κεντρικά)
# Δημιουργία νέου GPO, linked στο "Domain Controllers" OU

New-GPO -Name "DC-Advanced-Audit-Policy" -Comment "Ticket #SEC-2245"
New-GPLink -Name "DC-Advanced-Audit-Policy" -Target "OU=Domain Controllers,DC=company,DC=local"
```

```
Edit το GPO →
Computer Configuration → Policies → Windows Settings → Security Settings
→ Advanced Audit Policy Configuration → Audit Policies

Ρύθμισε (Success + Failure όπου εφαρμόζεται):

Account Logon:
  ✅ Audit Kerberos Authentication Service    (Success, Failure)
  ✅ Audit Kerberos Service Ticket Operations (Success, Failure)

Account Management:
  ✅ Audit User Account Management     (Success, Failure)
  ✅ Audit Security Group Management   (Success, Failure)  ← κρίσιμο για το ticket §requirement 2

DS Access:
  ✅ Audit Directory Service Access    (Success, Failure)
  ✅ Audit Directory Service Changes   (Success, Failure)  ← κρίσιμο για "ποιος άλλαξε τι"

Logon/Logoff:
  ✅ Audit Logon           (Success, Failure)
  ✅ Audit Logoff          (Success)
  ✅ Audit Special Logon   (Success, Failure)

Policy Change:
  ✅ Audit Authentication Policy Change  (Success, Failure)
  ✅ Audit Audit Policy Change           (Success, Failure)

Privilege Use:
  ✅ Audit Sensitive Privilege Use  (Success, Failure)
```

```powershell
# Επαλήθευση σε συγκεκριμένο DC μετά από gpupdate
auditpol /get /category:*
```

> ⚠️ **Πρόσεχε το "Failure" auditing σε high-volume categories** (π.χ. Logon/Logoff σε πολυάσχολο περιβάλλον) — μπορεί να δημιουργήσει τεράστιο όγκο logs. Στόχευσε auditing βάσει πραγματικής ανάγκης, όχι "ενεργοποίησε τα πάντα σε όλα" — αυτό κάνει τα logs άχρηστα λόγω όγκου (πολύ "θόρυβος", δύσκολο να βρεις το σημαντικό sinal).

---

## 🎯 5. Object-Level Auditing (SACL) σε AD Objects

Το "Audit Directory Service Changes" (§4) ενεργοποιεί τον **μηχανισμό**, αλλά χρειάζεσαι επίσης να ορίσεις **SACL** (System Access Control List — ίδια λογική με [`file-permissions-ntfs.md`](./file-permissions-ntfs.md#-7-acl-internals--dacl-sacl-ace)) πάνω σε **συγκεκριμένα** objects/OUs για να πάρεις granular auditing.

```
Πρακτικό παράδειγμα: Το ticket ζητάει alert όταν κάποιος προστεθεί στο
"Domain Admins" - χρειάζεται SACL πάνω σε αυτό το ΣΥΓΚΕΚΡΙΜΕΝΟ group.

GUI βήματα (Active Directory Users and Computers, με Advanced Features ενεργό):

1. Δεξί κλικ στο "Domain Admins" group → Properties → Security tab → Advanced
2. Auditing tab → Add
3. Principal: Everyone (θέλεις να καταγράφεις ΟΠΟΙΟΝΔΗΠΟΤΕ κάνει την αλλαγή)
4. Type: Success
5. Applies to: This object only
6. Permissions: ✅ Write members (καταγράφει ΠΡΟΣΘΗΚΗ/ΑΦΑΙΡΕΣΗ μελών)
```

```powershell
# Το ίδιο μέσω PowerShell (πιο scriptable, καλύτερο για documentation/repeat)
$group = Get-ADGroup "Domain Admins"
$acl = Get-Acl "AD:\$($group.DistinguishedName)"

$auditRule = New-Object System.DirectoryServices.ActiveDirectoryAuditRule(
    (New-Object System.Security.Principal.NTAccount("Everyone")),
    [System.DirectoryServices.ActiveDirectoryRights]::WriteProperty,
    [System.Security.AccessControl.AuditFlags]::Success
)
$acl.AddAuditRule($auditRule)
Set-Acl "AD:\$($group.DistinguishedName)" $acl
```

**Άλλα σημαντικά σημεία για SACL auditing:**

| Object/OU | Γιατί το παρακολουθείς |
|---|---|
| **Domain Admins, Enterprise Admins groups** | Membership changes = πιθανή privilege escalation |
| **AdminSDHolder object** | Αλλαγές εδώ επηρεάζουν ΟΛΑ τα privileged accounts (βλέπε `ad-security-hardening.md` §10) |
| **GPOs που αφορούν security settings** | Ανίχνευση αν κάποιος "χαλαρώσει" security policy |
| **Sensitive OUs** (π.χ. Finance, HR) | Αλλαγές σε group membership/permissions εκεί |
| **krbtgt account** | Οποιαδήποτε αλλαγή είναι εξαιρετικά ύποπτη (βλέπε Golden Ticket, `ad-security-hardening.md` §6) |

---

## 🔢 6. Τα Event IDs που Πραγματικά Έχουν Σημασία

| Event ID | Τι σημαίνει | Γιατί το παρακολουθείς |
|---|---|---|
| **4624** | Επιτυχές logon | Baseline activity, filtered για privileged accounts |
| **4625** | Αποτυγχημένο logon | Brute-force detection |
| **4634/4647** | Logoff | Πλήρης session tracking |
| **4672** | Λογαριασμός με special privileges έκανε login | Επιβεβαίωση admin activity |
| **4720** | Νέος user account δημιουργήθηκε | Unauthorized account creation |
| **4726** | User account διαγράφηκε | Audit trail |
| **4728/4732/4756** | Μέλος προστέθηκε σε privileged group (Domain Admins κ.λπ.) | **Κρίσιμο** — requirement #2 του ticket |
| **4756** | Μέλος προστέθηκε σε universal group | Παρόμοιο με 4728, αναλόγως group scope |
| **4738** | User account τροποποιήθηκε | Ανίχνευση αλλαγών σε privileges/attributes |
| **4767** | Λογαριασμός ξεκλειδώθηκε | Ασυνήθιστο pattern αν συχνό |
| **4768** | Kerberos TGT requested | Kerberoasting detection (βλέπε `kerberos-deep-dive.md` §12) |
| **4769** | Kerberos service ticket requested | Kerberoasting detection |
| **4771** | Kerberos preauth απέτυχε | Πιθανό password guessing |
| **4670** | Permissions άλλαξαν σε object | AdminSDHolder tampering detection |
| **5136** | AD object τροποποιήθηκε | Γενικό, ευρύ change tracking |
| **5137** | AD object δημιουργήθηκε | Νέα objects σε sensitive OUs |
| **5141** | AD object διαγράφηκε | Accidental/malicious deletion tracking |
| **4719** | Audit policy άλλαξε | **Κρίσιμο** — κάποιος προσπαθεί να "τυφλώσει" το logging |

> ⚠️ **Event 4719 είναι ιδιαίτερα κρίσιμο:** Αν κάποιος (επιτιθέμενος ή κακόβουλος insider) προσπαθεί να απενεργοποιήσει το audit logging πριν κάνει κάτι κακόβουλο, αυτό ΘΑ δημιουργήσει ένα 4719 event πρώτα — γι' αυτό συχνά αυτό το event ρυθμίζεται με **υψηλότερη προτεραιότητα alert** από σχεδόν οτιδήποτε άλλο.

---

## 📡 7. Log Forwarding — Από DCs σε Κεντρικό Σημείο

Λύνει το τρίτο requirement του ticket: **"logs διαθέσιμα ακόμα κι αν χαθεί ο DC."** Αν τα logs μένουν ΜΟΝΟ τοπικά στον DC, ένας επιτιθέμενος που καταλαμβάνει τον DC μπορεί απλά να τα διαγράψει (καλύπτοντας τα ίχνη του).

### Windows Event Forwarding (WEF) — Built-in Λύση

```powershell
# Βήμα 1: Στον collector server (κεντρικό σημείο συλλογής)
wecutil qc /q

# Βήμα 2: Στους DCs (sources) - ενεργοποίηση WinRM (χρειάζεται για forwarding)
winrm quickconfig -q

# Βήμα 3: Δημιουργία subscription στον collector - ποια events θέλεις να συλλέγεις
# Μέσω Event Viewer GUI: Subscriptions → Create Subscription
# → Source Computers: όλοι οι DCs
# → Events to collect: τα Event IDs του §6

# Ή μέσω XML subscription file για πιο scriptable/repeatable setup:
wecutil cs subscription-config.xml
```

```
Πλεονέκτημα του WEF: Native, δωρεάν, ενσωματωμένο στα Windows -
δεν χρειάζεται επιπλέον software.

Μειονέκτημα: Πιο "βασικό" από enterprise SIEM λύσεις - καλό ως πρώτο
επίπεδο/backup, αλλά τα περισσότερα enterprise setups χρησιμοποιούν
KAI κάτι πιο ισχυρό (§8) πάνω από αυτό.
```

### Εναλλακτικά: Syslog/Agent-Based Forwarding

Πολλά SIEM (Splunk, Sentinel, κ.λπ.) χρησιμοποιούν δικό τους **agent** (π.χ. Splunk Universal Forwarder, Azure Monitor Agent) εγκατεστημένο σε κάθε DC, που στέλνει τα logs απευθείας στο SIEM σε real-time — πιο σύγχρονη, πιο ευέλικτη προσέγγιση από το native WEF.

---

## 🔗 8. SIEM Integration

```powershell
# Παράδειγμα: Azure Monitor Agent (AMA) για forwarding σε Microsoft Sentinel
# (Εγκατάσταση μέσω Azure Arc αν οι DCs δεν είναι ήδη Azure VMs)

# Data Collection Rule (DCR) καθορίζει ΠΟΙΑ logs στέλνονται
# - Ρυθμίζεται μέσω Azure Portal ή ARM template, όχι απλό PowerShell one-liner

# Γενική αρχή ανεξαρτήτως SIEM vendor:
# 1. Agent/forwarder εγκατεστημένος σε κάθε DC
# 2. Configuration - ποια Event Logs/Event IDs να στέλνει (Security log, System log)
# 3. SIEM λαμβάνει, παρσάρει (parsing), κανονικοποιεί (normalization) τα events
# 4. Detection rules (§9) τρέχουν πάνω στα κανονικοποιημένα δεδομένα
```

| SIEM | Native AD Integration |
|---|---|
| **Microsoft Sentinel** | Πολύ φυσικό fit (ίδιο ecosystem), built-in AD/Azure AD connectors |
| **Splunk** | Universal Forwarder + Splunk App for Windows Infrastructure |
| **Elastic (ELK)** | Winlogbeat agent, built-in AD dashboards |
| **QRadar/ArcSight** | Enterprise-grade, πιο σύνθετο setup, συνήθως μεγάλες εταιρείες |

> 💡 **Real-world tip:** Το να **στέλνεις** logs σε SIEM είναι μόνο το μισό της δουλειάς — το άλλο μισό (και το πιο σημαντικό) είναι να έχεις **σωστά detection rules** πάνω σε αυτά τα δεδομένα (§9). Πολλές εταιρείες πληρώνουν για SIEM, στέλνουν logs, αλλά ποτέ δεν φτιάχνουν σωστά alerts — άρα έχουν απλά ένα ακριβό "log dump" χωρίς πραγματική ανιχνευτική αξία.

---

## 🚨 9. Detection Rules — Παραδείγματα

Έτσι μοιάζουν πραγματικά detection rules (λογική, όχι syntax συγκεκριμένου SIEM — η ίδια λογική εφαρμόζεται σε Splunk SPL, Sentinel KQL, κ.λπ.):

```
Rule #1: Προσθήκη σε Privileged Group (λύνει requirement #2 του ticket)
  Trigger: Event ID 4728 OR 4732 OR 4756
  WHERE target group IN ("Domain Admins", "Enterprise Admins", "Schema Admins")
  Action: ΑΜΕΣΟ high-priority alert στο security team

Rule #2: Πιθανό Kerberoasting
  Trigger: Event ID 4769
  WHERE ίδιος requesting user ζήτησε 10+ ΔΙΑΦΟΡΕΤΙΚΑ service tickets
  ΜΕΣΑ σε 5 λεπτά
  Action: Medium-priority alert, investigation

Rule #3: Audit Policy Tampering
  Trigger: Event ID 4719
  Action: ΑΜΕΣΟ critical alert (βλέπε §6 - πιθανό "κάλυμμα ιχνών")

Rule #4: Massive Failed Logons (Brute Force)
  Trigger: Event ID 4625
  WHERE 20+ αποτυχίες από ΤΗΝ ΙΔΙΑ πηγή IP ΜΕΣΑ σε 10 λεπτά
  Action: Alert + πιθανό automated IP block (αν το infrastructure το υποστηρίζει)

Rule #5: Off-Hours Privileged Access
  Trigger: Event ID 4672
  WHERE ώρα εκτός 07:00-19:00 ΚΑΙ δεν είναι scheduled maintenance window
  Action: Medium-priority alert (πιθανό compromised admin account ή insider)

Rule #6: Break-Glass Account Χρήση (βλέπε ad-security-hardening.md §11)
  Trigger: Event ID 4624
  WHERE username = "svc-breakglass01" (ή όποιο είναι το break-glass account)
  Action: ΑΜΕΣΟ critical alert - αυτό ΔΕΝ θα έπρεπε ΠΟΤΕ να συμβαίνει εκτός emergency
```

> 💡 Ξεκίνα με **λίγα, σωστά** detection rules (τα παραπάνω 6 είναι εξαιρετικό baseline) αντί να προσπαθήσεις να φτιάξεις 50 rules αμέσως — τα false-positive-heavy rules "κουράζουν" την ομάδα (alert fatigue) και τελικά αγνοούνται, ό,τι κι αν λένε.

---

## 📅 10. Log Retention & Compliance

```powershell
# Default Windows Security log size είναι ΠΟΛΥ μικρό για compliance needs
# (μπορεί να "γεμίσει" και να αρχίσει να διαγράφει παλιά events μέσα σε μέρες
# σε πολυάσχολο DC)

# Αύξηση μεγέθους (τοπικό log - ΠΑΝΤΑ σε συνδυασμό με forwarding §7,
# όχι ως μοναδική λύση)
wevtutil sl Security /ms:4294967296   # 4GB, παράδειγμα

# Retention policy - "Do not overwrite events" αν χρειάζεσαι εγγύηση
# ότι ΤΙΠΟΤΑ δεν χάνεται πριν το forwarding το "τραβήξει"
wevtutil sl Security /rt:false
```

| Compliance Framework | Τυπικό retention requirement |
|---|---|
| **GDPR** | Δεν ορίζει συγκεκριμένο αριθμό, αλλά "όσο χρειάζεται για τον σκοπό" — συνήθως 1+ χρόνο για security logs |
| **PCI-DSS** | Τουλάχιστον 1 χρόνο, με τους τελευταίους 3 μήνες άμεσα διαθέσιμους (όχι μόνο σε archive) |
| **ISO 27001** | Καθορίζεται από την ίδια την εταιρεία στο δικό της Information Security Policy, αλλά συνήθως 1+ χρόνο |

> ⚠️ Το requirement του ticket ("1 χρόνο πίσω") σημαίνει ότι **το τοπικό DC log δεν αρκεί ποτέ** — χρειάζεσαι σίγουρα forwarding (§7) σε ένα σύστημα (SIEM/log archive) που μπορεί να κρατήσει αυτόν τον όγκο δεδομένων για τόσο διάστημα, με κατάλληλο compression/archiving strategy.

---

## 🔧 11. Troubleshooting

| Πρόβλημα | Πιθανή Αιτία | Λύση |
|---|---|---|
| Δεν βλέπεις καθόλου τα αναμενόμενα events | Advanced Audit Policy δεν ενεργό, ή Basic Policy "νικάει" (§2) | Έλεγξε GPO setting "Force audit policy subcategory..." |
| SACL auditing δεν "πιάνει" τις αλλαγές | Λάθος permission type στο SACL (π.χ. Read αντί για Write) | Έλεγξε §5, βεβαιώσου Write/WriteProperty επιλεγμένο |
| Log forwarding δεν δουλεύει | WinRM δεν ρυθμισμένο σωστά, ή firewall μπλοκάρει | `winrm quickconfig`, έλεγξε firewall rules (port 5985/5986) |
| Security log γεμίζει πολύ γρήγορα | Πολύ ευρύ auditing (π.χ. Failure σε high-volume category) | Στόχευσε auditing πιο συγκεκριμένα, αύξησε log size (§10) |
| SIEM δεν λαμβάνει logs | Agent down, ή network connectivity issue προς SIEM endpoint | Έλεγξε agent service status, connectivity test |
| Πάρα πολλά false-positive alerts | Detection rules πολύ "χαλαρά" ρυθμισμένα | Fine-tune thresholds (§9), baseline "κανονικής" δραστηριότητας πρώτα |

```powershell
# Γρήγορος έλεγχος τρέχουσας audit policy
auditpol /get /category:*

# Test - δημιούργησε ένα test event και επιβεβαίωσε ότι καταγράφηκε
Add-ADGroupMember -Identity "Domain Admins" -Members "test-user-TEMP"
Get-WinEvent -LogName Security -MaxEvents 5 | Where-Object {$_.Id -eq 4728}
Remove-ADGroupMember -Identity "Domain Admins" -Members "test-user-TEMP" -Confirm:$false
```

---

## ✅ 12. Checklist — Auditing Baseline

```
☐ Advanced Audit Policy ενεργό σε ΟΛΟΥΣ τους DCs μέσω GPO
☐ "Force audit policy subcategory..." setting ενεργό (αποφυγή Basic/Advanced conflicts)
☐ SACL ρυθμισμένο σε privileged groups (Domain Admins, Enterprise Admins, κ.λπ.)
☐ SACL ρυθμισμένο σε άλλα sensitive objects (AdminSDHolder, krbtgt, sensitive OUs)
☐ Log forwarding ενεργό (WEF ή agent-based) - logs ΔΕΝ μένουν μόνο τοπικά στον DC
☐ SIEM integration ολοκληρωμένη, logs φτάνουν και παρσάρονται σωστά
☐ Τουλάχιστον τα 6 βασικά detection rules του §9 υπάρχουν και είναι tested
☐ Retention policy καλύπτει compliance requirements (τυπικά 1+ χρόνο)
☐ Alert fatigue έλεγχος - τα rules δεν παράγουν υπερβολικά false positives
☐ Documentation - ποια events παρακολουθούνται, γιατί, ποιο compliance requirement καλύπτουν
☐ Break-glass account (αν υπάρχει) έχει ΞΕΧΩΡΙΣΤΟ, critical-priority alert
```

---

## 📚 Σχετικά αρχεία

- [`active-directory.md`](./active-directory.md) — Users/Groups, OUs, GPO βασικά
- [`active-directory-advanced.md`](./active-directory-advanced.md) — FSMO, Replication, Security Tiering
- [`ad-security-hardening.md`](./ad-security-hardening.md) — Τα attacks που αυτό το auditing σκοπεύει να ανιχνεύσει
- [`kerberos-deep-dive.md`](./kerberos-deep-dive.md) — Event IDs 4768/4769 σε πλαίσιο Kerberoasting
- [`file-permissions-ntfs.md`](./file-permissions-ntfs.md) — Ίδια SACL/DACL λογική σε NTFS επίπεδο
- [`backup-disaster-recovery.md`](./backup-disaster-recovery.md) — Τι κάνεις ΜΕΤΑ από ό,τι ανιχνεύσεις εδώ
- Αυτό το αρχείο (`ad-auditing-siem.md`) — Advanced Audit Policy, SACL, log forwarding, SIEM, detection rules
