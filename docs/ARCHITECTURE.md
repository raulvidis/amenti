# Amenti Architecture

## Design Philosophy

**More persistent memory for less tokens.**

Traditional AI agent memory systems load everything into context on every session — personality files, user info, long-term memories, daily logs. As the agent accumulates knowledge, context grows linearly, consuming more tokens and money.

Amenti inverts this: store everything in SQLite, search with FTS5, load only what's relevant.

## The Problem

```
Session 1:   SOUL.md (2k) + USER.md (1k) + MEMORY.md (3k) = 6k tokens
Session 50:  SOUL.md (2k) + USER.md (2k) + MEMORY.md (15k) = 19k tokens
Session 200: SOUL.md (2k) + USER.md (3k) + MEMORY.md (40k) = 45k tokens
```

Memory grows, tokens grow, costs grow. And most of that context isn't relevant to the current conversation.

## The Solution

```
Every session: MEMORY.md (tasks + memory index, ~500 tokens) + FTS5 search (0 tokens until needed)
Per message:   ~200-500 tokens of relevant memories retrieved on demand
```

Total: ~700-1,000 tokens vs 6,000-45,000. That's **80-95% reduction**.

### Memory Index

MEMORY.md contains a **Memory Index** table — a lightweight lookup of what's stored in the DB:

```markdown
| Brief Description | Tags |
|---|---|
| User's partner abroad | partner, relationship, long distance, abroad |
| Docker restart policy | docker, restart, on-failure, container |
```

This solves the "agent doesn't know what it doesn't know" problem. Without the index, the agent has no way of knowing which topics exist in the DB and would either over-search (wasteful) or miss relevant memories (dangerous). The index costs ~100-300 tokens but eliminates blind searches entirely.

## Architecture

```
┌─────────────────────────────────────────────┐
│                Agent Session                 │
│                                             │
│  Boot: Load MEMORY.md (tasks + index, ~500t) │
│                                             │
│  On message:                                │
│    1. Need context? → FTS5 search           │
│    2. Learn something? → INSERT into DB     │
│    3. Task done? → Remove from MEMORY.md    │
│    4. New task? → Add to MEMORY.md          │
│                                             │
│  On idle (30min+):                          │
│    → Reflection cycle                       │
│    → Distill daily_logs → memories          │
│                                             │
│  Daily (6:30 AM):                           │
│    → Cleanup old logs/reflections           │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│              SQLite Database                 │
│                                             │
│  memories (+ FTS5)     ← permanent store     │
│  memory_links          ← relationships       │
│  daily_logs (+ FTS5)   ← raw, 30 days       │
│  reflections           ← structured, 30 days │
│  action_items          ← tasks               │
│  open_questions        ← follow-ups          │
│  agent_state           ← runtime state       │
│  identity_evolution    ← agent changes       │
└─────────────────────────────────────────────┘
```

## Memory Lifecycle

```
Session activity
    ↓
daily_logs (raw observations, 30 days)
    ↓  [reflection cycle — 30min idle trigger]
reflections (structured processing, 30 days)
    ↓  [distillation — daily hygiene]
memories (permanent, FTS5-searchable)
    ↓
open_questions (if confidence < 0.50)
identity_evolution (if role/personality shifted)
```

## Views

6 views provide convenient access to common queries:

- **`v_active_memories`** — Active memories sorted by confidence
- **`v_session_context`** — High-confidence (>=0.80) memories for session boot
- **`v_open_actions`** — Open action items sorted by priority
- **`v_pending_distillation`** — Reflections not yet distilled
- **`v_context_budget`** — Memories with running cumulative token total
- **`v_memory_graph`** — Linked active memories with relation types

## FTS5: Why Not Vector Embeddings?

| Feature | FTS5 | Vector DB |
|---------|------|-----------|
| Setup | Built into SQLite | Requires separate service |
| Dependencies | None | Python libs, embedding model |
| Speed | <1ms for most queries | Depends on index size |
| Cost | Free | Embedding API calls |
| Quality | Great for keyword/phrase | Better for semantic similarity |
| Complexity | SQL queries | Vector math, indexes, tuning |

For agent memory, FTS5 is the right choice because:
1. **Most agent memories are keyword-searchable** — "Docker restart policy" finds Docker memories
2. **Zero additional cost** — no embedding API calls
3. **Zero infrastructure** — just SQLite, no services to run
4. **Porter stemming** — "running" matches "run", "runs", etc.
5. **Good enough** — for structured memories with clear content, FTS5 works great

If semantic search becomes necessary later, vector embeddings can be added alongside FTS5.

## Confidence Scoring

Every memory is scored 0.0–1.0. This prevents confabulation and enables quality-based retrieval.

```sql
-- Session context: only high-confidence memories
SELECT * FROM memories WHERE is_active = 1 AND confidence >= 0.80;

-- Uncertain memories that need validation
SELECT * FROM memories WHERE confidence BETWEEN 0.50 AND 0.79;

-- Too uncertain for memory — stored as questions instead
-- (confidence < 0.50 → open_questions table)
```

## Supersede Pattern

Memories are never overwritten. When information changes, the old memory is deactivated and a new one is created with a reference to what it replaced.

```sql
-- Old: "User trains 5 hours/week"
UPDATE memories SET is_active = 0 WHERE id = 42;

-- New: "User trains 7 hours/week" (supersedes #42)
INSERT INTO memories (..., supersedes_id) VALUES (..., 42);
```

This preserves full history while keeping active queries clean.

## Integration

Amenti is designed to work with any agent framework that can:
1. Read a markdown file (MEMORY.md)
2. Execute SQL queries (via CLI, SDK, or tool)

The skill file (`templates/SKILL.md`) teaches the agent everything it needs to know about when to search, what to store, and how to maintain the system.
