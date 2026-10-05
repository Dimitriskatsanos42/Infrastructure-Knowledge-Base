<#
.SYNOPSIS
    Παρακολουθεί Windows services και τα ξεκινά αυτόματα αν έχουν σταματήσει.
.PARAMETER ServiceNames
    Λίστα με ονόματα services (π.χ. Spooler, W32Time, WinRM).
.PARAMETER LogPath
    Αρχείο καταγραφής ενεργειών.
.EXAMPLE
    .\service-monitor.ps1 -ServiceNames Spooler,W32Time,WinRM
.NOTES
    Απαιτεί εκτέλεση ως Administrator για την εκκίνηση services.
#>
param(
    [Parameter(Mandatory)][string[]]$ServiceNames,
    [string]$LogPath = "$env:TEMP\service-monitor.log"
)

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $line = "{0} [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path $LogPath -Value $line
    $color = switch ($Level) { 'ERROR' {'Red'} 'WARN' {'Yellow'} 'FIXED' {'Cyan'} default {'Green'} }
    Write-Host $line -ForegroundColor $color
}

foreach ($name in $ServiceNames) {
    $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
    if (-not $svc) { Write-Log "Το service '$name' δεν βρέθηκε." 'ERROR'; continue }

    if ($svc.Status -eq 'Running') {
        Write-Log "$name τρέχει κανονικά."
        continue
    }

    Write-Log "$name βρίσκεται σε κατάσταση '$($svc.Status)'. Προσπάθεια εκκίνησης..." 'WARN'
    try {
        Start-Service -Name $name -ErrorAction Stop
        $svc.WaitForStatus('Running', [TimeSpan]::FromSeconds(15))
        Write-Log "$name ξεκίνησε με επιτυχία." 'FIXED'
    }
    catch {
        Write-Log "Αποτυχία εκκίνησης $name : $($_.Exception.Message)" 'ERROR'
    }
}
