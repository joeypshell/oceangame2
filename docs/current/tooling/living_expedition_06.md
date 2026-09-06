# Living Expedition 06 Evidence

Use these isolated checkpoints to review the Signal Reef nursery without
reading or writing the normal profile:

```powershell
$godot = 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe'
& $godot --path . --review-checkpoint=living_expedition_06_anchor_ready
& $godot --path . --review-checkpoint=living_expedition_06_guardian_ready
& $godot --path . --review-checkpoint=living_expedition_06_restored_nursery
```

Run the actual-main-scene checkpoint checks headlessly:

```powershell
& $godot --headless --path . --script res://scripts/main/smoke/smoke_living_expedition_06_checkpoint_runtime.gd --review-checkpoint=living_expedition_06_anchor_ready
& $godot --headless --path . --script res://scripts/main/smoke/smoke_living_expedition_06_checkpoint_runtime.gd --review-checkpoint=living_expedition_06_guardian_ready
& $godot --headless --path . --script res://scripts/main/smoke/smoke_living_expedition_06_checkpoint_runtime.gd --review-checkpoint=living_expedition_06_restored_nursery
```

Run both complete branch journeys:

```powershell
& $godot --headless --path . --script res://scripts/main/smoke/smoke_living_expedition_06_journey.gd --smoke-living-expedition-06 --review-checkpoint=living_expedition_06_anchor_ready
& $godot --headless --path . --script res://scripts/main/smoke/smoke_living_expedition_06_journey.gd --smoke-living-expedition-06 --review-checkpoint=living_expedition_06_guardian_ready
```

Generate the focused desktop and landscape-mobile review set in this order:

```powershell
& $godot --path . --script res://scripts/main/captures/living_expedition_06_capture_runner.gd --review-checkpoint=living_expedition_06_anchor_ready
& $godot --path . --script res://scripts/main/captures/living_expedition_06_capture_runner.gd --review-checkpoint=living_expedition_06_guardian_ready
& $godot --path . --script res://scripts/main/captures/living_expedition_06_capture_runner.gd --review-checkpoint=living_expedition_06_restored_nursery
python tools/check_living_expedition_06_captures.py
```

The first command clears only the ignored LE06 evidence directory. Together
the commands write approach, Anchor action, Guardian action, immediate
sheltering, pending return, and restored-next-day frames under
`visual_captures/living_expedition_06/`. They do not accept or replace a
production baseline. Do not use `--headless` for these screenshot commands on
the current local setup.

These checks prove isolated fixture selection, collision-clear diver and Kite
starts, four-direction movement, adaptation-owned BOND actions, and restored
nursery projection. Run the integrated LE06 journey smoke for boat commitment,
failure cleanup, next-day restoration, cargo independence, and reload coverage.

Do not use a checkpoint as evidence that the full journey is clear or
motivating.

Accepted public review URLs retained for replay, verified at
`16300a9ca4cbe93b5e4ab74ffa6707cf049646a0`:

```text
https://joeypshell.github.io/oceangame2/?review=16300a9ca4cbe93b5e4ab74ffa6707cf049646a0&checkpoint=living_expedition_06_anchor_ready
https://joeypshell.github.io/oceangame2/?review=16300a9ca4cbe93b5e4ab74ffa6707cf049646a0&checkpoint=living_expedition_06_guardian_ready
https://joeypshell.github.io/oceangame2/?review=16300a9ca4cbe93b5e4ab74ffa6707cf049646a0&checkpoint=living_expedition_06_restored_nursery
```

The exact-SHA Web matrix passed for all three links. See the
[Web verification](../LIVING_EXPEDITION_06_WEB_VERIFICATION.md) and separate
[owner-GO closeout](../LIVING_EXPEDITION_06_CLOSEOUT.md) through #1375.
