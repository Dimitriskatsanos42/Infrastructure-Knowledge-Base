# 📡 Monitoring & Observability — Prometheus, Grafana & Logging

Όγδοο αρχείο του φακέλου **DevOps**, το τελευταίο του βασικού roadmap. Όλα τα προηγούμενα αρχεία (Docker, Kubernetes, Terraform, Ansible) δημιουργούν και τρέχουν υποδομή — αυτό το αρχείο δείχνει **πώς ξέρεις αν όλα αυτά δουλεύουν σωστά**, σε πραγματικό χρόνο. Συνδέεται άμεσα με το **Event Management** από το ITSM υλικό σου (`itsm-event-availability-policies.md`) — εδώ είναι η τεχνική, cloud-native υλοποίηση της ίδιας ιδέας.

---

## 🗺️ Πίνακας Περιεχομένων

1. [Οι 3 Πυλώνες του Observability](#-1-οι-3-πυλώνες-του-observability)
2. [Prometheus — Αρχιτεκτονική & Βασικά](#-2-prometheus--αρχιτεκτονική--βασικά)
3. [PromQL — Γλώσσα Ερωτημάτων](#-3-promql--γλώσσα-ερωτημάτων)
4. [Exporters — Πώς Συλλέγονται Metrics](#-4-exporters--πώς-συλλέγονται-metrics)
5. [Alertmanager — Ειδοποιήσεις](#-5-alertmanager--ειδοποιήσεις)
6. [Grafana — Οπτικοποίηση](#-6-grafana--οπτικοποίηση)
7. [Logging — ELK Stack & Loki](#-7-logging--elk-stack--loki)
8. [Distributed Tracing — Πρακτική Υλοποίηση](#-8-distributed-tracing--πρακτική-υλοποίηση)
9. [Kubernetes Monitoring — Πρακτικά](#-9-kubernetes-monitoring--πρακτικά)
10. [SLI, SLO, SLA — Η Σχέση τους](#-10-sli-slo-sla--η-σχέση-τους)
11. [Best Practices](#-11-best-practices)
12. [Πλήρες Παράδειγμα — Πλήρες Monitoring Stack](#-12-πλήρες-παράδειγμα--πλήρες-monitoring-stack)

---

## 🔺 1. Οι 3 Πυλώνες του Observability

Ήδη αναφέρθηκε συνοπτικά στο `devops-fundamentals-roadmap.md` — εδώ σε βάθος.

| Πυλώνας | Απαντά | Εργαλεία |
|---|---|---|
| **Metrics** | "Πόσο; Πόσο συχνά;" — αριθμητικά δεδομένα στον χρόνο | Prometheus, Grafana |
| **Logs** | "Τι ΑΚΡΙΒΩΣ συνέβη;" — λεπτομερή, discrete events | ELK Stack, Loki |
| **Traces** | "Πού πήγε το request μέσα από πολλαπλά services;" | Jaeger, Zipkin, OpenTelemetry |

### Monitoring vs Observability — η διαφορά
```
Monitoring:     "Ξέρω ΑΝ κάτι είναι χαλασμένο" (γνωστά, προκαθορισμένα dashboards/alerts)
Observability:  "Μπορώ να καταλάβω ΓΙΑΤΙ είναι χαλασμένο, ακόμα και για προβλήματα
                 που δεν είχα προβλέψει" (εξερεύνηση δεδομένων ad-hoc)
```
> Το monitoring απαντά ερωτήσεις που **ήξερες** να κάνεις εκ των προτέρων (πχ "είναι το CPU πάνω από 80%;"). Το observability σου επιτρέπει να κάνεις **νέες** ερωτήσεις όταν συμβαίνει κάτι απρόβλεπτο.

---

## 📊 2. Prometheus — Αρχιτεκτονική & Βασικά

### Αρχιτεκτονική
```
┌─────────────┐     scrape (pull)     ┌──────────────┐
│  Prometheus │ ──────────────────>  │   Target 1    │
│    Server    │ ──────────────────>  │  (app :9090)  │
│              │ ──────────────────>  │   Target 2    │
└──────┬───────┘                       └──────────────┘
       │
       ├──> Time Series Database (τοπική αποθήκευση)
       │
       ├──> Alertmanager (ειδοποιήσεις)
       │
       └──> Grafana (οπτικοποίηση, queries)
```

### Pull vs Push μοντέλο
```
Prometheus (Pull):
[Prometheus Server] --"Δώσε μου τα metrics σου"--> [Application]
(Ο Prometheus ρωτάει περιοδικά — "scrape interval", πχ κάθε 15 δευτερόλεπτα)

Εναλλακτικά (Push, πχ StatsD):
[Application] --"Ορίστε τα metrics μου"--> [Collector]
(Η εφαρμογή στέλνει μόνη της, χωρίς να περιμένει ερώτηση)
```
> Το **pull** μοντέλο του Prometheus έχει πλεονέκτημα: ο Prometheus server ξέρει αμέσως αν ένα target είναι **down** (αποτυγχάνει το scrape) — δεν χρειάζεται ξεχωριστό health check.

### Βασική ρύθμιση (prometheus.yml)
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'myapp'
    static_configs:
      - targets: ['app-server:3000']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['server1:9100', 'server2:9100']

rule_files:
  - 'alert-rules.yml'

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']
```

### Τύποι Metrics

| Τύπος | Περιγραφή | Παράδειγμα |
|---|---|---|
| **Counter** | Μόνο αυξάνεται (ή μηδενίζεται σε restart) | `http_requests_total` |
| **Gauge** | Ανεβαίνει/κατεβαίνει ελεύθερα | `memory_usage_bytes` |
| **Histogram** | Κατανομή τιμών σε "κάδους" (buckets) | `http_request_duration_seconds` |
| **Summary** | Παρόμοιο με histogram, με percentiles υπολογισμένα client-side | `request_latency_summary` |

---

## 🔍 3. PromQL — Γλώσσα Ερωτημάτων

```promql
# Τρέχουσα τιμή ενός metric
node_memory_MemAvailable_bytes

# Ρυθμός αύξησης ενός counter τα τελευταία 5 λεπτά (πολύ συχνό pattern)
rate(http_requests_total[5m])

# Φιλτράρισμα με labels
http_requests_total{status="500", service="payment-api"}

# Άθροιση ανά service
sum(rate(http_requests_total[5m])) by (service)

# Ποσοστό σφαλμάτων (error rate)
sum(rate(http_requests_total{status=~"5.."}[5m]))
/
sum(rate(http_requests_total[5m]))

# 95ο percentile latency (πολύ συχνό σε SLO tracking)
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Alert-style query: CPU > 80% για τα τελευταία 5 λεπτά
avg(rate(node_cpu_seconds_total{mode!="idle"}[5m])) by (instance) > 0.8
```

### Βασικοί τελεστές/functions
| Function | Χρήση |
|---|---|
| `rate()` | Ρυθμός αύξησης counter ανά δευτερόλεπτο |
| `sum() by ()` | Άθροιση ομαδοποιημένο ανά label |
| `avg()` | Μέσος όρος |
| `histogram_quantile()` | Υπολογισμός percentile από histogram |
| `increase()` | Συνολική αύξηση σε δεδομένο διάστημα |

---

## 📢 4. Exporters — Πώς Συλλέγονται Metrics

Ο Prometheus δεν "ξέρει" από μόνος του metrics για CPU, δίσκο κλπ. — χρειάζεται **exporters**, μικρά προγράμματα που εκθέτουν metrics σε format που ο Prometheus καταλαβαίνει.

| Exporter | Τι εκθέτει |
|---|---|
| **Node Exporter** | Hardware/OS metrics (CPU, memory, disk, network) — Linux servers |
| **Windows Exporter** | Ισοδύναμο για Windows servers |
| **cAdvisor** | Container-level metrics (resource usage ανά container) |
| **Blackbox Exporter** | Εξωτερικά probes (HTTP/TCP/ICMP — "είναι το site up;") |
| **MySQL/Postgres Exporter** | Database-specific metrics |
| **Custom application metrics** | Η ίδια η εφαρμογή σου εκθέτει metrics μέσω client library |

### Εγκατάσταση Node Exporter (Linux)
```bash
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar xvf node_exporter-1.7.0.linux-amd64.tar.gz
./node_exporter-1.7.0.linux-amd64/node_exporter &
# Τα metrics τώρα διαθέσιμα στο http://server:9100/metrics
```

### Custom application metrics (Node.js παράδειγμα)
```javascript
const client = require('prom-client');

const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Συνολικός αριθμός HTTP requests',
  labelNames: ['method', 'status']
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

// Σε κάθε request:
httpRequestsTotal.inc({ method: req.method, status: res.statusCode });
```

---

## 🚨 5. Alertmanager — Ειδοποιήσεις

Ο Prometheus **αξιολογεί** alert rules· το **Alertmanager** αναλαμβάνει **τι κάνεις** με αυτά (routing, grouping, notification channels).

### Alert Rule (στον Prometheus)
```yaml
# alert-rules.yml
groups:
  - name: myapp-alerts
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m]))
          / sum(rate(http_requests_total[5m])) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Error rate πάνω από 5% στο {{ $labels.service }}"
          description: "Τρέχον error rate: {{ $value | humanizePercentage }}"

      - alert: HighMemoryUsage
        expr: node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 0.1
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Λιγότερο από 10% διαθέσιμη μνήμη στο {{ $labels.instance }}"
```

### Alertmanager Routing
```yaml
# alertmanager.yml
route:
  receiver: 'default-team'
  group_by: ['alertname', 'service']
  group_wait: 30s
  repeat_interval: 4h
  routes:
    - match:
        severity: critical
      receiver: 'pagerduty-oncall'
    - match:
        severity: warning
      receiver: 'slack-devops'

receivers:
  - name: 'default-team'
    slack_configs:
      - channel: '#alerts'

  - name: 'pagerduty-oncall'
    pagerduty_configs:
      - service_key: '<pagerduty-key>'

  - name: 'slack-devops'
    slack_configs:
      - channel: '#devops-warnings'
```

> Αυτό συνδέεται άμεσα με το **Escalation Matrix** και **Major Incident Management** από το ITSM υλικό σου (`itsm-major-incidents-cab-csi.md`) — critical alerts πηγαίνουν σε on-call (PagerDuty), λιγότερο επείγοντα σε Slack.

---

## 📈 6. Grafana — Οπτικοποίηση

Το Grafana δεν συλλέγει δεδομένα μόνο του — συνδέεται σε **data sources** (Prometheus, Loki, databases) και τα οπτικοποιεί.

### Βασική ροή
```
1. Πρόσθεσε Data Source (Prometheus URL)
2. Δημιούργησε Dashboard
3. Πρόσθεσε Panels (γραφήματα) με PromQL queries
4. Ρύθμισε Alerts πάνω στα panels (εναλλακτικά ή επιπλέον του Alertmanager)
```

### Dashboard as Code (JSON model — version controlled)
```json
{
  "panels": [
    {
      "title": "Request Rate",
      "type": "graph",
      "targets": [
        {
          "expr": "sum(rate(http_requests_total[5m])) by (service)"
        }
      ]
    },
    {
      "title": "Error Rate %",
      "type": "gauge",
      "targets": [
        {
          "expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m])) * 100"
        }
      ]
    }
  ]
}
```

### Προτεινόμενα dashboards ανά χρήστη
| Ρόλος | Τι θέλει να βλέπει |
|---|---|
| On-call engineer | Real-time error rates, latency, active alerts |
| Team lead | Deployment frequency, MTTR trends (βλ. ITSM metrics) |
| Capacity planning | CPU/memory/disk trends over weeks/months |
| Executive | High-level uptime %, business metrics |

---

## 📜 7. Logging — ELK Stack & Loki

### ELK Stack (Elasticsearch, Logstash, Kibana)
```
[App logs] → [Logstash/Filebeat] → [Elasticsearch] → [Kibana (UI)]
              (συλλογή/parsing)      (αποθήκευση/index)   (αναζήτηση/dashboards)
```

### Filebeat config (ελαφρύ agent, στέλνει logs)
```yaml
# filebeat.yml
filebeat.inputs:
  - type: log
    paths:
      - /var/log/myapp/*.log
    json.keys_under_root: true

output.elasticsearch:
  hosts: ["elasticsearch:9200"]
```

### Grafana Loki — ελαφρύτερη εναλλακτική (ίδιο μοντέλο με Prometheus, αλλά για logs)
```
Loki: Δεν κάνει index στο ΠΛΗΡΕΣ περιεχόμενο του log (όπως το Elasticsearch),
      μόνο στα labels (πχ service, environment) — πολύ πιο "φτηνό" σε resources.
```

```yaml
# promtail-config.yml (ο "agent" του Loki, αντίστοιχο του Filebeat)
scrape_configs:
  - job_name: myapp
    static_configs:
      - targets: [localhost]
        labels:
          job: myapp
          __path__: /var/log/myapp/*.log
```

### LogQL query (Loki — παρόμοιο με PromQL)
```logql
{job="myapp"} |= "ERROR" | json | duration > 1000
```

### Πότε ELK vs Loki
| | ELK Stack | Grafana Loki |
|---|---|---|
| Πλήρες full-text search | ✅ Πολύ ισχυρό | ⚠️ Περιορισμένο |
| Resource requirements | Υψηλά | Χαμηλά |
| Integration με Prometheus/Grafana | Ξεχωριστό εργαλείο | Native, ίδιο ecosystem |
| Καλύτερο για | Μεγάλες, σύνθετες αναζητήσεις logs | Cost-effective logging σε K8s περιβάλλοντα |

---

## 🔗 8. Distributed Tracing — Πρακτική Υλοποίηση

Ήδη καλύφθηκε η θεωρία στο `devops-debugging-troubleshooting.md` — εδώ η πρακτική υλοποίηση με **OpenTelemetry** (το σύγχρονο standard).

```javascript
// Node.js — βασική ρύθμιση OpenTelemetry
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    url: 'http://jaeger-collector:4318/v1/traces',
  }),
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();
```

> Με auto-instrumentation, το OpenTelemetry **αυτόματα** παρακολουθεί HTTP calls, database queries, κλπ. — δεν χρειάζεται να προσθέσεις tracing κώδικα χειροκίνητα σε κάθε function.

---

## ☸️ 9. Kubernetes Monitoring — Πρακτικά

### kube-prometheus-stack (Helm chart — η πιο συνηθισμένη προσέγγιση)
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace
```
> Αυτό εγκαθιστά **μαζί**: Prometheus, Grafana, Alertmanager, Node Exporter, και προκαθορισμένα K8s dashboards — έτοιμο monitoring stack σε ένα command (βλ. `devops-kubernetes.md` για Helm βασικά).

### ServiceMonitor (πώς ο Prometheus Operator βρίσκει τι να κάνει scrape)
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: myapp-monitor
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: myapp
  endpoints:
    - port: metrics
      interval: 15s
```

### kubectl top — γρήγορος έλεγχος χωρίς πλήρες monitoring stack
```bash
kubectl top nodes
kubectl top pods -n production
```

---

## 🎯 10. SLI, SLO, SLA — Η Σχέση τους

Σύνδεση με το `itsm-event-availability-policies.md` — εδώ πώς μετριούνται τεχνικά.

| Όρος | Σημασία | Παράδειγμα |
|---|---|---|
| **SLI** (Service Level Indicator) | Η πραγματική, μετρημένη τιμή | "99.95% requests ολοκληρώθηκαν επιτυχώς" |
| **SLO** (Service Level Objective) | Ο εσωτερικός στόχος | "Θέλουμε 99.9% success rate" |
| **SLA** (Service Level Agreement) | Η συμβατική δέσμευση προς πελάτη (συνήθως πιο "χαλαρή" από το SLO) | "Εγγυόμαστε 99.5% uptime, αλλιώς penalty" |

### Error Budget — πρακτική χρήση SLO
```
SLO: 99.9% success rate → επιτρέπεται 0.1% failure rate

Αν το error budget (0.1%) έχει "καεί" νωρίς στο μήνα:
→ Σταμάτημα νέων risky releases, εστίαση σε σταθερότητα

Αν υπάρχει ακόμα άφθονο error budget:
→ Άνετα μπορείς να κάνεις νέες, πιο ρισκαρισμένες αλλαγές
```

### PromQL για SLO tracking
```promql
# Success rate τελευταίων 30 ημερών
sum(rate(http_requests_total{status!~"5.."}[30d]))
/
sum(rate(http_requests_total[30d]))
```

---

## ✅ 11. Best Practices

| Πρακτική | Γιατί |
|---|---|
| Alert σε **symptoms**, όχι σε **causes** | Alert για "high error rate" (symptom), όχι "high CPU" (μπορεί να είναι φυσιολογικό) |
| Κάθε alert πρέπει να είναι **actionable** | Αν δεν μπορείς να κάνεις τίποτα με αυτό, δεν χρειάζεται alert (μόνο θόρυβος) |
| Χρήση `for:` clause στα alert rules | Αποφυγή false positives από στιγμιαίες διακυμάνσεις |
| Structured logging (JSON) | Επιτρέπει querying/filtering (βλ. `devops-debugging-troubleshooting.md`) |
| Dashboards as Code | Version controlled, reproducible (σαν Terraform για dashboards) |
| Ξεκάθαρα labels/naming conventions σε metrics | `service`, `environment`, `region` — συνεπή σε όλη την υποδομή |
| Retention policy για metrics/logs | Μην κρατάς high-resolution δεδομένα για πάντα — ακριβό σε storage |

### Alert Fatigue — το πρόβλημα που πρέπει να αποφύγεις
```
Πάρα πολλά, μη-actionable alerts
        ↓
Η ομάδα αρχίζει να τα αγνοεί ("boy who cried wolf")
        ↓
Ένα ΠΡΑΓΜΑΤΙΚΑ κρίσιμο alert χάνεται μέσα στον θόρυβο
```
> Καλύτερα λίγα, καλά σχεδιασμένα alerts παρά πολλά χαμηλής αξίας.

---

## 🎯 12. Πλήρες Παράδειγμα — Πλήρες Monitoring Stack

```
Σενάριο: Microservices εφαρμογή σε Kubernetes, χρειάζεται πλήρες observability

1. Εγκατάσταση kube-prometheus-stack (Prometheus + Grafana + Alertmanager):
   helm install monitoring prometheus-community/kube-prometheus-stack \
     --namespace monitoring --create-namespace

2. Κάθε microservice εκθέτει custom metrics (/metrics endpoint):
   → ServiceMonitor αυτόματα τα ανιχνεύει και ξεκινά scraping

3. Loki + Promtail για logging:
   helm install loki grafana/loki-stack --namespace monitoring

4. OpenTelemetry Collector για distributed tracing:
   → Κάθε service auto-instrumented, στέλνει traces σε Jaeger

5. Alert rules ορίζονται:
   - HighErrorRate (>5% για 5 λεπτά) → Critical → PagerDuty
   - HighLatency (p95 > 2s για 10 λεπτά) → Warning → Slack
   - PodCrashLooping → Critical → PagerDuty

6. Grafana dashboards:
   - "Service Overview": request rate, error rate, latency (RED metrics)
   - "Infrastructure": node CPU/memory/disk
   - "Business Metrics": orders/min, revenue/hour

7. Incident συμβαίνει:
   → Alert πυροδοτείται (HighErrorRate στο payment-service)
   → PagerDuty ειδοποιεί on-call engineer
   → Engineer ανοίγει Grafana dashboard, βλέπει ΠΟΤΕ ξεκίνησε
   → Correlate με deployment timeline (ταιριάζει με πρόσφατο release)
   → Trace ID από τα logs → Jaeger → βλέπει ΠΟΥ ακριβώς αποτυγχάνει το request
   → Root cause εντοπίζεται, rollback (βλ. devops-kubernetes.md)
   → Grafana επιβεβαιώνει: error rate επιστρέφει στο φυσιολογικό

8. Post-incident:
   → SLO tracking δείχνει πόσο error budget "κάηκε"
   → Post-Incident Review (βλ. ITSM υλικό) με πλήρη δεδομένα από
     metrics/logs/traces, όχι μαντεψιές
```

Αυτό δείχνει το **πλήρες observability stack** σε δράση — από το πρώτο alert μέχρι το root cause, με κάθε πυλώνα (metrics, logs, traces) να συνεισφέρει στη διερεύνηση.

---

*Μέρος του [Infrastructure Knowledge Base](https://github.com/Dimitriskatsanos42/Infrastructure-Knowledge-Base) — φάκελος DevOps. Αυτό ολοκληρώνει το βασικό roadmap: fundamentals → Git/CI-CD → debugging → Docker → Kubernetes → Terraform → Ansible → Monitoring.*
