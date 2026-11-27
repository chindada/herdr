# Set up the Claude Code development environment

Complete the [shared prerequisites](../README.md#prerequisites). Run setup
commands that read local templates from the Herdr source checkout. Run the
[launch checks](#7-sign-in-and-verify) in the target pane.

`claude` is the primary profile. Run the `claude-k` commands if you need a
second, independent profile.

| Command | Configuration directory |
| --- | --- |
| `claude` | `~/.claude` |
| `claude-k` | `~/.claude-k` |

## 1. Prerequisites

Install Claude Code.

```sh
curl -fsSL https://claude.ai/install.sh | bash
```

Install GitHub MCP if the profile needs it.

```sh
brew install github-mcp-server
```

Install the language servers for the LSP plugins you plan to use. For `gopls`,
install Go with `brew install go` if needed. Add the directory from
`go env GOBIN` to the Herdr terminal's `PATH`. With the default Go workspace
and an unset `GOBIN`, use `~/go/bin`.

```sh
npm install --global pyright
npm install --global typescript-language-server typescript
go install golang.org/x/tools/gopls@latest
```

| Tool | Used by |
| --- | --- |
| `~/.local/bin/claude` | Claude Code native installation |
| `github-mcp-server` | GitHub MCP |
| `npx` | GitLab and iOS Simulator MCP |
| `pyright-langserver` | `pyright-lsp` plugin |
| `typescript-language-server` | `typescript-lsp` plugin |
| `gopls` | `gopls-lsp` plugin |
| `jq` | The status line script |

If `jq` is missing from the Herdr terminal, run `brew install jq` before
using the status line.

## 2. Profile aliases

Add the aliases you need to `~/.zshrc`. Open a new Herdr zsh terminal and run
`type claude` or `type claude-k` to check the alias. Use the same profile to
register MCP servers, sign in, and verify the setup.

```zsh
alias claude="CLAUDE_CONFIG_DIR=~/.claude ~/.local/bin/claude"
alias claude-k="CLAUDE_CONFIG_DIR=~/.claude-k ~/.local/bin/claude"
```

If the alias has not loaded, specify the configuration directory and binary
directly. Append the corresponding `mcp` subcommand to register a server.

```zsh
CLAUDE_CONFIG_DIR="$HOME/.claude" "$HOME/.local/bin/claude"
```

## 3. Configuration

Install the [shared checkpoint helper](../HERDR.md#context-checkpoints).
The [settings template](settings.json) configures the Herdr footer, saves
and restores checkpoints during compaction, and starts with Remote Control
off. It turns off auto-compact so team agents can choose when to use
`/compact`. The block below creates missing settings files. Remove the
second directory from the loop if you only use the primary profile.

```sh
(
  set -e
  for claude_config_dir in "$HOME/.claude" "$HOME/.claude-k"; do
    mkdir -p "$claude_config_dir"
    if [ ! -e "$claude_config_dir/settings.json" ]; then
      (
        umask 077
        set -C
        cat < claude/settings.json > "$claude_config_dir/settings.json"
      )
    fi
  done
)
```

### Update an existing profile

Back up each profile's `settings.json` and merge the template. Replace
`PreCompact`, `SessionStart`, and `statusLine` entries copied from an
earlier template with the current ones, and set `autoCompactEnabled` to
`false`. The `SessionStart` command calls the helper for every session source
in a Herdr pane. Claude Code 2.1.295 or later supports `onFailure: "block"`
on the `PreCompact` handler, which stops compaction when the helper fails or
is missing. Confirm the two checkpoint hooks are loaded with `/hooks`.
[Claude Code hooks](https://code.claude.com/docs/en/hooks)

To adopt the new defaults, review the entries copied from the old template:

- Remove the broad file, web, skill, and MCP allow rules. In particular,
  remove the GitHub wildcard before setting up a reviewer. Use
  `/permissions` to grant an individual tool from a trusted server when
  that pane needs it.
- Move `defaultMode`, the Git commit and push rules, and model and UI
  preferences to the appropriate user or role. Drop the empty `ask` list
  and the old `skipDangerousModePermissionPrompt`,
  `skipWorkflowUsageWarning`, and `skipAutoPermissionPrompt` entries.
  Let Claude record each user's responses.
- Keep enabled plugins and marketplace entries only where used. Use
  `/plugin` in each existing profile to disable installed plugins you no
  longer need.

### Roles and preferences

Either team role can use Claude Code. For a new member in the user-authorized
[team launch mode](../HERDR.md#add-a-member), use
`claude --dangerously-skip-permissions` with the selected configuration
directory. The roster and per-turn assignment govern the member's work,
including Git actions. The first launch in each configuration directory
can show a native dialog to acknowledge this mode. Answer it once in the
member's pane. The lead waits and continues onboarding after you clear it.

For approval-based launches, an interactive coder or reviewer can opt into
Auto mode when the account supports it. Reviewers inspect the frozen
candidate in read-only turns and report findings to the lead. An authorized
repair uses a separate editor assignment with checkout write access.
[Herdr review and repair](../HERDR.md#review-and-repair)

Use either Claude alias and adjust the settings file path for the profile.

```zsh
claude --permission-mode auto --model fable
claude --permission-mode auto --settings "$HOME/.claude/herdr-reviewer.json"
```

Use `/config` for appearance, suggestions, and model fallback preferences.
Use `/effort` to save an effort level for the active
model or `--effort` for one launch. Recent models use model-specific saved
effort in user settings.

For the approval-based workflow, use these Git rules in the role settings
file passed with `--settings`.
For a coder, save the example as `~/.claude/herdr-worker.json`. For a
reviewer, save it as `~/.claude/herdr-reviewer.json`.

```json
{
  "permissions": {
    "deny": ["Bash(codegpt commit *)", "Bash(git commit *)", "Bash(git push *)"]
  }
}
```

```zsh
claude --permission-mode auto --settings "$HOME/.claude/herdr-worker.json"
```

Keep any existing `Edit`, `Write`, and `NotebookEdit` denies in reviewer
settings. Keep the Git denies and team communication rules when merging
the file. Use read-only MCP registrations and scoped credentials for remote
review operations.

### Herdr team communication

For a role that reports through `hc` in an approval-based session, set up
the commands it needs in its role settings file before launching it.
Manual mode may otherwise ask for approval on each shell call. Merge these
entries into the file's `permissions` object. Use verified literal addresses
or the launch aliases chosen for `hc run --name` during
[Herdr setup](../HERDR.md#prepare-team-communication). Start the chosen
Claude alias with `--settings` pointing to that file.

This example lets `project-review` look up itself and `project-lead`, then
report to `project-lead`. Match both returned addresses to the roster before
sending.

```json
{
  "permissions": {
    "allow": [
      "Bash(hc get -- project-review)",
      "Bash(hc get -- project-lead)",
      "Bash(hc send -- project-lead *)"
    ]
  }
}
```

For a lead, include a `get` entry for its own name and separate
entries for each member and command needed, such as
`Bash(hc read --lines 0 -- project-review)`,
`Bash(hc wait --timeout 45 -- project-review)`, or
`Bash(hc send -- project-review *)`. Use the listed command form including
the option separator before the literal name. Verify the return path during
[team onboarding](../HERDR.md#prepare-team-communication).
If the reviewer settings require it, agree during onboarding to print READY
and the review report in the reviewer's pane.

When a role can compact a teammate's pane, add the exact allow entry
`Bash(herdr-context compact project-review)` with the authorized name.
Verify that `herdr-context` and `hc` resolve to your trusted installations.

### Status line

Both profiles run one installed copy of the
[status line script](statusline.sh). Install it, or update it after pulling
this repository, with:

```sh
mkdir -p "$HOME/.claude" &&
  install -m 755 claude/statusline.sh "$HOME/.claude/herdr-statusline.sh"
```

The footer shows the project directory, Git branch, model, and context use.
It adds the 5-hour quota left and the effort level when Claude Code reports
them. In an existing `settings.json`, replace only the `statusLine` value:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/herdr-statusline.sh"
  }
}
```

To opt in to labels for Pixel HQ, export `HERDR_STATUSLINE_LABELS=1` in the
child shell that will launch Claude Code. For `hc run`, you can prefix the
authorized Claude executable with `env HERDR_STATUSLINE_LABELS=1` after `--`.
The Core uses its own environment and explicit child overrides. Set the
option in the child even if it is already exported in the lead shell.
[Herdr Core launch source](https://github.com/herdrdev/herdr-core/blob/master/crates/herdr-core/src/api/run.rs)

The default is the terminal footer. Opt-in adds the `agent.model`,
`agent.context`, `agent.quota`, and `agent.effort` labels through `hc label`.
Pixel HQ prefers `claude.*` labels when present and falls back to `agent.*`.
The quota requires Claude Code's five-hour usage field.

If the terminal already ran Pixel HQ's own status line, its stale `claude.*`
labels stay on that terminal and hide the `agent.*` labels. Start a fresh pane
for the opted-in launch.

### Project MCP servers

The template leaves `enableAllProjectMcpServers` unset, so Claude Code asks
before it starts the servers in a project's `.mcp.json`. Approve them in that
dialog for each project you trust. If an existing `settings.json` sets
`enableAllProjectMcpServers` to `true`, remove the key. At user level it also
starts servers from folders you have not trusted yet.

### Agent teams

Herdr coordinates agents across terminals, so the template leaves Claude
Code agent teams off. If an existing `settings.json` sets
`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` in its `env` block, remove it to
return to the default. To try agent teams in one session, set the variable
for that launch only:

```zsh
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 claude
```

## 4. MCP credentials

Run the commands you need one at a time in the Herdr zsh terminal where you
will launch Claude Code. Enter each credential at its prompt. Your input
stays hidden. Skip variables that are already exported. When switching to a
new terminal, check that it has the variables you need.

| Variable | MCP server | Token source |
| --- | --- | --- |
| `CONTEXT7_API_KEY` | Context7 | [Context7 dashboard][context7-token] |
| `GITHUB_PERSONAL_ACCESS_TOKEN` | GitHub | [GitHub][github-token] |
| `GITLAB_PERSONAL_ACCESS_TOKEN` | GitLab | [GitLab][gitlab-token] |

```zsh
read -rs 'CONTEXT7_API_KEY?Context7 API key: ' && export CONTEXT7_API_KEY
read -rs 'GITHUB_PERSONAL_ACCESS_TOKEN?GitHub token: ' &&
  export GITHUB_PERSONAL_ACCESS_TOKEN
read -rs 'GITLAB_PERSONAL_ACCESS_TOKEN?GitLab token: ' &&
  export GITLAB_PERSONAL_ACCESS_TOKEN
```

## 5. MCP servers

Keep the single quotes in these commands. Claude Code resolves the variables
from its launch environment when it connects.
[Claude Code MCP environment variables][mcp-variables]

To update an existing server, first export its credentials in the terminal
you will use. Run `mcp remove --scope user <name>` with `claude` or `claude-k`,
then register the server again. For new servers, run the corresponding
registration command directly.

```sh
claude mcp add --scope user --transport http context7 \
  https://mcp.context7.com/mcp \
  --header 'CONTEXT7_API_KEY: ${CONTEXT7_API_KEY}'
claude-k mcp add --scope user --transport http context7 \
  https://mcp.context7.com/mcp \
  --header 'CONTEXT7_API_KEY: ${CONTEXT7_API_KEY}'
```

For GitHub review, register GitHub MCP in read-only mode in the profile
that needs it. Use a token scoped to the repositories under review.
In the review session, check `/mcp` for the effective server. A project or
local registration with the same name can take precedence over this
user-level registration.

```sh
claude mcp add --scope user github \
  -e 'GITHUB_PERSONAL_ACCESS_TOKEN=${GITHUB_PERSONAL_ACCESS_TOKEN}' \
  -- github-mcp-server stdio --read-only
claude-k mcp add --scope user github \
  -e 'GITHUB_PERSONAL_ACCESS_TOKEN=${GITHUB_PERSONAL_ACCESS_TOKEN}' \
  -- github-mcp-server stdio --read-only
```

Register GitLab only in a profile that needs it. The server reads its
token and API URL from its environment. If you registered it earlier
with a `--token` argument, remove it and register it again so the token
stays out of the process arguments. For a review-only registration, add
`-e GITLAB_PERMISSION_MODE=readonly` before the command separator `--`.

```sh
claude mcp add --scope user gitlab \
  -e 'GITLAB_PERSONAL_ACCESS_TOKEN=${GITLAB_PERSONAL_ACCESS_TOKEN}' \
  -e GITLAB_API_URL=https://gitlab.com/api/v4 \
  -- npx -y @zereight/mcp-gitlab
claude-k mcp add --scope user gitlab \
  -e 'GITLAB_PERSONAL_ACCESS_TOKEN=${GITLAB_PERSONAL_ACCESS_TOKEN}' \
  -e GITLAB_API_URL=https://gitlab.com/api/v4 \
  -- npx -y @zereight/mcp-gitlab
```

```sh
claude mcp add --scope user ios-simulator npx ios-simulator-mcp
claude-k mcp add --scope user ios-simulator npx ios-simulator-mcp
```

## 6. Optional plugins

Run only the install commands for the profile and projects that need
them. Enable Superpowers in each participating profile when the team
adopts its workflow. Keep `flutter` and `dart` on `PATH` if you use the
Flutter plugin.

Run `plugin marketplace list` with the chosen alias. Add any missing
marketplace you plan to use before installing its plugins. The official
marketplace registration also creates the local checkout used by the
[Codex skill copy](../codex/README.md#optional-skills-and-plugins).

```sh
claude plugin marketplace add anthropics/claude-plugins-official
claude plugin marketplace add flutter/agent-plugins
claude plugin marketplace add typesafe-ai/skills
claude-k plugin marketplace add anthropics/claude-plugins-official
claude-k plugin marketplace add flutter/agent-plugins
claude-k plugin marketplace add typesafe-ai/skills
```

```sh
claude plugin install superpowers@claude-plugins-official
claude plugin install claude-code-setup@claude-plugins-official
claude plugin install claude-md-management@claude-plugins-official
claude plugin install code-review@claude-plugins-official
claude plugin install frontend-design@claude-plugins-official
claude plugin install gopls-lsp@claude-plugins-official
claude plugin install playwright@claude-plugins-official
claude plugin install pyright-lsp@claude-plugins-official
claude plugin install typescript-lsp@claude-plugins-official
claude plugin install dart-flutter@dart-flutter
claude plugin install typesafe@typesafe-ai
```

```sh
claude-k plugin install superpowers@claude-plugins-official
claude-k plugin install claude-code-setup@claude-plugins-official
claude-k plugin install claude-md-management@claude-plugins-official
claude-k plugin install code-review@claude-plugins-official
claude-k plugin install frontend-design@claude-plugins-official
claude-k plugin install gopls-lsp@claude-plugins-official
claude-k plugin install playwright@claude-plugins-official
claude-k plugin install pyright-lsp@claude-plugins-official
claude-k plugin install typescript-lsp@claude-plugins-official
claude-k plugin install dart-flutter@dart-flutter
claude-k plugin install typesafe@typesafe-ai
```

## 7. Sign in and verify

Follow the [shared Herdr launch preflight](../HERDR.md#launch-preflight)
from the target checkout for the selected `CLAUDE_CONFIG_DIR` and settings
file. Check the enabled or task-relevant LSP and MCP executables in the
[prerequisites table](#1-prerequisites). Include `HERDR_STATUSLINE_LABELS=1`
on the verified route when the user opts into [status-line labels](#status-line).
For credentials entered in a prepared shell, complete the same-shell child
check before launching there.

For offline installation diagnostics, set `herdr_source` to the verified
absolute source checkout path and run the check for the chosen profile.

```sh
"$herdr_source/scripts/check-env.zsh" claude
"$herdr_source/scripts/check-env.zsh" claude-k
```

Launch that profile, use `/login` on first launch, and check the required
connections with `/mcp`. Verify the needed capability with a read-only call
and use an authenticated call when the task requires authentication. You can
list the installed servers and plugins from the same terminal.

```sh
claude mcp list
claude plugin list
claude-k mcp list
claude-k plugin list
```

`claude mcp list` starts every eligible server to check its health. That
includes the approved servers from the current folder's `.mcp.json`, but not
servers that are still pending approval. Run it from a folder whose project
servers you trust.

[context7-token]: https://context7.com/dashboard
[github-token]: https://github.com/settings/tokens
[gitlab-token]: https://gitlab.com/-/user_settings/personal_access_tokens
[mcp-variables]: https://code.claude.com/docs/en/mcp#environment-variable-expansion-in-mcp-json
