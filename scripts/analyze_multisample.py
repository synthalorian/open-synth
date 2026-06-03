#!/usr/bin/env python3
"""Analyze a WAV file and split it into octave/velocity zones for multi-sampling.

Usage:
    python analyze_multisample.py input.wav [--output-dir ./zones] [--zones 4]

Outputs:
    - Sliced WAV files per zone and velocity layer
    - zones.json manifest for SamplePlayer::loadMultiSample()

The script detects the fundamental frequency (root pitch) of the input WAV,
then creates 3-5 octave zones centered around detected pitch. For each zone,
it generates soft/medium/loud velocity layers by amplitude-based segmentation
(if the input contains sufficient dynamic variation) or by copying the same
sample with gain adjustments.
"""

import argparse
import json
import math
import os
import struct
import wave


def read_wav(path):
    """Read a mono or stereo WAV file. Returns (frames, num_channels, sample_rate, width)."""
    with wave.open(path, 'rb') as f:
        nchannels = f.getnchannels()
        sampwidth = f.getsampwidth()
        framerate = f.getframerate()
        nframes = f.getnframes()
        data = f.readframes(nframes)

    if sampwidth == 1:
        fmt = f"{len(data)}b"
        samples = struct.unpack(fmt, data)
        frames = [s / 128.0 for s in samples]
    elif sampwidth == 2:
        fmt = f"<{len(data)//2}h"
        samples = struct.unpack(fmt, data)
        frames = [s / 32768.0 for s in samples]
    elif sampwidth == 3:
        # 24-bit
        samples = []
        for i in range(0, len(data), 3):
            b = data[i:i+3]
            val = b[0] | (b[1] << 8) | (b[2] << 16)
            if val & 0x800000:
                val -= 0x1000000
            samples.append(val / 8388608.0)
        frames = samples
    elif sampwidth == 4:
        fmt = f"<{len(data)//4}i"
        samples = struct.unpack(fmt, data)
        frames = [s / 2147483648.0 for s in samples]
    else:
        raise ValueError(f"Unsupported sample width: {sampwidth}")

    # Deinterleave if stereo, return mono mix
    if nchannels == 2:
        mono = []
        for i in range(0, len(frames), 2):
            mono.append((frames[i] + frames[i+1]) * 0.5)
        frames = mono
    elif nchannels > 2:
        raise ValueError("Only mono or stereo WAVs supported")

    return frames, framerate, sampwidth


def write_wav(path, frames, sample_rate, sampwidth=2):
    """Write mono frames to a WAV file."""
    if sampwidth == 1:
        data = struct.pack(f"<{len(frames)}b", *[int(max(-128, min(127, s * 127))) for s in frames])
    elif sampwidth == 2:
        data = struct.pack(f"<{len(frames)}h", *[int(max(-32768, min(32767, s * 32767))) for s in frames])
    elif sampwidth == 3:
        # 24-bit
        data = b''
        for s in frames:
            val = int(max(-8388608, min(8388607, s * 8388607)))
            if val < 0:
                val += 0x1000000
            data += struct.pack('<I', val)[:3]
    elif sampwidth == 4:
        data = struct.pack(f"<{len(frames)}i", *[int(max(-2147483648, min(2147483647, s * 2147483647))) for s in frames])
    else:
        raise ValueError(f"Unsupported sample width: {sampwidth}")

    with wave.open(path, 'wb') as f:
        f.setnchannels(1)
        f.setsampwidth(sampwidth)
        f.setframerate(sample_rate)
        f.writeframes(data)


def detect_pitch(frames, sample_rate):
    """Detect fundamental frequency using autocorrelation."""
    n = len(frames)
    # Use a window of ~0.1s for analysis
    window_size = min(n, int(sample_rate * 0.1))
    if window_size < 2:
        return 440.0

    # Use the loudest segment
    best_start = 0
    best_energy = 0.0
    step = window_size // 4
    for i in range(0, n - window_size, step):
        energy = sum(f * f for f in frames[i:i+window_size])
        if energy > best_energy:
            best_energy = energy
            best_start = i

    buf = frames[best_start:best_start + window_size]

    # Autocorrelation
    autocorr = []
    for lag in range(1, window_size):
        s = 0.0
        for i in range(window_size - lag):
            s += buf[i] * buf[i + lag]
        autocorr.append(s)

    if not autocorr:
        return 440.0

    # Find first peak after zero crossing
    max_peak = 0.0
    peak_lag = 1
    for lag in range(1, len(autocorr)):
        if autocorr[lag] > max_peak:
            max_peak = autocorr[lag]
            peak_lag = lag

    # Refine with parabolic interpolation
    if 1 <= peak_lag < len(autocorr) - 1:
        alpha = autocorr[peak_lag - 1]
        beta = autocorr[peak_lag]
        gamma = autocorr[peak_lag + 1]
        p = 0.5 * (alpha - gamma) / (alpha - 2*beta + gamma)
        peak_lag = peak_lag + p

    freq = sample_rate / peak_lag if peak_lag > 0 else 440.0
    # Clamp to reasonable musical range
    freq = max(20.0, min(4000.0, freq))
    return freq


def freq_to_midi(freq):
    """Convert frequency to MIDI note number."""
    return 69 + 12 * math.log2(freq / 440.0)


def midi_to_freq(note):
    """Convert MIDI note number to frequency."""
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def split_into_zones(frames, sample_rate, root_note, num_zones=4):
    """Split sample into octave zones."""
    total = len(frames)
    zones = []

    # Determine zone boundaries: each zone covers ~1 octave
    # Root note is the detected pitch. We create zones around it.
    zone_width = 12  # semitones

    # Start from root_note - (num_zones//2)*12
    start_note = root_note - (num_zones // 2) * 12

    for i in range(num_zones):
        z_root = start_note + i * 12
        z_min = max(0, z_root - 6)
        z_max = min(127, z_root + 5)

        # For a single sample, we just duplicate the whole sample for each zone
        # In a real workflow, you'd record at each root note. Here we slice
        # the same sample but annotate different root notes for pitch shifting.
        zones.append({
            "rootNote": z_root,
            "minNote": z_min,
            "maxNote": z_max,
            "frames": frames,
            "sampleRate": sample_rate,
        })

    return zones


def create_velocity_layers(frames, sample_rate, sampwidth):
    """Create soft/medium/loud layers from a single sample.

    If the sample has sufficient dynamic range, we segment by RMS amplitude.
    Otherwise we use the full sample with gain adjustments.
    """
    total = len(frames)
    window = int(sample_rate * 0.01)  # 10ms windows
    if window < 1:
        window = 1

    # Compute RMS per window
    rms_values = []
    for i in range(0, total, window):
        chunk = frames[i:i+window]
        rms = math.sqrt(sum(f*f for f in chunk) / len(chunk)) if chunk else 0.0
        rms_values.append(rms)

    avg_rms = sum(rms_values) / len(rms_values) if rms_values else 0.0
    max_rms = max(rms_values) if rms_values else 0.0

    # If dynamic range is small, just use gain-adjusted copies
    if max_rms < 0.01 or (max_rms / (avg_rms + 1e-9)) < 2.0:
        # Low dynamic range: use full sample with gain adjustments
        soft = [f * 0.5 for f in frames]
        medium = frames[:]
        loud = [f * 1.2 for f in frames]
        # Clip loud
        loud = [max(-1.0, min(1.0, f)) for f in loud]
        return {"soft": soft, "medium": medium, "loud": loud}

    # Segment by amplitude thresholds
    soft_thresh = avg_rms * 0.6
    loud_thresh = avg_rms * 1.4

    soft = []
    medium = []
    loud = []

    for i, frame in enumerate(frames):
        w = i // window
        rms = rms_values[min(w, len(rms_values)-1)]
        if rms < soft_thresh:
            soft.append(frame)
            medium.append(frame * 0.8)
            loud.append(frame * 0.5)
        elif rms > loud_thresh:
            soft.append(frame * 0.5)
            medium.append(frame * 0.8)
            loud.append(frame)
        else:
            soft.append(frame * 0.7)
            medium.append(frame)
            loud.append(frame * 1.2)

    # Clip all
    soft = [max(-1.0, min(1.0, f)) for f in soft]
    medium = [max(-1.0, min(1.0, f)) for f in medium]
    loud = [max(-1.0, min(1.0, f)) for f in loud]

    return {"soft": soft, "medium": medium, "loud": loud}


def main():
    parser = argparse.ArgumentParser(description="Split a WAV into multi-sample zones")
    parser.add_argument("input", help="Input WAV file")
    parser.add_argument("--output-dir", "-o", default="./zones", help="Output directory")
    parser.add_argument("--zones", "-z", type=int, default=4, help="Number of octave zones (3-5)")
    parser.add_argument("--root-note", "-r", type=int, default=-1, help="Override root MIDI note")
    args = parser.parse_args()

    if not os.path.exists(args.input):
        print(f"Error: {args.input} not found")
        return 1

    args.zones = max(3, min(5, args.zones))

    print(f"Reading {args.input}...")
    frames, sample_rate, sampwidth = read_wav(args.input)
    print(f"  Sample rate: {sample_rate} Hz, Frames: {len(frames)}, Width: {sampwidth} bytes")

    if args.root_note >= 0:
        root_note = args.root_note
        print(f"Using override root note: {root_note}")
    else:
        freq = detect_pitch(frames, sample_rate)
        root_note = int(round(freq_to_midi(freq)))
        print(f"Detected pitch: {freq:.1f} Hz -> MIDI note {root_note}")

    os.makedirs(args.output_dir, exist_ok=True)

    zones = split_into_zones(frames, sample_rate, root_note, args.zones)

    manifest = {
        "name": os.path.splitext(os.path.basename(args.input))[0],
        "source": os.path.basename(args.input),
        "rootNote": root_note,
        "zones": []
    }

    print(f"Creating {args.zones} zones with velocity layers...")

    for i, zone in enumerate(zones):
        z_root = zone["rootNote"]
        z_min = zone["minNote"]
        z_max = zone["maxNote"]

        print(f"  Zone {i+1}: root={z_root}, range=[{z_min}-{z_max}]")

        layers = create_velocity_layers(zone["frames"], sample_rate, sampwidth)

        zone_entry = {
            "rootNote": z_root,
            "minNote": z_min,
            "maxNote": z_max,
            "minVelocity": 0.0,
            "maxVelocity": 1.0,
            "loopEnabled": False,
            "loopStart": 0,
            "loopEnd": 0,
            "layers": []
        }

        for layer_name, layer_frames in layers.items():
            fname = f"zone{i+1}_{layer_name}.wav"
            fpath = os.path.join(args.output_dir, fname)
            write_wav(fpath, layer_frames, sample_rate, sampwidth)
            zone_entry["layers"].append({
                "layer": layer_name,
                "file": fname
            })

        manifest["zones"].append(zone_entry)

    manifest_path = os.path.join(args.output_dir, "zones.json")
    with open(manifest_path, 'w') as f:
        json.dump(manifest, f, indent=2)

    print(f"\nDone. Manifest written to {manifest_path}")
    print(f"Load with: player.loadMultiSample(\"{manifest_path}\")")
    return 0


if __name__ == "__main__":
    exit(main())
