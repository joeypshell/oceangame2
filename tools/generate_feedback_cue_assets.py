#!/usr/bin/env python3
"""Generate deterministic compact WAV cues for gameplay feedback."""

from __future__ import annotations

import math
import struct
import wave
from dataclasses import dataclass
from hashlib import sha256
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "assets" / "audio" / "cues"
SAMPLE_RATE = 22_050
AMPLITUDE = 0.26


@dataclass(frozen=True)
class Segment:
    frequency: float
    duration: float
    volume: float = 1.0
    end_frequency: float | None = None
    waveform: str = "sine"
    noise_mix: float = 0.0


@dataclass(frozen=True)
class Cue:
    name: str
    segments: tuple[Segment, ...]
    release: float = 0.035


CUES = (
    Cue(
        "salvage_pickup",
        (
            Segment(720, 0.045, 0.75, 980),
            Segment(1040, 0.09, 0.82, 1380),
        ),
        0.025,
    ),
    Cue(
        "material_pickup",
        (
            Segment(0, 0.018, 0.7, waveform="noise", noise_mix=1.0),
            Segment(1180, 0.05, 0.72, 700, "triangle", 0.12),
            Segment(520, 0.075, 0.5, 390),
        ),
        0.02,
    ),
    Cue(
        "salvage_bank",
        (
            Segment(330, 0.055, 0.62, 270, "triangle", 0.08),
            Segment(0, 0.025),
            Segment(520, 0.08, 0.72, 650),
            Segment(760, 0.11, 0.8, 1020),
        ),
        0.03,
    ),
    Cue(
        "oxygen_low",
        (
            Segment(220, 0.095, 0.68, 175, "sine", 0.48),
            Segment(0, 0.06),
            Segment(220, 0.095, 0.68, 175, "sine", 0.48),
        ),
        0.025,
    ),
    Cue(
        "oxygen_critical",
        (
            Segment(280, 0.065, 0.86, 205, "sine", 0.42),
            Segment(0, 0.025),
            Segment(280, 0.065, 0.86, 205, "sine", 0.42),
            Segment(0, 0.025),
            Segment(300, 0.08, 0.92, 185, "sine", 0.46),
        ),
        0.02,
    ),
    Cue(
        "oxygen_failure",
        (
            Segment(240, 0.32, 0.85, 82, "sine", 0.62),
            Segment(75, 0.12, 0.58, 42, "triangle", 0.38),
        ),
        0.055,
    ),
    Cue(
        "hazard_warning",
        (
            Segment(940, 0.055, 0.82, 1120, "triangle", 0.08),
            Segment(0, 0.025),
            Segment(650, 0.055, 0.82, 790, "triangle", 0.08),
            Segment(0, 0.025),
            Segment(940, 0.065, 0.88, 1120, "triangle", 0.08),
        ),
        0.018,
    ),
    Cue(
        "hazard_contact",
        (
            Segment(0, 0.028, 0.95, waveform="noise", noise_mix=1.0),
            Segment(190, 0.18, 0.9, 48, "square", 0.5),
        ),
        0.04,
    ),
    Cue(
        "upgrade_purchase",
        (
            Segment(560, 0.05, 0.62, 690),
            Segment(760, 0.065, 0.72, 920),
            Segment(1040, 0.095, 0.78, 1360),
        ),
        0.025,
    ),
)


def envelope(sample_index: int, total_samples: int, release_samples: int) -> float:
    attack_samples = min(max(1, int(SAMPLE_RATE * 0.004)), max(1, total_samples // 3))
    release_samples = min(release_samples, max(1, total_samples // 2))
    if sample_index < attack_samples:
        return sample_index / attack_samples
    if sample_index > total_samples - release_samples:
        return max(0.0, (total_samples - sample_index) / max(1, release_samples))
    return 1.0


def oscillator(phase: float, waveform_name: str) -> float:
    sine = math.sin(phase)
    if waveform_name == "triangle":
        return (2.0 / math.pi) * math.asin(sine)
    if waveform_name == "square":
        return 0.72 if sine >= 0.0 else -0.72
    if waveform_name == "noise":
        return 0.0
    return sine


def next_noise(state: int) -> tuple[int, float]:
    state = (1_664_525 * state + 1_013_904_223) & 0xFFFFFFFF
    return state, ((state / 0xFFFFFFFF) * 2.0) - 1.0


def render_cue(cue: Cue) -> bytes:
    frames: list[int] = []
    phase = 0.0
    release_samples = int(SAMPLE_RATE * cue.release)
    noise_state = int.from_bytes(sha256(cue.name.encode("ascii")).digest()[:4], "little")
    for segment in cue.segments:
        segment_samples = max(1, int(SAMPLE_RATE * segment.duration))
        for i in range(segment_samples):
            env = envelope(i, segment_samples, release_samples)
            progress = i / max(1, segment_samples - 1)
            end_frequency = segment.frequency if segment.end_frequency is None else segment.end_frequency
            frequency = segment.frequency + (end_frequency - segment.frequency) * progress
            tone = 0.0
            if frequency > 0:
                phase += (math.tau * frequency) / SAMPLE_RATE
                tone = oscillator(phase, segment.waveform)
            noise_state, noise = next_noise(noise_state)
            mix = max(0.0, min(1.0, segment.noise_mix))
            value = ((tone * (1.0 - mix)) + (noise * mix)) * AMPLITUDE * segment.volume * env
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
