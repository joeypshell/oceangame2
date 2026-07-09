# First Feedback/Audio Micro-Pass Plan

Date: 2026-07-09

Issue: #471 `Plan next presentation micro-pass after darkness/light gate`
Milestone: Simple Diver Game 07 `Presentation And Game Feel`

## Decision

The next Presentation And Game Feel micro-pass should add the first compact feedback/audio cue layer for existing gameplay events.

This is the smallest meaningful next step because the prototype now has many player-facing states, but most of them are silent. A tiny cue layer can make pickup, banking, oxygen pressure, and hazards feel more finished without expanding map scale, enemy AI, inventory, economy, save data, or broad art replacement.

## Target Experience

The player should get subtle, short feedback when:

- salvage enters held cargo
- held salvage is banked at extraction
- oxygen crosses important pressure/failure states
- hazards warn or make contact

The cues should support existing overlay text, not replace it.

## Meaningful-Change Filter

This pass is worthwhile if it improves moment-to-moment feel in the current default slice while keeping all gameplay rules stable:

- no new objectives
- no new map topology
- no changed salvage values
- no changed oxygen thresholds
- no changed hazard penalties
- no broad UI framework

## Planned Issue Batch

Recommended order:

1. #481 `Define first compact feedback/audio cue contract`
2. #482 `Generate first placeholder UI/SFX cue assets`
3. #483 `Implement lightweight runtime audio cue player`
4. #484 `Trigger salvage pickup and banking feedback cues`
5. #485 `Trigger oxygen warning and failure feedback cues`
6. #486 `Trigger hazard warning and contact feedback cues`
7. #487 `Handle Web audio unlock and mute-safe startup`
8. #488 `Add deterministic feedback/audio cue smoke coverage`
9. #489 `Add focused feedback/audio review note or capture substitute`
10. #490 `Review and verify first feedback/audio pass`

## Boundaries

In scope:

- a tiny set of short UI/SFX cues
- one focused runtime cue helper
- existing event integrations only
- deterministic smoke or event-log coverage
- Web preview verification for missing assets/autoplay errors

Out of scope:

- music or ambient loops
- voice
- full audio options menu
- persistent preferences
- broad mixer architecture
- inventory/loadout systems
- enemy AI or combat audio systems
- map-scale expansion

## Validation Plan

Expected validation by the end of the batch:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --import
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-feedback-cues
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-salvage-loop
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-oxygen-pressure
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-hazard-pressure
python tools/check_file_lengths.py
git diff --check
```

Web verification should use `tools/check_web_preview.cjs` after runtime/audio assets land.

## Exit Criteria

- The first cue set is documented, implemented, and covered by deterministic smoke/event logs.
- Public Web preview initializes without missing audio assets, autoplay errors, Godot script errors, or resource packaging errors.
- The pass closes with a concise verification/closeout doc.
- The backlog remains scoped and does not drift into broad audio, inventory, enemies, or map expansion.
