"""
Dibujos del Rey del Mar v2 (los usa traje_v2_textura.py): la cara (según TRAJE_CARA, en
..._cara.py); el frente del peto con degradado, pectorales, filigrana de oro y escamas; la
armadura grabada con escamas que envuelve el cuerpo; y el espaldar con filo de oro y el emblema
del tridente con rayos. Formas en studs.
"""
import math
import numpy as np
from PIL import Image
import traje_v2_rey_del_mar_cara as CARA

ESCAMA, ESCAMA_LUZ = (16, 100, 128), (40, 150, 176)
LUZ, SOMBRA, BLANCO = (36, 146, 172), (12, 80, 108), (255, 255, 255)


def espejo(pts):
    return [(-x, z) for x, z in reversed(pts)]


def degradado(L, abajo, arriba):
    """Fondo de la región en degradado vertical (abajo -> arriba)."""
    W, H = L.tam()
    t = np.linspace(1, 0, H)[:, None, None]
    rgb = np.array(abajo, np.float32) * (1 - t) + np.array(arriba, np.float32) * t
    L.pegar(Image.fromarray(np.repeat(rgb, W, 1).astype(np.uint8), "RGB"), Image.new("L", (W, H), 0))


def espiral(cx, z, r0, vueltas, lado):
    return [(cx + lado * r0 * (1 - i / 30) * math.cos(i / 30 * vueltas * math.tau),
             z + r0 * (1 - i / 30) * math.sin(i / 30 * vueltas * math.tau)) for i in range(31)]


def escamas(L, a0, a1, b0, b1, tam=0.16):
    fila, b = 0, b1
    while b > b0:
        a = a0 + (tam / 2 if fila % 2 else 0)
        while a < a1:
            L.ovalo(a, b, tam * 0.52, tam * 0.42, ESCAMA)
            L.ovalo(a, b + tam * 0.08, tam * 0.44, tam * 0.32, ESCAMA_LUZ)
            L.ovalo(a, b + tam * 0.12, tam * 0.40, tam * 0.27, "mar")
            a += tam
        b -= tam * 0.62
        fila += 1


def pecho(L):
    degradado(L, (14, 92, 120), (30, 140, 166))
    for s in (-1, 1):  # pectorales: luz arriba y sombra abajo
        L.ovalo(s * 0.42, 3.45, 0.42, 0.34, SOMBRA)
        L.ovalo(s * 0.42, 3.50, 0.40, 0.30, "mar")
        L.ovalo(s * 0.40, 3.58, 0.30, 0.18, LUZ)
    escamas(L, -1.0, 1.0, 2.40, 3.02, 0.14)
    L.caja(-1.0, 3.02, 1.0, 3.06, "oro")
    for s in (-1, 1):  # filigrana dorada que sale de la gema
        L.trazo(espiral(s * 0.52, 3.62, 0.16, 1.4, s), 0.025, "oro")
        L.trazo([(s * 0.26, 3.33), (s * 0.5, 3.24), (s * 0.78, 3.30), (s * 0.9, 3.5)], 0.03, "oro")
        L.trazo([(s * 0.26, 3.33), (s * 0.4, 3.6), (s * 0.38, 3.8)], 0.025, "oro")
        L.trazo([(s * 0.9, 2.5), (s * 0.9, 3.9)], 0.04, "oro")
        for z in (2.6, 2.8):
            L.ovalo(s * 0.82, z, 0.03, 0.03, "oro")
    for i in range(-4, 5):  # olas grabadas arriba
        x = i * 0.2
        L.trazo([(x - 0.1, 3.88), (x - 0.05, 3.93), (x + 0.02, 3.92), (x + 0.04, 3.88)], 0.018, LUZ)


def armadura(L):
    L.fondo("mar")
    escamas(L, -3.4, 3.4, -0.4, 7.1, 0.17)


def espalda(L):
    """El espaldar: degradado, escamas abajo, filo de oro y el emblema del tridente en un aro."""
    degradado(L, (14, 92, 120), (30, 140, 166))
    escamas(L, -1.0, 1.0, 2.40, 3.00, 0.14)
    L.caja(-1.0, 3.00, 1.0, 3.04, "oro")
    for s in (-1, 1):
        L.trazo([(s * 0.9, 2.5), (s * 0.9, 3.9)], 0.04, "oro")
        L.trazo(espiral(s * 0.6, 3.72, 0.13, 1.4, s), 0.022, "oro")
    L.trazo([(0.42 * math.cos(a / 24 * math.tau), 3.33 + 0.42 * math.sin(a / 24 * math.tau)) for a in range(25)],
            0.045, "oro")
    for k in range(12):  # rayos del emblema
        a = k / 12 * math.tau
        L.trazo([(0.46 * math.cos(a), 3.33 + 0.46 * math.sin(a)), (0.58 * math.cos(a), 3.33 + 0.58 * math.sin(a))],
                0.018, "oro")
    for i in range(-4, 5):  # olas grabadas arriba
        x = i * 0.2
        L.trazo([(x - 0.1, 3.88), (x - 0.05, 3.93), (x + 0.02, 3.92), (x + 0.04, 3.88)], 0.018, LUZ)


DIBUJOS = {"cara": CARA.DIBUJO, "pecho": pecho, "armadura": armadura, "espalda": espalda}
