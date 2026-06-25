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

## Database Schema
Migrations live in `supabase/migrations/` but are **applied manually** via the Supabase SQL editor — there is no `supabase db push` step. Run new `.sql` files in the Supabase dashboard when adding tables.

Key schema facts:
- `posts.search_vector` (tsvector) is auto-populated by a trigger on insert/update — never set it manually.
- `posts.reading_time_minutes` is also computed by that same trigger (200 wpm).
- `profiles` rows are auto-created via an `on_auth_user_created` trigger on `auth.users`.
- `database.py` uses the **service role key** (bypasses RLS) — FastAPI is the authority layer, not RLS, for backend writes.

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
  auth.py                  JWT verification middleware
  database.py              Supabase client singleton (service role key)
  config.py                Env var loading
  routers/                 Empty — add posts.py, tags.py, search.py here
  services/                Empty — add search.py, storage.py here
  models/                  Empty — add Pydantic schemas here
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

## Auth Details

**Backend (`auth.py`):** JWT verification calls `admin.auth.get_user(token)` via the Supabase admin client — it does **not** decode the JWT locally with a secret. After verifying, it fetches `profiles.role` to attach the role to the user dict. Use `Depends(get_current_user)` for any authenticated route, `Depends(require_author)` to gate author-only endpoints.

**Frontend (`useAuth`):** Returns `{ session, user, role, loading }`. `role` is fetched from `profiles` after each auth state change — it's `'reader' | 'author' | null`. `ProtectedRoute` wraps pages that need auth; pass `requireRole="author"` to also gate on role.

## Test Credentials
Test account credentials live in `backend/.env` — never hardcode here.

- **Author account:** `TEST_AUTHOR_EMAIL` / `TEST_AUTHOR_PASSWORD`
- **Reader account:** `TEST_READER_EMAIL` / `TEST_READER_PASSWORD`

## Progress
Check PROGRESS.md for current phase status. Update as tasks complete.
