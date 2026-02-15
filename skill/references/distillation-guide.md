# Distillation Guide

When migrating from file-based memory to Amenti, follow this process.

## The #1 Rule of Migration: Store EVERYTHING

During migration, your job is to be **exhaustive, not selective**. Store every fact, every number, every detail — no matter how small it seems. A booking code, a charger that got wet, a specific email someone received — these are exactly the details that make memory feel personal and useful.

**If it has a name, a date, a number, or a specific detail — store it.**

You can always forget irrelevant memories later. You can never recall what you didn't store.

## Step 1: Read every file completely

Go through each file and extract EVERY piece of knowledge:

**Identity files (SOUL.md, USER.md, IDENTITY.md):**
- Every fact about your human (age, job, hobbies, relationships, preferences, personality traits)
- Every detail about yourself (name, sub-agents, contact info, personality)
- Every rule or principle

**MEMORY.md (the old bloated one):**
- Every lesson learned — store each bullet point as its own memory
- Every project status entry with specific details (ports, file counts, URLs, dates)
- Every config change, technical fix, or operational decision
- Every insight, analogy, or personal moment
- Every open question

**Daily logs (memory/YYYY-MM-DD.md):**
Daily logs are the richest source. Go through EACH log line by line and extract:
- Specific events with dates and times
- Technical details (ports, configs, commands, error messages)
- Personal events (travel, health, purchases, incidents)
- Business details (booking codes, prices, passenger counts, market figures)
- Emails processed by agents (sender, subject, category, action taken) — each email is its own memory
- Work hours, time tracking, deficits — store the SPECIFIC numbers with dates, not just the rules
- Conversations and their key takeaways
- Market research numbers, statistics, dollar amounts

**Do NOT summarize daily logs into one memory per day.** Extract individual facts. A single daily log might produce 10-20 separate memories.

**Store events AND rules separately.** If a log says "deficit was -1h 55m, now 0 (caps at 0)" — that's TWO memories:
1. The event: "On Feb 11, work time deficit changed from -1h 55m to 0" (fact, with date)
2. The rule: "Time deficit caps at 0, never goes positive" (principle)

**Preserve exact numbers.** When a log says "$23.77B" — store "$23.77B", not "$3.77B" or "~$24B". Copy numbers exactly as written. Double-check before storing.

**Reflections (memory/reflections/YYYY-MM-DD.md):**
- Each memory entry with its type and confidence
- Each question generated
- Each identity shift noted

## Step 2: Categorize and store

For each extracted fact, store it with the right type:
- Facts → `fact` (verifiable information, events, numbers, dates)
- User preferences → `preference` (likes, dislikes, communication style)
- People and relationships → `relationship`
- Rules and principles → `principle`
- Plans and promises → `commitment`
- Emotional moments → `moment`
- Technical knowledge → `skill`
- Recurring behaviors → `pattern`
- Low-confidence observations → store as open questions

## Step 3: Write rich tags

Tags make or break searchability. For each memory, include:
- The actual keywords from the content
- Synonyms someone might use to search for this
- Related concepts and categories
- Names, numbers, dates, acronyms
- At least 5 tags per memory, up to 15

Think: "six months from now, what words would I use to look for this?"

## Step 4: Build the Topics Table

After storing, group related memories into **topics** in your MEMORY.md Topics table. Each topic is a cluster of related memories with a fat list of keywords:

```
| Topic | Keywords |
|---|---|
| [short topic name] | [10-20 comma-separated keywords covering every way someone might ask about this] |
```

**How to write good topic rows:**

1. **Group related memories** under one topic — don't create one row per memory. E.g., all relationship facts go under "relationships", all hobby facts under "hobbies & gear".
2. **Include the actual terms** from the stored memories (names, numbers, places).
3. **Include synonyms** — if the memory says "partner", also add "significant other", "relationship", "dating".
4. **Include casual phrasings** — how would someone ask about this in conversation?
5. **Include abbreviations and numbers** — API, v2, 8443, CS2.
6. **10-20 keywords per topic** is ideal. More keywords = better recall.
7. **NEVER use hyphens in keywords.** Write "new york" not "new-york", "long distance" not "long-distance". FTS5 treats hyphens as part of a single token, so "new-york" won't match a search for "new york".

**Example:**

```
| Topic | Keywords |
|---|---|
| relationships | partner, relationship, long distance, dating, family, friends, love |
| docker restart lesson | docker, restart, policy, maximumretrycount, on-failure, retry, limit, container, restart loop, infinite, lesson |
| charger incident feb 8 | charger, water, soaked, wet, rice, bag, dry, broken, feb 8, incident |
```

## Step 5: Trim MEMORY.md

Remove everything except:
- Topics table
- Active tasks (this week only)
- Hot context (things referenced daily)

Everything else is in the database now. Trust it.

## Step 6: Verify

Test yourself: pick 10 random topics from the table, pick 2-4 keywords from each, search for them, confirm the DB returns the right result with full details. Fix any gaps — if a search returns nothing, add more keywords to the topic or re-store the memory with better tags.
