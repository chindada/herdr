# Set up the Codex development environment

Complete the [shared prerequisites](../README.md#prerequisites). Run setup
commands that read local templates from the Herdr source checkout. Run
[verification and launch](#verification-and-launch) in the target pane.

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

Install the [shared helper](../HERDR.md#context-checkpoints). In
`${CODEX_HOME:-$HOME/.codex}`, choose one hook representation. Use
[hooks.json](hooks.json), merging the two groups if the file already
exists, or add the same groups in `config.toml` if you manage hooks there.
Use the snippet below only if you chose `hooks.json` and need to create it.

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

Use `/hooks` in Codex to review and trust both definitions before using
them, and again after replacing an earlier version. If the session started
while `SessionStart` was untrusted, start a fresh Codex session after
trusting the hooks. Then run `herdr-context record` before compacting.

Keep the template's `save` command as written. It passes `codex` to select
the Codex block format, and it stops compaction when the helper is missing
or fails in a Herdr pane.

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

Either team role can use Codex. For a new member in the user-authorized
[team launch mode](../HERDR.md#add-a-member), use `codex --yolo --no-daemon`.
Keep `--profile <name>` when that member needs the selected profile's
configuration. `--yolo` selects a launch without Codex sandboxing or approval
prompts. The workspace-write and on-request settings below describe the
approval-based mode.

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

For approval-based reviews, launch from the task checkout with
`codex --no-daemon --profile review`.
Apply repairs during the turn assigned by the lead and leave the frozen
candidate intact. Use read-only tooling and scoped credentials for remote
MCP servers added to this profile.
[Herdr review and repair](../HERDR.md#review-and-repair)

### Herdr team communication

Codex's filesystem sandboxes can deny the Herdr Core socket. During team
setup, verify `hc` resolves to your trusted Herdr command. When a sandboxed
role needs to call it, add narrowly scoped rules to
`${CODEX_HOME:-$HOME/.codex}/rules/herdr-team.rules`. These rules allow
matching commands to run outside the sandbox, so list only the team names
and commands needed by the role. Rules in a Codex home apply to sessions
using that home and load at startup. Match a verified literal terminal
address or launch alias. For a new member that needs a rule in advance,
choose an alias before starting Codex and pass it to `hc run --name` as
described in [Herdr setup](../HERDR.md#prepare-team-communication).

This example lets `project-review` look up itself and `project-lead`, then
report to `project-lead`. Use the team's verified literal selectors. Match
both returned addresses to the roster before sending.

```starlark
prefix_rule(pattern = ["hc", "get", "--", "project-review"], decision = "allow")
prefix_rule(pattern = ["hc", "get", "--", "project-lead"], decision = "allow")
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
policy_home=$(mktemp -d) &&
  env CODEX_HOME="$policy_home" codex execpolicy check \
    --rules "$rules_dir/herdr-team.rules" -- hc send -- project-lead 'READY'
```

The check reads the selected rules and uses scratch for startup files. Check
both `hc get` selectors and the separate `hc send` selector this way. Each
should match its own rule, and an unrelated terminal should have no match.
Verify the READY return path with the prepared role in Herdr.

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

In the Herdr pane for the target checkout, set `herdr_source` to the verified
absolute source checkout path. Check and launch with the same profile and
environment. The offline check runs separately from `codex mcp list`, which
can contact configured HTTP MCP servers and send configured headers.
[Herdr launch rules](../HERDR.md#launch-rules)

Use the base profile by default.

```zsh
"$herdr_source/scripts/check-env.zsh" codex
codex mcp list
codex --no-daemon
```

Use the same name for each named-profile command. This example uses `work`.

```zsh
"$herdr_source/scripts/check-env.zsh" codex --profile work
codex --profile work mcp list
codex --no-daemon --profile work
```

Use `/mcp` in the session and call one read-only tool from each server you
need to confirm its connection. The offline check covers the base and
selected user profile. Use Codex's listing and the in-session check for any
additional settings applied by a trusted project.

[npm-permissions]: https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally/
[codex-rules]: https://learn.chatgpt.com/docs/agent-configuration/rules
