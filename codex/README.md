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

The [base configuration](config.toml) registers Context7. Add GitLab and other
services to a profile for the Herdr panes that use them.

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

Back up an existing `config.toml` before merging. Update the
`[mcp_servers.context7]` table in place, replacing `startup_timeout_ms` with
`startup_timeout_sec`. If you installed an earlier template, move any GitLab,
Atlassian, and Android tables you use, including their `.env` subtables,
into the appropriate profiles. Remove those tables from the base file so
profile selection controls when they load. When updating or moving a server,
remove any literal tokens from its `.env` subtable and from arguments such
as `--token` or `--api-key`. Keep the credential names in `env_vars` and
export their values in the launching pane.

## Context checkpoints

Install the [shared helper](../HERDR.md#context-checkpoints). Use
[hooks.json](hooks.json) in `${CODEX_HOME:-$HOME/.codex}`. Create the file
if it is missing, or merge its two hook groups into your existing hooks.
If you manage hooks in `config.toml`, add the same groups there. Use
`/hooks` in Codex to review and trust the two definitions before using them,
and again after replacing an earlier version. Keep the template's `save`
command as written. It passes `codex` to select the Codex block format,
and it stops compaction when the helper is missing or fails in a Herdr
pane.

```zsh
(
  set -e
  codex_config_dir="${CODEX_HOME:-$HOME/.codex}"
  mkdir -p "$codex_config_dir"
  if [[ ! -e "$codex_config_dir/hooks.json" ]]; then
    (
      umask 077
      set -C
      cat < codex/hooks.json > "$codex_config_dir/hooks.json"
    )
  fi
)
```

The helper saves before compacting. After compaction, `SessionStart`
prompts the agent to run `herdr-context load` for the same session's task
data. Other `SessionStart` sources start without a note.
Use agent-initiated `/compact` while there is still room to record the task.
Codex's built-in model-limit compaction is still available as a fallback.
In a Herdr pane, the hook stops it when the session has no note. An
untrusted hook does not run, and a hook that times out does not stop
compaction, so neither protects the note.
[Codex hooks](https://learn.chatgpt.com/docs/hooks)

## Personal profiles

A profile is a `<name>.config.toml` file beside `config.toml`. Codex layers
it over the base user file when you pass `--profile <name>`. Choose model,
sandbox, approvals, and additional MCP servers for the role.
The environment check reports a missing profile file before you launch.

### GitLab work profile

The [work profile](work.config.toml) adds GitLab.com, enables workspace
edits, and uses on-request approvals. Merge the example into an existing
`work.config.toml` or create the file with:

```zsh
(
  set -e
  codex_config_dir="${CODEX_HOME:-$HOME/.codex}"
  mkdir -p "$codex_config_dir"
  if [[ ! -e "$codex_config_dir/work.config.toml" ]]; then
    (
      umask 077
      set -C
      cat < codex/work.config.toml > "$codex_config_dir/work.config.toml"
    )
  fi
)
```

For self-managed GitLab, set that profile's `GITLAB_API_URL` to your API
endpoint. For review with GitLab, copy the GitLab tables into the review
profile and set `GITLAB_PERMISSION_MODE = "readonly"` under
`[mcp_servers.gitlab.env]`. Use a token scoped to the review task.

### Review profile

Save this as `review.config.toml` beside `config.toml` so reviewers can
fix issues in the task checkout with on-request approvals. If you used the
previous read-only profile, change its `sandbox_mode` to `workspace-write`
before launching the reviewer.

```toml
sandbox_mode = "workspace-write"
approval_policy = "on-request"

[mcp_servers.context7]
enabled = false
```

This example disables Context7 for local reviews. Merge the Context7
setting into any existing review profile. To opt in, set `enabled = true`
in that table and export `CONTEXT7_API_KEY` in the pane that will launch
the reviewer.

Launch from the task checkout with `codex --no-daemon --profile review`.
Apply repairs during the turn assigned by the lead and leave the frozen
candidate intact. Use read-only tooling and scoped credentials for remote
MCP servers added to this profile.
[Herdr review and repair](../HERDR.md#review-and-repair)

### Herdr team communication

Codex's filesystem sandboxes can deny the Herdr Core socket. During team
setup, verify `hc` resolves to your trusted Herdr command. For a role that
needs to call it, add narrowly scoped rules to
`${CODEX_HOME:-$HOME/.codex}/rules/herdr-team.rules`. These rules allow
matching commands to run outside the sandbox, so list only the team names
and commands needed by the role. Rules in a Codex home apply to sessions
using that home and load at startup. Choose the names before starting
Codex, then pass them to `hc run --name` as described in
[Herdr setup](../HERDR.md#prepare-team-communication).

This example lets `project-review` inspect itself and report to
`project-lead`. Use the team's chosen names.

```starlark
prefix_rule(pattern = ["hc", "get", "--", "project-review"], decision = "allow")
prefix_rule(pattern = ["hc", "send", "--", "project-lead"], decision = "allow")
```

For a lead, include a `get` rule for its own name and separate rules for
each member. Use `["hc", "read", "--lines", "0", "--", "project-review"]`
for the visible screen and
`["hc", "wait", "--timeout", "45", "--", "project-review"]` for a bounded
wait. Include the literal name and option separator in each allowed
command. Match and verify each rule before dispatch.
[Codex rules][codex-rules]

```zsh
rules_dir="${CODEX_HOME:-$HOME/.codex}/rules"
codex execpolicy check --rules "$rules_dir/herdr-team.rules" -- \
  hc send -- project-lead 'READY'
```

The policy check evaluates the command without sending a message. Verify
the actual READY and report path with the prepared role in Herdr.

To let a role compact a teammate's pane, add a rule for the installed
`herdr-context` helper and the literal authorized target. Verify that
`herdr-context` and `hc` resolve to your trusted installations.

```starlark
prefix_rule(
    pattern = ["herdr-context", "compact", "project-review"],
    decision = "allow",
)
```

### Optional Atlassian and Android servers

Add the server table you need to a personal profile. Both use `uvx`. For
Atlassian, export your deployment's base URLs, including the context path
if applicable. Keep just the URL and token pair for each product you use.
This example enables read-only tools.

```toml
[mcp_servers.mcp-atlassian]
command = "uvx"
args = ["mcp-atlassian"]
env_vars = [
  "JIRA_URL",
  "JIRA_PERSONAL_TOKEN",
  "CONFLUENCE_URL",
  "CONFLUENCE_PERSONAL_TOKEN",
]

[mcp_servers.mcp-atlassian.env]
READ_ONLY_MODE = "true"
```

For Android, install Android SDK Platform-Tools and put `adb` on the pane's
`PATH`. Check `adb devices` and connect only the device or emulator intended
for the task. The server defaults to the first available device.

```toml
[mcp_servers.android]
command = "uvx"
args = ["android-mcp"]
```

## MCP credentials

Run the relevant commands one at a time in the Herdr terminal where you will
launch Codex. Enter each credential at its prompt. Your input stays hidden.
Skip commands for variables that are already exported. When switching to a new
terminal, check that it has the variables you need.

```zsh
read -rs 'GITLAB_PERSONAL_ACCESS_TOKEN?GitLab token: ' &&
  export GITLAB_PERSONAL_ACCESS_TOKEN
read -r 'JIRA_URL?Jira base URL: ' && export JIRA_URL
read -rs 'JIRA_PERSONAL_TOKEN?Jira token: ' &&
  export JIRA_PERSONAL_TOKEN
read -r 'CONFLUENCE_URL?Confluence base URL: ' && export CONFLUENCE_URL
read -rs 'CONFLUENCE_PERSONAL_TOKEN?Confluence token: ' &&
  export CONFLUENCE_PERSONAL_TOKEN
read -rs 'CONTEXT7_API_KEY?Context7 API key: ' &&
  export CONTEXT7_API_KEY
```

## Optional skills and plugins

To reuse Claude Code's `frontend-design` skill, install the optional plugin
and locate its source under the official marketplace checkout. The command
below uses the default checkout path in the primary Claude profile and
preserves any existing copy. If the path is missing, clone the official
marketplace outside this repository and set `marketplace_dir` to that
checkout before running the copy.
[Marketplace source](https://github.com/anthropics/claude-plugins-official)

```zsh
(
  set -e
  codex_skills_dir="${CODEX_HOME:-$HOME/.codex}/skills"
  marketplace_dir="${marketplace_dir:-$HOME/.claude/plugins/marketplaces/claude-plugins-official}"
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

## Status line

Use `/statusline` in Codex to choose the built-in footer items. Codex also
offers an MCP-provided custom status line as an experimental feature that is
off by default. This setup does not need it. Turn it on under `/experimental`
only if you want to try it.

## Verification and launch

For basic setup, check and launch in the same Herdr pane:

```zsh
scripts/check-env.zsh codex
codex mcp list
codex --no-daemon
```

For a named profile, use the same name for each step. This example uses the
work profile:

```zsh
scripts/check-env.zsh codex --profile work
codex --profile work mcp list
codex --no-daemon --profile work
```

Use `/mcp` in the session and call one read-only tool from each server you
need to confirm its connection. The offline check covers the base and
selected user profile. Use Codex's listing and the in-session check for any
additional settings applied by a trusted project.

[npm-permissions]: https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally/
[codex-rules]: https://learn.chatgpt.com/docs/agent-configuration/rules
