# 🖥️ Windows Virtualization, Clustering & Infrastructure Services

Τέταρτο αρχείο της σειράς. Ενώ τα προηγούμενα καλύπτουν commands, extras και troubleshooting playbooks, αυτό εστιάζει σε **υποδομή σε επίπεδο enterprise**: virtualization, high availability, file/print services και hybrid identity — θέματα που ζητούνται συχνά σε πιο senior sysadmin/infra ρόλους.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Hyper-V Βασικά & Διαχείριση](#-1-hyper-v-βασικά--διαχείριση)
2. [Failover Clustering](#-2-failover-clustering)
3. [Storage Spaces & Storage Spaces Direct (S2D)](#-3-storage-spaces--storage-spaces-direct-s2d)
4. [DFS (Distributed File System)](#-4-dfs-distributed-file-system)
5. [File Server Resource Manager (FSRM)](#-5-file-server-resource-manager-fsrm)
6. [Network Load Balancing (NLB)](#-6-network-load-balancing-nlb)
7. [Remote Desktop Services (RDS)](#-7-remote-desktop-services-rds)
8. [NPS / RADIUS (802.1X Authentication)](#-8-nps--radius-8021x-authentication)
9. [Hybrid Identity — Azure AD Connect](#-9-hybrid-identity--azure-ad-connect)
10. [Sysinternals — Προχωρημένη Χρήση](#-10-sysinternals--προχωρημένη-χρήση)
11. [Real-World Scenarios](#-11-real-world-scenarios)
12. [Quick Reference — Cheat Sheet](#-12-quick-reference--cheat-sheet)

---

## 🧱 1. Hyper-V Βασικά & Διαχείριση

### Εγκατάσταση role
```powershell
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart
```

### Δημιουργία VM με PowerShell
```powershell
New-VM -Name "SRV-APP01" -MemoryStartupBytes 4GB -Generation 2 `
    -NewVHDPath "D:\VMs\SRV-APP01.vhdx" -NewVHDSizeBytes 60GB `
    -SwitchName "vSwitch-LAN"

Set-VMProcessor -VMName "SRV-APP01" -Count 2
Start-VM -Name "SRV-APP01"
```

### Virtual Switches
```powershell
# External switch — δίνει στα VMs πρόσβαση στο φυσικό δίκτυο
New-VMSwitch -Name "vSwitch-LAN" -NetAdapterName "Ethernet" -AllowManagementOS $true

# Internal switch — επικοινωνία host <-> VMs, όχι εξωτερικό δίκτυο
New-VMSwitch -Name "vSwitch-Internal" -SwitchType Internal
```

### Checkpoints (snapshots) — προσοχή σε production DCs
```powershell
Checkpoint-VM -Name "SRV-APP01" -SnapshotName "Before-Update"
Restore-VMSnapshot -VMName "SRV-APP01" -Name "Before-Update" -Confirm:$false
```
> ⚠️ Ποτέ checkpoints σε **Domain Controllers** χωρίς VM-Generation ID support — προκαλεί USN rollback.

### Live Migration (μεταξύ hosts σε cluster)
```powershell
Move-VM -Name "SRV-APP01" -DestinationHost "HV02" -IncludeStorage `
    -DestinationStoragePath "D:\VMs"
```

### Replica (DR σε δεύτερο site)
```powershell
Enable-VMReplication -VMName "SRV-APP01" -ReplicaServerName "HV-DR01" `
    -ReplicaServerPort 80 -AuthenticationType Kerberos
Start-VMInitialReplication -VMName "SRV-APP01"
```

---

## 🔗 2. Failover Clustering

### Δημιουργία cluster
```powershell
Install-WindowsFeature Failover-Clustering -IncludeManagementTools

Test-Cluster -Node "HV01","HV02" -Include "Storage Spaces Direct","Inventory","Network"

New-Cluster -Name "HV-Cluster01" -Node "HV01","HV02" `
    -StaticAddress 192.168.10.50 -NoStorage
```

### Cluster validation & health
```powershell
Get-ClusterNode
Get-ClusterResource
Test-Cluster -ReportName "C:\Reports\ClusterValidation.htm"
```

### Quorum configuration
```powershell
# Node Majority + File Share Witness (συνηθισμένο σε 2-node cluster)
Set-ClusterQuorum -NodeAndFileShareMajority "\\FileServer\Witness"
```

### Cluster-aware updating (CAU)
```powershell
Add-CauClusterRole -ClusterName "HV-Cluster01" -MaxFailedNodes 1 `
    -Force -DaysOfWeek Sunday -StartDate "2026-08-01"
```

---

## 💽 3. Storage Spaces & Storage Spaces Direct (S2D)

### Storage Spaces (τοπικά, single host)
```powershell
New-StoragePool -FriendlyName "Pool01" -StorageSubSystemFriendlyName "Storage Spaces*" `
    -PhysicalDisks (Get-PhysicalDisk -CanPool $true)

New-VirtualDisk -StoragePoolFriendlyName "Pool01" -FriendlyName "vDisk01" `
    -ResiliencySettingName Mirror -Size 500GB

New-Volume -DiskNumber 2 -FriendlyName "Data" -FileSystem ReFS -DriveLetter D
```

### Storage Spaces Direct (S2D) — hyperconverged cluster
```powershell
Enable-ClusterStorageSpacesDirect -CimSession "HV-Cluster01"
Get-StoragePool
Get-VirtualDisk
```
- Χρησιμοποιεί local disks από κάθε node σαν ένα ενιαίο shared storage pool.
- Ιδανικό για Hyper-V clusters χωρίς εξωτερικό SAN.

---

## 📁 4. DFS (Distributed File System)

### DFS Namespaces
```powershell
Install-WindowsFeature FS-DFS-Namespace -IncludeManagementTools

New-DfsnRoot -TargetPath "\\SRV01\Public" -Type DomainV2 -Path "\\contoso.com\Public"
New-DfsnFolder -Path "\\contoso.com\Public\Docs" -TargetPath "\\SRV01\Docs"
```

### DFS Replication (multi-site sync)
```powershell
Install-WindowsFeature FS-DFS-Replication -IncludeManagementTools

New-DfsReplicationGroup -GroupName "HQ-Branch-Sync"
New-DfsReplicatedFolder -GroupName "HQ-Branch-Sync" -FolderName "Shared"
Add-DfsrMember -GroupName "HQ-Branch-Sync" -ComputerName "SRV01","SRV-BRANCH01"
```

### Έλεγχος replication backlog
```powershell
Get-DfsrBacklog -GroupName "HQ-Branch-Sync" -FolderName "Shared" `
    -SourceComputerName "SRV01" -DestinationComputerName "SRV-BRANCH01"
```

---

## 📊 5. File Server Resource Manager (FSRM)

### Quota management
```powershell
Install-WindowsFeature FS-Resource-Manager -IncludeManagementTools

New-FsrmQuota -Path "D:\Shares\UserHome" -Size 5GB -SoftLimit
```

### File screening (αποκλεισμός τύπων αρχείων, πχ .exe, .mp3)
```powershell
New-FsrmFileGroup -Name "Blocked Files" -IncludePattern "*.exe","*.mp3"
New-FsrmFileScreen -Path "D:\Shares\UserHome" -IncludeGroup "Blocked Files"
```

### Storage reports
```powershell
New-FsrmStorageReport -Name "WeeklyUsage" -ReportType DuplicateFiles,LargeFiles `
    -Namespace "D:\Shares" -Schedule (New-FsrmScheduledTask -Time "06:00" -Weekly Monday)
```

---

## ⚖️ 6. Network Load Balancing (NLB)

```powershell
Install-WindowsFeature NLB -IncludeManagementTools

New-NlbCluster -InterfaceName "Ethernet" -ClusterName "WebCluster" `
    -ClusterPrimaryIP 192.168.10.100 -SubnetMask 255.255.255.0

Add-NlbClusterNode -NewNodeName "WEB02" -NewNodeInterface "Ethernet"
```
- Χρησιμοποιείται για stateless workloads (web servers, VPN gateways).
- Για stateful workloads (SQL, file services) → **Failover Clustering** αντί για NLB.

---

## 🖧 7. Remote Desktop Services (RDS)

### Βασική εγκατάσταση (session-based deployment)
```powershell
Install-WindowsFeature RDS-RD-Server,RDS-Licensing,RDS-Connection-Broker `
    -IncludeManagementTools

New-RDSessionDeployment -ConnectionBroker "RDCB01.contoso.com" `
    -WebAccessServer "RDWEB01.contoso.com" -SessionHost "RDSH01.contoso.com"
```

### RemoteApp publishing
```powershell
New-RDRemoteApp -Alias "Notepad" -DisplayName "Notepad" `
    -FilePath "C:\Windows\System32\notepad.exe" `
    -CollectionName "MainCollection"
```

### Licensing mode
```powershell
Set-RDLicenseConfiguration -LicenseServer "RDLIC01" -Mode PerUser -ConnectionBroker "RDCB01"
```

---

## 🔐 8. NPS / RADIUS (802.1X Authentication)

```powershell
Install-WindowsFeature NPAS -IncludeManagementTools

# Καταχώρηση RADIUS client (πχ wireless controller ή switch)
New-NpsRadiusClient -Name "WiFi-Controller" -Address 192.168.1.10 `
    -SharedSecret "StrongSecretHere"
```
- Χρησιμοποιείται για **802.1X** authentication σε wired/wireless δίκτυα και VPN.
- Συνεργάζεται με AD για user/computer certificate-based authentication (μαζί με PKI/AD CS).

---

## ☁️ 9. Hybrid Identity — Azure AD Connect

### Concept
- Συγχρονίζει on-prem Active Directory με **Microsoft Entra ID (Azure AD)**.
- Επιτρέπει **Single Sign-On** μεταξύ on-prem και cloud apps (Microsoft 365, Azure).

### Βασικά PowerShell commands (μετά την εγκατάσταση του Azure AD Connect)
```powershell
# Έλεγχος κατάστασης sync
Get-ADSyncScheduler

# Εξαναγκασμός sync cycle
Start-ADSyncSyncCycle -PolicyType Delta

# Έλεγχος τελευταίου sync error
Get-ADSyncConnectorRunStatus
```

### Password Hash Sync vs Pass-Through Authentication
| Μέθοδος | Πλεονέκτημα | Μειονέκτημα |
|---|---|---|
| Password Hash Sync (PHS) | Απλό, χωρίς επιπλέον υποδομή | Χρειάζεται sync του hash στο cloud |
| Pass-Through Auth (PTA) | Password validation on-prem | Χρειάζεται πάντα connector agent online |
| Federation (AD FS) | Πλήρης έλεγχος on-prem | Πιο πολύπλοκο, extra υποδομή |

---

## 🧰 10. Sysinternals — Προχωρημένη Χρήση

| Εργαλείο | Χρήση |
|---|---|
| **Process Explorer** | Real-time process tree, DLL/handle inspection |
| **Process Monitor (ProcMon)** | Καταγραφή file/registry/process activity — ιδανικό για "γιατί κολλάει αυτή η εφαρμογή" |
| **Autoruns** | Πλήρης λίστα όλων των startup items (πολύ πιο αναλυτικό από `msconfig`) |
| **PsExec** | Remote command execution χωρίς RDP |
| **Sigcheck** | Έλεγχος ψηφιακής υπογραφής εκτελέσιμων |
| **TCPView** | Real-time δικτυακές συνδέσεις ανά process |

### Παράδειγμα: εντοπισμός process που κλειδώνει αρχείο
```
Process Explorer → Find → Find Handle or DLL → πληκτρολόγησε το όνομα αρχείου
```

### PsExec — remote εκτέλεση εντολής
```cmd
PsExec.exe \\SRV01 -u DOMAIN\admin -p ******** ipconfig /all
```

---

## 🎯 11. Real-World Scenarios

### Σενάριο: "Χρειάζεται high availability για file server χωρίς SAN"
→ **Storage Spaces Direct (S2D) + Failover Clustering** σε 2+ nodes, με local NVMe/SSD disks.

### Σενάριο: "Δύο branch offices πρέπει να μοιράζονται τα ίδια shared documents"
→ **DFS Namespace** (ενιαίο namespace) + **DFS Replication** (multi-site sync) με στοχευμένο replication schedule ώστε να μην κορεστεί το WAN link.

### Σενάριο: "Οι χρήστες πρέπει να τρέχουν ένα legacy app χωρίς τοπική εγκατάσταση"
→ **RDS με RemoteApp publishing** — το app φαίνεται σαν τοπικό αλλά τρέχει στον RDSH server.

### Σενάριο: "Θέλουμε SSO μεταξύ on-prem AD και Microsoft 365"
→ **Azure AD Connect** με Password Hash Sync (πιο απλό) ή Pass-Through Authentication (αν χρειάζεται password validation on-prem, πχ λόγω custom password policies).

### Σενάριο: "Wireless clients πρέπει να κάνουν authenticate με domain credentials"
→ **NPS (RADIUS) + 802.1X** στο wireless controller, integrated με AD.

---

## ⚡ 12. Quick Reference — Cheat Sheet

| Σενάριο | Εντολή |
|---|---|
| Νέο VM | `New-VM -Name X -MemoryStartupBytes 4GB` |
| Live migration | `Move-VM -Name X -DestinationHost Y` |
| Cluster validation | `Test-Cluster -Node A,B` |
| Quorum config | `Set-ClusterQuorum` |
| Storage pool | `New-StoragePool` |
| DFS namespace | `New-DfsnRoot` |
| DFS backlog check | `Get-DfsrBacklog` |
| FSRM quota | `New-FsrmQuota` |
| NLB cluster | `New-NlbCluster` |
| RDS RemoteApp | `New-RDRemoteApp` |
| RADIUS client | `New-NpsRadiusClient` |
| Azure AD sync status | `Get-ADSyncScheduler` |
| Force AAD sync | `Start-ADSyncSyncCycle -PolicyType Delta` |
| Remote exec | `PsExec.exe \\host cmd` |

---

*Μέρος του [Infrastructure Knowledge Base](https://github.com/Dimitriskatsanos42/Infrastructure-Knowledge-Base) — καλύπτει virtualization, high availability, file/print/identity infrastructure. Συμπληρωματικό στα `windows-commands-reference.md`, `windows-sysadmin-extra.md` και `windows-advanced-troubleshooting-automation.md`.*
