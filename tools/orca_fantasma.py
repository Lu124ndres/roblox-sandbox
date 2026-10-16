import sys, numpy as np
from PIL import Image
import colorsys
def ghost(src, dst):
    im = np.asarray(Image.open(src).convert('RGB')).astype(np.float32) / 255
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    mx, mn = im.max(-1), im.min(-1)
    L = 0.3 * r + 0.55 * g + 0.15 * b
    s = np.where(mx > 1e-4, (mx - mn) / np.maximum(mx, 1e-4), 0)
    # tono 0..1
    h = np.zeros_like(L)
    d = np.maximum(mx - mn, 1e-5)
    h = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) / 6
    t = np.clip(L, 0, 1) ** 0.85
    oscuro = np.array([0.22, 0.08, 0.42]); claro = np.array([0.88, 0.84, 1.0])
    base = oscuro * (1 - t[..., None]) + claro * t[..., None]
    # acentos: dorado/naranja -> calabaza brillante; cian/azul -> fantasma cian; rojo/coral -> magenta
    naranja = np.array([1.0, 0.55, 0.1]); cian = np.array([0.45, 1.0, 0.95]); magenta = np.array([0.95, 0.3, 0.85])
    acento = np.where(((h > 0.05) & (h < 0.19))[..., None], naranja,
             np.where(((h > 0.42) & (h < 0.72))[..., None], cian, magenta))
    peso = np.clip((s - 0.3) / 0.35, 0, 1) * np.clip((mx - 0.2) / 0.3, 0, 1)
    out = base * (1 - peso[..., None]) + acento * (0.55 + 0.45 * mx[..., None]) * peso[..., None]
    Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8)).save(dst)
for n in (1, 2, 3, 4):
    ghost(f'/mnt/user-data/uploads/JuegoRoblox/assets/textures/OrcaE{n}_color.png', f'OrcaFantasmaE{n}_color.png')
