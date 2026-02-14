# Amenti — Persistent Memory Skill 🏛️

## Setup (run once)

If you don't have an `amenti.db` in your workspace yet, set yourself up:

```bash
# 1. Init the database
export AMENTI_DB=/path/to/your/workspace/amenti.db
cd /path/to/amenti && ./scripts/init-db.sh

# 2. Install CLI globally
ln -sf /path/to/amenti/bin/amenti /usr/local/bin/amenti

# 3. Set your agent ID
export AMENTI_AGENT=your_agent_name

# 4. Migrate your existing memory files into the database
./scripts/migrate.sh /path/to/your/workspace

# 5. Verify migration
amenti stats
```

After migration, your MEMORY.md should only contain active tasks. Everything else (lessons, insights, facts, relationships) now lives in the database.

**Trim your MEMORY.md** — remove everything except `## Active Tasks` with `- [ ]` items. The database has the rest.

**Update your AGENTS.md** — add this to your memory section:
```
You use Amenti for persistent memory. Search the database before answering:
  amenti search "keywords"
Store new knowledge:
  amenti store --type TYPE --content "..." --confidence 0.95 --tags "keyword1,keyword2"
Use amenti log instead of daily memory files.
For full reference: skills/amenti/SKILL.md
```

---

## The Golden Rule

**BEFORE you use web search, BEFORE you rely on training data — SEARCH YOUR DATABASE.**

1. User asks something → `amenti search "keywords"` FIRST
2. Database has the answer → USE IT. Do NOT search the web.
3. Database has NO answer → THEN use web search or training data
4. You learn something new → `amenti store` it with tags

---

## Environment

Set these before using the CLI:

```bash
export AMENTI_DB=/path/to/workspace/amenti.db
export AMENTI_AGENT=your_agent_name
```

---

## CLI Reference

### Search

```bash
amenti search "deployment issues"
amenti search "Docker" --type skill --min-confidence 0.8 --limit 5
```

**FTS5 is keyword-based.** If a search returns nothing, try synonyms. "work frustrations" → try "corporate" or "hate job".

### Store

```bash
amenti store --type fact --content "User works at esports company" --confidence 0.95 --tags "work,job,esports"
```

**ALWAYS include tags.** Tags are comma-separated keywords including synonyms that help search find this memory later.

**Types:** fact, preference, relationship, principle, commitment, moment, skill, pattern

**Confidence:** 0.95-1.0 direct, 0.80-0.94 implied, 0.50-0.79 inferred, <0.50 store as question not memory

### Recall (with linked memories)

```bash
amenti recall 5
```

### Link

```bash
amenti link 5 12 --relation supports
```

**Relations:** supports, contradicts, depends_on, related, supersedes

### Supersede (replace, preserving history)

```bash
amenti supersede 5 --content "Updated info"
```

### Forget (deactivate)

```bash
amenti forget 12
```

### Action Items

```bash
amenti task --add --description "Fix pipeline" --priority high
amenti tasks --status open
amenti task --done 3
amenti task --cancel 5
```

**Priority:** low, normal, high, urgent

### Questions (low-confidence observations)

```bash
amenti ask "Does user prefer morning coding?" --context "More commits after 8pm"
amenti answer 2 "Confirmed: evening coder"
amenti questions
```

### Daily Logs (replaces memory/YYYY-MM-DD.md files)

```bash
amenti log "Discussed deployment strategy" --category decision
amenti logs --date 2026-02-11
amenti logs --search "deployment"
```

### Reflections

```bash
amenti reflect "Fixed Docker issues, learned user preferences" \
  --memories '[{"type":"skill","content":"Docker needs on-failure","confidence":0.95}]' \
  --questions '["What other Docker issues?"]'
```

### Context Budget (top memories within N tokens)

```bash
amenti budget 2000
```

### Agent State

```bash
amenti state                        # show all
amenti state heartbeat_count 276    # set value
```

### Identity Evolution

```bash
amenti identity "Becoming more proactive" --trigger "User feedback"
```

### Stats & Export

```bash
amenti stats
amenti export
amenti export --type skill
```

---

## Multi-Agent

Scope operations by agent:

```bash
export AMENTI_AGENT=nova       # all ops scoped to nova
amenti search "calendar" --agent cleo  # search another agent's memories
```

---

## Maintenance

Run cleanup periodically (or add to heartbeat):

```bash
/path/to/amenti/scripts/cleanup.sh
```

This auto-promotes high-confidence memories before deleting old data, cleans orphaned links, stales old questions, cancels abandoned tasks.

---

**Your memories are your friendship with your human. Treat them like gold.** 🏛️
