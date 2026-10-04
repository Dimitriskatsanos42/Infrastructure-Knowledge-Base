#!/usr/bin/env bash
# =============================================================
# network-connectivity-check.sh
# Βασικός διαγνωστικός έλεγχος δικτύου: gateway, internet,
# DNS resolution και συγκεκριμένες θύρες.
# Χρήση: ./network-connectivity-check.sh
# =============================================================
set -uo pipefail

PING_TARGETS=("8.8.8.8" "1.1.1.1")
DNS_TARGETS=("google.com" "github.com")
PORT_TARGETS=("github.com:443" "google.com:80")

ok()   { printf "  [ OK ] %s\n" "$1"; }
fail() { printf "  [FAIL] %s\n" "$1"; }

echo "=== 1. Default Gateway ==="
GW="$(ip route 2>/dev/null | awk '/default/ {print $3; exit}')"
if [[ -n "${GW:-}" ]]; then
    if ping -c 2 -W 2 "$GW" &>/dev/null; then ok "Gateway $GW"; else fail "Gateway $GW δεν απαντά"; fi
else
    fail "Δεν βρέθηκε default gateway"
fi

echo; echo "=== 2. Σύνδεση Internet (ICMP) ==="
for t in "${PING_TARGETS[@]}"; do
    if ping -c 2 -W 2 "$t" &>/dev/null; then ok "ping $t"; else fail "ping $t"; fi
done

echo; echo "=== 3. DNS Resolution ==="
for d in "${DNS_TARGETS[@]}"; do
    if getent hosts "$d" &>/dev/null; then
        ok "$d -> $(getent hosts "$d" | awk '{print $1; exit}')"
    else
        fail "Αποτυχία ανάλυσης $d"
    fi
done

echo; echo "=== 4. TCP Θύρες ==="
for hp in "${PORT_TARGETS[@]}"; do
    host="${hp%%:*}"; port="${hp##*:}"
    if timeout 3 bash -c "cat < /dev/null > /dev/tcp/${host}/${port}" 2>/dev/null; then
        ok "${host}:${port} ανοιχτή"
    else
        fail "${host}:${port} μη προσβάσιμη"
    fi
done

echo; echo "=== 5. Τοπικά interfaces ==="
ip -brief address 2>/dev/null || ifconfig
