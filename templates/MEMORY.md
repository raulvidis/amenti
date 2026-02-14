# MEMORY.md — Active Context

*This file is loaded every session. Keep it under 3k tokens.*
*Your real memories are in the Amenti database. This file helps you find them.*

---

## Active Tasks

<!-- Only tasks you're working on THIS WEEK. Completed → amenti log. -->

## Topics

<!--
Each row is a TOPIC — a cluster of related memories in your database.
The Keywords column lists EVERY word someone might use to ask about this topic.
More keywords = more ways to find the memory. Think synonyms, aliases, abbreviations.

When someone asks a question:
1. Scan this table — which topic matches?
2. Pick 2-4 keywords from that row
3. Run: amenti search "keyword1 keyword2 keyword3"
4. Answer from the search result, NOT from this table

This table is a LOOKUP INDEX. It does NOT contain answers.
ALWAYS search the database before answering.
-->

| Topic | Keywords |
|---|---|

<!--
EXAMPLE (delete when you add real entries):

| Topic | Keywords |
|---|---|
| girlfriend & relationship | girlfriend, partner, iri, nagoya, japan, brain science, masters, long distance, dating, relationship, love |
| sim racing rig & stats | iracing, sim racing, rig, setup, hardware, simagic, alpha, moza, ks, simjack, pedals, wheel, seat, next level racing, victory, road atlanta, gt3, 3k, irating, safety rating |
| docker restart lesson | docker, restart, policy, maximumretrycount, on-failure, retry, limit, container, restart loop, infinite |
| charger incident feb 8 | charger, water, soaked, wet, rice, bag, dry, broken, feb 8 |

TIPS:
- Include the actual terms from the stored memory
- Include synonyms (girlfriend/partner, rig/setup/hardware)
- Include abbreviations and numbers (GT3, 3k, 8443)
- Include how someone would casually ask ("what happened to my charger")
- 10-20 keywords per topic is ideal
- Group related memories under one topic when they overlap
- NEVER use hyphens in keywords. Use spaces: "road atlanta" not "road-atlanta", "sim racing" not "sim-racing"
- FTS5 treats hyphens as part of one token — "road-atlanta" won't match a search for "road atlanta"
-->

## Hot Context

<!-- Things that come up daily. Move to DB once no longer active (1-2 weeks max). -->

---

### Rules for this file

1. **Under 3k tokens.** If it's growing, move knowledge to DB with `amenti store`.
2. **Topics = pointers.** Never answer from the table — always search the DB first.
3. **Sync the table.** Every store → add keywords to the matching topic (or create a new topic). Every forget → remove the topic if no memories left.
4. **Fat keywords.** More keywords = better recall. Think: how would someone ask about this 6 months from now?
5. **Only active items.** Completed tasks → `amenti log`. Lessons → `amenti store`.
