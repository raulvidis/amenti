#!/usr/bin/env bash
# ============================================================
# Amenti — Initialize Database
# ============================================================

set -euo pipefail

DB="${AMENTI_DB:-amenti.db}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEMA="$SCRIPT_DIR/../src/schema.sql"

if [[ -f "$DB" ]]; then
    echo "Database already exists at $DB"
    read -p "Reinitialize? This will DELETE all data. (y/N) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] || exit 0
    cp "$DB" "${DB}.bak"
    echo "Backup saved to ${DB}.bak"
    rm "$DB"
fi

if [[ ! -f "$SCHEMA" ]]; then
    echo "Error: schema.sql not found at $SCHEMA"
    exit 1
fi

sqlite3 "$DB" < "$SCHEMA"
echo "✅ Database initialized at $DB"
echo ""
echo "Tables created:"
sqlite3 "$DB" ".tables"
echo ""
echo "Next steps:"
echo "  1. Install CLI:  ln -s $(realpath "$SCRIPT_DIR/../bin/amenti") /usr/local/bin/amenti"
echo "  2. Set DB path:  export AMENTI_DB=$DB"
echo "  3. Run migrate:  AMENTI_DB=$DB $SCRIPT_DIR/migrate.sh /path/to/workspace"
