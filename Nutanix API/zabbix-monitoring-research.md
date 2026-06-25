# Zabbix + Nutanix — VM Monitoring Research

**Date:** 2026-06-25  
**Goal:** Design test cases for a Zabbix-based monitoring system that collects per-VM metrics (name, CPU, Memory, Disk, Network) from Nutanix Prism Central via API.

---

## Architecture Overview

```
Prism Central (10.8.23.7:9440)
        │
        │ REST API (HTTP Basic Auth)
        ▼
Zabbix Server
  ├── External Script (Python)   ← polls PC API, writes to Zabbix
  │     └── nutanix_vm_monitor.py
  └── HTTP Agent Items           ← Zabbix native HTTP checks (no script)
        └── Zabbix Low-Level Discovery (LLD) → auto-creates 1 host per VM
```

**Two integration paths — pick one:**

| Approach | Pros | Cons |
|----------|------|------|
| **External Script (Python)** | Full control, handles pagination, rate-limit aware | Requires Python on Zabbix server, manual deployment |
| **HTTP Agent (Native Zabbix)** | No scripts, pure Zabbix config | Harder to paginate; per-VM items need LLD template |

**Recommendation for this lab:** External Script. We already have Python data + confirmed API behaviour; the script can batch-collect all 48 VMs in 2 calls (config + stats), respect rate limits, and push to Zabbix.

---

## Rate Limit Awareness

From [Nutanix API User Guide](https://www.nutanix.dev/nutanix-api-user-guide/):

| PC Size | API Rate Limit |
|---------|---------------|
| X-Small | 30 req/sec |
| Small | 40 req/sec |
| Large | 60 req/sec |
| Extra Large | 80 req/sec |

**Lab PC (pc.7.3.1.3) size: unknown** — treat as X-Small (30 req/sec) to be safe.

**Design rule:** Collect all VMs in 1–2 bulk calls rather than 1 call per VM.  
With 48 VMs × 1 req/VM = 48 requests per poll cycle — that's fine for 60s intervals, but wasteful. Use:
- 1 call to `vmm/v4.0/ahv/config/vms?$limit=100` for inventory
- 1 call to `POST /api/nutanix/v3/groups` for all VM live stats

Total: **2 API calls per poll cycle** regardless of VM count.

---

## Metrics to Collect per VM

### Identity / Inventory (from `vmm/v4.0` config endpoint)

| Metric | API Field | Type | Notes |
|--------|-----------|------|-------|
| VM Name | `name` | string | Label/tag |
| Power State | `powerState` | string | `ON` / `OFF` |
| vCPU count | `numSockets × numCoresPerSocket` | int | Allocated |
| RAM allocated (GB) | `memorySizeBytes ÷ 1073741824` | float | Allocated |
| Disk count | `len(disks)` | int | Number of virtual disks |
| NIC count | `len(nics)` | int | Number of vNICs |
| extId | `extId` | string | Use as Zabbix host ID |

### Live Performance (from `vmm/v4.1` stats or `v3/groups` fallback)

| Metric | Field (v4.1) | Field (v3/groups) | Unit | Convert |
|--------|-------------|-------------------|------|---------|
| **CPU Usage %** | `hypervisorCpuUsagePpm` | `hypervisor_cpu_usage_ppm` | ppm | ÷ 10,000 |
| **Memory Usage %** | `memoryUsagePpm` | `memory_usage_ppm` | ppm | ÷ 10,000 |
| **Disk Read IOPS** | `controllerNumReadIops` | `controller_num_read_iops` | IOPS | direct |
| **Disk Write IOPS** | `controllerNumWriteIops` | `controller_num_write_iops` | IOPS | direct |
| **Disk Read BW** | `controllerReadIoBandwidthKbps` | `controller_read_io_bandwidth_kBps` | KB/s | ÷ 1024 for MB/s |
| **Disk Write BW** | `controllerWriteIoBandwidthKbps` | `controller_write_io_bandwidth_kBps` | KB/s | ÷ 1024 for MB/s |
| **Disk Latency** | `controllerAvgIoLatencyMicros` | `controller_avg_io_latency_usecs` | µs | direct |
| **Net RX bytes** | `hypervisorNumReceivedBytes` | `hypervisor_num_received_bytes` | bytes/30s | ÷ 30 for bytes/s |
| **Net TX bytes** | `hypervisorNumTransmittedBytes` | `hypervisor_num_transmitted_bytes` | bytes/30s | ÷ 30 for bytes/s |

> **Note:** `hypervisorMemoryUsagePpm` always returns 1,000,000 (100%) — this is a known bug on pc.7.3.1.3. Use `memoryUsagePpm` instead.

---

## Test Cases

### Setup

```bash
export PC_IP="10.8.23.7"
export PC_PORT="9440"
export PC_USER="Admin"
export PC_PASS="<your-password>"
export ZABBIX_API="http://<zabbix-host>/api_jsonrpc.php"
export ZABBIX_TOKEN="<zabbix-api-token>"
```

---

### ZBX-T01 · VM Inventory Discovery

**Goal:** Fetch full VM list and confirm all fields needed for Zabbix host creation are present.

**API:** `GET /api/vmm/v4.0/ahv/config/vms?$page=0&$limit=100`

```bash
curl -k -s \
  -u "$PC_USER:$PC_PASS" \
  -H "Accept: application/json" \
  "https://$PC_IP:$PC_PORT/api/vmm/v4.0/ahv/config/vms?\$page=0&\$limit=100" \
  | python3 -c "
import json, sys
d = json.load(sys.stdin)
vms = d['data']
print(f'Total VMs: {len(vms)}')
print()
print(f'{\"Name\":<40} {\"Power\":<5} {\"vCPU\":>5} {\"RAM GB\":>7} {\"extId\"}')
print('-' * 100)
for v in vms:
    cpu = v['numSockets'] * v['numCoresPerSocket']
    ram = round(v['memorySizeBytes'] / (1024**3), 1)
    print(f'{v[\"name\"]:<40} {v[\"powerState\"]:<5} {cpu:>5} {ram:>7} {v[\"extId\"]}')
"
```

**Acceptance Criteria:**
- [ ] `name`, `extId`, `powerState`, `numSockets`, `numCoresPerSocket`, `memorySizeBytes` all present on every VM
- [ ] No VM has a missing `extId` (used as unique key in Zabbix)
- [ ] All 48 VMs returned in single page (`$limit=100`)

---

### ZBX-T02 · Bulk Live Stats (v3/groups)

**Goal:** Confirm a single POST call returns live metrics for all VMs — this is the poll call Zabbix will run every 60s.

```bash
curl -k -s \
  -u "$PC_USER:$PC_PASS" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -X POST \
  -d '{
    "entity_type": "vm",
    "group_member_count": 100,
    "group_member_sort_attribute": "vm_name",
    "group_member_sort_order": "ASCENDING",
    "group_member_attributes": [
      {"attribute": "vm_name"},
      {"attribute": "hypervisor_cpu_usage_ppm"},
      {"attribute": "memory_usage_ppm"},
      {"attribute": "controller_num_read_iops"},
      {"attribute": "controller_num_write_iops"},
      {"attribute": "controller_read_io_bandwidth_kBps"},
      {"attribute": "controller_write_io_bandwidth_kBps"},
      {"attribute": "controller_avg_io_latency_usecs"},
      {"attribute": "hypervisor_num_received_bytes"},
      {"attribute": "hypervisor_num_transmitted_bytes"}
    ],
    "filter_criteria": "power_state==on"
  }' \
  "https://$PC_IP:$PC_PORT/api/nutanix/v3/groups" \
  | python3 -c "
import json, sys
d = json.load(sys.stdin)

def val(data, key):
    for a in data:
        if a.get('name') == key:
            v = a.get('values', [])
            return v[0].get('values', [''])[0] if v else ''
    return ''

entities = d['group_results'][0]['entity_results']
print(f'VMs with stats: {len(entities)}')
print()
print(f'{\"Name\":<40} {\"CPU%\":>6} {\"Mem%\":>6} {\"R-IOPS\":>7} {\"W-IOPS\":>7} {\"Lat-µs\":>8} {\"RX-KB/s\":>9} {\"TX-KB/s\":>9}')
print('-' * 105)
rows = []
for e in entities:
    dd = e['data']
    name  = val(dd, 'vm_name')
    cpu   = int(val(dd, 'hypervisor_cpu_usage_ppm') or 0) / 10000
    mem   = int(val(dd, 'memory_usage_ppm') or 0) / 10000
    riops = val(dd, 'controller_num_read_iops') or '0'
    wiops = val(dd, 'controller_num_write_iops') or '0'
    lat   = val(dd, 'controller_avg_io_latency_usecs') or '0'
    rx    = round(int(val(dd, 'hypervisor_num_received_bytes') or 0) / 30 / 1024, 1)
    tx    = round(int(val(dd, 'hypervisor_num_transmitted_bytes') or 0) / 30 / 1024, 1)
    rows.append((name, cpu, mem, riops, wiops, lat, rx, tx))

for r in sorted(rows, key=lambda x: x[1], reverse=True):
    print(f'{r[0]:<40} {r[1]:>6.2f} {r[2]:>6.2f} {r[3]:>7} {r[4]:>7} {r[5]:>8} {r[6]:>9} {r[7]:>9}')
"
```

**Acceptance Criteria:**
- [ ] HTTP 200
- [ ] All ON VMs returned (expect ~47)
- [ ] `hypervisor_cpu_usage_ppm` has values (not all 0 or empty)
- [ ] `memory_usage_ppm` has values
- [ ] `controller_avg_io_latency_usecs` present (key for disk health alerting)
- [ ] Network RX/TX bytes present for at least 1 VM

---

### ZBX-T03 · Poll Frequency — Rate Limit Check

**Goal:** Confirm that polling at 60s intervals with 2 API calls does not trigger rate limiting.

```bash
python3 -c "
import urllib.request, urllib.error, base64, json, time, ssl

PC = '10.8.23.7:9440'
USER = 'Admin'
PASS = '<your-password>'

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

creds = base64.b64encode(f'{USER}:{PASS}'.encode()).decode()
headers = {'Authorization': f'Basic {creds}', 'Accept': 'application/json'}

def call_config():
    req = urllib.request.Request(
        f'https://{PC}/api/vmm/v4.0/ahv/config/vms?\$limit=1',
        headers=headers
    )
    with urllib.request.urlopen(req, context=ctx, timeout=10) as r:
        return r.status

# Fire 10 consecutive requests — should all return 200
print('Firing 10 requests...')
for i in range(10):
    status = call_config()
    print(f'  Request {i+1}: HTTP {status}')
    time.sleep(0.1)   # 100ms gap = 10 req/sec — well under limit
print('Done. All should be 200.')
"
```

**Acceptance Criteria:**
- [ ] All 10 requests return HTTP 200
- [ ] No `429 Too Many Requests` at 10 req/sec
- [ ] Confirms safe to poll every 60s with 2 calls/cycle

---

### ZBX-T04 · Single VM Deep Stats (v4.1)

**Goal:** Confirm per-VM time-series stats from `vmm/v4.1` return all 9 monitoring fields for one VM. This is used for drill-down dashboards, not the main poll.

```bash
VM_ID="c90699b2-ec53-4800-93e7-4cf23024b75e"  # autoad
START=$(python3 -c "from datetime import datetime,timezone,timedelta; print((datetime.now(timezone.utc)-timedelta(minutes=10)).strftime('%Y-%m-%dT%H:%M:%SZ'))")
END=$(python3 -c "from datetime import datetime,timezone; print(datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'))")

curl -k -s \
  -u "$PC_USER:$PC_PASS" \
  -H "Accept: application/json" \
  "https://$PC_IP:$PC_PORT/api/vmm/v4.1/ahv/stats/vms/$VM_ID?\$startTime=$START&\$endTime=$END&\$samplingInterval=30&\$statType=SUM&\$select=*" \
  | python3 -c "
import json, sys
d = json.load(sys.stdin)
stats = d['data']['stats']
print(f'Stat samples: {len(stats)}')
for s in reversed(stats):
    if 'hypervisorCpuUsagePpm' not in s:
        continue
    print(f'Timestamp:    {s[\"timestamp\"]}')
    print(f'CPU %:        {round(s[\"hypervisorCpuUsagePpm\"]/10000, 2)}')
    print(f'Memory %:     {round(s[\"memoryUsagePpm\"]/10000, 2)}')
    print(f'R-IOPS:       {s.get(\"controllerNumReadIops\", 0)}')
    print(f'W-IOPS:       {s.get(\"controllerNumWriteIops\", 0)}')
    print(f'R-BW KB/s:    {s.get(\"controllerReadIoBandwidthKbps\", 0)}')
    print(f'W-BW KB/s:    {s.get(\"controllerWriteIoBandwidthKbps\", 0)}')
    print(f'Latency µs:   {s.get(\"controllerAvgIoLatencyMicros\", 0)}')
    print(f'Net RX bytes: {s.get(\"hypervisorNumReceivedBytes\", 0)}')
    print(f'Net TX bytes: {s.get(\"hypervisorNumTransmittedBytes\", 0)}')
    break
"
```

**Acceptance Criteria:**
- [ ] HTTP 200
- [ ] At least 1 sample with `hypervisorCpuUsagePpm` present
- [ ] All 9 target fields present in the same sample
- [ ] `memoryUsagePpm` returns a value < 1,000,000 (confirm not the broken `hypervisorMemoryUsagePpm`)

---

### ZBX-T05 · Alert Threshold Validation

**Goal:** Confirm metrics are numeric and within alertable ranges. Tests that the values Zabbix will receive are usable for threshold triggers.

```bash
python3 -c "
import urllib.request, urllib.error, base64, json, ssl

PC = '10.8.23.7:9440'
USER = 'Admin'
PASS = '<your-password>'

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

creds = base64.b64encode(f'{USER}:{PASS}'.encode()).decode()
body = json.dumps({
    'entity_type': 'vm',
    'group_member_count': 100,
    'group_member_attributes': [
        {'attribute': 'vm_name'},
        {'attribute': 'hypervisor_cpu_usage_ppm'},
        {'attribute': 'memory_usage_ppm'},
        {'attribute': 'controller_avg_io_latency_usecs'},
    ],
    'filter_criteria': 'power_state==on'
}).encode()

req = urllib.request.Request(
    f'https://{PC}/api/nutanix/v3/groups',
    data=body,
    headers={
        'Authorization': f'Basic {creds}',
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    },
    method='POST'
)

with urllib.request.urlopen(req, context=ctx, timeout=15) as r:
    d = json.load(r)

def val(data, key):
    for a in data:
        if a.get('name') == key:
            v = a.get('values', [])
            return v[0].get('values', [''])[0] if v else None
    return None

entities = d['group_results'][0]['entity_results']
alerts = []

THRESHOLDS = {
    'CPU > 80%':    lambda v: int(v or 0) / 10000 > 80,
    'Mem > 85%':    lambda v: int(v or 0) / 10000 > 85,
    'Lat > 20ms':   lambda v: int(v or 0) > 20000,
}

for e in entities:
    dd = e['data']
    name = val(dd, 'vm_name')
    cpu  = val(dd, 'hypervisor_cpu_usage_ppm')
    mem  = val(dd, 'memory_usage_ppm')
    lat  = val(dd, 'controller_avg_io_latency_usecs')

    if THRESHOLDS['CPU > 80%'](cpu):
        alerts.append(f'  ⚠️  {name}: CPU = {int(cpu)/10000:.1f}%')
    if THRESHOLDS['Mem > 85%'](mem):
        alerts.append(f'  ⚠️  {name}: Mem = {int(mem)/10000:.1f}%')
    if THRESHOLDS['Lat > 20ms'](lat):
        alerts.append(f'  ⚠️  {name}: Disk latency = {int(lat)/1000:.1f} ms')

print(f'VMs checked: {len(entities)}')
print(f'Alerts fired: {len(alerts)}')
for a in alerts:
    print(a)
if not alerts:
    print('  ✅ All VMs within normal thresholds')
"
```

**Acceptance Criteria:**
- [ ] Script runs without exception
- [ ] All CPU% values are 0.00–100.00 (not negative, not > 100)
- [ ] All Mem% values are 0.00–100.00
- [ ] Latency values are numeric (µs, not formatted strings)
- [ ] Alert list is non-empty if any VM is under load (validates threshold logic)

---

### ZBX-T06 · Pagination — More Than 100 VMs

**Goal:** Confirm pagination works when VM count exceeds the $limit=100 page size. Run this when cluster grows beyond 100 VMs.

```bash
python3 -c "
import urllib.request, base64, json, ssl

PC = '10.8.23.7:9440'
USER = 'Admin'
PASS = '<your-password>'

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

creds = base64.b64encode(f'{USER}:{PASS}'.encode()).decode()
headers = {'Authorization': f'Basic {creds}', 'Accept': 'application/json'}

all_vms = []
page = 0
while True:
    url = f'https://{PC}/api/vmm/v4.0/ahv/config/vms?\$page={page}&\$limit=100'
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, context=ctx, timeout=10) as r:
        d = json.load(r)
    batch = d['data']
    all_vms.extend(batch)
    print(f'  Page {page}: {len(batch)} VMs (total so far: {len(all_vms)})')
    if len(batch) < 100:
        break
    page += 1

print(f'Total VMs across all pages: {len(all_vms)}')
names = {v['extId'] for v in all_vms}
print(f'Unique extIds: {len(names)} (should equal total)')
"
```

**Acceptance Criteria:**
- [ ] Script exits cleanly on page with < 100 results
- [ ] Total count matches VM count from T01
- [ ] No duplicate `extId` values across pages

---

## Zabbix Integration Design

### Option A — External Script (Recommended)

Place `nutanix_vm_monitor.py` in `/usr/lib/zabbix/externalscripts/`.

**Zabbix item config:**
- **Type:** External check
- **Key:** `nutanix_vm_stats.py[{HOST.HOST},{$METRIC}]`
- **Update interval:** 60s

**Script interface:**
```
nutanix_vm_stats.py <vm_extId> <metric>
```
Where `<metric>` is one of: `cpu_pct`, `mem_pct`, `read_iops`, `write_iops`, `read_bw_kbps`, `write_bw_kbps`, `latency_us`, `net_rx_kbps`, `net_tx_kbps`

The script caches the bulk v3/groups response in `/tmp/nutanix_stats_cache.json` with a 55s TTL, so all 9 items per VM share a single API call per cycle.

### Option B — HTTP Agent (Native Zabbix)

Use Zabbix Low-Level Discovery with JSONPath preprocessing.

**Discovery rule URL:**
```
https://10.8.23.7:9440/api/vmm/v4.0/ahv/config/vms?$page=0&$limit=100
```

**LLD JSONPath macro extraction:**
```
{#VM_NAME}  → $.data[*].name
{#VM_ID}    → $.data[*].extId
```

**Limitation:** Each per-VM stat item needs a separate HTTP call to v4.1 (1 call per VM per interval). With 48 VMs × 60s = 48 HTTP checks/min — borderline for rate limits. Use the v3/groups POST approach if stat items are needed natively.

---

## Recommended Zabbix Triggers

| Trigger | Condition | Severity |
|---------|-----------|----------|
| High CPU | CPU% > 80% for 5 min | Warning |
| Critical CPU | CPU% > 95% for 2 min | High |
| High Memory | Mem% > 85% for 5 min | Warning |
| Critical Memory | Mem% > 95% | High |
| High Disk Latency | Latency > 20ms avg | Warning |
| Critical Disk Latency | Latency > 50ms avg | High |
| High Write IOPS | Write IOPS > 500 sustained | Info |
| VM Powered Off | `powerState` = OFF (unexpected) | Average |
| PC API Down | HTTP check fails | Disaster |

---

## Test Results Summary

| # | Test | Status | Notes |
|---|------|:------:|-------|
| ZBX-T01 | VM Inventory Discovery | — | Run to confirm all fields present |
| ZBX-T02 | Bulk Live Stats (v3/groups) | — | Core poll call for Zabbix |
| ZBX-T03 | Rate Limit Check | — | 10 req/10s — confirm no 429 |
| ZBX-T04 | Single VM Deep Stats (v4.1) | — | Drill-down / dashboard use |
| ZBX-T05 | Alert Threshold Validation | — | Confirm values are alertable |
| ZBX-T06 | Pagination (>100 VMs) | — | Run when cluster grows |

---

## Gotchas

| Issue | Cause | Fix |
|-------|-------|-----|
| `hypervisorMemoryUsagePpm` always 100% | Known bug on pc.7.3.1.3 | Use `memoryUsagePpm` or `memory_usage_ppm` |
| v3/groups returns 51 VMs but config shows 48 | CVMs included in groups response | Filter by `power_state==on` and skip VMs with `NTNX-*-CVM` in name |
| Stats 400 on v4.1 | Missing `$startTime` / `$endTime` | Always include both; use last 5–10 minutes |
| No data after PC restart | Stats cache warm-up takes ~2 min | Add 120s retry backoff on empty stats response |
| `$select` named fields → VMM-30102 | Bug in `vmm/v4.0` on this PC version | Use `vmm/v4.1` + `$select=*` only |
| SSL self-signed cert | Lab PC uses self-signed TLS | Add `-k` / `verify=False` / `ssl.CERT_NONE` |
| Network bytes are per-interval | `hypervisorNumReceivedBytes` resets each 30s sample | Divide by 30 for bytes/s, or by 30×1024 for KB/s |

---

## Sources

- [Zabbix Nutanix Integration](https://www.zabbix.com/integrations/nutanix) — official templates (Prism Element only, no per-VM stats natively)
- [Nutanix API User Guide](https://www.nutanix.dev/nutanix-api-user-guide/) — rate limits by PC size
- [Zabbix HTTP Agent Docs](https://www.zabbix.com/documentation/current/en/manual/config/items/itemtypes/http) — HTTP item config, auth, JSONPath
- Lab results from previous test sessions — `result-test/nutanix-api-v4-test-report.md`
