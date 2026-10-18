"""
Ficha del Marinero v2: el traje que llevan todos los jugadores. Gorra blanca con banda marino,
barba, camisa a rayas con chaleco marino abierto, pañuelo rojo, cinturón, pantalón azul y
botas. Piel fija para todos y cara dibujada (decidido con el usuario). Sin brillos.
Ver traje_v2.py para armarlo y traje_v2_base.py para lo que comparte con los otros trajes.
"""
import traje_v2_base as B

ARCHIVO = "Marinero"  # Traje<ARCHIVO>_v2.fbx, objetos y texturas
CARPETA = "marinero_v2"

COLORES = {
    "piel": (241, 194, 156),
    "barba": (101, 62, 38),
    "blanco": (244, 244, 239),
    "raya": (52, 104, 168),
    "marino": (31, 43, 77),
    "rojo": (205, 48, 45),
    "pantalon": (74, 118, 166),
    "cinturon": (78, 50, 32),
    "hebilla": (232, 186, 74),
    "bota": (110, 66, 40),
    "suela": (58, 38, 27),
    "gorra": (247, 247, 243),
    "ojo": (24, 24, 30),
    "boca": (70, 28, 30),
}
FONDO = COLORES["blanco"]
SOMBRA_PIEL = (226, 172, 136)
ROJO_OSCURO = (158, 32, 34)
# Regiones dibujadas: rectángulo de la textura y lo que cubren del cuerpo (x0, z0, x1, z1).
# La espalda se dibuja vista desde atrás (x invertida) para que no quede en espejo.
REGIONES = {
    "cara": ((0.0, 0.5, 0.5, 1.0), (-0.62, 4.08, 0.62, 5.14)),
    "pecho": ((0.5, 0.5, 1.0, 1.0), (-1.0, 2.0, 1.0, 4.0)),
    "espalda": ((0.0, 0.0, 0.5, 0.5), (1.0, 2.0, -1.0, 4.0)),
}

TORSO = dict(k=2, tramos={"base": (2.0, 1.0, 0.0, 0.12)},
             anillos=[(z, e, "base") for z, e in [
                 (2.0, 0.04), (2.04, 0), (2.18, 0), (2.30, 0), (2.40, 0), (2.50, 0), (3.0, 0),
                 (3.71, 0), (3.86, 0), (3.96, 0), (4.0, 0.04)]])
FRANJAS_MANGA = [3.15 + i * 0.85 / 6 for i in range(7)]  # 6 rayas, blanca abajo
BRAZO = dict(k=2, tramos={"base": (0.94, 0.94, 0.0, 0.10)},
             anillos=[(z, e, "base") for z, e in
                      [(2.0, 0.04), (2.04, 0)] + [(z, 0) for z in B.ANILLOS_MUNECA]
                      + [(z, 0) for z in B.ANILLOS_CODO]
                      + [(z, 0) for z in FRANJAS_MANGA[:-1]] + [(3.96, 0), (4.0, 0.04)]])
# La bota es más ancha y el pie sale hacia adelante (el empeine sube en rampa del pie a la
# caña); la suela asoma un poco. Las suelas no se tocan entre sí.
PIERNA = dict(k=2, tramos={"suela": (0.98, 1.16, -0.07, 0.12), "pie": (0.96, 1.12, -0.07, 0.12),
                           "cana": (0.96, 0.98, 0.0, 0.11), "pierna": (0.94, 0.94, 0.0, 0.10)},
              anillos=[(0.0, 0.03, "suela"), (0.03, 0, "suela"), (0.08, 0, "suela"), (0.08, 0, "pie"),
                       (0.26, 0, "pie"), (0.30, 0, "pie"), (0.40, 0, "cana"), (0.55, 0, "cana"),
                       (0.55, 0, "pierna")]
              + [(z, 0, "pierna") for z in B.ANILLOS_RODILLA]
              + [(1.70, 0, "pierna"), (1.85, 0, "pierna"), (1.98, 0, "pierna")])
CABEZA = dict(k=4, tramos={"base": (1.24, 1.16, 0.0, 0.22)},
              anillos=[(z, e, "base") for z, e in [
                  (4.08, 0.05), (4.13, 0), (4.30, 0), (4.62, 0), (4.95, 0), (5.11, 0), (5.14, 0.03)]])
# Gorra de marinero: banda marino, ala blanca doblada hacia arriba y copa blanca.
SOMBRERO = dict(k=4, tramos={"banda": (1.30, 1.22, 0.0, 0.24), "ala": (1.46, 1.38, 0.0, 0.30),
                             "copa": (1.02, 0.96, 0.0, 0.21), "copa2": (0.94, 0.88, 0.0, 0.17),
                             "copa3": (0.80, 0.74, 0.0, 0.10)},
                anillos=[(5.15, 0, "banda"), (5.31, 0, "banda"), (5.31, 0, "ala"), (5.45, 0, "ala"),
                         (5.45, 0, "copa"), (5.60, 0, "copa"), (5.68, 0, "copa2"), (5.71, 0, "copa3")])
PUENTES = {"cuello": "piel", "hombro": "blanco", "cadera": "pantalon", "union_sombrero": "barba"}


def accesorios():
    return []


def color_cabeza(c, n):
    if n.z > 0.6:
        return "barba"
    if n.z < -0.6 or c.z < 4.13:
        return "piel"
    if n.y > 0.6:
        return "barba" if c.z > 4.30 else "piel"
    # Costados: pelo arriba (bajo la gorra) y atrás, barba abajo; el resto, piel.
    pelo = c.z > 4.95 or (c.y > 0.25 and c.z > 4.30)
    barba = c.y < 0.15 and c.z < 4.62
    return "barba" if pelo or barba else "piel"


def color(parte, c, n):
    frente, atras = n.y < -0.6 and abs(n.z) < 0.75, n.y > 0.6 and abs(n.z) < 0.75
    if parte == "torso":
        if frente:
            return "region", "pecho"
        if atras:
            return "region", "espalda"
        if n.z > 0.6:
            return "paleta", "marino"
        if n.z < -0.6 or c.z < 2.18:
            return "paleta", "pantalon"
        return "paleta", "cinturon" if c.z < 2.30 else "marino"
    if parte == "cabeza":
        return ("region", "cara") if frente else ("paleta", color_cabeza(c, n))
    if parte == "sombrero":
        return "paleta", "marino" if c.z < 5.305 else "gorra"
    if parte.startswith("brazo"):
        if n.z > 0.6:
            return "paleta", "blanco"
        if c.z < FRANJAS_MANGA[0]:
            return "paleta", "piel"
        banda = int((c.z - FRANJAS_MANGA[0]) / (FRANJAS_MANGA[1] - FRANJAS_MANGA[0]))
        return "paleta", "blanco" if banda % 2 == 0 else "raya"
    if parte.startswith("pierna"):
        return "paleta", "suela" if c.z <= 0.081 else "bota" if c.z <= 0.551 else "pantalon"
    return "paleta", PUENTES[parte]


def espejo(pts):
    return [(-x, z) for x, z in reversed(pts)]


def cara(L):
    L.fondo("piel")
    pelo = [(-0.9, 4.95), (-0.47, 4.95), (-0.41, 5.01), (-0.37, 5.4), (-0.9, 5.4)]
    L.poligono(pelo, "barba")
    L.poligono(espejo(pelo), "barba")
    barba = [(-0.9, 3.9), (-0.9, 4.62), (-0.6, 4.62), (-0.52, 4.53), (-0.42, 4.46), (-0.3, 4.42),
             (-0.18, 4.44)]
    L.poligono(barba + espejo(barba), "barba")
    for s in (-1, 1):
        L.ovalo(s * 0.105, 4.445, 0.13, 0.05, "barba")  # bigote
        L.ovalo(s * 0.22, 4.73, 0.062, 0.092, "ojo")
        L.ovalo(s * 0.22 - 0.022, 4.765, 0.022, 0.022, "blanco")
        L.trazo([(s * 0.12, 4.885), (s * 0.22, 4.905), (s * 0.31, 4.895)], 0.05, "barba")
    L.ovalo(0, 4.56, 0.05, 0.065, SOMBRA_PIEL)  # nariz
    sonrisa = [(0.15 * t / 10, 4.365 - 0.075 * (1 - (t / 10) ** 2)) for t in range(-10, 11)]
    L.trazo(sonrisa, 0.04, "boca")


def pecho(L):
    L.fondo("blanco")
    z = 2.30 + 0.14
    while z < 4.2:
        L.caja(-1.3, z, 1.3, z + 0.14, "raya")
        z += 0.28
    L.caja(-1.3, 1.8, 1.3, 2.18, "pantalon")
    L.caja(-1.3, 2.18, 1.3, 2.30, "cinturon")
    L.caja(-0.12, 2.165, 0.12, 2.315, "hebilla")
    L.caja(-0.065, 2.21, 0.065, 2.27, "cinturon")
    chaleco = [(-1.3, 2.30), (-0.30, 2.30), (-0.24, 3.30), (-0.42, 4.2), (-1.3, 4.2)]
    L.poligono(chaleco, "marino")
    L.poligono(espejo(chaleco), "marino")
    for z in (2.55, 2.90):
        L.ovalo(-0.355, z, 0.035, 0.035, "hebilla")
    panuelo = [(-0.48, 4.2), (-0.30, 4.2), (0, 3.84), (0.30, 4.2), (0.48, 4.2), (0.09, 3.66),
               (-0.09, 3.66)]
    L.poligono(panuelo, "rojo")
    L.poligono([(-0.05, 3.70), (-0.21, 3.30), (-0.02, 3.38)], "rojo")
    L.poligono([(0.05, 3.70), (0.19, 3.27), (0.02, 3.38)], "rojo")
    L.ovalo(0, 3.71, 0.085, 0.07, ROJO_OSCURO)
    L.ovalo(0, 3.715, 0.06, 0.05, "rojo")


def espalda(L):
    L.fondo("marino")
    L.caja(-1.3, 1.8, 1.3, 2.18, "pantalon")
    L.caja(-1.3, 2.18, 1.3, 2.30, "cinturon")
    L.caja(-0.62, 3.30, 0.62, 4.2, "raya")
    for borde in (0.07, 0.13):
        ancho = 0.03
        L.caja(-0.62 + borde, 3.30 + borde, -0.62 + borde + ancho, 4.2, "blanco")
        L.caja(0.62 - borde - ancho, 3.30 + borde, 0.62 - borde, 4.2, "blanco")
        L.caja(-0.62 + borde, 3.30 + borde, 0.62 - borde, 3.30 + borde + ancho, "blanco")


DIBUJOS = {"cara": cara, "pecho": pecho, "espalda": espalda}
