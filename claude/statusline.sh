#!/bin/sh
# Claude Code status line for Herdr terminals.
#
# Claude Code passes the session as JSON on stdin. This prints one line and
# leaves out any part the JSON does not provide:
#   <directory> (<branch>) | <model> | ctx N% | 5h N% left | effort <level>
#
# With HERDR_STATUSLINE_LABELS=1, it also reports the model, context use,
# 5-hour quota left, and effort to Herdr as agent.* labels on $HC_TERMINAL_ID.

input=$(cat)
newline='
'

# The footer path writes no files, not even /dev/null, so it also works where
# the filesystem is read-only. Errors are captured and dropped instead.
fields=$(printf '%s' "$input" | jq -r '
  def text: if type == "string" then gsub("[[:cntrl:]]"; "") else "" end;
  def percent:
    if type == "number" then [0, ([100, .] | min)] | max | round else "" end;
  if type == "object" then . else {} end
  | (.workspace.current_dir? // .cwd? // null | text),
    (.model.display_name? // null | text),
    (.context_window.used_percentage? // null | percent),
    (.rate_limits.five_hour.used_percentage? // null
      | if type == "number" then 100 - . else . end | percent),
    (.effort.level? // null | text)
' 2>&1) || fields=

# Command substitution drops trailing newlines. Put back one per field so
# every split below finds its separator.
fields=$fields$newline$newline$newline$newline$newline
dir=${fields%%"$newline"*}
fields=${fields#*"$newline"}
model=${fields%%"$newline"*}
fields=${fields#*"$newline"}
context=${fields%%"$newline"*}
fields=${fields#*"$newline"}
quota=${fields%%"$newline"*}
fields=${fields#*"$newline"}
effort=${fields%%"$newline"*}

line=
append() {
  if [ -n "$1" ]; then
    line="${line:+$line | }$1"
  fi
}

if [ -n "$dir" ]; then
  branch=$(git -C "$dir" symbolic-ref --quiet --short HEAD 2>&1) ||
    branch=$(git -C "$dir" rev-parse --short HEAD 2>&1) ||
    branch=
  # Keep only the last line in case Git printed a warning before the name.
  branch=${branch##*"$newline"}
  append "$(basename "$dir")${branch:+ ($branch)}"
fi
append "$model"
append "${context:+ctx $context%}"
append "${quota:+5h $quota% left}"
append "${effort:+effort $effort}"

if [ -n "$line" ]; then
  printf '%s\n' "$line"
fi

if [ "${HERDR_STATUSLINE_LABELS:-}" = 1 ] && [ -n "${HC_TERMINAL_ID:-}" ] &&
  command -v hc >/dev/null 2>&1; then
  # Empty values clear labels the session no longer reports. Run detached so a
  # slow or failing hc never delays or changes the footer.
  hc label "$HC_TERMINAL_ID" "agent.model=$model" "agent.context=$context" \
    "agent.quota=$quota" "agent.effort=$effort" </dev/null >/dev/null 2>&1 &
fi
