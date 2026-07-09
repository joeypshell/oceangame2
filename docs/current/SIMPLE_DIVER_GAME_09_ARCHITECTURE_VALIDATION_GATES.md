# Simple Diver Game 09 Architecture And Validation Gates

Date: 2026-07-09

Issue: #651
Milestone: Simple Diver Game 09 `2D Subnautica Expansion Planning`

## Decision

Expansion implementation may begin only through focused owners and the existing controlled production pipeline.

Two no-behavior extractions are required before their related expansion code lands:

1. Extract session progression transaction/presentation wrappers from `main.gd` before adding scanner unlock/profile integration.
2. Extract world query/path/reachability helpers from `greybox_world.gd` before adding survey/fauna world queries.

New source rules, state owners, interactions, fauna behavior, smokes, and captures then live in separate sub-500-line files. The release-candidate runner remains the regression floor.

## Current Debt Snapshot

`python tools/check_file_lengths.py` reports:

- `scripts/main/main.gd`: 2,175 lines, temporary allowlist debt
- `scripts/world/greybox_world.gd`: 1,088 lines, temporary allowlist debt
- `scripts/main/capture_controller.gd`: 500 lines
- three smoke helpers: 497 lines
- one smoke helper: 491 lines
- no non-allowlisted oversized human-authored files

Expansion PRs must not increase either allowlisted file's line count. Near-limit capture/smoke files must not receive new expansion behavior.

## Ownership Boundaries

| Concern | Owner boundary |
| --- | --- |
| Application orchestration | `main.gd` creates owners, routes input/update reports, and refreshes presentation. It does not become the data model for new domains. |
| Existing session progression | `session_progression.gd` owns wallet/current upgrades; extracted runtime wrapper owns purchase coordination and progression text. |
| Profile and expedition discovery | New focused profile/expansion-state owners implement #648; no persistence dictionary in `main.gd`. |
| Map source | Slice-specific Python generators and committed generated JSON remain authoritative. |
| Schema validation | `docs/MAP_SPEC.md` plus greybox validator/test patterns define fields before source authoring. |
| World coordination | `greybox_world.gd` loads data and delegates rendering/state/query helpers behind stable public methods. |
| World queries | New focused query/path helper owns open-water paths, position/cell conversion, extraction/zone lookup where practical. |
| Survey interaction | New survey controller owns timing/cancel/complete; it reports state without mutating cargo. |
| Territorial fauna | New fauna controller owns deterministic state; focused world renderer/state helper owns source instances. |
| Hazard contact | Existing main hazard path remains the single penalty/reset integration point through a narrow report/call. |
| Presentation | Existing overlay/result orchestration consumes helper text/state; no inventory, journal, health-bar, or AI-debug UI. |
| Smokes/captures | New expansion domain files register with current dispatch; do not append to full helpers. |

## Refactor-Before-Growth Gates

### Main Progression Gate

Before scanner unlock/profile behavior:

- move existing progression purchase coordination, wallet/capability query wrappers, and progression overlay/result text into one focused runtime helper
- preserve current `U/C/L/P` input, costs, wallet, four upgrades, light application, reset, connector, and failure behavior
- keep `main.gd` call sites as small delegation points
- run progression, cargo, oxygen, light, current-gate, release-journey, and startup checks
- demonstrate a net reduction in `main.gd`

Do not combine this extraction with scanner implementation.

### World Query Gate

Before survey/fauna world queries:

- move open-water path/query utilities and practical extraction/zone/hazard lookup helpers into a focused helper
- keep current public `greybox_world.gd` method names or explicit delegates so runtime/smoke call sites remain stable
- preserve map loading, source dictionaries, salvage state, collision/parity, coordinates, and path results
- run all map validation, parity, production-slice route smokes, connector smoke, and startup checks
- demonstrate a net reduction in `greybox_world.gd`

Do not mix source schema or map authoring into this extraction.

### New Domain Gate

- Every new source/runtime/smoke/capture file must remain below 500 lines.
- Profile state, scanner unlock, survey interaction, survey rendering/query, fauna rendering/query, and territorial behavior remain separate where ownership differs.
- Prefer a small explicit report/API over shared mutable dictionaries.
- New helpers may reuse existing constants/structured data but must not clone authoritative state.

## Change-Type Validation Matrix

| Change type | Required checks before merge |
| --- | --- |
| Documentation/planning | `python tools/check_file_lengths.py`; `git diff --check`. |
| No-behavior GDScript extraction | Godot import/startup; targeted existing smokes; file lengths; diff check. Use the full RC runner when ownership crosses several core domains. |
| Schema/validator | Positive current maps; focused negative cases using existing test pattern; file lengths; diff check. No runtime behavior in the same issue. |
| Generator/source authoring | Regenerate affected JSON/SVG only; validate affected maps; parity; route/reachability checks; inspect source diff. |
| Profile/expedition state | Missing/invalid/versioned profile tests; reset/hazard/oxygen/connector/commit smoke; existing progression and release-journey smokes. |
| Scanner/survey runtime | Unlock/idempotence, progress/cancel/complete, oxygen, no-cargo, pending/commit/failure smoke; existing timed/pry/cargo smokes. |
| Territorial fauna runtime | Deterministic state/position smoke; existing static/moving hazard, oxygen, cargo restoration, route, and pending-discovery checks. |
| Focused visual change | Non-headless focused capture; `compare-all`; `check-clean --all-slices`; inspect expected and untouched areas. |
| Baseline acceptance | Separate decision issue after comparison; accept only intended configured PNGs; rerun clean check. |
| Web-visible/runtime change | Successful Actions export plus `check_web_preview.cjs <url> --expected-sha <sha>` at both supported viewport checks. |

Treat any Godot `SCRIPT ERROR` or `ERROR:` output as failure even if the process exits `0`.

## Release-Candidate Regression Floor

Keep all 28 current release-candidate gates green. Do not remove a gate to accommodate expansion.

After the anomaly route is implemented and stable, add one deterministic expansion-journey smoke to the runner covering scanner unlock, slice-04/slice-02 travel, survey, return, discovery commit, and retry/failure. Focused scanner/fauna tests remain separate diagnostics.

## Map And Source Gates

- Add source contract and validator before changing a slice generator.
- Modify `create_production_slice_04_map.py` / `create_production_slice_02_map.py`, never Godot terrain polygons.
- Commit regenerated map JSON with its generator change; generated map JSON is source output, unlike caches/builds.
- Require source/destination connector IDs/paths/entries to resolve.
- Require all connector, anomaly, fauna, survey, salvage, hazard, and return cells to be reachable and non-solid.
- Run Godot parity after generation and before visual review.
- Regenerate only affected previews/captures.

## Visual Asset Boundary

- Prefer existing approved terrain, diver, boat/relay, props, and background assets.
- A survey affordance or eel may add one named asset each only if existing/fallback art cannot communicate the behavior.
- Generated assets require a reproducible source script, review sheet, manifest entry, and focused in-engine capture.
- Do not regenerate or replace the whole scene, terrain atlas, player, boat, props, or background for this expansion.
- Keep topology/collision independent from art placement.

## Audio Boundary

- Existing pickup/bank/oxygen/hazard cues remain stable.
- At most one scanner completion cue and one eel warning cue may be considered in separate scoped issues.
- Audio must use the existing cue player, Web user-gesture unlock, graceful missing-asset behavior, and deterministic event logging.
- Silence must not make either interaction unreadable.
- No music, ambience system, voice system, mixer redesign, or broad cue replacement in the first batch.

## Capture And Baseline Boundary

- The 500-line capture controller is closed to expansion additions; use new files under `scripts/main/captures/`.
- Existing near-limit smoke helpers are closed to expansion additions; use new files under `scripts/main/smoke/`.
- Focused captures are review aids, not automatic baseline acceptance.
- Run baseline comparisons before acceptance and reject unrelated terrain/player/boat/relay/prop/camera/UI drift.
- Never commit `.import` sidecars, `exports/`, build output, local profile files, or browser screenshots from verification.

## Issue/PR Sequencing

Keep these as distinct passes:

1. no-behavior owner extraction
2. source/schema contract and validation
3. generator/source authoring
4. focused state/runtime behavior
5. deterministic smokes
6. focused capture
7. visual/baseline decision
8. Web verification
9. closeout

Do not use one PR to combine refactor, map source, runtime, visual asset, baseline acceptance, and deployment evidence.

## Exit Gate

The first expansion implementation batch is ready only when #652 can assign every planned change to an owner above, order the two required extractions before related growth, and name exact checks for each issue.

## Planning Verification

```powershell
python tools/check_file_lengths.py
python tools/run_release_candidate_validation.py --list
git diff --check
```
