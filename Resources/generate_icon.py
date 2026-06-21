#!/usr/bin/env python3
"""Generate minimal monochrome MacJournal icon: outlined circle with notebook.
Outputs 1024x1024 PNG, then creates .icns."""

from PIL import Image, ImageDraw
import os, subprocess, shutil

SIZE = 1024
RESOURCES = os.path.dirname(os.path.abspath(__file__))
OUTPUT_PNG = os.path.join(RESOURCES, "MacJournal_Icon.png")
OUTPUT_ICNS = os.path.join(RESOURCES, "MacJournal_Icon.icns")
ICONSET_DIR = os.path.join(RESOURCES, "MacJournal_Icon.iconset")

# Monochrome color
FG = (255, 255, 255, 255)  # white (tinted by app)

# Create transparent base
img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

cx, cy = SIZE / 2, SIZE / 2
R = int(SIZE * 0.44)  # circle radius
stroke = int(SIZE * 0.045)  # line weight

# ── Circle outline ──
draw.ellipse(
    [cx - R, cy - R, cx + R, cy + R],
    outline=FG,
    width=stroke,
)

# ── Notebook inside circle ──
# Clean rectangle with a spine line and page lines
nb_w = int(R * 1.05)
nb_h = int(nb_w * 1.35)
nb_x = int(cx - nb_w / 2)
nb_y = int(cy - nb_h / 2)
nb_corner = int(nb_w * 0.08)

draw.rounded_rectangle(
    [nb_x, nb_y, nb_x + nb_w, nb_y + nb_h],
    radius=nb_corner,
    outline=FG,
    width=int(stroke * 0.55),
)

# Spine line (left third)
spine_x = nb_x + int(nb_w * 0.18)
draw.line(
    [spine_x, nb_y + nb_corner, spine_x, nb_y + nb_h - nb_corner],
    fill=FG,
    width=max(int(stroke * 0.35), 2),
)

# ── Page lines ──
line_l = nb_x + int(nb_w * 0.28)
line_r = nb_x + nb_w - int(nb_w * 0.15)
ly_start = nb_y + int(nb_h * 0.22)
ly_end = nb_y + nb_h - int(nb_h * 0.18)
num_lines = 7
line_weight = max(int(stroke * 0.25), 2)

for i in range(num_lines):
    ly = int(ly_start + i * (ly_end - ly_start) / (num_lines - 1))
    lx_end = line_r if i not in (num_lines - 1,) else line_r - int(nb_w * 0.28)
    draw.line([line_l, ly, lx_end, ly], fill=FG, width=line_weight)

# Save 1024 PNG
img.save(OUTPUT_PNG, "PNG")
print(f"✓ Saved {OUTPUT_PNG} ({SIZE}x{SIZE})")

# Build .iconset + .icns
if os.path.exists(ICONSET_DIR):
    shutil.rmtree(ICONSET_DIR)
os.makedirs(ICONSET_DIR)

sizes = {
    "icon_16x16.png": 16, "icon_16x16@2x.png": 32,
    "icon_32x32.png": 32, "icon_32x32@2x.png": 64,
    "icon_128x128.png": 128, "icon_128x128@2x.png": 256,
    "icon_256x256.png": 256, "icon_256x256@2x.png": 512,
    "icon_512x512.png": 512, "icon_512x512@2x.png": 1024,
}
for name, sz in sizes.items():
    resized = img.resize((sz, sz), Image.LANCZOS)
    resized.save(os.path.join(ICONSET_DIR, name), "PNG")

subprocess.run(["iconutil", "-c", "icns", "-o", OUTPUT_ICNS, ICONSET_DIR], check=True)
shutil.rmtree(ICONSET_DIR)
print(f"✓ Saved {OUTPUT_ICNS}")
print("Done!")
