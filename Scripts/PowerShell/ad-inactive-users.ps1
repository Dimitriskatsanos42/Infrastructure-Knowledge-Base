<#
.SYNOPSIS
    Εντοπίζει ανενεργούς λογαριασμούς χρηστών στο Active Directory.
.PARAMETER DaysInactive
    Ημέρες χωρίς σύνδεση (προεπιλογή 90).
.PARAMETER Disable
    Αν δοθεί, απενεργοποιεί τους λογαριασμούς (με επιβεβαίωση).
.PARAMETER ExportPath
    Εξαγωγή αποτελεσμάτων σε CSV.
.EXAMPLE
    .\ad-inactive-users.ps1 -DaysInactive 120 -ExportPath C:\Reports\inactive.csv
.NOTES
    Απαιτεί το module ActiveDirectory (RSAT).
#>
param(
    [int]$DaysInactive = 90,
    [switch]$Disable,
    [string]$ExportPath
)

Import-Module ActiveDirectory -ErrorAction Stop

$inactive = Search-ADAccount -AccountInactive -UsersOnly -TimeSpan ([TimeSpan]::FromDays($DaysInactive)) |
    Where-Object { $_.Enabled } |
    Select-Object Name, SamAccountName, LastLogonDate, DistinguishedName |
    Sort-Object LastLogonDate

Write-Host "Βρέθηκαν $($inactive.Count) ενεργοί λογαριασμοί χωρίς σύνδεση για $DaysInactive+ ημέρες.`n" -ForegroundColor Cyan
$inactive | Format-Table Name, SamAccountName, LastLogonDate -AutoSize

if ($ExportPath) {
    $inactive | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
    Write-Host "Εξαγωγή σε: $ExportPath" -ForegroundColor Green
}

if ($Disable -and $inactive) {
    foreach ($u in $inactive) {
        Disable-ADAccount -Identity $u.SamAccountName -Confirm:$true -WhatIf:$false
    }
}
