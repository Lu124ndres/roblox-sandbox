r"""
Piezas del hábitat completo del Minotauro (las usa tools/blender/habitat_minotauro.py):
la arena del cráter (copia de src/client/Ambient/SandShape.luau), las coordenadas del cráter
en Blender y los generadores de cada pieza (muros del laberinto, columnas, obeliscos,
estatuas, zigurat, arco, labrys, dunas, losas y el mosaico del centro).

Convenciones: 1 unidad = 1 stud; Blender Z = Y del mundo (altura absoluta); un punto del
mundo relativo al centro del cráter (dx, y, dz) es en Blender (dx, -dz, y). Los ángulos son
los de Config.Habitats (grados desde +X del cráter, x = cos, z = sin).
Las piezas usan la Malla y la paleta de tools/blender/habitats.py.
"""
import json, math, os, random
from mathutils import Matrix, Vector

import habitats as H
import habitats_minotauro as HM
from habitats import T, girar

V = Vector
RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
with open(os.path.join(RAIZ, "src", "shared", "WorldLayoutData.json"), encoding="utf-8") as _f:
    _L = json.load(_f)
CX, CZ = float(_L["craterCenter"][0]), float(_L["craterCenter"][1])  # las ondas usan x, z absolutas
AGUA = float(_L["waterLevel"])  # la arena llega aquí (más dunas)

# Colores propios de esta escena, sumados a la paleta común (la textura es propia).
EXTRA = {
    "sillar": (178, 142, 104), "sillar2": (150, 116, 86), "sillar3": (200, 168, 128),
    "duna": (238, 206, 140),  # Terrain Sand del cráter (TerrainBuilder)
    "duna2": (222, 188, 124),
}
for _n, _c in EXTRA.items():
    if _n not in H.COLORES:
        H.COLORES[_n] = _c
        H.NOMBRES.append(_n)
PIEDRAS = ("sillar", "sillar", "sillar2", "sillar3")

# ---- la arena (copia de SandShape.luau) ------------------------------------------------------
BANK_START, BANK_WIDTH = 135.0, 55.0
WIND = (0.8, 0.6)
REACH = 200.0  # craterLakeRadius + 10: más afuera es acantilado
# Mesetas de arenisca: ángulo (grados), radio, radio de la roca, alto sobre la arena.
ROCAS = [(55, 182, 13, 9), (128, 184, 16, 12), (166, 180, 11, 7), (212, 183, 14, 10), (330, 184, 12, 8),
         (20, 184, 10, 6), (284, 186, 9, 6)]
SINK = 1.2  # studs que la base queda bajo la arena (como SandProps)


def suave(t):
    t = min(max(t, 0.0), 1.0)
    return t * t * (3 - 2 * t)


def arena(dx, dz):
    """Altura de la arena sola (sin rocas) en un punto del mundo relativo al centro del cráter."""
    x, z = CX + dx, CZ + dz
    r = math.hypot(dx, dz)
    ang = math.atan2(dz, dx)
    bank = suave((r - BANK_START) / BANK_WIDTH)
    along = x * WIND[0] + z * WIND[1]
    across = x * WIND[1] - z * WIND[0]
    ripple = 0.7 * math.sin(along * 0.22 + 1.6 * math.sin(across * 0.018))
    dune = 1.3 * (0.5 + 0.5 * math.sin(ang * 4 + r * 0.045 + 0.7)) * (0.5 + 0.5 * math.sin(ang * 9 - r * 0.02))
    drift = bank * (4.5 + 2.5 * math.sin(ang * 6 + 0.4) + 1.2 * math.sin(ang * 13))
    return AGUA + ripple * (1 - 0.6 * bank) + dune + drift


def arena_con_rocas(dx, dz):
    top = arena(dx, dz)
    roca = -math.inf
    x, z = CX + dx, CZ + dz
    for ang, radio, rr, alto in ROCAS:
        a = math.radians(ang)
        d = math.hypot(dx - math.cos(a) * radio, dz - math.sin(a) * radio) / rr
        if d < 1:
            wobble = 0.8 * math.sin(x * 0.4) * math.cos(z * 0.35)
            roca = max(roca, top + alto * math.sqrt(1 - d ** 4) + wobble)
    return roca if roca > top + 0.5 else top


def fondo(r):
    """Fondo de roca del cuenco (contrato; WorldZones.lakeFloor). Solo para el render."""
    if r < 75:
        return -150.0
    if r < 150:
        return -150 + 142 * (1 - math.cos(math.pi * (r - 75) / 75)) / 2
    if r < 190:
        return -8 + 7 * (r - 150) / 40
    if r < 205:
        return -1 + 31 * ((r - 190) / 15) ** 0.6
    return 30.0


# ---- coordenadas -------------------------------------------------------------------------
def pb(ang, r, z=0.0):
    """Ángulo del cráter y radio -> punto de Blender."""
    a = math.radians(ang)
    return V((r * math.cos(a), -r * math.sin(a), z))


def ejes(rumbo, inclinar=0.0):
    """Giro 4x4: X radial (hacia afuera) del ángulo `rumbo`, Y tangente, Z arriba.
    ejes(a + 90) lleva el +Y local hacia afuera (a los jugadores); ejes(a - 90), hacia el centro."""
    a = math.radians(rumbo)
    radial = V((math.cos(a), -math.sin(a), 0))
    tangente = V((math.sin(a), math.cos(a), 0))
    arriba = V((0, 0, 1))
    if inclinar:
        g = Matrix.Rotation(inclinar, 3, tangente)
        radial, arriba = g @ radial, g @ arriba
    return Matrix((radial, tangente, arriba)).transposed().to_4x4()


def escala(sx, sy, sz):
    return Matrix.Diagonal((sx, sy, sz, 1.0))


def radio_de(p):
    return math.hypot(p.x, p.y)


def angulo_de(p):
    return math.degrees(math.atan2(-p.y, p.x)) % 360


def arena_b(p):
    return arena(p.x, -p.y)


def suelo(p, radio):
    """La arena más baja entre el centro y 8 puntos alrededor (nada flota en una loma)."""
    bajo = arena_b(p)
    for k in range(8):
        a = math.pi * k / 4
        bajo = min(bajo, arena(p.x + math.cos(a) * radio, -(p.y + math.sin(a) * radio)))
    return bajo


def pegar(dest, src, M):
    """Copia la geometría de la Malla `src` (armada en su origen) a `dest` con la matriz M."""
    mapa = {v: dest.bm.verts.new(M @ v.co) for v in src.bm.verts}
    for f in src.bm.faces:
        try:
            nf = dest.bm.faces.new([mapa[v] for v in f.verts])
        except ValueError:
            continue
        for ls, ld in zip(f.loops, nf.loops):
            ld[dest.uv].uv = ls[src.uv].uv
        nf[dest.liso] = f[src.liso]
    src.bm.free()


def cerca_de(p, puntos, dist):
    return any((V((p.x, p.y, 0)) - V((q.x, q.y, 0))).length < dist for q in puntos)


# ---- muros del laberinto -----------------------------------------------------------------
HILADA = 4.0


def bloque_caido(m, r, q, grande=1.0):
    """Sillar caído en la arena, girado y medio enterrado."""
    tam = (r.uniform(4.0, 7.0) * grande, r.uniform(3.5, 6.0) * grande, r.uniform(2.6, 4.0) * grande)
    z = suelo(q, 2.5) - tam[2] * 0.3
    m.caja(T(q.x, q.y, z) @ girar("Z", r.uniform(0, 6.3)) @ girar("X", r.uniform(-0.35, 0.35))
           @ girar("Y", r.uniform(-0.3, 0.3)), tam, r.choice(PIEDRAS), bisel=0.25)


def muro(m, punto, rumbo, largo, alto, grueso=5.0, banda=False, semilla=0, caidas=2, contra=0,
         evitar=lambda p: False, escombro=None, rmin=128.0):
    """Muro de sillares grandes por una ruta: punto(s) da la posición (z = 0) a s studs del
    comienzo y rumbo(s) el ángulo de ejes() cuyo Y va a lo largo del muro (el +X es su cara de
    afuera). Alto casi parejo, con tramos caídos grandes (sus sillares quedan en la arena, en la
    Malla `escombro`), los extremos rotos en escalera y un remate arriba donde está sano.
    contra: lado de los contrafuertes (+1 cara +X, -1 cara -X, 0 sin). banda: franja roja con
    greca de oro en la cara +X."""
    r = random.Random(semilla)
    f1, f2 = r.uniform(0, 6.3), r.uniform(0, 6.3)
    huecos = [(r.uniform(0.18, 0.82) * largo, r.uniform(8, 15)) for _ in range(caidas)]
    escombro = escombro or m

    def hiladas(s):
        h = alto * (0.82 + 0.18 * math.sin(s * 0.09 + f1)) * (0.9 + 0.1 * math.sin(s * 0.037 + f2))
        for c, w in huecos:
            if abs(s - c) < w:
                h *= 0.08 + 0.92 * (abs(s - c) / w) ** 2
        h *= min(1.0, 0.3 + min(s, largo - s) / 14)
        return max(1, int(h / HILADA + 0.5))

    nmax = max(1, int(alto / HILADA + 0.5))
    for i in range(nmax):
        s = -r.uniform(0, 3.0) - (4.5 if i % 2 else 0)
        while s < largo:
            w = r.uniform(7.5, 10.5)
            s0, s1 = max(s, 0.0), min(s + w, largo)
            s += w
            if s1 - s0 < 2.0:
                continue
            sc = (s0 + s1) / 2
            n = hiladas(sc)
            if i >= n:
                continue
            p = punto(sc)
            g = suelo(p, grueso * 0.7) - SINK
            z0, h = g + i * HILADA, HILADA
            if i == 0:
                z0, h = g - 2.5, HILADA + 2.5  # la primera sigue bajo la arena
            M = T(p.x, p.y, z0 + h / 2) @ ejes(rumbo(sc) + r.uniform(-0.8, 0.8)) @ T(r.uniform(-0.2, 0.2), 0, 0)
            largo_b = s1 - s0 - 0.3
            m.caja(M, (grueso, largo_b, h - 0.22), r.choice(PIEDRAS), bisel=0.18)
            if i == n - 1 and n >= nmax - 1:
                m.caja(M @ T(0, 0, h / 2 + 0.45), (grueso + 1.2, largo_b + 0.2, 0.9), "piedra", bisel=0.08)
            if banda and i == 2 and n >= 4:
                cara = grueso / 2 + 0.12
                m.caja(M @ T(cara, 0, 0), (0.24, largo_b, h * 0.7), "rojo2")
                if r.random() < 0.5:
                    m.caja(M @ T(cara + 0.14, 0, 0), (0.2, largo_b * 0.6, 0.5), "oro")
                else:
                    m.caja(M @ T(cara + 0.14, 0, 0), (0.2, 0.5, h * 0.5), "oro")
    if contra:
        s = r.uniform(8, 14)
        while s < largo - 6:
            n = hiladas(s)
            p = punto(s)
            if n >= 3 and not evitar(p):
                g = suelo(p, 3.0) - SINK
                alto_c = n * HILADA * 0.75
                M = T(p.x, p.y, g) @ ejes(rumbo(s))
                m.caja(M @ T(contra * (grueso / 2 + 2.0), 0, (alto_c * 0.6 - 2.5) / 2), (4.0, 4.6, alto_c * 0.6 + 2.5),
                       "sillar2", bisel=0.15)
                m.caja(M @ T(contra * (grueso / 2 + 1.2), 0, alto_c * 0.6 + alto_c * 0.2), (2.4, 4.0, alto_c * 0.4),
                       "sillar", bisel=0.12)
            s += r.uniform(22, 30)
    for c, w in huecos:
        for k in range(r.randint(5, 8)):
            sc = min(max(c + r.uniform(-w, w), 1.0), largo - 1.0)
            lado = r.choice((-1, 1)) * r.uniform(grueso * 0.9, grueso * 2.6)
            p = punto(sc)
            q = T(p.x, p.y, 0) @ ejes(rumbo(sc)) @ V((lado, 0, 0))
            if radio_de(q) < rmin:  # nunca hacia el gigante ni el santuario
                q = T(p.x, p.y, 0) @ ejes(rumbo(sc)) @ V((-lado, 0, 0))
            if radio_de(q) < 186:
                bloque_caido(escombro, r, q)


def anillo(m, radio, a0, a1, alto, **kw):
    """Muro en arco de a0 a a1 grados (sentido creciente; a1 < a0 da la vuelta por 360)."""
    if a1 < a0:
        a1 += 360
    largo = math.radians(a1 - a0) * radio
    muro(m, lambda s: pb(a0 + math.degrees(s / radio), radio), lambda s: a0 + math.degrees(s / radio), largo, alto, **kw)


def radial(m, ang, r0, r1, alto, **kw):
    muro(m, lambda s: pb(ang, r0 + s), lambda s: ang + 90, r1 - r0, alto, **kw)


# ---- piezas sueltas (en su origen: z = 0 al ras de la arena, frente a +Y) ----------------
def columna(semilla, alto, rota):
    """Columna minoica grande (fuste de 8 estrías, más ancho arriba, capitel rojo). El plinto
    sigue bajo la arena. Devuelve la Malla y el alto de su cima."""
    m = H.Malla(semilla)
    r = m.rnd
    m.caja(T(0, 0, -1.5), (10.0, 10.0, 5.0), "sillar2", bisel=0.15)
    m.torno(T(0, 0, 1.0), [(4.6, 0), (4.8, 0.8), (4.3, 1.6)], 10, "marmol2")
    if rota:
        top = alto * r.uniform(0.3, 0.55)
        HM.fuste(m, 2.6, top, 3.9, estrias=8, roto=True)
        for k, (x, y, giro) in enumerate(((-1.5, 11.5, 0.2), (2.0, -12.0, -0.3))):  # tambores caídos, de lado
            M = T(x, y, 3.0) @ girar("Z", giro + r.uniform(-0.3, 0.3)) @ girar("Y", math.pi / 2)
            m.torno(M @ T(0, 0, -3.6), [(3.7, 0), (3.9, 7.2)], 10, lambda i, kk: "marmol2" if kk % 2 else "marmol")
        return m, top
    HM.fuste(m, 2.6, alto - 4.0, 3.9, estrias=8)
    m.torno(T(0, 0, alto - 4.0), [(4.1, 0), (5.3, 1.1), (5.6, 1.9), (5.3, 2.5)], 10, "rojo", liso=True)
    m.caja(T(0, 0, alto - 0.75), (11.6, 11.6, 1.5), {"+z": "piedra3", "resto": "piedra"})
    m.caja(T(0, 0, alto - 1.7), (12.0, 12.0, 0.4), "oro2")
    return m, alto


def obelisco(semilla, alto=32.0, roto=False):
    """Obelisco de arenisca con punta de oro; roto: le falta la punta y el pedazo cae al lado."""
    m = H.Malla(semilla)
    m.caja(T(0, 0, -1.0), (8.0, 8.0, 6.0), "sillar2", bisel=0.15)
    m.caja(T(0, 0, 2.6), (6.6, 6.6, 1.2), "piedra3")
    if roto:
        corte = alto * 0.55
        m.torno(T(0, 0, 3.2), [(3.4, 0), (2.8, corte)], 4, "sillar3", giro=math.pi / 4)
        M = T(9.0, 3.0, 2.0) @ girar("Z", 0.5) @ girar("Y", math.pi / 2 - 0.08)
        m.torno(M @ T(0, 0, -alto * 0.2), [(2.8, 0), (2.2, alto * 0.4)], 4, "sillar3", giro=math.pi / 4, punta=alto * 0.4 + 3)
        return m
    m.torno(T(0, 0, 3.2), [(3.4, 0), (2.2, alto)], 4, "sillar3", giro=math.pi / 4)
    m.torno(T(0, 0, 3.2 + alto), [(2.2, 0)], 4, "oro", giro=math.pi / 4, punta=3.4, base=False)
    for z in (6.0, alto * 0.5):  # franjas rojas talladas
        lado = 2 * 0.707 * (3.4 - 1.2 * z / alto) + 0.3
        m.caja(T(0, 0, 3.2 + z), (lado, lado, 0.8), "rojo2")
    return m


def estatua_minotauro(semilla, brazo_roto=True):
    """Estatua de un minotauro de pie (unos 33 de alto) sobre su plinto; un brazo roto, con el
    pedazo caído al pie."""
    m = H.Malla(semilla)
    m.caja(T(0, 0, 0), (12.0, 12.0, 7.0), "sillar2", bisel=0.15)
    m.caja(T(0, 0, 3.9), (13.0, 13.0, 0.9), "piedra3")
    z = 4.4
    for s in (-1, 1):  # piernas con pezuñas
        m.caja(T(s * 2.0, 0, z + 0.9), (3.4, 4.2, 1.8), "hierro2")
        m.caja(T(s * 2.0, 0, z + 6.6), (3.0, 3.4, 9.6), "marmol2", bisel=0.1)
    m.caja(T(0, 0, z + 13.2), (8.0, 5.2, 3.6), "rojo2", bisel=0.08)
    m.caja(T(0, 0, z + 14.9), (8.4, 5.4, 0.6), "oro")
    m.caja(T(0, 0, z + 19.5), (9.6, 5.6, 8.6), "marmol", bisel=0.1)  # torso
    m.caja(T(0, 0.6, z + 21.5), (10.6, 5.4, 4.0), "marmol2", bisel=0.1)  # hombros
    # Brazo sano: levantado, con un labrys pequeño.
    m.caja(T(-6.6, 0.4, z + 21.6) @ girar("Y", 0.25), (3.0, 3.2, 6.0), "marmol2", bisel=0.08)
    m.caja(T(-7.4, 1.6, z + 26.0) @ girar("X", -0.3), (2.6, 2.8, 5.4), "marmol", bisel=0.08)
    m.tubo([V((-7.6, 2.6, z + 22.0)), V((-7.6, 3.4, z + 33.0))], [0.45, 0.4], 6, "madera2")
    m.placa(T(-7.6, 3.4, z + 31.0) @ girar("Z", math.pi / 2), [(x * 1.2, zz * 1.2) for x, zz in HM.LABRYS], 0.4, "oro2")
    if brazo_roto:
        m.caja(T(6.0, 0.4, z + 21.2), (2.8, 3.0, 2.6), "marmol3", bisel=0.15)  # muñón
        m.caja(T(9.5, 5.5, 0.9) @ girar("Z", 0.7) @ girar("Y", 1.45), (2.8, 3.0, 9.0), "marmol2", bisel=0.15)
    else:
        m.caja(T(6.2, 0.4, z + 18.6) @ girar("Y", -0.15), (3.0, 3.2, 8.0), "marmol2", bisel=0.08)
    # Cabeza de toro con cuernos.
    hz = z + 26.4
    m.caja(T(0, 0.2, hz), (4.8, 5.0, 4.6), "marmol", bisel=0.1)
    m.caja(T(0, 3.2, hz - 1.0), (3.6, 2.6, 2.6), "marmol2", bisel=0.08)
    for s in (-1, 1):
        m.caja(T(s * 1.3, 4.5, hz - 1.0), (0.9, 0.3, 0.9), "negro")
        m.caja(T(s * 3.0, 0.4, hz + 0.6), (1.6, 1.2, 0.8), "marmol2")
        m.tubo([V((s * 2.2, 0, hz + 1.6)), V((s * 4.8, -0.2, hz + 2.6)), V((s * 6.0, 0.2, hz + 5.2)), V((s * 5.6, 0.8, hz + 7.0))],
               [1.0, 0.8, 0.5, 0.15], 6, "cuerno")
    return m


def estatua_toro(semilla, sin_cabeza=False):
    """Toro de piedra de pie sobre un plinto largo (unos 28 de alto con la cabeza). sin_cabeza:
    la cabeza rota yace en la arena, al lado del plinto."""
    m = H.Malla(semilla)
    m.caja(T(0, 0, 0.5), (22.0, 11.0, 9.0), "sillar2", bisel=0.15)
    m.caja(T(0, 0, 5.4), (23.0, 12.0, 0.9), "piedra3")
    m.caja(T(0, 5.8, 3.0), (18.0, 0.3, 2.0), "rojo2")  # franja del frente
    z = 5.9
    for x in (-6.5, 6.5):
        for y in (-2.2, 2.2):
            m.caja(T(x, y, z + 4.5), (2.6, 2.6, 9.0), "marmol2", bisel=0.08)
    m.caja(T(0, 0, z + 13.0), (17.0, 7.4, 8.6), "marmol", bisel=0.12)  # cuerpo
    m.caja(T(4.5, 0, z + 17.8), (6.0, 6.4, 2.6), "marmol2", bisel=0.12)  # giba
    m.tubo([V((-8.5, 0, z + 15.0)), V((-10.6, 0, z + 11.0)), V((-10.2, 0, z + 7.0))], [0.6, 0.5, 0.7], 5, "marmol2")
    cabeza = T(11.5, 0, z + 17.0)
    if sin_cabeza:
        m.caja(T(9.2, 0, z + 14.0), (2.4, 5.6, 5.6), "marmol3", bisel=0.2)  # cuello roto
        cabeza = T(16.0, 8.0, 2.4) @ girar("Z", 0.8) @ girar("X", 0.5)
    m.caja(cabeza, (6.0, 5.6, 6.0), "marmol", bisel=0.1)
    m.caja(cabeza @ T(3.6, 0, -1.4), (3.0, 4.0, 3.2), "marmol2", bisel=0.08)
    for s in (-1, 1):
        m.tubo([cabeza @ V((0, s * 2.6, 2.2)), cabeza @ V((-0.4, s * 5.6, 3.2)), cabeza @ V((0.6, s * 7.0, 6.2)),
                cabeza @ V((1.6, s * 6.4, 8.4))], [1.1, 0.9, 0.55, 0.15], 6, "cuerno")
    return m


def labrys_gigante(esc=5.5):
    """Labrys (hacha doble) de bronce enorme; origen donde el mango entra en la arena."""
    m = H.Malla(41)
    m.tubo([V((0, 0, -10)), V((0, 0, 34))], [1.3, 1.1], 8, "madera2")
    m.esfera(T(0, 0, 34.8), 1.8, "oro", 1)
    m.placa(T(0, 0, 26.0), [(x * esc, z * esc) for x, z in HM.LABRYS], 1.8, "oro2", "oro")
    for z in (-2.6, 2.6):
        m.tubo([V((-1.6, 0, 26 + z)), V((1.6, 0, 26 + z))], [1.7, 1.7], 8, "oro")
    return m


def duna(m, p, rumbo, largo, ancho, alto):
    """Duna de arena acumulada (montículo bajo de 8 lados), con la base bajo la arena."""
    z = suelo(p, 2.0) - 1.5
    M = T(p.x, p.y, z) @ ejes(rumbo) @ escala(ancho / 2, largo / 2, 1.0)
    m.torno(M, [(1.0, 0), (0.78, alto * 0.45), (0.4, alto * 0.85), (0.08, alto + 1.5)], 8,
            lambda i, k: "duna" if (i + k) % 3 else "duna2", giro=math.pi / 8)


def losa(m, r, p, ang, tam=6.0, asoma=0.3, colores=("piedra3", "piedra", "marmol2", "sillar3")):
    """Losa que asoma `asoma` studs sobre la arena más baja de su lugar."""
    z = suelo(p, tam * 0.45) + asoma - 0.7
    m.caja(T(p.x, p.y, z) @ ejes(ang + r.uniform(-6, 6), r.uniform(-0.05, 0.05)),
           (tam * r.uniform(0.85, 1.1), tam * r.uniform(0.85, 1.1), 1.4), r.choice(colores), bisel=0.12)


def _dovelas(m, r, zc, ri, ro, fondo, n=15):
    """Arco de medio punto de n dovelas (la clave de oro y un poco más alta), en el plano XZ."""
    for k in range(n):
        a0, a1 = math.pi * k / n + 0.008, math.pi * (k + 1) / n - 0.008
        clave = k == n // 2
        rro = ro + (1.8 if clave else 0)
        col = "oro2" if clave else r.choice(("piedra", "piedra3", "piedra"))
        vs = {}
        for i, a in enumerate((a0, a1)):
            for j, rr in enumerate((ri, rro)):
                for l, y in enumerate((-fondo, fondo)):
                    vs[i, j, l] = m.v(V((math.cos(a) * rr, y, zc + math.sin(a) * rr)))
        for cara in (((0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0)), ((0, 0, 1), (0, 1, 1), (1, 1, 1), (1, 0, 1)),
                     ((0, 0, 0), (0, 1, 0), (0, 1, 1), (0, 0, 1)), ((1, 0, 0), (1, 0, 1), (1, 1, 1), (1, 1, 0)),
                     ((0, 0, 0), (0, 0, 1), (1, 0, 1), (1, 0, 0)), ((0, 1, 0), (1, 1, 0), (1, 1, 1), (0, 1, 1))):
            m.cara([vs[c] for c in cara], col)


def arco_grande(hueco_r=16.0, pilar=12.0, pilar_h=18.0, podio=4.0):
    """La gran puerta del laberinto (unos 60 de alto) sobre un podio con escalinata. Origen al
    ras de la arena en el centro del paso; X de lado a lado; el frente (cabeza de toro y
    escalinata) a +Y. Devuelve la Malla y el medio ancho total."""
    m = H.Malla(31)
    r = m.rnd
    cx = hueco_r + pilar / 2
    borde = cx + pilar / 2
    # Podio (sigue bajo la arena) y escalinata hacia el frente.
    m.caja(T(0, 0, (podio - 4.0) / 2), (2 * borde + 10, 22.0, podio + 4.0), "sillar2", bisel=0.2)
    m.caja(T(0, 0, podio - 0.3), (2 * borde + 11, 23.0, 0.6), "piedra3")
    for k in range(5):
        alto = podio - k * podio / 5
        m.caja(T(0, 11.0 + 2.4 * (k + 0.5), (alto - 3.0) / 2), (30.0 - k * 0.8, 2.5, alto + 3.0),
               r.choice(("piedra3", "piedra", "marmol2")), bisel=0.08)
    z0 = podio
    for s in (-1, 1):
        x = s * cx
        m.caja(T(x, 0, z0 + 0.9), (pilar + 2.4, pilar + 2.4, 1.8), "piedra3", bisel=0.1)
        z, k = z0 + 1.8, 0
        while z < z0 + pilar_h - 0.4:
            h = min(r.uniform(3.4, 4.2), z0 + pilar_h - z)
            for d in (-1, 1):
                if k % 2:
                    m.caja(T(x + d * pilar / 4, 0, z + h / 2), (pilar / 2 - 0.2, pilar, h - 0.2), r.choice(PIEDRAS), bisel=0.12)
                else:
                    m.caja(T(x, d * pilar / 4, z + h / 2), (pilar, pilar / 2 - 0.2, h - 0.2), r.choice(PIEDRAS), bisel=0.12)
            z += h
            k += 1
        zt = z0 + pilar_h
        m.caja(T(x, 0, zt + 0.8), (pilar + 0.6, pilar + 0.6, 1.6), "rojo")
        m.caja(T(x, 0, zt + 1.75), (pilar + 1.0, pilar + 1.0, 0.3), "oro2")
        m.caja(T(x, 0, zt + 2.5), (pilar + 2.0, pilar + 2.0, 1.2), "piedra3")
    zc = z0 + pilar_h + 3.1
    ri, ro, fondo = hueco_r, hueco_r + 7.0, 5.5
    _dovelas(m, r, zc, ri, ro, fondo)
    z = zc
    while z < zc + ro - 0.5:  # enjutas
        h = min(3.6, zc + ro - z)
        xi = math.sqrt(max(ro * ro - (z + h - zc) ** 2, 0.0))
        for s in (-1, 1):
            if borde - xi > 1.0:
                m.caja(T(s * (xi + borde) / 2, 0, z + h / 2), (borde - xi - 0.15, fondo * 2 - 0.4, h - 0.15),
                       r.choice(PIEDRAS), bisel=0.1)
        z += h
    zt = zc + ro
    ancho = 2 * borde + 1.0
    m.caja(T(0, 0, zt + 1.7), (ancho, fondo * 2, 3.4), "sillar2", bisel=0.1)
    m.caja(T(0, fondo + 0.1, zt + 1.7), (ancho - 2.0, 0.3, 2.4), "rojo2")
    paso = 3.6
    for k in range(int((ancho - 3) / paso)):
        x = -ancho / 2 + 1.5 + paso * (k + 0.5)
        m.caja(T(x - 0.5, fondo + 0.3, zt + 2.25), (paso * 0.7, 0.2, 0.4), "oro")
        m.caja(T(x + 0.7, fondo + 0.3, zt + 1.55), (0.4, 0.2, 1.4), "oro")
    m.caja(T(-2.5, 0, zt + 4.0), (ancho - 5.0, fondo * 2 + 1.8, 1.4), "piedra3", bisel=0.1)  # una punta caída
    zb = zt + 4.7
    m.caja(T(0, 0, zb + 1.0), (17.0, 6.0, 2.0), "piedra3", bisel=0.08)  # cuernos de consagración
    for s in (-1, 1):
        m.tubo([V((s * 3.0, 0, zb + 1.8)), V((s * 6.2, 0, zb + 3.6)), V((s * 7.6, 0, zb + 7.4)), V((s * 7.2, 0, zb + 10.0))],
               [1.7, 1.4, 1.0, 0.4], 6, "marmol")
    m.caja(T(0, 0, zb + 2.6), (6.0, 4.0, 1.6), "marmol2")
    top = V((0, fondo + 1.6, zc + ri + 3.0))  # cabeza de toro de oro en la clave
    m.esfera(T(*top), 3.6, "oro", 1, escala=(1, 0.7, 1.15))
    m.caja(T(*(top + V((0, 1.0, -3.0)))), (4.0, 2.6, 3.0), "oro")
    for s in (-1, 1):
        m.tubo([top + V((s * 2.8, 0, 1.5)), top + V((s * 6.4, 0.5, 2.2)), top + V((s * 7.8, 0.7, 6.0))], [1.2, 0.9, 0.3], 5, "oro2")
    for s in (-1, 1):  # alas: muro bajo a cada lado, roto
        x0 = s * (borde + 5.2)
        zz = -2.5
        for h, l in ((7.0, 14.0), (4.0, 10.0), (4.0, 6.0)):
            m.caja(T(x0 + s * l / 2, 0, zz + h / 2), (l, 5.0, h - 0.2), r.choice(PIEDRAS), bisel=0.15)
            zz += h
    for k in range(10):  # sillares caídos al pie
        s = r.choice((-1, 1))
        m.caja(T(s * r.uniform(borde, borde + 16), r.uniform(-3, 16), 0.6) @ girar("Z", r.uniform(0, 3))
               @ girar("X", r.uniform(-0.4, 0.4)), (r.uniform(3.5, 6.0), r.uniform(3.0, 5.0), r.uniform(2.4, 3.4)),
               r.choice(PIEDRAS), bisel=0.25)
    return m, borde + 19.2


# Zigurat: escalones (x0, x1 radiales locales, medio ancho, Y absoluta de la cara de arriba).
ZIGURAT = [(-18, 18, 28, 10.0), (-8, 18, 22, 17.0), (-2, 18, 16, 23.5), (4, 15, 9, 26.5)]


def zigurat(m, b, ang, rc, r):
    """Zigurat en ruinas apoyado en el acantilado (nada pasa de Y = 30): cuatro escalones de
    sillares grandes con una franja roja en el borde, un santuario arriba con dos pilares rotos
    y cuernos de consagración, y una escalinata que baja hacia el centro hasta la arena (los
    sillares caídos van en la Malla b). Devuelve dos puntos de Blender para braseros en el
    primer escalón."""
    M0 = T(*pb(ang, rc)) @ ejes(ang)
    piso = min(suelo(M0 @ V((x, y, 0)), 3.0) for x in (-18, 0, 18) for y in (-28, 0, 28)) - 3.0
    abajo = piso
    for e, (x0, x1, w, top) in enumerate(ZIGURAT):
        nx, ny = max(1, round((x1 - x0) / 9)), max(1, round(2 * w / 9))
        dx, dy = (x1 - x0) / nx, 2 * w / ny
        for i in range(nx):
            for j in range(ny):
                if e < 3 and i == 0 and 0 < j < ny - 1 and abs(j - (ny - 1) / 2) > 1 and r.random() < 0.12:
                    continue  # sillar que falta en el borde (nunca bajo la escalinata)
                cx, cy = x0 + dx * (i + 0.5), -w + dy * (j + 0.5)
                borde_ = (i == 0 or j in (0, ny - 1)) and e < 3
                t = top - (r.uniform(0.0, 1.4) if borde_ else 0.0)
                m.caja(M0 @ T(cx, cy, (abajo + t) / 2), (dx - 0.3, dy - 0.3, t - abajo), r.choice(PIEDRAS), bisel=0.2)
        if e < 3:
            m.caja(M0 @ T(x0 - 0.15, 0, top - 1.6), (0.3, 2 * w - 3.0, 1.6), "rojo2")
        abajo = top - 1.0
    top = ZIGURAT[-1][3]
    for s in (-1, 1):
        m.caja(M0 @ T(6.5, s * 5.5, top + 1.3), (2.6, 2.6, 2.6), "rojo", bisel=0.1)
    m.caja(M0 @ T(10.5, 0, top + 0.6), (4.0, 9.0, 1.2), "piedra3")
    for s in (-1, 1):
        m.tubo([M0 @ V((10.5, s * 1.6, top + 1.2)), M0 @ V((10.5, s * 3.0, top + 2.0)), M0 @ V((10.5, s * 3.4, top + 2.9))],
               [0.8, 0.6, 0.25], 6, "marmol")
    x, z = ZIGURAT[2][0], ZIGURAT[2][3]
    k = 0
    while k < 30:
        z -= 1.5
        x -= 2.6
        g = suelo(M0 @ V((x, 0, 0)), 6.0)
        if z < g - 0.3:
            break
        m.caja(M0 @ T(x + 1.3, 0, (z + g - 3.0) / 2), (2.7, 14.0, z - g + 3.0), r.choice(("piedra3", "piedra", "marmol2")),
               bisel=0.08)
        if k % 2 == 0:
            for s in (-1, 1):
                m.caja(M0 @ T(x + 0.2, s * 7.8, (z + 2.4 + g - 3.0) / 2), (5.4, 1.8, z + 2.4 - g + 3.0), "sillar2", bisel=0.1)
        k += 1
    for k in range(10):
        s = r.choice((-1, 1))
        bloque_caido(b, r, M0 @ V((r.uniform(-24, -10), s * r.uniform(30, 38), 0)), 1.1)
    return [M0 @ V((-14.0, s * 22.0, ZIGURAT[0][3])) for s in (-1, 1)]
