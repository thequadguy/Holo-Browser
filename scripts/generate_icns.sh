#!/usr/bin/env bash

# Holo Browser Professional AppIcon Generator Script
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ICONSET_DIR="$ROOT_DIR/Resources/AppIcon.iconset"
ICNS_FILE="$ROOT_DIR/Resources/AppIcon.icns"
SOURCE_IMAGE="$ROOT_DIR/Resources/AppIcon.png"

mkdir -p "$ICONSET_DIR"

if [ -f "$SOURCE_IMAGE" ]; then
    echo "🎨 Found custom AppIcon.png! Generating .icns using sips..."
    sips -z 16 16     "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null
    sips -z 32 32     "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null
    sips -z 32 32     "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null
    sips -z 64 64     "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null
    sips -z 64 64     "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_64x64.png" > /dev/null
    sips -z 128 128   "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_64x64@2x.png" > /dev/null
    sips -z 128 128   "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null
    sips -z 256 256   "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null
    sips -z 256 256   "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null
    sips -z 512 512   "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null
    sips -z 512 512   "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null
    sips -z 1024 1024 "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null
else
    echo "⚠️ AppIcon.png not found. Falling back to Python generator..."
    python3 -c "
import math
from PIL import Image, ImageDraw

def draw_holo_icon(size):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    margin = size * 0.1
    
    # Outer rounded square with deep purple to neon blue gradient aesthetic
    # Draw dark background rounded rect
    corner_radius = size * 0.22
    draw.rounded_rectangle([margin, margin, size - margin, size - margin], radius=corner_radius, fill=(15, 23, 42, 255))
    
    # Draw cyan/purple glass ring
    center = size / 2
    r_outer = size * 0.32
    r_inner = size * 0.22
    
    draw.ellipse([center - r_outer, center - r_outer, center + r_outer, center + r_outer], outline=(99, 102, 241, 255), width=int(size*0.04))
    draw.ellipse([center - r_inner, center - r_inner, center + r_inner, center + r_inner], outline=(56, 189, 248, 255), width=int(size*0.03))
    
    # Sparkle / Star in center
    s = size * 0.12
    draw.polygon([
        (center, center - s),
        (center + s*0.3, center - s*0.3),
        (center + s, center),
        (center + s*0.3, center + s*0.3),
        (center, center + s),
        (center - s*0.3, center + s*0.3),
        (center - s, center),
        (center - s*0.3, center - s*0.3)
    ], fill=(244, 244, 245, 255))
    
    return img

sizes = [16, 32, 64, 128, 256, 512, 1024]
for s in sizes:
    img = draw_holo_icon(s)
    if s <= 512:
        img.save(f'$ICONSET_DIR/icon_{s}x{s}.png')
    if s >= 32:
        half = s // 2
        img.save(f'$ICONSET_DIR/icon_{half}x{half}@2x.png')
"
fi

iconutil -c icns "$ICONSET_DIR" -o "$ICNS_FILE"
echo "✓ AppIcon.icns generated at $ICNS_FILE"
