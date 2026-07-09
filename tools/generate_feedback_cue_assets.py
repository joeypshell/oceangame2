#!/usr/bin/env python3
"""Generate deterministic placeholder WAV cues for the first feedback/audio pass."""

from __future__ import annotations

import math
import struct
import wave
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "assets" / "audio" / "cues"
SAMPLE_RATE = 22_050
AMPLITUDE = 0.28


@dataclass(frozen=True)
class Segment:
    frequency: float
    duration: float
    volume: float = 1.0


@dataclass(frozen=True)
class Cue:
    name: str
    segments: tuple[Segment, ...]
    release: float = 0.035


CUES = (
    Cue("salvage_pickup", (Segment(740, 0.055), Segment(980, 0.075, 0.8))),
    Cue("salvage_bank", (Segment(520, 0.07), Segment(690, 0.08), Segment(890, 0.10, 0.75))),
    Cue("oxygen_low", (Segment(420, 0.08, 0.75), Segment(0, 0.03), Segment(420, 0.08, 0.75))),
    Cue("oxygen_critical", (Segment(360, 0.06), Segment(0, 0.025), Segment(320, 0.06), Segment(0, 0.025), Segment(280, 0.08))),
    Cue("oxygen_failure", (Segment(260, 0.10), Segment(190, 0.12, 0.85), Segment(140, 0.14, 0.75)), 0.06),
    Cue("hazard_warning", (Segment(610, 0.055), Segment(0, 0.035), Segment(610, 0.055))),
    Cue("hazard_contact", (Segment(155, 0.06), Segment(115, 0.08, 0.9), Segment(85, 0.08, 0.75)), 0.045),
    Cue("upgrade_purchase", (Segment(620, 0.055), Segment(820, 0.065), Segment(1080, 0.085, 0.7))),
)


def envelope(sample_index: int, total_samples: int, release_samples: int) -> float:
    attack_samples = max(1, int(SAMPLE_RATE * 0.006))
    if sample_index < attack_samples:
        return sample_index / attack_samples
    if sample_index > total_samples - release_samples:
        return max(0.0, (total_samples - sample_index) / max(1, release_samples))
    return 1.0


def render_cue(cue: Cue) -> bytes:
    frames: list[int] = []
    phase = 0.0
    release_samples = int(SAMPLE_RATE * cue.release)
    for segment in cue.segments:
        segment_samples = max(1, int(SAMPLE_RATE * segment.duration))
        for i in range(segment_samples):
            env = envelope(i, segment_samples, release_samples)
            if segment.frequency <= 0:
                value = 0.0
            else:
                phase += (math.tau * segment.frequency) / SAMPLE_RATE
                tone = math.sin(phase)
                soft_click = math.sin(phase * 0.5) * 0.12
                value = (tone + soft_click) * AMPLITUDE * segment.volume * env
            frames.append(int(max(-1.0, min(1.0, value)) * 32767))
    return struct.pack("<" + "h" * len(frames), *frames)


def write_cue(cue: Cue) -> Path:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    path = OUTPUT_DIR / f"{cue.name}.wav"
    with wave.open(str(path), "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        wav_file.writeframes(render_cue(cue))
    return path


def main() -> int:
    for cue in CUES:
        path = write_cue(cue)
        print(path.relative_to(ROOT).as_posix())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
