#!/bin/bash
# ============================================================
# Amenti — Initialize Memory Database
# ============================================================
# Usage: ./scripts/init-db.sh [path/to/database.db]
# Default: ./amenti.db

set -euo pipefail

DB_PATH="${1:-./amenti.db}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_PATH="$SCRIPT_DIR/../src/schema.sql"

if [ -f "$DB_PATH" ]; then
    echo "⚠️  Database already exists at $DB_PATH"
    echo "    To recreate, delete it first: rm $DB_PATH"
    exit 1
fi

if [ ! -f "$SCHEMA_PATH" ]; then
    echo "❌ Schema not found at $SCHEMA_PATH"
    exit 1
fi

echo "🏛️  Initializing Amenti database at $DB_PATH..."
sqlite3 "$DB_PATH" < "$SCHEMA_PATH"

echo "✅ Database created successfully!"
echo ""
echo "Tables:"
sqlite3 "$DB_PATH" ".tables"
echo ""
echo "Next steps:"
echo "  1. Copy templates/MEMORY.md to your agent workspace"
echo "  2. Copy templates/SKILL.md to your agent skills folder"
echo "  3. Set AMENTI_DB=$DB_PATH in your agent environment"
