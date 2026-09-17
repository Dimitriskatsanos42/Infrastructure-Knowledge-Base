# ⚙️ Ansible — Configuration Management σε Βάθος

Έβδομο αρχείο του φακέλου **DevOps**. Το Terraform (προηγούμενο αρχείο) **δημιουργεί** υποδομή (VMs, δίκτυα)· το **Ansible ρυθμίζει τι τρέχει μέσα** σε αυτή — εγκατάσταση πακέτων, ρύθμιση αρχείων, deployment εφαρμογών. Συνδέεται άμεσα με τις δεξιότητες που ήδη έχεις στο `bash-scripting.md` και `windows-advanced-troubleshooting-automation.md` — το Ansible είναι, ουσιαστικά, **οργανωμένη, επαναλαμβανόμενη αυτοματοποίηση** πάνω σε αυτά που ήδη κάνεις χειροκίνητα.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Γιατί Ansible — Agentless Προσέγγιση](#-1-γιατί-ansible--agentless-προσέγγιση)
2. [Βασικές Έννοιες](#-2-βασικές-έννοιες)
3. [Inventory — Ποιους Servers Διαχειρίζεσαι](#-3-inventory--ποιους-servers-διαχειρίζεσαι)
4. [Ad-Hoc Commands](#-4-ad-hoc-commands)
5. [Playbooks — Η Καρδιά του Ansible](#-5-playbooks--η-καρδιά-του-ansible)
6. [Variables & Facts](#-6-variables--facts)
7. [Templates (Jinja2)](#-7-templates-jinja2)
8. [Handlers — Ενέργειες σε Αλλαγές](#-8-handlers--ενέργειες-σε-αλλαγές)
9. [Roles — Οργάνωση σε Scale](#-9-roles--οργάνωση-σε-scale)
10. [Ansible Vault — Διαχείριση Secrets](#-10-ansible-vault--διαχείριση-secrets)
11. [Ansible σε Windows](#-11-ansible-σε-windows)
12. [Ansible σε CI/CD & Best Practices](#-12-ansible-σε-cicd--best-practices)
13. [Πλήρες Παράδειγμα — Web Server Provisioning](#-13-πλήρες-παράδειγμα--web-server-provisioning)

---

## 🤔 1. Γιατί Ansible — Agentless Προσέγγιση

| | Ansible | Puppet/Chef (agent-based) |
|---|---|---|
| Απαιτεί agent στο target | ❌ Όχι — μόνο SSH (Linux) ή WinRM (Windows) | ✅ Ναι — πρέπει να εγκατασταθεί σε κάθε node |
| Ξεκίνημα | Γρήγορο — αν έχεις ήδη SSH access, είσαι έτοιμος | Πιο αργό — deployment agent σε κάθε server πρώτα |
| Γλώσσα | YAML (πολύ αναγνώσιμο, χαμηλό learning curve) | Ruby DSL (Puppet/Chef) |
| Push vs Pull | **Push** — ο control node στέλνει εντολές | Συνήθως **Pull** — τα agents τραβάνε ρυθμίσεις περιοδικά |

### Γιατί το agentless είναι σημαντικό
```
Με agent-based:
1. Πρέπει να εγκαταστήσεις agent σε ΚΑΘΕ server (chicken-and-egg πρόβλημα:
   πώς αυτοματοποιείς την εγκατάσταση του εργαλείου αυτοματοποίησης;)

Με Ansible (agentless):
1. Ο server χρειάζεται μόνο SSH (Linux) ήδη ενεργό — που έχει ούτως ή άλλως
2. Το Ansible συνδέεται, τρέχει Python κώδικα προσωρινά, αποσυνδέεται
3. Καμία μόνιμη παρουσία λογισμικού στο target server
```

---

## 📖 2. Βασικές Έννοιες

| Όρος | Σημασία |
|---|---|
| **Control Node** | Το μηχάνημα όπου εγκαθιστάς/τρέχεις το Ansible |
| **Managed Node** | Ο server που ρυθμίζεται (δεν χρειάζεται Ansible εγκατεστημένο) |
| **Inventory** | Λίστα των managed nodes (ποιοι servers, ομαδοποιημένοι) |
| **Module** | Μονάδα κώδικα που κάνει μια συγκεκριμένη δουλειά (πχ `apt`, `copy`, `service`) |
| **Task** | Μία εκτέλεση ενός module με συγκεκριμένες παραμέτρους |
| **Playbook** | Αρχείο YAML με λίστα tasks — το "script" του Ansible |
| **Role** | Οργανωμένη συλλογή playbooks/tasks/templates για επαναχρησιμοποίηση |
| **Idempotency** | Τρέχοντας το ίδιο playbook πολλές φορές, το αποτέλεσμα είναι πάντα το ίδιο (δεν κάνει διπλή εγκατάσταση κλπ.) |

---

## 📋 3. Inventory — Ποιους Servers Διαχειρίζεσαι

### Static Inventory (απλό αρχείο)
```ini
# inventory.ini
[webservers]
web01.contoso.local ansible_host=192.168.1.10
web02.contoso.local ansible_host=192.168.1.11

[dbservers]
db01.contoso.local ansible_host=192.168.1.20

[production:children]
webservers
dbservers

[webservers:vars]
ansible_user=deploy
ansible_ssh_private_key_file=~/.ssh/id_ed25519
```

### YAML format (εναλλακτικό)
```yaml
# inventory.yml
all:
  children:
    webservers:
      hosts:
        web01.contoso.local:
        web02.contoso.local:
      vars:
        ansible_user: deploy
    dbservers:
      hosts:
        db01.contoso.local:
```

### Δυναμικό Inventory (για cloud — Azure/AWS)
```bash
# Αντί για στατική λίστα, το inventory "ρωτάει" το Azure API
# ποιες VMs υπάρχουν αυτή τη στιγμή, με ποια tags
ansible-inventory -i azure_rm.yml --list
```

### Έλεγχος connectivity
```bash
ansible all -i inventory.ini -m ping
# Αν όλα OK: "pong" από κάθε server, χωρίς να τρέξει κανένα playbook ακόμα
```

---

## 🎯 4. Ad-Hoc Commands

Γρήγορες, one-off εντολές χωρίς να γράψεις playbook — χρήσιμο για γρήγορους ελέγχους ή διορθώσεις.

```bash
# Ping όλων των servers
ansible all -i inventory.ini -m ping

# Τρέξε εντολή shell σε όλους τους webservers
ansible webservers -i inventory.ini -a "uptime"

# Έλεγχος disk space
ansible all -i inventory.ini -a "df -h"

# Εγκατάσταση πακέτου (module: apt)
ansible webservers -i inventory.ini -m apt -a "name=nginx state=present" --become

# Restart service
ansible webservers -i inventory.ini -m service -a "name=nginx state=restarted" --become

# Αντιγραφή αρχείου
ansible webservers -i inventory.ini -m copy -a "src=./app.conf dest=/etc/nginx/app.conf" --become
```

> `--become` = εκτέλεση με sudo/elevated δικαιώματα (αντίστοιχο του "Run as Administrator").

---

## 📜 5. Playbooks — Η Καρδιά του Ansible

Ένα playbook είναι μια **λίστα tasks**, γραμμένη σε YAML, που εκτελείται με τη σειρά.

```yaml
# webserver-setup.yml
---
- name: Ρύθμιση Web Servers
  hosts: webservers
  become: true

  tasks:
    - name: Εγκατάσταση Nginx
      apt:
        name: nginx
        state: present
        update_cache: true

    - name: Έναρξη και ενεργοποίηση Nginx
      service:
        name: nginx
        state: started
        enabled: true

    - name: Αντιγραφή custom config
      copy:
        src: files/nginx.conf
        dest: /etc/nginx/nginx.conf
        owner: root
        group: root
        mode: '0644'
      notify: Restart Nginx      # Θα ενεργοποιήσει τον handler (βλ. κεφάλαιο 8)

    - name: Άνοιγμα firewall port 80
      ufw:
        rule: allow
        port: '80'
        proto: tcp

  handlers:
    - name: Restart Nginx
      service:
        name: nginx
        state: restarted
```

### Εκτέλεση playbook
```bash
ansible-playbook -i inventory.ini webserver-setup.yml

# Dry-run (δείχνει τι ΘΑ άλλαζε, χωρίς να το κάνει — σαν terraform plan)
ansible-playbook -i inventory.ini webserver-setup.yml --check

# Μόνο σε συγκεκριμένο host
ansible-playbook -i inventory.ini webserver-setup.yml --limit web01.contoso.local

# Verbose output (χρήσιμο για debugging)
ansible-playbook -i inventory.ini webserver-setup.yml -vvv
```

### Βασικά modules που θα χρησιμοποιείς συχνά

| Module | Σκοπός |
|---|---|
| `apt` / `yum` / `dnf` | Package management (βλ. `linux-advanced-administration.md`) |
| `copy` / `template` | Αντιγραφή αρχείων |
| `service` / `systemd` | Έλεγχος υπηρεσιών |
| `file` | Δημιουργία/διαγραφή φακέλων, δικαιώματα |
| `user` / `group` | Διαχείριση χρηστών |
| `lineinfile` | Τροποποίηση συγκεκριμένης γραμμής σε αρχείο |
| `git` | Clone/update repository |
| `docker_container` | Διαχείριση Docker containers |
| `win_*` | Ισοδύναμα modules για Windows (βλ. κεφάλαιο 11) |

---

## 🔤 6. Variables & Facts

### Variables σε playbook
```yaml
- name: Εγκατάσταση με variable
  hosts: webservers
  vars:
    nginx_port: 8080
    app_version: "2.1.0"

  tasks:
    - name: Δείξε την τιμή
      debug:
        msg: "Εγκατάσταση nginx στο port {{ nginx_port }}, version {{ app_version }}"
```

### Variables σε ξεχωριστό αρχείο
```yaml
# group_vars/webservers.yml
nginx_port: 8080
max_connections: 1000
```

### Facts — αυτόματα συλλεγμένη πληροφορία για κάθε server
```bash
ansible webserver01 -i inventory.ini -m setup    # Δείχνει ΟΛΑ τα facts (τεράστια λίστα)
```
```yaml
- name: Χρήση fact μέσα σε task
  debug:
    msg: "Αυτός ο server έχει {{ ansible_memtotal_mb }}MB RAM και τρέχει {{ ansible_distribution }}"
```

### Conditionals με facts
```yaml
- name: Εγκατάσταση μόνο σε Ubuntu
  apt:
    name: nginx
    state: present
  when: ansible_distribution == "Ubuntu"

- name: Εγκατάσταση μόνο σε RHEL-based
  yum:
    name: nginx
    state: present
  when: ansible_os_family == "RedHat"
```

---

## 🎨 7. Templates (Jinja2)

Δυναμικά αρχεία ρύθμισης, με μεταβλητές που αντικαθίστανται ανά server/environment.

```jinja2
{# templates/nginx.conf.j2 #}
server {
    listen {{ nginx_port }};
    server_name {{ inventory_hostname }};

    location / {
        proxy_pass http://127.0.0.1:{{ app_port }};
    }

    {% if environment == "production" %}
    ssl_certificate /etc/ssl/certs/{{ inventory_hostname }}.crt;
    {% endif %}
}
```

```yaml
- name: Εφαρμογή template ρύθμισης
  template:
    src: templates/nginx.conf.j2
    dest: /etc/nginx/sites-available/myapp.conf
  notify: Restart Nginx
```

### Loops μέσα σε templates
```jinja2
{% for user in allowed_users %}
allow {{ user }};
{% endfor %}
```

---

## 🔔 8. Handlers — Ενέργειες σε Αλλαγές

Οι **handlers** τρέχουν **μόνο αν** κάτι πραγματικά άλλαξε (idempotency στην πράξη) — π.χ. restart μιας υπηρεσίας **μόνο** αν το config file της άλλαξε, όχι σε κάθε εκτέλεση του playbook.

```yaml
tasks:
  - name: Ενημέρωση config
    template:
      src: app.conf.j2
      dest: /etc/app/app.conf
    notify: Restart App      # Ενεργοποιεί τον handler ΜΟΝΟ αν το αρχείο άλλαξε

handlers:
  - name: Restart App
    service:
      name: myapp
      state: restarted
```

> Αν τρέξεις το playbook 2 φορές στη σειρά και τίποτα δεν άλλαξε τη 2η φορά, ο handler **δεν** θα τρέξει — κανένα περιττό restart υπηρεσίας.

---

## 📁 9. Roles — Οργάνωση σε Scale

Καθώς μεγαλώνουν τα playbooks, τα **roles** τα οργανώνουν σε επαναχρησιμοποιήσιμα, καλά δομημένα πακέτα.

### Δομή role
```
roles/
└── nginx/
    ├── tasks/
    │   └── main.yml
    ├── handlers/
    │   └── main.yml
    ├── templates/
    │   └── nginx.conf.j2
    ├── files/
    │   └── static-file.txt
    ├── vars/
    │   └── main.yml
    └── defaults/
        └── main.yml        # Default τιμές (χαμηλότερη προτεραιότητα)
```

### Χρήση role σε playbook
```yaml
# site.yml
---
- name: Ρύθμιση όλης της υποδομής
  hosts: all
  become: true
  roles:
    - common          # Βασικές ρυθμίσεις όλων των servers
    - nginx           # Μόνο για webservers
    - { role: postgres, when: "'dbservers' in group_names" }
```

### Δημιουργία σκελετού role
```bash
ansible-galaxy init roles/nginx
```

### Community roles (Ansible Galaxy)
```bash
ansible-galaxy install geerlingguy.nginx
ansible-galaxy install -r requirements.yml    # Πολλαπλά roles από αρχείο
```

---

## 🔐 10. Ansible Vault — Διαχείριση Secrets

Κρυπτογραφεί ευαίσθητα δεδομένα (passwords, API keys) μέσα στα YAML αρχεία.

```bash
# Δημιουργία κρυπτογραφημένου αρχείου
ansible-vault create secrets.yml
# Θα ζητήσει password, μετά ανοίγει editor

# Επεξεργασία υπάρχοντος
ansible-vault edit secrets.yml

# Προβολή περιεχομένου
ansible-vault view secrets.yml

# Κρυπτογράφηση ήδη υπάρχοντος αρχείου
ansible-vault encrypt vars/production.yml
```

```yaml
# secrets.yml (το περιεχόμενο μετά την αποκρυπτογράφηση)
db_password: "SuperSecretPass123"
api_key: "abc123xyz"
```

### Χρήση σε playbook
```bash
ansible-playbook site.yml --ask-vault-pass
# Ή με αρχείο password (ΠΟΤΕ committed στο git!)
ansible-playbook site.yml --vault-password-file ~/.vault_pass.txt
```

---

## 🪟 11. Ansible σε Windows

Το Ansible διαχειρίζεται και Windows servers, μέσω **WinRM** αντί για SSH — σύνδεση με το `windows-virtualization-clustering-infrastructure.md` υλικό σου.

### Ρύθμιση WinRM στο Windows target (μία φορά)
```powershell
# Στο Windows server (PowerShell as Administrator)
winrm quickconfig
Enable-PSRemoting -Force
```

### Inventory για Windows hosts
```ini
[windows]
win-srv01.contoso.local

[windows:vars]
ansible_connection=winrm
ansible_winrm_transport=ntlm
ansible_user=Administrator
ansible_password=SecurePassword123
ansible_port=5985
```

### Παράδειγμα playbook για Windows
```yaml
---
- name: Ρύθμιση Windows Server
  hosts: windows
  tasks:
    - name: Εγκατάσταση IIS
      win_feature:
        name: Web-Server
        state: present

    - name: Δημιουργία φακέλου εφαρμογής
      win_file:
        path: C:\inetpub\myapp
        state: directory

    - name: Restart υπηρεσίας
      win_service:
        name: W3SVC
        state: restarted
```

---

## 🚀 12. Ansible σε CI/CD & Best Practices

### Ansible μέσα σε GitHub Actions pipeline
```yaml
# .github/workflows/deploy.yml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Ansible
        run: pip install ansible

      - name: Run Playbook
        run: |
          ansible-playbook -i inventory/production.ini site.yml \
            --vault-password-file <(echo "${{ secrets.VAULT_PASSWORD }}")
```

### Best Practices

| Πρακτική | Γιατί |
|---|---|
| Χρήση roles για οτιδήποτε πάνω από ~50 γραμμές | Οργάνωση, επαναχρησιμοποίηση |
| Πάντα `--check` πριν production apply | Προεπισκόπηση αλλαγών (σαν terraform plan) |
| Ansible Vault για ΟΛΑ τα secrets | Ποτέ plaintext passwords σε playbooks |
| `become: true` μόνο όπου χρειάζεται, όχι global | Principle of least privilege |
| Version control για inventory + playbooks | Το ίδιο repo όπως ο κώδικας της εφαρμογής |
| Tags σε tasks για selective execution | `ansible-playbook site.yml --tags "nginx,security"` |

---

## 🎯 13. Πλήρες Παράδειγμα — Web Server Provisioning

Πλήρης ροή: από κενό Ubuntu server σε πλήρως λειτουργικό web server με ασφάλεια.

```yaml
# site.yml
---
- name: Πλήρης ρύθμιση Web Server
  hosts: webservers
  become: true
  vars:
    app_port: 3000
    nginx_port: 80

  tasks:
    - name: Ενημέρωση apt cache
      apt:
        update_cache: true
        cache_valid_time: 3600

    - name: Εγκατάσταση βασικών πακέτων
      apt:
        name:
          - nginx
          - ufw
          - fail2ban
        state: present

    - name: Ρύθμιση firewall — SSH
      ufw:
        rule: allow
        port: '22'
        proto: tcp

    - name: Ρύθμιση firewall — HTTP/HTTPS
      ufw:
        rule: allow
        port: "{{ item }}"
        proto: tcp
      loop:
        - '80'
        - '443'

    - name: Ενεργοποίηση UFW
      ufw:
        state: enabled
        policy: deny

    - name: Deployment nginx config από template
      template:
        src: templates/nginx-app.conf.j2
        dest: /etc/nginx/sites-available/myapp
      notify: Reload Nginx

    - name: Ενεργοποίηση site
      file:
        src: /etc/nginx/sites-available/myapp
        dest: /etc/nginx/sites-enabled/myapp
        state: link
      notify: Reload Nginx

    - name: Εγκατάσταση Node.js (για την εφαρμογή)
      apt:
        name: nodejs
        state: present

    - name: Clone εφαρμογής από Git
      git:
        repo: 'https://github.com/contoso/myapp.git'
        dest: /opt/myapp
        version: main

    - name: Εγκατάσταση npm dependencies
      npm:
        path: /opt/myapp

    - name: Δημιουργία systemd service για την εφαρμογή
      template:
        src: templates/myapp.service.j2
        dest: /etc/systemd/system/myapp.service
      notify:
        - Reload systemd
        - Restart App

  handlers:
    - name: Reload Nginx
      service:
        name: nginx
        state: reloaded

    - name: Reload systemd
      systemd:
        daemon_reload: true

    - name: Restart App
      systemd:
        name: myapp
        state: restarted
        enabled: true
```

### Εκτέλεση
```bash
ansible-playbook -i inventory/production.ini site.yml --check    # Dry-run πρώτα
ansible-playbook -i inventory/production.ini site.yml            # Πραγματική εφαρμογή
```

### Πώς συνδέεται με τα υπόλοιπα αρχεία του φακέλου
```
Terraform:  Δημιουργεί τη VM/υποδομή (devops-terraform-iac.md)
    ↓
Ansible:    Ρυθμίζει τι τρέχει μέσα στη VM (αυτό το αρχείο)
    ↓
Docker/K8s: Εναλλακτικά, αν η εφαρμογή τρέχει σε containers
            (devops-docker-containers.md, devops-kubernetes.md)
    ↓
CI/CD:      Αυτοματοποιεί όλη την παραπάνω ροή σε κάθε deployment
            (devops-git-cicd.md)
```

---

*Μέρος του [Infrastructure Knowledge Base](https://github.com/Dimitriskatsanos42/Infrastructure-Knowledge-Base) — φάκελος DevOps.*
