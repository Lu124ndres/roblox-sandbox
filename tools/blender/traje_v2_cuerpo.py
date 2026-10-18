"""
Arma la malla de un traje v2 en un bmesh a partir de su ficha (traje_v2_<clave>.py): torso,
cabeza, sombrero, brazos y piernas como tubos de anillos (traje_v2_tubos.py), unidos con
puentes cortos justo donde gira cada parte (cuello, hombros, caderas y sombrero). Los
accesorios (corona, capa, cuernos, tridente...) son tubos cerrados aparte, metidos un poco en
la parte que los lleva y pegados a un hueso, así nunca se separan. Después pinta: cada cara
toma su color o su dibujo según ficha.color (ver traje_v2_regiones.py).
"""
import math
import bmesh
import traje_v2_base as B
import traje_v2_regiones as R
from traje_v2_tubos import Tubo, puente

PUENTES = ("cuello", "hombro", "cadera", "union_sombrero")


def indice(anillos, z):
    return min(range(len(anillos)), key=lambda a: abs(anillos[a][0] - z))


class Armado:
    """La malla en construcción y el nombre de la parte de cada cara (capa entera "parte")."""

    def __init__(self, bm):
        self.bm = bm
        self.etiqueta = bm.faces.layers.int.new("parte")
        self.nombres = []
        self.accesorios = {}

    def id(self, nombre):
        if nombre not in self.nombres:
            self.nombres.append(nombre)
        return self.nombres.index(nombre)

    def tubo(self, nombre, anillos, fx, fy, k, matriz=None):
        return Tubo(self.bm, nombre, anillos, fx, fy, k, self.etiqueta, self.id(nombre), matriz)

    def puente(self, caras_a, caras_b, nombre):
        puente(self.bm, caras_a, caras_b, self.etiqueta, self.id(nombre))

    def parte(self, cara):
        return self.nombres[cara[self.etiqueta]]


def armar(bm, ficha):
    A = Armado(bm)
    torso = A.tubo("torso", B.anillos(ficha.TORSO), B.TORSO_FX, B.TORSO_FY, ficha.TORSO["k"])
    cabeza = A.tubo("cabeza", B.anillos(ficha.CABEZA), B.CABEZA_FX, B.CABEZA_FY, ficha.CABEZA["k"])
    sombrero = getattr(ficha, "SOMBRERO", None)
    if sombrero:
        s = A.tubo("sombrero", B.anillos(sombrero), B.SOMBRERO_FX, B.SOMBRERO_FY, sombrero["k"])
    A.puente(torso.celdas("arriba", 3, 4, 1, 5), cabeza.celdas("abajo", 1, 2, 1, 5), "cuello")
    if sombrero:
        A.puente(cabeza.celdas("arriba", 1, 2, 1, 5), s.celdas("abajo", 1, 2, 1, 5), "union_sombrero")
    ta = B.anillos(ficha.TORSO)
    z0, z1 = B.PUENTE_HOMBRO
    for s, lado in ((1, "Izq"), (-1, "Der")):
        an = B.anillos(ficha.BRAZO, s * B.BRAZO_CX)
        brazo = A.tubo("brazo_" + lado, an, B.BRAZO_FX, B.BRAZO_FY, ficha.BRAZO["k"])
        dentro, fuera = ("izq", "der") if s == 1 else ("der", "izq")
        A.puente(torso.lado(indice(ta, z0), indice(ta, z1), fuera, 2, 4),
                 brazo.lado(indice(an, z0), indice(an, z1), dentro, 1, 3), "hombro")
        pierna = A.tubo("pierna_" + lado, B.anillos(ficha.PIERNA, s * B.PIERNA_CX), B.PIERNA_FX,
                        B.PIERNA_FY, ficha.PIERNA["k"])
        i0 = 5 if s == 1 else 1
        A.puente(torso.celdas("abajo", i0, i0 + 1, 2, 4), pierna.celdas("arriba", 1, 2, 1, 3), "cadera")
    for acc in ficha.accesorios():
        nombre = "acc_" + acc["nombre"]
        A.tubo(nombre, acc["anillos"], acc.get("fx", [-1, 1]), acc.get("fy", [-1, 1]), acc.get("k", 2),
               acc.get("matriz"))
        A.accesorios[nombre] = acc
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    return A


def color_de(A, ficha, parte, c, n):
    """(tipo, valor) de una cara: el color del accesorio (un nombre de la paleta o una función
    como ficha.color) o, si no tiene, ficha.color(parte, centro, normal)."""
    propio = A.accesorios.get(parte, {}).get("color")
    if propio is None:
        return ficha.color(parte, c, n)
    if isinstance(propio, str):
        return "paleta", propio
    return propio if isinstance(propio, tuple) else propio(c, n)


def pintar(A, ficha):
    """UV de cada esquina de cara según su color (ver color_de)."""
    bm = A.bm
    uv = bm.loops.layers.uv.verify()
    for f in bm.faces:
        tipo, valor = color_de(A, ficha, A.parte(f), f.calc_center_median(), f.normal)
        for l in f.loops:
            co = l.vert.co
            if tipo == "region":
                l[uv].uv = R.uv_region(ficha, valor, co.x, co.z)
            elif tipo == "caja":
                l[uv].uv = R.uv_caja(ficha, valor, co, f.normal)
            else:
                l[uv].uv = R.uv_paleta(ficha, valor)
    # Sombreado: liso en las esquinas redondeadas, marcado en los cantos de 90 grados.
    for f in bm.faces:
        f.smooth = True
    for e in bm.edges:
        if len(e.link_faces) == 2 and e.calc_face_angle(0) > math.radians(50):
            e.smooth = False


def parte_de_vertice(A):
    """La parte de cada vértice (la de sus caras que no son puente)."""
    out = {}
    for v in A.bm.verts:
        partes = sorted({f[A.etiqueta] for f in v.link_faces})
        nombres = [A.nombres[i] for i in partes if A.nombres[i] not in PUENTES]
        out[v.index] = nombres[0] if nombres else "torso"
    return out


def pesos(A, parte, co):
    acc = A.accesorios.get(parte)
    if acc is None:
        return B.pesos_cuerpo(parte, co)
    if "pesos" in acc:
        return acc["pesos"](co)
    return {acc["hueso"]: 1.0}
