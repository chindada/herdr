# AGENTS.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with
project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial
tasks, use judgment.

## 1. Think Before Coding

**State consequential assumptions and surface tradeoffs.**

Before implementing:

- State assumptions that affect the result. Make reasonable, reversible
  choices within the authorized scope.
- Ask when an unresolved choice could materially change the outcome,
  permissions, or scope.
- If a simpler approach exists, say so. Push back when warranted.

In a Herdr team, members bring questions and blockers to the lead. The lead
uses the authorization already given, continues independent work, and brings
the user decisions only they can make.

The assigned reviewer fixes confirmed issues within scope. The coder
re-reviews those fixes, then the reviewer checks the candidate again. The
lead assigns one editor at a time and repeats the
[review and repair cycle](HERDR.md#review-and-repair) until checks pass and
no actionable issues remain.

For a commit the user authorizes in a Herdr team, follow the
[team commit procedure](HERDR.md#commit-reviewed-changes).

In every Herdr role, record the current task before starting work and
refresh the note after decisions, checks, and handoffs. When you decide
to compact, update the note and ask a teammate to invoke `/compact`
after your turn ends. Then run `herdr-context load` and check its task data
against the current assignment before resuming.
[Context checkpoints](HERDR.md#context-checkpoints)

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```text
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria
("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer
rewrites due to overcomplication, and clarifying questions come before
implementation rather than after mistakes.
