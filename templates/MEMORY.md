# MEMORY.md — Amenti Tag Index

*Last updated: YYYY-MM-DD*

**This file is a portal to Amenti DB. All knowledge lives there.**
**Usage:** Find matching tags below → `amenti search "tag1 tag2"`

---

## Topics

<!--
Each row maps a topic to search keywords for Amenti DB.
This table contains NO knowledge — only pointers.

When someone asks a question:
1. Scan this table — which topic matches?
2. Run: amenti search "keyword1 keyword2 keyword3"
3. Answer from the search result, NOT from this table

When you store a new memory:
1. amenti store --type TYPE --content "..." --confidence X --tags "..."
2. If new topic: add a row here with relevant search keywords
3. If existing topic: add new keywords if needed

TIPS:
- Include synonyms and how someone would casually ask
- 5-15 keywords per topic is ideal
- Use spaces not hyphens (FTS5 treats hyphens as one token)
- Keep the table lean — combine related topics
-->

| Topic | Keywords |
|---|---|

<!--
EXAMPLE (delete when you add real entries):

| Topic | Keywords |
|---|---|
| User — basics | `name age timezone location sleep schedule` |
| User — work | `developer job career fullstack corporate goals` |
| Relationships | `partner girlfriend boyfriend long distance dating` |
| Hardware setup | `sim rig wheel pedals seat hardware equipment` |
| Docker lessons | `docker restart container deployment pm2 nginx` |
-->

---

## Hot Context

<!-- Active situation context. Things that come up daily. Max 3-5 lines. -->
<!-- Move to DB once no longer active (1-2 weeks max). -->

---

*All knowledge in Amenti DB. This file is just the map.*
*Store: `amenti store --type TYPE --content "..." --confidence X --tags "..."`*
*Search: `amenti search "keywords"`*

### Rules
1. **Under 3k tokens.** This is loaded every session.
2. **Keywords = pointers.** Never answer from the table — always search DB first.
3. **Sync on store.** Every `amenti store` → update keywords here.
4. **Fat keywords.** More keywords = better recall. Think: how would someone ask about this 6 months from now?
5. **No knowledge here.** If you catch yourself writing facts in this file, stop and `amenti store` instead.
