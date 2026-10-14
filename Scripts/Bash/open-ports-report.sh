#!/usr/bin/env bash
# =============================================================
# open-ports-report.sh
# Αναφορά των θυρών που ακούνε (LISTEN) στον server, με την
# αντίστοιχη διεργασία. Προαιρετική εξαγωγή σε αρχείο.
# Χρήση: sudo ./open-ports-report.sh [αρχείο_εξόδου]
# =============================================================
set -uo pipefail

OUT="${1:-}"
REPORT="$(mktemp)"

{
    echo "=== Ανοιχτές θύρες - $(hostname) - $(date '+%F %T') ==="
    echo
    echo "--- TCP (LISTEN) ---"
    ss -tlnpH 2>/dev/null | awk '{printf "%-25s %s\n", $4, $6}'
    echo
    echo "--- UDP ---"
    ss -ulnpH 2>/dev/null | awk '{printf "%-25s %s\n", $4, $6}'
    echo
    echo "--- Θύρες ανοιχτές σε ΟΛΕΣ τις διεπαφές (0.0.0.0 / [::]) ---"
    ss -tlnH 2>/dev/null | awk '$4 ~ /^(0\.0\.0\.0|\*|\[::\]):/ {print $4}' | sort -u
    echo
    echo "--- Πλήθος ενεργών συνδέσεων ανά κατάσταση ---"
    ss -tan | awk 'NR>1 {c[$1]++} END {for (s in c) printf "%-12s %d\n", s, c[s]}'
} > "$REPORT"

cat "$REPORT"
if [[ -n "$OUT" ]]; then
    cp "$REPORT" "$OUT"
    echo; echo "Η αναφορά αποθηκεύτηκε στο: $OUT"
fi
rm -f "$REPORT"
