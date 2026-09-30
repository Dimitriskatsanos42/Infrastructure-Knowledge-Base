# 🧪 Testing & Quality Assurance

![Status](https://img.shields.io/badge/status-active-brightgreen)
![Docs](https://img.shields.io/badge/docs-Greek%20%2F%20Ελληνικά-blue)
![License](https://img.shields.io/badge/type-knowledge--base-lightgrey)

> Αρμοδιότητες, Αρχές, Επίπεδα Testing, Τεκμηρίωση & Καλές Πρακτικές για **Developers**, **QA Engineers** και **IT System Analysts / Testers**.

---

## 📚 Πίνακας Περιεχομένων

1. [Περιγραφή Repository](#-περιγραφή-repository)
2. [Δομή Φακέλου](#-δομή-φακέλου)
3. [Αρμοδιότητες & Δραστηριότητες](#-αρμοδιότητες--δραστηριότητες)
4. [Γιατί κάνουμε Software Testing;](#-γιατί-κάνουμε-software-testing)
5. [Η Πυραμίδα του Testing](#-η-πυραμίδα-του-testing)
6. [Επίπεδα Testing](#-επίπεδα-testing)
7. [Μεθοδολογίες Testing](#️-μεθοδολογίες-testing)
8. [Black-Box vs White-Box Testing](#️-black-box-vs-white-box-testing)
9. [Τύποι Non-Functional Testing](#-τύποι-non-functional-testing)
10. [Τεκμηρίωση (Use Cases, Test Cases, Reports)](#-τεκμηρίωση)
11. [Κύκλος Ζωής Defect](#-κύκλος-ζωής-defect)
12. [Καλές Πρακτικές](#-καλές-πρακτικές)
13. [Εργαλεία](#️-εργαλεία)
14. [Checklist πριν το Release](#-checklist-πριν-το-release)

---

## 📁 Περιγραφή Repository

Ο παρών φάκελος αφορά τις δραστηριότητες **testing** και διασφάλισης ποιότητας (QA) στο πλαίσιο ανάπτυξης web εφαρμογών, καθώς και τη συνεργασία με πελάτες κατά τη διάρκεια του κύκλου ζωής ανάπτυξης λογισμικού (SDLC).

Χρησιμοποιείται για:

- Οργάνωση & αποθήκευση **Test Plans**, **Test Cases**, **Test Reports**
- Καταγραφή **Use Cases** και απαιτήσεων
- Διατήρηση **User Manuals** και υλικού project management
- Έτοιμα **templates** προς επαναχρησιμοποίηση σε νέα projects

---

## 🗂 Δομή Φακέλου

```
Software Testing/
├── README.md                          ← Το παρόν αρχείο
└── templates/
    ├── Test-Plan-Template.md          ← Πλάνο ελέγχου (πεδίο εφαρμογής, στρατηγική, χρονοδιάγραμμα)
    ├── Use-Case-Template.md           ← Καταγραφή απαιτήσεων/σεναρίων χρήσης
    ├── Test-Case-Template.md          ← Μεμονωμένα σενάρια ελέγχου
    ├── Bug-Report-Template.md         ← Αναφορά σφάλματος (defect)
    └── Test-Summary-Report-Template.md← Συγκεντρωτική αναφορά αποτελεσμάτων
```

> 💡 Κάθε νέο project/feature μπορεί να δημιουργεί δικό του υποφάκελο (π.χ. `Projects/<project-name>/`) χρησιμοποιώντας τα παραπάνω templates ως βάση.

---

## 👤 Αρμοδιότητες & Δραστηριότητες

- **Συμμετοχή σε συναντήσεις** λειτουργικού χαρακτήρα (functional meetings) και προόδου (progress meetings) με πελάτες.
- **Ανάλυση & επεξεργασία** λειτουργικών/μη λειτουργικών απαιτήσεων και προδιαγραφών (Use Cases κ.ά.).
- **Συμμετοχή στον πλήρη κύκλο ανάπτυξης** web εφαρμογών: ανάλυση, testing, εκπαίδευση χρηστών (training) και υποστήριξη χρηστών (help-desk).
- **Προετοιμασία τεκμηρίωσης** ανάπτυξης λογισμικού: Test Cases, Test Reports, User Manuals κ.ά.
- **Υποστήριξη διαχείρισης έργου**: συντονισμός ομάδας, οργάνωση διεργασιών και reporting προόδου.

---

## 🎯 Γιατί κάνουμε Software Testing;

Το testing δεν αφορά μόνο την εύρεση bugs — αφορά τη **μείωση ρίσκου**, τη **διασφάλιση ποιότητας** και τη **μακροπρόθεσμη βιωσιμότητα** του κώδικα.

| Λόγος | Περιγραφή |
|---|---|
| 💰 **Οικονομία** | Η διόρθωση bug σε παραγωγή κοστίζει πολλαπλάσια από ό,τι κατά την ανάπτυξη |
| 🛡️ **Εμπιστοσύνη** | Αυτοματοποιημένα tests επιτρέπουν refactor χωρίς φόβο regressions |
| 🔒 **Ασφάλεια** | Εντοπισμός ευπαθειών πριν τις εκμεταλλευτούν κακόβουλοι χρήστες |
| 😊 **UX** | Διασφαλίζει ότι η εφαρμογή συμπεριφέρεται ακριβώς όπως αναμένει ο χρήστης |
| 📈 **Αξιοπιστία** | Μειώνει το downtime και ενισχύει την εμπιστοσύνη πελατών/χρηστών |

---

## 📐 Η Πυραμίδα του Testing

Η βασική αρχή: **πολλά γρήγορα tests στη βάση, λίγα αργά tests στην κορυφή.**

```
          ▲
         /E2E\            ← Αργά · Ακριβά · Υψηλή εμπιστοσύνη
        /─────\
       /       \
      /Integration\       ← Μέση ταχύτητα · Ελέγχουν σύνδεση εξαρτημάτων
     /─────────────\
    /               \
   /      Unit       \    ← Ταχύτατα · Απομονωμένα · Καλύπτουν edge cases
  /───────────────────\
```

---

## 🔍 Επίπεδα Testing

### 1. Unit Testing *(Μοναδιαίος Έλεγχος)*

Ελέγχει το **μικρότερο απομονωμένο κομμάτι κώδικα** — μια συνάρτηση, μέθοδο ή κλάση.

- ✅ Εξαιρετικά γρήγορο
- ✅ Χρησιμοποιεί mocks/stubs για εξωτερικές εξαρτήσεις
- ✅ Επιβεβαιώνει ότι μια συνάρτηση επιστρέφει το σωστό αποτέλεσμα

### 2. Integration Testing *(Έλεγχος Ενοποίησης)*

Ελέγχει πώς **συνεργάζονται** διαφορετικά modules, υπηρεσίες ή βάσεις δεδομένων.

- ✅ Αλληλεπιδρά με πραγματικά ή staged εξωτερικά συστήματα
- ✅ Διασφαλίζει ότι τα δεδομένα ρέουν σωστά μεταξύ εξαρτημάτων
- ⚠️ Πιο αργό από το Unit Testing

### 3. Functional / Component Testing *(Λειτουργικός Έλεγχος)*

Ελέγχει μια **ολοκληρωμένη λειτουργία** βάσει επιχειρηματικών απαιτήσεων.

- ✅ Επαληθεύει ότι το λογισμικό κάνει αυτό που ζήτησε ο πελάτης/χρήστης

### 4. System Testing *(Έλεγχος Συστήματος)*

Ελέγχει το **σύστημα ως σύνολο**, σε περιβάλλον όσο το δυνατόν πιο κοντά στο production.

- ✅ Καλύπτει end-to-end ροές, απόδοση και αξιοπιστία σε επίπεδο συστήματος

### 5. End-to-End (E2E) / Acceptance Testing

Ελέγχει **ολόκληρη τη ροή** από την πλευρά του χρήστη, σε πραγματικό browser ή συσκευή· περιλαμβάνει και το **User Acceptance Testing (UAT)**, όπου ο πελάτης/τελικός χρήστης επιβεβαιώνει ότι το σύστημα καλύπτει τις ανάγκες του.

- ✅ Η μεγαλύτερη σιγουριά — ελέγχει Frontend, Backend, DB και 3rd-party APIs
- ⚠️ Πιο αργά tests και πιο ευαίσθητα σε αλλαγές (flaky)

---

## ⚙️ Μεθοδολογίες Testing

### 🧪 Test-Driven Development (TDD)

Γράφεις το test **πριν** γράψεις τον κώδικα.

```
🔴 Red      →  Γράψε test που αποτυγχάνει (η λειτουργία δεν υπάρχει ακόμα)
🟢 Green    →  Γράψε τον ελάχιστο κώδικα για να περάσει το test
🔵 Refactor →  Καθάρισε τον κώδικα — το test πρέπει να παραμείνει πράσινο
```

> Επανάλαβε τον κύκλο για κάθε νέα λειτουργία.

### 👥 Behavior-Driven Development (BDD)

Επέκταση του TDD με **φυσική γλώσσα** (σύνταξη Given / When / Then), εστιάζει στη συμπεριφορά από την πλευρά του χρήστη.

```
Given  ο χρήστης βρίσκεται στη σελίδα σύνδεσης
When   πληκτρολογήσει σωστά στοιχεία και πατήσει υποβολή
Then   ανακατευθύνεται στο dashboard
```

### 🔁 Regression Testing

Επανέλεγχος υπαρχουσών λειτουργιών μετά από αλλαγές στον κώδικα, ώστε να επιβεβαιωθεί ότι **δεν έσπασε κάτι που ήδη δούλευε**.

### 💨 Smoke Testing

Γρήγορος, «επιφανειακός» έλεγχος βασικών λειτουργιών μετά από ένα νέο build, πριν προχωρήσει η ομάδα σε πλήρες testing.

---

## ☯️ Black-Box vs White-Box Testing

| | 🔲 Black-Box | ⬜ White-Box |
|---|---|---|
| **Γνώση κώδικα** | Καμία γνώση εσωτερικής δομής | Πλήρης πρόσβαση στον πηγαίο κώδικα |
| **Ποιος το κάνει** | QA Engineers, Τελικοί Χρήστες | Developers, Automation Engineers |
| **Εστίαση** | Inputs, outputs, απαιτήσεις χρήστη | Code paths, statements, branches, loops |
| **Τύποι** | System Testing, Acceptance Testing | Unit Testing, Mutation Testing |

> Υπάρχει και το **Grey-Box Testing**, συνδυασμός των δύο: μερική γνώση εσωτερικής λογικής με έλεγχο μέσω external interfaces.

---

## 🧩 Τύποι Non-Functional Testing

| Τύπος | Τι ελέγχει |
|---|---|
| ⚡ **Performance Testing** | Ταχύτητα απόκρισης του συστήματος υπό κανονικό φόρτο |
| 🏋️ **Load / Stress Testing** | Συμπεριφορά συστήματος υπό υψηλό ή ακραίο φόρτο |
| 🔐 **Security Testing** | Ευπάθειες, εξουσιοδότηση, αυθεντικοποίηση, διαρροή δεδομένων |
| ♿ **Usability / Accessibility** | Ευκολία χρήσης και προσβασιμότητα (WCAG) |
| 📱 **Compatibility Testing** | Συμπεριφορά σε διαφορετικά browsers/συσκευές/OS |

---

## 📋 Τεκμηρίωση

Τα παρακάτω αντιστοιχούν σε έτοιμα templates στον φάκελο [`templates/`](./templates).

### Use Case → [`Use-Case-Template.md`](./templates/Use-Case-Template.md)

Περιγράφει την αλληλεπίδραση χρήστη-συστήματος για την επίτευξη ενός στόχου:

- **Actor** — χρήστης ή εξωτερικό σύστημα
- **Main Flow** — κύρια ροή ενεργειών
- **Alternative Flows** — εναλλακτικές/εξαιρετικές ροές
- **Preconditions / Postconditions** — προϋποθέσεις και αναμενόμενα αποτελέσματα

### Test Plan → [`Test-Plan-Template.md`](./templates/Test-Plan-Template.md)

Καθορίζει τη **στρατηγική ελέγχου** ενός project: πεδίο εφαρμογής, προσέγγιση, resources, χρονοδιάγραμμα, κριτήρια εισόδου/εξόδου.

### Test Case → [`Test-Case-Template.md`](./templates/Test-Case-Template.md)

Περιγράφει ένα σενάριο ελέγχου και περιλαμβάνει:

- Προϋποθέσεις (Preconditions)
- Βήματα εκτέλεσης (Steps)
- Δεδομένα εισόδου (Test Data)
- Αναμενόμενο αποτέλεσμα (Expected Result)
- Πραγματικό αποτέλεσμα (Actual Result)
- Κατάσταση (Pass/Fail)

### Bug Report → [`Bug-Report-Template.md`](./templates/Bug-Report-Template.md)

Καταγραφή σφάλματος με βήματα αναπαραγωγής, severity/priority και περιβάλλον εκτέλεσης.

### Test Report → [`Test-Summary-Report-Template.md`](./templates/Test-Summary-Report-Template.md)

Συγκεντρωτική αναφορά που περιλαμβάνει:

- Σύνολο εκτελεσθέντων test cases
- Ποσοστό επιτυχίας/αποτυχίας
- Καταγεγραμμένα bugs (defects)
- Συμπεράσματα και προτάσεις

---

## 🔄 Κύκλος Ζωής Defect

```
New → Assigned → Open → In Progress → Fixed → Retest → Closed
                                          │
                                          └──→ Reopened (αν αποτύχει το retest)
```

| Κατάσταση | Περιγραφή |
|---|---|
| **New** | Το defect μόλις καταγράφηκε |
| **Assigned** | Ανατέθηκε σε developer |
| **Open** | Έχει επιβεβαιωθεί και εκκρεμεί διόρθωση |
| **Fixed** | Ο developer έχει ολοκληρώσει τη διόρθωση |
| **Retest** | Ο QA επαναλαμβάνει το test case |
| **Closed** | Το defect επιβεβαιώθηκε ότι διορθώθηκε |
| **Reopened** | Το retest απέτυχε — επιστρέφει σε Open |

---

## 💡 Καλές Πρακτικές

### Το μοτίβο AAA

Κάθε test πρέπει να ακολουθεί τη δομή:

```
Arrange  →  Αρχικοποίησε δεδομένα και συνθήκες εισόδου
Act      →  Εκτέλεσε τη συνάρτηση ή ενέργεια που ελέγχεις
Assert   →  Επιβεβαίωσε ότι το αποτέλεσμα είναι το αναμενόμενο
```

### Κανόνες

- **Απομόνωση** — ένα test δεν εξαρτάται ποτέ από το αποτέλεσμα άλλου
- **Ντετερμινισμός** — αποτέλεσμα ίδιο κάθε φορά· απόφευγε `Date.now()` χωρίς static seed
- **Ένα πράγμα** — κάθε test εστιάζει σε μία μόνο συμπεριφορά ή edge case
- **Ταχύτητα** — τα unit tests πρέπει να τρέχουν σε millisecond· βάλε τα αργά tests σε ξεχωριστό suite
- **Καθαρά δεδομένα** — κάθε test φτιάχνει/καθαρίζει τα δικά του δεδομένα (setup/teardown)

### Ονοματολογία

```
# Κακό
testUser()

# Καλό
should_ReturnError_When_PasswordIsTooShort()
```

---

## 🛠️ Εργαλεία

| Γλώσσα | Εργαλεία |
|---|---|
| **JavaScript / TypeScript** | Jest, Vitest, Mocha, Cypress, Playwright |
| **Python** | PyTest, Unittest, Robot Framework |
| **Java** | JUnit, TestNG, Mockito |
| **C# / .NET** | xUnit, NUnit, FluentAssertions |
| **Performance / Load** | JMeter, K6 |
| **API Testing** | Postman, REST Assured, Insomnia |
| **Bug Tracking / PM** | Jira, Azure DevOps, TestRail |

---

## ✅ Checklist πριν το Release

- [ ] Όλα τα κρίσιμα (critical/high) defects έχουν κλείσει
- [ ] Τα smoke tests περνάνε σε staging environment
- [ ] Έχει ολοκληρωθεί το regression suite
- [ ] Το Test Summary Report έχει εγκριθεί από stakeholders
- [ ] Τα release notes / user manual έχουν ενημερωθεί
- [ ] Έχει γίνει backup πριν το deployment

---

## 📌 Σημειώσεις

Αυτό το documentation ενημερώνεται συνεχώς καθώς προστίθενται νέα projects, εργαλεία και πρακτικές. Προτάσεις και βελτιώσεις είναι ευπρόσδεκτες μέσω Pull Request ή Issue.
