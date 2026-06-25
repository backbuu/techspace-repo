# Nutanix API v4 — Live VM Stats Research

**Date:** 2026-06-25  
**PC Version:** pc.7.3.1.3  
**Working API:** `vmm/v4.1` with `$select=*`  
**Fallback:** `POST /api/nutanix/v3/groups` (if v4.1 unavailable)

---

## Discovery: Which Version Works for Stats?

| API Version | Config (VMs) | Stats Endpoint |
|-------------|:------------:|:--------------:|
| `vmm/v4.0` | ✅ 200 | ❌ VMM-30102 |
| `vmm/v4.0.b1` | ✅ 200 | ❌ VMM-30102 |
| `vmm/v4.1` | ✅ 200 | ✅ **Works with `$select=*`** |

**Root cause of VMM-30102:** The stats endpoint requires `$select` but rejects named field values like `hypervisorCpuUsagePpm`. The wildcard `$select=*` is the only working form on pc.7.3.1.3.

---

## Working v4.1 Stats Endpoint

```
GET /api/vmm/v4.1/ahv/stats/vms/{extId}
```

### Required parameters

| Parameter | Required | Value |
|-----------|:--------:|-------|
| `$startTime` | ✅ | ISO 8601 UTC e.g. `2026-06-25T04:00:00Z` |
| `$endTime` | ✅ | ISO 8601 UTC |
| `$samplingInterval` | ✅ | Seconds — `30` (minimum confirmed) |
| `$statType` | ✅ | `SUM` or `AVG` |
| `$select` | ✅ | Must be `*` — named fields return VMM-30102 |

### Working curl

```bash
START=$(date -u -v-5M +"%Y-%m-%dT%H:%M:%SZ")   # macOS
END=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

curl -k -u "Admin:<password>" \
  -H "Accept: application/json" \
  "https://{pc_ip}:9440/api/vmm/v4.1/ahv/stats/vms/{extId}?\$startTime=${START}&\$endTime=${END}&\$samplingInterval=30&\$statType=SUM&\$select=*"
```

### Response structure

Returns a `stats` array — each element is a `VmStatsTuple` at a 30s timestamp. The first tuple contains cluster/hypervisor metadata; subsequent tuples contain live metrics.

```json
{
  "data": {
    "extId": "...",
    "stats": [
      {
        "$objectType": "vmm.v4.ahv.stats.VmStatsTuple",
        "timestamp": "2026-06-25T04:05:30Z",
        "hypervisorCpuUsagePpm": 2675,
        "memoryUsagePpm": 399650,
        "controllerNumReadIops": 0,
        "controllerNumWriteIops": 1,
        "controllerReadIoBandwidthKbps": 5,
        "controllerWriteIoBandwidthKbps": 7,
        "controllerAvgIoLatencyMicros": 345,
        "guestMemoryUsagePpm": 419760,
        "hypervisorNumReceivedBytes": 22409,
        "hypervisorNumTransmittedBytes": 27259,
        "..."
      }
    ]
  }
}
```

### All available stat fields (confirmed on pc.7.3.1.3)

**CPU & Memory**
| Field | Unit | Convert |
|-------|------|---------|
| `hypervisorCpuUsagePpm` | ppm | ÷ 10,000 = % |
| `hypervisorCpuReadyTimePpm` | ppm | ÷ 10,000 = % |
| `numVcpusUsedPpm` | ppm | ÷ 10,000 = % of total vCPU |
| `memoryUsagePpm` | ppm | ÷ 10,000 = % |
| `guestMemoryUsagePpm` | ppm | ÷ 10,000 = % |
| `hypervisorMemoryUsagePpm` | ppm | ÷ 10,000 = % |
| `memoryReservedBytes` | bytes | ÷ 1,073,741,824 = GB |

**Storage I/O (Controller)**
| Field | Unit |
|-------|------|
| `controllerNumIops` | IOPS total |
| `controllerNumReadIops` | IOPS read |
| `controllerNumWriteIops` | IOPS write |
| `controllerNumIo` | I/O count |
| `controllerNumReadIo` | I/O read count |
| `controllerNumWriteIo` | I/O write count |
| `controllerIoBandwidthKbps` | KB/s total |
| `controllerReadIoBandwidthKbps` | KB/s read |
| `controllerWriteIoBandwidthKbps` | KB/s write |
| `controllerAvgIoLatencyMicros` | µs |
| `controllerAvgReadIoLatencyMicros` | µs |
| `controllerAvgWriteIoLatencyMicros` | µs |
| `controllerAvgReadIoSizeKb` | KB |
| `controllerAvgWriteIoSizeKb` | KB |
| `controllerReadIoPpm` | ppm (read ratio) |
| `controllerWriteIoPpm` | ppm (write ratio) |
| `controllerTotalIoSizeKb` | KB |
| `controllerTotalReadIoSizeKb` | KB |
| `controllerTotalIoTimeMicros` | µs |
| `controllerTotalReadIoTimeMicros` | µs |
| `controllerUserBytes` | bytes (used storage) |
| `controllerTimespanMicros` | µs (sample window) |

**Working Set Size (WSS)**
| Field | Unit |
|-------|------|
| `controllerWss120SecondUnionMb` | MB (2-min WSS) |
| `controllerWss120SecondReadMb` | MB |
| `controllerWss120SecondWriteMb` | MB |
| `controllerWss3600SecondUnionMb` | MB (1-hr WSS) |
| `controllerWss3600SecondReadMb` | MB |
| `controllerWss3600SecondWriteMb` | MB |

**Storage Tier**
| Field | Unit |
|-------|------|
| `controllerStorageTierSsdUsageBytes` | bytes |

**Network**
| Field | Unit |
|-------|------|
| `hypervisorNumReceivedBytes` | bytes (per 30s interval) |
| `hypervisorNumTransmittedBytes` | bytes (per 30s interval) |
| `hypervisorNumReceivePacketsDropped` | count |
| `hypervisorNumTransmitPacketsDropped` | count |
| `hypervisorIoBandwidthKbps` | KB/s |

**Hypervisor I/O (pass-through)**
| Field | Unit |
|-------|------|
| `hypervisorNumIops` | IOPS |
| `hypervisorNumReadIops` | IOPS |
| `hypervisorNumWriteIops` | IOPS |
| `hypervisorAvgIoLatencyMicros` | µs |
| `hypervisorTimespanMicros` | µs |

---

## Live Stats — 47 VMs (2026-06-25 04:11 UTC, sorted by CPU)

| Name | CPU% | Mem% | R-IOPS | W-IOPS | R-KB/s | W-KB/s | Lat-µs |
|------|-----:|-----:|-------:|-------:|-------:|-------:|-------:|
| workload02-md-0-lf85r-rrnvt-52bng | 29.35 | 24.39 | 50 | 8 | 11700 | 107 | 1530 |
| nkp-h9xdk-z9f65 | 25.64 | 39.73 | 0 | 113 | 1 | 1111 | 18200 |
| nkp-md-0-shhzl-xwtkh-6j9s5 | 24.96 | 29.99 | 0 | 12 | 0 | 117 | 17011 |
| otest-1 | 21.74 | 67.48 | 0 | 33 | 0 | 209 | 576 |
| nkp-h9xdk-7cp6s | 21.20 | 41.02 | 0 | 105 | 0 | 880 | 15494 |
| workload01-md-0-d5fmv-2bm4f-fd4dw | 21.02 | 20.73 | 0 | 7 | 2 | 61 | 616 |
| ocp | 17.96 | 62.40 | 0 | 37 | 0 | 204 | 572 |
| workload01-md-0-d5fmv-2bm4f-ks2dz | 17.77 | 24.52 | 0 | 2 | 0 | 28 | 415 |
| workload02-md-0-lf85r-rrnvt-cf6sc | 17.75 | 22.40 | 0 | 7 | 0 | 148 | 716 |
| ocp7 | 17.25 | 49.10 | 0 | 36 | 0 | 202 | 625 |
| nkp-h9xdk-hr2gq | 14.72 | 38.52 | 0 | 107 | 0 | 841 | 19222 |
| workload02-9b8mg-p55sx | 14.61 | 31.68 | 0 | 67 | 0 | 492 | 19675 |
| pc | 14.41 | 31.45 | 0 | 0 | 0 | 0 | 0 |
| otest-6 | 14.11 | 36.63 | 0 | 31 | 0 | 153 | 2731 |
| otest-4 | 12.59 | 45.06 | 0 | 31 | 0 | 154 | 563 |
| nkp-md-0-shhzl-xwtkh-m9bhm | 12.45 | 32.11 | 0 | 9 | 0 | 557 | 25764 |
| workload01-49k7r-48j9q | 12.42 | 30.94 | 0 | 59 | 0 | 477 | 22276 |
| ocp2 | 12.35 | 30.39 | 0 | 1 | 0 | 88 | 1379 |
| otest-3 | 12.12 | 31.97 | 0 | 2 | 0 | 96 | 1060 |
| otest-2 | 11.36 | 31.35 | 0 | 1 | 0 | 91 | 1056 |
| ocp4 | 10.45 | 28.29 | 0 | 1 | 0 | 144 | 2159 |
| ocp6 | 10.43 | 37.03 | 0 | 37 | 0 | 198 | 869 |
| NTNX-files-1 | 10.42 | 63.76 | 0 | 7 | 0 | 87 | 23907 |
| workload02-9b8mg-swgtf | 9.52 | 21.05 | 0 | 66 | 0 | 398 | 3367 |
| objects-477294-default-0 | 9.36 | 35.23 | 0 | 46 | 0 | 558 | 22983 |
| workload02-9b8mg-tc5fl | 8.58 | 23.53 | 0 | 68 | 0 | 428 | 608 |
| workload01-49k7r-v75xd | 8.17 | 24.76 | 0 | 61 | 0 | 369 | 2326 |
| workload01-49k7r-5j262 | 8.13 | 24.06 | 0 | 61 | 0 | 391 | 565 |
| nkp-md-0-shhzl-xwtkh-gxrgm | 6.73 | 21.91 | 0 | 14 | 0 | 196 | 16076 |
| workload02-md-0-lf85r-rrnvt-bxnt6 | 5.73 | 20.64 | 0 | 4 | 0 | 34 | 636 |
| workload02-md-0-lf85r-rrnvt-s6m8p | 4.34 | 19.44 | 0 | 4 | 0 | 38 | 652 |
| nkp-md-0-shhzl-xwtkh-brk8x | 4.12 | 15.81 | 0 | 7 | 0 | 66 | 52816 |
| ocp5 | 4.06 | 14.01 | 0 | 0 | 0 | 6 | 685 |
| workload01-md-0-d5fmv-2bm4f-949gg | 3.89 | 19.71 | 0 | 7 | 0 | 66 | 602 |
| workload01-md-0-d5fmv-2bm4f-wv7cn | 3.75 | 18.87 | 0 | 4 | 0 | 38 | 464 |
| otest-5 | 3.31 | 14.13 | 0 | 2 | 0 | 8 | 488 |
| nkp-md-0-shhzl-xwtkh-rfr78 | 1.90 | 20.21 | 0 | 2 | 0 | 15 | 573 |
| objects-477294-xpwugkdmpu-envoy-0 | 1.87 | 38.52 | 0 | 0 | 0 | 2 | 58851 |
| nkp-md-0-shhzl-xwtkh-dkzbx | 1.84 | 13.59 | 0 | 1 | 0 | 8 | 483 |
| ocp3 | 1.83 | 17.62 | 0 | 1 | 0 | 6 | 526 |
| vmtestrep-2 | 1.50 | 15.64 | 0 | 0 | 0 | 2 | 825 |
| vmtestrep-3 | 1.43 | 15.54 | 0 | 0 | 0 | 1 | 1007 |
| auto_DND_calm_policy_engine_… | 0.74 | 39.64 | 0 | 2 | 0 | 10 | 466 |
| autoad | 0.52 | 40.39 | 1 | 3 | 16 | 33 | 15393 |
| ocp-boot- | 0.33 | 9.85 | 0 | 9 | 0 | 44 | 668 |
| nkp-boot | 0.26 | 11.59 | 0 | 6 | 0 | 31 | 8219 |
| vmtestrep-1 | 0.23 | 28.71 | 0 | 0 | 0 | 2 | 323 |

Raw JSON: `vm-stats-v4-raw.json`

---

## Fallback: v3 Groups API

If the PC version does not support `vmm/v4.1`, fall back to:

```bash
curl -k -u "Admin:<password>" \
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
      {"attribute": "controller_write_io_bandwidth_kBps"}
    ],
    "filter_criteria": "power_state==on"
  }' \
  "https://{pc_ip}:9440/api/nutanix/v3/groups"
```

Returns the latest real-time value for each stat per VM — no time window needed.

---

## Gotchas

| Issue | Detail |
|-------|--------|
| `$select=hypervisorCpuUsagePpm` → VMM-30102 | Named field selection broken on pc.7.3.1.3; use `$select=*` |
| `$select` omitted → VMM-30102 | Parameter is required even if wildcard |
| `vmm/v4.0` stats → always VMM-30102 | Only `vmm/v4.1` supports `$select=*` on this PC version |
| Stats array has metadata tuples | First tuple has `$objectType` + cluster info, no metrics — skip it |
| `hypervisorMemoryUsagePpm` always 1,000,000 | That's 100% — this is a hypervisor-reserved field; use `memoryUsagePpm` or `guestMemoryUsagePpm` for real guest RAM usage |
| Network bytes are per-interval, not cumulative | `hypervisorNumReceivedBytes` resets each 30s sample |
| Minimum `$samplingInterval` | 30 seconds confirmed; values below may fail |
