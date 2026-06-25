# Nutanix API v4 — Live Test Results

**Environment:** Prism Central `10.8.23.7:9440`  
**Tested:** 2026-06-25  
**API Version:** `vmm/v4.0`  
**Auth:** HTTP Basic (Admin)

---

## Test 1: Connectivity

```bash
curl -k -s -o /dev/null -w "%{http_code}" \
  -u "Admin:<password>" \
  -H "Accept: application/json" \
  "https://10.8.23.7:9440/api/vmm/v4.0/ahv/config/vms?$limit=1"
```

**Result:** `200 OK` ✅

---

## Test 2: List VMs

```bash
curl -k -s \
  -u "Admin:<password>" \
  -H "Accept: application/json" \
  "https://10.8.23.7:9440/api/vmm/v4.0/ahv/config/vms?$page=0&$limit=100"
```

**Result:** ✅ 48 VMs returned

### Cluster Summary

| Metric | Value |
|--------|-------|
| Total VMs | 48 |
| Power ON | 47 |
| Power OFF | 1 |
| Total vCPU | 263 |
| Total RAM | 988 GB |

### VM Inventory

| Name | Power | Sockets | Cores | RAM (GB) | extId |
|------|-------|---------|-------|----------|-------|
| autoad | ON | 2 | 1 | 4.0 | c90699b2-ec53-4800-93e7-4cf23024b75e |
| pc | ON | 24 | 1 | 92.0 | 9ee6e3a5-60fe-47dd-9308-7bcaeb8d621f |
| LinuxTools | OFF | 6 | 1 | 10.0 | 5e7ec121-b3d0-42c1-bd7e-b70c18e50df0 |
| objects-477294-default-0 | ON | 5 | 2 | 32.0 | 645f896a-0695-4204-a882-a12011cb9745 |
| objects-477294-xpwugkdmpu-envoy-0 | ON | 1 | 2 | 4.0 | aea211bf-f8ec-477f-9e4a-9b11b9718abf |
| NTNX-files-1 | ON | 4 | 1 | 12.0 | bc5a6930-2fa9-4918-b9e9-58104e516a25 |
| nkp-boot | ON | 4 | 1 | 8.0 | acd8d2b5-9134-4ee7-acc8-f63d2580a8cd |
| nkp-h9xdk-hr2gq | ON | 4 | 1 | 16.0 | 7e6de5ae-1b41-429b-6c5d-b7dde79197ac |
| nkp-md-0-shhzl-xwtkh-6j9s5 | ON | 8 | 1 | 32.0 | da0422d7-03e2-4625-7e6c-bd75db154785 |
| nkp-md-0-shhzl-xwtkh-gxrgm | ON | 8 | 1 | 32.0 | 27ae5f67-c484-45ac-64f8-60ba15ef24f1 |
| nkp-md-0-shhzl-xwtkh-m9bhm | ON | 8 | 1 | 32.0 | e65fa554-cc81-4053-51a5-bb42f2271cbc |
| nkp-md-0-shhzl-xwtkh-brk8x | ON | 8 | 1 | 32.0 | 99a934ba-c578-4ff0-6f2d-c4aa5433443a |
| nkp-h9xdk-7cp6s | ON | 4 | 1 | 16.0 | 48e742f9-bfc3-4101-763e-04a367bcdb5d |
| nkp-h9xdk-z9f65 | ON | 4 | 1 | 16.0 | fc897a19-ca29-4f4e-48cb-974288482872 |
| workload01-49k7r-48j9q | ON | 4 | 1 | 16.0 | 0662fff5-ac11-494b-54a6-40f62634d8db |
| workload02-9b8mg-p55sx | ON | 4 | 1 | 16.0 | 95bdede5-2001-448a-4b6c-74b3e9175056 |
| workload01-md-0-d5fmv-2bm4f-ks2dz | ON | 8 | 1 | 32.0 | a7a61309-4ec4-4130-7d12-6be2023ed8ce |
| workload01-md-0-d5fmv-2bm4f-949gg | ON | 8 | 1 | 32.0 | a13a3b14-0b45-426e-5325-d76a372f77e0 |
| workload01-md-0-d5fmv-2bm4f-wv7cn | ON | 8 | 1 | 32.0 | 0e013aa0-f9c9-4005-7c1d-fb3a2bcc402f |
| workload01-md-0-d5fmv-2bm4f-fd4dw | ON | 8 | 1 | 32.0 | 16619077-1383-4294-5ae5-0e163f9b96bc |
| workload02-md-0-lf85r-rrnvt-s6m8p | ON | 8 | 1 | 32.0 | ba20d56f-0e25-48ac-415e-6c52c9a3e482 |
| workload02-md-0-lf85r-rrnvt-52bng | ON | 8 | 1 | 32.0 | f3341aff-f77a-4460-6dfb-031e6b5a3ff7 |
| workload02-md-0-lf85r-rrnvt-cf6sc | ON | 8 | 1 | 32.0 | d4f2eaed-1b68-4ac9-5d89-dcf3083705ff |
| workload02-md-0-lf85r-rrnvt-bxnt6 | ON | 8 | 1 | 32.0 | 23a0e363-7694-495d-67a9-276fa18af18f |
| workload01-49k7r-5j262 | ON | 4 | 1 | 16.0 | 2e38c7a1-328b-4cff-5194-9d992375d164 |
| workload02-9b8mg-tc5fl | ON | 4 | 1 | 16.0 | f8bf8d67-3cb0-45be-4cbe-02a0567e7e48 |
| workload02-9b8mg-swgtf | ON | 4 | 1 | 16.0 | 83dff01b-fa3b-4f9f-45f5-e373d69de963 |
| workload01-49k7r-v75xd | ON | 4 | 1 | 16.0 | 87bfcdbc-4c59-458d-76ef-97d4f300e6a9 |
| auto_DND_calm_policy_engine_… | ON | 2 | 2 | 6.0 | 28a5bea3-8eb7-4e9b-9c0a-270a6b3b0972 |
| ocp | ON | 4 | 1 | 16.0 | 6538b7ca-9664-481c-7ee9-6d419ce6a639 |
| ocp2 | ON | 4 | 1 | 16.0 | 4568435c-e9ad-4309-6fea-46d3d2b3604c |
| ocp3 | ON | 4 | 1 | 16.0 | ac6273bb-6b37-4055-4212-0f409291a849 |
| ocp4 | ON | 4 | 1 | 16.0 | f754cab2-d453-4d80-7a2f-222600defa11 |
| ocp5 | ON | 4 | 1 | 16.0 | 27067292-88be-4c58-4e8e-94c880827784 |
| ocp6 | ON | 4 | 1 | 16.0 | fc238f62-e912-49c5-6617-5e3bba563e76 |
| ocp7 | ON | 4 | 1 | 16.0 | 6fcd1d85-7326-48d8-798d-c8e093bdd2f4 |
| ocp-boot- | ON | 4 | 1 | 8.0 | 04eb5ed3-844f-4a85-55f7-b76397495a80 |
| nkp-md-0-shhzl-xwtkh-dkzbx | ON | 8 | 1 | 32.0 | 41fa1918-b869-4252-4348-2d1603fe57b3 |
| nkp-md-0-shhzl-xwtkh-rfr78 | ON | 8 | 1 | 32.0 | eceb88cd-b1c4-4de3-4e4d-59d1c229e5ec |
| otest-3 | ON | 4 | 1 | 16.0 | e3be2948-201c-47c9-6ed7-db129f46da56 |
| otest-1 | ON | 4 | 1 | 16.0 | f18ddc4f-104a-48d2-5dde-9aa26e0e0f43 |
| otest-2 | ON | 4 | 1 | 16.0 | 7ea6b4d1-6e3b-4299-69ff-3b584ba09213 |
| otest-4 | ON | 4 | 1 | 16.0 | 28bd7ba2-7259-4264-65c7-206d1605ef00 |
| otest-6 | ON | 4 | 1 | 16.0 | 94b769e7-3c0f-49f2-76d9-628905c7450b |
| otest-5 | ON | 4 | 1 | 16.0 | 564cee7d-aa96-4c04-4633-58a1e9b9e6ca |
| vmtestrep-3 | ON | 1 | 1 | 4.0 | 4e10ba52-9747-4787-6dac-2e378af6dd3c |
| vmtestrep-2 | ON | 1 | 1 | 4.0 | 62700959-cce8-448b-7003-cf21a013e1ea |
| vmtestrep-1 | ON | 1 | 1 | 4.0 | 476f714e-e569-4f08-4ae7-46f997d2788e |

Raw response saved to: `vms-raw.json`

---

## Test 3: Get VM by extId

```bash
curl -k -s \
  -u "Admin:<password>" \
  -H "Accept: application/json" \
  "https://10.8.23.7:9440/api/vmm/v4.0/ahv/config/vms/c90699b2-ec53-4800-93e7-4cf23024b75e"
```

**Result:** ✅ Full VM object returned

### Example VM Detail — `autoad`

| Field | Value |
|-------|-------|
| `extId` | `c90699b2-ec53-4800-93e7-4cf23024b75e` |
| `name` | autoad |
| `powerState` | ON |
| `numSockets` | 2 |
| `numCoresPerSocket` | 1 |
| `memorySizeBytes` | 4,294,967,296 (4 GB) |
| `createTime` | 2026-06-12T10:03:18Z |
| `updateTime` | 2026-06-23T08:19:44Z |
| NICs | 1 × NORMAL_NIC |
| Disks | 1 × 50 GB (VmDisk) |

Raw response saved to: `vm-detail-autoad.json`

---

## Confirmed API Behaviour

- **Auth:** HTTP Basic works — `Authorization: Basic <base64>` or `-u user:pass` in curl
- **SSL:** Self-signed cert on lab PC — use `-k` flag
- **Pagination:** `$page=0&$limit=100` works; max 100 per page confirmed
- **Response envelope:** `{ "data": [...], "$reserved": {...} }` for list; `{ "data": {...} }` for single
- **Object type field:** `"$objectType": "vmm.v4.ahv.config.Vm"` on each VM
- **API version marker:** `"$fv": "v4.r1"` inside `$reserved` on each object

---

## Next Steps

- [ ] Test power operations (power-on / power-off) on a safe test VM
- [ ] Test OData filter: `$filter=powerState eq 'OFF'`
- [ ] Test `$select` to fetch only specific fields
- [ ] Test pagination loop across all VMs
- [ ] Draft article section: "Calling VM Information with Nutanix API v4"
