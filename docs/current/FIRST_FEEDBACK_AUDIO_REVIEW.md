# First Feedback/Audio Review Note

Date: 2026-07-09

Issue: #489 `Add focused feedback/audio review note or capture substitute`

Milestone: Simple Diver Game 07 `Presentation And Game Feel`

## Decision

Use the deterministic feedback cue smoke as the review artifact for the first compact audio pass. Audio cue playback is not visible in screenshots, and headless CI should not depend on audio hardware, so the useful review signal is the emitted cue event log.

No visual baseline acceptance is needed for this note.

## Review Command

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-feedback-cues
```

Treat `SCRIPT ERROR` or `ERROR:` lines as failures even if Godot exits `0`.

## Expected Review Output

The command should report one deterministic sequence over `production_slice_01`:

```text
Feedback cue smoke passed: target=salvage_entry_shaft hazard=hazard_shaft_choke cue_counts={ "salvage_pickup": 1, "salvage_bank": 1, "oxygen_low": 1, "oxygen_critical": 1, "oxygen_failure": 1, "hazard_warning": 1, "hazard_contact": 1 }.
```

The specific target and hazard ids are diagnostic context. The required review signal is that the cue counts include:

- `salvage_pickup`
- `salvage_bank`
- `oxygen_low`
- `oxygen_critical`
- `oxygen_failure`
- `hazard_warning`
- `hazard_contact`

## What This Proves

- Pickup and banking cue events emit from real collect/return runtime paths.
- Oxygen warning and failure cue events emit from threshold/failure transitions.
- Hazard warning and contact cue events emit from real warning/contact paths.
- Headless review works without audio hardware or a display renderer.
- The review artifact does not mutate map source, captures, accepted baselines, or audio assets.

## What This Does Not Prove

- Final sound design quality.
- Speaker/device volume.
- Browser user perception after audio unlock.
- Music, ambience, settings UI, or persistent mute behavior.

Those stay outside the first compact feedback/audio cue pass.
