# ⚙️ systemd & Services Management

> Πώς το Linux ξεκινά, σταματά και παρακολουθεί services — το σύστημα που τρέχει σε κάθε σύγχρονη διανομή.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Τι είναι το systemd;](#-1-τι-είναι-το-systemd)
2. [systemctl — Διαχείριση Services](#-2-systemctl--διαχείριση-services)
3. [journalctl — Logs](#-3-journalctl--logs)
4. [Δημιουργία Custom Service](#-4-δημιουργία-custom-service)
5. [Targets (Runlevels)](#-5-targets-runlevels)
6. [Χρήσιμα Παραδείγματα](#-6-χρήσιμα-παραδείγματα)

---

## 📌 1. Τι είναι το systemd;

Το **systemd** είναι το init system και service manager που χρησιμοποιεί το σύγχρονο Linux. Είναι η **πρώτη διεργασία** που τρέχει κατά το boot (PID 1) και υπεύθυνη για:

- Εκκίνηση/διακοπή services
- Διαχείριση logs (journald)
- Mount filesystems
- Διαχείριση network interfaces

```ini
Kernel boot
    ↓
systemd (PID 1)
    ↓
Εκκίνηση services παράλληλα
    ↓
Login prompt
```

---

## 🔧 2. systemctl — Διαχείριση Services

### Βασικές Εντολές

```bash
# Κατάσταση
systemctl status nginx            # Λεπτομερής κατάσταση service
systemctl is-active nginx         # Τρέχει; (active/inactive)
systemctl is-enabled nginx        # Ξεκινά στο boot; (enabled/disabled)

# Εκκίνηση / Διακοπή
systemctl start nginx             # Εκκίνηση
systemctl stop nginx              # Διακοπή
systemctl restart nginx           # Επανεκκίνηση
systemctl reload nginx            # Reload config (χωρίς διακοπή)
systemctl reload-or-restart nginx # Reload αν υποστηρίζεται, αλλιώς restart

# Autostart
systemctl enable nginx            # Ενεργοποίηση κατά το boot
systemctl disable nginx           # Απενεργοποίηση κατά το boot
systemctl enable --now nginx      # Enable + αμέσως start

# Εμφάνιση services
systemctl list-units --type=service              # Όλα τα services
systemctl list-units --type=service --state=running  # Μόνο τα ενεργά
systemctl list-unit-files --type=service         # Enabled/disabled κατάσταση
```

### Ανάγνωση systemctl status

```yaml
● nginx.service - A high performance web server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled; ...)
     Active: active (running) since Mon 2025-06-20 10:00:00 UTC; 2h ago
    Process: 1234 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
   Main PID: 1235 (nginx)
      Tasks: 2 (limit: 2309)
     Memory: 5.1M
        CPU: 23ms
     CGroup: /system.slice/nginx.service
             ├─1235 "nginx: master process /usr/sbin/nginx -g daemon off;"
             └─1236 "nginx: worker process"
```

| Πεδίο | Σημασία |
|-------|---------|
| `Loaded` | Unit file φορτώθηκε + enabled/disabled |
| `Active: active (running)` | Τρέχει κανονικά |
| `Active: failed` | Κατέρρευσε — δες τα logs! |
| `Active: inactive (dead)` | Σταματημένο |
| `Main PID` | Process ID του κύριου process |

---

## 📋 3. journalctl — Logs

Το **journald** είναι το logging subsystem του systemd. Αποθηκεύει logs σε binary format (εύκολη αναζήτηση/φιλτράρισμα).

### Βασικές Εντολές

```bash
# Γενικά logs
journalctl                        # Όλα τα logs (από την αρχή)
journalctl -e                     # Τελευταία logs (jump to end)
journalctl -f                     # Live follow (όπως tail -f)
journalctl -n 50                  # Τελευταίες 50 γραμμές

# Φιλτράρισμα ανά service
journalctl -u nginx               # Logs για nginx
journalctl -u nginx -f            # Live nginx logs
journalctl -u nginx --since "1 hour ago"

# Φιλτράρισμα ανά χρόνο
journalctl --since "2025-06-20 09:00:00"
journalctl --since "2025-06-20" --until "2025-06-21"
journalctl --since "1 hour ago"
journalctl --since "yesterday"

# Φιλτράρισμα ανά priority
journalctl -p err                 # Μόνο errors
journalctl -p warning             # Warnings και πιο σοβαρά
journalctl -u nginx -p err        # Nginx errors

# Boot logs
journalctl -b                     # Τρέχον boot
journalctl -b -1                  # Προηγούμενο boot
journalctl --list-boots           # Λίστα boots

# Output format
journalctl -u nginx --no-pager    # Χωρίς pagination
journalctl -u nginx -o json       # JSON format
journalctl -u nginx -o short-precise  # Ακριβής timestamp
```

### Priority Levels

| Level | Αριθμός | Σημασία |
|-------|---------|---------|
| emerg | 0 | Σύστημα μη λειτουργικό |
| alert | 1 | Άμεση δράση απαιτείται |
| crit | 2 | Κρίσιμη κατάσταση |
| err | 3 | Σφάλμα |
| warning | 4 | Προειδοποίηση |
| notice | 5 | Κανονικό αλλά αξιοσημείωτο |
| info | 6 | Πληροφορία |
| debug | 7 | Debug μηνύματα |

---

## 📝 4. Δημιουργία Custom Service

Όταν θέλεις να τρέχει ένα πρόγραμμα αυτόματα σαν service:

### Unit File Structure

```ini
# /etc/systemd/system/myapp.service

[Unit]
Description=My Custom Application
After=network.target          # Ξεκίνα αφού φορτωθεί το δίκτυο

[Service]
Type=simple
User=myappuser                # Τρέξε ως αυτόν τον user (ΟΧΙ root)
WorkingDirectory=/opt/myapp
ExecStart=/opt/myapp/start.sh
Restart=on-failure            # Επανεκκίνηση αν πέσει
RestartSec=5                  # Περίμενε 5 δευτερόλεπτα πριν restart

# Logging
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target    # Ξεκίνα στο normal boot
```

### Εγκατάσταση Custom Service

```bash
# 1. Δημιούργησε το unit file
sudo nano /etc/systemd/system/myapp.service

# 2. Ενημέρωσε το systemd για το νέο αρχείο
sudo systemctl daemon-reload

# 3. Ενεργοποίηση + εκκίνηση
sudo systemctl enable --now myapp

# 4. Έλεγχος
sudo systemctl status myapp
journalctl -u myapp -f
```

---

## 🎯 5. Targets (Runlevels)

Τα **targets** ορίζουν σε ποιο "επίπεδο λειτουργίας" βρίσκεται το σύστημα:

| Target | Παλιό Runlevel | Χρήση |
|--------|----------------|-------|
| `poweroff.target` | 0 | Απενεργοποίηση |
| `rescue.target` | 1 | Single-user mode |
| `multi-user.target` | 3 | Κανονικό — χωρίς GUI |
| `graphical.target` | 5 | Κανονικό — με GUI |
| `reboot.target` | 6 | Επανεκκίνηση |

```bash
systemctl get-default           # Ποιο target boot από default
systemctl set-default multi-user.target   # Αλλαγή default
systemctl isolate rescue.target  # Άμεση αλλαγή τώρα
```

---

## 💡 6. Χρήσιμα Παραδείγματα

```bash
# Έλεγχος γιατί ένα service απέτυχε
systemctl status myapp --no-pager
journalctl -u myapp -n 50 --no-pager

# Εύρεση services που απέτυχαν στο boot
systemctl --failed

# Restart service αυτόματα κάθε βράδυ (με systemd timer)
# Βλ. /etc/systemd/system/myapp-restart.timer

# Παρακολούθηση πολλών services ταυτόχρονα
watch -n 2 'systemctl status nginx ssh ufw | grep -E "Active:|●"'

# Γρήγορος έλεγχος κατάστασης πολλών services
for svc in nginx ssh ufw fail2ban; do
    echo "$svc: $(systemctl is-active $svc)"
done
```
