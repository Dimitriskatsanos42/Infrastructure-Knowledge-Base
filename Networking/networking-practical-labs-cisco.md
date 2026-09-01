# 🔧 Networking Practical Labs — Cisco IOS Configuration & Troubleshooting

Συμπληρωματικό αρχείο στο `networking.md`. Ενώ εκείνο καλύπτει τη **θεωρία** (OSI, TCP/IP, routing protocols, VLANs, κλπ.), αυτό δείχνει **πώς εφαρμόζονται στην πράξη** μέσω πραγματικών Cisco IOS εντολών — κάτι που ζητείται συχνά σε networking-related θέσεις εργασίας ή πιστοποιήσεις (CCNA-style).

---

## 🗺️ Πίνακας Περιεχομένων

1. [Βασική Πλοήγηση Cisco IOS](#-1-βασική-πλοήγηση-cisco-ios)
2. [Βασική Ρύθμιση Switch](#-2-βασική-ρύθμιση-switch)
3. [VLANs & Trunking — Πρακτική Υλοποίηση](#-3-vlans--trunking--πρακτική-υλοποίηση)
4. [Inter-VLAN Routing](#-4-inter-vlan-routing)
5. [Spanning Tree Protocol (STP)](#-5-spanning-tree-protocol-stp)
6. [Static & Default Routing](#-6-static--default-routing)
7. [OSPF — Βασική Ρύθμιση](#-7-ospf--βασική-ρύθμιση)
8. [Access Control Lists (ACLs)](#-8-access-control-lists-acls)
9. [NAT/PAT Configuration](#-9-natpat-configuration)
10. [HSRP — High Availability](#-10-hsrp--high-availability)
11. [DHCP Configuration σε Router](#-11-dhcp-configuration-σε-router)
12. [Troubleshooting Commands — Cheat Sheet](#-12-troubleshooting-commands--cheat-sheet)

---

## 🖥️ 1. Βασική Πλοήγηση Cisco IOS

### Modes
```
Router> enable                    # User EXEC → Privileged EXEC
Router# configure terminal        # Privileged EXEC → Global Config
Router(config)# interface g0/0    # Global Config → Interface Config
```

| Mode | Prompt | Τι επιτρέπει |
|---|---|---|
| User EXEC | `Router>` | Μόνο βασικοί, μη-καταστρεπτικοί έλεγχοι (show, ping) |
| Privileged EXEC | `Router#` | Πλήρης πρόσβαση σε show commands, debug |
| Global Config | `Router(config)#` | Αλλαγές ρυθμίσεων σε επίπεδο συσκευής |
| Interface Config | `Router(config-if)#` | Ρυθμίσεις συγκεκριμένου interface |

### Βασικές εντολές αποθήκευσης/ανάκτησης
```
Router# copy running-config startup-config    # Αποθήκευση ρυθμίσεων (persist μετά από reboot)
Router# show running-config                   # Τρέχουσα ενεργή ρύθμιση
Router# show startup-config                   # Ρύθμιση που θα φορτωθεί στο επόμενο boot
Router# reload                                # Επανεκκίνηση συσκευής
```

---

## 🔌 2. Βασική Ρύθμιση Switch

```
Switch> enable
Switch# configure terminal

! Hostname
Switch(config)# hostname SW-CORE01

! Management IP (VLAN 1 interface, για SSH/telnet πρόσβαση)
Switch(config)# interface vlan 1
Switch(config-if)# ip address 192.168.1.2 255.255.255.0
Switch(config-if)# no shutdown
Switch(config-if)# exit

Switch(config)# ip default-gateway 192.168.1.1

! Ασφάλεια πρόσβασης
Switch(config)# enable secret StrongPassword123
Switch(config)# line console 0
Switch(config-line)# password ConsolePass
Switch(config-line)# login
Switch(config-line)# exit

! SSH setup (αντί για telnet — best practice)
Switch(config)# ip domain-name contoso.local
Switch(config)# crypto key generate rsa
! (θα ζητήσει μέγεθος κλειδιού, π.χ. 2048)
Switch(config)# username admin secret AdminPass123
Switch(config)# line vty 0 15
Switch(config-line)# transport input ssh
Switch(config-line)# login local
```

---

## 🏷️ 3. VLANs & Trunking — Πρακτική Υλοποίηση

### Δημιουργία VLANs
```
Switch(config)# vlan 10
Switch(config-vlan)# name Finance
Switch(config-vlan)# exit

Switch(config)# vlan 20
Switch(config-vlan)# name HR
Switch(config-vlan)# exit
```

### Ανάθεση Access Ports
```
Switch(config)# interface fa0/1
Switch(config-if)# switchport mode access
Switch(config-if)# switchport access vlan 10
Switch(config-if)# exit

Switch(config)# interface range fa0/6 - 10
Switch(config-if-range)# switchport mode access
Switch(config-if-range)# switchport access vlan 20
```

### Trunk Port (σύνδεση Switch-to-Switch)
```
Switch(config)# interface gi0/1
Switch(config-if)# switchport mode trunk
Switch(config-if)# switchport trunk allowed vlan 10,20
Switch(config-if)# switchport trunk native vlan 99
```
> ⚠️ Best practice: αλλαγή του **native VLAN** σε κάτι διαφορετικό από το default VLAN 1 (πχ 99), για προστασία από VLAN hopping attacks.

### Επαλήθευση
```
Switch# show vlan brief
Switch# show interfaces trunk
Switch# show interfaces fa0/1 switchport
```

---

## 🔀 4. Inter-VLAN Routing

### Μέθοδος 1: Router-on-a-Stick (sub-interfaces σε trunk link)
```
Router(config)# interface g0/0
Router(config-if)# no shutdown
Router(config-if)# exit

Router(config)# interface g0/0.10
Router(config-subif)# encapsulation dot1Q 10
Router(config-subif)# ip address 192.168.10.1 255.255.255.0
Router(config-subif)# exit

Router(config)# interface g0/0.20
Router(config-subif)# encapsulation dot1Q 20
Router(config-subif)# ip address 192.168.20.1 255.255.255.0
```

### Μέθοδος 2: Layer 3 Switch (SVIs — πιο σύγχρονη/γρήγορη προσέγγιση)
```
Switch(config)# ip routing                    # Ενεργοποίηση L3 routing στο switch

Switch(config)# interface vlan 10
Switch(config-if)# ip address 192.168.10.1 255.255.255.0
Switch(config-if)# no shutdown
Switch(config-if)# exit

Switch(config)# interface vlan 20
Switch(config-if)# ip address 192.168.20.1 255.255.255.0
Switch(config-if)# no shutdown
```

---

## 🌲 5. Spanning Tree Protocol (STP)

Το **STP** αποτρέπει **loops** σε δίκτυα με πλεονάζουσες (redundant) συνδέσεις μεταξύ switches — χωρίς αυτό, ένα loop θα προκαλούσε broadcast storm και θα "έριχνε" όλο το δίκτυο.

### Βασική λογική
1. Επιλέγεται ένα **Root Bridge** (switch με το χαμηλότερο Bridge ID).
2. Κάθε άλλο switch υπολογίζει το συντομότερο μονοπάτι προς το Root Bridge.
3. Περιττές συνδέσεις μπαίνουν σε κατάσταση **Blocking** (δεν προωθούν κίνηση, αλλά παραμένουν έτοιμες σε περίπτωση αστοχίας).

### Βασικές εντολές
```
Switch(config)# spanning-tree mode rapid-pvst      # RSTP — γρηγορότερο convergence από το κλασικό STP
Switch(config)# spanning-tree vlan 10 priority 4096  # Χαμηλότερο priority = πιο πιθανό να γίνει Root Bridge

Switch# show spanning-tree vlan 10
Switch# show spanning-tree summary
```

### PortFast & BPDU Guard (για access ports σε τελικές συσκευές)
```
Switch(config-if)# spanning-tree portfast
Switch(config-if)# spanning-tree bpduguard enable
```
> `portfast` κάνει το port να μπαίνει άμεσα σε forwarding state (χωρίς να περιμένει το STP timer) — μόνο για ports που συνδέονται σε PCs, **ποτέ** σε άλλο switch.

---

## 🛣️ 6. Static & Default Routing

```
! Static route — συγκεκριμένο δίκτυο προορισμού
Router(config)# ip route 192.168.30.0 255.255.255.0 10.0.0.2

! Default route (gateway of last resort) — για όλη την υπόλοιπη κίνηση
Router(config)# ip route 0.0.0.0 0.0.0.0 203.0.113.1

! Επαλήθευση
Router# show ip route
Router# show ip route static
```

---

## 🌐 7. OSPF — Βασική Ρύθμιση

```
Router(config)# router ospf 1
Router(config-router)# network 192.168.10.0 0.0.0.255 area 0
Router(config-router)# network 192.168.20.0 0.0.0.255 area 0
Router(config-router)# router-id 1.1.1.1
Router(config-router)# exit

! Επαλήθευση
Router# show ip ospf neighbor
Router# show ip protocols
Router# show ip route ospf
```

### Wildcard mask — προσοχή, είναι το αντίστροφο του subnet mask
```
Subnet Mask:     255.255.255.0
Wildcard Mask:   0.0.0.255
```

---

## 🚧 8. Access Control Lists (ACLs)

### Standard ACL (φιλτράρει μόνο βάσει Source IP)
```
Router(config)# access-list 10 permit 192.168.10.0 0.0.0.255
Router(config)# access-list 10 deny any

Router(config)# interface g0/1
Router(config-if)# ip access-group 10 out
```

### Extended ACL (φιλτράρει Source, Destination, Protocol, Port)
```
Router(config)# access-list 100 permit tcp 192.168.10.0 0.0.0.255 any eq 443
Router(config)# access-list 100 permit tcp 192.168.10.0 0.0.0.255 any eq 80
Router(config)# access-list 100 deny ip any any log

Router(config)# interface g0/0
Router(config-if)# ip access-group 100 in
```

> ⚠️ Κανόνας: **Extended ACLs τοποθετούνται όσο πιο κοντά στην πηγή** (source), **Standard ACLs όσο πιο κοντά στον προορισμό** (destination) — γιατί το Standard ACL δεν ξέρει προορισμό/port, οπότε αν μπει νωρίς μπορεί να μπλοκάρει κίνηση που δεν έπρεπε.

### Επαλήθευση
```
Router# show access-lists
Router# show ip interface g0/0 | include access
```

---

## 🔄 9. NAT/PAT Configuration

```
! Ορισμός εσωτερικού και εξωτερικού interface
Router(config)# interface g0/0
Router(config-if)# ip nat inside
Router(config-if)# exit

Router(config)# interface g0/1
Router(config-if)# ip nat outside
Router(config-if)# exit

! ACL που ορίζει ποιο εσωτερικό δίκτυο θα κάνει NAT
Router(config)# access-list 1 permit 192.168.1.0 0.0.0.255

! PAT (NAT Overload) — χρήση της IP του outside interface
Router(config)# ip nat inside source list 1 interface g0/1 overload

! Επαλήθευση
Router# show ip nat translations
Router# show ip nat statistics
```

### Static NAT (για server προσβάσιμο από έξω)
```
Router(config)# ip nat inside source static 192.168.1.100 203.0.113.50
```

---

## 🔁 10. HSRP — High Availability

Το **HSRP (Hot Standby Router Protocol)** επιτρέπει σε δύο (ή περισσότερους) routers να μοιράζονται μία **virtual IP** ως default gateway — αν ο active router πέσει, ο standby αναλαμβάνει αυτόματα, χωρίς οι χρήστες να αλλάξουν τίποτα στη ρύθμιση τους.

```
! Στον Router-A (θα γίνει Active — υψηλότερο priority)
Router-A(config)# interface g0/0
Router-A(config-if)# ip address 192.168.1.2 255.255.255.0
Router-A(config-if)# standby 1 ip 192.168.1.1
Router-A(config-if)# standby 1 priority 110
Router-A(config-if)# standby 1 preempt

! Στον Router-B (θα γίνει Standby)
Router-B(config)# interface g0/0
Router-B(config-if)# ip address 192.168.1.3 255.255.255.0
Router-B(config-if)# standby 1 ip 192.168.1.1
Router-B(config-if)# standby 1 priority 100

! Επαλήθευση
Router# show standby brief
```
> Οι χρήστες βάζουν ως default gateway το **192.168.1.1** (virtual IP) — ποτέ τη φυσική IP κάποιου router.

---

## 📡 11. DHCP Configuration σε Router

```
Router(config)# ip dhcp excluded-address 192.168.1.1 192.168.1.10

Router(config)# ip dhcp pool LAN-POOL
Router(dhcp-config)# network 192.168.1.0 255.255.255.0
Router(dhcp-config)# default-router 192.168.1.1
Router(dhcp-config)# dns-server 8.8.8.8 1.1.1.1
Router(dhcp-config)# lease 7

! Επαλήθευση
Router# show ip dhcp binding
Router# show ip dhcp pool
```

---

## 🛠️ 12. Troubleshooting Commands — Cheat Sheet

| Σενάριο | Εντολή |
|---|---|
| Κατάσταση interfaces (up/down, IP) | `show ip interface brief` |
| Λεπτομέρειες συγκεκριμένου interface | `show interface g0/0` |
| Routing table | `show ip route` |
| MAC address table (switch) | `show mac address-table` |
| VLAN λίστα | `show vlan brief` |
| Trunk κατάσταση | `show interfaces trunk` |
| CDP γειτονικές συσκευές (Cisco Discovery Protocol) | `show cdp neighbors detail` |
| OSPF γείτονες | `show ip ospf neighbor` |
| NAT translations | `show ip nat translations` |
| ACL περιεχόμενο | `show access-lists` |
| Ping με source interface | `ping 8.8.8.8 source g0/0` |
| Traceroute | `traceroute 8.8.8.8` |
| Αντιγραφή τρέχουσας ρύθμισης σε flash | `copy running-config startup-config` |
| Έλεγχος logs | `show logging` |
| Debug (προσοχή σε production!) | `debug ip ospf events` |

### Δομημένη μεθοδολογία troubleshooting (Layer-by-layer, bottom-up)
```
1. Physical (Layer 1): Είναι συνδεδεμένο το καλώδιο; Interface "up/up";
   → show ip interface brief

2. Data Link (Layer 2): Σωστό VLAN; Trunk λειτουργεί; MAC table σωστό;
   → show vlan brief, show mac address-table

3. Network (Layer 3): Σωστή IP/subnet mask; Routing table έχει τη διαδρομή;
   → show ip route, ping

4. Transport/Application: Το port είναι ανοιχτό; Η υπηρεσία τρέχει;
   → telnet <ip> <port>, show access-lists
```

---

*Μέρος του [Infrastructure Knowledge Base](https://github.com/Dimitriskatsanos42/Infrastructure-Knowledge-Base) — φάκελος Networking, συμπληρωματικό στο θεωρητικό `networking.md`.*
