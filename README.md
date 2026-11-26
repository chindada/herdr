# Herdr development environment

This repository provides guides and configuration templates for running
agent teams in Herdr on macOS. One lead coordinates Codex CLI and Claude Code
teammates in the same space to carry a user's request through delivery.

## Quick start

- [Lead a team in Herdr](HERDR.md#starter-prompt) with the copyable starter prompt.
- [Set up Codex](codex/README.md) for the base setup or an optional work profile.
- [Set up Claude Code](claude/README.md) for `claude` or `claude-k`.

1. Clone this repository, or use your existing checkout. If Git is missing,
   install the [macOS Command Line Tools](#command-line-tools) first.

   ```zsh
   git clone https://github.com/chindada/herdr.git
   cd herdr
   ```

2. Install any missing [shared prerequisites](#prerequisites). Open a zsh
   pane in Herdr and change to the repository root.
3. Follow the setup guide for one or both tools to install, configure, and
   sign in. Export the MCP credentials you need in the pane that will run the
   tool. Each terminal started by `hc run` has its own environment.
   Install the [context checkpoint helper](HERDR.md#context-checkpoints)
   and enable its hooks for each CLI on the team.
4. Run the [environment check](#environment-check), then
   [launch from the same pane](HERDR.md#quick-start) and verify your MCP
   connections.
5. Paste the starter prompt into the lead's pane with your task. Include
   the roster if it is new or changing. The lead coordinates the
   [review and repair cycle](HERDR.md#review-and-repair) and brings you
   the decisions that need your input.

## Prerequisites

### Command Line Tools

If `xcode-select -p` cannot find the developer tools, install them and wait for
the macOS installer to finish.

```zsh
xcode-select -p >/dev/null 2>&1 || xcode-select --install
```

### Homebrew

If Homebrew is missing, run its installer in macOS Terminal.
[Homebrew installation guide][brew-install]

```zsh
/bin/bash -c "$(curl -fsSL \
  https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow the installer's next steps to put `brew` on your `PATH`. If a new Herdr
zsh terminal cannot find Homebrew, add the matching `brew shellenv` command to
`~/.zshrc` and run it in the current shell.

```zsh
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
```

### Git, Node.js, and uv

Install any missing tools. Node.js includes `npm` and `npx`. The environment
checker requires `uv` for every profile, and Codex uses `uvx` for Python MCP
servers.

```zsh
brew install git node uv
```

If global npm installs report a permissions error, set a user-owned prefix.
[npm permissions guide][npm-permissions]

```zsh
npm config set prefix "$HOME/.npm-global"
```

Add the npm binary directory and `~/.local/bin` to `~/.zshrc`. Run the same
command in the current shell to make the tools available immediately.

```zsh
export PATH="$(npm prefix -g)/bin:$HOME/.local/bin:$PATH"
```

### Herdr

On Apple Silicon, use the Herdr installer. On Intel Macs, follow the source
build instructions. [Herdr installation guide][herdr-install]

```zsh
curl -fsSL https://releases.herdr.dev/app/install.sh | sh
```

Open Herdr and start a zsh terminal. Confirm the tools are on its `PATH` and
`hc ls` lists your terminals. Change to the repository root before running
either guide.

```zsh
command -v brew git node npm npx uv hc
hc ls
```

## Environment check

From the Herdr pane where you will launch the tool, run the command for
your configuration. Use the second Codex example if you installed the work
profile.

```zsh
scripts/check-env.zsh codex
scripts/check-env.zsh codex --profile work
scripts/check-env.zsh claude
scripts/check-env.zsh claude-k
```

After the check passes, launch the tool in that pane and use `/mcp` to check
its connections. Call one read-only tool from each MCP server you plan to
use to verify its credentials and permissions.

The check runs offline and reads configuration without modifying it. It checks
required commands, reports installed versions, and checks configuration paths.
In a Herdr pane, it also requires the executable context checkpoint helper at
`~/.local/bin/herdr-context`. Confirm the checkpoint hooks in each CLI with
`/hooks`.
It uses `CODEX_HOME` or the default path for Codex and `~/.claude` or
`~/.claude-k` for the selected Claude Code profile. Pass the same
`--profile NAME` you will use with Codex to check the combined base and
named user files. Full Codex configuration, including trusted project
settings, is checked separately by the tool's own commands.

The Codex check first uses `uv` to find an installed Python with `tomllib`, then
tries `python3` on `PATH` if needed. The `uv` probe runs offline with downloads
disabled and uses temporary storage instead of the persistent cache. The
Claude Code check uses `jq` when available.

When the parser is available, the script checks configuration syntax, basic MCP
fields, and the local environment variables they reference. It reports only
credential names and their status. Set `enabled = false` in the configuration for
any Codex MCP server you do not use.

Exit code `0` means the basic checks passed, `1` means a required item is missing
or invalid, and `2` means the command was used incorrectly. The script reports
optional items and skipped checks as notes.

[brew-install]: https://docs.brew.sh/Installation
[herdr-install]: https://github.com/herdrdev/herdr-app#install
[npm-permissions]: https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally/
