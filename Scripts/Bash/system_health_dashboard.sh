#!/usr/bin/env bash
# ============================================

# Script: system_health_dashboard.sh.sh
# # Περιγραφή: Δημιουργεί αναφορά υγείας του Linux συστήματος 
#              με πληροφορίες για CPU, RAM, δίσκους, δίκτυο, διεργασίες και ενεργές υπηρεσίες.
#            
# Author: Dimitris Katsanos
# Date: 2026
# Usage: ./system_health_dashboard.sh [--services nginx,ssh,ufw]
# ============================================ 

set -euo pipefail

REPORT="system_report_$(date +%F_%H-%M-%S).txt"

{
echo "===== SYSTEM HEALTH REPORT ====="
echo "Generated: $(date)"
echo
echo "Hostname: $(hostname)"
echo "Uptime:"
uptime
echo
echo "CPU:"
top -bn1 | head -5
echo
echo "Memory:"
free -h
echo
echo "Disk:"
df -h
echo
echo "Network:"
ip -brief address || ifconfig
echo
echo "Top 10 Processes:"
ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head
echo
echo "Running Services:"
systemctl list-units --type=service --state=running 2>/dev/null | head -20 || true
} | tee "$REPORT"

echo
echo "Report saved to: $REPORT"
