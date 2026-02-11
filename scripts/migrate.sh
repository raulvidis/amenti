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
    MIGRATED=0

    python3 << PYEOF
import re, subprocess, time, sys

now = int(time.time())
agent = "$AGENT_ID"
db = "$DB"

def sql(query):
    subprocess.run(["sqlite3", "-batch", db, query], check=True)

with open("$MEMORY_FILE", "r") as f:
    content = f.read()

lines = content.split("\n")
section = ""
migrated = 0

for line in lines:
    line = line.strip()
    if not line:
        continue

    # Track sections
    if line.startswith("## "):
        section = line[3:].strip().lower()
        continue
    if line.startswith("### "):
        section = line[4:].strip().lower()
        continue

    # Skip headers and meta
    if line.startswith("#") or line.startswith("*") or line.startswith("---"):
        continue

    # Parse bullet points
    if line.startswith("- "):
        item = line[2:].strip()

        # Skip completed items
        if item.startswith("[x]") or item.startswith("~~"):
            continue

        # Active tasks → action_items
        if item.startswith("[ ]"):
            task = item[4:].strip()
            task_esc = task.replace("'", "''")
            sql(f"INSERT INTO action_items (description, source, priority, status, agent_id, created_at) VALUES ('{task_esc}', 'migration', 'normal', 'open', '{agent}', {now});")
            migrated += 1
            continue

        # Detect memory type from content/section
        mtype = "fact"
        confidence = 0.85

        # Check for known patterns
        item_lower = item.lower()
        if any(w in section for w in ["lesson", "rule", "critical"]):
            mtype = "principle"
            confidence = 0.95
        elif any(w in section for w in ["insight", "key insight"]):
            mtype = "pattern"
            confidence = 0.85
        elif any(w in item_lower for w in ["preference", "likes", "hates", "loves", "wants"]):
            mtype = "preference"
            confidence = 0.90
        elif any(w in item_lower for w in ["goal", "target", "plan", "commit"]):
            mtype = "commitment"
            confidence = 0.90
        elif any(w in item_lower for w in ["bug", "fix", "error", "docker", "nginx", "config"]):
            mtype = "skill"
            confidence = 0.90
        elif any(w in item_lower for w in ["friend", "relationship", "girlfriend", "partner"]):
            mtype = "relationship"
            confidence = 0.90

        # Strip markdown formatting
        item = re.sub(r'\*\*(.+?)\*\*', r'\1', item)
        item = re.sub(r'[✅❌🔥💡🤔🚀✨]', '', item).strip()
        item = re.sub(r'^—\s*', '', item).strip()

        if len(item) < 5:
            continue

        item_esc = item.replace("'", "''")
        tokens = len(item) // 4

        # Generate tags from key words
        words = re.findall(r'\b[A-Za-z]{4,}\b', item_lower)
        tags = ",".join(set(words[:8]))

        sql(f"INSERT INTO memories (type, content, source, confidence, tags, token_estimate, agent_id, created_at, updated_at) VALUES ('{mtype}', '{item_esc}', 'migration', {confidence}, '{tags}', {tokens}, '{agent}', {now}, {now});")
        migrated += 1

print(f"Migrated: {migrated} items from MEMORY.md")
PYEOF

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
    existing=$(sql "SELECT COUNT(*) FROM daily_logs WHERE date = '${date_str}' AND agent_id = '${AGENT_ID}';")
    if [[ "$existing" -gt 0 ]]; then
        echo "  Skipping $date_str (already migrated)"
        continue
    fi

    # Read file content and insert as single log entry
    content=$(cat "$logfile" | sed "s/'/''/g" | head -500)
    if [[ -n "$content" ]]; then
        sql "INSERT INTO daily_logs (date, category, content, agent_id, created_at)
             VALUES ('${date_str}', 'daily_log', '${content}', '${AGENT_ID}', ${NOW});"
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

    existing=$(sql "SELECT COUNT(*) FROM reflections WHERE date = '${date_str}' AND agent_id = '${AGENT_ID}';")
    if [[ "$existing" -gt 0 ]]; then
        echo "  Skipping $date_str (already migrated)"
        continue
    fi

    content=$(cat "$reffile" | sed "s/'/''/g" | head -500)
    if [[ -n "$content" ]]; then
        # Extract first paragraph as summary
        summary=$(echo "$content" | head -5 | tr '\n' ' ' | cut -c1-200 | sed "s/'/''/g")
        sql "INSERT INTO reflections (date, summary, agent_id, created_at)
             VALUES ('${date_str}', '${summary}', '${AGENT_ID}', ${NOW});"
        REF_COUNT=$((REF_COUNT + 1))
        echo "  Migrated: $date_str"
    fi
done
echo "Reflections migrated: $REF_COUNT"

# ---- 4. Migrate open questions ----

echo ""
echo "--- Migrating open questions from MEMORY.md ---"
if [[ -f "$MEMORY_FILE" ]]; then
    python3 << PYEOF2
import re, subprocess, time

now = int(time.time())
agent = "$AGENT_ID"
db = "$DB"

def sql(query):
    subprocess.run(["sqlite3", "-batch", db, query], check=True)

with open("$MEMORY_FILE", "r") as f:
    content = f.read()

in_questions = False
migrated = 0

for line in content.split("\n"):
    line = line.strip()
    if "open question" in line.lower() or "## questions" in line.lower():
        in_questions = True
        continue
    if line.startswith("## ") and in_questions:
        in_questions = False
        continue

    if in_questions and line.startswith("- [ ]"):
        q = line[6:].strip()
        if q:
            q_esc = q.replace("'", "''")
            sql(f"INSERT INTO open_questions (question, context, status, agent_id, created_at) VALUES ('{q_esc}', 'migrated from MEMORY.md', 'open', '{agent}', {now});")
            migrated += 1

print(f"Questions migrated: {migrated}")
PYEOF2
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
echo "✅ Migration complete. Review with: amenti stats"
