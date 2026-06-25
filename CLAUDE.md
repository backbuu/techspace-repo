# CLAUDE.md

RAG app with chat (default) and document ingestion interfaces. Config via env vars, no admin UI.

## Stack
- Frontend: React + TypeScript + Vite + Tailwind + shadcn/ui
- Backend: Python + FastAPI
- Database: Supabase (Postgres, pgvector, Auth, Storage, Realtime)
- LLM: OpenAI Responses API (Module 1), any OpenAI-compatible endpoint - OpenRouter, Ollama, LM Studio (Module 2+)
- Doc processing: Docling (Module 5+)
- Observability: LangSmith

## Rules
- Python backend must use a `venv` virtual environment
- No LangChain, no LangGraph - raw SDK calls only (the LangSmith SDK for tracing is allowed)
- Use Pydantic for structured LLM outputs
- All tables need Row-Level Security - users only see their own data
- Stream chat responses via SSE
- Use Supabase Realtime for ingestion status updates
- Module 2+ uses stateless completions - store and send chat history yourself
- Ingestion is manual file upload only - no connectors or automated pipelines

## Engineering Principles

Behavioral guidelines to reduce common coding mistakes. These bias toward caution over speed - for trivial tasks, use judgment.

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## Planning
- Save all plans to `.agent/plans/` folder
- Naming convention: `{sequence}.{plan-name}.md` (e.g., `1.auth-setup.md`, `2.document-ingestion.md`)
- Plans should be detailed enough to execute without ambiguity
- Each task in the plan must include at least one validation test to verify it works (see Goal-Driven Execution above)
- Assess complexity and single-pass feasibility - can an agent realistically complete this in one go?
- Include a complexity indicator at the top of each plan:
  - ✅ **Simple** - Single-pass executable, low risk
  - ⚠️ **Medium** - May need iteration, some complexity
  - 🔴 **Complex** - Break into sub-plans before executing

## Development Flow
1. **Plan** - Create a detailed plan and save it to `.agent/plans/`. Surface assumptions and tradeoffs before committing to an approach
2. **Build** - Execute the plan to implement the feature. Keep changes minimal and surgical
3. **Validate** - Test and verify the implementation works correctly. Use browser testing where applicable via an appropriate MCP
4. **Iterate** - Fix any issues found during validation. Loop until success criteria are verified


### Verify Services
- Backend health: `curl http://localhost:8000/health` should return `{"status":"ok"}`
- Frontend: Open http://localhost:5173 in browser


## Test Credentials
Test account credentials live in `backend/.env` (not committed) — never hardcode them here or in scripts. Read them from these env vars:

- **Primary test user:** `TEST_USER_EMAIL` / `TEST_USER_PASSWORD`
- **Second user (data-isolation tests):** `TEST_USER2_EMAIL` / `TEST_USER2_PASSWORD`

Example (load into a shell for validation/curl):
```bash
set -a; source backend/.env; set +a
# then use "$TEST_USER_EMAIL" / "$TEST_USER_PASSWORD"
```
See `backend/.env.example` for the placeholder entries.


## Validation Suite

The test suite lives at `.agent/validation/full-suite.md`. **If it does not
exist yet, create it** (with a Results Summary table at the bottom).

**When building or modifying any module, you MUST update the validation suite:**
1. Add a test case to `full-suite.md` for the new/changed module
   (format: `### TEST-{n}: Description` with Steps and Acceptance Criteria;
   continue numbering from the highest existing TEST id)
1. Add new API tests (curl-based) for any new or modified endpoints
2. Add new E2E tests (Playwright MCP) for any new UI flows
2. Execute the test (run the module script in `venv` and check the
   acceptance criteria — e.g. loss decreases, output shapes correct,
   checkpoint saved)
3. Record pass/fail in the Results Summary table at the bottom of `full-suite.md` with new section counts
6. Maintain test ordering - tests that create data must run before tests that read it
4. Add fixture files to `.agent/validation/fixtures/` if tests need sample data
4. Update PROGRESS.md: mark the module complete **and note its test result**
   (e.g. `[x] Module 5: ... — TEST-5 ✅ passed`)
7. Add cleanup steps for any new test data created

**Test ID conventions:**
- API tests: `API-{next-number}` (continue from highest existing)
- E2E tests: `E2E-{next-number}` (continue from highest existing)

A module is not "complete" until its test has been executed and passed.

## Progress
Check PROGRESS.md for current module status. Update it as you complete tasks.

# Notes

The Python Virtual Environment is located in the folder /backend/venv/ NOT .venv