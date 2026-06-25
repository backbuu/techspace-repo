# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

TechSpace is a tech blog platform. Readers browse and search articles publicly; authors publish markdown-based posts via a CMS UI. No admin panel — all config is via env vars and Supabase dashboard.

## Stack

| Layer | Choice |
|-------|--------|
| Frontend | React + TypeScript + Vite + Tailwind + shadcn/ui |
| Backend | Python + FastAPI |
| Database | Supabase (Postgres + Auth + Storage + Realtime) |
| Search | Full-text search via tsvector (Phase 1), pgvector semantic search (Phase 2) |
| Content | Markdown stored in Supabase, rendered via react-markdown |
| Observability | LangSmith (Phase 2, AI features only) |

## Rules

- Python backend must use `backend/venv/` — NOT `.venv`
- No LangChain, no LangGraph — raw SDK calls only (LangSmith SDK for tracing is allowed)
- Use Pydantic for structured outputs
- All Supabase tables need Row-Level Security — readers never see drafts; authors only edit their own posts
- Stream chat/AI responses via SSE
- No LLM abstractions in Phase 1

## Dev Commands

### Backend
```bash
cd backend
source venv/bin/activate
uvicorn main:app --reload --port 8000
```

Health check: `curl http://localhost:8000/health` → `{"status":"ok"}`

### Frontend
```bash
cd frontend
npm install
npm run dev        # http://localhost:5173
npm run build
npm run lint
```

### Environment
```bash
# Backend env
cp .env.example backend/.env
# Frontend env
cp .env.example frontend/.env.local  # rename VITE_* vars
```

## Architecture

### Auth & Roles
Two roles: `author` (create/edit/delete own posts) and `reader` (bookmarks, reading history). Public routes require no auth. Roles are set as custom claims in Supabase Auth. RLS enforces access at the DB layer — the FastAPI backend uses the service role key for server-side operations.

### Data Flow
- Frontend calls FastAPI for business logic (search, AI features, cover image upload proxying)
- Direct Supabase calls from the frontend for auth state and Realtime subscriptions
- Markdown content stored in Supabase `posts` table; rendered client-side

### Phases
- **Phase 1** (Modules 1–5): Core blog — auth, article CRUD, search, reader features
- **Phase 2** (Modules 6–7): AI — pgvector semantic search, AI writing assistant

See `PRD.md` for full scope and module breakdown.

### Current State
No `backend/` or `frontend/` directories exist yet — the project is pre-implementation. `PROGRESS.md` is the source of truth for what's done and what's next. Start there before building anything.

## Planning & Execution

- Save plans to `.agent/plans/{sequence}.{plan-name}.md`
- Use `/plan <feature>` to create a plan, `/build <path-to-plan>` to execute it
- Complexity indicators: ✅ Simple / ⚠️ Medium / 🔴 Complex (break 🔴 into sub-plans)
- Each task in a plan must have a verifiable acceptance criterion

## Validation

- Validation suite: `.agent/validation/full-suite.md` (create if missing)
- API tests: curl-based, ID prefix `API-{n}`
- E2E tests: Playwright MCP, ID prefix `E2E-{n}`
- A module is not complete until its test is executed and passes
- After completing a module: update `full-suite.md` results table and mark `PROGRESS.md`

## Test Credentials

Stored in `backend/.env` — never hardcode. Load with:
```bash
set -a; source backend/.env; set +a
```

| Variable | Purpose |
|----------|---------|
| `TEST_AUTHOR_EMAIL` / `TEST_AUTHOR_PASSWORD` | Author role test user |
| `TEST_READER_EMAIL` / `TEST_READER_PASSWORD` | Reader role test user |

See `.env.example` for all required vars.

## Progress

Check `PROGRESS.md` for current module status. Update it as tasks complete.

## Repo Layout Note

`NKP/` and `Nutanix API/` directories at the repo root are unrelated research notes — not part of TechSpace. Ignore them unless explicitly asked.
