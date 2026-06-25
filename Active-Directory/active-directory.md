# 🏢 Active Directory & Microsoft Entra ID

> Κεντρική διαχείριση χρηστών, υπολογιστών και πολιτικών σε Windows περιβάλλον — από τα πιο ζητούμενα skills στην Ελληνική αγορά εργασίας.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Τι είναι το Active Directory;](#-1-τι-είναι-το-active-directory)
2. [Βασικές Έννοιες](#-2-βασικές-έννοιες)
3. [Διαχείριση Users & Groups](#-3-διαχείριση-users--groups)
4. [Organizational Units (OUs)](#-4-organizational-units-ous)
5. [Group Policy Objects (GPO)](#-5-group-policy-objects-gpo)
6. [Microsoft Entra ID (Azure AD)](#️-6-microsoft-entra-id-azure-ad)
7. [On-Prem vs Entra ID — Σύγκριση](#-7-on-prem-vs-entra-id--σύγκριση)
8. [PowerShell για AD](#-8-powershell-για-ad)
9. [Troubleshooting](#-9-troubleshooting)

---

## 📌 1. Τι είναι το Active Directory;

Το **Active Directory Domain Services (AD DS)** είναι η υπηρεσία καταλόγου της Microsoft — ο κεντρικός "πυρήνας" ελέγχου σε κάθε Windows εταιρικό περιβάλλον.

**Γιατί είναι κρίσιμο:**

- **Single Sign-On** — ένας λογαριασμός, πρόσβαση σε όλα
- **Centralized management** — χιλιάδες υπολογιστές, μία πολιτική
- **Security** — έλεγχος ποιος έχει πρόσβαση σε τι
- **Auditing** — καταγραφή όλης της δραστηριότητας

```
Χρήστης → Συνδέεται → Domain Controller → Επαληθεύει credentials (Kerberos)
                                         → Εφαρμόζει GPO
                                         → Δίνει πρόσβαση σε πόρους
```

---

## 🧩 2. Βασικές Έννοιες

| Όρος | Εξήγηση |
|------|---------|
| **Domain** | Η βασική διοικητική ομάδα (π.χ. `company.local`) |
| **Domain Controller (DC)** | Ο server που τρέχει το AD — το κέντρο του συστήματος |
| **Forest** | Μία ή περισσότερες domains με κοινό schema |
| **Tree** | Domains με ιεραρχική σχέση στο ίδιο forest |
| **OU** | Organizational Unit — εικονικός φάκελος οργάνωσης |
| **LDAP** | Πρωτόκολλο επικοινωνίας με τον κατάλογο |
| **Kerberos** | Πρωτόκολλο authentication που χρησιμοποιεί το AD |
| **SYSVOL** | Shared folder με GPO files — αντιγράφεται σε όλους τους DCs |
| **FSMO Roles** | 5 ειδικοί ρόλοι που κατέχει κάποιος DC |

### Δομή Παραδείγματος

```
company.local  (Forest/Domain)
├── OU: Departments
│   ├── OU: IT
│   │   ├── 👤 dimitris.k (IT Admin)
│   │   └── 👤 maria.p (IT Support)
│   ├── OU: HR
│   └── OU: Finance
├── OU: Computers
│   ├── OU: Workstations
│   └── OU: Servers
└── OU: Service Accounts
    └── 👤 svc.backup
```

---

## 👥 3. Διαχείριση Users & Groups

### Τύποι Groups

| Τύπος | Scope | Χρήση |
|-------|-------|-------|
| **Security Group** | Χρήση για permissions και policies | IT-Admins, HR-Users |
| **Distribution Group** | Μόνο για email lists | company-all@company.com |

| Scope | Τι σημαίνει |
|-------|-------------|
| **Domain Local** | Πόροι μόνο σε αυτό το domain |
| **Global** | Μέλη μόνο από αυτό το domain, πόροι παντού |
| **Universal** | Μέλη και πόροι από παντού στο forest |

### Βέλτιστη Πρακτική — AGDLP

```
Accounts → Global Groups → Domain Local Groups → Permissions

Παράδειγμα:
- User dimitris.k  →  "IT-Admins" (Global)  →  "FileServer-Admins" (Domain Local)  →  Full Control στον file server
```

### GUI — Active Directory Users and Computers (ADUC)

```
Άνοιγμα: dsa.msc  ή  Server Manager → Tools → ADUC
```

**Δημιουργία User:**
1. Δεξί κλικ στο OU → New → User
2. First Name, Last Name, User Logon Name (π.χ. `d.katsanos`)
3. Κωδικός + τσεκάρισμα "User must change password at next logon"

**Reset κωδικού:**
- Δεξί κλικ στο user → Reset Password

**Disable/Unlock λογαριασμού:**
- Δεξί κλικ → Disable Account / Enable Account
- Για unlock: Properties → Account tab → Unlock account

---

## 📁 4. Organizational Units (OUs)

Οι OUs χρησιμεύουν για:
- **Οργάνωση** — λογική ομαδοποίηση αντικειμένων
- **Delegation** — ανάθεση διαχείρισης σε non-admins
- **GPO** — εφαρμογή διαφορετικών πολιτικών ανά τμήμα

```powershell
# Δημιουργία OU structure με PowerShell
New-ADOrganizationalUnit -Name "IT" -Path "OU=Departments,DC=company,DC=local"
New-ADOrganizationalUnit -Name "HR" -Path "OU=Departments,DC=company,DC=local"

# Μετακίνηση object σε άλλο OU
Move-ADObject -Identity "CN=dimitris.k,OU=HR,DC=company,DC=local" `
              -TargetPath "OU=IT,OU=Departments,DC=company,DC=local"
```

---

## 📋 5. Group Policy Objects (GPO)

### Εργαλείο: Group Policy Management Console

```
Άνοιγμα: gpmc.msc
```

### Σειρά Εφαρμογής — LSDOU

```
1. Local Policy          (ο υπολογιστής)
2. Site Policy           (physical location)
3. Domain Policy         (ολόκληρο το domain)
4. OU Policy             (συγκεκριμένο OU — κερδίζει!)
```

> **Θυμήσου:** Το πιο "κοντινό" GPO κερδίζει. Μπορείς να κάνεις Enforce ένα GPO ώστε να μην παρακαμφθεί.

### Χρήσιμα GPO Παραδείγματα

| Σενάριο | Διαδρομή στο GPO |
|---------|-----------------|
| Minimum password length | `Computer → Windows Settings → Security Settings → Account Policies` |
| Απενεργοποίηση USB | `Computer → Admin Templates → System → Removable Storage Access` |
| Desktop wallpaper | `User → Admin Templates → Desktop → Desktop Wallpaper` |
| Απενεργοποίηση CMD | `User → Admin Templates → System → Prevent access to the command prompt` |
| Map network drives | `User → Windows Settings → Drive Maps` |
| Εγκατάσταση software | `Computer → Software Settings → Software Installation` |

### Troubleshooting GPO

```powershell
# Εφαρμογή GPO αμέσως
gpupdate /force

# Αναφορά εφαρμοσμένων GPOs
gpresult /r               # Summary στο τερματικό
gpresult /h C:\gpreport.html /f   # HTML αναφορά

# Έλεγχος replication
repadmin /replsummary
```

> 🔬 **Lab:** Δημιούργησε GPO που ορίζει minimum password 12 χαρακτήρες + account lockout 5 αποτυχίες. Εφάρμοσέ το σε test OU και επαλήθευσε με `gpresult /r`.

---

## ☁️ 6. Microsoft Entra ID (Azure AD)

Το **Microsoft Entra ID** είναι η cloud-based υπηρεσία identity της Microsoft για:
- Microsoft 365 (Teams, SharePoint, Exchange Online)
- Azure resources
- Οποιαδήποτε εφαρμογή υποστηρίζει OAuth/SAML

### Βασικά Concepts

| Έννοια | Εξήγηση |
|--------|---------|
| **Tenant** | Ο "οργανισμός" σου στο cloud |
| **Conditional Access** | Πολιτικές πρόσβασης βάσει συνθηκών |
| **MFA** | Multi-Factor Authentication — must-have |
| **Privileged Identity Management (PIM)** | Just-in-time admin access |
| **Entra Connect** | Συγχρονισμός on-prem AD → Entra ID |

### Conditional Access — Παράδειγμα

```
ΑΝ: Χρήστης είναι Global Admin
ΚΑΙ: Συνδέεται από εκτός εταιρικού δικτύου
ΤΟΤΕ: Απαίτηση MFA + Compliant Device
```

---

## ⚖️ 7. On-Prem vs Entra ID — Σύγκριση

| Χαρακτηριστικό | On-Prem AD DS | Microsoft Entra ID |
|----------------|---------------|-------------------|
| **Τύπος** | On-premises directory | Cloud directory |
| **Authentication** | Kerberos, NTLM | OAuth 2.0, SAML, OIDC |
| **Domain Join** | Traditional Domain Join | Entra Join |
| **Group Policy** | GPO (GPMC) | Microsoft Intune (MDM) |
| **Admin Tool** | ADUC, GPMC | Azure Portal / Entra admin center |
| **Χρειάζεται DC** | ✅ Ναι | ❌ Όχι |
| **Ιδανικό για** | On-prem servers, legacy apps | Cloud apps, remote work, BYOD |

---

## 💻 8. PowerShell για AD

```powershell
# Φόρτωση module
Import-Module ActiveDirectory

# ====== USERS ======

# Εμφάνιση user
Get-ADUser -Identity "d.katsanos" -Properties *
Get-ADUser -Identity "d.katsanos" -Properties Department, Title, LastLogonDate

# Αναζήτηση users
Get-ADUser -Filter * -SearchBase "OU=IT,DC=company,DC=local" |
    Select-Object Name, SamAccountName, Enabled

Get-ADUser -Filter {Enabled -eq $false} | Select Name   # Disabled users

# Δημιουργία user
New-ADUser -Name "Dimitris Katsanos" `
           -GivenName "Dimitris" `
           -Surname "Katsanos" `
           -SamAccountName "d.katsanos" `
           -UserPrincipalName "d.katsanos@company.local" `
           -Path "OU=IT,OU=Departments,DC=company,DC=local" `
           -AccountPassword (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force) `
           -ChangePasswordAtLogon $true `
           -Enabled $true

# Bulk δημιουργία από CSV
# CSV format: Name,GivenName,Surname,Username
Import-Csv "C:\users.csv" | ForEach-Object {
    New-ADUser -Name $_.Name `
               -GivenName $_.GivenName `
               -Surname $_.Surname `
               -SamAccountName $_.Username `
               -UserPrincipalName "$($_.Username)@company.local" `
               -Path "OU=IT,DC=company,DC=local" `
               -AccountPassword (ConvertTo-SecureString "Welcome123!" -AsPlainText -Force) `
               -ChangePasswordAtLogon $true `
               -Enabled $true
    Write-Host "Δημιουργήθηκε: $($_.Name)"
}

# Disable/Enable/Unlock
Disable-ADAccount -Identity "d.katsanos"
Enable-ADAccount -Identity "d.katsanos"
Unlock-ADAccount -Identity "d.katsanos"

# Reset κωδικού
Set-ADAccountPassword -Identity "d.katsanos" `
                      -Reset `
                      -NewPassword (ConvertTo-SecureString "NewP@ss123!" -AsPlainText -Force)

# ====== GROUPS ======

# Μέλη group
Get-ADGroupMember -Identity "IT-Admins" | Select Name, SamAccountName

# Προσθήκη σε group
Add-ADGroupMember -Identity "IT-Admins" -Members "d.katsanos"
Add-ADGroupMember -Identity "IT-Admins" -Members "d.katsanos","m.papadaki"

# Αφαίρεση από group
Remove-ADGroupMember -Identity "IT-Admins" -Members "d.katsanos" -Confirm:$false

# ====== REPORTS ======

# Ανενεργοί users (90+ μέρες χωρίς login)
$CutoffDate = (Get-Date).AddDays(-90)
Get-ADUser -Filter {LastLogonDate -lt $CutoffDate -and Enabled -eq $true} `
           -Properties LastLogonDate |
    Select Name, SamAccountName, LastLogonDate |
    Export-Csv "C:\inactive_users.csv" -NoTypeInformation

# Όλοι οι locked users
Search-ADAccount -LockedOut | Select Name, SamAccountName, LockedOut
```

---

## 🔧 9. Troubleshooting

| Πρόβλημα | Πιθανή Αιτία | Λύση |
|----------|-------------|------|
| Ο user δεν μπορεί να συνδεθεί | Locked account, expired password | ADUC → Unlock + Reset |
| GPO δεν εφαρμόζεται | Replication lag, WMI filter, Loopback | `gpupdate /force`, `gpresult /r` |
| "Trust relationship failed" | Ο PC έχει χάσει επαφή με domain | `Test-ComputerSecureChannel -Repair -Credential (Get-Credential)` |
| Αργή σύνδεση | DNS προβλήματα | Βεβαιώσου DNS → DC IP |
| Replication errors | Network, permissions | `repadmin /replsummary` |

```powershell
# Βασικά diagnostic εργαλεία
nltest /dsgetdc:company.local        # Εύρεση DC
nslookup -type=SRV _ldap._tcp.company.local  # DNS check
dcdiag /test:replications            # Replication health
netdom query fsmo                    # FSMO role holders
```

> 🔬 **Lab Coming Soon:** Εγκατάσταση Windows Server 2022 σε VirtualBox, προαγωγή σε DC, δημιουργία domain, join workstation, δημιουργία OU/users/GPO.
