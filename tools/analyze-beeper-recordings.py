#!/usr/bin/env python3
"""Measure the Studio II beeper's fundamental in short hardware recordings.

The analysis deliberately ignores most mechanical joystick noise by filtering to
the 480--760 Hz fundamental band.  It reports contiguous audible events and a
cycle-by-cycle pitch trace suitable for spotting retrigger/overlap behavior.
"""

from __future__ import annotations

import argparse
import csv
import subprocess
from pathlib import Path

import numpy as np


def decode(path: Path, sample_rate: int = 44_100) -> np.ndarray:
    command = [
        "ffmpeg", "-v", "error", "-i", str(path), "-ac", "1", "-ar",
        str(sample_rate), "-f", "f32le", "-",
    ]
    raw = subprocess.check_output(command)
    return np.frombuffer(raw, dtype="<f4").astype(np.float64)


def runs(mask: np.ndarray) -> list[tuple[int, int]]:
    edges = np.diff(np.pad(mask.astype(np.int8), (1, 1)))
    return list(zip(np.flatnonzero(edges == 1), np.flatnonzero(edges == -1)))


def bandpass(samples: np.ndarray, fs: int, low: float = 480, high: float = 760) -> np.ndarray:
    """Zero-phase FFT bandpass with 30 Hz cosine shoulders."""
    spectrum = np.fft.rfft(samples)
    frequency = np.fft.rfftfreq(len(samples), 1 / fs)
    gain = np.zeros_like(frequency)
    shoulder = min(40.0, low / 4)
    gain[(frequency >= low) & (frequency <= high)] = 1.0
    lower = (frequency >= low - shoulder) & (frequency < low)
    upper = (frequency > high) & (frequency <= high + shoulder)
    gain[lower] = 0.5 - 0.5 * np.cos(
        np.pi * (frequency[lower] - (low - shoulder)) / shoulder
    )
    gain[upper] = 0.5 + 0.5 * np.cos(
        np.pi * (frequency[upper] - high) / shoulder
    )
    return np.fft.irfft(spectrum * gain, n=len(samples))


def detect_events(filtered: np.ndarray, fs: int) -> list[tuple[int, int]]:
    envelope = np.abs(filtered)
    smooth_len = max(1, round(fs * 0.008))
    envelope = np.convolve(envelope, np.ones(smooth_len) / smooth_len, "same")
    # A low percentile still finds the noise floor in clips dominated by one
    # long sound (for example Concentration/Match's long sequence).
    floor = np.percentile(envelope, 5)
    threshold = max(floor * 5.0, np.max(envelope) * 0.055)
    mask = envelope >= threshold

    # Join dropouts shorter than 25 ms, then discard clicks shorter than 18 ms.
    for start, end in runs(~mask):
        if start and end < len(mask) and end - start <= round(fs * 0.025):
            mask[start:end] = True
    pad = round(fs * 0.006)
    return [
        (max(0, start - pad), min(len(mask), end + pad))
        for start, end in runs(mask)
        if end - start >= round(fs * 0.018)
    ]


def pitch_frames(
    samples: np.ndarray, fs: int, start: int, end: int,
    pitch_min: float = 500, pitch_max: float = 700,
):
    """Track the strongest fundamental ridge in overlapping 36 ms frames."""
    width, hop, nfft = round(fs * 0.036), round(fs * 0.004), 65_536
    half = width // 2
    centers = np.arange(start + half, end - half + 1, hop)
    if not len(centers):
        return np.array([]), np.array([])
    window = np.hanning(width)
    frequency = np.fft.rfftfreq(nfft, 1 / fs)
    band = (frequency >= pitch_min) & (frequency <= pitch_max)
    indices = np.flatnonzero(band)
    result = []
    strengths = []
    for center in centers:
        magnitude = np.abs(np.fft.rfft(samples[center-half:center-half+width] * window, nfft))
        peak = indices[np.argmax(magnitude[band])]
        # Parabolic interpolation around the FFT maximum.
        left, middle, right = magnitude[peak-1:peak+2]
        offset = 0.5 * (left - right) / (left - 2 * middle + right)
        offset = float(np.clip(offset, -0.5, 0.5))
        result.append((peak + offset) * fs / nfft)
        strengths.append(middle)
    result, strengths = np.asarray(result), np.asarray(strengths)
    # Reject edge frames whose residual room/noise energy has no reliable ridge.
    valid = strengths >= np.max(strengths) * 0.08
    margin = min(5.0, (pitch_max - pitch_min) / 10)
    valid &= (result >= pitch_min + margin) & (result <= pitch_max - margin)
    return centers[valid] / fs, result[valid]


def median_slice(times, hz, lo, hi):
    values = hz[(times >= lo) & (times <= hi)]
    return float(np.median(values)) if len(values) else float("nan")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("recordings", nargs="+", type=Path)
    parser.add_argument("--csv", type=Path, help="write the cycle-level trace")
    parser.add_argument("--detect-min", type=float, default=480)
    parser.add_argument("--detect-max", type=float, default=760)
    parser.add_argument("--pitch-min", type=float, default=500)
    parser.add_argument("--pitch-max", type=float, default=700)
    args = parser.parse_args()
    fs = 44_100
    rows = []

    print("file,event,onset_s,duration_ms,frames,start_hz,middle_hz,end_hz,min_hz,max_hz")
    for path in args.recordings:
        samples = decode(path, fs)
        windowed = (samples - np.mean(samples)) * np.hanning(len(samples))
        spectrum = np.abs(np.fft.rfft(windowed))
        frequencies = np.fft.rfftfreq(len(samples), 1 / fs)
        candidates = np.flatnonzero(
            (frequencies >= 100) & (frequencies <= 3_000)
            & (spectrum >= np.roll(spectrum, 1))
            & (spectrum >= np.roll(spectrum, -1))
        )
        strongest = candidates[np.argsort(spectrum[candidates])[-8:]][::-1]
        peaks = " ".join(f"{frequencies[index]:.1f}" for index in strongest)
        print(f"# {path.name} spectral peaks (Hz): {peaks}")
        filtered = bandpass(samples, fs, args.detect_min, args.detect_max)
        for event_number, (start, end) in enumerate(detect_events(filtered, fs), 1):
            times, hz = pitch_frames(
                samples, fs, start, end, args.pitch_min, args.pitch_max
            )
            if not len(hz):
                continue
            onset, finish = start / fs, end / fs
            duration = finish - onset
            edge = min(0.025, duration / 3)
            middle = onset + duration / 2
            start_hz = median_slice(times, hz, onset + 0.006, onset + edge)
            middle_hz = median_slice(times, hz, middle - edge / 2, middle + edge / 2)
            end_hz = median_slice(times, hz, finish - edge, finish - 0.004)
            q10, q90 = np.percentile(hz, (10, 90))
            print(
                f"{path.name},{event_number},{onset:.4f},{duration*1000:.1f},"
                f"{len(hz)},{start_hz:.2f},{middle_hz:.2f},{end_hz:.2f},"
                f"{q10:.2f},{q90:.2f}"
            )
            rows.extend(
                (path.name, event_number, f"{time:.7f}", f"{pitch:.4f}")
                for time, pitch in zip(times, hz)
            )

    if args.csv:
        args.csv.parent.mkdir(parents=True, exist_ok=True)
        with args.csv.open("w", newline="", encoding="utf-8") as handle:
            writer = csv.writer(handle)
            writer.writerow(("file", "event", "time_s", "frequency_hz"))
            writer.writerows(rows)


if __name__ == "__main__":
    main()
