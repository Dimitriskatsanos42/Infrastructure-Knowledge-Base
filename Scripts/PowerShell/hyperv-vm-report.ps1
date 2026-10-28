<#
.SYNOPSIS
    Αναφορά Virtual Machines σε Hyper-V host: κατάσταση, πόροι, checkpoints.
.PARAMETER ComputerName
    Hyper-V host (προεπιλογή: τοπικός υπολογιστής).
.EXAMPLE
    .\hyperv-vm-report.ps1 -ComputerName HV01
.NOTES
    Απαιτεί το module Hyper-V και δικαιώματα Administrator.
#>
param([string]$ComputerName = $env:COMPUTERNAME)

Import-Module Hyper-V -ErrorAction Stop

$vms = Get-VM -ComputerName $ComputerName

$report = foreach ($vm in $vms) {
    $disks = Get-VMHardDiskDrive -VM $vm | ForEach-Object { (Get-VHD -Path $_.Path -ComputerName $ComputerName -ErrorAction SilentlyContinue) }
    [PSCustomObject]@{
        VM          = $vm.Name
        State       = $vm.State
        CPU         = $vm.ProcessorCount
        'RAM_GB'    = [math]::Round($vm.MemoryAssigned / 1GB, 2)
        'DiskUsed_GB' = [math]::Round((($disks | Measure-Object FileSize -Sum).Sum) / 1GB, 2)
        Uptime      = $vm.Uptime.ToString('d\.hh\:mm')
        Checkpoints = @(Get-VMSnapshot -VM $vm).Count
    }
}

Write-Host "`n=== Hyper-V Host: $ComputerName ===" -ForegroundColor Cyan
$report | Format-Table -AutoSize

$hostInfo = Get-VMHost -ComputerName $ComputerName
Write-Host "Λογικοί επεξεργαστές : $($hostInfo.LogicalProcessorCount)"
Write-Host ("Μνήμη host           : {0} GB" -f [math]::Round($hostInfo.MemoryCapacity / 1GB, 1))

$old = $report | Where-Object Checkpoints -gt 0
if ($old) {
    Write-Host "`n[!] VMs με checkpoints (επηρεάζουν την απόδοση):" -ForegroundColor Yellow
    $old | ForEach-Object { Write-Host "   - $($_.VM): $($_.Checkpoints)" -ForegroundColor Yellow }
}
