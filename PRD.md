# TechSpace — Product Requirements Document

## What We're Building

A tech blog and content platform where:
- **Readers** browse articles, filter by category/tag, search, and bookmark posts
- **Authors** publish markdown-based articles with cover images, tags, and metadata
- **No admin UI** — content managed via Supabase dashboard and markdown files

## Target Users

Technology practitioners: developers, DevOps engineers, cloud architects. They want concise, practical articles they can act on immediately.

## Scope

### In Scope
- ✅ Public article listing and reading (no auth required)
- ✅ Full-text search across articles
- ✅ Filter by category and tag
- ✅ Reader auth (bookmarks, reading history)
- ✅ Author auth (create, edit, delete own posts)
- ✅ Cover image upload (Supabase Storage)
- ✅ Markdown rendering with syntax highlighting
- ✅ Table of contents generation
- ✅ Reading time estimate
- ✅ Semantic search / related posts (Phase 2)
- ✅ Newsletter signup (Phase 2)

### Out of Scope
- ❌ Comments / community features
- ❌ Paid subscriptions / paywalls
- ❌ Multi-author editorial workflow
- ❌ Social login (GitHub, Google) — email auth only
- ❌ Mobile app
- ❌ RSS feed (Phase 2)

## Stack

| Layer | Choice |
|-------|--------|
| Frontend | React + TypeScript + Vite + Tailwind + shadcn/ui |
| Backend | Python + FastAPI |
| Database | Supabase (Postgres + Auth + Storage) |
| Search | Supabase full-text search (Phase 1), pgvector semantic search (Phase 2) |
| Content | Markdown stored in Supabase, rendered via react-markdown |
| Observability | LangSmith (Phase 2, AI features only) |

---

## Phase 1: Core Blog

### Module 1: Project Shell
Auth, database schema, backend scaffold, frontend scaffold.

### Module 2: Article Listing + Reading
Public article list, filters, post detail page with markdown rendering, TOC, reading time.

### Module 3: Author CMS
Author-only create/edit/delete posts, cover image upload, draft vs published state.

### Module 4: Search
Full-text search with Supabase tsvector, highlighted excerpts, filter by tag/category.

### Module 5: Reader Features
Bookmarks, reading history — requires reader auth.

---

## Phase 2: AI Enhancement

### Module 6: Semantic Search + Related Posts
pgvector embeddings on article content; semantic search; "related posts" widget.

### Module 7: AI Writing Assistant
Author CMS gets an AI draft helper — suggest titles, generate outlines, improve readability score.

---

## Success Criteria

- Reader can find and read any published article without logging in
- Author can publish a new article in under 5 minutes
- Search returns relevant results in under 300 ms
- All tables have RLS — readers never see drafts; authors only edit their own posts
