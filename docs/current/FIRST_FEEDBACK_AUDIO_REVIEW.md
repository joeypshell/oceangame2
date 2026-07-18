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
python tools/check_feedback_audio_assets.py
```

Treat `SCRIPT ERROR` or `ERROR:` lines as failures even if Godot exits `0`.

## Expected Review Output

The command should report one deterministic sequence over `production_slice_01`:

```text
Feedback cue smoke passed: first_material=material_titanium_crossing second_material=material_titanium_return first_salvage=salvage_entry_shaft second_salvage=salvage_center_crossing blocked=material_coil_scanner_floor canceled=timed+pry cargo_sorties=2 web_lock=no_stale_replay cue_counts={ "material_pickup": 2, "salvage_pickup": 2, "salvage_bank": 2, "oxygen_low": 1, "oxygen_critical": 1, "oxygen_failure": 1, "hazard_warning": 1, "hazard_contact": 1 } priorities=stable.
```

The specific source ids are diagnostic context. The required review signal is that the exact counts include:

- `material_pickup`: 2
- `salvage_pickup`: 2
- `salvage_bank`: 2
- `oxygen_low`, `oxygen_critical`, `oxygen_failure`, `hazard_warning`, and `hazard_contact`: 1 each

The asset checker should separately report nine deterministic, unique mono PCM cues.

## What This Proves

- Material and salvage pickup cues emit exactly once from real collection paths on two sorties.
- Proximity, cargo-full, and canceled timed/pry attempts stay silent.
- Banking emits once per offload.
- Oxygen warning and failure cue events emit from threshold/failure transitions.
- Hazard warning and contact cue events emit from real warning/contact paths.
- Locked Web audio records the eligible event, unlocks on input, and does not replay stale audio.
- Reviewed cue ids, priorities, format, duration, generated PCM, and fingerprints stay deterministic.
- Headless review works without audio hardware or a display renderer.
- The review artifact does not mutate map source, captures, accepted baselines, or audio assets.

## What This Does Not Prove

- Final sound design quality.
- Speaker/device volume.
- Browser user perception after audio unlock.
- Music, ambience, settings UI, or persistent mute behavior.

Those stay outside the first compact feedback/audio cue pass.
