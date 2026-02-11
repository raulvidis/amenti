# Amenti 🏛️

Persistent memory for AI agents. More memory, fewer tokens.

Amenti replaces bloated context files with a SQLite-backed memory system using FTS5 full-text search. Agents boot with a tiny task list and retrieve relevant memories on demand.

## How It Works

**Traditional:** Load 8,000+ tokens of context every session
**Amenti:** Load ~500 tokens (tasks only) + FTS5 search on demand

**The pipeline:**
```
Session activity → daily_logs (30 days) → reflections (30 days) → memories (permanent)
               ↓
           memory.md (tasks only)
```

**memory.md becomes a task list:**
```markdown
# MEMORY.md

## Active Tasks
- [ ] Fix deployment pipeline
- [ ] Research pricing tiers
```

Everything else lives in SQLite, searchable via FTS5.

## Features

- **FTS5 full-text search** — fast semantic search across all memories, zero maintenance
- **Confidence scoring** — every memory scored 0.0–1.0, no confabulation
- **Memory types** — fact, preference, relationship, principle, commitment, moment, skill, pattern
- **Reflection cycle** — automatic distillation from raw logs to permanent memories
- **Action-driven reflections** — reflections produce action items, not just questions
- **Token efficient** — 80-90% reduction in context tokens vs file-based memory
- **Supersede, don't overwrite** — full memory history preserved
- **30-day retention** — daily_logs and reflections expire after 30 days
- **Agent state tracking** — heartbeat counts, reflection timers, proactive check-ins
- **Identity evolution** — track how the agent changes over time

## Schema

7 tables total:

| Table | Purpose |
|-------|---------|
| `memories` | Permanent knowledge (FTS5 searchable) |
| `daily_logs` | Raw session notes (30 days, FTS5 searchable) |
| `reflections` | Structured processing |
| `action_items` | Tasks born from reflections or sessions |
| `open_questions` | Things to follow up on |
| `agent_state` | Runtime state (heartbeat, counters) |
| `identity_evolution` | How the agent changes over time |

**Files (NOT in DB):**
- `SOUL.md` / `IDENTITY.md` — core identity, loaded every session
- `USER.md` — about the human, loaded every session
- `MEMORY.md` — active tasks only (tiny scratchpad)

## Installation

```bash
# Initialize the database
./scripts/init-db.sh

# Copy memory template
cp templates/MEMORY.md /path/to/agent/workspace/MEMORY.md

# Install the skill file
cp templates/SKILL.md /path/to/agent/workspace/skills/amenti/SKILL.md
```

## Project Structure

```
amenti/
├── README.md
├── LICENSE
├── src/
│   └── schema.sql          # SQLite schema (7 tables, FTS5, triggers, views)
├── templates/
│   ├── MEMORY.md            # Lean memory.md template (tasks only)
│   └── SKILL.md             # Agent skill file (how to use Amenti)
├── scripts/
│   ├── init-db.sh           # Initialize database
│   ├── migrate.sh           # Migrate from file-based memory
│   └── cleanup.sh           # Manual cleanup script
├── docs/
│   └── ARCHITECTURE.md      # Design decisions and rationale
└── tests/
    └── test-queries.sql     # Example queries for testing
```

## Quick Start

```sql
-- Search memories
SELECT m.id, m.type, m.content, m.confidence
FROM memories_fts f
JOIN memories m ON f.rowid = m.id
WHERE memories_fts MATCH 'search terms'
ORDER BY f.rank LIMIT 5;

-- Store a memory
INSERT INTO memories (type, content, source, confidence, created_at, updated_at)
VALUES ('fact', 'User works remote on Fridays', 'direct statement', 0.95,
 strftime('%s','now'), strftime('%s','now'));

-- Create an action item
INSERT INTO action_items (description, source, priority, status, created_at)
VALUES ('Fix deployment pipeline', 'reflection', 'high', 'open',
 strftime('%s','now'));

-- Check open questions
SELECT question, context FROM open_questions WHERE status = 'open';

-- Update agent state (heartbeat)
INSERT OR REPLACE INTO agent_state (key, value, updated_at)
VALUES ('heartbeat_count', '100', strftime('%s','now'));

-- Add identity shift
INSERT INTO identity_evolution (date, shift, trigger, created_at)
VALUES ('2026-02-11', 'Agent is becoming more proactive', 'Substantial session',
 strftime('%s','now'));
```

## Memory Types

| Type | What it is | Example |
|------|-----------|---------|
| `fact` | Verifiable info | "User's iRating is 3k" |
| `preference` | Likes/dislikes | "Hates fluff, values directness" |
| `relationship` | People & dynamics | "Girlfriend in Japan, studying neuroscience" |
| `principle` | Rules or values | "Always backup config before editing" |
| `commitment` | Promises or plans | "Launch V2 by March" |
| `moment` | Emotionally significant | "First successful deployment together" |
| `skill` | Technical knowledge | "Docker restart needs on-failure policy" |
| `pattern` | Recurring behaviors | "Codes more on weekends" |

## Confidence Scoring

| Score | Meaning | Action |
|-------|---------|--------|
| 0.95–1.0 | Directly stated | Store as memory |
| 0.80–0.94 | Strongly implied | Store as memory |
| 0.50–0.79 | Inferred | Store, mark for validation |
| < 0.50 | Weak inference | Store as question, not memory |

## Action Items

Action items are born from reflections or user requests. They live in the `action_items` table:

| Status | Meaning |
|--------|---------|
| `open` | Not started |
| `in_progress` | Currently working on |
| `done` | Completed |
| `cancelled` | Abandoned |

**Priority levels:** low, normal, high, urgent

## Reflections

Reflections are NOT just summaries. They produce:

1. **Memories** → INSERT INTO memories table
2. **Action items** → INSERT INTO action_items table
3. **Questions** → INSERT INTO open_questions table
4. **Identity shifts** → INSERT INTO identity_evolution table

**Rule:** A reflection without action items is a wasted reflection.

## Cleanup

Automatic cleanup runs daily:

```sql
-- Remove old daily_logs
DELETE FROM daily_logs WHERE distilled = 1
  AND date < date('now', '-30 days');

-- Remove old reflections
DELETE FROM reflections WHERE distilled = 1
  AND date < date('now', '-30 days');

-- Stale questions become cancelled
UPDATE open_questions SET status = 'stale'
  WHERE status = 'open'
  AND created_at < strftime('%s','now','-30 days');

-- Old action items become cancelled
UPDATE action_items SET status = 'cancelled'
  WHERE status = 'open'
  AND created_at < strftime('%s','now','-60 days');
```

## License

MIT

---

**Built for AI agents that need more memory with fewer tokens.** 🏛️
