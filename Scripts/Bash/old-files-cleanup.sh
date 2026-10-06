#!/usr/bin/env bash
# =============================================================
# old-files-cleanup.sh
# Εντοπίζει (και προαιρετικά διαγράφει) αρχεία παλαιότερα από
# Ν ημέρες. Από προεπιλογή τρέχει σε DRY-RUN.
# Χρήση: ./old-files-cleanup.sh <φάκελος> <ημέρες> [--delete]
# Παράδειγμα: ./old-files-cleanup.sh /var/log/myapp 30 --delete
# =============================================================
set -euo pipefail

DIR="${1:-}"
DAYS="${2:-}"
MODE="${3:-}"

if [[ -z "$DIR" || -z "$DAYS" ]]; then
    echo "Χρήση: $0 <φάκελος> <ημέρες> [--delete]"
    exit 1
fi
if [[ ! -d "$DIR" ]]; then
    echo "Ο φάκελος '$DIR' δεν υπάρχει."
    exit 1
fi
# Προστασία από επικίνδυνες διαδρομές
case "$(realpath "$DIR")" in
    /|/bin|/boot|/etc|/usr|/lib*|/sbin|/home|/root)
        echo "Άρνηση: η διαδρομή '$DIR' είναι προστατευμένη."; exit 1 ;;
esac

echo "Αναζήτηση αρχείων παλαιότερων από ${DAYS} ημέρες στο: $DIR"
COUNT=$(find "$DIR" -type f -mtime +"$DAYS" | wc -l)
SIZE=$(find "$DIR" -type f -mtime +"$DAYS" -print0 | du -ch --files0-from=- 2>/dev/null | tail -1 | cut -f1)
echo "Βρέθηκαν: ${COUNT} αρχεία (${SIZE:-0})"

if [[ "$MODE" == "--delete" ]]; then
    find "$DIR" -type f -mtime +"$DAYS" -print -delete
    echo "Η διαγραφή ολοκληρώθηκε."
else
    find "$DIR" -type f -mtime +"$DAYS" | head -n 20
    (( COUNT > 20 )) && echo "... και ${COUNT} συνολικά."
    echo "[DRY-RUN] Δεν διαγράφηκε τίποτα. Προσθέστε --delete για πραγματική διαγραφή."
fi
