# Marl Growth Journey Integration

Issue: [#1395](https://github.com/joeypshell/oceangame2/issues/1395).
Date: 2026-09-20. Tested code commit: `be60f643487600d51308d6e2503171f8e20162bd`.
Base runtime: `680d147` (#1394). Technical evidence only, not visual acceptance
or an owner verdict. [Contract](LIVING_EXPEDITION_07_SOURCE_STATE_CONTRACT.md).

## Connected Journey

`smoke_living_expedition_07_journey.gd` launches actual `Main.tscn` through the
unadapted refuge checkpoint. It reuses `marl_review_driver.gd` for collision-driven
approach/dig, live eel lures, desktop numbered commands, and actual mobile touch
events. It does not seed a successful event, committed memory, or adaptation.

1. Deny unadapted Pin; pickup/identification/time/live threat alone earn nothing.
2. Dig the refuge, face the live threat, and shelter the group to earn pending
   Guarded the Nest. Oxygen failure locks swimming and loses pending/cargo.
3. Retry, earn the event again with full cargo, and return to the canonical boat.
   Both cargo and the exact individual's memory commit; repeated callbacks do not
   duplicate the memory or select growth.
4. Enter night with real input, defer, then advance the day. The refuge remains
   sheltered, but unadapted Marl still has no Pin or changed fins on the next dive.
5. Return, deliberately select Root Claws on a later night, advance, and launch a
   fresh sortie. The same identity now shows permanent hooked-fin anatomy.
6. Lure the unchanged eel low, dispatch Ground Pin with mobile controls, retreat
   through the physical opening, and observe timed release/cooldown. Recall
   restores clear, separated follow; the eel remains alive and its cache unclaimed.
7. Fail/retry/reload after commitment: growth persists, transient hold/cooldown
   clear, source map and diver equipment capabilities remain unchanged.

The checkpoint starts on Day 4; the deferral branch deliberately reaches Day 6.
Travel between source-authored field/boat boundaries is elided, not presented as
a continuous route playthrough. Field stepping advances real oxygen/daylight
owners; deterministic choreography asserts no ignored hostile contact. Cargo
is filled through normal collection owners as a capacity fixture, not collected
by swimming to each item. Whole-simulation pause also has a live Main probe.

## Coverage Ownership

| Boundary | Existing checks retained in the release suite |
| --- | --- |
| Source, seeds, geography | LE07 contract and production-source Python fixtures: guaranteed records outside random candidates, repeatability, full-body placement, return reachability, unchanged terrain/access collections; progression graph and all map validators/parity |
| Wrong identity and false positives | `smoke_marl_refuge`: ordinary threat/idle, interrupted threat, quiet/dead eel, Recall/abandon, wrong or uncommitted individual, identity change; LE05 journey now explicitly rejects refuge memory after ordinary titanium dig/pickup/bank |
| Durable attribution and save failure | `smoke_marl_memory_night`: wrong boat/map, captured Marl identity after active selection changes, duplicate callbacks, atomic save failure/retry, isolated disk reload, day projection, defer/confirm and other individuals unchanged |
| Physical hold lifecycle | `smoke_marl_ground_pin`: high/blocked targets, equipment/path denial, lost anchor/contact/LOS, Recall, cooldown, no stacking/refresh, timeout, release before weapon hit/defeat, failure and both teardown orders |
| Actual controls and bodies | Three LE07 Main checkpoint checks: clear spawns, four-way movement, desktop commands, real touch BOND/TOOL/USE, hotbar ownership, recovery; tactical-pause regression freezes actors and survival clocks |
| Earlier relationships | Silt Hound rescue/follow, ordinary excavation/guidance, LE05 journey/checkpoint; retained Kite/Mica, LE06 Anchor/Guardian nursery journeys and profile checks |
| Diver authority | Retained current/fins, light, pressure, rebreather, cutter, boat, weapon, hazard, oxygen and day regressions; companion current/path checks and growth capability-invariance assertion |

The new journey covers actual Main map reload using its isolated in-memory
profile. Durable disk persistence belongs to the existing memory/night test's
isolated `user://oceangame2_marl_memory_night_smoke.json`, cleaned by that test.
No check reads/writes the normal player's progress to manufacture success.

## Commands And Results

```powershell
$godot = 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe'
& $godot --headless --path . --fixed-fps 60 --script scripts/main/smoke/smoke_living_expedition_07_journey.gd -- --smoke-living-expedition-07 --review-checkpoint=living_expedition_07_refuge --show-mobile-controls
python tools/run_release_candidate_validation.py --require-godot
python tools/check_file_lengths.py
git diff --check
```

PASS: all 129 integration gates at the tested code commit, with zero failures or
skipped Godot gates. The runner rejects Godot `SCRIPT ERROR` / `ERROR:` even with
exit zero. File-length and whitespace checks pass; edited docs' local link
targets exist. The full suite ran once. The subsequent evidence/handoff changes
are documentation-only and do not require another complete run.

The new journey is 247 lines and its release registration helper is 38 lines.
Existing reported exceptions remain unchanged: `main.gd` 3013 (temporary debt),
`greybox_world.gd` 1357 and companion control 514 (cohesive owners), plus generated
map/graph data. No new file-length exception was added.

Diagnostics report Marl/event/memory/adaptation IDs, pending versus committed
state, hostile phase/health, hold/cooldown, cargo, health, oxygen and daylight.
The journey runs in regional Smoke CI; focused owners/checkpoints remain in core
CI, and source/graph fixtures remain in Source/Progression CI. No checks removed.

## Remaining Gates

#1396 owns affected desktop/mobile visual review, baseline comparison, and exact
deployed Web verification. #1397 requires the owner's growth/attachment verdict.
No captures, assets, map data, accepted baselines, or gameplay rules change here.
LE06 `16300a9` remains the latest owner-accepted Web runtime; #52/#53, Vein
Whiskers, release/legacy, a fourth species, and broad combat remain deferred.
