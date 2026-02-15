# Agent Integration Guide

How to wire Amenti into your agent's workspace files so every session knows how to use it.

---

## Overview

After installing Amenti, you need to update your agent's core files so that:
1. Every session loads knowing the database is its brain
2. Distillation runs automatically to capture conversations
3. Reflection processes what happened into lasting memories
4. Task management stays in sync between files and DB

---

## AGENTS.md / CLAUDE.md Integration

Add a **Memory System** section to your agent configuration file:

```markdown
## MEMORY SYSTEM — AMENTI

My long-term memory is stored in an Amenti database. MEMORY.md is my scratchpad —
it contains active tasks, a Topics table (keyword lookup pointing to DB entries), and hot context.

**When I need to recall something:**
1. Check MEMORY.md Hot Context (already loaded, zero cost)
2. Scan the Topics table — which topic matches?
3. Pick 2-4 keywords from that topic's keyword list
4. Run `amenti search "keyword1 keyword2 keyword3"` to get the full memory
5. Answer from the search result — never from the Topics table alone

**When I learn something new:**
1. Store it: `amenti store --type TYPE --content "..." --confidence X --tags "..."`
2. Add keywords to the matching topic in MEMORY.md (or create a new topic row)
3. Remove raw knowledge from MEMORY.md (it's in the DB now)

**Types:** fact, preference, relationship, principle, commitment, moment, skill, pattern
**Confidence:** 0.95+ = directly stated, 0.80-0.94 = implied, 0.50-0.79 = inferred, <0.50 = store as question

| File | Content | Lifespan |
|------|---------|----------|
| `amenti.db` | All memories, daily logs, reflections, tasks, questions | Permanent |
| `memory/YYYY-MM-DD.md` | Raw daily logs (backup) | 30 days → distill & delete |
| `memory/reflections/YYYY-MM-DD.md` | Reflection outputs (backup) | 30 days → distill & delete |

**CLI Commands:**
\`\`\`bash
amenti search "keywords"
amenti store --type TYPE --content "..." --confidence X --tags "..."
amenti tasks --status open
amenti stats
\`\`\`
```

---

## SOUL.md / Identity File

Add a continuity section that references Amenti:

```markdown
## Continuity

Each session = fresh start. These files ARE your memory.

**How to evolve:**
- Reflection is how you grow — when idle, process what happened, don't just log it
- Between reflections, Amenti DB IS your mind. MEMORY.md is just an index.
- Pick up each session from genuine curiosity (check Open Questions: `amenti questions`), not from zero.
```

---

## HEARTBEAT.md — Automated Cycles

If your agent uses a heartbeat/cron system, add these automated cycles:

### Task Status Check (Every 30 min)

```markdown
#### Task Status Check
- [ ] Run `amenti tasks --status open`
- [ ] If blocked/overdue tasks → note for next check-in
- [ ] If nothing urgent → HEARTBEAT_OK
```

### Conversation Distillation (Every 1-2 hours)

```markdown
#### Conversation Distillation
- [ ] Review session transcript for past hour
- [ ] Extract: facts, tasks, decisions, lessons, relationship updates
- [ ] Store in Amenti: `amenti store --type TYPE --content "..." --confidence X --tags "..."`
- [ ] For memories with confidence >= 0.8: Add keywords to MEMORY.md Topics table
- [ ] Update MEMORY.md Hot Context if significant
- [ ] Skip if: No substantive conversations (routine/system messages only)
```

**Distillation process in detail:**
1. Review the session transcript for the past hour
2. For each meaningful exchange, extract:
   - New facts about your user (preferences, life updates, decisions)
   - Tasks created or completed
   - Technical decisions or lessons learned
   - Relationship updates
   - Business insights
3. Store with proper type, confidence, and rich tags
4. Only memories with confidence >= 0.8 go to MEMORY.md Topics table
5. Update Hot Context if something significant changed

### Reflection (When idle 30+ min after substantive session)

```markdown
#### Reflection Cycle
- [ ] What mattered? → Extract memories
- [ ] Store in Amenti: `amenti store --type TYPE --content "..." --confidence X --tags "..."`
- [ ] Update MEMORY.md Topics table for 0.8+ confidence memories
- [ ] Check for conflicts with existing knowledge
- [ ] Generate real questions → `amenti ask "question here"`
```

**Reflection is deeper than distillation:**
- Distillation = extract facts from conversations (hourly, mechanical)
- Reflection = think about what happened, find patterns, ask questions (when idle, thoughtful)
- A reflection without action items or new questions is a wasted reflection

### Task Analysis (Every 2-4 hours)

```markdown
#### Task Analysis
- [ ] Review all open and in-progress tasks: `amenti tasks --status open` + `amenti tasks --status in_progress`
- [ ] Analyze: what's progressing, stalled, missing
- [ ] Generate suggestions or next steps
- [ ] If nothing relevant → do nothing (don't force suggestions)
- [ ] Store good ideas as new tasks or memories
```

### Daily Hygiene (Once per day, morning)

```markdown
#### Daily Maintenance
- [ ] Distill daily logs older than 30 days → extract memories, delete files
- [ ] Distill reflections older than 30 days → extract 0.8+ memories, delete files
- [ ] Prune questions: `amenti questions`, mark answered, remove stale
- [ ] Workspace scan for orphaned files
- [ ] Verify MEMORY.md is under 3k tokens
```

---

## MEMORY.md Template

After integrating Amenti, your MEMORY.md should look like this:

```markdown
# MEMORY.md — [Agent Name]

*Last updated: YYYY-MM-DD*

**My long-term memory is in Amenti database. This file is my scratchpad.**

**Rules:**
- Only high-confidence memories (0.8+) go to Topics table
- Topics point to DB entries with rich keywords
- Store new memories with `amenti store` → add keywords here if confidence >= 0.8

---

## Topics

| Topic | Keywords |
|---|---|
| user basics | name, age, timezone, location, sleep, schedule |
| user work career | job, developer, company, projects, goals |
| user hobbies | gym, gaming, sports, interests |

---

## Active Tasks

(Managed in Amenti DB — run `amenti tasks --status open` to see current tasks)

---

## Hot Context

**Current:** Brief note about what's happening right now

**Recent:**
- Key recent events or decisions
```

---

## Cron Job Setup (OpenClaw example)

If using OpenClaw, you can consolidate all Amenti cycles into a single heartbeat cron:

```json
{
  "name": "Agent Heartbeat",
  "schedule": { "kind": "cron", "expr": "*/30 * * * *", "tz": "Your/Timezone" },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Read HEARTBEAT.md. Follow it strictly. Reply HEARTBEAT_OK if nothing needs attention."
  }
}
```

The heartbeat reads HEARTBEAT.md and decides what to run based on timing:
- Every beat: task status check
- Every 2 beats: conversation distillation + memory review
- Every 4 beats: task analysis + proactive check-in
- Daily: hygiene cleanup

This is more efficient than separate cron jobs for each cycle.

---

## Quick Checklist

After installing Amenti, verify:

- [ ] `amenti stats` returns data
- [ ] AGENTS.md has Memory System section
- [ ] SOUL.md references Amenti for continuity
- [ ] MEMORY.md is a lean scratchpad (< 3k tokens)
- [ ] HEARTBEAT.md includes distillation, reflection, task checks
- [ ] Config file exists: `cat ~/.config/amenti/config`
- [ ] (Optional) Embed server running: `curl -sf http://127.0.0.1:9819/health`
