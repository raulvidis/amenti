#!/usr/bin/env bash
# ============================================================
# Amenti — Reindex: Embed all memories with vector embeddings
# Usage: ./scripts/reindex.sh [--force]
#   --force: Re-embed all memories (even those already embedded)
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
EMBED_PORT="${AMENTI_EMBED_PORT:-9819}"
EMBED_URL="http://127.0.0.1:${EMBED_PORT}"

# Load config
source <(python3 -c "
import os
for candidate in [os.environ.get('AMENTI_CONFIG',''), os.path.expanduser('~/.config/amenti/config'), os.path.expanduser('~/.amentirc')]:
    if candidate and os.path.isfile(candidate):
        for line in open(candidate):
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                print(f'export {line}')
        break
" 2>/dev/null || true)

DB="${AMENTI_DB:-amenti.db}"
FORCE="${1:-}"

echo "=== Amenti Vector Reindex ==="
echo "Database: $DB"

# Check if embedding column exists
HAS_COL=$(sqlite3 "$DB" "SELECT COUNT(*) FROM pragma_table_info('memories') WHERE name='embedding';")
if [[ "$HAS_COL" == "0" ]]; then
    echo "Adding embedding column..."
    sqlite3 "$DB" < "$PROJECT_DIR/src/schema_vec.sql"
    echo "✅ Schema updated"
fi

# Check embed server
if ! curl -sf "$EMBED_URL/health" > /dev/null 2>&1; then
    echo "❌ Embed server not running on $EMBED_URL"
    echo "Start it: python3 $PROJECT_DIR/src/embed_server.py"
    exit 1
fi

MODEL_INFO=$(curl -sf "$EMBED_URL/info")
echo "Embed server: $(echo "$MODEL_INFO" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(f"{d[\"model\"]} ({d[\"dimensions\"]}d)")')"

# Count memories to embed
if [[ "$FORCE" == "--force" ]]; then
    COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM memories WHERE is_active = 1;")
    echo "Force mode: re-embedding ALL $COUNT active memories"
else
    COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM memories WHERE is_active = 1 AND embedding IS NULL;")
    echo "Memories to embed: $COUNT"
fi

if [[ "$COUNT" == "0" ]]; then
    echo "✅ All memories already embedded"
    exit 0
fi

# Batch embed — grab all texts, send to server, update DB
echo "Embedding $COUNT memories..."

python3 << 'PYEOF'
import sqlite3, json, os, sys, urllib.request

db_path = os.environ.get("AMENTI_DB", "amenti.db")
embed_url = f"http://127.0.0.1:{os.environ.get('AMENTI_EMBED_PORT', '9819')}"
force = len(sys.argv) > 1 and sys.argv[1] == "--force"

db = sqlite3.connect(db_path)
db.row_factory = sqlite3.Row

if force or os.environ.get("REINDEX_FORCE"):
    rows = db.execute("SELECT id, content, tags FROM memories WHERE is_active = 1").fetchall()
else:
    rows = db.execute("SELECT id, content, tags FROM memories WHERE is_active = 1 AND embedding IS NULL").fetchall()

if not rows:
    print("Nothing to embed")
    sys.exit(0)

# Batch in groups of 32
BATCH_SIZE = 32
total = len(rows)
done = 0

for i in range(0, total, BATCH_SIZE):
    batch = rows[i:i+BATCH_SIZE]
    # Combine content + tags for richer embeddings
    texts = [f"{r['content']} {r['tags'] or ''}" for r in batch]
    
    req = urllib.request.Request(
        f"{embed_url}/embed_batch",
        data=json.dumps({"texts": texts}).encode(),
        headers={"Content-Type": "application/json"},
    )
    resp = urllib.request.urlopen(req)
    result = json.loads(resp.read())
    
    for row, vector in zip(batch, result["vectors"]):
        db.execute(
            "UPDATE memories SET embedding = ? WHERE id = ?",
            (json.dumps(vector), row["id"])
        )
    
    done += len(batch)
    pct = int(done / total * 100)
    print(f"  [{pct:3d}%] {done}/{total} embedded", end="\r")

db.commit()
db.close()
print(f"\n✅ Embedded {total} memories")
PYEOF

echo "Done!"
