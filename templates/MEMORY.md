# MEMORY.md — Active Context

*This file is loaded every API call. Keep it LEAN. Target: <3k tokens.*
*Everything else lives in Amenti DB. If it's not active, it doesn't belong here.*

---

## Memory Index

**This is your most important section.** It tells you what's in your DB without searching.

*Scan this table BEFORE searching — use these tags for accurate retrieval.*

### How to use

1. **Scan the table** for rows matching the user's topic
2. **Copy the tags** from matching rows into your search query
3. **Run `amenti search "tags"`** to retrieve the full memory

### Tag Search Examples

> User asks: "What's my girlfriend's name?"
> You scan the index, find: `girlfriend, iri, japan, nagoya, relationship`
> You run: `amenti search "girlfriend iri"`
> DB returns the full memory with all details.

> User asks: "How should I configure Docker restart?"
> You scan the index, find: `docker, restart, policy, container`
> You run: `amenti search "docker restart policy"`
> DB returns the technical details.

| Brief Description | Tags |
|---|---|
<!-- Examples — replace with real entries as you store memories: -->
| User's girlfriend lives in Japan | girlfriend, iri, japan, nagoya, relationship |
| Docker restart policy must use on-failure | docker, restart, policy, container |
| Prefers direct communication style | communication, preference, direct, honesty |

<!-- RULES:
- Add a row every time you `amenti store` something
- Tags must match what you stored (copy from --tags)
- Remove rows when you `amenti forget` a memory
- Keep descriptions short (5-10 words max)
- This is your lookup table — if it's not here, you won't know to search for it
-->

## Now (what I'm working on this week)

- [ ] Example: Ship v2 of the API by Friday
- [ ] Example: Fix FTS5 keyword mismatch issue

## Hot Context (need-to-know for current conversations)

<!-- Recent decisions, active project state, things that come up daily -->
<!-- Move to DB once no longer actively referenced (1-2 weeks max) -->

## Key People

<!-- Only people you interact with regularly — full details in DB -->
- **Raul** — your human. Details in DB.

---

### Rules for this file

1. **Max ~3k tokens.** If it's growing, move stuff to DB.
2. **Only active items.** Completed tasks → `amenti log`. Lessons learned → `amenti store`.
3. **Rotate weekly.** During reflection: finished? → DB. Stale? → DB. Still active? → stays.
4. **No archives.** This is a working scratchpad, not a knowledge base.
5. **Memory Index is sacred.** Always update it when storing/forgetting memories.
