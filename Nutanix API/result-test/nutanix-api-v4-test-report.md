# Nutanix API v4 — Test Report

**Environment:** Prism Central `10.8.23.7:9440` · Version `pc.7.3.1.3`  
**Tested:** 2026-06-25  
**Tester:** backbuu

---

## Summary

| # | Test | API | Status | Notes |
|---|------|-----|:------:|-------|
| T-01 | Connectivity check | `vmm/v4.0` | ✅ PASS | HTTP 200 |
| T-02 | List all VMs | `vmm/v4.0` | ✅ PASS | 48 VMs returned |
| T-03 | Get VM by extId | `vmm/v4.0` | ✅ PASS | Full object returned |
| T-04 | Live stats — v4.0 named `$select` | `vmm/v4.0` | ❌ FAIL | VMM-30102: `$select` broken |
| T-05 | Live stats — v4.0.b1 named `$select` | `vmm/v4.0.b1` | ❌ FAIL | Same VMM-30102 error |
| T-06 | Live stats — v4.1 `$select=*` | `vmm/v4.1` | ✅ PASS | 47 VMs, 40+ stat fields |
| T-07 | Live stats fallback | `v3/groups` | ✅ PASS | 51 VMs, all stat fields |

**7/7 tests completed · 5/7 positive outcomes · 2 expected-fail behaviours confirmed**

The 2 failures share the same root cause — named `$select` fields on `vmm/v4.0` and `v4.0.b1` are broken on pc.7.3.1.3. Resolved by using `vmm/v4.1` with `$select=*`.

---

## Cluster Snapshot

| Metric | Value |
|--------|-------|
| Total VMs | 48 |
| Power ON | 47 |
| Power OFF | 1 (`LinuxTools`) |
| Total vCPU | 263 |
| Total RAM allocated | 988 GB |

### Top Consumers at Test Time

| Metric | VM | Value |
|--------|----|-------|
| Highest CPU | workload02-md-0-lf85r-rrnvt-52bng | 29.35% |
| Highest Memory | otest-1 | 67.48% |
| Highest Write IOPS | nkp-h9xdk-z9f65 | 113 |
| Highest Read BW | workload02-md-0-lf85r-rrnvt-52bng | 11,700 KB/s |
| Highest Latency | objects-477294-xpwugkdmpu-envoy-0 | 58,851 µs |

---

## Key Findings

1. **Use `vmm/v4.1` for stats** — `vmm/v4.0` and `v4.0.b1` return `VMM-30102` on pc.7.3.1.3
2. **`$select=*` is the only working selector** — named fields always fail
3. **v3/groups is a reliable fallback** — works on all PC versions, no time window required
4. **Stats are 30s time-series** — always specify `$startTime` and `$endTime`
5. **Use `memoryUsagePpm` not `hypervisorMemoryUsagePpm`** — the hypervisor field always reads 100%

---

## Prerequisites

```bash
export PC_IP="10.8.23.7"
export PC_PORT="9440"
export PC_USER="Admin"
export PC_PASS="<your-password>"
```

Requirements: `curl`, `python3`

---

## T-01 · Connectivity Check

```bash
curl -k -s -o /dev/null -w "%{http_code}" \
  -u "$PC_USER:$PC_PASS" \
  -H "Accept: application/json" \
  "https://$PC_IP:$PC_PORT/api/vmm/v4.0/ahv/config/vms?\$limit=1"
```

**Expected:** `200` · **Result:** ✅ `200`

---

## T-02 · List All VMs

```bash
curl -k -s \
  -u "$PC_USER:$PC_PASS" \
  -H "Accept: application/json" \
  "https://$PC_IP:$PC_PORT/api/vmm/v4.0/ahv/config/vms?\$page=0&\$limit=100" \
  | python3 -m json.tool > results-vm-list.json
```

**Validate:**
```bash
python3 -c "
import json
with open('results-vm-list.json') as f: d=json.load(f)
vms = d['data']
print(f'VMs returned: {len(vms)}')
print(f'First VM: {vms[0][\"name\"]} | {vms[0][\"powerState\"]}')
"
```

**Expected:** VM count > 0, `powerState` is `ON` or `OFF`  
**Result:** ✅ 48 VMs returned

---

## T-03 · Get VM by extId

```bash
VM_ID="c90699b2-ec53-4800-93e7-4cf23024b75e"   # autoad

curl -k -s \
  -u "$PC_USER:$PC_PASS" \
  -H "Accept: application/json" \
  "https://$PC_IP:$PC_PORT/api/vmm/v4.0/ahv/config/vms/$VM_ID" \
  | python3 -m json.tool > results-vm-detail.json
```

**Validate:**
```bash
python3 -c "
import json
with open('results-vm-detail.json') as f: d=json.load(f)
vm = d['data']
print(f'Name:   {vm[\"name\"]}')
print(f'Power:  {vm[\"powerState\"]}')
print(f'CPU:    {vm[\"numSockets\"]} sockets x {vm[\"numCoresPerSocket\"]} cores')
print(f'RAM:    {vm[\"memorySizeBytes\"] // (1024**3)} GB')
print(f'Disks:  {len(vm.get(\"disks\",[]))}')
print(f'NICs:   {len(vm.get(\"nics\",[]))}')
"
```

**Expected:** Full object, no error key  
**Result:** ✅ autoad — 2 sockets, 4 GB RAM, 1 disk, 1 NIC

---

## T-04 · Live Stats — vmm/v4.0 (expected fail)

```bash
START=$(python3 -c "from datetime import datetime,timezone,timedelta; print((datetime.now(timezone.utc)-timedelta(minutes=5)).strftime('%Y-%m-%dT%H:%M:%SZ'))")
END=$(python3 -c "from datetime import datetime,timezone; print(datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'))")
VM_ID="c90699b2-ec53-4800-93e7-4cf23024b75e"

curl -k -s \
  -u "$PC_USER:$PC_PASS" \
  -H "Accept: application/json" \
  "https://$PC_IP:$PC_PORT/api/vmm/v4.0/ahv/stats/vms/$VM_ID?\$startTime=$START&\$endTime=$END&\$samplingInterval=30&\$statType=SUM&\$select=hypervisorCpuUsagePpm"
```

**Expected:** `VMM-30102` — `invalid argument with key '$select'`  
**Result:** ❌ FAIL (confirmed) — `VMM-30102`

---

## T-05 · Live Stats — vmm/v4.0.b1 (expected fail)

```bash
curl -k -s \
  -u "$PC_USER:$PC_PASS" \
  -H "Accept: application/json" \
  "https://$PC_IP:$PC_PORT/api/vmm/v4.0.b1/ahv/stats/vms/$VM_ID?\$startTime=$START&\$endTime=$END&\$samplingInterval=30&\$statType=SUM&\$select=hypervisorCpuUsagePpm"
```

**Expected:** `VMM-30102`  
**Result:** ❌ FAIL (confirmed)

---

## T-06 · Live Stats — vmm/v4.1 with `$select=*`

```bash
START=$(python3 -c "from datetime import datetime,timezone,timedelta; print((datetime.now(timezone.utc)-timedelta(minutes=5)).strftime('%Y-%m-%dT%H:%M:%SZ'))")
END=$(python3 -c "from datetime import datetime,timezone; print(datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'))")
VM_ID="c90699b2-ec53-4800-93e7-4cf23024b75e"

curl -k -s \
  -u "$PC_USER:$PC_PASS" \
  -H "Accept: application/json" \
  "https://$PC_IP:$PC_PORT/api/vmm/v4.1/ahv/stats/vms/$VM_ID?\$startTime=$START&\$endTime=$END&\$samplingInterval=30&\$statType=SUM&\$select=*" \
  | python3 -m json.tool > results-vm-stats-v4.json
```

**Validate:**
```bash
python3 -c "
import json
with open('results-vm-stats-v4.json') as f: d=json.load(f)
stats = d['data']['stats']
for s in reversed(stats):
    if 'hypervisorCpuUsagePpm' in s:
        print(f'Timestamp:  {s[\"timestamp\"]}')
        print(f'CPU:        {round(s[\"hypervisorCpuUsagePpm\"]/10000, 2)}%')
        print(f'Memory:     {round(s[\"memoryUsagePpm\"]/10000, 2)}%')
        print(f'Read IOPS:  {s.get(\"controllerNumReadIops\", 0)}')
        print(f'Write IOPS: {s.get(\"controllerNumWriteIops\", 0)}')
        print(f'Latency:    {s.get(\"controllerAvgIoLatencyMicros\", 0)} µs')
        print(f'Fields:     {len(s)}')
        break
"
```

**Expected:** HTTP 200, `stats` array, `hypervisorCpuUsagePpm` present  
**Result:** ✅ PASS — 9 samples, 40+ fields each

---

## T-07 · Live Stats — v3/groups Fallback

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
      {"attribute": "controller_avg_io_latency_usecs"}
    ],
    "filter_criteria": "power_state==on"
  }' \
  "https://$PC_IP:$PC_PORT/api/nutanix/v3/groups" \
  | python3 -m json.tool > results-vm-stats-v3.json
```

**Validate:**
```bash
python3 -c "
import json
with open('results-vm-stats-v3.json') as f: d=json.load(f)
def get_val(data, name):
    for a in data:
        if a.get('name') == name:
            v = a.get('values', [])
            return v[0].get('values', [''])[0] if v else ''
    return ''
entities = d['group_results'][0]['entity_results']
print(f'VMs returned: {len(entities)}')
rows = []
for e in entities:
    dd = e['data']
    name = get_val(dd,'vm_name')
    cpu  = get_val(dd,'hypervisor_cpu_usage_ppm')
    mem  = get_val(dd,'memory_usage_ppm')
    rows.append((name, round(int(cpu)/10000,2) if cpu else 0, round(int(mem)/10000,2) if mem else 0))
for r in sorted(rows, key=lambda x: x[1], reverse=True)[:5]:
    print(f'{r[0]:<40} CPU={r[1]}%  Mem={r[2]}%')
"
```

**Expected:** HTTP 200, live stats per VM  
**Result:** ✅ PASS — 51 VMs, real-time CPU%, Mem%, IOPS, bandwidth

---

## Gotchas

| Symptom | Cause | Fix |
|---------|-------|-----|
| `VMM-30102` on stats | Named `$select` broken on `vmm/v4.0` / `v4.0.b1` | Use `vmm/v4.1` with `$select=*` |
| Stats array has no metrics | First tuple is metadata-only | Iterate reversed until `hypervisorCpuUsagePpm` is present |
| Memory always 100% | Using `hypervisorMemoryUsagePpm` | Use `memoryUsagePpm` or `guestMemoryUsagePpm` |
| SSL error | Self-signed cert on lab PC | Add `-k` to all curl commands |
| Fewer VMs than expected | `$limit` defaults to 25 | Set `$limit=100`, paginate with `$page` |
| Stats 400 error | Missing `$startTime` / `$endTime` | Both required — always set a time window |
