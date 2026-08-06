# Monster Species Design Bible

Date: 2026-08-06

Status: Directional planning draft. Spark Ray and Veil Cuttle are implemented.
All other names, ids, abilities, habitats, and branches remain provisional until
a later owner-approved milestone selects one. This document does not authorize a
third-species implementation before the Living Expedition 03 player gate closes.

## Purpose

Define a recognizable initial monster roster for OceanGame without turning the
game into an elemental chart, a collection of utility keys, or a huge catalog of
interchangeable pets.

An OceanGame monster is an exaggerated but ecologically credible underwater
organism with:

- a body plan readable in silhouette;
- a distinctive wild behavior before it becomes a companion;
- agency and a physical reason to bond with the diver;
- one headline expedition verb;
- meaningful memories that can change the same individual in different ways;
- relationships with wildlife, threats, resources, and a remembered region; and
- a clear reason to choose it for tomorrow's expedition.

The roster should feel mixed rather than uniformly cute or hostile. Some species
may be immediately sympathetic, some strange, and some intimidating until their
behavior is understood.

## Signature Growth Grammar

Every bondable species follows the same product grammar:

```text
species anatomy defines credible possibilities
-> wild behavior teaches the player what the body can do
-> one physical relationship earns trust
-> a shared expedition event becomes a memory
-> night consolidation selects a visible adaptation
-> bounded use makes handling more fluent without becoming an XP grind
```

Species are not classes. Adaptations do not add arbitrary fire, water, electric,
or poison coverage. They intensify something the body, ecology, and individual
history already make believable.

## Roster Structure

The directional roster contains eight bondable species. That is enough to
support meaningful expedition choice without requiring a giant stable, dozens of
animations, or a broad combat rewrite.

The first production core is four species:

1. Spark Ray: embodied movement, current handling, and protective interruption.
2. Veil Cuttle: ecological interpretation, concealment, and behavior reading.
3. Silt Hound: material prospecting, buried-life tracking, and ground control.
4. Breaker Mantis: deliberate combat, armor breaking, and precision harvesting.

The remaining four provide later contrast:

5. Rivetback: interaction stability, cover, and wreck-field defense.
6. Lumenjaw: lure, decoy, and predator-attention control.
7. Ribbon Drake: agile pursuit, open-water herding, and a second mounted style.
8. Choir Bloom: distributed colony behavior and area coordination.

Implement one species at a time. A directional roster is not an issue batch.

## Species Design Template

Before a species can receive source or runtime work, define:

| Field | Required answer |
| --- | --- |
| Fantasy | What makes this organism memorable in one sentence? |
| Silhouette | Which body proportions remain recognizable at gameplay zoom? |
| Locomotion | How does it idle, travel, catch up, separate, and recover? |
| Wild behavior | What does the player observe before bonding? |
| Ecology | What does it seek, avoid, hunt, protect, or depend on? |
| Bond path | Why does one individual choose the boat and diver? |
| Base verb | What deliberate action changes expedition play? |
| Control role | Independent, mounted, or credibly capable of both? |
| Memory branches | Which consequential events support mutually legible growth? |
| Adaptation payoff | What changes in body, behavior, and mechanics next morning? |
| Resource relationship | What materials or biological knowledge surround it? |
| Map relationship | Which region and prior diver access make the encounter credible? |
| Limits | Which equipment, survival, or geography authority must remain intact? |
| Tomorrow reason | Why choose this individual for another sortie? |

A species fails review if its description still works after replacing its name
with "pet," if its ability could be a tool icon, or if a recolor is its clearest
adaptation.

## Directional Roster

| Species | Headline verb | Role | Mounted | Tomorrow reason |
| --- | --- | --- | --- | --- |
| Spark Ray | ride / brace | movement and guard | yes | cross known water with stable handling or interrupt a threat |
| Veil Cuttle | reveal / read | ecology and deception | no | understand a living behavior or expose a hidden relationship |
| Silt Hound | track / dig | prospecting and control | no | locate useful material candidates and buried organisms |
| Breaker Mantis | stagger / fracture | combat and precision harvest | no | confront armor or recover a high-grade sample deliberately |
| Rivetback | stabilize / shield | interaction support and defense | no | protect a long wreck interaction or hazardous extraction |
| Lumenjaw | lure / decoy | attention control and observation | no | draw out elusive wildlife or break a predator pursuit |
| Ribbon Drake | chase / herd | agile movement and pursuit | yes | cover open-water distance or influence a moving group |
| Choir Bloom | zone / coordinate | area support and crowd control | no | shape a multi-creature encounter without hidden damage |

### Spark Ray

**Fantasy:** A curious bioelectric ray that becomes a responsive living board
and protective partner rather than a vehicle.

- Silhouette: broad kite wings, narrow electric tail, low mounted posture.
- Wild behavior: reads currents and holds position against unstable flow.
- Bond path: physical rescue, canonical-boat commitment, next-sortie trust.
- Base role: independent follow plus direct mounted movement and Glide Surge.
- Implemented branches: Held the Flow -> Anchor Fins; Stood Ground -> Guardian
  Pulse.
- Limits: never replaces Fins, Shock Prod, pressure protection, light, oxygen,
  collision, or another access owner.
- Choice identity: the stable all-round movement partner with a guard branch.

### Veil Cuttle

**Fantasy:** A watchful chromatophore creature that notices relationships in the
water before the diver knows where to look.

- Silhouette: compact mantle, long veil fins, eye-led hovering, ribbon-like
  chromatophore responses.
- Wild behavior: investigates motion, changes pattern around migration traces,
  and avoids direct confrontation.
- Bond path: aid and observation lead to a compact boat habitat and deliberate
  next-sortie selection.
- Base role: independent sensing and Reveal Trace.
- Implemented branch: Followed the Bloom -> Drift Lens / Read Drift.
- Future branch space: a concealment or decoy memory may deepen its existing
  chromatophore anatomy, but must not become invisibility that erases danger.
- Limits: never replaces Scanner, Dive Light, map knowledge, or hard access.
- Choice identity: the partner for ecology, mystery, and advance warning.

### Silt Hound

**Fantasy:** A broad-headed sea-robin monster that runs on six finger fins,
listens through the seafloor, and digs with sudden whole-body bursts.

- Silhouette: low wedge head, six walking rays, whisker fans, whip tail.
- Wild behavior: follows mineral seepage and buried prey, leaving readable dig
  fans and false starts instead of glowing resource markers.
- Bond path: the diver protects a nesting route during a silt surge and returns
  a displaced brood stone rather than capturing the animal.
- Base role: `silt_read`, a deliberate nearby read of source-authored buried
  candidates and recent underground movement.
- Memory branch A: Followed the Seep -> **Vein Whiskers**, improving direction
  and confidence when prospecting guaranteed and daily material candidates.
- Memory branch B: Guarded the Nest -> **Root Claws**, enabling one aimed pin or
  trip against a small mobile threat without hidden damage.
- Resource relationship: titanium-bearing nodules, rubber-producing burrow
  organisms, shell fragments, and rare tool-grade seams.
- Limits: does not create resources, reveal the whole map, bypass a tool, or make
  required materials depend on an unlucky spawn.
- Choice identity: the best first new species because it connects exploration,
  random authored materials, recipes, and living behavior without duplicating
  Kite or Mica.

### Breaker Mantis

**Fantasy:** A territorial prism-eyed crustacean whose asymmetric striking arms
can read and break armor with frightening precision.

- Silhouette: tall eye stalks, one hammer club, one narrow sampling spear,
  segmented tail held like a spring.
- Wild behavior: performs warning displays, tests shells, and attacks only after
  a readable escalation cycle.
- Bond path: the diver respects its display, survives or redirects a territorial
  conflict, then protects the individual during a vulnerable molt.
- Base role: a deliberate short-range parry/strike with visible aim, windup,
  impact, recoil, and cooldown.
- Memory branch A: Broke the Charge -> **Thunder Club**, specializing in damage,
  stagger, and knockback against armored threats.
- Memory branch B: Read the Fracture -> **Prism Sight**, exposing a short harvest
  window that the diver must complete with the correct tool.
- Resource relationship: armor plates, electro-receptive tissue, prism shell,
  and upgraded material samples from defeated or safely molted wildlife.
- Limits: does not make every fight mandatory, replace all weapons, auto-attack,
  or turn harmless wildlife into a resource farm.
- Choice identity: the combat and precision-harvest specialist after the combat
  loop is ready to support it.

### Rivetback

**Fantasy:** A heavy hermit-crab monster that builds an evolving shell from
wreckage and treats structural failure as a territorial threat.

- Silhouette: low armored body, mismatched claws, tall recognizable scrap shell.
- Wild behavior: tests debris, changes shells, braces collapsing wreck pieces,
  and competes with scrap-feeding wildlife.
- Bond path: the diver returns a stolen shell core and helps the individual hold
  a wreck collapse long enough for both to escape.
- Base role: stabilize one active interaction so movement, recoil, or a nearby
  hazard does not erase legitimate progress.
- Branches: **Bastion Shell** for cover/interception; **Rig Claw** for longer
  stabilization and safe sample handling.
- Limits: does not replace Cutter, create cargo slots by default, or open a
  matching Rivetback lock.
- Choice identity: the partner for wreck recovery and dangerous long actions.

### Lumenjaw

**Fantasy:** A cloak-finned angler monster that speaks to the ecosystem by
changing the rhythm, color, and direction of its lure.

- Silhouette: narrow jaw, high lure mast, draped fins that collapse during a
  burst.
- Wild behavior: draws prey into view, steals another predator's attention, and
  goes dark when threatened.
- Bond path: the player learns its lure grammar and helps free it from a larger
  predator that has copied its signal.
- Base role: deliberately place a short-lived lure or decoy that affects
  attention, never hidden health values.
- Branches: **Beacon Crown** for observation and herding; **Blackwake** for
  pursuit breaks and retreat support.
- Limits: does not replace Dive Light, erase all aggro, or summon required
  wildlife from nowhere.
- Choice identity: the partner for elusive subjects and dangerous predator
  routes.

### Ribbon Drake

**Fantasy:** A long sea-dragon mount whose body writes a visible wake that nearby
wildlife instinctively follows or avoids.

- Silhouette: serpentine body, sail fins, hooked tail, diver seated low behind
  the head.
- Wild behavior: races current edges and bends schools without attacking them.
- Bond path: repeated noncompetitive escort through a migration route earns a
  voluntary close approach and eventual ride.
- Base role: fast, precise mounted pursuit and one deliberate herding wake.
- Branches: **Slipstream Crest** for acceleration and evasive handling; **Coil
  Ward** for an orbiting intercept and safer escort.
- Limits: uses the same equipment permissions as the diver, cannot defeat current
  gates through speed, and must feel different from Kite's stable glide.
- Choice identity: the open-water movement and moving-target specialist.

### Choir Bloom

**Fantasy:** A bonded siphonophore colony whose stable identity lives in a
recognizable arrangement of many glowing bodies rather than one animal.

- Silhouette: curved central ribbon, five to seven large light nodes, trailing
  capture filaments kept clear of the diver.
- Wild behavior: separates under danger, recombines through patterned light, and
  coordinates smaller organisms around a shared field.
- Bond path: the diver reunites scattered colony sections over meaningful
  encounters; the complete colony chooses to follow as one individual record.
- Base role: place one bounded formation zone with an explicit purpose and
  duration.
- Branches: **Sanctuary Chorus** for warning and non-damaging protection;
  **Hunter Chorus** for marking, slowing, or aligning a target for deliberate
  follow-up.
- Limits: no passive global aura, oxygen generation, hidden damage, or multiple
  active-party loophole.
- Choice identity: the unusual area-control partner for multi-creature scenes.

## Ecology Clusters

Do not author a bondable species alone. Each regional cluster needs at least one
living relationship that exists before and after recruitment.

| Region archetype | Prior diver access | Bondable focus | Resource or passive wildlife | Threat or rival | Authored relationship |
| --- | --- | --- | --- | --- | --- |
| current reef | Fins | Spark Ray | filter skates / current larvae | territorial eel | ray braces while small life shelters in its wake |
| kelp migration | Scanner and safe route | Veil Cuttle | jellyfish bloom / reef shoals | bloom patrol | cuttle reads migration evidence and animal response |
| silt basin | reachable floor plus sampling tool | Silt Hound | mineral nodules / burrow clams | buried ambusher | hound distinguishes food trails from mineral seepage |
| prism shelf | weapon and viable evade route | Breaker Mantis | plated urchins / molted shell | armored hunter | mantis display and fracture behavior reveal combat windows |
| wreck garden | Cutter | Rivetback | scrap mites / shell builders | chain-jaw scavenger | crab competes for shells and stabilizes shifting debris |
| dark chimney | Dive Light | Lumenjaw | glow minnows / blind grazers | lure mimic | lure grammar changes approach and pursuit behavior |
| open current channel | Fins | Ribbon Drake | migrating school | wake hunter | drake bends the group's route through body wake |
| abyssal colony field | pressure protection | Choir Bloom | drift polyps / sample colonies | colony predator | separated nodes signal, regroup, and defend a shared field |

Names in this table are design handles, not approved catalog or map ids.

## Map And Upgrade Relationship

- Diver equipment remains the predictable requirement for reaching and
  surviving a habitat.
- A companion changes what can be learned, controlled, harvested, protected, or
  pursued after the region is accessible.
- Required bonds and memories use guaranteed authored opportunities under every
  supported seed.
- Optional resource and wildlife candidates may vary by day without changing
  geography or making progression impossible.
- No species is obtained behind the only obstacle it is needed to solve.
- No companion action opens an unexplained species-shaped lock.
- Regions should promise a species through signs, behavior, sound, remains, or
  relationships before the bond encounter occurs.

## Wildlife, Enemies, And Resources

Not every monster is bondable. Each region may contain:

- passive wildlife that establishes normal behavior;
- defensive wildlife that warns before contact;
- territorial rivals that guard space rather than treasure locks;
- predators with readable pursuit and recovery cycles;
- harvestable organisms or shed materials;
- bondable individuals whose relationship is authored deliberately.

Progression resources may come from wildlife or enemies, but the source must be
legible and ethically/mechanically varied. Valid acquisition can include shed
material, molting, scanning, careful sampling, nonlethal handling, or defeat.
Required recipes need a guaranteed path and cannot depend on exterminating rare
wildlife or waiting for a random spawn.

## Art And Animation Contract

- Begin with monochrome silhouette sheets at diver gameplay scale.
- Review the base, follow, separated, action, and adaptation silhouettes before
  color or texture work.
- Every species needs a movement rhythm different from the existing two.
- Mounted species need rider placement, clearance, facing, action direction,
  forced separation, and dismount review.
- Each permanent branch changes anatomy, posture, markings, or a persistent
  effect visible without a menu.
- Color supports identity but never carries it alone.
- Generate and revise one named species asset family at a time; never regenerate
  terrain, diver, boat, or other accepted creatures to change one monster.

## Recommended Production Order

1. Finish the Living Expedition 03 visual, exact-Web, and owner gate with Kite
   and Mica only.
2. Review monochrome concept sheets for the four-species production core.
3. Use Living Expedition 04 to establish real wildlife/combat consequences with
   the current roster before adding a combat specialist.
4. Select Silt Hound as the recommended third-species proof because prospecting
   links creatures to the material/recipe loop and map revisits without
   duplicating current roles.
5. Add Breaker Mantis only after real-time combat, enemy health feedback,
   resource outcomes, and nonlethal/defeat rules have a stable owner.
6. Keep Rivetback, Lumenjaw, Ribbon Drake, and Choir Bloom directional until the
   four-species core proves daily selection remains understandable and useful.

## Non-Goals

- dozens of species before four distinct choices work;
- elemental strengths, weaknesses, rarity tiers, or type coverage;
- capture devices, random catch chance, breeding, fusion, or eggs;
- generic levels, stat allocation, or repeated-use evolution grinding;
- multiple active companions or a party combat rewrite;
- creatures that replace access equipment or function as colored keys;
- broad stable UI, final art, or full-region production in this planning pass.

## Species Review Gate

A proposed species is ready for a focused milestone only when the owner can
answer yes to all of these:

1. Can I recognize it from silhouette and movement without a label?
2. Can I describe what it does in the wild before it joins me?
3. Do I understand why this individual chooses the diver?
4. Does its headline verb change a real expedition decision?
5. Do its memories describe events rather than chores or XP?
6. Are its adaptations physically and mechanically different?
7. Does it belong to a region with wildlife, resources, and threats?
8. Does it preserve diver access, survival, map, and failure authority?
9. Is there a concrete reason to choose it for another day?
10. Is it more interesting as a living partner than the same effect as a tool?
