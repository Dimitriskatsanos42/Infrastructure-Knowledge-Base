#!/bin/bash
# ============================================
# Script: server-health-check.sh
# Περιγραφή: Έλεγχος κατάστασης Linux server
#            CPU, RAM, Disk, Services, Failed logins
# Author: Dimitris Katsanos
# Date: 2026
# Usage: ./server-health-check.sh [--services nginx,ssh,ufw]
# ============================================

set -euo pipefail

# --- Config ---
DISK_WARN=85
RAM_WARN=90
SERVICES=("nginx" "ssh" "ufw" "fail2ban")
LOG_FILE="/var/log/server-health.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME_=$(hostname)
SEPARATOR=$(printf '=%.0s' {1..55})

# --- Colors ---
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

# --- Functions ---
log() { echo "[$TIMESTAMP] $1" >> "$LOG_FILE"; }
ok()   { echo -e "  ${GREEN}✓ $1${NC}"; log "OK: $1"; }
warn() { echo -e "  ${YELLOW}⚠ $1${NC}"; log "WARN: $1"; }
fail() { echo -e "  ${RED}✗ $1${NC}"; log "FAIL: $1"; }
header() { echo -e "\n${CYAN}[ $1 ]${NC}"; }

# --- Header ---
echo -e "${CYAN}${SEPARATOR}"
echo -e "  SERVER HEALTH CHECK — ${HOSTNAME_}"
echo -e "  ${TIMESTAMP}"
echo -e "${SEPARATOR}${NC}"
log "=== Health Check Start: $HOSTNAME_ ==="

# --- CPU ---
header "CPU Load"
CORES=$(nproc)
LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')
LOAD_PCT=$(awk "BEGIN {printf \"%d\", ($LOAD/$CORES)*100}")
if [ "$LOAD_PCT" -lt 80 ]; then
    ok "Load: $LOAD (${LOAD_PCT}% of ${CORES} cores)"
else
    warn "Load HIGH: $LOAD (${LOAD_PCT}%)"
fi

# --- RAM ---
header "Memory"
MEM_TOTAL=$(free -m | awk '/Mem:/{print $2}')
MEM_USED=$(free -m | awk '/Mem:/{print $3}')
MEM_PCT=$(awk "BEGIN {printf \"%d\", ($MEM_USED/$MEM_TOTAL)*100}")
MEM_FREE_GB=$(awk "BEGIN {printf \"%.1f\", ($MEM_TOTAL-$MEM_USED)/1024}")
if [ "$MEM_PCT" -lt "$RAM_WARN" ]; then
    ok "RAM: ${MEM_PCT}% used (${MEM_FREE_GB}GB free)"
else
    fail "RAM HIGH: ${MEM_PCT}% used — μόνο ${MEM_FREE_GB}GB ελεύθερο!"
fi

# --- Disk ---
header "Disk"
while IFS= read -r line; do
    MOUNT=$(echo "$line" | awk '{print $6}')
    PCT=$(echo "$line" | awk '{print $5}' | tr -d '%')
    FREE=$(echo "$line" | awk '{print $4}')
    if [ "$PCT" -lt "$DISK_WARN" ]; then
        ok "$MOUNT: ${PCT}% used (${FREE} free)"
    else
        fail "$MOUNT: ${PCT}% — ΧΑΜΗΛΟΣ ΧΩΡΟΣ!"
    fi
done < <(df -h | awk 'NR>1 && $1 ~ /^\/dev/ {print}')

# --- Services ---
header "Services"
for SERVICE in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$SERVICE" 2>/dev/null; then
        ok "$SERVICE: running"
    elif systemctl list-unit-files --type=service 2>/dev/null | grep -q "^$SERVICE"; then
        fail "$SERVICE: NOT running!"
    else
        warn "$SERVICE: not installed"
    fi
done

# --- Failed Logins (last hour) ---
header "Failed SSH Logins (τελευταία ώρα)"
if [ -f /var/log/auth.log ]; then
    FAILS=$(grep "Failed password" /var/log/auth.log 2>/dev/null | \
            awk -v d="$(date --date='1 hour ago' '+%b %e %H')" '$0 >= d' | wc -l)
    if [ "$FAILS" -eq 0 ]; then
        ok "Καμία αποτυχημένη σύνδεση"
    elif [ "$FAILS" -lt 10 ]; then
        warn "${FAILS} αποτυχημένες συνδέσεις"
    else
        fail "${FAILS} αποτυχημένες συνδέσεις — πιθανή επίθεση!"
    fi
else
    warn "Δεν βρέθηκε /var/log/auth.log"
fi

# --- Footer ---
echo -e "\n${CYAN}${SEPARATOR}"
echo -e "  Ολοκληρώθηκε. Log: ${LOG_FILE}"
echo -e "${SEPARATOR}${NC}\n"
log "=== Health Check End ==="
