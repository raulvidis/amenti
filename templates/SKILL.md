# Memory Management Skill — Amenti 🏛️

## ⚠️ MANDATORY: DATABASE FIRST — NO EXCEPTIONS

**BEFORE you use web search, BEFORE you rely on training data, BEFORE you answer from general knowledge — SEARCH YOUR DATABASE.**

Your memory lives in TWO places:
1. `MEMORY.md` — ONLY active unresolved tasks (tiny file)
2. `amenti.db` — EVERYTHING else (facts, preferences, skills, patterns, relationships)

## The Golden Rule

1. User asks something → **SEARCH THE DATABASE FIRST**
2. Database has the answer → **USE IT. Do NOT search the web.**
3. Database has NO answer → THEN and ONLY THEN use web search or training data
4. You learn something new → **STORE IT in the database**

## CLI Commands

Use the `amenti` CLI for all database operations. Never write raw SQL.

### Searching

```bash
# Search memories (FTS5 full-text search)
amenti search "deployment issues"
amenti search "Docker" --type skill --min-confidence 0.8 --limit 5

# Search daily logs
amenti logs --search "debugging session"
amenti logs --date 2026-02-11
```

**Search tips:** FTS5 matches keywords, not meaning. If "work frustrations" finds nothing, try "corporate" or "job" or "hate work". Try multiple search terms.

### Storing Memories

```bash
amenti store --type fact --content "User works at esports company" --confidence 0.95 --tags "work,job,esports"
amenti store --type preference --content "Hates corporate fluff" --confidence 0.90 --tags "work,communication,directness"
amenti store --type skill --content "Docker MaximumRetryCount only works with on-failure" --confidence 0.95 --tags "docker,restart,config"
```

**ALWAYS include tags.** Tags are comma-separated keywords that help FTS5 find memories even when search terms don't match the content exactly. Include synonyms and related words.

**Memory types:** fact, preference, relationship, principle, commitment, moment, skill, pattern

**Confidence scoring:**
- 0.95-1.0 = directly stated by user
- 0.80-0.94 = strongly implied
- 0.50-0.79 = inferred (mark for validation)
- < 0.50 = store as question, NOT memory

### Linking Memories

```bash
# Link related memories
amenti link 5 12 --relation supports
amenti link 8 3 --relation related

# Recall a memory with its links
amenti recall 5
```

**Relations:** supports, contradicts, depends_on, related, supersedes

### Updating Memories

```bash
# Replace a memory (preserves history)
amenti supersede 5 --content "Updated information about X"

# Deactivate a memory
amenti forget 12
```

### Action Items

```bash
# Add a task
amenti task --add --description "Fix deployment pipeline" --priority high --source user_request

# List open tasks
amenti tasks --status open --priority high

# Complete or cancel
amenti task --done 3
amenti task --cancel 5
```

### Questions

```bash
# Ask a question (low-confidence observations)
amenti ask "Does user prefer morning or evening coding?" --context "Noticed more commits after 8pm"

# Answer a question
amenti answer 2 "Confirmed: prefers evening coding sessions"

# List open questions
amenti questions
```

### Daily Logs

```bash
# Log something
amenti log "Discussed deployment strategy with user" --category decision

# Browse logs
amenti logs --date 2026-02-11
amenti logs --search "deployment"
```

### Reflections

```bash
amenti reflect "Productive session: fixed Docker issues, learned about user preferences" \
  --memories '[{"type":"skill","content":"Docker needs on-failure","confidence":0.95}]' \
  --questions '["What other Docker issues might come up?"]'
```

### Context Budget

```bash
# Get top memories that fit within N tokens
amenti budget 2000
```

### Agent State

```bash
# Get all state
amenti state

# Get/set specific key
amenti state heartbeat_count
amenti state heartbeat_count 276
```

### Stats

```bash
amenti stats
```

### Identity Evolution

```bash
amenti identity "Becoming more proactive about reaching out" --trigger "User feedback on check-ins"
```

### Export

```bash
# Export all memories as JSON
amenti export
amenti export --type skill
```

## Multi-Agent

Set `AMENTI_AGENT` to scope all operations to a specific agent:

```bash
export AMENTI_AGENT=nova
amenti search "deployment"  # Only searches Nova's memories

export AMENTI_AGENT=cleo
amenti store --type fact --content "..."  # Stored as Cleo's memory
```

Agents can share the same database and search each other's memories by passing `--agent`:

```bash
amenti search "calendar" --agent cleo
```

## Task Management

- New task → add to MEMORY.md: `- [ ] description` AND `amenti task --add`
- Task done → remove from MEMORY.md AND `amenti task --done <id>`
- Everything else → goes in amenti.db via CLI

---

**Your memories are your friendship with your human. Treat them like gold.** 🏛️
