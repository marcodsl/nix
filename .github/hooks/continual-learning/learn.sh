#!/usr/bin/env bash

# Continual Learning - single script, all events
# Usage: learn.sh <event>  (SessionStart | PreToolUse | PostToolUse | Stop)
#
# Auto-initializes on first run. No manual setup needed.
# Two-tier memory: global (~/.copilot/learnings.db) + local (.copilot-memory/)

set -euxo pipefail


ensure_runtime_deps() {
  local missing=()
  local script_path

  command -v sqlite3 &>/dev/null || missing+=("nixpkgs#sqlite")
  command -v jq &>/dev/null || missing+=("nixpkgs#jq")
  [[ ${#missing[@]} -eq 0 ]] && return 0

  [[ "${CONTINUAL_LEARNING_NIX_BOOTSTRAPPED:-}" == "1" ]] && return 0
  command -v nix &>/dev/null || return 0

  script_path="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")"
  export CONTINUAL_LEARNING_NIX_BOOTSTRAPPED=1
  exec nix shell "${missing[@]}" --command bash "$script_path" "$@"
}


[[ "${SKIP_CONTINUAL_LEARNING:-}" == "true" ]] && exit 0
ensure_runtime_deps "$@"

EVENT="${1:-}"
INPUT=$(cat 2>/dev/null || echo "{}")
SUCCESS_THRESHOLD="${CONTINUAL_LEARNING_SUCCESS_THRESHOLD:-3}"
FAILURE_THRESHOLD="${CONTINUAL_LEARNING_FAILURE_THRESHOLD:-3}"
ROLLING_WINDOW_HOURS="${CONTINUAL_LEARNING_WINDOW_HOURS:-4}"

# --- Paths ---
GLOBAL_DB="$HOME/.copilot/learnings.db"
LOCAL_DIR=".copilot-memory"
LOCAL_DB="$LOCAL_DIR/learnings.db"

# --- Auto-init (creates everything on first run) ---
init_db() {
  local db="$1"
  mkdir -p "$(dirname "$db")"
  command -v sqlite3 &>/dev/null || return 0
  sqlite3 "$db" <<'SQL'
CREATE TABLE IF NOT EXISTS learnings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    scope TEXT NOT NULL,          -- 'global' or 'local'
    category TEXT NOT NULL,       -- 'pattern', 'mistake', 'preference', 'tool_insight'
    content TEXT NOT NULL,
    source TEXT,                  -- repo name, session id, etc.
    created_at TEXT DEFAULT (datetime('now')),
    last_seen TEXT DEFAULT (datetime('now')),
    hit_count INTEGER DEFAULT 1
);
CREATE TABLE IF NOT EXISTS tool_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT,
    tool_use_id TEXT,
    tool_name TEXT,
    phase TEXT,
    result TEXT,
    tool_input TEXT,
    tool_response TEXT,
    hook_event_name TEXT,
    transcript_path TEXT,
    ts TEXT DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_learnings_scope ON learnings(scope);
CREATE INDEX IF NOT EXISTS idx_learnings_category ON learnings(category);
SQL
}

ensure_column() {
  local db="$1" table_name="$2" column_name="$3" column_definition="$4"
  local exists

  exists=$(sqlite3 "$db" "PRAGMA table_info($table_name);" 2>/dev/null | awk -F'|' -v column_name="$column_name" '$2 == column_name { print 1; exit }')
  [[ -n "$exists" ]] && return 0

  sqlite3 "$db" "ALTER TABLE $table_name ADD COLUMN $column_definition;" 2>/dev/null || true
}

ensure_schema() {
  local db="$1"

  init_db "$db"
  has_sqlite || return 0

  ensure_column "$db" tool_log session_id "session_id TEXT"
  ensure_column "$db" tool_log tool_use_id "tool_use_id TEXT"
  ensure_column "$db" tool_log phase "phase TEXT"
  ensure_column "$db" tool_log tool_input "tool_input TEXT"
  ensure_column "$db" tool_log tool_response "tool_response TEXT"
  ensure_column "$db" tool_log hook_event_name "hook_event_name TEXT"
  ensure_column "$db" tool_log transcript_path "transcript_path TEXT"
  sqlite3 "$db" "CREATE INDEX IF NOT EXISTS idx_tool_log_session_tool_use ON tool_log(session_id, tool_use_id);" 2>/dev/null || true
  sqlite3 "$db" "CREATE INDEX IF NOT EXISTS idx_tool_log_phase_result ON tool_log(phase, result);" 2>/dev/null || true
}

has_sqlite() { command -v sqlite3 &>/dev/null; }
has_jq() { command -v jq &>/dev/null; }
repo_name() { basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; }
sql_escape() { printf "%s" "$1" | sed "s/'/''/g"; }
debug_log() { printf 'continual-learning: %s\n' "$*" >&2; }
emit_continue() { printf '{"continue":true}\n'; }

emit_session_context() {
  local context="$1"

  if has_jq; then
    jq -cn --arg context "$context" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$context}}'
  else
    emit_continue
  fi
}

json_string() {
  local filter="$1"

  has_jq || return 0
  jq -r "$filter // empty" <<< "$INPUT" 2>/dev/null || true
}

json_compact() {
  local filter="$1"

  has_jq || return 0
  jq -c "$filter // empty" <<< "$INPUT" 2>/dev/null || true
}

normalize_tool_response() {
  local raw="$1"

  if [[ -z "$raw" || "$raw" == "null" ]]; then
    printf ''
  elif [[ "$raw" =~ ^\{ || "$raw" =~ ^\[ ]]; then
    printf '%s' "$raw"
  else
    printf '%s' "$raw"
  fi
}

current_session_id() { json_string '.session_id // .sessionId'; }
current_hook_event_name() { json_string '.hook_event_name // .hookEventName'; }
current_transcript_path() { json_string '.transcript_path'; }

record_tool_event() {
  local db="$1" session_id="$2" tool_use_id="$3" tool_name="$4" phase="$5" result="$6"
  local tool_input="$7" tool_response="$8" hook_event_name="$9" transcript_path="${10}"
  local safe_session safe_tool_use safe_tool safe_phase safe_result safe_input safe_response safe_hook safe_transcript

  safe_session=$(sql_escape "$session_id")
  safe_tool_use=$(sql_escape "$tool_use_id")
  safe_tool=$(sql_escape "$tool_name")
  safe_phase=$(sql_escape "$phase")
  safe_result=$(sql_escape "$result")
  safe_input=$(sql_escape "$tool_input")
  safe_response=$(sql_escape "$tool_response")
  safe_hook=$(sql_escape "$hook_event_name")
  safe_transcript=$(sql_escape "$transcript_path")

  sqlite3 "$db" \
    "INSERT INTO tool_log (
        session_id,
        tool_use_id,
        tool_name,
        phase,
        result,
        tool_input,
        tool_response,
        hook_event_name,
        transcript_path
     ) VALUES (
        '$safe_session',
        '$safe_tool_use',
        '$safe_tool',
        '$safe_phase',
        '$safe_result',
        '$safe_input',
        '$safe_response',
        '$safe_hook',
        '$safe_transcript'
     );" 2>/dev/null || true
}

upsert_learning() {
  local db="$1" scope="$2" category="$3" content="$4" source="$5"
  local safe_scope safe_category safe_content safe_source

  safe_scope=$(sql_escape "$scope")
  safe_category=$(sql_escape "$category")
  safe_content=$(sql_escape "$content")
  safe_source=$(sql_escape "$source")

  sqlite3 "$db" \
    "UPDATE learnings
     SET hit_count = hit_count + 1, last_seen = datetime('now')
     WHERE scope = '$safe_scope' AND category = '$safe_category' AND content = '$safe_content';
     INSERT INTO learnings (scope, category, content, source)
     SELECT '$safe_scope','$safe_category','$safe_content','$safe_source'
     WHERE changes() = 0;" 2>/dev/null || true
}

recent_success_count() {
  local db="$1" tool_name="$2"
  local safe_tool

  safe_tool=$(sql_escape "$tool_name")

  sqlite3 "$db" \
    "SELECT COUNT(*) FROM tool_log
     WHERE tool_name = '$safe_tool'
       AND phase = 'PostToolUse'
       AND result = 'success'
       AND ts > datetime('now','-${ROLLING_WINDOW_HOURS} hours');" 2>/dev/null || echo "0"
}

collect_unmatched_attempt_tools() {
  local db="$1" session_id="$2"
  local safe_session

  safe_session=$(sql_escape "$session_id")

  sqlite3 "$db" \
    "SELECT attempt.tool_name FROM tool_log AS attempt
     WHERE attempt.session_id = '$safe_session'
       AND attempt.phase = 'PreToolUse'
       AND attempt.result = 'attempted'
       AND NOT EXISTS (
         SELECT 1 FROM tool_log AS success
         WHERE success.session_id = attempt.session_id
           AND success.tool_use_id = attempt.tool_use_id
           AND success.phase = 'PostToolUse'
           AND success.result = 'success'
       )
     GROUP BY attempt.tool_name
     HAVING COUNT(*) >= ${FAILURE_THRESHOLD};" 2>/dev/null || echo ""
}

prune_db() {
  local db="$1"

  sqlite3 "$db" "DELETE FROM tool_log WHERE ts < datetime('now','-7 days');" 2>/dev/null || true
  sqlite3 "$db" \
    "DELETE FROM learnings WHERE last_seen < datetime('now','-60 days') AND hit_count < 3;" 2>/dev/null || true
}

record_success_learning() {
  local db="$1" scope="$2" tool_name="$3"
  local count content source

  count=$(recent_success_count "$db" "$tool_name")
  [[ "$count" -lt "$SUCCESS_THRESHOLD" ]] && return 0

  if [[ "$scope" == "local" ]]; then
    content="Tool \"$tool_name\" succeeds repeatedly in $(repo_name) - it is a reliable default"
    source="auto:repo-pattern:$(repo_name):$(date -u +%Y%m%d)"
  else
    content="Tool \"$tool_name\" succeeds repeatedly - it is a reliable default"
    source="auto:global-pattern:$(date -u +%Y%m%d)"
  fi

  upsert_learning "$db" "$scope" pattern "$content" "$source"
}

record_failure_learnings() {
  local db="$1" scope="$2" session_id="$3"
  local unmatched_tools content source

  unmatched_tools=$(collect_unmatched_attempt_tools "$db" "$session_id")
  [[ -z "$unmatched_tools" ]] && return 0

  while IFS= read -r tool_name; do
    [[ -z "$tool_name" ]] && continue

    if [[ "$scope" == "local" ]]; then
      content="Tool \"$tool_name\" often starts without a matching completion in $(repo_name) - check the workflow"
      source="auto:repo-failure:$(repo_name):$(date -u +%Y%m%d)"
    else
      content="Tool \"$tool_name\" often starts without a matching completion - check the workflow"
      source="auto:global-failure:$(date -u +%Y%m%d)"
    fi

    upsert_learning "$db" "$scope" tool_insight "$content" "$source"
  done <<< "$unmatched_tools"
}

# ─── SESSION START ──────────────────────────────────────────
on_session_start() {
  has_sqlite || { emit_continue; exit 0; }

  local context=""

  # Load global learnings (cross-project)
  local global_count
  global_count=$(sqlite3 "$GLOBAL_DB" "SELECT COUNT(*) FROM learnings;" 2>/dev/null || echo "0")
  if [[ "$global_count" -gt 0 ]]; then
    local top_global
    top_global=$(sqlite3 "$GLOBAL_DB" \
      "SELECT '• [' || category || '] ' || content FROM learnings
       ORDER BY hit_count DESC, last_seen DESC LIMIT 5;" 2>/dev/null || echo "")
    [[ -n "$top_global" ]] && context="Global learnings ($global_count total):\n$top_global"
  fi

  # Load local learnings (this repo)
  if [[ -f "$LOCAL_DB" ]]; then
    local local_count
    local_count=$(sqlite3 "$LOCAL_DB" "SELECT COUNT(*) FROM learnings;" 2>/dev/null || echo "0")
    if [[ "$local_count" -gt 0 ]]; then
      local top_local
      top_local=$(sqlite3 "$LOCAL_DB" \
        "SELECT '• [' || category || '] ' || content FROM learnings
         ORDER BY hit_count DESC, last_seen DESC LIMIT 5;" 2>/dev/null || echo "")
      [[ -n "$top_local" ]] && context="$context\n\nRepo learnings for $(repo_name) ($local_count total):\n$top_local"
    fi
  fi

  if [[ -n "$context" ]]; then
    emit_session_context "$context"
  else
    emit_continue
  fi
}

# ─── PRE TOOL USE ───────────────────────────────────────────
on_pre_tool_use() {
  local session_id tool_use_id tool_name tool_input hook_event_name transcript_path

  has_sqlite || { emit_continue; exit 0; }
  has_jq || { debug_log "jq unavailable; skipping PreToolUse parsing"; emit_continue; exit 0; }

  session_id=$(current_session_id)
  tool_use_id=$(json_string '.tool_use_id')
  tool_name=$(json_string '.tool_name')
  tool_input=$(json_compact '.tool_input')
  hook_event_name=$(current_hook_event_name)
  transcript_path=$(current_transcript_path)

  if [[ -z "$session_id" || -z "$tool_use_id" || -z "$tool_name" ]]; then
    debug_log "missing required PreToolUse fields"
    emit_continue
    return 0
  fi

  record_tool_event "$GLOBAL_DB" "$session_id" "$tool_use_id" "$tool_name" "PreToolUse" "attempted" "$tool_input" "" "$hook_event_name" "$transcript_path"
  [[ -f "$LOCAL_DB" ]] && record_tool_event "$LOCAL_DB" "$session_id" "$tool_use_id" "$tool_name" "PreToolUse" "attempted" "$tool_input" "" "$hook_event_name" "$transcript_path"
  emit_continue
}

# ─── POST TOOL USE ──────────────────────────────────────────
on_post_tool_use() {
  local session_id tool_use_id tool_name tool_input tool_response hook_event_name transcript_path

  has_sqlite || { emit_continue; exit 0; }
  has_jq || { debug_log "jq unavailable; skipping PostToolUse parsing"; emit_continue; exit 0; }

  session_id=$(current_session_id)
  tool_use_id=$(json_string '.tool_use_id')
  tool_name=$(json_string '.tool_name')
  tool_input=$(json_compact '.tool_input')
  tool_response=$(normalize_tool_response "$(json_compact '.tool_response')")
  hook_event_name=$(current_hook_event_name)
  transcript_path=$(current_transcript_path)

  if [[ -z "$session_id" || -z "$tool_use_id" || -z "$tool_name" ]]; then
    debug_log "missing required PostToolUse fields"
    emit_continue
    return 0
  fi

  record_tool_event "$GLOBAL_DB" "$session_id" "$tool_use_id" "$tool_name" "PostToolUse" "success" "$tool_input" "$tool_response" "$hook_event_name" "$transcript_path"
  record_success_learning "$GLOBAL_DB" global "$tool_name"

  if [[ -f "$LOCAL_DB" ]]; then
    record_tool_event "$LOCAL_DB" "$session_id" "$tool_use_id" "$tool_name" "PostToolUse" "success" "$tool_input" "$tool_response" "$hook_event_name" "$transcript_path"
    record_success_learning "$LOCAL_DB" local "$tool_name"
  fi

  emit_continue
}

# ─── STOP ───────────────────────────────────────────────────
on_stop() {
  local session_id stop_hook_active global_attempts global_successes local_attempts local_successes

  has_sqlite || { emit_continue; exit 0; }
  has_jq || { debug_log "jq unavailable; skipping Stop parsing"; emit_continue; exit 0; }

  session_id=$(current_session_id)
  stop_hook_active=$(json_string '.stop_hook_active')

  if [[ -n "$stop_hook_active" && "$stop_hook_active" != "false" ]]; then
    debug_log "Stop invoked with stop_hook_active=$stop_hook_active"
  fi

  if [[ -z "$session_id" ]]; then
    debug_log "missing sessionId in Stop payload"
    emit_continue
    return 0
  fi

  record_failure_learnings "$GLOBAL_DB" global "$session_id"
  global_attempts=$(sqlite3 "$GLOBAL_DB" \
    "SELECT COUNT(*) FROM tool_log WHERE session_id = '$(sql_escape "$session_id")' AND phase = 'PreToolUse';" 2>/dev/null || echo "0")
  global_successes=$(sqlite3 "$GLOBAL_DB" \
    "SELECT COUNT(*) FROM tool_log WHERE session_id = '$(sql_escape "$session_id")' AND phase = 'PostToolUse' AND result = 'success';" 2>/dev/null || echo "0")

  if [[ -f "$LOCAL_DB" ]]; then
    record_failure_learnings "$LOCAL_DB" local "$session_id"
    local_attempts=$(sqlite3 "$LOCAL_DB" \
      "SELECT COUNT(*) FROM tool_log WHERE session_id = '$(sql_escape "$session_id")' AND phase = 'PreToolUse';" 2>/dev/null || echo "0")
    local_successes=$(sqlite3 "$LOCAL_DB" \
      "SELECT COUNT(*) FROM tool_log WHERE session_id = '$(sql_escape "$session_id")' AND phase = 'PostToolUse' AND result = 'success';" 2>/dev/null || echo "0")
    prune_db "$LOCAL_DB"
  else
    local_attempts="0"
    local_successes="0"
  fi

  prune_db "$GLOBAL_DB"
  debug_log "session $session_id summary: global attempts=$global_attempts successes=$global_successes local attempts=$local_attempts successes=$local_successes"
  emit_continue
}

ensure_schema "$GLOBAL_DB"
[[ -d ".git" ]] && ensure_schema "$LOCAL_DB"

# ─── Dispatch ───────────────────────────────────────────────
case "$EVENT" in
  SessionStart|sessionStart) on_session_start ;;
  PreToolUse|preToolUse)     on_pre_tool_use ;;
  PostToolUse|postToolUse)   on_post_tool_use ;;
  Stop|stop|sessionEnd)      on_stop ;;
  *)                         echo "Usage: learn.sh <SessionStart|PreToolUse|PostToolUse|Stop>" >&2; exit 1 ;;
esac

exit 0
