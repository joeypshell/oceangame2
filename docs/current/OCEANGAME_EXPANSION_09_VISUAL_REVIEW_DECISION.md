# OceanGame Expansion 09 Visual Review Decision

Date: 2026-07-13

Issue: #864 `Capture and run the player gate for the contiguous full-level candidate`

Status: **Technical PASS. Player GO/HOLD pending.**

## Decision Boundary

The contiguous `production_level_01` candidate is technically ready for player
review. This is not a GO to make it the default map. `production_slice_01`
remains the default, no accepted baseline was replaced, and #865 remains blocked
until the player explicitly answers GO.

## Candidate Evidence

`--capture-expansion-09-full-level` generated 14 candidate-only PNGs under
`visual_captures/expansion_09_full_level/`. The authored `production_level_*`
camera records supply seven contexts at 1280x720 and mobile 844x390 review sizes:

- full-level overview
- canonical top boat
- transformed opening gameplay
- upper-left sector
- lower-left sector
- lower-right sector
- cargo return toward the boat

The generated SVG and
`references/greybox/production_level_01_source_render_collision_review.png`
agree on the 158x161-tile source silhouette and expected collision footprint.
Runtime parity reports 14,898 terrain cells and 376 collision rectangles.

## Intentional Differences

- The candidate displays the complete supplied cave topology rather than a
  focused slice.
- Proven slice-01 gameplay occupies transformed full-map coordinates without a
  crop seam or map transition.
- Broad sector frames intentionally show a smaller diver against the larger
  geography; boat, opening, and return frames retain normal gameplay framing.
- The return frame holds one transformed entry salvage item and keeps the boat
  visible above, demonstrating the direct-return context without changing map
  source or durable profile state.

## Stable Areas

All 21 configured current production-slice PNGs remain byte-identical to their
accepted baselines:

- slice 01: 6/6
- slice 02: 5/5
- slice 03: 5/5
- slice 04: 5/5

Unrelated terrain, collision, diver, boat, HUD, prop, camera, hazard, and
connector-reference views therefore remain unchanged. Accepted baseline
directories pass `check-clean --all-slices`.

## Known Player-Review Risks

- Large unadorned sectors may be technically traversable but still difficult to
  orient within or remember.
- Passage scale and edge treatment may not communicate the useful route as
  clearly while swimming as they do in an overview.
- Broad camera views necessarily reduce the diver's visual prominence.
- The existing dense HUD occupies substantial mobile space even though the
  mobile canvas and touch alignment pass automated checks.
- Direct return is deterministic and collision-valid, but only play can show
  whether it feels understandable and worthwhile.

These are review questions, not evidence for an automated terrain rewrite.

## Exact Web Review

Verified runtime commit:
`b0bb1f97576f1504128b61247dbb21916be44b1e` (`b0bb1f9`)

Godot Web Export run:
[29271637330](https://github.com/joeypshell/oceangame2/actions/runs/29271637330)

Player review URL:

```text
https://joeypshell.github.io/oceangame2/?review=b0bb1f97576f1504128b61247dbb21916be44b1e&map=production_level_01
```

Independent browser verification confirmed:

- exact `build_info.json` full-SHA match
- public root still loads `production_slice_01`
- review URL loads `production_level_01` with an isolated fresh profile
- desktop 1280x720, wide 1920x1080, and mobile 844x390 initialization
- mobile canvas at `(0, 0)` and all four touch probes above tolerance
- no failed requests, missing resources, script errors, or Godot errors

Chromium emitted only software-WebGL fallback and `ReadPixels` performance
warnings; neither affected initialization or framing.

## Player Checklist

Play from the boat and answer these six questions:

1. **Continuity:** Does movement feel like one level, with no implied teleport or stitched seam?
2. **Orientation:** Can you understand where the boat, opening route, and distant sectors are relative to each other?
3. **Passages:** Are narrow and broad passages readable while moving, not only in the overview?
4. **Camera:** Does framing stay useful near boundaries without losing the diver or showing confusing blank space?
5. **Scale:** Does the larger geography feel worth exploring rather than merely oversized?
6. **Return:** Can you deliberately find and complete a direct swim back to the boat?

Reply **GO** only if this feels like one full level that can support future
capability-gated exploration without teleports. Reply **HOLD** with concrete
locations or behaviors that need correction. HOLD creates only scoped corrective
issues; it does not start #865.

## Verification

```powershell
python tools/check_camera_captures.py maps/production_level_01.greybox.json visual_captures/expansion_09_full_level --camera-id-prefix production_level_ --suffix 1280x720 --suffix mobile_844x390 --fail-on-stale
python tools/check_map_parity.py maps/production_level_01.greybox.json
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```
