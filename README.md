# TechSpace

A tech blog and content platform for technology practitioners. Readers browse and search articles; authors publish markdown-based posts.

## Stack

| Layer | Tech |
|-------|------|
| Frontend | React + TypeScript + Vite + Tailwind + shadcn/ui |
| Backend | Python + FastAPI |
| Database | Supabase (Postgres + Auth + Storage) |
| Search | Supabase full-text search → pgvector semantic search (Phase 2) |

## Quick Start

**Prerequisites:** Node 20+, Python 3.11+, a Supabase project.

```bash
# 1. Clone
git clone https://github.com/backbuu/techspace-repo
cd techspace-repo

# 2. Configure env vars
cp .env.example backend/.env
cp .env.example frontend/.env.local   # rename VITE_ vars
# Fill in SUPABASE_URL, keys, etc.

# 3. Backend
cd backend && python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000

# 4. Frontend (new terminal)
cd frontend && npm install && npm run dev
# → http://localhost:5173
```

## Project Structure

```
frontend/          React SPA
backend/           FastAPI app
.agent/plans/      Implementation plans (see 0.project-overview.md)
PRD.md             Full product requirements
PROGRESS.md        Module completion status
```

## Development

See [CLAUDE.md](CLAUDE.md) for engineering rules and architecture details.  
See [PRD.md](PRD.md) for full product requirements and module definitions.  
See [PROGRESS.md](PROGRESS.md) for current build status.
