mapfile -t fields < <(jq -r '.transcript_path // "", .cwd // ""')
transcript=${fields[0]:-}
cwd=${fields[1]:-}

[[ -z "$transcript" || ! -f "$transcript" ]] && exit 0

last_user_line=$(jq -r '
  select(
    .type == "user"
    and (.message.content | type == "array")
    and (any(.message.content[]?; .type == "tool_result") | not)
  )
  | input_line_number
' "$transcript" | tail -n 1)

edited=$(tail -n "+${last_user_line:-1}" "$transcript" | jq -r '
  select(.type == "assistant")
  | .message.content[]?
  | select(.type == "tool_use")
  | select(.name == "Edit" or .name == "Write" or .name == "MultiEdit" or .name == "NotebookEdit")
  | (.input.file_path // .input.notebook_path // empty)
' | sort -u)

[[ -z "$edited" ]] && exit 0

messages=()

if grep -qE '\.nix$' <<<"$edited"; then
  if [[ -n "$cwd" && -f "$cwd/flake.nix" ]]; then
    if ! nix flake check --no-build --no-pure-eval "$cwd" >&2; then
      messages+=("nix flake check failed - see stderr above")
    fi
  fi
fi

if (( ${#messages[@]} > 0 )); then
  printf -v joined '%s\n' "${messages[@]}"
  jq -nc --arg msg "$joined" '{systemMessage: $msg}'
fi
