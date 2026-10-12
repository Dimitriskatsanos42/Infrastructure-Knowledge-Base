<#
.SYNOPSIS
    Αντίγραφο ασφαλείας φακέλου με robocopy, ημερομηνία στον φάκελο προορισμού
    και αυτόματη διαγραφή παλιών backups.
.PARAMETER Source
    Φάκελος προέλευσης.
.PARAMETER DestinationRoot
    Φάκελος όπου θα δημιουργηθούν τα backups.
.PARAMETER KeepDays
    Πόσες ημέρες διατηρούνται τα backups (προεπιλογή 14).
.EXAMPLE
    .\file-backup.ps1 -Source C:\Data -DestinationRoot D:\Backups -KeepDays 30
#>
param(
    [Parameter(Mandatory)][string]$Source,
    [Parameter(Mandatory)][string]$DestinationRoot,
    [int]$KeepDays = 14
)

if (-not (Test-Path $Source)) { Write-Error "Ο φάκελος προέλευσης '$Source' δεν υπάρχει."; exit 1 }

$stamp  = Get-Date -Format 'yyyy-MM-dd_HH-mm'
$dest   = Join-Path $DestinationRoot "backup_$stamp"
$logDir = Join-Path $DestinationRoot 'logs'
New-Item -ItemType Directory -Path $dest, $logDir -Force | Out-Null
$log = Join-Path $logDir "backup_$stamp.log"

Write-Host "Έναρξη backup: $Source -> $dest" -ForegroundColor Cyan
robocopy $Source $dest /E /R:2 /W:5 /NP /LOG:$log | Out-Null

# Robocopy exit codes 0-7 = επιτυχία, 8+ = σφάλμα
if ($LASTEXITCODE -lt 8) {
    Write-Host "Το backup ολοκληρώθηκε επιτυχώς. Log: $log" -ForegroundColor Green
} else {
    Write-Host "Σφάλμα backup (robocopy code $LASTEXITCODE). Δείτε το log: $log" -ForegroundColor Red
    exit $LASTEXITCODE
}

# Εκκαθάριση παλιών backups
Get-ChildItem $DestinationRoot -Directory -Filter 'backup_*' |
    Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-$KeepDays) } |
    ForEach-Object {
        Write-Host "Διαγραφή παλιού backup: $($_.Name)" -ForegroundColor Yellow
        Remove-Item $_.FullName -Recurse -Force
    }
