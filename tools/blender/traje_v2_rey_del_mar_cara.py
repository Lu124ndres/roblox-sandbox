"""
Caras del Rey del Mar v2. Se elige con la variable de entorno TRAJE_CARA (a, b o c):
  a  Rey sabio: ojos con iris de agua que brilla, cejas, nariz y bigote en relieve, barba
     con dos trenzas de anillos de oro;
  b  Yelmo cerrado: visera de oro y turquesa con la ranura en T que brilla;
  c  Rey joven: sin barba, cejas castañas, sonrisa y marcas de agua que brillan.
Cada una trae sus piezas (Blender), su dibujo de la cara (PIL) y el color de los costados.
"""
import math
import os

VARIANTE = os.environ.get("TRAJE_CARA", "b")  # elegida por el usuario: Yelmo cerrado
BLANCO, NEGRO = (255, 255, 255), (20, 24, 34)


def color_cabeza(c, n):
    if n.y < -0.6 and abs(n.z) < 0.75:
        return "region", "cara"
    if n.z < -0.6:
        return "paleta", "piel"
    if VARIANTE == "a" and n.y < 0.2 and c.z < 4.45:
        return "paleta", "barba"
    return ("paleta", "oro") if 4.92 < c.z < 4.97 else ("caja", "armadura")


def piezas():
    from mathutils import Matrix
    from traje_v2_formas import pieza, placa, pua

    out = []
    if VARIANTE in ("a", "c"):
        ceja = "barba" if VARIANTE == "a" else "pelo"
        for s in (1, -1):
            m = Matrix.Translation((s * 0.21, -0.60, 4.88)) @ Matrix.Rotation(math.radians(-s * 14), 4, "Y")
            out.append(pieza(f"ceja{s}", placa(-0.035, 0.035, 0, 0, 0.30, 0.08), "Cabeza", ceja, matriz=m))
        out.append(pieza("nariz", [(4.50, 0, -0.62, 0.17, 0.11, 0.05), (4.56, 0, -0.635, 0.16, 0.12, 0.05),
                                   (4.70, 0, -0.60, 0.09, 0.06, 0.025)], "Cabeza", "piel"))
    if VARIANTE == "a":
        for s in (1, -1):
            an, m = pua((s * 0.04, -0.64, 4.45), (s, -0.15, -0.5), 0.36, 0.13, 0.2, 3, 0.6)
            out.append(pieza(f"bigote{s}", an, "Cabeza", "barba", matriz=m))
            trenza = []
            for i in range(6):  # trenza: anillos que se ensanchan y angostan
                z = 3.78 - i * 0.08
                ancho = 0.13 if i % 2 == 0 else 0.10
                trenza.append((z, s * 0.24, -0.66, ancho, ancho, ancho * 0.4))
            out.append(pieza(f"trenza{s}", list(reversed(trenza)), "Cabeza", "barba_sombra"))
            out.append(pieza(f"anillo_trenza{s}", [(3.50, s * 0.24, -0.66, 0.15, 0.15, 0.06),
                                                   (3.58, s * 0.24, -0.66, 0.15, 0.15, 0.06)], "Cabeza", "oro"))
        out.append(pieza("barba", [(3.70, 0, -0.50, 0.46, 0.20, 0.06), (3.86, 0, -0.52, 0.78, 0.28, 0.08),
                                   (4.02, 0, -0.54, 0.96, 0.32, 0.09), (4.22, 0, -0.54, 1.02, 0.32, 0.09),
                                   (4.42, 0, -0.50, 1.02, 0.30, 0.09)], "Cabeza",
                         lambda c, n: ("paleta", "barba_sombra" if c.z < 3.86 else "barba")))
    if VARIANTE == "b":
        def visera(c, n):
            return ("region", "cara") if n.y < -0.6 else ("paleta", "oro")

        out += [pieza("visera", placa(4.10, 4.97, 0, -0.60, 1.30, 0.12), "Cabeza", visera),
                pieza("nasal", placa(4.30, 4.95, 0, -0.665, 0.10, 0.06), "Cabeza", "oro")]
        for s in (1, -1):
            an, m = pua((s * 0.64, -0.40, 4.30), (s * 0.6, 0.5, 0.35), 0.42, 0.16, 0.1, 3, 0.4)
            out.append(pieza(f"pua_mejilla{s}", an, "Cabeza", "oro", matriz=m))
    return out


def espejo(pts):
    return [(-x, z) for x, z in reversed(pts)]


def casco(L):
    """Marco del casco abierto: frente con gema y carrilleras con filo de oro."""
    L.caja(-0.9, 4.95, 0.9, 5.4, "mar")
    L.caja(-0.9, 4.92, 0.9, 4.97, "oro")
    L.poligono([(0, 5.13), (0.09, 5.05), (0, 4.97), (-0.09, 5.05)], "oro")
    L.poligono([(0, 5.10), (0.055, 5.05), (0, 5.0), (-0.055, 5.05)], "gema", 1.0)
    for s in (-1, 1):
        L.poligono([(s * 0.9, 4.45), (s * 0.5, 4.45), (s * 0.45, 4.62), (s * 0.47, 4.95), (s * 0.9, 4.95)], "mar")
        L.trazo([(s * 0.5, 4.47), (s * 0.45, 4.62), (s * 0.47, 4.93)], 0.03, "oro")


def ojo(L, x, z, iris, brillo_iris=1.0, grande=1.0):
    g = grande
    L.poligono([(x - 0.11 * g, z), (x - 0.05 * g, z + 0.05 * g), (x + 0.06 * g, z + 0.05 * g),
                (x + 0.11 * g, z + 0.005), (x + 0.05 * g, z - 0.04 * g), (x - 0.06 * g, z - 0.04 * g)], BLANCO)
    L.ovalo(x, z + 0.004, 0.048 * g, 0.048 * g, iris, brillo_iris)
    L.ovalo(x, z + 0.004, 0.022 * g, 0.022 * g, NEGRO)
    L.ovalo(x - 0.018 * g, z + 0.022 * g, 0.012 * g, 0.012 * g, BLANCO, 1.0)
    L.trazo([(x - 0.12 * g, z - 0.005), (x - 0.05 * g, z + 0.055 * g), (x + 0.06 * g, z + 0.055 * g),
             (x + 0.12 * g, z + 0.005)], 0.018, NEGRO)


def cara_a(L):
    L.fondo("piel")
    casco(L)
    barba = [(-0.9, 3.9), (-0.9, 4.45), (-0.47, 4.45), (-0.40, 4.40), (-0.28, 4.39), (-0.16, 4.43)]
    L.poligono(barba + espejo(barba), "barba")
    for s in (-1, 1):
        for i in range(4):
            L.trazo([(s * (0.2 + i * 0.1), 4.40), (s * (0.24 + i * 0.1), 4.22)], 0.016, "barba_sombra")
        ojo(L, s * 0.21, 4.73, "ojo")
        L.trazo([(s * 0.36, 4.70), (s * 0.42, 4.67)], 0.012, "piel_sombra")  # patas de gallo
        L.trazo([(s * 0.36, 4.74), (s * 0.43, 4.75)], 0.012, "piel_sombra")
        L.ovalo(s * 0.30, 4.55, 0.07, 0.04, (236, 170, 150))  # mejillas
    L.trazo([(-0.12, 4.92), (0.12, 4.92)], 0.012, "piel_sombra")


def cara_b(L):
    L.fondo("mar")
    for s in (-1, 1):  # filigrana dorada del yelmo
        L.trazo([(s * 0.08, 5.1), (s * 0.3, 5.0), (s * 0.55, 5.08)], 0.025, "oro")
        L.trazo([(s * 0.12, 4.35), (s * 0.35, 4.2), (s * 0.58, 4.32)], 0.025, "oro")
        for i in range(3):
            L.ovalo(s * (0.22 + i * 0.1), 4.42 - i * 0.03, 0.022, 0.022, NEGRO)  # respiraderos
    L.caja(-0.9, 4.95, 0.9, 5.0, "oro")
    L.caja(-0.48, 4.68, 0.48, 4.80, NEGRO)  # ranura en T
    L.caja(-0.05, 4.38, 0.05, 4.80, NEGRO)
    L.caja(-0.44, 4.705, 0.44, 4.775, "gema", 1.0)
    L.caja(-0.025, 4.42, 0.025, 4.76, "gema", 1.0)
    L.caja(-0.9, 4.05, 0.9, 4.13, "oro")


def cara_c(L):
    L.fondo("piel")
    casco(L)
    for s in (-1, 1):
        ojo(L, s * 0.21, 4.72, "ojo", grande=1.15)
        for i in range(3):  # marcas de agua que brillan
            L.trazo([(s * (0.18 + i * 0.07), 4.60), (s * (0.21 + i * 0.07), 4.52)], 0.022, "gema", 1.0)
        L.ovalo(s * 0.32, 4.53, 0.07, 0.035, (240, 168, 150))
    sonrisa = [(0.03 + 0.14 * t / 10, 4.33 + 0.05 * (t / 10) ** 2 - 0.01) for t in range(-10, 11)]
    L.trazo(sonrisa, 0.025, "boca")
    L.trazo([(-0.05, 4.47), (0.04, 4.46)], 0.015, "piel_sombra")


DIBUJO = {"a": cara_a, "b": cara_b, "c": cara_c}[VARIANTE]
