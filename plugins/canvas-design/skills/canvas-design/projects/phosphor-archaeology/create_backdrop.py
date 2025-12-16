#!/usr/bin/env python3
"""
Phosphor Archaeology - Terminal Backdrop for GGPrompts
Creates a cyberpunk terminal aesthetic with proper subtitle visibility
"""

from PIL import Image, ImageDraw, ImageFont
import random
import math
import os

# Configuration
WIDTH = 1920
HEIGHT = 1080
FONT_DIR = os.path.join(os.path.dirname(__file__), '..', '..', 'canvas-fonts')
OUTPUT_PATH = '/home/matt/projects/ggprompts-next/public/images/terminal-backdrop.png'

# Color palette - Phosphor greens with cyan accents
VOID_BLACK = (0, 0, 0)
DARK_GREEN = (16, 40, 30)
PHOSPHOR_DIM = (16, 120, 80)
PHOSPHOR_MID = (16, 185, 129)
PHOSPHOR_BRIGHT = (34, 197, 94)
PHOSPHOR_GLOW = (74, 222, 128)
CYAN_ACCENT = (6, 182, 212)
AMBER_ACCENT = (255, 200, 87)
RED_ACCENT = (239, 68, 68)
YELLOW_ACCENT = (250, 204, 21)

def load_font(name, size):
    """Load a font from the canvas-fonts directory"""
    font_path = os.path.join(FONT_DIR, name)
    try:
        return ImageFont.truetype(font_path, size)
    except:
        return ImageFont.load_default()

def draw_glow_text(draw, pos, text, font, color, glow_radius=3, glow_color=None):
    """Draw text with a phosphor glow effect"""
    x, y = pos
    if glow_color is None:
        glow_color = tuple(min(255, c + 60) for c in color[:3]) + (40,)

    # Create glow layers
    for r in range(glow_radius, 0, -1):
        alpha = int(30 / r)
        gc = (*glow_color[:3], alpha)
        for dx in range(-r, r+1):
            for dy in range(-r, r+1):
                if dx*dx + dy*dy <= r*r:
                    draw.text((x + dx, y + dy), text, font=font, fill=gc)

    # Draw main text
    draw.text(pos, text, font=font, fill=color)

def draw_scanlines(img, intensity=0.03):
    """Add subtle CRT scanlines"""
    pixels = img.load()
    for y in range(0, HEIGHT, 2):
        for x in range(WIDTH):
            r, g, b = pixels[x, y][:3]
            factor = 1 - intensity
            pixels[x, y] = (int(r * factor), int(g * factor), int(b * factor))

def draw_matrix_rain(draw, font):
    """Draw cascading matrix-style characters"""
    chars = "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン0123456789"

    for _ in range(150):
        x = random.randint(0, WIDTH)
        y = random.randint(0, HEIGHT)
        char = random.choice(chars)
        alpha = random.randint(15, 60)
        color = (*PHOSPHOR_DIM[:3], alpha)
        draw.text((x, y), char, font=font, fill=color)

def draw_terminal_chrome(draw, fonts):
    """Draw window chrome elements"""
    # Traffic light buttons
    draw.ellipse([15, 10, 27, 22], fill=RED_ACCENT)
    draw.ellipse([35, 10, 47, 22], fill=YELLOW_ACCENT)
    draw.ellipse([55, 10, 67, 22], fill=PHOSPHOR_BRIGHT)

    # Window title
    title_font = fonts['mono_small']
    draw.text((WIDTH//2 - 80, 8), "ggprompts@terminal:~", font=title_font, fill=PHOSPHOR_MID)

def draw_status_panel(draw, fonts):
    """Draw status indicators on the right side"""
    x = WIDTH - 200
    y = 100
    mono = fonts['mono_small']

    # Status indicators
    draw.text((x, y), "status:", font=mono, fill=PHOSPHOR_DIM)
    draw_glow_text(draw, (x + 70, y), "ONLINE", mono, PHOSPHOR_BRIGHT, glow_radius=2)

    draw.text((x, y + 35), "uptime:", font=mono, fill=PHOSPHOR_DIM)
    draw.text((x + 70, y + 35), "99.97%", font=mono, fill=PHOSPHOR_MID)

    draw.text((x, y + 70), "latency:", font=mono, fill=PHOSPHOR_DIM)
    draw.text((x + 75, y + 70), "12ms", font=mono, fill=PHOSPHOR_MID)

def draw_left_panel(draw, fonts):
    """Draw command output on left side"""
    x = 60
    y = 70
    mono = fonts['mono_small']
    mono_dim = fonts['mono_tiny']

    lines = [
        ("$ claude", PHOSPHOR_MID, "  --version", PHOSPHOR_DIM),
        ("Claude Code v1.0.0", PHOSPHOR_MID, "", None),
        ("", None, "", None),
        ("$ prompt --watch", PHOSPHOR_MID, "", None),
        ("", None, "", None),
        ("Loading skills: agent creator...", PHOSPHOR_DIM, "", None),
        ("", None, "", None),
        ("await toolkit: {", PHOSPHOR_DIM, "", None),
        ("  skills:", CYAN_ACCENT, " [installed]", PHOSPHOR_DIM),
        ("  agents:", CYAN_ACCENT, " [3 active]", PHOSPHOR_DIM),
        ("}", PHOSPHOR_DIM, "", None),
    ]

    for i, line in enumerate(lines):
        if line[0]:
            draw.text((x, y + i * 28), line[0], font=mono, fill=line[1])
        if line[2]:
            text_width = draw.textlength(line[0], font=mono)
            draw.text((x + text_width, y + i * 28), line[2], font=mono, fill=line[3])

def draw_deploy_panel(draw, fonts):
    """Draw deployment status on right side"""
    x = WIDTH - 280
    y = 200
    mono = fonts['mono_tiny']

    draw.text((x, y), "queue to deploy: 3", font=mono, fill=PHOSPHOR_DIM)
    draw.text((x, y + 25), "active workers:", font=mono, fill=PHOSPHOR_DIM)
    draw.text((x + 120, y + 25), "5", font=mono, fill=CYAN_ACCENT)

def draw_progress_bar(draw, fonts):
    """Draw progress bar at bottom"""
    x = 60
    y = HEIGHT - 100
    width = 200
    mono = fonts['mono_small']

    draw.text((x, y - 25), "< Generating response...", font=mono, fill=PHOSPHOR_DIM)

    # Progress bar background
    draw.rectangle([x, y, x + width, y + 12], outline=PHOSPHOR_DIM, width=1)

    # Progress fill (73%)
    fill_width = int(width * 0.73)
    for i in range(fill_width):
        intensity = 0.7 + 0.3 * math.sin(i * 0.1)
        color = tuple(int(c * intensity) for c in PHOSPHOR_BRIGHT)
        draw.line([(x + i, y + 1), (x + i, y + 11)], fill=color)

    draw.text((x + width + 15, y - 2), "73%", font=mono, fill=PHOSPHOR_MID)

def draw_bottom_right_status(draw, fonts):
    """Draw bottom right status"""
    mono = fonts['mono_tiny']
    x = WIDTH - 180
    y = HEIGHT - 60

    draw.text((x, y), "[200] OK", font=mono, fill=PHOSPHOR_BRIGHT)
    draw.text((x, y + 25), "LATENCY: 12ms", font=mono, fill=PHOSPHOR_DIM)

def draw_corner_brackets(draw):
    """Draw decorative corner brackets around logo area"""
    cx, cy = WIDTH // 2, HEIGHT // 2 - 20
    bracket_size = 220
    bracket_length = 40

    # Cyan accent brackets
    color = (*CYAN_ACCENT, 180)
    weight = 2

    # Top-left
    draw.line([(cx - bracket_size, cy - 70), (cx - bracket_size + bracket_length, cy - 70)], fill=color, width=weight)
    draw.line([(cx - bracket_size, cy - 70), (cx - bracket_size, cy - 70 + bracket_length)], fill=color, width=weight)

    # Top-right
    draw.line([(cx + bracket_size, cy - 70), (cx + bracket_size - bracket_length, cy - 70)], fill=color, width=weight)
    draw.line([(cx + bracket_size, cy - 70), (cx + bracket_size, cy - 70 + bracket_length)], fill=color, width=weight)

    # Bottom-left
    draw.line([(cx - bracket_size, cy + 100), (cx - bracket_size + bracket_length, cy + 100)], fill=color, width=weight)
    draw.line([(cx - bracket_size, cy + 100), (cx - bracket_size, cy + 100 - bracket_length)], fill=color, width=weight)

    # Bottom-right
    draw.line([(cx + bracket_size, cy + 100), (cx + bracket_size - bracket_length, cy + 100)], fill=color, width=weight)
    draw.line([(cx + bracket_size, cy + 100), (cx + bracket_size, cy + 100 - bracket_length)], fill=color, width=weight)

def draw_center_logo(draw, fonts):
    """Draw the main GGPrompts logo and subtitle"""
    cx = WIDTH // 2
    cy = HEIGHT // 2 - 30

    # Main logo
    logo_font = fonts['logo']
    logo_text = "GGPrompts"
    bbox = draw.textbbox((0, 0), logo_text, font=logo_font)
    logo_width = bbox[2] - bbox[0]

    # Draw logo with strong glow
    logo_pos = (cx - logo_width // 2, cy - 40)
    draw_glow_text(draw, logo_pos, logo_text, logo_font, PHOSPHOR_GLOW, glow_radius=6, glow_color=(*PHOSPHOR_BRIGHT, 60))

    # Subtitle - BRIGHTER than before
    subtitle_font = fonts['mono_medium']
    subtitle_text = "AI Prompt Engineering Platform"
    bbox = draw.textbbox((0, 0), subtitle_text, font=subtitle_font)
    subtitle_width = bbox[2] - bbox[0]

    # Draw subtitle with enhanced visibility - brighter color and glow
    subtitle_pos = (cx - subtitle_width // 2, cy + 45)
    # Use a brighter base color for the subtitle
    subtitle_color = (120, 200, 160)  # Brighter green
    draw_glow_text(draw, subtitle_pos, subtitle_text, subtitle_font, subtitle_color, glow_radius=4, glow_color=(*PHOSPHOR_MID, 50))

    # Decorative line under subtitle
    line_y = cy + 85
    line_half_width = 180

    # Gradient line with cyan ends
    for i in range(-line_half_width, line_half_width + 1):
        # Fade at edges
        edge_dist = abs(i) / line_half_width
        if edge_dist > 0.8:
            alpha = int(255 * (1 - (edge_dist - 0.8) / 0.2))
            color = (*CYAN_ACCENT[:3], alpha)
        else:
            color = CYAN_ACCENT
        draw.point((cx + i, line_y), fill=color)
        draw.point((cx + i, line_y + 1), fill=color)

def main():
    # Create output directory if needed
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)

    # Create base image
    img = Image.new('RGBA', (WIDTH, HEIGHT), VOID_BLACK)
    draw = ImageDraw.Draw(img)

    # Load fonts
    fonts = {
        'logo': load_font('GeistMono-Bold.ttf', 72),
        'mono_large': load_font('GeistMono-Bold.ttf', 32),
        'mono_medium': load_font('GeistMono-Regular.ttf', 22),
        'mono_small': load_font('DMMono-Regular.ttf', 16),
        'mono_tiny': load_font('DMMono-Regular.ttf', 13),
        'matrix': load_font('GeistMono-Regular.ttf', 14),
    }

    # Build the composition
    draw_matrix_rain(draw, fonts['matrix'])
    draw_terminal_chrome(draw, fonts)
    draw_left_panel(draw, fonts)
    draw_status_panel(draw, fonts)
    draw_deploy_panel(draw, fonts)
    draw_progress_bar(draw, fonts)
    draw_bottom_right_status(draw, fonts)
    draw_corner_brackets(draw)
    draw_center_logo(draw, fonts)

    # Add subtle scanlines
    draw_scanlines(img, intensity=0.02)

    # Convert to RGB and save
    img_rgb = Image.new('RGB', (WIDTH, HEIGHT), VOID_BLACK)
    img_rgb.paste(img, mask=img.split()[3] if img.mode == 'RGBA' else None)

    # Composite properly
    final = Image.new('RGB', (WIDTH, HEIGHT), VOID_BLACK)
    final.paste(img)

    final.save(OUTPUT_PATH, 'PNG', quality=95)
    print(f"Saved to: {OUTPUT_PATH}")
    print(f"Size: {os.path.getsize(OUTPUT_PATH) / 1024:.1f}KB")

if __name__ == "__main__":
    main()
