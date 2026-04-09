-- ============================================================
-- Amenti — Vector Embedding Migration (v3 → v4)
-- Adds embedding column to memories table for semantic search
-- Run this on existing v3 databases to upgrade.
-- Fresh installs include embedding in schema.sql already.
-- ============================================================

-- Add embedding column (stored as JSON array of floats)
ALTER TABLE memories ADD COLUMN embedding TEXT;

-- Index for quick filtering of embedded vs non-embedded
CREATE INDEX IF NOT EXISTS idx_memories_has_embedding 
    ON memories(CASE WHEN embedding IS NOT NULL THEN 1 ELSE 0 END);

-- Create schema_version table if it doesn't exist (upgrade path)
CREATE TABLE IF NOT EXISTS schema_version (
    version INTEGER PRIMARY KEY,
    applied_at INTEGER NOT NULL
);

-- Create llm_cache table if it doesn't exist (upgrade path)
CREATE TABLE IF NOT EXISTS llm_cache (
    hash TEXT PRIMARY KEY,
    result TEXT NOT NULL,
    created_at INTEGER NOT NULL
);

-- Record migration
INSERT OR IGNORE INTO schema_version (version, applied_at) VALUES (4, strftime('%s','now'));
