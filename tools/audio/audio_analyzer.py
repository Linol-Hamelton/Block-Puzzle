#!/usr/bin/env python3
"""
Audio Analyzer for Lumina Blocks (FFmpeg 7.1 + NumPy).
Measures:
- Integrated Loudness (LUFS)
- True Peak (dBTP)
- Peak (dBFS)
- RMS (dBFS)
- Spectral Centroid (Hz)
- Energy < 200 Hz (%)
- Energy 6-10 kHz (%)
"""

import json
import os
import re
import subprocess
import sys
import numpy as np
import soundfile as sf

FFMPEG_PATH = r"C:\Users\Dmitry\AppData\Roaming\Python\Python314\site-packages\imageio_ffmpeg\binaries\ffmpeg-win-x86_64-v7.1.exe"
if not os.path.exists(FFMPEG_PATH):
    FFMPEG_PATH = "ffmpeg"


def measure_audio(file_path: str) -> dict:
    if not os.path.exists(file_path):
        raise FileNotFoundError(file_path)

    # 1. Read audio data with soundfile for FFT and sample stats (with FFmpeg fallback for .m4a)
    try:
        data, sr = sf.read(file_path)
    except Exception:
        cmd = [
            FFMPEG_PATH, "-hide_banner", "-i", file_path,
            "-f", "f32le", "-ar", "44100", "-ac", "2", "-"
        ]
        proc = subprocess.run(cmd, capture_output=True, check=True)
        data = np.frombuffer(proc.stdout, dtype=np.float32).reshape(-1, 2)
        sr = 44100

    if data.ndim > 1:
        mono = np.mean(data, axis=1)
    else:
        mono = data

    duration_sec = len(mono) / sr

    # Peak & RMS
    peak_linear = np.max(np.abs(mono))
    peak_dbfs = 20 * np.log10(peak_linear + 1e-9)
    rms_linear = np.sqrt(np.mean(mono ** 2))
    rms_dbfs = 20 * np.log10(rms_linear + 1e-9)

    # FFT analysis
    # For long files, take chunked average FFT to prevent huge memory usage
    chunk_size = 65536
    num_chunks = max(1, len(mono) // chunk_size)
    total_power = 0.0
    freq_power_sum = 0.0
    power_low = 0.0
    power_high = 0.0

    freqs = np.fft.rfftfreq(chunk_size, 1.0 / sr)
    low_mask = freqs < 200.0
    high_mask = (freqs >= 6000.0) & (freqs <= 10000.0)

    for i in range(num_chunks):
        chunk = mono[i * chunk_size : (i + 1) * chunk_size]
        if len(chunk) < chunk_size:
            chunk = np.pad(chunk, (0, chunk_size - len(chunk)))
        # Hann window
        windowed = chunk * np.hanning(chunk_size)
        spec = np.abs(np.fft.rfft(windowed))
        power = spec ** 2

        chunk_p_sum = np.sum(power)
        if chunk_p_sum > 1e-9:
            total_power += chunk_p_sum
            freq_power_sum += np.sum(freqs * spec)
            power_low += np.sum(power[low_mask])
            power_high += np.sum(power[high_mask])

    if total_power > 0:
        centroid = freq_power_sum / np.sqrt(total_power * chunk_size)
        pct_low = (power_low / total_power) * 100.0
        pct_high = (power_high / total_power) * 100.0
    else:
        centroid = 0.0
        pct_low = 0.0
        pct_high = 0.0

    # 2. FFmpeg ebur128 for ITU-R BS.1770-4 LUFS and True Peak
    cmd = [
        FFMPEG_PATH,
        "-hide_banner",
        "-nostats",
        "-i", file_path,
        "-af", "ebur128=peak=true",
        "-f", "null",
        "-"
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True, errors="ignore")
    stderr = proc.stderr

    # Parse ebur128 summary block
    lufs = -70.0
    true_peak = -70.0
    lra = 0.0

    m_lufs = re.search(r"Integrated loudness:\s+I:\s+([-\d\.]+)\s+LUFS", stderr)
    if m_lufs:
        lufs = float(m_lufs.group(1))

    m_tp = re.search(r"True peak:\s+Peak:\s+([-\d\.]+)\s+dBFS", stderr)
    if m_tp:
        true_peak = float(m_tp.group(1))

    m_lra = re.search(r"LRA:\s+([-\d\.]+)\s+LU", stderr)
    if m_lra:
        lra = float(m_lra.group(1))

    return {
        "file": os.path.basename(file_path),
        "path": file_path,
        "duration_sec": round(duration_sec, 2),
        "sample_rate": sr,
        "channels": data.shape[1] if data.ndim > 1 else 1,
        "lufs": round(lufs, 2),
        "true_peak_dbtp": round(true_peak, 2),
        "peak_dbfs": round(peak_dbfs, 2),
        "rms_dbfs": round(rms_dbfs, 2),
        "centroid_hz": round(float(centroid), 1),
        "energy_sub200_pct": round(float(pct_low), 1),
        "energy_6k_10k_pct": round(float(pct_high), 1),
        "lra": round(lra, 1),
        "size_bytes": os.path.getsize(file_path),
    }


def format_table(results: list) -> str:
    lines = [
        "| Файл | Длит. | LUFS | Peak | RMS | Спектр. центроид | <200 Гц | 6-10 кГц | Размер |",
        "| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |"
    ]
    for r in results:
        lines.append(
            f"| {r['file']} | {r['duration_sec']} с | {r['lufs']} LUFS | {r['peak_dbfs']} dBFS | "
            f"{r['rms_dbfs']} dBFS | {r['centroid_hz']} Гц | {r['energy_sub200_pct']}% | "
            f"{r['energy_6k_10k_pct']}% | {round(r['size_bytes']/1024, 1)} КБ |"
        )
    return "\n".join(lines)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: audio_analyzer.py <file1.wav/m4a> [file2.wav/m4a...]")
        sys.exit(1)

    results = []
    for p in sys.argv[1:]:
        if os.path.isfile(p):
            r = measure_audio(p)
            results.append(r)
        elif os.path.isdir(p):
            for fn in sorted(os.listdir(p)):
                if fn.endswith((".wav", ".m4a", ".mp3")):
                    r = measure_audio(os.path.join(p, fn))
                    results.append(r)

    print(format_table(results))
    print("\nJSON Summary:")
    print(json.dumps(results, indent=2))
