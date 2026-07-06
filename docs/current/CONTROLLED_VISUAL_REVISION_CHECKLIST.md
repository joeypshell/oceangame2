# Controlled Visual Revision Checklist

Use this checklist for each targeted visual pass. Keep the pass narrow enough that screenshot differences can be explained in one sentence.

## 1. Plan Issue

- Name the target issue and the follow-up implementation/review issues.
- State the single visual target.
- List affected assets, scripts, scenes, and review artifacts.
- List untouched areas: maps, collision, movement, camera, gameplay, debug markers, accepted baselines, and unrelated art.
- State expected screenshot differences and unacceptable differences.

## 2. Source Of Truth

- For terrain or map shape changes, edit the JSON source map or renderer first.
- For asset-only passes, keep `maps/*.greybox.json` unchanged.
- Keep runtime selection tied to existing source data where possible, such as entity `kind` values.
- Do not regenerate a whole scene to fix one named visual problem.

## 3. Implement

- Add or edit only named assets and integration points required by the issue.
- Update `docs/ASSET_MANIFEST.md` when asset status or paths change.
- Preserve fallback behavior for missing draft assets when the current renderer already has it.
- Avoid accepting new visual baselines in the implementation issue.

## 4. Capture And Compare

- Regenerate the relevant focused capture route when the pass needs one.
- Regenerate normal production-slice captures touched by the visual change.
- Run capture completeness and stale checks:

```bash
python tools/check_production_slice_captures.py --fail-on-stale
```

- Render accepted-baseline comparison sheets:

```bash
python tools/manage_production_slice_baseline.py compare-all
```

- Confirm differences are limited to the planned target before proceeding.

## 5. Validate Behavior

- Run source/render checks appropriate to the changed path:

```bash
python tools/check_map_parity.py
python tools/check_asset_manifest.py
```

- Run Godot smoke checks for any touched runtime path, including route, salvage, hazard, oxygen, or player checks when relevant.
- Run `git diff --check`.

## 6. Accept Or Defer Baselines

- Create a separate review/acceptance issue for baseline replacement.
- Accept baselines only after the current visuals are explicitly approved.
- If review exposes unrelated drift, keep the baseline fixed and create a focused follow-up issue.

## 7. Web Preview

- For exported runtime, asset, scene, script, or workflow changes, verify the Web preview.
- Use external build metadata when checking a deployed preview:

```bash
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha <commit-sha>
```

- Confirm no missing texture/resource warnings, failed requests, Godot errors, or stale build metadata.

## 8. Close The Loop

- Update the relevant current plan/decision docs.
- Close GitHub issues with commit hashes, screenshots/review artifacts, and exact verification commands.
- Create the next small follow-up issue instead of expanding the current pass.
