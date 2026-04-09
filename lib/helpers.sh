sql() { sqlite3 -batch "$DB" "$1"; }

sql_json() {
    local result
    result=$(sqlite3 -batch -json "$DB" "$1" 2>/dev/null)
    if [[ $? -eq 0 && -n "$result" ]]; then
        echo "$result"
    elif [[ $? -eq 0 ]]; then
        echo "[]"
    else
        sqlite3 -batch -header -column "$DB" "$1"
    fi
}

esc() { printf '%s' "${1//\'/\'\'}"; }

now_epoch() { date +%s; }

validate_int() {
    if ! [[ "$1" =~ ^[0-9]+$ ]]; then
        echo -e "${RED:-}Error:${NC:-} $2 must be a positive integer"
        exit 1
    fi
}

validate_num() {
    if ! [[ "$1" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo -e "${RED:-}Error:${NC:-} $2 must be a number"
        exit 1
    fi
}
