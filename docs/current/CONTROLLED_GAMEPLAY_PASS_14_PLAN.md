# Controlled Gameplay Pass 14 Plan

Date: 2026-07-08

Issue: #278 `Plan Controlled Gameplay Pass 14 around start-of-run objective cue`

## Decision

Controlled Gameplay Pass 14 should add one compact start-of-run objective cue for the existing `deep_cache_route_objective` on the default `production_slice_01` slice.

Selected behavior:

```text
When the run starts and the player is still at the boat/extraction area, show one compact objective line derived from the existing `route_objectives` metadata so the player sees the deep-cache retry target before leaving the boat.
```

This is not a new objective system. The cue should read from the existing `deep_cache_route_objective`, its `label`, and its `required_banked_targets`. Objective completion, result text, cargo, salvage, oxygen, hazard reset, and route outcome semantics remain the Pass 13 behavior.

## Target Experience

- The player starts at `surface_boat_entry` and can immediately see the current objective target before diving.
- The cue makes the existing deep-cache route objective understandable before the player has touched either required target.
- Once the player leaves the boat/extraction area, the cue can hide until normal Pass 13 progress text applies.
- Returning to extraction can show the cue again when the run is not complete and the objective still exists.
- The status overlay stays compact; no modal, tutorial panel, quest log, or objective-selection screen appears.
- Completing or failing the run still uses the existing Pass 13 objective result text.

## Meaningful-Change Filter

Pass 14 is worth doing only if it adds at least one of:

- clearer pre-dive intent for the already-authored deep-cache route
- a better reason to retry after a safe-route or incomplete-objective run
- deterministic proof that start-area objective text does not disturb cargo, salvage, oxygen, hazard, timed salvage, rest-pocket, route outcome, or result semantics
- a focused visual review state that shows the objective cue without changing terrain, map topology, assets, camera framing, or accepted baselines

If the work becomes a quest system, objective picker, economy, upgrade, inventory, enemy, save, procedural map, broad art replacement, or map-scale expansion, keep it out of this pass.

## Non-Goals

Pass 14 explicitly does not add:

- quest logs
- objective selection screens
- economy
- upgrades
- inventory
- enemies
- saves
- procedural generation
- broad art replacement
- map-scale expansion

## Planned Issue Batch

Recommended order:

1. #278 Plan Controlled Gameplay Pass 14 around start-of-run objective cue.
2. #279 Document Pass 14 objective cue source and text contract.
3. #280 Add Pass 14 objective cue metadata validation if needed.
4. #281 Implement compact Pass 14 start-of-run objective cue runtime.
5. #282 Add deterministic Pass 14 objective cue smoke coverage.
6. #283 Add focused Pass 14 objective cue review capture.
7. #284 Review Pass 14 visual impact and baseline decision.
8. #285 Verify public Web preview after Pass 14 objective cue.
9. #286 Add Pass 14 closeout and next-step evaluation.

Parallel split:

- After #278 lands, one agent can do #279 while another waits on #279 or takes only non-overlapping documentation/tooling work.
- #280 should follow #279 and should be skipped or closed with evidence if the source/text contract confirms no new source metadata is needed.
- #281 is the runtime gate for #282 and #283.
- #284, #285, and #286 are serial closeout work and should not be claimed early if doing so leaves another active agent without independent work.

Keep #52 and #53 deferred slice-03 polish unless slice-03 presentation becomes the selected goal.

## Source-Of-Truth Boundaries

Primary source:

```text
maps/production_slice_01.greybox.json
```

Current source metadata:

- objective id: `deep_cache_route_objective`
- route context: `deep_cache_commitment`
- label: `Deep cache route`
- required banked targets:
  - `salvage_lower_loop`
  - `salvage_deep_right_cache`
- start/extraction entity: `surface_boat_entry`

Preferred Pass 14 source rule:

```text
Do not add new map metadata unless #279/#280 proves the existing `route_objectives` record cannot define the cue contract cleanly.
```

The runtime should derive the cue from existing objective metadata and the player being in or near the boat/extraction area. Do not duplicate target coordinates, terrain topology, source marker rectangles, score values, oxygen values, cargo limits, or completion state in runtime UI code.

## Runtime And UI Boundaries

Use existing systems:

- `boat_spawn` / extraction checks
- `route_objectives` metadata
- Pass 13 objective progress/result feedback
- compact status overlay
- cargo, salvage, oxygen, hazard, timed-salvage, rest-pocket, return-pressure, and route-outcome state

Recommended display contract for #279:

```text
Objective: Deep cache route 0/2
```

That exact text can be refined in #279, but the behavior should stay compact: one line in the existing overlay while the player is at the boat/extraction area and the objective exists.

The cue must not:

- change objective completion rules
- change salvage score or oxygen bonus
- change cargo capacity
- collect, hold, restore, or bank salvage
- change timed-salvage duration, progress, or cancel behavior
- change hazard warning, penalty, reset, or tint behavior
- change oxygen rest-pocket refill, cap, or feedback
- change route outcome selection
- complete a run away from extraction
- create a quest log, objective-selection UI, persistent objective history, economy, upgrades, inventory, enemies, saves, procedural generation, or a broad visual pass

## Validation And Smoke Plan

Preserve existing coverage:

```powershell
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
python tools/check_map_parity.py maps/production_slice_01.greybox.json
--smoke-pass-13-route-commitment
--smoke-safe-deep-route-choice
--smoke-timed-salvage
--smoke-cargo-capacity
--smoke-hazard-pressure
--smoke-pass-12-oxygen-rest-pressure
```

Pass 14 should add one focused smoke, for example:

```text
--smoke-pass-14-objective-cue
```

The smoke should verify:

- the cue is visible at run start while the player is in or near `surface_boat_entry`
- the cue is derived from `deep_cache_route_objective` source metadata
- the cue disappears, yields, or remains compact according to the #279 contract after leaving the boat area
- normal Pass 13 progress text still appears after collecting or banking required targets
- safe-route completion still reports objective incomplete
- banking both required targets still reports objective complete
- hazard reset and oxygen failure do not create persistent objective history
- cargo, timed salvage, oxygen rest, route outcome, and result text remain stable

## Visual And Capture Plan

Add one focused capture after runtime lands. It should frame:

- the player at or near the boat/extraction area at the start of a run
- the compact start-of-run objective cue in the existing overlay
- unchanged boat, player, terrain, salvage, hazards, rest pocket, and route visuals outside the cue

Do not accept broad baseline changes. Normal production-slice captures should remain unchanged unless the cue is intentionally visible in that capture. Reference slices 02-04 should stay unchanged.

## Deferred Work

Keep these out of Pass 14:

- #52 and #53 slice-03 camera/topology polish
- full-map productionization
- map-scale expansion
- additional route objectives
- objective selection screens
- quest logs, achievements, persistent history, or save systems
- economy, upgrades, inventory screens, loadouts, enemies, or procedural generation
- broad visual replacement or new asset generation
- map topology changes
- new interaction families beyond the selected start-of-run cue

## Exit Criteria

Pass 14 is done when:

- the source/text contract documents exact cue visibility and text rules
- validation either confirms no new source metadata is needed or guards any narrowly added metadata
- runtime shows the cue only in the planned start/extraction context
- deterministic smoke protects cue visibility and existing objective semantics
- a focused capture exists for visual review
- visual review accepts only intentional cue differences or records no baseline change
- public Web preview is verified for the deployed cue state
- closeout records what changed, what stayed stable, and the recommended next direction
