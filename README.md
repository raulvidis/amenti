# Amenti 🏛️

Persistent memory for AI agents. More memory, fewer tokens.

Amenti replaces bloated context files with a SQLite-backed memory system using **hybrid search: FTS5 full-text + vector embeddings (semantic)**. Agents boot with a tiny task list and retrieve relevant memories on demand.

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

- **Hybrid search** — FTS5 keywords + LIKE fallback + vector similarity (semantic)
- **Local embeddings** — all-MiniLM-L6-v2 (80MB, 384d, ~1ms/embed, zero API cost)
- **Auto-embed on store** — new memories get vectorized automatically
- **CLI abstraction** — `amenti search`, `amenti store`, `amenti budget` — no raw SQL
- **Memory linking** — memories form a graph (supports, contradicts, depends_on, related)
- **Context budget** — "give me top memories that fit in N tokens"
- **Confidence scoring** — every memory scored 0.0–1.0, no confabulation
- **Smart retention** — high-confidence data auto-promotes before 30-day cleanup
- **Multi-agent** — agents share a DB, scoped by agent_id
- **Action-driven reflections** — reflections produce tasks, not just summaries
- **Task management** — built-in action items with priority and status tracking
- **Token efficient** — 80-95% reduction vs file-based memory

## Search Architecture

Amenti uses a 3-strategy hybrid search that combines precision with understanding:

```
Query → FTS5 (exact keywords)     → results
      → LIKE (partial match)      → merged & deduplicated
      → Vector similarity (semantic) → sorted by relevance
```

| Strategy | Strengths | Example |
|----------|-----------|---------|
| FTS5 | Exact keyword hits, instant | "Docker restart policy" → finds "Docker restart" |
| LIKE | Partial matches, typo-tolerant | "deploy" → finds "deployment" |
| Vector | Semantic understanding | "significant other abroad" → finds "girlfriend in Japan" |

When the embed server is running, all three strategies run on every search. Results are merged, deduplicated, and ranked. When it's not running, FTS5 + LIKE still work normally.

## Schema

8 tables:

| Table | Purpose |
|-------|---------|
| `memories` | Permanent knowledge (FTS5, vector embeddings, linked, tagged) |
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
export AMENTI_DB=/path/to/amenti.db
export AMENTI_AGENT=your_agent_name
./scripts/init-db.sh

# 2. Install the CLI
ln -s $(pwd)/bin/amenti /usr/local/bin/amenti

# 3. Migrate existing file-based memory
./scripts/migrate.sh /path/to/agent/workspace

# 4. Copy templates to agent workspace
cp templates/MEMORY.md /path/to/workspace/MEMORY.md
cp templates/SKILL.md /path/to/workspace/skills/amenti/SKILL.md
```

### Vector Embeddings (recommended)

```bash
# Install dependencies
pip3 install sentence-transformers

# Start the embed server (~500MB RAM, loads all-MiniLM-L6-v2)
python3 src/embed_server.py &

# Or with PM2 for persistence:
pm2 start src/embed_server.py --name amenti-embed --interpreter python3
pm2 save

# Embed all existing memories
./scripts/reindex.sh --force
```

The embed server runs on `localhost:9819`. When running:
- `amenti store` auto-embeds new memories (🧬 indicator)
- `amenti search` uses all 3 strategies (FTS5 + LIKE + vector)
- Swap models anytime — just `reindex.sh --force` after

## CLI

```bash
# Search (hybrid: FTS5 + LIKE + vector)
amenti search "deployment issues" --type fact --min-confidence 0.8

# Store (auto-embeds when embed server is running)
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

# Vector reindex
amenti reindex              # embed non-embedded memories
amenti reindex --force      # re-embed ALL (after model swap)

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

Before 30-day cleanup:

1. High-confidence memories (≥0.80) from reflections are **auto-promoted** to permanent
2. Distilled daily logs and reflections are deleted
3. Stale questions (30d) are marked stale
4. Abandoned action items (60d) are cancelled
5. Orphaned memory links are cleaned

## Memory Linking

Memories form a graph:

```bash
amenti link 5 12 --relation supports    # "quit corporate" supports "revenue target"
amenti link 8 3 --relation depends_on   # "V2 plan" depends on "server migration"
amenti recall 5                         # Shows memory #5 + all linked memories
```

Relations: `supports`, `contradicts`, `depends_on`, `related`, `supersedes`

## Task Management

Tasks live in the database, not files:

```bash
amenti task --add --description "Deploy to staging" --priority high
amenti tasks --status open
amenti tasks --status in_progress
amenti task --done 3
amenti task --cancel 5
```

Recommended cron cycles:
- **Every 30 min:** Check open tasks, update stuck ones
- **Every 2 hours:** Analyze task landscape, generate suggestions

## Multi-Agent

Multiple agents share one database, scoped by agent_id:

```bash
export AMENTI_AGENT=nova
amenti store --type fact --content "..."

export AMENTI_AGENT=cleo
amenti search "calendar events" --agent nova  # Cross-agent search
```

## Embed Server

The embed server provides local vector embeddings with zero API cost:

| Property | Value |
|----------|-------|
| Model | all-MiniLM-L6-v2 |
| Dimensions | 384 |
| RAM | ~500MB |
| Speed | ~1ms per embedding (after model load) |
| Port | 9819 (configurable via `AMENTI_EMBED_PORT`) |

**Endpoints:**
- `POST /embed` — Embed single text: `{"text": "..."}`
- `POST /embed_batch` — Embed multiple: `{"texts": ["...", "..."]}`
- `GET /health` — Health check
- `GET /info` — Model info

**Swapping models:** Change `AMENTI_EMBED_MODEL` env var, restart server, run `amenti reindex --force`.

## Project Structure

```
amenti/
├── README.md
├── LICENSE
├── bin/
│   └── amenti                # CLI tool (bash)
├── src/
│   ├── schema.sql            # SQLite schema (8 tables, FTS5, triggers, views)
│   ├── schema_vec.sql        # Vector embedding migration
│   └── embed_server.py       # Local embedding server (MiniLM)
├── templates/
│   ├── MEMORY.md             # Lean memory.md template
│   ├── AGENTS.md             # Agent config template
│   └── SKILL.md              # Agent skill file (how to use Amenti)
├── scripts/
│   ├── init-db.sh            # Initialize database
│   ├── migrate.sh            # Migrate from file-based memory
│   ├── reindex.sh            # Batch embed all memories
│   └── cleanup.sh            # Smart cleanup with auto-promotion
└── docs/
    └── ARCHITECTURE.md       # Design decisions and rationale
```

## License

MIT

---

**Built for AI agents that remember.** 🏛️
