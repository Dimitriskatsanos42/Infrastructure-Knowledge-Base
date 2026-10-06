#!/usr/bin/env bash
# =============================================================
# service-monitor.sh
# Παρακολουθεί systemd services και τα επανεκκινεί αν έχουν
# σταματήσει. Απαιτεί δικαιώματα root για restart.
# Χρήση: sudo ./service-monitor.sh nginx sshd cron
# =============================================================
set -uo pipefail

LOG_FILE="/var/log/service-monitor.log"
[[ -w "$(dirname "$LOG_FILE")" ]] || LOG_FILE="./service-monitor.log"

if (( $# == 0 )); then
    echo "Χρήση: $0 <service1> [service2] ..."
    exit 1
fi

log() { echo "$(date '+%F %T') $*" | tee -a "$LOG_FILE"; }

for svc in "$@"; do
    if systemctl is-active --quiet "$svc"; then
        log "[ OK ] $svc τρέχει κανονικά"
    else
        log "[WARN] $svc ΔΕΝ τρέχει - προσπάθεια επανεκκίνησης..."
        if systemctl restart "$svc"; then
            sleep 2
            if systemctl is-active --quiet "$svc"; then
                log "[FIXED] $svc επανεκκινήθηκε με επιτυχία"
            else
                log "[ERROR] $svc απέτυχε μετά την επανεκκίνηση"
            fi
        else
            log "[ERROR] Η εντολή restart για $svc απέτυχε"
        fi
    fi
done
