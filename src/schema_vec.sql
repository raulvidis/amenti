-- ============================================================
-- Amenti — Vector Embedding Migration (v4)
-- Adds embedding column to memories table for semantic search
-- ============================================================

-- Add embedding column (stored as JSON array of floats)
ALTER TABLE memories ADD COLUMN embedding TEXT;

-- Index for quick filtering of embedded vs non-embedded
CREATE INDEX IF NOT EXISTS idx_memories_has_embedding 
    ON memories(CASE WHEN embedding IS NOT NULL THEN 1 ELSE 0 END);
