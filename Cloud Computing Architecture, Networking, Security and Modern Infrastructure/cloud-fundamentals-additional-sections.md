---

## 🔗 12. Προχωρημένη Δικτύωση στο Cloud (Advanced Cloud Networking)

[#-12-προχωρημένη-δικτύωση-στο-cloud-advanced-cloud-networking](#-12-προχωρημένη-δικτύωση-στο-cloud-advanced-cloud-networking)

Πέρα από το βασικό VPC, οι πραγματικές αρχιτεκτονικές χρειάζονται τρόπους να συνδέσουν πολλά δίκτυα μεταξύ τους — cloud με cloud, cloud με on-premises, ή VPC με VPC.

- **VPC Peering:** Απευθείας ιδιωτική σύνδεση ανάμεσα σε δύο VPCs, σαν να ήταν στο ίδιο δίκτυο. Δεν επιτρέπει transitive routing (αν το A συνδέεται με το B και το B με το C, το A **δεν** βλέπει αυτόματα το C).
- **Transit Gateway:** Λειτουργεί σαν κεντρικός "δικτυακός κόμβος" (hub) που συνδέει δεκάδες VPCs και on-premises δίκτυα μεταξύ τους, λύνοντας το πρόβλημα του transitive routing που έχει το Peering.
- **Site-to-Site VPN:** Κρυπτογραφημένη σύνδεση μέσω του δημόσιου Internet ανάμεσα στο on-premises data center και το VPC (χρησιμοποιεί IPsec tunnels). Γρήγορο να στηθεί, αλλά η ταχύτητα εξαρτάται από τη σύνδεση Internet.
- **Direct Connect (AWS) / ExpressRoute (Azure):** Αποκλειστική, φυσική ενσύρματη σύνδεση ανάμεσα στο data center του πελάτη και τον πάροχο cloud, χωρίς να περνά από το δημόσιο Internet. Προσφέρει σταθερό latency και μεγαλύτερο bandwidth — απαραίτητο για enterprise / hybrid workloads.
- **DNS στο Cloud (π.χ. AWS Route 53):** Διαχειριζόμενη υπηρεσία DNS που εκτελεί και routing policies (π.χ. Latency-based, Geolocation, Weighted) για να στέλνει τον χρήστη στο πλησιέστερο ή πιο υγιές endpoint.
- **NAT Gateway:** Επιτρέπει σε instances μέσα σε private subnet να βγαίνουν προς το Internet (π.χ. για updates), χωρίς όμως το Internet να μπορεί να ξεκινήσει σύνδεση προς αυτά.

| Λύση Σύνδεσης      | Χρήση                                              | Χαρακτηριστικό                          |
| ------------------- | --------------------------------------------------- | ---------------------------------------- |
| VPC Peering          | 1-προς-1 σύνδεση VPCs                               | Απλό, χωρίς transitive routing           |
| Transit Gateway       | Σύνδεση πολλαπλών VPCs/on-prem                      | Hub-and-spoke, scalable                  |
| Site-to-Site VPN      | Γρήγορη hybrid σύνδεση                              | Μέσω Internet, κρυπτογραφημένο           |
| Direct Connect        | Enterprise / high-throughput hybrid                | Αποκλειστική γραμμή, χαμηλό latency      |

---

## 🛡️ 13. Disaster Recovery & Business Continuity

[#️-13-disaster-recovery--business-continuity](#️-13-disaster-recovery--business-continuity)

Η ικανότητα ενός συστήματος να ανακάμπτει από αστοχίες (region outage, ανθρώπινο λάθος, cyberattack) μετριέται με δύο βασικές μετρικές:

- **RTO (Recovery Time Objective):** Πόσος χρόνος επιτρέπεται να περάσει μέχρι το σύστημα να ξαναλειτουργήσει μετά από ένα incident.
- **RPO (Recovery Point Objective):** Πόσα δεδομένα (σε χρόνο) είναι αποδεκτό να χαθούν — δηλαδή πόσο "παλιό" μπορεί να είναι το τελευταίο backup που θα χρησιμοποιηθεί.

**Στρατηγικές DR (από φθηνότερη/αργότερη σε ακριβότερη/ταχύτερη):**

1. **Backup & Restore:** Τακτικά backups σε άλλη περιοχή. Χαμηλό κόστος, αλλά υψηλό RTO (ώρες).
2. **Pilot Light:** Ένα ελάχιστο, "σβηστό" αντίγραφο της critical υποδομής τρέχει σε δεύτερη περιοχή και ενεργοποιείται/scale-up όταν χρειαστεί.
3. **Warm Standby:** Μια πλήρως λειτουργική αλλά μειωμένης κλίμακας έκδοση του συστήματος τρέχει συνεχώς σε δεύτερη περιοχή, έτοιμη να αναλάβει πλήρες load.
4. **Multi-Site Active-Active:** Το σύστημα τρέχει ταυτόχρονα σε πολλαπλές περιοχές με real-time replication. Ελάχιστο RTO/RPO, αλλά το ακριβότερο σε κόστος και πολυπλοκότητα.

---

## 💰 14. Cost Optimization & FinOps

[#-14-cost-optimization--finops](#-14-cost-optimization--finops)

Το **FinOps** είναι η πρακτική συνεργασίας μηχανικών, οικονομικών και διοίκησης ώστε ο οργανισμός να έχει έλεγχο και πρόβλεψη στο κόστος του cloud.

- **Right-Sizing:** Επιλογή του σωστού μεγέθους instance βάσει πραγματικής χρήσης (αποφυγή over-provisioning).
- **Reserved Instances / Savings Plans:** Δέσμευση χρήσης για 1-3 χρόνια με σημαντική έκπτωση (έως ~70%) σε σύγκριση με το on-demand pricing.
- **Spot Instances:** Χρήση αχρησιμοποίητης χωρητικότητας του παρόχου με τεράστια έκπτωση, με το ρίσκο να διακοπούν με μικρή προειδοποίηση — ιδανικό για batch jobs, CI/CD runners, fault-tolerant workloads.
- **Auto Scaling:** Αυτόματη μείωση πόρων εκτός ωρών αιχμής, ώστε να μην πληρώνεις για ανενεργή χωρητικότητα.
- **Tagging Strategy:** Ετικέτες (tags) σε κάθε πόρο (π.χ. `team`, `environment`, `project`) για να είναι δυνατή η κατανομή κόστους (cost allocation) ανά ομάδα/έργο.
- **Storage Lifecycle Policies:** Αυτόματη μετάβαση παλιών δεδομένων σε φθηνότερες κλάσεις αποθήκευσης (π.χ. AWS S3 Standard → S3 Glacier).

---

## 🌍 15. Multi-Cloud & Hybrid Στρατηγικές

[#-15-multi-cloud--hybrid-στρατηγικές](#-15-multi-cloud--hybrid-στρατηγικές)

- **Multi-Cloud:** Χρήση περισσότερων του ενός παρόχων (π.χ. AWS + Azure) ταυτόχρονα, συνήθως για να αποφευχθεί το **Vendor Lock-in**, να αξιοποιηθούν συγκεκριμένα δυνατά σημεία κάθε παρόχου, ή για λόγους κανονιστικής συμμόρφωσης.
- **Vendor Lock-in:** Ο κίνδυνος να εξαρτηθεί ένας οργανισμός τόσο πολύ από τα proprietary εργαλεία ενός παρόχου, που το να μεταναστεύσει αλλού γίνεται τεχνικά ή οικονομικά ασύμφορο.
- **Abstraction Layers:** Εργαλεία όπως το Terraform ή το Kubernetes βοηθούν να γράφεται κώδικας/configuration που είναι λιγότερο εξαρτημένο από συγκεκριμένο πάροχο.
- **Hybrid Cloud σε πράξη:** Συνήθως συνδυάζεται με Direct Connect/ExpressRoute (ενότητα 12) ώστε τα on-premises συστήματα να επικοινωνούν με χαμηλό latency με το cloud.

---

## 🔐 16. Zero Trust Architecture

[#-16-zero-trust-architecture](#-16-zero-trust-architecture)

Παραδοσιακά μοντέλα ασφάλειας εμπιστεύονταν αυτόματα οτιδήποτε βρισκόταν "μέσα" στο δίκτυο (perimeter security). Το **Zero Trust** αντιστρέφει τη λογική:

> "Never trust, always verify" — καμία συσκευή, χρήστης ή υπηρεσία δεν θεωρείται έμπιστη εξ ορισμού, ανεξάρτητα από το αν βρίσκεται εντός ή εκτός του δικτύου.

- **Least Privilege Access:** Κάθε χρήστης/υπηρεσία παίρνει μόνο τα ελάχιστα δικαιώματα που χρειάζεται για τη δουλειά του, τίποτα παραπάνω.
- **Micro-Segmentation:** Το δίκτυο χωρίζεται σε πολύ μικρές, απομονωμένες ζώνες, ώστε αν παραβιαστεί ένα σημείο, ο εισβολέας να μην μπορεί να κινηθεί ελεύθερα (lateral movement) στο υπόλοιπο δίκτυο.
- **Continuous Verification:** Η ταυτότητα και τα δικαιώματα ελέγχονται σε κάθε αίτημα, όχι μόνο κατά το login.
- **Identity as the New Perimeter:** Η ταυτότητα (identity) γίνεται το βασικό σημείο ελέγχου ασφαλείας, αντί για τα παραδοσιακά network firewalls.

---

## 🔁 17. DevOps & CI/CD Pipelines στο Cloud

[#-17-devops--cicd-pipelines-στο-cloud](#-17-devops--cicd-pipelines-στο-cloud)

Η ενσωμάτωση αυτοματοποιημένων pipelines είναι ο πυρήνας του σύγχρονου cloud-native development.

- **CI (Continuous Integration):** Κάθε αλλαγή κώδικα ενσωματώνεται αυτόματα, χτίζεται (build) και τεστάρεται.
- **CD (Continuous Delivery/Deployment):** Ο κώδικας που περνά τα tests προωθείται αυτόματα προς staging ή και production.
- **Δημοφιλή Εργαλεία:** GitHub Actions, GitLab CI/CD, Jenkins, AWS CodePipeline, ArgoCD (GitOps για Kubernetes).
- **Blue-Green Deployment:** Δύο πανομοιότυπα περιβάλλοντα (Blue = τρέχον, Green = νέα έκδοση). Η κίνηση μεταφέρεται ακαριαία στο Green μόλις επιβεβαιωθεί ότι λειτουργεί, επιτρέποντας άμεσο rollback.
- **Canary Deployment:** Η νέα έκδοση διοχετεύεται σταδιακά σε μικρό ποσοστό χρηστών (π.χ. 5%) πριν επεκταθεί σε όλους, μειώνοντας το ρίσκο.

**Παράδειγμα απλού Terraform block (IaC στην πράξη):**

```hcl
resource "aws_instance" "web_server" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"

  tags = {
    Name        = "web-server"
    Environment = "production"
  }
}
```

---

## 🏛️ 18. Well-Architected Framework & Governance

[#️-18-well-architected-framework--governance](#️-18-well-architected-framework--governance)

Το **AWS Well-Architected Framework** (και τα αντίστοιχα του Azure/GCP) αποτελεί ένα σύνολο βέλτιστων πρακτικών οργανωμένο σε πυλώνες, χρήσιμο ανεξαρτήτως παρόχου:

| Πυλώνας                        | Στόχος                                                                 |
| ------------------------------- | ------------------------------------------------------------------------ |
| **Operational Excellence**      | Λειτουργία και παρακολούθηση συστημάτων για παραγωγή αξίας.             |
| **Security**                    | Προστασία δεδομένων, συστημάτων και περιουσιακών στοιχείων.             |
| **Reliability**                 | Ανάκαμψη από αστοχίες και ικανοποίηση ζήτησης.                          |
| **Performance Efficiency**      | Αποδοτική χρήση πόρων ανάλογα με τις απαιτήσεις.                        |
| **Cost Optimization**           | Αποφυγή περιττού κόστους (βλ. ενότητα 14 - FinOps).                     |
| **Sustainability**              | Ελαχιστοποίηση περιβαλλοντικού αποτυπώματος των workloads.               |

- **Governance:** Πολιτικές που διασφαλίζουν ότι οι πόροι δημιουργούνται σύμφωνα με τους κανόνες του οργανισμού (π.χ. AWS Organizations, Azure Policy, Service Control Policies - SCPs).
- **Compliance:** Συμμόρφωση με κανονιστικά πλαίσια όπως GDPR, ISO 27001, SOC 2 — κρίσιμο ειδικά σε κλάδους όπως τράπεζες και υγεία.

---
