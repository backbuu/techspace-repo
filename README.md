# TechSpace Research Repo

Personal research workspace for TechSpace — a tech blog platform for cloud, Kubernetes, AI, and infrastructure practitioners. This repo holds research notes, API test results, and reference documentation that feed into published articles.

---

## What's in This Repo

| Folder / File | Contents |
|---------------|----------|
| [`Nutanix API/`](#nutanix-api-v4-research) | API v4 research, live test results, and reference docs |
| `PRD.md` | TechSpace platform product requirements |
| `PROGRESS.md` | Module completion tracker |
| `ONBOARDING.md` | Claude Code onboarding guide for new teammates |
| `CLAUDE.md` | AI assistant context and writing guidelines |

---

## Nutanix API v4 Research

Live-tested against Prism Central `pc.7.3.1.3` / AOS `7.3` on 2026-06-25.

### Test Environment

| Component | Version |
|-----------|---------|
| Prism Central | `pc.7.3.1.3` |
| AOS (RNO-POC012) | `7.3` |
| AOS (DR) | `7.3` |
| Architecture | X86_64 / All-Flash |

### Research Areas

| Topic | Status | Key Files |
|-------|--------|-----------|
| VM Info (name, IP, CPU, RAM, disk, power state) | ✅ Done | `Nutanix API/test-call-vm-info.md` |
| VM Live Stats (CPU %, mem %, IOPS, net) | ✅ Done | `Nutanix API/test-call-vm-live-stats-v4.md` |
| VPC — List, Get, Create, Update, Delete | ✅ Done | `Nutanix API/vpc-and-projects-api.md` |
| Projects related to VPC | ✅ Done | `Nutanix API/result-test/vpc-project-api-summary.md` |

### API Version Findings (PC 7.3.1.3)

| Namespace | Working | Not Available |
|-----------|---------|--------------|
| `networking` | `v4.0.b1`, `v4.0`, `v4.1` | `v4.0.a1` ❌ |
| `vmm` | `v4.0.b1` | `v4.0.b2`+  ❌ |
| `iam` (projects) | — | All v4 versions ❌ — use v3 |
| `v3` API | ✅ Fully available | — |

### Key Findings

- **VPC endpoint:** `GET /api/networking/v4.0/config/vpcs` — `v4.0.a1` returns 404 on this build.
- **Projects:** v4 IAM projects endpoint not yet GA on PC 7.3.1.3. Use `POST /api/nutanix/v3/projects/list`.
- **VPC↔Project join:** match `project.status.resources.vpc_reference_list[].uuid` to `vpc.extId`.
- **VM stats:** v4 stats endpoint requires `$select` — unreliable on this build. Use `GET /PrismGateway/services/rest/v1/vms/{uuid}` for live metrics.
- **Always probe API versions** before hardcoding — availability varies by PC build even on the same release.

### Folder Structure

```
Nutanix API/
├── README.md                        # Full reference guide + environment details
├── PROGRESS.md                      # Research task tracker
├── vpc-and-projects-api.md          # VPC CRUD + Projects API reference
├── test-call-project.md             # Step-by-step: VPC list → Projects → relationship map
├── test-call-vm-info.md             # Step-by-step: VM config + live stats
├── test-call-vm-live-stats-v4.md    # VM live stats via v4 stats endpoint
├── vm-api-research.md               # VM API v4 research notes
├── postman-guide.md                 # Postman setup and quick test steps
└── result-test/
    └── vpc-project-api-summary.md   # Solution summary: Projects related to VPC
```

---

## TechSpace Platform

| Layer | Stack |
|-------|-------|
| Frontend | React + TypeScript + Vite + Tailwind + shadcn/ui |
| Backend | Python + FastAPI |
| Database | Supabase (Postgres + Auth + Storage + Realtime) |
| Search | Full-text search (Phase 1), pgvector semantic (Phase 2) |
| Content | Markdown stored in Supabase, rendered client-side |

See `PRD.md` for full scope. See `PROGRESS.md` for current status.

---

## References

- [Nutanix v4 API User Guide](https://www.nutanix.dev/nutanix-api-user-guide/)
- [Nutanix API Namespace Reference](https://developers.nutanix.com/api-reference?namespace=networking&version=v4.0)
- [Nutanix API Version Availability](https://www.nutanix.dev/api-versions/)
- [ntnx-api-python-clients on GitHub](https://github.com/nutanix/ntnx-api-python-clients)
