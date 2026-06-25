# Nutanix API v4 — Test Results

**Environment:** Prism Central `10.8.23.7:9440` · Version `pc.7.3.1.3`  
**Tested:** 2026-06-25  
**Tester:** backbuu

---

## Files in This Folder

| File | Description |
|------|-------------|
| `README.md` | This summary |
| `test-steps.md` | Step-by-step test procedure with curl commands |
| `results-vm-list.json` | Raw API response — List VMs |
| `results-vm-detail.json` | Raw API response — Get VM by extId |
| `results-vm-stats-v4.json` | Raw API response — Live stats (vmm/v4.1) |
| `results-vm-stats-v3.json` | Raw API response — Live stats (v3/groups fallback) |

---

## Summary

### Tests Executed

| # | Test | API | Status | Notes |
|---|------|-----|:------:|-------|
| T-01 | Connectivity check | `vmm/v4.0` | ✅ PASS | HTTP 200 |
| T-02 | List all VMs | `vmm/v4.0` | ✅ PASS | 48 VMs returned |
| T-03 | Get VM by extId | `vmm/v4.0` | ✅ PASS | Full object returned |
| T-04 | Live stats — v4.0 | `vmm/v4.0` | ❌ FAIL | VMM-30102: `$select` broken |
| T-05 | Live stats — v4.0.b1 | `vmm/v4.0.b1` | ❌ FAIL | Same VMM-30102 error |
| T-06 | Live stats — v4.1 `$select=*` | `vmm/v4.1` | ✅ PASS | 47 VMs, 40+ stat fields |
| T-07 | Live stats fallback | `v3/groups` | ✅ PASS | 51 VMs, all stat fields |

**5/7 tests passed.** The 2 failures are the same root cause — named `$select` fields on `vmm/v4.0` are broken on pc.7.3.1.3.

---

### Cluster Snapshot (captured 2026-06-25)

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

### Key Findings

1. **Use `vmm/v4.1` for stats** — `vmm/v4.0` and `v4.0.b1` stats endpoint returns `VMM-30102` on pc.7.3.1.3
2. **`$select=*` is the only working selector** — named fields (e.g. `hypervisorCpuUsagePpm`) always fail
3. **v3/groups is a reliable fallback** — works on all PC versions, returns real-time stats in one call
4. **Stats are time-series at 30s granularity** — not instantaneous; always specify a window (`$startTime`/`$endTime`)
5. **`hypervisorMemoryUsagePpm` is always 1,000,000** — use `memoryUsagePpm` or `guestMemoryUsagePpm` instead
