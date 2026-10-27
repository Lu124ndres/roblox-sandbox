r"""
Hábitat completo de la Orca (contrato: docs/contrato_habitat_completo.md, 2026-10-23): un
arrecife de coral que tapiza el fondo plano del lago nuevo (Y = -250, hasta r = 184) y trepa
por la pared casi vertical (r = 184 a 190) hasta la orilla. Reemplaza a los props sueltos de
Config.Habitats.byGiant.Orca (CoralRama, CoralCerebro, CoralAbanico, Alga, Almeja y
RocaPercebes) y reusa sus generadores (tools/blender/habitats_orca.py) dentro de la escena.

La pared se viste por tramos de 45° (ángulo del cráter, desde +X, x = cos, z = sin):
      0-45   bosque de kelp alto que sube hacia la luz y un pináculo de arrecife
     45-90   jardín de abanicos: cuatro cornisas apiladas con abanicos y ramas, y un pináculo
     90-135  el barco hundido, escorado, con el palo apoyado en la pared y un cofre con perlas
    135-180  el arco grande, con coral encima y kelp debajo
    180-225  segundo bosque de kelp, el pináculo más alto y una cornisa con almeja
    225-270  escalera de cornisas que sube en diagonal (del lado de la puerta) y un pináculo
    270-315  las almejas gigantes sobre una plataforma de roca, con perlas que brillan
    315-360  arco chico y cornisas con cerebros
Además: contrafuertes de roca en la pared, una franja media de cornisas (Y -80 a -40: lo que se
ve de la pared de enfrente desde el paseo), manchones de coral por el fondo (en r < 95 solo
cosas bajas, de 15 studs como máximo) y una franja de orilla (rocas con percebes a flor de
agua, costra de algas, estrellas y corales pegados a la pared), que se ve aun con agua.

Zonas que respeta (lo comprueba revisar_zonas() al construir):
    r >= 205 nada; Y <= 30 en el acantilado;
    r < 95 solo hasta Y = -235 (el gigante); r < 100 hasta -136 y r < 124 hasta -84 (santuario);
    la orca: en r < 160 nada sobre Y = -140 (en la inmersión larga la E4 baja la panza hasta ~-120) y
    cerca de la superficie (Y > -30) nada más adentro de r = 184 (la cría nada pegada a la orilla).

Mallas, todas con la MISMA caja (cubitos mínimos en las esquinas, caja simétrica en X e Y):
    OrcaHabitat1        roca: cornisas, contrafuertes, arcos, pináculos, plataforma, bases
    OrcaHabitat2/3/6    coral: cerebros, ramas, abanicos, estrellas, anémonas y rocas con
                        percebes (libre() lo reparte en tres mallas para no pasar el tope)
    OrcaHabitat4        bosques de kelp, costra de algas de la orilla y rocas al pie del kelp
    OrcaHabitat5        el barco hundido, el cofre, las almejas y el coral que les toca
    OrcaHabitatBrillo1  perlas (Neon blanco nacarado)
    OrcaHabitatBrillo2  puntas de anémonas y erizos bioluminiscentes (Neon turquesa)
Coordenadas: 1 unidad = 1 stud, origen en el centro del cráter a Y = 0 del mundo, Z de Blender
= Y del mundo (absoluta). Un punto del mundo (dx, y, dz) es (dx, -dz, y) en Blender. Ninguna
malla choca. Paleta: la de tools/blender/habitats.py con unos basaltos de más.
Exporta assets/blender/habitat_orca/OrcaHabitat.fbx (textura embebida), su JSON (caja, mallas,
luces) y assets/textures/OrcaHabitat_color.png; los renders van en renders/habitat_orca/.

Uso sin abrir Blender:
    blender -b --factory-startup --python tools/blender/habitat_orca.py -- exportar render
"""
import bpy, bmesh, json, math, os, random, sys
from mathutils import Matrix, Vector

V = Vector
RAIZ = globals().get("RAIZ") or os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
sys.path.insert(0, os.path.join(RAIZ, "tools", "blender"))
import habitats as H  # noqa: E402
import habitats_orca as HO  # noqa: E402

SALIDA = os.path.join(RAIZ, "assets", "blender", "habitat_orca")
TEX = os.path.join(RAIZ, "assets", "textures", "OrcaHabitat_color.png")
FBX = os.path.join(SALIDA, "OrcaHabitat.fbx")
JSON = os.path.join(SALIDA, "OrcaHabitat.json")
RENDERS = os.path.join(RAIZ, "renders", "habitat_orca")
H.TEX = TEX  # la paleta de los hábitats, guardada con el nombre de este hábitat
for _n, _c in (("basalto", (58, 56, 70)), ("basalto2", (44, 42, 54)), ("basalto3", (80, 76, 90)),
               ("costra", (70, 104, 92)), ("costra2", (112, 96, 128))):
    H.COLORES[_n] = _c
    H.NOMBRES.append(_n)
rnd = random.Random(250)

MAX_TRIS = 9800
FONDO = -250.0          # fondo plano del lago de la Orca
R_PLANO = 184.0         # hasta aquí el fondo es plano
R_LAGO = 190.0          # pie del acantilado
R_PASEO = 205.0
GIGANTE_R, GIGANTE_ALTO = 95.0, 15.0
ORCA_R, ORCA_TOPE = 160.0, -140.0
ROCA = ("basalto", "basalto2", "basalto3", "roca2", "basalto")
BRILLO = {"OrcaHabitatBrillo1": (252, 248, 255), "OrcaHabitatBrillo2": (120, 255, 230)}


# ---- forma del lago ---------------------------------------------------------------------------
def rpared(z):
    """Radio de la pared (o del acantilado) a la altura z."""
    if z <= FONDO:
        return R_PLANO
    if z < -1:
        return R_PLANO + (R_LAGO - R_PLANO) * (z - FONDO) / (-1 - FONDO)
    t = (min(z, 30.0) + 1) / 31
    return R_LAGO + 15 * t ** (1 / 0.6)


def ang(a):
    """Ángulo del cráter (grados, x = cos, z = sin) a ángulo de Blender."""
    return -math.radians(a)


def polar(theta, r, z):
    return V((r * math.cos(theta), r * math.sin(theta), z))


def ejes(theta, inclinar=0.0, ladear=0.0):
    """Matriz 4x4: X radial (hacia la pared), Y tangente, Z arriba; inclinada y ladeada."""
    radial = V((math.cos(theta), math.sin(theta), 0))
    tangente = V((-math.sin(theta), math.cos(theta), 0))
    m = Matrix((radial, tangente, V((0, 0, 1)))).transposed().to_4x4()
    if inclinar:
        m = Matrix.Rotation(inclinar, 4, tangente) @ m
    if ladear:
        m = Matrix.Rotation(ladear, 4, radial) @ m
    return m


def en(p, theta=0.0, escala=1.0, giro=None):
    """Matriz para pegar un prop en p mirando al centro (su +Y local hacia adentro)."""
    g = giro if giro is not None else theta + math.pi / 2
    return Matrix.Translation(p) @ Matrix.Rotation(g, 4, "Z") @ Matrix.Scale(escala, 4)


# ---- capas: mallas que juntan props -----------------------------------------------------------
class Capa(H.Malla):
    def piedra(self, c, tam, theta, color=None, bisel=0.5, inclinar=0.0, ladear=0.0):
        self.caja(Matrix.Translation(c) @ ejes(theta, inclinar, ladear), tam, color or rnd.choice(ROCA),
                  bisel=bisel)

    def pegar(self, prop, M, piso=True):
        """Copia la malla de un prop (H.Malla) con la matriz M; piso: corta lo de bajo z = 0."""
        vm = {}
        for v in prop.bm.verts:
            co = v.co.copy()
            if piso:
                co.z = max(co.z, 0.0)
            vm[v] = self.bm.verts.new(M @ co)
        for f in prop.bm.faces:
            try:
                nf = self.bm.faces.new([vm[v] for v in f.verts])
            except ValueError:
                continue
            for la, lb in zip(f.loops, nf.loops):
                lb[self.uv].uv = la[prop.uv].uv
            nf[self.liso] = f[prop.liso]
        prop.bm.free()

    def tris(self):
        return sum(len(f.verts) - 2 for f in self.bm.faces)


# ---- props propios (livianos) -----------------------------------------------------------------
def rama(semilla, colores=("coral", "coral2", "coral3"), alto=14.0, raices=3):
    """Coral de ramas liviano (dos niveles), para repetir mucho."""
    m = H.Malla(semilla)
    r = m.rnd

    def brote(p, d, largo, radio, nivel):
        pts, rad = [p], [radio]
        for i in range(1, 3):
            d = (d + V((r.uniform(-0.35, 0.35), r.uniform(-0.35, 0.35), 0.25))).normalized()
            pts.append(pts[-1] + d * largo / 2)
            rad.append(radio * (1 - i / 3.4))
        m.tubo(pts, rad, 4, colores[0] if nivel == 0 else colores[2 if r.random() < 0.5 else 1], liso=True)
        if nivel == 0:
            for _ in range(2):
                nd = (d + V((r.uniform(-0.8, 0.8), r.uniform(-0.8, 0.8), 0.3))).normalized()
                brote(pts[r.randint(1, 2)], nd, largo * 0.75, rad[1] * 0.9, 1)

    for k in range(raices):
        a = 2 * math.pi * k / raices + r.uniform(-0.3, 0.3)
        d = V((math.cos(a) * 0.45, math.sin(a) * 0.45, 1)).normalized()
        brote(V((math.cos(a), math.sin(a), 0)) * 1.2, d, alto * 0.55, 1.3, 0)
    return m


def cerebro(semilla, R=7.0):
    """Coral cerebro liviano: media esfera aplastada con surcos de dos colores."""
    m = H.Malla(semilla)
    claro, oscuro = (("cerebro", "cerebro2"), ("alga3", "costra"), ("coral3", "coral2"), ("amarillo", "amarillo2"),
                     ("cerebro", "cerebro2"))[semilla % 5]

    def surco(f):
        c = f.calc_center_median()
        return oscuro if math.sin(c.x * 1.3 + c.y * 0.9 + c.z * 1.7 + semilla) > 0.3 else claro

    m.esfera(H.T(0, 0, R * 0.2), R, surco, 2 if semilla % 3 == 0 else 1, 0.08, semilla, escala=(1, 1, 0.66))
    return m


def abanico(semilla):
    """Abanico de mar liviano: una o dos placas con borde ondulado y tres nervaduras."""
    m = H.Malla(semilla)
    r = m.rnd
    cols = r.choice((("morado", "morado2"), ("amarillo", "amarillo2"), ("coral", "coral2"), ("naranja", "naranja2")))
    for k in range(1 + semilla % 2):
        esc = 1.0 - 0.25 * k
        M = H.T(k * 3.5 - 1.5, -1.5 * k, 0) @ H.girar("Z", 0.7 * k)
        cont = [(0, 0)] + [(math.cos(a) * 10 * esc * (0.9 + 0.1 * math.sin(i * 2.3)),
                            1.5 + math.sin(a) * 10 * esc * (0.9 + 0.1 * math.sin(i * 2.3)))
                           for i, a in enumerate(math.pi * (0.12 + 0.76 * i / 8) for i in range(9))]
        m.placa(M, cont, 0.35, cols[0], cols[1])
        for i in range(3):
            a = math.pi * (0.25 + 0.25 * i)
            m.tubo([M @ V((0, 0.25, 0.8)), M @ V((math.cos(a) * 9 * esc, 0.25, 1.5 + math.sin(a) * 9 * esc))],
                   [0.35, 0.18], 3, cols[1], cerrar=False)
    return m


def kelp(semilla, alto):
    """Un tallo de kelp: tubo de 4 lados que se mece, una hoja por nudo y un flotador arriba."""
    m = H.Malla(semilla)
    r = m.rnd
    n = max(5, round(alto / 13))
    fase = r.uniform(0, 6.3)
    pts = []
    for i in range(n + 1):
        t = i / n
        pts.append(V((math.sin(fase + t * 3.1) * 2.4 * t, math.cos(fase * 1.3 + t * 2.4) * 1.8 * t, alto * t)))
    m.tubo(pts, [1.4 - 0.7 * i / n for i in range(n + 1)], 4, "alga2", cerrar=False)
    for i in range(1, n + 1):
        largo = r.uniform(10.0, 15.0) * (1.1 - 0.35 * i / n)
        hoja = [(0, 0), (3.0, 2.4), (largo, 1.0), (largo * 0.6, -1.3)]
        M = H.T(*pts[i]) @ H.girar("Z", fase + i * 2.4) @ H.girar("Y", -0.75)
        m.placa(M, hoja, 0.12, "alga" if i % 3 else ("alga3" if i % 2 else "costra"))
    m.esfera(H.T(*pts[-1]), 1.8, "alga3", 0)
    return m


def roca_percebes(semilla, rad=3.5):
    """Roca con percebes, más liviana que la de habitats_orca (para la orilla)."""
    m = H.Malla(semilla)
    r = m.rnd
    m.roca(H.T(0, 0, rad * 0.35), rad, r.choice(("roca", "roca3", "basalto3")), 1, 0.35, semilla, (1.2, 1, 0.75))
    for k in range(5):
        a, h = r.uniform(0, 2 * math.pi), r.uniform(0.2, 0.8)
        n = V((math.cos(a) * math.cos(h), math.sin(a) * math.cos(h), math.sin(h))).normalized()
        p = V((n.x * rad * 1.1, n.y * rad * 0.95, rad * 0.35 + n.z * rad * 0.7))
        rot = n.to_track_quat("Z", "Y").to_matrix().to_4x4()
        s = rad / 3.5
        m.torno(H.T(*p) @ rot, [(0.7 * s, -0.3 * s), (0.5 * s, 0.6 * s), (0.22 * s, 0.9 * s)], 5,
                "percebe" if k % 3 else "percebe2", base=False)
    return m


def estrella(semilla):
    m = H.Malla(semilla)
    col = m.rnd.choice((("estrella", "estrella2"), ("azul", "azul"), ("morado", "morado2"), ("amarillo", "amarillo2")))
    m.placa(H.T(0, 0, 0.25) @ H.girar("X", math.pi / 2), HO.ESTRELLA, 0.5, col[0], col[1])
    return m


def anemona(semilla, b):
    """Anémona: pie corto y tentáculos; las puntas (bioluminiscentes) van a la malla de brillo."""
    m = H.Malla(semilla)
    r = m.rnd
    m.torno(H.T(), [(1.3, 0), (1.0, 1.4), (1.4, 2.0)], 6, r.choice(("coral2", "morado2", "turquesa")))
    for k in range(7):
        a = 2 * math.pi * k / 7 + r.uniform(-0.2, 0.2)
        p1 = V((math.cos(a) * 0.9, math.sin(a) * 0.9, 2.0))
        p2 = V((math.cos(a) * 1.8, math.sin(a) * 1.8, 3.4))
        m.tubo([p1, p2], [0.3, 0.2], 4, "turquesa", cerrar=False)
        b.append(p2)
    return m


# ---- piezas de roca ---------------------------------------------------------------------------
def cornisa(roca, theta, z, largo, hondo, grosor=4.5):
    """Cornisa de roca que sale de la pared: lajas en arco con ménsulas debajo. Devuelve
    lugares de apoyo arriba: (theta, radio, z)."""
    rp = rpared(z)
    rext = rp + 3.0  # se mete 3 studs en el terreno
    n = max(2, round(largo / 9))
    giro_total = largo / (rp - hondo / 2)
    apoyos = []
    for k in range(n):
        t = theta + giro_total * ((k + 0.5) / n - 0.5)
        h = hondo * (0.7 + 0.3 * math.sin(k * 1.9 + theta * 7))
        rin = rp - h
        zk = z + rnd.uniform(-0.7, 0.7)
        g = grosor * rnd.uniform(0.85, 1.15)
        ancho = largo / n * 1.18
        roca.piedra(polar(t, (rin + rext) / 2, zk), (rext - rin, ancho, g), t, inclinar=rnd.uniform(-0.05, 0.05))
        roca.piedra(polar(t, (rp - h * 0.55 + rext) / 2, zk - g * 0.95), (rext - rp + h * 0.55, ancho * 0.8, g * 0.9), t)
        roca.piedra(polar(t, (rp - h * 0.25 + rext) / 2, zk - g * 1.8), (rext - rp + h * 0.25, ancho * 0.6, g * 0.8), t)
        if rnd.random() < 0.5:  # costra de algas en el borde
            roca.piedra(polar(t, rin + 0.8, zk + g / 2 + 0.2), (1.6, ancho * 0.7, 0.5), t, "costra", 0.15)
        apoyos.append((t, rin + 0.4 * h, zk + g / 2))
    return apoyos


def contrafuerte(roca, theta, z0, z1, ancho=14.0):
    """Contrafuerte de roca pegado a la pared, de z0 a z1: hiladas de dos bloques corridos,
    más hondo y ancho abajo (talud) y más fino arriba."""
    z = z0
    while z < z1 - 2:
        alto = min(rnd.uniform(9, 14), z1 - z)
        zc = z + alto / 2
        u = (zc - z0) / max(z1 - z0, 1)
        rp = rpared(zc)
        lados = (-1, 1) if u < 0.4 else (rnd.uniform(-0.4, 0.4),)  # arriba, un bloque por hilada
        for lado in lados:
            hondo = rnd.uniform(4, 8) * (1.6 - 0.8 * u)
            w = ancho * rnd.uniform(0.45, 0.7) * (1.3 - 0.5 * u) * (1 if len(lados) == 2 else 1.5)
            t = theta + lado * w * 0.35 / rp + rnd.uniform(-0.01, 0.01)
            roca.piedra(polar(t, rp - hondo / 2 + 1.5, zc + rnd.uniform(-1.5, 1.5)), (hondo + 3, w, alto * 1.05), t,
                        bisel=1.0, ladear=rnd.uniform(-0.12, 0.12))
        z += alto * 0.9
    return z


def pinaculo(roca, centro, alto, radio=13.0):
    """Pináculo de arrecife que sale del fondo: anillos de bloques que se afinan hacia arriba.
    Devuelve apoyos (puntos) en los escalones y en la cima."""
    apoyos = []
    z = 0.0
    while z < alto - 3:
        u = z / alto
        h = rnd.uniform(6, 9)
        rr = radio * (1 - 0.7 * u)
        n = 3 if rr > 6 else 2
        giro = rnd.uniform(0, 6.3)
        for k in range(n):
            t = giro + 2 * math.pi * k / n
            w = rr * rnd.uniform(1.0, 1.3)
            roca.piedra(centro + polar(t, rr * 0.45, z + h / 2), (w, w * 0.9, h), t + rnd.uniform(-0.3, 0.3), bisel=1.0)
        if rnd.random() < 0.6:
            t = rnd.uniform(0, 6.3)
            apoyos.append(centro + polar(t, rr * 0.8, z + h * 0.9))
        z += h * 0.85
    apoyos.append(centro + V((0, 0, z + 1)))
    for k in range(4):  # talud al pie
        t = rnd.uniform(0, 6.3)
        roca.piedra(centro + polar(t, radio * rnd.uniform(0.8, 1.2), 1.5), (rnd.uniform(5, 9), rnd.uniform(5, 8), 4),
                    t, bisel=1.0)
    return apoyos


def arco(roca, centro, theta, luz, alto, grueso=9.0):
    """Arco natural de roca: dos pilares de bloques y un dintel en medio círculo. La luz va a lo
    largo de la tangente. Devuelve apoyos arriba del dintel (puntos)."""
    tang = V((-math.sin(theta), math.cos(theta), 0))
    rc = luz / 2
    zc = alto - rc  # centro del medio círculo, sobre el pie
    for lado in (-1, 1):
        base = centro + tang * lado * rc
        z = 0.0
        while z < zc:
            h = rnd.uniform(6, 9)
            w = grueso * (1.5 - 0.5 * z / max(zc, 1)) * rnd.uniform(0.9, 1.1)
            roca.piedra(base + V((0, 0, z + h / 2)), (w, w * 0.9, h), theta + rnd.uniform(-0.2, 0.2), bisel=0.9)
            z += h * 0.9
        for k in range(3):  # talud
            roca.piedra(base + tang * lado * rnd.uniform(3, 9) + V((rnd.uniform(-4, 4), rnd.uniform(-4, 4), 2)),
                        (rnd.uniform(5, 9), rnd.uniform(5, 9), rnd.uniform(3, 5)), rnd.uniform(0, 6), bisel=1.0)
    apoyos = []
    n = max(7, round(math.pi * rc / 6))
    for k in range(n + 1):
        a = math.pi * k / n
        p = centro + tang * (-math.cos(a) * rc) + V((0, 0, zc + math.sin(a) * rc + grueso * 0.3))
        roca.piedra(p, (grueso, math.pi * rc / n * 1.3, grueso * 0.9), theta, ladear=-(a - math.pi / 2), bisel=0.9)
        if 0 < k < n:
            apoyos.append(p + V((0, 0, grueso * 0.45)))
    return apoyos


# ---- el barco hundido -------------------------------------------------------------------------
def barco(cuerpo, brillo):
    """Barco de vela hundido, en coordenadas locales: eslora en X (proa en +X), quilla en z = 0.
    Roto de popa (tablas que faltan) y con el palo mayor quebrado. Devuelve el tope del palo
    (local) y el centro del cofre."""
    m = cuerpo
    r = random.Random(77)
    L, B, P = 64.0, 9.0, 13.0  # eslora, media manga, puntal
    m.caja(H.T(0, 0, 0.8), (L, 1.6, 1.6), "madera2")

    def manga(x):
        return B * max(0.0, 1 - (x / (L * 0.52)) ** 4) ** 0.5

    costillas = [-L / 2 + 3 + 5.6 * i for i in range(11)]
    for x in costillas:
        w = manga(x)
        for lado in (-1, 1):
            for j in range(5):  # la costilla en U
                a0, a1 = math.pi * j / 10, math.pi * (j + 1) / 10
                p0 = V((x, lado * w * math.sin(a0), P * (1 - math.cos(a0)) * 0.9 + 0.8))
                p1 = V((x, lado * w * math.sin(a1), P * (1 - math.cos(a1)) * 0.9 + 0.8))
                c, d = (p0 + p1) / 2, p1 - p0
                rot = Matrix.Rotation(math.atan2(d.z, d.y), 4, "X")
                m.caja(H.T(*c) @ rot, (0.9, d.length + 0.4, 0.9), "madera2")
    for lado in (-1, 1):  # tablas del casco, con huecos (más hacia la popa rota)
        for j in range(5):
            a = math.pi * (j + 0.5) / 10
            for i in range(len(costillas) - 1):
                x0, x1 = costillas[i], costillas[i + 1]
                if r.random() < (0.12 + 0.6 * max(0.0, -x0 - 8) / 24) * (1 if lado > 0 else 0.6):
                    continue
                xm = (x0 + x1) / 2
                w = manga(xm)
                c = V((xm, lado * (w * math.sin(a) + 0.5), P * (1 - math.cos(a)) * 0.9 + 0.8))
                rot = Matrix.Rotation(lado * (math.pi / 2 - a) * 0.9, 4, "X")
                m.caja(H.T(*c) @ rot, (x1 - x0 + 0.3, 0.5, P * 0.9 * math.pi / 10 * 1.35),
                       r.choice(("madera", "madera", "madera3")))
    for i in range(len(costillas) - 1):  # cubierta (media, la popa está hundida)
        x0, x1 = costillas[i], costillas[i + 1]
        if x0 < -14 or r.random() < 0.2:
            continue
        w = manga((x0 + x1) / 2)
        m.caja(H.T((x0 + x1) / 2, 0, P + 0.4), (x1 - x0 + 0.2, 2 * w, 0.5), "madera3")
    for lado in (-1, 1):  # borda
        m.caja(H.T(4, lado * (B - 0.2), P + 1.4), (L * 0.6, 0.5, 1.6), "madera2")
    m.tubo([V((L * 0.48, 0, P - 1)), V((L * 0.5 + 12, 0, P + 6))], [0.8, 0.4], 6, "madera2")  # bauprés
    m.caja(H.T(L * 0.3, 0, P + 2.6), (8, 2 * B * 0.7, 2.6), "madera")  # castillo de proa
    m.caja(H.T(L * 0.3, 0, P + 4.0), (8.4, 2 * B * 0.72, 0.4), "madera2")
    # Palo mayor quebrado en la base, inclinado hacia la pared (+Y local), con su verga y la vela rota.
    base = V((2, 0, P))
    dirp = V((0, math.sin(math.radians(30)), math.cos(math.radians(30))))
    largo = 62.0
    tope = base + dirp * largo
    m.tubo([base + dirp * t for t in (0, largo * 0.5, largo)], [1.1, 0.9, 0.6], 6, "madera2")
    verga_c = base + dirp * largo * 0.72
    m.tubo([verga_c + V((-14, 0, 0)), verga_c + V((14, 0, 0))], [0.5, 0.5], 5, "madera2")
    vela = [(-13, 0), (-12, -9), (-7, -14), (-2, -10), (3, -16), (9, -12), (13, -4), (13, 0)]
    rot_vela = Matrix.Rotation(math.radians(-30), 4, "X")
    m.placa(H.T(*(verga_c + V((0, 0.8, -0.6)))) @ rot_vela, vela, 0.2, "tela", "tela2")
    cofa = base + dirp * largo * 0.86
    m.torno(H.T(*cofa) @ rot_vela, [(2.6, -0.6), (2.6, 0.9), (2.2, 1.0)], 8, "madera")
    m.tubo([V((-6, 0, P + 0.4)), V((-24, -14, 2))], [0.8, 0.6], 6, "madera2")  # el mesana, caído
    # Ancla, cañones y tablas sueltas en el fondo, por la popa rota.
    for k, (x, y) in enumerate(((-30, -14), (-38, 6), (-22, 18))):
        m.caja(H.T(x, y, 0.3) @ H.girar("Z", r.uniform(0, 3)), (r.uniform(5, 9), 1.2, 0.5), "madera")
    for k, (x, y) in enumerate(((14, -14), (-12, -16))):
        m.torno(H.T(x, y, 1.2) @ H.girar("Z", 0.4 + k) @ H.girar("Y", math.pi / 2), [(1.2, -3), (0.9, 3), (1.1, 3.2)], 6,
                "hierro")
    m.caja(H.T(L * 0.44, -10, 1.6) @ H.girar("Z", 0.3), (0.9, 0.9, 7), "hierro2")
    m.caja(H.T(L * 0.44, -10, 0.5) @ H.girar("Z", 0.3), (6, 0.9, 0.9), "hierro2")
    # Cofre abierto con oro y perlas, junto al casco.
    cofre = V((-6, -16, 0))
    m.caja(H.T(*(cofre + V((0, 0, 1.6)))), (6, 3.8, 3.2), "madera")
    m.caja(H.T(*(cofre + V((0, 0, 3.25)))), (6.2, 4.0, 0.3), "oro2")
    m.caja(H.T(*(cofre + V((0, 2.6, 4.6)))) @ H.girar("X", -1.1), (6, 0.5, 3.6), "madera3")
    for k in range(9):
        m.caja(H.T(*(cofre + V((r.uniform(-2.4, 2.4), r.uniform(-1.4, 1.4), 3.3 + r.uniform(0, 0.6))))) @
               H.girar("Z", r.uniform(0, 3)), (1.1, 1.1, 0.3), "oro")
    for k in range(6):
        p = cofre + V((r.uniform(-4, 4), r.uniform(-4.5, -2.5), 0.25))
        m.caja(H.T(*p) @ H.girar("Z", r.uniform(0, 3)) @ H.girar("X", r.uniform(-0.3, 0.3)), (1.1, 1.1, 0.3), "oro")
    for p in ((-1.2, 0.3, 4.1), (1.0, -0.6, 4.0), (0.2, 0.8, 4.2)):
        brillo.esfera(H.T(*(cofre + V(p))), 0.75, "perla", 1)
    return tope, cofre + V((0, 0, 4))


# ---- escena -----------------------------------------------------------------------------------
def construir():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    roca, fondo, pared, alga, heroe, perla, bio, orilla = (Capa(k) for k in range(1, 9))
    luces = []
    CORAL_FONDO = CORAL_PARED = (fondo, pared, orilla, heroe)  # el coral se reparte entre cuatro mallas

    def libre(capas):
        """La capa con menos triángulos: reparte el coral entre mallas del mismo tipo."""
        return min(capas, key=lambda c: c.tris()) if isinstance(capas, tuple) else capas

    def poner_anemona(p, theta, escala=1.0):
        b = []
        capas = CORAL_FONDO if math.hypot(p.x, p.y) < R_PLANO - 6 else CORAL_PARED
        M = en(p, theta, escala)
        libre(capas).pegar(anemona(rnd.randint(0, 9999), b), M)
        for q in b:
            bio.caja(M @ H.T(*q), (0.75 * escala,) * 3, "turquesa")

    def coral_suelto(capas, p, theta, escala, tipo):
        s = rnd.randint(0, 9999)
        giro = theta + math.pi / 2 + rnd.uniform(-0.5, 0.5)
        capa = libre(capas)
        if tipo == "rama":
            cols = rnd.choice((("coral", "coral2", "coral3"), ("naranja", "naranja2", "amarillo"),
                               ("morado", "morado2", "coral3")))
            capa.pegar(rama(s, cols), en(p, theta, escala, giro))
        elif tipo == "cerebro":
            capa.pegar(cerebro(s), en(p, theta, escala, rnd.uniform(0, 6)))
        elif tipo == "abanico":
            capa.pegar(abanico(s), en(p, theta, escala, giro))
        elif tipo == "estrella":
            capa.pegar(estrella(s), en(p, theta, escala, rnd.uniform(0, 6)))
        elif tipo == "percebes":
            capa.pegar(roca_percebes(s), en(p, theta, escala, rnd.uniform(0, 6)))

    def vestir_cornisa(apoyos, tipos):
        for i, (t, r, z) in enumerate(apoyos):
            tipo = tipos[i % len(tipos)]
            if tipo is None:
                continue
            p = polar(t, r, z - 0.3)
            if tipo == "anemona":
                poner_anemona(p, t, 1.5 if z < -60 else 1.0)
            elif tipo == "kelp":
                alga.pegar(kelp(rnd.randint(0, 9999), rnd.uniform(25, 45)), en(p, t))
            else:
                if z < -150:
                    escala = rnd.uniform(1.7, 2.3)
                elif z < -55 or tipo in ("cerebro", "estrella"):
                    escala = rnd.uniform(1.3, 1.6)
                else:
                    escala = rnd.uniform(0.55, 0.7)  # cerca de la orilla, coral bajo
                coral_suelto(CORAL_PARED, p, t, escala, tipo)

    def bosque(a0, a1, n, alto0, alto1):
        """Kelp al pie de la pared (r 172-181), del fondo hacia la luz."""
        for k in range(n):
            a = a0 + (a1 - a0) * (k + rnd.uniform(0.1, 0.9)) / n
            r = rnd.uniform(172, 181)
            alto = rnd.uniform(alto0, alto1) if r >= 176 else min(rnd.uniform(alto0, alto1), 100)
            alga.pegar(kelp(rnd.randint(0, 9999), alto), en(polar(ang(a), r, FONDO - 0.5), ang(a)))
            if k % 3 == 0:  # rocas al pie
                alga.pegar(roca_base(rnd.randint(0, 999)), en(polar(ang(a), r - 5, FONDO - 0.6), ang(a), 0.8))

    def pinaculo_vestido(a, r, alto):
        t = ang(a)
        for i, p in enumerate(pinaculo(roca, polar(t, r, FONDO - 1), alto)):
            tipo = ("rama", "abanico", "cerebro", "anemona")[i % 4]
            if tipo == "anemona":
                poner_anemona(p, t, 1.4)
            else:
                coral_suelto(CORAL_FONDO, p, t, rnd.uniform(1.5, 2.1), tipo)

    # Tramo 0-45: bosque de kelp alto; una cornisa con ramas a media pared y un pináculo.
    bosque(2, 44, 12, 150, 205)
    vestir_cornisa(cornisa(roca, ang(28), -120, 30, 9), ("rama", "anemona", "rama"))
    contrafuerte(roca, ang(8), FONDO - 2, -150)
    pinaculo_vestido(30, 140, 72)
    # Tramo 45-90: jardín de abanicos, cuatro cornisas apiladas y contrafuertes que las unen.
    for z, a, largo, hondo in ((-212, 66, 42, 14), (-166, 58, 36, 12), (-118, 72, 32, 10), (-72, 63, 26, 7)):
        vestir_cornisa(cornisa(roca, ang(a), z, largo, hondo), ("abanico", "rama", "anemona", "abanico", "rama"))
    contrafuerte(roca, ang(50), FONDO - 2, -60, 16)
    contrafuerte(roca, ang(84), FONDO - 2, -100, 12)
    pinaculo_vestido(62, 125, 55)
    # Tramo 90-135: el barco hundido (escorado hacia la pared, el palo apoyado en ella).
    a_barco, r_barco = 108.0, 141.0
    t = ang(a_barco)
    local, local_brillo = Capa(91), Capa(92)
    tope, cofre = barco(local, local_brillo)
    # El giro deja el +Y local (hacia donde cae el palo) mirando a la pared; la escora lo recuesta.
    Mb = (Matrix.Translation(polar(t, r_barco, FONDO - 1.2)) @ Matrix.Rotation(t - math.pi / 2, 4, "Z")
          @ Matrix.Rotation(math.radians(-12), 4, "X"))
    heroe.pegar(local, Mb, piso=False)
    perla.pegar(local_brillo, Mb, piso=False)
    tope_m = Mb @ tope
    luces.append((Mb @ cofre, (255, 220, 150), 22))
    for k in range(5):  # coral que ya creció en el casco
        x = -24 + 11 * k
        coral_suelto(heroe, Mb @ V((x, rnd.uniform(-3, 3), 13.5)), t, rnd.uniform(1.0, 1.4),
                     ("rama", "cerebro", "abanico", "rama", "cerebro")[k])
    for a in (96, 101, 118, 124):
        alga.pegar(kelp(rnd.randint(0, 9999), rnd.uniform(70, 95)),
                   en(polar(ang(a), rnd.uniform(176, 180), FONDO - 0.5), ang(a)))
    vestir_cornisa(cornisa(roca, ang(118), -150, 28, 9), ("cerebro", "anemona", "rama"))
    contrafuerte(roca, ang(132), FONDO - 2, -110)
    # Tramo 135-180: el arco grande, coral encima y kelp debajo.
    t = ang(160)
    for i, p in enumerate(arco(roca, polar(t, 156, FONDO - 1), t, 46, 62)):
        if i % 2 == 0:
            coral_suelto(heroe, p, t, rnd.uniform(1.4, 1.8), ("rama", "abanico", "cerebro")[i // 2 % 3])
    for k in range(4):
        alga.pegar(kelp(rnd.randint(0, 9999), rnd.uniform(28, 40)),
                   en(polar(t + rnd.uniform(-0.06, 0.06), 156 + rnd.uniform(-4, 4), FONDO - 0.5), t))
    vestir_cornisa(cornisa(roca, ang(146), -96, 26, 7), ("rama", "abanico", "anemona"))
    vestir_cornisa(cornisa(roca, ang(172), -48, 22, 5), ("anemona", "rama"))
    contrafuerte(roca, ang(140), FONDO - 2, -100, 14)
    # Tramo 180-225: segundo bosque de kelp, un pináculo y una cornisa con una almeja.
    bosque(184, 222, 10, 140, 190)
    pinaculo_vestido(200, 135, 80)
    ap = cornisa(roca, ang(204), -182, 30, 14, 5.5)
    t0, r0, z0 = ap[len(ap) // 2]
    info = HO.almeja(31, 8.0)
    Ma = en(polar(t0, r0 + 1.5, z0 - 0.3), t0, 1.4)
    heroe.pegar(info["malla"], Ma)
    perla.pegar(info["brillo"], Ma, piso=False)
    luces.append((Ma @ V(info["llama"]), (250, 238, 255), 24))
    vestir_cornisa(ap[:len(ap) // 2] + ap[len(ap) // 2 + 1:], ("rama", "anemona"))
    contrafuerte(roca, ang(214), FONDO - 2, -186)
    # Tramo 225-270: escalera de cornisas en diagonal, del fondo hasta cerca de la orilla.
    for k in range(7):
        a = 230 + 5.5 * k
        z = -228 + 31 * k
        hondo = 11 if z < -100 else (7 if z < -45 else 4)
        tipos = ("rama", "anemona", "cerebro") if k % 2 else ("abanico", "rama", "anemona")
        vestir_cornisa(cornisa(roca, ang(a), z, 22, hondo, 4.0), tipos)
    contrafuerte(roca, ang(228), FONDO - 2, -200)
    pinaculo_vestido(250, 145, 60)
    # Tramo 270-315: plataforma con tres almejas gigantes y sus perlas.
    t = ang(292)
    centro = polar(t, 162, FONDO)
    tang = polar(t + math.pi / 2, 1, 0)
    for k in range(13):  # la plataforma: lajas bajas
        p = centro + tang * rnd.uniform(-58, 58) + polar(t, rnd.uniform(-12, 10), 0)
        roca.piedra(p + V((0, 0, 1.2)), (rnd.uniform(10, 16), rnd.uniform(10, 16), 3.4), rnd.uniform(0, 6), bisel=0.8)
    for k, (dt, dr, esc) in enumerate(((-40, 3, 2.2), (0, -2, 2.6), (40, 4, 2.0))):
        p = centro + tang * dt + polar(t, dr, 2.6)
        Ma = en(p, t, esc, t + math.pi / 2 + (k - 1) * 0.3)
        info = HO.almeja(40 + k, 8.0)
        heroe.pegar(info["malla"], Ma)
        perla.pegar(info["brillo"], Ma, piso=False)
        luces.append((Ma @ V(info["llama"]), (250, 238, 255), 28))
    for k in range(8):
        p = centro + tang * rnd.uniform(-60, 60) + polar(t, rnd.uniform(-20, -14), 0)
        if k % 2:
            poner_anemona(p, t, 1.6)
        else:
            coral_suelto(CORAL_FONDO, p, t, 1.8, ("estrella", "cerebro")[k // 2 % 2])
    vestir_cornisa(cornisa(roca, ang(282), -140, 28, 9), ("abanico", "rama", "anemona"))
    vestir_cornisa(cornisa(roca, ang(306), -84, 24, 6), ("rama", "cerebro"))
    contrafuerte(roca, ang(270), FONDO - 2, -150, 14)
    contrafuerte(roca, ang(316), FONDO - 2, -90, 16)
    # Tramo 315-360: arco chico pegado a la pared y cornisas con cerebros.
    t = ang(338)
    for i, p in enumerate(arco(roca, polar(t, 165, FONDO - 1), t, 30, 40, 7.0)):
        if i % 2:
            coral_suelto(heroe, p, t, 1.4, ("cerebro", "rama")[i // 2 % 2])
    vestir_cornisa(cornisa(roca, ang(326), -190, 32, 13), ("cerebro", "rama", "anemona", "cerebro"))
    vestir_cornisa(cornisa(roca, ang(350), -108, 26, 8), ("rama", "abanico", "anemona"))
    contrafuerte(roca, ang(324), FONDO - 2, -186)
    contrafuerte(roca, ang(356), FONDO - 2, -60, 12)

    # Franja media de la pared (Y -80 a -40): lo que se ve de la pared de enfrente desde el paseo.
    for a, z, largo, hondo in ((15, -62, 28, 8), (38, -44, 22, 5), (100, -58, 26, 8), (128, -76, 28, 9),
                               (192, -64, 26, 8), (220, -50, 24, 6), (298, -56, 26, 8), (344, -70, 28, 9)):
        vestir_cornisa(cornisa(roca, ang(a), z, largo, hondo, 4.0), ("rama", "abanico", "anemona", "cerebro"))

    # Manchones de coral por el fondo, entre r = 100 y 175: (ángulo, radio, cuántos).
    manchones = [(15, 118, 5), (52, 160, 3), (82, 108, 5), (88, 160, 3), (135, 120, 5), (150, 100, 4),
                 (186, 118, 5), (215, 108, 4), (238, 112, 5), (262, 158, 3), (300, 118, 5), (322, 140, 4),
                 (355, 156, 3), (115, 172, 3), (178, 170, 3), (5, 165, 3)]
    for a, r, n in manchones:
        t = ang(a)
        c = polar(t, r, FONDO - 0.6)
        roca.pegar(roca_base(rnd.randint(0, 999)), en(c, t, rnd.uniform(1.4, 1.9), rnd.uniform(0, 6)))
        for k in range(n):
            p = c + polar(rnd.uniform(0, 6.3), rnd.uniform(6, 16), 0)
            tipo = ("rama", "cerebro", "abanico", "estrella", "rama", "cerebro")[k % 6]
            if math.hypot(p.x, p.y) < GIGANTE_R + 16 and tipo in ("rama", "abanico"):
                tipo = "cerebro"  # junto al gigante, solo coral bajo
            coral_suelto(CORAL_FONDO, p, t, rnd.uniform(1.6, 2.3) if tipo != "cerebro" else 1.5, tipo)
        if n >= 4:
            poner_anemona(c + polar(rnd.uniform(0, 6.3), 8, 0), t, 1.6)
    # Dentro del radio del gigante: solo cosas bajas, sueltas (cerebros, estrellas, lajas,
    # anémonas, erizos que brillan), sin dibujar una grilla.
    puestos = []
    while len(puestos) < 26:
        a, r = rnd.uniform(0, 360), 92 * math.sqrt(rnd.uniform(0.04, 1))
        p = polar(ang(a), r, FONDO - 0.4)
        if all((p - q).length > 15 for q in puestos):
            puestos.append(p)
    for k, p in enumerate(puestos):
        t = math.atan2(p.y, p.x)
        tipo = k % 6
        if tipo in (0, 3):
            coral_suelto(CORAL_FONDO, p, t, rnd.uniform(1.1, 1.6), "cerebro")
        elif tipo == 1:
            coral_suelto(CORAL_FONDO, p, t, rnd.uniform(1.5, 2.4), "estrella")
        elif tipo == 2:
            poner_anemona(p, t, 1.3)
        elif tipo == 4:
            roca.piedra(p + V((0, 0, 1.0)), (rnd.uniform(7, 11), rnd.uniform(5, 8), 2.6), rnd.uniform(0, 6), "roca", 0.7)
            coral_suelto(CORAL_FONDO, p + polar(t, 5, 0.6), t, 0.6, "rama")
        else:
            roca.pegar(roca_base(k), en(p, t, 0.7, rnd.uniform(0, 6)))
        for j in range(2):  # erizos que brillan
            bio.esfera(H.T(*(p + polar(rnd.uniform(0, 6.3), rnd.uniform(5, 8), 0.6))), 0.8, "turquesa", 0)
    for k in (0, 13):
        luces.append((puestos[k] + V((0, 0, 8)), (120, 255, 230), 30))

    # Orilla: rocas con percebes a flor de agua, estrellas y coral pegado a la pared (lo que se ve
    # siempre desde el paseo, sobre los discos del abismo de CraterWater).
    for k in range(60):
        a = 6 * k + rnd.uniform(-1.5, 1.5)
        t = ang(a)
        for j in range(2):  # costra de algas y esponjas pegada a la pared, entre las piezas
            z = rnd.uniform(-10, -1.5)
            alga.piedra(polar(t + rnd.uniform(-0.02, 0.02), rpared(z) + 0.3, z), (1.6, rnd.uniform(3, 6), rnd.uniform(1.5, 3)),
                        t, rnd.choice(("costra", "costra2", "alga2", "musgo2")), 0.3)
        if k % 2 == 0:
            z = rnd.uniform(-2.5, -1.0)
            libre(CORAL_PARED).pegar(roca_percebes(k, rnd.uniform(3.8, 5.0)), en(polar(t, rpared(z) + 0.6, z), t, 1.0,
                                                                     rnd.uniform(0, 6)), piso=False)
        else:
            z = rnd.uniform(-12, -5)
            rp = rpared(z)
            roca.piedra(polar(t, rp - 0.25, z - 1.2), (5.5, 10, 2.4), t, bisel=0.4)
            roca.piedra(polar(t, rp + 0.6, z - 3.2), (3.5, 7, 2.2), t, bisel=0.4)
            tipo = ("rama", "abanico", "anemona", "cerebro", "rama", "estrella")[k // 2 % 6]
            p = polar(t, rp - 1.6, z)
            if tipo == "anemona":
                poner_anemona(p, t, 1.0)
            else:
                coral_suelto(CORAL_PARED, p, t, 0.55 if tipo != "cerebro" else 0.4, tipo)
        if k % 3 == 1:
            z = rnd.uniform(-9, 1.5)
            n = V((-math.cos(t), -math.sin(t), 0.15)).normalized()
            rot = n.to_track_quat("Z", "Y").to_matrix().to_4x4()
            libre(CORAL_PARED).pegar(estrella(k), Matrix.Translation(polar(t, rpared(z) - 0.2, z)) @ rot @ H.girar("Z", k))
    return {"OrcaHabitat1": roca, "OrcaHabitat2": fondo, "OrcaHabitat3": pared, "OrcaHabitat4": alga,
            "OrcaHabitat5": heroe, "OrcaHabitat6": orilla, "OrcaHabitatBrillo1": perla,
            "OrcaHabitatBrillo2": bio}, luces, tope_m


def roca_base(semilla):
    """Base de roca de un manchón: dos rocas bajas."""
    m = H.Malla(semilla)
    r = m.rnd
    for k in range(2):
        m.roca(H.T(r.uniform(-3, 3), r.uniform(-3, 3), 0), r.uniform(3.5, 5.5), r.choice(("roca", "roca2", "basalto3")),
               1, 0.35, semilla + k, (1.2, 1, 0.5))
    return m


# ---- revisión, salida y renders ---------------------------------------------------------------
def revisar_zonas(mallas):
    """Cuenta vértices que pisan una zona prohibida del contrato (y las de la orca)."""
    malos = {}
    for nombre, m in mallas.items():
        for v in m.bm.verts:
            x, y, z = v.co
            r = math.hypot(x, y)
            falta = None
            if r >= R_PASEO - 0.5 or z > 30:
                falta = "paseo"
            elif r < GIGANTE_R and z > FONDO + GIGANTE_ALTO:
                falta = "gigante"
            elif (r < 100 and z > -136) or (r < 124 and z > -84):
                falta = "santuario"
            elif r < ORCA_R and z > ORCA_TOPE:
                falta = "orca honda"
            elif z > -30 and r < R_PLANO:
                falta = "orca orilla"
            if falta:  # cuántos y el primero (r, z) para encontrarlo
                clave = f"{nombre}:{falta}"
                n, ej = malos.get(clave, (0, (round(r, 1), round(z, 1))))
                malos[clave] = (n + 1, ej)
    return malos


def limites(m):
    ps = [v.co for v in m.bm.verts]
    return (V((min(p.x for p in ps), min(p.y for p in ps), min(p.z for p in ps))),
            V((max(p.x for p in ps), max(p.y for p in ps), max(p.z for p in ps))))


def cerrar(mallas):
    """Caja común: simétrica en X e Y, cubitos mínimos en dos esquinas de cada malla."""
    lims = [limites(m) for m in mallas.values()]
    a = max(max(-lo.x, -lo.y, hi.x, hi.y) for lo, hi in lims)
    lo = V((-a, -a, min(lo.z for lo, _ in lims)))
    hi = V((a, a, max(hi.z for _, hi in lims)))
    for nombre, m in mallas.items():
        color = "perla" if "Brillo" in nombre else "basalto2"
        for esquina, s in ((lo, 1), (hi, -1)):
            m.caja(H.T(*(esquina + V((0.02, 0.02, 0.02)) * s)), (0.04, 0.04, 0.04), color)
    return lo, hi


def objeto(nombre, m, mat):
    bm = m.bm
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=0.0005)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    lisos = [f[m.liso] == 1 for f in bm.faces]
    me = bpy.data.meshes.new(nombre)
    bm.normal_update()
    bm.to_mesh(me)
    bm.free()
    for p, liso in zip(me.polygons, lisos):
        p.use_smooth = liso
    if hasattr(me, "set_sharp_from_angle"):
        me.set_sharp_from_angle(angle=math.radians(40))
    o = bpy.data.objects.new(nombre, me)
    o.data.materials.append(mat)
    bpy.context.scene.collection.objects.link(o)
    return o


def mat_brillo(nombre, color):
    mat = bpy.data.materials.new(nombre)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    c = [v / 255 for v in color] + [1]
    bsdf.inputs["Base Color"].default_value = c
    bsdf.inputs["Emission Color"].default_value = c
    bsdf.inputs["Emission Strength"].default_value = 1.5
    return mat


def a_mundo(p):
    """Blender (x, y, z) -> mundo relativo al centro del cráter (dx, y, dz)."""
    return [round(p.x, 2), round(p.z, 2), round(-p.y, 2)]


def exportar(objs, lo, hi, luces):
    os.makedirs(SALIDA, exist_ok=True)
    for x in bpy.data.objects:
        x.select_set(x in objs)
    bpy.ops.export_scene.fbx(filepath=FBX, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
                             path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y",
                             bake_space_transform=True, mesh_smooth_type="OFF", object_types={'MESH'})
    datos = {"ancho": round(hi.x - lo.x, 3), "alto": round(hi.z - lo.z, 3), "centroY": round((hi.z + lo.z) / 2, 3),
             "mallas": [{"nombre": o.name, "brillo": list(BRILLO[o.name]) if o.name in BRILLO else None} for o in objs],
             "luces": [{"pos": a_mundo(p), "color": list(c), "rango": rango} for p, c, rango in luces],
             "fuegos": []}
    with open(JSON, "w", encoding="utf-8") as f:
        json.dump(datos, f, indent=1, ensure_ascii=False)
        f.write("\n")


def fondo_render():
    """El fondo del lago (fórmula del contrato) como malla gris, solo para el render."""
    perfil = [(0, FONDO), (R_PLANO, FONDO), (R_LAGO, -1.0)]
    perfil += [(R_LAGO + 15 * (k / 10), -1 + 31 * (k / 10) ** 0.6) for k in range(1, 11)]
    perfil += [(240, 30.0), (260, 30.0)]
    bm = bmesh.new()
    n = 128
    anillos = []
    for r, z in perfil:
        anillos.append([bm.verts.new((max(r, 0.01) * math.cos(2 * math.pi * k / n),
                                      max(r, 0.01) * math.sin(2 * math.pi * k / n), z)) for k in range(n)])
    for a, b in zip(anillos, anillos[1:]):
        for k in range(n):
            bm.faces.new((a[k], a[(k + 1) % n], b[(k + 1) % n], b[k]))
    me = bpy.data.meshes.new("FondoRender")
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new("FondoRender", me)
    mat = bpy.data.materials.new("Fondo")
    mat.use_nodes = True
    mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.36, 0.36, 0.38, 1)
    o.data.materials.append(mat)
    bpy.context.scene.collection.objects.link(o)
    return o


def agua_render():
    bm = bmesh.new()
    bmesh.ops.create_circle(bm, cap_ends=True, segments=96, radius=R_LAGO + 2)
    for v in bm.verts:
        v.co.z = 2.0
    me = bpy.data.meshes.new("AguaRender")
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new("AguaRender", me)
    mat = bpy.data.materials.new("Agua")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.02, 0.25, 0.32, 1)
    bsdf.inputs["Alpha"].default_value = 0.55
    bsdf.inputs["Roughness"].default_value = 0.2
    for attr, val in (("surface_render_method", "BLENDED"), ("blend_method", "BLEND")):
        try:
            setattr(mat, attr, val)
        except (AttributeError, TypeError):
            pass
    o.data.materials.append(mat)
    bpy.context.scene.collection.objects.link(o)
    o.hide_render = True
    return o


def renders(luces):
    escena = bpy.context.scene
    for motor in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            escena.render.engine = motor
            break
        except TypeError:
            continue
    escena.render.resolution_x, escena.render.resolution_y = 1600, 1000
    escena.view_settings.view_transform = "Standard"
    mundo = bpy.data.worlds.new("Fondo")
    mundo.use_nodes = True
    mundo.node_tree.nodes["Background"].inputs[0].default_value = (0.32, 0.42, 0.5, 1)
    mundo.node_tree.nodes["Background"].inputs[1].default_value = 0.9
    escena.world = mundo
    sol = bpy.data.objects.new("Sol", bpy.data.lights.new("Sol", "SUN"))
    sol.data.energy = 3.2
    sol.rotation_euler = (math.radians(28), math.radians(8), math.radians(-30))
    escena.collection.objects.link(sol)
    for k, (p, c, _) in enumerate(luces):
        lz = bpy.data.objects.new(f"Luz{k}", bpy.data.lights.new(f"Luz{k}", "POINT"))
        lz.data.color = [v / 255 for v in c]
        lz.data.energy = 60000
        lz.location = p
        escena.collection.objects.link(lz)
    fondo_render()
    agua = agua_render()
    cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
    escena.collection.objects.link(cam)
    escena.camera = cam
    cam.data.clip_end = 3000
    os.makedirs(RENDERS, exist_ok=True)

    def foto(nombre, pos, mira, lente=24, con_agua=False):
        agua.hide_render = not con_agua
        cam.location = pos
        cam.rotation_euler = (V(mira) - V(pos)).to_track_quat('-Z', 'Y').to_euler()
        cam.data.lens = lente
        escena.render.filepath = os.path.join(RENDERS, nombre + ".png")
        bpy.ops.render.render(write_still=True)
        print("RENDER", escena.render.filepath)

    puerta = polar(ang(270), 220, 34)  # el paseo junto a la puerta (+Y de Blender)
    vistas = {
        "paseo_puerta": (puerta, polar(ang(90), 60, -170), 20, False),
        "paseo_sur": (polar(ang(200), 220, 34), polar(ang(20), 60, -170), 20, False),
        "paseo_norte": (polar(ang(20), 220, 34), polar(ang(200), 60, -170), 20, False),
        "borde_puerta": (polar(ang(270), 206, 34), polar(ang(90), 20, -250), 16, False),
        "aerea": ((0, -1, 700), (0, 0, -250), 26, False),
        "agua_paseo": (puerta, polar(ang(90), 60, -100), 20, True),
        "fondo_barco": (polar(ang(60), 60, -228), polar(ang(108), 150, -215), 22, False),
        "fondo_almejas": (polar(ang(250), 80, -232), polar(ang(292), 162, -238), 26, False),
        "pared_orilla": (polar(ang(0), 120, 10), polar(ang(70), 188, -30), 22, False),
    }
    solo = [a for a in ARGS if a in vistas]
    for nombre, (pos, mira, lente, con_agua) in vistas.items():
        if not solo or nombre in solo:
            foto(nombre, pos, mira, lente, con_agua)


MALLAS, LUCES, TOPE = construir()
print("PALO del barco: r", round(math.hypot(TOPE.x, TOPE.y), 1), "z", round(TOPE.z, 1), "pared",
      round(rpared(TOPE.z), 1))
print("ZONAS", revisar_zonas(MALLAS) or "ok")
LO, HI = cerrar(MALLAS)
TRIS = {n: m.tris() for n, m in MALLAS.items()}
print("HABITAT tris", TRIS, "total", sum(TRIS.values()), "caja", tuple(round(v, 2) for v in LO),
      tuple(round(v, 2) for v in HI), "luces", len(LUCES))
assert all(t <= MAX_TRIS for t in TRIS.values()), f"una malla pasa de {MAX_TRIS} triángulos: {TRIS}"
assert len(LUCES) <= 12, "más de 12 luces"
PALETA = H.material()
bpy.data.images["Habitats_color"].name = "OrcaHabitat_color"
OBJS = [objeto(n, m, mat_brillo(n, BRILLO[n]) if n in BRILLO else PALETA) for n, m in MALLAS.items()]
if "exportar" in ARGS:
    exportar(OBJS, LO, HI, LUCES)
    print("EXPORTADO", FBX)
if "render" in ARGS:
    renders(LUCES)
