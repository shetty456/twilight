"""Export launcher icons from StoryArtwork's moon-and-stars fallback design.

Run from apps/deeksha with: python3 tool/generate_app_icon.py
Requires Pillow and NumPy. Glyph code points and colors mirror story_artwork.dart.
"""

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
FLUTTER_VERSION = json.loads((ROOT.parents[1] / ".fvmrc").read_text())["flutter"]
FONT = (
    Path.home()
    / "fvm"
    / "versions"
    / FLUTTER_VERSION
    / "bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf"
)
BACKGROUND = ((0x50, 0x34, 0x4E), (0x25, 0x1C, 0x38), (0x12, 0x1C, 0x32))
APRICOT = (0xF0, 0xBD, 0x9D)
SYMBOLS = (
    (0xE42F, 80, 80, 78, 255),  # nightlight_round
    (0xE0B7, 120, 32, 24, 0x88),  # auto_awesome
    (0xF01D4, 36, 116, 16, 0x77),  # star_rounded
)


def gradient(size):
    coords = np.arange(size, dtype=np.float32)
    t = (coords[:, None] + coords[None, :]) / (2 * (size - 1))
    first = np.array(BACKGROUND[0], dtype=np.float32)
    middle = np.array(BACKGROUND[1], dtype=np.float32)
    last = np.array(BACKGROUND[2], dtype=np.float32)
    rgb = np.where(
        (t <= 0.5)[..., None],
        first + (middle - first) * np.minimum(t * 2, 1)[..., None],
        middle + (last - middle) * np.maximum(t * 2 - 1, 0)[..., None],
    )
    return Image.fromarray(np.rint(rgb).astype(np.uint8), "RGB")


def draw_symbols(size, content_width=None, monochrome=False):
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    width = content_width or size
    scale = width / 160
    origin = (size - width) / 2
    for code, x, y, glyph_size, alpha in SYMBOLS:
        font = ImageFont.truetype(str(FONT), round(glyph_size * scale))
        mask = Image.new("L", (size, size), 0)
        painter = ImageDraw.Draw(mask)
        character = chr(code)
        bounds = painter.textbbox((0, 0), character, font=font)
        center_x = origin + x * scale
        center_y = origin + y * scale
        left = center_x - (bounds[0] + bounds[2]) / 2
        top = center_y - (bounds[1] + bounds[3]) / 2
        painter.text((round(left), round(top)), character, font=font, fill=255)
        if not monochrome:
            mask = mask.point(lambda value: round(value * alpha / 255))
        ink = (255, 255, 255, 255) if monochrome else (*APRICOT, 255)
        layer = Image.new("RGBA", (size, size), ink)
        layer.putalpha(mask)
        image = Image.alpha_composite(image, layer)
    return image


def icon(size, content_width=None):
    return Image.alpha_composite(
        gradient(size).convert("RGBA"), draw_symbols(size, content_width)
    ).convert("RGB")


def save_resized(image, path, size):
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize((size, size), Image.Resampling.LANCZOS).save(path)


def main():
    if not FONT.exists():
        raise FileNotFoundError(f"Flutter Material Icons font missing: {FONT}")

    master = icon(1024)
    master_path = ROOT / "assets/branding/deeksha-app-icon-master.png"
    master_path.parent.mkdir(parents=True, exist_ok=True)
    master.save(master_path)

    ios = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((ios / "Contents.json").read_text())
    for item in contents["images"]:
        points = float(item["size"].split("x")[0])
        pixels = round(points * int(item["scale"][0]))
        save_resized(master, ios / item["filename"], pixels)

    android = ROOT / "android/app/src/main/res"
    for density, size in {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }.items():
        save_resized(master, android / f"mipmap-{density}/ic_launcher.png", size)
        foreground_size = round(size * 108 / 48)
        foreground = draw_symbols(432, content_width=340)
        monochrome = draw_symbols(432, content_width=340, monochrome=True)
        save_resized(
            foreground,
            android / f"mipmap-{density}/ic_launcher_foreground.png",
            foreground_size,
        )
        save_resized(
            monochrome,
            android / f"mipmap-{density}/ic_launcher_monochrome.png",
            foreground_size,
        )

    web = ROOT / "web"
    for size in (192, 512):
        save_resized(master, web / f"icons/Icon-{size}.png", size)
        maskable = icon(1024, content_width=870)
        save_resized(maskable, web / f"icons/Icon-maskable-{size}.png", size)
    save_resized(master, web / "favicon.png", 32)


if __name__ == "__main__":
    main()
