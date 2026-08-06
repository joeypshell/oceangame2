# Living Expedition 02 Evidence

Use the isolated `living_expedition_02_start` checkpoint for the two-partner
proof. It loads `production_level_01` with prior required progression complete,
Kite committed and selected, Mica still available at her source-authored rescue,
and empty cargo. It never reads or writes the normal durable profile.

## Local Review

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --review-checkpoint=living_expedition_02_start
```

## Deterministic Journey

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --script res://scripts/main/smoke/smoke_two_species_sortie_integration.gd --review-checkpoint=living_expedition_02_start
```

The journey covers schema-v1 migration, Mica rescue with full cargo, failure
restore, canonical-boat commitment, two-partner habitat selection, Mica's
non-mounted action set, Reveal Trace plus Scanner handoff, oxygen/combat/hazard/
retry cleanup, Kite reselection and Mount restoration, save/reload, and one
protected equipment gate. CI runs this once in the journey tier.

Focused source and graph coverage:

```powershell
python tools/test_production_level_01_living_expedition_02.py
python tools/test_progression_graph_creatures.py
```

These checks keep Mica and her trace optional, reachable, non-rewarding, and
unable to satisfy equipment gates. Exact-Web evidence remains owned by its
dedicated milestone issue.

## Focused Visual Review

Run the non-headless capture runner:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --script res://scripts/main/captures/living_expedition_02_capture_runner.gd --review-checkpoint=living_expedition_02_start
```

It writes eight desktop `1280x720` and eight landscape-mobile `844x390`
frames under `visual_captures/living_expedition_02/`. The ignored capture set
covers the Kite-only habitat, two-partner habitat, confirmed Mica selection,
Mica close-follow identity, Reveal Trace aim and result, Kite reselection, and
restored mounted actions. The runner fails when required companion UI leaves
the canvas or overlaps visible mobile test controls.

The intentional decision and unchanged-baseline evidence are recorded in
[Living Expedition 02 Visual Decision](../LIVING_EXPEDITION_02_VISUAL_DECISION.md).
