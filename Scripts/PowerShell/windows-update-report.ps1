<#
.SYNOPSIS
    Αναφορά ενημερώσεων Windows: τελευταία hotfixes, εκκρεμής επανεκκίνηση,
    κατάσταση υπηρεσίας Windows Update.
.EXAMPLE
    .\windows-update-report.ps1
#>

Write-Host "`n=== Windows Update Report - $env:COMPUTERNAME ===" -ForegroundColor Cyan
$os = Get-CimInstance Win32_OperatingSystem
Write-Host "OS      : $($os.Caption) (Build $($os.BuildNumber))"
Write-Host "Boot    : $($os.LastBootUpTime)"

Write-Host "`n--- Υπηρεσία Windows Update ---" -ForegroundColor Cyan
Get-Service wuauserv, BITS, CryptSvc | Select-Object Name, Status, StartType | Format-Table -AutoSize

Write-Host "--- Τελευταίες 10 ενημερώσεις ---" -ForegroundColor Cyan
Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 10 HotFixID, Description, InstalledOn, InstalledBy | Format-Table -AutoSize

Write-Host "--- Εκκρεμής επανεκκίνηση ---" -ForegroundColor Cyan
$pending = @(
    (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'),
    (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'),
    ($null -ne (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name PendingFileRenameOperations -ErrorAction SilentlyContinue))
) -contains $true

if ($pending) { Write-Host "[!] Απαιτείται επανεκκίνηση." -ForegroundColor Yellow }
else          { Write-Host "Δεν απαιτείται επανεκκίνηση." -ForegroundColor Green }

$last = (Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1).InstalledOn
if ($last -and $last -lt (Get-Date).AddDays(-60)) {
    Write-Host "`n[!] Η τελευταία ενημέρωση εγκαταστάθηκε πριν από περισσότερες από 60 ημέρες ($last)." -ForegroundColor Yellow
}
