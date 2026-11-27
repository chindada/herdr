# Context management for Herdr teams

Herdr teams should be able to resume an assignment after compaction using a
short checkpoint and a durable record. Apply the same working rules to the
current team and to future teams formed from the [shared guide](../../../HERDR.md).

## Scope and approaches

The implementation changes only `HERDR.md`. Add the working rules to the
existing assignment, reporting, and checkpoint sections. Have the Starter
prompt direct the lead to apply them during setup and repeat the assignment
and handback expectations to members. Preserve the existing helper, hook
flow, CLI settings, permissions, and layout. App settings, new helper code,
and new automated compaction are outside the scope.

- **Shared rules with a short Starter prompt reference.** Put each rule where
  the lead or member uses it. The Starter prompt tells the lead what to
  establish and verify, while the guide holds the details. Use this approach
  because it gives future teams an explicit instruction and keeps one source
  for the compaction procedure.
- **Self-contained Starter prompt.** Repeat the full operating procedure in
  the prompt and the guide. A pasted prompt would carry every detail, with
  two copies to update whenever the procedure changes. The prompt already
  requires the lead to read the shared guide.

## Operating requirements

1. **Durable handbacks.** The lead identifies an approved, durable shared
   location accessible to the assigned members and gives them a report path
   with the assignment. Members write detailed technical reports in English
   with the existing evidence and check fields. Their short Taiwan Traditional
   Chinese `hc` handback gives the outcome or verdict, the absolute report
   path, the candidate SHA-256 when applicable, and any decision or blocker
   for the lead. Keep the guide's existing fallback when a durable writable
   location is unavailable.
2. **Compact checkpoints.** The lead, coders, and reviewers run
   `herdr-context record` from their assigned checkout and refresh the note at
   decisions, checks, and handbacks. The helper stores the note privately
   outside the checkout.
   Keep the note within 2,048 bytes. Include the current assignment and scope,
   applicable candidate digest, durable artifact and report pointers, and the
   exact next action. Keep detailed evidence and check results in the report.
3. **Context checks at assignment and handback.** At dispatch, the lead checks
   context used in their own session and the recipient's session. The member
   checks their own session before sending a handback. The lead checks their
   own session on receipt. Prefer a current percent-used `agent.context` label
   from `hc get -- <terminal>` or a visible context footer through
   `hc read --lines 0 -- <terminal>`. Use slash commands only at the verified
   idle or done boundary with an empty composer and no dialog or draft.
   Use `/status` for Codex and `/context` for Claude Code. Convert a remaining
   percentage to percent used when needed. Treat missing or stale readings
   as unknown if a current value cannot be read safely. Account usage and
   rate-limit quota are separate measurements.
   [OpenAI developer commands](https://learn.chatgpt.com/docs/developer-commands?surface=cli)
   [Anthropic Claude Code commands](https://code.claude.com/docs/en/commands)
   [Anthropic status line context fields](https://code.claude.com/docs/en/statusline#context-window-fields)
4. **Prepare at 60%, coordinate at 80%.** Both reminders apply to the lead and
   every team member. At 60% context used or above, refresh the note and report
   pointers. At 80% used or above, also look for the next safe stopping point.
   If compaction would help, the session owner updates the note, asks a
   teammate, and ends the turn. The teammate follows the existing
   [checkpoint procedure](../../../HERDR.md#context-checkpoints) to verify
   current-session initialization and trusted hooks, the pane, space and
   checkout, and an idle or done state with an empty composer and no dialog
   or draft. Wait or report the blocker if the boundary is unsafe. After
   compaction, load in the same session and checkout and verify the restored
   assignment, candidate, and next action before resuming.
5. **Keep native compaction behavior.** The percentages are team reminders.
   Preserve Codex's model-limit fallback and the Claude Code team template's
   disabled automatic and idle compaction. Manual `/compact` keeps using
   `PreCompact` to save and `SessionStart` with `source: "compact"` to prompt
   `herdr-context load`. Keep the distinction between same-session compaction
   and a new, resumed, cleared, or forked session that requires a fresh note.
   [OpenAI hooks reference](https://learn.chatgpt.com/docs/hooks)
   [OpenAI configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference)
   [Anthropic hooks reference](https://code.claude.com/docs/en/hooks)
   [Anthropic auto-compact setting](https://code.claude.com/docs/en/settings-reference#autocompactenabled)

## Acceptance and recovery evidence

- Inspect the implementation diff. The shared guide and Starter prompt cover
  each requirement. At dispatch, verify that the lead checks their own
  context and the recipient's. At handback, verify that the member checks
  their own context before sending and the lead checks their own on receipt.
  Verify the preferred read-only methods and safe boundary for slash commands,
  both reminders for all roles, the durable handback fields, and recording
  from the assigned checkout with private storage outside it. The diff
  contains only the approved guide edits. Check Markdown links and anchors
  and run `git diff --check`.
- Verify one disposable interactive Herdr session for Codex and one for Claude
  Code using the relevant launch route and effective checkpoint setup. The
  lead owns the verification. Ensure the disposable address and checkout are
  verified before typing into the pane. Keep live team panes out of the test.
  In each disposable session, observe initialization and the loaded hooks.
  Use `herdr-context record` from the assigned checkout to record a unique
  test marker, task, and exact next action. Compact at the verified idle
  boundary using the existing procedure.
  For Codex, wait for the CLI to report compaction complete. Verify the pane
  is idle or done with an empty composer and no dialog or draft, then submit
  one ordinary test continuation in the same session and checkout. Omit the
  marker, task, and exact next action from the prompt. Verify that Codex
  delivers the queued `SessionStart` load instruction on that turn.
  For Claude Code, observe the post-compaction `SessionStart` load instruction
  as the CLI delivers it. For both CLIs, verify that the instruction led to
  an actual `herdr-context load` call in the same session and checkout with
  exit status 0. Compare the loaded marker, task, and exact next action with
  the recorded values. A CLI passes when all three match and the pane returns
  ready. Record a failure or unavailable check with its specific blocker.
  [Codex 0.172.0 manual compaction hook test](https://github.com/openai/codex/blob/rust-v0.172.0/codex-rs/core/tests/suite/hooks.rs#L2187-L2257)
- The lead keeps a durable per-CLI record of the operator, commands and exit
  statuses, observed results, CLI and Herdr versions, machine and launch
  profile or route, and the relevant installed helper and effective hook and
  settings identities or digests. A fresh team can reuse a readable passing
  record for that CLI if the tested procedure and relevant inputs and
  execution environment still match, including versions, launch route,
  helper, hooks, and effective settings. If evidence is missing or the
  effective setup differs, rerun a disposable check for the affected CLI.
  Reuse still requires verifying the actual live session and safe boundary
  before any compaction. The 60% and 80% reminders are checked by inspecting
  the guide, and the disposable test exercises recovery directly.

## Platform research

Context7's Codex repository index covered the commands, token-triggered
compaction, and the `compact` source. The OpenAI documentation index supplied
the `PreCompact` behavior missing from the initial result. The upstream source
tag for the installed Codex 0.172.0 confirms the command descriptions. Herdr's
Codex guide retains the required `/hooks` trust check.
[Codex 0.172.0 slash command source](https://github.com/openai/codex/blob/rust-v0.172.0/codex-rs/tui/src/slash_command.rs)
[OpenAI hooks reference](https://learn.chatgpt.com/docs/hooks)
[Herdr Codex setup](../../../codex/README.md#context-checkpoints)

Context7's Claude Code result covered `PreCompact` and automatic and idle
settings. The Anthropic command and hooks references fill in `/context` and
the `SessionStart` `compact` matcher. Installed Claude Code 2.1.332 meets the
documented 2.1.295 minimum for `onFailure: "block"`. Platform docs establish
the CLI behavior. Disposable recovery checks supply evidence for the installed
Herdr helper and effective profiles.
[Anthropic commands](https://code.claude.com/docs/en/commands)
[Anthropic hooks reference](https://code.claude.com/docs/en/hooks)
[Herdr Claude Code setup](../../../claude/README.md#3-configuration)
