# Milestones

Last updated: 2026-07-09

This is the compact milestone index. Detailed direction lives in:

- `docs/planning/OCEANGAME_PHASE_2_ROADMAP.md`
- `docs/planning/CAPABILITY_RESOURCE_PROGRESSION_MATRIX.md`
- `docs/current/OCEANGAME_EXPANSION_02_PLAN.md`

## Current State

Simple Diver Game 01-09 and OceanGame Expansion 01 are complete. Expansion 01 issues #662-#671 proved a scanner-backed anomaly journey across `production_slice_01 <-> production_slice_04 <-> production_slice_02`, exact return/commit state, deterministic failure cleanup, focused visual review, and public Web deployment.

Phase 2 is now selected. Its organizing loop is daylight with multiple oxygen sorties, boat-only banking, night debrief/preparation, material-and-knowledge projects, capability-gated map returns, practical research, enemies/weapons, and biological resources.

Emergency Week and overnight Food/Water/Power survival taxes are rejected. Shortcut and fast-travel networks are also rejected; the player continues to travel through remembered geography.

## Planning Horizons

- Committed: Expansion 02 has the active ten-issue batch #685-#694.
- Directional: Expansions 03-09 have open milestones with goals and exit criteria, but no issue batches yet.
- Vision: production content, vehicles, broad crafting, final art/audio, accessibility, input support, balance, save hardening, and release work remain intentionally un-ticketed.

## Open GitHub Milestones

1. [Expansion 02: Expedition Day Foundation](https://github.com/joeypshell/oceangame2/milestone/28) - daylight, open-surface oxygen, boat banking, multiple sorties, and night transition.
2. [Expansion 03: Seeded Materials And First Tool Project](https://github.com/joeypshell/oceangame2/milestone/29) - typed materials, authored candidate pools, one project, and one active tool.
3. [Expansion 04: Capability-Gated Map Progression](https://github.com/joeypshell/oceangame2/milestone/30) - one remembered place opened by a diver capability.
4. [Expansion 05: Practical Research Foundation](https://github.com/joeypshell/oceangame2/milestone/31) - scans and samples that change preparation and progression.
5. [Expansion 06: Combat Foundation](https://github.com/joeypshell/oceangame2/milestone/32) - health, one weapon, one hostile enemy, and readable defeat/recovery.
6. [Expansion 07: Biological Resources And Weapon Progression](https://github.com/joeypshell/oceangame2/milestone/33) - passive/hostile creature materials and one equipment progression step.
7. [Expansion 08: Daily Conditions And Enemy Ecology](https://github.com/joeypshell/oceangame2/milestone/34) - readable seeded opportunities inside stable geography and a broader small ecology.
8. [Expansion 09: Regional World Growth](https://github.com/joeypshell/oceangame2/milestone/35) - memorable authored regions through the JSON pipeline.

## Active Issue Order

1. #685 plan the Expansion 02 experience contract.
2. #686 define sortie/day/profile state ownership.
3. #687 implement deterministic daylight runtime.
4. #688 separate open-surface oxygen from boat banking.
5. #689 implement multiple sorties per day.
6. #690 add compact daylight and end-day presentation.
7. #691 add night debrief and next-day transition.
8. #692 add integrated smoke and CI/release coverage.
9. #693 add focused captures and visual review.
10. #694 verify Web deployment and record GO/HOLD closeout.

## Roadmap Rules

- Do not create issue batches for Expansions 03-09 until the preceding closeout selects the next milestone.
- Keep controlled passes as validation/review structure, not as the product roadmap.
- Keep `production_slice_01` as the default boat hub unless a separate source-driven decision changes it.
- Preserve source-authored maps, reachability, parity, focused captures, and public Web verification in every milestone.
- Keep #52/#53 deferred optional slice-03 polish unless slice-03 presentation becomes the selected goal.
