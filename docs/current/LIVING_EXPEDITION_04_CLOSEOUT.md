# Living Expedition 04 Closeout

Date: 2026-08-09

Issue: #1323 `Run Living Expedition 04 owner closeout`

Status: **HOLD; TECHNICALLY COMPLETE, EXPERIMENT CLOSED**

## Decision

Living Expedition 04 closes on the owner's explicit HOLD. The original proof
asked whether choosing Kite or Mica created two understandable and useful ways
to handle the same territorial eel. It did not.

Guardian-Pulse Kite created a deliberate zero-damage opening and remains part
of the encounter. Mica's eel prediction remained unclear and non-useful after a
focused presentation correction. The owner then reported that the prediction
"is pretty useless" and that BOND appeared to slow the player while the eel
continued. The prediction is retired instead of receiving another correction.

This closeout does not claim player GO, fun, or another-day motivation.

## Retained Proof

- Ordinary movement can evade or retreat from the territorial eel.
- Guardian-Pulse Kite can deliberately knock the eel back and create a short
  recovery opening without dealing damage.
- Shock Prod remains the only eel damage and defeat authority.
- Only defeat exposes the existing electrocyte harvest.
- Cargo-full blocking, boat banking, Retry, reload, and fresh-day restoration
  retain their existing semantics.
- BOND now pauses the complete gameplay simulation during command selection;
  keyboard and mobile command input remain active while player, hostile,
  companion, oxygen, daylight, hazards, and cooldowns remain frozen.

## Rejected Experiment

- Mica is no longer an active response to `deep_cache_territorial_eel`.
- Eel guidance, command rows, journey smoke, and current capture evidence do
  not present `Predict Lunge` as a solution.
- Mica keeps the owner-approved moving-ecology `Read Drift` role from Living
  Expedition 03.
- The source-gated generic hostile reader remains dormant future material. It
  may be reconsidered only for a separately authored encounter where advance
  information creates an obvious action or route decision.

The design lesson is stricter than "make the prediction clearer": companion
actions must change a viable choice or a deliberate outcome. Merely describing
an attack already visible under oxygen and daylight pressure is not enough.

## Issue And PR Record

| Issue | Pull request | Merge | Result |
| --- | --- | --- | --- |
| #1312 | [#1313](https://github.com/joeypshell/oceangame2/pull/1313) | `ea6af24` | Selected the bounded encounter proof |
| #1314 | [#1324](https://github.com/joeypshell/oceangame2/pull/1324) | `188ed9d` | Locked source and state ownership |
| #1315 | [#1325](https://github.com/joeypshell/oceangame2/pull/1325) | `d0cfe95` | Added relationship validation |
| #1316 | [#1326](https://github.com/joeypshell/oceangame2/pull/1326) | `f4f4c00` | Authored the eel relationship and checkpoint |
| #1317 | [#1327](https://github.com/joeypshell/oceangame2/pull/1327) | `c862e4c` | Implemented the now-rejected Mica experiment |
| #1318 | [#1328](https://github.com/joeypshell/oceangame2/pull/1328) | `1c18f78` | Refined Guardian Pulse feedback |
| #1319 | [#1329](https://github.com/joeypshell/oceangame2/pull/1329) | `521801b` | Integrated encounter outcomes |
| #1320 | [#1330](https://github.com/joeypshell/oceangame2/pull/1330) | `656aa12` | Added deterministic journey coverage |
| #1321 | [#1331](https://github.com/joeypshell/oceangame2/pull/1331) | `ce6f23f` | Recorded focused visual evidence |
| #1322 | [#1332](https://github.com/joeypshell/oceangame2/pull/1332) | `c87e273` | Recorded the initial exact-Web candidate |
| #1333 | [#1334](https://github.com/joeypshell/oceangame2/pull/1334) | `80bdef4` | Tried one bounded clarity correction |
| #1335 | [#1337](https://github.com/joeypshell/oceangame2/pull/1337) | `c66f129` | Retired Mica's active eel response |
| #1336 | [#1338](https://github.com/joeypshell/oceangame2/pull/1338) | `bbcc255` | Corrected BOND to tactical pause |

## Technical Evidence

Corrected runtime `bbcc255fb35339bb62aa5b2626526490b33d596b` passed:

- [Godot Smoke run 31345781298](https://github.com/joeypshell/oceangame2/actions/runs/31345781298):
  source/map validation, core runtime, and regional journey jobs
- [Progression Audit run 31345781382](https://github.com/joeypshell/oceangame2/actions/runs/31345781382):
  progression relationship audit
- [Godot Web Export run 31345781293](https://github.com/joeypshell/oceangame2/actions/runs/31345781293):
  exact build, browser checks, and GitHub Pages deployment
- an independent public Chromium check against the same full SHA, including the
  isolated Living Expedition 04 checkpoint, desktop/wide/mobile framing, and
  rendered mobile controls

`LIVING_EXPEDITION_04_VISUAL_DECISION.md` records focused evidence without an
accepted-baseline change. `LIVING_EXPEDITION_04_WEB_VERIFICATION.md` records the
corrected deployment and browser evidence.

## Boundaries Preserved

- No map, topology, reward, profile, progression, resource, or asset changed.
- No new species, enemy, memory, adaptation, or combat framework was added.
- Kite and Mica remain the complete current roster.
- #52/#53 remain deferred optional slice-03 presentation work.

## Next Decision

No new implementation milestone is committed by this closeout. A separate
direction audit should select one bounded proof only if it creates a clearer
player purpose and a companion action with an immediately legible payoff. Do
not restore Mica's eel prediction or add a third species by default.

## Verification

```powershell
python tools/check_file_lengths.py
git diff --check
```
