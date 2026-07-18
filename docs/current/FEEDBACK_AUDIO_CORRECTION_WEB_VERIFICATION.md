# Feedback Audio Correction Technical Review And Web Verification

Date: 2026-07-17

Issue: #1023

Runtime candidate: `ede39d1b2d8ceec2b446df3f385ad06519481016`

## Result

**Technical PASS. Expansion 13 remains at owner HOLD until #969 records the
player replay.**

The bounded #1020-#1023 interlude fixes the previously silent first material
pickup path, gives the existing semantic events individually generated cue
assets, protects the lifecycle in headless CI, and verifies the exact public
Web candidate. It does not prove that the owner finds the sounds clear,
pleasant, or sufficiently distinct in play.

- Public preview: `https://joeypshell.github.io/oceangame2/`
- Fresh owner review:
  `https://joeypshell.github.io/oceangame2/?review=ede39d1b2d8ceec2b446df3f385ad06519481016`
- [Godot Web Export run 29627699612](https://github.com/joeypshell/oceangame2/actions/runs/29627699612): success

## Lifecycle Evidence

The focused `--smoke-feedback-cues` run uses real production-slice collection,
offload, oxygen, and hazard owners. It verified:

- proximity without collection stays silent
- the first material collected on a fresh sortie emits exactly one
  `material_pickup` event with that source id
- remaining in range does not repeat the event
- material and salvage collection repeat once on a second sortie
- each of two salvage offloads emits one `salvage_bank` event
- a cargo-full material remains available and emits no pickup event
- canceled timed and pry interactions collect nothing and emit no pickup event
- locked Web audio records one eligible event, unlocks on input, and does not
  replay stale audio
- low oxygen, critical oxygen, oxygen failure, hazard warning, and hazard
  contact each emit once with the reviewed priority

Exact event counts were material pickup `2`, salvage pickup `2`, bank `2`, and
each oxygen/hazard transition `1`.

## Cue Evidence

Two complete generator runs produced identical hashes. The committed WAVs
match generated PCM byte for byte; all are mono 16-bit PCM at 22.05 kHz and
have unique fingerprints.

| Cue | Duration | SHA-256 prefix |
| --- | ---: | --- |
| `salvage_pickup` | 0.135s | `e4a051a080a1` |
| `material_pickup` | 0.143s | `4cfb1b948d0e` |
| `salvage_bank` | 0.270s | `f2597e3d4938` |
| `oxygen_low` | 0.250s | `d1c997c10fc0` |
| `oxygen_critical` | 0.260s | `f8c53622588b` |
| `oxygen_failure` | 0.440s | `9b166f397fa1` |
| `hazard_warning` | 0.225s | `06c3e27dd123` |
| `hazard_contact` | 0.208s | `65c3191266f0` |
| `upgrade_purchase` | 0.210s | `75599b34ae08` |

Objective separation follows the contract: salvage rises, material uses a
noise transient and descending clink, banking is about twice as long as a
pickup, oxygen uses low double/triple/vent shapes, danger uses a higher
alternating triplet, and contact begins with noise before a low impact. Human
listening remains part of #969.

## Stable Boundaries

The interlude changed nine named cue WAVs plus their generator, manifest,
contract, runtime event ownership, focused smoke, validator, CI hook, and
review docs. It changed no map source, terrain, collision, camera, visual
asset, gameplay threshold, progression rule, capture, or accepted baseline.

`check-clean --all-slices` reports clean for `production_level_01` and slices
01-04. Independent desktop and iPhone-landscape screenshots were inspected
from ignored `scratch/` output; framing and visible UI remain stable. No visual
baseline acceptance was needed.

## Web Evidence

The public checker independently verified deployed runtime `ede39d1`:

- external `build_info.json` reports the exact 40-character SHA
- root and fresh-review URLs initialize `production_level_01`
- explicit slice review initializes `production_slice_01` on desktop/mobile
- primary canvas: 1280x720 CSS pixels
- wide canvas: 1920x1080 CSS pixels
- iPhone-landscape canvas: 2532x1170 intrinsic at 844x390 CSS, positioned at
  `(0, 0)` over an 844x390 visual viewport
- mobile touch differences: stick-down `8.60`, oxygen `4.91`, build `5.60`,
  use `5.10`; all exceed the minimum `2`
- framing mean difference: `1.35`, below the maximum `18`
- no failed requests, missing assets, autoplay/audio errors, `SCRIPT ERROR`,
  or Godot `ERROR:` output

Chromium emitted only allowed WebGL `ReadPixels` performance warnings.

## Owner Replay

#969 and milestone #39 remain open. On the fresh URL, confirm:

1. The first collected cargo item on a fresh page/sortie is audible.
2. Banking has a distinct payoff cue, and the first pickup after leaving for a
   second sortie is audible again.
3. Material, valuable salvage, oxygen pressure, danger warning, damage/contact,
   and banking are distinguishable during play.
4. The existing active-tool and sealed-wreck replay still feels deliberate,
   clear, and worth completing.

Reply with GO or a concrete HOLD finding. Do not select Expansion 14 first.

## Verification

```powershell
python tools/generate_feedback_cue_assets.py
python tools/check_feedback_audio_assets.py
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-feedback-cues
python tools/manage_production_slice_baseline.py check-clean --all-slices
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha ede39d1b2d8ceec2b446df3f385ad06519481016
python tools/check_file_lengths.py
git diff --check
```
