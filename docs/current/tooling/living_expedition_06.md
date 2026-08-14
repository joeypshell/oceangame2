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

These checks prove isolated fixture selection, collision-clear diver and Kite
starts, four-direction movement, adaptation-owned BOND actions, and restored
nursery projection. Run the integrated LE06 journey smoke for boat commitment,
failure cleanup, next-day restoration, cargo independence, and reload coverage.

Do not use a checkpoint as evidence that the full journey is clear or
motivating. Public Web URLs belong here only after their exact deployed SHA has
been verified.
