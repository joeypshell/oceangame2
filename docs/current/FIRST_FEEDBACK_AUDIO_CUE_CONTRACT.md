# First Feedback/Audio Cue Contract

Date: 2026-07-09

Issue: #481 `Define first compact feedback/audio cue contract`

Milestone: Simple Diver Game 07 `Presentation And Game Feel`

## Decision

The first feedback/audio pass adds a tiny event-cue layer for existing gameplay states only. It should make salvage, banking, oxygen pressure, hazards, and one existing upgrade purchase feel clearer without changing map source, oxygen thresholds, cargo rules, salvage values, objective rules, hazards, upgrades, or completion conditions.

The contract is intentionally narrow: future runtime work should emit cue events from confirmed gameplay transitions and let the audio helper play or silently ignore them when audio is unavailable.

## Cue Set

| Cue id | Event | Intent | Priority | Cooldown/dedupe |
| --- | --- | --- | --- | --- |
| `salvage_pickup` | Salvage enters held cargo after instant, timed, or pry completion. | Short warm pickup tick. | Normal | Once per salvage id per collection event. Do not replay every frame while in range. |
| `material_pickup` | A standard or biological recipe material enters held cargo. | Short tactile clink distinct from valuable salvage. | Normal | Once per material candidate or biological source after successful collection. Cargo-full and canceled attempts stay silent. |
| `salvage_bank` | Held salvage is banked at extraction and score/wallet changes. | Warmer confirm/payoff. | Normal | Once per banking event, even if multiple held items bank together. |
| `oxygen_low` | Oxygen crosses the existing low-pressure threshold from above. | Soft warning ping. | Medium | Once per expedition until oxygen refills/resets above the threshold. |
| `oxygen_critical` | Oxygen crosses the existing critical/failure-warning threshold from above. | Sharper warning ping. | High | Once per expedition until oxygen refills/resets above the threshold. |
| `oxygen_failure` | Oxygen depletion triggers the existing failure/surface/reset result. | Clear fail/down cue. | High | Once per failure event. |
| `hazard_warning` | Existing hazard warning state begins for a specific hazard. | Brief caution ping that supports the overlay. | Medium | At most once per hazard id per warning window, with a short global cooldown around 1 second. |
| `hazard_contact` | Existing hazard contact applies penalty/reset behavior. | Impact/error cue. | High | Once per accepted contact event after existing hazard contact cooldowns. |
| `upgrade_purchase` | Existing session upgrade purchase succeeds. | Positive confirm. | Normal | Once per purchase. May be deferred if it would broaden the first runtime pass. |

## Sound Language

- Collection is bright and short. Valuable salvage rises like a compact find; recipe material uses a dry click and descending clink so the two cargo types do not blur together.
- Banking is longer and resolves upward after a low confirmation beat. It should read as payoff rather than another pickup.
- Oxygen uses an airy low-frequency tank/breath family. Low oxygen is a slow double pulse, critical oxygen is a faster three-pulse escalation, and failure becomes one longer descending vent.
- Danger uses a dry, high metallic alternating alarm. It must not share the airy pulse rhythm or low register of oxygen.
- Contact/damage begins with a noise transient and falls into a low impact. It should read as something already happened, not as advance warning.
- Upgrade purchase remains a compact bright arpeggio. Music, ambience, enemy/tool foley, and broad mixer work remain outside this contract.

## Priority Rules

- High-priority cues may overlap or interrupt low/normal cues if the implementation needs a simple policy.
- Normal cues should stay subtle and short so repeated salvage/banking actions do not feel noisy.
- The first pass does not need a complex queue, mixer, ducking, or category volume system.
- Cue emission should be state-transition based, not per-frame polling.

## Asset Constraints

- Use short placeholder UI/SFX assets, preferably under 0.7 seconds and usually under 0.3 seconds.
- Keep cues non-musical, subtle, and readable over the current bright underwater presentation.
- Use Godot-loadable `.wav` or `.ogg` assets under a small audio asset folder.
- Do not commit `.import` sidecars or generated editor cache.
- Do not introduce broad ambience, music loops, voice, or a full audio pack in this pass.

## Web Autoplay Contract

- Runtime audio must tolerate locked Web audio before the first user gesture.
- Startup should never show autoplay errors, missing asset errors, or script errors if cues cannot play yet.
- The first player input may unlock/resume audio, but this pass should not add an options screen or persistent mute preference.
- Playback remains unlocked across sorties. Normal keyboard, touch, mouse, or controller movement therefore unlocks Web audio before proximity collection; do not queue stale gameplay cues for replay after a later gesture.
- If audio remains unavailable, gameplay continues silently and deterministic smokes still pass through event-log verification.

## Smoke/Test Contract

Future smoke coverage should verify cue emission through a deterministic event log or lightweight test hook, not through an audio device:

- material pickup, salvage pickup, and banking emit the expected cue ids in order
- oxygen low, critical, and failure cues emit on threshold/result transitions only
- hazard warning and contact cues emit without per-frame spam
- Web-safe startup does not require audio playback to pass

## Non-Goals

- music or ambience
- broad mixer architecture
- volume/options UI
- persistent preferences
- voice
- inventory or loadout UI
- new gameplay behavior
- enemy/combat audio systems
- map-scale expansion
