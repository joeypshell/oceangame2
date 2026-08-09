# Living Expedition 04 Visual Decision

Date: 2026-08-08

Issue: #1321 `Review Living Expedition 04 desktop and mobile visual evidence`

Status: **FOCUSED EVIDENCE ACCEPTED; NO BASELINE REPLACEMENT**

## Decision

Accept the focused companion-shaped eel encounter evidence for exact-Web
verification. The generated frames show the intended Mica, Kite, Shock Prod,
and defeat-only harvest states without accepting a new production baseline.

## Intentional Differences

- Mica projects the territorial eel's warning phase and lunge direction before
  the player commits to an approach.
- Guardian Pulse creates a visible opening and knockback while leaving the
  eel at full health.
- A connected Shock Prod discharge leaves the eel at one of three health and
  keeps the selected weapon readable in the active-tool hotbar.
- Defeating the eel clears the territory and exposes the explicit electrocyte
  harvest while the guarded cache remains separate.

These frames demonstrate two understandable companion-shaped approaches:
Mica supplies advance information, while Kite creates a non-damaging opening.
The Shock Prod remains the only defeat path and the only way to expose the
biological resource.

## Focused Evidence

The ignored `visual_captures/living_expedition_04/` set contains four states at
desktop `1280x720` and an `844x390` landscape-mobile window (`693x390` logical
game canvas):

1. Mica reading the eel's warning intent.
2. Guardian Pulse creating a no-damage recovery opening.
3. Shock Prod damage with the eel at one health.
4. Defeat with electrocyte harvesting available.

The runner verifies the player, eel, and active companion stay in frame and
clear of the active-tool hotbar and touch controls. It also checks warning and
action feedback, the three owned tools, selected Shock Prod ownership where
relevant, exact encounter state, and bounded mobile `BOND`, `TOOL`, `USE`, and
movement controls. A standalone checker requires all eight PNGs, exact logical
dimensions, the isolated checkpoint, runtime bounds verification, and
`baseline_accepted=false`.

The inherited full status panel remains dense, particularly on the mobile
canvas. It is existing prototype presentation debt rather than LE04 drift; this
decision neither replaces nor accepts that HUD as a new visual baseline.

## Stable Areas

Accepted baseline comparisons remain clean for `production_level_01`, all four
production slices, and `transfer_hub_interior_01`. Terrain, collision, cameras,
player, boat, companions, tool hotbar, touch controls, map source, and accepted
baseline files remain unchanged. No generated capture, comparison sheet,
visual asset, map source, or `.import` sidecar is committed.

## Commands

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --script res://scripts/main/captures/living_expedition_04_capture_runner.gd --review-checkpoint=living_expedition_04_start
python tools/check_living_expedition_04_captures.py
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --script res://scripts/main/captures/living_expedition_01_capture_runner.gd --review-checkpoint=living_expedition_01_start
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --script res://scripts/main/captures/living_expedition_02_capture_runner.gd --review-checkpoint=living_expedition_02_start
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --script res://scripts/main/captures/living_expedition_03_capture_runner.gd --review-checkpoint=living_expedition_03_start
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

Exact public Web and checkpoint evidence remains owned by #1322.
