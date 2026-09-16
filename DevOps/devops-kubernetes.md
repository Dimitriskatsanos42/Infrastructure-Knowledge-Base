# ☸️ Kubernetes — Container Orchestration σε Βάθος

Πέμπτο αρχείο του φακέλου **DevOps**, συμπληρωματικό στα `devops-fundamentals-roadmap.md`, `devops-git-cicd.md`, `devops-debugging-troubleshooting.md` και `devops-docker-containers.md`. Το Docker σου έδειξε πώς πακετάρεις **ένα** container· το Kubernetes δείχνει πώς διαχειρίζεσαι **εκατοντάδες** containers σε production scale, με αυτόματη αποκατάσταση, scaling και zero-downtime deployments.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Γιατί Χρειάζεται Kubernetes](#-1-γιατί-χρειάζεται-kubernetes)
2. [Αρχιτεκτονική — Control Plane & Worker Nodes](#-2-αρχιτεκτονική--control-plane--worker-nodes)
3. [Βασικά Objects — Pod, Deployment, Service](#-3-βασικά-objects--pod-deployment-service)
4. [YAML Manifests — Πρακτικά Παραδείγματα](#-4-yaml-manifests--πρακτικά-παραδείγματα)
5. [kubectl — Βασικές Εντολές](#-5-kubectl--βασικές-εντολές)
6. [ConfigMaps & Secrets](#-6-configmaps--secrets)
7. [Namespaces — Λογικός Διαχωρισμός](#-7-namespaces--λογικός-διαχωρισμός)
8. [Scaling & Self-Healing](#-8-scaling--self-healing)
9. [Ingress — Είσοδος Κίνησης στο Cluster](#-9-ingress--είσοδος-κίνησης-στο-cluster)
10. [Persistent Storage](#-10-persistent-storage)
11. [Helm — Package Manager για Kubernetes](#-11-helm--package-manager-για-kubernetes)
12. [Πλήρες Παράδειγμα — Deployment 3-Tier Εφαρμογής σε K8s](#-12-πλήρες-παράδειγμα--deployment-3-tier-εφαρμογής-σε-k8s)

---

## 🤔 1. Γιατί Χρειάζεται Kubernetes

Το Docker Compose (βλ. `devops-docker-containers.md`) δουλεύει καλά για **development** ή μικρά, single-host deployments. Αλλά σε production, χρειάζεσαι απαντήσεις σε ερωτήσεις που το Compose δεν λύνει:

| Ερώτημα | Docker Compose | Kubernetes |
|---|---|---|
| "Τι γίνεται αν πέσει ο host;" | Τίποτα — τα πάντα εκεί σταματούν | Το K8s ξαναδημιουργεί τα pods σε άλλο node |
| "Πώς κάνω scale σε 50 instances;" | Χειροκίνητα, δύσκολο | `kubectl scale` — αυτόματο |
| "Πώς κάνω zero-downtime deployment;" | Δύσκολο | Native rolling updates |
| "Πώς κατανέμω κίνηση σε πολλά instances;" | Χρειάζεται εξωτερικό load balancer | Ενσωματωμένο (Service) |
| "Τι γίνεται αν το container κρασάρει;" | Χρειάζεται restart policy | Αυτόματο restart, health checks |

> Το Kubernetes είναι ουσιαστικά ένα **αυτοματοποιημένο λειτουργικό σύστημα για ολόκληρο cluster** — αντί να διαχειρίζεσαι μεμονωμένους servers, του λες "θέλω 5 αντίγραφα αυτής της εφαρμογής, πάντα διαθέσιμα" και το ίδιο φροντίζει να το πετύχει.

---

## 🏗️ 2. Αρχιτεκτονική — Control Plane & Worker Nodes

```
┌─────────────────────── CONTROL PLANE ───────────────────────┐
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────┐    │
│  │ API Server   │  │  Scheduler   │  │  Controller     │    │
│  │ (kube-apiserver) │ (kube-scheduler)│  Manager        │    │
│  └──────────────┘  └──────────────┘  └────────────────┘    │
│                    ┌──────────────┐                         │
│                    │     etcd     │  (κρατά ΟΛΗ την          │
│                    │  (database)  │   κατάσταση του cluster) │
│                    └──────────────┘                         │
└───────────────────────────┬───────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│  Worker Node 1 │   │  Worker Node 2 │   │  Worker Node 3 │
│  ┌───────────┐ │   │  ┌───────────┐ │   │  ┌───────────┐ │
│  │  kubelet   │ │   │  │  kubelet   │ │   │  │  kubelet   │ │
│  ├───────────┤ │   │  ├───────────┤ │   │  ├───────────┤ │
│  │ Pod │ Pod │ │   │  │ Pod │ Pod │ │   │  │ Pod │ Pod │ │
│  └───────────┘ │   │  └───────────┘ │   │  └───────────┘ │
└───────────────┘   └───────────────┘   └───────────────┘
```

### Control Plane — Ρόλοι

| Component | Ρόλος |
|---|---|
| **API Server** | Η "μπροστινή πόρτα" — όλες οι εντολές (`kubectl`) περνάνε από εδώ |
| **etcd** | Key-value database που κρατά την **πλήρη κατάσταση** του cluster (ποιο pod τρέχει πού, ρυθμίσεις, κλπ.) |
| **Scheduler** | Αποφασίζει **σε ποιο node** θα τρέξει κάθε νέο pod (βάσει resources, constraints) |
| **Controller Manager** | Συνεχώς συγκρίνει "τι θέλεις" (desired state) με "τι υπάρχει" (actual state) και διορθώνει διαφορές |

### Worker Node — Ρόλοι
| Component | Ρόλος |
|---|---|
| **kubelet** | Ο "agent" σε κάθε node — μιλάει με το control plane, τρέχει/σταματάει pods |
| **kube-proxy** | Διαχειρίζεται networking rules, ώστε τα Services να δουλεύουν σωστά |
| **Container Runtime** | Αυτό που πραγματικά τρέχει τα containers (containerd, CRI-O) |

### Η βασική φιλοσοφία: Declarative, όχι Imperative
```
Imperative (τι να κάνεις):
"Ξεκίνα ένα container, μετά ένα δεύτερο, μετά ρύθμισε load balancing..."

Declarative (τι θέλεις να υπάρχει — αυτό κάνει το K8s):
"Θέλω 3 replicas αυτής της εφαρμογής, πάντα διαθέσιμα"
→ Το K8s αναλαμβάνει ΠΩΣ να το πετύχει και να το διατηρήσει
```

---

## 🧱 3. Βασικά Objects — Pod, Deployment, Service

### Pod — η μικρότερη μονάδα
```
Pod
└── Container(s)   ← συνήθως 1, μερικές φορές περισσότερα (sidecar pattern)
```
- Το **Pod** είναι το μικρότερο deployable unit στο K8s — **όχι** το container.
- Συνήθως 1 container ανά pod, αλλά μπορεί να έχει περισσότερα που μοιράζονται δίκτυο/storage (πχ ένα app container + ένα logging sidecar).
- Pods είναι **εφήμερα** — δεν τα δημιουργείς απευθείας σε production, τα διαχειρίζεται ένα Deployment.

### Deployment — διαχειρίζεται Pods
```
Deployment (θέλω 3 replicas του "myapp:1.0")
    ├── Pod 1 (myapp:1.0)
    ├── Pod 2 (myapp:1.0)
    └── Pod 3 (myapp:1.0)
```
- Ορίζει **πόσα replicas** θέλεις και **ποιο image**.
- Χειρίζεται rolling updates, rollbacks, self-healing (αν πεθάνει ένα pod, δημιουργεί νέο).

### Service — σταθερό δίκτυο σημείο εισόδου
```
Service (myapp-service, σταθερό DNS name)
    │
    ├──> Pod 1 (IP αλλάζει κάθε φορά που ξαναδημιουργείται)
    ├──> Pod 2
    └──> Pod 3
```
- Τα Pods έχουν **εφήμερες IPs** — όταν ξαναδημιουργούνται, αλλάζουν.
- Το **Service** δίνει ένα **σταθερό** όνομα/IP που πάντα δείχνει στα σωστά, τρέχοντα pods (μέσω label selectors).

### Τύποι Service

| Τύπος | Περιγραφή | Χρήση |
|---|---|---|
| **ClusterIP** (default) | Πρόσβαση μόνο εντός του cluster | Επικοινωνία μεταξύ services (πχ API → DB) |
| **NodePort** | Ανοίγει συγκεκριμένο port σε κάθε node | Testing, απλά setups |
| **LoadBalancer** | Δημιουργεί εξωτερικό load balancer (cloud provider) | Public-facing εφαρμογές σε production |

---

## 📝 4. YAML Manifests — Πρακτικά Παραδείγματα

### Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-deployment
  labels:
    app: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
        - name: myapp
          image: myregistry.azurecr.io/myapp:1.4.2
          ports:
            - containerPort: 3000
          resources:
            requests:
              cpu: "250m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
          livenessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 15
            periodSeconds: 20
          readinessProbe:
            httpGet:
              path: /ready
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
```

### Επεξήγηση κρίσιμων πεδίων

| Πεδίο | Σημασία |
|---|---|
| `replicas` | Πόσα αντίγραφα του pod θέλεις |
| `selector.matchLabels` | Πώς το Deployment ξέρει ποια pods "ανήκουν" σε αυτό |
| `resources.requests` | Το **ελάχιστο** που εγγυάται ο Scheduler σε αυτό το pod |
| `resources.limits` | Το **μέγιστο** — αν το ξεπεράσει σε memory, γίνεται OOMKilled (βλ. `devops-debugging-troubleshooting.md`) |
| `livenessProbe` | "Είναι ζωντανό;" — αν αποτύχει, το K8s **restart-άρει** το pod |
| `readinessProbe` | "Είναι έτοιμο να δεχτεί traffic;" — αν αποτύχει, το Service **σταματά** να στέλνει κίνηση εκεί (χωρίς restart) |

### Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  type: ClusterIP
  selector:
    app: myapp          # Πρέπει να ταιριάζει με τα labels του Deployment/Pod!
  ports:
    - port: 80
      targetPort: 3000
```

> ⚠️ Το πιο συχνό λάθος αρχαρίων: το `selector` του Service **δεν ταιριάζει** με τα `labels` των pods → το Service δεν βρίσκει κανένα pod (`kubectl get endpoints` δείχνει `<none>`) — βλ. `devops-debugging-troubleshooting.md` κεφάλαιο 8.

---

## 🔧 5. kubectl — Βασικές Εντολές

```bash
# Context/cluster
kubectl config get-contexts
kubectl config use-context <context-name>

# Εφαρμογή manifests
kubectl apply -f deployment.yaml
kubectl apply -f .                          # Όλα τα .yaml στον φάκελο

# Επισκόπηση resources
kubectl get pods
kubectl get deployments
kubectl get services
kubectl get all -n <namespace>

# Λεπτομέρειες
kubectl describe pod <pod-name>
kubectl describe deployment <deployment-name>

# Διαγραφή
kubectl delete -f deployment.yaml
kubectl delete pod <pod-name>               # Θα ξαναδημιουργηθεί από το Deployment!
kubectl delete deployment <deployment-name>  # Αυτό ΔΕΝ ξαναδημιουργείται

# Scaling
kubectl scale deployment myapp-deployment --replicas=5

# Editing "live" (προσοχή σε production)
kubectl edit deployment myapp-deployment
```

---

## 🔐 6. ConfigMaps & Secrets

Διαχωρίζουν **configuration** από το **image** — μπορείς να αλλάξεις ρυθμίσεις χωρίς να ξαναχτίσεις το image.

### ConfigMap (μη ευαίσθητα δεδομένα)
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
data:
  LOG_LEVEL: "info"
  API_TIMEOUT: "30"
  FEATURE_FLAG_NEW_UI: "true"
```

### Secret (ευαίσθητα δεδομένα — base64 encoded, ΟΧΙ κρυπτογραφημένο by default!)
```bash
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=SuperSecret123
```

### Χρήση μέσα σε Deployment
```yaml
spec:
  containers:
    - name: myapp
      image: myapp:1.0
      envFrom:
        - configMapRef:
            name: myapp-config
      env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
```

> ⚠️ Τα default Kubernetes Secrets είναι **base64 encoded, όχι encrypted** — για πραγματική ασφάλεια σε production, χρησιμοποίησε **External Secrets Operator** με HashiCorp Vault ή Azure Key Vault (βλ. `devops-git-cicd.md` κεφάλαιο 9).

---

## 🗂️ 7. Namespaces — Λογικός Διαχωρισμός

Χωρίζουν το cluster σε **λογικά, απομονωμένα** τμήματα — παρόμοια ιδέα με τα VLANs στο networking ή τα Resource Groups στο Azure.

```bash
kubectl create namespace staging
kubectl create namespace production

kubectl get pods -n production
kubectl apply -f deployment.yaml -n staging
```

### Τυπική χρήση namespaces
| Namespace | Σκοπός |
|---|---|
| `default` | Default, αν δεν οριστεί άλλο (καλό να μην το χρησιμοποιείς σε production) |
| `kube-system` | Εσωτερικά K8s components — μην πειράζεις |
| `staging` | Pre-production testing environment |
| `production` | Live περιβάλλον |
| `monitoring` | Prometheus, Grafana, κλπ. |

### Resource Quotas ανά namespace (αποτροπή "ένα namespace τρώει όλα τα resources")
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: staging-quota
  namespace: staging
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
```

---

## 📈 8. Scaling & Self-Healing

### Manual Scaling
```bash
kubectl scale deployment myapp-deployment --replicas=10
```

### Horizontal Pod Autoscaler (HPA) — αυτόματο scaling βάσει CPU/memory
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp-deployment
  minReplicas: 3
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```
```bash
kubectl apply -f hpa.yaml
kubectl get hpa                    # Παρακολούθηση σε πραγματικό χρόνο
```

### Self-Healing — τι γίνεται αυτόματα
```
1. Pod κρασάρει → kubelet το ανιχνεύει → restart (μέσω restartPolicy)
2. Ολόκληρο node πέφτει → Controller Manager το ανιχνεύει →
   δημιουργεί νέα pods σε ΑΛΛΑ, υγιή nodes
3. Pod αποτυγχάνει το readiness probe → Service σταματά να στέλνει κίνηση εκεί
   (χωρίς restart — απλά "περιμένει" να γίνει ready ξανά)
```

### Rolling Update — zero-downtime deployment
```bash
kubectl set image deployment/myapp-deployment myapp=myapp:1.5.0
kubectl rollout status deployment/myapp-deployment
kubectl rollout undo deployment/myapp-deployment    # Rollback αν κάτι πάει στραβά
```

```yaml
# Ρύθμιση στρατηγικής rolling update μέσα στο Deployment spec
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1          # Πόσα ΕΠΙΠΛΕΟΝ pods μπορούν να τρέξουν κατά τη μετάβαση
      maxUnavailable: 0    # Πόσα pods μπορούν να είναι μη-διαθέσιμα (0 = zero downtime)
```

---

## 🚪 9. Ingress — Είσοδος Κίνησης στο Cluster

Το **Ingress** διαχειρίζεται HTTP/HTTPS routing από έξω προς πολλαπλά Services — σαν "reverse proxy" για όλο το cluster, με βάση domain name/path.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
    - hosts:
        - app.contoso.com
      secretName: contoso-tls
  rules:
    - host: app.contoso.com
      http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: api-service
                port:
                  number: 80
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 80
```

### Χωρίς vs με Ingress
```
Χωρίς Ingress: Κάθε Service χρειάζεται δικό του LoadBalancer (ακριβό, πολλά public IPs)

Με Ingress: Ένα LoadBalancer/Ingress Controller δρομολογεί
            βάσει path/domain σε πολλαπλά εσωτερικά Services
```

---

## 💾 10. Persistent Storage

Όπως τα Docker Volumes, αλλά σε επίπεδο cluster — δεδομένα που επιβιώνουν πέρα από τον κύκλο ζωής ενός pod.

```yaml
# PersistentVolumeClaim — το "αίτημα" για storage
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: db-storage-claim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

```yaml
# Χρήση μέσα σε pod/deployment
spec:
  containers:
    - name: postgres
      image: postgres:16
      volumeMounts:
        - name: db-storage
          mountPath: /var/lib/postgresql/data
  volumes:
    - name: db-storage
      persistentVolumeClaim:
        claimName: db-storage-claim
```

### StatefulSet — για stateful εφαρμογές (databases, message queues)
Διαφορά από Deployment: κάθε pod παίρνει **σταθερό, μοναδικό όνομα** (πχ `db-0`, `db-1`, `db-2`) και **δικό του** persistent volume — κρίσιμο για databases που χρειάζονται σταθερή ταυτότητα.

---

## 📦 11. Helm — Package Manager για Kubernetes

Αντί να γράφεις δεκάδες YAML αρχεία χειροκίνητα για κάθε environment, το **Helm** τα "πακετάρει" σε **charts** με templating και parameters.

```bash
# Εγκατάσταση ενός chart (πχ nginx-ingress controller)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install my-ingress ingress-nginx/ingress-nginx

# Λίστα εγκατεστημένων releases
helm list

# Upgrade με νέες τιμές
helm upgrade myapp ./myapp-chart --set image.tag=1.5.0

# Rollback
helm rollback myapp 1
```

### Βασική δομή ενός Helm Chart
```
myapp-chart/
├── Chart.yaml           # Metadata (όνομα, version)
├── values.yaml          # Default παράμετροι
└── templates/
    ├── deployment.yaml  # Template με {{ .Values.xxx }} placeholders
    ├── service.yaml
    └── ingress.yaml
```

```yaml
# values.yaml
replicaCount: 3
image:
  repository: myapp
  tag: "1.4.2"
```

```yaml
# templates/deployment.yaml (απόσπασμα)
spec:
  replicas: {{ .Values.replicaCount }}
  template:
    spec:
      containers:
        - image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```

> Με ένα `values-staging.yaml` και ένα `values-production.yaml`, το **ίδιο** chart μπορεί να deploy-άρει σε διαφορετικά environments με διαφορετικές τιμές (replicas, resource limits, κλπ.).

---

## 🎯 12. Πλήρες Παράδειγμα — Deployment 3-Tier Εφαρμογής σε K8s

Συνέχεια του παραδείγματος από το `devops-docker-containers.md` — τα ίδια images, τώρα σε Kubernetes:

```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: myapp-production

---
# api-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: myapp-production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
        - name: api
          image: myregistry.azurecr.io/myapi:1.4.2
          ports:
            - containerPort: 3000
          envFrom:
            - configMapRef:
                name: api-config
          env:
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: password
          resources:
            requests: { cpu: "250m", memory: "256Mi" }
            limits: { cpu: "500m", memory: "512Mi" }
          readinessProbe:
            httpGet: { path: /health, port: 3000 }

---
# api-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: api-service
  namespace: myapp-production
spec:
  selector:
    app: api
  ports:
    - port: 80
      targetPort: 3000

---
# api-hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
  namespace: myapp-production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  minReplicas: 3
  maxReplicas: 15
  metrics:
    - type: Resource
      resource:
        name: cpu
        target: { type: Utilization, averageUtilization: 70 }

---
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  namespace: myapp-production
spec:
  rules:
    - host: app.contoso.com
      http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service: { name: api-service, port: { number: 80 } }
          - path: /
            pathType: Prefix
            backend:
              service: { name: frontend-service, port: { number: 80 } }
```

### Εφαρμογή όλων μαζί
```bash
kubectl apply -f namespace.yaml
kubectl apply -f . -n myapp-production
kubectl get all -n myapp-production
kubectl rollout status deployment/api -n myapp-production
```

### Επόμενα βήματα (βλ. επόμενα αρχεία της σειράς)
```
→ devops-terraform-iac.md: Δημιουργία του ΙΔΙΟΥ του Kubernetes cluster (AKS/EKS) μέσω κώδικα
→ devops-ansible.md: Configuration management για ό,τι δεν καλύπτει το K8s
→ devops-monitoring-observability.md: Prometheus/Grafana για monitoring όλου του cluster
```

---

*Μέρος του [Infrastructure Knowledge Base](https://github.com/Dimitriskatsanos42/Infrastructure-Knowledge-Base) — φάκελος DevOps, συμπληρωματικό στα `devops-fundamentals-roadmap.md`, `devops-git-cicd.md`, `devops-debugging-troubleshooting.md` και `devops-docker-containers.md`.*
