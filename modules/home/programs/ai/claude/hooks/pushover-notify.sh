payload=$(cat)

event=$(jq -r '.notification_type // ""' <<<"$payload")
session=$(jq -r '.session_id // "unknown"' <<<"$payload")
cwd=$(jq -r '.cwd // ""' <<<"$payload")

[[ -z "$event" ]] && exit 0

lock="/tmp/claude-pushover-${session}-${event}"
now=$(date +%s)
if [[ -f "$lock" ]]; then
  last=$(stat -c %Y "$lock" 2>/dev/null || echo 0)
  if (( now - last < 60 )); then
    exit 0
  fi
fi
mkdir -p "$(dirname "$lock")"
touch "$lock"

case "$event" in
  permission_prompt) body="Permission requested" ;;
  idle_prompt) body="Waiting for input" ;;
  elicitation_dialog) body="MCP elicitation" ;;
  *) body="$event" ;;
esac

project="${cwd:+$(basename "$cwd")}"
project="${project:-unknown}"
title="Claude Code @ $(hostname): ${project}"

token=$(<"$PUSHOVER_TOKEN_FILE")
user=$(<"$PUSHOVER_USER_FILE")

if [[ -z "$token" || -z "$user" ]]; then
  exit 0
fi

curl -sS --max-time 8 https://api.pushover.net/1/messages.json \
  --data-urlencode "token=${token}" \
  --data-urlencode "user=${user}" \
  --data-urlencode "title=${title}" \
  --data-urlencode "message=${body}" \
  --data-urlencode "priority=0" \
  >/dev/null || true

exit 0
