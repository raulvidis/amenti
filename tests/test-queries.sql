-- ============================================================
-- Amenti Test Suite — Schema v2
-- ============================================================

-- 1. Test FTS5 search for memories
-- Expected: Returns "Always backup config files before editing" from memories table
SELECT '=== TEST 1: FTS5 search ===';
SELECT m.id, m.type, m.content, m.confidence
FROM memories_fts f
JOIN memories m ON f.rowid = m.id
WHERE memories_fts MATCH 'backup config files'
ORDER BY f.rank LIMIT 5;

-- 2. Test daily_logs table with 30-day retention
SELECT '=== TEST 2: Daily logs query ===';
SELECT COUNT(*) as total_logs
FROM daily_logs
WHERE date >= date('now', '-30 days');

-- 3. Test reflections table
SELECT '=== TEST 3: Reflections query ===';
SELECT COUNT(*) as total_reflections
FROM reflections;

-- 4. Test action_items table
SELECT '=== TEST 4: Action items query ===';
SELECT COUNT(*) as total_actions
FROM action_items
WHERE status IN ('open', 'in_progress');

-- 5. Test agent_state table
SELECT '=== TEST 5: Agent state ===';
SELECT key, value
FROM agent_state
ORDER BY key;

-- 6. Test identity_evolution table
SELECT '=== TEST 6: Identity evolution ===';
SELECT COUNT(*) as total_shifts
FROM identity_evolution;

-- 7. Test open_questions table
SELECT '=== TEST 7: Open questions ===';
SELECT COUNT(*) as total_questions
FROM open_questions
WHERE status = 'open';

-- 8. Test views
SELECT '=== TEST 8: Active memories view ===';
SELECT * FROM v_active_memories LIMIT 5;

SELECT '=== TEST 9: Open actions view ===';
SELECT * FROM v_open_actions LIMIT 5;

SELECT '=== TEST 10: Pending distillation ===';
SELECT * FROM v_pending_distillation;

-- 11. Test search with no results
SELECT '=== TEST 11: Search with no results (should return empty) ===';
SELECT m.id, m.type, m.content
FROM memories_fts f
JOIN memories m ON f.rowid = m.id
WHERE memories_fts MATCH 'xyz123nonexistent' LIMIT 5;

-- 12. Test inserting a memory
SELECT '=== TEST 12: Insert test memory ===';
INSERT INTO memories (type, content, source, confidence, tags, created_at, updated_at)
VALUES ('test', 'This is a test memory inserted via SQL', 'test', 1.0, 'test', strftime('%s','now'), strftime('%s','now'));

-- 13. Verify insertion
SELECT '=== TEST 12b: Verify insertion ===';
SELECT id, type, content, confidence FROM memories WHERE type = 'test' ORDER BY id DESC LIMIT 1;

-- 14. Cleanup test memory
SELECT '=== TEST 14: Cleanup ===';
DELETE FROM memories WHERE type = 'test' AND content = 'This is a test memory inserted via SQL';

-- 15. Test supersedes functionality
SELECT '=== TEST 15: Supersedes test ===';
INSERT INTO memories (type, content, source, confidence, supersedes_id, created_at, updated_at)
VALUES ('fact', 'Old memory', 'test', 1.0, NULL, strftime('%s','now')-10, strftime('%s','now')-10);

INSERT INTO memories (type, content, source, confidence, supersedes_id, created_at, updated_at)
VALUES ('fact', 'New memory (replaces old)', 'test', 1.0, (SELECT id FROM memories WHERE content = 'Old memory'), strftime('%s','now'), strftime('%s','now'));

SELECT '=== TEST 15b: Check that old is deactivated ===';
SELECT id, content, is_active FROM memories WHERE type = 'fact' ORDER BY id DESC LIMIT 2;

DELETE FROM memories WHERE type = 'fact';

-- 16. Test daily_logs insertion
SELECT '=== TEST 16: Insert daily log ===';
INSERT INTO daily_logs (date, category, content, created_at)
VALUES ('2026-02-11', 'test', 'Test daily log entry', strftime('%s','now'));

SELECT '=== TEST 16b: Verify insertion ===';
SELECT * FROM daily_logs WHERE category = 'test';

DELETE FROM daily_logs WHERE category = 'test';

-- 17. Test action_items insertion
SELECT '=== TEST 17: Insert action item ===';
INSERT INTO action_items (description, source, priority, status, created_at)
VALUES ('Test action item', 'test', 'normal', 'open', strftime('%s','now'));

SELECT '=== TEST 17b: Verify insertion ===';
SELECT * FROM action_items WHERE description = 'Test action item';

DELETE FROM action_items WHERE description = 'Test action item';

-- 18. Test open_questions insertion
SELECT '=== TEST 18: Insert open question ===';
INSERT INTO open_questions (question, context, status, created_at)
VALUES ('Test question', 'Test context', 'open', strftime('%s','now'));

SELECT '=== TEST 18b: Verify insertion ===';
SELECT * FROM open_questions WHERE question = 'Test question';

DELETE FROM open_questions WHERE question = 'Test question';

-- 19. Test agent_state update
SELECT '=== TEST 19: Update agent state ===';
INSERT OR REPLACE INTO agent_state (key, value, updated_at)
VALUES ('heartbeat_count', '1000', strftime('%s','now'));

SELECT '=== TEST 19b: Verify update ===';
SELECT key, value FROM agent_state WHERE key = 'heartbeat_count';

-- 20. Test identity_evolution insertion
SELECT '=== TEST 20: Insert identity shift ===';
INSERT INTO identity_evolution (date, shift, trigger, created_at)
VALUES ('2026-02-11', 'Agent is becoming more proactive', 'Test trigger', strftime('%s','now'));

SELECT '=== TEST 20b: Verify insertion ===';
SELECT * FROM identity_evolution WHERE shift = 'Agent is becoming more proactive';

DELETE FROM identity_evolution WHERE shift = 'Agent is becoming more proactive';

-- ============================================================
-- Summary
-- ============================================================
SELECT '=== TEST SUITE COMPLETE ===';
SELECT 'All 20 tests should pass if schema is correct.';
