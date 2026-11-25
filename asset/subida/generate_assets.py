#!/usr/bin/env python3
"""Genera los assets graficos para la ficha de Google Play de kawaii pdf."""

import subprocess
from PIL import Image, ImageDraw, ImageFont

OUT = "/Users/bigobs/SitioWebmacos/flutter/mipdf/asset/subida"
BASE = "/Users/bigobs/SitioWebmacos/flutter/mipdf/asset/imagenes/easyeditor.png"

# ── Kawaii colors ───────────────────────────────────────────────────
PINK50   = (255, 240, 245)
PINK100  = (255, 224, 235)
PINK200  = (255, 194, 215)
PINK300  = (255, 163, 193)
PINK400  = (255, 133, 168)
PINK500  = (255, 107, 157)
PINK600  = (232, 74, 127)
PINK700  = (196, 47, 99)
CREAM    = (255, 249, 247)
BLUSH    = (255, 239, 243)
CORAL    = (255, 154, 139)
MINT     = (200, 240, 224)
TEXT_P   = (74, 44, 58)
WHITE    = (255, 255, 255)

# ── Helpers ──────────────────────────────────────────────────────────
def gradient_h(img, c1, c2):
    """Horizontal gradient."""
    w, h = img.size
    for x in range(w):
        r = int(c1[0] + (c2[0] - c1[0]) * x / w)
        g = int(c1[1] + (c2[1] - c1[1]) * x / w)
        b = int(c1[2] + (c2[2] - c1[2]) * x / w)
        for y in range(h):
            img.putpixel((x, y), (r, g, b))

def gradient_v(img, c1, c2):
    """Vertical gradient."""
    w, h = img.size
    for y in range(h):
        r = int(c1[0] + (c2[0] - c1[0]) * y / h)
        g = int(c1[1] + (c2[1] - c1[1]) * y / h)
        b = int(c1[2] + (c2[2] - c1[2]) * y / h)
        for x in range(w):
            img.putpixel((x, y), (r, g, b))

def draw_text(draw, text, x, y, font_size, color=TEXT_P):
    """Draw text centered at x,y."""
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
    except:
        font = ImageFont.load_default()
    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text((x - tw // 2, y - th // 2), text, fill=color, font=font)

# ── 1. Icono de tienda 512x512 ──────────────────────────────────────
print("📱 Generando icono de tienda 512x512...")
subprocess.run(["sips", "-z", "512", "512", BASE, "--out", f"{OUT}/store_icon.png"], check=True)
print("   ✅ store_icon.png")

# ── 2. Feature Graphic 1024x500 ─────────────────────────────────────
print("🎨 Generando Feature Graphic 1024x500...")
fg = Image.new("RGB", (1024, 500))
gradient_h(fg, PINK100, PINK400)
# White pill card in center
card = Image.new("RGBA", (800, 320), (0, 0, 0, 0))
cdraw = ImageDraw.Draw(card)
cdraw.rounded_rectangle([0, 0, 799, 319], radius=40, fill=(255, 255, 255, 230))
# Load icon scaled down
icon = Image.open(BASE).convert("RGBA")
icon = icon.resize((140, 140))
card.paste(icon, (330, 30), icon)
cdraw2 = ImageDraw.Draw(card)
draw_text(cdraw2, "🌸 kawaii pdf 🌸", 400, 200, 48, PINK700)
draw_text(cdraw2, "Herramientas PDF con estilo kawaii", 400, 250, 20, (138, 107, 120))
fg.paste(card, (112, 90), card)
fg.save(f"{OUT}/feature_graphic.jpg", "JPEG", quality=90)
print("   ✅ feature_graphic.jpg")

# ── 3. Capturas de pantalla 1080x1920 ──────────────────────────────
def make_screenshot(filename, title):
    w, h = 1080, 1920
    img = Image.new("RGB", (w, h))
    gradient_v(img, CREAM, PINK50)

    draw = ImageDraw.Draw(img)

    # AppBar (pink gradient bar at top)
    for y in range(0, 220):
        r = int(PINK500[0] + (PINK400[0] - PINK500[0]) * y / 220)
        g = int(PINK500[1] + (PINK400[1] - PINK500[1]) * y / 220)
        b = int(PINK500[2] + (PINK400[2] - PINK500[2]) * y / 220)
        for x in range(w):
            img.putpixel((x, y), (r, g, b))

    # AppBar title
    draw_text(draw, "🌸 kawaii pdf 🌸", w // 2, 120, 44, WHITE)

    # Title
    draw_text(draw, title, w // 2, 340, 40, PINK700)
    # Subtitle
    draw_text(draw, "Selecciona una herramienta para tus documentos", w // 2, 390, 24, (138, 107, 120))

    # Cards grid (2x3)
    card_w, card_h = 460, 380
    gap = 40
    start_x = (w - (2 * card_w + gap)) // 2
    start_y = 470

    tools = [
        ("📝", "Crear PDF", "Nuevo doc", PINK500),
        ("🔗", "Unir PDFs", "Combinar", PINK600),
        ("✂️", "Dividir PDF", "Extraer", CORAL),
        ("🔓", "Desbloquear", "Quitar pass", PINK200),
        ("🔒", "Proteger", "Contraseña", PINK400),
        ("✏️", "Modificar", "Editar texto", PINK300),
    ]

    for i, (emoji, name, desc, color) in enumerate(tools):
        col, row = i % 2, i // 2
        cx = start_x + col * (card_w + gap)
        cy = start_y + row * (card_h + gap)

        # Card shadow
        for sx in range(cx + 6, cx + card_w + 6):
            for sy in range(cy + 6, cy + card_h + 6):
                if 0 <= sx < w and 0 <= sy < h:
                    img.putpixel((sx, sy), (255, 200, 210))

        # Card bg white
        for bx in range(cx, cx + card_w):
            for by in range(cy, cy + card_h):
                if 0 <= bx < w and 0 <= by < h:
                    img.putpixel((bx, by), WHITE)

        # Icon circle
        ic_cx, ic_cy = cx + card_w // 2, cy + 90
        icon_r = 70
        for ix in range(ic_cx - icon_r, ic_cx + icon_r):
            for iy in range(ic_cy - icon_r, ic_cy + icon_r):
                if (ix - ic_cx) ** 2 + (iy - ic_cy) ** 2 <= icon_r ** 2:
                    if 0 <= ix < w and 0 <= iy < h:
                        img.putpixel((ix, iy), tuple(int(c * 0.15) for c in color))

        # Emoji as icon
        draw_text(draw, emoji, ic_cx, ic_cy, 56, color)

        # Label
        draw_text(draw, name, cx + card_w // 2, cy + 210, 32, TEXT_P)
        draw_text(draw, desc, cx + card_w // 2, cy + 248, 22, (138, 107, 120))

    img.save(f"{OUT}/{filename}.png", "PNG")
    print(f"   ✅ {filename}.png")

print("📸 Generando capturas de pantalla 1080x1920...")
make_screenshot("screenshot_1_home", "✨ Herramientas PDF")
make_screenshot("screenshot_2_home", "✨ Herramientas PDF")
print("   ¡Capturas generadas!")

print("\n🎉 Todos los assets generados en asset/subida/")
