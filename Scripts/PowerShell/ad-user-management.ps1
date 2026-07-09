<#
.SYNOPSIS
    ad-user-management.ps1 — Bulk δημιουργία/διαχείριση χρηστών σε Active Directory.

.DESCRIPTION
    Διαβάζει ένα CSV αρχείο με στοιχεία χρηστών και εκτελεί μαζικές (bulk)
    ενέργειες σε Active Directory: δημιουργία, ενημέρωση, απενεργοποίηση
    ή διαγραφή χρηστών. Κρατάει log αρχείο με αποτελέσματα και σφάλματα.

.PARAMETER CsvPath
    Διαδρομή προς το CSV αρχείο εισόδου.

.PARAMETER Action
    Η ενέργεια που θα εκτελεστεί: Create, Update, Disable, Delete.

.PARAMETER LogPath
    Φάκελος όπου θα αποθηκεύονται τα log αρχεία. Προεπιλογή: .\logs

.PARAMETER WhatIf
    Αν οριστεί, το script μόνο δείχνει τι θα έκανε, χωρίς να εκτελέσει
    πραγματικές αλλαγές στο AD (dry-run).

.EXAMPLE
    .\ad-user-management.ps1 -CsvPath .\users.csv -Action Create

.EXAMPLE
    .\ad-user-management.ps1 -CsvPath .\users.csv -Action Disable -WhatIf

.NOTES
    Απαιτείται το module ActiveDirectory (RSAT) και κατάλληλα δικαιώματα.

    Αναμενόμενες στήλες στο CSV (για Create):
        FirstName,LastName,SamAccountName,Department,Title,OU,Password

    Παράδειγμα CSV:
        FirstName,LastName,SamAccountName,Department,Title,OU,Password
        Γιώργος,Παπαδόπουλος,gpapadopoulos,IT,Sys Admin,"OU=IT,DC=company,DC=local",P@ssw0rd123!
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$CsvPath,

    [Parameter(Mandatory = $true)]
    [ValidateSet('Create', 'Update', 'Disable', 'Delete')]
    [string]$Action,

    [string]$LogPath = ".\logs",

    [switch]$WhatIfMode
)

# ---------------------------------------------------------------
# Αρχικοποίηση
# ---------------------------------------------------------------
$ErrorActionPreference = 'Stop'

# Έλεγχος module ActiveDirectory
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Error "Το module ActiveDirectory δεν είναι εγκατεστημένο. Εγκαταστήστε το RSAT."
    exit 1
}
Import-Module ActiveDirectory -ErrorAction Stop

# Δημιουργία φακέλου logs
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath | Out-Null
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile   = Join-Path $LogPath "ad-user-management_$timestamp.log"
$reportCsv = Join-Path $LogPath "ad-user-management_report_$timestamp.csv"

$results = @()

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Write-Host $line
    Add-Content -Path $logFile -Value $line
}

# ---------------------------------------------------------------
# Φόρτωση CSV
# ---------------------------------------------------------------
Write-Log "Φόρτωση CSV: $CsvPath"
$users = Import-Csv -Path $CsvPath

if (-not $users -or $users.Count -eq 0) {
    Write-Log "Το CSV δεν περιέχει εγγραφές." "WARN"
    exit 0
}

Write-Log "Βρέθηκαν $($users.Count) εγγραφές. Ενέργεια: $Action. WhatIf: $($WhatIfMode.IsPresent)"

# ---------------------------------------------------------------
# Συναρτήσεις ανά ενέργεια
# ---------------------------------------------------------------

function New-ADUserFromRow {
    param($Row)

    $displayName = "$($Row.FirstName) $($Row.LastName)"
    $upn         = "$($Row.SamAccountName)@$((Get-ADDomain).DNSRoot)"

    if (Get-ADUser -Filter "SamAccountName -eq '$($Row.SamAccountName)'" -ErrorAction SilentlyContinue) {
        Write-Log "Ο χρήστης $($Row.SamAccountName) υπάρχει ήδη — παράλειψη." "WARN"
        return [PSCustomObject]@{ SamAccountName = $Row.SamAccountName; Status = "Skipped (exists)" }
    }

    $securePwd = ConvertTo-SecureString $Row.Password -AsPlainText -Force

    $params = @{
        Name                  = $displayName
        GivenName             = $Row.FirstName
        Surname               = $Row.LastName
        SamAccountName        = $Row.SamAccountName
        UserPrincipalName     = $upn
        Department            = $Row.Department
        Title                 = $Row.Title
        Path                  = $Row.OU
        AccountPassword       = $securePwd
        Enabled               = $true
        ChangePasswordAtLogon = $true
    }

    if ($WhatIfMode) {
        Write-Log "[WhatIf] Θα δημιουργούνταν χρήστης: $($Row.SamAccountName) στο OU: $($Row.OU)"
        return [PSCustomObject]@{ SamAccountName = $Row.SamAccountName; Status = "WhatIf-Create" }
    }

    try {
        New-ADUser @params
        Write-Log "Δημιουργήθηκε ο χρήστης: $($Row.SamAccountName)"
        return [PSCustomObject]@{ SamAccountName = $Row.SamAccountName; Status = "Created" }
    }
    catch {
        Write-Log "ΣΦΑΛΜΑ κατά τη δημιουργία $($Row.SamAccountName): $($_.Exception.Message)" "ERROR"
        return [PSCustomObject]@{ SamAccountName = $Row.SamAccountName; Status = "Error: $($_.Exception.Message)" }
    }
}

function Update-ADUserFromRow {
    param($Row)

    if (-not (Get-ADUser -Filter "SamAccountName -eq '$($Row.SamAccountName)'" -ErrorAction SilentlyContinue)) {
        Write-Log "Ο χρήστης $($Row.SamAccountName) δεν βρέθηκε — παράλειψη." "WARN"
        return [PSCustomObject]@{ SamAccountName = $Row.SamAccountName; Status = "Skipped (not found)" }
    }

    if ($WhatIfMode) {
        Write-Log "[WhatIf] Θα ενημερωνόταν ο χρήστης: $($Row.SamAccountName)"
        return [PSCustomObject]@{ SamAccountName = $Row.SamAccountName; Status = "WhatIf-Update" }
    }

    try {
        Set-ADUser -Identity $Row.SamAccountName -Department $Row.Department -Title $Row.Title
        Write-Log "Ενημερώθηκε ο χρήστης: $($Row.SamAccountName)"
        return [PSCustomObject]@{ SamAccountName = $Row.SamAccountName; Status = "Updated" }
    }
    catch {
        Write-Log "ΣΦΑΛΜΑ κατά την ενημέρωση $($Row.SamAccountName): $($_.Exception.Message)" "ERROR"
        return [PSCustomObject]@{ SamAccountName = $Row.SamAccountName; Status = "Error: $($_.Exception.Message)" }
    }
}

function Disable-ADUserFromRow {
    param($Row)

    if (-not (Get-ADUser -Filter "SamAccountName -eq '$($Row.SamAccountName)'" -ErrorAction SilentlyContinue)) {
        Write-Log "Ο χρήστης $($Row.SamAccountName) δεν βρέθηκε — παράλειψη." "WARN"
        return [PSCustomObject]@{ SamAccountName = $Row.SamAccountName; Status = "Skipped (not found)" }
    }

    if ($WhatIfMode) {
        Write-Log "[WhatIf] Θα απενεργοποιούνταν ο χρήστης: $($Row.SamAccountName)"
        return [PSCustomObject]@{ SamAccountName = $Row.SamAccountName; Status = "WhatIf-Disable" }
    }

    try {
        Disable-ADAccount -Identity $Row.SamAccountName
        Write-Log "Απενεργοποιήθηκε ο χρήστης: $($Row.SamAccountName)"
        return [PSCustomObject]@{ SamAccountName = $Row.SamAccountName; Status = "Disabled" }
    }
    catch {
        Write-Log "ΣΦΑΛΜΑ κατά την απενεργοποίηση $($Row.SamAccountName): $($_.Exception.Message)" "ERROR"
        return [PSCustomObject]@{ SamAccountName = $Row.SamAccountName; Status = "Error: $($_.Exception.Message)" }
    }
}

function Remove-ADUserFromRow {
    param($Row)

    if (-not (Get-ADUser -Filter "SamAccountName -eq '$($Row.SamAccountName)'" -ErrorAction SilentlyContinue)) {
        Write-Log "Ο χρήστης $($Row.SamAccountName) δεν βρέθηκε — παράλειψη." "WARN"
        return [PSCustomObject]@{ SamAccountName = $Row.SamAccountName; Status = "Skipped (not found)" }
    }

    if ($WhatIfMode) {
        Write-Log "[WhatIf] Θα διαγραφόταν ο χρήστης: $($Row.SamAccountName)"
        return [PSCustomObject]@{ SamAccountName = $Row.SamAccountName; Status = "WhatIf-Delete" }
    }

    try {
        Remove-ADUser -Identity $Row.SamAccountName -Confirm:$false
        Write-Log "Διαγράφηκε ο χρήστης: $($Row.SamAccountName)"
        return [PSCustomObject]@{ SamAccountName = $Row.SamAccountName; Status = "Deleted" }
    }
    catch {
        Write-Log "ΣΦΑΛΜΑ κατά τη διαγραφή $($Row.SamAccountName): $($_.Exception.Message)" "ERROR"
        return [PSCustomObject]@{ SamAccountName = $Row.SamAccountName; Status = "Error: $($_.Exception.Message)" }
    }
}

# ---------------------------------------------------------------
# Κύριος βρόχος εκτέλεσης
# ---------------------------------------------------------------
foreach ($row in $users) {

    if (-not $row.SamAccountName) {
        Write-Log "Παράλειψη εγγραφής χωρίς SamAccountName." "WARN"
        continue
    }

    $result = switch ($Action) {
        'Create'  { New-ADUserFromRow     -Row $row }
        'Update'  { Update-ADUserFromRow  -Row $row }
        'Disable' { Disable-ADUserFromRow -Row $row }
        'Delete'  { Remove-ADUserFromRow  -Row $row }
    }

    $results += $result
}

# ---------------------------------------------------------------
# Αναφορά αποτελεσμάτων
# ---------------------------------------------------------------
$results | Export-Csv -Path $reportCsv -NoTypeInformation -Encoding UTF8

$summary = $results | Group-Object Status | Select-Object Name, Count
Write-Log "=== Σύνοψη ==="
$summary | ForEach-Object { Write-Log ("{0}: {1}" -f $_.Name, $_.Count) }

Write-Log "Ολοκληρώθηκε. Αναφορά: $reportCsv"
Write-Log "Log αρχείο: $logFile"
