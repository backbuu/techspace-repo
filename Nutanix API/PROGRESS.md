# Nutanix API V4 Research — Progress Tracker

## Goal
Research Nutanix Prism Central REST API v4 (VMM namespace) — VM listing, detail, power operations, create/update/delete — and produce a publishable article for the TechSpace blog.

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
- [ ] Capture full VM response schema (all fields with types)
- [ ] Capture example curl commands (list, get, power on/off)
- [ ] Verify Python SDK setup and `ntnx_vmm_py_client` usage
- [ ] Confirm GA version vs beta (v4.0 vs v4.0.b1 vs v4.1)

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

## Open Questions

1. Is `v4.0.b1` still the latest stable, or has `v4.1` reached GA?
2. Full VM response schema — need a live cluster or OpenAPI spec to confirm all fields.
3. Rate limits — not publicly documented; needs confirmation from Nutanix support or community.
4. Does `$filter` support nested fields (e.g., `cluster/extId eq '...'`)?
