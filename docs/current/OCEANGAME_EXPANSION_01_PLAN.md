# OceanGame Expansion 01: Anomaly Survey Foundation

Date: 2026-07-09

Issues: #662-#671
Milestone: OceanGame Expansion 01 `Anomaly Survey Foundation`

## Decision

Implement one complete anomaly-survey journey on top of the Simple Diver Game 08 release candidate:

```text
final-dive lead -> unlock scanner at boat -> travel slice 01 -> 04 -> 02
-> survey one anomaly -> return slice 02 -> 04 -> 01
-> commit one discovery at the boat
```

This pass proves curiosity, remembered-route progress, preparation, time/oxygen pressure, and a risky return without adding a general inventory, crafting, save, fauna, or seamless-world system.

## Target Experience

- The completed `lower_left_final_dive_signal` makes the anomaly follow-up available.
- The slice-01 boat offers one always-equipped profile capability: `survey_scanner_1`.
- The player revisits slice 04, follows a new source-authored link into slice 02, and finds one authored anomaly.
- Staying near the anomaly advances a continuous survey while oxygen drains; leaving range cancels partial progress.
- Completion creates one pending discovery and no cargo or direct score.
- The player must return through slice 04 to the canonical slice-01 boat to commit the discovery.
- Reset, hazard restoration, or oxygen failure clears uncommitted discovery, while a committed discovery remains durable.

## Scanner Affordability

Lock `survey_scanner_1` to a cost of `300` wallet.

#815 supersedes the original score-funded fins route: `propulsion_fins` now uses guaranteed pre-eel titanium/rubber ingredients and spends no wallet. The slice-04 destination cache still pays the 300 needed for the scanner on the next boat return without grinding.

Rules:

- Offer the unlock only at the canonical slice-01 boat after the final-dive lead is available.
- Deduct 300 exactly once when the capability is not already unlocked.
- An already-unlocked profile never pays again.
- Insufficient funds changes no wallet, capability, objective, or expedition state.
- Wallet remains session-only; the scanner capability and completed discovery belong to the minimal profile owner.

## Source-Of-Truth Boundaries

- `tools/create_production_slice_04_map.py` owns the forward connector source.
- `tools/create_production_slice_02_map.py` owns the return connector and anomaly target source.
- Generated slice JSON remains committed source output; Godot scenes do not own connector rectangles, target placement, terrain, or collision.
- `docs/MAP_SPEC.md` and `tools/validate_greybox_map.py` define and validate fields before generator authoring.
- Existing terrain topology remains unchanged unless implementation reproduces a separate reachability blocker.
- Regenerate only affected JSON, SVG previews, review artifacts, and focused captures.

## State Boundaries

- Map-leg state keeps current oxygen, cargo, salvage, hazards, objectives, interactions, and reset/load behavior.
- Session state keeps current wallet, upgrades, opened progression containers, and best scores.
- One focused expedition owner carries a single pending discovery across connectors.
- One focused profile owner stores schema version, unlocked capability IDs, and completed discovery IDs.
- `R`, hazard restoration, and oxygen failure clear partial survey and pending discovery.
- Slice-01 boat return commits a pending discovery once; repeat surveys or returns cannot duplicate it.
- No arbitrary world state, salvage depletion, wallet, oxygen, cargo, or hazard position becomes persistent.

## Runtime And UI Boundaries

- `main.gd` coordinates focused owners and must have a net line reduction before scanner/profile behavior lands.
- `greybox_world.gd` delegates world queries and must have a net line reduction before survey queries land.
- New progression, profile, expedition, survey, smoke, and capture owners stay below 500 lines.
- Existing near-limit smoke helpers and the 500-line capture controller are closed to expansion additions.
- Survey is a dedicated non-salvage interaction; instant, timed, and pry salvage behavior stays unchanged.
- Feedback stays compact in the existing overlay/result hierarchy: scanner required/unlocked, survey progress/interrupted/completed, return to boat, and discovery committed.
- Do not add inventory, loadout, journal, research, scanner viewport, or crafting UI.

## Planned Issue Order

1. #662 records this implementation plan and exact affordability/state/source decisions.
2. #663 extracts progression transaction and presentation wrappers from `main.gd` with no behavior change.
3. #664 extracts world query/path helpers from `greybox_world.gd` with no behavior change.
4. #665 adds the anomaly survey source contract and validator coverage.
5. #666 adds focused profile capability and expedition discovery state owners.
6. #667 authors bidirectional slice-04/slice-02 connectors and one slice-02 anomaly through generators.
7. #668 implements scanner unlock, survey progress, pending return, and boat commit behavior.
8. #669 adds one deterministic complete-journey smoke and CI/release-runner coverage.
9. #670 adds focused survey/commit captures and records the visual baseline decision.
10. #671 verifies the deployed Web commit and closes this milestone with the next-step decision.

Dependencies:

- #663 and #664 are no-behavior growth gates.
- #665 may follow this plan independently, but #667 waits for #664 and #665.
- #666 waits for #663; #668 waits for #663-#667.
- #669 waits for runtime; #670 waits for deterministic smoke; #671 waits for visual review.

## Validation Plan

Keep all release-candidate gates green. Add focused checks for:

- scanner offer gating, 300-wallet payment, insufficient funds, and idempotence
- valid anomaly/connector schema plus negative validator cases
- bidirectional connector resolution, non-solid placement, reachability, and terrain/collision parity
- survey no-instant-completion, progress, leave-range cancel, oxygen drain, no-cargo completion, and duplicate prevention
- pending discovery survival across connectors
- reset, hazard, and oxygen-failure cleanup
- canonical boat commit exactly once and completed-profile reload
- unchanged instant/timed/pry salvage, progression, connector, and release-journey behavior

Required regression floor before closeout:

```powershell
python tools/run_release_candidate_validation.py
python tools/check_file_lengths.py
git diff --check
```

## Capture And Web Plan

- Add focused captures under a new anomaly-survey capture owner, not `capture_controller.gd`.
- Frame one meaningful partial survey state and one returned/committed discovery result.
- Compare affected current captures against accepted baselines before any acceptance.
- Reject unrelated terrain, collision, camera, diver, boat/relay, prop, route, or UI drift.
- Do not commit `.import` sidecars, exports, local profiles, or browser verification screenshots.
- Verify the public preview with external build metadata, both supported viewport checks, no failed requests, and no Godot `SCRIPT ERROR` or `ERROR:` lines.

## Deferred Work

- Territorial eel implementation remains Phase B until this journey closes deterministically.
- #52/#53 and slice-03 integration remain deferred.
- Additional tools, anomaly targets, destinations, connectors, discoveries, fauna, and resources remain deferred.
- Inventory/crafting, persistent wallet/economy, base building, vehicles, combat, ecosystem AI, procedural generation, broad biomes, full-map productionization, and broad art/audio replacement remain out of scope.

## Exit Criteria

- The final-dive lead points to a playable scanner-backed follow-up.
- The scanner is affordable from the existing journey, purchased once, profile-owned, and readable.
- Slice-04/slice-02 travel is source-authored, bidirectional, reachable, and parity-clean.
- One survey creates pending discovery without cargo or score and remains under oxygen/route pressure.
- Failure cleanup, connector preservation, canonical return, exact-once commit, and completed reload are deterministic.
- The full release-candidate runner and focused expansion smoke pass.
- Focused captures communicate survey and return payoff without unrelated baseline drift.
- The public Web preview serves the intended closeout commit cleanly.
- Closeout explicitly chooses Phase B territorial fauna, another bounded discovery step, or a pause.
