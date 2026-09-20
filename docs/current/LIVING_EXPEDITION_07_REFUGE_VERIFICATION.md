# Marl Refuge Field Event

Date: 2026-09-19. Issue: [#1391](https://github.com/joeypshell/oceangame2/issues/1391).
Contract: [LE07 source/state](LIVING_EXPEDITION_07_SOURCE_STATE_CONTRACT.md).

## Implemented

- The existing Excavate owner runs the same approach, anticipation, dig, impact,
  and completion phases for two distinct outcomes. LE05's deposit still exposes
  normal capacity-limited titanium; the LE07 refuge opens for three passive
  scallops. No duplicate action state machine or mutable source fields.
- The focused Marl event owner reads the source-bound hostile controller's real
  warning-to-lunge transition during this attempt. Only committed, active Marl,
  completed physical digging, a sheltered group, and the present pair qualify
  one identity-bound pending `guarded_the_nest`. The eel still targets the diver.
- Quiet/defeated visits can open the shelter without memory. Interrupted warnings,
  proximity, ordinary material digging/pickup, or replayed completion do not qualify.
- Recall/abandonment cancels an attempt or pending memory. Failure/Retry/reload
  clears field state through Silt Hound control/sortie ownership. An opened refuge
  survives same-day boat abandonment/relaunch; a fresh next-day world restores an
  uncommitted opportunity. Refuge code never revives or mutates the eel.
- Full cargo does not block refuge work. No reward, permanent profile change,
  night option, Ground Pin, map topology, asset replacement, or baseline acceptance.

`burrow_refuge_presentation.gd` is a small source-positioned projection: closed
silt arch, dig disturbance, group retreat, open shelter. Final adaptation art,
main-scene checkpoints, and desktop/mobile review remain #1394/#1396.

## Focused Evidence

`smoke_marl_refuge.gd` uses actual production world/collision, spawned Marl through
the sortie owner, real BOND dispatch, original action phases, and the real eel
controller. The successful route produces one warning and one lunge, zero diver
hits, visible group arrival, and one pending memory. It tests source/profile
immutability, full-cargo independence, repeated commands/callbacks, copied reports,
wrong/uncommitted identity, missing Light, interrupted warning, threat-only,
quiet/defeated visits, Recall, separation, same-day shelter continuity, actual
pending-memory cleanup on failure variants, next-day reset, and teardown.

BOND freezes action/group timers; the existing real-main tactical-pause smoke
protects eel, player, oxygen, daylight, hazards, companion, and mobile timing.
Core runtime CI includes the new focused smoke. Full integrated journey/release
coverage remains #1395, not duplicated for each implementation issue.

```powershell
godot --headless --path . --script scripts/main/smoke/smoke_marl_refuge.gd --fixed-fps 60
godot --headless --path . --script scripts/main/smoke/smoke_silt_hound_excavate.gd
godot --headless --path . --script scripts/main/smoke/smoke_silt_hound_companion.gd
godot --headless --path . --script scripts/main/smoke/smoke_silt_hound_journey_guidance.gd
godot --headless --path . --script scripts/main/smoke/smoke_companion_command_tactical_pause.gd --review-checkpoint=living_expedition_04_start
godot --headless --path . --quit-after 120
python tools/check_file_lengths.py
git diff --check
```

`godot` above means the local Godot 4.7 console executable (see
[local tooling](tooling/local_run.md)). Non-headless working-state inspection:

```powershell
godot --path . --script scripts/main/smoke/smoke_marl_refuge.gd --fixed-fps 60 --capture-marl-refuge
godot --path . --resolution 844x390 --script scripts/main/smoke/smoke_marl_refuge.gd --fixed-fps 60 --capture-marl-refuge
```

Ignored outputs: `tmp/living_expedition_07/refuge/<width>x<height>/`:
`closed.png`, `digging.png`, `sheltered.png`. These inspect working world feedback,
not accepted baselines or a complete player-facing review checkpoint. Headless
cannot capture locally. Treat `SCRIPT ERROR`/`ERROR:` as failures even at exit 0.

## Next Boundary

#1392 must secure this captured individual's pending memory exactly once at the
canonical boat, derive lasting shelter state from secured memory, and offer a
deliberate Root Claws night choice or deferral. Pending here is intentionally not
saved growth. #1393 owns Ground Pin; owner judgement remains #1397.
