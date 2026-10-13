#!/usr/bin/env bash
# =============================================================
# firewall-status.sh
# Εντοπίζει ποιο firewall χρησιμοποιείται (ufw, firewalld,
# nftables, iptables) και εμφανίζει την τρέχουσα κατάσταση.
# Χρήση: sudo ./firewall-status.sh
# =============================================================
set -uo pipefail

echo "=== Έλεγχος Firewall - $(hostname) - $(date '+%F %T') ==="
FOUND=false

if command -v ufw &>/dev/null; then
    FOUND=true
    echo; echo "--- UFW ---"
    ufw status verbose
fi

if command -v firewall-cmd &>/dev/null; then
    FOUND=true
    echo; echo "--- firewalld ---"
    if systemctl is-active --quiet firewalld; then
        echo "Κατάσταση: ενεργό"
        echo "Default zone : $(firewall-cmd --get-default-zone)"
        echo "Active zones : $(firewall-cmd --get-active-zones | tr '\n' ' ')"
        firewall-cmd --list-all
    else
        echo "Το firewalld είναι εγκατεστημένο αλλά ανενεργό."
    fi
fi

if command -v nft &>/dev/null; then
    FOUND=true
    echo; echo "--- nftables (σύνοψη rulesets) ---"
    nft list tables 2>/dev/null || echo "Απαιτούνται δικαιώματα root."
fi

if command -v iptables &>/dev/null; then
    FOUND=true
    echo; echo "--- iptables (INPUT chain) ---"
    iptables -L INPUT -n --line-numbers 2>/dev/null || echo "Απαιτούνται δικαιώματα root."
fi

$FOUND || echo "Δεν βρέθηκε γνωστό εργαλείο firewall."
