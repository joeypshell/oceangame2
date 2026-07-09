# Simple Diver Game 08 Validation Matrix

Date: 2026-07-09

Issue: #623
Milestone: Simple Diver Game 08 `Release Candidate`

## Decision

This matrix defines what blocks Simple Diver Game 08 release-candidate status. It is a hardening gate for the current small diver game, not permission to add new features.

Release-candidate work should prove the current default experience is runnable, validated, reviewable, and handoff-ready. Failures that affect the default journey, source-of-truth integrity, runtime startup, committed release evidence, or public Web preview are blockers. Deferred slice polish and broader expansion ideas create follow-up issues only.

## Gate Matrix

| Gate | Required Check | Blocks Release Candidate | Follow-Up Only |
| --- | --- | --- | --- |
| Repo hygiene | `python tools/check_file_lengths.py`; `git diff --check` | Non-allowlisted oversized human-authored files, whitespace errors, or generated/cache files in the diff. | Known allowlisted file-length debt already tracked by the audit tool. |
| Map source truth | `python tools/validate_greybox_map.py <map>` for production slices and required comparison maps; `python tools/check_map_parity.py` | Default/release-path map invalid, unreachable required gameplay entity, or Godot terrain/collision parity mismatch. | Optional slice-03 presentation polish in #52/#53 unless slice-03 becomes the selected release path. |
| Asset and capture inventory | `python tools/check_asset_manifest.py`; `python tools/check_production_slice_captures.py` | Required committed release asset or capture inventory is missing, stale, or points at an invalid file. | Non-release review capture needs reframing or a future optional view. |
| Godot import/startup | Headless import and startup from `project.godot`. Treat `SCRIPT ERROR` and `ERROR:` lines as failures. | Any import/startup crash, script error, missing required runtime resource, or blue-greybox fallback caused by missing assets. | Local editor-only warning with documented workaround and no runtime/export impact. |
| Core gameplay smokes | Existing smoke flags for salvage, cargo, oxygen, hazard pressure, safe/deep routes, route result, primary completion, progression, upgrades, and player facing. | Default journey semantics fail, oxygen/cargo/hazard pressure breaks, player-facing regression returns, or route/objective/result flow fails. | Smoke covering a non-selected or intentionally deferred map slice needs separate polish. |
| Release journey smoke | #625 default-journey smoke or equivalent runner output. | No deterministic beginning-to-end proof from entry through objective, return/banking, result, and retry/next-dive state. | Extra alternate-route journey coverage beyond the selected release path. |
| Visual baseline review | `python tools/manage_production_slice_baseline.py compare-all`; `python tools/manage_production_slice_baseline.py check-clean --all-slices` | Unexplained drift in default/release review views, dirty accepted-baseline directories, or accepted baseline sidecars. | Intentional visual change that needs a separate review and acceptance issue. |
| Focused capture review | Release-candidate capture index from #626, using existing focused capture commands. | Required release review capture cannot be generated or inspected, or it hides the player-facing/default-journey state being verified. | Additional nice-to-have capture angle for later documentation. |
| Web preview | `node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha <sha>` for the deployed runtime/export commit. | Build metadata mismatch for expected runtime, missing canvas, failed resources, Godot `SCRIPT ERROR`/`ERROR:`, or viewport framing drift outside the checker tolerance. | Docs-only commit after the last runtime export, if the prior runtime SHA remains intentionally deployed and documented. |
| Docs and handoff | README, `docs/current/PROJECT_CONTEXT.md`, split tooling docs, and closeout docs describe the current run/verify/continue flow. | Current docs tell a future agent to run stale commands, chase closed issues as active work, or treat deferred polish as a release blocker. | Archival cleanup of old pass docs that does not affect current handoff. |

## Core Smoke Set

The release-candidate blocker set should include, at minimum:

- `--smoke-salvage-loop`
- `--smoke-cargo-capacity`
- `--smoke-oxygen-pressure`
- `--smoke-hazard-pressure`
- `--smoke-safe-deep-route-choice`
- `--smoke-route-outcome-result`
- `--smoke-primary-dive-completion`
- `--smoke-pass-18-progression`
- `--smoke-pass-19-cargo-upgrade`
- `--smoke-pass-20-light-upgrade`
- `--smoke-pass-27-facing-transitions`
- the #625 release/default-journey smoke once added

Existing broader CI smokes may continue to run, but release-candidate judgment should stay focused on the default small-game path unless a later issue deliberately adds another release path.

## Expected Evidence

By the end of Simple Diver Game 08, evidence should be split across small docs instead of one oversized closeout:

- #624: one-command release-candidate validation runner and output shape.
- #625: deterministic default-journey smoke and example output.
- #626: capture review index naming required release-candidate views.
- #627: local run/import quickstart verification note.
- #628: public Web preview verification note.
- #629: accepted baseline and capture inventory audit note.
- #630: README/project-context handoff refresh.
- #631: final go/no-go closeout with blockers and deferred polish.

## Deferred Non-Blockers

Do not block release-candidate status on:

- #52 and #53 slice-03 presentation polish while slice-03 remains outside the selected release path.
- Known file-length debt in `scripts/main/main.gd` and `scripts/world/greybox_world.gd` while `tools/check_file_lengths.py` reports them as temporary allowlist debt.
- Broad economy, inventory, save files, enemies, procedural generation, broad audio, broad art replacement, or full-map productionization.
- Additional alternate routes or map-scale expansion not required for the current default journey.

## Verification

```powershell
python tools/check_file_lengths.py
git diff --check
```
