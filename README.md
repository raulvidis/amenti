# Amenti 🏛️

**Persistent memory for AI agents.** More memory, fewer tokens.

Amenti replaces bloated context files with a SQLite-backed memory system using **hybrid search: FTS5 + vector embeddings**. Agents boot with a tiny index and retrieve memories on demand.

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)

---

## Quickstart

**One-liner install:**
```bash
curl -sSL https://raw.githubusercontent.com/raulvidis/amenti/main/install.sh | bash
```

**Manual install:**
```bash
git clone https://github.com/raulvidis/amenti.git
cd amenti
export AMENTI_DB=/path/to/amenti.db
export AMENTI_AGENT=your_agent_name
./scripts/init-db.sh
ln -s $(pwd)/bin/amenti /usr/local/bin/amenti
```

**With vector embeddings (recommended):**
```bash
pip3 install sentence-transformers
pm2 start src/embed_server.py --name amenti-embed --interpreter python3
./scripts/reindex.sh --force
```

---

## Agent Skill Package

Amenti includes a ready-to-use skill package for AI agents. The install script **automatically detects your agent's skills directory** and copies everything into place — no manual setup needed.

After installation, your agent gets:

```
<agent-skills-dir>/amenti/
├── SKILL.md                  # Main skill file with YAML frontmatter
└── references/
    └── distillation-guide.md # Migration guide (loaded on demand)
```

The skill follows the [Anthropic Agent Skills format](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf) with:
- **Progressive disclosure** — Frontmatter triggers → SKILL.md body → references/
- **Rich description** — Trigger phrases for automatic loading
- **Troubleshooting section** — Common issues and solutions

> If your agent uses a non-standard skills directory, set `AMENTI_SKILLS_DIR` before running the installer.

---

## How It Works

| Traditional | Amenti |
|-------------|--------|
| Load 8,000+ tokens every session | Load ~500 tokens + search on demand |
| Context bloat over time | Constant-size memory index |
| Manual updates | Auto-distillation + smart cleanup |

```
Session activity → daily_logs (30 days) → reflections → memories (permanent)
                                                      → action_items (tasks)
                                                      → open_questions
```

---

## Features

- **Hybrid search** — FTS5 keywords + LIKE fallback + vector embeddings (semantic)
- **Local embeddings** — all-MiniLM-L6-v2 (80MB, 384d, ~1ms/embed, zero API cost)
- **Confidence scoring** — Every memory scored 0.0–1.0
- **Memory linking** — Memories form a graph (supports, contradicts, depends_on)
- **Context budget** — "Top memories that fit in N tokens"
- **Multi-agent** — Agents share a DB, scoped by agent_id
- **Task management** — Built-in action items with priority tracking
- **Smart cleanup** — High-confidence data auto-promotes before 30-day cleanup

---

## Search Architecture

```
Query → FTS5 (exact keywords)     → results
      → LIKE (partial match)      → merged & deduplicated
      → Vector (semantic)         → sorted by relevance
```

| Strategy | Example |
|----------|---------|
| FTS5 | "Docker restart policy" → finds exact match |
| LIKE | "deploy" → finds "deployment" |
| Vector | "significant other abroad" → finds "partner lives abroad" |

---

## CLI Reference

```bash
# Search memories
amenti search "deployment issues" --type fact --min-confidence 0.8

# Store memory (auto-embeds when embed server running)
amenti store --type fact --content "..." --confidence 0.95 --tags "tag1,tag2"

# Recall with linked context
amenti recall 5

# Context budget (top memories within N tokens)
amenti budget 2000

# Task management
amenti task --add --description "Fix pipeline" --priority high
amenti tasks --status open
amenti task --done 3

# Daily logs
amenti log "Fixed Docker issue" --category task
amenti logs --search "docker"

# Stats
amenti stats

# Vector reindex
amenti reindex              # embed non-embedded memories
amenti reindex --force      # re-embed ALL (after model swap)
```

---

## Memory Types

| Type | What it is | Example |
|------|-----------|---------|
| `fact` | Verifiable info | "User works remotely 3 days/week" |
| `preference` | Likes/dislikes | "Hates fluff, values directness" |
| `relationship` | People & dynamics | "Partner lives abroad" |
| `principle` | Rules or values | "Always backup before editing" |
| `commitment` | Promises or plans | "Launch V2 by March" |
| `moment` | Emotionally significant | "First successful deployment" |
| `skill` | Technical knowledge | "Docker needs on-failure policy" |
| `pattern` | Recurring behaviors | "Codes more on weekends" |

---

## Confidence Scoring

| Score | Meaning |
|-------|---------|
| 0.95–1.0 | Directly stated by human |
| 0.80–0.94 | Strongly implied or observed |
| 0.50–0.79 | Inferred (mark for validation) |
| < 0.50 | Store as question, not memory |

---

## Embed Server

| Property | Value |
|----------|-------|
| Model | all-MiniLM-L6-v2 |
| Dimensions | 384 |
| RAM | ~500MB |
| Speed | ~1ms per embedding |
| Port | 9819 (configurable) |

```bash
# Start with PM2
pm2 start src/embed_server.py --name amenti-embed --interpreter python3
pm2 save
```

**Endpoints:**
- `POST /embed` — Embed single text
- `POST /embed_batch` — Embed multiple texts
- `GET /health` — Health check

---

## Project Structure

```
amenti/
├── bin/amenti          # CLI tool
├── src/
│   ├── schema.sql      # SQLite schema (8 tables, FTS5, triggers)
│   └── embed_server.py # Local embedding server
├── templates/
│   ├── MEMORY.md       # Lean memory.md template
│   └── SKILL.md        # Agent skill file
├── scripts/
│   ├── init-db.sh      # Initialize database
│   ├── migrate.sh      # Migrate from file-based memory
│   ├── reindex.sh      # Batch embed all memories
│   └── cleanup.sh      # Smart cleanup
└── docs/
    └── ARCHITECTURE.md # Design decisions
```

---

## Multi-Agent

```bash
export AMENTI_AGENT=your_agent_name
amenti store --type fact --content "..."

export AMENTI_AGENT=assistant_two
amenti search "calendar" --agent your_agent_name  # Cross-agent search
```

---

## Migrating from File-Based Memory

```bash
# Migrate existing MEMORY.md, daily logs, reflections
./scripts/migrate.sh /path/to/agent/workspace

# Copy templates
cp templates/MEMORY.md /path/to/workspace/MEMORY.md
cp templates/SKILL.md /path/to/workspace/skills/amenti/SKILL.md

# Verify
amenti stats
```

See `templates/SKILL.md` for the full migration guide.

---

## Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **CPU** | Any x86_64 / ARM64 | 2+ cores |
| **RAM** | 256MB (no embeddings) | 1GB (with embed server) |
| **Disk** | 50MB + DB size | 500MB (model + DB growth) |
| **SQLite** | 3.35+ (FTS5 support) | 3.40+ |
| **Bash** | 4.0+ | 5.0+ |
| **Python** | 3.8+ (embeddings only) | 3.10+ |
| **OS** | Linux, macOS | Ubuntu 22.04+, macOS 13+ |

The embed server loads `all-MiniLM-L6-v2` (~80MB model) and uses ~500MB RAM at runtime. Without embeddings, Amenti runs on virtually anything — a Raspberry Pi, a VPS, a laptop.

---

## Inspiration

Search pipeline inspired by [QMD](https://github.com/tobi/qmd) by Tobi Lütke — RRF fusion, BM25 normalization, and embedding cache concepts adapted for agent memory.

---

## License

MIT — use it, fork it, improve it.

---

**Built for AI agents that remember.** 🏛️
