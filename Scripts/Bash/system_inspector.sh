#!/usr/bin/env bash
# ==============================================================================
# Script  : system_inspector.sh
# Περιγραφή     : Προηγμένο σύστημα ελέγχου υγείας & ασφάλειας Linux για KB
# Author: Dimitris Katsanos
# Date: 2026
# ==============================================================================


# --- Strict Bash Execution Options ---
set -euo pipefail
IFS=$'\n\t'

# --- Colors for Output ---
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# --- Default Variables ---
OUTPUT_FORMAT="text"
THRESHOLD_CPU=80
THRESHOLD_MEM=85
THRESHOLD_DISK=90
LOG_FILE="/tmp/sys_inspector_$(date +%Y%m%d_%H%M%S).log"

# --- Helper Functions ---
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    case "${level}" in
        INFO)  echo -e "${GREEN}[INFO]${NC} [${timestamp}] ${message}" ;;
        WARN)  echo -e "${YELLOW}[WARN]${NC} [${timestamp}] ${message}" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} [${timestamp}] ${message}" >&2 ;;
        DEBUG) echo -e "${BLUE}[DEBUG]${NC} [${timestamp}] ${message}" ;;
    esac
}

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Advanced System Health & Security Inspector.

Options:
  -f, --format FORMAT   Output format: text, json (Default: text)
  -c, --cpu INT         CPU usage warning threshold percentage (Default: 80)
  -m, --mem INT         Memory usage warning threshold percentage (Default: 85)
  -d, --disk INT        Disk usage warning threshold percentage (Default: 90)
  -h, --help            Display this help message
EOF
    exit 0
}

cleanup() {
    # Executed on script exit (trapped)
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log ERROR "Script terminated unexpectedly with exit code ${exit_code}."
    fi
}
trap cleanup EXIT

# --- Parse Arguments ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -c|--cpu)
            THRESHOLD_CPU="$2"
            shift 2
            ;;
        -m|--mem)
            THRESHOLD_MEM="$2"
            shift 2
            ;;
        -d|--disk)
            THRESHOLD_DISK="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            log ERROR "Unknown flag: $1"
            usage
            ;;
    esac
done

# --- System Checks ---
get_cpu_usage() {
    # Idle percentage from top/mpstat or proc/stat calculation
    local cpu_idle
    cpu_idle=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print $1}')
    echo "100 - ${cpu_idle}" | bc -l | awk '{printf "%.1f", $1}'
}

get_mem_usage() {
    free -m | awk 'NR==2{printf "%.1f", $3*100/$2 }'
}

get_disk_usage() {
    df -h / | awk 'NR==2 {print $5}' | sed 's/%//'
}

check_failed_services() {
    if command -v systemctl &> /dev/null; then
        systemctl list-units --state=failed --no-legend | awk '{print $1}' | tr '\n' ' '
    else
        echo "systemd-not-found"
    fi
}

check_open_ports() {
    if command -v ss &> /dev/null; then
        ss -tuln | awk 'NR>1 {print $5}' | awk -F: '{print $NF}' | sort -u -n | tr '\n' ',' | sed 's/,$//'
    else
        echo "ss-not-found"
    fi
}

# --- Main Execution ---
main() {
    log INFO "Starting System Inspection..."

    # Gather Metrics
    local cpu_use mem_use disk_use failed_svcs open_ports
    cpu_use=$(get_cpu_usage)
    mem_use=$(get_mem_usage)
    disk_use=$(get_disk_usage)
    failed_svcs=$(check_failed_services)
    open_ports=$(check_open_ports)

    # Threshold evaluation
    local cpu_status="OK" mem_status="OK" disk_status="OK"
    (( $(echo "${cpu_use} > ${THRESHOLD_CPU}" | bc -l) )) && cpu_status="WARNING"
    (( $(echo "${mem_use} > ${THRESHOLD_MEM}" | bc -l) )) && mem_status="WARNING"
    [[ "${disk_use}" -gt "${THRESHOLD_DISK}" ]] && disk_status="WARNING"

    # Formatting Output
    if [[ "${OUTPUT_FORMAT}" == "json" ]]; then
        cat << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "hostname": "$(hostname)",
  "metrics": {
    "cpu_usage_percent": ${cpu_use},
    "cpu_status": "${cpu_status}",
    "memory_usage_percent": ${mem_use},
    "memory_status": "${mem_status}",
    "disk_usage_percent": ${disk_use},
    "disk_status": "${disk_status}"
  },
  "security": {
    "open_ports": [${open_ports}],
    "failed_services": "${failed_svcs:-none}"
  }
}
EOF
    else
        echo -e "\n=========================================="
        echo -e "       SYSTEM HEALTH & SECURITY REPORT    "
        echo -e "=========================================="
        echo -e "Hostname       : $(hostname)"
        echo -e "Date           : $(date)"
        echo -e "------------------------------------------"
        echo -e "CPU Usage      : ${cpu_use}% [${cpu_status}]"
        echo -e "RAM Usage      : ${mem_use}% [${mem_status}]"
        echo -e "Disk Usage (/) : ${disk_use}% [${disk_status}]"
        echo -e "------------------------------------------"
        echo -e "Open Ports     : ${open_ports}"
        echo -e "Failed Services: ${failed_svcs:-None}"
        echo -e "==========================================\n"

        # Warnings output
        [[ "${cpu_status}" == "WARNING" ]] && log WARN "CPU usage exceeds threshold (${THRESHOLD_CPU}%)"
        [[ "${mem_status}" == "WARNING" ]] && log WARN "Memory usage exceeds threshold (${THRESHOLD_MEM}%)"
        [[ "${disk_status}" == "WARNING" ]] && log WARN "Disk usage exceeds threshold (${THRESHOLD_DISK}%)"
    fi

    log INFO "Inspection finished successfully."
}

main "$@"