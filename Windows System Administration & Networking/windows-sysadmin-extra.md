# 🖧 Windows System Administration — Επιπλέον Κεφάλαια
> Συνέχεια του "Windows System & Networking Command Reference" — Δίσκοι, Registry, Services, Logs, Firewall, Remote Management, Active Directory, Updates, Scheduled Tasks.

---

## 🗺️ Πίνακας Περιεχομένων

7. [Δίσκοι & Storage](#-7-δίσκοι--storage)
8. [Registry](#-8-registry)
9. [Services](#-9-services)
10. [Event Viewer / Logs](#-10-event-viewer--logs)
11. [Firewall](#-11-firewall)
12. [Remote Management](#-12-remote-management)
13. [Active Directory](#-13-active-directory)
14. [Windows Updates](#-14-windows-updates)
15. [Scheduled Tasks](#-15-scheduled-tasks)
16. [Quick Reference Cheat Sheet](#-16-quick-reference--cheat-sheet)

---

## 💾 7. Δίσκοι & Storage

### 📖 Θεωρία: Πώς οργανώνονται οι δίσκοι στα Windows

Ένας φυσικός δίσκος (Disk) χωρίζεται σε **Partitions**, και κάθε partition μορφοποιείται με ένα **File System** (π.χ. NTFS) για να γίνει **Volume** (αυτό που βλέπεις ως γράμμα, π.χ. `C:`).

```
Physical Disk 0
   │
   ├── Partition 1 (System Reserved / EFI)
   │
   ├── Partition 2 (C:) ── NTFS ── Volume "C:"
   │
   └── Partition 3 (D:) ── NTFS ── Volume "D:"
```

**MBR vs GPT:**

| Χαρακτηριστικό | MBR | GPT |
|---|---|---|
| Μέγιστο μέγεθος δίσκου | 2TB | 9.4 ZB |
| Μέγιστες partitions | 4 primary | 128 |
| Boot mode | Legacy BIOS | UEFI |
| Redundancy | Όχι (1 αντίγραφο partition table) | Ναι (αντίγραφα σε πολλά σημεία) |

> ⚠️ Δίσκος πάνω από 2TB **πρέπει** να είναι GPT, αλλιώς ο υπολογιστής βλέπει μόνο τα πρώτα 2TB.

---

### `chkdsk` — Έλεγχος ακεραιότητας file system

#### 📖 Θεωρία: Bad Sectors & File System Errors

Το NTFS κρατά έναν πίνακα (**MFT — Master File Table**) με όλα τα αρχεία και τα σημεία τους στον δίσκο. Απότομο κλείσιμο, power loss ή bad sectors μπορεί να χαλάσουν αυτόν τον πίνακα. Το `chkdsk` σαρώνει και διορθώνει:

```
chkdsk C:                    :: Μόνο σάρωση (read-only, χωρίς αλλαγές)
chkdsk C: /f                 :: Διόρθωση σφαλμάτων file system
chkdsk C: /r                 :: /f + έλεγχος για bad sectors (πιο αργό)
chkdsk C: /x                 :: Force unmount πρώτα (αν χρειάζεται)
```

> ⚠️ Αν ο δίσκος `C:` είναι σε χρήση (πάντα είναι, αφού τρέχει το OS), το `chkdsk /f` θα ζητήσει **reboot** για να τρέξει πριν φορτώσουν τα Windows.

**Ανάγνωση αποτελέσματος:**

| Μήνυμα | Σημαίνει |
|---|---|
| `Windows has scanned the file system and found no problems` | Όλα ΟΚ |
| `Windows has made corrections to the file system` | Βρέθηκαν και διορθώθηκαν σφάλματα |
| Αναφορά για `bad sectors` | Πιθανό πρόβλημα υλικού (disk aging) — αξίζει backup άμεσα |

---

### `diskpart` — Διαχείριση partitions (CLI)

#### 📖 Θεωρία: Interactive shell για δίσκους

Το `diskpart` είναι δικό του mini-shell — μπαίνεις μέσα με `diskpart` και δουλεύεις με εντολές `list`, `select`, `create` κτλ. Είναι επικίνδυνο εργαλείο: `clean` σβήνει partition table χωρίς επιβεβαίωση.

```
diskpart

list disk                     :: Λίστα φυσικών δίσκων
select disk 1                 :: Επιλογή δίσκου (ΠΡΟΣΟΧΗ στο νούμερο!)
list partition                :: Partitions του επιλεγμένου δίσκου
select partition 2
list volume                   :: Όλα τα volumes (όλων των δίσκων)
select volume 3

clean                         :: ⚠️ Διαγράφει ΟΛΑ τα partitions του δίσκου
create partition primary      :: Δημιουργία νέας partition
format fs=ntfs quick          :: Γρήγορη μορφοποίηση NTFS
assign letter=E               :: Ανάθεση γράμματος

detail disk                   :: Λεπτομέρειες επιλεγμένου δίσκου
exit
```

> ⚠️ **Πάντα** επιβεβαίωσε με `list disk` / `list volume` ποιο disk number είναι το σωστό πριν από `clean` ή `format` — δεν υπάρχει "undo".

---

### PowerShell εναλλακτικές (πιο ασφαλείς & scriptable)

```powershell
Get-Disk                                  :: Λίστα φυσικών δίσκων
Get-Volume                                :: Λίστα volumes με % free space
Get-Partition                             :: Λίστα partitions

Get-Volume | Select DriveLetter, FileSystemLabel, SizeRemaining, Size

# Νέος δίσκος: initialize + partition + format σε 3 βήματα
Initialize-Disk -Number 1 -PartitionStyle GPT
New-Partition -DiskNumber 1 -UseMaximumSize -DriveLetter E
Format-Volume -DriveLetter E -FileSystem NTFS -NewFileSystemLabel "Data"

# Repair
Repair-Volume -DriveLetter C -Scan
```

---

### BitLocker — Κρυπτογράφηση δίσκου

#### 📖 Θεωρία

Το BitLocker κρυπτογραφεί ολόκληρο το volume. Το κλειδί αποθηκεύεται είτε σε **TPM chip** (hardware, αυτόματο unlock) είτε ως **Recovery Key** (48ψήφιος αριθμός, χρειάζεται αν αλλάξει hardware ή χαθεί το TPM state).

```
manage-bde -status                        :: Κατάσταση κρυπτογράφησης όλων των volumes
manage-bde -on C: -RecoveryPassword       :: Ενεργοποίηση σε C: με recovery key
manage-bde -lock C:                       :: Κλείδωμα (χρειάζεται recovery key για unlock)
manage-bde -unlock C: -RecoveryPassword <key>
manage-bde -protectors -get C:            :: Δες τα protectors (TPM, recovery key κτλ.)
```

```powershell
Get-BitLockerVolume                       :: PowerShell εναλλακτική
```

> 💡 Αν ο χρήστης λέει "μου ζητάει recovery key στην εκκίνηση", συνήθως άλλαξε κάτι στο BIOS/UEFI (π.χ. Secure Boot toggle) και το TPM "δεν αναγνωρίζει" πια το state — φυσιολογικό, όχι απαραίτητα πρόβλημα ασφαλείας.

---

## 🗂️ 8. Registry

### 📖 Θεωρία: Τι είναι το Registry

Το Registry είναι μια ιεραρχική βάση δεδομένων (σαν "σκελετός" ρυθμίσεων) όπου τα Windows και οι εφαρμογές αποθηκεύουν configuration. Οργανώνεται σε **Hives**:

| Hive | Περιεχόμενο |
|---|---|
| `HKEY_LOCAL_MACHINE` (HKLM) | Ρυθμίσεις συστήματος — ισχύουν για όλους τους χρήστες |
| `HKEY_CURRENT_USER` (HKCU) | Ρυθμίσεις του τρέχοντος χρήστη |
| `HKEY_USERS` (HKU) | Όλα τα προφίλ χρηστών (HKCU είναι ένα "shortcut" μέσα σε αυτό) |
| `HKEY_CLASSES_ROOT` (HKCR) | File associations, COM objects |
| `HKEY_CURRENT_CONFIG` | Τρέχον hardware profile |

Κάθε hive έχει **Keys** (σαν φακέλους) και **Values** (σαν αρχεία μέσα, με Name/Type/Data).

**Τύποι values:**

| Τύπος | Χρήση |
|---|---|
| `REG_SZ` | Απλό κείμενο |
| `REG_DWORD` | 32-bit αριθμός (0/1 συχνά για on/off) |
| `REG_BINARY` | Δυαδικά δεδομένα |
| `REG_MULTI_SZ` | Λίστα από strings |
| `REG_EXPAND_SZ` | Κείμενο με μεταβλητές (π.χ. `%SystemRoot%`) |

> ⚠️ Λάθος αλλαγή στο Registry μπορεί να κάνει τα Windows να μη ξεκινούν. **Πάντα** export πριν από αλλαγή.

---

### `reg query` / `reg add` / `reg delete`

```
:: Ανάγνωση key
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion"

:: Ανάγνωση συγκεκριμένης τιμής
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName

:: Προσθήκη/τροποποίηση τιμής
reg add "HKCU\Software\MyApp" /v Setting1 /t REG_DWORD /d 1 /f

:: Διαγραφή τιμής
reg delete "HKCU\Software\MyApp" /v Setting1 /f

:: Διαγραφή ολόκληρου key (ΠΡΟΣΟΧΗ)
reg delete "HKCU\Software\MyApp" /f
```

**Backup / Restore:**

```
reg export "HKCU\Software\MyApp" C:\backup\myapp.reg    :: Export πριν αλλαγή
reg import C:\backup\myapp.reg                           :: Restore αν κάτι πάει στραβά
```

---

### PowerShell εναλλακτικές

```powershell
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
New-ItemProperty -Path "HKCU:\Software\MyApp" -Name "Setting1" -Value 1 -PropertyType DWord
Remove-ItemProperty -Path "HKCU:\Software\MyApp" -Name "Setting1"
```

---

### Χρήσιμα Registry paths για Helpdesk

| Path | Χρήση |
|---|---|
| `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run` | Προγράμματα που τρέχουν στην εκκίνηση (όλοι οι χρήστες) |
| `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` | Προγράμματα εκκίνησης (τρέχων χρήστης) |
| `HKLM\SYSTEM\CurrentControlSet\Services` | Λίστα εγκατεστημένων services |
| `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList` | Προφίλ χρηστών του υπολογιστή |

```
:: Έλεγχος τι τρέχει στην εκκίνηση (autoruns, χωρίς GUI εργαλείο)
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
```

---

## ⚙️ 9. Services

### 📖 Θεωρία: Τι είναι ένα Windows Service

Ένα **Service** είναι ένα background πρόγραμμα που τρέχει ανεξάρτητα από το αν έχει γίνει login κάποιος χρήστης — π.χ. o Print Spooler, το Windows Update, ο DHCP Client.

**Startup Types:**

| Τύπος | Συμπεριφορά |
|---|---|
| `Automatic` | Ξεκινά αυτόματα στο boot |
| `Automatic (Delayed Start)` | Ξεκινά λίγο μετά το boot, για να μη "φορτώνει" την εκκίνηση |
| `Manual` | Ξεκινά μόνο όταν το ζητήσει κάποια εφαρμογή/χρήστης |
| `Disabled` | Δεν ξεκινά ποτέ |

Κάθε service τρέχει κάτω από έναν **λογαριασμό** (π.χ. `Local System`, `Local Service`, `Network Service`, ή συγκεκριμένο user account) — αυτό καθορίζει τα δικαιώματά του.

---

### `sc` — Service Control (CMD)

```
sc query                              :: Όλα τα services + κατάσταση
sc query spooler                      :: Συγκεκριμένο service
sc queryex spooler                    :: + PID

sc start spooler
sc stop spooler
sc config spooler start= auto         :: Αλλαγή startup type (ΠΡΟΣΟΧΗ: space μετά το =)
sc config spooler start= demand       :: Manual
sc config spooler start= disabled     :: Disabled

sc qc spooler                         :: Configuration (startup type, dependencies, account)
```

> ⚠️ Στο `sc config`, το space μετά το `=` είναι **υποχρεωτικό** (`start= auto`, όχι `start=auto`).

---

### PowerShell — Πιο ισχυρό & ευανάγνωστο

```powershell
Get-Service                                    :: Όλα τα services
Get-Service -Name Spooler                      :: Συγκεκριμένο
Get-Service | Where-Object Status -eq "Running"
Get-Service | Where-Object Status -eq "Stopped" | Where StartType -eq "Automatic"  # Ύποπτα stopped

Start-Service Spooler
Stop-Service Spooler
Restart-Service Spooler

Set-Service Spooler -StartupType Automatic
Set-Service Spooler -StartupType Disabled

# Ποιος λογαριασμός τρέχει το service
Get-CimInstance Win32_Service -Filter "Name='Spooler'" | Select Name, StartName, State
```

**Troubleshooting Use Case — Service δεν ξεκινά:**

```powershell
# 1. Δες την κατάσταση
Get-Service Spooler

# 2. Δες dependencies — αν κάποιο dependency είναι stopped, το service δεν θα ξεκινήσει
sc qc spooler

# 3. Δοκίμασε manual start και δες το error
Start-Service Spooler -ErrorAction Stop

# 4. Έλεγξε το Event Viewer (System log) για το ακριβές σφάλμα
Get-WinEvent -LogName System -MaxEvents 20 | Where Message -like "*Spooler*"
```

---

## 📜 10. Event Viewer / Logs

### 📖 Θεωρία: Πώς οργανώνονται τα logs

Τα Windows καταγράφουν κάθε σημαντικό συμβάν σε **Event Logs**, χωρισμένα σε κατηγορίες:

| Log | Περιεχόμενο |
|---|---|
| `System` | Συμβάντα OS/drivers/services (crashes, service start/stop) |
| `Application` | Συμβάντα εφαρμογών |
| `Security` | Login/logoff, αλλαγές δικαιωμάτων, audit events |
| `Setup` | Εγκαταστάσεις/updates |

Κάθε event έχει: **Event ID**, **Level** (Information/Warning/Error/Critical), **Source**, **Time**, **Message**.

**Χρήσιμα Event IDs:**

| Event ID | Log | Σημαίνει |
|---|---|---|
| `4624` | Security | Επιτυχής login |
| `4625` | Security | Αποτυχημένος login (πιθανό brute-force αν επαναλαμβάνεται) |
| `4634` | Security | Logoff |
| `4720` | Security | Δημιουργία νέου user account |
| `4732` | Security | Προσθήκη user σε security group |
| `6005` | System | Το OS ξεκίνησε (Event Log service started) |
| `6006` | System | Καθαρό shutdown |
| `41` | System | Απότομος τερματισμός (Kernel-Power — π.χ. διακοπή ρεύματος, crash) |
| `7034` | System | Service τερμάτισε απροσδόκητα |
| `1074` | System | Ελεγχόμενο shutdown/restart — δείχνει ποιος/τι το ξεκίνησε |

> 💡 Το `Event ID 41` χωρίς αντίστοιχο `1074` πριν από αυτό σημαίνει ότι ο υπολογιστής **δεν** έκλεισε κανονικά — χρήσιμο για διάγνωση απρόβλεπτων restarts.

---

### `wevtutil` — CLI εργαλείο (CMD)

```
wevtutil el                                    :: Λίστα όλων των logs
wevtutil qe System /c:10 /rd:true /f:text      :: Τελευταία 10 events από System
wevtutil qe Security /c:5 /rd:true /f:text     :: Τελευταία 5 από Security

:: Φιλτράρισμα με XPath (πιο ισχυρό)
wevtutil qe System /q:"*[System[(EventID=41)]]" /f:text /c:5

:: Καθαρισμός log (ΠΡΟΣΟΧΗ — μη αναστρέψιμο)
wevtutil cl Application
```

---

### `Get-WinEvent` — PowerShell (προτιμότερο)

```powershell
# Τελευταία 20 events από System
Get-WinEvent -LogName System -MaxEvents 20

# Μόνο Errors
Get-WinEvent -LogName System -MaxEvents 50 | Where LevelDisplayName -eq "Error"

# Συγκεκριμένο Event ID
Get-WinEvent -LogName Security -FilterXPath "*[System[(EventID=4625)]]" -MaxEvents 20

# Αποτυχημένα logins τελευταίου 24ώρου
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625; StartTime=(Get-Date).AddDays(-1)}

# Αναζήτηση σε μήνυμα
Get-WinEvent -LogName Application -MaxEvents 100 | Where Message -like "*crash*"

# Export για ανάλυση/αναφορά
Get-WinEvent -LogName System -MaxEvents 500 | Export-Csv C:\logs\system.csv -NoTypeInformation
```

**Security Use Case — Έλεγχος για brute-force login attempts:**

```powershell
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625} -MaxEvents 50 |
    Select TimeCreated, @{N="User";E={$_.Properties[5].Value}}, @{N="SourceIP";E={$_.Properties[19].Value}} |
    Group-Object SourceIP | Sort Count -Descending
```

---

## 🔥 11. Firewall

### 📖 Θεωρία: Windows Defender Firewall

Το Windows Firewall δουλεύει με **κανόνες (rules)** που ελέγχουν εισερχόμενη (Inbound) και εξερχόμενη (Outbound) κίνηση, ανά **Profile**:

| Profile | Πότε εφαρμόζεται |
|---|---|
| `Domain` | Ο υπολογιστής είναι συνδεδεμένος σε domain network |
| `Private` | Ιδιωτικό δίκτυο (σπίτι/γραφείο, εμπιστοσύνη) |
| `Public` | Δημόσιο δίκτυο (καφετέρια, αεροδρόμιο — πιο αυστηρό) |

Κάθε rule ορίζει: πρόγραμμα/port/protocol, direction, action (Allow/Block), και σε ποιο profile ισχύει.

---

### `netsh advfirewall` (CMD)

```
netsh advfirewall show allprofiles state           :: Κατάσταση firewall ανά profile
netsh advfirewall set allprofiles state on          :: Ενεργοποίηση
netsh advfirewall set allprofiles state off         :: Απενεργοποίηση (ΠΡΟΣΟΧΗ)

:: Άνοιγμα port
netsh advfirewall firewall add rule name="Allow RDP" dir=in action=allow protocol=TCP localport=3389

:: Κλείσιμο/διαγραφή rule
netsh advfirewall firewall delete rule name="Allow RDP"

:: Λίστα κανόνων
netsh advfirewall firewall show rule name=all
```

---

### PowerShell — `NetSecurity` module (προτιμότερο)

```powershell
Get-NetFirewallProfile                              :: Κατάσταση profiles
Get-NetFirewallRule | Where Enabled -eq True | Select DisplayName, Direction, Action

# Νέος κανόνας — άνοιγμα port
New-NetFirewallRule -DisplayName "Allow RDP" -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow

# Νέος κανόνας — αποκλεισμός συγκεκριμένης εφαρμογής
New-NetFirewallRule -DisplayName "Block App" -Direction Outbound -Program "C:\App\app.exe" -Action Block

# Ενεργοποίηση/απενεργοποίηση υπάρχοντος κανόνα
Disable-NetFirewallRule -DisplayName "Allow RDP"
Enable-NetFirewallRule -DisplayName "Allow RDP"

# Διαγραφή
Remove-NetFirewallRule -DisplayName "Allow RDP"
```

**Troubleshooting Use Case — "Δεν μπορώ να συνδεθώ με RDP στον server":**

```powershell
# 1. Έλεγχος αν το port ακούει τοπικά στον server
Test-NetConnection -ComputerName localhost -Port 3389

# 2. Έλεγχος firewall rule
Get-NetFirewallRule -DisplayGroup "Remote Desktop" | Select DisplayName, Enabled, Direction, Action

# 3. Αν το rule λείπει/είναι disabled → ενεργοποίηση
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# 4. Έλεγχος από τον client
Test-NetConnection -ComputerName server01 -Port 3389
```

---

## 🖥️ 12. Remote Management

### 📖 Θεωρία: Τρόποι απομακρυσμένης διαχείρισης

| Εργαλείο | Πρωτόκολλο/Port | Χρήση |
|---|---|---|
| **RDP** (`mstsc`) | TCP 3389 | Πλήρες γραφικό περιβάλλον απομακρυσμένα |
| **WinRM / PowerShell Remoting** | TCP 5985 (HTTP) / 5986 (HTTPS) | Εκτέλεση εντολών/scripts απομακρυσμένα |
| **PsExec** (Sysinternals) | SMB (445) | Εκτέλεση προγραμμάτων απομακρυσμένα χωρίς μόνιμη σύνδεση |

---

### `mstsc` — Remote Desktop

```
mstsc                              :: Άνοιγμα GUI, εισαγωγή server χειροκίνητα
mstsc /v:server01                  :: Απευθείας σύνδεση σε server
mstsc /v:server01 /admin           :: Σύνδεση σε console session (admin mode)
mstsc /v:server01:3390             :: Custom port
```

> 💡 Πριν δοκιμάσεις RDP, έλεγξε πρώτα connectivity: `Test-NetConnection server01 -Port 3389`. Αν αποτύχει, το πρόβλημα είναι firewall/service, όχι credentials.

---

### PowerShell Remoting (WinRM)

#### 📖 Θεωρία

Το **WinRM (Windows Remote Management)** είναι η Microsoft υλοποίηση του πρωτοκόλλου **WS-Management** — επιτρέπει εκτέλεση PowerShell εντολών σε απομακρυσμένο υπολογιστή σαν να είσαι τοπικά. Πρέπει να είναι **ενεργοποιημένο** στον στόχο (`Enable-PSRemoting`) και συνήθως χρειάζεται domain-joined περιβάλλον ή TrustedHosts config.

```powershell
# Ενεργοποίηση στον στόχο (τρέχει τοπικά ΣΤΟΝ server)
Enable-PSRemoting -Force

# Έλεγχος αν είναι διαθέσιμο
Test-WSMan server01

# Interactive session — σαν να "μπαίνεις" μέσα στον server
Enter-PSSession -ComputerName server01
# ... εντολές εκτελούνται στον server ...
Exit-PSSession

# Εκτέλεση μίας εντολής χωρίς interactive session
Invoke-Command -ComputerName server01 -ScriptBlock { Get-Service Spooler }

# Σε πολλούς υπολογιστές ταυτόχρονα
Invoke-Command -ComputerName server01,server02,server03 -ScriptBlock { Get-Process }

# Με διαφορετικά credentials
Invoke-Command -ComputerName server01 -Credential (Get-Credential) -ScriptBlock { Restart-Service Spooler }

# Non-domain υπολογιστές — προσθήκη σε TrustedHosts πρώτα (τρέχει στον client)
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "server01" -Force
```

> ⚠️ Το `Enter-PSSession`/`Invoke-Command` χρειάζεται τα κατάλληλα δικαιώματα (μέλος `Administrators` ή `Remote Management Users` group στον στόχο).

---

### PsExec (Sysinternals)

```
:: Εκτέλεση εντολής σε απομακρυσμένο υπολογιστή
psexec \\server01 cmd

:: Με credentials
psexec \\server01 -u DOMAIN\admin -p Password123 cmd

:: Εκτέλεση συγκεκριμένου προγράμματος
psexec \\server01 ipconfig /all

:: Interactive session ως SYSTEM (τοπικά, για troubleshooting permissions)
psexec -s -i cmd
```

> 💡 Το PsExec δεν είναι built-in — κατεβαίνει από το Sysinternals Suite της Microsoft.

---

## 🏢 13. Active Directory

### 📖 Θεωρία: Δομή AD

Το **Active Directory** είναι η κεντρική βάση δεδομένων ταυτότητας/δικαιωμάτων σε domain environment. Βασικά αντικείμενα:

```
Forest
  └── Domain (π.χ. company.local)
        ├── OU: IT Department
        │     ├── User: d.katsanos
        │     └── Computer: PC-IT-01
        ├── OU: Sales
        │     └── User: k.papadopoulos
        └── Security Groups (π.χ. "IT-Admins", "Sales-ReadOnly")
```

- **OU (Organizational Unit):** Φάκελος οργάνωσης — εκεί "κολλάνε" τα GPOs
- **Security Group:** Ομάδα χρηστών/υπολογιστών για permissions (διαφορετικό από OU!)
- **Distinguished Name (DN):** Πλήρης "διεύθυνση" ενός object, π.χ. `CN=Dimitris Katsanos,OU=IT,DC=company,DC=local`

> 💡 Οι Groups χρησιμοποιούνται για **permissions**, τα OUs για **GPOs και οργάνωση**. Ένας χρήστης μπορεί να ανήκει σε πολλά groups αλλά μόνο σε ένα OU.

---

### `dsquery` / `dsget` (CMD — legacy αλλά ακόμα χρήσιμο)

```
:: Εύρεση χρήστη
dsquery user -name "Dimitris*"

:: Εύρεση computer
dsquery computer -name "PC-IT*"

:: Πληροφορίες συγκεκριμένου user (χρειάζεται πλήρες DN)
dsget user "CN=Dimitris Katsanos,OU=IT,DC=company,DC=local" -memberof
```

---

### PowerShell — `ActiveDirectory` module (RSAT, προτιμότερο)

```powershell
# Εγκατάσταση RSAT module (αν λείπει)
# Windows 10/11: Settings > Optional Features > RSAT: Active Directory

Import-Module ActiveDirectory

# Εύρεση χρήστη
Get-ADUser -Identity dkatsanos -Properties *
Get-ADUser -Filter "Name -like '*Katsanos*'"

# Λίστα users σε OU
Get-ADUser -SearchBase "OU=IT,DC=company,DC=local" -Filter *

# Δημιουργία νέου χρήστη
New-ADUser -Name "Test User" -SamAccountName "tuser" -Path "OU=IT,DC=company,DC=local" -Enabled $true -AccountPassword (ConvertTo-SecureString "P@ss123!" -AsPlainText -Force)

# Group membership
Get-ADUser dkatsanos -Properties MemberOf | Select -ExpandProperty MemberOf
Add-ADGroupMember -Identity "IT-Admins" -Members dkatsanos
Remove-ADGroupMember -Identity "IT-Admins" -Members dkatsanos

# Computers στο domain
Get-ADComputer -Filter * -Properties LastLogonDate | Select Name, LastLogonDate

# Unlock / Reset password
Unlock-ADAccount -Identity dkatsanos
Set-ADAccountPassword -Identity dkatsanos -Reset -NewPassword (ConvertTo-SecureString "NewP@ss123!" -AsPlainText -Force)
Set-ADUser -Identity dkatsanos -ChangePasswordAtLogon $true

# Disable/Enable account
Disable-ADAccount -Identity dkatsanos
Enable-ADAccount -Identity dkatsanos
```

**Troubleshooting Use Case — "Ο χρήστης δεν μπορεί να κάνει login, λέει locked out":**

```powershell
# 1. Έλεγχος κατάστασης λογαριασμού
Get-ADUser dkatsanos -Properties LockedOut, PasswordExpired, Enabled

# 2. Ξεκλείδωμα
Unlock-ADAccount -Identity dkatsanos

# 3. Εύρεση ΑΠΟ ΠΟΥ έγιναν τα failed attempts (στον Domain Controller)
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4740} -MaxEvents 10   # Account Lockout events
```

---

## 🔄 14. Windows Updates

### 📖 Θεωρία: Πώς λειτουργούν τα updates

Ο **Windows Update Agent** ελέγχει περιοδικά για updates είτε από τη Microsoft απευθείας, είτε — σε επιχειρησιακό περιβάλλον — από **WSUS (Windows Server Update Services)**, όπου ο IT admin εγκρίνει ποια updates διανέμονται.

**Κατηγορίες updates:**

| Τύπος | Περιγραφή |
|---|---|
| Security Updates | Διορθώσεις ασφαλείας — κρίσιμα |
| Cumulative Updates | Συγκεντρωτικά μηνιαία (Patch Tuesday) |
| Feature Updates | Νέα έκδοση OS (π.χ. 22H2 → 23H2) |
| Driver Updates | Ενημερώσεις drivers μέσω Windows Update |

---

### Έλεγχος & διαχείριση (GUI εντολές μέσω CMD)

```
:: Άνοιγμα Windows Update settings
start ms-settings:windowsupdate

:: Ιστορικό εγκατεστημένων updates (classic control panel)
control /name Microsoft.WindowsUpdate

:: Λίστα εγκατεστημένων hotfixes
wmic qfe list brief

:: Ή σε PowerShell
Get-HotFix | Sort InstalledOn -Descending
```

---

### PowerShell — `PSWindowsUpdate` module

```powershell
# Εγκατάσταση module (χρειάζεται internet, μία φορά)
Install-Module PSWindowsUpdate -Force

Import-Module PSWindowsUpdate

Get-WindowsUpdate                          :: Λίστα διαθέσιμων updates
Get-WUHistory                              :: Ιστορικό εγκατεστημένων

Install-WindowsUpdate -AcceptAll -AutoReboot     :: Εγκατάσταση όλων + auto restart
Install-WindowsUpdate -KBArticleID "KB5034123"   :: Συγκεκριμένο update

Hide-WindowsUpdate -KBArticleID "KB5034123"      :: Απόκρυψη προβληματικού update
```

**Troubleshooting Use Case — Update αποτυγχάνει επανειλημμένα:**

```
:: 1. Επανεκκίνηση Windows Update services
net stop wuauserv
net stop bits
net stop cryptsvc

:: 2. Μετονομασία φακέλου cache (θα ξαναδημιουργηθεί)
ren C:\Windows\SoftwareDistribution SoftwareDistribution.old

:: 3. Επανεκκίνηση services
net start wuauserv
net start bits
net start cryptsvc

:: 4. Νέα προσπάθεια
```

> 💡 Αν το πρόβλημα παραμένει, τρέξε πρώτα `dism /online /cleanup-image /restorehealth` και `sfc /scannow` (§5) — πολλά update failures προέρχονται από corrupted component store.

---

## ⏰ 15. Scheduled Tasks

### 📖 Θεωρία

Ο **Task Scheduler** τρέχει προγράμματα/scripts αυτόματα βάσει **triggers** (ώρα, event, login, κτλ.). Χρησιμοποιείται τόσο από τα Windows όσο και από admins για αυτοματοποίηση (backups, cleanup scripts, monitoring).

Κάθε task έχει: **Trigger** (πότε), **Action** (τι εκτελεί), **Conditions** (π.χ. μόνο αν υπάρχει AC power), **Settings** (retry policy κτλ.).

---

### `schtasks` (CMD)

```
schtasks /query                                     :: Λίστα όλων των tasks
schtasks /query /fo LIST /v                         :: Αναλυτικά
schtasks /query /tn "MyTask"                        :: Συγκεκριμένο task

:: Δημιουργία task — καθημερινά στις 03:00
schtasks /create /tn "NightlyBackup" /tr "C:\Scripts\backup.bat" /sc daily /st 03:00

:: Δημιουργία — κάθε φορά που κάνει login ο χρήστης
schtasks /create /tn "StartupScript" /tr "C:\Scripts\startup.ps1" /sc onlogon

:: Manual εκτέλεση τώρα (για test)
schtasks /run /tn "NightlyBackup"

:: Απενεργοποίηση/ενεργοποίηση
schtasks /change /tn "NightlyBackup" /disable
schtasks /change /tn "NightlyBackup" /enable

:: Διαγραφή
schtasks /delete /tn "NightlyBackup" /f
```

---

### PowerShell — `ScheduledTasks` module (προτιμότερο)

```powershell
Get-ScheduledTask                                          :: Όλα τα tasks
Get-ScheduledTask -TaskName "NightlyBackup"

Get-ScheduledTaskInfo -TaskName "NightlyBackup"             :: Last run, next run, last result

# Δημιουργία task
$action = New-ScheduledTaskAction -Execute "C:\Scripts\backup.bat"
$trigger = New-ScheduledTaskTrigger -Daily -At "03:00"
Register-ScheduledTask -TaskName "NightlyBackup" -Action $action -Trigger $trigger -User "SYSTEM"

Start-ScheduledTask -TaskName "NightlyBackup"
Disable-ScheduledTask -TaskName "NightlyBackup"
Enable-ScheduledTask -TaskName "NightlyBackup"
Unregister-ScheduledTask -TaskName "NightlyBackup" -Confirm:$false
```

**Troubleshooting Use Case — Το scheduled task "δεν τρέχει":**

```powershell
# 1. Έλεγχος τελευταίου αποτελέσματος (0 = success)
Get-ScheduledTaskInfo -TaskName "NightlyBackup" | Select LastRunTime, LastTaskResult

# 2. Αν LastTaskResult != 0, ψάξε τον κωδικό (π.χ. 0x1 = γενικό σφάλμα, 
#    0x41303 = δεν έτρεξε ποτέ ακόμα, 0x8004131F = ήδη τρέχει)

# 3. Έλεγχος του λογαριασμού κάτω από τον οποίο τρέχει
Get-ScheduledTask -TaskName "NightlyBackup" | Select -ExpandProperty Principal

# 4. Manual test για να δεις το πραγματικό σφάλμα
Start-ScheduledTask -TaskName "NightlyBackup"
Get-WinEvent -LogName "Microsoft-Windows-TaskScheduler/Operational" -MaxEvents 10
```

---

## 📋 16. Quick Reference — Cheat Sheet

### 💾 Δίσκοι
| Εντολή | Χρήση |
|---|---|
| `chkdsk C: /f` | Διόρθωση file system errors |
| `diskpart` | Interactive partition management |
| `Get-Disk` / `Get-Volume` | PowerShell λίστα δίσκων/volumes |
| `manage-bde -status` | Κατάσταση BitLocker |

### 🗂️ Registry
| Εντολή | Χρήση |
|---|---|
| `reg query "HKLM\..."` | Ανάγνωση key |
| `reg add "HKCU\..." /v X /t REG_DWORD /d 1 /f` | Προσθήκη τιμής |
| `reg export "HKCU\..." backup.reg` | Backup πριν αλλαγή |

### ⚙️ Services
| Εντολή | Χρήση |
|---|---|
| `Get-Service` | Λίστα services |
| `Start-Service` / `Stop-Service` / `Restart-Service` | Έλεγχος service |
| `Set-Service -StartupType Automatic` | Αλλαγή startup type |

### 📜 Logs
| Εντολή | Χρήση |
|---|---|
| `Get-WinEvent -LogName System -MaxEvents 20` | Τελευταία events |
| `Get-WinEvent -FilterHashtable @{LogName='Security';Id=4625}` | Failed logins |

### 🔥 Firewall
| Εντολή | Χρήση |
|---|---|
| `Get-NetFirewallRule` | Λίστα κανόνων |
| `New-NetFirewallRule -DisplayName X -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow` | Νέος κανόνας |

### 🖥️ Remote Management
| Εντολή | Χρήση |
|---|---|
| `mstsc /v:server01` | RDP σύνδεση |
| `Enter-PSSession -ComputerName server01` | PowerShell remoting |
| `Invoke-Command -ComputerName server01 -ScriptBlock {...}` | Απομακρυσμένη εντολή |

### 🏢 Active Directory
| Εντολή | Χρήση |
|---|---|
| `Get-ADUser -Identity user -Properties *` | Πληροφορίες χρήστη |
| `Unlock-ADAccount -Identity user` | Ξεκλείδωμα λογαριασμού |
| `Add-ADGroupMember -Identity Group -Members user` | Προσθήκη σε group |

### 🔄 Updates
| Εντολή | Χρήση |
|---|---|
| `Get-HotFix` | Εγκατεστημένα updates |
| `Get-WindowsUpdate` / `Install-WindowsUpdate -AcceptAll` | Έλεγχος/εγκατάσταση (PSWindowsUpdate) |

### ⏰ Scheduled Tasks
| Εντολή | Χρήση |
|---|---|
| `Get-ScheduledTask` | Λίστα tasks |
| `Get-ScheduledTaskInfo -TaskName X` | Αποτέλεσμα τελευταίας εκτέλεσης |
| `Register-ScheduledTask` | Δημιουργία νέου task |

---

> 📝 **Σημείωση:** Οι περισσότερες εντολές αυτού του εγγράφου (`diskpart`, `manage-bde`, `reg add/delete`, `sc config`, `New-NetFirewallRule`, Active Directory cmdlets, `Install-WindowsUpdate`) απαιτούν εκτέλεση **ως Administrator**, και οι Active Directory εντολές επιπλέον απαιτούν το **RSAT: Active Directory module** εγκατεστημένο.
