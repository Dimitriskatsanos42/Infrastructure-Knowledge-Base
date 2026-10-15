# 🔀 VLAN & Routing Topology

Τα **VLANs** χωρίζουν ένα φυσικό δίκτυο σε πολλά λογικά (broadcast domains). Για να επικοινωνήσουν μεταξύ τους χρειάζεται **inter-VLAN routing** σε Layer 3 συσκευή.

## 📐 Διάγραμμα (Layer 3 Switch + Inter-VLAN Routing)

```mermaid
graph TB
    INET(("Internet / ISP"))
    FW["Firewall / Edge Router"]
    L3["Core L3 Switch - SVIs + OSPF"]

    subgraph ACC["Access Switches - Trunks 802.1Q"]
        SW1["Access SW 1"]
        SW2["Access SW 2"]
        SW3["Access SW 3"]
    end

    subgraph VLANS["VLANs"]
        V10["VLAN 10 - Users 10.10.10.0/24"]
        V20["VLAN 20 - Servers 10.10.20.0/24"]
        V30["VLAN 30 - VoIP 10.10.30.0/24"]
        V40["VLAN 40 - Guest WiFi 10.10.40.0/24"]
        V99["VLAN 99 - Management 10.10.99.0/24"]
    end

    INET --- FW
    FW ---|"Routed link 10.0.0.0/30"| L3
    L3 ===|"Trunk"| SW1
    L3 ===|"Trunk"| SW2
    L3 ===|"Trunk"| SW3
    SW1 --- V10
    SW1 --- V30
    SW2 --- V20
    SW3 --- V40
    SW3 --- V99
```

## 📐 Διάγραμμα δρομολόγησης (Multi-site με OSPF)

```mermaid
graph LR
    subgraph AREA0["OSPF Area 0 - Backbone"]
        HQ["HQ L3 Core"]
        R1["Router - Branch A"]
        R2["Router - Branch B"]
    end

    HQ ===|"WAN 10.255.0.0/30"| R1
    HQ ===|"WAN 10.255.0.4/30"| R2
    R1 -.->|"Backup link"| R2

    R1 --- NA["Branch A LAN 10.20.0.0/24"]
    R2 --- NB["Branch B LAN 10.30.0.0/24"]
    HQ --- NH["HQ VLANs 10.10.0.0/16"]
```

## 🗂️ Πλάνο VLAN (παράδειγμα)

| VLAN ID | Όνομα | Subnet | Gateway | Σκοπός |
|---------|-------|--------|---------|--------|
| 10 | USERS | 10.10.10.0/24 | 10.10.10.1 | Υπολογιστές χρηστών |
| 20 | SERVERS | 10.10.20.0/24 | 10.10.20.1 | Εσωτερικοί servers |
| 30 | VOIP | 10.10.30.0/24 | 10.10.30.1 | IP τηλέφωνα (QoS) |
| 40 | GUEST | 10.10.40.0/24 | 10.10.40.1 | Επισκέπτες (μόνο Internet) |
| 99 | MGMT | 10.10.99.0/24 | 10.10.99.1 | Διαχείριση συσκευών |
| 999 | BLACKHOLE | - | - | Αχρησιμοποίητες θύρες (shutdown) |

## 💻 Παράδειγμα διαμόρφωσης (Cisco IOS)

```text
! --- Δημιουργία VLANs ---
vlan 10
 name USERS
vlan 20
 name SERVERS

! --- Inter-VLAN routing (SVIs) στο L3 switch ---
ip routing
interface vlan 10
 ip address 10.10.10.1 255.255.255.0
 no shutdown
interface vlan 20
 ip address 10.10.20.1 255.255.255.0
 no shutdown

! --- Trunk προς access switch ---
interface gigabitEthernet 1/0/48
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30,99
 switchport trunk native vlan 999

! --- Θύρα χρήστη ---
interface gigabitEthernet 1/0/1
 switchport mode access
 switchport access vlan 10
 spanning-tree portfast
 switchport port-security

! --- OSPF ---
router ospf 1
 router-id 1.1.1.1
 network 10.10.0.0 0.0.255.255 area 0
 passive-interface default
 no passive-interface gigabitEthernet 1/0/47
```

## 🔎 Μέθοδοι Inter-VLAN Routing

| Μέθοδος | Περιγραφή | Χρήση |
|---------|-----------|-------|
| **Router-on-a-stick** | Ένας router με subinterfaces πάνω σε ένα trunk | Μικρά δίκτυα, labs |
| **Layer 3 Switch (SVI)** | Routing στο switch με virtual interfaces | Τυπική επιλογή σε εταιρικά δίκτυα |
| **Routed ports** | Layer 3 θύρες, χωρίς VLANs | Core / uplinks |

## ✅ Βέλτιστες πρακτικές

- Native VLAN **διαφορετικό από το 1** και αχρησιμοποίητο.
- **Allowed VLAN list** στα trunks (όχι "all").
- Αχρησιμοποίητες θύρες: `shutdown` και τοποθέτηση σε blackhole VLAN.
- Ενεργοποίηση **BPDU Guard / Root Guard**, **DHCP Snooping** και **Dynamic ARP Inspection**.
- **ACLs** στο inter-VLAN routing (π.χ. οι guests δεν φτάνουν στους servers).
- **Passive-interface** στα LAN interfaces όπου δεν χρειάζεται OSPF.
- Συνεπής σύμβαση: το VLAN ID να αντιστοιχεί στο τρίτο octet (VLAN 10 → 10.10.**10**.0/24).

## ⚠️ Συχνά λάθη

- VLAN που δεν υπάρχει σε όλα τα switches του trunk path.
- Αναντιστοιχία native VLAN μεταξύ των δύο άκρων του trunk.
- Ξεχασμένα default gateway ή DHCP helper (`ip helper-address`).
- Επικαλυπτόμενα subnets μεταξύ sites.

## 🛠️ Εντολές ελέγχου

```text
show vlan brief
show interfaces trunk
show ip interface brief
show ip route
show ip ospf neighbor
show spanning-tree
```

## 🔗 Σχετικά

[Enterprise Network](./01-enterprise-network.md) · [DMZ](./04-dmz-architecture.md)
