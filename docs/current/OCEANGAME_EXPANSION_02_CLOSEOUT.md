# OceanGame Expansion 02 Closeout

Date: 2026-07-09

Issues: #685-#694

Milestone: OceanGame Expansion 02 `Expedition Day Foundation`

## Decision

**GO** to OceanGame Expansion 03: Seeded Materials And First Tool Project.

Daylight and multiple oxygen sorties now work well enough to organize the game loop. The player has distinct reasons to surface, return to the boat, end a day, and begin the next one. The loop is not yet a durable retention layer by itself: typed materials and one concrete capability project are the next required payoff so another day promises progress rather than only another score run.

Do not add map-scale growth, enemies, broad crafting, or survival taxes before that focused material-to-tool loop is proved.

## Delivered Experience

- One deterministic 300-second daylight budget persists across sorties and connectors.
- Oxygen remains a separate tactical budget and refills at source-derived open surface.
- Open surface does not bank cargo, commit discovery, purchase upgrades, or end the day.
- Boat return offloads cargo and allows another sortie without ending the day.
- Dusk, night-soon, boat action, and surface context fit in the existing compact overlay.
- Voluntary boat return and forced nightfall produce an explicit debrief.
- Forced nightfall clears unbanked cargo and pending discovery while preserving banked day results and durable profile progression.
- `N` starts a clean next morning at the canonical slice-01 boat.
- Night consumes no Food, Water, Power, or other survival resource.

## Ownership And Source Boundaries

- `sortie_state.gd` owns oxygen, held cargo, active/offload state, current map leg, and local failure.
- `expedition_day_state.gd` owns day number, daylight, phase, sortie count, day bank totals, committed discovery ids, and end reason.
- `expansion_profile_state.gd` owns durable capabilities and committed discoveries.
- Focused presentation, debrief, offload, smoke, and capture helpers keep `main.gd` as orchestration debt rather than a new gameplay owner.
- JSON maps, generators, validators, terrain/collision parity, boat rectangles, connectors, and authored camera tests remain authoritative. Expansion 02 changed no map topology.

## Validation Evidence

- `--smoke-expedition-day` covers surface recovery, boat offload, connector persistence, repeated sorties, voluntary debrief, forced nightfall cleanup, next-day reset, and profile reload.
- All 47 GitHub workflow smoke flags passed after integration.
- The full release-candidate validation suite passed at closeout, including map validation/parity and the integrated day smoke.
- Focused day captures were inspected at 1280x720 and 1920x1080.
- All four accepted production-slice baseline comparisons remained clean; no baseline accept command ran.
- Public build `a2dab3c930785aa753495e29c4dbcf24ec06c0be` passed metadata, initialization, request, error, and dual-viewport framing checks.

Visual decision: `docs/current/OCEANGAME_EXPANSION_02_VISUAL_BASELINE_DECISION.md`.

Web evidence: `docs/current/OCEANGAME_EXPANSION_02_WEB_PREVIEW_VERIFICATION.md`.

## Known Risks For Expansion 03

- The 300-second daylight value is a first tuning target, not final balance.
- Map reload currently recreates map-local entity availability. Seeded resources need explicit day ownership and depletion rules before implementation.
- Existing connector/relay behavior predates canonical-boat material commitment. Expansion 03 planning must decide whether typed cargo crosses connectors and where it may be secured without weakening boat-return pressure.
- Session wallet and current session upgrades are not profile-persistent. The first completed tool project must have explicit durable ownership and schema rules.
- The debrief is intentionally only a summary shell; projects and forecasts do not exist yet.
- `main.gd` remains temporary file-length debt at 2,039 lines. New material/tool work must use focused owners rather than growing it.

## Deferred And Rejected

- #52/#53 remain deferred optional slice-03 presentation polish.
- Capability-gated map expansion waits for Expansion 04.
- Practical research, combat, biological resources, daily conditions, and regional growth stay in their named later milestones.
- Emergency Week, overnight Food/Water/Power taxes, arbitrary procedural geography, and shortcut/fast-travel networks remain rejected.

## Expansion 03 Entry Conditions

Before runtime or map authoring, the next issue batch must lock:

1. The exact player promise and one tool-enabled remembered interaction.
2. A minimal typed-material and project-state contract.
3. Deterministic authored candidate selection with guaranteed prerequisites.
4. Day/resource depletion, connector cargo, boat commitment, and profile ownership.
5. Validator, smoke, focused capture, visual decision, Web verification, and closeout boundaries.

Only Expansion 03 should receive the next approximately ten actionable issues. Expansions 04-09 remain directional.
