# Milestones

This file summarizes the product roadmap. The detailed current roadmap is `docs/current/SIMPLE_DIVER_GAME_ROADMAP.md`.

## Roadmap Decision

As of 2026-07-08, `oceangame2` is no longer organized only around controlled prototype passes. The next product target is a finished small side-view diver salvage game before any larger 2D Subnautica-like OceanGame expansion.

Controlled gameplay and visual passes remain useful, but they are now a validation lane inside the roadmap. Each new issue batch should serve player-facing progress: curiosity, pressure, payoff, remembered places, meaningful route choice, or a reason to try another expedition.

## Completed Foundation

The project has already proven:

- source-authored JSON maps can drive Godot terrain, collision, entities, captures, and previews
- bounded regions from the supplied full sketch can become validated production slices
- `production_slice_01` can support salvage, oxygen, cargo, hazards, route metadata, objective feedback, smokes, captures, baselines, and Web preview verification
- targeted visual and gameplay changes can be reviewed without regenerating or destabilizing the whole scene

## Current Constraints

- Keep `production_slice_01` as the default preview map unless a separate default-preview decision changes it.
- Preserve `maps/full_cave_sketch_01.greybox.json` as a topology draft and planning source.
- Keep icons from the supplied sketch out of terrain conversion unless they are reauthored as JSON entities.
- Grow route scale only when it supports the roadmap, not as automatic whole-map productionization.
- Keep #52 and #53 as optional slice-03 camera/topology polish unless slice-03 presentation becomes the selected goal.

## Current GitHub Milestones

Simple Diver Game 01 through 09 are complete. The active implementation milestone is:

1. OceanGame Expansion 01: Anomaly Survey Foundation

Milestone 09 issues #643-#652 selected the bounded anomaly-survey foundation. Expansion 01 issues #662-#671 implement it in dependency order.

## Current Next Direction

Simple Diver Game 08 release-candidate hardening is complete. Issues #622-#631 completed the release-candidate plan, validation matrix, one-command validation runner, release journey smoke, capture review index, local run verification, public Web export handoff, baseline/capture audit, documentation refresh, and go/no-go closeout.

Milestone 09 closed with a GO for OceanGame Expansion 01. The active outcome is one scanner-backed anomaly survey across `production_slice_01 <-> production_slice_04 <-> production_slice_02`, with one returned discovery and no territorial fauna until Phase B. Keep #52/#53 deferred and do not expand into procedural generation, full inventory/loadouts, save-heavy progression, broad economy, combat/AI, broad art/audio replacement, or full-map productionization.

## Recently Completed Prototype Passes

- #129-#148 completed Controlled Gameplay Pass 04.
- #150-#159 completed Controlled Gameplay Pass 05 and main-file guard work.
- #160-#169 completed Controlled Gameplay Pass 06 timed-salvage readability.
- #170-#179 completed Controlled Gameplay Pass 07 hazard/navigation pressure.
- #180-#190 completed Controlled Gameplay Pass 08 cautious route-scale expansion.
- #191-#199 completed Controlled Gameplay Pass 09 southwest pocket route-decision payoff.
- #201-#209 completed Controlled Gameplay Pass 10 return/banking pressure.
- #213-#222 completed Controlled Gameplay Pass 11 pre-pickup route readability.
- #224-#233 completed Controlled Gameplay Pass 12 oxygen/rest route pressure.
- #236-#245 completed Controlled Gameplay Pass 13 route commitment objective.
- #278-#286 completed Controlled Gameplay Pass 14 start-of-run objective cue.
- #298-#307 completed Controlled Gameplay Pass 15 objective follow-through, including source marker, validation, runtime cue, smoke, capture, visual decision, Web verification, and closeout.
- #320-#329 completed Controlled Gameplay Pass 16 primary dive completion, including source contract, validation, runtime completion gate, smoke, capture, visual decision, Web verification, and closeout.
- #340-#349 completed Controlled Gameplay Pass 17 pry salvage, including source contract, validation, source target authoring, staged runtime interaction, smoke, capture, visual decision, Web verification, and closeout.
- #360-#369 completed Controlled Gameplay Pass 18 session progression, including planning, runtime progression contract, session wallet, one oxygen tank upgrade, overlay feedback, smoke, capture, visual decision, Web verification, and closeout.
- #380-#389 completed Controlled Gameplay Pass 19 cargo capacity progression, including planning, cargo contract, session cargo upgrade, overlay feedback, smoke, capture, visual decision, Web verification, and closeout.
- #400-#409 completed Controlled Gameplay Pass 20 light confidence progression, including planning, light contract, session light upgrade, overlay feedback, smoke, capture, visual decision, Web verification, and closeout.
- #420-#429 completed Controlled Gameplay Pass 21 world-slice connector proof, including planning, connector contract, schema validation, source connector authoring, runtime transition, smoke, capture, visual decision, Web verification, and closeout.
- #502-#511 completed Controlled Gameplay Pass 22 destination payoff, including planning, payoff contract, validation, source target authoring, runtime feedback, smoke, capture, visual decision, Web verification, and closeout.
- #522-#531 completed Controlled Gameplay Pass 23 next-dive objective prompt, including planning, prompt contract, validation, source authoring, runtime result text, smoke, capture, visual/Web verification, and closeout.
- #542-#551 completed Controlled Gameplay Pass 24 relay follow-through, including planning, objective contract, validation, source authoring, runtime feedback, smoke, capture, visual decision, Web verification, and closeout.
- #562-#571 completed Controlled Gameplay Pass 25 final-dive objective seed, including planning, final-dive contract, validation, source authoring, runtime feedback, smoke, capture, visual decision, Web verification, and closeout.
- #582-#590 completed Controlled Gameplay Pass 26 result presentation polish, including planning, result-presentation contract, runtime hierarchy, final-dive cue, smoke, focused capture, visual decision, Web verification, and closeout.
- #602-#610 completed Controlled Gameplay Pass 27 player movement/facing readability, including planning, reproduction, runtime rendering fix, movement evaluation, repeated-reversal smoke, focused capture, visual decision, Web verification, and closeout.
