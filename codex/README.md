# Set up the Codex development environment

Complete the [shared prerequisites](../README.md#prerequisites), then run these
commands from the repository root in a Herdr terminal.

## Installation

```zsh
npm install --global @openai/codex && codex --version
```

If your terminal cannot find `codex`, check that the global npm binary directory
is on its `PATH`. If npm reports a permissions error, set the global install
location to a directory you can write to, then retry the installation.
[npm global installation permissions][npm-permissions]

Once the installation succeeds and `codex --version` reports the installed
version, sign in.

```zsh
codex login
```

## MCP configuration

The Jira, Confluence, and Android MCP servers use `uvx`. The Android MCP server
also requires Android SDK Platform-Tools and `adb` on `PATH`. The template
uses company endpoints for Jira and Confluence. Configure the services your
account can access.

On a fresh Mac, install Python before running the TOML environment check.

```zsh
uv python install
```

This command creates `config.toml` only if the file is missing.

```zsh
(
  set -e
  codex_config_dir="${CODEX_HOME:-$HOME/.codex}"
  mkdir -p "$codex_config_dir"
  if [[ ! -e "$codex_config_dir/config.toml" ]]; then
    (
      umask 077
      set -C
      cat < codex/config.toml > "$codex_config_dir/config.toml"
    )
  fi
)
```

Back up `config.toml` if it already exists. Add any missing MCP servers from
the [configuration template](config.toml). Update existing
`[mcp_servers.<name>]` tables and their `.env` subtables in place so each table
appears only once. Use `env_vars` to pass credentials and remove any old
plaintext token fields.

## MCP credentials

Run the relevant commands one at a time in the Herdr terminal where you will
launch Codex. Enter each credential at its prompt. Your input stays hidden.
Skip commands for variables that are already exported. When switching to a new
terminal, check that it has the variables you need.

```zsh
read -rs 'GITLAB_PERSONAL_ACCESS_TOKEN?GitLab token: ' &&
  export GITLAB_PERSONAL_ACCESS_TOKEN
read -rs 'JIRA_PERSONAL_TOKEN?Jira token: ' &&
  export JIRA_PERSONAL_TOKEN
read -rs 'CONFLUENCE_PERSONAL_TOKEN?Confluence token: ' &&
  export CONFLUENCE_PERSONAL_TOKEN
read -rs 'CONTEXT7_API_KEY?Context7 API key: ' &&
  export CONTEXT7_API_KEY
```

## Optional skills and plugins

To use the Claude Code `frontend-design` skill in Codex, first install the
plugin using the [Claude Code setup guide](../claude/README.md). The command
below preserves any existing copy of the skill.

```zsh
(
  set -e
  codex_skills_dir="${CODEX_HOME:-$HOME/.codex}/skills"
  marketplace_dir="$HOME/.claude/plugins/marketplaces/claude-plugins-official"
  plugin_dir="$marketplace_dir/plugins/frontend-design"
  mkdir -p "$codex_skills_dir"
  if [[ ! -e "$codex_skills_dir/frontend-design" ]]; then
    cp -R "$plugin_dir/skills/frontend-design" "$codex_skills_dir/"
  fi
)
```

Flutter development requires Flutter and Dart on `PATH`.
[Flutter plugin setup guide](https://docs.flutter.dev/ai/get-started)

```zsh
codex plugin marketplace add flutter/agent-plugins
codex plugin add dart-flutter@dart-flutter
```

## Verification and launch

Check that `codex mcp list` reads your configuration and lists the MCP servers
you intend to use. Then launch Codex from the same Herdr terminal and call the
MCP tools you need to verify their connections.

```zsh
codex mcp list
```

```zsh
codex --no-daemon
```

[npm-permissions]: https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally/
