# 🏗️ Terraform — Infrastructure as Code σε Βάθος

Έκτο αρχείο του φακέλου **DevOps**. Ενώ το Kubernetes διαχειρίζεται *τι τρέχει μέσα* σε ένα cluster, το **Terraform** δημιουργεί *το ίδιο το cluster*, τα δίκτυα, τις βάσεις δεδομένων — ολόκληρη την υποδομή, ως κώδικα. Συνδέεται άμεσα με το `azure-iaas-fundamentals.md` που ήδη έχεις — εκεί έφτιαχνες resources με PowerShell/CLI εντολές· εδώ τα ίδια resources γίνονται **δηλωτικός, version-controlled κώδικας**.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Γιατί Terraform (και όχι μόνο scripts)](#-1-γιατί-terraform-και-όχι-μόνο-scripts)
2. [Βασικές Έννοιες](#-2-βασικές-έννοιες)
3. [Terraform Workflow](#-3-terraform-workflow)
4. [HCL Syntax — Βασικά](#-4-hcl-syntax--βασικά)
5. [State File — Το Πιο Κρίσιμο Κομμάτι](#-5-state-file--το-πιο-κρίσιμο-κομμάτι)
6. [Variables & Outputs](#-6-variables--outputs)
7. [Modules — Επαναχρησιμοποίηση Κώδικα](#-7-modules--επαναχρησιμοποίηση-κώδικα)
8. [Πρακτικό Παράδειγμα — Azure Infrastructure](#-8-πρακτικό-παράδειγμα--azure-infrastructure)
9. [Πολλαπλά Περιβάλλοντα (Dev/Staging/Prod)](#-9-πολλαπλά-περιβάλλοντα-devstagingprod)
10. [Terraform σε CI/CD Pipeline](#-10-terraform-σε-cicd-pipeline)
11. [Best Practices & Συνηθισμένα Λάθη](#-11-best-practices--συνηθισμένα-λάθη)
12. [Πλήρες Παράδειγμα — AKS Cluster από το Μηδέν](#-12-πλήρες-παράδειγμα--aks-cluster-από-το-μηδέν)

---

## 🤔 1. Γιατί Terraform (και όχι μόνο scripts)

Θα μπορούσες να δημιουργήσεις υποδομή με ένα PowerShell script (όπως στο `azure-iaas-fundamentals.md`). Το πρόβλημα:

| Πρόβλημα με scripts | Πώς το λύνει το Terraform |
|---|---|
| Imperative — λέει "κάνε αυτό, μετά αυτό" | **Declarative** — λες "θέλω αυτό να υπάρχει", το Terraform βρίσκει το πώς |
| Τρέχοντας το script 2 φορές → error ή duplicate resources | **Idempotent** — τρέχοντάς το πολλές φορές, το αποτέλεσμα είναι πάντα το ίδιο |
| Δεν ξέρεις τι θα αλλάξει πριν το τρέξεις | `terraform plan` δείχνει **ακριβώς** τι θα αλλάξει, ΠΡΙΝ εφαρμοστεί |
| Δύσκολο να κάνεις "undo" | `terraform destroy` καταργεί καθαρά ό,τι δημιουργήθηκε |
| Δεν ξέρει "τι υπάρχει ήδη" | Κρατά **state** — ξέρει ακριβώς τι έχει δημιουργήσει |

### Declarative παράδειγμα
```hcl
# Δεν λες "δημιούργησε VM, μετά βάλε δίσκο, μετά σύνδεσε δίκτυο"
# Λες απλά "θέλω αυτό να υπάρχει":

resource "azurerm_linux_virtual_machine" "web" {
  name                = "web-server-01"
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_D2s_v5"
  # ...
}
```

---

## 📖 2. Βασικές Έννοιες

| Όρος | Σημασία |
|---|---|
| **Provider** | Το "plugin" που ξέρει πώς να μιλήσει σε μια πλατφόρμα (Azure, AWS, GCP, Kubernetes) |
| **Resource** | Ένα συγκεκριμένο κομμάτι υποδομής (VM, VNet, Database) |
| **Data Source** | Ανάγνωση πληροφορίας για ήδη υπάρχον resource (όχι δημιουργία) |
| **State** | Αρχείο που κρατά ποια resources έχει δημιουργήσει το Terraform και την τρέχουσα κατάστασή τους |
| **Module** | Επαναχρησιμοποιήσιμο "πακέτο" resources (σαν function σε προγραμματισμό) |
| **Plan** | Προεπισκόπηση αλλαγών πριν εφαρμοστούν |
| **Apply** | Πραγματική εφαρμογή των αλλαγών |

---

## 🔄 3. Terraform Workflow

```
1. write   →  Γράφεις .tf αρχεία (τι θέλεις να υπάρχει)
2. init    →  terraform init  (κατεβάζει providers/modules)
3. plan    →  terraform plan  (δείχνει τι ΘΑ αλλάξει)
4. apply   →  terraform apply (εφαρμόζει τις αλλαγές)
5. destroy →  terraform destroy (καταστρέφει την υποδομή, όταν δεν χρειάζεται πια)
```

```bash
terraform init       # Πρώτο βήμα πάντα σε νέο project
terraform validate   # Έλεγχος συντακτικής ορθότητας
terraform fmt         # Αυτόματη μορφοποίηση κώδικα
terraform plan        # Προεπισκόπηση — ΤΙ θα αλλάξει
terraform apply       # Εφαρμογή (θα ζητήσει επιβεβαίωση "yes")
terraform apply -auto-approve   # Χωρίς interactive επιβεβαίωση (χρήσιμο σε CI/CD)
terraform destroy     # Καταστροφή ΟΛΩΝ των resources που διαχειρίζεται
```

### Τι δείχνει το `terraform plan` (symbols)
```
+ create   → Νέο resource θα δημιουργηθεί
~ update   → Υπάρχον resource θα τροποποιηθεί
- destroy  → Resource θα διαγραφεί
-/+ replace → Θα καταστραφεί και ξαναδημιουργηθεί (πχ αλλαγή σε immutable πεδίο)
```

---

## 📝 4. HCL Syntax — Βασικά

**HCL** (HashiCorp Configuration Language) — η γλώσσα που γράφεται το Terraform.

```hcl
# Provider block — ποια πλατφόρμα, ποια credentials
provider "azurerm" {
  features {}
}

# Resource block — τι θέλεις να δημιουργηθεί
resource "azurerm_resource_group" "main" {
  name     = "rg-production"
  location = "westeurope"

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# Resource που εξαρτάται από άλλο (implicit dependency)
resource "azurerm_virtual_network" "main" {
  name                = "vnet-production"
  resource_group_name = azurerm_resource_group.main.name    # Αναφορά σε άλλο resource
  location             = azurerm_resource_group.main.location
  address_space         = ["10.0.0.0/16"]
}
```

### Πώς λειτουργούν οι εξαρτήσεις (dependency graph)
Όταν γράφεις `azurerm_resource_group.main.name` μέσα σε άλλο resource, το Terraform **αυτόματα** καταλαβαίνει ότι πρέπει πρώτα να δημιουργήσει το resource group, **μετά** το VNet — χωρίς να χρειάζεται να το πεις ρητά.

---

## 💾 5. State File — Το Πιο Κρίσιμο Κομμάτι

Το `terraform.tfstate` είναι το αρχείο που κρατά **ποια resources υπάρχουν πραγματικά** και τη ρύθμισή τους. Χωρίς αυτό, το Terraform δεν ξέρει τι έχει ήδη δημιουργήσει.

### ⚠️ Γιατί ΠΟΤΕ τοπικό state σε ομαδική εργασία
```
❌ ΠΡΟΒΛΗΜΑ:
Developer A τρέχει terraform apply τοπικά → state στο δικό του laptop
Developer B τρέχει terraform apply τοπικά → ΔΕΝ ξέρει τι έκανε ο Α
→ Conflicts, duplicate resources, χάος

✅ ΛΥΣΗ: Remote State (κοινόχρηστο, με locking)
```

### Remote State σε Azure Storage
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstateprodstorage"
    container_name        = "tfstate"
    key                    = "production.terraform.tfstate"
  }
}
```

### State Locking
Όταν κάποιος τρέχει `terraform apply`, το state **κλειδώνει** — κανείς άλλος δεν μπορεί να κάνει ταυτόχρονη αλλαγή, αποτρέποντας corruption.

### Βασικές εντολές state
```bash
terraform state list                    # Λίστα όλων των διαχειριζόμενων resources
terraform state show azurerm_resource_group.main   # Λεπτομέρειες συγκεκριμένου resource
terraform import azurerm_resource_group.main /subscriptions/.../rg-production
# ↑ "Εισαγωγή" ήδη υπάρχοντος resource (που δημιουργήθηκε manual) στο Terraform state
```

> ⚠️ **Ποτέ** μην επεξεργάζεσαι το `.tfstate` αρχείο χειροκίνητα — χρησιμοποίησε πάντα τις `terraform state` εντολές.

---

## 🔤 6. Variables & Outputs

### Variables — αποφυγή hardcoded τιμών
```hcl
# variables.tf
variable "environment" {
  description = "Το περιβάλλον (dev/staging/prod)"
  type        = string
  default     = "dev"
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "admin_password" {
  type      = string
  sensitive = true       # Δεν εμφανίζεται στο output του plan/apply
}
```

```hcl
# main.tf — χρήση variables
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.environment}"
  location = "westeurope"
}
```

### Πέρασμα τιμών
```bash
terraform apply -var="environment=production"
terraform apply -var-file="production.tfvars"
```

```hcl
# production.tfvars
environment = "production"
vm_size     = "Standard_D4s_v5"
```

### Outputs — εξαγωγή χρήσιμων τιμών μετά το apply
```hcl
# outputs.tf
output "vm_public_ip" {
  value = azurerm_public_ip.main.ip_address
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}
```
```bash
terraform output                  # Δες όλα τα outputs
terraform output vm_public_ip     # Δες συγκεκριμένο
```

---

## 📦 7. Modules — Επαναχρησιμοποίηση Κώδικα

Αντί να επαναλαμβάνεις τον ίδιο κώδικα για κάθε environment, το πακετάρεις σε **module**.

### Δομή
```
modules/
└── web-app/
    ├── main.tf        # Τα resources
    ├── variables.tf   # Τι δέχεται ως input
    └── outputs.tf     # Τι επιστρέφει
environments/
├── dev/
│   └── main.tf        # Καλεί το module με dev παραμέτρους
└── production/
    └── main.tf         # Καλεί το ΙΔΙΟ module με production παραμέτρους
```

### Παράδειγμα module
```hcl
# modules/web-app/main.tf
resource "azurerm_linux_web_app" "main" {
  name                = var.app_name
  resource_group_name = var.resource_group_name
  location             = var.location
  service_plan_id      = var.service_plan_id

  site_config {
    application_stack {
      node_version = "20-lts"
    }
  }
}
```

```hcl
# environments/production/main.tf
module "web_app" {
  source              = "../../modules/web-app"
  app_name             = "myapp-production"
  resource_group_name  = azurerm_resource_group.main.name
  location              = "westeurope"
  service_plan_id       = azurerm_service_plan.main.id
}
```

### Public Module Registry
```hcl
# Χρήση έτοιμου, community module αντί να γράφεις από το μηδέν
module "vnet" {
  source  = "Azure/vnet/azurerm"
  version = "4.1.0"

  resource_group_name = azurerm_resource_group.main.name
  vnet_name            = "vnet-production"
  address_space         = ["10.0.0.0/16"]
}
```

---

## ☁️ 8. Πρακτικό Παράδειγμα — Azure Infrastructure

Το ίδιο VNet/Subnet/NSG setup που έφτιαχνες με PowerShell στο `azure-iaas-fundamentals.md`, τώρα σε Terraform:

```hcl
resource "azurerm_resource_group" "main" {
  name     = "rg-production"
  location = "westeurope"
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-production"
  resource_group_name = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  address_space         = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "app" {
  name                 = "subnet-app"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes      = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "app" {
  name                = "nsg-app"
  resource_group_name = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "443"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}
```

---

## 🌍 9. Πολλαπλά Περιβάλλοντα (Dev/Staging/Prod)

### Workspaces (απλή προσέγγιση — ίδιος κώδικας, διαφορετικό state ανά environment)
```bash
terraform workspace new staging
terraform workspace new production
terraform workspace select staging
terraform workspace list
```
```hcl
resource "azurerm_resource_group" "main" {
  name = "rg-${terraform.workspace}"   # rg-staging, rg-production
}
```

### Ξεχωριστοί φάκελοι (πιο σαφής προσέγγιση, συνιστώμενη για production)
```
environments/
├── dev/
│   ├── main.tf
│   └── terraform.tfvars
├── staging/
│   ├── main.tf
│   └── terraform.tfvars
└── production/
    ├── main.tf
    └── terraform.tfvars
```
> Οι ξεχωριστοί φάκελοι είναι πιο ασφαλείς — αποτρέπουν το ρίσκο να τρέξεις κατά λάθος `apply` στο λάθος workspace/environment.

---

## ⚙️ 10. Terraform σε CI/CD Pipeline

Σύνδεση με το `devops-git-cicd.md` — το Terraform σπάνια τρέχει manual σε production, αλλά μέσα από pipeline.

```yaml
# .github/workflows/terraform.yml
name: Terraform CI/CD

on:
  pull_request:
    paths: ['infrastructure/**']
  push:
    branches: [main]
    paths: ['infrastructure/**']

jobs:
  terraform:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./infrastructure
    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        run: terraform init
        env:
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

      - name: Terraform Plan
        run: terraform plan -no-color -out=tfplan
        if: github.event_name == 'pull_request'

      - name: Terraform Apply
        run: terraform apply -auto-approve tfplan
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
```

### Καλή πρακτική: Plan σε PR, Apply σε merge
```
Pull Request δημιουργείται
   → terraform plan τρέχει αυτόματα
   → Το output εμφανίζεται ως comment στο PR (τι ΘΑ αλλάξει)
   → Reviewer βλέπει ακριβώς την επίπτωση πριν εγκρίνει

Merge στο main
   → terraform apply τρέχει αυτόματα
   → Η υποδομή ενημερώνεται
```
> Αυτό είναι στην ουσία **Change Management** (βλ. `itil-service-management-templates.md`) αλλά πλήρως αυτοματοποιημένο — το `terraform plan` output **είναι** το impact analysis του Change Request.

---

## ✅ 11. Best Practices & Συνηθισμένα Λάθη

| Best Practice | Γιατί |
|---|---|
| Πάντα `terraform plan` πριν από `apply` | Ποτέ μη προβλέψιμες αλλαγές σε production |
| Remote state με locking | Αποφυγή conflicts σε ομαδική εργασία |
| `sensitive = true` για passwords/secrets | Αποφυγή exposure σε logs/console output |
| Μικρά, focused modules | Επαναχρησιμοποίηση, ευκολότερο testing |
| Version pinning σε providers | `version = "~> 3.0"` — αποφυγή unexpected breaking changes |
| Tags σε ΟΛΑ τα resources | Κοστολόγηση, οργάνωση, audit (βλ. Vendor/Cost tracking στο ITSM υλικό) |

### Συνηθισμένα λάθη αρχαρίων
```
❌ terraform apply χωρίς προηγούμενο plan review
❌ Τοπικό (όχι remote) state σε ομαδικό project
❌ Hardcoded credentials μέσα στα .tf αρχεία
❌ Χειροκίνητη τροποποίηση resources που διαχειρίζεται το Terraform
   (προκαλεί "drift" — το state δεν ταιριάζει πια με την πραγματικότητα)
❌ terraform destroy σε production χωρίς διπλό έλεγχο ποιο workspace/environment
```

### Ανίχνευση drift
```bash
terraform plan
# Αν δείξει αλλαγές που ΔΕΝ έκανες εσύ μέσω Terraform,
# κάποιος άλλαξε κάτι χειροκίνητα (πχ μέσω Azure Portal) — αυτό είναι "drift"
```

---

## 🎯 12. Πλήρες Παράδειγμα — AKS Cluster από το Μηδέν

Δημιουργία του Kubernetes cluster (βλ. `devops-kubernetes.md`) μέσω Terraform:

```hcl
resource "azurerm_resource_group" "aks" {
  name     = "rg-aks-production"
  location = "westeurope"
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-production"
  location             = azurerm_resource_group.aks.location
  resource_group_name  = azurerm_resource_group.aks.name
  dns_prefix            = "aksprod"
  kubernetes_version    = "1.29"

  default_node_pool {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_D2s_v5"

    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy  = "calico"
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive = true
}
```

### Ροή: Από κώδικα σε λειτουργικό cluster
```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Σύνδεση kubectl στο νέο cluster
az aks get-credentials --resource-group rg-aks-production --name aks-production
kubectl get nodes    # Επιβεβαίωση ότι το cluster είναι έτοιμο

# Τώρα μπορείς να εφαρμόσεις τα K8s manifests από το devops-kubernetes.md
kubectl apply -f namespace.yaml
kubectl apply -f . -n myapp-production
```

Αυτό δείχνει την πλήρη αλυσίδα: **Terraform δημιουργεί το cluster → Kubernetes manifests τρέχουν πάνω σε αυτό → CI/CD pipeline (GitHub Actions) αυτοματοποιεί όλη τη ροή.**

---

*Μέρος του [Infrastructure Knowledge Base](https://github.com/Dimitriskatsanos42/Infrastructure-Knowledge-Base) — φάκελος DevOps, συμπληρωματικό στα `devops-fundamentals-roadmap.md`, `devops-git-cicd.md`, `devops-debugging-troubleshooting.md`, `devops-docker-containers.md` και `devops-kubernetes.md`.*
