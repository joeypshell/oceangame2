# Web Export

Generate optional local build metadata for the preview overlay:

```bash
python tools/write_build_info.py
```

This writes ignored `build_info.json`. The web export workflow generates that file from `GITHUB_SHA` before export, so the public preview can identify the deployed commit.

The latest exact-SHA Pages and checkpoint verification is recorded in [Living Expedition 01 Technical Review](../LIVING_EXPEDITION_01_TECHNICAL_REVIEW.md). The [OceanGame Expansion 18 Visual Baseline Decision](../OCEANGAME_EXPANSION_18_VISUAL_BASELINE_DECISION.md) remains the latest accepted visual-baseline decision, and the older [Simple Diver Game 08 Web Export Handoff](../SIMPLE_DIVER_GAME_08_WEB_EXPORT_HANDOFF.md) remains the release-candidate foundation.

Build a local Web export preview:

```powershell
python tools/write_build_info.py
python tools/write_web_export_preset.py
New-Item -ItemType Directory -Force exports/web | Out-Null
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --export-release Web exports/web/index.html
Copy-Item build_info.json exports/web/build_info.json
python -m http.server 8060 --directory exports/web
```

Open `http://127.0.0.1:8060/` after the server starts. Do not open `exports/web/index.html` directly; Godot Web exports need to be served over HTTP.

If the local export reports missing `web_nothreads_*` templates, install the Godot 4.7 export templates through the editor or use the GitHub Actions artifact; CI installs templates during the workflow.

Verify a served Web export in Chromium:

```powershell
$env:NODE_PATH = "$env:TEMP\oceangame2-web-preview-check\node_modules"
npm install --prefix "$env:TEMP\oceangame2-web-preview-check" playwright@1.55.0
& "$env:TEMP\oceangame2-web-preview-check\node_modules\.bin\playwright.cmd" install chromium
node tools/check_web_preview.cjs http://127.0.0.1:8060/ --expected-sha (git rev-parse HEAD)
```

The checker uses `living_expedition_02_start` as the current named checkpoint.
Pass `--checkpoint <id>` to verify a retained checkpoint instead.

The check fails if the web preview logs missing texture warnings such as `Unable to open texture asset`, `Unable to create cave TileSet`, `SCRIPT ERROR`, `ERROR:`, failed resource requests, a missing Godot canvas, a framing/readability mismatch between 1280x720 and 1920x1080 browser viewports, a touch-enabled 844x390 canvas that is not top anchored or does not cover the visual viewport, visible mobile controls that do not respond at their rendered touch positions, or an external `build_info.json` whose `git_sha` does not match the expected commit. Omit `--expected-sha` when checking an older export that does not include external build metadata.

The generated Web preset injects a small Head Include that fixes the page container to the top of the browser viewport and uses `100dvh` with a `100vh` fallback. It does not independently position or size the canvas; Godot remains the sole owner of canvas geometry so its rendered position and touch-coordinate origin stay aligned on iPhone Safari.

GitHub Actions builds the same preview in `Godot Web Export`. The workflow writes `build_info.json`, copies it beside `exports/web/index.html` as external Pages metadata, serves the exported build, and runs `tools/check_web_preview.cjs` with the expected `GITHUB_SHA` before uploading the artifact or deploying Pages. Download the `oceangame2-web-export` artifact from the workflow run when you need to inspect a build. The workflow also deploys GitHub Pages from `main` when Pages is already enabled for the repository. If the Pages job says it skipped deployment, open repository Settings, enable Pages, and set the source to GitHub Actions. The latest preview should then be available at `https://joeypshell.github.io/oceangame2/`.

The public export uses the project stretch policy to keep a 1280x720 logical gameplay frame even when the browser canvas is larger. `Build <sha>` in the overlay is the deployed commit; `Build local` is a local checkout. If Web and local HUD text or salvage totals differ, first confirm the local checkout/worktree is at the same commit and map as the deployed `build_info.json`.

For an isolated player-review run, open `https://joeypshell.github.io/oceangame2/?review=<sha>`. The `review` query starts with a fresh in-memory profile without reading, deleting, or writing the normal durable profile; the overlay reports `Review profile fresh/isolated` and whether fins are owned. The Web checker exercises this URL and requires the startup marker before passing.

For focused Expansion 14 review, use
`https://joeypshell.github.io/oceangame2/?review=<sha>&checkpoint=expansion_14_start`.
This named checkpoint remains isolated but starts after the archive commit with
prior projects complete, the Current Stabilizer unbuilt, and Ti2 + Coil1
banked. The Web checker requires the checkpoint marker and full-level map
marker. Unsupported checkpoint ids fall back to an empty isolated profile;
there is no arbitrary profile-state injection.

For focused Expansion 16 review, use
`https://joeypshell.github.io/oceangame2/?review=<sha>&checkpoint=expansion_16_start`.
This isolated checkpoint starts at the boat with prior required tools and
discoveries complete, Ti1 + Rubber1 + Coil1 + Gel1 banked, and the
closed-circuit rebreather plus far-west discovery unresolved.

For focused Expansion 17 review, use
`https://joeypshell.github.io/oceangame2/?review=<sha>&checkpoint=expansion_17_start`.
This isolated checkpoint starts at the boat after the far-west recorder commit,
with both coordinate transponders unresolved. Desktop active-tool use is
`Space`; the landscape-mobile `USE` control dispatches the same action.

For focused Expansion 18 review, use
`https://joeypshell.github.io/oceangame2/?review=<sha>&checkpoint=expansion_18_start`.
This isolated checkpoint starts at the boat after the wreck-network coordinates
are committed, with the Transfer Hub entrance available and its navigation core
unresolved. Use `E`/`ACT` at the entrance and `Space`/`USE` with the Cutter.

For focused Living Expedition 01 review, use
`https://joeypshell.github.io/oceangame2/?review=<sha>&checkpoint=living_expedition_01_start`.
This isolated checkpoint starts immediately before the Spark Ray rescue with
the required prior projects complete, Cutter/Fins/Shock Prod available, empty
cargo, and no companion committed. It is the fresh isolated milestone start
for the three-day owner journey; a blank historical profile remains a separate
whole-game progression review.

For focused Living Expedition 02 review, use
`https://joeypshell.github.io/oceangame2/?review=<sha>&checkpoint=living_expedition_02_start`.
This isolated checkpoint starts at the canonical boat with Kite committed and
selected, Mica unrescued, prior required progression complete, and empty cargo.
The checker probes movement and all nine mobile command surfaces; TOOL and USE
cover habitat selection/confirmation, while RESET covers retry.

The public root and `https://joeypshell.github.io/oceangame2/?review=<sha>` now load `production_level_01`; the review query still isolates profile state. To review a retained slice fixture, add an explicit supported map, for example `?review=<sha>&map=production_slice_01`. A bare `map` query without `review` does not override the default. The Web checker verifies the full-level default and explicit slice-01 fallback at desktop and mobile browser sizes.
