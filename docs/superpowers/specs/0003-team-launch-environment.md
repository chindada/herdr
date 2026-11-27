# Team launch environment for Herdr teams

Herdr teams should start each Claude member with the language servers, MCP
server commands, and credential variables its profile needs. The same
launch preflight applies to Codex members. A terminal
started with `hc run` gets the Herdr Core's program environment, which can
differ from the person's login shell. Before launch, the lead verifies the
environment on the exact route the member will use.

## Evidence

The lead observed the following on the local Core:

- The direct Core route and both running `claude-k` processes could not
  resolve `pyright-langserver`, `typescript-language-server`, or `gopls`.
  Three MCP credential variables were absent.
- Pyright was already installed. Adding its directory to a temporary Core
  environment let it pass initialize and hover.
- On the same Core, a `/bin/zsh -lic` route resolved all three servers and
  found the credential variables present. Zsh was 5.9.
- Both profiles reported six MCP servers connected on either route.
- Authenticated GitHub and GitLab reads and a read-only Context7 call worked
  through the login route. A connected status alone does not prove that a
  server can be used with authentication.

For Codex, the lead observed:

- The effective default profile enables Context7 and Dart. The `work`
  profile adds GitLab. The `review` profile disables Context7 and keeps
  Dart.
- On the direct Core route:
  - Context7 initialized with no key, and the example public lookup
    succeeded;
  - Dart listed 14 tools;
  - `work` GitLab could not initialize without
    `GITLAB_PERSONAL_ACCESS_TOKEN`.
- On the login route, with the key and token set, Context7 calls and
  authenticated read-only GitLab calls succeeded. Dart tool discovery also
  passed.

## Scope

Change `HERDR.md` (Launch rules, Add a member, Starter prompt, and an
optional short reusable Claude preflight) and `claude/README.md` (the
sign-in and preflight explanation). The changes are confined to
documentation. Also change `codex/README.md` (the Codex preflight explanation
and profile examples). Use one shared route rule with profile-specific
examples and cross-references.

This change is incremental to the earlier reviewed working-tree snapshot
`3aa9588310982a3e66d570c64563d47182a4548dae48696b4c3a56504ee1f9ea`
(0002 final-r2). Its Git base is still
`71c4f8444f7b45d4dab1d0993f29114d1be8c2fe`.
- Compare the edits to the three guide files against that snapshot.
- Preserve the snapshot's `AGENTS.md`, spec 0002, and other prior changes.
- The deliverables are those three guide edits and this numbered spec.
- The local plan stays ignored and untracked.

Make no changes to repository scripts, configuration or settings files, or
global installs, and restart no live team sessions. Keep the Codex Dart
check, readiness and trust handling, existing sessions, and authorization
behavior. Keep these in the authorized child argv:
- for Codex, `--no-daemon` on every launch, `--yolo` only in the
  user-authorized team launch mode, and any `--profile`;
- the Claude status-line opt-in and only user-authorized permission flags.

Keep the earlier review and delegation changes intact. The installed `hc`
manual is authoritative for command arguments.

## Approaches

- **Verified per-launch route.** Check each launch route and use the one that
  passes. It matches what the member actually receives, works per machine and
  profile, and leaves no global state. It costs one preflight per route. Use
  this approach.
- **System-wide or default hardcoding.** Add directories to the Core
  environment or a global profile, or hard-code `PATH` in the guide. This
  removes the per-launch step. But it bakes in machine-specific paths, changes
  every terminal, drifts with updates, and is still unverified on remote
  machines. Global installs and configuration are out of scope.
- **Login shell for every launch.** This is simple, but it depends on
  interactive profile side effects and is unverified for a given route. Show
  `zsh -lic` only as an optional example that has been verified.

## Requirements

1. **Identify the effective route.** For each requested Claude profile, the
   lead records the launch route:
   - machine (`--on`), and cwd;
   - Claude executable;
   - `CLAUDE_CONFIG_DIR` and any settings file;
   - wrapper, and nonsecret overrides.
2. **Run the preflight on that route.** Use `hc exec` with the same machine,
   cwd, wrapper, and overrides as the planned `hc run`. Check:
   - the executables of the enabled or task-relevant LSP plugins listed in
     `claude/README.md`;
   - the commands the profile's MCP servers start;
   - the presence of each required credential variable.

   Report variable names with `set` or `unset` only, never their values.

   A standalone `hc exec` has no PTY, and startup files can branch on the
   tty or `TERM`, so its result is an initial diagnostic. Check the
   effective terminal environment on the intended route when choosing a
   login wrapper or when results depend on terminal startup. One suitable
   method is a short non-agent `hc run` PTY probe on the same machine, cwd,
   wrapper, and selected profile. Another is an equivalent check in the same
   actual terminal environment before executing Claude.
3. **Recover on the same route.** If the direct Core route lacks expected
   items:
   - Choose a verified login shell or an explicit child `PATH` with
     nonsecret overrides.
   - Repeat the same preflight on the same machine, cwd, and profile.
   - Launch with the route that passes.

   After launch, verify `foreground.argv` and `foreground.cwd`. Do not claim
   readiness for a required environment-dependent function until the actual
   route check passes.
4. **Forward argv literally.** The real executable, the profile, the
   status-line opt-in, the authorized flags, and the onboarding prompt are
   passed as arguments after a sentinel.
   - The shell code is a fixed literal such as `exec "$@"`.
   - Never interpolate the prompt, tokens, or paths into shell code.
   - With `zsh -c`, the argument after the command string becomes `$0`
     (the sentinel), and the remaining arguments become positional
     parameters. `exec` replaces the wrapper with the agent.

   [zsh invocation](https://zsh.sourceforge.io/Doc/Release/Invocation.html)
   [zsh shell grammar](https://zsh.sourceforge.io/Doc/Release/Shell-Grammar.html)
5. **Match remote routes.** Use the same `--on <machine>` for the preflight
   and the launch. Use executable, profile, and checkout paths verified on
   that machine, and keep the returned full address. Do not rely on
   caller-side `$HOME` expansion for remote paths.
6. **Handle missing credentials and optional gaps.**
   - If a required credential is still unset on the passing route, use the
     existing prepared-shell flow, where a person enters it, and report the
     capability as blocked.
   - After the person enters credentials, recheck names and presence only
     from a child of that same live shell, with the selected cwd and profile
     or overrides, before the authorized launch there. Each variable must be
     exported and nonempty. A fresh `hc exec` cannot see pane-local exports.
   - Report an optional gap, such as an LSP server or MCP server the task
     does not need, without blocking unrelated work.
7. **Report two results separately.**
   - The launch preflight: route, resolved executables, and variable
     presence.
   - MCP handshake and authentication: connected status, plus one
     read-only call when the task depends on that server.
   - Require an authenticated read-only call only when the task needs an
     authenticated capability. Report a passing public lookup made without
     credentials as public access, not as authentication.
8. **Apply the same preflight to Codex.** For each requested Codex member,
   apply requirements 1 to 7 on the same Core route.
   - **Route:** record the Codex executable, `CODEX_HOME` when set, the
     effective default or named `--profile`, and the authorized launch
     flags.
   - **Check:**
     - the executables of the profile's enabled MCP stdio servers;
     - nonempty exported credential variables, only where an enabled server
       requires them;
     - the existing Dart/Flutter subprocess check when the profile uses
       Dart.
   - **Same rules:** use the real PTY environment where relevant, and the
     same fallback, recheck, and prepared-shell rules.
   - **Do not require** inputs for disabled or optional tools.
   - **Inventory versus health:** `codex mcp list` shows configuration
     inventory only. Health needs tool discovery or a read-only call.
     Authentication needs an authenticated read-only call only when the task
     needs an authenticated capability. A public Context7 lookup can pass
     without `CONTEXT7_API_KEY`.

## Example

An optional verified login-shell launch of a Claude member:

```zsh
hc run --bg --cwd "$project_dir" --parent "$lead" \
  --label "herdr.space=$space_id" -- \
  /bin/zsh -lic 'exec "$@"' herdr-member \
  env HERDR_STATUSLINE_LABELS=1 CLAUDE_CONFIG_DIR="$claude_config_dir" \
  "$claude_bin" --dangerously-skip-permissions -- "$onboarding_prompt"
```

The same wrapper for a Codex member with a named profile:

```zsh
hc run --bg --cwd "$project_dir" --parent "$lead" \
  --label "herdr.space=$space_id" -- \
  /bin/zsh -lic 'exec "$@"' herdr-member \
  "$codex_bin" --yolo --no-daemon --profile work -- "$onboarding_prompt"
```

## Acceptance

- **Raw-Core failure and same-route recovery.** When the direct Core route
  lacks an expected LSP executable, the preflight reports it as missing.
  After a verified login shell or explicit child `PATH` is chosen, the same
  preflight on the same machine, cwd, and profile passes. The member is
  launched on that route, and `hc get` shows the expected `foreground.argv`
  and `foreground.cwd`.
- **Terminal-dependent environment.** When a path or credential differs
  between the non-PTY `hc exec` probe and the intended PTY route, the route
  check detects it before the member is accepted for affected work.
- **Prepared-shell recheck.** A child of the prepared shell reports an unset,
  empty, or unexported variable as blocked. It reports a nonempty exported
  variable as present before the launch there.
- **Literal forwarding.** An onboarding prompt containing quotes, `$`,
  backticks, `;`, and newlines reaches Claude or Codex as one unchanged
  argument. The
  shell code string contains no prompt, token, or path text.
- **Remote routes.** The preflight and launch name the same `--on` machine
  and use paths verified on that machine.
- **Readiness and optional gaps.** These stay unchanged:
  - trust and bypass dialogs, and screen reads when status is null;
  - existing sessions and authorization;
  - the Codex Dart check.

  A missing optional item is reported without blocking unrelated work. A
  missing required credential goes through the prepared-shell flow and is
  reported as a blocked capability.
- **Codex `work` profile without a token.** On the chosen route, an unset,
  empty, or unexported `GITLAB_PERSONAL_ACCESS_TOKEN` blocks only the GitLab
  capability. The default and `review` profiles do not require it. With the
  token exported and nonempty, an authenticated read-only GitLab call passes
  before GitLab work is accepted.
- **Public Context7 lookup.** With `CONTEXT7_API_KEY` unset on the default
  profile, a passing public Context7 lookup is reported as public access, not
  as authentication. Work that needs only public lookups proceeds.
- **Codex disabled optional Context7.**
  - With the `review` profile, which disables Context7, the preflight
    requires neither `CONTEXT7_API_KEY` nor a Context7 check.
  - A `codex mcp list` entry is not reported as health or authentication.
- **Reporting and scope.**
  - Preflight and MCP authentication results are reported separately.
  - No credential value appears in arguments, `hc send` text, labels,
    files, or reports.
  - Against the 0002 final-r2 snapshot, only `HERDR.md`, `claude/README.md`,
    `codex/README.md`, and this spec change.
  - `AGENTS.md` and spec 0002 match the snapshot, and the plan stays ignored
    and untracked.
  - `git diff --check` passes, and local Markdown links and anchors resolve.
