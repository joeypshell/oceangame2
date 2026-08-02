# Active Tool And Wreck Reward Contract

Date: 2026-07-17

Owner: Expansion 13 owner-HOLD correction #1000-#1009

## Active Equipment

The ordered active-tool catalog is:

1. `survey_scanner_1` - display label `Scanner`
2. `salvage_cutter` - display label `Cutter`
3. `shock_prod` - display label `Shock prod`

The controller derives ownership from durable profile capabilities. It skips
unowned entries and never creates capability state.

These capabilities remain passive and do not enter the catalog:

- propulsion fins
- oxygen and cargo capacity
- dive light
- pressure suit
- current stabilizer
- shock-prod capacitor

The capacitor modifies the selected shock prod; it is not another tool.

## Input Ownership

Create named Godot actions:

- `active_tool_cycle_next`: keyboard `Tab`; mobile `TOOL`
- `active_tool_use`: keyboard `Q`; mobile `USE`

Future controller bindings attach to these actions rather than bypassing the
active-tool controller. Direct numbered selection and reverse cycling are
deferred.

Legacy player-facing behavior changes intentionally:

- `Space/USE` uses the selected tool; `Q` is not a separate tool action.
- `Space` is no longer a separate player-facing shock-prod attack.
- proximity is never a cutter-use input.

Automation may call domain helpers directly when testing a domain contract,
but integrated smoke must exercise the shared actions.

## Selection State

- Selection is session runtime state, not a new profile field.
- With no owned active tools, selection is empty.
- On first ownership refresh, select the first owned catalog entry.
- Cycling advances through owned entries and wraps.
- If the selected capability becomes invalid, normalize to the first owned
  entry.
- Map loads, reset, day transition, and profile reload refresh ownership and
  preserve the selected id when still valid.
- Switching away from an in-progress scanner or cutter cancels that interaction
  through the existing domain owner.

## Use Dispatch

The controller reports one of `used`, `unavailable`, `wrong_context`, or
`no_tool` and delegates behavior:

- Scanner: call the existing scanner action once. Its cone, target selection,
  progress, line of sight, and cancellation remain scanner-owned.
- Cutter: require a nearby `cutter_salvage` target, then activate it once.
  Existing frame updates may advance only an activated matching target.
- Shock prod: call the existing attack once. Range, facing, cooldown, damage,
  capacitor effect, and enemy state remain combat-owned.

Wrong-tool proximity cannot invoke another tool. Context feedback should name
the required tool and the cycle/use controls without exposing undiscovered
equipment.

## HUD Contract

One compact unframed or minimally framed control shows:

- selected tool icon or stable symbol
- short selected label
- `Tab Tool | Space/USE` on desktop

The mobile testing overlay exposes `TOOL` and `USE` in reachable positions.
Do not add an inventory grid, recipe list, or permanent explanatory panel.

## Material Presentation

Material source identity remains `material_id`. Rendering maps it to:

- `titanium_scrap`: existing pale metal/scrap direction
- `rubber_sheet`: dark rolled, looped, or bundled elastomer silhouette
- `conductive_coil`: clearly wound spring/coil silhouette

Visuals must remain distinct in silhouette and value, not only hue. Placement,
selection pools, cargo, and recipe quantities do not change.

## Sealed-Wreck Reward

Source target: `salvage_sealed_wreck_cache`

Add source-authored reward metadata:

- `reward_kind`: `discovery`
- `reward_id`: `southeast_wreck_navigation_data`
- `reward_pending_label`: `Wreck navigation data secured | Return to surface boat`
- `reward_commit_label`: `Navigation data logged: Southeast wreck coordinates`
- `reward_next_lead_label`: `Wreck coordinates | Signal continues deep southeast`
- `reward_commit_map_id`: `production_level_01`
- `reward_commit_map_path`: `res://maps/production_level_01.greybox.json`
- `reward_commit_entry_id`: `surface_boat_entry`

Completion is atomic at the target: if cargo rules block the valuable salvage,
the cut cannot complete and the discovery cannot be created. On success, the
valuable salvage enters held cargo and the discovery becomes pending.

Failure or reset before boat return clears pending data and restores the
unbanked target. Canonical-boat return banks salvage and commits the discovery
exactly once. The southeast regional journey requires the committed navigation
data in addition to its existing capability/pressure boundaries.

Existing profiles that already contain `southeast_wreck_archive_discovery`
must migrate as having the navigation data so completed progress is not lost.
Other profiles can reopen the non-persistent sealed target and earn it normally.

## Economy Boundary

The target retains its existing valuable score, but user-facing correction text
calls this **salvage value**, not progression. It is not spendable money yet.

- materials build recipes
- blueprints/knowledge unlock recipes
- unique discoveries unlock routes and objectives
- salvage value measures banked valuables
- future credits require a separate contract and may not replace the first
  three systems

## Protected Invariants

- no map topology, collision, spawn, boat, camera, or slice-fixture changes
- no automatic cutter progress
- no scanner activation from proximity
- no enemy attack without selected shock prod and shared use
- no discovery commit away from the canonical boat
- no loss of cargo/failure restoration or exact-once persistence semantics
- no broad economy, inventory, or tool-upgrade system
