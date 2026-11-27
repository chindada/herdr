# Independent Herdr review rounds

Herdr teams need a review procedure that produces two independent verdicts on
the same final snapshot. The existing repair loop allows a reviewer to edit
before another reviewer sees the candidate, and its one-reviewer completion
rule leaves an extra gate for commits. Apply the same review and repair
procedure to specifications, plans, and implementation candidates.

## Scope

Update the review procedure and the specification, plan, and commit gates in
`HERDR.md`, along with affected roster, onboarding, and report language.
Add the lead's delegation boundary to the team operation guidance in
`HERDR.md`.
Replace the superseded procedure in `AGENTS.md` with a reference to the guide
and keep its single-editor instruction. Align the affected reviewer passages in
`codex/README.md` and `claude/README.md` with read-only reviews and the
separate editor assignment. The changes are confined to documentation. Keep the
existing roster authority, snapshot format, report fields, and commit
authorization procedure. The new spec supersedes the review procedure in the
historical workflow spec.

## Approaches

- Keep reviewer-led repair and recruit additional independent reviewers when
  needed. This preserves direct fixes, but an editor can consume an available
  reviewer and force a new handoff before the final gate.
- Have both reviewers report independently and give the original author one
  repair assignment. This adds an editor handoff and keeps both reviewers
  eligible through ordinary repair rounds. Use this approach.
- Track reviewer eligibility separately for every surviving change and combine
  partial reviews. This can preserve a reviewer's eligibility for changes they
  did not write, but requires provenance and coverage tracking across partial
  verdicts. Use two eligible whole-candidate verdicts for the team gate.

## Review and repair

1. The lead assigns at least two eligible nonauthor reviewers from the
   authorized roster and freezes the specification, plan, and implementation
   separately. If fewer than two eligible reviewers are available, hold the
   gate and request authorization for any additional member needed. Both
   reviewers independently inspect the same read-only archive
   and cite its SHA-256. They report to the lead before seeing each other's
   findings. When both CLIs are available, keep at least one reviewer on a CLI
   different from the author's.
2. The lead deduplicates findings, resolves conflicts against the accepted
   scope, and gives one editor a consolidated list. Record each disposition
   with evidence and return disputed dispositions to their reporters for
   resolution. Each accepted item has a reference, supporting evidence, the
   expected behavior, and a way to check the repair. Route a requirements
   change back through the specification and any affected plan review.
3. The original author is the default editor. If another editor is needed,
   prefer someone outside the reviewer pair. Only the assigned editor writes.
   Before editing, the editor compares assigned paths, contents, and
   executable bits with the frozen payload and verifies that declared
   deletions are absent. A mismatch stops the edit. The editor returns the
   input digest, repairs, and check results. The lead freezes the result and
   the original author confirms the repairs and checks for regressions on
   that new digest. Return any issue found in the author check to the lead
   for resolution before dispatching the reviewer round.
4. Both reviewers independently check the new frozen candidate. Repeat the
   cycle for any actionable in-scope finding. Reuse check evidence only when
   relevant inputs and the execution environment still match. If the digest
   stays unchanged, preserve clean verdicts and get confirmation on any
   remaining disputed finding from its reporter. A clean initial round needs
   no duplicate reviewer verdicts if the author confirms that unchanged
   digest and required checks pass.

The author confirmation and the two eligible reviewer verdicts all cite the
final SHA-256. If any reviewer-authored change survives in the candidate,
count an independent replacement for that reviewer's whole-candidate verdict.
This includes content changes, deletions, and executable-bit changes. Record
the reviewer-authored changes. Applying that reviewer's patch through
another editor retains its authorship. Reporting a defect or expected behavior
for the editor to implement independently preserves reviewer eligibility.

## Lead delegation

The lead preserves its context and attention for coordination. It delegates
drafting and repairing specifications and plans, and implementing and
repairing changes, to authorized coder sessions. The lead owns scoping and
acceptance boundaries, assignments and the single-editor handoff,
consolidation of independent reviewer findings, readiness and checkpoint
verification, freezing artifacts, and the authorized commit and delivery. The
lead may scope, verify, and coordinate without authoring the deliverables.

The original author remains the default assigned coder for repairs and gives
the author confirmation. Each assigned coder maintains its own checkpoint note
under the existing checkpoint procedure. If a suitable coder is unavailable,
use the existing roster and authorization rules.

A tiny change keeps the guide's existing path without a separate formal
specification or plan where the guide permits it. The lead still records its
confined scope and direct check, verifies that an authorized coder is
suitable, and assigns that coder.

This delegation governs new work under the revised guide. Artifacts already
accepted during this transition keep their accepted status.

## Commit verification

Keep the existing per-change requirement for two independent nonauthor
reviews. Require the completed review gate with author confirmation and two
eligible whole-candidate verdicts on the final archive and passing checks.
Keep the separate authorization and the base,
deletion, and staged-tree checks. The official Git documentation describes
`git read-tree` loading a tree into the index without changing working files
when invoked without working-tree update flags, and `git write-tree` deriving
a tree from the current index. Context7 served the current upstream manual
when asked for 2.56.1. The lead resolves Homebrew Git 2.56.1 and the direct
Core shell resolves Apple Git 2.54.0. The existing commands fit both tool
routes. [git-read-tree](https://github.com/git/htmldocs/blob/gh-pages/git-read-tree.adoc)
[git-write-tree](https://github.com/git/htmldocs/blob/gh-pages/git-write-tree.adoc)

## Acceptance

- A clean candidate can finish with author confirmation, passing required
  checks, and two independent verdicts on its unchanged digest.
- Overlapping or conflicting findings yield one checked repair assignment
  to the sole editor. After an edit, the author confirmation and both
  independent verdicts identify the replacement digest.
- A one-byte content mismatch or a declared deletion still present in the
  assigned paths stops the edit before any repair.
- A reviewer who authored any surviving change, including a deletion or
  executable-bit change, must be replaced for the whole-candidate verdict.
  A reviewer who only reported an issue remains eligible when the editor
  authors the repair independently. One eligible reviewer leaves the gate
  pending.
- If a finding is resolved by the reporter on an unchanged digest, preserve
  any existing clean verdict on that digest. If the author finds a regression,
  resolve it before asking the reviewers to confirm the repaired candidate.
- The specification and plan are frozen and reviewed separately before
  implementation. An outstanding actionable finding, required check, or
  eligible verdict holds each gate.
- The commit procedure references the final dual-review gate and preserves
  the authorization, exact staged-tree checks, and CodeGPT command.
- For new work under the revised guide, every frozen specification, plan,
  and implementation digest traces to an assigned coder's handback. The
  lead's records show scoping, assignments,
  consolidated findings, freezing, verification, commit, and delivery, with
  no deliverable content authored by the lead.
- A repair after consolidated findings goes to the original author by
  default, and that author confirms the refrozen digest. Each assigned coder
  records its own checkpoint note at the start of the task and refreshes it
  after each handoff.
- When no suitable coder is available, the guide routes the lead to the
  existing roster and authorization rules and adds no new tooling or settings.
- Tracing a small, confined edit through the tiny-change path shows the lead
  recording its scope and direct check, verifying a suitable authorized coder,
  and assigning that coder, with no separate formal specification or plan.
- Active team instructions point to one procedure. Local Markdown links and
  anchors resolve, `git diff --check` passes, and the reviewed plan is ignored
  and untracked.
