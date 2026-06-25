# Progress

Track progress through phases and modules. Update as tasks complete.

## Convention
- `[ ]` = Not started
- `[-]` = In progress
- `[x]` = Completed

## Modules

### Phase 1: Core Blog

- [x] **Module 1: Project Shell** — backend scaffold, DB schema, frontend scaffold, auth wiring
  - [x] T1 Backend scaffold (FastAPI + venv + health endpoint)
  - [x] T2 Auth middleware (JWT validation, role extraction)
  - [x] T3 Database schema + RLS (schema.sql)
  - [x] T4 Frontend scaffold (Vite + React + TS + Tailwind + shadcn config)
  - [x] T5 Frontend auth context (Supabase session + role)
  - [x] T6 Posts router stub (GET /posts, GET /posts/{slug})
  - [x] T7 Environment wiring + venv installed
  - Validation: API-1 ✅ API-3 ✅

- [ ] **Module 2: Article Listing + Reading**
- [ ] **Module 3: Author CMS**
- [ ] **Module 4: Search**
- [ ] **Module 5: Reader Features**

### Phase 2: AI Enhancement

- [ ] **Module 6: Semantic Search + Related Posts**
- [ ] **Module 7: AI Writing Assistant**
