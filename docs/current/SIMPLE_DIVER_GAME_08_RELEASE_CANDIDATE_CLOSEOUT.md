# Simple Diver Game 08 Release-Candidate Closeout

Date: 2026-07-09

Issue: #631
Milestone: Simple Diver Game 08 `Release Candidate`

## Decision

GO for Simple Diver Game 08 release-candidate status.

The current small diver game is runnable, validated, reviewable, and documented well enough to stop release-candidate hardening work. Do not keep adding validation-only issues unless a new failure appears. The next work should be selected deliberately from playtest feedback or the next roadmap milestone.

## Validation Summary

Fresh full runner:

```powershell
python tools/run_release_candidate_validation.py
```

Result: PASS.

The full runner passed:

- file-length audit
- whitespace diff check
- asset manifest path check
- production-slice capture inventory
- accepted baseline directory clean check
- map validation for comparison maps, full sketch, and production slices 01-04
- Godot headless import
- Godot headless startup
- Godot terrain/collision parity
- salvage loop smoke
- cargo capacity smoke
- oxygen pressure smoke
- hazard pressure smoke
- safe/deep route choice smoke
- route outcome result smoke
- primary dive completion smoke
- release journey smoke
- Pass 18 progression smoke
- Pass 19 cargo upgrade smoke
- Pass 20 light upgrade smoke
- Pass 27 facing transition smoke

Additional evidence from the release-candidate batch:

- #627 verified local import/startup and launch helper arguments for the default production slice.
- #628 verified the public Web preview, Pages deployment, external `build_info.json`, and browser runtime check for deployed SHA `a529d0d62ee52c4ec5cc498ecdb4636dad723fca`.
- #629 verified production-slice accepted baselines and committed captures, with no current-vs-accepted drift found.
- #630 refreshed README, milestones, roadmap, and project context so new sessions see the release-candidate state first.

## Blockers

No release-candidate blockers remain.

## Deferred Non-Blockers

- #52 and #53 remain optional slice-03 presentation polish.
- Known file-length debt in `scripts/main/main.gd` and `scripts/world/greybox_world.gd` remains tracked by `tools/check_file_lengths.py` as temporary allowlist debt.
- Full-map productionization, enemies, broad economy, complex inventory/loadouts, save-heavy sandbox systems, broad audio systems, procedural generation, broad art replacement, and larger OceanGame expansion remain outside this release-candidate closeout.

## Recommended Next Direction

Pause validation batching and review the release candidate through the local project or public Web preview. If feedback finds a blocker, create a small issue for that blocker. If the release candidate holds up, create the next scoped roadmap batch from the next selected milestone rather than continuing Simple Diver Game 08 hardening.

## Verification

```powershell
python tools/run_release_candidate_validation.py
python tools/check_file_lengths.py
git diff --check
```
