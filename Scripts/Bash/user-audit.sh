#!/usr/bin/env bash
# =============================================================
# user-audit.sh
# Έλεγχος λογαριασμών χρηστών σε Linux: χρήστες με shell,
# μέλη sudo, κενοί κωδικοί, πρόσφατες συνδέσεις.
# Χρήση: sudo ./user-audit.sh
# =============================================================
set -uo pipefail

echo "=== Audit χρηστών - $(hostname) - $(date '+%F %T') ==="

echo; echo "--- 1. Χρήστες με interactive shell ---"
awk -F: '$7 !~ /(nologin|false|sync|shutdown|halt)$/ {printf "%-20s UID=%-6s shell=%s\n", $1, $3, $7}' /etc/passwd

echo; echo "--- 2. Λογαριασμοί με UID 0 (root-level) ---"
awk -F: '$3 == 0 {print $1}' /etc/passwd

echo; echo "--- 3. Μέλη sudo / wheel / admin ---"
for g in sudo wheel admin; do
    if getent group "$g" &>/dev/null; then
        echo "[$g]: $(getent group "$g" | cut -d: -f4)"
    fi
done

echo; echo "--- 4. Λογαριασμοί χωρίς κωδικό ---"
if [[ $EUID -eq 0 ]]; then
    awk -F: '($2 == "" ) {print $1}' /etc/shadow
    echo "(κενό = δεν βρέθηκαν)"
else
    echo "Απαιτούνται δικαιώματα root."
fi

echo; echo "--- 5. Τελευταίες 10 συνδέσεις ---"
last -n 10 2>/dev/null | head -n 10

echo; echo "--- 6. Αποτυχημένες προσπάθειες σύνδεσης ---"
lastb -n 10 2>/dev/null || echo "Μη διαθέσιμο (απαιτείται root)."
