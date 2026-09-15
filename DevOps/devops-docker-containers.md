# 🐳 Docker & Containerization — Βασικά & Πρακτική

Τέταρτο αρχείο του φακέλου **DevOps**, συμπληρωματικό στα `devops-fundamentals-roadmap.md`, `devops-git-cicd.md` και `devops-debugging-troubleshooting.md`. Καλύπτει το **Docker** σε βάθος — από τη θεωρία (τι είναι πραγματικά ένα container) μέχρι πρακτικά Dockerfiles, docker-compose και best practices για production.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Τι Είναι Πραγματικά ένα Container](#-1-τι-είναι-πραγματικά-ένα-container)
2. [Containers vs Virtual Machines](#-2-containers-vs-virtual-machines)
3. [Docker Αρχιτεκτονική](#-3-docker-αρχιτεκτονική)
4. [Βασικές Docker Εντολές](#-4-βασικές-docker-εντολές)
5. [Dockerfile — Γραφή & Best Practices](#-5-dockerfile--γραφή--best-practices)
6. [Multi-Stage Builds](#-6-multi-stage-builds)
7. [Docker Networking](#-7-docker-networking)
8. [Volumes & Data Persistence](#-8-volumes--data-persistence)
9. [Docker Compose — Multi-Container Εφαρμογές](#-9-docker-compose--multi-container-εφαρμογές)
10. [Image Optimization & Security](#-10-image-optimization--security)
11. [Registry — Αποθήκευση & Διανομή Images](#-11-registry--αποθήκευση--διανομή-images)
12. [Πλήρες Παράδειγμα — Containerize μια 3-Tier Εφαρμογή](#-12-πλήρες-παράδειγμα--containerize-μια-3-tier-εφαρμογή)

---

## 📦 1. Τι Είναι Πραγματικά ένα Container

Ένα container **δεν είναι** μια "ελαφριά VM" — είναι μια **διεργασία του host λειτουργικού συστήματος**, απομονωμένη μέσω δύο βασικών χαρακτηριστικών του Linux kernel:

| Μηχανισμός | Τι κάνει |
|---|---|
| **Namespaces** | Απομονώνει τι "βλέπει" το container: δικό του PID space, δικό του network, δικό του filesystem view |
| **cgroups** (Control Groups) | Περιορίζει πόσα resources (CPU, memory, I/O) μπορεί να χρησιμοποιήσει |

### Γιατί έχει σημασία αυτή η διάκριση
Επειδή ένα container **μοιράζεται τον kernel του host**, δεν χρειάζεται να "σηκώσει" ολόκληρο λειτουργικό σύστημα (όπως μια VM) — γι' αυτό ξεκινάει σε **δευτερόλεπτα** αντί για λεπτά, και είναι πολύ πιο "ελαφρύ" σε resources.

```
Host OS Kernel (Linux)
├── Namespace A (Container 1) — δικό του PID 1, δικό του network stack
├── Namespace B (Container 2) — δικό του PID 1, δικό του network stack
└── Namespace C (Container 3) — δικό του PID 1, δικό του network stack
```

---

## ⚖️ 2. Containers vs Virtual Machines

| | Virtual Machine | Container |
|---|---|---|
| Τι περιλαμβάνει | Πλήρες guest OS + kernel | Μόνο την εφαρμογή + libraries |
| Εκκίνηση | Λεπτά | Δευτερόλεπτα (ή λιγότερο) |
| Μέγεθος | GBs | MBs (συνήθως) |
| Απομόνωση | Πλήρης (ξεχωριστός kernel) | Process-level (μοιράζονται τον host kernel) |
| Πυκνότητα (πόσα σε ένα host) | Δεκάδες | Εκατοντάδες/χιλιάδες |
| Χρήση | Διαφορετικά OS στο ίδιο hardware | Πακετάρισμα/deployment εφαρμογών |

```
Virtual Machines:                    Containers:
┌─────────┐ ┌─────────┐             ┌─────────┐ ┌─────────┐
│  App A  │ │  App B  │             │  App A  │ │  App B  │
├─────────┤ ├─────────┤             ├─────────┤ ├─────────┤
│ Guest OS│ │ Guest OS│             │ Docker Engine (shared)│
├─────────┴─┴─────────┤             ├───────────────────────┤
│      Hypervisor      │             │      Host OS Kernel   │
├───────────────────────┤             ├───────────────────────┤
│       Host OS         │             │       Hardware         │
└───────────────────────┘             └───────────────────────┘
```

> **Σημείωση:** τα δύο δεν είναι αμοιβαία αποκλειόμενα — πολύ συχνά τρέχεις Docker containers **μέσα** σε μια VM (πχ στο Azure/AWS), συνδυάζοντας την ασφάλεια απομόνωσης της VM με την ευελιξία των containers.

---

## 🏗️ 3. Docker Αρχιτεκτονική

```
┌──────────────┐      REST API      ┌──────────────────┐
│ Docker Client │ ────────────────> │  Docker Daemon    │
│  (docker CLI) │                    │  (dockerd)         │
└──────────────┘                    └──────────────────┘
                                              │
                          ┌───────────────────┼───────────────────┐
                          ▼                   ▼                   ▼
                    ┌──────────┐        ┌──────────┐        ┌──────────┐
                    │Container 1│       │Container 2│       │  Images   │
                    └──────────┘        └──────────┘        └──────────┘
```

| Στοιχείο | Ρόλος |
|---|---|
| **Docker Client** | Το CLI (`docker`) που χρησιμοποιείς |
| **Docker Daemon** (`dockerd`) | Η διεργασία στο παρασκήνιο που κάνει την πραγματική δουλειά |
| **Image** | Το "πρότυπο" (template) — read-only, στρωματοποιημένο (layered) |
| **Container** | Μια **εκτελούμενη instance** ενός image (read-write layer πάνω στο image) |
| **Registry** | Αποθήκη images (πχ Docker Hub, private registry) |

### Layers — γιατί τα images είναι στρωματοποιημένα
```
Layer 4: COPY app.js .              (η τελευταία αλλαγή σου)
Layer 3: RUN npm install            (dependencies)
Layer 2: COPY package.json .
Layer 1: FROM node:20-alpine        (base image)
```
> Κάθε εντολή στο Dockerfile δημιουργεί ένα νέο layer. Το Docker **cache-άρει** layers — αν δεν άλλαξε κάτι σε ένα layer, το reuse-άρει σε επόμενα builds (γρηγορότερο build).

---

## 🔧 4. Βασικές Docker Εντολές

### Images
```bash
docker images                         # Λίστα local images
docker pull nginx:latest              # Λήψη image από registry
docker build -t myapp:1.0 .           # Build image από Dockerfile στον τρέχοντα φάκελο
docker rmi myapp:1.0                  # Διαγραφή image
docker tag myapp:1.0 myapp:latest     # Νέο tag στο ίδιο image
```

### Containers
```bash
docker run -d -p 8080:80 --name web nginx     # Τρέξε container (detached, port mapping)
docker ps                                      # Ενεργά containers
docker ps -a                                   # Όλα τα containers (και stopped)
docker stop web                                # Σταμάτημα (graceful, SIGTERM)
docker kill web                                # Άμεσο σταμάτημα (SIGKILL)
docker rm web                                  # Διαγραφή (πρέπει να είναι stopped)
docker restart web
```

### Καθαρισμός (πολύ χρήσιμο, τα images/containers "μαζεύονται" με τον καιρό)
```bash
docker system df                      # Πόσο χώρο πιάνουν images/containers/volumes
docker system prune                   # Καθαρισμός stopped containers, unused networks, dangling images
docker system prune -a                # Πιο επιθετικό — αφαιρεί ΟΛΑ τα unused images
docker volume prune                   # Καθαρισμός unused volumes
```

---

## 📄 5. Dockerfile — Γραφή & Best Practices

### Απλό παράδειγμα (Node.js εφαρμογή)
```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

USER node

CMD ["node", "server.js"]
```

### Επεξήγηση βασικών εντολών

| Εντολή | Σκοπός |
|---|---|
| `FROM` | Το base image (πάντα η πρώτη γραμμή) |
| `WORKDIR` | Ορίζει τον working directory μέσα στο container |
| `COPY` | Αντιγραφή αρχείων από τον host μέσα στο image |
| `RUN` | Εκτέλεση εντολής **κατά το build** (δημιουργεί layer) |
| `EXPOSE` | Τεκμηρίωση ποιο port χρησιμοποιεί η εφαρμογή (δεν ανοίγει το port, μόνο δηλώνει) |
| `ENV` | Ορισμός environment variable |
| `USER` | Αλλαγή από root σε λιγότερο-προνομιούχο χρήστη (security best practice) |
| `CMD` | Η default εντολή που τρέχει όταν ξεκινάει το container |
| `ENTRYPOINT` | Παρόμοιο με CMD, αλλά πιο δύσκολο να παρακαμφθεί — καλό για "εφαρμογές σαν εντολή" |

### Best Practices — Checklist

```dockerfile
# ✅ Χρησιμοποίησε συγκεκριμένο, μικρό base image (alpine variants)
FROM node:20-alpine          # ΟΧΙ FROM node:latest (απρόβλεπτο ποια version)

# ✅ Αντίγραψε ΠΡΩΤΑ τα dependency manifests, ΜΕΤΑ τον υπόλοιπο κώδικα
# (εκμεταλλεύεται το layer caching — τα dependencies αλλάζουν σπανιότερα από τον κώδικα)
COPY package*.json ./
RUN npm ci
COPY . .

# ✅ Χρησιμοποίησε .dockerignore (αντίστοιχο του .gitignore)
# node_modules/, .git/, *.md, .env

# ✅ Μην τρέχεις ως root
USER node

# ✅ Χρησιμοποίησε multi-stage builds για compiled languages (βλ. κεφάλαιο 6)

# ❌ ΜΗΝ βάζεις secrets/credentials μέσα στο Dockerfile
# ENV DB_PASSWORD=secret123    ← ΠΟΤΕ ΕΤΣΙ
```

### .dockerignore παράδειγμα
```
node_modules
.git
.env
*.md
.vscode
dist
npm-debug.log
```

---

## 🏗️ 6. Multi-Stage Builds

Λύνει ένα πολύ συνηθισμένο πρόβλημα: το **build environment** (compilers, dev dependencies) δεν χρειάζεται να καταλήγει στο **τελικό production image** — αυτό το κάνει μικρότερο και πιο ασφαλές.

### Παράδειγμα: Go εφαρμογή (compiled language)
```dockerfile
# Stage 1: Build
FROM golang:1.22 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o myapp .

# Stage 2: Production (μόνο το compiled binary)
FROM alpine:3.19
WORKDIR /app
COPY --from=builder /app/myapp .
CMD ["./myapp"]
```

### Παράδειγμα: React frontend (build στο Node, serve με Nginx)
```dockerfile
# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Serve με Nginx (πολύ μικρότερο τελικό image)
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### Αποτέλεσμα μεγέθους (τυπικό παράδειγμα)
| Προσέγγιση | Μέγεθος τελικού image |
|---|---:|
| Single-stage (με build tools) | ~1.2 GB |
| Multi-stage (μόνο runtime) | ~40 MB |

---

## 🌐 7. Docker Networking

### Τύποι δικτύου

| Network Type | Περιγραφή |
|---|---|
| **bridge** (default) | Ιδιωτικό εσωτερικό δίκτυο, containers επικοινωνούν μέσω IP/container name |
| **host** | Το container μοιράζεται απευθείας το network stack του host (καμία απομόνωση δικτύου) |
| **none** | Καμία δικτυακή πρόσβαση |
| **overlay** | Για multi-host επικοινωνία (Docker Swarm) |

### Πρακτικά παραδείγματα
```bash
# Δημιουργία custom bridge network
docker network create myapp-network

# Containers στο ίδιο custom network βλέπουν ο ένας τον άλλον με το ΟΝΟΜΑ τους (DNS)
docker run -d --name db --network myapp-network postgres
docker run -d --name api --network myapp-network myapi
# Μέσα στο "api" container: μπορείς να κάνεις connect στο "db:5432"

# Port mapping (host:container)
docker run -d -p 8080:80 nginx        # host port 8080 → container port 80
docker run -d -p 127.0.0.1:8080:80 nginx   # Μόνο localhost, όχι εξωτερική πρόσβαση
```

---

## 💾 8. Volumes & Data Persistence

Containers είναι **εφήμερα** (ephemeral) — όταν διαγράφονται, χάνονται και τα δεδομένα τους. Τα **Volumes** λύνουν αυτό το πρόβλημα.

| Τύπος | Περιγραφή | Χρήση |
|---|---|---|
| **Named Volume** | Διαχειρίζεται από το Docker, αποθηκεύεται σε `/var/lib/docker/volumes` | Databases, persistent app data |
| **Bind Mount** | Χαρτογραφεί συγκεκριμένο φάκελο του host | Development (live code reload) |
| **tmpfs Mount** | Στη μνήμη, ποτέ στον δίσκο | Προσωρινά, ευαίσθητα δεδομένα |

```bash
# Named volume
docker volume create db-data
docker run -d --name db -v db-data:/var/lib/postgresql/data postgres

# Bind mount (χρήσιμο σε development)
docker run -d --name web -v $(pwd)/src:/app/src myapp

# Λίστα/επιθεώρηση volumes
docker volume ls
docker volume inspect db-data
```

---

## 🧩 9. Docker Compose — Multi-Container Εφαρμογές

Ορίζει **πολλαπλά** containers και τη σχέση τους σε ένα αρχείο, αντί για πολλαπλές μεμονωμένες `docker run` εντολές.

```yaml
# docker-compose.yml
version: "3.8"

services:
  web:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DB_HOST=db
    depends_on:
      - db
    networks:
      - app-network

  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: myapp
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - app-network

  redis:
    image: redis:alpine
    networks:
      - app-network

volumes:
  db-data:

networks:
  app-network:
```

### Βασικές εντολές
```bash
docker compose up -d              # Εκκίνηση όλων των services (detached)
docker compose down               # Σταμάτημα + διαγραφή containers/networks
docker compose down -v            # Επιπλέον: διαγραφή volumes
docker compose logs -f web        # Logs συγκεκριμένου service
docker compose ps                 # Κατάσταση services
docker compose exec web sh        # Exec σε running service
docker compose build --no-cache   # Rebuild images χωρίς cache
```

### `.env` αρχείο για μεταβλητές (δεν μπαίνει σε git — βλ. `.gitignore` στο `devops-git-cicd.md`)
```
DB_PASSWORD=SuperSecretPass123
NODE_ENV=production
```

---

## 🔒 10. Image Optimization & Security

### Μείωση μεγέθους image
```dockerfile
# ✅ Χρήση alpine ή distroless base images
FROM node:20-alpine          # ~180MB αντί για ~1GB (node:20 πλήρες)

# ✅ Συνδυασμός RUN εντολών (λιγότερα layers)
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*
# αντί για 3 ξεχωριστά RUN

# ✅ Multi-stage builds (βλ. κεφάλαιο 6)
```

### Security scanning
```bash
# Docker Scout (ενσωματωμένο στο Docker Desktop)
docker scout cves myapp:latest

# Trivy (open-source, πολύ διαδεδομένο)
trivy image myapp:latest
```

### Βασικοί κανόνες ασφάλειας
| Κανόνας | Γιατί |
|---|---|
| Μην τρέχεις ως root | Αν κάποιος "σπάσει" το container, δεν έχει root δικαιώματα |
| Χρησιμοποίησε official/verified images | Αποφυγή malicious/backdoored images |
| Σκάναρε images για vulnerabilities (CI pipeline) | Εντοπισμός γνωστών CVEs πριν το deployment |
| Ποτέ secrets μέσα στο image | Χρήση secrets management (βλ. `devops-git-cicd.md` κεφάλαιο 9) |
| Read-only filesystem όπου γίνεται | `docker run --read-only` — μειώνει attack surface |

---

## 📤 11. Registry — Αποθήκευση & Διανομή Images

```bash
# Docker Hub (public/private)
docker login
docker tag myapp:1.0 username/myapp:1.0
docker push username/myapp:1.0

# Private registry (πχ Azure Container Registry)
docker login myregistry.azurecr.io
docker tag myapp:1.0 myregistry.azurecr.io/myapp:1.0
docker push myregistry.azurecr.io/myapp:1.0

# Λήψη από private registry
docker pull myregistry.azurecr.io/myapp:1.0
```

### Tagging strategy — best practice
```bash
# ❌ Αποφυγή μόνο :latest σε production (μη προβλέψιμο ποια ακριβώς version τρέχει)
docker build -t myapp:latest .

# ✅ Συγκεκριμένα, ανιχνεύσιμα tags
docker build -t myapp:1.4.2 .
docker build -t myapp:$(git rev-parse --short HEAD) .    # Git commit hash
docker build -t myapp:$(date +%Y%m%d)-build .             # Ημερομηνία build
```

---

## 🎯 12. Πλήρες Παράδειγμα — Containerize μια 3-Tier Εφαρμογή

```
Σενάριο: Web app (React) + API (Node.js) + Database (PostgreSQL)

1. Dockerfile για το API (multi-stage):

FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
USER node
EXPOSE 3000
CMD ["node", "dist/server.js"]

2. Dockerfile για το Frontend (multi-stage, Nginx serve):

FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html
EXPOSE 80

3. docker-compose.yml που τα ενώνει όλα:

version: "3.8"
services:
  frontend:
    build: ./frontend
    ports: ["80:80"]
    depends_on: [api]

  api:
    build: ./api
    ports: ["3000:3000"]
    environment:
      - DB_HOST=db
      - DB_PASSWORD=${DB_PASSWORD}
    depends_on: [db]

  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes: ["db-data:/var/lib/postgresql/data"]

volumes:
  db-data:

4. Εκκίνηση:
   docker compose up -d --build

5. Επόμενο βήμα (βλ. επόμενο αρχείο της σειράς):
   → Αυτά τα ίδια images πηγαίνουν σε Kubernetes για production-grade
     orchestration, scaling, και self-healing.
```

---

*Μέρος του [Infrastructure Knowledge Base](https://github.com/Dimitriskatsanos42/Infrastructure-Knowledge-Base) — φάκελος DevOps, συμπληρωματικό στα `devops-fundamentals-roadmap.md`, `devops-git-cicd.md` και `devops-debugging-troubleshooting.md`.*
