"""Draws the app icon (two stacked cards on teal) and writes every size.

Run from the repo root: python tool/generate_icons.py   (needs Pillow)
Writes the iOS AppIcon set and the Android launcher icons. Edit the constants
below to change the design, then run it again.
"""
import json
import os
from PIL import Image, ImageDraw

BG = (15, 110, 86)          # teal
CARD_BACK = (93, 202, 165)
CARD_FRONT = (255, 255, 255)
LINE_DARK = (15, 110, 86)
LINE_LIGHT = (159, 225, 203)
SS = 4                      # supersampling for smooth edges
U = 160.0                   # the design is laid out on a 160-unit square


def rounded_card(canvas, rect, radius, angle, fill, size, centre=(80, 82)):
    """Draw a rounded rect, rotated about centre, onto canvas (RGBA)."""
    s = size / U
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    x, y, w, h = rect
    ImageDraw.Draw(layer).rounded_rectangle(
        [x * s, y * s, (x + w) * s, (y + h) * s], radius * s, fill=fill)
    layer = layer.rotate(-angle, center=(centre[0] * s, centre[1] * s),
                         resample=Image.BICUBIC)
    canvas.alpha_composite(layer)


def art(size, background):
    """The artwork at size x size. background: RGB tuple, 'rounded', or None."""
    big = size * SS
    c = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    s = big / U
    d = ImageDraw.Draw(c)
    if background == "rounded":
        d.rounded_rectangle([0, 0, big - 1, big - 1], 36 * s, fill=BG)
    elif background is not None:
        d.rectangle([0, 0, big, big], fill=background)
    rounded_card(c, (26, 46, 108, 74), 12, -9, CARD_BACK, big)
    # Front card and its text lines share one rotation.
    front = Image.new("RGBA", c.size, (0, 0, 0, 0))
    fd = ImageDraw.Draw(front)
    fd.rounded_rectangle([26 * s, 40 * s, 134 * s, 114 * s], 12 * s, fill=CARD_FRONT)
    for (x, y, w, col) in [(44, 58, 56, LINE_DARK), (44, 76, 72, LINE_LIGHT),
                           (44, 92, 44, LINE_LIGHT)]:
        fd.rounded_rectangle([x * s, y * s, (x + w) * s, (y + 8) * s], 4 * s, fill=col)
    front = front.rotate(-5, center=(80 * s, 82 * s), resample=Image.BICUBIC)
    c.alpha_composite(front)
    return c.resize((size, size), Image.LANCZOS)


def save(img, path, flatten=False):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if flatten:  # App Store icons must have no alpha channel
        img = img.convert("RGB")
    img.save(path, optimize=True)


# iOS: full-bleed square, no alpha; iOS applies its own corner mask.
ios_dir = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
contents = json.load(open(f"{ios_dir}/Contents.json"))
done = set()
for entry in contents["images"]:
    name = entry.get("filename")
    if not name or name in done:
        continue
    base = float(entry["size"].split("x")[0])
    scale = int(entry["scale"].rstrip("x"))
    px = round(base * scale)
    save(art(px, BG), f"{ios_dir}/{name}", flatten=True)
    done.add(name)

# Android legacy launcher icons (pre-API 26): rounded square on transparent.
res = "android/app/src/main/res"
for folder, px in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96),
                   ("xxhdpi", 144), ("xxxhdpi", 192)]:
    save(art(px, "rounded"), f"{res}/mipmap-{folder}/ic_launcher.png")

# Android adaptive icon (API 26+): foreground on transparent, background colour.
# The launcher masks to ~66% of the 108dp canvas; the artwork sits well inside.
for folder, px in [("mdpi", 108), ("hdpi", 162), ("xhdpi", 216),
                   ("xxhdpi", 324), ("xxxhdpi", 432)]:
    # Shrunk to 80% so the card corners stay inside the launcher's mask.
    inner = round(px * 0.8)
    fg = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    fg.alpha_composite(art(inner, None), ((px - inner) // 2, (px - inner) // 2))
    save(fg, f"{res}/mipmap-{folder}/ic_launcher_foreground.png")

os.makedirs(f"{res}/mipmap-anydpi-v26", exist_ok=True)
open(f"{res}/mipmap-anydpi-v26/ic_launcher.xml", "w", newline="\n").write(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
    '    <background android:drawable="@color/ic_launcher_background"/>\n'
    '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
    '</adaptive-icon>\n')
open(f"{res}/values/ic_launcher_background.xml", "w", newline="\n").write(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<resources>\n'
    '    <color name="ic_launcher_background">#0F6E56</color>\n'
    '</resources>\n')

# Preview sheet for eyeballing the result (not committed).
os.makedirs("build", exist_ok=True)
sheet = Image.new("RGBA", (1100, 560), (235, 235, 235, 255))
sheet.alpha_composite(art(512, BG), (20, 20))
sheet.alpha_composite(art(256, "rounded"), (560, 20))
sheet.alpha_composite(art(120, "rounded"), (840, 20))
sheet.alpha_composite(art(60, "rounded"), (980, 20))
fg = Image.new('RGBA', (256, 256), (0, 0, 0, 0))
fg.alpha_composite(art(205, None), (25, 25))
adaptive = Image.new("RGBA", (256, 256), BG + (255,))
adaptive.alpha_composite(fg)
mask = Image.new("L", (256, 256), 0)
ImageDraw.Draw(mask).ellipse([0, 0, 255, 255], fill=255)
circ = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
circ.paste(adaptive, (0, 0), mask)
sheet.alpha_composite(circ, (560, 290))
sheet.convert("RGB").save("build/icon_preview.png")
print("done")
