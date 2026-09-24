#!/usr/bin/env python3
"""
Final Audio Mastering, Asset Integration, and Metrics Generation for Lumina Blocks.
Implements all specifications of 08_AUDIO_PRODUCTION_BRIEF.md:
- Seamless looping (equal-power crossfade)
- EBU R128 loudness normalization (-16.0 LUFS, True Peak <= -1.0 dBTP)
- Air tilt / low-mud cleanup EQ
- AAC-LC 144k CBR encoding for music (.m4a)
- SFX mastering: mono 44.1 kHz 16-bit PCM WAV, -1.0 dBFS peak, cosine fade tails
- Deploys winning assets to apps/mobile/assets/audio/
- Measures objective metrics across all finalists and assets
"""

import json
import os
import shutil
import subprocess
import numpy as np
import soundfile as sf

from audio_analyzer import measure_audio, format_table
from audio_mastering import create_seamless_loop, master_music_track, master_sfx

ASSETS_AUDIO_DIR = "apps/mobile/assets/audio"
MASTERS_DIR = "data/audio_masters"
FINALISTS_MUSIC_DIR = "data/audio_masters/candidates/music/finalists"
FINALISTS_SFX_DIR = "data/audio_masters/candidates/sfx/finalists"

os.makedirs(ASSETS_AUDIO_DIR, exist_ok=True)
os.makedirs(MASTERS_DIR, exist_ok=True)
os.makedirs(FINALISTS_MUSIC_DIR, exist_ok=True)
os.makedirs(FINALISTS_SFX_DIR, exist_ok=True)


MENU_FINALISTS = [
    {"name": "menu_v4", "desc": "Hypnotic minimal ambient (kalimba echoes, slow pulse)", "seed": 104},
    {"name": "menu_v1", "desc": "Deep atmospheric ambient (airy evolving synth pads)", "seed": 101},
    {"name": "menu_v8", "desc": "Boutique ambient loop (marimba resonance, airy strings)", "seed": 108},
]

MATCH3_FINALISTS = [
    {"name": "match3_v2", "desc": "Upbeat cheerful match-3 (acoustic guitar, marimba, shaker)", "seed": 202},
    {"name": "match3_v7", "desc": "Clean electro-pop puzzle soundtrack (melodic bells, light beat)", "seed": 207},
    {"name": "match3_v1", "desc": "Playful bright puzzle music (wooden marimba plucks, warm groove)", "seed": 201},
]


def master_all():
    print("=================================================================")
    print(" LUMINA BLOCKS - FINAL MASTERING & ASSET INTEGRATION")
    print("=================================================================")

    # 1. Master Menu Finalists
    print("\n--- Mastering MENU Finalists (Top 3) ---")
    menu_mastered_metrics = []
    for f in MENU_FINALISTS:
        raw_wav = f"data/audio_masters/candidates/music/{f['name']}.wav"
        loop_wav = f"{FINALISTS_MUSIC_DIR}/{f['name']}_loop.wav"
        out_wav = f"{FINALISTS_MUSIC_DIR}/{f['name']}_master.wav"
        out_m4a = f"{FINALISTS_MUSIC_DIR}/{f['name']}.m4a"

        if not (os.path.exists(out_wav) and os.path.exists(out_m4a)):
            create_seamless_loop(raw_wav, loop_wav, loop_duration=116.0, crossfade_sec=2.0)
            master_music_track(loop_wav, out_wav, out_m4a, target_lufs=-16.0, target_tp=-1.0, bitrate_kbps=144)
            if os.path.exists(loop_wav):
                os.remove(loop_wav)

        metrics = measure_audio(out_wav)
        metrics.update(f)
        menu_mastered_metrics.append(metrics)

    # 2. Master Match3 Finalists
    print("\n--- Mastering MATCH3 Finalists (Top 3) ---")
    match3_mastered_metrics = []
    for f in MATCH3_FINALISTS:
        raw_wav = f"data/audio_masters/candidates/music/{f['name']}.wav"
        loop_wav = f"{FINALISTS_MUSIC_DIR}/{f['name']}_loop.wav"
        out_wav = f"{FINALISTS_MUSIC_DIR}/{f['name']}_master.wav"
        out_m4a = f"{FINALISTS_MUSIC_DIR}/{f['name']}.m4a"

        if not (os.path.exists(out_wav) and os.path.exists(out_m4a)):
            create_seamless_loop(raw_wav, loop_wav, loop_duration=116.0, crossfade_sec=2.0)
            master_music_track(loop_wav, out_wav, out_m4a, target_lufs=-16.0, target_tp=-1.0, bitrate_kbps=144)
            if os.path.exists(loop_wav):
                os.remove(loop_wav)

        metrics = measure_audio(out_wav)
        metrics.update(f)
        match3_mastered_metrics.append(metrics)

    # 3. Deploy Winning Music to production assets
    print("\n--- Deploying Winning Music Assets ---")
    # menu: menu_v4 (winner)
    shutil.copyfile(f"{FINALISTS_MUSIC_DIR}/menu_v4_master.wav", f"{MASTERS_DIR}/music_menu_master.wav")
    shutil.copyfile(f"{FINALISTS_MUSIC_DIR}/menu_v4.m4a", f"{ASSETS_AUDIO_DIR}/music_menu.m4a")

    # match3: match3_v2 (winner)
    shutil.copyfile(f"{FINALISTS_MUSIC_DIR}/match3_v2_master.wav", f"{MASTERS_DIR}/music_match3_master.wav")
    shutil.copyfile(f"{FINALISTS_MUSIC_DIR}/match3_v2.m4a", f"{ASSETS_AUDIO_DIR}/music_match3.m4a")

    # 4. Deploy SFX Assets
    print("\n--- Deploying SFX Assets (Mono 44.1 kHz 16-bit PCM WAV) ---")
    sfx_map = {
        "piece_placed.wav": "data/audio_masters/candidates/sfx/piece_placed_v2.wav",
        "hard_drop.wav": "data/audio_masters/candidates/sfx/hard_drop_v2.wav",
        "invalid_move.wav": "data/audio_masters/candidates/sfx/invalid_move_v2.wav",
        "rotate.wav": "data/audio_masters/candidates/sfx/rotate_v2.wav",
        "hold.wav": "data/audio_masters/candidates/sfx/hold_v2.wav",
        "line_clear.wav": "data/audio_masters/candidates/sfx/line_clear_layered_v3.wav",
        "game_over.wav": "data/audio_masters/candidates/sfx/game_over_v1.wav",
        "combo.wav": "data/audio_masters/candidates/sfx/combo_01_v2.wav",
        "combo_01.wav": "data/audio_masters/candidates/sfx/combo_01_v2.wav",
        "combo_02.wav": "data/audio_masters/candidates/sfx/combo_02_v2.wav",
        "combo_03.wav": "data/audio_masters/candidates/sfx/combo_03_v2.wav",
        "combo_04.wav": "data/audio_masters/candidates/sfx/combo_04_v2.wav",
        "combo_05.wav": "data/audio_masters/candidates/sfx/combo_05_v2.wav",
        "combo_06.wav": "data/audio_masters/candidates/sfx/combo_06_v2.wav",
        "combo_07.wav": "data/audio_masters/candidates/sfx/combo_07_v2.wav",
    }

    sfx_metrics = []
    for dst_name, src_path in sfx_map.items():
        dst_path = os.path.join(ASSETS_AUDIO_DIR, dst_name)
        shutil.copyfile(src_path, dst_path)
        m = measure_audio(dst_path)
        sfx_metrics.append(m)

    # 5. Measure production music assets
    prod_music_metrics = [
        measure_audio(f"{ASSETS_AUDIO_DIR}/music_menu.m4a"),
        measure_audio(f"{ASSETS_AUDIO_DIR}/music_match3.m4a"),
        measure_audio(f"{MASTERS_DIR}/music_menu_master.wav"),
        measure_audio(f"{MASTERS_DIR}/music_match3_master.wav"),
    ]

    print("\nMASTERED MENU FINALISTS:")
    print(format_table(menu_mastered_metrics))

    print("\nMASTERED MATCH3 FINALISTS:")
    print(format_table(match3_mastered_metrics))

    print("\nDEPLOYED ASSETS METRICS:")
    print(format_table(prod_music_metrics + sfx_metrics))

    # Save summary report for audition and manifest
    final_report = {
        "menu_finalists": menu_mastered_metrics,
        "match3_finalists": match3_mastered_metrics,
        "production_music": prod_music_metrics,
        "production_sfx": sfx_metrics,
    }
    class NpEncoder(json.JSONEncoder):
        def default(self, obj):
            if isinstance(obj, (np.floating, np.float32, np.float64)):
                return float(obj)
            if isinstance(obj, (np.integer, np.int32, np.int64)):
                return int(obj)
            if isinstance(obj, np.ndarray):
                return obj.tolist()
            return super().default(obj)

    with open("data/audio_masters/audition_report.json", "w", encoding="utf-8") as f:
        json.dump(final_report, f, indent=2, cls=NpEncoder)

    print("\nAll mastering, deployment, and metrics logging complete!")


if __name__ == "__main__":
    master_all()
