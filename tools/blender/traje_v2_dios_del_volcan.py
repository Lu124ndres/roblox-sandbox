"""
Ficha del Dios del Volcán v2 (pase de 399 R$): un demonio de roca con magma adentro. El cuerpo
es magma que brilla (dibujo "magma") y encima van placas de obsidiana agrietada (pectorales,
abdominales, espalda, muslos, mangas, guanteletes, grebas): la lava se ve en las juntas, los
codos y las rodillas. Cuernos con relieve, corona y cresta de púas, hombreras en capas con púas
y gotas de lava, corazón de cristal, púas en la columna, los nudillos, las rodillas y las
botas, faja de hierro con hebilla de calavera. La cara se elige entre varias
(traje_v2_dios_del_volcan_cara.py, variable TRAJE_CARA). Accesorios en ..._piezas.py y dibujos
en ..._dibujo.py.
"""
import traje_v2_base as B
import traje_v2_dios_del_volcan_cara as CARA
from traje_v2_dios_del_volcan_piezas import accesorios  # noqa: F401 (lo lee traje_v2_cuerpo)

ARCHIVO = "DiosDelVolcan"
CARPETA = "dios_del_volcan_v2"
ENCUADRE = 8.4
CENTRO_Z = 3.15

COLORES = {
    "roca": (40, 34, 37),
    "roca_clara": (78, 67, 69),
    "roca_oscura": (24, 20, 23),
    "lava": (255, 110, 20),
    "lava_clara": (255, 214, 110),
    "brasa": (196, 52, 12),
    "hierro": (60, 58, 64),
    "cuerno": (54, 45, 47),
    "ojo": (255, 196, 60),
}
BRILLOS = {"lava": 1.0, "lava_clara": 1.0, "brasa": 0.6, "ojo": 1.0}
FONDO = COLORES["roca"]
PALETA_RECT = (0.75, 0.0, 1.0, 0.5)
GRIETAS, MAGMA = ("caja", "grietas"), ("caja", "magma")
REGIONES = {
    "cara": ((0.0, 0.5, 0.5, 1.0), (-0.66, 4.06, 0.66, 5.16)),
    "pecho": ((0.5, 0.5, 1.0, 1.0), (-0.96, 2.40, 0.96, 4.0)),  # frente de pectorales y abdominales
    "grietas": ((0.0, 0.0, 0.5, 0.5), (-3.3, -0.3, 3.3, 7.0)),  # roca: envuelve (proyección "caja")
    "magma": ((0.5, 0.0, 0.75, 0.5), (-3.3, -0.3, 3.3, 7.0)),  # el cuerpo de lava bajo las placas
}

# El torso queda de 2.0 de ancho donde se une a los brazos (si no, el puente del hombro no
# tiene largo); la faja de hierro, abajo, es más ancha.
TORSO = dict(k=2, tramos={"base": (2.0, 1.0, 0.0, 0.12), "faja": (2.06, 1.10, 0.0, 0.14)},
             anillos=[(2.0, 0.04, "faja"), (2.04, 0, "faja"), (2.36, 0, "faja")]
             + [(z, 0, "base") for z in (2.36, 2.42, 2.50, 3.0, 3.71, 3.86, 3.96)] + [(4.0, 0.04, "base")])
BRAZO = dict(k=2, tramos={"base": (0.94, 0.94, 0.0, 0.10), "mano": (0.92, 0.92, 0.0, 0.12)},
             anillos=[(2.0, 0.04, "mano"), (2.04, 0, "mano")] + [(z, 0, "mano") for z in B.ANILLOS_MUNECA]
             + [(z, 0, "base") for z in [2.46] + B.ANILLOS_CODO + [3.4, 3.71, 3.86, 3.96]] + [(4.0, 0.04, "base")])
# Botas y grebas macizas: más fondo, no más ancho (las suelas no se tocan entre sí).
PIERNA = dict(k=2, tramos={"suela": (0.98, 1.24, -0.09, 0.12), "pie": (0.96, 1.20, -0.09, 0.12),
                           "greba": (0.96, 1.06, 0.0, 0.13), "pierna": (0.94, 0.94, 0.0, 0.10)},
              anillos=[(0.0, 0.03, "suela"), (0.03, 0, "suela"), (0.09, 0, "suela"), (0.09, 0, "pie"),
                       (0.28, 0, "pie"), (0.31, 0, "pie"), (0.41, 0, "greba"), (0.68, 0, "greba"),
                       (0.74, 0, "greba"), (0.74, 0, "pierna")]
              + [(z, 0, "pierna") for z in B.ANILLOS_RODILLA] + [(z, 0, "pierna") for z in (1.70, 1.85, 1.98)])
CABEZA = dict(k=4, tramos={"base": (1.24, 1.16, 0.0, 0.22)},
              anillos=[(z, e, "base") for z, e in [(4.08, 0.05), (4.13, 0), (4.30, 0), (4.62, 0),
                                                    (4.95, 0), (5.11, 0), (5.14, 0.03)]])
PUENTES = {"cuello": "brasa", "hombro": "brasa", "cadera": "brasa"}


def color(parte, c, n):
    if parte == "torso":
        if n.z < -0.6 or c.z < 2.36:
            return "paleta", "hierro" if n.z > -0.6 else "roca_oscura"
        return GRIETAS if n.z > 0.6 else MAGMA
    if parte == "cabeza":
        return CARA.color_cabeza(c, n)
    if parte.startswith("brazo"):
        if c.z < 2.44:  # puños de lava
            return "paleta", "lava" if n.z > -0.6 else "brasa"
        return MAGMA
    if parte.startswith("pierna"):
        if c.z <= 0.091:
            return "paleta", "roca_oscura"
        if 0.67 < c.z <= 0.741:
            return "paleta", "hierro"
        return MAGMA if 0.74 < c.z < 1.26 else GRIETAS  # la rodilla es una junta de lava
    return "paleta", PUENTES[parte]
