# AGENTS.md — Memory-Augmented Agent Guide

## Golden Rule

**MEMORY.md is your scratchpad. Amenti DB is your brain.**

MEMORY.md is a **tag index** — a portal to Amenti DB. It holds search tags, hot context, and nothing else.
Everything you've ever learned, experienced, or been told lives in the Amenti database.

---

## How to Remember

### When someone tells you something worth keeping:

```bash
amenti store --type fact --content "The actual information" \
  --confidence 0.95 \
  --tags "keyword1,keyword2,synonym1,related_concept"
```

**Do this in the moment.** Don't wait for reflection. If it matters, store it now.

Tags are how you'll find it later — be generous with synonyms and related terms.

**Then update the Tags table in MEMORY.md:**

Add or update search tags for the relevant topic. No tags entry = you'll never search for it.

### When you finish a task or learn a lesson:

```bash
amenti log "What happened and what I learned" --category decision
```

Then remove it from MEMORY.md if it was there.

### When a task comes up:

Add it to MEMORY.md (active context). When done → log it → remove from MEMORY.md.

---

## How to Recall

### The 3-Layer Lookup (follow this order):

**Layer 1: MEMORY.md Hot Context (zero cost — already loaded)**
Check active context first. If the answer is here, use it. Done.

**Layer 2: MEMORY.md Tags → Amenti DB (primary recall)**
Scan the Tags table in MEMORY.md. Find matching tags → search Amenti:

```bash
amenti search "tag1 tag2 tag3"
```

One search. If no results, try 1-2 alternative keywords:
- Synonyms: "work frustrations" → "corporate job"
- Shorter: "Docker restart policy" → "Docker restart"
- Key noun: "partner" or "hobby"

**Max 3 searches per topic.** If nothing after 3, you don't know it.

**Layer 2.5: memory_search tool (fallback only)**
Only if Amenti returns nothing useful. This searches MEMORY.md and memory/*.md files using embeddings.

**Layer 3: Ask the user**
Don't guess. Don't confabulate. Say "I don't have that in my memory."

### Critical: Don't Over-Search

❌ **Wrong:** Search DB for every single user message
❌ **Wrong:** Search 5+ times trying to find something
❌ **Wrong:** Search for things already in MEMORY.md

✅ **Right:** Check MEMORY.md → not there → 1 search → found it → done
✅ **Right:** Topic already discussed this session → use conversation context
✅ **Right:** User just told you something → respond, don't search for confirmation

**Rule of thumb:** If you've already searched for a topic in this conversation, don't search again. Use what you got.

---

## When to Search vs. Not Search

### SEARCH (hit the DB):
- User asks about something from a previous session
- You need historical context for a decision
- You're reflecting and need to check for contradictions
- User references something you should know but don't

### DON'T SEARCH:
- User just told you the answer in this message
- It's in MEMORY.md (already loaded)
- You found it earlier in this conversation
- It's a new topic — nothing to recall
- General knowledge questions (that's not memory, that's training data)

---

## MEMORY.md Hygiene

**Keep it under 3k tokens.** This is loaded on EVERY API call.

### What belongs in MEMORY.md:
- Active tasks (this week)
- Current project state
- Hot context (things coming up daily)

### What does NOT belong:
- Completed tasks → `amenti log` + remove
- Lessons learned → `amenti store` + remove
- Historical decisions → `amenti store` + remove
- User preferences → `amenti store` (query when needed)
- Anything "just in case" → DB

### Weekly rotation (during reflection):
1. Scan MEMORY.md
2. Done items → `amenti log`, then delete from file
3. Lessons → `amenti store`, then delete from file
4. Still active → keep
5. Not referenced in 2+ weeks → move to DB

---

## Reflection with Amenti

During reflection cycles:

1. **Store new memories** from the session:
   ```bash
   amenti store --type TYPE --content "..." --confidence X --tags "..."
   ```

2. **Log the session summary:**
   ```bash
   amenti log "Session summary: what happened, what was decided" --category reflection
   ```

3. **Create action items:**
   ```bash
   amenti task --add --description "Next step" --priority normal
   ```

4. **Clean MEMORY.md** — remove anything that just got stored in DB
5. **Verify Tags table** — every stored memory must have a row in the index table

5. **Check for contradictions:**
   ```bash
   amenti search "topic of new memory"
   ```
   If existing memory conflicts → `amenti supersede OLD_ID --content "Updated info"`

---

## Multi-Agent Memory

Agents share the same DB but use different agent IDs:

```bash
export AMENTI_AGENT=your_agent_name    # or assistant_two, etc.
```

Search across agents:
```bash
amenti search "topic" --agent assistant_two
```

Each agent's memories are tagged with their ID. Cross-agent search is explicit.

---

## Token Budget Reference

| Action | Cost |
|--------|------|
| MEMORY.md (loaded every call) | ~target 750-3,000 tokens |
| 1 amenti search | ~400 tokens (call + result) |
| 1 amenti store | ~80 tokens (call + confirmation) |
| 1 amenti log | ~80 tokens |
| Typical session (2-3 searches) | ~800-1,200 tokens |
| File-based equivalent (20k+ MEMORY.md) | 20,000+ tokens every call |

**Goal: MEMORY.md + occasional DB lookups < bloated MEMORY.md every call.**

---

## Migrating a Bloated MEMORY.md to Amenti

If your MEMORY.md has grown beyond ~3k tokens, follow these steps to distill it into the database.

### Step 1: Run the migration script
```bash
bash /path/to/amenti/scripts/migrate.sh /path/to/your/workspace
```
This parses bullet points from MEMORY.md into memories, tasks, and questions.

### Step 2: Review what was imported
```bash
amenti stats          # Check counts
amenti export         # Review all imported memories
```
Fix any misclassified types or low-confidence entries.

### Step 3: Build the Tags table
For every stored memory, add a row to the Tags table in MEMORY.md:
```markdown
| Topic | Search Tags |
|---|---|
| Relationships | `partner long distance abroad dating` |
| Docker lessons | `docker restart on-failure container` |
```
This is how you'll know what's in the DB without searching.

### Step 4: Trim MEMORY.md
Remove everything except:
- The Tags table (topic → search tags)
- Hot context (max 3-5 lines, things that come up daily)

Target: <3k tokens. MEMORY.md is a portal, not a knowledge store.

### Migration Checklist
- [ ] Run `migrate.sh` on your workspace
- [ ] Verify with `amenti stats` — memories, tasks, questions all imported
- [ ] Build Tags table with a row per topic
- [ ] Trim MEMORY.md to tags + hot context only
- [ ] Verify MEMORY.md is under 3k tokens
- [ ] Test: ask yourself a question, find it via tags → search → answer

---

*Your files are your working memory. Your database is your long-term memory. Keep them separate.*
