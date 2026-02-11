#!/bin/bash
# ============================================================
# Amenti — Daily Cleanup Script
# ============================================================
# Usage: ./scripts/cleanup.sh [path/to/database.db]
# Run daily (e.g., via cron at 6:30 AM)

set -euo pipefail

DB_PATH="${1:-./amenti.db}"

if [ ! -f "$DB_PATH" ]; then
    echo "❌ Database not found at $DB_PATH"
    exit 1
fi

echo "🧹 Running Amenti daily cleanup..."

sqlite3 "$DB_PATH" <<'SQL'
-- Delete distilled daily logs older than 7 days
DELETE FROM daily_logs WHERE distilled = 1 AND date < date('now', '-7 days');

-- Delete distilled reflections older than 7 days
DELETE FROM reflections WHERE distilled = 1 AND date < date('now', '-7 days');

-- Mark stale open questions (older than 30 days)
UPDATE open_questions SET status = 'stale'
WHERE status = 'open' AND created_at < unixepoch('now', '-30 days');

-- Clean up old token tracking (older than 90 days)
DELETE FROM token_usage WHERE created_at < unixepoch('now', '-90 days');

-- Report
SELECT 'Cleanup complete' as status;
SELECT 'Active memories: ' || COUNT(*) FROM memories WHERE is_active = 1;
SELECT 'Open questions: ' || COUNT(*) FROM open_questions WHERE status = 'open';
SELECT 'Pending logs: ' || COUNT(*) FROM daily_logs WHERE distilled = 0;
SELECT 'Pending reflections: ' || COUNT(*) FROM reflections WHERE distilled = 0;
SQL

echo "✅ Done!"
