# Portable Herdr team workflow

Herdr teams should be able to run the same workflow in any project. The lead
verifies where the work belongs, and independent review makes the specification
and plan dependable inputs for implementation. The guide and the starter prompt
should describe the same sequence and authority boundaries.

## Design scope

Extend the existing `HERDR.md` workflow and starter prompt. Reuse the roster,
assignment, checkpoint, and snapshot handoff for the new review stages. Update
linked setup examples and prerequisites where the verified workflow requires it.
Include the focused checker and checkpoint repairs below. Preserve existing
launch defaults, sessions, user settings, and layouts. Report evidence and the
proposed scope to the lead before editing files outside the agreed scope.

## Guide and target checkout

The user can provide a guide path or URL. Use that reference if readable, then
try a guide in the target checkout or a known separate source checkout, and then
the [canonical guide](https://github.com/chindada/herdr/blob/main/HERDR.md).
Give each member a reference readable on their machine. Report the blocker if no
guide is available for a required session.

Resolve the guide location and the task checkout independently. Run assignments
from the target checkout on the verified Herdr machine. Check `pwd -P` against
`hc get`'s `foreground.cwd`, and verify the live address, parent, space, and
assigned role before dispatch. Use `herdr-app status` and `herdr-app ls` to
resolve the window's selected space and the team's machine. A focus change does
not change the assignment's checkout or space. Resolve linked profile guides
relative to the Herdr source or the guide URL. Resolve optional scripts by their
verified source paths independently of the guide lookup. If a script is
available, run it from the target pane with the actual launch profile and
environment. Use verified absolute source script paths in the README and both
CLI profile guides. A URL-only guide still supports team work with installed
tools. Report missing checkpoint support for assignments that depend on it.

Read the target repository's applicable instructions, including any rules for
the assigned paths. The guide supplies the team workflow. The Herdr source
repository's project rules apply to work in that repository.

## Team checks and recovery

The user approves the roster and launch mode. With no authorized roster, propose
the smallest suitable set of roles and wait for authorization before launching.
Coders and reviewers can use either supported CLI. Use the authorized roster or
the member's confirmed assignment to distinguish roles when members run the same
CLI. Reuse matching sessions and preserve working or mismatched sessions.
Dispatch only to an available member with no outstanding assignment. The lead
assigns one editor per shared checkout or resource, freezes candidates, and
handles authorized commits.

Tell each member which approved selector to use for self lookup, lead lookup,
and sending to the lead. Show all three as narrow literal rules for both CLIs
and verify the operations with the approved selectors. Match lookup responses
to the actual terminal addresses used in the roster and READY report. Confirm
delivery of each assignment by a new working turn or acknowledgment. A message
or timeout can interrupt a wait before the member finishes. Check the live state
and match the actual handback to its assignment and candidate before advancing.

Check required subprocess commands in the actual Herdr launch environment and
profile. A command discovered in an interactive shell can be absent in the core
shell or the process that launches an MCP server. When a launch wrapper is used,
test its environment too. Recover missing subprocess paths with a verified login
shell or explicit executable directories. An absolute CLI path resolves only the
CLI. Preserve live sessions while diagnosing optional tools, and gate only the
affected capability. Use `hc run --bg` for authorized prepared shells and include
both `hc` and `herdr-app` in the setup checks. Herdr Core combines its program
environment with explicit child overrides. [Herdr Core launch source](https://github.com/herdrdev/herdr-core/blob/master/crates/herdr-core/src/api/run.rs)

Document opt-in Claude telemetry in the launch and profile guides. When the
user opts in, export `HERDR_STATUSLINE_LABELS=1` in the child launch shell or
pass it explicitly as a nonsecret environment assignment with `hc run`. A lead
shell export alone is insufficient. The footer works independently of the
Herdr labels. Pixel HQ prefers `claude.*` and falls back to the script's
`agent.*` labels. The five-hour quota requires Claude's five-hour usage field.
The baseline observed working footers with absent opt-in variables and labels.

Separate genuine user decisions from avoidable prompts. A startup trust or
acknowledgment dialog, such as Codex's native Folder access prompt in an
untrusted checkout or Claude Code's bypass-mode acknowledgment, is a user
decision even with `--yolo` or `--dangerously-skip-permissions`. It can appear
before the CLI processes its first prompt while `hc get` reports a null agent
status rather than `blocked`. When a launched or reused member shows null or
unexpected status, read its screen with `hc read --lines 0` before resending or
assigning work. Report the member and dialog to the user, preserve the session,
and send no keys to it. Resume after the person clears it and delivery of the
initial prompt is verified.

A prompt caused by the team's own avoidable command, such as bundled
destructive cleanup of scratch, is not a decision to escalate first. Preflight
checks for side effects and keep useful checks separate from fixture cleanup.
Prefer small non-destructive commands in fresh, owned scratch. Leave scratch in
place when useful work can finish, or clean only fresh scratch owned by that
check when permitted. If such a command prompts, is blocked, or is declined,
preserve the session, honor the decline, rerun the useful check through a
permitted alternative, and continue independent work. Escalate only an actual
user decision or a blocker with no permitted alternative. Leave every prompt for
the user unless they explicitly authorize a response.

Keep checkpoint notes within the helper's 2,048-byte limit and link longer
handoffs. Verify the helper and hooks for the actual profile before depending on
restore.

## Checkpoint ownership and compatibility

Keep the existing live-note, saved-note, and owner keys. Add one pane-level
pointer holding the active session and canonical checkout. A non-compaction
`SessionStart` records it for the launch checkout. `record`, `load`, and `save`
reject a different checkout with a diagnostic identifying the active checkout.
Use the active session to validate the existing owner during restore and save.
`save` keeps its CLI-specific block response and hook session validation.
Pointerless legacy sessions retain their existing key lookup, including a valid
legacy spelling of the same checkout. Preserve existing saved notes. Redirecting
writes or switching to pane-only keys would hide mistakes and require migrating
state. The additive pointer fits the existing note and rollback model.

Resolve a real Git root with canonical on-disk casing. A confirmed non-Git
result can use the canonical directory itself. Surface other Git failures,
including timeouts, using exit status and stderr. Submodules and separate
worktrees have their own checkout identity. [Node.js subprocess API](https://github.com/nodejs/node/blob/main/doc/api/child_process.md)

Keep one interactive session per pane, and unset `HC_TERMINAL_ID` for every
nested CLI invocation, including noninteractive ones. Guard `SessionStart` in
both shipped templates before invoking the helper so a plain CLI start works
without it. Preserve the existing `PreCompact` hook contracts and document
Claude Code 2.1.295 as the minimum for `onFailure: "block"`. The observed
version was 2.1.332, so documenting the minimum preserves the handler contract
without adding a second failure protocol. [Claude Code hooks reference](https://code.claude.com/docs/en/hooks)

Before peer compaction, verify trusted hooks, observed initialization in the
current session, and a note recorded for that session. A stale owner or note
cannot establish current-session proof. Check the same-machine requirement and
report a remote peer or unavailable foreground checkout explicitly. After
waiting, confirm an idle or done peer with an empty composer and no dialog or
draft. Verify the restored note against the assignment before resuming. The
reset and stale-note hazards were reproduced at the helper level. The chosen
design uses current-session procedure because reliable live PID correlation was
unproven. Normal checkpoint hooks need no Herdr socket.

## Offline environment checker

Check that the installed checkpoint helper matches the source and that `PATH`
resolves to the same installed helper. Accept equivalent symlinks and diagnose
stale content and a shadowing helper separately. Diagnose a missing readable
Codex companion script before interpreting parser results, including when a
symlinked entry point has no companion. Keep Python fallback available when
`uv` is absent, while still reporting missing `uv` and returning failure.
Resolve `awk` via `PATH` and diagnose a missing tool distinctly from an unset
credential. Preserve existing profile layering and offline behavior.

## Specification, plan, and implementation

A tiny change has an obvious outcome, a confined edit, and a direct check, such
as an unambiguous typo correction. The lead records its scope and check. A change
with design decisions, changed behavior, or dependencies across repositories
requires the full sequence, as does an explicit request for it. When requirements
grow beyond a tiny change, use the full sequence before proceeding with the
expanded scope. Existing implementation review and commit requirements apply at
either size.

1. **Specification.** Record the outcome, requirements, scope, assumptions,
   tradeoffs, and testable acceptance criteria in a written specification. An
   independent reviewer checks it against the request and target rules. Resolve
   any required user decisions and finish the review before drafting the plan.
2. **Plan.** The coder uses `superpowers:writing-plans` with the accepted
   specification as input. Use a small number of small, independently verifiable tasks.
   Each task names its dependencies, authorized paths, expected outcome, and
   verification. Identify work that can proceed in parallel and the files or
   resources that require a single editor. An independent reviewer checks the
   plan against the specification before execution.
3. **Implementation.** The coder uses `superpowers:executing-plans` with the
   accepted plan. Run independent work concurrently when the authorized team has
   separate writable workspaces or the parallel work is read-only. Serialize
   changes in any shared checkout. Verify each task and apply the existing
   implementation review and repair cycle to the resulting candidate.

In this repository and projects using the Herdr workflow, write specifications
under `docs/superpowers/specs/` with a four-digit sequence and meaningful slug.
Start at `0001` and use the next unused sequence in the target directory. Omit
dates from specification names and keep plan naming unchanged. Consult Context7
for applicable platform and library best practices while drafting. Record the
primary sources, reconcile them with installed versions, compare viable options,
and recommend the fit for the project. In touched code, comment each new or
changed structure and method with its design, implementation, and an example.
Put these authoring rules in `HERDR.md` and reference them from `AGENTS.md`.

Context7 supplied current Herdr Core, Node.js, and Git source documentation for
this design. The exact installed Herdr Core 0.1.22 and Node.js 26.13.1 versions
were absent from its index. Use the installed manuals and observed command
behavior to confirm local arguments, hook contracts, and runtime assumptions.

Keep plans as ignored local artifacts under `docs/superpowers/plans/` in the
target checkout. At the planning stage, add a scoped `.gitignore` rule such as
`/docs/superpowers/plans/` only if needed and within the authorized edit scope.
Confirm that the actual plan is ignored and untracked, and that specifications
and other documentation remain visible. If target policy conflicts, report it
to the lead before creating or staging a plan and wait for a resolution.

### Review and repair before each phase advances

Run the existing single-editor review and repair cycle separately for the
specification and plan. The lead freezes the author's draft and assigns an
independent reviewer who did not author it. The reviewer checks the whole
candidate and reports the input SHA-256, findings, and checks. With an editor
assignment, the reviewer first verifies that the assigned paths, contents, and
executable bits match the frozen candidate. A mismatch goes back to the lead
before any edit. The reviewer fixes confirmed in-scope issues and returns the
changed checkout to the lead.

After the independent review, the author re-reviews the current frozen candidate
against the requirements and reviewer findings, including when the initial
review is clean. Any edit is made by the assigned editor and refrozen by the
lead. The author and reviewer check the current candidate in that order after
each repair. Advance only when required checks pass, the author confirms the
current candidate, and the reviewer confirms no actionable issues on the same
SHA-256. Changes to accepted requirements return to specification review and
send any affected plan back through plan review.

Freeze the base commit and intended deletions as metadata in the hashed
candidate archive alongside its files and modes. Include previously tracked
paths removed by renames. Verify the digest before and after inspection, and
check intended absences before repair and in the integrated tree. Load the base
into a temporary index, apply the exact payload and deletions, and compare its
written tree to the staged tree. After an authorized commit, verify that the
commit has the reviewed tree and expected parent. Keep archive metadata out of
the integration tree. [Git user manual](https://github.com/git/htmldocs/blob/gh-pages/user-manual.adoc)

Existing commit checks still apply. CodeGPT v1.8.0 skips pre-commit and
commit-msg hooks. The designated lead runs target-required checks before
`codegpt commit --no_confirm` and raises incompatible target policy before
committing. [CodeGPT v1.8.0 commit source](https://github.com/appleboy/CodeGPT/blob/v1.8.0/git/git.go#L134)

### Writes in another repository

When work needs writes to another repository, the lead first tells the user
which repository and work require access, how many new Session teammates are
needed, and their roles. The user creates the new Session teammates. Wait before
assigning writes there. After the teammates become available, verify their
destination checkout, applicable rules, roles, and readiness, then assign the
authorized writes and checks. Work in the current checkout may continue where
it has no dependency on the other repository. A confirmed issue there goes
through this same handoff before anyone edits it.

## Acceptance and portability checks

- **Documentation and plan placement.** The guide and starter prompt agree on
  the phase order, editor handoffs, and cross-repository write gate. Run
  `git diff --check`. For an untracked draft, inspect
  `git diff --no-index --check -- /dev/null "$draft"` for whitespace diagnostics.
  Check numbered naming, the `AGENTS.md` authoring reference, and design,
  implementation, and example comments on new or changed code structures and
  methods. Examples use placeholders for private paths and machine identities.
  At the planning stage, `git check-ignore -v -- "$plan"` identifies an ignore
  rule, `git ls-files -- "$plan"` returns no entry, and a neighboring
  specification remains visible. Test that conflicting policy goes to the lead.
- **Disposable portability fixture.** Use a disposable target checkout with
  its own applicable rules and a separately located copy of the guide. Include
  a path with spaces. Verify the supplied guide wins when readable, a readable
  local copy works when the supplied reference is unavailable, and a URL can
  supply the guide when local copies are unavailable. Exercise URL fallback
  with a fixture or controlled fetch. Verify that total lookup failure is
  reported before work starts and that target rules and working directory remain
  in effect for every guide source. An isolated Herdr Core run already exchanged
  READY, a bounded assignment, and a handback between stand-ins in a target path
  with spaces. It read the target rule files and a separate local guide, then
  fetched the canonical raw Markdown from the target. Real CLI profiles and the
  remaining guide resolution cases still require verification.
- **Workflow cases in the fixture.** Walk through a tiny edit and a non-tiny
  change. For both documents, test an initially clean review and a repair. An
  old digest or missing author re-review blocks either path. Author confirmation
  followed by reviewer confirmation on the latest digest releases the next
  phase. With identical candidate files, changing the base or deletion list
  changes the archive SHA-256. Confirm the temporary index excludes archive
  metadata, the reviewed tree matches the integration, and the commit gate
  requires target checks even when the commit tool skips hooks. Simulate a
  dependency on another repository. Verify that write assignments wait after
  the count and roles are reported, until the user's new Session teammates are
  verified.
- **Offline environment check.** From the target directory, run
  `"$herdr_source/scripts/check-env.zsh" codex` or its
  `codex --profile "$profile"` form. Use `claude` or `claude-k` for the
  corresponding installed configuration. Exercise a valid configuration and a
  missing required prerequisite with disposable profiles. Confirm exit status
  `0` for the valid case and `1` with a diagnostic for the missing prerequisite.
  Record any parser or configuration check that the helper says it skipped.
  Compare `command -v dart` in interactive zsh with
  `hc exec -- /bin/sh -c 'command -v dart'` for the observed Dart MCP `ENOENT`.
  Verify an optional MCP failure leaves independent work eligible. In scratch,
  exercise stale, shadowed, and equivalent-symlink helpers, a missing companion,
  Python fallback with missing `uv`, and `awk` available only on `PATH` or
  absent. Simulate a cleanup prompt and verify the useful check can proceed
  independently or be reported through a permitted alternative.
- **Checkpoint fixtures.** Verify same-checkout record, save, and restore,
  rejection of mismatched checkouts, and legacy saved-note restore. Exercise
  canonical casing, true non-Git directories, Git failures and timeouts,
  submodules, and separate worktrees. Check both `SessionStart` templates without
  a Herdr environment or helper, nested invocations without `HC_TERMINAL_ID`,
  and deliberate diagnostics for remote or unavailable peer checkouts. Walk
  through refusal of peer compaction when current hook and checkpoint proof is
  missing. Distinguish fixture results from real CLI hook coverage.
- **Authorized live Herdr smoke test.** Use verified, authorized sessions in
  the target space. Read the installed `hc --skill` and `herdr-app --skill`
  manuals. Check the required commands and the prepared-shell launch flags.
  Check `pwd -P`, `hc get -- "$lead"`, `hc get -- "$member"`,
  `herdr-app status`, and `herdr-app ls`. Exchange READY and one bounded
  assignment with a handback. Confirm the addresses, parent, foreground
  checkout, space, roles, and return path using the actual launch profiles.
  With narrow permissions, confirm both approved lookups and the send, and
  check that an unrelated target has no matching rule. Exercise reuse when two
  members run the same CLI, and confirm pending work stays assigned after an
  interrupted wait. In an untrusted disposable checkout, confirm that a startup
  trust dialog with null agent status is found by screen inspection, reported,
  and given no keys or resend, and that onboarding resumes only after the
  person clears it and delivery is verified. A live Codex probe already showed
  this dialog with null `hc` status. Check the note limit and current-session
  restore when authorized. With disposable telemetry inputs, verify labels are
  opt-in and the quota requires the five-hour usage field. If live opt-in
  coverage is authorized, verify the labels from a child launch and the Pixel HQ
  readout.
  Preserve unrelated sessions and layout.

Sandbox fixtures use disposable configuration and synthetic credentials. Live
checks use the permissions and profiles the user authorizes. Record the commands,
exit statuses, relevant tool versions, and snapshot digests. Report unavailable
runtime coverage as pending. Reserve additional live service checks for a
requirement that needs them, since `mcp list` can contact configured servers.
