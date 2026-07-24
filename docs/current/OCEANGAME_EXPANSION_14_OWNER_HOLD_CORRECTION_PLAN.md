# OceanGame Expansion 14 Owner-HOLD Correction Plan

Date: 2026-07-24

Status: Locked by #1069 for bounded implementation in #1070-#1077. #1040 and
milestone #40 remain open for the final owner GO/HOLD decision.

## Decision

The owner reviewed exact checkpoint
`f2f27508a07687a480b8a4ac2d9fdaa79556b257` and recorded HOLD. Expansion 14
keeps its existing archive, Current Stabilizer, passive current, relay core,
survey, cargo, failure, and boat-commit chain. The correction makes that chain
readable and makes the already-present combat/scanner/equipment systems behave
coherently.

This is one correction batch, not Expansion 15.

## Owner Evidence

- The Shock Prod bolt appeared, but eel health was hidden, hits did not control
  enemy position, and repeated use made defeat feel random.
- A miss looked like an unexplained semicircle around the player.
- The owner found the left-flow current and salvage beyond it after building the
  stabilizer, but could not identify the intended relay or a reason to scan.
- Scanner behavior did not communicate which objects were identifiable or
  which targets required scan completion.
- Passive equipment had no persistent HUD home while the top cargo strip had
  unused space.

## Combat Contract

- Shock Prod range remains 72 pixels and cooldown remains 0.65 seconds.
- Targeting and presentation use one forward cone with a 35-degree half-angle.
- A ready miss draws a directional electrical discharge to the range edge and
  a small endpoint fizzle. It does not draw a 180-degree semicircle.
- Every valid hit deals one health, moves the eel 44 pixels away from the
  player within its authored territory, and creates a 0.35-second hit reaction.
- The capacitor remains stronger: a warning/lunge hit uses the source-authored
  full recovery duration and cancels that attack.
- A compact world-local health bar appears while the eel is engaged or damaged.
  It reports the authoritative current/max health and visibly reaches zero
  before the defeated eel is hidden.
- Cooldown input produces no fake discharge or damage. Contact damage, player
  knockback, day-local eel defeat, guarded-cache behavior, and no automatic
  combat reward remain unchanged.

## Scanner Contract

The Scanner identifies gameplay-relevant source subjects, not arbitrary terrain
tiles or decorative background shapes.

Supported subject families are:

- salvage and material pickups
- cutter/tool targets
- hostiles
- current gates and regional landmarks
- survey/progression targets
- canonical boat/extraction records

When Scanner is selected, `Q` / mobile `USE` projects the existing forward cone
and deterministically selects the best eligible subject by the established
angle/distance/id ordering.

- Ordinary identification immediately shows a temporary target-local card with
  a short name and type/description. It grants no cargo, score, blueprint,
  discovery, project, capability, or profile mutation.
- A progression survey card says `Hold Q/USE to scan`, shows progress, and
  advances only while use is held, Scanner remains selected, and the subject
  remains in cone, range, and line of sight.
- Releasing use, switching tools, facing away, leaving range, or losing line of
  sight cancels current progress under the existing reset semantics.
- Existing full-cargo independence, pending state, failure cleanup, and
  canonical-boat exact-once commitment remain unchanged.
- The temporary card is world-local near the subject, remains legible at the
  supported review zooms, and does not become a permanent codex or HUD panel.

## Relay Contract

The intended Expansion 14 boundary is
`upper_left_wreck_relay_current` at tiles `x=53, y=57, w=3, h=4`. It pushes
left before `current_stabilizer` ownership. After ownership, the player swims
normally through it in both directions.

There is no `E`, activation prompt, connector, teleport, or map load.

The pocket immediately to its right contains one coherent destination:

- landmark: `upper_left_wreck_relay_landmark`
- visible scan subject/console: `upper_left_wreck_relay_survey`
- cargo payoff: `upper_left_wreck_relay_core`

The relay survey receives explicit source-owned subject and presentation
metadata. Its renderer must show a recognizable console/signal at the authored
scan anchor before the player activates Scanner.

## HUD Contract

- Scanner, Cutter, and Shock Prod remain in the bottom active-tool hotbar.
- The top surface gains a visually separate `EQUIPPED` segment beside `CARGO`.
- The segment is a read-only projection of owned passive capabilities:
  Propulsion Fins, Dive Light, Pressure Suit, Current Stabilizer, and Shock Prod
  Capacitor.
- Cargo quantities and capacity remain authoritative and visually distinct.
- The top strip owns no profile or gameplay state and provides no equipment
  management, drag/drop, inventory grid, or loadout selection.
- Desktop, wide, and iPhone-landscape layouts must remain clear of vitals,
  objectives, the bottom hotbar, and touch controls.

## Source And Ownership Boundaries

- Map/generator source owns explicit relay subject metadata and presentation id.
- A focused world helper may derive informational scan subjects from existing
  gameplay records; it must not infer progression rewards from coordinates.
- `TerritorialHostileController` remains authoritative for eel health, phase,
  position, and defeat.
- `ShockProdController` remains authoritative for range, cooldown, damage, and
  attack result; presentation consumes its report.
- `AnomalySurveyRuntime` and `SurveyInteractionController` retain progression
  scan/pending ownership. Generic identification remains read-only.
- HUD helpers consume profile/runtime reports and own no mutable gameplay state.

## Frozen Issue Set

1. #1069 lock this correction contract.
2. #1070 add scanner subject metadata and validation.
3. #1071 make the relay and scan target readable in world.
4. #1072 implement hold-to-scan and the target-local readout.
5. #1073 correct Shock Prod combat feel.
6. #1074 add passive equipment to the top HUD.
7. #1075 add integrated deterministic coverage.
8. #1076 capture and review only affected visual states.
9. #1077 verify one exact public Web checkpoint and refresh the handoff.
10. Return to #1040 for owner GO/HOLD.

Issues #1071-#1074 may be implemented independently after their contracts are
available. #1075 depends on all four; #1076 depends on #1075; #1077 depends on
#1076. No issue outside #1069-#1077 enters this resolver run.

## Verification Strategy

- Run focused owner tests on each implementation issue.
- Run the integrated release suite once in #1075, not after every issue.
- Regenerate only affected map outputs and captures.
- Compare affected baselines before any visual acceptance.
- Verify the merged exact SHA on normal, fresh-review, checkpoint, reference,
  desktop, wide, and iPhone-landscape Web paths.

## Non-Goals

- no new enemy, weapon, ammo, loot table, or combat reward
- no codex database, research tree, inventory screen, or equipment management
- no terrain/topology expansion, connector, teleport, or current activation key
- no broad HUD replacement or accepted-baseline sweep
- no Expansion 15 selection and no slice-03 work

## Exit Criteria

The correction reaches #1040 when the eel fight communicates aim, hit, health,
recoil, cooldown, and defeat; Scanner identifies ordinary gameplay subjects and
requires held input for progression scans; the correct relay current and scan
console are unmistakable; passive equipment is readable separately from cargo
and active tools; and deterministic, focused visual, mobile, and exact-SHA Web
evidence agree.
