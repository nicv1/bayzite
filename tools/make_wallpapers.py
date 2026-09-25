#!/usr/bin/env python3
"""Generate Bayzite's original wallpapers (flowing silk ribbons).

Usage:  python3 tools/make_wallpapers.py [output_dir]
Needs:  numpy, pillow  (pip install numpy pillow)

Produces 3840x2160 JPEGs:
  bayzite-dusk.jpg   dark variant (default)
  bayzite-dawn.jpg   light variant
  bayzite-dusk-blur.png  blurred + darkened copy used for the login screen
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

W, H = 3840, 2160


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def ribbon_curve(xn, params):
    """Centre line of a ribbon (normalised coords, y grows downward)."""
    base, amp, freq, phase, tilt, amp2, freq2 = params
    return (base + tilt * (xn - 0.5)
            + amp * np.sin(2 * np.pi * freq * xn + phase)
            + amp2 * np.sin(2 * np.pi * freq2 * xn + phase * 1.7))


def render(palette, ribbons, seed, grain=0.012):
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    xn, yn = xx / W, yy / H

    # Background: diagonal gradient + soft radial bloom.
    bg_a, bg_b, bloom_col, bloom_pos = palette["bg_a"], palette["bg_b"], palette["bloom"], palette["bloom_pos"]
    t = np.clip(0.55 * xn + 0.45 * yn, 0, 1)[..., None]
    img = (1 - t) * np.array(bg_a, np.float32) + t * np.array(bg_b, np.float32)
    d = np.sqrt(((xn - bloom_pos[0]) * 1.6) ** 2 + (yn - bloom_pos[1]) ** 2)
    img += np.exp(-(d / 0.42) ** 2)[..., None] * np.array(bloom_col, np.float32)

    for r in ribbons:
        c = ribbon_curve(xn, r["curve"])
        # thickness breathes along x so the ribbon looks like folded fabric
        thick = r["width"] * (0.65 + 0.35 * np.sin(2 * np.pi * (xn * r["breath"] + r["curve"][3] * 0.3)))
        s = (yn - c) / thick               # -1..1 inside the ribbon
        inside = smoothstep(1.0, 0.92, np.abs(s))
        # fabric shading: dark core, lighter toward the upper edge
        shade = 0.5 + 0.5 * np.tanh(-s * 1.6)
        body = (1 - shade)[..., None] * np.array(r["dark"], np.float32) + shade[..., None] * np.array(r["light"], np.float32)
        # bright rim on the leading edge + outer glow
        rim = np.exp(-((s + 1.0) / 0.035) ** 2)
        glow = np.exp(-(np.maximum(np.abs(s) - 1.0, 0) / 0.35) ** 2) * (np.abs(s) > 1.0)
        a = (inside * r["alpha"])[..., None]
        img = img * (1 - a) + body * a
        img += (rim * r["rim_strength"])[..., None] * np.array(r["rim"], np.float32)
        img += (glow * r["glow_strength"])[..., None] * np.array(r["rim"], np.float32)

    # vignette
    v = np.sqrt((xn - 0.5) ** 2 + (yn - 0.5) ** 2)
    img *= (1 - palette["vignette"] * smoothstep(0.35, 0.85, v))[..., None]
    # film grain keeps gradients from banding
    img += rng.normal(0, grain, img.shape[:2]).astype(np.float32)[..., None]
    return Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8), "RGB")


DUSK = dict(
    palette=dict(bg_a=(0.030, 0.028, 0.075), bg_b=(0.075, 0.060, 0.150),
                 bloom=(0.20, 0.14, 0.34), bloom_pos=(0.78, 0.30), vignette=0.55),
    ribbons=[
        dict(curve=(0.30, 0.10, 0.55, 0.4, 0.45, 0.03, 1.3), width=0.16, breath=0.8,
             dark=(0.07, 0.06, 0.16), light=(0.26, 0.22, 0.46), rim=(0.62, 0.58, 1.00),
             alpha=0.92, rim_strength=0.75, glow_strength=0.10),
        dict(curve=(0.62, 0.12, 0.45, 2.3, 0.35, 0.025, 1.1), width=0.20, breath=0.6,
             dark=(0.05, 0.05, 0.12), light=(0.30, 0.25, 0.52), rim=(0.70, 0.64, 1.00),
             alpha=0.94, rim_strength=0.85, glow_strength=0.12),
        dict(curve=(0.95, 0.08, 0.35, 4.0, 0.25, 0.02, 0.9), width=0.18, breath=0.5,
             dark=(0.04, 0.04, 0.10), light=(0.22, 0.19, 0.40), rim=(0.55, 0.52, 0.95),
             alpha=0.95, rim_strength=0.55, glow_strength=0.08),
    ],
    seed=7,
)

DAWN = dict(
    palette=dict(bg_a=(0.93, 0.90, 0.97), bg_b=(0.80, 0.78, 0.94),
                 bloom=(0.10, 0.06, 0.00), bloom_pos=(0.25, 0.25), vignette=0.12),
    ribbons=[
        dict(curve=(0.30, 0.10, 0.55, 0.4, 0.45, 0.03, 1.3), width=0.16, breath=0.8,
             dark=(0.66, 0.62, 0.88), light=(0.96, 0.93, 1.00), rim=(1.0, 1.0, 1.0),
             alpha=0.80, rim_strength=0.35, glow_strength=0.05),
        dict(curve=(0.62, 0.12, 0.45, 2.3, 0.35, 0.025, 1.1), width=0.20, breath=0.6,
             dark=(0.58, 0.54, 0.84), light=(0.93, 0.90, 1.00), rim=(1.0, 1.0, 1.0),
             alpha=0.85, rim_strength=0.40, glow_strength=0.05),
        dict(curve=(0.95, 0.08, 0.35, 4.0, 0.25, 0.02, 0.9), width=0.18, breath=0.5,
             dark=(0.52, 0.48, 0.80), light=(0.86, 0.83, 0.98), rim=(1.0, 1.0, 1.0),
             alpha=0.88, rim_strength=0.30, glow_strength=0.04),
    ],
    seed=11,
)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "system_files/shared/usr/share/backgrounds/bayzite"
    os.makedirs(out, exist_ok=True)
    dusk = render(DUSK["palette"], DUSK["ribbons"], DUSK["seed"])
    dusk.save(os.path.join(out, "bayzite-dusk.jpg"), quality=92, optimize=True)
    dawn = render(DAWN["palette"], DAWN["ribbons"], DAWN["seed"], grain=0.008)
    dawn.save(os.path.join(out, "bayzite-dawn.jpg"), quality=92, optimize=True)
    # login-screen background: blurred and darkened
    blur = dusk.resize((1920, 1080), Image.LANCZOS).filter(ImageFilter.GaussianBlur(40))
    blur = Image.eval(blur, lambda p: int(p * 0.6))
    blur.save(os.path.join(out, "bayzite-dusk-blur.png"), optimize=True)
    for f in sorted(os.listdir(out)):
        print(os.path.join(out, f), os.path.getsize(os.path.join(out, f)) // 1024, "KiB")


if __name__ == "__main__":
    main()
