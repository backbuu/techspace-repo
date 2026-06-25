# TechSpace — Validation Suite

Run tests in order. Tests that create data must run before tests that read it.

---

## TEST-1: Backend Health Check

**Module:** 1 — Project Shell

**Steps:**
```bash
cd backend && source venv/bin/activate
uvicorn main:app --port 8000 &
curl http://localhost:8000/health
```

**Acceptance Criteria:**
- Returns `{"status":"ok"}` with HTTP 200

**Result:** ⬜ Not run

---

## TEST-2: Supabase Schema

**Module:** 1 — Project Shell

**Steps:**
1. Run `supabase/migrations/001_initial_schema.sql` in Supabase SQL editor
2. Open Supabase Table Editor

**Acceptance Criteria:**
- Tables exist: `profiles`, `posts`, `categories`, `tags`, `post_tags`, `bookmarks`, `reading_history`
- RLS is enabled on all tables (shown in Supabase dashboard)

**Result:** ⬜ Not run

---

## TEST-3: Auth Sign Up

**Module:** 1 — Project Shell

**Steps:**
1. Open `http://localhost:5173/signup`
2. Enter a new email and password (min 6 chars), submit

**Acceptance Criteria:**
- Redirected to `/` (home page)
- `profiles` table in Supabase has a row for the new user (trigger auto-creates it)

**Result:** ⬜ Not run

---

## TEST-4: Auth Sign In + Session Persistence

**Module:** 1 — Project Shell

**Steps:**
1. Sign in at `/login` with the account created in TEST-3
2. Refresh the page

**Acceptance Criteria:**
- After sign in: header shows "Sign out" instead of "Sign in / Sign up"
- After refresh: still signed in (session persists via Supabase localStorage)

**Result:** ⬜ Not run

---

## TEST-5: Protected Route — Unauthenticated

**Module:** 1 — Project Shell

**Steps:**
1. Sign out
2. Navigate to `/bookmarks`

**Acceptance Criteria:**
- Redirected to `/login`

**Result:** ⬜ Not run

---

## TEST-6: Author Role Guard

**Module:** 1 — Project Shell

**Steps:**
1. Sign in as a reader account (role = 'reader' in profiles)
2. Navigate to `/dashboard`

**Acceptance Criteria:**
- Redirected to `/` (not shown the dashboard)

**Result:** ⬜ Not run

---

## API-1: Health Endpoint

```bash
curl -s http://localhost:8000/health | python3 -m json.tool
# Expected: {"status": "ok"}
```

**Result:** ⬜ Not run

---

## Results Summary

| Test | Module | Description | Result |
|------|--------|-------------|--------|
| TEST-1 | 1 | Backend health check | ⬜ |
| TEST-2 | 1 | Supabase schema deployed | ⬜ |
| TEST-3 | 1 | Sign up creates profile | ⬜ |
| TEST-4 | 1 | Session persists on refresh | ⬜ |
| TEST-5 | 1 | Unauth redirect to /login | ⬜ |
| TEST-6 | 1 | Reader blocked from /dashboard | ⬜ |
| API-1 | 1 | /health returns 200 | ⬜ |
