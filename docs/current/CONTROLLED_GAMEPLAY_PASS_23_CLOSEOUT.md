# Controlled Gameplay Pass 23 Closeout

Date: 2026-07-09

Issues: #522-#531
Milestone: Simple Diver Game 06 `Objective And Run Structure`

## Decision

Pass 23 is complete.

The primary dive result now gives the player one compact reason to start another expedition:

```text
primary objective complete -> Next dive: Investigate lower-left relay
```

This remains a narrow objective-structure pass, not a quest log, map-scale expansion, save system, inventory/loadout system, economy pass, enemy pass, procedural system, or full productionization of the sketch map.

## Implemented Behavior

- `production_slice_01` remains the default preview and public Web map.
- Source maps may define `next_dive_objective_prompts`.
- `production_slice_01` defines `deep_cache_next_dive_prompt` for the existing `deep_cache_route_objective`.
- The completed primary-objective result panel appends `Next dive: Investigate lower-left relay`.
- Failed, incomplete, reset, and prompt-omitted paths preserve previous result behavior.
- Normal salvage, cargo, oxygen, hazard, banking, progression, connector, and reset semantics remain stable.

## Source And Runtime Decisions

- Prompt metadata is source-authored in the production-slice generator path and documented in the Pass 23 prompt contract.
- Runtime reads prompt metadata from `GreyboxWorld` and keeps display logic in the focused next-dive prompt helper.
- The pass intentionally avoids adding another connector merely because the lower-left connector exists.
- The prompt points toward the existing lower-left relay work so the run result has remembered-place direction without broad new systems.

## Verification

Implemented during the pass:

- Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_23_PLAN.md` under #522
- Source contract: `docs/current/CONTROLLED_GAMEPLAY_PASS_23_NEXT_DIVE_PROMPT_CONTRACT.md` under #523
- Map validation and source prompt authoring under #524-#525
- Runtime prompt display under #526
- Deterministic smoke: `--smoke-pass-23-next-dive-objective` under #527
- Focused capture command: `--capture-pass-23-next-dive-objective` under #528
- Public Web and visual verification: `docs/current/PASS_23_NEXT_DIVE_OBJECTIVE_VISUAL_WEB_VERIFICATION.md` under #530

Closeout verification:

```powershell
python tools/check_file_lengths.py
git diff --check
```

## Visual And Web Result

No production-slice accepted baseline changes were needed.

`python tools/manage_production_slice_baseline.py check-clean --all-slices` reported slices 01-04 clean during #530. The Pass 23 focused capture showed the completed result panel with the next-dive prompt; the generated PNG was review-only and was not committed.

The public Web preview deployed build `3d743bf96d8a74d60731da41f8e87970e3920cb8`; the preview checker confirmed matching metadata, canvas initialization at 1280x720 and 1920x1080, no failed requests, and no Godot errors.

## Stable Areas

Pass 23 intentionally kept these stable:

- default preview map selection
- terrain topology, collision, and camera tests
- accepted production-slice baselines
- player movement, facing, collision, and sprite behavior
- oxygen, cargo, hazard, banking, progression, connector, and reset rules
- existing primary objective completion and failure semantics except for the new success-only prompt line

## Remaining Gaps

- The next-dive prompt points to the lower-left relay, but the follow-through objective at that relay is not implemented yet.
- The connected slice work is still a compact proof, not a multi-area expedition with persistent cargo, oxygen, or objective state.
- The focused local headless capture command may time out before writing a PNG on this machine, consistent with existing tooling warnings.
- #52 and #53 remain deferred optional slice-03 polish unless slice-03 presentation becomes the selected goal.

## Next Recommendation

The next batch should stay in Milestone 06 and make the Pass 23 prompt pay off with one small follow-through objective at the lower-left relay or destination cache.

Recommended Pass 24 shape: source-author one lower-left relay follow-through cue, validate it, show compact runtime feedback when reached or completed, add deterministic smoke, add one focused capture, review visual impact, verify Web preview, and close out. Keep it tiny: no enemies, procedural generation, full inventory/loadouts, save files, broad economy, broad audio systems, full-map productionization, or broad art replacement.
