#!/bin/sh

set +x +v

case "$#:${1-}" in
  1:codex|1:claude|1:claude-k) ;;
  *)
    printf '%s\n' 'Usage: scripts/check-env.zsh codex|claude|claude-k' >&2
    exit 2
    ;;
esac

target=$1
case "$0" in
  */*) script_dir=${0%/*} ;;
  *) script_dir=. ;;
esac

failures=0

ok() { printf '[OK] %s\n' "$*"; }
note() { printf '[Note] %s\n' "$*"; }
fail() {
  printf '[Error] %s\n' "$*"
  failures=$((failures + 1))
}

check_file() {
  if [ -f "$1" ] && [ -r "$1" ]; then
    ok "$1"
  else
    fail "Missing or unreadable configuration file $1"
    return 1
  fi
}

check_mcp_environment() {
  if [ -z "$1" ]; then
    note 'The current MCP configuration has no local environment variables to check.'
    return
  fi
  newline='
'
  pending=$1${newline}
  while [ -n "${pending}" ]; do
    variable_name=${pending%%"${newline}"*}
    pending=${pending#*"${newline}"}
    if /usr/bin/awk -v name="${variable_name}" 'BEGIN { exit(length(ENVIRON[name]) == 0) }' </dev/null; then
      ok "${variable_name} is exported and nonempty"
    else
      fail "${variable_name} is unset, unexported, or empty"
    fi
  done
}

codex_mcp_variables() {
  command -v uv >/dev/null || return 3
  if codex_python=$(uv python find --offline --no-python-downloads \
      --no-cache --no-project --no-config) &&
      [ -f "${codex_python}" ] && [ -x "${codex_python}" ]; then
    if "${codex_python}" -IB "$1" "$2"; then
      return 0
    else
      codex_python_status=$?
      case "${codex_python_status}" in
        3|126|127) ;;
        *) return "${codex_python_status}" ;;
      esac
    fi
  fi

  command -v python3 >/dev/null || return 3
  python3 -IB "$1" "$2"
}

check_codex_config() {
  codex_config_file=$1
  check_file "${codex_config_file}" || return

  if codex_variables=$(codex_mcp_variables "${script_dir}/check-codex-config.py" "${codex_config_file}" 2>/dev/null); then
    ok 'Checked Codex TOML syntax and basic MCP fields'
    check_mcp_environment "${codex_variables}"
  else
    case "$?" in
      3) note 'Skipped TOML and MCP credential checks. They require uv and an installed Python with tomllib.' ;;
      *) fail "Could not parse TOML or MCP environment settings in ${codex_config_file}" ;;
    esac
  fi
}

check_claude_config() {
  claude_settings_file="$1/settings.json"
  claude_mcp_file="$1/.claude.json"

  check_file "${claude_settings_file}"
  if ! command -v jq >/dev/null; then
    note 'JSON and MCP credential checks require jq.'
    return
  fi

  if [ -f "${claude_settings_file}" ] && [ -r "${claude_settings_file}" ]; then
    if jq -es 'length == 1 and (.[0] | type == "object")' "${claude_settings_file}" >/dev/null 2>&1; then
      ok 'Checked Claude Code settings.json syntax'
    else
      fail "Could not parse JSON in ${claude_settings_file}"
    fi
  fi
  if [ ! -e "${claude_mcp_file}" ] && [ ! -L "${claude_mcp_file}" ]; then
    note "No user-level MCP configuration at ${claude_mcp_file}"
    return
  fi
  check_file "${claude_mcp_file}" || return

  if claude_variables=$(jq -rs '
    if length == 1 and (.[0] | type == "object") then .[0]
    else error("Expected one settings object") end
    | if has("mcpServers") then .mcpServers else {} end
    | if type != "object" then error("Expected an MCP server object") else . end
    | [ .[] | if type != "object" then error("Expected an MCP server") else . end
        | (.command, .args, .env, .url, .headers)
        | .. | strings | scan("\\$\\{([A-Za-z_][A-Za-z0-9_]*)\\}") | .[0] ]
    | unique[]
  ' "${claude_mcp_file}" 2>/dev/null); then
    ok 'Checked the Claude Code user-level MCP configuration'
    check_mcp_environment "${claude_variables}"
  else
    fail "Could not parse JSON or MCP settings in ${claude_mcp_file}"
  fi
}

printf 'Checking %s\n' "${target}"
if [ -n "${HC_TERMINAL_ID:-}" ]; then
  ok 'Detected the current Herdr terminal'
else
  note 'HC_TERMINAL_ID is missing. Run this check from the Herdr terminal where you launch the tool.'
fi

for tool in uv hc git node npm npx; do
  if command -v "${tool}" >/dev/null; then
    ok "${tool} is on PATH"
  else
    fail "${tool} is missing from PATH"
  fi
done

if [ "${target}" = codex ]; then
  # A non-directory config path keeps the version probe from creating Codex helper files.
  if ! command -v codex >/dev/null; then
    fail 'codex is missing from PATH'
  elif codex_version=$(CODEX_HOME=/dev/null codex --version 2>/dev/null) && [ -n "${codex_version}" ]; then
    ok "${codex_version}"
  else
    fail 'Could not determine the Codex CLI version'
  fi
  check_codex_config "${CODEX_HOME:-${HOME}/.codex}/config.toml"
  for tool in uvx adb; do
    if ! command -v "${tool}" >/dev/null; then
      note "${tool} is missing from PATH. Jira, Confluence, or Android MCP may require it."
    fi
  done
else
  claude_config_dir="${HOME}/.${target}"
  claude_bin="${HOME}/.local/bin/claude"
  if [ ! -x "${claude_bin}" ]; then
    fail "No executable Claude Code binary at ${claude_bin}"
  elif claude_version=$(CLAUDE_CONFIG_DIR="${claude_config_dir}" "${claude_bin}" --version 2>/dev/null) && [ -n "${claude_version}" ]; then
    ok "${claude_version}"
  else
    fail "Could not determine the Claude Code version of ${claude_bin}"
  fi
  check_claude_config "${claude_config_dir}"
  if ! command -v github-mcp-server >/dev/null; then
    note 'GitHub MCP requires github-mcp-server on PATH.'
  fi
fi

if [ "${failures}" -gt 0 ]; then
  printf 'Checks finished with %s required item(s) missing or invalid.\n' "${failures}"
  exit 1
fi
printf '%s\n' 'Basic environment checks passed.'
