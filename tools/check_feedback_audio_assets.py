#!/usr/bin/env python3
"""Validate committed feedback WAVs against their deterministic generator."""

from __future__ import annotations

import hashlib
import struct
import wave
from dataclasses import dataclass
from pathlib import Path

from generate_feedback_cue_assets import CUES, OUTPUT_DIR, SAMPLE_RATE, render_cue


EXPECTED_CUE_IDS = (
    "salvage_pickup",
    "material_pickup",
    "salvage_bank",
    "oxygen_low",
    "oxygen_critical",
    "oxygen_failure",
    "hazard_warning",
    "hazard_contact",
    "upgrade_purchase",
)
MIN_DURATION_SECONDS = 0.08
MAX_DURATION_SECONDS = 0.70
MIN_PEAK = 0.04
MAX_PEAK = 0.95


@dataclass(frozen=True)
class AssetReport:
    cue_id: str
    duration_seconds: float
    peak: float
    digest: str


def _read_wav(path: Path) -> tuple[int, int, int, bytes]:
    with wave.open(str(path), "rb") as wav_file:
        channels = wav_file.getnchannels()
        sample_width = wav_file.getsampwidth()
        frame_rate = wav_file.getframerate()
        frames = wav_file.readframes(wav_file.getnframes())
    return channels, sample_width, frame_rate, frames


def _peak_amplitude(frames: bytes) -> float:
    sample_count = len(frames) // 2
    if sample_count <= 0:
        return 0.0
    samples = struct.unpack(f"<{sample_count}h", frames)
    return max(abs(sample) for sample in samples) / 32767.0


def validate_assets() -> tuple[list[AssetReport], list[str]]:
    errors: list[str] = []
    reports: list[AssetReport] = []
    cues_by_id = {cue.name: cue for cue in CUES}
    expected_set = set(EXPECTED_CUE_IDS)
    generated_set = set(cues_by_id)
    committed_set = {path.stem for path in OUTPUT_DIR.glob("*.wav")}

    if generated_set != expected_set:
        errors.append(
            "generator cue ids differ from the reviewed contract: "
            f"missing={sorted(expected_set - generated_set)} "
            f"unexpected={sorted(generated_set - expected_set)}"
        )
    if committed_set != expected_set:
        errors.append(
            "committed cue ids differ from the reviewed contract: "
            f"missing={sorted(expected_set - committed_set)} "
            f"unexpected={sorted(committed_set - expected_set)}"
        )

    for cue_id in EXPECTED_CUE_IDS:
        cue = cues_by_id.get(cue_id)
        path = OUTPUT_DIR / f"{cue_id}.wav"
        if cue is None or not path.is_file():
            continue
        try:
            channels, sample_width, frame_rate, frames = _read_wav(path)
        except (EOFError, wave.Error) as exc:
            errors.append(f"{cue_id}: unreadable WAV: {exc}")
            continue

        if channels != 1:
            errors.append(f"{cue_id}: expected mono, found {channels} channels")
        if sample_width != 2:
            errors.append(f"{cue_id}: expected 16-bit PCM, found {sample_width * 8}-bit")
        if frame_rate != SAMPLE_RATE:
            errors.append(f"{cue_id}: expected {SAMPLE_RATE} Hz, found {frame_rate} Hz")

        generated_frames = render_cue(cue)
        if frames != generated_frames:
            errors.append(f"{cue_id}: committed PCM differs from deterministic generator output")

        duration = (len(frames) / sample_width / channels / frame_rate) if frame_rate > 0 else 0.0
        peak = _peak_amplitude(frames)
        if not MIN_DURATION_SECONDS <= duration <= MAX_DURATION_SECONDS:
            errors.append(
                f"{cue_id}: duration {duration:.3f}s is outside "
                f"{MIN_DURATION_SECONDS:.2f}-{MAX_DURATION_SECONDS:.2f}s"
            )
        if not MIN_PEAK <= peak <= MAX_PEAK:
            errors.append(f"{cue_id}: normalized peak {peak:.3f} is outside {MIN_PEAK:.2f}-{MAX_PEAK:.2f}")

        reports.append(
            AssetReport(
                cue_id=cue_id,
                duration_seconds=duration,
                peak=peak,
                digest=hashlib.sha256(path.read_bytes()).hexdigest(),
            )
        )

    digests: dict[str, list[str]] = {}
    for report in reports:
        digests.setdefault(report.digest, []).append(report.cue_id)
    for digest, cue_ids in digests.items():
        if len(cue_ids) > 1:
            errors.append(f"duplicate cue fingerprint {digest[:12]}: {', '.join(cue_ids)}")

    return reports, errors


def main() -> int:
    reports, errors = validate_assets()
    for report in reports:
        print(
            f"{report.cue_id:18} duration={report.duration_seconds:.3f}s "
            f"peak={report.peak:.3f} sha256={report.digest[:12]}"
        )
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print(f"Feedback audio assets passed: {len(reports)} deterministic, unique mono PCM cues.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
