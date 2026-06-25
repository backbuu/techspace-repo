# Nutanix API v4 — Test & Reference

Hands-on test scripts and reference docs for the Nutanix REST API v4, built and verified against a live Prism Central environment. Covers VM information retrieval, live stats, VPC/Projects, and Zabbix monitoring integration.

---

> **⚠️ Version Disclaimer**
>
> All code, endpoints, and test results were verified on the environment below. API namespace availability, endpoint paths, and response schemas **vary across PC and AOS releases**. What works on one build may return `404` or behave differently on another.
>
> **Tested Environment**
>
> | Component | Version |
> |-----------|---------|
> | Prism Central | `pc.7.3.1.3` (`el8.5-release-ganges-7.3.1.3`) |
> | AOS (primary cluster) | `7.3` |
> | PC Nodes | 1 (single-node) |
> | Storage | All-Flash, X86_64 |
>
> **API Version Availability (confirmed on this build)**
>
> | Namespace | Working | Not Available |
> |-----------|---------|---------------|
> | `vmm` config | `v4.0`, `v4.0.b1`, `v4.1` | `v4.0.b2` |
> | `vmm` stats | **`v4.1` only** (with `$select=*`) | `v4.0`, `v4.0.b1` — VMM-30102 |
> | `networking` | `v4.0.b1`, `v4.0.b2`, `v4.0`, `v4.1` | `v4.0.a1` |
> | `clustermgmt` | `v4.0.b1` | — |
> | `prism` (tasks) | `v4.0.b1` | — |
> | `iam` v4 projects | ❌ 404 on this build | Use v3 fallback |
> | v3 API (`/api/nutanix/v3/`) | ✅ Fully available | — |
> | v1 REST (`/PrismGateway/services/rest/v1/`) | ✅ Fully available | — |

---

## Files in This Folder

### Core API Reference

| File | What it covers |
|------|----------------|
| [vm-api-research.md](./vm-api-research.md) | Base URL pattern, auth methods, all VM endpoints, OData syntax, Python SDK setup |
| [vpc-and-projects-api.md](./vpc-and-projects-api.md) | VPC full CRUD (List, Get, Create, Update, Delete) + Projects |
| [postman-guide.md](./postman-guide.md) | Postman collection setup and quick test steps |

### Live Test Logs

| File | What it covers |
|------|----------------|
| [api-test-results.md](./api-test-results.md) | T-01 to T-03: connectivity, list VMs (48), get VM by extId |
| [test-call-project.md](./test-call-project.md) | VPC list → Project list → VPC↔Project relationship map |
| [test-call-vm-info.md](./test-call-vm-info.md) | VM name, IP, CPU, Memory, Disk, Network, Power state |
| [test-call-vm-live-stats-v4.md](./test-call-vm-live-stats-v4.md) | Live stats discovery — version probe, working endpoint found |
| [test-summary.md](./test-summary.md) | Summary of all early tests with confirmed behaviours |
| [vm-live-stats.md](./vm-live-stats.md) | 51 VMs live stats via v3/groups — sorted by CPU usage |
| [vm-stats-v4-research.md](./vm-stats-v4-research.md) | Full discovery of `vmm/v4.1` working stats; all 40+ stat fields documented |

### Monitoring Integration

| File | What it covers |
|------|----------------|
| [zabbix-monitoring-research.md](./zabbix-monitoring-research.md) | Zabbix integration design, rate limits, 6 test cases (ZBX-T01–T06), alert thresholds |

### Progress & Tracking

| File | What it covers |
|------|----------------|
| [PROGRESS.md](./PROGRESS.md) | Phase checklist: research → test → article draft |

### Raw JSON Results

| File | Description |
|------|-------------|
| [vms-raw.json](./vms-raw.json) | Full API response — all 48 VMs |
| [vm-detail-autoad.json](./vm-detail-autoad.json) | Single VM full object (`autoad`) |
| [vm-stats-v4-raw.json](./vm-stats-v4-raw.json) | Raw `vmm/v4.1` time-series stats response |

### Condensed Test Report

| Folder | Description |
|--------|-------------|
| [result-test/](./result-test/) | Single-file report: 7 tests, curl commands, validation scripts, gotchas |

---

## API Overview

### Base URL

```
https://{prism_central_ip}:9440/api/{namespace}/{version}/{resource}
```

### Namespaces

| Namespace | Purpose | Use This Version |
|-----------|---------|-----------------|
| `vmm` | VM config — list, get, power ops | `v4.0` |
| `vmm` stats | VM live performance metrics | `v4.1` + `$select=*` |
| `networking` | VPC, subnets, virtual switches | `v4.0` |
| `iam` / projects | Projects, users, roles | v3 fallback |
| `prism` | Task polling (async ops) | `v4.0.b1` |

### Authentication

```bash
# HTTP Basic Auth (lab / testing)
curl -sk -u "{username}:{password}" "https://{pc_ip}:9440/api/..."

# API Key (service accounts / production)
curl -sk -H "X-Ntnx-Api-Key: {api_key}" "https://{pc_ip}:9440/api/..."
```

### Pagination

| Parameter | Default | Max |
|-----------|---------|-----|
| `$page` | `0` | — (zero-based) |
| `$limit` | `50` | `100` |
| `$filter` | — | OData syntax e.g. `powerState eq 'ON'` |

Always loop pages until `data` returns fewer items than `$limit`.

### Rate Limits (Prism Central)

| PC Size | API Rate Limit |
|---------|---------------|
| X-Small | 30 req/sec |
| Small | 40 req/sec |
| Large | 60 req/sec |
| Extra Large | 80 req/sec |

Design polling scripts to use bulk endpoints (1–2 calls per cycle) rather than 1 call per VM.

---

## Quick Start

```bash
PC="10.8.23.7"
AUTH="Admin:<password>"

# List all VMs
curl -sk -u "$AUTH" \
  "https://$PC:9440/api/vmm/v4.0/ahv/config/vms?\$page=0&\$limit=100" \
  | python3 -m json.tool

# Live stats — all VMs (bulk, no time window needed)
curl -sk -u "$AUTH" \
  -H "Content-Type: application/json" -X POST \
  -d '{"entity_type":"vm","group_member_count":100,"group_member_attributes":[{"attribute":"vm_name"},{"attribute":"hypervisor_cpu_usage_ppm"},{"attribute":"memory_usage_ppm"},{"attribute":"controller_num_read_iops"},{"attribute":"controller_num_write_iops"}],"filter_criteria":"power_state==on"}' \
  "https://$PC:9440/api/nutanix/v3/groups" \
  | python3 -m json.tool

# Live stats — single VM time-series (vmm/v4.1 only)
START=$(python3 -c "from datetime import datetime,timezone,timedelta; print((datetime.now(timezone.utc)-timedelta(minutes=5)).strftime('%Y-%m-%dT%H:%M:%SZ'))")
END=$(python3 -c "from datetime import datetime,timezone; print(datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'))")
VM_ID="c90699b2-ec53-4800-93e7-4cf23024b75e"

curl -sk -u "$AUTH" \
  "https://$PC:9440/api/vmm/v4.1/ahv/stats/vms/$VM_ID?\$startTime=$START&\$endTime=$END&\$samplingInterval=30&\$statType=SUM&\$select=*" \
  | python3 -m json.tool

# List VPCs
curl -sk -u "$AUTH" \
  "https://$PC:9440/api/networking/v4.0/config/vpcs?\$limit=100" \
  | python3 -m json.tool

# List Projects (v3 fallback — v4 iam not available on this build)
curl -sk -u "$AUTH" \
  -X POST "https://$PC:9440/api/nutanix/v3/projects/list" \
  -H "Content-Type: application/json" \
  -d '{"kind":"project","length":100,"offset":0}' \
  | python3 -m json.tool
```

---

## Test Results at a Glance

### VM API Tests (7 total)

| # | Test | API | Status |
|---|------|-----|:------:|
| T-01 | Connectivity | `vmm/v4.0` | ✅ |
| T-02 | List all VMs | `vmm/v4.0` | ✅ 48 VMs |
| T-03 | Get VM by extId | `vmm/v4.0` | ✅ Full object |
| T-04 | Stats with named `$select` | `vmm/v4.0` | ❌ VMM-30102 |
| T-05 | Stats with named `$select` | `vmm/v4.0.b1` | ❌ VMM-30102 |
| T-06 | Stats with `$select=*` | `vmm/v4.1` | ✅ 40+ fields |
| T-07 | Stats via v3/groups | `v3` | ✅ 51 VMs |

### Cluster Snapshot (2026-06-25)

| Metric | Value |
|--------|-------|
| Total VMs | 48 |
| Power ON | 47 |
| vCPU allocated | 263 |
| RAM allocated | 988 GB |

---

## Key Findings

1. **Use `vmm/v4.1` for per-VM time-series stats** — `vmm/v4.0` returns `VMM-30102` on this PC build
2. **`$select=*` is the only working selector** — named fields always fail on pc.7.3.1.3
3. **Use `v3/groups` for bulk live stats** — 1 POST returns all VMs, no time window required, works on all PC versions
4. **`memoryUsagePpm` not `hypervisorMemoryUsagePpm`** — the hypervisor field always reads 100% (known bug)
5. **Stats are 30s time-series** — always specify `$startTime` + `$endTime`; both are required

---

## Known Issues (on pc.7.3.1.3)

| Issue | Workaround |
|-------|-----------|
| `vmm` stats `$select` named fields → VMM-30102 | Use `vmm/v4.1` + `$select=*` |
| `iam/v4.x/authz/projects` → 404 | Use `POST /api/nutanix/v3/projects/list` |
| `hypervisorMemoryUsagePpm` always 100% | Use `memoryUsagePpm` or `guestMemoryUsagePpm` |
| SSL self-signed cert | Add `-k` to all curl commands |
| Stats return 400 | `$startTime` and `$endTime` are both required |
| Network bytes are per-interval not cumulative | Divide by 30 (seconds) for bytes/s |

---

## References

- [Nutanix v4 API User Guide](https://www.nutanix.dev/nutanix-api-user-guide/)
- [VMM API Reference](https://developers.nutanix.com/api-reference?namespace=vmm&version=v4.0.b1)
- [Networking API Reference](https://developers.nutanix.com/api-reference?namespace=networking&version=v4.0.a1)
- [Prism API Reference](https://developers.nutanix.com/api-reference?namespace=prism&version=v4.0.b1)
- [Zabbix Nutanix Integration](https://www.zabbix.com/integrations/nutanix)
- [ntnx-api-python-clients on GitHub](https://github.com/nutanix/ntnx-api-python-clients)
