#!/usr/bin/env bash
# =============================================================
# db-backup.sh
# Backup βάσης δεδομένων MySQL/MariaDB ή PostgreSQL με συμπίεση
# και αυτόματη διαγραφή παλιών αντιγράφων.
# Χρήση:
#   ./db-backup.sh mysql    <βάση> [φάκελος] [ημέρες_διατήρησης]
#   ./db-backup.sh postgres <βάση> [φάκελος] [ημέρες_διατήρησης]
# Οι κωδικοί πρέπει να ορίζονται μέσω ~/.my.cnf ή ~/.pgpass
# (ΠΟΤΕ μέσα στο script).
# =============================================================
set -euo pipefail

ENGINE="${1:-}"; DB="${2:-}"
DEST="${3:-/var/backups/db}"
KEEP="${4:-7}"

if [[ -z "$ENGINE" || -z "$DB" ]]; then
    echo "Χρήση: $0 <mysql|postgres> <βάση> [φάκελος] [ημέρες]"; exit 1
fi

mkdir -p "$DEST"
STAMP="$(date +%Y%m%d_%H%M%S)"
FILE="${DEST}/${DB}_${STAMP}.sql.gz"

case "$ENGINE" in
    mysql)    mysqldump --single-transaction --routines --triggers "$DB" | gzip > "$FILE" ;;
    postgres) pg_dump "$DB" | gzip > "$FILE" ;;
    *) echo "Μη υποστηριζόμενη μηχανή: $ENGINE"; exit 1 ;;
esac

# Έλεγχος ακεραιότητας του συμπιεσμένου αρχείου
if gzip -t "$FILE"; then
    echo "[ OK ] Backup: $FILE ($(du -h "$FILE" | cut -f1))"
else
    echo "[FAIL] Το αρχείο backup είναι κατεστραμμένο!"; exit 1
fi

# Διαγραφή παλιών
DELETED=$(find "$DEST" -name "${DB}_*.sql.gz" -mtime +"$KEEP" -print -delete | wc -l)
echo "Διαγράφηκαν ${DELETED} παλιά backup(s) (> ${KEEP} ημέρες)."
