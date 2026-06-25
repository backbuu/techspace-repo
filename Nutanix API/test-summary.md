# Nutanix API v4 — Test Summary

**Date:** 2026-06-25  
**Environment:** Prism Central 10.8.23.7:9440  
**API Namespace:** `vmm/v4.0`  
**Auth:** HTTP Basic

---

## Results at a Glance

| # | Test | Endpoint | Status |
|---|------|----------|--------|
| 1 | Connectivity check | `GET /api/vmm/v4.0/ahv/config/vms?$limit=1` | ✅ 200 OK |
| 2 | List all VMs | `GET /api/vmm/v4.0/ahv/config/vms?$page=0&$limit=100` | ✅ 48 VMs |
| 3 | Get VM by extId | `GET /api/vmm/v4.0/ahv/config/vms/{extId}` | ✅ Full object |

---

## Cluster Snapshot

| Metric | Value |
|--------|-------|
| Total VMs | 48 |
| Power ON | 47 |
| Power OFF | 1 |
| Total vCPU | 263 |
| Total RAM | 988 GB |

---

## VM Groups Found

| Group | Count | Description |
|-------|-------|-------------|
| `nkp-*` | 10 | Nutanix Kubernetes Platform nodes |
| `ocp*` / `ocp-boot-` | 8 | OpenShift cluster nodes |
| `workload0*` | 10 | Workload cluster VMs (NKP workloads) |
| `otest-*` | 6 | OpenShift test VMs |
| `vmtestrep-*` | 3 | Test/replication VMs |
| `objects-*` | 2 | Nutanix Objects (S3-compatible storage) |
| `NTNX-files-*` | 1 | Nutanix Files (NAS) |
| Infrastructure | 8 | `pc`, `autoad`, `ocp-boot-`, Calm policy engine, `LinuxTools` |

---

## Confirmed Behaviours

| Item | Detail |
|------|--------|
| Auth | HTTP Basic — `Authorization: Basic <base64(user:pass)>` |
| SSL | Self-signed cert on lab PC — always use `-k` |
| Response envelope | `{ "data": [...] }` for list, `{ "data": {} }` for single |
| Object type | `"$objectType": "vmm.v4.ahv.config.Vm"` on each VM |
| API version marker | `"$fv": "v4.r1"` inside `$reserved` |
| Pagination | `$page` (0-based) + `$limit` (max 100) works correctly |
| Key VM fields | `extId`, `name`, `powerState`, `numSockets`, `numCoresPerSocket`, `memorySizeBytes`, `nics`, `disks`, `createTime`, `updateTime` |

---

## Example curl Commands

**List VMs (page 0, 100 per page):**
```bash
curl -k -u "Admin:<password>" \
  -H "Accept: application/json" \
  "https://10.8.23.7:9440/api/vmm/v4.0/ahv/config/vms?$page=0&$limit=100"
```

**Get single VM:**
```bash
curl -k -u "Admin:<password>" \
  -H "Accept: application/json" \
  "https://10.8.23.7:9440/api/vmm/v4.0/ahv/config/vms/{extId}"
```

---

## Raw Data Files

| File | Description |
|------|-------------|
| `vms-raw.json` | Full API response — all 48 VMs |
| `vm-detail-autoad.json` | Single VM full object (`autoad`) |
| `api-test-results.md` | Detailed test log with all outputs |

---

## Pending Tests

- [ ] `$filter=powerState eq 'OFF'` — filter by power state
- [ ] `$select=name,extId,powerState` — field projection
- [ ] Power on/off via `POST /{extId}/$actions/power-on`
- [ ] Pagination loop (when VM count > 100)
- [ ] API key auth (`X-Ntnx-Api-Key` header)
