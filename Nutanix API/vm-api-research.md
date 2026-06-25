# Nutanix API v4 — VM Operations Research Notes

> Status: Phase 1 research. Verified against nutanix.dev docs (June 2026).

---

## 1. Namespace & Base URL

The VM management API lives in the **vmm** namespace.

```
https://{prism_central_ip}:9440/api/vmm/v4.0/ahv/config/vms
```

- Port is always **9440** (HTTPS)
- Replace `v4.0` with `v4.0.b1` or `v4.1` depending on target PC version
- Requires **Prism Central pc.2024.3** or later + **AOS 7.0** or later

---

## 2. Authentication

### Option A — HTTP Basic Auth
Standard base64-encoded `username:password` in the `Authorization` header.

```bash
curl -k -u admin:password https://{pc_ip}:9440/api/vmm/v4.0/ahv/config/vms
```

Or manually:
```bash
TOKEN=$(echo -n "admin:password" | base64)
curl -k -H "Authorization: Basic $TOKEN" https://{pc_ip}:9440/api/vmm/v4.0/ahv/config/vms
```

### Option B — API Key (Recommended for automation)
- Only available for **service account** users
- Pass via `X-Ntnx-Api-Key` header
- Requires an IAM authorization policy granting the service account access

```bash
curl -k -H "X-Ntnx-Api-Key: {api_key}" https://{pc_ip}:9440/api/vmm/v4.0/ahv/config/vms
```

### Required Headers (all requests)
| Header | Value |
|--------|-------|
| `Accept` | `application/json` |
| `Content-Type` | `application/json` (POST/PUT/PATCH) |
| `NTNX-Request-Id` | Random UUID — ensures idempotency for mutating calls |
| `If-Match` | ETag from GET response — required for PUT/PATCH/DELETE |

---

## 3. VM Endpoints

### 3.1 List VMs
```
GET /api/vmm/v4.0/ahv/config/vms
```

**Query parameters:**

| Parameter | Type | Default | Max | Description |
|-----------|------|---------|-----|-------------|
| `$page` | int | 0 | — | Zero-based page offset |
| `$limit` | int | 25 | 100 | Results per page |
| `$filter` | string | — | — | OData v4 filter expression |
| `$orderby` | string | — | — | Sort field + direction (`name asc`) |
| `$select` | string | — | — | Comma-separated field list |
| `$expand` | string | — | — | Expand related entities |

**Pagination formula:**
```
start_index = page * limit
end_index   = (limit * (page + 1)) - 1
```

**Example — page through all VMs:**
```bash
# Page 0
GET /api/vmm/v4.0/ahv/config/vms?$page=0&$limit=100

# Page 1
GET /api/vmm/v4.0/ahv/config/vms?$page=1&$limit=100
```

---

### 3.2 Get VM by ID
```
GET /api/vmm/v4.0/ahv/config/vms/{extId}
```

`extId` is the UUID of the VM (e.g., `550e8400-e29b-41d4-a716-446655440000`).

Response includes the `ETag` header — save it for update/delete operations.

---

### 3.3 Power Operations

All power operations are **POST** to an `$actions` sub-resource:

```
POST /api/vmm/v4.0/ahv/config/vms/{extId}/$actions/power-on
POST /api/vmm/v4.0/ahv/config/vms/{extId}/$actions/power-off
POST /api/vmm/v4.0/ahv/config/vms/{extId}/$actions/shutdown      # graceful
POST /api/vmm/v4.0/ahv/config/vms/{extId}/$actions/reboot
POST /api/vmm/v4.0/ahv/config/vms/{extId}/$actions/reset
```

These return an async task (`extId` for the task). Poll `/api/prism/v4.0/config/tasks/{taskExtId}` to check completion.

**Example:**
```bash
curl -k -X POST \
  -u admin:password \
  -H "Content-Type: application/json" \
  -H "NTNX-Request-Id: $(uuidgen)" \
  https://{pc_ip}:9440/api/vmm/v4.0/ahv/config/vms/{vm_extid}/$actions/power-on
```

---

### 3.4 Create VM
```
POST /api/vmm/v4.0/ahv/config/vms
```

Minimum request body:
```json
{
  "name": "my-vm",
  "numSockets": 2,
  "numCoresPerSocket": 1,
  "memorySizeBytes": 4294967296,
  "cluster": {
    "extId": "{cluster_extid}"
  },
  "nics": [
    {
      "networkInfo": {
        "nicType": "NORMAL_NIC",
        "subnet": {
          "extId": "{subnet_extid}"
        }
      }
    }
  ]
}
```

---

### 3.5 Update VM
```
PUT /api/vmm/v4.0/ahv/config/vms/{extId}
```

Requires `If-Match` header with the ETag from the GET response. Send the full VM object with modifications.

---

### 3.6 Delete VM
```
DELETE /api/vmm/v4.0/ahv/config/vms/{extId}
```

Requires `If-Match` header. Returns async task.

---

## 4. OData Filter Examples

```
# Exact name match
$filter=name eq 'my-vm'

# Name prefix
$filter=startswith(name, 'prod-')

# Power state (ON / OFF / UNKNOWN)
$filter=powerState eq 'ON'

# Combined
$filter=powerState eq 'ON' and numSockets gt 4

# Name contains
$filter=contains(name, 'web')
```

Logical operators: `eq`, `ne`, `gt`, `ge`, `lt`, `le`, `and`, `or`, `not`, `in`
String functions: `contains()`, `startswith()`, `endswith()`, `tolower()`, `toupper()`

---

## 5. VM Response Fields (Known)

| Field | Type | Description |
|-------|------|-------------|
| `extId` | string (UUID) | Unique VM identifier |
| `name` | string | VM display name |
| `description` | string | Optional description |
| `powerState` | enum | `ON`, `OFF`, `UNKNOWN` |
| `numSockets` | int | Number of vCPU sockets |
| `numCoresPerSocket` | int | Cores per socket |
| `memorySizeBytes` | int | RAM in bytes |
| `cluster` | object | `{ extId }` cluster reference |
| `nics` | array | Network interfaces |
| `disks` | array | Storage disks |
| `guestOs` | object | Guest OS info |
| `categories` | array | Category key/value pairs |
| `createTime` | datetime | ISO 8601 |
| `updateTime` | datetime | ISO 8601 |

> **Note:** Full schema with all nested fields needs verification against the live API Explorer or OpenAPI spec at `https://{pc_ip}:9440/api/nutanix/v4.0/openapi.json`

---

## 6. Python SDK

**Install:**
```bash
pip install ntnx-vmm-py-client
```

**Basic setup:**
```python
import ntnx_vmm_py_client
from ntnx_vmm_py_client.api import VmApi

config = ntnx_vmm_py_client.Configuration()
config.host = "https://{pc_ip}:9440"
config.username = "admin"
config.password = "password"
config.verify_ssl = False  # for self-signed certs

client = ntnx_vmm_py_client.ApiClient(configuration=config)
vm_api = VmApi(api_client=client)
```

**List VMs:**
```python
response = vm_api.list_vms(_page=0, _limit=50, _filter="powerState eq 'ON'")
for vm in response.data:
    print(vm.ext_id, vm.name, vm.power_state)
```

**Get VM by ID:**
```python
vm = vm_api.get_vm_by_id(extId="550e8400-e29b-41d4-a716-446655440000")
print(vm.data)
```

**Power on:**
```python
vm_api.power_on(extId="550e8400-e29b-41d4-a716-446655440000")
```

**Power off:**
```python
vm_api.power_off(extId="550e8400-e29b-41d4-a716-446655440000")
```

---

## 7. Key Gotchas

- **100 VM max per page** — always paginate; never assume one call returns all VMs
- **Stats are separate** — VM list/get does NOT include performance metrics; those require a separate API call
- **ETag required for writes** — GET the VM first, capture the `ETag` response header, pass it as `If-Match` on PUT/DELETE
- **NTNX-Request-Id** — generate a fresh UUID per mutating request for idempotency
- **Async operations** — create/update/delete/power ops return a task `extId`; poll `/api/prism/v4.0/config/tasks/{taskExtId}` for completion
- **Self-signed certs** — Prism Central uses a self-signed cert by default; use `-k` in curl or `verify_ssl=False` in the SDK during dev

---

## 8. Open Questions

- [ ] Is `v4.0.b1` the latest stable? Confirm `v4.1` GA status
- [ ] Full nested schema for `nics`, `disks`, `guestOs` objects
- [ ] Rate limits — not documented publicly
- [ ] Filter by `cluster.extId` — does nested field filtering work?
