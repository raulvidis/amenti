#!/bin/bash
# ============================================================
# Amenti — Migrate from File-Based Memory
# ============================================================
# Usage: ./scripts/migrate.sh <database.db> <workspace_path>
#
# Reads existing MEMORY.md, USER.md, SOUL.md, IDENTITY.md
# and imports relevant data into the Amenti database.
#
# This is a one-time migration helper. Review the output
# and adjust confidence scores as needed.

set -euo pipefail

DB_PATH="${1:-}"
WORKSPACE="${2:-}"

if [ -z "$DB_PATH" ] || [ -z "$WORKSPACE" ]; then
    echo "Usage: ./scripts/migrate.sh <database.db> <workspace_path>"
    echo "Example: ./scripts/migrate.sh ./amenti.db /root/.openclaw/workspace"
    exit 1
fi

if [ ! -f "$DB_PATH" ]; then
    echo "❌ Database not found at $DB_PATH. Run init-db.sh first."
    exit 1
fi

echo "🏛️  Amenti Migration Tool"
echo "   Database: $DB_PATH"
echo "   Workspace: $WORKSPACE"
echo ""

# Check for files
for file in MEMORY.md USER.md SOUL.md IDENTITY.md; do
    if [ -f "$WORKSPACE/$file" ]; then
        echo "✅ Found $file"
    else
        echo "⚠️  $file not found (skipping)"
    fi
done

echo ""
echo "⚠️  Migration is semi-automatic."
echo "    This script prepares the data but you should review"
echo "    and adjust confidence scores before finalizing."
echo ""
echo "To complete migration manually:"
echo "  1. Review your MEMORY.md for facts, preferences, patterns, etc."
echo "  2. Insert each as a memory with appropriate type + confidence"
echo "  3. Extract active tasks into the new lean MEMORY.md"
echo "  4. Import USER.md fields into user_context table"
echo "  5. Import SOUL.md/IDENTITY.md into agent_identity table"
echo ""
echo "Example inserts:"
echo ""
echo "  sqlite3 $DB_PATH \"INSERT INTO memories (type, content, source, confidence, created_at, updated_at)"
echo "    VALUES ('fact', 'User sleeps 10-11pm, wakes 6:50am', 'USER.md', 0.95, unixepoch('now'), unixepoch('now'));\""
echo ""
echo "  sqlite3 $DB_PATH \"INSERT INTO user_context (key, value, category, updated_at)"
echo "    VALUES ('timezone', 'Europe/Bucharest', 'basic', unixepoch('now'));\""
echo ""
echo "  sqlite3 $DB_PATH \"INSERT INTO agent_identity (key, value, category, updated_at)"
echo "    VALUES ('name', 'Nova', 'core', unixepoch('now'));\""
echo ""
echo "For a fully automated migration, use the agent skill file"
echo "(templates/SKILL.md) to have your agent do the migration itself."
