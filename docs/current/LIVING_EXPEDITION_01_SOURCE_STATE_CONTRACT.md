# Living Expedition 01 Source And State Contract

Status: implementation contract for milestone #45; target behavior only until
the linked issues merge.

## Purpose

Living Expedition 01 proves one rescued Spark Ray as a persistent individual,
an independent companion, and a directly controlled mount. It adds no second
species, stable UI, turn-based combat, terrain expansion, or broad companion AI.

## Stable IDs

| Role | ID |
| --- | --- |
| Species | `spark_ray` |
| Individual | `spark_ray_juvenile_01` |
| Rescue | `spark_ray_rescue_01` |
| Riding review | `spark_ray_riding_review_01` |
| Base mounted action | `glide_surge` |
| Current memory opportunity | `spark_ray_current_memory_01` |
| Hostile memory opportunity | `spark_ray_eel_memory_01` |
| Memory | `held_the_flow` |
| Memory | `stood_ground` |
| Adaptation | `anchor_fins` |
| Adaptation | `guardian_pulse` |
| Current payoff | `spark_ray_anchor_current_01` |
| Hostile payoff | `spark_ray_guardian_eel_01` |
| Input action | `companion_command` |

These IDs are immutable once source authoring or profile fixtures use them.
Display labels and individual callsign may change independently.

The exact catalog and optional map-record shapes are defined in
`docs/current/LIVING_EXPEDITION_01_MAP_SCHEMA.md`.

## Ownership

| State | Authoritative owner |
| --- | --- |
| Species anatomy, allowed roles, base actions, memory/adaptation relationships | immutable creature catalog |
| Rescue, memory opportunity, context target, and payoff placement | generated map source |
| Individual id, rescue commitment, active selection, earned memories, selected adaptation | versioned companion profile state |
| Position, velocity, follow state, mounted state, target, cooldown, palette selection | transient companion runtime |
| Player or mounted movement dispatch | focused control-mode coordinator |
| Diver or creature hotbar contents | one projection of current control mode |
| Oxygen, daylight, diver health, tools, cargo, boat commitment, failure | existing authoritative owners |

Map JSON must not own mutable individual state. Profile state must not persist
position, velocity, targets, cooldowns, palette state, or mounted state. Creature
fields must not be added directly to `main.gd`.

## Three-Day Proof

1. Day 1 rescue uses one physical, source-authored situation and an already
   understood diver verb.
2. The individual remains sortie-local until the canonical boat commits the
   rescue exactly once.
3. A committed active individual can be ridden on the next launched sortie.
   Riding availability is derived from commitment; it is not a recipe, score
   purchase, blueprint, random roll, or separate profile flag.
4. Day 2 proves follow, recovery, command, mount/dismount, `glide_surge`, and one
   complete memory opportunity.
5. The canonical boat secures the earned memory. Night offers only adaptations
   backed by that individual's committed memories.
6. One deliberate choice applies exactly once. Day 3 shows the selected body,
   behavior, independent action, mounted action, and focused payoff.

## Control Contract

- `B/BOND` maps to `companion_command`; `Q` remains unused by this system.
- Pressing `B` toggles a palette that pauses all gameplay simulation consistently
  while input remains live and shows at most three numbered contextual commands.
- Desktop `1`-`3` directly activates the matching row; `B` or `Esc` closes it.
- The first-proof independent palette may expose recall, mount, and the selected
  adaptation action when each is valid.
- Unmounted diver controls remain `Tab/TOOL` and `Space/USE`.
- Mounted `Tab/TOOL` selects creature actions and mounted `Space/USE` activates
  them; diver tools are unavailable until dismount.
- Touch taps `BOND` to toggle, then uses `TOOL` and `USE` sequentially.
- Invalid mount, dismount, target, range, clearance, or cooldown states return
  immediate visible feedback and do not silently change state.

## Follow And Riding

The active Spark Ray uses readable near, follow, catch-up, separated/worried,
and deterministic recovery states. It uses existing collision and world-query
authority and cannot routinely teleport, cross solid terrain, or pass an
equipment gate alone.

Mounting requires proximity and rider clearance. Mounted movement preserves the
existing collision-active world, camera framing, oxygen drain, daylight passage,
diver health, and route gates. `glide_surge` is a short non-damaging movement
action with readable direction and cooldown. It cannot cross a route the diver's
current equipment cannot cross.

Dismounting requires diver clearance. If clearance is unavailable, the pair
remains mounted and receives a concise denial cue. A major hostile hit applies
existing diver damage/knockback semantics and forces a readable separation; the
proof adds no creature health or permanent injury.

## Memory And Adaptation

`held_the_flow` qualifies only after the pair completes the contracted current
event. `stood_ground` qualifies only after the pair resolves the contracted full
territorial-threat cycle. Idling, repeated exposure, trivial actions, checkpoint
reload, or attacking harmless wildlife cannot qualify either memory.

Anchor Fins adds:

- an independent command that braces one authored current interaction
- a mounted brace action for the same bounded opportunity
- a broader fin-tip silhouette and stable low-current posture

Guardian Pulse adds:

- a deliberately aimed independent support command
- a mounted pulse action selected through the creature hotbar
- readable direction, range, target, discharge, hit or miss, knockback, and
  cooldown

Neither adaptation replaces fins, the Current Stabilizer, the Shock Prod, or an
unrelated equipment gate. Guardian Pulse cannot silently kill, farm rewards, or
become an autonomous damage engine.

## Failure, Retry, And Reload

- Uncommitted rescue and memory progress returns to its pre-sortie state after
  health or oxygen failure and Retry.
- A boat-committed individual, memory, or adaptation persists exactly once and
  cannot duplicate, reroll, or disappear.
- Failure while mounted resets transient control state and restores the normal
  boat/failure owner; free movement cannot continue behind the result state.
- Profile reload restores committed identity and adaptation but begins in normal
  unmounted state.
- Review checkpoints use isolated profiles and cannot mutate normal progress.
- Existing day, equipment, discovery, material, cargo, health, and profile
  migrations remain unchanged.

## Validation And Review

Automation must prove stable IDs, legal relationships, exact-once state,
follow/separation, mount clearance, mode switching, hotbar ownership, consistent
tactical pause, both adaptation branches, equipment-gate authority, failure, reload,
desktop controls, and landscape-mobile controls.

The owner review must complete the three-day path and judge attachment, command
clarity, mounted feel, adaptation payoff, build curiosity, and desire to begin
another expedition. Automation cannot claim those experience outcomes.
