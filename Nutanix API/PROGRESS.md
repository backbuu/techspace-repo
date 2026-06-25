# Nutanix API V4 Research — Progress Tracker

## Goal
Research Nutanix Prism Central REST API v4 — VM, VPC, and Projects — and produce publishable articles for the TechSpace blog. All research live-tested against PC 10.8.23.7 (PC 7.3.1.3 / AOS 7.3).

## Files in This Folder

| File | Contents |
|------|----------|
| `README.md` | Project overview, environment details, API version table, quick start |
| `vpc-and-projects-api.md` | VPC full CRUD + Projects API reference with live results |
| `test-call-project.md` | Step-by-step test: VPC list → Project list → relationship map |
| `test-call-vm-info.md` | Step-by-step test: VM config + live stats |
| `test-call-vm-live-stats-v4.md` | VM live stats using v4 stats endpoint only |
| `postman-guide.md` | Postman setup and quick test steps |
| `vm-api-research.md` | VM API v4 research notes |
| `PROGRESS.md` | This file |

## Status Legend
- `[ ]` Not started
- `[-]` In progress
- `[x]` Done

---

## Phase 1: Research

- [x] Identify correct API namespace and base URL
- [x] Document authentication methods (Basic Auth, API Key)
- [x] Document VM list endpoint + query parameters
- [x] Document VM get-by-ID endpoint
- [x] Document VM power operations (on / off / shutdown / reboot)
- [x] Document VM create / update / delete endpoints
- [x] Document pagination model (`$page`, `$limit`)
- [x] Document OData filter syntax for VMs
- [x] Document required headers (If-Match, NTNX-Request-Id)
- [x] Capture full VM response schema (all fields with types) — see `test-call-vm-info.md`
- [x] Capture example curl commands (list, get, power on/off) — see `vm-api-research.md`
- [x] Verify Python SDK setup and `ntnx_vmm_py_client` usage — confirmed `v4.0.b1`
- [x] Confirm GA version vs beta — `vmm/v4.0.b1` ✅, `vmm/v4.0.b2`+ ❌ on this PC

## Phase 2: Article Draft

- [ ] Outline article structure
- [ ] Write introduction (why v4, what changed from v3)
- [ ] Write Authentication section
- [ ] Write VM List section (with curl + Python examples)
- [ ] Write VM Detail section
- [ ] Write Power Operations section
- [ ] Write Create VM section
- [ ] Write Pagination & Filtering section
- [ ] Add Summary table
- [ ] Review and edit

## Phase 3: Publish

- [ ] Final review
- [ ] Add front matter (date, author, category: Nutanix)
- [ ] Publish to TechSpace

---

## Sources

| Source | URL | Notes |
|--------|-----|-------|
| Nutanix Developer Portal | https://developers.nutanix.com/api-reference?namespace=vmm&version=v4.0.b1 | Primary VMM v4 reference |
| Nutanix v4 API User Guide | https://www.nutanix.dev/nutanix-api-user-guide/ | Auth, pagination, OData |
| VMM Python SDK Docs | https://developers.nutanix.com/api/v1/sdk/namespaces/main/vmm/versions/v4.0/languages/python/ntnx_vmm_py_client.api.vm_api.html | Python SDK method list |
| Updating VMs with PowerShell | https://www.nutanix.dev/2025/11/25/updating-vms-with-the-nutanix-v4-apis-and-powershell/ | Auth headers, If-Match, ETag |
| Deploying VMs from Templates | https://www.nutanix.dev/2025/06/29/deploying-vms-from-templates-using-nutanix-v4-python-sdk-and-rest-apis/ | Python SDK patterns |
| API Versions Reference | https://www.nutanix.dev/api-versions/ | Namespace GA status |

---

## Phase 4: VPC + Projects Live Testing

- [x] Confirm correct VPC endpoint path (`/api/networking/v4.0/config/vpcs` — NOT `v4.0.a1`)
- [x] List VPCs — returns **VPN-for-Test** (`extId: 71f5d1e9-e7eb-4d2d-a3cb-d371d4f8310b`)
- [x] Confirm VPC type: REGULAR, external IPs: `10.8.23.23/24`, gateway nodes: `10.8.23.25/26`
- [x] Test v4 IAM projects endpoint (`/api/iam/v4.0/authz/projects`) — returns garbled response on this PC version
- [x] Confirm v3 fallback works: `POST /api/nutanix/v3/projects/list` ✅
- [x] Found 2 projects: **Project-VPC** (linked to VPN-for-Test VPC) and **NTNX** (no VPC)
- [x] Confirm VPC↔Project relationship via `vpc_reference_list` in v3 project response

### Live Test Results (2026-06-25, PC 10.8.23.7)

| API | Endpoint | Status |
|-----|----------|--------|
| VPC List | `GET /api/networking/v4.0/config/vpcs` | ✅ Working |
| VPC v4.0.a1 | `GET /api/networking/v4.0.a1/config/vpcs` | ❌ 404 |
| Projects v4 | `GET /api/iam/v4.0/authz/projects` | ❌ Garbled response |
| Projects v3 | `POST /api/nutanix/v3/projects/list` | ✅ Working |

### VPC Found

| Name | extId | Type | External IPs |
|------|-------|------|-------------|
| VPN-for-Test | `71f5d1e9-e7eb-4d2d-a3cb-d371d4f8310b` | REGULAR | `10.8.23.23`, `10.8.23.24` |

### Projects Found

| Name | UUID | VPC Linked |
|------|------|-----------|
| Project-VPC | `e15d97b2-1b6b-43b3-829c-fa94f433a7a0` | VPN-for-Test ✅ |
| NTNX | `e68b227a-8358-43cf-8697-8028e337b299` | None |

---

## Open Questions

1. Is `v4.0.b1` still the latest stable, or has `v4.1` reached GA?
2. Full VM response schema — need a live cluster or OpenAPI spec to confirm all fields.
3. Rate limits — not publicly documented; needs confirmation from Nutanix support or community.
4. Does `$filter` support nested fields (e.g., `cluster/extId eq '...'`)?
5. When will `iam/v4.0/authz/projects` be stable on this PC version?
