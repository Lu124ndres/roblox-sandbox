r"""
Base del hábitat del zorro de agua (habitat_zorrodeagua.py): paleta, la clase Malla, la forma
del fondo del cráter y las zonas que el hábitat no puede tocar.

Coordenadas (docs/contrato_habitat_completo.md): 1 unidad = 1 stud, origen en el centro del
cráter a Y = 0 del mundo, Z de Blender = Y del mundo (altura absoluta). Un ángulo `a` del cráter
(grados desde +X, x = cos, z = sin) cae en Blender en (r·cos a, -r·sin a): eso hace polar().
"""
import bmesh, json, math, os, random
from mathutils import Matrix, Vector

V = Vector
RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
with open(os.path.join(RAIZ, "src", "shared", "WorldLayoutData.json"), encoding="utf-8") as _f:
    _L = json.load(_f)
AGUA = float(_L["waterLevel"])  # 2
LAGO = float(_L["craterLakeRadius"])  # 190: empieza el acantilado
PASEO = float(_L["craterCliffRadius"])  # 205: el paseo de los jugadores
BORDE_Y = float(_L["craterRimHeight"])  # 30
PUERTA = (_L["bridgeAngle"] + 180) % 360  # 270: por ahí llega el puente
PUERTA_HUECO = 22  # grados a cada lado de la puerta sin nada alto (como IceShore.DOOR_GAP)
TECHO = BORDE_Y - 0.3  # lo más alto que llega una pieza (nunca por encima del paseo)
rnd = random.Random(71)

# Los lugares del zorro, copiados de src/shared/Zorro/Guarida.luau (nombre, ángulo, radio,
# radio de la parte plana, tipo). Las losas y la roca son de primitivas (IceFloes, IceRocks):
# el hábitat les deja lugar alrededor. `libre` es el radio que no se toca: el borde de un
# témpano grande llega a ~1.6 veces su `size` más la repisa (IceFloes.BIG, LEDGE_GROW); la roca
# de vigía, su `size` más el pie que se abre en el agua (IceFloes.ROCK_FLARE).
SPOTS = (
    ("Centro", 0, 0, 36, "tempano"),
    ("Puerta", 215, 115, 30, "tempano"),
    ("Orilla", 330, 110, 30, "tempano"),
    ("Fondo", 100, 112, 32, "tempano"),
    ("Vigia", 160, 128, 24, "roca"),
)
SPOT_TOP = {"tempano": 1.2, "roca": 14.0}  # alto de la cima sobre el agua

COLORES = {
    "hielo": (222, 243, 252), "hielo2": (176, 226, 244), "hielo3": (96, 186, 222), "hielo4": (140, 208, 236),
    "nieve": (240, 248, 255), "escarcha": (212, 234, 247), "grieta": (64, 140, 190), "cueva": (28, 58, 88),
    "roca": (84, 94, 108), "roca2": (100, 110, 124), "roca3": (70, 78, 92), "roca4": (116, 124, 138),
    "rocaesc": (150, 166, 182), "cristal": (191, 243, 255), "cristal2": (143, 216, 240), "cristal3": (230, 247, 255),
}
NOMBRES = list(COLORES)
CELDA, LADO = 32, 4
ROCAS = ("roca", "roca2", "roca3", "roca", "roca4")
BRILLO = (170, 228, 255)  # el Neon celeste suave de los cristales


def suelo(r):
    """Fondo del lago de cuenco (WorldZones.lakeFloor y CraterShape.height)."""
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


def polar(a, r, z):
    t = math.radians(a)
    return V((r * math.cos(t), -r * math.sin(t), z))


def afuera(a):
    t = math.radians(a)
    return V((math.cos(t), -math.sin(t), 0))


def ejes(a, inclinar=0.0, girar=0.0):
    """Ejes de un bloque en el ángulo `a` del cráter: X hacia afuera, Y a lo largo de la orilla,
    Z arriba; `inclinar` (rad) tumba la cima hacia afuera y `girar` (rad) gira sobre Z."""
    x = afuera(a)
    z = V((0, 0, 1))
    y = z.cross(x)
    m = Matrix((x, y, z)).transposed()
    if girar:
        m = Matrix.Rotation(girar, 3, z) @ m
    if inclinar:
        m = Matrix.Rotation(inclinar, 3, m.col[1]) @ m
    return m


def angulo(p):
    return math.degrees(math.atan2(-p.y, p.x)) % 360


def dif(a, b):
    return (a - b + 180) % 360 - 180


def contorno(rad, lados, estirar=0.35, ruido=0.18):
    """Polígono chueco (Vector2, antihorario) de radio medio `rad`."""
    giro, puntos = rnd.uniform(0, math.tau), []
    for k in range(lados):
        t = (k + rnd.uniform(-0.22, 0.22)) / lados * math.tau
        r = rad * (1 + estirar * math.cos(2 * t)) / (1 + estirar * 0.5) * rnd.uniform(1 - ruido, 1 + ruido)
        puntos.append(V((math.cos(t + giro) * r, math.sin(t + giro) * r)))
    return puntos


# --- Zonas --------------------------------------------------------------------------------------

OCUPADO = []  # discos (centro Vector2, radio) que ya tienen algo: rocas, cuevas, cristales


def ocupar(p, rad):
    OCUPADO.append((V((p.x, p.y)), rad))


def choca_spot(p, rad, justo=False):
    """¿Un disco de radio `rad` en `p` entra en el lugar de un témpano grande o de la roca de
    vigía? `justo`: con el borde más probable (1.7 veces `size`) en vez del más ancho posible;
    para lo que va a ras del agua (banquisa, nieve), que puede llegar más cerca."""
    for _, a, r, size, tipo in SPOTS:
        c = polar(a, r, 0)
        if tipo == "tempano":
            libre = size * (1.7 if justo else 1.85)
        else:
            libre = size + (20 if justo else 26)
        if (V((p.x, p.y)) - c.xy).length < libre + rad:
            return True
    return False


def zona_ok(p, rad, alto=0.0, margen=4.0):
    """¿Cabe un disco de radio `rad` en `p` con la cima a `alto` (Y)? Fuera del santuario y del
    gigante (r - rad >= 125), dentro del cráter, lejos de los lugares del zorro, de la puerta (si es
    alto) y de lo que ya está puesto."""
    r = p.xy.length
    if r - rad < 125 or choca_spot(p, rad):
        return False
    if alto > AGUA + 3 and abs(dif(angulo(p), PUERTA)) < PUERTA_HUECO + math.degrees(rad / max(r, 1)):
        return False
    return all((p.xy - c).length >= rad + rc + margen for c, rc in OCUPADO)


def cabe(centro, tam, giro):
    """¿Las 8 esquinas de la caja quedan dentro del cráter (antes del paseo y bajo su altura)?"""
    for sx in (-0.5, 0.5):
        for sy in (-0.5, 0.5):
            for sz in (-0.5, 0.5):
                q = V(centro) + giro @ V((sx * tam[0], sy * tam[1], sz * tam[2]))
                if q.z > TECHO or q.xy.length > PASEO - 0.4:
                    return False
    return True


class Malla:
    def __init__(self, nombre):
        self.nombre = nombre
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.verify()

    def _uv(self, color):
        i = NOMBRES.index(color)
        return V((((i % LADO) + 0.5) / LADO, ((i // LADO) + 0.5) / LADO))

    def pintar(self, caras, color):
        uv = self._uv(color)
        for f in caras:
            for l in f.loops:
                l[self.uv].uv = uv

    def _por_cara(self, caras, centro, arriba, lados):
        for f in caras:
            f.normal_update()
            n = f.normal if (f.calc_center_median() - centro).dot(f.normal) >= 0 else -f.normal
            self.pintar([f], arriba if n.z > 0.55 else lados)

    def bloque(self, centro, tam, arriba, lados=None, giro=None):
        """Caja de `tam` (x, y, z) girada por `giro` (columnas = ejes locales); la cara que mira
        arriba toma `arriba` y las demás `lados`."""
        r = bmesh.ops.create_cube(self.bm, size=1.0)
        g = giro or Matrix.Identity(3)
        c = V(centro)
        for v in r["verts"]:
            v.co = g @ V((v.co.x * tam[0], v.co.y * tam[1], v.co.z * tam[2])) + c
        self._por_cara({f for v in r["verts"] for f in v.link_faces}, c, arriba, lados or arriba)

    def prisma(self, centro, puntos, z0, z1, arriba, lados=None):
        """Losa vertical sobre el polígono `puntos` (Vector2 desde `centro`), de z0 a z1."""
        cx, cy = centro[0], centro[1]
        abajo = [self.bm.verts.new((cx + p.x, cy + p.y, z0)) for p in puntos]
        tope = [self.bm.verts.new((cx + p.x, cy + p.y, z1)) for p in puntos]
        caras = [self.bm.faces.new(tope), self.bm.faces.new(list(reversed(abajo)))]
        n = len(puntos)
        for k in range(n):
            caras.append(self.bm.faces.new((abajo[k], abajo[(k + 1) % n], tope[(k + 1) % n], tope[k])))
        self._por_cara(caras, V((cx, cy, (z0 + z1) / 2)), arriba, lados or arriba)

    def cristal(self, base, eje, ancho, alto, color, lados=5):
        """Prisma de `lados` caras con punta, que crece de `base` hacia `eje`."""
        e = V(eje).normalized()
        a = e.orthogonal().normalized()
        b = e.cross(a)
        giro = rnd.uniform(0, math.tau)
        base = V(base)

        def anillo(c, r):
            return [self.bm.verts.new(c + (a * math.cos(giro + k * math.tau / lados)
                                           + b * math.sin(giro + k * math.tau / lados)) * r) for k in range(lados)]

        r0 = anillo(base, ancho)
        r1 = anillo(base + e * alto * 0.74, ancho * 0.92)
        punta = self.bm.verts.new(base + e * alto)
        caras = [self.bm.faces.new(list(reversed(r0)))]
        for k in range(lados):
            j = (k + 1) % lados
            caras.append(self.bm.faces.new((r0[k], r0[j], r1[j], r1[k])))
            caras.append(self.bm.faces.new((r1[k], r1[j], punta)))
        self.pintar(caras, color)

    def tris(self):
        return sum(len(f.verts) - 2 for f in self.bm.faces)

    def limites(self):
        ps = [v.co for v in self.bm.verts]
        return (V((min(p.x for p in ps), min(p.y for p in ps), min(p.z for p in ps))),
                V((max(p.x for p in ps), max(p.y for p in ps), max(p.z for p in ps))))
