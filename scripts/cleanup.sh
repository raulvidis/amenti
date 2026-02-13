#!/usr/bin/env bash
# ============================================================
# Amenti Smart Cleanup
# Retention based on confidence — high-value data survives
# ============================================================

set -euo pipefail

DB="${AMENTI_DB:-amenti.db}"

if [[ ! -f "$DB" ]]; then
    echo "Error: Database not found at $DB"
    exit 1
fi

sql() { sqlite3 -batch "$DB" "$1"; }

echo "=== Amenti Smart Cleanup ==="
echo "Database: $DB"
echo ""

# 1. Auto-promote high-confidence memories from reflections before deletion
# Reflections older than 30 days with confidence >= 0.80 get their memories
# extracted and promoted to permanent memories table (if not already there)
echo "--- Step 1: Auto-promoting high-confidence reflection memories ---"
PROMOTED=$(AMENTI_CLEANUP_DB="$DB" python3 -c "
import sqlite3, json, time, os

db_path = os.environ['AMENTI_CLEANUP_DB']
db = sqlite3.connect(db_path)
now = int(time.time())
promoted = 0

rows = db.execute(
    \"\"\"SELECT id, memories_extracted FROM reflections
       WHERE distilled = 0 AND date < date('now', '-30 days')
       AND memories_extracted IS NOT NULL AND memories_extracted != ''\"\"\"
).fetchall()

for ref_id, memories_json in rows:
    try:
        data = json.loads(memories_json)
        for m in data:
            if m.get('confidence', 0) >= 0.80:
                db.execute(
                    '''INSERT OR IGNORE INTO memories
                       (type, content, source, confidence, tags, token_estimate, agent_id, created_at, updated_at)
                       VALUES (?, ?, 'auto-promoted from reflection', ?, ?, ?, 'default', ?, ?)''',
                    (m.get('type', 'fact'), m['content'], m['confidence'],
                     m.get('tags', ''), len(m['content']) // 4, now, now))
                promoted += 1
    except Exception as e:
        print(f'Error processing reflection {ref_id}: {e}', __import__('sys').stderr)

db.commit()
db.close()
print(promoted)
" 2>&1)
echo "Promoted: $PROMOTED memories"

# Steps 2-7 wrapped in a single transaction for atomicity
echo ""
echo "--- Steps 2-7: Cleanup (transactional) ---"

OLD_LOGS=$(sql "SELECT COUNT(*) FROM daily_logs WHERE distilled = 1 AND date < date('now', '-30 days');")
OLD_REFS=$(sql "SELECT COUNT(*) FROM reflections WHERE distilled = 1 AND date < date('now', '-30 days');")
STALE_Q=$(sql "SELECT COUNT(*) FROM open_questions WHERE status = 'open' AND created_at < strftime('%s','now','-30 days');")
ABANDONED=$(sql "SELECT COUNT(*) FROM action_items WHERE status = 'open' AND created_at < strftime('%s','now','-60 days');")
ORPHANED=$(sql "SELECT COUNT(*) FROM memory_links WHERE source_id NOT IN (SELECT id FROM memories) OR target_id NOT IN (SELECT id FROM memories);")

sql "
BEGIN;

-- Step 2: Clean old daily logs (30 days, distilled only)
DELETE FROM daily_logs WHERE distilled = 1 AND date < date('now', '-30 days');

-- Step 3: Clean old reflections (30 days, distilled only)
DELETE FROM reflections WHERE distilled = 1 AND date < date('now', '-30 days');

-- Step 4: Mark non-distilled old items as distilled (promoted in step 1)
UPDATE reflections SET distilled = 1 WHERE distilled = 0 AND date < date('now', '-30 days');
UPDATE daily_logs SET distilled = 1 WHERE distilled = 0 AND date < date('now', '-30 days');

-- Step 5: Stale questions (30 days with no answer)
UPDATE open_questions SET status = 'stale' WHERE status = 'open' AND created_at < strftime('%s','now','-30 days');

-- Step 6: Cancel abandoned action items (60 days)
UPDATE action_items SET status = 'cancelled' WHERE status = 'open' AND created_at < strftime('%s','now','-60 days');

-- Step 7: Clean orphaned memory links
DELETE FROM memory_links WHERE source_id NOT IN (SELECT id FROM memories) OR target_id NOT IN (SELECT id FROM memories);

COMMIT;
"

echo "Removed: $OLD_LOGS daily logs"
echo "Removed: $OLD_REFS reflections"
echo "Staled: $STALE_Q questions"
echo "Cancelled: $ABANDONED action items"
echo "Removed: $ORPHANED orphaned links"

# Summary
echo ""
echo "=== Cleanup Complete ==="
echo -n "Active memories:    "; sql "SELECT COUNT(*) FROM memories WHERE is_active = 1;"
echo -n "Total token est:    "; sql "SELECT COALESCE(SUM(token_estimate),0) FROM memories WHERE is_active = 1;"
echo -n "Daily logs:         "; sql "SELECT COUNT(*) FROM daily_logs;"
echo -n "Reflections:        "; sql "SELECT COUNT(*) FROM reflections;"
echo -n "Open actions:       "; sql "SELECT COUNT(*) FROM action_items WHERE status IN ('open','in_progress');"
echo -n "Open questions:     "; sql "SELECT COUNT(*) FROM open_questions WHERE status = 'open';"
