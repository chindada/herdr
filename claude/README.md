# Set up the Claude Code development environment

Complete the [shared prerequisites](../README.md#prerequisites), then run these
commands from the repository root in a Herdr terminal.

`claude` is the primary profile. Run the `claude-k` commands if you need a
second, independent profile.

| Command | Configuration directory |
| --- | --- |
| `claude` | `~/.claude` |
| `claude-k` | `~/.claude-k` |

## 1. Prerequisites

Install Claude Code and GitHub MCP.

```sh
curl -fsSL https://claude.ai/install.sh | bash
```

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
| `pyright` | `pyright-lsp` plugin |
| `typescript-language-server` | `typescript-lsp` plugin |
| `gopls` | `gopls-lsp` plugin |
| `jq` | The status line in `settings.json` |

If `jq` is missing from the Herdr terminal, run `brew install jq` before
using the template's status line.

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

Review the permissions, model, and plugins in the
[settings template](settings.json). If `settings.json` exists, back it up and
merge the settings you need. The block below creates missing files. Remove the
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

```sh
claude mcp add --scope user github \
  -e 'GITHUB_PERSONAL_ACCESS_TOKEN=${GITHUB_PERSONAL_ACCESS_TOKEN}' \
  -- github-mcp-server stdio
claude-k mcp add --scope user github \
  -e 'GITHUB_PERSONAL_ACCESS_TOKEN=${GITHUB_PERSONAL_ACCESS_TOKEN}' \
  -- github-mcp-server stdio
```

```sh
claude mcp add --scope user gitlab -- npx -y @zereight/mcp-gitlab \
  '--token=${GITLAB_PERSONAL_ACCESS_TOKEN}' --api-url=https://gitlab.com/api/v4
claude-k mcp add --scope user gitlab -- npx -y @zereight/mcp-gitlab \
  '--token=${GITLAB_PERSONAL_ACCESS_TOKEN}' --api-url=https://gitlab.com/api/v4
```

```sh
claude mcp add --scope user ios-simulator npx ios-simulator-mcp
claude-k mcp add --scope user ios-simulator npx ios-simulator-mcp
```

## 6. Optional plugins

Install the plugins you need for the profile you use. Keep `flutter` and
`dart` on `PATH` if you use the Flutter plugin.

```sh
claude plugin marketplace add \
  https://github.com/anthropics/claude-plugins-official
claude plugin marketplace add flutter/agent-plugins
claude plugin marketplace add typesafe-ai/skills
claude-k plugin marketplace add \
  https://github.com/anthropics/claude-plugins-official
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

Launch the profile from the Herdr terminal where you exported its credentials.
Use `/login` on first launch and `/mcp` to check the connections. You can also
list the installed MCP servers and plugins from the same terminal.

```sh
claude mcp list
claude plugin list
claude-k mcp list
claude-k plugin list
```

[context7-token]: https://context7.com/dashboard
[github-token]: https://github.com/settings/tokens
[gitlab-token]: https://gitlab.com/-/user_settings/personal_access_tokens
[mcp-variables]: https://code.claude.com/docs/en/mcp#environment-variable-expansion-in-mcp-json
