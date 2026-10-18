"""
Caras del Dios del Volcán v2. Se elige con la variable de entorno TRAJE_CARA (a, b o c):
  a  Calavera demonio: ceño en V, pómulos y mandíbula en relieve con colmillos, ojos de fuego
     hundidos y la boca encendida;
  b  Yelmo de guerra: visera de hierro con ranuras y rejilla que brillan y púas en las mejillas;
  c  Rostro de magma: la cara es lava que ruge, con media máscara de obsidiana y cuernitos.
Cada una trae sus piezas (Blender), su dibujo de la cara (PIL) y el color de los costados.
"""
import math
import os

VARIANTE = os.environ.get("TRAJE_CARA", "a")  # elegida por el usuario: Calavera demonio
NEGRO = (14, 10, 12)


def color_cabeza(c, n):
    if n.y < -0.6 and abs(n.z) < 0.75:
        return "region", "cara"
    return ("paleta", "roca_oscura") if n.z < -0.6 else ("caja", "grietas")


def piezas():
    from mathutils import Matrix
    from traje_v2_formas import pieza, placa, pua

    def pua_brasa(nombre, base, d, largo, grueso):
        an, m = pua(base, d, largo, grueso)
        return pieza(nombre, an, "Cabeza", "roca_clara", matriz=m)

    out = []
    if VARIANTE == "a":
        for s in (1, -1):  # ceño en V: dos placas inclinadas hacia el centro
            m = Matrix.Translation((s * 0.30, -0.60, 4.86)) @ Matrix.Rotation(math.radians(-s * 16), 4, "Y")
            out += [pieza(f"ceno{s}", placa(-0.07, 0.07, 0, 0, 0.62, 0.14), "Cabeza", "roca_clara", matriz=m),
                    pieza(f"pomulo{s}", placa(4.44, 4.58, s * 0.38, -0.60, 0.34, 0.10, w1=0.28), "Cabeza", "roca_clara")]
            for j, x in enumerate((0.13, 0.33)):  # colmillos de abajo (suben) y de arriba (bajan)
                an, m = pua((s * x, -0.66, 4.24), (0, -0.25, 1), 0.17 - 0.04 * j, 0.09)
                out.append(pieza(f"colmillo{s}{j}", an, "Cabeza", "roca_clara", matriz=m))
            an, m = pua((s * 0.16, -0.64, 4.46), (0, -0.2, -1), 0.14, 0.08)
            out.append(pieza(f"colmillo_alto{s}", an, "Cabeza", "roca_clara", matriz=m))
        out.append(pieza("mandibula", placa(4.02, 4.26, 0, -0.42, 1.02, 0.50, w1=1.10), "Cabeza",
                         lambda c, n: ("paleta", "roca_clara") if n.y < -0.6 else ("caja", "grietas")))
    if VARIANTE == "b":
        out += [pieza("visera", placa(4.10, 4.98, 0, -0.60, 1.30, 0.12), "Cabeza",
                      lambda c, n: ("region", "cara") if n.y < -0.6 else ("paleta", "hierro")),
                pieza("cresta_visera", placa(4.40, 5.02, 0, -0.67, 0.10, 0.07, w1=0.06), "Cabeza", "hierro")]
        for s in (1, -1):
            out.append(pua_brasa(f"pua_mejilla{s}", (s * 0.62, -0.45, 4.35), (s * 0.7, 0.4, 0.3), 0.45, 0.17))
    if VARIANTE == "c":
        out.append(pieza("mascara", placa(4.66, 5.02, 0, -0.60, 1.28, 0.10, w1=1.34), "Cabeza",
                         lambda c, n: ("region", "cara") if n.y < -0.6 else ("paleta", "roca_oscura")))
        for s in (1, -1):
            out.append(pua_brasa(f"cuernito{s}", (s * 0.28, -0.64, 4.98), (s * 0.3, -0.5, 1), 0.3, 0.12))
    return out


def espejo(pts):
    return [(-x, z) for x, z in reversed(pts)]


def ojos_fuego(L, z, alto=0.07):
    for s in (-1, 1):
        L.poligono([(s * 0.06, z + 0.04), (s * 0.42, z + 0.12), (s * 0.45, z - 0.08), (s * 0.10, z - 0.10)], NEGRO)
        L.poligono([(s * 0.11, z + 0.0), (s * 0.38, z + 0.06), (s * 0.37, z - alto + 0.02), (s * 0.14, z - 0.04)],
                   "ojo", 1.0)
        L.ovalo(s * 0.25, z, 0.04, 0.02, (255, 250, 210), 1.0)


def cara_a(L):
    from traje_v2_grietas import grietas

    grietas(L, semilla=11, celda=0.42, roca=(46, 39, 42))
    ojos_fuego(L, 4.70)
    L.poligono([(-0.07, 4.56), (0.07, 4.56), (0, 4.44)], NEGRO)  # nariz
    L.caja(-0.40, 4.24, 0.40, 4.44, NEGRO)  # boca encendida entre los colmillos
    L.caja(-0.36, 4.27, 0.36, 4.41, "lava", 1.0)
    L.caja(-0.30, 4.31, 0.30, 4.37, "lava_clara", 1.0)
    for s in (-1, 1):
        L.trazo([(s * 0.48, 4.62), (s * 0.56, 4.48), (s * 0.52, 4.32)], 0.025, "lava", 1.0)


def cara_b(L):
    L.fondo("hierro")
    for i in range(-5, 6):  # remaches y placas grabadas
        L.ovalo(i * 0.11, 5.0, 0.018, 0.018, "roca_clara")
    for s in (-1, 1):
        for k in range(3):  # ranuras de los ojos (verticales, en abanico)
            x = s * (0.14 + k * 0.1)
            L.poligono([(x - 0.025, 4.62), (x + 0.025, 4.62), (x + 0.02 * s, 4.86), (x - 0.03 + 0.02 * s, 4.86)], NEGRO)
            L.poligono([(x - 0.012, 4.65), (x + 0.012, 4.65), (x + 0.02 * s, 4.83), (x + 0.02 * s - 0.02, 4.83)],
                       "ojo", 1.0)
        L.trazo([(s * 0.05, 4.95), (s * 0.5, 4.88)], 0.03, "roca_oscura")
    L.caja(-0.34, 4.18, 0.34, 4.46, NEGRO)  # rejilla de la boca
    for k in range(7):
        x = -0.30 + k * 0.1
        L.caja(x - 0.02, 4.21, x + 0.02, 4.43, "lava", 1.0)


def cara_c(L):
    from traje_v2_grietas import magma

    magma(L, semilla=21, celda=0.2)
    # Media máscara de obsidiana (la pieza "mascara" usa esta misma región de 4.66 a 5.02).
    L.poligono([(-0.9, 4.64), (-0.3, 4.64), (-0.12, 4.58), (0, 4.62), (0.12, 4.58), (0.3, 4.64), (0.9, 4.64),
                (0.9, 5.3), (-0.9, 5.3)], (34, 28, 31))
    for s in (-1, 1):  # ojos que dejan ver la lava de adentro
        L.poligono([(s * 0.08, 4.80), (s * 0.42, 4.90), (s * 0.44, 4.74), (s * 0.12, 4.72)], NEGRO)
        L.poligono([(s * 0.13, 4.79), (s * 0.38, 4.86), (s * 0.38, 4.77), (s * 0.15, 4.75)], (255, 250, 210), 1.0)
        L.trazo([(s * 0.5, 4.98), (s * 0.62, 4.86), (s * 0.58, 4.72)], 0.02, "lava", 1.0)
    boca = [(-0.36, 4.42), (-0.2, 4.47), (0, 4.45), (0.2, 4.47), (0.36, 4.42), (0.26, 4.18), (0, 4.12), (-0.26, 4.18)]
    L.poligono(boca, (110, 20, 5), 0.5)
    L.poligono([(x * 0.8, 4.30 + (z - 4.30) * 0.75) for x, z in boca], (255, 250, 220), 1.0)
    for i in range(6):
        x = -0.25 + i * 0.1
        L.poligono([(x - 0.035, 4.46), (x + 0.035, 4.46), (x, 4.36)], (40, 32, 34))


DIBUJO = {"a": cara_a, "b": cara_b, "c": cara_c}[VARIANTE]
