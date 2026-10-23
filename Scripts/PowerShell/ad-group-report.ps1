<#
.SYNOPSIS
    Αναφορά μελών ομάδας Active Directory (με εμφωλευμένες ομάδες).
.PARAMETER GroupName
    Όνομα ομάδας AD.
.PARAMETER ExportPath
    Προαιρετική εξαγωγή σε CSV.
.EXAMPLE
    .\ad-group-report.ps1 -GroupName "Domain Admins"
#>
param(
    [Parameter(Mandatory)][string]$GroupName,
    [string]$ExportPath
)

Import-Module ActiveDirectory -ErrorAction Stop

try { $null = Get-ADGroup -Identity $GroupName -ErrorAction Stop }
catch { Write-Error "Η ομάδα '$GroupName' δεν βρέθηκε."; exit 1 }

$members = Get-ADGroupMember -Identity $GroupName -Recursive |
    Where-Object objectClass -eq 'user' |
    Get-ADUser -Properties DisplayName, Enabled, LastLogonDate, EmailAddress |
    Select-Object DisplayName, SamAccountName, EmailAddress, Enabled, LastLogonDate |
    Sort-Object DisplayName

Write-Host "Ομάδα: $GroupName - Σύνολο μελών: $($members.Count)`n" -ForegroundColor Cyan
$members | Format-Table -AutoSize

if ($ExportPath) {
    $members | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
    Write-Host "Εξαγωγή σε: $ExportPath" -ForegroundColor Green
}
