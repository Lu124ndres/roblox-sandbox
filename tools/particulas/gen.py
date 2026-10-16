"""Genera las texturas de partículas propias del juego (PNG con alfa).

Uso: python3 gen.py <carpeta_salida>

  FuegoFlip  1024², 4x4 cuadros: lengua de fuego que sube, se retuerce y se
             rompe (colores ya horneados: núcleo blanco, amarillo, naranja, rojo)
  AguaFlip   1024², 4x4 cuadros: medialuna de agua que gira y se deshace
             (núcleo blanco, celeste, azul)
  Brasa      128²: punto brillante (blanco, se tiñe con Color)
  Halo       256²: brillo suave redondo (blanco)
  Anillo     512²: aro de onda expansiva (blanco)
  Chispa     256²: estrella de 4 puntas (blanco)
  Burbuja    256²: burbuja con reflejo (blanco)
"""

import os
import sys

import numpy as np
from PIL import Image
from scipy.ndimage import map_coordinates

RNG = np.random.default_rng(7)


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def fbm(size, base_cells, octaves=4):
    """Ruido fractal que se repite sin costuras (filtrado en frecuencia)."""
    k = np.fft.fftfreq(size) * size
    kx, ky = np.meshgrid(k, k)
    f = np.sqrt(kx * kx + ky * ky)
    f[0, 0] = 1
    lo, hi = base_cells * 0.5, base_cells * 2**octaves
    amp = np.where((f >= lo) & (f <= hi), f**-1.4, 0)
    phase = np.exp(2j * np.pi * RNG.random((size, size)))
    out = np.real(np.fft.ifft2(amp * phase))
    return (out - out.min()) / (out.max() - out.min())


NOISE = fbm(512, 4)
NOISE2 = fbm(512, 5, 3)


def sample(field, x, y):
    n = field.shape[0]
    return map_coordinates(field, [np.mod(y, 1) * n, np.mod(x, 1) * n], order=1, mode="wrap")


def ramp(intensity, stops):
    pos = np.array([s[0] for s in stops])
    cols = np.array([s[1] for s in stops], dtype=float)
    out = np.zeros(intensity.shape + (3,))
    for c in range(3):
        out[..., c] = np.interp(intensity, pos, cols[:, c])
    return out


def rgba(color, alpha):
    img = np.dstack([np.clip(color, 0, 255), np.clip(alpha, 0, 1) * 255])
    return Image.fromarray(img.astype(np.uint8), "RGBA")


def grid(n):
    y, x = np.mgrid[0:n, 0:n]
    u = (x + 0.5) / n * 2 - 1
    v = 1 - (y + 0.5) / n  # 0 abajo, 1 arriba
    return u, v


FIRE = [
    (0.0, (120, 10, 0)),
    (0.3, (210, 45, 5)),
    (0.55, (255, 130, 20)),
    (0.78, (255, 210, 70)),
    (1.0, (255, 252, 225)),
]
WATER = [
    (0.0, (0, 40, 140)),
    (0.35, (0, 120, 230)),
    (0.65, (40, 210, 255)),
    (0.85, (170, 245, 255)),
    (1.0, (255, 255, 255)),
]


def flame(n, t, seed):
    u, v = grid(n)
    v = v * 1.08 - 0.04
    top = 0.97 - 0.32 * t  # la punta baja al apagarse
    h = np.clip(v / top, 0, 1.2)
    # Turbulencia que sube: el ruido se desplaza hacia arriba con t.
    sx = sample(NOISE, u * 0.35 + seed, v * 0.55 - t * 0.9 + seed)
    sx2 = sample(NOISE2, u * 0.7 + seed * 2, v * 1.1 - t * 1.6)
    wobble = (sx - 0.5) * 0.55 * h**1.3 + (sx2 - 0.5) * 0.2 * h
    width = 0.5 * np.clip(h / 0.16, 0, 1) ** 0.55 * (1 - np.clip(h, 0, 1)) ** 0.9
    width = np.maximum(width, 1e-3)
    d = np.abs(u - wobble) / width
    body = smoothstep(1.0, 0.25, d) * (h <= 1.0)
    breakup = sample(NOISE2, u * 0.9 + seed, v * 0.9 - t * 2.0 + seed)
    holes = smoothstep(0.15 + 0.55 * t * h, 0.45 + 0.4 * t * h, breakup)
    core = smoothstep(0.75, 0.0, d) * smoothstep(0.75, 0.1, h)
    intensity = body * holes * (0.55 + 0.45 * core) * (1 - 0.55 * t)
    intensity = np.clip(intensity + 0.35 * core * body * (1 - t), 0, 1)
    alpha = smoothstep(0.04, 0.35, intensity) * smoothstep(0.0, 0.06, v)
    return ramp(intensity, FIRE), alpha


def crescent(n, t, seed):
    u, v = grid(n)
    y = v * 2 - 1
    r = np.sqrt(u * u + y * y)
    ang = np.arctan2(y, u) + t * 1.2
    span = 2.6 - 1.4 * t  # arco que se acorta
    a = np.mod(ang, 2 * np.pi)
    along = np.clip(a / span, 0, 1)
    inside = a < span
    radius = 0.62 + 0.08 * np.sin(along * np.pi)
    thick = 0.28 * np.sin(np.clip(along, 0, 1) * np.pi) ** 0.7 * (1 - 0.4 * t) + 1e-3
    turb = sample(NOISE, u * 0.5 + seed, y * 0.5 - t * 0.6 + seed) - 0.5
    d = np.abs(r - radius + turb * 0.12) / thick
    body = smoothstep(1.0, 0.1, d) * inside
    holes = smoothstep(0.1 + 0.5 * t, 0.4 + 0.45 * t, sample(NOISE2, u * 0.8 + seed, y * 0.8 + t))
    intensity = np.clip(body * holes * (1 - 0.4 * t) + 0.3 * smoothstep(0.5, 0, d) * inside, 0, 1)
    alpha = smoothstep(0.03, 0.3, intensity)
    return ramp(intensity, WATER), alpha


def flipbook(fn, n=256):
    sheet = Image.new("RGBA", (n * 4, n * 4))
    for k in range(16):
        color, alpha = fn(n, k / 15, 0.13 * (k % 3))
        sheet.paste(rgba(color, alpha), ((k % 4) * n, (k // 4) * n))
    return sheet


def white(alpha):
    n = alpha.shape[0]
    return rgba(np.full((n, n, 3), 255.0), alpha)


def ember(n=128):
    u, v = grid(n)
    r = np.sqrt(u * u + (v * 2 - 1) ** 2)
    return white(np.clip(np.exp(-(r / 0.22) ** 2) + 0.45 * np.exp(-(r / 0.55) ** 2), 0, 1) * (r < 1))


def halo(n=256):
    u, v = grid(n)
    r = np.sqrt(u * u + (v * 2 - 1) ** 2)
    return white(np.clip(1 - r, 0, 1) ** 2.2)


def ring(n=512):
    u, v = grid(n)
    r = np.sqrt(u * u + (v * 2 - 1) ** 2)
    edge = np.exp(-(((r - 0.82) / 0.07) ** 2))
    inner = 0.25 * smoothstep(0.0, 0.8, r) * (r < 0.82)
    return white(np.clip(edge + inner, 0, 1) * (r < 1))


def star(n=256):
    u, v = grid(n)
    y = v * 2 - 1
    r = np.sqrt(u * u + y * y)
    arms = np.exp(-(np.abs(u) / 0.035) ** 1.2) * np.exp(-np.abs(y) * 2.2)
    arms += np.exp(-(np.abs(y) / 0.035) ** 1.2) * np.exp(-np.abs(u) * 2.2)
    du, dy = (u + y) / np.sqrt(2), (u - y) / np.sqrt(2)
    arms += 0.4 * np.exp(-(np.abs(du) / 0.03)) * np.exp(-np.abs(dy) * 4.5)
    arms += 0.4 * np.exp(-(np.abs(dy) / 0.03)) * np.exp(-np.abs(du) * 4.5)
    glow = np.exp(-(r / 0.12) ** 2) + 0.3 * np.exp(-(r / 0.35) ** 2)
    return white(np.clip(arms + glow, 0, 1) * (r < 1))


def bubble(n=256):
    u, v = grid(n)
    y = v * 2 - 1
    r = np.sqrt(u * u + y * y)
    rim = np.exp(-(((r - 0.86) / 0.06) ** 2))
    fill = 0.12 + 0.25 * smoothstep(0.4, 0.86, r)
    spot = np.exp(-(((u + 0.35) / 0.16) ** 2 + ((y - 0.38) / 0.11) ** 2))
    alpha = np.clip(rim * 0.95 + fill * (r < 0.86) + spot, 0, 1) * (r < 0.95)
    return white(alpha)


def main():
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    flipbook(flame).save(os.path.join(out, "FuegoFlip.png"))
    flipbook(crescent).save(os.path.join(out, "AguaFlip.png"))
    ember().save(os.path.join(out, "Brasa.png"))
    halo().save(os.path.join(out, "Halo.png"))
    ring().save(os.path.join(out, "Anillo.png"))
    star().save(os.path.join(out, "Chispa.png"))
    bubble().save(os.path.join(out, "Burbuja.png"))


if __name__ == "__main__":
    main()
