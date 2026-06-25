---
description: Create an implementation plan
argument-hint: [feature-or-module]
---

# Plan

Create a detailed implementation plan for: `$ARGUMENTS`

## Process

1. **Gather context**
   - Read CLAUDE.md, PRD.md, and PROGRESS.md
   - Explore the relevant parts of the codebase
   - Surface assumptions and tradeoffs before committing to an approach - if multiple interpretations exist, ask

2. **Draft the plan** following the Planning rules in CLAUDE.md:
   - Complexity indicator at the top (✅ Simple / ⚠️ Medium / 🔴 Complex)
   - Ordered tasks, each with at least one validation test
   - Detailed enough to execute without ambiguity
   - If 🔴 Complex, break into sub-plans instead

3. **Save the plan**
   - Folder: `.agent/plans/`
   - Name: `{sequence}.{plan-name}.md` - use the next number after existing plans

4. **Report** - Summarise the plan, its complexity, and suggest running `/build .agent/plans/{file}` to execute it
