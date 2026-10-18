"""
Tubos de anillos para el Marinero v2 (y cualquier personaje de bloques): cada parte es una
pila de rectángulos de esquinas redondeadas unidos por quads, con tapas en cuadrícula, y las
partes se unen con puentes cortos (se borran las caras de un rectángulo en cada parte y se
unen los dos bordes). Todo queda en una sola malla cerrada, sin piezas sueltas.

Un anillo es (z, cx, cy, ancho, fondo, radio). Las líneas rectas salen de fx y fy (fracciones
de medio lado recto), así que dos anillos con el mismo "ancho - 2 radio" tienen los mismos
puntos rectos y la tapa no cambia de cuadrícula (eso permite chaflanes sin mover las líneas).
"""
import math
import bmesh
from mathutils import Vector as V


def puntos_anillo(z, cx, cy, w, d, r, fx, fy, k):
    """Puntos en orden alrededor (frente, esquina, derecha, esquina, atrás, ...) e índices de
    los puntos rectos: frente[i], atras[i], izq[j], der[j] y la esquina de cada lado."""
    sx, sy = w / 2 - r, d / 2 - r
    xs, ys = [cx + f * sx for f in fx], [cy + f * sy for f in fy]
    pts, idx = [], {"frente": [], "der": [], "atras": [], "izq": []}

    def arco(ccx, ccy, a0):
        for m in range(1, k):
            a = math.radians(a0 + 90 * m / k)
            pts.append(V((ccx + r * math.cos(a), ccy + r * math.sin(a), z)))

    for x in xs:
        idx["frente"].append(len(pts)); pts.append(V((x, cy - d / 2, z)))
    arco(xs[-1], ys[0], -90)
    for y in ys:
        idx["der"].append(len(pts)); pts.append(V((cx + w / 2, y, z)))
    arco(xs[-1], ys[-1], 0)
    for x in reversed(xs):
        idx["atras"].insert(0, len(pts)); pts.append(V((x, cy + d / 2, z)))
    arco(xs[0], ys[-1], 90)
    for y in reversed(ys):
        idx["izq"].insert(0, len(pts)); pts.append(V((cx - w / 2, y, z)))
    arco(xs[0], ys[0], 180)
    return pts, idx, xs, ys


class Tubo:
    """Una parte: anillos unidos y dos tapas. Guarda las caras para colorear y puentear."""

    def __init__(self, bm, nombre, anillos, fx, fy, k, etiqueta):
        self.bm, self.nombre = bm, nombre
        self.anillos, self.caras = [], {}
        for an in anillos:
            pts, idx, xs, ys = puntos_anillo(*an, fx, fy, k)
            verts = [bm.verts.new(p) for p in pts]
            self.anillos.append((verts, idx, xs, ys))
        # Lados: cara (anillo a, posición p) entre el anillo a y a+1.
        for a in range(len(self.anillos) - 1):
            va, vb = self.anillos[a][0], self.anillos[a + 1][0]
            n = len(va)
            for p in range(n):
                f = bm.faces.new((va[p], va[(p + 1) % n], vb[(p + 1) % n], vb[p]))
                self.caras[("lado", a, p)] = f
        self.tapa("abajo", 0, k)
        self.tapa("arriba", len(self.anillos) - 1, k)
        for f in self.caras.values():
            f[etiqueta] = 0  # se pone después con la parte

    def tapa(self, cual, a, k):
        bm = self.bm
        verts, idx, xs, ys = self.anillos[a]
        z = verts[0].co.z
        nodo = {(i, j): bm.verts.new((x, y, z)) for i, x in enumerate(xs) for j, y in enumerate(ys)}
        nx, ny = len(xs), len(ys)
        caras = {}
        for i in range(nx - 1):
            for j in range(ny - 1):
                caras[("celda", i, j)] = (nodo[i, j], nodo[i + 1, j], nodo[i + 1, j + 1], nodo[i, j + 1])
        f, b, l, r = idx["frente"], idx["atras"], idx["izq"], idx["der"]
        for i in range(nx - 1):
            caras[("frente", i)] = (verts[f[i]], verts[f[i + 1]], nodo[i + 1, 0], nodo[i, 0])
            caras[("atras", i)] = (nodo[i, ny - 1], nodo[i + 1, ny - 1], verts[b[i + 1]], verts[b[i]])
        for j in range(ny - 1):
            caras[("izq", j)] = (verts[l[j]], nodo[0, j], nodo[0, j + 1], verts[l[j + 1]])
            caras[("der", j)] = (nodo[nx - 1, j], verts[r[j]], verts[r[j + 1]], nodo[nx - 1, j + 1])
        # Esquinas: abanico de quads desde el centro del arco (k par).
        n = len(verts)
        for nombre, desde, nodo_c in (("e0", f[-1], (nx - 1, 0)), ("e1", r[-1], (nx - 1, ny - 1)),
                                      ("e2", b[0], (0, ny - 1)), ("e3", l[0], (0, 0))):
            arco = [verts[(desde + m) % n] for m in range(k + 1)]
            for m in range(0, k, 2):
                caras[(nombre, m)] = (nodo[nodo_c], arco[m], arco[m + 1], arco[m + 2])
        for clave, vs in caras.items():
            self.caras[(cual,) + clave] = bm.faces.new(vs)

    def celdas(self, cual, i0, i1, j0, j1):
        """Caras de la tapa entre las líneas i0..i1 (x) y j0..j1 (y)."""
        return [self.caras[(cual, "celda", i, j)] for i in range(i0, i1) for j in range(j0, j1)]

    def lado(self, a0, a1, cara, j0, j1):
        """Caras del lado 'izq' o 'der' entre los anillos a0..a1 y las líneas j0..j1 (y)."""
        out = []
        for a in range(a0, a1):
            idx = self.anillos[a][1][cara]
            for j in range(j0, j1):
                p0, p1 = idx[j], idx[j + 1]
                out.append(self.caras[("lado", a, min(p0, p1) if abs(p0 - p1) == 1 else max(p0, p1))])
        return out


def borde(caras):
    """Aristas del borde de un grupo de caras (las que tocan una sola cara del grupo)."""
    grupo = set(caras)
    return [e for f in caras for e in f.edges if sum(1 for g in e.link_faces if g in grupo) == 1]


def puente(bm, caras_a, caras_b, etiqueta, valor):
    """Borra dos grupos de caras y une sus bordes con un tubo corto. Devuelve las caras nuevas."""
    ea, eb = borde(caras_a), borde(caras_b)
    assert len(ea) == len(eb), f"puente con bordes distintos: {len(ea)} y {len(eb)}"
    interiores = {e for f in list(caras_a) + list(caras_b) for e in f.edges} - set(ea) - set(eb)
    bmesh.ops.delete(bm, geom=list(caras_a) + list(caras_b), context="FACES_ONLY")
    # Las aristas y vértices de adentro del rectángulo quedan sueltos: se borran.
    sueltos = {v for e in interiores for v in e.verts}
    bmesh.ops.delete(bm, geom=list(interiores), context="EDGES")
    bmesh.ops.delete(bm, geom=[v for v in sueltos if v.is_valid and not v.link_edges], context="VERTS")
    nuevas = bmesh.ops.bridge_loops(bm, edges=ea + eb)["faces"]
    for f in nuevas:
        f[etiqueta] = valor
    return nuevas
