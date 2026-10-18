"""
Ficha del Rey del Mar v2 (pase de 149 R$): mitad Poseidón, mitad caballero. Armadura turquesa
grabada con escamas y filos de oro en relieve, peto con gema de mar, gorguera, hombreras de
concha en capas con cristales, brazales y grebas con aletas, rodilleras, punteras de oro,
corona de dos pisos con gemas, cresta y aletas, y una capa real con cuello alto que ondea
(huesos Capa1 y Capa2, los mueve su estilo en el juego). La cara se elige entre varias
(traje_v2_rey_del_mar_cara.py, variable TRAJE_CARA). Accesorios en ..._piezas.py y dibujos
en ..._dibujo.py.
"""
import traje_v2_base as B
import traje_v2_rey_del_mar_cara as CARA
from traje_v2_rey_del_mar_piezas import accesorios  # noqa: F401 (lo lee traje_v2_cuerpo)

ARCHIVO = "ReyDelMar"
CARPETA = "rey_del_mar_v2"
ENCUADRE = 8.0
CENTRO_Z = 3.1

COLORES = {
    "piel": (241, 194, 156),
    "barba": (226, 240, 246),
    "barba_sombra": (168, 204, 222),
    "mar": (22, 122, 150),
    "mar_claro": (52, 178, 196),
    "mar_oscuro": (12, 66, 98),
    "oro": (242, 192, 64),
    "oro_oscuro": (186, 128, 30),
    "capa": (28, 48, 128),
    "capa_forro": (18, 26, 70),
    "gema": (40, 214, 255),
    "ojo": (60, 228, 255),
    "coral": (246, 104, 84),
    "guante": (20, 36, 72),
    "boca": (90, 52, 52),
    "piel_sombra": (222, 168, 132),
    "pelo": (92, 58, 36),
}
BRILLOS = {"gema": 1.0, "ojo": 1.0}
FONDO = COLORES["mar"]
PALETA_RECT = (0.75, 0.0, 1.0, 0.5)
REGIONES = {
    "cara": ((0.0, 0.5, 0.5, 1.0), (-0.66, 4.06, 0.66, 5.16)),
    "pecho": ((0.5, 0.5, 1.0, 1.0), (-0.96, 2.42, 0.96, 3.98)),  # el frente del peto
    "armadura": ((0.0, 0.0, 0.5, 0.5), (-3.3, -0.3, 3.3, 7.0)),  # envuelve (proyección "caja")
    "capa": ((0.5, 0.0, 0.75, 0.5), (1.25, 0.55, -1.25, 4.80)),  # vista desde atrás, con el cuello
}

TORSO = dict(k=2, tramos={"base": (2.0, 1.0, 0.0, 0.12), "falda": (2.04, 1.12, 0.0, 0.14),
                          "cinto": (2.02, 1.08, 0.0, 0.13)},
             anillos=[(2.0, 0.04, "falda"), (2.04, 0, "falda"), (2.28, 0, "falda"), (2.28, 0, "cinto"),
                      (2.44, 0, "cinto"), (2.44, 0, "base")]
             + [(z, 0, "base") for z in (2.50, 3.0, 3.71, 3.86, 3.96)] + [(4.0, 0.04, "base")])
# Las bandas de oro sobresalen un poco (relieve) y no caen en franjas de articulación.
BRAZO = dict(k=2, tramos={"base": (0.94, 0.94, 0.0, 0.10), "mano": (0.9, 0.9, 0.0, 0.10),
                          "nudillo": (0.94, 0.94, 0.0, 0.11), "brazal": (1.04, 1.04, 0.0, 0.13),
                          "brazal_oro": (1.09, 1.09, 0.0, 0.14), "banda": (0.99, 0.99, 0.0, 0.11)},
             anillos=[(2.0, 0.04, "mano"), (2.04, 0, "mano"), (2.14, 0, "mano"), (2.14, 0, "nudillo"),
                      (2.22, 0, "nudillo"), (2.22, 0, "mano")] + [(z, 0, "mano") for z in B.ANILLOS_MUNECA]
             + [(2.46, 0, "brazal_oro"), (2.52, 0, "brazal_oro"), (2.52, 0, "brazal"), (2.64, 0, "brazal"),
                (2.64, 0, "brazal_oro"), (2.70, 0, "brazal_oro")]
             + [(z, 0, "base") for z in B.ANILLOS_CODO + [3.30]]
             + [(3.30, 0, "banda"), (3.36, 0, "banda"), (3.36, 0, "base")]
             + [(z, 0, "base") for z in (3.71, 3.86, 3.96)] + [(4.0, 0.04, "base")])
PIERNA = dict(k=2, tramos={"suela": (0.98, 1.16, -0.07, 0.12), "pie": (0.96, 1.12, -0.07, 0.12),
                           "greba": (0.95, 0.98, 0.0, 0.12), "greba_oro": (0.98, 1.02, 0.0, 0.13),
                           "pierna": (0.94, 0.94, 0.0, 0.10), "banda": (0.98, 0.98, 0.0, 0.11)},
              anillos=[(0.0, 0.03, "suela"), (0.03, 0, "suela"), (0.08, 0, "suela"), (0.08, 0, "pie"),
                       (0.26, 0, "pie"), (0.30, 0, "pie"), (0.40, 0, "greba_oro"), (0.45, 0, "greba_oro"),
                       (0.45, 0, "greba"), (0.66, 0, "greba"), (0.66, 0, "greba_oro"), (0.72, 0, "greba_oro"),
                       (0.72, 0, "pierna")]
              + [(z, 0, "pierna") for z in B.ANILLOS_RODILLA]
              + [(1.44, 0, "pierna"), (1.44, 0, "banda"), (1.50, 0, "banda"), (1.50, 0, "pierna")]
              + [(z, 0, "pierna") for z in (1.70, 1.85, 1.98)])
CABEZA = dict(k=4, tramos={"base": (1.24, 1.16, 0.0, 0.22)},
              anillos=[(z, e, "base") for z, e in [(4.08, 0.05), (4.13, 0), (4.30, 0), (4.45, 0),
                                                    (4.62, 0), (4.92, 0), (5.11, 0), (5.14, 0.03)]])
# Casco: aro de la corona (oro) y domo turquesa encima.
SOMBRERO = dict(k=4, tramos={"aro": (1.32, 1.24, 0.0, 0.25), "domo": (1.14, 1.06, 0.0, 0.2),
                             "domo2": (0.9, 0.82, 0.0, 0.14), "domo3": (0.6, 0.54, 0.0, 0.07)},
                anillos=[(5.15, 0, "aro"), (5.36, 0, "aro"), (5.36, 0, "domo"), (5.50, 0, "domo"),
                         (5.58, 0, "domo2"), (5.62, 0, "domo3")])
PUENTES = {"cuello": "piel", "hombro": "mar_oscuro", "cadera": "mar_oscuro", "union_sombrero": "mar"}

HUESOS_EXTRA = {
    "Capa1": ((0, 0.56, 3.95), (0, 0.56, 2.3), "Pecho"),
    "Capa2": ((0, 0.56, 2.3), (0, 0.56, 0.62), "Capa1"),
}
# Poses de revisión: al caminar la capa vuela hacia atrás.
POSES_EXTRA = {"caminar": {"Capa1": [((1, 0, 0), 50)], "Capa2": [((1, 0, 0), 15)]},
               "sentado": {"Capa1": [((1, 0, 0), 25)]}}
ARMADURA = ("caja", "armadura")


def color(parte, c, n):
    if parte == "torso":
        if n.z > 0.6:
            return "paleta", "mar_oscuro"
        if n.z < -0.6:
            return "paleta", "oro"
        return ("paleta", "oro") if 2.28 < c.z < 2.44 else ARMADURA
    if parte == "cabeza":
        return CARA.color_cabeza(c, n)
    if parte == "sombrero":
        return "paleta", "oro" if c.z < 5.365 else "mar"
    if parte.startswith("brazo"):
        if c.z < 2.43:
            return "paleta", "oro" if 2.14 < c.z < 2.22 else "guante"
        if c.z < 2.71:
            return ARMADURA if 2.52 < c.z < 2.64 else ("paleta", "oro")
        return "paleta", "oro" if 3.30 < c.z < 3.36 else "mar_oscuro"
    if parte.startswith("pierna"):
        if c.z <= 0.081:
            return "paleta", "oro_oscuro"
        if c.z <= 0.401:
            return "paleta", "mar_oscuro"
        if c.z <= 0.721:
            return ARMADURA if 0.45 < c.z < 0.66 else ("paleta", "oro")
        return "paleta", "oro" if 1.44 < c.z < 1.50 else "mar_oscuro"
    return "paleta", PUENTES[parte]
