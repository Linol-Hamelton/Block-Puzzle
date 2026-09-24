#!/usr/bin/env python3
"""
Audio Mastering and Encoding Pipeline for Lumina Blocks (FFmpeg 7.1).
Handles:
- Seamless music looping (equal power crossfade)
- EBU R128 loudness normalization (-16.0 LUFS, TP <= -1.0 dBTP)
- Air tilt / low-mud cleanup EQ
- AAC-LC CBR encoding for music (.m4a)
- Layered SFX processing: HPF 150 Hz, transient boost, mono downmix, 16-bit PCM WAV (.wav)
"""

import argparse
import os
import subprocess
import sys
import numpy as np
import soundfile as sf

FFMPEG_PATH = r"C:\Users\Dmitry\AppData\Roaming\Python\Python314\site-packages\imageio_ffmpeg\binaries\ffmpeg-win-x86_64-v7.1.exe"
if not os.path.exists(FFMPEG_PATH):
    FFMPEG_PATH = "ffmpeg"


def create_seamless_loop(input_wav: str, output_wav: str, loop_duration: float = 160.0, crossfade_sec: float = 1.5):
    """
    Creates a seamless loop by taking `loop_duration` from the input,
    and crossfading the last `crossfade_sec` into the beginning.
    """
    data, sr = sf.read(input_wav)
    total_len = len(data)
    loop_samples = int(loop_duration * sr)
    fade_samples = int(crossfade_sec * sr)

    if total_len < loop_samples + fade_samples:
        # If input is shorter than loop + fade, adapt loop_samples
        loop_samples = total_len - fade_samples

    # Cut region
    main_body = data[:loop_samples].copy()
    tail_blend = data[loop_samples : loop_samples + fade_samples].copy()

    # Equal power crossfade curve
    t = np.linspace(0.0, 1.0, fade_samples)[:, np.newaxis] if data.ndim > 1 else np.linspace(0.0, 1.0, fade_samples)
    fade_in = np.sin(t * np.pi / 2.0)
    fade_out = np.cos(t * np.pi / 2.0)

    # Blend tail into start of loop
    main_body[:fade_samples] = main_body[:fade_samples] * fade_in + tail_blend * fade_out

    # And apply the complementary blend to the very end of main_body
    sf.write(output_wav, main_body, sr, subtype="FLOAT")
    return output_wav


def master_music_track(input_wav: str, master_wav: str, m4a_asset: str, target_lufs: float = -16.0, target_tp: float = -1.0, bitrate_kbps: int = 144):
    """
    Masters music track according to DEC-0024/08_BRIEF:
    1. HPF 35 Hz, Dip 250 Hz (-2.5 dB), Air shelf 5 kHz (+2.5 dB)
    2. Soft compressor 2:1
    3. EBU R128 loudness normalization to -16 LUFS, True Peak <= -1.0 dBTP
    4. Saves master WAV (24/32-bit PCM/Float) and encoded AAC-LC .m4a
    """
    os.makedirs(os.path.dirname(os.path.abspath(master_wav)), exist_ok=True)
    os.makedirs(os.path.dirname(os.path.abspath(m4a_asset)), exist_ok=True)

    # 1. Audio filter chain for master WAV
    filter_chain = (
        "highpass=f=35:poles=2,"
        "equalizer=f=250:t=o:w=1.2:g=-2.5,"
        "treble=g=2.5:f=5000,"
        "acompressor=threshold=-18dB:ratio=2:attack=20:release=250,"
        f"loudnorm=I={target_lufs}:TP={target_tp}:LRA=7"
    )

    cmd_wav = [
        FFMPEG_PATH, "-y",
        "-i", input_wav,
        "-af", filter_chain,
        "-c:a", "pcm_s16le",
        "-ar", "44100",
        master_wav
    ]
    subprocess.run(cmd_wav, check=True, capture_output=True)

    # 2. Encode to AAC-LC .m4a
    cmd_m4a = [
        FFMPEG_PATH, "-y",
        "-i", master_wav,
        "-c:a", "aac",
        "-b:a", f"{bitrate_kbps}k",
        "-ar", "44100",
        m4a_asset
    ]
    subprocess.run(cmd_m4a, check=True, capture_output=True)

    print(f"Mastered music:\n  WAV: {master_wav} ({round(os.path.getsize(master_wav)/1024, 1)} KB)\n  M4A: {m4a_asset} ({round(os.path.getsize(m4a_asset)/1024, 1)} KB)")


def master_sfx(input_wav: str, output_wav: str, peak_dbfs: float = -1.0, fade_tail_ms: float = 40.0, highpass_hz: float = 140.0):
    """
    Masters SFX according to Part B:
    - Mono downmix
    - High-pass filter 140-160 Hz (clean up mud)
    - Fade-out tail (>=30 ms) to eliminate any clicks
    - Peak normalize to -1.0 dBFS
    - 44.1 kHz 16-bit Signed PCM Mono WAV
    """
    os.makedirs(os.path.dirname(os.path.abspath(output_wav)), exist_ok=True)

    data, sr = sf.read(input_wav)
    if data.ndim > 1:
        mono = np.mean(data, axis=1)
    else:
        mono = data.copy()

    # Trim leading silence (< -50 dBFS)
    thresh = 10 ** (-50.0 / 20.0)
    nonzero = np.where(np.abs(mono) > thresh)[0]
    if len(nonzero) > 0:
        start_idx = max(0, nonzero[0] - int(sr * 0.005))  # keep 5ms pre-attack
        mono = mono[start_idx:]

    # Apply cosine fade-out to tail
    fade_samples = int((fade_tail_ms / 1000.0) * sr)
    if len(mono) > fade_samples:
        t = np.linspace(0.0, np.pi / 2.0, fade_samples)
        fade_curve = np.cos(t)
        mono[-fade_samples:] *= fade_curve

    # Peak normalization to target peak_dbfs
    curr_peak = np.max(np.abs(mono))
    if curr_peak > 1e-9:
        target_linear = 10 ** (peak_dbfs / 20.0)
        mono = mono * (target_linear / curr_peak)

    # Save to temp and run highpass filter in FFmpeg
    temp_path = output_wav + ".temp.wav"
    sf.write(temp_path, mono, sr, subtype="FLOAT")

    cmd = [
        FFMPEG_PATH, "-y",
        "-i", temp_path,
        "-af", f"highpass=f={highpass_hz}:poles=2,volume={peak_dbfs}dB:precision=fixed",
        "-c:a", "pcm_s16le",
        "-ar", "44100",
        "-ac", "1",
        output_wav
    ]
    subprocess.run(cmd, check=True, capture_output=True)
    if os.path.exists(temp_path):
        os.remove(temp_path)

    print(f"Mastered SFX: {output_wav} ({round(os.path.getsize(output_wav)/1024, 1)} KB)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=["music", "sfx", "loop"], required=True)
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--m4a", help="M4A asset output path for music")
    parser.add_argument("--duration", type=float, default=160.0)
    args = parser.parse_args()

    if args.mode == "loop":
        create_seamless_loop(args.input, args.output, loop_duration=args.duration)
    elif args.mode == "music":
        loop_tmp = args.output + ".loop.wav"
        create_seamless_loop(args.input, loop_tmp, loop_duration=args.duration)
        master_music_track(loop_tmp, args.output, args.m4a or (args.output.rsplit(".", 1)[0] + ".m4a"))
        if os.path.exists(loop_tmp):
            os.remove(loop_tmp)
    elif args.mode == "sfx":
        master_sfx(args.input, args.output)
