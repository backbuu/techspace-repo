# Nutanix VM Live Stats

**Captured:** 2026-06-25 03:59 UTC  
**Environment:** Prism Central 10.8.23.7:9440  
**API:** `POST /api/nutanix/v3/groups` (stats via Prism v3 groups endpoint)  
**VMs:** 51 ON

> **Note on API v4 stats:** `GET /api/vmm/v4.0/ahv/stats/vms/{extId}` requires `$startTime`, `$endTime`, and `$select` — but `$select` fails with `VMM-30102` on this PC version. Live stats fetched via the v3 groups API instead, which returns real-time metrics in a single call.

---

## Live Stats — Sorted by CPU Usage

| Name | CPU% | Mem% | R-IOPS | W-IOPS | R-MB/s | W-MB/s |
|------|-----:|-----:|-------:|-------:|-------:|-------:|
| nkp-h9xdk-7cp6s | 45.71 | 48.42 | 57 | 159 | 0.24 | 1.31 |
| workload02-9b8mg-p55sx | 37.33 | 34.95 | 171 | 63 | 10.62 | 0.62 |
| nkp-h9xdk-z9f65 | 29.70 | 44.29 | 0 | 158 | 0.00 | 1.47 |
| otest-1 | 26.31 | 68.64 | 0 | 33 | 0.00 | 0.20 |
| nkp-md-0-shhzl-xwtkh-6j9s5 | 22.62 | 29.97 | 0 | 17 | 0.00 | 0.15 |
| ocp7 | 20.06 | 49.01 | 0 | 34 | 0.00 | 0.18 |
| ocp | 19.71 | 62.00 | 0 | 33 | 0.00 | 0.20 |
| NTNX-RNO-POC012-3-CVM | 19.16 | 66.97 | 0 | 0 | 0.00 | 0.00 |
| workload01-md-0-d5fmv-2bm4f-fd4dw | 18.04 | 23.20 | 0 | 7 | 0.17 | 0.33 |
| workload02-md-0-lf85r-rrnvt-52bng | 17.72 | 23.84 | 0 | 5 | 0.00 | 0.04 |
| workload01-md-0-d5fmv-2bm4f-ks2dz | 17.71 | 23.98 | 10 | 3 | 0.17 | 0.18 |
| workload02-md-0-lf85r-rrnvt-cf6sc | 17.29 | 21.83 | 0 | 6 | 0.00 | 0.05 |
| NTNX-RNO-POC012-1-CVM | 17.03 | 59.81 | 0 | 0 | 0.00 | 0.00 |
| workload01-md-0-d5fmv-2bm4f-wv7cn | 16.02 | 21.82 | 0 | 5 | 0.00 | 0.31 |
| NTNX-RNO-POC012-4-CVM | 14.95 | 54.73 | 0 | 0 | 0.00 | 0.00 |
| otest-6 | 14.59 | 37.37 | 0 | 31 | 0.00 | 0.16 |
| otest-4 | 14.32 | 45.47 | 0 | 32 | 0.00 | 0.17 |
| workload01-49k7r-48j9q | 13.88 | 31.79 | 0 | 63 | 0.00 | 0.42 |
| NTNX-RNO-POC012-2-CVM | 13.84 | 63.08 | 0 | 0 | 0.00 | 0.00 |
| nkp-md-0-shhzl-xwtkh-m9bhm | 13.71 | 32.15 | 0 | 10 | 0.00 | 0.11 |
| ocp6 | 13.38 | 37.68 | 0 | 35 | 0.00 | 0.29 |
| pc | 13.33 | 31.60 | 0 | 0 | 0.00 | 0.00 |
| NTNX-files-1 | 12.33 | 63.83 | 0 | 8 | 0.00 | 0.07 |
| nkp-h9xdk-hr2gq | 11.82 | 38.24 | 0 | 161 | 0.00 | 1.11 |
| otest-3 | 11.77 | 32.03 | 0 | 1 | 0.00 | 0.10 |
| ocp2 | 11.74 | 30.56 | 0 | 1 | 0.00 | 0.08 |
| otest-2 | 11.57 | 31.33 | 0 | 1 | 0.00 | 0.09 |
| ocp4 | 10.97 | 28.07 | 0 | 1 | 0.00 | 0.11 |
| workload02-9b8mg-tc5fl | 8.19 | 23.55 | 0 | 63 | 0.00 | 0.39 |
| workload01-49k7r-5j262 | 8.17 | 24.25 | 0 | 61 | 0.00 | 0.39 |
| workload02-9b8mg-swgtf | 7.43 | 22.30 | 0 | 63 | 0.00 | 0.37 |
| objects-477294-default-0 | 7.25 | 35.60 | 0 | 45 | 0.00 | 0.56 |
| nkp-md-0-shhzl-xwtkh-gxrgm | 6.65 | 21.77 | 0 | 15 | 0.00 | 0.17 |
| workload01-49k7r-v75xd | 6.37 | 26.04 | 0 | 62 | 0.00 | 0.37 |
| workload02-md-0-lf85r-rrnvt-bxnt6 | 5.98 | 20.99 | 0 | 3 | 0.00 | 0.03 |
| nkp-md-0-shhzl-xwtkh-rfr78 | 5.38 | 20.25 | 0 | 1 | 0.00 | 0.01 |
| nkp-md-0-shhzl-xwtkh-brk8x | 4.42 | 15.69 | 0 | 8 | 0.00 | 0.07 |
| ocp3 | 4.34 | 17.67 | 0 | 0 | 0.00 | 0.00 |
| workload02-md-0-lf85r-rrnvt-s6m8p | 4.20 | 19.44 | 0 | 4 | 0.00 | 0.04 |
| ocp5 | 3.82 | 13.97 | 0 | 0 | 0.00 | 0.01 |
| workload01-md-0-d5fmv-2bm4f-949gg | 3.69 | 19.77 | 0 | 4 | 0.00 | 0.05 |
| otest-5 | 3.55 | 14.16 | 0 | 1 | 0.00 | 0.01 |
| nkp-md-0-shhzl-xwtkh-dkzbx | 1.90 | 13.54 | 0 | 0 | 0.00 | 0.01 |
| objects-477294-xpwugkdmpu-envoy-0 | 1.63 | 38.52 | 0 | 0 | 0.00 | 0.00 |
| vmtestrep-2 | 1.56 | 15.63 | 0 | 0 | 0.00 | 0.00 |
| vmtestrep-3 | 1.46 | 15.55 | 0 | 0 | 0.00 | 0.00 |
| auto_DND_calm_policy_engine_… | 0.57 | 39.66 | 0 | 0 | 0.00 | 0.00 |
| vmtestrep-1 | 0.34 | 29.21 | 0 | 0 | 0.00 | 0.00 |
| nkp-boot | 0.28 | 11.75 | 0 | 8 | 0.00 | 0.04 |
| ocp-boot- | 0.26 | 9.98 | 0 | 6 | 0.00 | 0.03 |
| autoad | 0.25 | 39.96 | 0 | 1 | 0.00 | 0.01 |

---

## Top Consumers

| Category | VM | Value |
|----------|-----|-------|
| Highest CPU | nkp-h9xdk-7cp6s | 45.71% |
| Highest Memory | otest-1 | 68.64% |
| Highest Read IOPS | workload02-9b8mg-p55sx | 171 |
| Highest Write IOPS | nkp-h9xdk-7cp6s | 159 |
| Highest Read BW | workload02-9b8mg-p55sx | 10.62 MB/s |
| Highest Write BW | nkp-h9xdk-z9f65 | 1.47 MB/s |

---

## API Method Used

The v4 stats endpoint (`/api/vmm/v4.0/ahv/stats/vms/{extId}`) returned error `VMM-30102` on this PC version — `$select` parameter not accepted. Used the Prism v3 groups API instead:

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
  "https://10.8.23.7:9440/api/nutanix/v3/groups"
```

**Stat fields available via v3/groups:**

| Field | Unit |
|-------|------|
| `hypervisor_cpu_usage_ppm` | ppm → divide by 10,000 for % |
| `memory_usage_ppm` | ppm → divide by 10,000 for % |
| `controller_num_read_iops` | IOPS |
| `controller_num_write_iops` | IOPS |
| `controller_read_io_bandwidth_kBps` | KB/s → divide by 1,024 for MB/s |
| `controller_write_io_bandwidth_kBps` | KB/s → divide by 1,024 for MB/s |
| `hypervisor_num_transmitted_bytes` | bytes |
| `hypervisor_num_received_bytes` | bytes |
