#!/usr/bin/env bash
# =============================================================
# disk-usage-alert.sh
# Ελέγχει τη χρήση δίσκου σε όλα τα mounted filesystems και
# προειδοποιεί όταν ξεπεραστεί ένα όριο (threshold).
# Χρήση: ./disk-usage-alert.sh [threshold%]   (προεπιλογή: 80)
# =============================================================
set -euo pipefail

THRESHOLD="${1:-80}"
HOST="$(hostname)"
ALERTS=0

echo "=== Έλεγχος δίσκων στο ${HOST} ($(date '+%Y-%m-%d %H:%M:%S')) ==="
echo "Όριο ειδοποίησης: ${THRESHOLD}%"
echo

# Παραλείπουμε tmpfs, devtmpfs, squashfs κ.λπ.
while read -r fs size used avail pct mount; do
    usage="${pct%\%}"
    if (( usage >= THRESHOLD )); then
        echo "[ALERT] ${mount} (${fs}) στο ${pct} - ελεύθερα: ${avail}"
        ALERTS=$((ALERTS + 1))
    else
        echo "[ OK  ] ${mount} (${fs}) στο ${pct} - ελεύθερα: ${avail}"
    fi
done < <(df -hP -x tmpfs -x devtmpfs -x squashfs -x overlay | tail -n +2)

echo
if (( ALERTS > 0 )); then
    echo "Βρέθηκαν ${ALERTS} filesystem(s) πάνω από το όριο."
    exit 1
fi
echo "Όλα τα filesystems είναι εντός ορίων."
