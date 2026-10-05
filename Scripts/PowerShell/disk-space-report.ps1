<#
.SYNOPSIS
    Αναφορά χώρου δίσκων με χρωματική ένδειξη και προαιρετική εξαγωγή σε CSV.
.PARAMETER WarningPercent
    Όριο προειδοποίησης για χρησιμοποιούμενο χώρο (προεπιλογή 80).
.PARAMETER ExportPath
    Αν δοθεί, αποθηκεύει την αναφορά σε αρχείο CSV.
.EXAMPLE
    .\disk-space-report.ps1 -WarningPercent 85 -ExportPath C:\Reports\disks.csv
#>
param(
    [int]$WarningPercent = 80,
    [string]$ExportPath
)

$report = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $usedPct = [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 1)
    [PSCustomObject]@{
        Computer  = $env:COMPUTERNAME
        Drive     = $_.DeviceID
        Label     = $_.VolumeName
        SizeGB    = [math]::Round($_.Size / 1GB, 2)
        FreeGB    = [math]::Round($_.FreeSpace / 1GB, 2)
        UsedPct   = $usedPct
        Status    = if ($usedPct -ge $WarningPercent) { 'WARNING' } else { 'OK' }
    }
}

foreach ($d in $report) {
    $color = if ($d.Status -eq 'WARNING') { 'Red' } else { 'Green' }
    Write-Host ("{0} {1,6}% used | {2,8} GB free of {3,8} GB  [{4}]" -f $d.Drive, $d.UsedPct, $d.FreeGB, $d.SizeGB, $d.Status) -ForegroundColor $color
}

if ($ExportPath) {
    $report | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
    Write-Host "`nΗ αναφορά αποθηκεύτηκε στο: $ExportPath" -ForegroundColor Cyan
}
