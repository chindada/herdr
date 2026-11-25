# Herdr development environment

This repository provides guides and configuration templates for setting up
Codex CLI and Claude Code in Herdr terminals on macOS. Export MCP credentials as
environment variables in the terminal where you launch each tool.

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

## Setup guides

Set up either tool independently. To copy `frontend-design` from Claude Code
to Codex, complete the Claude Code plugin steps first.

- [Claude Code setup guide](claude/README.md)
- [Codex CLI setup guide](codex/README.md)

Launch each tool from the Herdr zsh terminal where you entered its credentials.
`hc run` opens a separate terminal that needs its own credential environment
variables.

## Environment check

After setup, run the check from the Herdr terminal where you plan to launch the
tool. The command below checks Codex. Use `claude` or `claude-k` to check the
corresponding Claude Code profile.

```zsh
scripts/check-env.zsh codex
```

The check runs offline and reads configuration without modifying it. It checks
required commands, reports installed versions, and checks configuration paths.
It uses `CODEX_HOME` or the default path for Codex and `~/.claude` or
`~/.claude-k` for the selected Claude Code profile.

The Codex check first uses `uv` to find an installed Python with `tomllib`, then
tries `python3` on `PATH` if needed. The `uv` probe runs offline with downloads
disabled and uses temporary storage instead of the persistent cache. The
Claude Code check uses `jq` when available.

When the parser is available, the script checks configuration syntax, basic MCP
fields, and the local environment variables they reference. It reports only
credential names and their status. Set `enabled = false` in the configuration for
any Codex MCP server you do not use. Follow the setup guides to verify live
connections.

Exit code `0` means the basic checks passed, `1` means a required item is missing
or invalid, and `2` means the command was used incorrectly. The script reports
optional items and skipped checks as notes.

[brew-install]: https://docs.brew.sh/Installation
[herdr-install]: https://github.com/herdrdev/herdr-app#install
[npm-permissions]: https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally/
