# 🧠 Windows Advanced Administration — Troubleshooting, Automation & Architecture

Συνέχεια των `windows-commands-reference.md` και `windows-sysadmin-extra.md`. Ενώ τα δύο πρώτα αρχεία καλύπτουν **εντολές και εργαλεία** (reference/cheat sheet style), αυτό το αρχείο εστιάζει σε **σενάρια troubleshooting, αυτοματοποίηση με PowerShell και αρχιτεκτονικές αποφάσεις** — δηλαδή στο "πώς σκέφτεται" ένας sysadmin σε πραγματικά περιστατικά.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Active Directory Replication & Deep Troubleshooting](#-1-active-directory-replication--deep-troubleshooting)
2. [Group Policy Deep Dive](#-2-group-policy-deep-dive)
3. [DNS/DHCP High Availability](#-3-dnsdhcp-high-availability)
4. [PowerShell Automation & Remoting](#-4-powershell-automation--remoting)
5. [Performance Monitoring & Bottleneck Analysis](#-5-performance-monitoring--bottleneck-analysis)
6. [Backup & Disaster Recovery](#-6-backup--disaster-recovery)
7. [Security Hardening & LAPS](#-7-security-hardening--laps)
8. [Certificate Services (PKI) Βασικά](#-8-certificate-services-pki-βασικά)
9. [WSUS & Patch Management](#-9-wsus--patch-management)
10. [Advanced Networking (Routing, VPN, IPAM)](#-10-advanced-networking-routing-vpn-ipam)
11. [Real-World Troubleshooting Playbooks](#-11-real-world-troubleshooting-playbooks)
12. [Quick Reference — Cheat Sheet](#-12-quick-reference--cheat-sheet)

---

## 🔗 1. Active Directory Replication & Deep Troubleshooting

### Έλεγχος υγείας replication
```powershell
# Γενικός έλεγχος υγείας domain controller
dcdiag /v /c /d /e /s:DC01

# Κατάσταση replication μεταξύ όλων των DCs
repadmin /replsummary

# Λεπτομερής προβολή replication partners ενός DC
repadmin /showrepl DC01

# Εξαναγκασμός replication σε όλα τα partners
repadmin /syncall /AdeP

# Εντοπισμός lingering objects
repadmin /removelingeringobjects DC01 <GUID> <NamingContext> /advisory_mode
```

### Metadata cleanup μετά από αποτυχημένη υποβάθμιση DC
```powershell
ntdsutil
metadata cleanup
# ή με PowerShell:
Remove-ADDomainController -DomainController "OldDC01" -Force
```

### USN Rollback — αναγνώριση & αντιμετώπιση
- Συμβαίνει όταν επαναφέρεις snapshot VM ενός DC χωρίς VM-Generation ID support.
- Event ID **2095** στο Directory Service log.
- Λύση: απομόνωση DC από δίκτυο, ανάκτηση από authoritative backup ή re-promotion.

---

## 🧩 2. Group Policy Deep Dive

### Ανάλυση εφαρμογής GPO σε client
```powershell
# Δημιουργία HTML report με πλήρη ανάλυση
gpresult /h C:\Reports\gpresult.html /f

# RSoP σε συγκεκριμένο χρήστη/υπολογιστή
gpresult /r /user:DOMAIN\jdoe

# Καταγραφή σε event log για debugging (client side)
gpupdate /force /boot /logoff
```

### Σειρά εφαρμογής (LSDOU) & συνηθισμένα προβλήματα
1. **Local** → **Site** → **Domain** → **OU** (τελευταίο "κερδίζει" σε conflict)
2. **Block Inheritance** στο OU δεν παρακάμπτει "Enforced" GPOs ανώτερου επιπέδου.
3. **Loopback Processing** (Merge/Replace) — χρήσιμο για Terminal Servers / Kiosk PCs:
```powershell
# Στο Computer Configuration > Administrative Templates > System > Group Policy
# "Configure user Group Policy loopback processing mode" = Merge ή Replace
```
4. **WMI Filters** — παράδειγμα φιλτραρίσματος μόνο για Windows 11 laptops:
```sql
SELECT * FROM Win32_OperatingSystem WHERE Version LIKE "10.0.22%"
```

### Debugging όταν ένα GPO "δεν πιάνει"
- Έλεγχος **Security Filtering** (default: Authenticated Users).
- Έλεγχος **Delegation tab** για Apply Group Policy = Allow.
- `gpresult /h` → κοίτα "Denied GPOs" section, δείχνει *γιατί* απορρίφθηκε.

---

## 🌐 3. DNS/DHCP High Availability

### DHCP Failover (χωρίς cluster, Server 2012+)
```powershell
Add-DhcpServerv4Failover `
  -Name "HQ-Failover" `
  -ScopeId 192.168.10.0 `
  -PartnerServer DHCP02 `
  -Mode LoadBalance `
  -LoadBalancePercent 50
```
- **Load Balance mode**: και οι δύο servers ενεργοί ταυτόχρονα.
- **Hot Standby mode**: ένας primary, ένας passive (καλύτερο για hub-and-spoke).

### DNS Conditional Forwarding
```powershell
Add-DnsServerConditionalForwarderZone `
  -Name "partner.local" `
  -MasterServers 10.10.5.5
```

### DNS Scavenging (καθαρισμός stale records)
```powershell
Set-DnsServerScavenging -ScavengingState $true -ScavengingInterval 7.00:00:00
```

---

## ⚙️ 4. PowerShell Automation & Remoting

### PowerShell Remoting setup
```powershell
Enable-PSRemoting -Force
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "10.10.0.*" -Force
Enter-PSSession -ComputerName SRV01 -Credential (Get-Credential)
```

### Bulk operations παράδειγμα — απενεργοποίηση ανενεργών λογαριασμών AD
```powershell
$cutoff = (Get-Date).AddDays(-90)
Search-ADAccount -AccountInactive -TimeSpan 90.00:00:00 -UsersOnly |
    Where-Object { $_.Enabled -eq $true } |
    ForEach-Object {
        Disable-ADAccount -Identity $_.SamAccountName
        Write-Output "Disabled: $($_.SamAccountName)"
    }
```

### Desired State Configuration (DSC) — απλό παράδειγμα
```powershell
Configuration WebServerConfig {
    Node "SRV01" {
        WindowsFeature IIS {
            Ensure = "Present"
            Name   = "Web-Server"
        }
    }
}
WebServerConfig -OutputPath "C:\DSC"
Start-DscConfiguration -Path "C:\DSC" -Wait -Verbose
```

### Scheduled inventory script (CSV export όλων των servers)
```powershell
$servers = Get-Content "C:\Scripts\servers.txt"
$results = foreach ($s in $servers) {
    Get-CimInstance Win32_OperatingSystem -ComputerName $s |
        Select-Object PSComputerName, Caption, Version, LastBootUpTime
}
$results | Export-Csv "C:\Reports\inventory.csv" -NoTypeInformation
```

---

## 📊 5. Performance Monitoring & Bottleneck Analysis

### Βασικοί Performance Counters που πρέπει να ξέρεις
| Counter | Τι δείχνει | Κρίσιμο κατώφλι |
|---|---|---|
| `\Processor(_Total)\% Processor Time` | Φόρτος CPU | >85% συνεχόμενα |
| `\Memory\Available MBytes` | Ελεύθερη μνήμη | <10% total RAM |
| `\PhysicalDisk(_Total)\Avg. Disk Queue Length` | Disk bottleneck | >2 ανά spindle |
| `\Network Interface\Bytes Total/sec` | Χρήση δικτύου | κοντά σε NIC limit |

### Καταγραφή με PowerShell
```powershell
Get-Counter -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 2 -MaxSamples 10
```

### Data Collector Sets (perfmon) για μακροχρόνια καταγραφή
```cmd
logman create counter PerfLog -c "\Processor(_Total)\% Processor Time" "\Memory\Available MBytes" -si 00:00:15 -o C:\PerfLogs\perflog.blg
logman start PerfLog
```

### Resource Monitor / Process Explorer
- `resmon.exe` → tab **Disk** για εντοπισμό process που "τρώει" I/O.
- Process Explorer (Sysinternals) → **Ctrl+Alt+H** για highlighting active processes σε real time.

---

## 💾 6. Backup & Disaster Recovery

### Windows Server Backup (system state)
```powershell
wbadmin start systemstatebackup -backuptarget:E:
wbadmin get versions
wbadmin start systemstaterecovery -version:<VersionID>
```

### VSS (Volume Shadow Copy) — έλεγχος & καθαρισμός
```cmd
vssadmin list shadows
vssadmin delete shadows /for=C: /oldest
```

### Authoritative Restore ενός AD object (πχ διαγραμμένο OU)
```powershell
ntdsutil
activate instance ntds
authoritative restore
restore subtree "OU=Sales,DC=contoso,DC=com"
```
> ⚠️ Χρειάζεται boot σε **DSRM (Directory Services Restore Mode)** πρώτα.

### Recycle Bin AD (soft-delete) — γρηγορότερη εναλλακτική
```powershell
Get-ADObject -Filter {displayName -eq "John Doe"} -IncludeDeletedObjects |
    Restore-ADObject
```

---

## 🔒 7. Security Hardening & LAPS

### LAPS (Local Administrator Password Solution)
```powershell
# Εγκατάσταση CSE στο client
msiexec /i LAPS.x64.msi /quiet

# Επέκταση AD schema
Import-Module AdmPwd.PS
Update-AdmPwdADSchema

# Ανάκτηση password από helpdesk
Get-AdmPwdPassword -ComputerName "PC01"
```

### Βασικό security baseline (CIS-style)
```powershell
# Απενεργοποίηση SMBv1
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol

# Enforce LSA protection
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" `
    -Name "RunAsPPL" -Value 1 -PropertyType DWord -Force

# Audit policy — λεπτομερής παρακολούθηση logon events
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
```

### Event IDs που αξίζει να παρακολουθείς
| Event ID | Σημασία |
|---|---|
| 4624 / 4625 | Επιτυχής / Αποτυχημένη σύνδεση |
| 4720 | Δημιουργία νέου χρήστη |
| 4732 | Προσθήκη μέλους σε security group |
| 4768 / 4769 | Kerberos TGT/Service ticket request |

---

## 📜 8. Certificate Services (PKI) Βασικά

```powershell
# Εγκατάσταση Enterprise Root CA role
Install-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools
Install-AdcsCertificationAuthority -CAType EnterpriseRootCA

# Έκδοση certificate template διαθέσιμου για auto-enrollment
certutil -SetCAtemplates +WebServer

# Ανανέωση/έλεγχος πιστοποιητικού από client
certutil -pulse
```
- **Root CA**: offline, καλύτερα σε απομονωμένο VM.
- **Subordinate/Issuing CA**: online, εκδίδει τα πραγματικά certificates.

---

## 🛠️ 9. WSUS & Patch Management

```powershell
# Έλεγχος κατάστασης WSUS server
Get-WsusServer | Get-WsusServerHealth

# Approve updates αυτόματα για ένα computer group
Get-WsusUpdate -Approval Unapproved -Classification Critical |
    Approve-WsusUpdate -Action Install -TargetGroupName "Servers"

# Force check-in στον client
wuauclt /detectnow /reportnow
```
- Ρύθμιση **GPO → Specify intranet Microsoft update service location** για να δείχνουν όλα τα clients στον WSUS.
- Χρήση **computer groups** για staged rollout (Pilot → Production).

---

## 🌍 10. Advanced Networking (Routing, VPN, IPAM)

### Static routing σε Windows Server
```powershell
New-NetRoute -DestinationPrefix "10.20.0.0/24" -NextHop 192.168.1.1 -InterfaceAlias "Ethernet"
```

### Site-to-Site VPN (RRAS) — γρήγορη εγκατάσταση
```powershell
Install-WindowsFeature RemoteAccess -IncludeManagementTools
Install-RemoteAccess -VpnType RoutingOnly
```

### IPAM (IP Address Management) role
```powershell
Install-WindowsFeature IPAM -IncludeManagementTools
Invoke-IpamGpoProvisioning -Domain contoso.com -GpoPrefixName IPAM
```
- Κεντρική διαχείριση IP ranges, DHCP scopes και DNS zones από ένα σημείο.

### Βασικά με Wireshark/netsh trace για troubleshooting
```cmd
netsh trace start capture=yes tracefile=C:\trace.etl
netsh trace stop
```

---

## 🎯 11. Real-World Troubleshooting Playbooks

### Playbook: "Ο χρήστης δεν μπορεί να συνδεθεί στο domain"
1. `ping DC01` → έλεγχος συνδεσιμότητας.
2. `nltest /sc_query:contoso.com` → έλεγχος secure channel.
3. Αν σπασμένο: `Test-ComputerSecureChannel -Repair`
4. Έλεγχος DNS client settings (`ipconfig /all` → σωστό DNS server;)
5. Έλεγχος ώρας συστήματος (Kerberos ανέχεται μόνο ±5 λεπτά skew).

### Playbook: "Server έχει high CPU χωρίς προφανή αιτία"
1. `Get-Process | Sort-Object CPU -Descending | Select -First 10`
2. Αν system process ψηλά → έλεγχος driver μέσω Process Explorer (system idle vs interrupts).
3. Έλεγχος Windows Update ή Defender full scan σε εξέλιξη.
4. `perfmon` → Data Collector Set για 24ωρη καταγραφή αν το πρόβλημα είναι διαλείπον.

### Playbook: "GPO εφαρμόζεται σε test OU αλλά όχι σε production"
1. `gpresult /h` στο production PC → έλεγχος "Denied GPOs".
2. Σύγκριση Security Filtering μεταξύ των δύο GPOs.
3. Έλεγχος αν υπάρχει conflicting GPO με υψηλότερο link order.
4. Έλεγχος replication μεταξύ DCs (`repadmin /replsummary`) — μήπως το GPO δεν έχει προλάβει να replicate.

### Playbook: "DNS resolution αργεί ή αποτυγχάνει διαλείποντα"
1. `nslookup <host> <dns-server>` σε κάθε DNS server ξεχωριστά.
2. Έλεγχος για stale/duplicate records → `dnscmd /ZoneInfo`
3. Έλεγχος scavenging ρυθμίσεων.
4. Έλεγχος forwarders (`Get-DnsServerForwarder`) για αργή upstream απόκριση.

---

## ⚡ 12. Quick Reference — Cheat Sheet

| Σενάριο | Εντολή |
|---|---|
| Replication health | `repadmin /replsummary` |
| Force GPO update | `gpupdate /force` |
| GPO report | `gpresult /h report.html` |
| DHCP failover status | `Get-DhcpServerv4Failover` |
| Remote session | `Enter-PSSession -ComputerName X` |
| Live perf counter | `Get-Counter "\Processor(_Total)\% Processor Time"` |
| System state backup | `wbadmin start systemstatebackup` |
| VSS shadow list | `vssadmin list shadows` |
| LAPS password | `Get-AdmPwdPassword -ComputerName X` |
| WSUS force check-in | `wuauclt /detectnow` |
| Static route add | `New-NetRoute` |
| Network trace | `netsh trace start capture=yes` |
| Secure channel repair | `Test-ComputerSecureChannel -Repair` |

---

*Μέρος του [Infrastructure Knowledge Base](https://github.com/Dimitriskatsanos42/Infrastructure-Knowledge-Base) — συμπληρωματικό στα `windows-commands-reference.md` και `windows-sysadmin-extra.md`, με έμφαση σε troubleshooting σενάρια, αυτοματοποίηση και αρχιτεκτονικές αποφάσεις.*
