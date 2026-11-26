# Work in Herdr

Set up Herdr panes for a team whose lead takes a user request through
implementation, review, repair, and verification.

The manuals that ship with your Herdr version are the source of truth for
commands. Read both before you run anything here, and use
`hc <command> --help` and `herdr-app commands` for exact arguments.

```zsh
hc --skill
herdr-app --skill
```

## Quick start

Open the Herdr space and focus the pane you will work in. In that pane's zsh,
change to this repository. Export only the credentials the agent needs,
following the [Claude Code guide](claude/README.md#4-mcp-credentials) or the
[Codex guide](codex/README.md#mcp-credentials).

Check the environment for the tool you will launch. Use `codex`, `claude`, or
`claude-k`. The check fails when a required item such as `uv` is missing.

```zsh
scripts/check-env.zsh codex
```

Launch the agent from the same pane. Codex needs `--no-daemon` in Herdr.
Without it, its commands run outside the terminal that `hc` manages.

```zsh
codex --no-daemon
```

For a named Codex profile, use the same profile for the offline check and
launch. Install the [work profile](codex/README.md#gitlab-work-profile) first
if this pane needs GitLab.

```zsh
scripts/check-env.zsh codex --profile work
codex --no-daemon --profile work
```

Launch Claude Code with the configuration directory of the profile you
intend to use. The `claude` and `claude-k` aliases from the Claude Code guide
do the same.

```zsh
CLAUDE_CONFIG_DIR="$HOME/.claude" "$HOME/.local/bin/claude"
```

## Launch rules

A terminal started with `hc run` gets the Herdr core's environment. It does
not get the variables you exported in the terminal that started it. When an
agent needs MCP credentials, start a shell in the new terminal by running
`hc run` without a command. A person enters the credentials in that shell,
then launches the agent from it. Reuse the prepared pane for later tasks
that need the same role and access.

`hc run` starts executables, not shell aliases, and the core's `PATH` can
differ from your shell's. Launch through a login shell you have verified, or
give the full path of the executable and its configuration directory.

```zsh
hc run --bg --name project-lead --cwd "$PWD" -- \
  /bin/zsh -lic 'codex --no-daemon'
```

Keep credential values in the environment only. Never put them in command
arguments, `hc send` text, labels, files, or reports. Refer to a credential by
its variable name.

## Three levels of verification

Each level proves more and touches more. Use the lowest one that answers your
question.

| Check | Proves | Starts MCP servers |
| --- | --- | --- |
| `scripts/check-env.zsh <target>` | Commands, paths, variable names | No |
| `codex mcp list` | Codex reads the configuration | No |
| `claude mcp list` | Eligible servers answer | Yes |
| `/mcp` and one read-only tool call | Credentials and permissions work | Yes |

`claude mcp list` starts every eligible server: the registered ones and the
approved servers from the current folder's `.mcp.json`. It does not start a
server that is still pending approval. Approve a project's servers only when
you trust the project, and run the command from a folder you trust.

## Team operation

A lead agent coordinates other agents in the same space with `hc`. The person
decides who is on the team and what each member may do.

### Record the facts

Confirm the lead's address from `HC_TERMINAL_ID` and look up its team name.
Check that the name resolves to that address. This example uses
`project-lead`. Use the same form for authorized members. Read app status
and layout when setting up or changing the team's layout.

```zsh
printf '%s\n' "$HC_TERMINAL_ID"
hc get -- project-lead
```

```zsh
herdr-app status
herdr-app ls
```

Record these values:

- From `hc get`: the lead's `address`, its `foreground.cwd`, its `parent`, and
  its `herdr.space` label.
- From `herdr-app status`: the `space`, `tab`, and `focused_pane` the window
  shows now. The shown space can differ from the lead's own space.
- From `herdr-app ls`: each space's `id` and `name`, and the `terminal`
  address, `pane`, and `status` of every terminal in the team's space.

### Agree on the roster

Reuse the members the person has already authorized. Record each member's
assigned address, team name, and role. Use the address to identify the
member in READY replies, reports, and pane titles. A role is an assignment,
so the same terminal can take a different role later.

Start a new member only when the person's roster and scope call for one. Do
not stop, move, rename, or send input to terminals outside that roster.

### Prepare team communication

Before dispatching work, use the real launch profile for each role.
Verify that the lead can inspect and contact each authorized member and
that the coder and reviewer can edit the task checkout when assigned.
Use the onboarding READY message to verify the member's return path.
When a role needs permission for the local Herdr connection, configure
it during setup.

Choose a distinct Herdr name for each terminal, including a new lead,
before setting up its launch permissions. Use team-specific names and keep
them reserved for that team. Pass the same names to `hc run --name` so the
rules can be in place before Herdr assigns terminal addresses. For an
existing pane without a name, read `HC_TERMINAL_ID` in its shell before
launching the agent. Substitute that literal address for its name in the
rules, commands, and onboarding prompt.

- [Codex team communication](codex/README.md#herdr-team-communication)
- [Claude Code team communication](claude/README.md#herdr-team-communication)

Limit permissions to the team names and commands the role needs. Place
`--` before the literal name or authorized address in a permitted command.
Before sending input, verify that the name resolves to the roster address
in the expected space and working directory. A reviewer can print READY
and the verdict in its pane for the lead to read.

### Add a member

Start each new member as an interactive agent in the background, using
its chosen name, an explicit working directory, and the lead as its parent.
`hc run` prints the address of the new terminal. Record it with the
member's name and role. Use the verified literal name for `hc` commands
and set `member` to the assigned address for the layout commands below.

For a Codex reviewer, prepare the
[review profile](codex/README.md#review-profile) with workspace write
access before launch.

```zsh
hc run --bg --name project-review --cwd /path/to/repo \
  --parent "$HC_TERMINAL_ID" -- \
  /bin/zsh -lic 'codex --no-daemon --profile review'
```

For a Claude coder, choose the prepared alias and
[worker settings](claude/README.md#roles-and-preferences). This example
uses `claude` with Auto mode.

```zsh
hc run --bg --name project-coder --cwd /path/to/repo \
  --parent "$HC_TERMINAL_ID" -- \
  /bin/zsh -lic 'claude --permission-mode auto --settings "$HOME/.claude/herdr-worker.json"'
```

For a member that needs MCP credentials, start a shell instead. Give it a
pane as described in [Show the team](#show-the-team), so a person can enter
the credentials, run the environment check, and launch the agent there.

```zsh
hc run --bg --name project-mcp --cwd /path/to/repo --parent "$HC_TERMINAL_ID"
```

A member ends when its parent ends unless you add `--outlive-parent`. To place
a member in another space or tab at launch, add `--label herdr.space=<id>`
and `--label herdr.tab=<id>` with IDs from `herdr-app ls`.

Before sending onboarding, verify the intended CLI, its working directory,
and an available input prompt. A wait can return for a message or a timeout
while the member is still starting. Check the result and inspect the pane.
These examples use `project-review` for the member and `project-lead`
for the lead. Use the team's verified names.

```zsh
hc wait --timeout 45 -- project-review
hc get -- project-review
hc read --lines 0 -- project-review
```

When the member can receive input, send the onboarding request. Replace
the example addresses, parent, and directory with the values from `hc get`.
Check the READY reply before assigning work.

```zsh
hc send -- project-review \
  'Onboard as reviewer. Lead project-lead (t6), member t7,
  parent t6, cwd /path/to/repo. Follow Onboard a member in HERDR.md.
  Print READY in your pane.'
```

### Show the team

These commands change what the person sees. Run them only for a layout the
person asked for, and leave other tabs, panes, and running programs alone.

A member gets its own pane in the lead's tab. Find the target pane of that
tab in `herdr-app ls` and set `target_pane` to its ID. Focus that pane
immediately before `terminal.keep`, because the split follows the focused
pane.

```zsh
herdr-app do pane.focus --pane "$target_pane"
herdr-app do terminal.keep --terminal "$member" --place right
herdr-app ls
hc get -- project-review
```

`terminal.keep` splits `right` or `down`. It can answer `pending: true` and
apply the change a moment later. Before you continue, confirm in
`herdr-app ls` that the member has its new pane in the lead's tab, and check
its space there and in `hc get`. A member started without labels has no space
until it is shown. Then pin it to the top of the agent lists.

```zsh
herdr-app do terminal.pin --terminal "$member" --pinned true
```

A member that already has a pane somewhere else must give it up first.
Parking removes the pane, turns off core keep, and leaves the program
running. It can also answer `pending: true`.

```zsh
herdr-app do terminal.park --terminal "$member"
herdr-app ls
hc get -- project-review
```

After parking, confirm in `herdr-app ls` that the old pane no longer shows
the member, and in `hc get` that the member is still `live` with the same
`parent` and foreground program. Only then focus the target pane and run
`terminal.keep`.

Titles are optional. Name the shared tab after the space, and name each
member's pane with its address. Take `team_tab`, `space_name`, and
`member_pane` from `herdr-app ls`.

```zsh
herdr-app do tab.rename --id "$team_tab" --name "$space_name-lead"
herdr-app do pane.rename --pane "$member_pane" --name "$member"
```

Check the result before you report it. Compare the `terminal` and `pane`
pairs in `herdr-app ls` with the roster, then save a screenshot and look at
it.

```zsh
herdr-app ls
herdr-app shot /tmp/herdr-team.png
```

### Onboard a member

Send this prompt to each member. The lead supplies the verified addresses,
the lead's team name, parent, working directory, and role. Include the
reporting path agreed in
[Prepare team communication](#prepare-team-communication).

```text
You are joining a Herdr team in this repository.
Lead: <lead-name> (<lead-address>). Member: <member-address>. Role: <role>.
Parent: <parent>. Working directory: <foreground.cwd>.

This step is setup only. Do not edit files, start agents, or change the
Herdr layout.

1. Read CLAUDE.md, which imports AGENTS.md, and HERDR.md in this
   repository.
2. Confirm the working directory and instructions you can access.
3. Reply with READY, your member address, parent, working directory,
   and role. Use hc send -- <lead-name> "<reply>" when authorized,
   or print the reply in your pane for the lead to read.

Wait for an assignment from the lead. A review assignment specifies
whether you are the editor for that turn. Bring questions and blockers
to the lead. The designated lead handles authorized commits.
```

A member is ready when the lead has its reply and has checked its actual
terminal, working directory, and role.

### Review and repair

Assign one coder and at least one reviewer. When both CLIs are available,
use a reviewer on a different CLI from the coder. The lead names the task
checkout and the editor for each turn. Only that editor changes files in
the checkout, and each handoff ends the editor's turn.

1. The lead gives the coder the starting snapshot, task scope, constraints,
   required checks, and reporting path. The coder implements the task, runs
   the checks, and hands back the changed files and results.
2. The lead freezes the candidate and hands it to the reviewer. The
   reviewer checks the whole change and directly fixes confirmed issues
   within the assignment in the task checkout. Before editing, compare only
   the assigned candidate paths in the checkout against the archive.
   Verify that the paths, contents, and executable bits match. If anything
   differs, stop and report it to the lead. After a fix, run the relevant
   checks, report the input snapshot's SHA-256, and hand back the changed
   checkout so the lead can freeze the output under a new SHA-256.
3. The coder re-reviews the reviewer's fixes on the new snapshot. Check
   that each issue is resolved and that the repair introduces no regression.
   Report any remaining or new issues to the lead so the reviewer can
   address them on the next turn.
4. The reviewer reviews the latest candidate again. If the reviewer makes
   another fix, freeze the new candidate and repeat the coder re-review.
   If there is another reviewer, give them a separate turn and send any
   fixes they make through the same cycle.
5. Finish when the latest candidate passes the required checks and the
   reviewer finds no actionable in-scope issues, with coder confirmation
   of every reviewer fix on that candidate. Clean verdicts and coder
   confirmation must cite the latest candidate's SHA-256. Report any issue
   that requires a decision beyond the assigned scope to the lead. For a
   commit, also meet the [team commit checks](#commit-reviewed-changes).

For each handoff after edits, the lead archives the exact candidate files
outside the checkout. Keep relative paths and executable modes, include
intended new files, and exclude credentials and other local state.
Verify the archive digest and extract it to a new directory. Remove write
permission with `chmod -R a-w "$candidate_dir"`, where `candidate_dir`
is the absolute path to the extracted tree. Give each participant the
archive, its digest, and the extracted path. Verify the digest before and
after inspection. Run checks that need to write in an authorized location
outside the frozen copy.

Compute the digest like this, where `candidate_archive` is the absolute path
of the finished archive.

```zsh
shasum -a 256 -- "$candidate_archive"
```

### Commit reviewed changes

The user authorizes commits and pushes separately. For an authorized
commit, the designated lead needs `codegpt` on `PATH`. Check the target
branch and its expected tip, then stage only the approved changes.
The review and repair loop can finish with one reviewer. Before committing,
obtain a second independent review so each change has two reviewers who
did not write it. Both reviews must apply to the accepted candidate.

Verify the candidate's contents and file modes. Use a temporary Git index
based on the expected tip to build the Git tree from the frozen candidate.
Record that tree as `reviewed_tree` and compare it with the staged changes.

```zsh
test "$(git write-tree)" = "$reviewed_tree" &&
  codegpt commit --no_confirm
```

After the command, verify that the target branch points to the new commit,
its parent and tree match the approved integration, and the working tree
has the expected state. A push requires its own authorization.

### Reports and stalled work

Members report to the lead when they finish or get stuck. Every handback,
including a coder confirmation or reviewer verdict without edits, includes
the SHA-256 of the snapshot examined, fixes or `none`, and check results
or `not run`. Send the result directly or print it in the pane if that is
the configured return path. The lead records it with the task. Use a report
file when the role has an authorized writable location. Replace
`project-lead` and `<sha256>` with the verified lead name and snapshot digest.

```zsh
hc send -- project-lead \
  'Snapshot SHA-256: <sha256>. Fixes: none.
Checks: Markdown lint passed. Verdict: clean.'
```

The lead waits with `hc`, not with `sleep`, and reads a member's screen to
see what happened.

```zsh
hc wait --timeout 45 -- project-review
hc get -- project-review
hc read --lines 0 -- project-review
```

Use the team's verified member names. Check why a wait returned and
read the handback before considering a task complete.

Read the screen when a member is blocked. Continue independent work or
use an available authorized path if the blocked step is optional. Ask the
user when a permission decision or other consequential choice is required.
Leave the permission prompt for the user to answer.

### Context checkpoints

From this repository, install the shared helper. Run the same command
again after pulling an updated helper.

```zsh
mkdir -p "$HOME/.local/bin"
install -m 0755 scripts/herdr-context.cjs "$HOME/.local/bin/herdr-context"
```

Enable the hooks in the [Codex guide](codex/README.md#context-checkpoints)
and the [Claude Code guide](claude/README.md#3-configuration) for each
configuration that launches team panes.

Lead, coder, and reviewer each keep their own short note. Run
`herdr-context record` from the assigned checkout at the start of a task,
and update it after key decisions, checks, or handoffs. For example:

```zsh
herdr-context record <<'EOF'
Task and role: Review the candidate as the assigned reviewer.
Scope and decisions: Review the assigned files and preserve user edits.
Candidate and paths: Record the SHA-256 and the checkout and archive paths.
Progress and checks: Record completed work, results, and remaining issues.
Next: Compare the checkout to the archive before making repairs.
EOF
```

Write task facts and omit credentials, transcripts, and raw tool output.
The helper replaces the previous note for that pane and checkout. The
checkout is the Git root, or the real directory outside Git, so its
subdirectories share one note. Notes stay in a private per-user directory
under `/tmp`, outside the checkout.

Each new, resumed, cleared, or forked session starts without a note, so
record one in that session before compacting. `PreCompact` saves the note
for the current session. It blocks compaction in a Herdr pane when the
session has no note or the save fails, including when the helper is
missing or exits with an error. A Codex hook that is untrusted or times
out cannot protect compaction, so confirm both hooks with `/hooks`. After
compaction, `SessionStart` prompts the agent to run `herdr-context load`
in the same checkout. The command returns the saved note as task data.

Run one interactive agent per Herdr pane. For a nested Codex or Claude Code
smoke test, prefix the CLI executable with `env -u HC_TERMINAL_ID` so its
startup hooks leave the parent pane's task note alone.

Choose to compact at a useful stopping point while there is still room
to record the note. Update the note, request compaction from a teammate,
and end the current turn. The lead can ask a teammate to do the same for
its own pane. The teammate verifies the request and the target's space
and address, waits for the turn to end, and checks the screen for an
empty input prompt before invoking the helper. Both panes must be in the
same space. A pane's own `herdr.space` label sets its space. A hidden
member without that label uses the label of its live parent, such as the
lead's pane. The helper refuses a target in another space or with no space.

```zsh
hc wait --timeout 45 -- project-review
hc read --lines 0 -- project-review
herdr-context compact project-review
```

The helper types only `/compact` into the designated pane. It refuses a
target that is working, blocked, or in error. Herdr holds the keys while a
person is typing in that pane, and the helper reports a failure if they are
not delivered within 15 seconds. Read the screen before trying again. Wait
and read the screen to confirm compaction succeeded. Send the next
assignment or continuation once the pane is ready. The agent checks the
loaded task data against the latest task and candidate before continuing.

If a pane reaches its context limit without a usable prompt, or shows a
dialog, an error, or a person's draft, do not type into it. Tell the
person what the screen shows. They can clear it and run `/compact` there.
If the session cannot continue, the person can end it, and the lead starts
a replacement and sends the latest assignment and candidate SHA-256. The
replacement records a new note before it starts work.

Claude Code's team template turns off automatic and idle compaction.
Codex's model-limit compaction remains a fallback. Both hooks cover
automatic and manual compaction when the CLI triggers them.

### Language

Write prompts, assignments, reports, and repository content in English. Write
on-screen updates for the person and short `hc send` handbacks in Traditional
Chinese (Taiwan).

## Starter prompt

Paste this into the agent that will lead.

```text
Act as the lead for this Herdr space. Read HERDR.md in the current
checkout, or use the GitHub copy if the local file is unavailable:
https://github.com/chindada/herdr/blob/main/HERDR.md

Verify the current space and reuse the task, roster, and scope I have
already authorized. Have the reviewer fix issues within scope, the coder
re-review the fixes, and the reviewer check the result again. Repeat until
the candidate is clear of actionable issues and passes verification.
For authorized commits, follow Commit reviewed changes in HERDR.md.
Ask only for a consequential missing decision or a necessary approval.
```
