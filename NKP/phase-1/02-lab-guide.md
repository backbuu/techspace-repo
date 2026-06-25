# Phase 1: Lab Guide

**3 labs, ~6–9 hours total.** Each lab has setup steps, exercises, and a checkpoint you must pass before moving on.

---

## Prerequisites

- A machine with internet access (Linux, macOS, or Windows with WSL2)
- Docker Desktop (macOS/Windows) or Docker Engine (Linux)
- A free Docker Hub account — [hub.docker.com](https://hub.docker.com)
- A terminal

### Install Docker

```bash
# Linux (Ubuntu/Debian)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# Verify
docker version
docker run hello-world
```

---

## Lab 1 — Linux Fundamentals (Week 1)

**Time:** ~2 hours
**Goal:** Get comfortable on Linux before touching containers.

### Setup

Use any of the following:
- Your local Linux machine / WSL2
- [KillerCoda Ubuntu playground](https://killercoda.com/playgrounds/scenario/ubuntu) — free, browser-based

### Exercises

#### 1.1 Process Management

```bash
# Start a background process
sleep 300 &

# Find its PID
ps aux | grep sleep

# Kill it
kill <PID>

# Verify it's gone
ps aux | grep sleep
```

**Try this:** Start 3 `sleep` processes with different durations. List them all, then kill only the middle one. Verify the other two are still running.

---

#### 1.2 systemd

```bash
# Install nginx as a test service
sudo apt update && sudo apt install -y nginx

# Check its status
systemctl status nginx

# Stop it
sudo systemctl stop nginx

# Start it again
sudo systemctl start nginx

# Watch the logs in real time (Ctrl+C to stop)
sudo journalctl -u nginx -f

# In another terminal, curl nginx to generate a log entry
curl http://localhost
```

**Try this:** Disable nginx from starting on boot. Reboot (or simulate with `sudo systemctl daemon-reload`) and confirm it doesn't auto-start.

---

#### 1.3 Networking

```bash
# What IPs does this machine have?
ip addr

# What's the default route?
ip route

# What ports are listening?
ss -tlnp

# DNS lookup
dig google.com
nslookup google.com

# Test HTTP
curl -v http://google.com
curl -I http://google.com        # headers only
```

**Try this:** Find which port nginx is listening on using `ss`. Confirm it with `curl`.

---

#### 1.4 Files and Logs

```bash
# Create a test file
echo "line 1" >> /tmp/test.log
echo "line 2" >> /tmp/test.log
echo "ERROR: something failed" >> /tmp/test.log
echo "line 4" >> /tmp/test.log

# Search it
grep "ERROR" /tmp/test.log

# Watch it live (in one terminal)
tail -f /tmp/test.log

# Append to it in another terminal
echo "new line" >> /tmp/test.log
```

**Try this:** Find all files under `/var/log` that contain the word "error" (case-insensitive). Use `grep -ri`.

---

#### Lab 1 Checkpoint ✅

- [ ] Started and killed a background process by PID
- [ ] Started/stopped nginx with systemctl and read its logs with journalctl
- [ ] Listed listening ports with `ss -tlnp` and confirmed nginx is there
- [ ] Searched a log file with `grep`

---

## Lab 2 — Docker Fundamentals (Week 2)

**Time:** ~3 hours
**Goal:** Build images, run containers, use volumes and networks.

### Setup

```bash
# Confirm Docker is installed and running
docker version
docker run hello-world
```

---

### Exercise 2.1 — Run Your First Real Container

```bash
# Run nginx and map port 8080 on host → port 80 in container
docker run -d --name web -p 8080:80 nginx:1.27

# Confirm it's running
docker ps

# Hit it
curl http://localhost:8080

# Follow its logs
docker logs -f web

# In another terminal, hit it again to see log entries appear
curl http://localhost:8080

# Stop and remove
docker stop web
docker rm web
```

**Try this:** Run nginx with an environment variable `NGINX_HOST=mysite.com`. Exec into the container and verify the env var is set.

```bash
docker run -d --name web -e NGINX_HOST=mysite.com nginx:1.27
docker exec -it web env | grep NGINX
```

---

### Exercise 2.2 — Build a Custom Image

Create a simple Python web app:

```bash
mkdir ~/lab-docker && cd ~/lab-docker
```

**`app.py`:**
```python
from http.server import HTTPServer, BaseHTTPRequestHandler
import os

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        msg = os.environ.get("GREETING", "Hello from container!")
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(msg.encode())

    def log_message(self, format, *args):
        print(f"{self.address_string()} - {format % args}")

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    print(f"Listening on port {port}")
    HTTPServer(("", port), Handler).serve_forever()
```

**`Dockerfile`:**
```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY app.py .

EXPOSE 8080

CMD ["python", "app.py"]
```

```bash
# Build
docker build -t myapp:1.0 .

# Run with default greeting
docker run -d --name app1 -p 8080:8080 myapp:1.0
curl http://localhost:8080

# Run with custom greeting
docker stop app1 && docker rm app1
docker run -d --name app1 -p 8080:8080 -e GREETING="Hi from NKP lab!" myapp:1.0
curl http://localhost:8080

# Check image layers
docker history myapp:1.0
```

**Try this:** Add a second route `/health` that returns `{"status": "ok"}`. Rebuild and verify both routes work.

---

### Exercise 2.3 — Volumes

```bash
# Create a named volume
docker volume create mydata

# Run a container that writes to it
docker run --rm -v mydata:/data alpine sh -c "echo 'persistent!' > /data/file.txt"

# Run another container and read the same volume
docker run --rm -v mydata:/data alpine cat /data/file.txt
# Output: persistent!

# The volume survives even after containers are removed
docker volume ls
docker volume inspect mydata
```

**Try this:** Run a postgres container with a named volume. Insert a row. Stop and remove the container. Start a new postgres container using the same volume. Confirm the data is still there.

```bash
docker volume create pgdata

docker run -d --name pg1 \
  -e POSTGRES_PASSWORD=secret \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16

docker exec -it pg1 psql -U postgres -c "CREATE TABLE test (id int); INSERT INTO test VALUES (1);"

docker stop pg1 && docker rm pg1

docker run -d --name pg2 \
  -e POSTGRES_PASSWORD=secret \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16

docker exec -it pg2 psql -U postgres -c "SELECT * FROM test;"
# Should return: 1
```

---

### Exercise 2.4 — Container Networking

```bash
# Create a custom bridge network
docker network create mynet

# Start a postgres container on it
docker run -d --name db --network mynet \
  -e POSTGRES_PASSWORD=secret \
  postgres:16

# Start an alpine container on the same network
docker run -it --rm --network mynet alpine sh

# Inside alpine — reach postgres by name (DNS resolution via Docker)
ping db
nc -zv db 5432       # check port 5432 is open
```

**Try this:** Run your `myapp:1.0` container and a postgres container on the same network. Pass the DB hostname as an env var to the app container and verify it can reach the DB port.

---

### Exercise 2.5 — Push to Docker Hub

```bash
# Log in
docker login

# Tag your image (replace 'yourusername' with your Docker Hub username)
docker tag myapp:1.0 yourusername/myapp:1.0

# Push
docker push yourusername/myapp:1.0

# Delete local image and pull it back down
docker rmi yourusername/myapp:1.0
docker pull yourusername/myapp:1.0
docker run -d -p 8080:8080 yourusername/myapp:1.0
curl http://localhost:8080
```

---

#### Lab 2 Checkpoint ✅

- [ ] Ran nginx, hit it with curl, read logs, stopped and removed the container
- [ ] Built a custom image from a Dockerfile
- [ ] Proved volume data persists across container restarts (postgres exercise)
- [ ] Connected two containers via a custom Docker network using DNS names
- [ ] Pushed an image to Docker Hub and pulled it back

---

## Lab 3 — Docker Compose + YAML (Week 3)

**Time:** ~2 hours
**Goal:** Run a multi-service app with Compose. Master YAML before Kubernetes.

### Exercise 3.1 — First Compose App

```bash
mkdir ~/lab-compose && cd ~/lab-compose
```

Copy your `app.py` and `Dockerfile` from Lab 2 into this folder, then create:

**`docker-compose.yml`:**
```yaml
version: "3.9"

services:
  db:
    image: postgres:16
    environment:
      POSTGRES_DB: labdb
      POSTGRES_USER: labuser
      POSTGRES_PASSWORD: labsecret
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U labuser -d labdb"]
      interval: 5s
      timeout: 3s
      retries: 5

  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      GREETING: "Hello from Compose!"
      DB_HOST: db
      DB_PORT: "5432"
    depends_on:
      db:
        condition: service_healthy

volumes:
  pgdata:
```

```bash
# Start everything
docker compose up -d

# Check status
docker compose ps

# Logs
docker compose logs -f

# Hit the app
curl http://localhost:8080

# Shell into the app container
docker compose exec app sh

# Tear down (keeps volumes)
docker compose down

# Tear down and delete volumes
docker compose down -v
```

---

### Exercise 3.2 — Environment Variables with .env

```bash
# Create .env file (never commit this to Git)
cat > .env << 'EOF'
DB_PASSWORD=supersecret
GREETING=Hello from .env file!
EOF

# Add .env to .gitignore
echo ".env" >> .gitignore
```

Update `docker-compose.yml` to use the variables:

```yaml
version: "3.9"

services:
  db:
    image: postgres:16
    environment:
      POSTGRES_DB: labdb
      POSTGRES_USER: labuser
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U labuser -d labdb"]
      interval: 5s
      timeout: 3s
      retries: 5

  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      GREETING: ${GREETING}
      DB_HOST: db
    depends_on:
      db:
        condition: service_healthy

volumes:
  pgdata:
```

```bash
docker compose up -d
curl http://localhost:8080
# Output: Hello from .env file!
```

---

### Exercise 3.3 — YAML Practice (Kubernetes-Style)

Write these YAML structures by hand (no copy-paste). Validate with `python3 -c "import yaml; yaml.safe_load(open('test.yaml'))"`.

**Exercise A — nested maps:**
```yaml
# Write this from memory
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: default
  labels:
    app: myapp
    env: lab
data:
  DB_HOST: postgres
  DB_PORT: "5432"
  LOG_LEVEL: info
```

**Exercise B — list of maps:**
```yaml
# Write this from memory
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
    - name: app
      image: myapp:1.0
      ports:
        - containerPort: 8080
      env:
        - name: GREETING
          value: "Hello!"
        - name: DB_HOST
          value: postgres
```

**Exercise C — multi-line strings:**
```yaml
# Write this from memory
apiVersion: v1
kind: ConfigMap
metadata:
  name: scripts
data:
  startup.sh: |
    #!/bin/bash
    echo "Starting app..."
    python app.py
  description: >
    This ConfigMap stores startup scripts
    for the application container.
```

**Try this:** Intentionally break each file (wrong indentation, missing colon, tab instead of space) and observe the error. Fix it.

---

### Exercise 3.4 — Scale with Compose

```bash
# Scale the app service to 3 replicas
docker compose up -d --scale app=3

# List containers — you'll see 3 app instances
docker compose ps

# Note: port mapping conflicts when scaling — remove the ports section for this to work
```

Update `docker-compose.yml` — remove the `ports` from `app` (use a load balancer instead):

```yaml
services:
  nginx:
    image: nginx:1.27
    ports:
      - "8080:80"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - app

  app:
    build: .
    # no ports here — nginx proxies to it
    environment:
      GREETING: "Scaled app!"
```

**`nginx.conf`:**
```nginx
upstream app {
    server lab-compose-app-1:8080;
    server lab-compose-app-2:8080;
    server lab-compose-app-3:8080;
}

server {
    listen 80;
    location / {
        proxy_pass http://app;
    }
}
```

```bash
docker compose up -d --scale app=3
curl http://localhost:8080   # nginx load-balances across 3 app containers
```

---

#### Lab 3 Checkpoint ✅

- [ ] Multi-service app (app + db) running with Docker Compose
- [ ] `.env` file drives config — no secrets hardcoded in `docker-compose.yml`
- [ ] Wrote 3 YAML structures from memory and validated them
- [ ] Intentionally broke YAML and read the error message
- [ ] Scaled app to 3 replicas behind nginx

---

## Phase 1 Lab Summary

| Lab | Status | Time Spent |
|-----|--------|------------|
| Lab 1 — Linux Fundamentals | [ ] | |
| Lab 2 — Docker Fundamentals | [ ] | |
| Lab 3 — Docker Compose + YAML | [ ] | |

**Phase 1 complete when all 3 labs are checked off.** Move to Phase 2 — Kubernetes Core.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `permission denied` running docker | `sudo usermod -aG docker $USER && newgrp docker` |
| Port already in use | `ss -tlnp \| grep 8080` to find what's using it, then stop it |
| Container exits immediately | `docker logs <name>` — read the error |
| Compose can't find `.env` | Make sure `.env` is in the same directory as `docker-compose.yml` |
| YAML parse error | Count spaces carefully — no tabs. Use [yamllint.com](https://www.yamllint.com) |
| Volume data not persisting | Make sure you're using the same volume name and not running `down -v` |

---

## Resources

- [Docker Getting Started](https://docs.docker.com/get-started/)
- [Play with Docker](https://labs.play-with-docker.com/) — free browser lab (no install needed)
- [KillerCoda Ubuntu Playground](https://killercoda.com/playgrounds/scenario/ubuntu)
- [YAML Lint Online](https://www.yamllint.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [How Docker Works — Namespaces & cgroups](https://dev.to/doogal/how-docker-actually-works-a-deep-dive-into-namespaces-and-cgroups-5h3e)
