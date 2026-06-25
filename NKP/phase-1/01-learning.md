# Phase 1: Foundations — Learning Document

**Duration:** Weeks 1–3 (~5–8 hrs/week)
**Goal:** Understand containers and the problems they solve before touching Kubernetes.

---

## Week 1 — Linux Basics

Kubernetes runs on Linux. You don't need to be a sysadmin, but you need to be comfortable working on Linux nodes, reading logs, and debugging processes and networking.

### 1.1 The Linux Process Model

Every running program is a process. Linux identifies processes by **PID** (Process ID). When you run a container, it's just a Linux process — with restrictions applied.

```bash
ps aux                        # list all running processes
ps aux | grep nginx           # find a specific process
kill -9 <PID>                 # force-kill a process
top                           # live process view
htop                          # better live view (install with apt/yum)
```

### 1.2 systemd — Service Management

Modern Linux distros use `systemd` to manage services. Kubernetes components (kubelet, containerd) run as systemd services.

```bash
systemctl status kubelet           # check if kubelet is running
systemctl start nginx              # start a service
systemctl stop nginx               # stop a service
systemctl restart nginx            # restart
systemctl enable nginx             # start on boot
systemctl disable nginx            # don't start on boot
journalctl -u kubelet -f           # follow logs for a service
journalctl -u kubelet --since "5m ago"   # last 5 minutes of logs
```

### 1.3 File System and Permissions

```bash
ls -la /etc/                   # list with permissions
chmod 644 file.txt             # owner rw, group r, others r
chown user:group file.txt      # change owner
cat /etc/os-release            # check Linux distro and version
df -h                          # disk usage per filesystem
du -sh /var/log/               # size of a directory
```

**Permission notation:**

| Symbol | Numeric | Meaning |
|--------|---------|---------|
| `rwx` | 7 | read + write + execute |
| `rw-` | 6 | read + write |
| `r--` | 4 | read only |
| `---` | 0 | no permissions |

### 1.4 Networking Commands

These are the commands you'll reach for constantly when debugging Kubernetes networking.

```bash
ip addr                        # show all network interfaces and IPs
ip addr show eth0              # show a specific interface
ip route                       # show routing table
ss -tlnp                       # show listening TCP ports with process names
ss -ulnp                       # show listening UDP ports
curl -v http://localhost:8080  # test HTTP endpoint (verbose)
curl -sk https://host/path     # skip SSL check
ping 10.0.0.1                  # test connectivity
traceroute 8.8.8.8             # trace network path
nslookup google.com            # DNS lookup
dig google.com                 # detailed DNS lookup
```

**Why this matters for K8s:** Kubernetes assigns IPs to every Pod and Service. When something isn't reachable, you'll use `ss`, `ip route`, and `curl` to trace where the packet is getting dropped.

### 1.5 Package Management

```bash
# Debian/Ubuntu
apt update && apt install -y curl wget vim

# RHEL/CentOS/Rocky
yum install -y curl wget vim
# or
dnf install -y curl wget vim
```

### 1.6 Working with Files and Logs

```bash
tail -f /var/log/syslog        # follow a log file
tail -100 /var/log/syslog      # last 100 lines
grep "ERROR" /var/log/app.log  # search for a pattern
grep -r "failed" /var/log/     # recursive search
cat file.yaml                  # print file contents
less file.yaml                 # page through a large file (q to quit)
```

---

## Week 2 — Containers: What They Are and How They Work

### 2.1 The Problem Containers Solve

Before containers, deploying an app meant:
- "It works on my machine" — different library versions, OS configs
- Heavyweight VMs to isolate apps — slow to start, wasteful
- Manual dependency management — fragile, hard to reproduce

**Containers package the app + its dependencies into a single portable unit.** Same image runs identically on a developer's laptop, a CI pipeline, and production.

### 2.2 Containers vs Virtual Machines

| | Virtual Machine | Container |
|--|----------------|-----------|
| Isolation | Full OS per VM | Shares host OS kernel |
| Boot time | Minutes | Milliseconds |
| Size | GBs | MBs |
| Overhead | High (hypervisor + guest OS) | Low |
| Use case | Strong isolation, different OS | App packaging, microservices |

**Containers are not VMs.** They're Linux processes with two kernel features applied: **namespaces** (isolation) and **cgroups** (resource limits).

### 2.3 How Containers Work: Namespaces

A **namespace** restricts what a process can see. Docker/containerd uses 6 namespaces:

| Namespace | What it isolates |
|-----------|-----------------|
| `pid` | Processes — container sees only its own PIDs, starting from PID 1 |
| `net` | Network — container gets its own network interface, IP, and routes |
| `mnt` | Filesystem — container has its own root filesystem (`/`) |
| `uts` | Hostname — container can have its own hostname |
| `ipc` | Inter-process communication — shared memory, message queues |
| `user` | User IDs — root inside container ≠ root on host |

**Demo — see namespaces in action:**
```bash
# Run a container
docker run -d --name demo nginx

# Find its PID on the host
docker inspect demo --format '{{.State.Pid}}'

# Look at that process's namespaces
ls -la /proc/<PID>/ns/
```

### 2.4 How Containers Work: cgroups

**cgroups** (Control Groups) enforce resource limits. Without cgroups, one container could eat all the CPU and RAM on the host.

```bash
# Run a container limited to 0.5 CPU and 256MB RAM
docker run -d --cpus="0.5" --memory="256m" nginx

# See the container's resource usage
docker stats
```

**cgroup v2** (default on modern kernels) provides more accurate accounting for CPU and memory. Kubernetes 1.25+ uses cgroup v2 by default.

### 2.5 Container Images and Layers

A container image is a **read-only, layered filesystem** built from a Dockerfile. Each instruction in the Dockerfile creates a new layer.

```
Image layers (read-only):
  Layer 4: COPY app.py /app/           ← your app
  Layer 3: RUN pip install flask        ← dependencies
  Layer 2: RUN apt install python3      ← runtime
  Layer 1: FROM ubuntu:24.04            ← base OS

Container writable layer (copy-on-write):
  ← all writes go here; deleted when container stops
```

**Why layers matter:** Layers are cached and shared. If 10 containers use the same base image, the base image layers are stored once on disk.

### 2.6 Docker Core Concepts

| Concept | Description |
|---------|-------------|
| **Image** | Read-only blueprint (built from Dockerfile, stored in a registry) |
| **Container** | Running instance of an image |
| **Dockerfile** | Instructions to build an image |
| **Registry** | Stores and distributes images (Docker Hub, GHCR, private registries) |
| **Volume** | Persistent storage that survives container restarts |
| **Network** | Virtual network connecting containers |

### 2.7 Essential Docker Commands

```bash
# Images
docker pull nginx:1.27                 # pull image from registry
docker images                          # list local images
docker rmi nginx:1.27                  # remove image
docker build -t myapp:1.0 .            # build from Dockerfile in current dir
docker push myapp:1.0                  # push to registry

# Containers
docker run nginx                       # run container (foreground)
docker run -d nginx                    # run detached (background)
docker run -d -p 8080:80 nginx         # map host port 8080 → container port 80
docker run -d --name web nginx         # give container a name
docker run -d -e ENV_VAR=value nginx   # set environment variable
docker run -d -v /host/path:/container/path nginx  # mount volume

docker ps                              # list running containers
docker ps -a                           # list all containers (including stopped)
docker stop web                        # stop container gracefully
docker rm web                          # remove stopped container
docker rm -f web                       # force remove running container

# Inspect and debug
docker logs web                        # container stdout/stderr
docker logs -f web                     # follow logs
docker exec -it web bash               # open shell in running container
docker inspect web                     # full container metadata (JSON)
docker stats                           # live resource usage
```

### 2.8 Writing a Dockerfile

```dockerfile
# Start from official Python 3.12 slim base
FROM python:3.12-slim

# Set working directory inside container
WORKDIR /app

# Copy dependency file first (layer cache optimization)
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose the port the app listens on (documentation only)
EXPOSE 8080

# Command to run when container starts
CMD ["python", "app.py"]
```

**Layer caching tip:** Copy `requirements.txt` and install dependencies before copying the rest of the code. If only your code changes (not dependencies), Docker reuses the cached dependency layer — much faster builds.

### 2.9 Docker Networking

```bash
# List networks
docker network ls

# Create a custom network
docker network create mynet

# Run containers on the same network (they can reach each other by name)
docker run -d --name db --network mynet postgres:16
docker run -d --name app --network mynet myapp:1.0

# Inside 'app' container, reach 'db' by hostname
docker exec -it app ping db
```

**Port mapping:**
```
Host port 8080 → Container port 80
docker run -p 8080:80 nginx
Access: http://localhost:8080
```

### 2.10 Docker Volumes

Containers are ephemeral — when they stop, writes to the container filesystem are lost. Use volumes for data that must persist.

```bash
# Named volume (managed by Docker)
docker volume create pgdata
docker run -d -v pgdata:/var/lib/postgresql/data postgres:16

# Bind mount (host directory → container)
docker run -d -v $(pwd)/data:/app/data myapp:1.0

# List volumes
docker volume ls

# Remove unused volumes
docker volume prune
```

---

## Week 3 — YAML and Docker Compose

### 3.1 YAML Fundamentals

Kubernetes uses YAML for every resource definition. Getting comfortable with YAML now saves pain later.

**Scalars (strings, numbers, booleans):**
```yaml
name: my-app
port: 8080
enabled: true
version: "1.0"      # quotes prevent type coercion
```

**Lists:**
```yaml
fruits:
  - apple
  - banana
  - cherry

# Inline form
fruits: [apple, banana, cherry]
```

**Maps (key-value objects):**
```yaml
config:
  host: localhost
  port: 5432
  ssl: true
```

**Nested structures:**
```yaml
app:
  name: myapp
  image: myapp:1.0
  env:
    - name: DB_HOST
      value: postgres
    - name: DB_PORT
      value: "5432"
  ports:
    - containerPort: 8080
```

**Multi-line strings:**
```yaml
# Literal block (preserves newlines)
script: |
  #!/bin/bash
  echo "hello"
  exit 0

# Folded block (newlines become spaces)
description: >
  This is a long description
  that wraps across lines.
```

**Common gotchas:**
- Indentation is **spaces only** — never tabs
- Strings with `:` or `#` must be quoted: `label: "key: value"`
- `true`, `false`, `yes`, `no` are booleans — quote them if you mean the string
- `null` and `~` both mean null

### 3.2 Validate YAML

```bash
# Install yamllint
pip install yamllint

# Lint a file
yamllint docker-compose.yml

# Python one-liner to check syntax
python3 -c "import yaml; yaml.safe_load(open('file.yaml'))" && echo "Valid"
```

### 3.3 Docker Compose

Docker Compose defines and runs multi-container apps with a single `docker-compose.yml` file. Think of it as the stepping stone between "running containers manually" and "Kubernetes."

```yaml
# docker-compose.yml
version: "3.9"

services:
  db:
    image: postgres:16
    environment:
      POSTGRES_DB: mydb
      POSTGRES_USER: user
      POSTGRES_PASSWORD: secret
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d mydb"]
      interval: 10s
      timeout: 5s
      retries: 5

  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      DB_HOST: db
      DB_PORT: "5432"
      DB_NAME: mydb
      DB_USER: user
      DB_PASSWORD: secret
    depends_on:
      db:
        condition: service_healthy

volumes:
  pgdata:
```

**Key Compose commands:**
```bash
docker compose up -d          # start all services in background
docker compose down           # stop and remove containers
docker compose down -v        # also remove volumes
docker compose logs -f app    # follow logs for the 'app' service
docker compose ps             # status of all services
docker compose exec app bash  # shell into running service
docker compose build          # rebuild images
docker compose restart app    # restart a single service
```

### 3.4 Environment Variables and .env Files

```bash
# .env file (never commit to Git)
DB_PASSWORD=supersecret
API_KEY=abc123
```

```yaml
# docker-compose.yml — reference .env automatically
services:
  app:
    environment:
      DB_PASSWORD: ${DB_PASSWORD}
      API_KEY: ${API_KEY}
```

### 3.5 Container Registries

```bash
# Log in to Docker Hub
docker login

# Tag an image for a registry
docker tag myapp:1.0 yourusername/myapp:1.0

# Push to Docker Hub
docker push yourusername/myapp:1.0

# Pull from Docker Hub
docker pull yourusername/myapp:1.0

# Log in to a private registry
docker login registry.example.com
docker tag myapp:1.0 registry.example.com/myapp:1.0
docker push registry.example.com/myapp:1.0
```

---

## Phase 1 Summary

| Topic | What You Can Now Do |
|-------|-------------------|
| Linux processes | `ps`, `kill`, `top`, `systemctl`, `journalctl` |
| Linux networking | `ip`, `ss`, `curl`, `ping`, `dig` |
| Linux filesystem | permissions, `df`, `du`, `grep`, `tail` |
| Containers | Explain namespaces, cgroups, and image layers |
| Docker | Build images, run containers, use volumes and networks |
| Docker Compose | Run multi-container apps with a single file |
| YAML | Write valid YAML, avoid common gotchas |
| Registries | Push and pull images |

**You're ready for Phase 2 when you can:**
- [ ] Build a Docker image from scratch and push it to Docker Hub
- [ ] Run a multi-container app (app + database) with Docker Compose
- [ ] SSH into a Linux host and find why a service isn't running (`systemctl`, `journalctl`, `ss`)
- [ ] Write a valid YAML file without errors

---

## Key Resources

- [Docker Getting Started](https://docs.docker.com/get-started/)
- [Play with Docker](https://labs.play-with-docker.com/) — free browser lab
- [Linux Journey](https://linuxjourney.com/) — interactive Linux basics
- [YAML Lint](https://www.yamllint.com/) — paste and validate YAML online
- [How Docker Works (Namespaces & cgroups)](https://dev.to/doogal/how-docker-actually-works-a-deep-dive-into-namespaces-and-cgroups-5h3e)
- [Container Security Fundamentals — Isolation & Namespaces](https://securitylabs.datadoghq.com/articles/container-security-fundamentals-part-2/)
