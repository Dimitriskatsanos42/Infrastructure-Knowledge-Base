#!/usr/bin/env bash
# ============================================
#
# Script: server_security_audit.sh
# Περιγραφή: Ελέγχει την υγεία και την ασφάλεια ενός Linux server
#             με ελέγχους CPU, RAM, δίσκου, υπηρεσιών, ports
#             και αποτυχημένων login attempts.
#
# Author: Dimitris Katsanos
# Date: 2026
# Usage: ./server_security_audit.sh
#
# ============================================

set -euo pipefail

REPORT="security_audit_$(date +%F_%H-%M-%S).txt"


check_status() {

VALUE=$1
LIMIT=$2
NAME=$3

if [ "$VALUE" -ge "$LIMIT" ]; then
    echo "[WARNING] $NAME : $VALUE%"
else
    echo "[OK] $NAME : $VALUE%"
fi

}


{

echo "================================="
echo " LINUX SERVER SECURITY AUDIT"
echo "================================="
echo

echo "Date:"
date

echo
echo "Hostname:"
hostname


echo
echo "===== SYSTEM LOAD ====="

LOAD=$(uptime | awk -F'load average:' '{print $2}')

echo "Load Average:$LOAD"



echo
echo "===== MEMORY CHECK ====="

MEM=$(free | awk '/Mem/ {print int($3/$2 *100)}')

check_status "$MEM" 80 "Memory Usage"



echo
echo "===== DISK CHECK ====="

df -h | grep '^/dev' | while read line
do

USAGE=$(echo $line | awk '{print $5}' | tr -d '%')
PART=$(echo $line | awk '{print $1}')

check_status "$USAGE" 85 "Disk $PART"

done



echo
echo "===== RUNNING SERVICES ====="

SERVICES=("ssh" "cron" "systemd-journald")

for service in "${SERVICES[@]}"
do

if systemctl is-active --quiet $service
then
    echo "[OK] $service running"
else
    echo "[WARNING] $service stopped"
fi

done



echo
echo "===== OPEN NETWORK PORTS ====="

ss -tuln



echo
echo "===== FAILED LOGIN ATTEMPTS ====="

if command -v lastb >/dev/null
then

FAILED=$(lastb | wc -l)

if [ "$FAILED" -gt 1 ]
then
    echo "[WARNING] Failed logins detected: $FAILED"
else
    echo "[OK] No failed login attempts"
fi

else

echo "lastb command not available"

fi



echo
echo "===== USERS WITH SUDO ACCESS ====="

grep -E 'sudo|wheel' /etc/group



echo
echo "===== TOP CPU PROCESSES ====="

ps aux --sort=-%cpu | head -6


echo
echo "===== AUDIT FINISHED ====="


} | tee "$REPORT"



echo
echo "Report saved:"
echo "$REPORT"
