#!/usr/bin/env bash
# =============================================================
# pending-updates-check.sh
# Εμφανίζει τις διαθέσιμες ενημερώσεις (και τις ενημερώσεις
# ασφαλείας) για apt/dnf/yum, καθώς και αν απαιτείται reboot.
# Χρήση: sudo ./pending-updates-check.sh
# =============================================================
set -uo pipefail

echo "=== Έλεγχος ενημερώσεων - $(hostname) - $(date '+%F %T') ==="

if command -v apt-get &>/dev/null; then
    echo "Package manager: apt"
    apt-get update -qq 2>/dev/null
    TOTAL=$(apt list --upgradable 2>/dev/null | tail -n +2 | wc -l)
    SEC=$(apt list --upgradable 2>/dev/null | grep -ci security || true)
    echo "Διαθέσιμες ενημερώσεις : $TOTAL"
    echo "Ενημερώσεις ασφαλείας  : $SEC"
    (( TOTAL > 0 )) && apt list --upgradable 2>/dev/null | tail -n +2 | head -n 15
elif command -v dnf &>/dev/null || command -v yum &>/dev/null; then
    PM=$(command -v dnf || command -v yum)
    echo "Package manager: $(basename "$PM")"
    "$PM" -q check-update 2>/dev/null | awk 'NF==3' | head -n 15
    echo "--- Ενημερώσεις ασφαλείας ---"
    "$PM" -q updateinfo list security 2>/dev/null | head -n 15 || echo "Μη διαθέσιμο."
else
    echo "Δεν βρέθηκε υποστηριζόμενος package manager."; exit 1
fi

echo
if [[ -f /var/run/reboot-required ]]; then
    echo "[!] Απαιτείται επανεκκίνηση του συστήματος."
elif command -v needs-restarting &>/dev/null && ! needs-restarting -r &>/dev/null; then
    echo "[!] Απαιτείται επανεκκίνηση του συστήματος."
else
    echo "Δεν απαιτείται επανεκκίνηση."
fi
