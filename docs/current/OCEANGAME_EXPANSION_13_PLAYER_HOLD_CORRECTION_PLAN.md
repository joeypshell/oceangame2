# OceanGame Expansion 13 Player-HOLD Correction Plan

Date: 2026-07-17

Planning issue: #980

Player gate: #969

## Decision

Expansion 13 is on **HOLD**. The earlier `go` was a workflow-continuation
instruction, not player approval. Milestone #39 and #969 remain open while one
bounded correction proves a believable scanner-to-cutter journey and a clearer
reason to keep exploring.

Do not select Expansion 14 or add another region, tool tier, enemy, economy
layer, or map transition during this correction.

## Confirmed Problems

The current implementation breaks progression causality:

- `GreyboxSurveyTargets.target_at` accepts a scan whenever the player is inside
  a target rectangle; facing, range from a scanner beam, and terrain occlusion
  do not matter.
- Every survey subject is rendered as the same haze and ellipse rings, so the
  player scans an abstract marker rather than an object in the world.
- `AnomalySurveyRuntime.COMMIT_RESULT` hardcodes a cutter-plan reward while the
  source target only describes a generic anomaly.
- `salvage_cutter_project` treats `lower_right_anomaly_discovery` as knowledge;
  there is no explicit salvage-cutter blueprint identity or physical source.
- Project and objective presentation can announce the next construction task
  without first making the discovery, place, or reason for that task matter.

These are structural loop failures. New HUD wording or prettier circles alone
would not resolve the HOLD.

## Target Experience

The correction proves this complete causal chain:

1. A prior finding or remembered sealed target leaves one broad maintenance
   signal beyond the existing east current.
2. The scanner-owning player reaches a recognizable, partially concealed wreck
   artifact in unchanged contiguous geography.
3. The player faces the artifact and presses `Q/SCAN`. A short wireframe cone
   projects from the diver; proximity alone does nothing.
4. The timed scan advances only while the artifact remains in the cone and in
   line of sight. Moving, turning away, leaving range, failure, or losing the
   target cancels progress.
5. The scan identifies a salvage-cutter maintenance blueprint. It remains
   pending knowledge until the player returns to the canonical surface boat.
6. Boat commitment explicitly reports `Blueprint recovered: Salvage cutter`.
   Only then does the Ti2/Coil1 project tracker appear.
7. The player gathers and banks the recipe materials, ends the day at the boat,
   and builds the cutter during night debrief.
8. The next lead points back to a previously seen sealed wreck target. Cutting
   it produces a concrete payoff and one broad next mystery rather than another
   unexplained project row.

The intended motivation is curiosity, preparation, a changed capability, and
payoff in remembered geography. It is not a tutorial checklist.

## Scanner Contract

### Acquisition

- A `Q/SCAN` press emits the scanner pulse. Mobile `SCAN` uses the same action.
- The initial proof uses a runtime-owned cone six source tiles long with a
  30-degree half-angle, projected horizontally from the diver's facing sign.
- A target is eligible only when its scan anchor is in front of the diver,
  inside the cone, within range, and connected by an unobstructed terrain
  line-of-sight query.
- If multiple subjects qualify, choose deterministically by smallest angular
  difference, then distance, then stable source id.
- A missed pulse briefly shows the field and reports no return. It does not
  activate the nearest off-axis or behind-player target.

### Progress And Cancellation

- One press activates the eligible subject; no continuous key hold is required.
- The cone remains visible while timed progress is active.
- Progress continues only while the same subject remains eligible. Moving out
  of range, turning away, terrain occlusion, failure, or reset cancels to zero.
- Oxygen, daylight, hazards, cargo, and movement continue under their existing
  owners. Scanning remains independent of cargo capacity.
- Completed pending knowledge still commits only at the canonical boat.

### Presentation

- Show a restrained wireframe cone boundary during a pulse or active scan.
- Highlight/bracket only the acquired physical subject and show compact
  progress. Do not leave a permanent glowing scan volume in the world.
- Artifact, resource, environment, and creature subjects must have readable
  physical presentation. A generic circle is not the subject.
- Debug outlines may still expose source rectangles under the existing debug
  flag, but normal play must not render those rectangles or universal rings.

## Blueprint And Profile Contract

- Add explicit durable knowledge id `salvage_cutter_blueprint`.
- The cutter project requires that id, not the generic
  `lower_right_anomaly_discovery`.
- The authored artifact is the only source for this blueprint in the corrected
  fresh-profile journey. Its source metadata names the reward; runtime text may
  not infer a cutter from target type or hardcoded target id.
- Existing profiles that completed the old anomaly or cutter project must
  migrate without losing valid progress. A completed cutter implies the new
  blueprint; an old committed anomaly may grant the replacement blueprint once
  for compatibility.
- No cutter recipe, material counts, `BUILD`, or project-ready prompt appears
  before the blueprint commits at the boat.
- After commitment, the existing material and night-build semantics remain:
  Ti2/Coil1, banked materials only, build during debrief, exact-once durable
  capability.
- Optional later projects must not replace the main place-based lead merely
  because they are the next row in the project catalog. Their own knowledge
  provenance remains follow-up work unless this correction already has an
  authored source.

## Source-Of-Truth Boundaries

- Update the focused production source helper, then regenerate
  `production_level_01` and its SVG. Do not hand-edit generated JSON or Godot
  scene geometry.
- Keep terrain, collision, spawn, boat, pressure/current zones, and slices
  01-04 unchanged.
- Replace the abstract lower-right anomaly presentation with one named wreck
  artifact and source-authored scan anchor/reward metadata in the existing east
  pocket. Do not add a new chamber or connector.
- Validation must distinguish physical subject kind from reward kind and reject
  blueprint rewards on generic resource/environment signals.
- Scanner cone geometry belongs to the scanner runtime, not per-map tuning.
  Source owns subject identity, anchor, physical presentation, reward, timing,
  clue, finding, and canonical commit metadata.

## Objective And UI Boundaries

- Main guidance names a place, signal, object, obstacle, or return goal. It does
  not expose undiscovered project recipes.
- The project tracker appears immediately after valid blueprint commitment and
  hides after construction.
- The sequence is: broad clue, scanner field feedback, identified artifact,
  pending boat return, explicit blueprint, recipe/material progress, night
  build, remembered cutter target, payoff.
- Temporary scan/progress/pending feedback may replace the main clue while
  relevant and then clear. Permanent HUD growth is not part of the correction.
- The shock prod, stabilizer, and other optional project rows may not preempt
  this main journey with unexplained `locked` text.

## Planned Issue Batch

1. Add physical scan-subject and explicit blueprint-reward schema/validation.
2. Author the hidden cutter-blueprint artifact through the production-level
   source pipeline with one named visual subject.
3. Implement deterministic forward-cone and terrain-line-of-sight acquisition.
4. Add scanner field, target highlight, progress, miss, and mobile presentation.
5. Rewire cutter blueprint/profile migration and knowledge-gated project HUD.
6. Integrate the place-based clue, pending return, night build, sealed-target
   return, and payoff without optional-project preemption.
7. Add deterministic progression, scanner-cone, cancellation, migration,
   objective, and full-journey smoke coverage.
8. Capture and review the corrected desktop/mobile journey, accept only
   intentional differences, and verify the exact public Web candidate.
9. Return to #969 for a real fresh-profile player GO/HOLD.

Create the implementation issues only after this plan merges. Freeze them with
#969 under milestone #39 and do not add unrelated open work.

## Validation And Review

- schema negative cases for generic-subject blueprint rewards, missing physical
  presentation, invalid reward ids, and invalid anchors
- generator repeatability, full-level validation, reachability, progression
  graph, parity, and unchanged terrain/slice fixtures
- focused cone tests: ahead, behind, off-angle, out-of-range, wall-occluded,
  deterministic tie-break, turn-away cancel, move-away cancel, and mobile action
- fresh and migrated profile tests proving no recipe before knowledge and no
  valid cutter loss
- full journey proving artifact scan, boat commitment, recipe collection,
  night build, sealed-target return, payoff, failure cleanup, and reload
- focused desktop/mobile captures before any baseline decision
- exact-SHA Web metadata, initialization, framing, touch, request, and console
  checks before player review

## Non-Goals

- no full scanner catalog, bestiary, free-aim cursor, minimap, inventory, or
  crafting-tree UI
- no procedural artifact placement or random required progression
- no map topology, connector, teleport, shortcut, or fast-travel change
- no new region, enemy, weapon tier, material family, economy, survival tax, or
  broad art replacement
- no attempt to fix every later blueprint source in this correction
- no slice-03 polish; #52/#53 remain deferred

## Exit Criteria

The correction returns to #969 only when a fresh profile can understand why it
is searching, deliberately scan a physical artifact in front of the diver,
bring home an explicit cutter blueprint, see the recipe only after discovery,
build it at night, and use it on a remembered sealed target for a worthwhile
payoff without any abstract circle granting an unrelated tool.

Exit question: **Did the scanner feel like a deliberate exploration tool, and
did discovering, building, and returning with the salvage cutter create a clear
reason to keep playing rather than another arbitrary task?**
