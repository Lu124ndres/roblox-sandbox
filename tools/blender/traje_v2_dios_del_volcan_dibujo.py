"""
Dibujos del Dios del Volcán v2 (los usa traje_v2_textura.py): la cara (según TRAJE_CARA, en
..._cara.py); el frente de pectorales y abdominales, de roca agrietada con runas encendidas y
cantos tallados; la roca que envuelve las placas; y el magma del cuerpo que se ve en las
juntas. Formas en studs.
"""
import traje_v2_dios_del_volcan_cara as CARA
from traje_v2_grietas import grietas, magma

TALLA, LUZ = (22, 18, 21), (96, 84, 86)


def runa(L, x, z, h, forma):
    """Runas encendidas talladas en la piedra (trazos rectos)."""
    trazos = {
        0: [[(0, -1), (0, 1)], [(0, 1), (0.6, 0.4), (0, 0)], [(0, 0), (0.6, -1)]],
        1: [[(0, -1), (0, 1)], [(-0.5, 0.5), (0.5, -0.1)], [(-0.5, -0.1), (0.5, 0.5)]],
        2: [[(-0.4, -1), (0, 1), (0.4, -1)], [(-0.25, -0.2), (0.25, -0.2)]],
        3: [[(0, -1), (0, 1)], [(0, 0.6), (0.5, 1)], [(0, 0.2), (0.5, 0.6)]],
    }[forma % 4]
    for t in trazos:
        L.trazo([(x + a * h, z + b * h) for a, b in t], 0.028, "lava", 1.0)


def pecho(L):
    grietas(L, semilla=5, celda=0.4, ancho=0.018)
    for s in (-1, 1):  # canto tallado de cada pectoral: luz arriba, sombra abajo
        L.trazo([(s * 0.08, 3.90), (s * 0.90, 3.90)], 0.03, LUZ)
        L.trazo([(s * 0.08, 3.22), (s * 0.5, 3.20), (s * 0.92, 3.30)], 0.04, TALLA)
        L.trazo([(s * 0.9, 3.25), (s * 0.9, 3.88)], 0.03, TALLA)
        for i, (x, z) in enumerate(((0.62, 3.70), (0.80, 3.52), (0.62, 3.40))):
            runa(L, s * x, z, 0.06, i + (0 if s > 0 else 2))
        for z0, z1 in ((2.52, 2.72), (2.77, 2.97), (3.02, 3.14)):  # abdominales
            L.trazo([(s * 0.05, z1 - 0.02), (s * 0.43, z1 - 0.02)], 0.022, LUZ)
            L.trazo([(s * 0.05, z0 + 0.02), (s * 0.43, z0 + 0.02)], 0.03, TALLA)


def piedra(L):
    grietas(L, semilla=3, celda=0.62)


def lava(L):
    magma(L, semilla=9, celda=0.3)


DIBUJOS = {"cara": CARA.DIBUJO, "pecho": pecho, "grietas": piedra, "magma": lava}
