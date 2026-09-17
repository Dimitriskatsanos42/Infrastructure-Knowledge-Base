# 🚀 DevOps

Υλικό γύρω από DevOps πρακτικές, εργαλεία και ροές εργασίας — από τη θεωρία/κουλτούρα μέχρι πλήρη, λειτουργικά CI/CD pipelines, containerization, orchestration, infrastructure as code και observability. Σχεδιασμένο ώστε κάποιος με background σε system administration (βλ. φακέλους `Windows System Administration & Networking`, `Linux-Administration`, `Networking`) να δει πώς οι δεξιότητές του μεταφέρονται και επεκτείνονται στο DevOps.

---

## 📂 Περιεχόμενα

| # | Αρχείο | Τι καλύπτει |
|:---:|---|---|
| 1 | [`devops-fundamentals-roadmap.md`](./devops-fundamentals-roadmap.md) | Τι είναι το DevOps, μοντέλο CALMS, ο DevOps κύκλος (infinity loop), roadmap εκμάθησης, συνολικός χάρτης εργαλείων, και πώς οι sysadmin δεξιότητες μεταφέρονται στο DevOps. **Ξεκίνα από εδώ.** |
| 2 | [`devops-git-cicd.md`](./devops-git-cicd.md) | Git σε βάθος (εντολές, branching strategies, merge conflicts), και 3 πλήρη CI/CD pipelines (GitHub Actions, Jenkins, GitLab CI) με deployment strategies και secrets management. |
| 3 | [`devops-debugging-troubleshooting.md`](./devops-debugging-troubleshooting.md) | Συστηματική μεθοδολογία debugging σε DevOps περιβάλλον: Docker/Kubernetes debugging, CI/CD pipeline debugging, distributed tracing/correlation IDs, performance profiling, playbook συχνών production issues. |
| 4 | [`devops-docker-containers.md`](./devops-docker-containers.md) | Containerization βασικά (namespaces/cgroups), Dockerfile best practices, multi-stage builds, networking, volumes, Docker Compose, image security & optimization. |
| 5 | [`devops-kubernetes.md`](./devops-kubernetes.md) | Container orchestration: αρχιτεκτονική (Control Plane/Worker Nodes), Pods/Deployments/Services, ConfigMaps/Secrets, autoscaling (HPA), Ingress, persistent storage, Helm. |
| 6 | [`devops-terraform-iac.md`](./devops-terraform-iac.md) | Infrastructure as Code: HCL syntax, state management, variables/modules, πολλαπλά environments, Terraform σε CI/CD, πλήρες παράδειγμα δημιουργίας AKS cluster. |
| 7 | [`devops-ansible.md`](./devops-ansible.md) | Configuration management: agentless προσέγγιση, playbooks/roles/handlers, templates (Jinja2), Ansible Vault για secrets, υποστήριξη Windows (WinRM). |
| 8 | [`devops-monitoring-observability.md`](./devops-monitoring-observability.md) | Οι 3 πυλώνες observability: Prometheus/PromQL, Alertmanager, Grafana, ELK Stack/Loki, distributed tracing, SLI/SLO/SLA & error budgets. |

---

## 🗺️ Προτεινόμενη σειρά ανάγνωσης

```
1. devops-fundamentals-roadmap.md        → Η συνολική εικόνα
2. devops-git-cicd.md                    → Version control + αυτοματοποίηση pipelines
3. devops-docker-containers.md           → Πακετάρισμα εφαρμογών
4. devops-kubernetes.md                  → Ορχήστρωση containers σε scale
5. devops-terraform-iac.md               → Δημιουργία της υποδομής ως κώδικας
6. devops-ansible.md                     → Ρύθμιση ό,τι τρέχει μέσα στην υποδομή
7. devops-monitoring-observability.md    → Παρακολούθηση όλων των παραπάνω
8. devops-debugging-troubleshooting.md   → Πότε κάτι πάει στραβά (διάβασε παράλληλα με τα 3-7)
```

> Το αρχείο #3 (debugging) είναι σκόπιμα εγκάρσιο στη ροή — αξίζει μια πρώτη ανάγνωση νωρίς, αλλά τα περισσότερα από όσα περιγράφει (Docker/K8s debugging) έχουν πλήρες νόημα μόνο αφού έχεις διαβάσει τα αντίστοιχα αρχεία.

---

## 🧩 Πώς Συνδέονται Όλα Μεταξύ Τους

```
devops-terraform-iac.md
   └── Δημιουργεί την υποδομή (VMs, VNets, AKS cluster)
         │
         ▼
devops-ansible.md                    devops-docker-containers.md
   └── Ρυθμίζει VMs χειροκίνητα         └── Πακετάρει εφαρμογές σε containers
         (εναλλακτική προσέγγιση)              │
                                                ▼
                                       devops-kubernetes.md
                                          └── Ορχηστρώνει τα containers σε production
                                                │
                                                ▼
devops-git-cicd.md
   └── Αυτοματοποιεί ΟΛΗ την παραπάνω ροή σε κάθε commit/deployment
         │
         ▼
devops-monitoring-observability.md
   └── Παρακολουθεί την υγεία όλων των παραπάνω σε πραγματικό χρόνο
         │
         ▼
devops-debugging-troubleshooting.md
   └── Τι κάνεις όταν κάτι από όλα τα παραπάνω χαλάσει
```

---

## 🔗 Σχετικοί φάκελοι στο repo

- [`Windows System Administration & Networking`](../Windows%20System%20Administration%20%26%20Networking) — περιλαμβάνει `azure-iaas-fundamentals.md`, βάση για το cloud deployment target που δημιουργεί το Terraform
- [`Linux-Administration`](../Linux-Administration) — Bash scripting, systemd, βάση για CI/CD runners, container hosts και Ansible playbooks
- [`Networking`](../Networking) — δικτυακά θεμέλια απαραίτητα για container/Kubernetes networking και QoS/monitoring
- [`IT-Service-Management`](../IT-Service-Management) — το CI/CD pipeline είναι, ουσιαστικά, αυτοματοποιημένο Change/Release Management· το observability stack είναι η τεχνική υλοποίηση του Event Management

---

*Μέρος του [Infrastructure Knowledge Base](https://github.com/Dimitriskatsanos42/Infrastructure-Knowledge-Base).*
