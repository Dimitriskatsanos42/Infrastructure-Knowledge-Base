<#
.SYNOPSIS
    Διαγνωστικός έλεγχος δικτύου: adapters, IP, gateway, DNS, ping, θύρες.
.EXAMPLE
    .\network-diagnostics.ps1
#>

$pingTargets = '8.8.8.8', '1.1.1.1'
$dnsTargets  = 'google.com', 'microsoft.com'
$portTargets = @(
    @{ Host = 'github.com';    Port = 443 },
    @{ Host = 'microsoft.com'; Port = 443 }
)

function Show-Result($ok, $text) {
    if ($ok) { Write-Host "  [ OK ] $text" -ForegroundColor Green }
    else     { Write-Host "  [FAIL] $text" -ForegroundColor Red }
}

Write-Host "`n=== 1. Ενεργοί Network Adapters ===" -ForegroundColor Cyan
Get-NetAdapter | Where-Object Status -eq 'Up' |
    Select-Object Name, InterfaceDescription, LinkSpeed, MacAddress | Format-Table -AutoSize

Write-Host "=== 2. Ρυθμίσεις IP ===" -ForegroundColor Cyan
Get-NetIPConfiguration | Where-Object { $_.IPv4Address } | ForEach-Object {
    Write-Host ("  {0}: IP={1} GW={2} DNS={3}" -f $_.InterfaceAlias,
        $_.IPv4Address.IPAddress,
        ($_.IPv4DefaultGateway.NextHop -join ','),
        ($_.DnsServer.ServerAddresses -join ','))
}

Write-Host "`n=== 3. Ping ===" -ForegroundColor Cyan
foreach ($t in $pingTargets) { Show-Result (Test-Connection $t -Count 2 -Quiet) "ping $t" }

Write-Host "`n=== 4. DNS Resolution ===" -ForegroundColor Cyan
foreach ($d in $dnsTargets) {
    try {
        $r = Resolve-DnsName $d -Type A -ErrorAction Stop | Select-Object -First 1
        Show-Result $true "$d -> $($r.IPAddress)"
    } catch { Show-Result $false "Αποτυχία ανάλυσης $d" }
}

Write-Host "`n=== 5. TCP Θύρες ===" -ForegroundColor Cyan
foreach ($p in $portTargets) {
    $res = Test-NetConnection -ComputerName $p.Host -Port $p.Port -WarningAction SilentlyContinue
    Show-Result $res.TcpTestSucceeded "$($p.Host):$($p.Port)"
}

Write-Host "`n=== 6. Ενεργές συνδέσεις (Established, top 10) ===" -ForegroundColor Cyan
Get-NetTCPConnection -State Established | Select-Object -First 10 LocalAddress, LocalPort, RemoteAddress, RemotePort, OwningProcess | Format-Table -AutoSize
