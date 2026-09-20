# Marl Memory And Night Verification

Issue: [#1392](https://github.com/joeypshell/oceangame2/issues/1392).
Date: 2026-09-19. Base: `9fa3c6e` (#1391 / PR #1400).
Scope: boat commitment, persistent shelter projection, and deliberate night growth.
This is technical evidence, not LE07 owner acceptance or a Ground Pin review.

## Implemented

- The real refuge dig + live eel cycle + sheltered group produces the existing
  identity-bound pending event. Field qualification is unchanged.
- `silt_hound_memory_return.gd` checks the source opportunity's canonical map and
  boat entry. It transfers pending memory before habitat dismissal, so process
  ordering cannot erase it. Failed saves retain a transient retry until reset/reload.
- `earn_companion_memory_for` uses the existing snapshot/save/rollback transaction,
  targeting Marl rather than temporarily changing the active companion. Full cargo
  is irrelevant; no material, score, or equipment reward is added.
- The committed `guarded_the_nest` memory projects a sheltered refuge after reload,
  failure, and later sorties, including when Kite or Mica is selected. No extra
  nursery flag, mutable source field, or profile-version bump is introduced.
- At night, qualified Marl offers **Root Claws** or **Not tonight**. B cycles and
  Space/USE confirms; mobile night mode now includes BOND. Deferral leaves the
  memory intact and permits the next day, with eligibility on a later night.
- Confirmation is deliberate, exact-once, and rollback-safe. The night explanation
  names the event, hooked fins/planted posture, near-floor pin, and stationary
  tradeoff. It explicitly marks the action/changed-fin visuals as not yet available.
- The sortie report exposes Root Claws identity with `ground_pin_available=false`.
  No Ground Pin command or fin-art replacement is implemented here (#1393/#1394).

## Focused Checks

Run from the repository worktree with Godot 4.7:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --script res://scripts/main/smoke/smoke_marl_memory_night.gd --fixed-fps 60
```

The new check is registered in `tools/ci/run_core_smokes.sh`. It exercises the
actual physical dig and authoritative eel, not injected success flags, then checks:

- Field rejection and wrong-map return; failure/reload before commitment.
- Full-cargo fixture, failed save before habitat dismissal, then successful retry
  with Kite selected; exact-once Marl memory and unchanged Kite/Mica histories.
- Unknown identity and wrong-species rejection; no automatic boat/day adaptation.
- Root Claws/Not tonight, repeat deferral, later-night eligibility, failed and
  repeated confirmation, single-slot schema-v3 round trip, and durable shelter.

Passing local regressions: `smoke_marl_refuge.gd`,
`smoke_companion_profile_state.gd` (including v1/v2 migration),
`smoke_companion_memory_night.gd`, `smoke_companion_ecology_observation.gd`,
`smoke_companion_habitat_selection.gd`, and `smoke_mobile_test_controls.gd`
(night BOND touch dispatch included). Headless editor import/startup is clean.
File-length audit and `git diff --check` pass. Applicable PR CI supplies the
combined regression run; no repeated local full-release suite is required.

## Working Visual Evidence

Rendered the actual Main night screen with an isolated in-memory eligible profile,
not the player's normal save, at desktop 1280x720 and landscape-mobile 844x390.
Inspected Root Claws and Not tonight: explanation and confirm controls fit;
night mobile BOND/USE remain reachable and the movement stick is hidden.
The existing narrow text panel remains provisional, not a final HUD redesign.

Local unaccepted outputs: `tmp/living_expedition_07/night_*.png`.
No baseline acceptance, generated captures, `.import` files, source maps, topology,
assets, or hostile behavior changed. Final growth/action presentation and exact
Web verification remain #1394-#1396; owner verdict remains #1397.

## Next

Continue with [#1393](https://github.com/joeypshell/oceangame2/issues/1393): physical
Ground Pin and bounded hostile hold/release ownership. Do not interpret saved
Root Claws as an already implemented action. #52/#53 remain deferred.
