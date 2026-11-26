#!/bin/sh

set +x +v

usage() {
  printf '%s\n' 'Usage: scripts/check-env.zsh codex [--profile NAME] | claude | claude-k' >&2
  exit 2
}

case "$#:${1-}" in
  1:codex|1:claude|1:claude-k) ;;
  3:codex)
    [ "$2" = --profile ] || usage
    case "$3" in
      ''|*[!A-Za-z0-9_-]*) usage ;;
      *) ;;
    esac
    ;;
  *) usage ;;
esac

target=$1
codex_profile=${3-}
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

# Design: report whether each named MCP credential is exported and nonempty
# without printing its value. A missing awk is its own failure, distinct from
# an unset variable.
# Implementation: awk is resolved on PATH once; ENVIRON reads only exported
# variables. The names arrive one per line.
# Example: check_mcp_environment 'CONTEXT7_API_KEY' prints
# "[OK] CONTEXT7_API_KEY is exported and nonempty" or an unset error.
check_mcp_environment() {
  if [ -z "$1" ]; then
    note 'The current MCP configuration has no local environment variables to check.'
    return
  fi
  if ! command -v awk >/dev/null; then
    fail 'awk is missing from PATH, so the MCP credential variables could not be checked.'
    return
  fi
  newline='
'
  pending=$1${newline}
  while [ -n "${pending}" ]; do
    variable_name=${pending%%"${newline}"*}
    pending=${pending#*"${newline}"}
    if awk -v name="${variable_name}" 'BEGIN { exit(length(ENVIRON[name]) == 0) }' </dev/null; then
      ok "${variable_name} is exported and nonempty"
    else
      fail "${variable_name} is unset, unexported, or empty"
    fi
  done
}

# Design: run the TOML companion with a Python 3.11+ interpreter. Prefer the
# interpreter uv finds offline, and fall back to python3 when uv is absent or
# its interpreter cannot run the script. Missing uv is reported separately by
# the required-tool loop, not here.
# Implementation: status 3 means no usable tomllib (a skipped check); other
# nonzero statuses are parse failures.
# Example: codex_mcp_variables scripts/check-codex-config.py ~/.codex/config.toml
# prints one variable name per line and returns 0.
codex_mcp_variables() {
  if command -v uv >/dev/null &&
      codex_python=$(uv python find '>=3.11' --offline --no-python-downloads \
        --no-cache --no-project --no-config) &&
      [ -f "${codex_python}" ] && [ -x "${codex_python}" ]; then
    if "${codex_python}" -IB "$@"; then
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
  python3 -IB "$@"
}

# Design: check the selected Codex files, then their MCP variable names. The
# companion parser must exist beside this script before its result is
# interpreted, so a missing companion is not reported as invalid TOML.
# Implementation: the companion path is derived from the invoked path of
# this script; a symlinked entry point outside scripts/ has no companion.
# Example: check_codex_config ~/.codex/config.toml ~/.codex/work.config.toml
check_codex_config() {
  for codex_config_file do
    check_file "${codex_config_file}" || return
  done

  codex_companion="${script_dir}/check-codex-config.py"
  if [ ! -f "${codex_companion}" ] || [ ! -r "${codex_companion}" ]; then
    fail "Missing or unreadable Codex checker companion ${codex_companion}. Run check-env.zsh by its path inside the Herdr scripts directory."
    return
  fi
  if codex_variables=$(codex_mcp_variables "${codex_companion}" "$@" 2>/dev/null); then
    ok 'Checked Codex TOML syntax and basic MCP fields'
    check_mcp_environment "${codex_variables}"
  else
    case "$?" in
      3) note 'Skipped TOML and MCP credential checks. They require Python 3.11 or later with tomllib, found through uv or python3.' ;;
      *) fail "Could not parse the selected Codex TOML or combined MCP settings in $*" ;;
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
    def string_array: type == "array" and all(.[]; type == "string");
    def string_map: type == "object" and all(.[]; type == "string");
    def basic_server:
      if type != "object" then false
      elif (has("type") | not) or .type == "stdio" then
        (.command | type == "string" and length > 0)
        and ((has("args") | not) or (.args | string_array))
        and ((has("env") | not) or (.env | string_map))
      elif .type == "http" or .type == "sse" or .type == "streamable-http"
          or .type == "ws" then
        (.url | type == "string")
        and ((has("headers") | not) or (.headers | string_map))
      else false end;

    if length == 1 and (.[0] | type == "object") then .[0]
    else error("Expected one settings object") end
    | if has("mcpServers") then .mcpServers else {} end
    | if type != "object" then error("Expected an MCP server object") else . end
    | [ .[] | if basic_server then . else error("Invalid MCP server settings") end
        | (.command, .args, .env, .url, .headers)
        | .. | strings | scan("\\$\\{([A-Za-z_][A-Za-z0-9_]*)\\}") | .[0] ]
    | unique[]
  ' "${claude_mcp_file}" 2>/dev/null); then
    ok 'Checked the Claude Code user-level MCP configuration'
    check_mcp_environment "${claude_variables}"
    if jq -e 'any(.mcpServers[]?; .command? == "github-mcp-server")' \
        "${claude_mcp_file}" >/dev/null 2>&1; then
      claude_github_mcp=1
    fi
  else
    fail "Could not parse JSON or MCP settings in ${claude_mcp_file}"
  fi
}

printf 'Checking %s\n' "${target}"
if [ -n "${HC_TERMINAL_ID:-}" ]; then
  ok 'Detected the current Herdr terminal'
  # Design: the hooks run the installed helper and agents run the one on
  # PATH, so both must be the same file with the same content as this
  # checkout's source. Stale content and a shadowing helper fail separately;
  # an equivalent symlink passes.
  # Implementation: cmp compares bytes with the source beside this script,
  # and the shell test -ef compares the resolved files without extra tools.
  # Example: after `install -m 0755 scripts/herdr-context.cjs ~/.local/bin/herdr-context`,
  # both checks print [OK]; an older copy prints "... is stale".
  context_helper="${HOME}/.local/bin/herdr-context"
  context_source="${script_dir}/herdr-context.cjs"
  if [ ! -f "${context_helper}" ] || [ ! -x "${context_helper}" ]; then
    fail "Install the context checkpoint helper as an executable at ${context_helper}"
  elif [ ! -f "${context_source}" ] || [ ! -r "${context_source}" ]; then
    fail "Could not compare the context checkpoint helper: missing or unreadable source ${context_source}"
  elif ! command -v cmp >/dev/null; then
    fail 'cmp is missing from PATH, so the context checkpoint helper could not be compared with its source.'
  elif cmp -s "${context_source}" "${context_helper}"; then
    ok "Context checkpoint helper at ${context_helper} matches ${context_source}"
  else
    fail "The context checkpoint helper at ${context_helper} is stale. Reinstall it from ${context_source}."
  fi
  if ! context_command=$(command -v herdr-context); then
    fail 'herdr-context is missing from PATH. Add ~/.local/bin to PATH.'
  elif [ "${context_command}" -ef "${context_helper}" ]; then
    ok 'herdr-context is on PATH'
  else
    fail "herdr-context on PATH is ${context_command}, which shadows ${context_helper}."
  fi
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
  codex_config_dir=${CODEX_HOME:-${HOME}/.codex}
  if [ -n "${codex_profile}" ]; then
    check_codex_config "${codex_config_dir}/config.toml" \
      "${codex_config_dir}/${codex_profile}.config.toml"
  else
    check_codex_config "${codex_config_dir}/config.toml"
  fi
  if ! command -v uvx >/dev/null; then
    note 'Optional Atlassian and Android MCP servers need uvx on PATH.'
  fi
  if ! command -v adb >/dev/null; then
    note 'The optional Android MCP server needs adb on PATH.'
  fi
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
  claude_github_mcp=0
  check_claude_config "${claude_config_dir}"
  if ! command -v github-mcp-server >/dev/null; then
    if [ "${claude_github_mcp}" = 1 ]; then
      fail 'The user-level MCP configuration runs github-mcp-server, but it is missing from PATH.'
    else
      note 'GitHub MCP requires github-mcp-server on PATH.'
    fi
  fi
fi

if [ "${failures}" -gt 0 ]; then
  printf 'Checks finished with %s required item(s) missing or invalid.\n' "${failures}"
  exit 1
fi
printf '%s\n' 'Basic environment checks passed.'
