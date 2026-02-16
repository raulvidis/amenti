---
name: amenti
description: Persistent long-term memory system for AI agents. Use when you need to remember facts about your user, recall past conversations, store new learnings, search for information in your memory database, or manage tasks and questions. Trigger phrases include "remember this", "what do you know about", "recall", "search memory", "store this fact", "do I know anything about".
license: MIT
metadata:
  author: Raul Vidis
  version: 1.0.0
  category: memory
  tags: [memory, persistence, sqlite, search, recall, storage]
---

# Amenti — Persistent Memory Skill

Your long-term memory lives in a SQLite database. This file teaches you how to use it.

---

## MANDATORY BEHAVIOR

**These rules are NON-NEGOTIABLE. You MUST follow them in every session.**

1. **ALWAYS search before answering.** If a user asks about anything you should know (people, dates, preferences, past decisions, projects, technical details), run `amenti search` BEFORE responding. Never guess. Never rely on training data for personal context.

2. **ALWAYS store new knowledge.** When you learn something new during a conversation — a fact, preference, decision, lesson, relationship detail — store it immediately with `amenti store`. Don't wait until later. Don't assume you'll remember.

3. **ALWAYS update your Topics table.** After storing a memory with confidence >= 0.8, add its keywords to MEMORY.md's Topics table. If you skip this, future sessions won't know to search for it.

4. **NEVER answer "I don't know" without searching first.** Run at least 2 different searches with different keywords before admitting you don't have the information.

5. **NEVER fabricate memories.** If the database returns nothing, say so. Don't fill gaps with guesses.

6. **Store tasks immediately.** When a task comes up, run `amenti task --add` right away. Don't just note it mentally.

7. **Distill conversations.** At the end of substantive sessions, extract and store key learnings. Don't let knowledge evaporate.

---

## Installation

### 1. Initialize the database

```bash
export AMENTI_DB=/path/to/your/workspace/amenti.db
export AMENTI_AGENT=your_agent_name
cd /path/to/amenti && ./scripts/init-db.sh
ln -sf /path/to/amenti/bin/amenti /usr/local/bin/amenti
```

This creates a config file at `~/.config/amenti/config` so spawned agents and sub-processes can find the database without needing the env var. If the config file wasn't created automatically, create it manually:

```bash
mkdir -p ~/.config/amenti
echo "AMENTI_DB=/path/to/your/workspace/amenti.db" > ~/.config/amenti/config
echo "AMENTI_AGENT=your_agent_name" >> ~/.config/amenti/config
```

### 2. Migrate your existing memory files

If you have existing files (MEMORY.md, daily logs, reflections), migrate them into the database:

```bash
./scripts/migrate.sh /path/to/your/workspace
amenti stats  # verify everything imported
```

### 3. Distill your MEMORY.md

After migration, your MEMORY.md needs to become a slim lookup table. Do this yourself:

1. Read through your current MEMORY.md
2. For every piece of knowledge (facts, lessons, rules, insights), verify it was migrated with `amenti search`
3. If something was missed, store it manually: `amenti store --type TYPE --content "..." --confidence X --tags "keyword1,keyword2,..."`
4. Build a Topics table in MEMORY.md (see template below)
5. Delete everything from MEMORY.md except: Active Tasks, Topics table, Hot Context
6. Target: under 3k tokens

### 4. Update your AGENTS.md / CLAUDE.md

Add a section to your agent configuration file explaining that Amenti is your brain. Something like:

```
## Memory System

My long-term memory is stored in an Amenti database. MEMORY.md is my scratchpad — it contains
active tasks, a Topics table (keyword lookup pointing to DB entries), and hot context.

When I need to recall something:
1. Check MEMORY.md Hot Context (already loaded, zero cost)
2. Scan the Topics table — which topic matches?
3. Pick 2-4 keywords from that topic's keyword list
4. Run `amenti search "keyword1 keyword2 keyword3"` to get the full memory
5. Answer from the search result — never from the Topics table alone

When I learn something new:
1. Store it: `amenti store --type TYPE --content "..." --confidence X --tags "..."`
2. Add keywords to the matching topic in MEMORY.md (or create a new topic row)
3. Remove raw knowledge from MEMORY.md (it's in the DB now)
```

Write this in your own words. The goal is that any future session loads MEMORY.md and immediately knows: my real memories are in the database, this file tells me how to find them.

---

### 5. Set up vector embeddings (optional but recommended)

Vector embeddings enable semantic search — finding memories by meaning, not just keywords. "Significant other studying abroad" will find "partner lives abroad" even without keyword overlap.

**Requirements:** Python 3 + sentence-transformers

```bash
pip3 install sentence-transformers
```

**Start the embed server:**

```bash
python3 /path/to/amenti/src/embed_server.py &
# Or with PM2 for persistence:
pm2 start /path/to/amenti/src/embed_server.py --name amenti-embed --interpreter python3
pm2 save
```

The server runs on `localhost:9819` (~500MB RAM, uses all-MiniLM-L6-v2 model, 384 dimensions).

**Embed all existing memories:**

```bash
cd /path/to/amenti && ./scripts/reindex.sh --force
```

**How it works:**
- `amenti store` auto-embeds new memories when the embed server is running (🧬 indicator)
- `amenti search` uses hybrid search: FTS5 → LIKE → Vector similarity
- Vector results appear with `match_type: "vector"` and a `similarity` score
- If the embed server is not running, everything works normally (FTS5 + LIKE only)

**Re-embed after model upgrade:**

```bash
cd /path/to/amenti && ./scripts/reindex.sh --force
```

---

## How Memory Works

### The Database is Your Brain

Everything you know lives in the database: facts about your human, technical lessons, project history, relationship details, personal insights. Your MEMORY.md is just a table of contents — it points to memories but doesn't contain them.

### The Topics Table is Your Search Index

Your MEMORY.md has a `## Topics` table. Each row is a **topic** — a cluster of related memories — with a fat list of **keywords** covering every way someone might ask about it.

```
| Topic | Keywords |
|---|---|
| relationships | partner, relationship, long distance, dating, family, friends, love |
| hobbies & gear | hobby, equipment, setup, hardware, stats, competitive, gear, pedals, wheel |
```

The keywords are a **synonym expansion layer** on top of the database search. FTS5 only matches exact keywords — so if someone asks "what's your significant other's name?" but the memory says "partner", the search would miss. The Topics table bridges that gap by listing both "partner" AND "significant other" as keywords for the same topic.

**More keywords = better recall.** When building a topic row, think: what are all the different ways someone could ask about this? Include the exact terms from the stored memory, plus synonyms, abbreviations, casual phrasings, and numbers.

**The Topics table contains pointers, not answers.** Never answer from it. Always search the database first.

### The Search Protocol

Every time you're asked a question about something you should know:

1. **Check Hot Context** in MEMORY.md — if it's there, answer immediately
2. **Scan the Topics table** — which topic matches the question?
3. **Pick 2-4 keywords** directly from that topic's keyword list — use the EXACT words from the table
4. **Search the database** — `amenti search "keyword1 keyword2 keyword3"`
5. **Answer from the result** — include all relevant details the DB returned
6. **If nothing found** — try different keywords from the same topic row
7. **If still nothing** — try a broader search with just 1 core term (e.g., just "docker" or just "partner")
8. **If truly nothing** — say "I don't have that in my memory"

**Search tips:**
- Use 2-3 keywords max per search — too many keywords can cause FTS5 to miss results
- If "user developer fullstack startup" returns nothing, try just "developer startup"
- Always try at least 2 different searches before giving up
- The keywords in your Topics table are designed to match what's in the DB — trust them

Never guess. Never fabricate. Trust your database or admit you don't know.

---

## CLI Reference

### Search

```bash
amenti search "keywords here"
amenti search "Docker" --type skill --min-confidence 0.8 --limit 5
```

FTS5 is keyword-based. If a search returns nothing, try synonyms or related words.

### Store

```bash
amenti store --type fact --content "The server runs on port 8443" --confidence 0.95 --tags "server,port,8443,dashboard"
```

**Always include rich tags.** Tags should include: key terms, synonyms, abbreviations, related concepts. More tags = better searchability.

**Types:** fact, preference, relationship, principle, commitment, moment, skill, pattern

**Confidence scoring:**
- 0.95-1.0 — directly stated by your human
- 0.80-0.94 — strongly implied or observed
- 0.50-0.79 — inferred (mark for validation)
- Below 0.50 — store as open question, not memory

### Recall

```bash
amenti recall 5          # full details of memory #5
```

### Link

```bash
amenti link 5 12 --relation supports
```

Relations: supports, contradicts, depends_on, related, supersedes

### Supersede (update a memory, preserving history)

```bash
amenti supersede 5 --content "Updated information here"
```

Old memory gets deactivated, new one created. Full audit trail preserved.

### Forget

```bash
amenti forget 12         # deactivates memory #12
```

After forgetting, remove the corresponding keywords (or entire topic row) from your Topics table.

### Action Items

```bash
amenti task --add --description "Fix the pipeline" --priority high
amenti tasks --status open
amenti task --done 3
amenti task --cancel 5
```

Priority: low, normal, high, urgent

### Questions (low-confidence observations)

```bash
amenti ask "Does the user prefer morning coding?" --context "More commits after 8pm"
amenti answer 2 "Confirmed: evening coder"
amenti questions
```

### Daily Logs

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

### Context Budget

```bash
amenti budget 2000       # top memories within 2000 tokens
```

### Identity Evolution

```bash
amenti identity "Becoming more proactive" --trigger "User feedback"
```

### Vector Reindex

```bash
amenti reindex            # embed only non-embedded memories
amenti reindex --force    # re-embed ALL memories (e.g., after model upgrade)
```

Requires the embed server running on localhost:9819.

### Stats & Export

```bash
amenti stats
amenti export
amenti export --type skill
```

---

## Multi-Agent

All tables are scoped by agent ID. Each agent has its own memories.

```bash
export AMENTI_AGENT=your_agent_name
amenti search "calendar" --agent assistant_two    # search another agent's memories
```

---

## Task Management

Your tasks live in the database, not in files. Use the `action_items` table to track everything you need to do.

### Storing Tasks

When a task comes up during a session:

```bash
amenti task --add --description "Deploy synqr to staging" --priority high
amenti task --add --description "Research n8n marketplace pricing" --priority normal
```

When you complete or cancel a task:

```bash
amenti task --done 3
amenti task --cancel 5
```

### Viewing Tasks

```bash
amenti tasks --status open          # all open tasks
amenti tasks --status in_progress   # what you're working on
```

### Task Tracking in MEMORY.md

Your MEMORY.md `## Active Tasks` section should mirror your most important open tasks from the database. Keep only this week's tasks there — the database has the full history.

When you complete a task, remove it from MEMORY.md and mark it done in the DB.

### Automated Task Cycles

Set up two recurring cycles to stay on top of your work:

**Every 30 minutes — Task Status Check:**
1. Run `amenti tasks --status open` to see all open tasks
2. Check if any tasks are blocked, overdue, or need attention
3. Update task status if anything changed (in_progress, done, cancelled)
4. If a task is stuck, log why and consider breaking it into smaller tasks

**Every 2 hours — Task Analysis & Suggestions:**
1. Review all open and in-progress tasks
2. Analyze the current state — what's progressing, what's stalled, what's missing
3. Come up with ideas, suggestions, or next steps based on the task landscape
4. If nothing relevant — do nothing. Don't force suggestions.
5. Store any good ideas as new tasks or as memories for later

These cycles should be part of your heartbeat or cron system. Add them to your AGENTS.md or HEARTBEAT.md so they run automatically.

The 30-minute check keeps you responsive. The 2-hour analysis keeps you strategic. Together they prevent tasks from going stale or falling through the cracks.

---

## Maintenance

### Hourly Conversation Distillation

Run a cron job every hour to distill conversations into long-term memory:

**Process:**
1. Review session transcript for significant interactions in the past hour
2. Extract important moments:
   - New facts about your human (preferences, life updates, decisions)
   - Tasks created or completed
   - Technical decisions or lessons learned
   - Relationship updates
   - Business insights
3. Store in Amenti DB with proper type, confidence, and rich tags
4. **For memories with confidence >= 0.8:** Add keywords to MEMORY.md Topics table
5. Update MEMORY.md Hot Context if something significant changed

**MEMORY.md Rules:**
- Only high-confidence memories (0.8+) go to MEMORY.md Topics table
- Split by topics and add relevant tags/keywords
- Keep MEMORY.md lean — it's an index, not storage
- The database holds the actual memories

**Skip if:** No substantive conversations, only routine/system messages.

### Daily Reflection Cycle

After a substantive session, reflect on what happened:

1. What did I learn? → `amenti store` new memories + update Topics table
2. What tasks came up? → `amenti task --add` or add to MEMORY.md Active Tasks
3. What questions remain? → `amenti ask`
4. Did my identity shift? → `amenti identity`

### Weekly Hygiene

1. Review Topics table — remove keywords/rows for forgotten memories, add rows for new ones
2. Run cleanup: `./scripts/cleanup.sh`
3. Check MEMORY.md is under 3k tokens — move anything stale to the database
4. Review open questions — answer or mark stale

### When Storing New Memories

Every time you store a memory:
1. `amenti store --type TYPE --content "..." --confidence X --tags "rich,tags,here"`
2. Add keywords to the matching topic in MEMORY.md's Topics table (or create a new topic row)
3. Remove the raw knowledge from MEMORY.md body (it's in the DB now)

Every time you forget a memory:
1. `amenti forget ID`
2. Remove the corresponding keywords from the Topics table (or delete the topic row if no memories left)

The Topics table must always reflect what's in the database. If it's not in the Topics table, you won't know to search for it.

---

## Distillation Guide

When migrating from file-based memory to Amenti, see `references/distillation-guide.md` for the complete migration process including:
- Extracting facts from identity files, daily logs, and reflections
- Categorizing memories by type
- Writing effective tags
- Building the Topics table

---

## Troubleshooting

### Search returns nothing

**Cause:** Keywords don't match stored content exactly.

**Solutions:**
- Try different synonyms from the Topics table
- Use fewer keywords (2-3 max)
- Try just 1 core term (e.g., just "docker" or just "partner")
- Check if the memory exists: `amenti search "term" --limit 20`

### Memory not found after storing

**Cause:** Tags don't match search terms.

**Solutions:**
- Always include 5-15 rich tags when storing
- Include synonyms, abbreviations, related concepts
- Add keywords to the Topics table in MEMORY.md

### Embed server not running

**Symptom:** No `🧬 embedded` indicator when storing.

**Solution:**
```bash
python3 /path/to/amenti/src/embed_server.py &
# Or with PM2:
pm2 start /path/to/amenti/src/embed_server.py --name amenti-embed --interpreter python3
```

### Database not found

**Cause:** `AMENTI_DB` env var or config file not set.

**Solutions:**
```bash
# Check config
cat ~/.config/amenti/config

# Set manually
export AMENTI_DB=/path/to/your/workspace/amenti.db
export AMENTI_AGENT=your_agent_name
```

---

## Principles

- **Supersede, never overwrite.** Old memories get deactivated, new ones created. History is preserved.
- **Confidence scores matter.** Don't store guesses as facts. Below 0.50 = question, not memory.
- **The Index is sacred.** Always keep it in sync with the database. It's your table of contents.
- **Search before you speak.** If you should know something, check the database before answering.
- **Rich tags save you.** The more tags you add when storing, the easier it is to find later.
- **MEMORY.md is a scratchpad.** Keep it lean. The database is your real brain.

---

## Enforcement Checklist

Use this to self-audit every session:

- [ ] Did I search Amenti before answering personal/historical questions?
- [ ] Did I store every new fact, preference, or decision learned this session?
- [ ] Did I update the Topics table for high-confidence memories?
- [ ] Did I log any new tasks with `amenti task --add`?
- [ ] Did I distill the conversation before session end?
- [ ] Is my MEMORY.md still under 3k tokens?

If you skipped any of these, you're doing it wrong. Go back and fix it.
