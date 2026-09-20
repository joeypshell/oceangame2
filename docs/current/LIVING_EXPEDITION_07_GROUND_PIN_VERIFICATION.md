# Marl Ground Pin Verification

Issue: [#1393](https://github.com/joeypshell/oceangame2/issues/1393).
Date: 2026-09-19. Base: `182e5d0` (#1392 / PR #1401).
Technical action evidence only, not milestone or visual-baseline acceptance.

## Ownership And Behavior

- Learned Root Claws exposes Ground Pin through existing BOND/numbered actions
  and mobile TOOL/USE. Marl stays independent; the diver keeps tools and survival.
- `silt_hound_ground_pin_runtime.gd` reads the existing LE07 context, requires
  its Dive Light/Shock Prod permissions and selected committed Marl, and owns
  approach/cancel/cooldown. No mutable state enters the map or profile.
- `silt_hound_pin_geometry.gd` validates full-body terrain sweeps, floor support,
  equipment-aware paths, and line of sight. A conservative torso-contact envelope
  replaces damage-radius guessing. The actor physically approaches the authored
  anchor at 118px/s, plants for 0.12s, and grips only a low warning/lunging eel.
- A 1.5s acquisition window can whiff. There is no target homing, position snap,
  terrain alteration, ranged freeze, or simultaneous excavation.
- The existing hostile controller alone owns `support_held`, position, health,
  contact, and the maximum 1.75s hold. A weak action-owner reference and explicit
  release callback prevent dangling ownership. Held movement/attack/contact stop.
- Release restores recovery with consumed contact, never a stale lunge. A weapon
  hit releases before normal damage/recoil/defeat. Timeout, Recall, separation,
  lost anchor/contact/LOS, equipment loss, failure, reload/day change, or teardown
  all release. Recall and whiffs retain the 8s cooldown; lifecycle resets clear it.
- BOND freezes actors, hostile/hold clocks and cooldown through the same whole-tree
  pause already used for oxygen/daylight. No time-scale or extra input binding.
- Pin does no damage, grants no immunity or loot, and leaves the 2.5s guarded
  cache attemptable. Electrocyte harvest still requires the existing weapon defeat.
- Only Marl's planted/gripping procedural pose and held-eel health-bar visibility
  change visually. Permanent changed-fin art and review checkpoints remain #1394.

## Focused Verification

```powershell
$godot = 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe'
& $godot --headless --path . --script res://scripts/main/smoke/smoke_marl_ground_pin.gd --fixed-fps 60
python tools/check_file_lengths.py
git diff --check
```

The new smoke is in the core CI lane. Nineteen actual acquisitions use unchanged
source eel warning/lunge/recovery and collision-driven actor motion. Initial
fixture placement is explicit; no hostile position/phase or successful hold is
injected. It checks high/blocked/missing-source/unlearned/defeated targets,
equipment checks, whiff, action exclusion, no refresh/stack, maximum hold,
cooldown and pause, weapon/lethal release, all lifecycle cancellations, safe
follow recovery, unchanged source/profile/cache, and hidden defeat-only harvest.

Passing focused regressions: Guardian Pulse payoff, Marl memory/night and refuge,
Silt Hound rescue/follow, Shock Prod capacitor, Expansion 06 combat foundation,
hazard pressure, whole-simulation tactical pause, and mobile controls. Headless
startup is clean. Applicable PR CI supplies the broader regression run; the
combined LE07 journey/release suite belongs to #1395, not a repeated local run.

## Working Captures

```powershell
& $godot --path . --script res://scripts/main/smoke/smoke_marl_ground_pin.gd --fixed-fps 60 --resolution 1280x720 --capture-marl-pin
& $godot --path . --script res://scripts/main/smoke/smoke_marl_ground_pin.gd --fixed-fps 60 --resolution 844x390 --capture-marl-pin
```

Inspected local held/released scenes in both viewport sizes. Marl's feet reach
the authored ledge, the grip meets the eel, and health remains full. This focused
actor view does not establish final HUD/readability acceptance. Ignored outputs:
`tmp/living_expedition_07/pin/<viewport>/held.png` and `released.png`.
No assets, map JSON, terrain, baselines, captures, or `.import` sidecars committed.

Next: #1394 growth/action readability and isolated review checkpoints, then
#1395 integrated evidence, #1396 visual/Web, and #1397 owner verdict. The latest
owner-accepted Web runtime remains LE06 `16300a9`; #52/#53 remain deferred.
