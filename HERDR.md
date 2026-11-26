# Work in Herdr

Set up Herdr panes for a team whose lead takes a user request through
implementation, review, repair, and verification.

Use this file as the team's Herdr guide in any project. Give the team a
readable path or URL to the guide. Copying it into the project is optional.
Follow the target project's applicable rules alongside this guide. The Herdr
source repository's `AGENTS.md` and `CLAUDE.md` apply to that repository.

The manuals that ship with your Herdr version are the source of truth for
commands. Read both before you run anything here, and use
`hc <command> --help` and `herdr-app commands` for exact arguments.

```zsh
hc --skill
herdr-app --skill
```

## Quick start

Open the target project's Herdr space, focus the pane you will use, and set
its working directory to the project's checkout. Keep this directory for
agent launches and task work. The guide can come from a separate checkout
or the [canonical GitHub copy](https://github.com/chindada/herdr/blob/main/HERDR.md).

The optional profile guides and the environment and checkpoint helper
scripts live in the Herdr source repository. Resolve profile guide links
relative to that source. If you use the scripts, set `herdr_source` to the
absolute path of its checkout on the machine running them. Export only the
credentials the agent needs, following the
[Claude Code guide](claude/README.md#4-mcp-credentials) or
[Codex guide](codex/README.md#mcp-credentials) if needed.

To check the launch environment, run the Herdr source script from the
target pane with `codex`, `claude`, or `claude-k`. The check fails when a
required item such as `uv` is missing.

```zsh
"$herdr_source/scripts/check-env.zsh" codex
```

Launch the agent from the same pane. Codex needs `--no-daemon` in Herdr.
Without it, its commands run outside the terminal that `hc` manages. For
the team launch mode the user authorizes, start the lead with `--yolo`.

```zsh
codex --yolo --no-daemon
```

For an approval-based launch, omit `--yolo` to keep the configured sandbox
and approval policy.

```zsh
codex --no-daemon
```

For a named Codex profile, use the same profile for the offline check and
launch. Install the [work profile](codex/README.md#gitlab-work-profile) first
if this pane needs GitLab.

```zsh
"$herdr_source/scripts/check-env.zsh" codex --profile work
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
hc run --bg --cwd "$PWD" -- \
  /bin/zsh -lic 'codex --yolo --no-daemon'
```

Use this team launch mode when the user authorizes its flags. Otherwise use
the approval-based alternative, which keeps the configured permission mode.
Keep the running lead when provisioning members from its starter prompt.

Keep credential values in the environment only. Never put them in command
arguments, `hc send` text, labels, files, or reports. Refer to a credential by
its variable name.

## Three levels of verification

Each level proves more and touches more. Use the lowest one that answers your
question.

| Check | Proves | Starts or contacts MCP servers |
| --- | --- | --- |
| `"$herdr_source/scripts/check-env.zsh" <target>` | Commands, paths, variable names | No |
| `codex mcp list` | Codex reads the configuration | Can contact configured HTTP MCP servers during authentication discovery and send configured headers |
| `claude mcp list` | Eligible servers answer | Yes |
| `/mcp` and one read-only tool call | Credentials and permissions work | Yes |

Use `"$herdr_source/scripts/check-env.zsh" codex` for local-only verification. Add
`--profile <name>` to include a named user profile.

`claude mcp list` starts every eligible server: the registered ones and the
approved servers from the current folder's `.mcp.json`. It does not start a
server that is still pending approval. Approve a project's servers only when
you trust the project, and run the command from a folder you trust.

## Team operation

A lead agent coordinates other agents in the same space with `hc`. The person
decides who is on the team and what each member may do.

### Record the facts

Read the lead's actual address from `HC_TERMINAL_ID`. If an approval rule
allows a literal lead alias, such as `project-lead`, query
`hc get -- project-lead` first. Verify that its returned `address` matches
`HC_TERMINAL_ID` and keep that address as `lead`. When address-based
lookup is allowed, query by address as shown below. Capture
`foreground.cwd` before changing directories and check it against `pwd -P`.
Resolve the selected space and its actual machine with app status and layout
and check that the lead belongs to it. If the selected space and the lead's
space differ, resolve which one the user intends before launching there.
Keep the resolved machine, space, and target checkout when focus changes.

Run `herdr-app status`, `herdr-app ls`, layout commands, and screenshots
on the machine hosting the visible Herdr window. If the lead is headless,
use an authorized operator on that desktop. If desktop operations are
unavailable, report visibility as pending.

```zsh
lead="$HC_TERMINAL_ID"
hc get -- "$lead"
pwd -P
```

```zsh
herdr-app status
herdr-app ls
```

Record these values:

- From `hc get`: the lead's `address`, its `foreground.cwd`, its `parent`, and
  its `herdr.space` label. Verify any existing launch alias against the
  actual address before using it.
- From `herdr-app status`: the `space`, `tab`, and `focused_pane` the window
  shows now. The shown space can differ from the lead's own space.
- From `herdr-app ls`: the team's space `id`, `name`, and `machine` (local if
  unset), and its tab IDs, `pane` IDs, `terminal` addresses, and statuses.

### Agree on the roster

The requested roster authorizes its listed roles and commands. Either CLI
can be a coder or reviewer. The roster and per-turn assignment determine
the role.

Inspect `hc ls` and verify candidates with `hc get`. Reuse an authorized
live member whose role, running CLI conversation, parent, current directory,
and space match. Record its actual address and any existing launch alias.
Create only missing authorized members. If a roster member has a permission
or launch-mode mismatch, report it, preserve the session, and leave the
entry pending. Resolve ambiguous matches before retrying. Leave unrelated
terminals alone.

### Prepare team communication

Before dispatching work, use the real launch profile for each role.
Verify that the lead can inspect and contact each authorized member and
that the coder and reviewer can edit the task checkout when assigned.
Use the onboarding READY message to verify the member's return path.
When a role needs permission for the local Herdr connection, configure
it during setup.

Use actual terminal addresses as member names in the roster, native titles,
and READY reports. Omit launch aliases by default. An immutable
`hc run --name` launch alias can still be used in an approval-based setup to
prepare narrow rules before an address is assigned.
Reserve such aliases for the team and preserve them on reuse. Use a verified
literal address or alias supported by the current rule. A native title
change leaves the launch alias and its rules in place.

- [Codex team communication](codex/README.md#herdr-team-communication)
- [Claude Code team communication](claude/README.md#herdr-team-communication)

Limit permissions to the team names and commands the role needs. Place
`--` before the literal name or authorized address in a permitted command.
Before sending input, verify that the name resolves to the roster address
in the expected space and working directory. A reviewer can print READY
and the verdict in its pane for the lead to read.

### Add a member

Use `hc run --bg` for every new interactive member. Bind `project_dir`
and `space_id` to the verified target checkout and space ID. Use the
verified `lead` address and prepare an `onboarding_prompt` for that member's
role using [Onboard a member](#onboard-a-member). Pass it as the first
positional prompt. The same launch works for either role.

These visible-team examples opt into the space with `herdr.space`.
A `herdr.tab` label selects a tab. Without it, Herdr can create a
temporary tab in the space. Labels control placement in the window.
A lead on the owning core launches there with its verified local address.
From another core, verify the route with `hc machine ls` and use qualified
addresses for remote terminals. Use `hc run --on <machine>` with the
checkout path on that machine and keep the returned full address.
For a requested shared layout, use [Show the team](#show-the-team) to
move the same authorized terminals into the lead's tab.

```zsh
hc run --bg --cwd "$project_dir" --parent "$lead" \
  --label "herdr.space=$space_id" -- \
  codex --yolo --no-daemon -- "$onboarding_prompt"
```

```zsh
hc run --bg --cwd "$project_dir" --parent "$lead" \
  --label "herdr.space=$space_id" -- \
  env CLAUDE_CONFIG_DIR="$HOME/.claude" "$HOME/.local/bin/claude" \
  --dangerously-skip-permissions -- "$onboarding_prompt"
```

Use a verified executable path if the core's PATH differs. Set
`CLAUDE_CONFIG_DIR` to the selected profile, such as `$HOME/.claude-k`.
Without it, Claude Code reads a different configuration than the profile
aliases. Alternatively, launch a Claude alias through a verified login
shell. When wrapping a launch in zsh, pass the onboarding text as a
positional argument to the shell.

For `--on` launches, use executable and profile paths verified on the target
machine, or expand `HOME` inside a verified target login shell. The `$HOME`
in the local example expands on the caller.

```zsh
hc run --bg --cwd "$project_dir" --parent "$lead" \
  --label "herdr.space=$space_id" -- \
  /bin/zsh -lic 'exec codex --yolo --no-daemon -- "$1"' \
  herdr-member "$onboarding_prompt"
```

For an authorized background-only launch, omit the
`--label "herdr.space=$space_id"` argument and leave `herdr.tab` unset.
Keep `--parent "$lead"` and use the verified live parent's space for the
hidden member.

Use the launch flags the user authorized. Keep any selected Codex
`--profile` or Claude configuration directory and settings file. For
approval-based launches, see the [Codex review profile](codex/README.md#review-profile)
and [Claude role settings and Auto mode](claude/README.md#roles-and-preferences).
Those permission settings apply to their own mode. A launch that bypasses
approvals still follows the assigned scope. If managed policy, tool
permissions, or a startup decision blocks the requested launch, report it.

Claude Code can ask once per configuration directory to acknowledge
`--dangerously-skip-permissions`. When `hc read --lines 0` shows that
native dialog, tell the user which member shows it and leave the answer
to them. Do not send keys to the dialog. After the user clears it, check
that the member received its onboarding before resending.

Record the returned terminal address, then verify live state,
`foreground.argv`, `foreground.cwd`, parent, and space with `hc get`.
Check the member's space label for a visible launch. Set `member` to the
verified address for layout commands. After an ambiguous launch failure,
inspect existing terminals before retrying.

For a member that needs MCP credentials, start a shell instead. Give it a
pane as described in [Show the team](#show-the-team), so a person can enter
the credentials, run the environment check, and launch the agent there.

```zsh
hc run --bg --cwd "$project_dir" --parent "$lead"
```

A member ends when its parent ends unless you add `--outlive-parent`.

For a prepared shell or launch without the first prompt, wait for the
intended CLI to start. Verify its working directory and inspect the pane
for an idle, empty composer before sending onboarding. Check delivery
before resending after a timeout. Use a verified alias if the lead's
rules require one.

```zsh
hc wait --timeout 45 -- "$member"
hc get -- "$member"
hc read --lines 0 -- "$member"
```

```zsh
hc send -- "$member" "$onboarding_prompt"
```

### Show the team

These commands change what the person sees. Run them only for a layout the
person asked for, and leave other tabs, panes, and running programs alone.

For the standard four-member roster, use one large, full-height lead pane
alongside a 2 by 2 grid of four equal member panes in the shared tab.
Follow any layout the user requests and adapt the arrangement to other
roster sizes.

When Pixel HQ visibility is requested, verify each member's space label and
pin each member as soon as its launch is verified. Recheck the pin on reused
members and after placing each terminal.

```zsh
herdr-app do terminal.pin --terminal "$member" --pinned true
```

A member gets its own pane in the lead's tab. Find the target pane of that
tab in `herdr-app ls` and set `target_pane` to its ID. Focus that pane
immediately before `terminal.keep`, because the split follows the focused
pane.

```zsh
herdr-app do pane.focus --pane "$target_pane"
herdr-app do terminal.keep --terminal "$member" --place right
herdr-app ls
hc get -- "$member"
```

`terminal.keep` splits `right` or `down`. It can answer `pending: true` and
apply the change a moment later. Before you continue, confirm in
`herdr-app ls` that the member has its new pane in the lead's tab, and check
its space there and in `hc get`. A member started without labels can gain
a space when it is shown.

A member that already has a pane somewhere else must give it up first.
Parking removes the pane, turns off core keep, and leaves the program
running. It can also answer `pending: true`.

```zsh
herdr-app do terminal.park --terminal "$member"
herdr-app ls
hc get -- "$member"
```

After parking, confirm in `herdr-app ls` that the old pane no longer shows
the member, and in `hc get` that the member is still `live` with the same
`parent` and foreground program. Only then focus the target pane and run
`terminal.keep`.

For Pixel HQ, name the shared tab after the space and set each agent's
native conversation title to its verified terminal address. Take
`team_tab` and `space_name` from `herdr-app ls`.

```zsh
herdr-app do tab.rename --id "$team_tab" --name "$space_name-lead"
```

In Codex, have each session call its own native title tool when available.
For `mcp__codex_tui__set_thread_title`, supply the address as `title` and
omit `threadId`. For Claude Code, use its native `/rename <address>`
command. If delivering it with `hc keys`, verify the address, foreground
CLI, parent, and cwd with `hc get`. Inspect `hc read --lines 0` for an
idle or completed turn with an empty composer and no dialog or queued
input. Send the literal command keys and one Enter only at that safe
boundary. Verify the native title and report any title change the
running CLI cannot support.

Check `herdr-app status` for layout errors and compare the roster against
the terminal and pane pairs in `herdr-app ls`. For requested Pixel HQ
visibility, choose a unique `team_shot` path outside the checkout. Take
and open a fresh screenshot. Confirm that the lead and every member have
a recognizable name and icon independently visible in the team panel,
and that all split panes are visible together in the shared tab. Report
any visibility blocker with the affected terminals.

```zsh
herdr-app status
herdr-app ls
herdr-app shot "$team_shot"
```

### Onboard a member

Use this prompt for each member. Supply a guide reference the member can
read, the verified lead address, checkout and space, the assigned role,
and the return path agreed in
[Prepare team communication](#prepare-team-communication).

```text
You are joining a Herdr team. Herdr guide: <readable path or URL>.
Lead and expected parent: <lead-address>. Role: <role>.
Expected checkout: <absolute project-dir>. Expected space: <name, ID, machine>.

This step is setup only. Leave the checkout and layout as they are.

1. Read the supplied Herdr guide and any applicable rules present in the
   target project. Name the references you actually read.
2. Use pwd -P and hc get -- "$HC_TERMINAL_ID" to verify your live address,
   parent, space and foreground working directory. Verify the lead's address.
3. Reply with READY and the terminal=, role=, space= and cwd= fields.
   Include the verified parent and rules read. Use hc send -- <lead-address>
   "<reply>" when authorized, using a verified alias if required. Otherwise,
   print the reply in your pane.

Stay interactive and wait for an assignment from the lead.
Launch authority belongs to the lead. A review assignment specifies
whether you are the editor for that turn. Bring questions and blockers
to the lead. The designated lead handles authorized commits.
Use English for agent work and records. Use Taiwan Traditional Chinese
for human-facing text and short hc replies. Preserve protocol fields.
```

A member is ready when the lead has its READY reply and has verified the
live address, foreground CLI and working directory, parent, space, machine,
and assigned role. In a setup-only turn, verify readiness and any requested
visibility, then leave the existing sessions available for assignments.

### Run an assignment

Maintain one short roster and task record. Keep the verified checkout,
space and machine, tab and panes, member addresses and roles, current phase,
sole checkout editor, authorized scope, and immutable artifact references.
Record status and open questions there as they arise. When using checkpoints,
keep the record in the note if it fits or link to the approved handoff
record from the note. The lead resumes from the record when a result or
direction arrives. Wait for work with an outstanding handback.

For a substantial handoff, use the location approved by the user or project.
Otherwise, use an absolute shared path outside the checkout that every
assigned member can read. For separate machines without a shared path, use
a targeted transfer such as `hc put` to the verified member. Record the
destination path and confirm the copied artifact's digest.

Give each assignment an owner, editor or read-only designation, branch and
checkout, baseline or candidate, allowed paths, any skills needed, checks,
dependencies, reporting path, and stop condition. Repeat the
[language instruction](#language). Before sending, verify the recipient's
live address, role, parent, space, machine, and cwd against the record.
Set `member` to the verified address or required alias. Confirm the
assignment began through a new reported working turn or the member's
acknowledgement. For uncertain delivery, inspect the member's status and
screen before resending.

```zsh
hc wait --timeout 45 -- "$member"
hc get -- "$member"
hc read --lines 0 -- "$member"
```

Inspect the wait reason and current state. With `reason: message`, read the
incoming message. With `reason: timeout`, check progress before waiting
again. A live terminal can finish a turn and stay available. A terminal
exit ends the program and may leave the assignment unfinished. Read the
actual handback or blocker before advancing the task.

Keep idle members productive. At each dispatch, handback, or dependency
stall, check which members are available. Proactively give suitable idle
members useful independent work within the authorized scope, such as
reproductions, fixtures, review, evidence readback, or preparation for the
next step. Give each member one bounded active unit at a time, reserve
reviewer capacity for upcoming candidates, and keep a single editor for
each shared checkout or resource. When nothing useful can advance within
scope, or the user has paused the work, let the member stand by.

### Review and repair

Assign one coder and at least one reviewer. When both CLIs are available,
use a reviewer on a different CLI from the coder. Record each reviewer's
address, CLI, snapshot, and whether they authored any changes. The lead
names the task checkout and the editor for each turn. Only that editor
changes files in the checkout, and each handoff ends the editor's turn.

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
at the location agreed in [Run an assignment](#run-an-assignment).
Keep relative paths and executable modes, include intended new files,
and exclude credentials and other local state.
Record intended deletions with the candidate, including old rename paths.
Verify the archive digest and extract it to a new directory. Remove write
permission with `chmod -R a-w "$candidate_dir"`, where `candidate_dir`
is the absolute path to the extracted tree. Give each participant the
archive, its digest, the extracted path, and the deletion list. Verify the
digest before and after inspection. Run checks that need to write in an
authorized location outside the frozen copy.

Compute the digest like this, where `candidate_archive` is the absolute path
of the finished archive.

```zsh
shasum -a 256 -- "$candidate_archive"
```

### Commit reviewed changes

`HERDR.md` is the sole team guide for commit policy.
`codegpt commit --no_confirm` is the sole permitted way to create a commit
in this repository and for teams following this workflow. The user
authorizes commits and pushes separately.
Only the designated lead creates an authorized team commit. The lead needs
`codegpt` on `PATH`. Check the target branch and its expected tip, then stage
only the approved changes.
The review and repair loop can finish with one reviewer. Before committing,
each change needs two independent reviews by reviewers who did not write
that change. Both reviews must apply to the same final snapshot and cite
its digest.

Verify the candidate's contents and file modes. Use a temporary Git index
based on the expected tip. Remove the candidate's recorded deletion paths
from that index before adding the frozen candidate files. Record the
resulting tree as `reviewed_tree` and compare it with the staged changes.

```zsh
test "$(git write-tree)" = "$reviewed_tree" &&
  codegpt commit --no_confirm
```

After the command, verify that the target branch points to the new commit,
its parent and tree match the approved integration, and the working tree
has the expected state. A push requires its own authorization.

### Reports and stalled work

Members report to the lead when they finish or get stuck. Every handback,
including a coder confirmation or reviewer verdict without edits, identifies
the immutable inputs actually examined or used to run checks. Include the
snapshot SHA-256, fixes or `none`, commands and recorded exit statuses, and
any checks skipped, `not run`, or blocked. Distinguish source inspection
from runtime checks. For runtime checks, record relevant installed tool
versions and the execution and configuration used, such as the machine,
profile, and digests of installed helpers or settings files. The lead
records the result with the task and checks the final delta. Reuse accepted
evidence when the relevant inputs still match, and attribute it to the
member and CLI that produced it. The commit procedure still needs separate
user authorization.

Write the English technical report to the approved writable location when
available. Otherwise deliver it with the same required fields through an
authorized channel, including the pane if agreed. Use Taiwan Traditional
Chinese for the short human-facing status or file pointer. Send it to the
verified lead or print it in the pane if that is the agreed return path.

```zsh
hc send -- "$lead" \
  '快照 SHA-256 <sha256>。修正：無。Markdown 檢查通過，無待修問題。報告 /path/to/report.md。'
```

Read the screen when a member is blocked. Continue independent work or
use an available authorized path if the blocked step is optional. Ask the
user when a permission decision or other consequential choice is required.
Leave the permission prompt for the user to answer.

### Context checkpoints

Checkpoint use requires the shared helper and both hooks. Install the helper
from the Herdr source checkout. Run the same command after updating it.

```zsh
mkdir -p "$HOME/.local/bin"
install -m 0755 "$herdr_source/scripts/herdr-context.cjs" "$HOME/.local/bin/herdr-context"
```

Enable the hooks in the [Codex guide](codex/README.md#context-checkpoints)
and the [Claude Code guide](claude/README.md#3-configuration) for each
configuration that launches team panes. Use one hook representation per
Codex user configuration. If Codex already started with an untrusted
`SessionStart` hook, trust both hooks in `/hooks` and start a fresh Codex
session before recording the task note and compacting.

Start each agent CLI in its assigned checkout. At startup, its
`SessionStart` hook initializes checkpoint ownership for that checkout and
clears any old note, so a new session starts without one. When you launch
the CLI with `hc run`, pass that directory with `--cwd`. Starting it from
a shell already in the checkout, such as an existing pane, also works.

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
in the same checkout. Load the saved task data and verify it against the
latest assignment and candidate before recording a replacement note.

Run one interactive agent per Herdr pane. For a nested Codex or Claude Code
smoke test, prefix the CLI executable with `env -u HC_TERMINAL_ID` so its
startup hooks leave the parent pane's task note alone.

Choose to compact at a useful stopping point while there is still room
to record the note. Update the note, request compaction from a teammate,
and end the current turn. The lead can ask a teammate to do the same for
its own pane. Pause routine sends to the target until it is ready again.
The teammate verifies the request and the target's space and address, then
waits for the turn to end and reads the screen. Set `peer` to that verified
address or required alias. Both panes must be in the same space. A pane's
own `herdr.space` label sets its space. A hidden member without that label
uses the label of its live parent. The helper refuses a target in another
space or with no space.

```zsh
hc wait --timeout 45 -- "$peer"
hc read --lines 0 -- "$peer"
```

Look at that screen right away. Continue only if the composer is empty
and the pane shows no dialog or draft. Then invoke the helper on its own.

```zsh
herdr-context compact "$peer"
```

The helper types only `/compact` into the designated pane. It refuses a
target that is working, blocked, or in error. Herdr waits for typing to
pause, then sends the keys. An unsent draft can still be present after
the pause, and the helper's Enter can submit it. The helper reports a
failure if the keys are not delivered within 15 seconds. Read the screen
before trying again. After the helper returns, wait and check the live
session and its screen to confirm compaction succeeded and the composer
is ready. The teammate reports completion to the lead. The lead resumes
its own work from the record or sends the member one continuation for the
recorded assignment. The lead dispatches the next assignment when the
current one is complete. Check the pane before repeating a continuation
whose delivery is unclear.

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

Use English for agent instructions and assignments, durable reports and
checkpoints, and repository prose. Use Taiwan Traditional Chinese for
human-facing terminal and chat text, including final replies and short
`hc send` status messages and report pointers. Keep commands, addresses,
hashes, paths, and the protocol literals `READY`, `terminal=`, `role=`,
`space=`, and `cwd=` exact.

```text
READY terminal=t7 role=reviewer space=sp123 cwd=/srv/project
已核對上層 t3。已讀 /srv/guides/HERDR.md。待命。
```

## Starter prompt

Paste this into the running lead. Edit the roster to authorize only the roles
and launch commands you want. Use it on its own for setup, or append a task
to start after READY.

```text
Act as the lead for this Herdr space.
Guide reference: <readable path or URL, if supplied>.
Target checkout: <absolute path, or resolve from this pane>.
Read the supplied guide first. If unavailable, use a readable local
copy of this guide when present, then fall back to the canonical copy:
https://github.com/chindada/herdr/blob/main/HERDR.md
Read any applicable rules present in the target project.

Read the installed hc and herdr-app manuals. Use this terminal as the lead.
Verify the target working directory, lead address, and selected machine
and space from live state. Use the target checkout for assignments.

Authorized roster and launch commands:
- Codex coder: codex --yolo --no-daemon
- Codex reviewer: codex --yolo --no-daemon
- Claude coder: claude --dangerously-skip-permissions
- Claude reviewer: claude --dangerously-skip-permissions

Reuse matching live authorized members and launch only missing members as
interactive children. Use actual addresses as names. Omit new aliases
unless narrow permission rules need them. Record the verified roster and
preserve existing sessions when reporting permission or launch mismatches.

Give each member the guide reference and verify its READY reply with
terminal=, role=, space= and cwd=. Pin the members and show the team in one
shared tab with distinct split panes. For the standard four-member roster,
use one large, full-height lead pane alongside a 2 by 2 grid of four equal
member panes. Follow any layout I request and adapt to other roster sizes.
Set native titles to actual addresses and verify independent Pixel HQ
visibility with a screenshot. Report the roster, readiness, and any blockers.

If I supply a task, start it once its assigned members are READY and
follow Run an assignment and Review and repair. Use Commit reviewed
changes when I authorize a commit. Otherwise verify setup only and keep
the team interactive.

Use English for agent instructions, reports, checkpoints and repo prose.
Use Taiwan Traditional Chinese for human-facing text and short hc status
or report pointers. Preserve commands, paths, hashes and protocol fields.
Repeat the language instruction when assigning work.
```
