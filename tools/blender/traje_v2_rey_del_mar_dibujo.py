"""
Dibujos del Rey del Mar v2 (los usa traje_v2_textura.py): la cara (según TRAJE_CARA, en
..._cara.py); el frente del peto con degradado, pectorales, filigrana de oro y escamas; la
armadura grabada con escamas que envuelve el cuerpo; y la capa con doble borde de oro, olas,
estrellas y el emblema del tridente con rayos. Formas en studs.
"""
import math
import numpy as np
from PIL import Image
import traje_v2_rey_del_mar_cara as CARA

OLA, ESCAMA, ESCAMA_LUZ = (40, 66, 158), (16, 100, 128), (40, 150, 176)
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


def capa(L):
    degradado(L, (18, 30, 92), (34, 58, 146))
    z = 1.0
    while z < 3.9:  # olas suaves
        L.trazo([(x / 10, z + 0.05 * math.sin(x * 0.9 + z * 3)) for x in range(-14, 15)], 0.03, OLA)
        z += 0.28
    azar = np.random.default_rng(4)
    for x, zz in azar.uniform((-0.85, 1.0), (0.85, 3.8), (45, 2)):  # estrellitas de oro esparcidas
        if math.hypot(x, zz - 2.75) > 0.78:
            L.ovalo(x, zz, 0.018, 0.018, "oro")
    for s in (-1, 1):  # doble borde de oro (la capa se abre hacia abajo)
        L.trazo([(s * 0.93, 3.98), (s * 1.08, 0.62)], 0.05, "oro")
        L.trazo([(s * 0.84, 3.9), (s * 0.98, 0.8)], 0.018, "oro")
    L.caja(-1.5, 0.4, 1.5, 0.78, "oro")
    for i in range(-6, 7):
        L.ovalo(i * 0.2, 0.78, 0.1, 0.06, (24, 40, 110))
    L.caja(-1.5, 3.92, 1.5, 4.0, "oro")
    # Cuello alto: filo de oro siguiendo su forma, olas y una concha con gema al centro.
    for s in (-1, 1):
        L.trazo([(s * 0.70, 3.98), (s * 0.88, 4.66)], 0.04, "oro")
    L.caja(-1.0, 4.64, 1.0, 4.9, "oro")
    for i in range(-3, 4):
        L.trazo([(i * 0.18 - 0.08, 4.12), (i * 0.18 - 0.03, 4.17), (i * 0.18 + 0.04, 4.16)], 0.018, "oro")
    for k in range(7):
        a = math.pi * (0.1 + 0.8 * k / 6)
        L.trazo([(0, 4.30), (0.2 * math.cos(a), 4.30 + 0.2 * math.sin(a))], 0.02, "oro")
    L.ovalo(0, 4.32, 0.05, 0.05, "gema", 1.0)
    for k in range(16):  # emblema: rayos, aro, tridente y gema
        a = k / 16 * math.tau
        L.trazo([(0.55 * math.cos(a), 2.75 + 0.55 * math.sin(a)), (0.72 * math.cos(a), 2.75 + 0.72 * math.sin(a))],
                0.02, "oro")
    L.trazo([(0.48 * math.cos(a / 20 * math.tau), 2.75 + 0.48 * math.sin(a / 20 * math.tau)) for a in range(21)],
            0.06, "oro")
    L.caja(-0.03, 2.35, 0.03, 3.15, "oro")
    L.caja(-0.22, 2.92, 0.22, 2.97, "oro")
    for x, alto in ((-0.2, 3.13), (0, 3.22), (0.2, 3.13)):
        L.poligono([(x - 0.045, 2.95), (x + 0.045, 2.95), (x, alto)], "oro")
    L.ovalo(0, 2.75, 0.07, 0.07, "gema", 1.0)
    L.ovalo(-0.02, 2.77, 0.02, 0.02, BLANCO, 1.0)


DIBUJOS = {"cara": CARA.DIBUJO, "pecho": pecho, "armadura": armadura, "capa": capa}
