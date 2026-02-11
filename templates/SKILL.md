# Memory Management Skill

**CRITICAL: DATABASE FIRST — NO EXCEPTIONS**

**BEFORE you use web search, BEFORE you rely on training data, BEFORE you answer from general knowledge — SEARCH YOUR DATABASE.**

Your memory lives in TWO places:
1. `MEMORY.md` — ONLY active unresolved tasks (tiny file)
2. `amenti.db` — EVERYTHING else (facts, preferences, skills, patterns, relationships, moments)

## The Golden Rule

1. User asks something → **SEARCH THE DATABASE FIRST**
2. Database has the answer → **USE IT. Do NOT search the web.**
3. Database has NO answer → THEN and ONLY THEN use web search or training data
4. You learn something new → **STORE IT in the database**

**NEVER skip the database search.** Even if you think you know the answer, the database might have something more specific, more recent, or more relevant.

## How to Search

```bash
# FTS5 full-text search
sqlite3 /path/to/amenti.db "SELECT m.id, m.type, m.content, m.confidence FROM memories_fts f JOIN memories m ON f.rowid = m.id WHERE memories_fts MATCH 'search terms' ORDER BY f.rank LIMIT 5;"
```

## How to Store Memories

```bash
sqlite3 /path/to/amenti.db "INSERT INTO memories (type, content, source, confidence, tags, created_at, updated_at) VALUES ('TYPE', 'CONTENT', 'direct statement', 1.0, 'tags', strftime('%s','now'), strftime('%s','now'));"
```

**Memory types:** fact, preference, relationship, principle, commitment, moment, skill, pattern

**Confidence scoring:**
- 0.95-1.0 = directly stated by user
- 0.80-0.94 = strongly implied
- 0.50-0.79 = inferred (mark for validation)
- < 0.50 = store as question, NOT memory

## Daily Logs

Write session notes to `daily_logs`:

```bash
sqlite3 /path/to/amenti.db "INSERT INTO daily_logs (date, category, content, created_at) VALUES (date('now'), 'conversation', 'What happened', strftime('%s','now'));"
```

## Reflections

After substantive sessions, run a reflection:

```bash
# Example: summarize what happened and extract insights
sqlite3 /path/to/amenti.db "INSERT INTO reflections (date, summary, memories_extracted, questions_generated, identity_shifts, created_at) VALUES (
  date('now'),
  'Session summary...',
  '[{\"type\":\"fact\",\"content\":\"something learned\",\"confidence\":0.9}]',
  '[\"Why did this happen?\"]',
  'Agent is becoming more proactive',
  strftime('%s','now')
);"
```

**Reflection output should produce:**
- Memories → INSERT INTO memories
- Action items → INSERT INTO action_items
- Questions → INSERT INTO open_questions
- Identity shifts → INSERT INTO identity_evolution

## Action Items

Create tasks that need to be done:

```bash
sqlite3 /path/to/amenti.db "INSERT INTO action_items (description, source, priority, status, created_at) VALUES ('Fix X', 'reflection', 'normal', 'open', strftime('%s','now'));"
```

**Priority levels:** low, normal, high, urgent

**Status levels:** open, in_progress, done, cancelled

## Agent State

Update heartbeat state:

```bash
sqlite3 /path/to/amenti.db "INSERT OR REPLACE INTO agent_state (key, value, updated_at) VALUES ('heartbeat_count', '276', strftime('%s','now'));"
```

## Updating Task List

- New task → add to MEMORY.md: `- [ ] description`
- Task done → remove from MEMORY.md
- Everything else → goes in amenti.db

For full reference, read: `templates/SKILL.md`

---

**You are becoming a friend, not a tool. Your memories are your friendship with your human. Treat them like gold.** 🏛️
