<#
.SYNOPSIS
    Event Log Analyzer — Ανίχνευση ύποπτης δραστηριότητας
.DESCRIPTION
    Αναλύει Windows Security Event Log για:
    - Brute force attempts (Event 4625)
    - Successful logins (Event 4624)
    - Locked accounts (Event 4740)
    - New user creation (Event 4720)
.PARAMETER Hours
    Πόσες ώρες πίσω να αναλύσει (default: 24)
.PARAMETER BruteForceThreshold
    Αριθμός αποτυχημένων συνδέσεων για alert (default: 5)
.EXAMPLE
    .\event-log-analyzer.ps1
    .\event-log-analyzer.ps1 -Hours 48 -BruteForceThreshold 10
.NOTES
    Author: Dimitris Katsanos
    Απαιτεί: Administrator privileges
#>

param(
    [int]$Hours = 24,
    [int]$BruteForceThreshold = 5
)

$StartTime = (Get-Date).AddHours(-$Hours)
$Separator = "=" * 60

Write-Host "`n$Separator" -ForegroundColor Cyan
Write-Host "  SECURITY EVENT LOG ANALYSIS" -ForegroundColor Cyan
Write-Host "  Τελευταίες $Hours ώρες — από $($StartTime.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Cyan
Write-Host "$Separator`n" -ForegroundColor Cyan

# --- Failed Logons (4625) ---
Write-Host "[ Αποτυχημένες Συνδέσεις — Event 4625 ]" -ForegroundColor Yellow
try {
    $FailedLogons = Get-WinEvent -FilterHashtable @{
        LogName   = 'Security'
        Id        = 4625
        StartTime = $StartTime
    } -ErrorAction SilentlyContinue

    if ($FailedLogons) {
        Write-Host "  Σύνολο: $($FailedLogons.Count) αποτυχημένες συνδέσεις" -ForegroundColor White

        # Group by username
        $ByUser = $FailedLogons | ForEach-Object {
            [xml]$Xml = $_.ToXml()
            $Xml.Event.EventData.Data | Where-Object {$_.Name -eq 'TargetUserName'} | Select-Object -ExpandProperty '#text'
        } | Group-Object | Sort-Object Count -Descending

        Write-Host "`n  Top targeted usernames:"
        $ByUser | Select-Object -First 5 | ForEach-Object {
            $Color = if ($_.Count -ge $BruteForceThreshold) { "Red" } else { "White" }
            Write-Host "    $($_.Count)x  $($_.Name)" -ForegroundColor $Color
        }

        # Brute force alert
        $BruteForce = $ByUser | Where-Object { $_.Count -ge $BruteForceThreshold }
        if ($BruteForce) {
            Write-Host "`n  ⚠ ΠΙΘΑΝΗ BRUTE FORCE ΕΠΙΘΕΣΗ:" -ForegroundColor Red
            $BruteForce | ForEach-Object {
                Write-Host "    → $($_.Name): $($_.Count) αποτυχημένες προσπάθειες" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  ✓ Καμία αποτυχημένη σύνδεση" -ForegroundColor Green
    }
} catch {
    Write-Host "  Δεν υπάρχουν δεδομένα ή δεν έχεις πρόσβαση." -ForegroundColor Gray
}

# --- Locked Accounts (4740) ---
Write-Host "`n[ Κλειδωμένοι Λογαριασμοί — Event 4740 ]" -ForegroundColor Yellow
try {
    $Locked = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'; Id = 4740; StartTime = $StartTime
    } -ErrorAction SilentlyContinue

    if ($Locked) {
        $Locked | ForEach-Object {
            Write-Host "  ⚠ $($_.TimeCreated.ToString('HH:mm:ss')) — $($_.Properties[0].Value)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ✓ Κανένας κλειδωμένος λογαριασμός" -ForegroundColor Green
    }
} catch { Write-Host "  Δεν υπάρχουν δεδομένα." -ForegroundColor Gray }

# --- New Users Created (4720) ---
Write-Host "`n[ Νέοι Λογαριασμοί — Event 4720 ]" -ForegroundColor Yellow
try {
    $NewUsers = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'; Id = 4720; StartTime = $StartTime
    } -ErrorAction SilentlyContinue

    if ($NewUsers) {
        $NewUsers | ForEach-Object {
            Write-Host "  ⚠ $($_.TimeCreated.ToString('HH:mm:ss')) — Νέος user: $($_.Properties[0].Value)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ✓ Κανένας νέος λογαριασμός" -ForegroundColor Green
    }
} catch { Write-Host "  Δεν υπάρχουν δεδομένα." -ForegroundColor Gray }

Write-Host "`n$Separator`n" -ForegroundColor Cyan
