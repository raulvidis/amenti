# Amenti 🏛️

Persistent memory for AI agents. More memory, fewer tokens.

Amenti replaces bloated context files with a SQLite-backed memory system using FTS5 full-text search. Agents boot with a tiny task list and retrieve relevant memories on demand.

## How It Works

**Traditional:** Load 8,000+ tokens of context every session
**Amenti:** Load ~500 tokens (tasks + Memory Index) + search on demand

**Requires:** SQLite3, Bash, Python3

```
Session activity → daily_logs (30 days) → reflections → memories (permanent)
                                                      → action_items (tasks)
                                                      → open_questions
                                                      → identity_evolution
```

## Features

- **FTS5 full-text search** — fast keyword search across all memories, zero maintenance
- **CLI abstraction** — `amenti search`, `amenti store`, `amenti budget` — no raw SQL
- **Memory linking** — memories form a graph (supports, contradicts, depends_on, related)
- **Context budget** — "give me top memories that fit in N tokens"
- **Confidence scoring** — every memory scored 0.0–1.0, no confabulation
- **Smart retention** — high-confidence data auto-promotes before 30-day cleanup
- **Multi-agent** — agents share a DB, scoped by agent_id
- **Action-driven reflections** — reflections produce tasks, not just summaries
- **Token efficient** — 80-95% reduction vs file-based memory

## Schema

8 tables:

| Table | Purpose |
|-------|---------|
| `memories` | Permanent knowledge (FTS5, linked, tagged, token-estimated) |
| `memory_links` | Relationships between memories (graph) |
| `daily_logs` | Raw session notes (30 days, FTS5) |
| `reflections` | Structured processing |
| `action_items` | Tasks born from reflections or sessions |
| `open_questions` | Things to follow up on |
| `agent_state` | Runtime state (heartbeat, counters) |
| `identity_evolution` | How the agent changes over time |

## Installation

```bash
# 1. Initialize the database
./scripts/init-db.sh

# 2. Install the CLI
ln -s $(pwd)/bin/amenti /usr/local/bin/amenti
export AMENTI_DB=/path/to/amenti.db

# 3. Migrate existing file-based memory
./scripts/migrate.sh /path/to/agent/workspace

# 4. Copy templates to agent workspace
cp templates/MEMORY.md /path/to/workspace/MEMORY.md
cp templates/SKILL.md /path/to/workspace/skills/amenti/SKILL.md
```

## CLI

```bash
# Search
amenti search "deployment issues" --type fact --min-confidence 0.8

# Store (with tags for better FTS5 hits)
amenti store --type fact --content "User loves sim racing" --confidence 0.95 --tags "hobby,racing,iracing"

# Link memories
amenti link 5 12 --relation supports

# Recall with linked context
amenti recall 5

# Context budget — top memories within N tokens
amenti budget 2000

# Action items
amenti task --add --description "Fix pipeline" --priority high
amenti tasks --status open
amenti task --done 3

# Daily logs
amenti log "Fixed Docker restart policy issue" --category task
amenti logs --search "docker"

# Stats
amenti stats

# Multi-agent
AMENTI_AGENT=nova amenti search "calendar"
AMENTI_AGENT=cleo amenti store --type fact --content "..."
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

## Smart Retention

Not all data is equal. Before 30-day cleanup:

1. High-confidence memories (≥0.80) from reflections are **auto-promoted** to permanent
2. Distilled daily logs and reflections are deleted
3. Stale questions (30d) are marked stale
4. Abandoned action items (60d) are cancelled
5. Orphaned memory links are cleaned

## Memory Linking

Memories aren't flat — they form a graph:

```bash
amenti link 5 12 --relation supports    # "quit corporate" supports "revenue target"
amenti link 8 3 --relation depends_on   # "V2 plan" depends on "server migration"
amenti recall 5                         # Shows memory #5 + all linked memories
```

Relations: `supports`, `contradicts`, `depends_on`, `related`, `supersedes`

## Multi-Agent

Multiple agents can share one database:

```bash
export AMENTI_AGENT=nova     # All operations scoped to Nova
amenti store --type fact --content "..."

export AMENTI_AGENT=cleo     # Switch to Cleo
amenti search "calendar events" --agent nova  # Search Nova's memories from Cleo
```

## Project Structure

```
amenti/
├── README.md
├── LICENSE
├── bin/
│   └── amenti               # CLI tool
├── src/
│   └── schema.sql           # SQLite schema (8 tables, FTS5, triggers, views)
├── templates/
│   ├── MEMORY.md            # Lean memory.md template (tasks only)
│   └── SKILL.md             # Agent skill file (how to use Amenti)
├── scripts/
│   ├── init-db.sh           # Initialize database
│   ├── migrate.sh           # Migrate from file-based memory
│   └── cleanup.sh           # Smart cleanup with auto-promotion
└── docs/
    └── ARCHITECTURE.md      # Design decisions and rationale
```

## License

MIT

---

**Built for AI agents that remember.** 🏛️
