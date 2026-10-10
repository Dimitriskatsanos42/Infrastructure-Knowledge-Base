# 🏗️ Architecture Diagrams

Συλλογή από αρχιτεκτονικά διαγράμματα υποδομών IT. Κάθε αρχείο περιέχει **διάγραμμα Mermaid** (το GitHub το εμφανίζει αυτόματα), επεξήγηση των συστατικών, βέλτιστες πρακτικές και συχνά λάθη σχεδίασης.

## 📚 Περιεχόμενα

| # | Αρχείο | Θέμα |
|---|--------|------|
| 1 | [`01-enterprise-network.md`](./01-enterprise-network.md) | Εταιρικό δίκτυο (Core / Distribution / Access) |
| 2 | [`02-active-directory-topology.md`](./02-active-directory-topology.md) | Τοπολογία Active Directory (Forest, Domains, Sites) |
| 3 | [`03-hybrid-cloud.md`](./03-hybrid-cloud.md) | Hybrid Cloud (On-Prem + Azure / Entra ID) |
| 4 | [`04-dmz-architecture.md`](./04-dmz-architecture.md) | Αρχιτεκτονική DMZ |
| 5 | [`05-vlan-routing-topology.md`](./05-vlan-routing-topology.md) | VLAN και Routing |
| 6 | [`06-backup-architecture.md`](./06-backup-architecture.md) | Αρχιτεκτονική Backup (3-2-1-1-0) |
| 7 | [`07-monitoring-architecture.md`](./07-monitoring-architecture.md) | Αρχιτεκτονική Monitoring και Alerting |
| 8 | [`08-disaster-recovery-architecture.md`](./08-disaster-recovery-architecture.md) | Disaster Recovery (RTO / RPO) |

## 🧭 Προτεινόμενη σειρά μελέτης

`Enterprise Network → VLAN/Routing → DMZ → Active Directory → Hybrid Cloud → Backup → Monitoring → Disaster Recovery`

## ℹ️ Σημειώσεις

- Τα διαγράμματα είναι **παραδείγματα αναφοράς** (reference designs). Σε πραγματικά περιβάλλοντα προσαρμόζονται ανάλογα με μέγεθος, budget και απαιτήσεις συμμόρφωσης.
- Οι διευθύνσεις IP που εμφανίζονται είναι ενδεικτικές (ιδιωτικά εύρη RFC 1918).
- Για να επεξεργαστείτε τα διαγράμματα, χρησιμοποιήστε το [Mermaid Live Editor](https://mermaid.live).
