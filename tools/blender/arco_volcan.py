r"""
Arco del volcán: la puerta del Cráter del Abismo, donde el puente toca el borde (referencia
del usuario, 2026-10-18). Estilo de bloques: piedra volcánica en hiladas irregulares, ríos de
lava por los dos bordes de cada pilar que siguen por el arco, grietas encendidas, tres picos
con cráter de lava arriba, cuernos en los hombros, zócalos escalonados y brasas al pie.

Dos mallas con la MISMA caja (cubitos mínimos en las esquinas de la caja común), para que
PropDresser las ponga con ajuste "caja" sin desfasarse:
    ArcoVolcan       la piedra, con una textura de paleta
    ArcoVolcanLava   la lava (en el juego es Neon naranja: brilla sola)
Medidas en studs, origen en el centro de la base; X de lado a lado, Z hacia arriba, el
frente mira a -Y (el arco es igual por las dos caras). El fuego y el humo de los picos los
pone el juego (tools/puerta.py) en PICOS.
Exporta assets/blender/ArcoVolcan.fbx (textura embebida), assets/textures/ArcoVolcan_color.png
y una vista previa en assets/blender/render/ArcoVolcan.png.

Uso sin abrir Blender:
    blender -b --factory-startup --python tools/blender/arco_volcan.py -- exportar render
"""
import bpy, bmesh, math, os, random, sys
from mathutils import Matrix, Vector

V = Vector
RAIZ = globals().get("RAIZ") or os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
TEX = os.path.join(RAIZ, "assets", "textures", "ArcoVolcan_color.png")
FBX = os.path.join(RAIZ, "assets", "blender", "ArcoVolcan.fbx")
RENDER = os.path.join(RAIZ, "assets", "blender", "render", "ArcoVolcan.png")
rnd = random.Random(7)

COLORES = {
    "basalto": (44, 38, 46), "basalto2": (60, 52, 60), "basalto3": (32, 28, 34), "ceniza": (82, 72, 74),
    "lava": (255, 120, 30), "lava2": (255, 192, 60), "lava3": (255, 70, 24),
}
NOMBRES = list(COLORES)
PIEDRA = ("basalto", "basalto2", "basalto3", "basalto", "ceniza")
CELDA, LADO = 32, 4

HUECO = 37.0                  # ancho libre del paso (el puente mide 34)
PILAR_W, PILAR_D, PILAR_H = 11.0, 10.0, 26.0
R_IN, R_MID, R_OUT = HUECO / 2, HUECO / 2 + 5.5, HUECO / 2 + 11.0
ARCO_D = 9.0
RIO = 2.0                     # ancho de los ríos de lava
HILADA = 2.8
X_PILAR = HUECO / 2 + PILAR_W / 2
# Cimas de los tres picos (x, z): ahí el juego pone fuego y humo.
PICOS = []


def hacer_paleta():
    img = bpy.data.images.get("ArcoVolcan_color") or bpy.data.images.new("ArcoVolcan_color", 128, 128)
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

    def bloque(self, centro, tam, color, giro=None):
        """Caja de `tam` (x, y, z) girada por la matriz `giro` (columnas = ejes locales)."""
        r = bmesh.ops.create_cube(self.bm, size=1.0)
        g = giro or Matrix.Identity(3)
        for v in r["verts"]:
            v.co = g @ V((v.co.x * tam[0], v.co.y * tam[1], v.co.z * tam[2])) + V(centro)
        i = NOMBRES.index(color)
        uv = V((((i % LADO) + 0.5) / LADO, ((i // LADO) + 0.5) / LADO))
        for f in {f for v in r["verts"] for f in v.link_faces}:
            for l in f.loops:
                l[self.uv].uv = uv

    def limites(self):
        xs = [v.co for v in self.bm.verts]
        return (V((min(p.x for p in xs), min(p.y for p in xs), min(p.z for p in xs))),
                V((max(p.x for p in xs), max(p.y for p in xs), max(p.z for p in xs))))


def piedra():
    return rnd.choice(PIEDRA)


def giro_arco(theta):
    """Ejes de un bloque del arco en el ángulo theta: X radial, Y hondo, Z tangente."""
    radial = V((math.cos(theta), 0, math.sin(theta)))
    tangente = V((-math.sin(theta), 0, math.cos(theta)))
    return Matrix((radial, V((0, 1, 0)), tangente)).transposed()


def pilar(s, lado):
    """Núcleo, hiladas de bloques irregulares en las cuatro caras, zócalo y ménsula."""
    x0 = lado * X_PILAR
    s.bloque((x0, 0, PILAR_H / 2), (PILAR_W - 1.2, PILAR_D - 1.2, PILAR_H), "basalto3")
    for k in range(int(PILAR_H / HILADA)):
        z = HILADA * (k + 0.5)
        for eje, largo, ancho in (("x", PILAR_W, PILAR_D), ("y", PILAR_D, PILAR_W)):
            for signo in (-1, 1):
                pos = -largo / 2 + (rnd.uniform(0, 1.2) if k % 2 else 0)
                while pos < largo / 2 - 0.4:
                    w = min(rnd.uniform(2.4, 3.8), largo / 2 - pos)
                    fuera = ancho / 2 - 0.45 + rnd.uniform(-0.25, 0.2)
                    c = pos + w / 2
                    if eje == "x":
                        s.bloque((x0 + c, signo * fuera, z), (w - 0.15, 0.9, HILADA - 0.15), piedra())
                    else:
                        s.bloque((x0 + signo * fuera, c, z), (0.9, w - 0.15, HILADA - 0.15), piedra())
                    pos += w
    for k, (ancho, alto, z) in enumerate(((PILAR_W + 3.4, 1.8, 0.9), (PILAR_W + 1.8, 1.4, 2.5))):
        s.bloque((x0, 0, z), (ancho, PILAR_D + 3.0 - k * 1.4, alto), "basalto3" if k == 0 else "basalto2")
    s.bloque((x0 + lado * (PILAR_W / 2 + 1.0), 0, 16), (2.4, PILAR_D - 2.5, 1.4), "basalto2")
    s.bloque((x0 + lado * (PILAR_W / 2 + 0.6), 0, 14.9), (1.4, PILAR_D - 3.5, 1.0), "basalto3")


def arco(s):
    """Dos anillos de dovelas trabadas sobre los pilares."""
    for anillo, (r0, r1, n) in enumerate(((R_IN, R_MID, 13), (R_MID, R_OUT, 15))):
        dt = math.pi / n
        for k in range(n):
            t = dt * (k + 0.5)
            rc = (r0 + r1) / 2 + rnd.uniform(-0.15, 0.15)
            c = V((rc * math.cos(t), 0, PILAR_H + rc * math.sin(t)))
            hondo = ARCO_D + rnd.uniform(-0.6, 0.4)
            s.bloque(c, (r1 - r0 - 0.15, hondo, rc * dt - 0.15), piedra(), giro_arco(t))


def cresta(s):
    """Rocas dentadas sobre el lomo del arco: el borde de arriba no es liso."""
    n = 26
    for k in range(n):
        t = math.pi * (k + 0.5) / n
        alto = rnd.uniform(1.0, 2.8)
        rc = R_OUT + alto / 2 - 0.3
        c = V((rc * math.cos(t), rnd.uniform(-1.5, 1.5), PILAR_H + rc * math.sin(t)))
        s.bloque(c, (alto, rnd.uniform(3, 5.5), rnd.uniform(2, 3.4)), piedra(), giro_arco(t))


def pico(s, l, x, base, escala, profundo=8.0):
    """Pico de bloques que se afinan hacia arriba, con un cráter de lava en la cima."""
    z = base
    for k, ancho in enumerate((8.0, 6.2, 4.4, 2.8)):
        alto = 2.6 * escala
        a = ancho * escala
        dx = rnd.uniform(-0.3, 0.3)
        s.bloque((x + dx, 0, z + alto / 2), (a, profundo * (1 - k * 0.18), alto), piedra())
        for lado in (-1, 1):  # bloques sueltos a los costados: perfil dentado
            if rnd.random() < 0.7:
                s.bloque((x + dx + lado * (a / 2 + 0.3), rnd.uniform(-1, 1), z + alto * 0.4), (1.2, 1.6, alto * 0.7), piedra())
        z += alto
    l.bloque((x, 0, z - 0.3), (1.6 * escala, 1.6 * escala, 0.7), "lava2")
    for cara in (-1, 1):  # chorros de lava por la cara del pico, de la cima hacia abajo
        for k in range(3):
            hondo = profundo * (1 - (3 - k) * 0.18) / 2 + 0.15
            l.bloque((x + rnd.uniform(-0.5, 0.5), cara * hondo, base + 2.6 * escala * (3 - k) + 1.3 * escala),
                     (0.9, 0.3, 2.6 * escala + 0.2), "lava" if k else "lava2")
    PICOS.append((round(x, 2), round(z, 2)))


def picos(s, l):
    pico(s, l, 0, PILAR_H + R_OUT + 0.6, 1.6)
    for lado in (-1, 1):
        x = lado * 20
        pico(s, l, x, PILAR_H + math.sqrt(R_OUT ** 2 - x ** 2) + 0.4, 1.2)


def cuernos(s):
    """Cuernos curvos de piedra en los hombros del arco, hacia afuera y arriba."""
    for lado in (-1, 1):
        p = V((lado * (R_OUT - 1.5), 0, PILAR_H + 12))
        for k, (tam, ang) in enumerate(((2.6, 20), (2.1, 40), (1.6, 62), (1.1, 80))):
            u = V((lado * math.cos(math.radians(ang)), 0, math.sin(math.radians(ang))))
            largo = 2.6
            c = p + u * largo / 2
            z = u
            x = V((0, 1, 0)).cross(z).normalized()
            g = Matrix((x, V((0, 1, 0)), z)).transposed()
            s.bloque(c, (tam, tam, largo + 0.3), "basalto3", g)
            p = p + u * largo


def rios(l):
    """Ríos de lava por los bordes de los pilares, en las dos caras, que siguen por el arco."""
    cara_y = PILAR_D / 2 + 0.2
    for lado in (-1, 1):
        for borde in (R_IN + 1.4, R_OUT - 1.4):
            x = lado * borde
            for k in range(int(PILAR_H / HILADA)):
                z = HILADA * (k + 0.5)
                dx = rnd.uniform(-0.25, 0.25)
                for cara in (-1, 1):
                    l.bloque((x + dx, cara * cara_y, z), (RIO, 0.4, HILADA + 0.1), "lava" if k % 3 else "lava2")
    for radio in (R_IN + 1.4, R_OUT - 1.4):
        n = 22
        dt = math.pi / n
        for k in range(n):
            t = dt * (k + 0.5)
            c = V((radio * math.cos(t), 0, PILAR_H + radio * math.sin(t)))
            for cara in (-1, 1):
                l.bloque(c + V((0, cara * (ARCO_D / 2 + 0.2), 0)), (RIO, 0.4, radio * dt + 0.15), "lava" if k % 4 else "lava2", giro_arco(t))


def grietas(l):
    """Grietas cortas en zigzag en las caras de los pilares."""
    for lado in (-1, 1):
        for cara in (-1, 1):
            for _ in range(3):
                x = lado * X_PILAR + rnd.uniform(-1.8, 1.8)
                z = rnd.uniform(4, PILAR_H - 4)
                for k in range(3):
                    x += rnd.choice((-0.6, 0.6))
                    l.bloque((x, cara * (PILAR_D / 2 + 0.2), z + k * 1.0), (0.35, 0.3, 1.1), "lava3")


def brasas(l):
    """Charquitos de lava y brasas al pie de los pilares."""
    for lado in (-1, 1):
        for cara in (-1, 1):
            for _ in range(4):
                p = (lado * X_PILAR + rnd.uniform(-6, 6), cara * rnd.uniform(7, 8.6), rnd.uniform(0.3, 0.6))
                t = rnd.uniform(0.7, 1.3)
                l.bloque(p, (t, t, t), rnd.choice(("lava", "lava2")))
            for _ in range(2):
                p = (lado * X_PILAR + rnd.uniform(-6, 6), cara * rnd.uniform(7, 8.6), rnd.uniform(3, 7))
                l.bloque(p, (0.5, 0.5, 0.5), "lava2")


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
    s, l = Malla(), Malla()
    for lado in (-1, 1):
        pilar(s, lado)
    arco(s)
    cresta(s)
    picos(s, l)
    cuernos(s)
    rios(l)
    grietas(l)
    brasas(l)
    # Misma caja para las dos mallas: un cubito mínimo en cada esquina de la caja común.
    (a0, a1), (b0, b1) = s.limites(), l.limites()
    # Simétrica en X e Y: el centro de la caja queda justo sobre el origen (centro de la base).
    ax = max(-a0.x, -b0.x, a1.x, b1.x)
    ay = max(-a0.y, -b0.y, a1.y, b1.y)
    lo = V((-ax, -ay, 0.0))
    hi = V((ax, ay, max(a1.z, b1.z)))
    for m, color in ((s, "basalto3"), (l, "lava")):
        for esquina in (lo, hi):
            m.bloque(esquina - V((0.02, 0.02, 0.02)) * (1 if esquina is hi else -1), (0.04, 0.04, 0.04), color)
    piedra_o = objeto("ArcoVolcan", s, material("ArcoVolcan", img))
    lava_o = objeto("ArcoVolcanLava", l, material("ArcoVolcanLava", img, 1.2))
    return piedra_o, lava_o, hi - lo


def vista_previa(objs, caja):
    escena = bpy.context.scene
    for motor in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            escena.render.engine = motor
            break
        except TypeError:
            continue
    escena.render.resolution_x, escena.render.resolution_y = 1200, 900
    escena.view_settings.view_transform = "Standard"  # colores tal cual (como en Roblox)
    mundo = bpy.data.worlds.new("Fondo")
    mundo.use_nodes = True
    mundo.node_tree.nodes["Background"].inputs[0].default_value = (0.08, 0.1, 0.14, 1)
    escena.world = mundo
    sol = bpy.data.objects.new("Sol", bpy.data.lights.new("Sol", "SUN"))
    sol.data.energy = 3.0
    sol.rotation_euler = (math.radians(50), 0, math.radians(-35))
    escena.collection.objects.link(sol)
    cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
    cam.location = (-62, -118, 40)
    escena.collection.objects.link(cam)
    escena.camera = cam
    destino = V((0, 0, caja.z * 0.46))
    cam.rotation_euler = (destino - cam.location).to_track_quat('-Z', 'Y').to_euler()
    cam.data.lens = 38
    os.makedirs(os.path.dirname(RENDER), exist_ok=True)
    escena.render.filepath = RENDER
    bpy.ops.render.render(write_still=True)


def exportar(objs):
    for x in bpy.data.objects:
        x.select_set(x in objs)
    os.makedirs(os.path.dirname(FBX), exist_ok=True)
    bpy.ops.export_scene.fbx(filepath=FBX, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
                             path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y",
                             bake_space_transform=True, mesh_smooth_type="OFF", object_types={'MESH'})


PIEDRA_O, LAVA_O, CAJA = construir()
TRIS = {o.name: sum(len(p.vertices) - 2 for p in o.data.polygons) for o in (PIEDRA_O, LAVA_O)}
print("ARCO tris", TRIS, "caja", tuple(round(v, 2) for v in CAJA), "picos", PICOS)
if "exportar" in ARGS or globals().get("EXPORTAR"):
    exportar((PIEDRA_O, LAVA_O))
    print("EXPORTADO", FBX)
if "render" in ARGS:
    vista_previa((PIEDRA_O, LAVA_O), CAJA)
    print("RENDER", RENDER)
