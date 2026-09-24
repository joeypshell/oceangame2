# Living Expedition 07 Review

Issue #1394 adds local presentation/checkpoint evidence, not visual baseline
acceptance or an owner GO. [Integrated evidence](../LIVING_EXPEDITION_07_INTEGRATED_VERIFICATION.md)
is recorded under #1395. [Visual](../LIVING_EXPEDITION_07_VISUAL_DECISION.md) and
[exact-Web evidence](../LIVING_EXPEDITION_07_WEB_VERIFICATION.md) under #1396 are
recorded at `5819f1d`. [#1397 closeout](../LIVING_EXPEDITION_07_CLOSEOUT.md)
records owner GO on corrected runtime `7a78592`. Subsequent
#1405 fixes WebGL health-bar warnings; #1408 corrects the unsafe field arrival
and adds a live, delayed-input regression. Use the steps below on the current build.

## Isolated Starts

Run from the clean current worktree, not the stale primary checkout:

```powershell
$godot = 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe'
& $godot --path . -- --review-checkpoint=living_expedition_07_refuge
& $godot --path . -- --review-checkpoint=living_expedition_07_night
& $godot --path . -- --review-checkpoint=living_expedition_07_pin
```

- `refuge`: Day 4, unadapted Marl at the source-authored approach west of the
  arch, outside the eel's warning range. `B` offers `2 Excavate` immediately,
  including after reading. Close with `B`, swim a short distance right until
  the eel warns, then press `B`, `2`. When it lunges, swim left back past your
  starting spot, staying near the arch. Watch the scallops retreat and the
  pending boat-return message appear. Excavating before drawing the eel is a
  quiet rescue, not Guarded the Nest; do not use it for this memory review.
- `night`: Day 4 at the canonical boat with only Guarded the Nest secured.
  Press `N`. `B` switches Root Claws / Not tonight; `Space` confirms deliberately.
- `pin`: Day 5, adapted Marl at the same safe field start. Swim right to draw
  the eel's warning. Let the first lunge bring
  the eel down, swim just above the floor, then press `B` and choose Ground Pin
  when enabled. Dodge aside after the next warning. During the grip, strike with
  the selected Shock Prod or retreat. A strike releases the grip before damage.

Mobile uses sequential `BOND`, `TOOL`, `USE`; no held chord. Add
`--show-mobile-controls` locally to exercise the real touch buttons. BOND pauses
the whole simulation. The diver keeps its tools; Marl is not mounted.

All three use actual `Main.tscn`, source-owned map placement, existing project
transactions, empty cargo, and Marl selected. Equipment includes Fins, Dive
Light, Cutter, Shock Prod, and source-declared recipe prerequisites. Field dives
retain the normal oxygen budget. These are isolated shortcuts, not a seeded
normal save or a substitute for the full boat/night journey test.

Only the two LE07 field checkpoints offset their camera away from the debug
panel, preserving the existing 0.7 zoom. Normal play, older checkpoints, terrain,
and broad HUD layout are unchanged. Review offsets live/die with the player.

Use the [three verified Web starts](../LIVING_EXPEDITION_07_WEB_VERIFICATION.md#short-owner-review)
for refuge, night, and Pin instead of replaying the equipment chain. The review
query isolates state; it does not pin GitHub Pages to an immutable old build.
Serve Godot Web exports over HTTP; do not open exported HTML with `file://`.

## Focused Checks

```powershell
foreach ($checkpoint in 'refuge', 'night', 'pin') {
  & $godot --headless --path . --fixed-fps 60 --script scripts/main/smoke/smoke_living_expedition_07_checkpoint_runtime.gd -- "--review-checkpoint=living_expedition_07_$checkpoint" --show-mobile-controls
}
& $godot --headless --path . --script scripts/main/smoke/smoke_living_expedition_05_checkpoint_runtime.gd -- --review-checkpoint=living_expedition_05_excavate_ready
& $godot --headless --path . --fixed-fps 60 --script scripts/main/smoke/smoke_marl_ground_pin.gd
& $godot --headless --path . --fixed-fps 60 --script scripts/main/smoke/smoke_marl_memory_night.gd
python tools/check_file_lengths.py
git diff --check
```

Treat `SCRIPT ERROR` / `ERROR:` as failure even with exit code zero. The three
real-scene checkpoints also run in core smoke CI. They check isolated profile,
clear bodies, four-way movement clearance, correct selection, pause, numbered
keyboard dispatch, sequential actual touch events, follow recovery, and normal
hotbar ownership. The night shortcut uses real `N` / `B` / `Space` input.
The refuge check first runs a separate live arrival: immediate menu, twelve
seconds of normal simulation, delayed keyboard/touch menus, then ordinary
movement/action inputs through warning, dig, dodge and pending memory. No owner
is frozen or manually stepped during that probe; damage/knockback, oxygen and
daylight remain active. The existing deterministic driver then runs on a fresh scene.

## Integrated Journey

```powershell
& $godot --headless --path . --fixed-fps 60 --script scripts/main/smoke/smoke_living_expedition_07_journey.gd -- --smoke-living-expedition-07 --review-checkpoint=living_expedition_07_refuge --show-mobile-controls
python tools/run_release_candidate_validation.py --require-godot
```

The journey starts unadapted in actual Main, earns the refuge event, loses it on
failure, retries with full cargo, banks at the canonical boat, defers growth,
then chooses it on a later night. A fresh sortie proves visible Root Claws,
physical Ground Pin/retreat, released follow, and survival of committed growth
across failure/reload. Oxygen/daylight run during deterministic field stepping.
Travel between source-authored field/boat boundaries is elided; this is not a
continuous route playthrough. Checkpoint and source tests retain clearance and
return-path coverage. The isolated profile never writes the normal save.

Regional journey CI runs this command. The release runner retains earlier
journeys and adds LE07 source, owner, checkpoint, and journey gates. Run the full
suite once at integration; after repairs rerun only impacted checks.

## Captures

```powershell
python tools/capture_living_expedition_07.py --godot "$godot"
python tools/check_living_expedition_07_captures.py
```

Non-headless rendering is required locally. This runs the same real-scene driver
through physical approach/dig, live eel cycles, and normal command dispatch;
it does not relocate or freeze the eel to fabricate a pin. Automatic frame
advancement is suspended for deterministic capture stepping only.

Nine states produce eighteen ignored PNGs under
`visual_captures/living_expedition_07/`: closed refuge, dig, retreat, pending
return, night choice, matched unadapted/adapted readiness, hold, and release.
Desktop output is 1280x720. The 844x390 mobile window has a letterboxed 693x390
canvas; HUD/input geometry stays in the real 1280x720 logical viewport.
Capture-only framing is fixed per size: authored 0.7 desktop zoom, 0.55 mobile
overview with touch controls visible. It does not alter normal camera settings.

The checker rejects missing/extra frames, stale source fingerprints, replaced
images, wrong identity/state/dimensions, missing runtime subject/HUD bounds,
different before/after framing, tracked output, or baseline acceptance claims.
No PNG, manifest, `.import`, or local profile belongs in a commit.

## Named Visual Boundary

Changed: Marl's six hooked fin tips, grounded grip and release-lift pose, compact
growth guidance/night choice, and the small silt arch/scallop group. The old
LE05 titanium mound remains distinct and unchanged. Terrain, diver, boat, Kite,
Mica, materials, LE06 nursery, rewards, and action timing are not replaced.

Real-scene testing also caught and corrected Ground Pin's capability lookup:
crafted Shock Prod ownership comes from the profile, not the traversal-upgrade
callback. The same two-owner lookup already used by Guardian Pulse is retained;
no equipment requirement was removed.
