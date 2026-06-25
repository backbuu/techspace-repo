# Nutanix API v4 — Test Procedure

**Environment:** Prism Central `10.8.23.7:9440`  
**Auth:** HTTP Basic — `Admin` / `<password>`  
**Prerequisites:** `curl`, `python3` available on test machine

> Set env vars before running any test:
> ```bash
> export PC_IP="10.8.23.7"
> export PC_PORT="9440"
> export PC_USER="Admin"
> export PC_PASS="<your-password>"
> ```

---

## T-01 · Connectivity Check

**Goal:** Confirm API is reachable and auth works.

```bash
curl -k -s -o /dev/null -w "%{http_code}" \
  -u "$PC_USER:$PC_PASS" \
  -H "Accept: application/json" \
  "https://$PC_IP:$PC_PORT/api/vmm/v4.0/ahv/config/vms?\$limit=1"
```

**Expected:** `200`  
**Result:** ✅ `200`

---

## T-02 · List All VMs

**Goal:** Retrieve full VM inventory via `vmm/v4.0`.

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

**Goal:** Fetch full detail for a single VM.

```bash
# Pick an extId from T-02 results
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
print(f'Name:    {vm[\"name\"]}')
print(f'Power:   {vm[\"powerState\"]}')
print(f'Sockets: {vm[\"numSockets\"]}')
print(f'RAM GB:  {vm[\"memorySizeBytes\"] // (1024**3)}')
print(f'Disks:   {len(vm.get(\"disks\",[]))}')
print(f'NICs:    {len(vm.get(\"nics\",[]))}')
"
```

**Expected:** All fields populated, no error key in response  
**Result:** ✅ Full object returned — autoad: 2 sockets, 4 GB RAM, 1 disk, 1 NIC

---

## T-04 · Live Stats — vmm/v4.0 (expected fail)

**Goal:** Confirm `vmm/v4.0` stats endpoint fails on pc.7.3.1.3.

```bash
START=$(python3 -c "from datetime import datetime,timezone,timedelta; print((datetime.now(timezone.utc)-timedelta(minutes=5)).strftime('%Y-%m-%dT%H:%M:%SZ'))")
END=$(python3 -c "from datetime import datetime,timezone; print(datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'))")
VM_ID="c90699b2-ec53-4800-93e7-4cf23024b75e"

curl -k -s \
  -u "$PC_USER:$PC_PASS" \
  -H "Accept: application/json" \
  "https://$PC_IP:$PC_PORT/api/vmm/v4.0/ahv/stats/vms/$VM_ID?\$startTime=$START&\$endTime=$END&\$samplingInterval=30&\$statType=SUM&\$select=hypervisorCpuUsagePpm"
```

**Expected:** `VMM-30102` error — `invalid argument with key '$select'`  
**Result:** ❌ FAIL (as expected) — error code `VMM-30102` confirmed

---

## T-05 · Live Stats — vmm/v4.0.b1 (expected fail)

**Goal:** Confirm `vmm/v4.0.b1` has the same issue.

```bash
curl -k -s \
  -u "$PC_USER:$PC_PASS" \
  -H "Accept: application/json" \
  "https://$PC_IP:$PC_PORT/api/vmm/v4.0.b1/ahv/stats/vms/$VM_ID?\$startTime=$START&\$endTime=$END&\$samplingInterval=30&\$statType=SUM&\$select=hypervisorCpuUsagePpm"
```

**Expected:** Same `VMM-30102`  
**Result:** ❌ FAIL (as expected)

---

## T-06 · Live Stats — vmm/v4.1 with `$select=*`

**Goal:** Confirm `vmm/v4.1` returns live stats using the wildcard selector.

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
# Find the most recent sample with real metrics
for s in reversed(stats):
    if 'hypervisorCpuUsagePpm' in s:
        cpu  = round(s['hypervisorCpuUsagePpm']/10000, 2)
        mem  = round(s['memoryUsagePpm']/10000, 2)
        riops = s.get('controllerNumReadIops', 0)
        wiops = s.get('controllerNumWriteIops', 0)
        lat   = s.get('controllerAvgIoLatencyMicros', 0)
        print(f'Timestamp: {s[\"timestamp\"]}')
        print(f'CPU:       {cpu}%')
        print(f'Memory:    {mem}%')
        print(f'Read IOPS: {riops}')
        print(f'Write IOPS:{wiops}')
        print(f'Latency:   {lat} µs')
        print(f'Stat keys: {len(s)} fields')
        break
"
```

**Expected:** HTTP 200, `stats` array with 30s samples, `hypervisorCpuUsagePpm` present  
**Result:** ✅ PASS — 9 samples returned, 40+ fields per sample

---

## T-07 · Live Stats — v3/groups Fallback

**Goal:** Validate that the v3/groups endpoint returns live stats for all VMs as a fallback.

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
print()
print(f'{\"Name\":<38} {\"CPU%\":>6} {\"Mem%\":>6} {\"W-IOPS\":>7}')
print('-'*62)
rows = []
for e in entities:
    dd = e['data']
    name = get_val(dd,'vm_name')
    cpu = get_val(dd,'hypervisor_cpu_usage_ppm')
    mem = get_val(dd,'memory_usage_ppm')
    wiops = get_val(dd,'controller_num_write_iops')
    rows.append((name, round(int(cpu)/10000,2) if cpu else 0, round(int(mem)/10000,2) if mem else 0, wiops or '0'))

for r in sorted(rows, key=lambda x: x[1], reverse=True)[:10]:
    print(f'{r[0]:<38} {r[1]:>6.2f} {r[2]:>6.2f} {r[3]:>7}')
print('... (top 10 shown)')
"
```

**Expected:** HTTP 200, VM list with real-time stat values per VM  
**Result:** ✅ PASS — 51 VMs returned with live CPU%, Mem%, IOPS, bandwidth

---

## Test Result Summary

| Test | Description | Expected | Result |
|------|-------------|----------|--------|
| T-01 | Connectivity | HTTP 200 | ✅ PASS |
| T-02 | List VMs | ≥ 1 VM returned | ✅ PASS |
| T-03 | Get VM by extId | Full VM object | ✅ PASS |
| T-04 | Stats v4.0 named $select | VMM-30102 error | ✅ PASS (confirmed fail) |
| T-05 | Stats v4.0.b1 named $select | VMM-30102 error | ✅ PASS (confirmed fail) |
| T-06 | Stats v4.1 `$select=*` | 30s time-series data | ✅ PASS |
| T-07 | Stats v3/groups fallback | Real-time stats all VMs | ✅ PASS |

**7/7 tests completed · 5/7 positive outcomes · 2 expected-fail behaviours confirmed**

---

## Gotchas to Watch For

| Symptom | Cause | Fix |
|---------|-------|-----|
| `VMM-30102` on stats | Named `$select` broken in `vmm/v4.0` and `v4.0.b1` | Use `vmm/v4.1` with `$select=*` |
| Stats array missing metric fields | First tuple is metadata-only | Loop backwards until `hypervisorCpuUsagePpm` is present |
| `memoryUsagePpm` shows 100% | Using `hypervisorMemoryUsagePpm` by mistake | Use `memoryUsagePpm` or `guestMemoryUsagePpm` |
| SSL error | PC uses self-signed cert | Add `-k` flag to all curl commands |
| Fewer VMs than expected | `$limit` defaults to 25 | Always set `$limit=100` and paginate with `$page` |
| Stats endpoint returns 400 | Missing `$startTime` or `$endTime` | Both are required — always include a time window |
