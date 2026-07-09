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

The open GitHub milestones should mirror this roadmap:

1. Simple Diver Game 01: Prototype Stabilization
2. Simple Diver Game 02: Core Diver Loop Vertical Slice
3. Simple Diver Game 03: Salvage Tools And Interaction Set
4. Simple Diver Game 04: Progression And Economy Slice
5. Simple Diver Game 05: World Slice Expansion
6. Simple Diver Game 06: Objective And Run Structure
7. Simple Diver Game 07: Presentation And Game Feel
8. Simple Diver Game 08: Release Candidate
9. Simple Diver Game 09: 2D Subnautica Expansion Planning

## Current Next Direction

Controlled Gameplay Pass 19 completed a second Milestone 04 progression step: banked salvage now supports both one session-only `O2 tank +15` upgrade and one session-only `Cargo +1` upgrade at extraction. The next batch should either add one more tiny light/tool-style unlock or deliberately move to a pressure/payoff-driven Milestone 05 world-slice expansion; do not jump to enemies, procedural generation, full inventory/loadout systems, save files, or broad economy work.

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
