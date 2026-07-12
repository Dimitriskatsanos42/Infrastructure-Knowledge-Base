<#
.SYNOPSIS
    Windows System Health Check
.DESCRIPTION
    Ελέγχει CPU, RAM, Disk και κρίσιμα Services.
    Αποθηκεύει αποτέλεσμα σε log file.
.PARAMETER LogPath
    Διαδρομή log file (default: C:\Logs\health-check.log)
.EXAMPLE
    .\system-health-check.ps1
    .\system-health-check.ps1 -LogPath "D:\Logs\health.log"
.NOTES
    Author: Dimitris Katsanos
    Date: 2026
#>

param(
    [string]$LogPath = "C:\Logs\health-check.log"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- Setup ---
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$Separator = "=" * 60
$Services  = @("Spooler","wuauserv","WinDefend","EventLog")
$DiskWarn  = 85   # % για warning
$RamWarn   = 90   # % για warning

# Ensure log directory exists
$LogDir = Split-Path $LogPath
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Entry = "[$Timestamp] [$Level] $Message"
    Add-Content -Path $LogPath -Value $Entry
    switch ($Level) {
        "OK"   { Write-Host "  ✓ $Message" -ForegroundColor Green }
        "WARN" { Write-Host "  ⚠ $Message" -ForegroundColor Yellow }
        "FAIL" { Write-Host "  ✗ $Message" -ForegroundColor Red }
        default { Write-Host "  $Message" }
    }
}

# --- Header ---
Write-Host "`n$Separator" -ForegroundColor Cyan
Write-Host "  SYSTEM HEALTH CHECK — $env:COMPUTERNAME" -ForegroundColor Cyan
Write-Host "  $Timestamp" -ForegroundColor Cyan
Write-Host "$Separator`n" -ForegroundColor Cyan
Add-Content $LogPath "$Separator`nHealth Check — $Timestamp`n$Separator"

# --- CPU ---
Write-Host "[ CPU ]" -ForegroundColor Yellow
$CPU = (Get-CimInstance Win32_Processor | Measure-Object LoadPercentage -Average).Average
if ($CPU -lt 80) { Write-Log "CPU Usage: ${CPU}%" "OK" }
else             { Write-Log "CPU Usage HIGH: ${CPU}%" "WARN" }

# --- RAM ---
Write-Host "`n[ Memory ]" -ForegroundColor Yellow
$OS  = Get-CimInstance Win32_OperatingSystem
$RAM = [math]::Round((($OS.TotalVisibleMemorySize - $OS.FreePhysicalMemory) / $OS.TotalVisibleMemorySize) * 100, 1)
$TotalGB = [math]::Round($OS.TotalVisibleMemorySize / 1MB, 1)
$FreeGB  = [math]::Round($OS.FreePhysicalMemory / 1MB, 1)
if ($RAM -lt $RamWarn) { Write-Log "RAM: ${RAM}% used (${FreeGB}GB free of ${TotalGB}GB)" "OK" }
else                   { Write-Log "RAM HIGH: ${RAM}% used" "WARN" }

# --- Disk ---
Write-Host "`n[ Disks ]" -ForegroundColor Yellow
Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null } | ForEach-Object {
    $UsedPct = [math]::Round(($_.Used / ($_.Used + $_.Free)) * 100, 1)
    $FreeGB  = [math]::Round($_.Free / 1GB, 1)
    if ($UsedPct -lt $DiskWarn) { Write-Log "$($_.Name): ${UsedPct}% used (${FreeGB}GB free)" "OK" }
    else                        { Write-Log "$($_.Name): ${UsedPct}% — LOW DISK SPACE!" "FAIL" }
}

# --- Services ---
Write-Host "`n[ Services ]" -ForegroundColor Yellow
foreach ($SvcName in $Services) {
    try {
        $Svc = Get-Service -Name $SvcName -ErrorAction Stop
        if ($Svc.Status -eq "Running") { Write-Log "$SvcName: Running" "OK" }
        else                           { Write-Log "$SvcName: $($Svc.Status)" "FAIL" }
    } catch {
        Write-Log "$SvcName: Not found" "WARN"
    }
}

# --- Footer ---
Write-Host "`n$Separator" -ForegroundColor Cyan
Write-Host "  Ολοκληρώθηκε. Log: $LogPath" -ForegroundColor Cyan
Write-Host "$Separator`n" -ForegroundColor Cyan
