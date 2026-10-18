"""
Arma la malla del Marinero v2 en un bmesh: torso, cabeza, gorra, brazos y piernas como tubos
de anillos (marinero_v2_tubos.py), unidos con puentes cortos justo donde gira cada parte
(cuello, hombros, caderas y gorra). Después pinta: cada cara toma un color plano de la paleta,
salvo la cara, el pecho y la espalda, que van a sus regiones dibujadas con proyección plana.
"""
import math
import bmesh
import marinero_v2_datos as D
from marinero_v2_tubos import Tubo, puente

TORSO, CABEZA, GORRA, BRAZO_I, BRAZO_D, PIERNA_I, PIERNA_D = range(7)
CUELLO, HOMBRO, CADERA, SOMBRERO = range(7, 11)
PUENTES = {CUELLO, HOMBRO, CADERA, SOMBRERO}
COLOR_PUENTE = {CUELLO: "piel", HOMBRO: "blanco", CADERA: "pantalon", SOMBRERO: "barba"}


def anillos_bloque(p, cx):
    return [(z, cx, 0.0, p["w"] - 2 * e, p["d"] - 2 * e, p["r"] - e) for z, e in p["anillos"]]


def anillos_pierna(cx):
    out = []
    for z, e, tramo in D.PIERNA["anillos"]:
        w, d, cy, r = D.TRAMOS_PIERNA[tramo]
        out.append((z, cx, cy, w - 2 * e, d - 2 * e, r - e))
    return out


def indice(anillos, z):
    return min(range(len(anillos)), key=lambda a: abs(anillos[a][0] - z))


def armar(bm, etiqueta):
    def tubo(nombre, anillos, p, valor):
        t = Tubo(bm, nombre, anillos, p["fx"], p["fy"], p["k"], etiqueta)
        for f in t.caras.values():
            f[etiqueta] = valor
        return t

    torso = tubo("torso", anillos_bloque(D.TORSO, 0.0), D.TORSO, TORSO)
    cabeza = tubo("cabeza", anillos_bloque(D.CABEZA, 0.0), D.CABEZA, CABEZA)
    gorra = tubo("gorra", [(z, 0.0, 0.0, w, d, r) for z, w, d, r in D.GORRA["anillos"]], D.GORRA, GORRA)
    puente(bm, torso.celdas("arriba", 3, 4, 1, 5), cabeza.celdas("abajo", 1, 2, 1, 5), etiqueta, CUELLO)
    puente(bm, cabeza.celdas("arriba", 1, 2, 1, 5), gorra.celdas("abajo", 1, 2, 1, 5), etiqueta, SOMBRERO)
    ta = [a[:1] for a in anillos_bloque(D.TORSO, 0.0)]
    for s, brazo_v, pierna_v in ((1, BRAZO_I, PIERNA_I), (-1, BRAZO_D, PIERNA_D)):
        an = anillos_bloque(D.BRAZO, s * D.BRAZO["cx"])
        brazo = tubo("brazo", an, D.BRAZO, brazo_v)
        ba = [a[:1] for a in an]
        dentro, fuera = ("izq", "der") if s == 1 else ("der", "izq")
        z0, z1 = D.PUENTE_HOMBRO
        puente(bm, torso.lado(indice(ta, z0), indice(ta, z1), fuera, 2, 4),
               brazo.lado(indice(ba, z0), indice(ba, z1), dentro, 1, 3), etiqueta, HOMBRO)
        pierna = tubo("pierna", anillos_pierna(s * D.PIERNA["cx"]), D.PIERNA, pierna_v)
        i0 = 5 if s == 1 else 1
        puente(bm, torso.celdas("abajo", i0, i0 + 1, 2, 4), pierna.celdas("arriba", 1, 2, 1, 3),
               etiqueta, CADERA)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])


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


def color_brazo(c, n):
    if n.z > 0.6:
        return "blanco"
    if c.z < D.FRANJAS_MANGA[0]:
        return "piel"
    banda = int((c.z - D.FRANJAS_MANGA[0]) / (D.FRANJAS_MANGA[1] - D.FRANJAS_MANGA[0]))
    return "blanco" if banda % 2 == 0 else "raya"


def color_pierna(c, n):
    if c.z <= 0.081:
        return "suela"
    if c.z <= 0.551:
        return "bota"
    return "pantalon"


def color_torso(c, n):
    if n.z > 0.6:
        return "marino"
    if n.z < -0.6 or c.z < 2.18:
        return "pantalon"
    return "cinturon" if c.z < 2.30 else "marino"


def pintar(bm, etiqueta):
    """UV de cada esquina de cara: región dibujada (planar) o celda de la paleta."""
    uv = bm.loops.layers.uv.verify()
    for f in bm.faces:
        parte, c, n = f[etiqueta], f.calc_center_median(), f.normal
        region = None
        if parte == TORSO and n.y < -0.6 and abs(n.z) < 0.75:
            region = "pecho"
        elif parte == TORSO and n.y > 0.6 and abs(n.z) < 0.75:
            region = "espalda"
        elif parte == CABEZA and n.y < -0.6 and abs(n.z) < 0.75:
            region = "cara"
        if region:
            for l in f.loops:
                l[uv].uv = D.uv_region(region, l.vert.co.x, l.vert.co.z)
            continue
        if parte in PUENTES:
            color = COLOR_PUENTE[parte]
        elif parte == TORSO:
            color = color_torso(c, n)
        elif parte == CABEZA:
            color = color_cabeza(c, n)
        elif parte == GORRA:
            color = "marino" if c.z < 5.305 else "gorra"
        elif parte in (BRAZO_I, BRAZO_D):
            color = color_brazo(c, n)
        else:
            color = color_pierna(c, n)
        for l in f.loops:
            l[uv].uv = D.uv_paleta(color)
    # Sombreado: liso en las esquinas redondeadas, marcado en los cantos de 90 grados.
    for f in bm.faces:
        f.smooth = True
    for e in bm.edges:
        if len(e.link_faces) == 2 and e.calc_face_angle(0) > math.radians(50):
            e.smooth = False


def parte_de_vertice(bm, etiqueta):
    """La parte de cada vértice (la de sus caras que no son puente)."""
    out = {}
    for v in bm.verts:
        partes = {f[etiqueta] for f in v.link_faces} - PUENTES
        out[v.index] = min(partes) if partes else TORSO
    return out
