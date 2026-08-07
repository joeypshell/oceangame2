# Living Expedition 03 Visual Decision

Date: 2026-08-06

Issue: #1283 `Review Living Expedition 03 desktop and mobile visual evidence`

Status: **FOCUSED EVIDENCE ACCEPTED; NO BASELINE REPLACEMENT**

## Decision

Accept the focused Mica ecology presentation for exact-Web verification. The
generated evidence proves the intended journey states and adds no accepted
production baseline.

## Intentional Differences

- Mica visibly reacts before the concealed southwest migration is revealed.
- Reveal Trace draws a thin source-derived filament with path points and travel
  direction instead of the prior anonymous circular trace.
- The held Scanner projects its cone, bounded subject card, and partial progress
  over the revealed environmental relationship.
- Identification remains pending and explicitly directs the player back to the
  canonical surface boat.
- Night compares the committed `Followed the Bloom` memory with its deliberate
  `Drift Lens` consolidation.
- Next-sortie Read Drift projects the existing deep jellyfish patrol path and
  direction without changing the patrol.
- Landscape-mobile night controls now use a compact contextual TOOL, BUILD,
  DAY, and USE grid. Dive movement and its nine-command test layout return when
  the next day starts.

The filament remains deliberately prototype-scale, but the path, repeated
points, direction, linked moving jellyfish, and separate Scanner card make it a
living migration relationship rather than a generic ring or reward marker.

## Focused Evidence

The ignored `visual_captures/living_expedition_03/` set contains six states at
desktop `1280x720` and landscape-mobile `844x390`:

1. Mica reacting to the concealed migration.
2. The revealed migration filament.
3. Held Scanner identification at 50 percent.
4. Identified evidence pending canonical-boat return.
5. Followed the Bloom and Drift Lens at night.
6. Next-sortie Read Drift against the deep patrol.

The runner verifies all mobile controls remain inside the canvas. It also
checks the new Scanner card and the existing night result panel remain bounded
and clear of the relevant touch controls. A standalone checker requires all 12
PNGs, exact logical image dimensions, the isolated checkpoint, runtime bounds
verification, and `baseline_accepted=false`.

## Stable Areas

Both prior Living Expedition capture runners completed after the LE03 source
transition. The LE02 fixture now reviews its inherited Reveal Trace on Day 2,
when the linked bloom is active, without changing its isolated profile or the
normal journey.

`compare-all` rendered every accepted family and the review sheets retained
black difference columns. `check-clean --all-slices` passed for:

- `production_level_01`
- `production_slice_01`
- `production_slice_02`
- `production_slice_03`
- `production_slice_04`
- `transfer_hub_interior_01`

Terrain, collision, cameras, player, boat, tools, accepted HUD framing, Kite,
Mica identity, and all accepted baseline files remain unchanged. No generated
capture, baseline, visual asset, map source, or `.import` sidecar is committed.

## Commands

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --script res://scripts/main/captures/living_expedition_03_capture_runner.gd --review-checkpoint=living_expedition_03_start
python tools/check_living_expedition_03_captures.py
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --script res://scripts/main/captures/living_expedition_01_capture_runner.gd --review-checkpoint=living_expedition_01_start
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --script res://scripts/main/captures/living_expedition_02_capture_runner.gd --review-checkpoint=living_expedition_02_start
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

Exact public Web and checkpoint evidence remains owned by #1284.
