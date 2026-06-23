# =============================================================================
# Title: Help Desk & IT Support Automated Troubleshooting Tool
# =============================================================================

$DesktopPath = [Environment]::GetFolderPath("Desktop")
$LogFile = "$DesktopPath\IT_Troubleshooting_Report.txt"

function Show-Menu {
    Clear-Host
    Write-Host "=========================================================" -ForegroundColor Cyan
    Write-Host "          IT SUPPORT AUTOMATED DIAGNOSTIC TOOL          " -ForegroundColor Yellow -BackgroundColor Black
    Write-Host "=========================================================" -ForegroundColor Cyan
    Write-Host " Please select an option by typing the corresponding number:"
    Write-Host ""
    Write-Host " [1] Network & Internet Check (ipconfig, ping, nslookup)" -ForegroundColor White
    Write-Host " [2] System & User Info (systeminfo, whoami)" -ForegroundColor White
    Write-Host " [3] Active Connections & Open Ports (netstat)" -ForegroundColor White
    Write-Host " [4] Firewall & Security Status (netsh)" -ForegroundColor White
    Write-Host " [5] Generate Full Report (Log File) on Desktop" -ForegroundColor Green
    Write-Host " [6] Exit" -ForegroundColor Red
    Write-Host "=========================================================" -ForegroundColor Cyan
}

do {
    Show-Menu
    $Selection = Read-Host "`nEnter your choice (1-6)"

    switch ($Selection) {
        "1" {
            Clear-Host
            Write-Host "=== NETWORK DIAGNOSTICS ===" -ForegroundColor Yellow
            Write-Host "`n1. Showing IP Configuration (ipconfig)..." -ForegroundColor Gray
            ipconfig /all
            
            Write-Host "`n2. Pinging Google DNS (ping)..." -ForegroundColor Gray
            ping 8.8.8.8 -n 3
            
            Write-Host "`n3. Testing DNS Resolution (nslookup)..." -ForegroundColor Gray
            nslookup google.com
            
            Read-Host "`nPress Enter to return to menu..."
        }
        
        "2" {
            Clear-Host
            Write-Host "=== SYSTEM INFORMATION ===" -ForegroundColor Yellow
            Write-Host "`n1. Current User & Privileges (whoami)..." -ForegroundColor Gray
            whoami /all
            
            Write-Host "`n2. OS & Hardware Summary (systeminfo)..." -ForegroundColor Gray
            systeminfo | Select-String "OS Name", "OS Version", "System Type", "Total Physical Memory"
            
            Read-Host "`nPress Enter to return to menu..."
        }
        
        "3" {
            Clear-Host
            Write-Host "=== ACTIVE CONNECTIONS & PORTS ===" -ForegroundColor Yellow
            Write-Host "Fetching open ports (netstat) - Please wait..." -ForegroundColor Gray
            netstat -ano | Select-Object -First 20
            
            Read-Host "`nPress Enter to return to menu..."
        }
        
        "4" {
            Clear-Host
            Write-Host "=== SECURITY & FIREWALL CHECK ===" -ForegroundColor Yellow
            Write-Host "Windows Firewall Status..." -ForegroundColor Gray
            netsh advfirewall show allprofiles | Select-String "State"
            
            Read-Host "`nPress Enter to return to menu..."
        }
        
        "5" {
            Clear-Host
            Write-Host "Generating report... Please wait..." -ForegroundColor Yellow
            
            "=== IT SUPPORT AUTOMATED REPORT ===" > $LogFile
            "Date: $(Get-Date)" >> $LogFile
            "==================================" >> $LogFile
            
            ">> IP CONFIGURATION <<" >> $LogFile
            ipconfig /all >> $LogFile
            
            ">> SYSTEM INFO <<" >> $LogFile
            systeminfo | Select-String "OS Name", "OS Version" >> $LogFile
            
            ">> FIREWALL STATE <<" >> $LogFile
            netsh advfirewall show allprofiles >> $LogFile
            
            Write-Host "Report generated successfully at: $LogFile" -ForegroundColor Green
            Read-Host "`nPress Enter to return to menu..."
        }
        
        "6" {
            Write-Host "`nExiting tool. Have a great day!" -ForegroundColor Cyan
            break
        }
        
        default {
            Write-Host "Invalid choice. Please select between 1 and 6." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($Selection -ne "6")