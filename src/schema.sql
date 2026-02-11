-- ============================================================
-- Amenti — Persistent Memory for AI Agents
-- Schema v2 — 7 tables, 30-day retention, action-driven
-- ============================================================
--
--   memories            — permanent knowledge (FTS5)
--   daily_logs          — raw session notes (30 days, FTS5)
--   reflections         — structured processing
--   action_items        — tasks born from reflections or sessions
--   open_questions      — things to follow up on
--   agent_state         — runtime state (heartbeat, counters)
--   identity_evolution  — how the agent changes over time
--
-- Files (NOT in DB):
--   SOUL.md / IDENTITY.md — core identity, loaded every session
--   USER.md — about the human, loaded every session
--   MEMORY.md — active tasks only (tiny scratchpad)
--
-- ============================================================

PRAGMA journal_mode = WAL;
PRAGMA foreign_keys = ON;

-- ============================================================
-- 1. MEMORIES — Permanent knowledge store
-- ============================================================

CREATE TABLE memories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL CHECK(type IN (
        'fact',           -- Verifiable info
        'preference',     -- Likes/dislikes/wants
        'relationship',   -- People & dynamics
        'principle',      -- Rules or values
        'commitment',     -- Promises or plans
        'moment',         -- Emotionally significant
        'skill',          -- Technical knowledge
        'pattern'         -- Recurring behaviors
    )),
    content TEXT NOT NULL,
    source TEXT,                        -- "direct statement", "inferred", "observed"
    confidence REAL NOT NULL CHECK(confidence BETWEEN 0.0 AND 1.0),
    tags TEXT,                          -- Comma-separated, optional
    supersedes_id INTEGER,              -- If this replaces an older memory
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (supersedes_id) REFERENCES memories(id)
);

CREATE INDEX idx_memories_type ON memories(type);
CREATE INDEX idx_memories_active ON memories(is_active);
CREATE INDEX idx_memories_created ON memories(created_at);

CREATE VIRTUAL TABLE memories_fts USING fts5(
    content, type, tags,
    content=memories,
    content_rowid=id,
    tokenize='porter unicode61'
);

CREATE TRIGGER memories_ai AFTER INSERT ON memories BEGIN
    INSERT INTO memories_fts(rowid, content, type, tags)
    VALUES (new.id, new.content, new.type, new.tags);
END;

CREATE TRIGGER memories_ad AFTER DELETE ON memories BEGIN
    INSERT INTO memories_fts(memories_fts, rowid, content, type, tags)
    VALUES ('delete', old.id, old.content, old.type, old.tags);
END;

CREATE TRIGGER memories_au AFTER UPDATE ON memories BEGIN
    INSERT INTO memories_fts(memories_fts, rowid, content, type, tags)
    VALUES ('delete', old.id, old.content, old.type, old.tags);
    INSERT INTO memories_fts(rowid, content, type, tags)
    VALUES (new.id, new.content, new.type, new.tags);
END;

-- ============================================================
-- 2. DAILY LOGS — Raw session notes (30 days)
-- ============================================================

CREATE TABLE daily_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,                 -- YYYY-MM-DD
    category TEXT,                      -- "conversation", "task", "issue", "decision"
    content TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    distilled INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_daily_logs_date ON daily_logs(date);
CREATE INDEX idx_daily_logs_distilled ON daily_logs(distilled);

CREATE VIRTUAL TABLE daily_logs_fts USING fts5(
    content, category,
    content=daily_logs,
    content_rowid=id,
    tokenize='porter unicode61'
);

CREATE TRIGGER daily_logs_ai AFTER INSERT ON daily_logs BEGIN
    INSERT INTO daily_logs_fts(rowid, content, category)
    VALUES (new.id, new.content, new.category);
END;

CREATE TRIGGER daily_logs_ad AFTER DELETE ON daily_logs BEGIN
    INSERT INTO daily_logs_fts(daily_logs_fts, rowid, content, category)
    VALUES ('delete', old.id, old.content, old.category);
END;

-- ============================================================
-- 3. REFLECTIONS — Structured processing
-- ============================================================
-- Reflections produce:
--   1. Memories → INSERT INTO memories
--   2. Action items → INSERT INTO action_items
--   3. Questions → INSERT INTO open_questions
--   4. Identity shifts → INSERT INTO identity_evolution
--
-- A reflection without action items is a wasted reflection.

CREATE TABLE reflections (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,                 -- YYYY-MM-DD
    summary TEXT NOT NULL,              -- What happened (1-2 sentences)
    memories_extracted TEXT,            -- JSON: [{type, content, confidence}]
    questions_generated TEXT,           -- JSON: ["Why did X happen?"]
    identity_shifts TEXT,              -- Any changes noted (free text)
    created_at INTEGER NOT NULL,
    distilled INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_reflections_date ON reflections(date);

-- ============================================================
-- 4. ACTION ITEMS — Tasks born from reflections or sessions
-- ============================================================

CREATE TABLE action_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    description TEXT NOT NULL,
    source TEXT,                        -- "reflection", "user_request", "self_identified"
    source_id INTEGER,                 -- ID of reflection or daily_log that spawned it
    priority TEXT DEFAULT 'normal' CHECK(priority IN ('low', 'normal', 'high', 'urgent')),
    status TEXT NOT NULL DEFAULT 'open' CHECK(status IN ('open', 'in_progress', 'done', 'cancelled')),
    due_date TEXT,                      -- YYYY-MM-DD, optional
    completed_at INTEGER,
    created_at INTEGER NOT NULL
);

CREATE INDEX idx_action_items_status ON action_items(status);
CREATE INDEX idx_action_items_priority ON action_items(priority);

-- ============================================================
-- 5. OPEN QUESTIONS — Follow-ups
-- ============================================================

CREATE TABLE open_questions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    question TEXT NOT NULL,
    context TEXT,                       -- Why this matters
    status TEXT NOT NULL DEFAULT 'open' CHECK(status IN ('open', 'answered', 'stale')),
    answer TEXT,
    created_at INTEGER NOT NULL,
    resolved_at INTEGER
);

CREATE INDEX idx_questions_status ON open_questions(status);

-- ============================================================
-- 6. AGENT STATE — Runtime state
-- ============================================================

CREATE TABLE agent_state (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at INTEGER NOT NULL
);

-- Default state entries
INSERT INTO agent_state (key, value, updated_at) VALUES
    ('heartbeat_count', '0', strftime('%s','now')),
    ('last_heartbeat', '0', strftime('%s','now')),
    ('reflection_due', 'false', strftime('%s','now')),
    ('last_reflection', '0', strftime('%s','now')),
    ('last_proactive_checkin', '0', strftime('%s','now'));

-- ============================================================
-- 7. IDENTITY EVOLUTION — How the agent changes over time
-- ============================================================

CREATE TABLE identity_evolution (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,                 -- YYYY-MM-DD
    shift TEXT NOT NULL,               -- What changed
    trigger TEXT,                       -- What caused it
    reflection_id INTEGER,             -- If born from a reflection
    created_at INTEGER NOT NULL,
    FOREIGN KEY (reflection_id) REFERENCES reflections(id)
);

CREATE INDEX idx_identity_date ON identity_evolution(date);

-- ============================================================
-- VIEWS
-- ============================================================

CREATE VIEW v_active_memories AS
SELECT * FROM memories WHERE is_active = 1 ORDER BY confidence DESC, updated_at DESC;

CREATE VIEW v_session_context AS
SELECT * FROM memories WHERE is_active = 1 AND confidence >= 0.80
ORDER BY type, updated_at DESC;

CREATE VIEW v_open_actions AS
SELECT * FROM action_items WHERE status IN ('open', 'in_progress')
ORDER BY
    CASE priority WHEN 'urgent' THEN 0 WHEN 'high' THEN 1 WHEN 'normal' THEN 2 WHEN 'low' THEN 3 END,
    created_at;

CREATE VIEW v_pending_distillation AS
SELECT * FROM reflections WHERE distilled = 0 ORDER BY date;

-- ============================================================
-- LIFECYCLE
-- ============================================================
--
--   Session activity
--       ↓
--   daily_logs (raw, 30 days)
--       ↓  [reflection cycle — 30min idle]
--   reflections
--       ├→ memories (confidence >= 0.50)
--       ├→ action_items (tasks to do)
--       ├→ open_questions (confidence < 0.50)
--       └→ identity_evolution (if shifts detected)
--
-- Cleanup (daily):
--   DELETE FROM daily_logs WHERE distilled = 1
--     AND date < date('now', '-30 days');
--   DELETE FROM reflections WHERE distilled = 1
--     AND date < date('now', '-30 days');
--   UPDATE open_questions SET status = 'stale'
--     WHERE status = 'open'
--     AND created_at < strftime('%s','now','-30 days');
--   UPDATE action_items SET status = 'cancelled'
--     WHERE status = 'open'
--     AND created_at < strftime('%s','now','-60 days');
--
-- ============================================================
