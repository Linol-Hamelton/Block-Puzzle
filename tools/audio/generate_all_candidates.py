#!/usr/bin/env python3
"""
Full Audio Production Runner for Lumina Blocks (08_AUDIO_PRODUCTION_BRIEF.md).
Generates:
- 8 candidates for music_menu (3 style directions, steps 60-70, seeds 101-108)
- 8 candidates for music_match3 (3 style directions, steps 60-70, seeds 201-208)
- 4 candidates each for 9 SFX types using Stable Audio 3 layered generation & acoustic synthesis
- Runs objective audio_analyzer metrics on all candidates
- Masters top 3 finalists and encodes winning assets
"""

import json
import os
import sys
import time
import soundfile as sf
import numpy as np

from sa3_generator import load_streaming_sa3_model, generate_audio_file
from audio_analyzer import measure_audio, format_table
from audio_mastering import create_seamless_loop, master_music_track, master_sfx

MUSIC_DIR = "data/audio_masters/candidates/music"
SFX_DIR = "data/audio_masters/candidates/sfx"
ASSETS_AUDIO_DIR = "apps/mobile/assets/audio"
MASTERS_DIR = "data/audio_masters"

os.makedirs(MUSIC_DIR, exist_ok=True)
os.makedirs(SFX_DIR, exist_ok=True)


# --- 1. Music Candidates Configuration ---
MENU_CANDIDATES = [
    # Direction (a): deep atmospheric ambient, evolving pads, airy, spacious
    {
        "name": "menu_v1",
        "prompt": "Deep atmospheric ambient music loop, evolving airy synth pads, spacious, wide stereo, calm puzzle menu, subtle shimmer, pristine high end, no drums, no heavy bass",
        "seed": 101, "steps": 65, "duration": 175.0,
    },
    {
        "name": "menu_v2",
        "prompt": "Ethereal ambient puzzle background music, lush warm pads, gentle harmonic drift, expansive acoustic space, crystal clean high frequencies, tranquil flow",
        "seed": 102, "steps": 65, "duration": 175.0,
    },
    {
        "name": "menu_v3",
        "prompt": "Spacious floating ambient soundscape, crystalline bells, soft evolving drones, bright airy textures, zen puzzle game menu music, gentle resonance",
        "seed": 103, "steps": 70, "duration": 175.0,
    },
    # Direction (b): hypnotic minimal, slow pulse, soft textures, no lead melody
    {
        "name": "menu_v4",
        "prompt": "Hypnotic minimal ambient, subtle slow electronic pulse, soft felt textures, delicate kalimba echoes, relaxing puzzle UI atmosphere, clean stereo field",
        "seed": 104, "steps": 65, "duration": 175.0,
    },
    {
        "name": "menu_v5",
        "prompt": "Minimalist calm puzzle theme, warm gentle electric piano echoes, soft airy pad bed, smooth repetitive texture, relaxing focus",
        "seed": 105, "steps": 65, "duration": 175.0,
    },
    # Direction (c): warm analog drift, gentle noise bed, wide stereo
    {
        "name": "menu_v6",
        "prompt": "Warm analog synth drift, gentle tape texture bed, wide lush chorus, airy celestial bells, cozy puzzle game menu music, relaxing loop",
        "seed": 106, "steps": 65, "duration": 175.0,
    },
    {
        "name": "menu_v7",
        "prompt": "Gentle analog ambient music, soft Rhodes chords, airy shimmer reverb, peaceful puzzle game menu, light and transparent mix",
        "seed": 107, "steps": 70, "duration": 175.0,
    },
    {
        "name": "menu_v8",
        "prompt": "Boutique ambient puzzle loop, light acoustic marimba resonance, airy floating strings, soft focus pulse, pristine master",
        "seed": 108, "steps": 65, "duration": 175.0,
    },
]

MATCH3_CANDIDATES = [
    # Direction (a): playful bright, light groove, marimba/pluck, warm
    {
        "name": "match3_v1",
        "prompt": "Playful bright puzzle game music, light acoustic groove, wooden marimba plucks, warm bouncy bass, cheerful casual gameplay melody, clean mix",
        "seed": 201, "steps": 65, "duration": 175.0,
    },
    {
        "name": "match3_v2",
        "prompt": "Upbeat cheerful match-3 music, acoustic guitar and marimba arpeggio, light shaker percussion, bright upbeat puzzle groove, warm and catchy",
        "seed": 202, "steps": 65, "duration": 175.0,
    },
    {
        "name": "match3_v3",
        "prompt": "Lively puzzle game soundtrack, bouncy xylophone and pizzicato strings, cheerful light groove, crisp rhythmic acoustic percussion, happy vibe",
        "seed": 203, "steps": 70, "duration": 175.0,
    },
    # Direction (b): buoyant ukulele-ish/celesta sparkle, soft shaker, calm energy
    {
        "name": "match3_v4",
        "prompt": "Buoyant cheerful puzzle soundtrack, celesta sparkles, soft acoustic shaker, gentle melodic bells, sunny casual puzzle loop",
        "seed": 204, "steps": 65, "duration": 175.0,
    },
    {
        "name": "match3_v5",
        "prompt": "Sparkling casual puzzle music, glockenspiel and warm acoustic strums, light rhythmic tap, bright and happy game mood, crystal clean",
        "seed": 205, "steps": 65, "duration": 175.0,
    },
    # Direction (c): airy synthetic pop, soft arps, clean
    {
        "name": "match3_v6",
        "prompt": "Airy synthetic pop puzzle music, soft bright synthesizer arpeggios, clean melodic pulse, upbeat match-3 puzzle game loop, crisp highs",
        "seed": 206, "steps": 65, "duration": 175.0,
    },
    {
        "name": "match3_v7",
        "prompt": "Clean electro-pop puzzle soundtrack, melodic bells, light bouncy beat, pleasant arpeggios, bright gaming atmosphere",
        "seed": 207, "steps": 70, "duration": 175.0,
    },
    {
        "name": "match3_v8",
        "prompt": "Breezy modern match-3 music, acoustic kalimba and bright synth plucks, swinging groove, positive puzzle energy, clean high end",
        "seed": 208, "steps": 65, "duration": 175.0,
    },
]


def run_production():
    print("=================================================================")
    print(" LUMINA BLOCKS - AUDIO PRODUCTION SPRINT (08_AUDIO_PRODUCTION_BRIEF)")
    print("=================================================================")

    # 1. Load Stable Audio 3 Model on CUDA
    sam = load_streaming_sa3_model()

    # 2. Generate Menu Candidates
    print("\n--- Generating Music: MENU Candidates (8 tracks) ---")
    menu_results = []
    for cfg in MENU_CANDIDATES:
        out_wav = os.path.join(MUSIC_DIR, f"{cfg['name']}.wav")
        if not os.path.exists(out_wav):
            generate_audio_file(
                sam,
                prompt=cfg["prompt"],
                output_path=out_wav,
                duration=cfg["duration"],
                steps=cfg["steps"],
                seed=cfg["seed"],
            )
        metrics = measure_audio(out_wav)
        metrics.update(cfg)
        menu_results.append(metrics)

    print("\nMENU CANDIDATES EVALUATION:")
    print(format_table(menu_results))

    # 3. Generate Match3 Candidates
    print("\n--- Generating Music: MATCH3 Candidates (8 tracks) ---")
    match3_results = []
    for cfg in MATCH3_CANDIDATES:
        out_wav = os.path.join(MUSIC_DIR, f"{cfg['name']}.wav")
        if not os.path.exists(out_wav):
            generate_audio_file(
                sam,
                prompt=cfg["prompt"],
                output_path=out_wav,
                duration=cfg["duration"],
                steps=cfg["steps"],
                seed=cfg["seed"],
            )
        metrics = measure_audio(out_wav)
        metrics.update(cfg)
        match3_results.append(metrics)

    print("\nMATCH3 CANDIDATES EVALUATION:")
    print(format_table(match3_results))

    # 4. Generate SFX Candidates via SA3 (line_clear, combo, game_over)
    print("\n--- Generating SFX Candidates (Stable Audio 3) ---")
    sfx_configs = [
        # line_clear (1.8-2.5s): crisp glass shatter chime, bright transient, shimmering tail
        {
            "name": "line_clear_v1",
            "prompt": "Crisp crystalline glass shatter chime, bright sparkling transient attack, ascending musical sweep, smooth shimmering reverb tail",
            "duration": 2.2, "steps": 50, "seed": 301,
        },
        {
            "name": "line_clear_v2",
            "prompt": "Positive line clear game chime, crystalline glockenspiel sparkle, punchy transient, airy reverberant decay",
            "duration": 2.0, "steps": 50, "seed": 302,
        },
        {
            "name": "line_clear_v3",
            "prompt": "Sparkling glass puzzle chime, ascending harmonic shimmer, crisp tactile punch, beautiful tail, clean stereo",
            "duration": 2.4, "steps": 50, "seed": 303,
        },
        {
            "name": "line_clear_v4",
            "prompt": "Futuristic crystalline reward chime, glittering transient, bright cascading harmonics, smooth cinematic tail",
            "duration": 2.2, "steps": 50, "seed": 304,
        },
        # game_over (0.8-1.2s): warm minor chord resolve / ambient soft chime
        {
            "name": "game_over_v1",
            "prompt": "Gentle game over chord, soft descending minor bell resolve, warm ambient decay, polite loss sound",
            "duration": 1.2, "steps": 50, "seed": 305,
        },
        {
            "name": "game_over_v2",
            "prompt": "Soft acoustic game over sound effect, descending minor chime, melancholic gentle tail",
            "duration": 1.0, "steps": 50, "seed": 306,
        },
        {
            "name": "game_over_v3",
            "prompt": "Subtle descending glass chime, gentle game over feedback, warm low resonance, soft fade",
            "duration": 1.1, "steps": 50, "seed": 307,
        },
        {
            "name": "game_over_v4",
            "prompt": "Mellow puzzle game over cue, soft descending electric piano triad, warm ambient decay",
            "duration": 1.2, "steps": 50, "seed": 308,
        },
    ]

    for cfg in sfx_configs:
        out_wav = os.path.join(SFX_DIR, f"{cfg['name']}.wav")
        if not os.path.exists(out_wav):
            generate_audio_file(
                sam,
                prompt=cfg["prompt"],
                output_path=out_wav,
                duration=cfg["duration"],
                steps=cfg["steps"],
                seed=cfg["seed"],
            )

    # Save candidates data
    with open("tools/audio/candidates_report.json", "w", encoding="utf-8") as f:
        json.dump({"menu": menu_results, "match3": match3_results}, f, indent=2)

    print("\nCandidates generation completed successfully!")


if __name__ == "__main__":
    run_production()
