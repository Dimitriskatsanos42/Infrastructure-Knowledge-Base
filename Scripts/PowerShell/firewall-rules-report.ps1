<#
.SYNOPSIS
    Αναφορά Windows Firewall: προφίλ και ενεργοί κανόνες εισερχομένων.
.PARAMETER ExportPath
    Προαιρετική εξαγωγή των κανόνων σε CSV.
.EXAMPLE
    .\firewall-rules-report.ps1 -ExportPath C:\Reports\fw.csv
#>
param([string]$ExportPath)

Write-Host "`n=== Προφίλ Firewall ===" -ForegroundColor Cyan
Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction | Format-Table -AutoSize

$rules = Get-NetFirewallRule -Direction Inbound -Enabled True -Action Allow | ForEach-Object {
    $port = $_ | Get-NetFirewallPortFilter
    $app  = $_ | Get-NetFirewallApplicationFilter
    [PSCustomObject]@{
        Name      = $_.DisplayName
        Profile   = $_.Profile
        Protocol  = $port.Protocol
        LocalPort = $port.LocalPort
        Program   = $app.Program
    }
}

Write-Host "=== Ενεργοί κανόνες Allow Inbound: $($rules.Count) ===" -ForegroundColor Cyan
$rules | Sort-Object Name | Select-Object -First 25 | Format-Table -AutoSize

Write-Host "=== Κανόνες που ανοίγουν συγκεκριμένες θύρες ===" -ForegroundColor Yellow
$rules | Where-Object { $_.LocalPort -ne 'Any' } | Sort-Object LocalPort | Select-Object -First 25 | Format-Table -AutoSize

if ($ExportPath) {
    $rules | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
    Write-Host "Εξαγωγή σε: $ExportPath" -ForegroundColor Green
}
