#!/usr/bin/env bash
# =============================================================
# docker-cleanup.sh
# Εμφανίζει τη χρήση χώρου του Docker και καθαρίζει
# σταματημένα containers, αχρησιμοποίητα images, networks.
# Από προεπιλογή τρέχει σε DRY-RUN (μόνο αναφορά).
# Χρήση: ./docker-cleanup.sh [--prune] [--volumes]
# =============================================================
set -euo pipefail

PRUNE=false; VOLUMES=false
for arg in "$@"; do
    case "$arg" in
        --prune)   PRUNE=true ;;
        --volumes) VOLUMES=true ;;
        *) echo "Άγνωστη παράμετρος: $arg"; exit 1 ;;
    esac
done

command -v docker &>/dev/null || { echo "Το Docker δεν είναι εγκατεστημένο."; exit 1; }

echo "=== Χρήση χώρου Docker ==="
docker system df
echo
echo "=== Σταματημένα containers ==="
docker ps -a --filter "status=exited" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
echo
echo "=== Dangling images ==="
docker images -f "dangling=true" --format "table {{.Repository}}\t{{.ID}}\t{{.Size}}"
echo

if $PRUNE; then
    echo ">>> Εκτέλεση καθαρισμού..."
    docker container prune -f
    docker image prune -af
    docker network prune -f
    if $VOLUMES; then
        echo ">>> Καθαρισμός αχρησιμοποίητων volumes..."
        docker volume prune -f
    fi
    echo; echo "Ο καθαρισμός ολοκληρώθηκε."; docker system df
else
    echo "[DRY-RUN] Δεν διαγράφηκε τίποτα. Χρησιμοποιήστε --prune (και προαιρετικά --volumes)."
fi
