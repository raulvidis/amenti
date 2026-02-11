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
PROMOTED=0
while IFS=$'\t' read -r ref_id memories_json; do
    if [[ -n "$memories_json" && "$memories_json" != "null" ]]; then
        echo "$memories_json" | python3 -c "
import sys, json, time
try:
    data = json.loads(sys.stdin.read())
    now = int(time.time())
    for m in data:
        if m.get('confidence', 0) >= 0.80:
            content = m['content'].replace(\"'\", \"''\")
            mtype = m.get('type', 'fact')
            conf = m['confidence']
            tags = m.get('tags', '').replace(\"'\", \"''\")
            tokens = len(content) // 4
            sql = f\"INSERT OR IGNORE INTO memories (type, content, source, confidence, tags, token_estimate, agent_id, created_at, updated_at) VALUES ('{mtype}', '{content}', 'auto-promoted from reflection', {conf}, '{tags}', {tokens}, 'default', {now}, {now});\"
            print(sql)
except Exception as e:
    print(f'Error processing reflection: {e}', file=sys.stderr)
" | while read -r insert_sql; do
            sql "$insert_sql"
            PROMOTED=$((PROMOTED + 1))
        done
    fi
done < <(sqlite3 -batch -separator $'\t' "$DB" "SELECT id, memories_extracted FROM reflections WHERE distilled = 0 AND date < date('now', '-30 days') AND memories_extracted IS NOT NULL AND memories_extracted != '';")
echo "Promoted: $PROMOTED memories"

# 2. Clean old daily logs (30 days, distilled only)
echo ""
echo "--- Step 2: Cleaning daily logs older than 30 days ---"
OLD_LOGS=$(sql "SELECT COUNT(*) FROM daily_logs WHERE distilled = 1 AND date < date('now', '-30 days');")
sql "DELETE FROM daily_logs WHERE distilled = 1 AND date < date('now', '-30 days');"
echo "Removed: $OLD_LOGS daily logs"

# 3. Clean old reflections (30 days, distilled only)
echo ""
echo "--- Step 3: Cleaning reflections older than 30 days ---"
OLD_REFS=$(sql "SELECT COUNT(*) FROM reflections WHERE distilled = 1 AND date < date('now', '-30 days');")
sql "DELETE FROM reflections WHERE distilled = 1 AND date < date('now', '-30 days');"
echo "Removed: $OLD_REFS reflections"

# 4. Mark non-distilled old items as distilled (they've been promoted in step 1)
echo ""
echo "--- Step 4: Marking old undistilled items ---"
sql "UPDATE reflections SET distilled = 1 WHERE distilled = 0 AND date < date('now', '-30 days');"
sql "UPDATE daily_logs SET distilled = 1 WHERE distilled = 0 AND date < date('now', '-30 days');"

# 5. Stale questions (30 days with no answer)
echo ""
echo "--- Step 5: Marking stale questions ---"
STALE_Q=$(sql "SELECT COUNT(*) FROM open_questions WHERE status = 'open' AND created_at < strftime('%s','now','-30 days');")
sql "UPDATE open_questions SET status = 'stale' WHERE status = 'open' AND created_at < strftime('%s','now','-30 days');"
echo "Staled: $STALE_Q questions"

# 6. Cancel abandoned action items (60 days)
echo ""
echo "--- Step 6: Cancelling abandoned action items ---"
ABANDONED=$(sql "SELECT COUNT(*) FROM action_items WHERE status = 'open' AND created_at < strftime('%s','now','-60 days');")
sql "UPDATE action_items SET status = 'cancelled' WHERE status = 'open' AND created_at < strftime('%s','now','-60 days');"
echo "Cancelled: $ABANDONED action items"

# 7. Clean orphaned memory links (pointing to deleted/inactive memories)
echo ""
echo "--- Step 7: Cleaning orphaned links ---"
ORPHANED=$(sql "SELECT COUNT(*) FROM memory_links WHERE source_id NOT IN (SELECT id FROM memories) OR target_id NOT IN (SELECT id FROM memories);")
sql "DELETE FROM memory_links WHERE source_id NOT IN (SELECT id FROM memories) OR target_id NOT IN (SELECT id FROM memories);"
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
