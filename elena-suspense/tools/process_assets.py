#!/usr/bin/env python3
"""
Asset Processing Pipeline for Ren'Py 8 Ecchi/Suspense Visual Novel.
Automates:
1. Background removal using rembg (for sprites)
2. High-quality 1080p (1920x1080) resizing and intelligent cropping
3. WebP compression (85% quality) to optimize for Ren'Py Web (<25MB limit) & Standalone distributions
4. Thumbnail generation for persistent CG Gallery
"""

import os
import sys
import argparse
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance, ImageFont

# Try importing rembg; fallback gracefully if offline/not ready
try:
    from rembg import remove as rembg_remove
    REMBG_AVAILABLE = True
except ImportError:
    REMBG_AVAILABLE = False


def process_sprites(
    raw_dir: Path,
    out_dir: Path,
    target_height: int = 1080,
    quality: int = 85,
    remove_bg: bool = False
) -> None:
    """
    Process character sprite images:
    - Optional rembg background stripping
    - Proportional scaling to target height (standard Ren'Py 1080p canvas)
    - Export as optimized WebP
    """
    raw_dir = Path(raw_dir)
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    supported_exts = {".png", ".jpg", ".jpeg", ".webp", ".bmp"}
    files = [f for f in raw_dir.glob("*") if f.suffix.lower() in supported_exts]

    print(f"[Sprite Pipeline] Found {len(files)} files in {raw_dir}")

    for img_path in files:
        stem = img_path.stem
        out_path = out_dir / f"{stem}.webp"

        try:
            with Image.open(img_path) as img:
                img = img.convert("RGBA")

                # If requested and background needs stripping
                if remove_bg and REMBG_AVAILABLE:
                    print(f"  -> Stripping background with rembg: {img_path.name}")
                    img = rembg_remove(img)

                # Maintain aspect ratio and scale to target height
                w, h = img.size
                scale_ratio = target_height / float(h)
                new_w = int(w * scale_ratio)
                new_h = int(target_height)

                resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)

                # Save as optimized WebP
                resized.save(out_path, format="WEBP", quality=quality, method=6)
                print(f"  [OK] Exported sprite -> {out_path} ({new_w}x{new_h})")

        except Exception as e:
            print(f"  [ERROR] Failed to process sprite {img_path.name}: {e}", file=sys.stderr)


def process_backgrounds_and_cgs(
    raw_bg_dir: Path,
    out_bg_dir: Path,
    raw_cg_dir: Path,
    out_cg_dir: Path,
    target_size: tuple = (1920, 1080),
    quality: int = 85
) -> None:
    """
    Process Backgrounds and Event CGs:
    - Resize/crop to exact 1920x1080 (16:9)
    - WebP compression (85% quality)
    - Generate 480x270 thumbnails for CG Gallery
    """
    target_w, target_h = target_size
    target_ratio = target_w / float(target_h)

    def _process_item(img_path: Path, output_file: Path, is_cg: bool = False):
        try:
            with Image.open(img_path) as img:
                img = img.convert("RGB")
                w, h = img.size
                current_ratio = w / float(h)

                # Intelligent center crop to 16:9 if aspect ratio differs
                if abs(current_ratio - target_ratio) > 0.01:
                    if current_ratio > target_ratio:
                        # Wider than 16:9 -> crop horizontal sides
                        crop_w = int(h * target_ratio)
                        left = (w - crop_w) // 2
                        box = (left, 0, left + crop_w, h)
                    else:
                        # Taller than 16:9 -> crop top/bottom
                        crop_h = int(w / target_ratio)
                        top = (h - crop_h) // 2
                        box = (0, top, w, top + crop_h)
                    img = img.crop(box)

                # Resize to target canvas size
                final_img = img.resize((target_w, target_h), Image.Resampling.LANCZOS)
                final_img.save(output_file, format="WEBP", quality=quality, method=6)
                print(f"  [OK] Exported -> {output_file} ({target_w}x{target_h})")

                # Generate thumbnail if it's an event CG
                if is_cg:
                    thumb_path = output_file.parent / f"{output_file.stem}_thumb.webp"
                    thumb_w, thumb_h = 480, 270
                    thumb_img = final_img.resize((thumb_w, thumb_h), Image.Resampling.LANCZOS)
                    thumb_img.save(thumb_path, format="WEBP", quality=quality, method=6)
                    print(f"  [OK] Generated Gallery Thumb -> {thumb_path}")

        except Exception as e:
            print(f"  [ERROR] Failed to process {img_path.name}: {e}", file=sys.stderr)

    # Process BGs
    raw_bg_dir = Path(raw_bg_dir)
    out_bg_dir = Path(out_bg_dir)
    out_bg_dir.mkdir(parents=True, exist_ok=True)
    bg_files = [f for f in raw_bg_dir.glob("*") if f.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"}]
    print(f"[BG Pipeline] Found {len(bg_files)} files in {raw_bg_dir}")
    for f in bg_files:
        _process_item(f, out_bg_dir / f"{f.stem}.webp", is_cg=False)

    # Process CGs
    raw_cg_dir = Path(raw_cg_dir)
    out_cg_dir = Path(out_cg_dir)
    out_cg_dir.mkdir(parents=True, exist_ok=True)
    cg_files = [f for f in raw_cg_dir.glob("*") if f.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"}]
    print(f"[CG Pipeline] Found {len(cg_files)} files in {raw_cg_dir}")
    for f in cg_files:
        _process_item(f, out_cg_dir / f"{f.stem}.webp", is_cg=True)


def generate_baseline_raw_assets(base_dir: Path) -> None:
    """
    Generates high-aesthetic Dark Academia / Suspense baseline test assets:
    - Elena Sprites (neutral, flustered, submission) with transparent alpha
    - Backgrounds (study_normal, study_dark)
    - Event CGs (cg_confrontation, cg_climax, cg_aftermath)
    """
    raw_sprites_dir = base_dir / "raw_assets" / "sprites"
    raw_bg_dir = base_dir / "raw_assets" / "bg"
    raw_cgs_dir = base_dir / "raw_assets" / "cgs"

    for d in (raw_sprites_dir, raw_bg_dir, raw_cgs_dir):
        d.mkdir(parents=True, exist_ok=True)

    print("[Generator] Creating stylized Dark Academia raw baseline assets...")

    # 1. Backgrounds Generator
    def create_study_bg(dark: bool = False):
        w, h = 1920, 1080
        img = Image.new("RGB", (w, h), (18, 14, 20) if dark else (36, 26, 32))
        draw = ImageDraw.Draw(img)

        # Gradient wall & floor
        for y in range(h):
            factor = y / h
            if not dark:
                r = int(35 + factor * 25)
                g = int(24 + factor * 18)
                b = int(28 + factor * 16)
            else:
                r = int(12 + factor * 14)
                g = int(10 + factor * 12)
                b = int(20 + factor * 18)
            draw.line([(0, y), (w, y)], fill=(r, g, b))

        # Victorian Bookshelves & Arch in background
        wood_color = (20, 12, 10) if dark else (45, 28, 20)
        draw.rectangle([60, 80, 520, 850], fill=wood_color, outline=(70, 45, 30), width=4)
        draw.rectangle([1400, 80, 1860, 850], fill=wood_color, outline=(70, 45, 30), width=4)

        # Books
        book_colors = [(80, 30, 30), (30, 60, 50), (100, 75, 40), (50, 40, 70), (70, 60, 30)]
        for shelf_y in range(160, 820, 130):
            draw.line([(60, shelf_y), (520, shelf_y)], fill=(70, 45, 30), width=6)
            draw.line([(1400, shelf_y), (1860, shelf_y)], fill=(70, 45, 30), width=6)
            # draw books
            bx = 75
            while bx < 500:
                bw = 18 + (bx % 17)
                bh = 90 + (bx % 25)
                c = book_colors[(bx + shelf_y) % len(book_colors)]
                if dark:
                    c = (c[0] // 2, c[1] // 2, c[2] // 2)
                draw.rectangle([bx, shelf_y - bh, bx + bw - 3, shelf_y], fill=c)
                bx += bw

        # Tall arched window with moonlight / rain
        win_x1, win_y1, win_x2, win_y2 = 700, 60, 1220, 750
        win_tint = (20, 35, 60) if dark else (50, 60, 80)
        draw.rounded_rectangle([win_x1, win_y1, win_x2, win_y2], radius=120, fill=win_tint, outline=(80, 70, 60), width=6)
        # Window bars
        draw.line([(960, win_y1), (960, win_y2)], fill=(60, 50, 45), width=4)
        draw.line([(win_x1, 350), (win_x2, 350)], fill=(60, 50, 45), width=4)
        draw.line([(win_x1, 550), (win_x2, 550)], fill=(60, 50, 45), width=4)

        # Mahogany Desk in foreground
        desk_y = 780
        desk_color = (28, 16, 12) if dark else (58, 32, 22)
        draw.polygon([(200, 1080), (450, desk_y), (1470, desk_y), (1720, 1080)], fill=desk_color)
        draw.line([(450, desk_y), (1470, desk_y)], fill=(90, 55, 35), width=5)

        # Ambient lamp glow
        glow_layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        glow_draw = ImageDraw.Draw(glow_layer)
        lamp_pos = (580, 720) if not dark else (580, 730)
        glow_color = (255, 190, 80, 70) if not dark else (160, 180, 240, 40)
        glow_radius = 350 if not dark else 200
        glow_draw.ellipse(
            [lamp_pos[0] - glow_radius, lamp_pos[1] - glow_radius, lamp_pos[0] + glow_radius, lamp_pos[1] + glow_radius],
            fill=glow_color
        )
        glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(80))
        img = Image.alpha_composite(img.convert("RGBA"), glow_layer).convert("RGB")

        # Subtle vignette overlay
        vignette = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        vdraw = ImageDraw.Draw(vignette)
        vdraw.rectangle([0, 0, w, h], fill=(0, 0, 0, 80 if not dark else 140))
        vdraw.ellipse([300, 100, 1620, 980], fill=(0, 0, 0, 0))
        vignette = vignette.filter(ImageFilter.GaussianBlur(120))
        img = Image.alpha_composite(img.convert("RGBA"), vignette).convert("RGB")

        return img

    study_normal = create_study_bg(dark=False)
    study_dark = create_study_bg(dark=True)
    study_normal.save(raw_bg_dir / "study_normal.png")
    study_dark.save(raw_bg_dir / "study_dark.png")

    # 2. Character Sprites Generator (Elena: 22, Dark Academia Scholar / Assistant)
    # Neutral, Flustered, Submission
    def create_elena_sprite(expression: str = "neutral"):
        w, h = 800, 1080
        img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)

        center_x = 400

        # Hair back
        hair_color = (42, 28, 36, 255) # Dark auburn/burgundy tinted black
        draw.ellipse([center_x - 140, 160, center_x + 140, 700], fill=hair_color)

        # Body / Shoulders & Dark Academia Outfit
        # Neck & skin
        skin_color = (255, 230, 218, 255)
        blush_color = (255, 160, 175, 120)
        draw.rectangle([center_x - 30, 310, center_x + 30, 420], fill=skin_color)

        # Exposed collarbone / chest depending on expression
        chest_depth = 460 if expression == "neutral" else (510 if expression == "flustered" else 560)
        draw.polygon([(center_x - 45, 380), (center_x + 45, 380), (center_x, chest_depth)], fill=skin_color)

        # Blouse & Victorian Knit Vest / Blazer
        blouse_white = (240, 238, 245, 255)
        blazer_dark = (32, 26, 42, 255)
        skirt_charcoal = (24, 20, 30, 255)

        # Torso outline
        draw.polygon([(center_x - 130, 410), (center_x + 130, 410), (center_x + 110, 850), (center_x - 110, 850)], fill=blouse_white)

        if expression == "neutral":
            # Neat Dark Academia blazer & tie
            draw.polygon([(center_x - 145, 410), (center_x - 60, 420), (center_x - 75, 840), (center_x - 150, 850)], fill=blazer_dark)
            draw.polygon([(center_x + 145, 410), (center_x + 60, 420), (center_x + 75, 840), (center_x + 150, 850)], fill=blazer_dark)
            # Silk tie
            draw.polygon([(center_x - 15, 420), (center_x + 15, 420), (center_x + 20, 680), (center_x, 720), (center_x - 20, 680)], fill=(120, 28, 45, 255))
        elif expression == "flustered":
            # Loosened tie, unbuttoned blazer, flushed skin
            draw.polygon([(center_x - 155, 410), (center_x - 80, 430), (center_x - 100, 840), (center_x - 160, 850)], fill=blazer_dark)
            draw.polygon([(center_x + 155, 410), (center_x + 80, 430), (center_x + 100, 840), (center_x + 160, 850)], fill=blazer_dark)
            # Crooked loosened tie
            draw.polygon([(center_x - 20, 470), (center_x + 10, 460), (center_x + 35, 690), (center_x + 15, 730), (center_x - 5, 690)], fill=(120, 28, 45, 255))
        else: # submission
            # Blazer slipping off shoulders, unbuttoned blouse, exposed delicate ecchi silhouette
            draw.polygon([(center_x - 170, 460), (center_x - 95, 520), (center_x - 110, 870), (center_x - 175, 880)], fill=blazer_dark)
            draw.polygon([(center_x + 170, 460), (center_x + 95, 520), (center_x + 110, 870), (center_x + 175, 880)], fill=blazer_dark)
            # Camisole lace & skin reveal
            draw.polygon([(center_x - 40, 510), (center_x + 40, 510), (center_x, 570)], fill=(20, 20, 30, 220))

        # Skirt
        draw.polygon([(center_x - 110, 850), (center_x + 110, 850), (center_x + 130, 1080), (center_x - 130, 1080)], fill=skirt_charcoal)

        # Head & Face
        head_w, head_h = 100, 125
        head_top = 190
        draw.ellipse([center_x - head_w, head_top, center_x + head_w, head_top + head_h * 2], fill=skin_color)

        # Hair front / Bangs
        draw.polygon([
            (center_x - 110, head_top + 30),
            (center_x - 40, head_top + 130),
            (center_x - 10, head_top + 90),
            (center_x + 30, head_top + 140),
            (center_x + 90, head_top + 80),
            (center_x + 115, head_top + 30),
            (center_x + 80, head_top - 20),
            (center_x - 80, head_top - 20)
        ], fill=hair_color)

        # Eyes & Expressions
        eye_y = head_top + 120
        eye_color = (60, 110, 140, 255) # Deep cyan/slate blue academic gaze

        if expression == "neutral":
            # Composed eyes + thin gold-rimmed glasses
            draw.ellipse([center_x - 55, eye_y, center_x - 20, eye_y + 18], fill=eye_color)
            draw.ellipse([center_x + 20, eye_y, center_x + 55, eye_y + 18], fill=eye_color)
            draw.ellipse([center_x - 45, eye_y + 3, center_x - 38, eye_y + 10], fill=(255, 255, 255, 255))
            draw.ellipse([center_x + 30, eye_y + 3, center_x + 37, eye_y + 10], fill=(255, 255, 255, 255))
            # Eyebrows
            draw.line([(center_x - 60, eye_y - 12), (center_x - 20, eye_y - 10)], fill=(40, 25, 30), width=3)
            draw.line([(center_x + 20, eye_y - 10), (center_x + 60, eye_y - 12)], fill=(40, 25, 30), width=3)
            # Gentle slight curve mouth
            draw.line([(center_x - 15, head_top + 180), (center_x + 15, head_top + 180)], fill=(180, 90, 100), width=3)

            # Elegant glasses
            draw.rectangle([center_x - 62, eye_y - 6, center_x - 14, eye_y + 24], outline=(210, 180, 110, 220), width=2)
            draw.rectangle([center_x + 14, eye_y - 6, center_x + 62, eye_y + 24], outline=(210, 180, 110, 220), width=2)
            draw.line([(center_x - 14, eye_y + 8), (center_x + 14, eye_y + 8)], fill=(210, 180, 110, 220), width=2)

        elif expression == "flustered":
            # Widened flustered eyes, trembling gaze
            draw.ellipse([center_x - 58, eye_y - 4, center_x - 18, eye_y + 22], fill=eye_color)
            draw.ellipse([center_x + 18, eye_y - 4, center_x + 58, eye_y + 22], fill=eye_color)
            draw.ellipse([center_x - 48, eye_y, center_x - 40, eye_y + 8], fill=(255, 255, 255, 255))
            draw.ellipse([center_x + 28, eye_y, center_x + 36, eye_y + 8], fill=(255, 255, 255, 255))
            # Troubled arched eyebrows
            draw.line([(center_x - 60, eye_y - 8), (center_x - 20, eye_y - 16)], fill=(40, 25, 30), width=3)
            draw.line([(center_x + 20, eye_y - 16), (center_x + 60, eye_y - 8)], fill=(40, 25, 30), width=3)
            # Parted trembling mouth
            draw.ellipse([center_x - 12, head_top + 175, center_x + 12, head_top + 190], fill=(160, 70, 85))

            # Heavy cheek & chest blush
            blush = Image.new("RGBA", (w, h), (0, 0, 0, 0))
            bdraw = ImageDraw.Draw(blush)
            bdraw.ellipse([center_x - 70, eye_y + 15, center_x - 20, eye_y + 45], fill=(255, 110, 140, 140))
            bdraw.ellipse([center_x + 20, eye_y + 15, center_x + 70, eye_y + 45], fill=(255, 110, 140, 140))
            bdraw.ellipse([center_x - 40, 420, center_x + 40, 480], fill=(255, 120, 140, 90))
            blush = blush.filter(ImageFilter.GaussianBlur(14))
            img = Image.alpha_composite(img, blush)

            # Tilting glasses
            draw = ImageDraw.Draw(img)
            draw.rectangle([center_x - 62, eye_y - 2, center_x - 14, eye_y + 28], outline=(210, 180, 110, 220), width=2)
            draw.rectangle([center_x + 14, eye_y - 8, center_x + 62, eye_y + 22], outline=(210, 180, 110, 220), width=2)
            draw.line([(center_x - 14, eye_y + 10), (center_x + 14, eye_y + 6)], fill=(210, 180, 110, 220), width=2)

        else: # submission
            # Half-lidded surrender eyes, moist eyelashes, breathless
            draw.ellipse([center_x - 56, eye_y + 2, center_x - 18, eye_y + 18], fill=eye_color)
            draw.ellipse([center_x + 18, eye_y + 2, center_x + 56, eye_y + 18], fill=eye_color)
            # Eyelids lowered
            draw.ellipse([center_x - 58, eye_y - 4, center_x - 16, eye_y + 10], fill=skin_color)
            draw.ellipse([center_x + 16, eye_y - 4, center_x + 58, eye_y + 10], fill=skin_color)
            # Moisture highlight
            draw.ellipse([center_x - 44, eye_y + 8, center_x - 38, eye_y + 14], fill=(255, 255, 255, 255))
            draw.ellipse([center_x + 30, eye_y + 8, center_x + 36, eye_y + 14], fill=(255, 255, 255, 255))
            # Soft parted lips / gasp
            draw.ellipse([center_x - 14, head_top + 176, center_x + 14, head_top + 195], fill=(190, 75, 95))
            draw.ellipse([center_x - 8, head_top + 180, center_x + 8, head_top + 190], fill=(230, 110, 130))

            # Deep ecstatic blush
            blush = Image.new("RGBA", (w, h), (0, 0, 0, 0))
            bdraw = ImageDraw.Draw(blush)
            bdraw.ellipse([center_x - 80, eye_y + 10, center_x + 80, eye_y + 55], fill=(255, 90, 130, 160))
            bdraw.ellipse([center_x - 60, 390, center_x + 60, 520], fill=(255, 100, 140, 120))
            blush = blush.filter(ImageFilter.GaussianBlur(16))
            img = Image.alpha_composite(img, blush)

        return img

    elena_neutral = create_elena_sprite("neutral")
    elena_flustered = create_elena_sprite("flustered")
    elena_submission = create_elena_sprite("submission")

    elena_neutral.save(raw_sprites_dir / "elena_neutral.png")
    elena_flustered.save(raw_sprites_dir / "elena_flustered.png")
    elena_submission.save(raw_sprites_dir / "elena_submission.png")

    # 3. Event CGs Generator (1920x1080)
    # CG 1: Confrontation (Elena backed against archive bookshelf, documents in hand)
    # CG 2: Climax (Intimate surrender on mahogany study desk, moonlight & warmth)
    # CG 3: Aftermath (Quiet dawn intimacy, secret pact, shared warmth)
    def create_cg(cg_type: str):
        w, h = 1920, 1080
        img = Image.new("RGB", (w, h), (15, 12, 18))
        draw = ImageDraw.Draw(img)

        if cg_type == "confrontation":
            # Dynamic angled bookshelf background
            for y in range(h):
                t = y / h
                draw.line([(0, y), (w, y)], fill=(int(20 + t * 25), int(14 + t * 18), int(22 + t * 24)))
            draw.polygon([(100, 0), (600, 0), (500, 1080), (0, 1080)], fill=(30, 18, 14))
            draw.polygon([(1350, 0), (1920, 0), (1920, 1080), (1200, 1080)], fill=(24, 15, 12))

            # Dramatic shadow of protagonist looming
            draw.polygon([(0, 300), (450, 600), (250, 1080), (0, 1080)], fill=(10, 8, 12))

            # Elena cornered center-right
            cx, cy = 1050, 560
            # Elena silhouette / close-up
            draw.ellipse([cx - 220, cy - 380, cx + 220, cy + 420], fill=(255, 230, 220)) # skin
            draw.ellipse([cx - 260, cy - 420, cx + 260, cy - 80], fill=(42, 28, 36)) # hair
            # Disheveled blouse & documents pressed to chest
            draw.polygon([(cx - 160, cy - 60), (cx + 160, cy - 60), (cx + 140, cy + 420), (cx - 140, cy + 420)], fill=(240, 238, 248))
            draw.polygon([(cx - 120, cy + 40), (cx + 120, cy + 20), (cx + 140, cy + 260), (cx - 100, cy + 280)], fill=(215, 195, 160)) # Ledger
            # Gold lettering on ledger
            draw.line([(cx - 80, cy + 100), (cx + 80, cy + 90)], fill=(120, 90, 50), width=4)
            draw.line([(cx - 80, cy + 140), (cx + 60, cy + 130)], fill=(120, 90, 50), width=3)

            # Dramatic eyes & flustered tension
            draw.ellipse([cx - 70, cy - 200, cx - 15, cy - 160], fill=(60, 110, 140))
            draw.ellipse([cx + 25, cy - 200, cx + 80, cy - 160], fill=(60, 110, 140))
            draw.ellipse([cx - 50, cy - 195, cx - 35, cy - 180], fill=(255, 255, 255))
            draw.ellipse([cx + 45, cy - 195, cx + 60, cy - 180], fill=(255, 255, 255))
            # Troubled mouth
            draw.ellipse([cx - 15, cy - 90, cx + 15, cy - 70], fill=(180, 80, 95))

            # Intense blush & lighting overlay
            ov = Image.new("RGBA", (w, h), (0, 0, 0, 0))
            odraw = ImageDraw.Draw(ov)
            odraw.ellipse([cx - 100, cy - 180, cx + 100, cy - 110], fill=(255, 90, 120, 130))
            # Golden lamp beam from left
            odraw.polygon([(0, 200), (cx + 300, 300), (cx + 300, 900), (0, 800)], fill=(255, 190, 80, 45))
            ov = ov.filter(ImageFilter.GaussianBlur(40))
            img = Image.alpha_composite(img.convert("RGBA"), ov).convert("RGB")

        elif cg_type == "climax":
            # Ecchi Climax: Mahogany Desk Intimacy, Moonlight, Ecstatic Submission
            for y in range(h):
                t = y / h
                draw.line([(0, y), (w, y)], fill=(int(25 + t * 35), int(15 + t * 20), int(28 + t * 30)))

            # Desk surface angled
            draw.polygon([(0, 500), (1920, 400), (1920, 1080), (0, 1080)], fill=(40, 20, 16))

            # Elena reclining on desk
            cx, cy = 960, 620
            # Body curves
            draw.ellipse([cx - 380, cy - 260, cx + 380, cy + 280], fill=(255, 232, 222))
            draw.ellipse([cx - 420, cy - 360, cx + 120, cy], fill=(42, 28, 36)) # Hair spread on desk

            # Undone lace & delicate details
            draw.polygon([(cx - 150, cy - 120), (cx + 180, cy - 80), (cx + 120, cy + 180), (cx - 180, cy + 140)], fill=(245, 240, 250, 200))
            draw.line([(cx - 160, cy - 60), (cx + 170, cy - 30)], fill=(40, 35, 45), width=4)

            # Breathless ecstatic face
            fx, fy = cx + 80, cy - 160
            draw.ellipse([fx - 140, fy - 110, fx + 140, fy + 130], fill=(255, 232, 222))
            # Half-closed moist eyes
            draw.ellipse([fx - 55, fy - 30, fx - 10, fy], fill=(60, 110, 140))
            draw.ellipse([fx + 15, fy - 30, fx + 60, fy], fill=(60, 110, 140))
            draw.ellipse([fx - 40, fy - 22, fx - 25, fy - 10], fill=(255, 255, 255))
            draw.ellipse([fx + 30, fy - 22, fx + 45, fy - 10], fill=(255, 255, 255))
            # Open gasping lips
            draw.ellipse([fx - 18, fy + 45, fx + 18, fy + 75], fill=(210, 80, 105))
            draw.ellipse([fx - 10, fy + 52, fx + 10, fy + 68], fill=(245, 120, 140))

            # Sensual glow & moonlight filter
            ov = Image.new("RGBA", (w, h), (0, 0, 0, 0))
            odraw = ImageDraw.Draw(ov)
            odraw.ellipse([cx - 300, cy - 300, cx + 300, cy + 200], fill=(255, 120, 150, 110))
            # Moonlight beam from top right
            odraw.polygon([(1500, 0), (1920, 0), (1200, 1080), (600, 1080)], fill=(160, 200, 255, 55))
            # Warm candle shimmer from bottom left
            odraw.ellipse([100, 600, 700, 1080], fill=(255, 180, 70, 70))
            ov = ov.filter(ImageFilter.GaussianBlur(50))
            img = Image.alpha_composite(img.convert("RGBA"), ov).convert("RGB")

        else: # aftermath
            # Quiet Aftermath: Warm Dawn Glow, Shared Secrets, Lingering Intimacy
            for y in range(h):
                t = y / h
                draw.line([(0, y), (w, y)], fill=(int(40 + t * 40), int(25 + t * 25), int(35 + t * 30)))

            # Window with soft dawn amber light
            draw.rounded_rectangle([700, 80, 1220, 650], radius=80, fill=(180, 120, 90), outline=(90, 60, 50), width=6)

            # Soft study armchair & blanket
            cx, cy = 960, 640
            draw.ellipse([cx - 300, cy - 200, cx + 300, cy + 300], fill=(80, 35, 40)) # Velvet armchair
            # Elena resting peacefully, draped in oversized blazer / blanket
            draw.ellipse([cx - 160, cy - 140, cx + 160, cy + 180], fill=(255, 235, 226))
            draw.polygon([(cx - 200, cy), (cx + 200, cy), (cx + 220, cy + 360), (cx - 220, cy + 360)], fill=(35, 28, 42))

            # Peaceful sweet closed eyes
            fx, fy = cx, cy - 80
            draw.arc([fx - 55, fy - 10, fx - 15, fy + 20], start=20, end=160, fill=(40, 25, 30), width=3)
            draw.arc([fx + 15, fy - 10, fx + 55, fy + 20], start=20, end=160, fill=(40, 25, 30), width=3)
            # Gentle contented smile
            draw.arc([fx - 16, fy + 40, fx + 16, fy + 65], start=10, end=170, fill=(190, 90, 105), width=3)

            # Soft morning haze
            ov = Image.new("RGBA", (w, h), (0, 0, 0, 0))
            odraw = ImageDraw.Draw(ov)
            odraw.rectangle([0, 0, w, h], fill=(255, 200, 140, 50))
            ov = ov.filter(ImageFilter.GaussianBlur(60))
            img = Image.alpha_composite(img.convert("RGBA"), ov).convert("RGB")

        return img

    cg_conf = create_cg("confrontation")
    cg_clim = create_cg("climax")
    cg_aft = create_cg("aftermath")

    cg_conf.save(raw_cgs_dir / "cg_confrontation.png")
    cg_clim.save(raw_cgs_dir / "cg_climax.png")
    cg_aft.save(raw_cgs_dir / "cg_aftermath.png")

    print("[Generator] Baseline raw assets generated successfully.")


def generate_baseline_audio(base_dir: Path) -> None:
    """
    Generates minimal clean audio waveform files for Ren'Py (.ogg / .wav)
    so audio channels (music, ambience, sfx) play without missing asset warnings.
    """
    import wave
    import math
    import struct

    audio_dir = base_dir / "game" / "audio"
    audio_dir.mkdir(parents=True, exist_ok=True)

    def write_tone(filepath: Path, freq: float = 440.0, duration: float = 1.0, volume: float = 0.3, wave_type: str = "sine"):
        sample_rate = 22050
        num_samples = int(sample_rate * duration)
        with wave.open(str(filepath), 'wb') as wav:
            wav.setnchannels(1) # mono
            wav.setsampwidth(2) # 16-bit
            wav.setframerate(sample_rate)
            frames = bytearray()
            for i in range(num_samples):
                t = i / sample_rate
                # Apply envelope to prevent clicking
                fade_len = int(0.05 * sample_rate)
                env = 1.0
                if i < fade_len:
                    env = i / fade_len
                elif i > num_samples - fade_len:
                    env = (num_samples - i) / fade_len

                if wave_type == "sine":
                    val = math.sin(2.0 * math.pi * freq * t)
                elif wave_type == "rain":
                    # pseudo noise
                    val = ((math.sin(t * 1234.5) + math.sin(t * 4321.0) + math.sin(t * 789.0)) / 3.0)
                elif wave_type == "heartbeat":
                    # low frequency thump
                    pulse = math.exp(-((t % 0.8) - 0.15)**2 / 0.005)
                    val = math.sin(2.0 * math.pi * 55.0 * t) * pulse
                else:
                    val = math.sin(2.0 * math.pi * freq * t)

                sample = int(val * volume * env * 32767.0)
                sample = max(-32768, min(32767, sample))
                frames.extend(struct.pack('<h', sample))
            wav.writeframes(frames)

    # Generate BGM & SFX
    write_tone(audio_dir / "rain_ambience.ogg", freq=120.0, duration=3.0, volume=0.25, wave_type="rain")
    write_tone(audio_dir / "suspense_theme.ogg", freq=110.0, duration=4.0, volume=0.3, wave_type="sine")
    write_tone(audio_dir / "ecchi_theme.ogg", freq=220.0, duration=4.0, volume=0.3, wave_type="sine")
    write_tone(audio_dir / "heartbeat.ogg", freq=55.0, duration=2.4, volume=0.4, wave_type="heartbeat")
    write_tone(audio_dir / "page_flip.ogg", freq=800.0, duration=0.25, volume=0.2, wave_type="rain")
    write_tone(audio_dir / "click.ogg", freq=1200.0, duration=0.08, volume=0.25, wave_type="sine")
    print("[Audio] Baseline ambient, BGM, and SFX files generated.")


def main():
    parser = argparse.ArgumentParser(description="Process and optimize visual novel assets for Ren'Py 8.")
    parser.add_argument("--project-root", default=".", help="Root directory of the project")
    parser.add_argument("--all", action="store_true", help="Process all assets (sprites, bgs, cgs)")
    parser.add_argument("--generate-baseline", action="store_true", help="Generate initial baseline assets")
    parser.add_argument("--quality", type=int, default=85, help="WebP compression quality (default: 85)")
    parser.add_argument("--target-height", type=int, default=1080, help="Target sprite height (default: 1080)")

    args = parser.parse_args()
    base_dir = Path(args.project_root).resolve()

    if args.generate_baseline or not (base_dir / "raw_assets" / "sprites" / "elena_neutral.png").exists():
        generate_baseline_raw_assets(base_dir)
        generate_baseline_audio(base_dir)

    print(f"=== Starting Asset Optimization Pipeline (Quality={args.quality}%) ===")

    # Process Sprites
    process_sprites(
        raw_dir=base_dir / "raw_assets" / "sprites",
        out_dir=base_dir / "game" / "images" / "characters",
        target_height=args.target_height,
        quality=args.quality,
        remove_bg=False
    )

    # Process Backgrounds and Event CGs
    process_backgrounds_and_cgs(
        raw_bg_dir=base_dir / "raw_assets" / "bg",
        out_bg_dir=base_dir / "game" / "images" / "bg",
        raw_cg_dir=base_dir / "raw_assets" / "cgs",
        out_cg_dir=base_dir / "game" / "images" / "cgs",
        target_size=(1920, 1080),
        quality=args.quality
    )

    print("=== Asset Pipeline Complete! All assets ready for Ren'Py 8 ===")


if __name__ == "__main__":
    main()
