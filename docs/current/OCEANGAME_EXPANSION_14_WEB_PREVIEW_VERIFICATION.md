# OceanGame Expansion 14 Web Preview Verification

Date: 2026-07-24

Issues: #1039 `Verify the exact Expansion 14 public Web candidate`, #1057
`Verify Expansion 14 checkpoint Web review path`, bounded corrections
#1061/#1063/#1065, and owner-HOLD correction closeout #1077

## Current Checkpoint Result

**PASS for exact deployment and focused review startup. Owner GO is recorded
in #1040.** The reviewed public build is:

- exact SHA: `1f148ebd9766ae18be48f0c14368c83d62375d05`
- build version: `1f148eb`
- `git_ref`: `main`
- `dirty`: `false`
- [Godot Web Export run 30129321057](https://github.com/joeypshell/oceangame2/actions/runs/30129321057):
  success, including Pages deploy and checkpoint-aware browser verification
- checkpoint URL:
  `https://joeypshell.github.io/oceangame2/?review=1f148ebd9766ae18be48f0c14368c83d62375d05&checkpoint=expansion_14_start`

The named checkpoint starts from an isolated in-memory profile after the
southeast archive commit. Earlier projects are complete, Ti2 + Coil1 is
banked, and the Current Stabilizer, advanced-current crossing, relay core, and
relay survey remain incomplete. It changes no normal save or default launch.

The independent public checker confirmed the checkpoint marker and
`production_level_01`, the empty fresh-profile path, retained slice-01
fallback, 1280x720 and 1920x1080 framing, iPhone-landscape touch alignment,
matching build metadata, no failed requests, and no Godot error output.

## Bounded Owner-HOLD Corrections

- #1069 locks the correction contract without changing Expansion 14 ownership.
- #1070/#1071 make scanner subjects and the Northwest Wreck Relay explicit in
  source metadata and rendering.
- #1072 requires held `Q/USE` for progression scans, cancels on release or tool
  switch, gives ordinary subjects reward-free identification, and presents a
  temporary target-local readout.
- #1073 adds world-local eel health, authoritative hit recoil, explicit cadence,
  a connected electrical bolt, and a directional endpoint fizzle on misses.
- #1074 keeps passive equipment in the top cargo strip while active tools remain
  in the bottom hotbar.
- #1075 adds one bounded deterministic correction matrix.
- #1076 records a focused desktop/wide/mobile visual PASS with no new baseline;
  all 35 accepted full-level and slice PNGs remained byte-identical.
- #1087 keeps the scanner field and local identification active for the full
  held `Q/USE` interval, then clears immediately on release.
- #1088 freezes player movement behind oxygen-failure retry and restores it
  through the existing reset path.

The correction implementation and technical/Web checks are complete. Owner GO
was recorded separately after player review; the checks do not alter map
topology or progression ownership or accept a new visual baseline.

## Original Candidate Result

**PASS for technical deployment. Player GO was still open at this historical
candidate.** The public GitHub Pages preview served the post-baseline Expansion
14 candidate at:

```text
https://joeypshell.github.io/oceangame2/
```

Verified deployment:

- exact SHA: `739ffd59fa37d40c9dc1d909facc5de17a3c05dd`
- build version: `739ffd5`
- `git_ref`: `main`
- `dirty`: `false`
- [Godot Web Export run 29658558080](https://github.com/joeypshell/oceangame2/actions/runs/29658558080): success, including Pages deploy
- fresh player-review URL:
  `https://joeypshell.github.io/oceangame2/?review=739ffd59fa37d40c9dc1d909facc5de17a3c05dd`

The #1038 merge changed only visual-baseline and documentation paths, so the
path-filtered workflow was manually dispatched on `main`. Its artifact and the
public metadata both identify the exact merge SHA rather than the earlier
runtime-source deployment.

## Browser Evidence

`tools/check_web_preview.cjs` independently verified the deployed Pages site:

- root and fresh-review URLs initialize `production_level_01`
- explicit review fallback initializes `production_slice_01`
- primary canvas: 1280x720 CSS pixels
- wide canvas: 1920x1080 CSS pixels
- iPhone-landscape canvas: 2532x1170 intrinsic at 844x390 CSS, positioned at
  `(0, 0)` over an 844x390 visual viewport with zero offset
- touch probes: move-down `8.60`, oxygen `4.91`, project `5.60`, use `5.10`;
  all exceed the required `2`
- framing mean difference: `1.32`, below the maximum `18`
- no failed requests, missing resources, `SCRIPT ERROR`, or Godot `ERROR:`
  output

The corrected artifact identifies build `1f148eb`, preserves the fresh isolated
profile marker and full-level boat entry, and keeps the held-cargo strip clear
of the bottom-center active-tool hotbar. The touch-enabled mobile check keeps
the canvas top anchored and MOVE/O2/BAG/TOOL/BUILD/DAY/RESET/ACT/USE controls
reachable without covering either HUD surface.

Chromium emitted only the allowed software-WebGL fallback and `ReadPixels`
performance warnings. They did not affect initialization, input, framing, or
network checks.

## Journey Boundary

The original Expansion 14 journey source is
`00980855b4dfb3defd79b488592ee610f189f667`. Later checkpoint and correction
work changes focused review startup, tool/scanner presentation, relay
readability, passive-equipment presentation, and Shock Prod feedback without
changing map topology, progression ownership, cargo semantics, or accepted
baselines. Focused evidence still confirms the blocked current, stabilizer
promise, passive crossing, Northwest Wreck Relay and core, held scanner survey,
pending boat return, and archive result.

The public query contract deliberately supports fresh profiles and map choice,
not profile-state injection or capture flags. Browser automation therefore
proves exact deployment, startup, HUD separation, and touch behavior but does
not skip directly to the relay. The live current-to-relay journey later
received owner GO in #1040.

## Verification

```powershell
gh workflow run godot-web-export.yml --repo joeypshell/oceangame2 --ref main
$env:NODE_PATH = "$env:TEMP\oceangame2-web-preview-check\node_modules"
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 1f148ebd9766ae18be48f0c14368c83d62375d05
python tools/check_file_lengths.py
git diff --check
```
