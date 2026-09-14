# 🐞 DevOps Debugging & Troubleshooting

Τρίτο αρχείο του φακέλου **DevOps**, συμπληρωματικό στα `devops-fundamentals-roadmap.md` και `devops-git-cicd.md`. Το debugging σε DevOps περιβάλλον είναι **διαφορετικό** από το παραδοσιακό "βάζω breakpoint και τρέχω" — η πολυπλοκότητα των containers, microservices και pipelines απαιτεί συστηματική προσέγγιση. Αυτό το αρχείο καλύπτει ακριβώς αυτή τη μεθοδολογία.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Η Debugging Νοοτροπία σε DevOps Περιβάλλον](#-1-η-debugging-νοοτροπία-σε-devops-περιβάλλον)
2. [Docker/Container Debugging](#-2-dockercontainer-debugging)
3. [Kubernetes Debugging](#-3-kubernetes-debugging)
4. [CI/CD Pipeline Debugging](#-4-cicd-pipeline-debugging)
5. [Application-Level Debugging](#-5-application-level-debugging)
6. [Distributed Systems — Logging, Tracing & Correlation](#-6-distributed-systems--logging-tracing--correlation)
7. [Performance Debugging & Profiling](#-7-performance-debugging--profiling)
8. [Network Debugging σε Containerized Περιβάλλον](#-8-network-debugging-σε-containerized-περιβάλλον)
9. [Common Production Issues — Playbook](#-9-common-production-issues--playbook)
10. [Εργαλεία — Συνολικός Χάρτης](#-10-εργαλεία--συνολικός-χάρτης)
11. [Πλήρες Παράδειγμα — Από Alert σε Root Cause](#-11-πλήρες-παράδειγμα--από-alert-σε-root-cause)

---

## 🧠 1. Η Debugging Νοοτροπία σε DevOps Περιβάλλον

### Γιατί είναι διαφορετικό από παραδοσιακό debugging
Σε ένα monolithic, single-server περιβάλλον, το πρόβλημα είναι συνήθως "σε ένα μέρος". Σε DevOps/microservices περιβάλλον, ένα request μπορεί να περάσει από **10+ services**, containers που δημιουργούνται/καταστρέφονται δυναμικά, και υποδομή που αλλάζει κάθε μέρα (IaC deployments). Το "ξαναπαράγω το bug τοπικά" συχνά **δεν είναι εφικτό**.

### Η δομημένη προσέγγιση (bottom-up, layer by layer)
```
1. Είναι πρόβλημα εφαρμογής ή υποδομής;
   → Ελέγχεις logs εφαρμογής ΠΡΩΤΑ, μετά infrastructure metrics

2. Πότε ξεκίνησε; Τι άλλαξε γύρω από εκείνη τη στιγμή;
   → Deployment; Config change; Traffic spike; Εξωτερική εξάρτηση (DB, API);

3. Είναι isolated (ένα instance/pod) ή widespread (όλα);
   → Isolated: πιθανό hardware/node πρόβλημα
   → Widespread: πιθανό code/config/dependency πρόβλημα

4. Reproducible ή intermittent;
   → Reproducible: ευκολότερο, μπορείς να δοκιμάσεις fix τοπικά
   → Intermittent: χρειάζεται περισσότερο monitoring/tracing πριν καταλάβεις pattern
```

### Ο κανόνας "Correlate, don't guess"
Πριν κάνεις οποιαδήποτε αλλαγή, **βρες τη συσχέτιση** (correlation) μεταξύ του συμπτώματος και ενός γεγονότος (deployment, config change, external event). Αλλαγές "στα τυφλά" σε production χωρίς αυτή τη συσχέτιση συχνά προσθέτουν ένα δεύτερο πρόβλημα πάνω στο πρώτο.

---

## 🐳 2. Docker/Container Debugging

### Βασικές εντολές διερεύνησης
```bash
docker ps -a                          # Όλα τα containers (ακόμα και stopped)
docker logs <container-id>            # Logs του container
docker logs -f --tail 100 <container-id>   # Live tail, τελευταίες 100 γραμμές
docker inspect <container-id>         # Πλήρης JSON με config, network, mounts
docker stats                          # Real-time CPU/memory/network χρήση
```

### Είσοδος σε running container για live διερεύνηση
```bash
docker exec -it <container-id> bash        # Αν έχει bash
docker exec -it <container-id> sh          # Αν είναι Alpine-based (δεν έχει bash)

# Μέσα στο container:
ps aux                    # Ποιες διεργασίες τρέχουν
env                       # Environment variables — σωστά περασμένα;
cat /etc/resolv.conf      # DNS ρυθμίσεις
netstat -tulnp            # Ports που ακούει η εφαρμογή
```

### Container που κρασάρει αμέσως (δεν προλαβαίνεις exec)
```bash
# Δες γιατί τερμάτισε
docker logs <container-id>

# Τρέξε το ίδιο image αλλά με entrypoint override, για interactive διερεύνηση
docker run -it --entrypoint sh <image-name>

# Δες exit code (χρήσιμο για να ξέρεις τι είδους αποτυχία ήταν)
docker inspect <container-id> --format='{{.State.ExitCode}}'
```

### Συνηθισμένοι exit codes
| Exit Code | Σημασία |
|:---:|---|
| 0 | Επιτυχής τερματισμός |
| 1 | Γενικό σφάλμα εφαρμογής |
| 137 | **OOMKilled** — Out of Memory, το container σκοτώθηκε από το kernel |
| 139 | Segmentation fault |
| 143 | SIGTERM — κανονικός τερματισμός (πχ από `docker stop`) |

### Debugging image build issues
```bash
docker build --progress=plain --no-cache -t myapp .   # Πλήρες output κάθε layer, χωρίς cache

# Δημιουργία container από ενδιάμεσο layer για διερεύνηση
docker build -t myapp:debug --target <stage-name> .    # Αν multi-stage Dockerfile
docker run -it myapp:debug sh
```

---

## ☸️ 3. Kubernetes Debugging

### Πρώτο βήμα πάντα — τι κατάσταση έχει το pod
```bash
kubectl get pods -n <namespace>
kubectl get pods -n <namespace> -o wide     # Επιπλέον: σε ποιο node, IP
```

### Κατάσταση pod — τι σημαίνει η κάθε μία

| Status | Σημασία | Πρώτη ενέργεια |
|---|---|---|
| `Pending` | Δεν έχει προγραμματιστεί ακόμα σε node | `kubectl describe pod` — δες Events |
| `ImagePullBackOff` | Δεν μπόρεσε να κατεβάσει το image | Έλεγξε image name/tag, registry credentials |
| `CrashLoopBackOff` | Το container ξεκινάει και κρασάρει επανειλημμένα | `kubectl logs --previous` |
| `OOMKilled` | Σκοτώθηκε λόγω μνήμης | Αύξησε memory limits ή βρες memory leak |
| `Running` αλλά `0/1 Ready` | Τρέχει αλλά αποτυγχάνει το readiness probe | Έλεγξε το health check endpoint |

### Βαθύτερη διερεύνηση
```bash
kubectl describe pod <pod-name> -n <namespace>
# Δες: Events (στο τέλος του output) — εκεί φαίνονται τα πραγματικά προβλήματα

kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous     # Logs από το ΠΡΟΗΓΟΥΜΕΝΟ (κρασαρισμένο) container
kubectl logs <pod-name> -c <container-name> -n <namespace>   # Αν multi-container pod

kubectl exec -it <pod-name> -n <namespace> -- sh
```

### Debug container χωρίς να τροποποιήσεις το pod (ephemeral containers, K8s 1.23+)
```bash
kubectl debug -it <pod-name> --image=busybox --target=<container-name>
```

### Έλεγχος resources/limits
```bash
kubectl top pod <pod-name> -n <namespace>       # Τρέχουσα χρήση CPU/memory
kubectl describe pod <pod-name> | grep -A 5 Limits
```

### Networking troubleshooting μέσα σε K8s
```bash
kubectl get svc -n <namespace>                        # Services
kubectl get endpoints <service-name> -n <namespace>    # Ποια pods "βλέπει" το service

# Test connectivity από μέσα στο cluster
kubectl run debug-pod --image=busybox -it --rm -- sh
# Μέσα:
wget -O- http://<service-name>.<namespace>.svc.cluster.local
nslookup <service-name>.<namespace>.svc.cluster.local
```

### Deployment δεν κάνει rollout σωστά
```bash
kubectl rollout status deployment/<deployment-name> -n <namespace>
kubectl rollout history deployment/<deployment-name> -n <namespace>
kubectl rollout undo deployment/<deployment-name> -n <namespace>   # Rollback στην προηγούμενη έκδοση
```

---

## ⚙️ 4. CI/CD Pipeline Debugging

### Πρώτα ερωτήματα όταν ένα pipeline αποτυγχάνει
```
1. Σε ποιο ΣΥΓΚΕΚΡΙΜΕΝΟ stage/step απέτυχε; (όχι "το pipeline απέτυχε")
2. Είναι flaky (τυχαία αποτυγχάνει) ή deterministic (πάντα εδώ);
3. Δούλευε στο προηγούμενο commit; Τι άλλαξε;
4. Είναι πρόβλημα κώδικα, ή πρόβλημα του ΙΔΙΟΥ του pipeline/environment;
```

### GitHub Actions — debugging τεχνικές
```yaml
# Ενεργοποίηση verbose logging
# Settings → Secrets → προσθήκη: ACTIONS_STEP_DEBUG = true

# Τοπική εκτέλεση pipeline πριν το push (με το εργαλείο 'act')
# act -j build-and-test
```

```bash
# Εργαλείο act — τρέχει GitHub Actions τοπικά σε Docker
act -j build-and-test --verbose
```

### Jenkins — debugging τεχνικές
```groovy
// Προσθήκη debug output μέσα σε pipeline stage
stage('Debug Info') {
    steps {
        sh 'env | sort'                    // Δες όλα τα environment variables
        sh 'printenv'
        sh 'whoami && pwd && ls -la'
    }
}
```
```bash
# Console Output στο Jenkins UI — πάντα πρώτο σημείο ελέγχου
# Replay: μπορείς να "παίξεις ξανά" ένα pipeline με τροποποιημένο Jenkinsfile, χωρίς νέο commit
```

### Συνηθισμένα προβλήματα pipeline
| Σύμπτωμα | Πιθανή αιτία |
|---|---|
| "Δουλεύει τοπικά, όχι στο pipeline" | Διαφορετικό environment (versions, env vars, file paths) |
| Flaky test failures | Race conditions, εξάρτηση σε timing, shared test state |
| "Permission denied" σε CI | Ο CI runner δεν έχει τα ίδια δικαιώματα με το τοπικό μηχάνημα |
| Timeout σε build | Network issue προς dependency registry, ή πραγματικά αργό build |
| Secret δεν φαίνεται σωστό | Λάθος όνομα secret, ή δεν έχει granted access στο συγκεκριμένο environment |

---

## 🔍 5. Application-Level Debugging

### Structured Logging — γιατί έχει σημασία
```
❌ Κακό logging:
"Error occurred"

✅ Καλό (structured) logging:
{
  "timestamp": "2026-09-11T10:15:23Z",
  "level": "ERROR",
  "service": "payment-api",
  "trace_id": "abc-123-def",
  "message": "Payment gateway timeout",
  "user_id": "usr_4521",
  "gateway_response_time_ms": 5023
}
```
> Το structured logging (JSON) επιτρέπει **αναζήτηση/φιλτράρισμα** σε εργαλεία όπως ELK/Loki, κάτι αδύνατο με απλό free-text logging.

### Log Levels — πότε χρησιμοποιείται το καθένα
| Level | Πότε |
|---|---|
| `DEBUG` | Λεπτομέρειες μόνο για development/troubleshooting — ΟΧΙ ενεργό by default σε production |
| `INFO` | Φυσιολογικά γεγονότα (πχ "User logged in") |
| `WARN` | Κάτι ασυνήθιστο αλλά όχι σφάλμα (πχ "Retry attempt 2/3") |
| `ERROR` | Κάτι απέτυχε, χρειάζεται προσοχή |
| `FATAL/CRITICAL` | Η εφαρμογή δεν μπορεί να συνεχίσει |

### Remote Debugging (attach debugger σε running process)
```bash
# Node.js — ενεργοποίηση debug port
node --inspect=0.0.0.0:9229 app.js
# Μετά: σύνδεση από VS Code / Chrome DevTools στο <host>:9229

# Python — remote debugging με debugpy
python -m debugpy --listen 0.0.0.0:5678 --wait-for-client app.py
```
> ⚠️ Remote debugging σε **production** είναι ρίσκο (παύει το process σε breakpoint = downtime). Χρησιμοποιείται κυρίως σε staging.

### Core Dumps (όταν μια εφαρμογή κρασάρει βίαια)
```bash
# Linux — ενεργοποίηση core dumps
ulimit -c unlimited

# Ανάλυση core dump με gdb
gdb <executable> <core-file>
(gdb) bt          # backtrace — δείχνει το stack trace τη στιγμή του crash
```

---

## 🔗 6. Distributed Systems — Logging, Tracing & Correlation

### Το πρόβλημα σε microservices
```
Request → API Gateway → Auth Service → Order Service → Payment Service → Database
```
Αν το request αποτύχει, **σε ποιο service;** Χωρίς correlation, ψάχνεις logs σε 5 διαφορετικά μέρη χωρίς να ξέρεις ποια γραμμή ανήκει στο ίδιο request.

### Correlation ID / Trace ID — η λύση
```
1. Το API Gateway δημιουργεί ένα μοναδικό trace_id: "abc-123"
2. Το περνάει σε κάθε downstream call (HTTP header: X-Trace-ID: abc-123)
3. Κάθε service το συμπεριλαμβάνει σε ΚΑΘΕ log entry του
4. Τώρα μπορείς: grep "abc-123" σε όλα τα logs → βλέπεις ΟΛΟ το ταξίδι του request
```

### Distributed Tracing (οπτικοποίηση, πχ Jaeger)
```
Trace: abc-123
├── API Gateway        [12ms]
├── Auth Service        [8ms]
├── Order Service       [45ms]
│   └── Database Query  [38ms]  ← Εδώ είναι η καθυστέρηση!
└── Payment Service     [120ms]
    └── External API    [110ms]  ← Και εδώ
```
> Το distributed tracing δείχνει **οπτικά** πού πάει ο χρόνος ενός request — ανεκτίμητο για performance debugging σε microservices.

### Log Aggregation query παράδειγμα (Loki/LogQL)
```logql
{service="payment-api"} |= "ERROR" | json | trace_id="abc-123"
```

---

## ⚡ 7. Performance Debugging & Profiling

### Πρώτο βήμα: εντόπισε ΠΟΥ είναι το bottleneck
```
CPU-bound;  Memory-bound;  I/O-bound (disk/network);  ή Lock contention;
```

### Profiling εργαλεία ανά γλώσσα
| Γλώσσα | Εργαλείο |
|---|---|
| Node.js | `node --prof`, Chrome DevTools Profiler, clinic.js |
| Python | `cProfile`, `py-spy` (μπορεί να κάνει attach σε running process χωρίς restart) |
| Java | `jstack` (thread dump), `jmap` (heap dump), VisualVM |
| Go | `pprof` (ενσωματωμένο) |

### Παράδειγμα: py-spy σε running production process
```bash
py-spy top --pid 12345          # Live view ποιες functions καταναλώνουν CPU
py-spy dump --pid 12345         # Snapshot όλων των threads τη δεδομένη στιγμή
```

### Memory Leak εντοπισμός (concept)
```
1. Παρατήρησε trend: η μνήμη ανεβαίνει σταθερά με την ώρα, δεν κατεβαίνει ποτέ
   → kubectl top pod --watch, ή Grafana graph με memory usage over time

2. Πάρε heap snapshot σε 2 διαφορετικές χρονικές στιγμές
   → Σύγκρινε: ποια objects αυξάνονται συνεχώς χωρίς να "καθαρίζονται"

3. Συχνή αιτία: event listeners που δεν αφαιρούνται, caches χωρίς eviction policy,
   ανοιχτές database connections που δεν κλείνουν
```

---

## 🌐 8. Network Debugging σε Containerized Περιβάλλον

### "Το container δεν μπορεί να συνδεθεί με άλλο container/service"
```bash
# 1. Είναι στο ίδιο Docker network;
docker network inspect <network-name>

# 2. DNS resolution δουλεύει;
docker exec -it <container> nslookup <other-service-name>

# 3. Το port είναι πραγματικά ανοιχτό μέσα στο container;
docker exec -it <container> netstat -tulnp

# 4. Test raw connectivity
docker exec -it <container> curl -v http://other-service:8080/health
docker exec -it <container> nc -zv other-service 8080
```

### Kubernetes networking — πιο σύνθετο
```bash
# Είναι το Service σωστά ρυθμισμένο να δείχνει στα σωστά pods;
kubectl get endpoints <service-name>
# Αν άδειο (<none>) → το selector του Service δεν ταιριάζει με τα labels των pods!

kubectl describe svc <service-name>     # Δες τα Selector labels
kubectl get pods --show-labels          # Σύγκρινε με τα labels των pods

# NetworkPolicy μπλοκάρει;
kubectl get networkpolicy -n <namespace>
```

---

## 📋 9. Common Production Issues — Playbook

| Σύμπτωμα | Πρώτος έλεγχος | Πιθανή αιτία |
|---|---|---|
| 502/503 errors | Load balancer/ingress logs, pod readiness | Backend pods down ή overloaded |
| CrashLoopBackOff | `kubectl logs --previous` | Config error, missing env var, dependency down |
| Αργό API response | Distributed tracing, DB slow query log | N+1 query, missing index, external API timeout |
| OOMKilled | Memory limits vs actual usage | Memory leak, ή limits πολύ χαμηλά ρυθμισμένα |
| "Works on my machine" | Diff environment variables/versions | Environment drift, missing config σε CI/staging |
| Deployment "κολλάει" | `kubectl rollout status` | Health check αποτυγχάνει, resource quota γεμάτο |
| Intermittent 5xx | Correlation με deployment timeline | Rolling update σε εξέλιξη, ή flaky dependency |

---

## 🧰 10. Εργαλεία — Συνολικός Χάρτης

| Κατηγορία | Εργαλεία |
|---|---|
| Container inspection | `docker logs/exec/inspect`, `kubectl logs/describe/exec` |
| Log aggregation | ELK Stack, Grafana Loki, Splunk |
| Distributed Tracing | Jaeger, Zipkin, OpenTelemetry |
| Metrics/Monitoring | Prometheus + Grafana, Datadog |
| APM (Application Performance Monitoring) | New Relic, Datadog APM, Elastic APM |
| Profiling | py-spy, pprof, VisualVM, Chrome DevTools |
| Network debugging | `tcpdump`, `curl -v`, `nc`, Wireshark (βλ. `networking-qos-monitoring.md`) |
| Local pipeline testing | `act` (GitHub Actions τοπικά) |
| Chaos Engineering (proactive) | Chaos Monkey, Litmus — δοκιμή αντοχής **πριν** συμβεί το πρόβλημα |

---

## 🔗 11. Πλήρες Παράδειγμα — Από Alert σε Root Cause

```
1. Alert (Prometheus/Grafana): "Payment API — error rate 15%, latency p99 > 3s"

2. Πρώτος έλεγχος — τι άλλαξε πρόσφατα;
   → kubectl rollout history deployment/payment-api
   → Νέο deployment έγινε πριν 20 λεπτά

3. Έλεγχος pod status
   → kubectl get pods -n production | grep payment-api
   → 2/5 pods σε CrashLoopBackOff

4. Logs από το κρασαρισμένο pod
   → kubectl logs <pod-name> --previous
   → "FATAL: Cannot connect to database — connection refused"

5. Correlation: το νέο deployment άλλαξε το DB connection string
   → Έλεγχος του Config Map / Secret που άλλαξε στο τελευταίο commit
   → Εντοπισμός: λάθος DB hostname στο νέο config

6. Immediate mitigation (rollback):
   → kubectl rollout undo deployment/payment-api
   → Επιβεβαίωση: error rate πέφτει, pods γίνονται Running/Ready

7. Root cause στο config, ΟΧΙ στον κώδικα
   → Δημιουργία Problem Record (βλ. ITSM υλικό) για root cause analysis:
     γιατί δεν πιάστηκε αυτό σε staging;
   → Εύρημα: το staging περιβάλλον δεν είχε validation του DB connection
     string πριν το deployment

8. Fix της διαδικασίας (CSI entry):
   → Προσθήκη automated health check στο pipeline ΠΡΙΝ το production deploy
   → Προσθήκη pre-deployment smoke test που επιβεβαιώνει DB connectivity
```

Αυτό το παράδειγμα δείχνει την πλήρη ροή: **Alert → Correlation με deployment → Pod investigation → Logs → Root cause → Rollback → Process fix** — η ουσία του συστηματικού DevOps debugging.

---

*Μέρος του [Infrastructure Knowledge Base](https://github.com/Dimitriskatsanos42/Infrastructure-Knowledge-Base) — φάκελος DevOps, συμπληρωματικό στα `devops-fundamentals-roadmap.md` και `devops-git-cicd.md`.*
