#!/usr/bin/env bash
# ============================================================
# Amenti Migration — File-based memory → SQLite
# Parses MEMORY.md, daily logs, and reflections
# ============================================================

set -euo pipefail

DB="${AMENTI_DB:-amenti.db}"
AGENT_ID="${AMENTI_AGENT:-default}"
WORKSPACE="${1:-.}"

if [[ ! -f "$DB" ]]; then
    echo "Error: Database not found at $DB. Run 'amenti init' first."
    exit 1
fi

sql() { sqlite3 -batch "$DB" "$1"; }
esc() { printf '%s' "${1//\'/\'\'}"; }
NOW=$(date +%s)

echo "=== Amenti Migration ==="
echo "Database: $DB"
echo "Workspace: $WORKSPACE"
echo "Agent: $AGENT_ID"
echo ""

# ---- 1. Migrate MEMORY.md ----

MEMORY_FILE="$WORKSPACE/MEMORY.md"
if [[ -f "$MEMORY_FILE" ]]; then
    echo "--- Migrating MEMORY.md ---"

    AMENTI_MIGRATE_DB="$DB" \
    AMENTI_MIGRATE_AGENT="$AGENT_ID" \
    AMENTI_MIGRATE_FILE="$MEMORY_FILE" \
    python3 -c "
import re, sqlite3, time, os

now = int(time.time())
agent = os.environ['AMENTI_MIGRATE_AGENT']
db_path = os.environ['AMENTI_MIGRATE_DB']
memory_file = os.environ['AMENTI_MIGRATE_FILE']

db = sqlite3.connect(db_path)

with open(memory_file, 'r') as f:
    content = f.read()

lines = content.split('\n')
section = ''
migrated = 0

for line in lines:
    line = line.strip()
    if not line:
        continue

    # Track sections
    if line.startswith('## '):
        section = line[3:].strip().lower()
        continue
    if line.startswith('### '):
        section = line[4:].strip().lower()
        continue

    # Skip headers and meta
    if line.startswith('#') or line.startswith('*') or line.startswith('---'):
        continue

    # Parse bullet points
    if line.startswith('- '):
        item = line[2:].strip()

        # Skip completed items
        if item.startswith('[x]') or item.startswith('~~'):
            continue

        # Active tasks -> action_items
        if item.startswith('[ ]'):
            task = item[4:].strip()
            db.execute(
                '''INSERT INTO action_items (description, source, priority, status, agent_id, created_at)
                   VALUES (?, 'migration', 'normal', 'open', ?, ?)''',
                (task, agent, now))
            migrated += 1
            continue

        # Detect memory type from content/section
        mtype = 'fact'
        confidence = 0.85

        item_lower = item.lower()
        if any(w in section for w in ['lesson', 'rule', 'critical']):
            mtype = 'principle'
            confidence = 0.95
        elif any(w in section for w in ['insight', 'key insight']):
            mtype = 'pattern'
            confidence = 0.85
        elif any(w in item_lower for w in ['preference', 'likes', 'hates', 'loves', 'wants']):
            mtype = 'preference'
            confidence = 0.90
        elif any(w in item_lower for w in ['goal', 'target', 'plan', 'commit']):
            mtype = 'commitment'
            confidence = 0.90
        elif any(w in item_lower for w in ['bug', 'fix', 'error', 'docker', 'nginx', 'config']):
            mtype = 'skill'
            confidence = 0.90
        elif any(w in item_lower for w in ['friend', 'relationship', 'partner', 'family']):
            mtype = 'relationship'
            confidence = 0.90

        # Strip markdown formatting
        item = re.sub(r'\*\*(.+?)\*\*', r'\1', item)
        item = re.sub(r'[^\\w\\s.,;:!?\\-\\(\\)\\'\\\"/@#\\$%&+=]', '', item).strip()
        item = re.sub(r'^—\s*', '', item).strip()

        if len(item) < 5:
            continue

        tokens = len(item) // 4

        # Generate rich tags
        words = re.findall(r'\b[A-Za-z0-9]{3,}\b', item_lower)
        specials = re.findall(r'\b[A-Z]{2,}\b', item)
        specials += re.findall(r'\d+[kKmM]?\b', item)
        specials += re.findall(r'v?\d+\.\d+', item)
        names = re.findall(r'\b[A-Z][a-z]{2,}\b', item)
        all_tags = list(set([w.lower() for w in words + specials + names if len(w) >= 2]))[:15]
        tags = ','.join(all_tags)

        db.execute(
            '''INSERT INTO memories (type, content, source, confidence, tags, token_estimate, agent_id, created_at, updated_at)
               VALUES (?, ?, 'migration', ?, ?, ?, ?, ?, ?)''',
            (mtype, item, confidence, tags, tokens, agent, now, now))
        migrated += 1

db.commit()
db.close()
print(f'Migrated: {migrated} items from MEMORY.md')
"

else
    echo "No MEMORY.md found at $MEMORY_FILE — skipping"
fi

# ---- 2. Migrate daily logs ----

echo ""
echo "--- Migrating daily log files ---"
LOG_COUNT=0
for logfile in "$WORKSPACE"/memory/20??-??-??.md; do
    [[ -f "$logfile" ]] || continue
    date_str=$(basename "$logfile" .md)

    # Check if already migrated
    existing=$(sql "SELECT COUNT(*) FROM daily_logs WHERE date = '$(esc "$date_str")' AND agent_id = '$(esc "$AGENT_ID")';")
    if [[ "$existing" -gt 0 ]]; then
        echo "  Skipping $date_str (already migrated)"
        continue
    fi

    # Read file content and insert
    content=$(head -500 "$logfile")
    if [[ -n "$content" ]]; then
        sql "INSERT INTO daily_logs (date, category, content, agent_id, created_at)
             VALUES ('$(esc "$date_str")', 'daily_log', '$(esc "$content")', '$(esc "$AGENT_ID")', ${NOW});"
        LOG_COUNT=$((LOG_COUNT + 1))
        echo "  Migrated: $date_str"
    fi
done
echo "Daily logs migrated: $LOG_COUNT"

# ---- 3. Migrate reflection files ----

echo ""
echo "--- Migrating reflection files ---"
REF_COUNT=0
for reffile in "$WORKSPACE"/memory/reflections/20??-??-??.md; do
    [[ -f "$reffile" ]] || continue
    date_str=$(basename "$reffile" .md)

    existing=$(sql "SELECT COUNT(*) FROM reflections WHERE date = '$(esc "$date_str")' AND agent_id = '$(esc "$AGENT_ID")';")
    if [[ "$existing" -gt 0 ]]; then
        echo "  Skipping $date_str (already migrated)"
        continue
    fi

    content=$(head -500 "$reffile")
    if [[ -n "$content" ]]; then
        # Extract first paragraph as summary
        summary=$(echo "$content" | head -5 | tr '\n' ' ' | cut -c1-200)
        sql "INSERT INTO reflections (date, summary, agent_id, created_at)
             VALUES ('$(esc "$date_str")', '$(esc "$summary")', '$(esc "$AGENT_ID")', ${NOW});"
        REF_COUNT=$((REF_COUNT + 1))
        echo "  Migrated: $date_str"
    fi
done
echo "Reflections migrated: $REF_COUNT"

# ---- 4. Migrate open questions ----

echo ""
echo "--- Migrating open questions from MEMORY.md ---"
if [[ -f "$MEMORY_FILE" ]]; then
    AMENTI_MIGRATE_DB="$DB" \
    AMENTI_MIGRATE_AGENT="$AGENT_ID" \
    AMENTI_MIGRATE_FILE="$MEMORY_FILE" \
    python3 -c "
import re, sqlite3, time, os

now = int(time.time())
agent = os.environ['AMENTI_MIGRATE_AGENT']
db_path = os.environ['AMENTI_MIGRATE_DB']
memory_file = os.environ['AMENTI_MIGRATE_FILE']

db = sqlite3.connect(db_path)

with open(memory_file, 'r') as f:
    content = f.read()

in_questions = False
migrated = 0

for line in content.split('\n'):
    line = line.strip()
    if 'open question' in line.lower() or '## questions' in line.lower():
        in_questions = True
        continue
    if line.startswith('## ') and in_questions:
        in_questions = False
        continue

    if in_questions and line.startswith('- [ ]'):
        q = line[6:].strip()
        if q:
            db.execute(
                '''INSERT INTO open_questions (question, context, status, agent_id, created_at)
                   VALUES (?, 'migrated from MEMORY.md', 'open', ?, ?)''',
                (q, agent, now))
            migrated += 1

db.commit()
db.close()
print(f'Questions migrated: {migrated}')
"
fi

# ---- Summary ----

echo ""
echo "=== Migration Complete ==="
echo -n "Active memories:    "; sql "SELECT COUNT(*) FROM memories WHERE is_active = 1;"
echo -n "Daily logs:         "; sql "SELECT COUNT(*) FROM daily_logs;"
echo -n "Reflections:        "; sql "SELECT COUNT(*) FROM reflections;"
echo -n "Action items:       "; sql "SELECT COUNT(*) FROM action_items WHERE status = 'open';"
echo -n "Open questions:     "; sql "SELECT COUNT(*) FROM open_questions WHERE status = 'open';"
echo ""
echo "Migration complete. Review with: amenti stats"
