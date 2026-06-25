# Solution Summary: Nutanix API v4 — Projects Related to VPC

Tested on PC `7.3.1.3` / AOS `7.3` on 2026-06-25. This document summarises the correct API calls, findings, and the working solution for retrieving Projects and their VPC relationships using Nutanix API v4.

---

## Problem

Two questions to answer via API:
1. **Which VPCs exist on this Prism Central?**
2. **Which Projects are linked to a VPC, and what is the relationship?**

---

## Environment

| Component | Version |
|-----------|---------|
| Prism Central | `pc.7.3.1.3` (`el8.5-release-ganges-7.3.1.3`) |
| AOS (RNO-POC012) | `7.3` |
| AOS (DR) | `7.3` |
| PC Node Count | 1 (single-node) |
| Storage | All-Flash / X86_64 |

---

## API Version Findings

Not all v4 namespaces are available on every PC build. Results from probing this environment:

| Namespace & Version | Available | Notes |
|--------------------|-----------|-------|
| `networking/v4.0.a1` | ❌ 404 | Documented in older guides — does not work |
| `networking/v4.0.b1` | ✅ 200 | Earliest working version |
| `networking/v4.0` | ✅ 200 | Recommended — stable alias |
| `networking/v4.1` | ✅ 200 | Also available |
| `iam/v4.0` (projects) | ❌ 404 | Not yet available on PC 7.3.1.3 |
| `iam/v4.1` (projects) | ❌ 404 | Not yet available on PC 7.3.1.3 |
| `v3` API | ✅ | Fully available — use for Projects |

**Key finding:** Use `networking/v4.0` for VPCs. Use the v3 API for Projects — the v4 IAM projects endpoint is not yet GA on PC 7.3.1.3.

---

## Solution: 2-Call Workflow

Getting Projects related to a VPC requires two API calls — one to each namespace — then joining on the VPC `extId`.

```
Step 1: GET /api/networking/v4.0/config/vpcs
        → returns VPC list with extId per VPC

Step 2: POST /api/nutanix/v3/projects/list
        → returns projects, each with vpc_reference_list[]

Join:   project.vpc_reference_list[].uuid == vpc.extId
```

---

## Step 1 — List VPCs

**Endpoint:** `GET /api/networking/v4.0/config/vpcs`

```bash
curl -sk -u "{username}:{password}" \
  "https://{pc_ip}:9440/api/networking/v4.0/config/vpcs?\$limit=100" \
  | python3 -m json.tool
```

**Result on this environment — 1 VPC found:**

| Field | Value |
|-------|-------|
| Name | `VPN-for-Test` |
| extId | `71f5d1e9-e7eb-4d2d-a3cb-d371d4f8310b` |
| Type | `REGULAR` (NAT VPC) |
| SNAT IPs | `10.8.23.23`, `10.8.23.24` |
| DNS | `1.1.1.1` |
| Gateway nodes | `10.8.23.25` (active), `10.8.23.26` (active) — HA pair |
| External subnet | `f4c742b3-5ee8-421e-b069-0aa2bdbda2ad` |

---

## Step 2 — List Projects

**Endpoint:** `POST /api/nutanix/v3/projects/list`

```bash
curl -sk -u "{username}:{password}" \
  -X POST "https://{pc_ip}:9440/api/nutanix/v3/projects/list" \
  -H "Content-Type: application/json" \
  -d '{"kind": "project", "length": 100, "offset": 0}' \
  | python3 -m json.tool
```

**Result on this environment — 2 Projects found:**

| Project | UUID | VPC Linked | State |
|---------|------|-----------|-------|
| `Project-VPC` | `e15d97b2-1b6b-43b3-829c-fa94f433a7a0` | `VPN-for-Test` ✅ | COMPLETE |
| `NTNX` | `e68b227a-8358-43cf-8697-8028e337b299` | none | COMPLETE |

---

## Step 3 — Relationship Map

Join `vpc_reference_list[].uuid` (from Projects v3) with `extId` (from VPCs v4):

```
VPN-for-Test  (networking/v4.0)
extId: 71f5d1e9-e7eb-4d2d-a3cb-d371d4f8310b
  │
  └── Project-VPC  (v3/projects)
        uuid    : e15d97b2-1b6b-43b3-829c-fa94f433a7a0
        subnets : overlay-49, secodary-for-vpc-49
        default : secodary-for-vpc-49
        users   : adminuser02@ntnxlab.local
        cluster : 0006540b-48a3-ade0-50cf-3cecef82a4d9 (RNO-POC012)

NTNX  (v3/projects)
  uuid    : e68b227a-8358-43cf-8697-8028e337b299
  vpc     : none (flat VLAN subnets only)
  subnets : primary, secondary
  groups  : CN=SSP Admins,CN=Users,DC=ntnxlab,DC=local
  cluster : 0006540b-48a3-ade0-50cf-3cecef82a4d9 (RNO-POC012)
```

---

## Working Python Script

Runs both calls, joins the data, and prints the relationship map.

```bash
pip install ntnx-networking-py-client requests urllib3
```

```python
"""
Nutanix API v4 — Projects related to VPC
PC 7.3.1.3 / AOS 7.3 — tested 2026-06-25
"""

import requests
import urllib3
import ntnx_networking_py_client as networking

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

PC_IP    = "{pc_ip}"
PORT     = 9440
USERNAME = "{username}"
PASSWORD = "{password}"
BASE_URL = f"https://{PC_IP}:{PORT}"
AUTH     = (USERNAME, PASSWORD)


def get_vpcs():
    config = networking.Configuration()
    config.host, config.port = PC_IP, PORT
    config.username, config.password = USERNAME, PASSWORD
    config.verify_ssl = False

    api  = networking.VpcsApi(api_client=networking.ApiClient(configuration=config))
    resp = api.list_vpcs(_page=0, _limit=100)
    return {v.ext_id: v for v in (resp.data or [])}


def get_projects():
    r = requests.post(
        f"{BASE_URL}/api/nutanix/v3/projects/list",
        auth=AUTH, verify=False,
        json={"kind": "project", "length": 100, "offset": 0}
    )
    r.raise_for_status()
    return r.json().get("entities", [])


def print_vpc_project_map(vpcs, projects):
    print("── VPC ↔ Project Map ──────────────────────────────────")
    for project in projects:
        res      = project["status"]["resources"]
        name     = project["status"]["name"]
        uuid     = project["metadata"]["uuid"]
        vpc_refs = res.get("vpc_reference_list", [])
        subnets  = [s["name"] for s in res.get("subnet_reference_list", [])]
        users    = [u["name"] for u in res.get("user_reference_list", [])]
        groups   = [g["name"] for g in res.get("external_user_group_reference_list", [])]

        if vpc_refs:
            for ref in vpc_refs:
                vpc = vpcs.get(ref["uuid"])
                vpc_name = vpc.name if vpc else ref["uuid"]
                print(f"\n  VPC: {vpc_name}  →  Project: {name}")
                print(f"    project uuid : {uuid}")
                print(f"    subnets      : {subnets}")
                print(f"    users        : {users or 'none'}")
                print(f"    groups       : {groups or 'none'}")
        else:
            print(f"\n  Project: {name}  (no VPC)")
            print(f"    project uuid : {uuid}")
            print(f"    subnets      : {subnets}")
            print(f"    groups       : {groups or 'none'}")


if __name__ == "__main__":
    print("Fetching VPCs...")
    vpcs = get_vpcs()
    print(f"  {len(vpcs)} VPC(s) found\n")

    print("Fetching Projects...")
    projects = get_projects()
    print(f"  {len(projects)} Project(s) found\n")

    print_vpc_project_map(vpcs, projects)
```

---

## Key Takeaways

| Finding | Detail |
|---------|--------|
| **Correct VPC endpoint** | `networking/v4.0` — `v4.0.a1` returns 404 on PC 7.3.1.3 |
| **Projects via v4 IAM** | Not available on PC 7.3.1.3 — all IAM v4 versions return 404 |
| **Projects via v3** | Fully working — use `POST /api/nutanix/v3/projects/list` |
| **Join key** | `project.status.resources.vpc_reference_list[].uuid` == `vpc.extId` |
| **VPCs found** | 1 — `VPN-for-Test` (REGULAR/NAT) |
| **Projects found** | 2 — `Project-VPC` (linked to VPC), `NTNX` (no VPC) |
| **Always probe first** | API version availability varies per PC build — never hardcode |
