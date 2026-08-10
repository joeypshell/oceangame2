# Living Expedition 04 Visual Decision

Date: 2026-08-09

Issues: #1321 original review; #1333 Mica clarity correction; #1335 owner-HOLD
retirement

Status: **MICA EEL EVIDENCE REJECTED; THREE RETAINED STATES; NO BASELINE CHANGE**

## Decision

The owner found Mica's territorial-eel prediction non-useful even after its
focused clarity correction. The `mica_intent_read` frame is therefore retired
from current LE04 evidence. It must not be used to imply that the experiment
succeeded or be accepted as a production baseline.

Retain the focused frames that still demonstrate useful, intentional outcomes:

1. Guardian Pulse creates a visible zero-damage recovery opening.
2. Shock Prod visibly damages the eel and owns its health change.
3. Defeat exposes the explicit electrocyte harvest while the guarded cache
   remains separate.

Mica's moving-ecology `Read Drift` presentation remains accepted under Living
Expedition 03 and is not changed by this decision.

## Intentional Differences

- The LE04 capture manifest and checker contain three states instead of four.
- Stale ignored `mica_intent_read` PNGs are removed by the focused runner.
- Journey and guidance evidence identify Kite as the eel's sole active
  companion response.
- No map, terrain, camera, player, boat, companion asset, tool, reward, profile,
  or accepted baseline changes.

## Focused Evidence

The ignored `visual_captures/living_expedition_04/` set contains three states at
desktop `1280x720` and landscape-mobile `844x390` (`693x390` logical canvas):

- `guardian_opening`
- `shock_prod_damage`
- `defeat_harvest_available`

The runner verifies player, eel, and active companion framing; hostile state;
Guardian zero damage; selected Shock Prod ownership; explicit harvest state;
active-tool hotbar bounds; and mobile controls. The checker requires all six
PNGs, exact dimensions, the isolated checkpoint, runtime bounds verification,
and `baseline_accepted=false`.

The inherited status panel remains dense, especially on mobile. That is
existing presentation debt and is neither fixed nor accepted here.

## Stable Areas

Accepted baseline comparisons remain authoritative for `production_level_01`,
all production slices, and `transfer_hub_interior_01`. This decision commits no
generated capture, comparison sheet, visual asset, `.import` sidecar, or
baseline replacement.

## Commands

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --script res://scripts/main/captures/living_expedition_04_capture_runner.gd --review-checkpoint=living_expedition_04_start
python tools/check_living_expedition_04_captures.py
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

The prior exact-Web evidence remains historical evidence for the rejected
experiment. The corrected exact build is verified after #1335/#1336 land and
is recorded by #1323 without claiming owner GO.
