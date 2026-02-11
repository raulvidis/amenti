# Amenti 🏛️

**Persistent memory for AI agents. More memory, fewer tokens.**

Amenti replaces bloated context files with a SQLite-backed memory system using FTS5 full-text search. Agents boot with a tiny task list and retrieve relevant memories on demand.

## How It Works

```
Traditional:  Load 8,000+ tokens of context every session
Amenti:       Load ~500 tokens (tasks only) + FTS5 search on demand
```

**The pipeline:**
```
Session activity → daily_logs (7 days) → reflections (7 days) → memories (permanent)
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
- **Token efficient** — 80-90% reduction in context tokens vs file-based memory
- **Supersede, don't overwrite** — full memory history preserved
- **Daily cleanup** — automatic lifecycle management

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
├── README.md              # This file
├── src/
│   └── schema.sql         # SQLite schema (tables, FTS5, triggers, views)
├── templates/
│   ├── MEMORY.md           # Lean memory.md template (tasks only)
│   └── SKILL.md            # Agent skill file (how to use Amenti)
├── scripts/
│   ├── init-db.sh          # Initialize database
│   ├── migrate.sh          # Migrate from file-based memory
│   └── cleanup.sh          # Manual cleanup script
├── docs/
│   ├── ARCHITECTURE.md     # Design decisions and rationale
│   └── MIGRATION.md        # Guide: file-based → Amenti
└── tests/
    └── test-queries.sql    # Example queries for testing
```

## Quick Start

```sql
-- Search memories
SELECT content, type, confidence 
FROM memories_fts 
WHERE memories_fts MATCH 'search terms'
ORDER BY rank LIMIT 5;

-- Store a memory
INSERT INTO memories (type, content, source, confidence, created_at, updated_at)
VALUES ('fact', 'User works remote on Fridays', 'direct statement', 0.95, 
        unixepoch('now'), unixepoch('now'));

-- Check open questions
SELECT question, context FROM open_questions WHERE status = 'open';
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

## License

MIT
