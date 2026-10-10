# 🏢 Active Directory Topology

Η τοπολογία του AD περιγράφεται σε δύο επίπεδα:

- **Λογική δομή:** Forest, Domains, Organizational Units (OUs), Trusts.
- **Φυσική δομή:** Sites, Subnets, Domain Controllers, Replication.

## 📐 Λογική δομή (Forest / Domain)

```mermaid
graph TB
    subgraph FOREST["Forest: corp.local"]
        ROOT["Root Domain: corp.local"]
        CH1["Child Domain: eu.corp.local"]
        CH2["Child Domain: us.corp.local"]
        ROOT --> CH1
        ROOT --> CH2
    end

    subgraph OUS["OU Structure - corp.local"]
        OU1["OU: Users"]
        OU2["OU: Computers"]
        OU3["OU: Servers"]
        OU4["OU: Groups"]
        OU5["OU: Service Accounts"]
    end

    EXT["External Forest: partner.local"]

    ROOT --> OUS
    ROOT <-. "Forest Trust" .-> EXT
```

## 📐 Φυσική δομή (Sites και Replication)

```mermaid
graph LR
    subgraph HQ["Site: HQ-Athens - 10.10.0.0/16"]
        DC1["DC01 - GC + FSMO"]
        DC2["DC02 - GC + DNS"]
    end

    subgraph BR1["Site: Branch-Patras - 10.20.0.0/16"]
        DC3["DC03 - GC + DNS"]
    end

    subgraph BR2["Site: Branch-Preveza - 10.30.0.0/24"]
        RODC["RODC01 - Read-Only DC"]
    end

    DC1 <-->|"Intra-site replication"| DC2
    DC1 <-->|"Site Link: 100 cost - WAN"| DC3
    DC3 -->|"One-way replication"| RODC
    DC1 -.->|"Site Link: 200 cost"| RODC
```

## 🧱 Βασικά συστατικά

| Συστατικό | Περιγραφή |
|-----------|-----------|
| **Forest** | Όριο ασφαλείας και κοινό Schema / Global Catalog |
| **Domain** | Όριο διαχείρισης, πολιτικών και replication ονομάτων |
| **OU** | Λογική οργάνωση αντικειμένων και delegation / GPO |
| **Site** | Φυσική τοποθεσία με γρήγορο δίκτυο (ορίζεται από subnets) |
| **Site Link** | Ορίζει κόστος και προγραμματισμό replication μεταξύ sites |
| **Global Catalog (GC)** | Μερικό αντίγραφο όλων των αντικειμένων του forest |
| **RODC** | Read-only DC για ανασφαλή ή απομακρυσμένα sites |

## 👑 Ρόλοι FSMO (5)

| Ρόλος | Εύρος | Λειτουργία |
|-------|-------|-----------|
| Schema Master | Forest | Αλλαγές στο Schema |
| Domain Naming Master | Forest | Προσθήκη / αφαίρεση domains |
| PDC Emulator | Domain | Συγχρονισμός ώρας, κωδικοί, GPO |
| RID Master | Domain | Κατανομή RID pools |
| Infrastructure Master | Domain | Αναφορές cross-domain |

## ✅ Βέλτιστες πρακτικές

- Τουλάχιστον **2 DCs ανά domain** και ανά κρίσιμο site.
- Ένα **single-domain forest** επαρκεί για τις περισσότερες εταιρείες. Τα πολλαπλά domains αυξάνουν την πολυπλοκότητα.
- Ορθή ρύθμιση **Sites & Subnets** ώστε οι clients να βρίσκουν το κοντινότερο DC.
- **DNS** ενσωματωμένο στο AD σε κάθε DC.
- Τακτικό **System State backup** των DCs και δοκιμή επαναφοράς.
- **Tiered administration model** (Tier 0/1/2) για προστασία των privileged accounts.
- Αρχικό έλεγχο υγείας: `dcdiag /v`, `repadmin /replsummary`, `repadmin /showrepl`.

## ⚠️ Συχνά λάθη

- Όλοι οι FSMO ρόλοι σε DC που δεν έχει backup.
- Λανθασμένος χρόνος (Kerberos αποτυγχάνει με απόκλιση > 5 λεπτά).
- Έλλειψη Subnets στο Sites & Services, οπότε οι clients κάνουν authentication μέσω WAN.
- Χρήση Domain Admin για καθημερινές εργασίες.

## 🔗 Σχετικά

[Hybrid Cloud (Entra Connect)](./03-hybrid-cloud.md) · [Backup](./06-backup-architecture.md)
