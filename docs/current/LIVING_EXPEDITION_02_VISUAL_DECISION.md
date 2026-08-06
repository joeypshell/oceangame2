# Living Expedition 02 Visual Decision

Date: 2026-08-05

Issue: #1260 `Review Living Expedition 02 desktop and mobile visual evidence`

Status: **FOCUSED EVIDENCE ACCEPTED; NO BASELINE REPLACEMENT**

## Decision

Accept the focused two-partner presentation for exact-Web verification. The
review adds deterministic evidence only; it does not accept or replace an
existing production baseline.

## Intentional Differences

- The canonical boat projects a compact habitat panel with one or two named
  individuals, species identity, history, and an explicit `NEXT` selection.
- Mica reads as a small purple/teal Veil Cuttle with a hovering silhouette and
  close sensing-partner position distinct from Kite's mounted Spark Ray shape.
- Mica's BOND palette contains Recall and Reveal Trace, never Mount.
- Reveal Trace shows a directional cone before use and a separate teal result
  pulse that hands identification back to the Scanner.
- Returning to the habitat and selecting Kite restores Kite's mounted action
  hotbar without retaining Mica's field action.

## Focused Evidence

The ignored `visual_captures/living_expedition_02/` set contains eight states at
desktop `1280x720` and landscape-mobile `844x390`:

1. Kite-only habitat before Mica commitment.
2. Two-partner habitat after commitment, with Kite still next.
3. Confirmed Mica next-sortie selection.
4. Mica close-follow field identity.
5. Reveal Trace aim with the bounded BOND palette.
6. Reveal Trace result and Scanner handoff.
7. Confirmed Kite reselection after Mica's sortie.
8. Kite mounted actions restored on the later sortie.

The renderer verifies required habitat, palette, and mounted-action surfaces on
both sizes. It also verifies every mobile control remains inside the canvas and
that the reviewed companion UI does not overlap the movement or command touch
targets. The prior Living Expedition 01 capture runner still completes.

## Stable Areas

`compare-all` rendered every accepted family before this decision. Difference
columns were empty/black, and `check-clean --all-slices` passed for:

- `production_level_01`
- `production_slice_01`
- `production_slice_02`
- `production_slice_03`
- `production_slice_04`
- `transfer_hub_interior_01`

Terrain, collision, player, boat, Kite, tools, cameras, accepted HUD framing,
and all Living Expedition 01 baselines remain unchanged. No generated capture,
accepted baseline, visual asset, or `.import` sidecar is committed by this
decision.

## Commands

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --script res://scripts/main/captures/living_expedition_02_capture_runner.gd --review-checkpoint=living_expedition_02_start
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --script res://scripts/main/captures/living_expedition_01_capture_runner.gd --review-checkpoint=living_expedition_01_start
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

Exact public Web and touch verification passed in #1261. The owner supplied GO
in #1262; `LIVING_EXPEDITION_02_CLOSEOUT.md` records the final decision.
