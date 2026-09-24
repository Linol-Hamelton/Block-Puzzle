#!/usr/bin/env python3
"""
Layered SFX Sound Design and Candidate Generator for Lumina Blocks.
Generates >=4 distinct candidates for each of the 9 SFX:
- line_clear (v1..v4)
- combo_01..07 (v1..v4 ladder sets)
- piece_placed (v1..v4)
- hard_drop (v1..v4)
- invalid_move (v1..v4)
- game_over (v1..v4)
- rotate (v1..v4)
- hold (v1..v4)
"""

import os
import numpy as np
import soundfile as sf
from audio_mastering import master_sfx

SFX_CANDIDATES_DIR = "data/audio_masters/candidates/sfx"
os.makedirs(SFX_CANDIDATES_DIR, exist_ok=True)
SR = 44100


def create_transient_punch(duration_sec=0.03, freq_start=3500.0, freq_end=300.0):
    """Generates an ultra-fast punch transient (<5 ms attack)."""
    t = np.linspace(0, duration_sec, int(SR * duration_sec))
    # Exponential frequency chirp
    freq = freq_start * ((freq_end / freq_start) ** (t / duration_sec))
    phase = 2 * np.pi * np.cumsum(freq) / SR
    env = np.exp(-t * 80.0)  # very fast decay
    punch = np.sin(phase) * env
    return punch


def create_sparkle_layer(duration_sec=1.5, freqs=[2400, 3600, 4800, 6000, 7200], decay=4.0):
    """Generates high-frequency shimmering crystal harmonics (2-8 kHz)."""
    t = np.linspace(0, duration_sec, int(SR * duration_sec))
    sparkle = np.zeros_like(t)
    for i, f in enumerate(freqs):
        phase = 2 * np.pi * f * t + (i * 0.4)
        env = np.exp(-t * (decay + i * 0.8))
        # Subtle chorus modulation
        mod = 1.0 + 0.08 * np.sin(2 * np.pi * (6.0 + i) * t)
        sparkle += np.sin(phase) * env * mod * (1.0 / (i + 1.0))
    return sparkle / (np.max(np.abs(sparkle)) + 1e-9)


def generate_piece_placed_candidates():
    """Generates 4 candidates for piece_placed (0.12-0.18s tactile 'thock')."""
    for v, (f_body, q, f_click, decay_rate) in enumerate([
        (160.0, 18.0, 3200.0, 35.0),  # v1: warm acoustic thock
        (180.0, 22.0, 3800.0, 42.0),  # v2: crisp glass tactile
        (150.0, 15.0, 2800.0, 30.0),  # v3: solid wood pop
        (200.0, 25.0, 4200.0, 45.0),  # v4: snappy ceramic tap
    ], start=1):
        dur = 0.15
        t = np.linspace(0, dur, int(SR * dur))
        body = np.sin(2 * np.pi * f_body * t) * np.exp(-t * decay_rate)
        # Fast click transient
        click_len = int(0.015 * SR)
        click_t = t[:click_len]
        click = np.sin(2 * np.pi * f_click * click_t) * np.exp(-click_t * 250.0)
        click_padded = np.pad(click, (0, len(t) - click_len))

        mixed = 0.65 * body + 0.35 * click_padded
        raw_path = os.path.join(SFX_CANDIDATES_DIR, f"piece_placed_v{v}_raw.wav")
        out_path = os.path.join(SFX_CANDIDATES_DIR, f"piece_placed_v{v}.wav")
        sf.write(raw_path, mixed, SR)
        master_sfx(raw_path, out_path, peak_dbfs=-1.0, fade_tail_ms=35.0, highpass_hz=120.0)
        if os.path.exists(raw_path):
            os.remove(raw_path)


def generate_hard_drop_candidates():
    """Generates 4 candidates for hard_drop (0.28-0.35s solid punch)."""
    for v, (f_low, punch_weight, body_decay) in enumerate([
        (110.0, 0.45, 18.0),
        (125.0, 0.50, 22.0),
        (95.0, 0.40, 15.0),
        (140.0, 0.55, 25.0),
    ], start=1):
        dur = 0.32
        t = np.linspace(0, dur, int(SR * dur))
        # Pitch drop body
        freq = f_low * np.exp(-t * 12.0) + 45.0
        phase = 2 * np.pi * np.cumsum(freq) / SR
        body = np.sin(phase) * np.exp(-t * body_decay)

        # Transient punch
        punch = create_transient_punch(duration_sec=0.035, freq_start=4500.0, freq_end=f_low)
        punch_padded = np.pad(punch, (0, len(t) - len(punch)))

        mixed = (1.0 - punch_weight) * body + punch_weight * punch_padded
        raw_path = os.path.join(SFX_CANDIDATES_DIR, f"hard_drop_v{v}_raw.wav")
        out_path = os.path.join(SFX_CANDIDATES_DIR, f"hard_drop_v{v}.wav")
        sf.write(raw_path, mixed, SR)
        master_sfx(raw_path, out_path, peak_dbfs=-1.0, fade_tail_ms=45.0, highpass_hz=80.0)
        if os.path.exists(raw_path):
            os.remove(raw_path)


def generate_invalid_move_candidates():
    """Generates 4 candidates for invalid_move (0.18-0.22s polite rejection thud)."""
    for v, (f_thud, f_buzz) in enumerate([
        (130.0, 220.0),
        (145.0, 260.0),
        (120.0, 190.0),
        (160.0, 280.0),
    ], start=1):
        dur = 0.20
        t = np.linspace(0, dur, int(SR * dur))
        # Dual-tone dissonance
        tone1 = np.sin(2 * np.pi * f_thud * t) * np.exp(-t * 24.0)
        tone2 = np.sin(2 * np.pi * f_buzz * t) * np.exp(-t * 28.0)
        # Transient click
        click = np.sin(2 * np.pi * 1800.0 * t[:int(0.01 * SR)]) * np.exp(-t[:int(0.01 * SR)] * 300.0)
        click_padded = np.pad(click, (0, len(t) - len(click)))

        mixed = 0.45 * tone1 + 0.40 * tone2 + 0.15 * click_padded
        raw_path = os.path.join(SFX_CANDIDATES_DIR, f"invalid_move_v{v}_raw.wav")
        out_path = os.path.join(SFX_CANDIDATES_DIR, f"invalid_move_v{v}.wav")
        sf.write(raw_path, mixed, SR)
        master_sfx(raw_path, out_path, peak_dbfs=-1.0, fade_tail_ms=35.0, highpass_hz=100.0)
        if os.path.exists(raw_path):
            os.remove(raw_path)


def generate_rotate_and_hold_candidates():
    """Generates 4 candidates each for rotate and hold (0.08-0.12s crisp ticks)."""
    for v in range(1, 5):
        # Rotate: crisp tick
        dur_rot = 0.10
        t_rot = np.linspace(0, dur_rot, int(SR * dur_rot))
        f_rot = 3200.0 + (v * 300.0)
        tick = np.sin(2 * np.pi * f_rot * t_rot) * np.exp(-t_rot * 65.0)
        noise = (np.random.rand(len(t_rot)) * 2.0 - 1.0) * np.exp(-t_rot * 120.0) * 0.3
        rot_mixed = tick + noise
        raw_r = os.path.join(SFX_CANDIDATES_DIR, f"rotate_v{v}_raw.wav")
        out_r = os.path.join(SFX_CANDIDATES_DIR, f"rotate_v{v}.wav")
        sf.write(raw_r, rot_mixed, SR)
        master_sfx(raw_r, out_r, peak_dbfs=-1.0, fade_tail_ms=30.0, highpass_hz=180.0)
        if os.path.exists(raw_r):
            os.remove(raw_r)

        # Hold: double latch click
        dur_hold = 0.13
        t_hold = np.linspace(0, dur_hold, int(SR * dur_hold))
        hold_sig = np.zeros_like(t_hold)
        # Click 1
        c1_len = int(0.015 * SR)
        hold_sig[:c1_len] += np.sin(2 * np.pi * 2600.0 * t_hold[:c1_len]) * np.exp(-t_hold[:c1_len] * 200.0)
        # Click 2 (18 ms later)
        c2_start = int(0.018 * SR)
        c2_len = int(0.02 * SR)
        if c2_start + c2_len < len(hold_sig):
            hold_sig[c2_start : c2_start + c2_len] += 0.85 * np.sin(2 * np.pi * 3800.0 * t_hold[:c2_len]) * np.exp(-t_hold[:c2_len] * 180.0)
        raw_h = os.path.join(SFX_CANDIDATES_DIR, f"hold_v{v}_raw.wav")
        out_h = os.path.join(SFX_CANDIDATES_DIR, f"hold_v{v}.wav")
        sf.write(raw_h, hold_sig, SR)
        master_sfx(raw_h, out_h, peak_dbfs=-1.0, fade_tail_ms=30.0, highpass_hz=160.0)
        if os.path.exists(raw_h):
            os.remove(raw_h)


def generate_combo_ladder_candidates():
    """
    Generates 4 candidate ladders for combo_01..07 (0.35-0.55s each).
    Escalating pentatonic ladder: C5, D5, E5, G5, A5, C6, D6.
    Bright crystal shimmer, rich harmonics, centroid >= 2.5 kHz.
    """
    PENTATONIC_FREQS = [523.25, 587.33, 659.25, 783.99, 880.00, 1046.50, 1174.66]

    for v, (shimmer_gain, decay_base) in enumerate([
        (0.40, 7.5),   # v1: Balanced crystalline bells
        (0.55, 6.5),   # v2: Extra bright sparkling ladder
        (0.30, 9.0),   # v3: Crisp short marimba cascade
        (0.48, 7.0),   # v4: Ethereal celestial bells
    ], start=1):
        for step_idx, root_f in enumerate(PENTATONIC_FREQS, start=1):
            dur = 0.45 + (step_idx * 0.02)  # subtle length expansion as ladder climbs
            t = np.linspace(0, dur, int(SR * dur))

            # Fundamental + harmonics (1st, 2nd, 3rd, 4th, 6th)
            fundamental = np.sin(2 * np.pi * root_f * t) * np.exp(-t * decay_base)
            h1 = np.sin(2 * np.pi * (root_f * 2) * t) * np.exp(-t * (decay_base + 1.5)) * 0.6
            h2 = np.sin(2 * np.pi * (root_f * 3) * t) * np.exp(-t * (decay_base + 3.0)) * 0.35
            h3 = np.sin(2 * np.pi * (root_f * 4) * t) * np.exp(-t * (decay_base + 4.5)) * 0.25

            # High sparkling overtone layer (chime resonance)
            chime_f = root_f * 4.2
            sparkle = np.sin(2 * np.pi * chime_f * t) * np.exp(-t * (decay_base + 2.0)) * shimmer_gain

            # Transient strike
            strike_len = int(0.008 * SR)
            strike = (np.random.rand(strike_len) * 2.0 - 1.0) * np.exp(-t[:strike_len] * 400.0) * 0.15
            strike_padded = np.pad(strike, (0, len(t) - strike_len))

            combo_signal = fundamental + h1 + h2 + h3 + sparkle + strike_padded

            raw_path = os.path.join(SFX_CANDIDATES_DIR, f"combo_{step_idx:02d}_v{v}_raw.wav")
            out_path = os.path.join(SFX_CANDIDATES_DIR, f"combo_{step_idx:02d}_v{v}.wav")
            sf.write(raw_path, combo_signal, SR)
            master_sfx(raw_path, out_path, peak_dbfs=-1.0, fade_tail_ms=40.0, highpass_hz=140.0)
            if os.path.exists(raw_path):
                os.remove(raw_path)


def generate_line_clear_layered_candidates():
    """
    Generates 4 layered candidates for line_clear (1.8-2.2s):
    Layer 1: Initial crisp punch transient (<5 ms)
    Layer 2: Ascending crystalline glass shimmer chime (from SA3 generated candidates or synthesized)
    Layer 3: Sparkling high-frequency tail (2-6 kHz)
    """
    for v in range(1, 5):
        sa3_cand_path = os.path.join(SFX_CANDIDATES_DIR, f"line_clear_v{v}.wav")
        dur = 2.0
        t = np.linspace(0, dur, int(SR * dur))

        # Transient body
        punch = create_transient_punch(duration_sec=0.04, freq_start=4800.0, freq_end=160.0)
        punch_padded = np.pad(punch, (0, len(t) - len(punch)))

        # Sparkling harmonic cascade
        sparkle = create_sparkle_layer(duration_sec=dur, freqs=[2200, 3300, 4400, 5500, 6600, 8800], decay=3.2)

        if os.path.exists(sa3_cand_path):
            sa3_data, _ = sf.read(sa3_cand_path)
            if sa3_data.ndim > 1:
                sa3_mono = np.mean(sa3_data, axis=1)
            else:
                sa3_mono = sa3_data
            if len(sa3_mono) < len(t):
                sa3_padded = np.pad(sa3_mono, (0, len(t) - len(sa3_mono)))
            else:
                sa3_padded = sa3_mono[:len(t)]
            mixed = 0.55 * sa3_padded + 0.30 * sparkle + 0.25 * punch_padded
        else:
            mixed = 0.65 * sparkle + 0.35 * punch_padded

        raw_path = os.path.join(SFX_CANDIDATES_DIR, f"line_clear_layered_v{v}_raw.wav")
        out_path = os.path.join(SFX_CANDIDATES_DIR, f"line_clear_layered_v{v}.wav")
        sf.write(raw_path, mixed, SR)
        master_sfx(raw_path, out_path, peak_dbfs=-1.0, fade_tail_ms=60.0, highpass_hz=130.0)
        if os.path.exists(raw_path):
            os.remove(raw_path)


if __name__ == "__main__":
    print("Generating layered SFX candidates...")
    generate_piece_placed_candidates()
    generate_hard_drop_candidates()
    generate_invalid_move_candidates()
    generate_rotate_and_hold_candidates()
    generate_combo_ladder_candidates()
    generate_line_clear_layered_candidates()
    print("All layered SFX candidates generated and mastered!")
