r"""
Guarida del descanso como santuario flotante (pedido del usuario, 2026-10-23): una isla de
roca volcánica que flota sobre el lago vacío, a restArenaTop. Estilo de bloques, como el
arco y el volcán:
    arriba   piso de losas en anillos, estrado central de tres escalones con cristales de
             magma, muro bajo de sillares y 8 pilares con un cristal de magma en la punta;
    runas    anillos de lava incrustados en el piso y glifos entre ellos;
    abajo    un cono de roca invertido (anillos de bloques que se afinan hacia la punta),
             con vetas de lava que bajan hasta una gota encendida;
    cadenas  8 cadenas de basalto colgando de los pilares, con una roca de lastre;
    halo     16 piedras rúnicas que flotan alrededor, debajo del borde.

Varias mallas con la MISMA caja (cubitos mínimos en las esquinas de la caja común), para que
PropDresser las ponga con ajuste "caja" sin desfasarse (ninguna pasa de 9.800 triángulos):
    GuaridaPiso      piso y estrado
    GuaridaRoca      el cono de abajo, los pilares y el halo
    GuaridaBorde     el muro, las cadenas y los lastres
    GuaridaLava      runas, cristales y vetas (en el juego es Neon naranja: brilla sola)
Medidas en studs, origen en el centro del piso (arriba del piso = 0); Z hacia arriba.
Radio del piso = restArenaRadius (WorldLayoutData.json). La pieza que se choca es el Piso de
primitivas (tools/generar_isla.py): las mallas no chocan.
Exporta assets/blender/GuaridaSantuario.fbx (textura embebida),
assets/textures/GuaridaSantuario_color.png, la caja en assets/blender/GuaridaSantuario.json
(la lee generar_isla.py) y una vista previa en assets/blender/render/GuaridaSantuario.png.

Uso sin abrir Blender:
    blender -b --factory-startup --python tools/blender/guarida_santuario.py -- exportar render
"""
import bpy, bmesh, json, math, os, random, sys
from mathutils import Matrix, Vector

V = Vector
RAIZ = globals().get("RAIZ") or os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
TEX = os.path.join(RAIZ, "assets", "textures", "GuaridaSantuario_color.png")
FBX = os.path.join(RAIZ, "assets", "blender", "GuaridaSantuario.fbx")
CAJA_JSON = os.path.join(RAIZ, "assets", "blender", "GuaridaSantuario.json")
RENDER = os.path.join(RAIZ, "assets", "blender", "render", "GuaridaSantuario.png")
LAYOUT = os.path.join(RAIZ, "src", "shared", "WorldLayoutData.json")
rnd = random.Random(23)

COLORES = {
    "basalto": (44, 38, 46), "basalto2": (60, 52, 60), "basalto3": (30, 26, 32), "ceniza": (82, 72, 74),
    "obsidiana": (22, 18, 28), "losa": (68, 60, 66), "losa2": (54, 47, 55), "musgo": (48, 44, 40),
    "lava": (255, 120, 30), "lava2": (255, 192, 60), "lava3": (255, 70, 24),
}
NOMBRES = list(COLORES)
PIEDRA = ("basalto", "basalto2", "basalto3", "basalto", "ceniza")
LOSAS = ("losa", "losa2", "losa", "basalto2", "ceniza")
CELDA, LADO = 32, 4
MAX_TRIS = 9800

with open(LAYOUT, encoding="utf-8") as f:
    R = float(json.load(f)["restArenaRadius"])  # radio del piso
ESTRADO = ((20.0, 1.2), (14.0, 2.6), (8.0, 4.2))  # (radio, alto de la cara de arriba)
PILARES = [22.5 + 45 * k for k in range(8)]  # ángulos (grados) de los pilares del borde
PILAR_ALTO = 24.0
GIRO_Z, GIRO_R = 13.0, 9.0  # anillos cruzados alrededor del cristal de poder
CONO_PISOS, CONO_PASO = 14, 7.0  # anillos del cono de abajo y su alto
HALO_R, HALO_N = R + 16, 16
CADENA_R, CADENA_ESLABONES, ESLABON = R + 5.5, 12, 3.8


def hacer_paleta():
    img = bpy.data.images.get("GuaridaSantuario_color") or bpy.data.images.new("GuaridaSantuario_color", 128, 128)
    px = [0.0] * (128 * 128 * 4)
    for i, n in enumerate(NOMBRES):
        cx, cy = (i % LADO) * CELDA, (i // LADO) * CELDA
        r, g, b = (c / 255 for c in COLORES[n])
        for y in range(cy, cy + CELDA):
            for x in range(cx, cx + CELDA):
                k = (y * 128 + x) * 4
                px[k:k + 4] = [r, g, b, 1.0]
    img.pixels = px
    img.filepath_raw = TEX
    img.file_format = 'PNG'
    os.makedirs(os.path.dirname(TEX), exist_ok=True)
    img.save()
    return img


class Malla:
    def __init__(self):
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.verify()

    def pintar(self, verts, color):
        i = NOMBRES.index(color)
        uv = V((((i % LADO) + 0.5) / LADO, ((i // LADO) + 0.5) / LADO))
        for f in {f for v in verts for f in v.link_faces}:
            for l in f.loops:
                l[self.uv].uv = uv

    def bloque(self, centro, tam, color, giro=None):
        """Caja de `tam` (x, y, z) girada por la matriz `giro` (columnas = ejes locales)."""
        r = bmesh.ops.create_cube(self.bm, size=1.0)
        g = giro or Matrix.Identity(3)
        for v in r["verts"]:
            v.co = g @ V((v.co.x * tam[0], v.co.y * tam[1], v.co.z * tam[2])) + V(centro)
        self.pintar(r["verts"], color)

    def cilindro(self, centro, radio, alto, color, lados=48):
        r = bmesh.ops.create_cone(self.bm, cap_ends=True, segments=lados, radius1=radio, radius2=radio, depth=alto)
        for v in r["verts"]:
            v.co += V(centro)
        self.pintar(r["verts"], color)

    def tris(self):
        return sum(len(f.verts) - 2 for f in self.bm.faces)

    def limites(self):
        xs = [v.co for v in self.bm.verts]
        return (V((min(p.x for p in xs), min(p.y for p in xs), min(p.z for p in xs))),
                V((max(p.x for p in xs), max(p.y for p in xs), max(p.z for p in xs))))


def ejes(theta, inclinar=0.0):
    """Ejes de un bloque en el ángulo theta: X radial, Y tangente, Z arriba (inclinado
    `inclinar` radianes hacia afuera)."""
    radial = V((math.cos(theta), math.sin(theta), 0))
    tangente = V((-math.sin(theta), math.cos(theta), 0))
    arriba = V((0, 0, 1))
    if inclinar:
        rot = Matrix.Rotation(inclinar, 3, tangente)
        radial, arriba = rot @ radial, rot @ arriba
    return Matrix((radial, tangente, arriba)).transposed()


def polar(theta, radio, z):
    return V((radio * math.cos(theta), radio * math.sin(theta), z))


def piedra():
    return rnd.choice(PIEDRA)


def piso(p):
    """Losas en anillos de 8 studs sobre una losa oscura (las juntas se ven negras)."""
    p.cilindro((0, 0, -1.4), R, 2.6, "basalto3", 64)
    r0 = ESTRADO[0][0] - 1
    while r0 < R - 2.5:
        r1 = min(r0 + 8, R - 2.5)
        rc = (r0 + r1) / 2
        n = max(8, round(2 * math.pi * rc / 10))
        corrido = rnd.uniform(0, 1)
        for k in range(n):
            t = 2 * math.pi * (k + corrido) / n
            alto = 2 + rnd.uniform(-0.08, 0.08)
            p.bloque(polar(t, rc, alto / 2 - 2 + 0.02), (r1 - r0 - 0.35, 2 * math.pi * rc / n - 0.35, alto),
                     rnd.choice(LOSAS), ejes(t))
        r0 = r1


def estrado(p, l):
    """Tres escalones de sillares con labio de lava; cristales de magma en el primero."""
    abajo = 0.0
    for k, (radio, alto) in enumerate(ESTRADO):
        p.cilindro((0, 0, (abajo + alto) / 2), radio - 0.6, alto - abajo, "basalto3", 40)
        n = max(10, round(2 * math.pi * radio / 4.5))
        for j in range(n):
            t = 2 * math.pi * (j + 0.5 * k) / n
            p.bloque(polar(t, radio - 0.9, (abajo + alto) / 2), (1.8, 2 * math.pi * radio / n - 0.2, alto - abajo),
                     "obsidiana" if k == 2 else piedra(), ejes(t))
        l.cilindro((0, 0, alto + 0.04), radio - 2.2, 0.1, "lava2" if k == 2 else "lava", 40)
        p.cilindro((0, 0, alto + 0.06), radio - 2.6, 0.12, "obsidiana", 40)
        abajo = alto
    for k in range(4):
        t = math.radians(45 + 90 * k)
        racimo(l, polar(t, (ESTRADO[0][0] + ESTRADO[1][0]) / 2, ESTRADO[0][1]), t, 1.8)


def racimo(l, base, theta, escala):
    """Cristales de magma: prismas largos inclinados hacia afuera, el del medio más alto."""
    for j, (alto, ancho, abre, gira) in enumerate(((7, 1.6, 0.0, 0), (4.6, 1.2, 0.45, 1.2), (5.2, 1.3, 0.4, -1.1),
                                                     (3.4, 1.0, 0.6, 2.4), (3.0, 0.9, 0.55, -2.5))):
        t = theta + gira * 0.5
        g = ejes(t, abre + rnd.uniform(-0.08, 0.08))
        a = alto * escala
        c = V(base) + g @ V((0, 0, a / 2 - 0.6))
        l.bloque(c, (ancho * escala, ancho * escala, a), "lava2" if j == 0 else rnd.choice(("lava", "lava3")), g)


def giroscopio(s, l):
    """Dos anillos verticales cruzados de sillares con una franja de lava por dentro,
    alrededor del cristal de poder (que es de primitivas: tools/generar_isla.py)."""
    n = 28
    for plano in (0.0, math.pi / 2):
        lado = V((math.cos(plano), math.sin(plano), 0))
        normal = V((0, 0, 1)).cross(lado)
        for k in range(n):
            a = 2 * math.pi * (k + 0.5) / n
            radial = lado * math.cos(a) + V((0, 0, math.sin(a)))
            tangente = radial.cross(normal)
            g = Matrix((radial, normal, tangente)).transposed()
            c = V((0, 0, GIRO_Z)) + radial * GIRO_R
            largo = 2 * math.pi * GIRO_R / n
            s.bloque(c, (1.4, 1.2 if plano else 1.0, largo - 0.12), "obsidiana", g)
            l.bloque(c - radial * 0.75, (0.2, 0.6, largo - 0.3), "lava2" if k % 4 == 0 else "lava", g)


def runas(l):
    """Anillos de lava a rayas incrustados en el piso y glifos entre ellos."""
    for radio, n, ancho in ((ESTRADO[0][0] + 2.5, 32, 0.7), (48, 64, 0.9), (R - 6, 96, 1.0)):
        for k in range(n):
            if k % 8 == 7:
                continue  # un hueco cada tanto: se lee como runa, no como aro
            t = 2 * math.pi * (k + 0.5) / n
            l.bloque(polar(t, radio, 0.06), (ancho, 2 * math.pi * radio / n - 0.5, 0.14), "lava", ejes(t))
    glifos = (
        ((0, 0, 0.5, 3.2), (0, 1.2, 2.2, 0.5), (0, -1.2, 2.2, 0.5)),
        ((0, 0, 3.2, 0.5), (-1.2, 0.6, 0.5, 2.0), (1.2, -0.6, 0.5, 2.0)),
        ((-0.9, 0, 0.5, 3.2), (0.9, 0, 0.5, 3.2), (0, 0, 2.3, 0.5)),
        ((0, 1.1, 2.6, 0.5), (0, -1.1, 2.6, 0.5), (0, 0, 0.5, 1.8)),
    )
    for radio, n in ((33, 12), (66, 20)):
        for k in range(n):
            t = 2 * math.pi * (k + 0.5) / n
            g = ejes(t)
            centro = polar(t, radio, 0.06)
            for dx, dy, sx, sy in glifos[(k + n) % len(glifos)]:
                l.bloque(centro + g @ V((dx, dy, 0)), (sx, sy, 0.14), "lava2" if k % 3 == 0 else "lava", g)


def muro(p):
    """Muro bajo de dos hiladas de sillares y una de remate, al borde del piso."""
    z0 = 0.0
    for hilada, (alto, ancho, color) in enumerate(((1.6, 2.6, None), (1.5, 2.4, None), (0.6, 3.0, "basalto3"))):
        n = round(2 * math.pi * R / (5.5 if hilada < 2 else 7))
        corrido = 0.5 * hilada
        for k in range(n):
            t = 2 * math.pi * (k + corrido) / n
            p.bloque(polar(t, R - 1.3 + rnd.uniform(-0.1, 0.1), z0 + alto / 2),
                     (ancho, 2 * math.pi * R / n - 0.2, alto - 0.08), color or piedra(), ejes(t))
        z0 += alto


def pilares(s, l):
    """Pilares de bloques sobre el muro, cada uno con un racimo de magma en la punta y una
    ménsula hacia afuera de donde cuelga la cadena."""
    for ang in PILARES:
        t = math.radians(ang)
        g = ejes(t)
        s.bloque(polar(t, R - 1, 1.2), (8.4, 8.4, 2.4), "basalto3", g)
        z = 2.4
        while z < PILAR_ALTO - 1:
            alto = rnd.uniform(2.2, 2.8)
            gg = ejes(t + rnd.uniform(-0.08, 0.08))
            s.bloque(polar(t, R - 1 + rnd.uniform(-0.15, 0.15), z + alto / 2), (5.4, 5.4, alto - 0.1), piedra(), gg)
            z += alto
        s.bloque(polar(t, R - 1, z + 0.6), (7.4, 7.4, 1.2), "basalto2", g)
        s.bloque(polar(t, R - 1, z + 1.6), (5.6, 5.6, 0.8), "basalto3", g)
        racimo(l, polar(t, R - 1, z + 2.0), t, 2.0)
        # Ménsula hacia afuera (la cadena cuelga de su punta) y veta de lava al frente.
        s.bloque(polar(t, R + 2.6, 4.2), (6.0, 2.6, 1.6), "basalto3", g)
        s.bloque(polar(t, R + 5.2, 3.2), (1.8, 2.6, 2.4), "basalto2", g)
        for k in range(4):
            l.bloque(polar(t, R + 1.25, 3.4 + k * 2.4), (0.3, 0.9, 2.2), "lava" if k % 2 else "lava3", g)


def cono(s, l):
    """La roca de abajo: anillos de bloques que se afinan hasta una punta con una gota de lava."""
    radios = [R * (1 - k / CONO_PISOS) ** 0.6 for k in range(CONO_PISOS)]
    for k, rk in enumerate(radios):
        z = -2.6 - CONO_PASO * (k + 0.5)
        hondo = min(rk, 15)
        n = max(6, round(2 * math.pi * rk / 14))
        corrido = rnd.uniform(0, 1)
        for j in range(n):
            t = 2 * math.pi * (j + corrido) / n
            sale = rnd.uniform(-1.2, 1.6)
            s.bloque(polar(t, rk - hondo / 2 + sale, z + rnd.uniform(-0.8, 0.8)),
                     (hondo, 2 * math.pi * rk / n + rnd.uniform(0.4, 2.0), CONO_PASO + rnd.uniform(0.4, 1.6)), piedra(),
                     ejes(t, rnd.uniform(-0.12, 0.12)))
    fondo = -2.6 - CONO_PASO * CONO_PISOS
    for k, ancho in enumerate((12, 8, 5, 2.6)):  # la punta
        s.bloque((rnd.uniform(-0.5, 0.5), rnd.uniform(-0.5, 0.5), fondo - 2.5 * k), (ancho, ancho, 3.0), piedra())
    punta = fondo - 2.5 * 3 - 1.5
    l.bloque((0, 0, punta - 1.2), (1.6, 1.6, 2.4), "lava2")
    l.bloque((0, 0, punta - 3.6), (0.9, 0.9, 1.6), "lava")
    # Vetas de lava que bajan por la roca, de anillo en anillo.
    for v in range(10):
        t = 2 * math.pi * v / 10 + rnd.uniform(-0.1, 0.1)
        for k, rk in enumerate(radios):
            if rnd.random() < 0.18:
                continue
            t += rnd.uniform(-0.05, 0.05)
            z = -2.6 - CONO_PASO * (k + 0.5)
            l.bloque(polar(t, rk + 1.75, z), (0.6, 2.4 * (1 - k / CONO_PISOS) + 1.0, CONO_PASO + 0.4),
                     "lava3" if k % 3 == 2 else "lava", ejes(t))


def cadenas(c):
    """Cadenas de basalto que cuelgan de las ménsulas, con una roca de lastre abajo."""
    for ang in PILARES:
        t = math.radians(ang)
        top = polar(t, CADENA_R, 2.0)
        for k in range(CADENA_ESLABONES):
            centro = top - V((0, 0, ESLABON * (k + 0.5)))
            plano = t + (math.pi / 2 if k % 2 else 0)
            lado = V((math.cos(plano), math.sin(plano), 0))
            g = Matrix((lado, V((0, 0, 1)).cross(lado), V((0, 0, 1)))).transposed()
            color = "basalto3" if k % 2 else "basalto"
            for sgn in (-1, 1):
                c.bloque(centro + lado * sgn * 0.95, (0.7, 0.7, ESLABON + 0.5), color, g)
                c.bloque(centro + V((0, 0, sgn * (ESLABON / 2 + 0.05))), (2.6, 0.7, 0.7), color, g)
        z = top.z - ESLABON * CADENA_ESLABONES - 1.2
        for ancho, alto in ((4.6, 3.0), (6.2, 3.6), (4.8, 2.6)):
            gg = ejes(t + rnd.uniform(-0.4, 0.4), rnd.uniform(-0.15, 0.15))
            c.bloque(polar(t, CADENA_R, z - alto / 2), (ancho, ancho, alto), piedra(), gg)
            z -= alto


def halo(s, l):
    """Piedras rúnicas que flotan alrededor, debajo del borde, con un glifo de lava hacia afuera."""
    for k in range(HALO_N):
        t = 2 * math.pi * (k + 0.5) / HALO_N
        z = -9 + 3.5 * math.sin(3 * t)
        g = ejes(t, rnd.uniform(-0.15, 0.15))
        s.bloque(polar(t, HALO_R, z), (2.4, 3.6, 6.4), "basalto3", g)
        s.bloque(polar(t, HALO_R - 0.2, z + 3.6), (2.0, 2.8, 1.2), "basalto2", g)
        s.bloque(polar(t, HALO_R + 0.2, z - 3.5), (1.6, 2.2, 1.0), "basalto2", g)
        cara = polar(t, HALO_R + 1.3, z)
        for dy, dz, sy, sz in ((0, 0, 0.5, 4.0), (0, 1.0, 2.2, 0.5), (0, -0.8, 1.6, 0.5)):
            l.bloque(cara + g @ V((0, dy, dz)), (0.2, sy, sz), "lava2" if k % 2 else "lava", g)


def objeto(nombre, malla, material):
    me = bpy.data.meshes.new(nombre)
    bmesh.ops.recalc_face_normals(malla.bm, faces=malla.bm.faces[:])
    malla.bm.to_mesh(me)
    malla.bm.free()
    o = bpy.data.objects.new(nombre, me)
    o.data.materials.append(material)
    bpy.context.scene.collection.objects.link(o)
    return o


def material(nombre, img, emision=0.0):
    mat = bpy.data.materials.get(nombre) or bpy.data.materials.new(nombre)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = 'Closest'
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.85
    if emision:
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = emision
    return mat


def construir():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    img = hacer_paleta()
    p, s, c, l = Malla(), Malla(), Malla(), Malla()
    piso(p)
    estrado(p, l)
    giroscopio(p, l)
    runas(l)
    muro(c)
    pilares(s, l)
    cono(s, l)
    halo(s, l)
    cadenas(c)
    mallas = {"GuaridaPiso": p, "GuaridaRoca": s, "GuaridaBorde": c, "GuaridaLava": l}
    # Misma caja para todas: un cubito mínimo en cada esquina de la caja común, simétrica en
    # X e Y para que su centro quede sobre el eje del piso.
    lims = [m.limites() for m in mallas.values()]
    a = max(max(-lo.x, -lo.y, hi.x, hi.y) for lo, hi in lims)
    lo = V((-a, -a, min(lo.z for lo, _ in lims)))
    hi = V((a, a, max(hi.z for _, hi in lims)))
    for nombre, m in mallas.items():
        color = "lava" if nombre == "GuaridaLava" else "basalto3"
        for esquina in (lo, hi):
            m.bloque(esquina - V((0.02, 0.02, 0.02)) * (1 if esquina is hi else -1), (0.04, 0.04, 0.04), color)
    tris = {n: m.tris() for n, m in mallas.items()}
    assert all(t <= MAX_TRIS for t in tris.values()), f"una malla pasa de {MAX_TRIS} triángulos: {tris}"
    objs = [objeto(n, m, material(n, img, 1.2 if n == "GuaridaLava" else 0.0)) for n, m in mallas.items()]
    return objs, lo, hi, tris


def vista_previa(objs, lo, hi):
    escena = bpy.context.scene
    for motor in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            escena.render.engine = motor
            break
        except TypeError:
            continue
    escena.render.resolution_x, escena.render.resolution_y = 1400, 1000
    escena.view_settings.view_transform = "Standard"
    mundo = bpy.data.worlds.new("Fondo")
    mundo.use_nodes = True
    mundo.node_tree.nodes["Background"].inputs[0].default_value = (0.05, 0.05, 0.08, 1)
    escena.world = mundo
    sol = bpy.data.objects.new("Sol", bpy.data.lights.new("Sol", "SUN"))
    sol.data.energy = 3.0
    sol.rotation_euler = (math.radians(55), 0, math.radians(-35))
    escena.collection.objects.link(sol)
    cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
    cam.location = (-200, -260, 40)
    escena.collection.objects.link(cam)
    escena.camera = cam
    destino = V((0, 0, (lo.z + hi.z) * 0.35))
    cam.rotation_euler = (destino - cam.location).to_track_quat('-Z', 'Y').to_euler()
    cam.data.lens = 40
    cam.data.clip_end = 2000
    os.makedirs(os.path.dirname(RENDER), exist_ok=True)
    escena.render.filepath = RENDER
    bpy.ops.render.render(write_still=True)


def exportar(objs, lo, hi):
    for x in bpy.data.objects:
        x.select_set(x in objs)
    os.makedirs(os.path.dirname(FBX), exist_ok=True)
    bpy.ops.export_scene.fbx(filepath=FBX, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
                             path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y",
                             bake_space_transform=True, mesh_smooth_type="OFF", object_types={'MESH'})
    # Caja común en ejes de Roblox (Y arriba): tamaño y alto del centro sobre el piso.
    caja = {"ancho": round(hi.x - lo.x, 3), "alto": round(hi.z - lo.z, 3), "centroY": round((hi.z + lo.z) / 2, 3),
            "mallas": [o.name for o in objs], "lava": "GuaridaLava"}
    with open(CAJA_JSON, "w", encoding="utf-8") as f:
        json.dump(caja, f, indent=1, ensure_ascii=False)
        f.write("\n")


OBJS, LO, HI, TRIS = construir()
print("GUARIDA tris", TRIS, "caja", tuple(round(v, 2) for v in LO), tuple(round(v, 2) for v in HI))
if "exportar" in ARGS or globals().get("EXPORTAR"):
    exportar(OBJS, LO, HI)
    print("EXPORTADO", FBX)
if "render" in ARGS:
    vista_previa(OBJS, LO, HI)
    print("RENDER", RENDER)
