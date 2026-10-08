<#
.SYNOPSIS
    Audit τοπικών λογαριασμών και ομάδων σε Windows.
.DESCRIPTION
    Εμφανίζει τοπικούς χρήστες, κατάσταση λογαριασμών, μέλη των Administrators
    και λογαριασμούς χωρίς λήξη κωδικού.
.EXAMPLE
    .\local-user-audit.ps1 -ExportPath C:\Reports\users.csv
.NOTES
    Εκτελέστε ως Administrator.
#>
param([string]$ExportPath)

Write-Host "`n=== Τοπικοί Χρήστες ===" -ForegroundColor Cyan
$users = Get-LocalUser | Select-Object Name, Enabled, LastLogon, PasswordLastSet, PasswordExpires, PasswordRequired
$users | Format-Table -AutoSize

Write-Host "=== Μέλη της ομάδας Administrators ===" -ForegroundColor Cyan
Get-LocalGroupMember -Group 'Administrators' | Select-Object Name, ObjectClass, PrincipalSource | Format-Table -AutoSize

Write-Host "=== Ενεργοί λογαριασμοί που δεν απαιτούν κωδικό ===" -ForegroundColor Yellow
$noPwd = $users | Where-Object { $_.Enabled -and -not $_.PasswordRequired }
if ($noPwd) { $noPwd | Format-Table -AutoSize } else { Write-Host "  Κανένας." -ForegroundColor Green }

Write-Host "=== Ενεργοί λογαριασμοί που δεν λήγει ο κωδικός ===" -ForegroundColor Yellow
$noExpiry = $users | Where-Object { $_.Enabled -and -not $_.PasswordExpires }
if ($noExpiry) { $noExpiry | Format-Table -AutoSize } else { Write-Host "  Κανένας." -ForegroundColor Green }

if ($ExportPath) {
    $users | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
    Write-Host "`nΕξαγωγή σε: $ExportPath" -ForegroundColor Cyan
}
