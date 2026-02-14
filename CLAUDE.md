# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is Amenti

Amenti is a SQLite-backed persistent memory system for AI agents. It replaces large context files with FTS5 full-text search, so agents boot with a tiny task list (~500 tokens, <3k with Memory Index) and retrieve relevant memories on demand — 80-95% token reduction vs file-based memory.

## Tech Stack

Pure Bash + SQLite. No package manager, no build system. Requires: SQLite3, Bash, Python3.

- **CLI:** Single Bash script (`bin/amenti`, ~740 lines) using a command router pattern
- **Database:** SQLite3 with WAL mode, FTS5 full-text search (Porter stemming + Unicode61)
- **Python3:** Used in `search` and `budget` commands for JSON parsing and parameterized queries

## Commands

```bash
# Initialize database from schema
./scripts/init-db.sh

# Run cleanup (smart retention, auto-promotion)
./scripts/cleanup.sh

# Migrate from file-based memory
./scripts/migrate.sh /path/to/workspace

# CLI usage (reads from ~/.config/amenti/config, AMENTI_DB env var, or defaults to ./amenti.db)
./bin/amenti help
./bin/amenti stats
```

## Architecture

### Data Flow

```
Session activity → daily_logs (30-day, FTS5) → reflections → memories (permanent, FTS5)
                                                            → action_items (tasks)
                                                            → open_questions
                                                            → identity_evolution
```

### Database Schema (8 tables in `src/schema.sql`)

- **memories** + **memories_fts** — Permanent knowledge store. FTS5 indexes content/type/tags. Triggers auto-calculate `token_estimate` (length/4) and keep FTS in sync. Confidence scored 0.0-1.0.
- **memory_links** — Graph relationships between memories (supports, contradicts, depends_on, related, supersedes).
- **daily_logs** + **daily_logs_fts** — Raw session notes with 30-day retention. Marked `distilled=1` after processing.
- **reflections** — Structured processing that produces memories, action_items, open_questions, and identity_evolution entries.
- **action_items** — Tasks with priority (low/normal/high/urgent) and status (open/in_progress/done/cancelled).
- **open_questions** — Low-confidence observations (< 0.50) stored as questions rather than memories.
- **agent_state** — Key-value runtime state, composite PK of (key, agent_id).
- **identity_evolution** — Tracks how the agent's personality shifts over time.

6 views: `v_active_memories`, `v_session_context`, `v_open_actions`, `v_pending_distillation`, `v_context_budget`, `v_memory_graph`.

### Key Patterns

- **Supersede, never overwrite:** Old memory deactivated (`is_active=0`), new memory created with `supersedes_id` reference. Full audit trail preserved.
- **Confidence scoring:** 0.95-1.0 = directly stated, 0.80-0.94 = strongly implied, 0.50-0.79 = inferred (mark for validation), < 0.50 = store as open_question not memory.
- **Multi-agent:** All tables scoped by `agent_id` (default: "default"). Set via `AMENTI_AGENT` env var. Agents share one DB.
- **Smart retention:** `scripts/cleanup.sh` auto-promotes high-confidence (>=0.80) memories before deleting 30-day-old distilled logs/reflections. Stales questions at 30d, cancels tasks at 60d.
- **FTS5 over vectors:** Intentional — zero dependencies, zero API costs, keyword search is sufficient for structured agent memories.

### CLI Structure (`bin/amenti`)

Command router dispatches to `cmd_*()` functions. SQL executed via `sql()` (raw) and `sql_json()` (JSON/formatted output) wrappers. Single quotes in content escaped with `''` for SQL injection prevention. 19 commands: search, store, recall, link, forget, supersede, tasks, task, questions, ask, answer, log, logs, reflect, identity, state, budget, stats, export, init.

### Templates

- `templates/MEMORY.md` — Minimal task-only scratchpad loaded each session (~500 tokens minimal, <3k target)
- `templates/SKILL.md` — Teaches agents when to search, what to store, how to maintain Amenti

## Memory Types

8 types enforced by CHECK constraint: `fact`, `preference`, `relationship`, `principle`, `commitment`, `moment`, `skill`, `pattern`.

## Link Relations

5 types enforced by CHECK constraint: `supports`, `contradicts`, `depends_on`, `related`, `supersedes`.
