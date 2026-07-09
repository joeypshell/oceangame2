# Controlled Gameplay Pass 26 Plan

Date: 2026-07-09

Milestone: Simple Diver Game 07 `Presentation And Game Feel`

Issues: #582-#591

## Decision

Pass 26 will improve the clarity and feel of the existing completed-run result moment.

Pass 25 completed the compact objective chain:

```text
Deep cache complete -> lower-left relay investigated -> Final dive signal found
```

The next useful step is not another objective system or map expansion. It is a small presentation pass that makes the current run result read like a payoff: what the player completed, what changed, what score/progression they earned, and what they can do next.

## Target Experience

- A completed run should make the primary objective outcome visually and textually obvious.
- Follow-through text should read in a stable order: objective, relay/final-dive progress, score/progression, oxygen, retry prompt.
- Failed runs should remain concise and should not show stale completion or final-dive text.
- The final-dive seed should feel like a compact capstone signal, not a hidden implementation detail.
- The pass may add one small feedback cue if it supports that result moment.

## Meaningful-Change Filter

This pass should create at least one of these player-facing values:

- clearer payoff for finishing the current objective chain
- stronger confidence about whether the run succeeded or failed
- more readable next-step motivation after the final-dive seed
- more stable presentation before later mood, sound, or visual polish

If a proposed change only adds labels, debug text, or broad UI architecture, keep it out of this pass.

## Planned Issue Batch

1. #582 Plan Controlled Gameplay Pass 26 around result presentation polish.
2. #583 Document Pass 26 objective/result presentation contract.
3. #584 Implement clearer objective result hierarchy for completed runs.
4. #585 Add compact completion feedback cue for final-dive signal.
5. #586 Add deterministic smoke for Pass 26 result presentation ordering.
6. #587 Add focused Pass 26 result presentation review capture.
7. #588 Review Pass 26 visual impact and baseline decision.
8. #589 Verify public Web preview after Pass 26 presentation polish.
9. #590 Add Pass 26 closeout and Milestone 07 next-step evaluation.
10. #591 Audit Milestone 07 release-readiness gaps after Pass 26.

## Source-Of-Truth Boundaries

- Do not change map topology, collision, route reachability, or authored salvage placement.
- Do not hand-tune Godot scene geometry.
- Keep `production_slice_01` as the default preview map.
- Treat Pass 25 objective/final-dive metadata as existing source state.
- Do not add new objective metadata unless a later issue explicitly requires it.

## Runtime And UI Boundaries

- Preserve salvage, cargo, oxygen, hazard, banking, connector, progression, and reset semantics.
- Keep result presentation compact enough for the existing overlay scale.
- Prefer focused helper code over growing `scripts/main/main.gd`.
- The result hierarchy should be deterministic and smoke-covered.
- The optional completion cue should reuse existing overlay/result patterns; it is not a broad HUD redesign.

## Validation And Smoke Plan

Smoke coverage should protect:

- successful completed-run ordering
- failure-state suppression of completion-only lines
- primary objective, relay follow-through, and final-dive result text hierarchy
- score/progression and oxygen lines remaining present
- retry prompt remaining last or otherwise clearly separated

No new map validator behavior is expected unless implementation changes the source contract, which this plan does not recommend.

## Visual And Capture Plan

- Add one focused review capture for the Pass 26 completed-result state.
- Regenerate only affected captures.
- Compare accepted production-slice baselines before accepting any visual differences.
- Accept only intentional presentation differences.
- Do not accept unrelated terrain, player, boat, prop, camera, or map drift.

## Non-Goals

- No new maps.
- No enemies.
- No inventory or loadout systems.
- No save-heavy progression.
- No procedural generation.
- No broad economy work.
- No broad audio, music, or ambience pass.
- No broad art replacement.
- No full-map productionization.
- No slice-03 polish unless #52/#53 become the selected goal.

## Exit Criteria

- The objective/result presentation contract is documented.
- Completed and failed result states have deterministic ordering.
- Runtime presentation changes are smoke-covered.
- A focused capture verifies the player-facing result moment.
- Visual review and public Web verification are recorded.
- Closeout states whether Milestone 07 should continue with game-feel polish or shift toward release-readiness gaps.
