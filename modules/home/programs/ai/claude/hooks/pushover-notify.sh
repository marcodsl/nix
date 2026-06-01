# Runs under `set -euo pipefail` injected by writeShellApplication (default.nix).
# Goal: never propagate a failure, and report internal errors + unknown event types to Pushover.

notify() {
  # $1=title  $2=body  $3=priority
  local token user
  token=$(cat "$PUSHOVER_TOKEN_FILE" 2>/dev/null) || return 0
  user=$(cat "$PUSHOVER_USER_FILE" 2>/dev/null) || return 0
  [[ -z "$token" || -z "$user" ]] && return 0
  curl -sS --max-time 8 https://api.pushover.net/1/messages.json \
    --data-urlencode "token=${token}" \
    --data-urlencode "user=${user}" \
    --data-urlencode "title=${1}" \
    --data-urlencode "message=${2}" \
    --data-urlencode "priority=${3}" \
    >/dev/null 2>&1 || true
  return 0
}

# Best-effort mtime throttle: returns success (still throttled) when $1 was
# touched within the last $2 seconds, otherwise touches it and returns failure.
throttled() {
  # $1=lockfile  $2=window_secs
  local now last
  now=$(date +%s 2>/dev/null || echo 0)
  if [[ -f "$1" ]]; then
    last=$(stat -c %Y "$1" 2>/dev/null || echo 0)
    (( now - last < $2 )) && return 0
  fi
  touch "$1" 2>/dev/null || true
  return 1
}

notify_error() {
  # $1=body ; throttled to one notification per session per 5 min
  local host
  throttled "/tmp/claude-pushover-err-${session:-unknown}" 300 && return 0
  host=$(hostname 2>/dev/null || echo host)
  notify "Claude Code hook error @ ${host}" "$1" 1
}

# shellcheck disable=SC2329  # invoked indirectly via the ERR trap below
on_error() {
  trap - ERR
  notify_error "exit ${1} at line ${2}: ${3}"
  exit 0
}
trap 'on_error "$?" "$LINENO" "$BASH_COMMAND"' ERR

payload=$(cat)

event=$(jq -r '.notification_type // ""' <<<"$payload" 2>/dev/null)
session=$(jq -r '.session_id // "unknown"' <<<"$payload" 2>/dev/null)
cwd=$(jq -r '.cwd // ""' <<<"$payload" 2>/dev/null)

[[ -z "$event" ]] && exit 0

throttled "/tmp/claude-pushover-${session}-${event}" 60 && exit 0

case "$event" in
  permission_prompt) body="Permission requested" ;;
  idle_prompt) body="Waiting for input" ;;
  elicitation_dialog) body="MCP elicitation" ;;
  auth_success|elicitation_complete|elicitation_response) exit 0 ;;
  *) notify_error "unexpected notification_type: ${event}"; exit 0 ;;
esac

project="${cwd:+$(basename "$cwd")}"
project="${project:-unknown}"
title="Claude Code @ $(hostname): ${project}"

notify "$title" "$body" 0

exit 0
