# 🔧 Bash Scripting

> Αυτοματοποίηση εργασιών με Bash — από loops και conditionals μέχρι cron jobs και πρακτικά scripts.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Δομή Script](#-1-δομή-script)
2. [Μεταβλητές](#-2-μεταβλητές)
3. [Input & Output](#-3-input--output)
4. [Conditionals (if/case)](#-4-conditionals-ifcase)
5. [Loops](#-5-loops)
6. [Functions](#-6-functions)
7. [Error Handling](#-7-error-handling)
8. [Cron Jobs](#-8-cron-jobs)
9. [Πρακτικά Scripts](#-9-πρακτικά-scripts)

---

## 📄 1. Δομή Script

```bash
#!/bin/bash
# ============================================
# Script: example.sh
# Περιγραφή: Τι κάνει αυτό το script
# Author: Dimitris Katsanos
# Date: 2026-06-20
# Usage: ./example.sh [argument]
# ============================================

set -e    # Σταμάτα αν κάποια εντολή αποτύχει
set -u    # Σφάλμα αν χρησιμοποιηθεί undefined variable
set -o pipefail  # Σφάλμα αν αποτύχει εντολή μέσα σε pipe

# Κώδικας εδώ...
echo "Script ξεκίνησε"
```

```bash
# Κάνε το script εκτελέσιμο
chmod +x example.sh

# Εκτέλεση
./example.sh
bash example.sh
```

---

## 📦 2. Μεταβλητές

```bash
# Ορισμός μεταβλητών (ΔΕΝ υπάρχουν κενά γύρω από το =)
NAME="Dimitris"
AGE=25
LOG_FILE="/var/log/myscript.log"

# Χρήση μεταβλητής
echo "Γεια σου, $NAME"
echo "Ηλικία: ${AGE} χρονών"    # Με {} για ασφάλεια

# Command substitution — αποθήκευση output εντολής
HOSTNAME=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}')

# Read-only μεταβλητές
readonly MAX_RETRIES=3

# Μαθηματικά
COUNT=10
RESULT=$((COUNT * 2 + 5))   # Αριθμητική
echo "Αποτέλεσμα: $RESULT"

# String operations
TEXT="Hello World"
echo ${#TEXT}           # Μήκος: 11
echo ${TEXT,,}          # Lowercase: hello world
echo ${TEXT^^}          # Uppercase: HELLO WORLD
echo ${TEXT/World/Linux}  # Replace: Hello Linux
```

### Special Variables

```bash
$0      # Όνομα script
$1, $2  # Arguments (1ο, 2ο)
$@      # Όλα τα arguments ως λίστα
$#      # Αριθμός arguments
$?      # Exit code προηγούμενης εντολής (0 = επιτυχία)
$$      # PID του τρέχοντος script
$USER   # Τρέχων χρήστης
$HOME   # Home directory
$PWD    # Τρέχων φάκελος
```

---

## 📥 3. Input & Output

```bash
# Ανάγνωση input από χρήστη
read -p "Δώσε το όνομά σου: " NAME
read -s -p "Δώσε κωδικό: " PASSWORD  # -s = silent (δεν εμφανίζεται)
echo ""   # Νέα γραμμή μετά το silent read

# Εκτύπωση με χρώματα
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color

echo -e "${GREEN}✓ Επιτυχία${NC}"
echo -e "${RED}✗ Σφάλμα${NC}"
echo -e "${YELLOW}⚠ Προειδοποίηση${NC}"

# Redirect output
echo "Log entry" >> /var/log/myapp.log   # Append σε αρχείο
echo "Error msg" >&2                      # Stderr
command > /dev/null 2>&1                  # Suppress all output
```

---

## 🔀 4. Conditionals (if/case)

```bash
# Βασικό if
if [ "$NAME" == "Dimitris" ]; then
    echo "Γεια σου Δημήτρη!"
elif [ "$NAME" == "Giorgos" ]; then
    echo "Γεια σου Γιώργη!"
else
    echo "Γεια σου $NAME!"
fi

# Έλεγχος αρχείων
if [ -f "/etc/nginx/nginx.conf" ]; then
    echo "Το αρχείο υπάρχει"
fi

if [ -d "/var/log" ]; then
    echo "Ο φάκελος υπάρχει"
fi

if [ ! -f "/tmp/lock" ]; then
    echo "Το lock file ΔΕΝ υπάρχει"
fi
```

### Συγκρίσεις

| Strings | Αριθμοί | Σημαίνει |
|---------|---------|----------|
| `==` | `-eq` | Ίσο |
| `!=` | `-ne` | Διαφορετικό |
| — | `-lt` | Μικρότερο |
| — | `-gt` | Μεγαλύτερο |
| — | `-le` | Μικρότερο ή ίσο |
| — | `-ge` | Μεγαλύτερο ή ίσο |

```bash
# Αριθμητική σύγκριση
if [ $AGE -ge 18 ]; then
    echo "Ενήλικας"
fi

# Έλεγχος κατάστασης service
if systemctl is-active --quiet nginx; then
    echo "Nginx τρέχει"
else
    echo "Nginx είναι εκτός λειτουργίας"
fi

# case statement
case "$1" in
    start)
        echo "Εκκίνηση..."
        systemctl start myapp
        ;;
    stop)
        echo "Διακοπή..."
        systemctl stop myapp
        ;;
    restart)
        systemctl restart myapp
        ;;
    *)
        echo "Χρήση: $0 {start|stop|restart}"
        exit 1
        ;;
esac
```

---

## 🔄 5. Loops

```bash
# for loop — λίστα τιμών
for name in Alice Bob Charlie; do
    echo "Γεια σου, $name!"
done

# for loop — αριθμοί
for i in {1..5}; do
    echo "Αριθμός $i"
done

# for loop — αρχεία
for file in /var/log/*.log; do
    echo "Log file: $file"
    wc -l "$file"
done

# C-style for loop
for ((i=0; i<10; i++)); do
    echo "i = $i"
done

# while loop
COUNT=0
while [ $COUNT -lt 5 ]; do
    echo "Count: $COUNT"
    ((COUNT++))
done

# while loop — διάβασε γραμμές από αρχείο
while IFS= read -r line; do
    echo "Γραμμή: $line"
done < /etc/hosts

# Loop με services
for SERVICE in nginx ssh ufw fail2ban; do
    STATUS=$(systemctl is-active "$SERVICE" 2>/dev/null || echo "not-installed")
    printf "%-15s %s\n" "$SERVICE:" "$STATUS"
done
```

---

## 🔨 6. Functions

```bash
# Ορισμός function
log() {
    local TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    local MESSAGE="$1"
    echo "[$TIMESTAMP] $MESSAGE" | tee -a /var/log/myscript.log
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Αυτό το script χρειάζεται root." >&2
        exit 1
    fi
}

service_status() {
    local SERVICE="$1"
    if systemctl is-active --quiet "$SERVICE"; then
        echo -e "${GREEN}✓ $SERVICE: running${NC}"
        return 0
    else
        echo -e "${RED}✗ $SERVICE: not running${NC}"
        return 1
    fi
}

# Κλήση functions
check_root
log "Script ξεκίνησε"
service_status nginx
```

---

## ⚠️ 7. Error Handling

```bash
#!/bin/bash
set -euo pipefail

# Trap για cleanup αν σκοτωθεί το script
cleanup() {
    echo "Cleanup..."
    rm -f /tmp/myscript.lock
}
trap cleanup EXIT INT TERM

# Έλεγχος exit code
if ! systemctl restart nginx; then
    echo "ERROR: Αποτυχία restart nginx" >&2
    exit 1
fi

# Retry logic
retry() {
    local RETRIES=3
    local DELAY=5
    local CMD="$@"

    for ((i=1; i<=RETRIES; i++)); do
        if $CMD; then
            return 0
        fi
        echo "Προσπάθεια $i/$RETRIES απέτυχε. Αναμονή ${DELAY}s..."
        sleep $DELAY
    done
    echo "Όλες οι προσπάθειες απέτυχαν." >&2
    return 1
}

retry systemctl start myapp
```

---

## ⏰ 8. Cron Jobs

Το **cron** εκτελεί εντολές αυτόματα σε χρονοπρογραμματισμένα διαστήματα.

### Σύνταξη

```
* * * * * command
│ │ │ │ │
│ │ │ │ └── Ημέρα εβδομάδας (0-7, 0/7=Κυριακή)
│ │ │ └──── Μήνας (1-12)
│ │ └────── Ημέρα μήνα (1-31)
│ └──────── Ώρα (0-23)
└────────── Λεπτό (0-59)
```

### Παραδείγματα

```bash
# Επεξεργασία crontab
crontab -e    # Επεξεργασία
crontab -l    # Εμφάνιση
crontab -r    # Διαγραφή όλων

# Παραδείγματα cron entries:
# Κάθε λεπτό
* * * * * /opt/scripts/check.sh

# Κάθε μέρα στις 2:00 πρωί
0 2 * * * /opt/scripts/backup.sh

# Κάθε Δευτέρα στις 9:00
0 9 * * 1 /opt/scripts/weekly-report.sh

# Κάθε 15 λεπτά
*/15 * * * * /opt/scripts/monitor.sh

# 1η κάθε μήνα στις 00:00
0 0 1 * * /opt/scripts/monthly-cleanup.sh

# Αποθήκευση output σε log
0 2 * * * /opt/scripts/backup.sh >> /var/log/backup.log 2>&1
```

---

## 🛠️ 9. Πρακτικά Scripts

### System Health Check

```bash
#!/bin/bash
# system-health-check.sh — Ελέγχει την υγεία του συστήματος

set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
THRESHOLD_CPU=80; THRESHOLD_DISK=85; THRESHOLD_MEM=90

ok()   { echo -e "${GREEN}✓ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
fail() { echo -e "${RED}✗ $1${NC}"; }

echo "=== System Health Check — $(hostname) — $(date) ==="
echo ""

# CPU Load
LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')
CORES=$(nproc)
LOAD_PCT=$(echo "$LOAD $CORES" | awk '{printf "%d", ($1/$2)*100}')
if [ "$LOAD_PCT" -lt "$THRESHOLD_CPU" ]; then
    ok "CPU Load: ${LOAD} (${LOAD_PCT}% of capacity)"
else
    warn "CPU Load HIGH: ${LOAD} (${LOAD_PCT}% of capacity)"
fi

# Memory
MEM_FREE=$(free | awk '/Mem:/{printf "%d", ($3/$2)*100}')
if [ "$MEM_FREE" -lt "$THRESHOLD_MEM" ]; then
    ok "Memory Usage: ${MEM_FREE}%"
else
    fail "Memory Usage HIGH: ${MEM_FREE}%"
fi

# Disk
DISK=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
if [ "$DISK" -lt "$THRESHOLD_DISK" ]; then
    ok "Disk Usage: ${DISK}%"
else
    fail "Disk Usage HIGH: ${DISK}%"
fi

# Services
echo ""
echo "--- Services ---"
for SERVICE in nginx ssh ufw; do
    if systemctl is-active --quiet "$SERVICE" 2>/dev/null; then
        ok "$SERVICE: running"
    else
        fail "$SERVICE: NOT running"
    fi
done

echo ""
echo "=== Ολοκληρώθηκε ==="
```

> 🔬 **Lab:** Αντέγραψε αυτό το script, κάνε το εκτελέσιμο, πρόσθεσέ το ως cron job κάθε πρωί στις 8:00 και δες το output να αποθηκεύεται σε log file.


