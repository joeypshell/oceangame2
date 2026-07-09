# Controlled Gameplay Pass 26 Result Presentation Contract

Date: 2026-07-09

Milestone: Simple Diver Game 07 `Presentation And Game Feel`

Issues: #583-#587

## Decision

Pass 26 result presentation is a runtime/UI contract only.

The pass should make completed and failed run results easier to read without changing map source, terrain, collision, salvage placement, cargo, oxygen, connector, upgrade, objective, or reset semantics.

## Result Panel States

The result panel is visible only when the current expedition is complete or failed.

When the run is still active:

- the result panel stays hidden
- result label text is empty
- normal status-overlay feedback remains responsible for in-run prompts

When the run is complete:

- the result title is `Expedition complete`
- completion-only objective/follow-through lines may appear
- score, progression, oxygen, and retry lines remain visible

When the run fails:

- the result title is `Expedition failed`
- completion-only objective/follow-through/final-dive lines must be suppressed
- stale success text from the previous run must not appear
- oxygen should read as depleted
- retry affordance remains visible

## Target Result-Line Ordering

Pass 26 should use this hierarchy for completed runs:

1. Expedition outcome title.
2. Primary objective outcome.
3. Relay follow-through outcome, if completed.
4. Final-dive seed outcome, if completed.
5. Route outcome or route-choice summary.
6. Score summary.
7. Salvage/cargo summary.
8. Session progression and wallet summary.
9. Oxygen result.
10. Retry prompt.

This is a presentation hierarchy, not a new scoring or objective rule. Existing text may be reused, but completion/payoff lines should be easier to see than bookkeeping lines.

## Required Lines And Conditions

- Title: always present when the panel is visible.
- Primary objective result: present only when the route/objective helper has a non-empty result.
- Next-dive prompt: allowed only when the existing next-dive helper says it should display.
- Relay follow-through result: only on completed, non-failed runs with completed relay metadata.
- Final-dive result: only on completed, non-failed runs with completed final-dive seed metadata.
- Score summary: always present when the panel is visible.
- Salvage score: should remain present unless folded into a clearer score summary.
- Best score: should remain visible unless the implementation documents an equivalent compact replacement.
- Salvage count: should remain visible unless folded into a clearer salvage/cargo summary.
- Progression/wallet summary: should remain present because session upgrades affect retry motivation.
- Oxygen: always present; completed runs show remaining oxygen, failed runs show depletion.
- Retry prompt: present after the result details and kept visually easy to find.

## Optional Completion Cue

Issue #585 may add one compact completion cue for the final-dive signal.

The cue must:

- reuse existing overlay/result-presentation patterns
- avoid new art, broad audio, or a new HUD system
- appear only for the completed final-dive signal state
- clear on reset or failed runs
- avoid changing objective, cargo, oxygen, connector, or banking semantics

## Reset And Failure Rules

Reset, failure, and map reload must clear presentation-only state that could imply completed objectives.

Specifically:

- failed runs must not display `Final dive signal found`
- failed runs must not display relay completion text unless a future contract explicitly allows partial failure summaries
- reset must return the result panel to hidden/empty while a run is active
- maps without final-dive seed metadata must keep previous behavior
- maps without primary-objective metadata must keep their existing all-salvage completion behavior

## Source-Of-Truth Boundaries

Pass 26 must not add or reinterpret map topology.

Allowed:

- result panel ordering
- compact text grouping
- presentation-only helper extraction
- deterministic smoke/capture setup for the result state

Not allowed:

- new source map fields
- terrain, collision, or reachability edits
- salvage, hazard, connector, or objective placement changes
- new inventory/loadout, save, enemy, economy, or full-map systems
- broad baseline acceptance

## Smoke Expectations

The Pass 26 smoke should verify at minimum:

- completed-run title and objective/payoff hierarchy
- final-dive result text appears only after the completed seed state
- failed runs suppress completion-only final-dive and relay text
- score/progression, oxygen, and retry text remain present
- reset clears presentation-only completion state

## Capture Expectations

The focused Pass 26 capture should frame the completed-result state after the existing objective chain.

It should not accept baselines. Visual review and Web preview verification remain separate issues.
