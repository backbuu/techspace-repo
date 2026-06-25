# Nutanix Administrator 101 — Learning List

Preparation guide for the **Nutanix Certified Associate (NCA) v6.10** exam.
Target: pass NCA as a foundation for Nutanix administration work.

---

## Exam at a Glance

| Item | Detail |
|------|--------|
| Exam | NCA v6.10 |
| Questions | 50 (multiple choice + multiple response) |
| Time | 90 minutes |
| Passing score | 3000 (scale: 1000–6000) |
| Cost | $100 USD |
| Recommended experience | 6–12 months IT infrastructure + 3–6 months Nutanix |

**Free NCA voucher** is included when you enroll in the instructor-led NHCF course.

---

## Recommended Learning Path

### Step 1 — Nutanix Hybrid Cloud Fundamentals (NHCF)

The official prep course. 2-day ILT or 16-hour self-paced. Maps directly to all NCA domains.

| Module | Topics |
|--------|--------|
| 1. Introduction | HCI vs. 3-tier architecture, Prism Central vs. Prism Element, Pulse, cluster security |
| 2. Hardware & Storage | Nodes, blocks, clusters, AOS Distributed Storage, storage pools, containers, RF1/RF2/RF3, snapshots |
| 3. Networking | AHV networking, managed vs. unmanaged networks, Network Visualizer |
| 4. Image Management | Image Service — upload, import, manage via Prism Central |
| 5. VM Management | Create, clone, snapshot, recovery points, categories, affinity policies |
| 6. Backup & DR | Data protection strategies, protection domains, remote sites, VM migration |
| 7. Monitoring & Health | Alerts, NCC health checks, log collection, support case filing, Prism reporting |
| 8. Licensing & Upgrades | License Manager, Life Cycle Manager (LCM), inventory, upgrade workflows |

> Register at [Nutanix University](https://university.nutanix.com) — ILT includes a free NCA voucher.

---

### Step 2 — NCA Exam Domains (Blueprint v6.10)

Four domains tested. Study these after NHCF or in parallel.

#### Domain 1 — Lifecycle Management
- What LCM does and how it differs between Prism Central and Prism Element
- Running inventory and identifying available software/firmware upgrades
- Monitoring upgrade jobs and interpreting upgrade status
- Putting a node into maintenance mode and understanding its cluster impact

#### Domain 2 — Basic Administration
- **VM operations:** snapshots, live migration, resource monitoring
- **Users and roles:** define roles, assign permissions, understand RBAC in Prism
- Cluster-level network settings (DNS, NTP, SMTP)
- Alert and notification configuration — thresholds, email recipients

#### Domain 3 — Environmental Health
- Running NCC health checks and interpreting results
- Reading cluster resiliency status (data resiliency widget)
- Collecting logs (log bundle) for support escalation
- Verifying Pulse is active and communicating with Nutanix support
- Creating a support ticket from Prism

#### Domain 4 — Cluster Configuration
- Redundancy Factor vs. Replication Factor — RF1, RF2, RF3 trade-offs
- Storage components: storage pools, containers, datastores
- Storage optimization: dedup, compression, erasure coding (when each applies)
- Supported hypervisors: AHV, ESXi, Hyper-V — key differences
- AHV networking: bridges, bonds, VLANs
- Nutanix product portfolio basics: AOS, AHV, Prism, Files, Objects, Calm
- Disaster recovery use cases: Metro Availability, Leap, async replication

---

### Step 3 — Hands-On Practice

These tasks cover the highest-frequency exam scenarios. Do each one in a lab (use [Nutanix Test Drive](https://www.nutanix.com/test-drive) or a home lab).

- [ ] Log into Prism Element and Prism Central — identify the differences in the UI
- [ ] Create a VM with a disk, NIC, and boot image
- [ ] Take a VM snapshot and revert it
- [ ] Live-migrate a VM between hosts
- [ ] Run an LCM inventory and review available updates
- [ ] Check cluster resiliency status and interpret the data resiliency widget
- [ ] Run NCC health checks and read the summary output
- [ ] Configure an alert policy with a custom threshold
- [ ] Collect a log bundle from Prism
- [ ] Create a storage container with compression enabled
- [ ] Review and verify Pulse connectivity status

---

### Step 4 — NCA Exam Prep

| Resource | Notes |
|----------|-------|
| [NCA Exam Blueprint PDF (v6.10)](https://www.nutanix.com/content/dam/nutanix/en/resources/datasheets/ds-ebg-nca-6-10.pdf) | Official blueprint — read before scheduling |
| [NCA Exam Prep Course](https://www.nutanix.com/support-services/training-certification/training/course-details-nca-exam-prep) | Nutanix-official short prep module |
| Udemy NCA 6.10 Practice Exams | 3rd-party but well-reviewed; good for drilling exam format |
| [Nutanix Community Blog](https://next.nutanix.com) | Real-world tips, study notes from people who passed |

**Exam tip:** The NCA tests navigation and recognition, not deep engineering. Know *where* to do things in Prism — not just *what* they mean.

---

## Study Timeline (Suggested)

| Week | Focus |
|------|-------|
| 1 | NHCF Modules 1–4 (architecture, storage, networking, images) |
| 2 | NHCF Modules 5–8 (VMs, DR, monitoring, LCM) + lab tasks |
| 3 | NCA blueprint review, domain-by-domain; complete all lab checklist items |
| 4 | Practice exams, weak-area review, schedule and sit the exam |

---

## After NCA — Next Steps

| Cert | Focus |
|------|-------|
| NCP-MCI v6.10 | Nutanix Certified Professional — Multi-Cloud Infrastructure (main admin cert) |
| NCP-DB | Database services on Nutanix (Era) |
| NCP-EUC | End-user computing (Frame, AHV) |
| AAPM v6.10 | Advanced Administration and Performance Management (master level) |

---

## Sources

- [Nutanix NCA v6.10 Certification Page](https://www.nutanix.com/support-services/training-certification/certifications/certification-details-nutanix-certified-associate-v6-10)
- [NCA Exam Blueprint Guide (PDF)](https://www.nutanix.com/content/dam/nutanix/en/resources/datasheets/ds-ebg-nca-6-10.pdf)
- [NHCF Course Details](https://www.nutanix.com/support-services/training-certification/training/course-details-nutanix-hybrid-cloud-fundamentals)
- [NCA Exam Prep Course](https://www.nutanix.com/support-services/training-certification/training/course-details-nca-exam-prep)
- [Nutanix Certification Overview](https://www.nutanix.com/support-services/training-certification)
