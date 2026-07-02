#!/usr/bin/env bash
#
# backup-with-rsync.sh — Αυτόματο backup με rsync
#
# Περιγραφή:
#   Κάνει incremental backup ενός φακέλου (πηγή) σε φάκελο προορισμού
#   (τοπικό ή remote μέσω SSH), κρατώντας logs και διαγράφοντας παλιά
#   backups πέραν ενός ορίου διατήρησης (retention).
#
# Χρήση:
#   ./backup-with-rsync.sh
#   (ρυθμίστε τις μεταβλητές παρακάτω ή περάστε τις ως env vars)
#
#   SOURCE_DIR=/home/user DEST_DIR=/mnt/backup ./backup-with-rsync.sh
#
# Cron παράδειγμα (καθημερινά στις 02:30):
#   30 2 * * * /path/to/backup-with-rsync.sh >> /var/log/backup-with-rsync.log 2>&1
#
set -euo pipefail

# ------------------------------------------------------------------
# Ρυθμίσεις (μπορούν να οριστούν και ως environment variables)
# ------------------------------------------------------------------

# Φάκελος πηγή (τι θέλουμε να αντιγράψουμε)
SOURCE_DIR="${SOURCE_DIR:-/home/user/data}"

# Φάκελος προορισμού. Μπορεί να είναι τοπικός ή remote π.χ.:
#   user@remote-host:/path/to/backup
DEST_DIR="${DEST_DIR:-/mnt/backup}"

# Φάκελος για τα logs
LOG_DIR="${LOG_DIR:-/var/log/backup-with-rsync}"

# Πόσες ημέρες να κρατάμε παλιά backups (0 = χωρίς καθαρισμό)
RETENTION_DAYS="${RETENTION_DAYS:-30}"

# Επιπλέον επιλογές rsync (π.χ. --exclude)
RSYNC_EXTRA_OPTS="${RSYNC_EXTRA_OPTS:---exclude=.cache --exclude=tmp/}"

# ------------------------------------------------------------------
# Εσωτερικές μεταβλητές
# ------------------------------------------------------------------
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
BACKUP_PATH="${DEST_DIR%/}/backup_${TIMESTAMP}"
LATEST_LINK="${DEST_DIR%/}/latest"
LOG_FILE="${LOG_DIR%/}/backup_${TIMESTAMP}.log"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# ------------------------------------------------------------------
# Έλεγχοι πριν ξεκινήσει το backup
# ------------------------------------------------------------------
if ! command -v rsync >/dev/null 2>&1; then
    log "ΣΦΑΛΜΑ: Το rsync δεν είναι εγκατεστημένο."
    exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
    log "ΣΦΑΛΜΑ: Ο φάκελος πηγή δεν υπάρχει: $SOURCE_DIR"
    exit 1
fi

log "=== Έναρξη backup ==="
log "Πηγή:       $SOURCE_DIR"
log "Προορισμός: $BACKUP_PATH"

# ------------------------------------------------------------------
# Εκτέλεση rsync
# Χρησιμοποιούμε --link-dest ώστε τα αρχεία που δεν άλλαξαν να γίνονται
# hard link με το προηγούμενο backup (εξοικονόμηση χώρου - incremental).
# ------------------------------------------------------------------
mkdir -p "$BACKUP_PATH"

RSYNC_CMD=(rsync -aH --delete --stats)

# Αν υπάρχει προηγούμενο backup, το χρησιμοποιούμε ως βάση σύγκρισης
if [ -L "$LATEST_LINK" ] && [ -d "$LATEST_LINK" ]; then
    RSYNC_CMD+=(--link-dest="$LATEST_LINK")
    log "Χρήση προηγούμενου backup για incremental αντιγραφή: $LATEST_LINK"
fi

# Προσθήκη επιπλέον επιλογών (π.χ. excludes)
# shellcheck disable=SC2206
RSYNC_CMD+=($RSYNC_EXTRA_OPTS)

RSYNC_CMD+=("${SOURCE_DIR%/}/" "$BACKUP_PATH/")

log "Εντολή: ${RSYNC_CMD[*]}"

if "${RSYNC_CMD[@]}" >> "$LOG_FILE" 2>&1; then
    log "Το rsync ολοκληρώθηκε επιτυχώς."
else
    log "ΣΦΑΛΜΑ: Το rsync απέτυχε. Δείτε το log: $LOG_FILE"
    exit 1
fi

# Ενημέρωση του symlink "latest" ώστε να δείχνει στο νέο backup
ln -sfn "$BACKUP_PATH" "$LATEST_LINK"
log "Το symlink 'latest' ενημερώθηκε -> $BACKUP_PATH"

# ------------------------------------------------------------------
# Καθαρισμός παλιών backups (retention policy)
# ------------------------------------------------------------------
if [ "$RETENTION_DAYS" -gt 0 ]; then
    log "Διαγραφή backups παλαιότερων από $RETENTION_DAYS ημέρες..."
    find "$DEST_DIR" -maxdepth 1 -type d -name "backup_*" -mtime "+${RETENTION_DAYS}" -print -exec rm -rf {} \; | while read -r deleted; do
        log "Διαγράφηκε: $deleted"
    done
fi

log "=== Το backup ολοκληρώθηκε επιτυχώς ==="
exit 0