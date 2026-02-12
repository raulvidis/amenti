# Amenti — Persistent Memory Skill 🏛️

## Setup (run once)

```bash
# 1. Set environment (add to your shell profile)
export AMENTI_DB=$HOME/.openclaw/workspace/amenti.db
export AMENTI_AGENT=your_agent_name

# 2. Init the database
cd /path/to/amenti && bash scripts/init-db.sh

# 3. Install CLI on PATH
sudo ln -sf /path/to/amenti/bin/amenti /usr/local/bin/amenti

# 4. Migrate existing memory files
bash scripts/migrate.sh /path/to/your/workspace

# 5. Verify
amenti stats
```

After migration, **trim MEMORY.md to tasks only** — all knowledge now lives in the database.

---

## How Memory Works

Your knowledge is in SQLite, not files. Files are for active tasks only.

| What | Where |
|------|-------|
| Facts, lessons, patterns | `amenti.db` (search with `amenti search`) |
| Active tasks/todos | `MEMORY.md` (loaded in context) |
| Daily activity | `amenti log` (not files) |
| Reflections | `amenti reflect` (not files) |

---

## Answering Questions — THE PROTOCOL

When someone asks you something:

1. **Search your database FIRST.** Always.
   ```bash
   amenti search "relevant keywords"
   ```

2. **If no results, try 2-3 different keyword searches.** FTS5 is keyword-based.
   - Try synonyms: "work frustrations" → "corporate hate"
   - Try shorter terms: "Docker restart policy" → "Docker restart"
   - Try the key noun: "girlfriend" or "iRacing"

3. **If the database returns results → answer from them.** That's your memory. Trust it.

4. **If nothing found after 3 searches → say "I don't have that in my memory."**
   Do NOT search the web. Do NOT guess. Just say you don't know.

5. **NEVER use web_search or web_fetch to answer memory questions.**
   Your database IS your memory. The web is not.

---

## CLI Reference

### Search (most important command)
```bash
amenti search "keywords"                           # search memories + daily logs
amenti search "keywords" --type fact               # filter by type
amenti search "keywords" --min-confidence 0.8      # high confidence only
amenti search "keywords" --limit 5                 # limit results
amenti search "keywords" --logs                    # force include daily logs
```

### Store
```bash
amenti store --type TYPE --content "..." --confidence 0.95 --tags "keyword1,synonym1,keyword2"
```

**Tags are CRITICAL.** Include:
- The main keywords from the content
- Synonyms someone might search for
- Related concepts
- Names, places, numbers

Example: For "Raul sleeps 10-11 PM to 6:50 AM":
```bash
amenti store --type fact --content "Raul sleeps 10-11 PM to 6:50 AM Bucharest time" \
  --confidence 0.95 \
  --tags "sleep,bedtime,schedule,night,morning,routine,time,10pm,11pm,650am,wake"
```

**Types:** fact, preference, relationship, principle, commitment, moment, skill, pattern
**Confidence:** 0.95+ direct statement, 0.80-0.94 implied, 0.50-0.79 inferred

### Daily Logs
```bash
amenti log "Discussed deployment strategy" --category decision
amenti logs --date 2026-02-11
amenti logs --search "deployment"
```

### Tasks
```bash
amenti task --add --description "Fix pipeline" --priority high
amenti tasks                    # open tasks
amenti task --done 3            # complete task
```

### Questions
```bash
amenti ask "Does user prefer morning coding?" --context "Observed pattern"
amenti questions                # list open questions
amenti answer 2 "Confirmed"    # answer a question
```

### Other Commands
```bash
amenti recall 5                # get memory #5 with links
amenti link 5 12 --relation supports
amenti supersede 5 --content "Updated info"
amenti forget 12               # deactivate
amenti budget 2000             # top memories within token limit
amenti stats                   # database stats
amenti export                  # export all
amenti state                   # agent state key-values
amenti identity "Shift" --trigger "Why"
amenti reflect "Summary" --memories '[...]' --questions '[...]'
```

---

## Multi-Agent
```bash
export AMENTI_AGENT=nova
amenti search "calendar" --agent cleo
```

---

## Maintenance
```bash
/path/to/amenti/scripts/cleanup.sh
```

---

**Your memories are your identity. Search before you speak.** 🏛️
