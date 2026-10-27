r"""
Base del hábitat completo de la Orca fantasma (lo usan habitat_orcafantasma*.py): el fondo
del cuenco, la ubicación en el cráter, copiar props a la escena, el suelo propio de la repisa,
las rocas, las algas, el musgo y las almas.

Coordenadas de Blender con el origen en el centro del cráter: Z = Y del mundo (absoluta);
un ángulo `a` de Config.Habitats queda en (r·cos a, -r·sin a).
"""
import math
import bmesh
from mathutils import Matrix, Vector as V, noise
import habitats as H
from habitats import T

# ---- el fondo del cuenco (contrato: WorldZones.lakeFloor) ------------------------------


def piso(r):
    r = abs(r)
    if r < 75:
        return -150.0
    if r < 150:
        t = (r - 75) / 75
        return -150 + 142 * (1 - math.cos(math.pi * t)) / 2
    if r < 190:
        return -8 + 7 * (r - 150) / 40
    if r < 205:
        return -1 + 31 * ((r - 190) / 15) ** 0.6
    return 30.0


def piso_en(p):
    return piso(math.hypot(p.x, p.y))


def radio_acantilado(z):
    """Radio de la pared del acantilado a la altura z (inversa del tramo 190-205)."""
    z = max(-1.0, min(30.0, z))
    return 190 + 15 * ((z + 1) / 31) ** (1 / 0.6)


def polar(ang, r, z=0.0):
    a = math.radians(ang)
    return V((r * math.cos(a), -r * math.sin(a), z))


def ejes(ang):
    """X hacia afuera (radial), Y tangente (X × Y = Z), Z arriba."""
    a = math.radians(ang)
    return V((math.cos(a), -math.sin(a), 0)), V((math.sin(a), math.cos(a), 0)), V((0, 0, 1))


def marco(ang, r, z, escala=1.0, giro=0.0):
    """Matriz de un prop en (ang, r, z): su +Y mira hacia afuera (a los jugadores del paseo,
    como HabitatService) y `giro` grados extra alrededor de Z."""
    x, y, zz = ejes(ang)
    m = Matrix((-y, x, zz)).transposed().to_4x4()
    m.translation = polar(ang, r, z)
    return m @ Matrix.Rotation(math.radians(giro), 4, "Z") @ Matrix.Scale(escala, 4)


def tope_nado(r):
    """Hasta dónde puede subir una pieza común: la cría nada en la superficie hasta r ≈ 175,
    así que entre r 150 y 182 lo común queda bajo el agua (Y < -0.5)."""
    return -0.5 if 148 <= r <= 182 else 99.0


# ---- copiar geometría ------------------------------------------------------------------


def volcar(dst, src, M, apoyar=True):
    """Copia la geometría de `src` (Malla) en `dst` con la matriz M. `apoyar` corta lo que
    queda bajo z = 0 local, como Malla.objeto(piso=True) al exportar el prop suelto."""
    mapa = {}
    for v in src.bm.verts:
        p = v.co.copy()
        if apoyar:
            p.z = max(p.z, 0.0)
        mapa[v] = dst.bm.verts.new(M @ p)
    for f in src.bm.faces:
        try:
            nf = dst.bm.faces.new([mapa[v] for v in f.verts])
        except ValueError:
            continue
        for l_s, l_d in zip(f.loops, nf.loops):
            l_d[dst.uv].uv = l_s[src.uv].uv
        nf[dst.liso] = f[src.liso]
    src.bm.free()


def recortar(malla, quedar_y_mayor, y_corte):
    """Corta la malla por el plano y = y_corte y se queda con un lado (el barco partido)."""
    bm = malla.bm
    no = V((0, -1, 0)) if quedar_y_mayor else V((0, 1, 0))
    geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
    bmesh.ops.bisect_plane(bm, geom=geom, plane_co=V((0, y_corte, 0)), plane_no=no, clear_outer=True)


def abierta(m, vs, color):
    """Cara de una lámina abierta (suelo, redes), con la normal hacia arriba. Se marca para
    que el armado no le recalcule la normal."""
    capa = m.bm.faces.layers.int.get("abierta") or m.bm.faces.layers.int.new("abierta")
    f = m.cara(vs, color)
    f.normal_update()
    if f.normal.z < 0:
        f.normal_flip()
    f[capa] = 1
    return f


# ---- suelo propio de la repisa y la ladera ---------------------------------------------

LODOS = ("lodo", "lodo2", "arenaosc", "lodo", "arenaosc2")


def suelo(m, radios, lados=160):
    """Lámina de arena oscura y lodo pegada al fondo (r 128 a 190), con lomas suaves y
    manchas de color, para que no quede fondo desnudo entre los grupos."""
    anillos = []
    for i, r in enumerate(radios):
        borde = i in (0, len(radios) - 1)
        anillo = []
        for k in range(lados):
            th = 2 * math.pi * k / lados
            x, y = r * math.cos(th), r * math.sin(th)
            loma = 0.0 if borde else 0.7 + 0.9 * noise.noise(V((x / 22, y / 22, 0.3)))
            anillo.append(m.v(V((x, y, piso(r) + 0.15 + max(0.0, loma)))))
        anillos.append(anillo)
    for i in range(len(anillos) - 1):
        a, b = anillos[i], anillos[i + 1]
        for k in range(lados):
            k2 = (k + 1) % lados
            c = (a[k].co + b[k2].co) / 2
            n = noise.noise(V((c.x / 30, c.y / 30, 4.0)))
            color = LODOS[int((n + 1) * 2.49) % len(LODOS)]
            abierta(m, (a[k], b[k], b[k2], a[k2]), color)


# ---- rocas, algas, musgo y almas -------------------------------------------------------


def roca(m, ang, r, radio, rnd, color=None):
    escala = (rnd.uniform(0.9, 1.3), rnd.uniform(0.9, 1.3), rnd.uniform(0.5, 0.75))
    # En el acantilado se apoya en el lado de abajo y queda medio metida en la pared; nunca
    # pasa de Y = 30; en la franja del nado queda bajo el agua.
    z = min(piso(r), piso(r - radio) + radio * 0.35, 29.0 - radio * escala[2] * 1.3,
            tope_nado(r) - radio * escala[2] * 1.3)
    z = max(z, piso(r) - radio * escala[2] * 0.9)  # nunca enterrada del todo
    m.roca(T(*polar(ang, r, z)) @ H.girar("Z", rnd.uniform(0, 6.28)), radio,
           color or rnd.choice(("rocaf", "rocaf2", "rocaf", "rocaf3")), 1, 0.3, rnd.uniform(0, 9), escala)


def alga(m, ang, r, rnd, tope=None):
    """Alga pálida: sube del fondo ondulando; en la ladera llega a la superficie y se tiende."""
    base = polar(ang, r, piso(r) - 0.8)
    tope = min(tope if tope is not None else rnd.uniform(-1.5, 1.5), tope_nado(r) - 0.3)
    largo = tope - base.z
    if largo < 2:
        return
    n = 8
    fase, dx = rnd.uniform(0, 6.28), rnd.uniform(1.5, 3.5)
    lado = V((rnd.uniform(-1, 1), rnd.uniform(-1, 1), 0)).normalized()
    pts = []
    for j in range(n):
        s = j / (n - 1)
        p = base + V((0, 0, largo * s)) + lado * math.sin(fase + s * 5) * dx * s
        if j == n - 1:
            p += lado * rnd.uniform(3, 6)
            p.z -= 0.6
        if p.xy.length < 126:  # no entra al santuario (r < 124)
            p.xy = p.xy.normalized() * 126
        pts.append(p)
    grueso = rnd.uniform(1.0, 1.6) * (1.3 if largo > 15 else 1.0)
    m.tubo(pts, [grueso * (1 - 0.6 * j / (n - 1)) for j in range(n)], 4,
           rnd.choice(("algapalida", "algapalida2", "algapalida")))


def musgo(m, ang, rnd):
    """Una tira de musgo pálido que cuelga del borde del acantilado, pegada a la pared."""
    z0, z1 = 27.0, rnd.uniform(3.0, 12.0)
    pts = []
    for j in range(7):
        z = z0 + (z1 - z0) * j / 6
        pts.append(polar(ang + rnd.uniform(-0.25, 0.25), radio_acantilado(z) - 0.9 - 0.3 * math.sin(j), z))
    m.tubo(pts, [0.9, 1.1, 1.0, 0.9, 0.75, 0.55, 0.35], 4, rnd.choice(("musgopalido", "algapalida2")))


def alma(b, centro, tam, rnd):
    """Un alma que flota: gota alargada con una cola que se enrosca hacia abajo."""
    b.esfera(T(*centro), tam, "fantasma", 1, 0.15, rnd.uniform(0, 9), escala=(1, 1, 1.35))
    lado = V((rnd.uniform(-1, 1), rnd.uniform(-1, 1), 0)).normalized()
    pts = [centro - V((0, 0, tam * 0.9))]
    for j in range(1, 5):
        pts.append(centro - V((0, 0, tam * (0.9 + 0.9 * j))) + lado * math.sin(j * 1.3) * tam * 0.6)
    b.tubo(pts, [tam * 0.7, tam * 0.5, tam * 0.35, tam * 0.2, tam * 0.08], 5, "fantasma")


def columna_almas(b, ang, r, z0, z1, n, rnd):
    """Almas que suben en espiral como una columna, más chicas cuanto más arriba."""
    fase = rnd.uniform(0, 6.28)
    for j in range(n):
        s = j / max(1, n - 1)
        a = fase + s * 4.2
        c = polar(ang, r, z0 + (z1 - z0) * s) + V((math.cos(a), math.sin(a), 0)) * (2.5 + 2.0 * s)
        alma(b, c, 2.4 - 1.1 * s + rnd.uniform(-0.2, 0.2), rnd)
