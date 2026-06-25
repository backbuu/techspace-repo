# Learning Plan: Kubernetes & NKP (Nutanix Kubernetes Platform)

A structured, progressive learning plan from Kubernetes fundamentals to NKP administration and certification. Estimated total time: **12–16 weeks** at ~5–8 hours/week.

---

## Track Overview

```
Phase 1: Foundations (Weeks 1–3)
  └── Containers → Linux basics → Kubernetes core concepts

Phase 2: Kubernetes Core (Weeks 4–7)
  └── Workloads → Networking → Storage → RBAC → kubectl hands-on

Phase 3: Kubernetes Advanced (Weeks 8–9)
  └── Helm → GitOps → Observability → Cluster API (CAPI)

Phase 4: NKP Fundamentals (Weeks 10–12)
  └── NKP architecture → Deploy → Manage → Multicluster

Phase 5: NKP Advanced + Certification (Weeks 13–16)
  └── NKPA course → NCP-CN exam prep → practice tests
```

---

## Phase 1: Foundations (Weeks 1–3)

### Goal
Understand containers and the problems Kubernetes solves before touching a cluster.

### Topics

- [ ] **Linux basics** — processes, networking (`ip`, `ss`, `curl`), systemd, file permissions
- [ ] **Containers** — what a container is, how it differs from a VM, namespaces, cgroups
- [ ] **Docker / Podman** — build images, run containers, volumes, networking
- [ ] **Container registries** — push/pull images, Docker Hub, private registries
- [ ] **YAML** — syntax, anchors, multi-document files (K8s uses YAML everywhere)

### Resources

- [Docker Getting Started](https://docs.docker.com/get-started/)
- [Play with Docker](https://labs.play-with-docker.com/) — free browser-based lab
- [Linux Journey](https://linuxjourney.com/) — interactive Linux basics

### Checkpoint
- [ ] Build a Docker image from a Dockerfile and push it to Docker Hub
- [ ] Run a multi-container app with `docker compose`

---

## Phase 2: Kubernetes Core (Weeks 4–7)

### Goal
Understand and operate core Kubernetes objects. Be comfortable with `kubectl`.

### Topics

- [ ] **K8s architecture** — control plane (API server, etcd, scheduler, controller manager), worker node (kubelet, kube-proxy, container runtime)
- [ ] **Pods** — lifecycle, multi-container pods, init containers, probes (liveness, readiness, startup)
- [ ] **Workloads** — Deployment, ReplicaSet, StatefulSet, DaemonSet, Job, CronJob
- [ ] **Services** — ClusterIP, NodePort, LoadBalancer, ExternalName
- [ ] **Ingress** — routing HTTP traffic, TLS termination
- [ ] **ConfigMaps & Secrets** — injecting config into pods (env vars, volume mounts)
- [ ] **Persistent Volumes** — PV, PVC, StorageClass, dynamic provisioning
- [ ] **Namespaces** — resource isolation, resource quotas, limit ranges
- [ ] **RBAC** — Role, ClusterRole, RoleBinding, ClusterRoleBinding, ServiceAccounts
- [ ] **kubectl** — get, describe, logs, exec, apply, delete, port-forward, rollout

### Resources

- [Kubernetes Official Tutorials](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [Kubernetes Roadmap](https://roadmap.sh/kubernetes)
- [KodeKloud Kubernetes Path](https://kodekloud.com/learning-path/kubernetes) — hands-on labs
- [Kubernetes Up and Running (book)](https://www.oreilly.com/library/view/kubernetes-up-and/9781098110192/)

### Lab Environment Options

| Option | Cost | Notes |
|--------|------|-------|
| [Killercoda](https://killercoda.com/) | Free | Browser-based K8s labs |
| [Play with Kubernetes](https://labs.play-with-k8s.com/) | Free | 4-hour sessions |
| [minikube](https://minikube.sigs.k8s.io/) | Free | Local single-node cluster |
| [kind](https://kind.sigs.k8s.io/) | Free | Local multi-node via Docker |

### Checkpoint
- [ ] Deploy a multi-replica app with a Deployment + Service + Ingress
- [ ] Mount a Secret as an env var and a ConfigMap as a volume
- [ ] Create a PVC and attach it to a pod
- [ ] Create a Role and bind it to a ServiceAccount

---

## Phase 3: Kubernetes Advanced (Weeks 8–9)

### Goal
Add production-grade tooling: package management, GitOps, observability, and the Cluster API foundation that NKP is built on.

### Topics

- [ ] **Helm** — charts, values, templating, `helm install/upgrade/rollback`
- [ ] **GitOps with Flux or ArgoCD** — declarative cluster state, sync from Git
- [ ] **Observability** — Prometheus + Grafana for metrics, Loki for logs, distributed tracing basics
- [ ] **Network policies** — restrict pod-to-pod traffic, Calico/Cilium basics
- [ ] **Cluster API (CAPI)** — what it is, management cluster vs workload cluster, providers
- [ ] **Multi-cluster concepts** — hub/spoke model, federation, cluster lifecycle

### Resources

- [Helm Docs](https://helm.sh/docs/)
- [Argo CD Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- [Cluster API Book](https://cluster-api.sigs.k8s.io/)
- [CNCF Top 28 Resources 2026](https://www.cncf.io/blog/2026/01/19/top-28-kubernetes-resources-for-2026-learn-and-stay-up-to-date/)

### Checkpoint
- [ ] Deploy an app with Helm and customize values
- [ ] Set up a GitOps sync with ArgoCD pointing to a Git repo
- [ ] Query Prometheus metrics for a running workload

---

## Phase 4: NKP Fundamentals (Weeks 10–12)

### Goal
Understand NKP architecture and deploy/manage clusters on Nutanix infrastructure.

### NKP Architecture

```
Prism Central (AHV / AOS)
  └── NKP Management Cluster
        ├── Cluster API Controller (CAPI v1.9.6)
        ├── Cluster Manager  — lifecycle: create, scale, upgrade, delete
        ├── Application Manager — GitOps-driven app deployment
        └── NKP Insights Engine — metrics, events, anomaly detection

        manages ──▶  Workload Cluster 1
                     Workload Cluster 2
                     Workload Cluster N
```

### Key NKP Concepts

| Concept | Description |
|---------|-------------|
| Management Cluster | Control plane for all NKP operations — hosts CAPI and NKP controllers |
| Workload Cluster | Application clusters provisioned and managed by the management cluster |
| Cluster API (CAPI) | K8s-native framework for cluster lifecycle management |
| Workspace | Multi-tenancy unit — isolates teams and their clusters |
| Project | Logical grouping for apps and policies across clusters |
| NKP Insights | Built-in monitoring and anomaly detection across all clusters |
| Kommander | NKP's multi-cluster management UI (upstream: D2iQ DKP) |

### Topics

- [ ] **NKP overview** — what it adds over vanilla K8s, licensing tiers (Essential / Pro / Ultimate)
- [ ] **NKP on AHV** — integration with Prism Central, VM provisioning via CAPI Nutanix provider
- [ ] **Deploy management cluster** — prerequisites, `nkp create cluster nutanix`, bootstrap process
- [ ] **Deploy workload clusters** — via UI and CLI, node pools, autoscaling
- [ ] **Cluster lifecycle** — scale, upgrade, delete
- [ ] **Workspaces and Projects** — multi-tenancy setup
- [ ] **Identity and RBAC** — configure identity providers (LDAP/AD), map groups to roles
- [ ] **Application deployment** — deploy apps via NKP catalog and GitOps

### Resources

- [NKP 2.15 Architecture Doc](https://portal.nutanix.com/docs/Nutanix-Kubernetes-Platform-v2_15:top-overview-nkp-architecture-c.html)
- [Nutanix Bible — NKP Chapter](https://www.nutanixbible.com/18a-book-of-cloud-native-services-nutanix-kubernetes-platform.html)
- [NKP Step-by-Step Deployment Guide (Medium)](https://medium.com/@tanmaybhandge/getting-started-with-nutanix-kubernetes-platform-nkp-a-step-by-step-deployment-guide-8bcb54a80377)
- [NKP Cheat Sheet](https://www.taylor-norris.com/post/new-to-nkp-here-s-your-ultimate-cheat-sheet-to-the-nutanix-kubernetes-platform)
- [NKP on Nutanix.dev](https://www.nutanix.dev/category/cloudnative/nkp/)
- [Deploy K8s Cluster with Terraform on NKP](https://www.nutanix.dev/2025/10/22/how-to-deploy-a-kubernetes-cluster-in-the-nutanix-kubernetes-platform-using-terraform/)

### Checkpoint
- [ ] Describe the difference between management cluster and workload cluster
- [ ] List the CAPI components NKP uses and what each does
- [ ] Create a workload cluster and attach it to the management cluster
- [ ] Configure a workspace and assign a user group

---

## Phase 5: NKP Advanced + Certification (Weeks 13–16)

### Goal
Complete formal training, pass the NCP-CN certification exam.

### NKPA Course Topics (Official Nutanix Training)

- [ ] NKP fundamentals, terminology, licensing
- [ ] Installation — standard and air-gapped environments
- [ ] Cluster lifecycle management (create, scale, upgrade, delete)
- [ ] Workspaces and Projects
- [ ] Identity providers and RBAC configuration
- [ ] Monitoring and troubleshooting NKP clusters

**Course:** [Nutanix Kubernetes Platform Administration (NKPA)](https://www.nutanix.com/support-services/training-certification/training/course-details-nutanix-kubernetes-platform-administration)

### NCP-CN Certification

| Detail | Value |
|--------|-------|
| Exam | Nutanix Certified Professional — Cloud Native (NCP-CN) |
| Version | 6.10 |
| Questions | 75 multiple choice |
| Duration | 120 minutes |
| Passing score | 3000 / 6000 (scaled) |
| Fee | $200 USD |
| Experience recommended | 6–12 months K8s, 6 months NKP |

**Exam covers:**
- Deploy and configure NKP clusters
- Optimize and troubleshoot NKP
- Perform administrative tasks (RBAC, identity, upgrades)
- Manage multi-cluster and multi-tenancy scenarios

**Prep resources:**
- [NCP-CN Certification Page](https://www.nutanix.com/support-services/training-certification/certifications/certification-details-nutanix-certified-professional-cloud-native-v6-10)
- [NCP-CN Practice Tests](https://open-exam-prep.com/practice/nutanix-ncp-cn)
- [NKP Community Blog](https://next.nutanix.com/education-blog-153/embrace-the-power-of-kubernetes-with-the-nutanix-certified-professional-cloud-native-ncp-cn-certification-44288)

### Checkpoint
- [ ] Complete NKPA course
- [ ] Score 80%+ on 2 practice exams before booking the real exam
- [ ] Pass NCP-CN exam

---

## Weekly Schedule (Suggested)

| Week | Phase | Focus |
|------|-------|-------|
| 1 | 1 | Linux basics + containers |
| 2 | 1 | Docker hands-on + YAML |
| 3 | 1 | Container networking + registries |
| 4 | 2 | K8s architecture + Pods |
| 5 | 2 | Workloads (Deployment, StatefulSet, DaemonSet) |
| 6 | 2 | Services + Ingress + Storage |
| 7 | 2 | RBAC + Namespaces + kubectl mastery |
| 8 | 3 | Helm + GitOps (ArgoCD) |
| 9 | 3 | Observability + Network Policies + CAPI intro |
| 10 | 4 | NKP architecture + management cluster |
| 11 | 4 | Deploy workload clusters + lifecycle ops |
| 12 | 4 | Workspaces, Projects, Identity, RBAC |
| 13 | 5 | NKPA course — Part 1 |
| 14 | 5 | NKPA course — Part 2 |
| 15 | 5 | Practice exams + gap review |
| 16 | 5 | NCP-CN exam |

---

## Progress Tracker

### Phase 1 — Foundations
- [ ] Linux basics
- [ ] Docker / containers hands-on
- [ ] YAML fluency
- [ ] Checkpoint: multi-container app running

### Phase 2 — Kubernetes Core
- [ ] K8s architecture understood
- [ ] Core objects (Pod, Deployment, Service, PVC, RBAC)
- [ ] kubectl comfortable
- [ ] Checkpoint: full app deployed on local cluster

### Phase 3 — Kubernetes Advanced
- [ ] Helm
- [ ] GitOps (ArgoCD)
- [ ] Observability (Prometheus + Grafana)
- [ ] CAPI concepts clear
- [ ] Checkpoint: GitOps pipeline working

### Phase 4 — NKP Fundamentals
- [ ] NKP architecture understood
- [ ] Management cluster deployed
- [ ] Workload cluster created and managed
- [ ] Workspace + identity configured
- [ ] Checkpoint: end-to-end cluster lifecycle on Nutanix

### Phase 5 — Certification
- [ ] NKPA course completed
- [ ] Practice exam score 80%+
- [ ] NCP-CN passed ✅

---

## Key Differences: Vanilla K8s vs NKP

| Feature | Vanilla Kubernetes | NKP |
|---------|-------------------|-----|
| Cluster provisioning | Manual / scripts | Automated via CAPI + Nutanix provider |
| Multi-cluster management | DIY (federation, Argo) | Built-in via Kommander |
| GitOps | Bring your own (Flux/ArgoCD) | Built-in FluxCD |
| Monitoring | Bring your own (Prometheus stack) | Built-in NKP Insights |
| Identity / RBAC | Bring your own (OIDC integration) | Built-in identity provider config |
| Storage | Bring your own (CSI drivers) | Nutanix CSI pre-integrated |
| Air-gapped support | Complex | Supported natively |
| Certification path | CKA / CKAD / CKS | NCP-CN (NKPA training) |
