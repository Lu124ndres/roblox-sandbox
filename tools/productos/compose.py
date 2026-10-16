"""Compone los íconos 512x512 de productos y pases (estilo cartoon brillante)."""
import math, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops

S = 512
HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "..", "..", "assets", "ui", "iconos")
OUT = os.path.join(HERE, "..", "..", "assets", "ui", "productos")
FONT = os.path.join(HERE, "LuckiestGuy.woff")  # @fontsource/luckiest-guy (OFL)
os.makedirs(OUT, exist_ok=True)

COLORS = {  # (centro, borde)
    "poder": ((150, 90, 255), (40, 20, 120)),
    "monedas": ((255, 210, 60), (190, 90, 0)),
    "llenar": ((70, 230, 210), (0, 90, 120)),
    "pack": ((255, 120, 200), (110, 20, 140)),
    "ruleta": ((255, 150, 60), (170, 30, 40)),
    "descanso": ((255, 120, 50), (120, 20, 10)),
    "estanque": ((80, 200, 255), (10, 60, 160)),
    "regalo": ((110, 240, 120), (10, 110, 60)),
    "monstruo": ((190, 110, 255), (60, 10, 110)),
    "cana": ((120, 220, 255), (20, 70, 150)),
    "canasta": ((255, 190, 90), (140, 60, 10)),
    "botas": ((150, 255, 150), (20, 120, 70)),
    "vip": ((255, 225, 90), (200, 100, 0)),
    "mar": ((90, 230, 255), (0, 60, 150)),
    "volcan": ((255, 110, 40), (110, 10, 10)),
    "boost": ((255, 240, 90), (150, 40, 200)),
}


def background(kind):
    inner, outer = COLORS[kind]
    bg = Image.new("RGB", (S, S))
    px = bg.load()
    c = S / 2
    for y in range(S):
        for x in range(S):
            d = min(1.0, math.hypot(x - c, y - c) / (S * 0.62))
            t = d ** 1.3
            px[x, y] = tuple(int(inner[i] * (1 - t) + outer[i] * t) for i in range(3))
    rays = Image.new("L", (S, S), 0)
    dr = ImageDraw.Draw(rays)
    n = 16
    for i in range(n):
        a0 = (i / n) * 2 * math.pi
        a1 = a0 + math.pi / n
        dr.polygon([(c, c), (c + 800 * math.cos(a0), c + 800 * math.sin(a0)),
                    (c + 800 * math.cos(a1), c + 800 * math.sin(a1))], fill=38)
    rays = rays.filter(ImageFilter.GaussianBlur(2))
    bg = Image.composite(Image.new("RGB", (S, S), (255, 255, 255)), bg, rays)
    glow = Image.new("L", (S, S), 0)
    ImageDraw.Draw(glow).ellipse((c - 150, c - 170, c + 150, c + 130), fill=110)
    glow = glow.filter(ImageFilter.GaussianBlur(60))
    bg = Image.composite(Image.new("RGB", (S, S), (255, 255, 230)), bg, glow)
    return bg.convert("RGBA")


def load(name):
    return Image.open(os.path.join(SRC, name)).convert("RGBA")


def cell(sheet, level, cols=5, size=200):
    i = level - 1
    x, y = (i % cols) * size, (i // cols) * size
    return load(sheet).crop((x, y, x + size, y + size))


def trim(im):
    box = im.getchannel("A").point(lambda a: 255 if a > 12 else 0).getbbox()
    return im.crop(box) if box else im


def place(canvas, im, box_size, center, shadow=True):
    im = trim(im)
    k = box_size / max(im.size)
    im = im.resize((max(1, int(im.width * k)), max(1, int(im.height * k))), Image.LANCZOS)
    im = im.filter(ImageFilter.UnsharpMask(radius=2, percent=70, threshold=2))
    x, y = int(center[0] - im.width / 2), int(center[1] - im.height / 2)
    if shadow:
        a = im.getchannel("A").point(lambda v: int(v * 0.45))
        sh = Image.new("RGBA", im.size, (0, 0, 0, 0))
        sh.putalpha(a)
        sh = sh.filter(ImageFilter.GaussianBlur(8))
        canvas.alpha_composite(sh, (x + 6, y + 12))
    canvas.alpha_composite(im, (x, y))


def label(canvas, text, cy, size=96, fill=(255, 255, 255), fill2=(255, 220, 70), maxw=400):
    if not text:
        return
    f = ImageFont.truetype(FONT, size)
    while f.getlength(text) > maxw and size > 40:
        size -= 4
        f = ImageFont.truetype(FONT, size)
    w = f.getlength(text)
    x = S / 2 - w / 2
    stroke = max(6, size // 9)
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.text((x + 3, cy + 7), text, font=f, fill=(0, 0, 0, 150), anchor="ls",
           stroke_width=stroke, stroke_fill=(0, 0, 0, 150))
    d.text((x, cy), text, font=f, fill=(25, 20, 45, 255), anchor="ls",
           stroke_width=stroke, stroke_fill=(25, 20, 45, 255))
    canvas.alpha_composite(layer)
    # relleno con degradado vertical blanco -> color
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).text((x, cy), text, font=f, fill=255, anchor="ls")
    top, bot = cy - size * 0.75, cy
    grad = Image.new("RGBA", (S, S))
    gp = ImageDraw.Draw(grad)
    for y in range(S):
        t = min(1, max(0, (y - top) / max(1, bot - top)))
        gp.line([(0, y), (S, y)], fill=tuple(int(fill[i] * (1 - t) + fill2[i] * t) for i in range(3)) + (255,))
    canvas.paste(grad, (0, 0), mask)


def frame(canvas):
    """Borde redondeado brillante; fuera del borde queda transparente."""
    r = 90
    m = Image.new("L", (S, S), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, S - 1, S - 1), r, fill=255)
    out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    out.paste(canvas, (0, 0), m)
    rim = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(rim).rounded_rectangle((6, 6, S - 7, S - 7), r - 6, outline=(255, 255, 255, 120), width=8)
    out.alpha_composite(rim)
    return out


def make(key, kind, icon, text="", sub=None, size=380, icon_y=None, text_size=100):
    c = background(kind)
    has_text = bool(text)
    cy = icon_y or (S / 2 - 30 if has_text else S / 2)
    place(c, icon, size if not has_text else min(size, 350), (S / 2, cy))
    if sub:
        place(c, sub[0], sub[1], sub[2])
    label(c, text.upper(), 470, text_size)
    frame(c).save(os.path.join(OUT, key + ".png"))
