# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

TechSpace is a tech blog and content platform. Readers can browse articles, filter by category/tag, and bookmark posts. Authors publish via a markdown-based CMS backed by Supabase. A FastAPI backend handles auth, content API, and search.

## Stack
- Frontend: React + TypeScript + Vite + Tailwind + shadcn/ui
- Backend: Python + FastAPI
- Database: Supabase (Postgres, Auth, Storage, Full-Text Search)
- Content: Markdown files rendered client-side (react-markdown + remark-gfm)
- Search: Supabase full-text search (tsvector) + pgvector for semantic search (Phase 2)
- Observability: LangSmith (Phase 2, AI features only)

## Dev Commands

```bash
# Backend (from repo root)
cd backend && python -m venv venv          # first time only
source backend/venv/bin/activate
pip install -r backend/requirements.txt    # first time / after dep changes
uvicorn main:app --reload --port 8000

# Frontend (from repo root)
cd frontend && npm install                 # first time / after dep changes
npm run dev                                # starts on http://localhost:5173

# Type-check frontend
cd frontend && npm run build
```

**Env vars:** backend reads from `backend/.env`; frontend reads from `frontend/.env.local`. Copy `.env.example` for the full list.

## Rules
- Python backend must use a `venv` virtual environment (NOT .venv)
- No LangChain, no LangGraph — raw SDK calls only
- Use Pydantic for all request/response schemas
- All tables need Row-Level Security
- Stream search results where applicable via SSE
- No admin UI — content management via Supabase dashboard + markdown files

## Engineering Principles

### 1. Think Before Coding
State assumptions explicitly. Ask if multiple interpretations exist. Push back when a simpler approach works.

### 2. Simplicity First
Minimum code that solves the problem. No speculative abstractions.

### 3. Surgical Changes
Touch only what you must. Match existing style. Don't refactor unrelated code.

### 4. Goal-Driven Execution
Define verifiable success criteria before implementing. Loop until validated.

## Planning
- Save all plans to `.agent/plans/`
- Naming convention: `{sequence}.{plan-name}.md`
- Include complexity indicator: ✅ Simple / ⚠️ Medium / 🔴 Complex
- Each task must have at least one validation test

## Development Flow
1. **Plan** — save to `.agent/plans/`
2. **Build** — minimal, surgical implementation
3. **Validate** — test against acceptance criteria
4. **Iterate** — fix until criteria pass

## Architecture

```
frontend/                  React + Vite SPA
  src/
    components/
      ui/                  shadcn/ui primitives
      layout/              Header, Footer, Sidebar
      blog/                PostCard, PostList, TagBadge, TOC
    pages/                 Home, PostDetail, Category, Search, Bookmarks
    hooks/                 useAuth, usePosts, useBookmarks, useSearch
    lib/                   supabase client, api helpers

backend/                   FastAPI
  main.py                  Entry point, route registration, CORS
  routers/
    posts.py               CRUD for posts (author-only writes)
    tags.py                Tag listing and filtering
    search.py              Full-text + semantic search
    auth.py                JWT verification middleware
  services/
    search.py              tsvector queries, pgvector (Phase 2)
    storage.py             Cover image upload to Supabase Storage
  models/                  Pydantic schemas
  venv/                    Python virtual environment (NOT .venv)

.agent/
  plans/                   Implementation plans
  validation/              Test suite and fixtures
```

Data flows:
- **Read (public):** Frontend → FastAPI `/posts` → Supabase (no auth required for published posts)
- **Write (author):** Frontend → FastAPI (JWT verified) → Supabase (RLS enforces author_id)
- **Search:** Frontend → FastAPI `/search` → tsvector full-text query → ranked results
- **Bookmarks:** Frontend → Supabase directly via anon key + user JWT (RLS enforces user_id)
- **Images:** Author upload → FastAPI → Supabase Storage (public bucket for cover images)

## Test Credentials
Test account credentials live in `backend/.env` — never hardcode here.

- **Author account:** `TEST_AUTHOR_EMAIL` / `TEST_AUTHOR_PASSWORD`
- **Reader account:** `TEST_READER_EMAIL` / `TEST_READER_PASSWORD`

## Progress
Check PROGRESS.md for current phase status. Update as tasks complete.
