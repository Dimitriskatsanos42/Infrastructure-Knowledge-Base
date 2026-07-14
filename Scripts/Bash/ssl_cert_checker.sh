#!/usr/bin/env bash
# ============================================
#
# Script: ssl_cert_checker.sh
#
# Περιγραφή:
# Ελέγχει την ημερομηνία λήξης SSL certificates
# για μία λίστα από domains/hosts και ειδοποιεί
# όταν κάποιο πλησιάζει σε λήξη.
#
# Χρήση:
#   ./ssl_cert_checker.sh domain1.com domain2.com:443
#   ή διάβασε από αρχείο: ./ssl_cert_checker.sh -f domains.txt
#
# Author: Dimitris Katsanos
# Date: 2026
#
# ============================================
set -euo pipefail

REPORT="ssl_report_$(date +%F_%H-%M-%S).txt"
WARN_DAYS=30      # Προειδοποίηση αν λήγει σε λιγότερες από τόσες μέρες
CRIT_DAYS=7       # Κρίσιμο όριο

usage() {
    echo "Χρήση: $0 domain1.com [domain2.com:port ...]"
    echo "       $0 -f domains.txt"
    exit 1
}

if [ "$#" -eq 0 ]; then
    usage
fi

DOMAINS=()

if [ "$1" = "-f" ]; then
    FILE="${2:-}"
    if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
        echo "Σφάλμα: δεν βρέθηκε το αρχείο '$FILE'"
        exit 1
    fi
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        [[ "$line" =~ ^# ]] && continue
        DOMAINS+=("$line")
    done < "$FILE"
else
    DOMAINS=("$@")
fi

check_cert() {
    local TARGET="$1"
    local HOST="${TARGET%%:*}"
    local PORT="443"
    if [[ "$TARGET" == *:* ]]; then
        PORT="${TARGET##*:}"
    fi

    local EXPIRY_RAW
    if ! EXPIRY_RAW=$(echo | timeout 10 openssl s_client -servername "$HOST" -connect "$HOST:$PORT" 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null); then
        echo "$HOST:$PORT | ✘ ΣΦΑΛΜΑ: δεν ήταν δυνατή η σύνδεση ή ανάκτηση certificate"
        return
    fi

    local EXPIRY_DATE
    EXPIRY_DATE=$(echo "$EXPIRY_RAW" | cut -d= -f2)

    local EXPIRY_EPOCH NOW_EPOCH DAYS_LEFT
    EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$EXPIRY_DATE" +%s 2>/dev/null)
    NOW_EPOCH=$(date +%s)
    DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

    local STATUS
    if [ "$DAYS_LEFT" -lt 0 ]; then
        STATUS="✘ ΕΛΗΞΕ ήδη πριν $((-DAYS_LEFT)) μέρες"
    elif [ "$DAYS_LEFT" -le "$CRIT_DAYS" ]; then
        STATUS="🔴 ΚΡΙΣΙΜΟ: λήγει σε $DAYS_LEFT μέρες"
    elif [ "$DAYS_LEFT" -le "$WARN_DAYS" ]; then
        STATUS="🟡 ΠΡΟΣΟΧΗ: λήγει σε $DAYS_LEFT μέρες"
    else
        STATUS="✔ OK: λήγει σε $DAYS_LEFT μέρες"
    fi

    echo "$HOST:$PORT | Λήξη: $EXPIRY_DATE | $STATUS"
}

{
echo "================================="
echo "     SSL CERTIFICATE CHECKER"
echo "================================="
echo
echo "Date:"
date
echo
echo "Thresholds: WARNING <= ${WARN_DAYS}d, CRITICAL <= ${CRIT_DAYS}d"
echo
echo "===== ΑΠΟΤΕΛΕΣΜΑΤΑ ====="
for D in "${DOMAINS[@]}"; do
    check_cert "$D"
done
echo
echo "Έλεγχος ολοκληρώθηκε"
} | tee "$REPORT"

echo
echo "Report saved:"
echo "$REPORT"