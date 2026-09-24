#!/usr/bin/env python3
"""
Stable Audio 3 Medium - Direct CUDA Streaming Generator for Lumina Blocks.
Loads model weights directly into CUDA float16 without CPU RAM commitment limits.
Supports batch candidate generation and reproducible seeds.
"""

import argparse
import json
import os
import struct
import sys
import time
import numpy as np
import soundfile as sf
import torch

from stable_audio_3.factory import create_diffusion_cond_from_config
from stable_audio_3.loading_utils import remap_state_dict_keys
from stable_audio_3.model import all_models, StableAudioModel


def load_streaming_sa3_model(device="cuda", model_name="medium"):
    print(f"[{time.strftime('%H:%M:%S')}] Resolving Stable Audio 3 '{model_name}' checkpoint...")
    cfg_path, ckpt_path = all_models[model_name].resolve()
    with open(cfg_path, "r", encoding="utf-8") as f:
        cfg = json.load(f)

    print(f"[{time.strftime('%H:%M:%S')}] Creating float16 model directly on {device}...")
    torch.set_default_device(device)
    torch.set_default_dtype(torch.float16)
    model = create_diffusion_cond_from_config(cfg)
    torch.set_default_device("cpu")
    torch.set_default_dtype(torch.float32)

    model_state = model.state_dict()

    print(f"[{time.strftime('%H:%M:%S')}] Streaming weights from safetensors to {device}...")
    with open(ckpt_path, "rb") as f:
        header_len = struct.unpack("<Q", f.read(8))[0]
        header = json.loads(f.read(header_len).decode("utf-8"))
        data_start = 8 + header_len

        sample_dict = {k: k for k in header.keys() if k != "__metadata__"}
        remapped = remap_state_dict_keys(sample_dict, model_state)

        matched = 0
        for target_k, old_k in remapped.items():
            if target_k in model_state:
                info = header[old_k]
                offsets = info["data_offsets"]
                shape = info["shape"]
                dt = np.float32 if info["dtype"] == "F32" else np.float16
                f.seek(data_start + offsets[0])
                raw = f.read(offsets[1] - offsets[0])
                arr = np.frombuffer(raw, dtype=dt).reshape(shape)
                t = torch.from_numpy(arr)
                if t.dtype == torch.float32:
                    t = t.half()
                if model_state[target_k].shape == t.shape:
                    model_state[target_k].copy_(t.to(device, non_blocking=True))
                    matched += 1

    torch.cuda.synchronize()
    model.eval().requires_grad_(False)
    vram_mb = torch.cuda.memory_allocated() // (1024 * 1024)
    print(f"[{time.strftime('%H:%M:%S')}] Model ready on {device}! Loaded {matched} tensors ({vram_mb} MB VRAM allocated).")

    sam = StableAudioModel(model, cfg, device=device, model_half=True)
    return sam


def generate_audio_file(
    sam: StableAudioModel,
    prompt: str,
    output_path: str,
    duration: float = 170.0,
    steps: int = 60,
    cfg_scale: float = 1.0,
    negative_prompt: str = None,
    seed: int = 42,
):
    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    print(f"\n[{time.strftime('%H:%M:%S')}] Generating: '{prompt[:60]}...'")
    print(f"  Duration: {duration}s | Steps: {steps} | Seed: {seed} | CFG: {cfg_scale} | Target: {output_path}")

    t0 = time.time()
    audio = sam.generate(
        prompt=prompt,
        negative_prompt=negative_prompt,
        duration=duration,
        steps=steps,
        cfg_scale=cfg_scale,
        seed=seed,
    )
    t1 = time.time()
    elapsed = t1 - t0

    # audio shape is [batch_size, channels, samples]
    audio_np = audio.squeeze(0).detach().cpu().float().numpy().T  # [samples, channels]
    sample_rate = 44100

    # Save as 32-bit float WAV candidate
    sf.write(output_path, audio_np, sample_rate, subtype="FLOAT")
    size_kb = os.path.getsize(output_path) / 1024
    print(f"[{time.strftime('%H:%M:%S')}] Saved in {elapsed:.1f}s ({size_kb:.1f} KB) -> {output_path}")

    return {
        "output_path": output_path,
        "prompt": prompt,
        "negative_prompt": negative_prompt,
        "duration": duration,
        "steps": steps,
        "seed": seed,
        "cfg_scale": cfg_scale,
        "generation_time_sec": round(elapsed, 1),
    }


def main():
    parser = argparse.ArgumentParser(description="Generate audio with Stable Audio 3 Medium")
    parser.add_argument("--prompt", type=str, help="Text prompt")
    parser.add_argument("--negative-prompt", type=str, default="low quality, noisy, distorted, muddy, bass heavy, clipping")
    parser.add_argument("--output", type=str, help="Output WAV path")
    parser.add_argument("--duration", type=float, default=170.0, help="Duration in seconds")
    parser.add_argument("--steps", type=int, default=60, help="Diffusion steps (50-100 recommended)")
    parser.add_argument("--seed", type=int, default=42, help="Random seed")
    parser.add_argument("--cfg-scale", type=float, default=1.0, help="Classifier free guidance scale")
    parser.add_argument("--batch-file", type=str, help="JSON batch plan file")

    args = parser.parse_args()

    sam = load_streaming_sa3_model()

    if args.batch_file:
        with open(args.batch_file, "r", encoding="utf-8") as f:
            batch = json.load(f)
        results = []
        for item in batch:
            res = generate_audio_file(
                sam,
                prompt=item["prompt"],
                negative_prompt=item.get("negative_prompt", args.negative_prompt),
                output_path=item["output"],
                duration=item.get("duration", 170.0),
                steps=item.get("steps", 60),
                cfg_scale=item.get("cfg_scale", 1.0),
                seed=item.get("seed", 42),
            )
            results.append(res)
        report_path = args.batch_file + ".results.json"
        with open(report_path, "w", encoding="utf-8") as f:
            json.dump(results, f, indent=2)
        print(f"\nBatch complete! Results saved to {report_path}")
    elif args.prompt and args.output:
        generate_audio_file(
            sam,
            prompt=args.prompt,
            negative_prompt=args.negative_prompt,
            output_path=args.output,
            duration=args.duration,
            steps=args.steps,
            cfg_scale=args.cfg_scale,
            seed=args.seed,
        )
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
