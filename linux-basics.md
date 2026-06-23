# 🐧 Linux Basics — Filesystem, Permissions & Users

> Τα θεμέλια της διαχείρισης Linux — αυτά τα χρειάζεσαι σε κάθε IT ρόλο.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Filesystem Hierarchy](#-1-filesystem-hierarchy)
2. [Βασικές Εντολές](#-2-βασικές-εντολές)
3. [Permissions & Ownership](#-3-permissions--ownership)
4. [Users & Groups](#-4-users--groups)
5. [Package Management](#-5-package-management)
6. [Networking Commands](#-6-networking-commands)
7. [Logs & Monitoring](#-7-logs--monitoring)

---

## 📁 1. Filesystem Hierarchy

Το Linux ακολουθεί το **FHS (Filesystem Hierarchy Standard)**. Κάθε φάκελος έχει συγκεκριμένο σκοπό:

| Directory | Τι περιέχει |
|-----------|-------------|
| `/` | Root — η αρχή του filesystem |
| `/etc` | Αρχεία ρυθμίσεων (config files) |
| `/var` | Μεταβλητά δεδομένα (logs, spool) |
| `/var/log` | System logs |
| `/home` | Προσωπικοί φάκελοι χρηστών |
| `/root` | Home φάκελος του root user |
| `/bin`, `/usr/bin` | Εκτελέσιμα / εντολές |
| `/sbin`, `/usr/sbin` | Εντολές για administrators |
| `/tmp` | Προσωρινά αρχεία (καθαρίζονται στο reboot) |
| `/proc` | Virtual filesystem — πληροφορίες kernel/processes |
| `/dev` | Device files (δίσκοι, USB, κτλ.) |
| `/opt` | Πρόσθετο λογισμικό τρίτων |
| `/srv` | Data που σερβίρεται από services (web, ftp) |

---

## 💻 2. Βασικές Εντολές

### Πλοήγηση

```bash
pwd                     # Πού βρίσκομαι τώρα;
ls                      # Περιεχόμενα φακέλου
ls -la                  # Λεπτομέρειες + hidden files
cd /etc                 # Μετακίνηση σε φάκελο
cd ..                   # Ένα επίπεδο πιο πάνω
cd ~                    # Πήγαινε στο home dir
```

### Αρχεία & Φάκελοι

```bash
mkdir -p projects/lab1  # Δημιουργία φακέλου (με γονικούς)
touch file.txt          # Δημιουργία κενού αρχείου
cp file.txt backup.txt  # Αντιγραφή
cp -r dir1/ dir2/       # Αντιγραφή φακέλου
mv file.txt /tmp/       # Μετακίνηση / μετονομασία
rm file.txt             # Διαγραφή αρχείου
rm -rf old_dir/         # Διαγραφή φακέλου (ΠΡΟΣΟΧΗ!)
```

### Ανάγνωση Αρχείων

```bash
cat /etc/hosts          # Εμφάνιση όλου του αρχείου
less /var/log/syslog    # Σελίδα-σελίδα (q για έξοδο)
head -20 file.txt       # Πρώτες 20 γραμμές
tail -20 file.txt       # Τελευταίες 20 γραμμές
tail -f /var/log/syslog # Live παρακολούθηση log
grep "error" file.txt   # Αναζήτηση μέσα σε αρχείο
grep -i -r "fail" /var/log/  # Recursive, case-insensitive
```

### System Info

```bash
uname -a                # Πληροφορίες kernel
hostname                # Όνομα υπολογιστή
uptime                  # Πόσο καιρό τρέχει + load
df -h                   # Χώρος δίσκων
du -sh /var/log/*       # Μέγεθος φακέλων
free -h                 # RAM usage
top                     # Real-time CPU/RAM monitor
htop                    # Καλύτερο top (αν εγκατεστημένο)
```

---

## 🔐 3. Permissions & Ownership

### Ανάγνωση Permissions

```
-rwxr-xr-- 1 dimitris admins 4096 Jun 2025 script.sh
 ↑↑↑↑↑↑↑↑↑↑
 ||└─┬─┘└─┬─┘└─┬─┘
 |  Owner Group Others
 └─ Τύπος: - = αρχείο | d = φάκελος | l = symlink
```

| Σύμβολο | Αριθμός | Σημαίνει |
|---------|---------|----------|
| `r` | 4 | Read |
| `w` | 2 | Write |
| `x` | 1 | Execute |
| `-` | 0 | Καμία άδεια |

**Παραδείγματα octal:**

| Octal | Συμβολικό | Σημαίνει |
|-------|-----------|----------|
| `755` | `rwxr-xr-x` | Owner: όλα, Group+Others: read+execute |
| `644` | `rw-r--r--` | Owner: read+write, Others: read only |
| `600` | `rw-------` | Μόνο ο owner βλέπει |
| `777` | `rwxrwxrwx` | Όλοι έχουν όλα — ΜΗΝ το χρησιμοποιείς! |

### chmod — Αλλαγή Permissions

```bash
# Με αριθμούς (octal)
chmod 755 script.sh          # rwxr-xr-x
chmod 644 config.txt         # rw-r--r--
chmod -R 755 /var/www/       # Recursive

# Με γράμματα
chmod u+x script.sh          # Προσθήκη execute στον owner
chmod g-w file.txt           # Αφαίρεση write από group
chmod o=r file.txt           # Others: μόνο read
chmod a+r file.txt           # Όλοι: προσθήκη read
```

### chown — Αλλαγή Ιδιοκτησίας

```bash
chown dimitris file.txt              # Αλλαγή owner
chown dimitris:admins file.txt       # Owner + group
chown -R www-data:www-data /var/www/ # Recursive
chgrp developers project/            # Αλλαγή μόνο group
```

> 🔬 **Lab:** Δημιούργησε ένα script.sh, δες τα default permissions με `ls -la`, πρόσθεσε execute δικαίωμα και τρέξε το.

---

## 👥 4. Users & Groups

### Διαχείριση Χρηστών

```bash
# Δημιουργία
useradd -m -s /bin/bash -G sudo newuser
# -m = δημιούργησε home dir
# -s = καθόρισε shell
# -G = πρόσθεσε σε group

passwd newuser               # Ορισμός κωδικού

# Τροποποίηση
usermod -aG docker newuser   # Πρόσθεσε σε group (χωρίς να αφαιρεθεί από τα άλλα)
usermod -s /bin/zsh newuser  # Αλλαγή shell
usermod -L newuser           # Lock account
usermod -U newuser           # Unlock account

# Διαγραφή
userdel -r olduser           # Διαγραφή user + home dir

# Πληροφορίες
id newuser                   # UID, GID, groups
whoami                       # Τρέχων χρήστης
who                          # Ποιοι είναι συνδεδεμένοι
last                         # Ιστορικό συνδέσεων
cat /etc/passwd              # Όλοι οι χρήστες
```

### Διαχείριση Groups

```bash
groupadd developers          # Δημιουργία group
groupdel developers          # Διαγραφή group
groups newuser               # Groups του χρήστη
getent group sudo            # Μέλη group
cat /etc/group               # Όλα τα groups
```

### sudo — Εκτέλεση ως root

```bash
sudo apt update              # Εκτέλεση ως root
sudo -i                      # Μεταβαίνω σε root shell
sudo -u www-data command     # Εκτέλεση ως άλλος user
sudo visudo                  # Επεξεργασία sudoers (ΜΗΝ χρησιμοποιείς nano!)
```

**Βασικό sudoers entry:**
```
# /etc/sudoers
dimitris    ALL=(ALL:ALL) ALL    # Full sudo access
%admins     ALL=(ALL:ALL) ALL    # Όλη η ομάδα admins
deploy      ALL=(ALL) NOPASSWD: /usr/bin/systemctl   # Χωρίς password για συγκεκριμένη εντολή
```

---

## 📦 5. Package Management

### Ubuntu / Debian (apt)

```bash
apt update                   # Ανανέωση λίστας packages
apt upgrade                  # Αναβάθμιση όλων
apt install nginx            # Εγκατάσταση
apt remove nginx             # Αφαίρεση (κρατάει config)
apt purge nginx              # Αφαίρεση + config files
apt autoremove               # Αφαίρεση περιττών dependencies
apt search "web server"      # Αναζήτηση
apt show nginx               # Πληροφορίες package
dpkg -l | grep nginx         # Εμφάνιση εγκατεστημένων
```

### RHEL / CentOS / Fedora (dnf)

```bash
dnf install nginx
dnf remove nginx
dnf update
dnf search nginx
rpm -qa | grep nginx         # Εγκατεστημένα packages
```

---

## 🌐 6. Networking Commands

```bash
# IP & Interfaces
ip addr show                 # Εμφάνιση IPs (ή: ip a)
ip route show                # Routing table
ip link show                 # Network interfaces

# Connectivity
ping -c 4 google.com
traceroute google.com
curl -I https://google.com   # HTTP headers
wget -q -O /dev/null https://google.com

# DNS
nslookup google.com
dig google.com
dig +short MX gmail.com

# Ports & Connections
ss -tlnp                     # Listening ports (σύγχρονο)
ss -an | grep :80
netstat -tlnp                # Παλαιό αλλά ακόμα χρήσιμο
```

---

## 📋 7. Logs & Monitoring

```bash
# systemd logs
journalctl -xe               # Τελευταία events
journalctl -u nginx          # Logs συγκεκριμένου service
journalctl -f                # Live follow
journalctl --since "1 hour ago"
journalctl --since "2025-06-01" --until "2025-06-20"

# Παραδοσιακά logs
tail -f /var/log/syslog
tail -f /var/log/auth.log
grep "Failed password" /var/log/auth.log

# System resources
df -h                        # Disk usage
du -sh /var/log/*            # Μέγεθος φακέλων
free -h                      # RAM
vmstat 1 5                   # CPU/Memory stats
iostat                       # Disk I/O stats
```

---

## 📚 Πηγές Μελέτης

- [Linux Journey](https://linuxjourney.com) — Δωρεάν interactive learning
- [The Linux Command Line](https://linuxcommand.org/tlcl.php) — Δωρεάν βιβλίο PDF
- [OverTheWire: Bandit](https://overthewire.org/wargames/bandit/) — Gamified Linux learning

> 🔬 **Lab Coming Soon:** Setup Ubuntu Server σε VirtualBox, δημιουργία users, ρύθμιση SSH key-based auth, εγκατάσταση nginx.
