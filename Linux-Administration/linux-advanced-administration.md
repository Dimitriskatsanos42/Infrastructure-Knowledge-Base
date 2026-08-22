# 🐧 Linux Advanced Administration — Networking, Storage, Security & Troubleshooting

Συμπληρωματικό αρχείο στα `linux-basics.md`, `bash-scripting.md`, `process-management.md`, `systemd-services.md` και `user-permissions-gr.md`. Καλύπτει θέματα που συνήθως λείπουν από ένα βασικό Linux knowledge base: **δίκτυο/firewall, storage/LVM, logging, scheduling, SSH hardening, performance troubleshooting** και **containers**.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Δίκτυο & Firewall](#-1-δίκτυο--firewall)
2. [Package Management (apt / dnf / yum)](#-2-package-management-apt--dnf--yum)
3. [Storage, Partitions & LVM](#-3-storage-partitions--lvm)
4. [Logging & journalctl](#-4-logging--journalctl)
5. [Cron & Task Scheduling](#-5-cron--task-scheduling)
6. [SSH & Security Hardening](#-6-ssh--security-hardening)
7. [Performance Monitoring & Troubleshooting](#-7-performance-monitoring--troubleshooting)
8. [Containers — Docker Βασικά](#-8-containers--docker-βασικά)
9. [Backup Βασικά (rsync, tar, cron)](#-9-backup-βασικά-rsync-tar-cron)
10. [Real-World Troubleshooting Playbooks](#-10-real-world-troubleshooting-playbooks)
11. [Quick Reference — Cheat Sheet](#-11-quick-reference--cheat-sheet)

---

## 🌐 1. Δίκτυο & Firewall

### Βασικός έλεγχος δικτύου
```bash
ip a                          # Εμφάνιση interfaces & IPs
ip route                      # Routing table
ip link set eth0 up/down      # Ενεργοποίηση/απενεργοποίηση interface

ss -tulnp                     # Ενεργές συνδέσεις & ports (αντικαθιστά το παλιό netstat)
ping -c 4 8.8.8.8
traceroute google.com
dig google.com                # DNS lookup
```

### Static IP configuration (Netplan — Ubuntu/Debian)
```yaml
# /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    eth0:
      addresses: [192.168.1.50/24]
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
```
```bash
sudo netplan apply
```

### firewalld (RHEL/CentOS/Fedora)
```bash
firewall-cmd --state
firewall-cmd --zone=public --add-service=ssh --permanent
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --reload
firewall-cmd --list-all
```

### ufw (Ubuntu/Debian)
```bash
sudo ufw enable
sudo ufw allow 22/tcp
sudo ufw allow from 192.168.1.0/24 to any port 3306
sudo ufw status verbose
sudo ufw deny 23
```

### iptables (χαμηλότερο επίπεδο, χρήσιμο να το ξέρεις)
```bash
iptables -L -v -n                                  # Λίστα κανόνων
iptables -A INPUT -p tcp --dport 22 -j ACCEPT       # Allow SSH
iptables -A INPUT -j DROP                           # Drop όλα τα υπόλοιπα
iptables-save > /etc/iptables/rules.v4              # Persist
```

---

## 📦 2. Package Management (apt / dnf / yum)

### Debian/Ubuntu (apt)
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install nginx -y
sudo apt remove nginx
sudo apt autoremove
apt list --installed | grep nginx
apt-cache policy nginx        # Διαθέσιμες εκδόσεις
```

### RHEL/CentOS/Fedora (dnf/yum)
```bash
sudo dnf update -y
sudo dnf install httpd -y
sudo dnf remove httpd
dnf list installed | grep httpd
dnf history                   # Ιστορικό αλλαγών — χρήσιμο για rollback
sudo dnf history undo <ID>
```

### Repositories
```bash
# Debian/Ubuntu — προσθήκη PPA
sudo add-apt-repository ppa:example/ppa
sudo apt update

# RHEL — προσθήκη repo
sudo dnf config-manager --add-repo https://example.com/repo.repo
```

---

## 💽 3. Storage, Partitions & LVM

### Βασική επισκόπηση δίσκων
```bash
lsblk                         # Δέντρο block devices
df -h                         # Χρήση filesystems
du -sh /var/log/*             # Χρήση χώρου ανά directory
fdisk -l                      # Λεπτομέρειες partitions
```

### Δημιουργία partition & filesystem
```bash
sudo fdisk /dev/sdb           # Δημιουργία νέου partition (interactive)
sudo mkfs.ext4 /dev/sdb1
sudo mkdir /data
sudo mount /dev/sdb1 /data

# Persist στο /etc/fstab
echo "/dev/sdb1  /data  ext4  defaults  0  2" | sudo tee -a /etc/fstab
```

### LVM (Logical Volume Manager) — flexibility σε production
```bash
# Δημιουργία physical volume, volume group, logical volume
sudo pvcreate /dev/sdb
sudo vgcreate vg_data /dev/sdb
sudo lvcreate -L 50G -n lv_data vg_data
sudo mkfs.ext4 /dev/vg_data/lv_data
sudo mount /dev/vg_data/lv_data /data

# Επέκταση logical volume χωρίς downtime
sudo lvextend -L +20G /dev/vg_data/lv_data
sudo resize2fs /dev/vg_data/lv_data
```

### Swap management
```bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
free -h
```

---

## 📜 4. Logging & journalctl

### journalctl (systemd logs)
```bash
journalctl -xe                          # Πρόσφατα logs με context
journalctl -u nginx.service             # Logs συγκεκριμένης υπηρεσίας
journalctl --since "1 hour ago"
journalctl --since "2026-08-20 09:00" --until "2026-08-20 10:00"
journalctl -p err                       # Μόνο errors
journalctl -f                           # Live tail (σαν tail -f)
journalctl --disk-usage                 # Πόσο χώρο πιάνουν τα logs
sudo journalctl --vacuum-time=7d        # Καθαρισμός logs παλαιότερα από 7 μέρες
```

### Παραδοσιακά log files
```bash
tail -f /var/log/syslog          # Debian/Ubuntu general log
tail -f /var/log/messages        # RHEL/CentOS general log
tail -f /var/log/auth.log        # Authentication attempts (Debian)
grep "Failed password" /var/log/auth.log | wc -l   # Μέτρηση failed logins
```

### rsyslog — forwarding logs σε κεντρικό server
```bash
# /etc/rsyslog.d/50-forward.conf
*.* @@central-log-server:514
```

---

## ⏰ 5. Cron & Task Scheduling

### Crontab syntax
```
* * * * * command
│ │ │ │ │
│ │ │ │ └── Ημέρα εβδομάδας (0-7, 0 και 7 = Κυριακή)
│ │ │ └──── Μήνας (1-12)
│ │ └────── Ημέρα μήνα (1-31)
│ └──────── Ώρα (0-23)
└────────── Λεπτό (0-59)
```

### Παραδείγματα
```bash
crontab -e                                    # Επεξεργασία cron του χρήστη
crontab -l                                    # Λίστα τρεχόντων cron jobs

# Backup κάθε βράδυ στις 2:00
0 2 * * * /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1

# Καθαρισμός temp files κάθε Κυριακή στις 3:00
0 3 * * 0 find /tmp -type f -mtime +7 -delete

# Κάθε 15 λεπτά
*/15 * * * * /usr/local/bin/healthcheck.sh
```

### systemd timers (μοντέρνα εναλλακτική του cron)
```ini
# /etc/systemd/system/backup.timer
[Unit]
Description=Daily backup timer

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
```
```bash
sudo systemctl enable --now backup.timer
systemctl list-timers
```

---

## 🔐 6. SSH & Security Hardening

### Βασική ασφάλεια SSH (/etc/ssh/sshd_config)
```bash
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
Port 2222                      # Αλλαγή default port (security through obscurity, όχι μόνη λύση)
AllowUsers admin deploy
MaxAuthTries 3
```
```bash
sudo systemctl restart sshd
```

### SSH key-based authentication
```bash
ssh-keygen -t ed25519 -C "admin@srv01"
ssh-copy-id user@remote-host
ssh -i ~/.ssh/id_ed25519 user@remote-host
```

### fail2ban — αυτόματο block brute-force attempts
```bash
sudo apt install fail2ban -y

# /etc/fail2ban/jail.local
[sshd]
enabled = true
maxretry = 5
bantime = 3600
findtime = 600
```
```bash
sudo systemctl restart fail2ban
fail2ban-client status sshd
```

### SELinux (RHEL) βασικά
```bash
getenforce                        # Τρέχουσα κατάσταση
sudo setenforce 1                 # Enforcing mode
sestatus
sudo semanage port -a -t http_port_t -p tcp 8080   # Άνοιγμα custom port για SELinux context
```

---

## 📊 7. Performance Monitoring & Troubleshooting

### Real-time monitoring
```bash
top                                # Classic process viewer
htop                                # Βελτιωμένο, interactive
vmstat 2 5                          # CPU/memory/IO κάθε 2 δευτ, 5 φορές
iostat -x 2                         # Disk I/O statistics
sar -u 1 5                          # CPU utilization (χρειάζεται sysstat)
```

### Εντοπισμός process που "τρώει" resources
```bash
ps aux --sort=-%cpu | head -10      # Top 10 CPU-heavy processes
ps aux --sort=-%mem | head -10      # Top 10 memory-heavy processes
lsof -p <PID>                       # Ανοιχτά αρχεία ενός process
```

### Disk space troubleshooting
```bash
du -h --max-depth=1 / | sort -rh | head -10   # Ποιοι φάκελοι πιάνουν χώρο
find / -xdev -size +500M -exec ls -lh {} \;   # Αρχεία >500MB
```

### Network troubleshooting
```bash
ss -s                                # Σύνοψη socket statistics
tcpdump -i eth0 port 443 -w capture.pcap
nc -zv host 443                      # Έλεγχος αν port είναι ανοιχτό
```

---

## 🐳 8. Containers — Docker Βασικά

```bash
# Εγκατάσταση
curl -fsSL https://get.docker.com | sh
sudo systemctl enable --now docker

# Βασικές εντολές
docker ps                            # Ενεργά containers
docker ps -a                         # Όλα τα containers
docker images                        # Λίστα images
docker run -d -p 8080:80 --name web nginx
docker logs -f web
docker exec -it web bash             # Είσοδος σε running container
docker stop web && docker rm web
```

### Docker Compose παράδειγμα
```yaml
# docker-compose.yml
version: "3.8"
services:
  web:
    image: nginx:latest
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
  db:
    image: mysql:8
    environment:
      MYSQL_ROOT_PASSWORD: examplepass
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
```
```bash
docker compose up -d
docker compose down
```

---

## 💾 9. Backup Βασικά (rsync, tar, cron)

```bash
# rsync — incremental backup σε remote server
rsync -avz --delete /data/ user@backup-server:/backups/data/

# tar — compressed archive
tar -czvf backup-$(date +%F).tar.gz /etc /home

# Αποκατάσταση από tar
tar -xzvf backup-2026-08-20.tar.gz -C /restore/

# Συνδυασμός με cron για αυτοματοποιημένα daily backups
0 1 * * * rsync -avz --delete /data/ user@backup-server:/backups/data/ >> /var/log/rsync-backup.log 2>&1
```

---

## 🎯 10. Real-World Troubleshooting Playbooks

### Playbook: "Ο server έχει γεμίσει δίσκο και δεν ξέρω γιατί"
```bash
df -h                                          # Ποιο filesystem γέμισε
du -h --max-depth=1 / | sort -rh | head -10    # Ποιος φάκελος
journalctl --disk-usage                        # Μήπως τα systemd logs
find / -xdev -size +1G -exec ls -lh {} \;      # Μεγάλα μεμονωμένα αρχεία
```

### Playbook: "Μια υπηρεσία δεν ξεκινάει"
```bash
systemctl status myservice.service      # Πρώτη ματιά
journalctl -u myservice.service -n 50   # Τελευταία 50 logs
systemctl show myservice.service -p ExecStart   # Έλεγχος τι εκτελεί ακριβώς
sudo -u serviceuser /path/to/binary --test      # Δοκιμή manual εκτέλεσης
```

### Playbook: "Ο server είναι αργός, δεν ξέρω αν είναι CPU, RAM ή Disk"
```bash
top                       # Πρώτη ματιά — CPU/mem
vmstat 2 5                # 'wa' column υψηλό = disk I/O bottleneck
iostat -x 2                # Επιβεβαίωση disk bottleneck ανά device
free -h                    # Έλεγχος αν swap χρησιμοποιείται υπερβολικά (κακό σημάδι)
```

### Playbook: "Δεν μπορώ να συνδεθώ μέσω SSH"
```bash
# Από client side
ssh -v user@host                     # Verbose mode δείχνει που κολλάει

# Από server side (αν έχεις console/IPMI access)
systemctl status sshd
journalctl -u sshd -n 50
sudo ufw status / firewall-cmd --list-all    # Μήπως μπλοκάρει το firewall
```

---

## ⚡ 11. Quick Reference — Cheat Sheet

| Σενάριο | Εντολή |
|---|---|
| Δικτυακά interfaces | `ip a` |
| Ενεργές συνδέσεις | `ss -tulnp` |
| Firewall status (ufw) | `ufw status verbose` |
| Firewall status (firewalld) | `firewall-cmd --list-all` |
| Package update (Debian) | `apt update && apt upgrade` |
| Package update (RHEL) | `dnf update` |
| Δίσκοι/partitions | `lsblk` / `df -h` |
| LVM επέκταση | `lvextend -L +20G ...` |
| Logs υπηρεσίας | `journalctl -u service -f` |
| Cron edit | `crontab -e` |
| SSH key setup | `ssh-copy-id user@host` |
| fail2ban status | `fail2ban-client status sshd` |
| Top CPU processes | `ps aux --sort=-%cpu \| head` |
| Docker containers | `docker ps -a` |
| Backup με rsync | `rsync -avz --delete src/ dest/` |

---

*Μέρος του [Infrastructure Knowledge Base](https://github.com/Dimitriskatsanos42/Infrastructure-Knowledge-Base) — φάκελος Linux-Administration. Συμπληρωματικό στα `linux-basics.md`, `bash-scripting.md`, `process-management.md`, `systemd-services.md` και `user-permissions-gr.md`.*
