r"""
Hábitat del DragonMarino: constantes de los contratos del juego, paleta y la Malla con sus
primitivas (bloques, columnas de basalto, cristales, tornos, tubos y barras). Lo usan
habitat_dragonmarino_penones.py, habitat_dragonmarino_orilla.py, habitat_dragonmarino_borde.py
y habitat_dragonmarino.py (el que se corre).
"""
import bpy, bmesh, json, math, os, random, sys
from mathutils import Matrix, Vector

V = Vector
TAU = 2 * math.pi
RAIZ = globals().get("RAIZ") or os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
ID = "DragonMarino"
DIR = os.path.join(RAIZ, "assets", "blender", "habitat_dragonmarino")
FBX = os.path.join(DIR, f"{ID}Habitat.fbx")
CAJA_JSON = os.path.join(DIR, f"{ID}Habitat.json")
TEX = os.path.join(RAIZ, "assets", "textures", f"{ID}Habitat_color.png")
RENDERS = os.path.join(RAIZ, "renders", "habitat_dragonmarino")
MAX_TRIS = 9800

COLORES = {
    # basalto (LairCrag.SHADES) y lo que toca la lava
    "basalto": (36, 32, 38), "basalto2": (47, 42, 47), "basalto3": (26, 23, 28), "basalto4": (20, 18, 23),
    "cima": (62, 56, 62), "cima2": (74, 66, 70), "obsidiana": (22, 18, 28), "obsidiana2": (40, 31, 46),
    "caliente": (62, 30, 24), "caliente2": (80, 40, 30), "costra": (84, 38, 28), "costra2": (58, 28, 24),
    "ceniza": (64, 56, 58), "ceniza2": (82, 72, 74), "ceniza3": (100, 90, 88), "carbon": (38, 31, 30),
    # huesos, huevos y escamas del dragón marino (LairNest)
    "hueso": (196, 182, 160), "hueso2": (170, 156, 134), "hueso3": (140, 126, 108), "cuerno": (110, 96, 84),
    "cascara": (32, 128, 138), "cascara2": (26, 104, 126), "cascara3": (44, 150, 138),
    "mancha": (120, 222, 208), "mancha2": (16, 66, 80),
    "escama": (30, 112, 122), "escama2": (22, 84, 98), "escama3": (62, 156, 146),
    # lava (LairParts.MAGMA, MAGMA_HOT, EMBER)
    "lava": (255, 98, 22), "lava2": (255, 176, 64), "lava3": (255, 60, 20),
}
NOMBRES = list(COLORES)
LADO, CELDA = 8, 32  # textura de 256 x 256, celdas de 32 px
PIEDRA = ("basalto", "basalto2", "basalto3", "basalto4", "basalto")

# --- Contratos del juego ----------------------------------------------------------------
LAVA = -25.0  # Dragon/Guarida.lava (CraterLava.LEVEL)
# Dragon/Guarida.perches: ángulo (grados), radio, alto de la cima sobre la lava, radio de la cima
PERCHES = ((0, 0, 22, 34), (35, 115, 14, 26), (155, 132, 18, 26), (265, 112, 10, 24))
NIDO_OFFSET = (0.0, 0.0, 12.0)  # Guarida.nest.offset (mundo) sobre la central
BAJO = 14.0  # cuánto sigue la roca bajo la lava (LairRocks.BELOW)
FLARE = 11.0  # cuánto más ancha es la roca en la lava que arriba
# LairFalls: ángulos y recorrido (radio, desvío) del acantilado a la lava
CASCADAS = (15, 105, 215, 295)
FALL = (201, 197, 193.5, 190.6)
RIVER = ((187, 0), (176, 3.5), (163, -3), (151, 1))
DROP = (151, 146, 140, 131)
GAP = 1.8
VENTS = ((52, 168), (197, 165))  # bocas de LairVents en la repisa (quedan de primitivas)
CRISTALES = ((45, 182, 1.9), (112, 184, 1.7), (165, 183, 2.0), (288, 183, 1.9), (322, 184, 1.7), (352, 184, 2.0))
CRISTALES_PARED = ((60, 1.1), (200, 1.15), (345, 1.1))  # en el acantilado, r 196
FUMAROLAS = ((0, 161, 1.9), (180, 158, 2.0), (275, 172, 1.7))
# Peñascos de la orilla: ángulo, radio del centro, radio, alto de la cima (Y)
PENASCOS = ((75, 140, 13, 9), (125, 140, 12, 4), (192, 141, 13, 13), (232, 139, 12, 6),
            (318, 139, 13, 10), (347, 140, 12, 2))
ESQUELETO = (243, 171)  # ángulo y radio del centro
AGUJAS = ((70, 172, 44), (310, 168, 38), (340, 171, 48))  # agujas de la repisa: ángulo, radio, Y de la punta
CRANEO = (90, 192)  # cráneo colosal tallado en el acantilado, frente a la puerta: ángulo y radio
ARCO = (127, 143, 176)  # arco de basalto en la repisa: ángulos de las patas y radio
PUERTA, PUERTA_HUECO = 270, 13  # el puente llega por aquí: el acantilado queda libre
PASEO_Y = 30.0


def piso(r):
    """Fondo del lago de cuenco (contrato; WorldZones.lakeFloor y CraterShape.height)."""
    if r < 75:
        return -150.0
    if r < 150:
        t = (r - 75) / 75
        return -150 + 142 * (1 - math.cos(math.pi * t)) / 2
    if r < 190:
        return -8 + 7 * (r - 150) / 40
    if r < 205:
        return -1 + 31 * ((r - 190) / 15) ** 0.6
    return PASEO_Y


def en(grados, r, y):
    a = math.radians(grados)
    return V((r * math.cos(a), -r * math.sin(a), y))


def lado_de(grados):
    """El costado de LairFalls (side = (-out.Z, 0, out.X) del mundo) en Blender."""
    a = math.radians(grados)
    return V((-math.sin(a), -math.cos(a), 0))


def radio_de(p):
    return math.hypot(p.x, p.y)


def angulo_de(p):
    return math.degrees(math.atan2(-p.y, p.x)) % 360


def dif(a, b):
    return abs((a - b + 180) % 360 - 180)


def perch_top(perch):
    ang, r, top, size = perch
    return en(ang, r, LAVA + top), size


# --- Paleta y malla ------------------------------------------------------------------------
def hacer_paleta():
    n = LADO * CELDA
    img = bpy.data.images.get(f"{ID}Habitat_color") or bpy.data.images.new(f"{ID}Habitat_color", n, n)
    px = [0.5] * (n * n * 4)
    for i, nombre in enumerate(NOMBRES):
        cx, cy = (i % LADO) * CELDA, (i // LADO) * CELDA
        r, g, b = (c / 255 for c in COLORES[nombre])
        for y in range(cy, cy + CELDA):
            for x in range(cx, cx + CELDA):
                k = (y * n + x) * 4
                px[k:k + 4] = [r, g, b, 1.0]
    img.pixels = px
    img.filepath_raw = TEX
    img.file_format = "PNG"
    os.makedirs(os.path.dirname(TEX), exist_ok=True)
    img.save()
    return img


def uv_de(color):
    i = NOMBRES.index(color)
    return V((((i % LADO) + 0.5) / LADO, ((i // LADO) + 0.5) / LADO))


class Malla:
    def __init__(self):
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.verify()

    def cara(self, vs, color):
        f = self.bm.faces.new(vs)
        c = uv_de(color)
        for l in f.loops:
            l[self.uv].uv = c
        return f

    def pintar(self, verts, color):
        c = uv_de(color)
        for f in {f for v in verts for f in v.link_faces}:
            for l in f.loops:
                l[self.uv].uv = c

    def bloque(self, centro, tam, color, giro=None):
        """Caja de `tam` (x, y, z) girada por `giro` (3x3, columnas = ejes locales)."""
        r = bmesh.ops.create_cube(self.bm, size=1.0)
        g = giro or Matrix.Identity(3)
        for v in r["verts"]:
            v.co = g @ V((v.co.x * tam[0], v.co.y * tam[1], v.co.z * tam[2])) + V(centro)
        self.pintar(r["verts"], color)

    def columna(self, base, alto, radio, color, tapa=None, lados=6, giro=math.pi / 6, eje=None,
                fondo=False, arriba=None, solo_tapa=False):
        """Prisma de `lados` desde `base` a lo largo de `eje` (vertical si no). `arriba`: radio
        de la tapa (si no, igual). Sin tapa de abajo salvo `fondo` (va enterrada). `solo_tapa`:
        solo la cara de arriba (columnas rodeadas de otras: sus costados no se ven)."""
        e = (eje or V((0, 0, 1))).normalized()
        rot = V((0, 0, 1)).rotation_difference(e).to_matrix()
        u, w = rot @ V((1, 0, 0)), rot @ V((0, 1, 0))
        b0, t0 = V(base), V(base) + e * alto
        ra = radio if arriba is None else arriba
        abajo, cima = [], []
        for k in range(lados):
            a = giro + TAU * k / lados
            d = u * math.cos(a) + w * math.sin(a)
            cima.append(self.bm.verts.new(t0 + d * ra))
            if not solo_tapa:
                abajo.append(self.bm.verts.new(b0 + d * radio))
        if solo_tapa:
            self.cara(cima, tapa or color)
            return
        for k in range(lados):
            j = (k + 1) % lados
            self.cara((abajo[k], abajo[j], cima[j], cima[k]), color)
        self.cara(cima, tapa or color)
        if fondo:
            self.cara(list(reversed(abajo)), color)

    def cristal(self, base, eje, radio, alto, color, lados=4):
        """Prisma con punta (los cristales de LairCrystals): cuerpo hasta 0.75 y punta."""
        e = eje.normalized()
        rot = V((0, 0, 1)).rotation_difference(e).to_matrix()
        u, w = rot @ V((1, 0, 0)), rot @ V((0, 1, 0))
        b0 = V(base)
        abajo, medio = [], []
        for k in range(lados):
            a = math.pi / 4 + TAU * k / lados
            d = u * math.cos(a) + w * math.sin(a)
            abajo.append(self.bm.verts.new(b0 + d * radio))
            medio.append(self.bm.verts.new(b0 + e * alto * 0.75 + d * radio))
        punta = self.bm.verts.new(b0 + e * alto)
        for k in range(lados):
            j = (k + 1) % lados
            self.cara((abajo[k], abajo[j], medio[j], medio[k]), color)
            self.cara((medio[k], medio[j], punta), color)

    def torno(self, centro, perfil, lados, colores, giro=0.0, ruido=0.0, rnd=None):
        """Sólido de revolución: perfil [(radio, z)] de abajo arriba, tapa arriba."""
        anillos = []
        for r, z in perfil:
            ring = []
            for k in range(lados):
                a = giro + TAU * k / lados
                rr = r * (1 + (rnd.uniform(-1, 1) * ruido if rnd else 0))
                ring.append(self.bm.verts.new(V(centro) + V((math.cos(a) * rr, math.sin(a) * rr, z))))
            anillos.append(ring)
        for i in range(len(anillos) - 1):
            a, b = anillos[i], anillos[i + 1]
            for k in range(lados):
                j = (k + 1) % lados
                self.cara((a[k], a[j], b[j], b[k]), colores[(i + k) % len(colores)])
        self.cara(anillos[-1], colores[0])

    def esfera(self, centro, radios, color, sub=1, giro=None, rnd=None, ruido=0.0):
        r = bmesh.ops.create_icosphere(self.bm, subdivisions=sub, radius=1.0)
        g = giro or Matrix.Identity(3)
        for v in r["verts"]:
            k = 1 + (rnd.uniform(-1, 1) * ruido if rnd else 0)
            v.co = g @ V((v.co.x * radios[0] * k, v.co.y * radios[1] * k, v.co.z * radios[2] * k)) + V(centro)
        self.pintar(r["verts"], color)

    def tubo(self, puntos, radios, lados, color):
        n = len(puntos)
        tang = [(puntos[min(i + 1, n - 1)] - puntos[max(i - 1, 0)]).normalized() for i in range(n)]
        ref = V((0, 0, 1)) if abs(tang[0].z) < 0.9 else V((1, 0, 0))
        u = tang[0].cross(ref).normalized()
        anillos = []
        for i in range(n):
            if i:
                u = (u - tang[i] * u.dot(tang[i])).normalized()
            w = tang[i].cross(u)
            anillos.append([self.bm.verts.new(puntos[i] + (u * math.cos(TAU * k / lados) + w * math.sin(TAU * k / lados))
                                              * radios[i]) for k in range(lados)])
        for i in range(n - 1):
            a, b = anillos[i], anillos[i + 1]
            for k in range(lados):
                j = (k + 1) % lados
                self.cara((a[k], a[j], b[j], b[k]), color)
        self.cara(list(reversed(anillos[0])), color)
        punta = self.bm.verts.new(puntos[-1] + tang[-1] * radios[-1] * 0.8)
        for k in range(lados):
            self.cara((anillos[-1][k], anillos[-1][(k + 1) % lados], punta), color)

    def barra(self, a, b, ancho, grosor, color, arriba=None):
        """Caja de a a b (LairParts.bar): `ancho` de costado, `grosor` hacia arriba."""
        a, b = V(a), V(b)
        largo = (b - a).normalized()
        up = arriba or (V((1, 0, 0)) if abs(largo.z) > 0.98 else V((0, 0, 1)))
        lado = largo.cross(up).normalized()
        g = Matrix((lado, largo, lado.cross(largo))).transposed()
        self.bloque((a + b) / 2, (ancho, (b - a).length, grosor), color, g)

    def tris(self):
        return sum(len(f.verts) - 2 for f in self.bm.faces)

    def limites(self):
        ps = [v.co for v in self.bm.verts]
        return (V((min(p.x for p in ps), min(p.y for p in ps), min(p.z for p in ps))),
                V((max(p.x for p in ps), max(p.y for p in ps), max(p.z for p in ps))))


def girar_al_azar(rnd, fuerza):
    return (Matrix.Rotation(rnd.uniform(0, TAU), 3, "Z") @ Matrix.Rotation(rnd.uniform(-fuerza, fuerza), 3, "X")
            @ Matrix.Rotation(rnd.uniform(-fuerza, fuerza), 3, "Y"))


def hexagonos(radio_max, c):
    """Centros de una grilla hexagonal (columnas de radio circunscrito c) dentro del círculo."""
    dx, dy = math.sqrt(3) * c, 1.5 * c
    filas = int(radio_max / dy) + 1
    for j in range(-filas, filas + 1):
        off = dx / 2 if j % 2 else 0.0
        cols = int(radio_max / dx) + 2
        for i in range(-cols, cols + 1):
            x, y = i * dx + off, j * dy
            if math.hypot(x, y) <= radio_max:
                yield x, y


def ejes(theta, inclinar=0.0):
    """Ejes de un bloque en el ángulo theta (radianes, en el plano XY de Blender): X radial,
    Y tangente, Z arriba (inclinado `inclinar` radianes hacia afuera)."""
    radial = V((math.cos(theta), math.sin(theta), 0))
    tangente = V((-math.sin(theta), math.cos(theta), 0))
    arriba = V((0, 0, 1))
    if inclinar:
        rot = Matrix.Rotation(inclinar, 3, tangente)
        radial, arriba = rot @ radial, rot @ arriba
    return Matrix((radial, tangente, arriba)).transposed()


def racimo(brillo, roca, base, eje, escala, rnd, color="lava2", pie="obsidiana"):
    """Racimo de cristales de fuego (LairCrystals.cluster): uno alto en el medio y cinco
    inclinados alrededor, con un pie de roca oscura. `eje`: hacia dónde crecen."""
    e = eje.normalized()
    rot = V((0, 0, 1)).rotation_difference(e).to_matrix()
    brillo.cristal(base, e, 1.1 * escala, 9 * escala, color)
    for k in range(5):
        alrededor = TAU * k / 5 + rnd.uniform(-0.3, 0.3)
        abre = math.radians(rnd.uniform(18, 38))
        d = rot @ V((math.cos(alrededor), math.sin(alrededor), 0))
        eje_k = (e * math.cos(abre) + d * math.sin(abre)).normalized()
        brillo.cristal(V(base) + d * 1.4 * escala, eje_k, rnd.uniform(0.65, 0.9) * escala,
                       rnd.uniform(3.5, 6.5) * escala, color)
    roca.bloque(V(base) + e * 0.2 * escala, (4.6 * escala, 4.2 * escala, 1.6 * escala), pie, rot)

