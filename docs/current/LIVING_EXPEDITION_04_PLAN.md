# Living Expedition 04 Plan

Date: 2026-08-08

Amended: 2026-08-09 after owner HOLD

Issues: #1312 original plan; #1335 Mica-response retirement; #1336 BOND timing;
#1323 owner closeout

Status: complete at owner HOLD in milestone #48. The rejected Mica experiment
is retired and the BOND timing correction is deployed. Do not extend this
milestone with another enemy, species, adaptation, map change, or reward.

## Decision

Living Expedition 04 reused the existing `deep_cache_territorial_eel`, guarded
cache, electrocyte harvest, Kite, Mica, and Shock Prod to test whether active
companion choice changed one real-time wildlife encounter.

The implemented proof established four separate outcomes:

- ordinary movement can evade or retreat from the territorial eel;
- Guardian-Pulse Kite can deliberately create a temporary zero-damage opening;
- Shock Prod remains the only damage and defeat authority; and
- only defeat exposes the existing explicit electrocyte harvest.

The proof also attempted to make Drift-Lens Mica predict the eel's lunge. The
owner found that result non-useful even after a focused clarity correction.
That experiment is rejected for this encounter. Mica remains a deliberate
reader of authored moving ecology, not an active eel solution.

## Retained Experience

1. The isolated Day 3 checkpoint has Kite and Mica committed and adapted, with
   Shock Prod and prior progression available.
2. The player may select Kite at the canonical boat for the next sortie.
3. Guardian Pulse can be aimed during warning or lunge to knock the eel back
   and create a short recovery opening without reducing health.
4. The player still owns movement, timing, cache attempts, weapon use, and
   harvest interaction.
5. Shock Prod damage, three-hit defeat, cargo pressure, boat banking, failure,
   reload, and fresh-day restoration retain their existing semantics.
6. Anchor-Fins Kite receives no combat action or free adaptation change.

## Retired Experiment

- `deep_cache_eel_companion_response` no longer lists Mica.
- Near this eel, Mica does not receive `Predict Lunge` and guidance does not
  advertise her as a solution.
- The generic hostile-intent reader remains source-gated and dormant so a later
  authored encounter may evaluate it on its own merits.
- Existing moving-jellyfish `Read Drift` behavior, memory, adaptation, profile,
  and presentation remain unchanged.
- Rejected Mica eel frames are removed from current LE04 capture evidence and
  are not accepted as baselines.

## Meaningful-Change Filter

Keep an encounter action only when it creates a legible decision or changes
what the player can deliberately accomplish. Information that merely restates
an obvious attack, costs scarce oxygen to interpret, or adds command friction
without a useful response fails this filter.

Guardian Pulse remains because it creates a clear, temporary action window.
Mica's eel prediction is retired because it failed this filter. Preserving a
failed experiment as active content would be drift, not iteration.

## Source And State Boundaries

- The production-level generator owns the single eel relationship and its
  Guardian-Pulse response by stable id.
- The relationship references existing eel, cache, harvest, catalog action,
  adaptation, and equipment ids; it owns no geometry or mutable state.
- `CompanionProfileState` remains authoritative for both individuals,
  commitment, active selection, memories, and adaptations.
- `TerritorialHostileController` remains authoritative for eel phase, position,
  health, contact, recovery, and defeat.
- Guardian Pulse may request only a zero-damage support interruption.
- Shock Prod remains the only health mutation path.
- The biological resource owner exposes the electrocyte only after defeat.
- No LE04 feature state belongs in `main.gd` or generated map JSON.

## BOND Timing Correction

The owner also reported that opening the BOND palette appeared to slow only the
player while the eel continued. #1336 corrects that separate control defect with
a whole-simulation tactical pause. Palette input remains live on keyboard and
mobile while player, eel, oxygen, daylight, hazards, companion movement, and
action cooldowns remain frozen until selection closes.

This timing correction must not restore Mica's eel action or change Guardian
Pulse, Shock Prod, map, reward, profile, or progression behavior.

## Validation And Evidence

Automation must prove:

- exactly one source-authored Guardian-Pulse response exists for the eel;
- Mica cannot target this eel and receives no eel-specific guidance;
- moving-ecology `Read Drift` remains unchanged;
- Guardian Pulse changes recovery/position but not health, defeat, or harvest;
- Shock Prod damage and defeat-only harvest remain authoritative;
- ordinary retreat, cargo-full blocking, banking, Retry, connector reload, and
  fresh-day restoration remain deterministic;
- access, topology, cache ownership, profile adaptations, and rewards do not
  change; and
- current desktop/mobile focused captures contain Guardian opening, Shock Prod
  damage, and defeat/harvest states only.

Accepted production baselines remain unchanged. Focused captures stay ignored
review evidence. The complete release suite runs once after the integrated
control correction rather than after every small edit.

## Deferred Work

- a different authored use for hostile prediction
- another species, enemy, memory, or adaptation
- general combat or ecosystem architecture
- map expansion or topology changes
- broad HUD, art, animation, audio, accessibility, or input replacement
- #52/#53 optional slice-03 presentation polish

## Exit Criteria

1. Mica's rejected eel path is absent from active source, guidance, smoke, and
   capture evidence while her ecology role still passes.
2. Guardian Pulse, ordinary evade, Shock Prod defeat, and explicit harvest
   remain stable.
3. BOND command selection affects the complete simulation consistently.
4. Exact Web verification passes on the corrected commit.
5. #1323 records owner HOLD on the original companion-choice experiment and
   closes the milestone without claiming that the prediction was successful.
