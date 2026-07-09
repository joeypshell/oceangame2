# Depth Darkness Light Gate Web Preview Verification

Date: 2026-07-09

Issue: #469 `Verify public Web preview after darkness-light pass`

## Decision

The public Web preview is verified for the darkness/light gate pass.

The deployed app build metadata points to `eb09665b6dd7c6a1c5120a300e7af037dbbf1cd4`, the merged app/capture commit for #467. The later #468 commit `f3604c3993357d084b919349c3c55a2ccc8aec9b` is documentation-only and did not trigger a Web export, so `eb09665` is the correct public-preview commit to verify.

## Verified URL

```text
https://joeypshell.github.io/oceangame2/
```

## Result

- Build metadata matched expected SHA `eb09665b6dd7c6a1c5120a300e7af037dbbf1cd4`.
- Godot initialized in browser.
- Normal canvas initialized at `1280x720`.
- Wide canvas initialized at `1920x1080`.
- Framing thumbnail mean difference was `1.26` with max `18`, within the checker's stable-preview range.
- Browser console showed Godot/WebGL initialization logs and WebGL `ReadPixels` performance warnings only.
- No missing texture, missing JSON, TileSet, script, or Godot error lines were reported.

The first darkness/light gate is therefore public-preview safe for review. The focused before/after review captures remain the best way to inspect the local dark-pocket readability change:

- `visual_captures/darkness_light_gate/production_slice_01_darkness_light_before_light.png`
- `visual_captures/darkness_light_gate/production_slice_01_darkness_light_after_light.png`

## Verification

Command run with the local bundled Node runtime and Playwright module path:

```powershell
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha eb09665b6dd7c6a1c5120a300e7af037dbbf1cd4
```

Additional checks:

```powershell
python tools/check_file_lengths.py
git diff --check
```

## Follow-Up

Close out the darkness/light gate pass under #470 and select the next small presentation/game-feel step.
