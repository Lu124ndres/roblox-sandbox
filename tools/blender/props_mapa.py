r"""
Props del mapa en 3D, estilo caricatura low-poly, con una sola textura de paleta
(cada cara pinta un cuadrito de color: se ve plano y nítido como el resto del juego):
    Palmera1..3   tronco curvo por anillos y hojas dobles caídas, con cocos
    Arbusto1..2   matas redondeadas con flores
    Roca1..3      piedras talladas (la 3 con musgo arriba)
    Cresta1..2    picos de basalto del volcán, irregulares, con rocas al pie
    BordeEstanque / BordeSagrado   borde de mármol de los estanques con losa y filo de oro
Cada objeto tiene el origen en el centro de su base. Exporta assets/blender/PropsMapa.fbx
(textura embebida) y assets/textures/PropsMapa_color.png. El juego los pone en el mapa con
server/World/PropDresser (las piezas "Ancla" que deja tools/generar_isla.py).
Uso desde el MCP de Blender:  RAIZ = r"C:\...\JuegoRoblox"; exec(open(RAIZ + r"\tools\blender\props_mapa.py").read())
"""
import bpy, bmesh, math, os, random
from mathutils import Vector, noise, Matrix

rnd = random.Random(11)
V = Vector
TEX = os.path.join(RAIZ, "assets", "textures", "PropsMapa_color.png")
FBX = os.path.join(RAIZ, "assets", "blender", "PropsMapa.fbx")

# --- Paleta: cuadritos de 32 px en una imagen de 256 (8 x 8) --------------------------
COLORES = {
    "tronco": (138, 98, 62), "tronco2": (170, 128, 84), "tronco3": (112, 78, 50),
    "hoja": (58, 150, 72), "hoja2": (88, 182, 86), "hoja3": (40, 118, 62),
    "coco": (104, 70, 42), "roca": (128, 132, 140), "roca2": (104, 108, 118),
    "roca3": (150, 154, 160), "musgo": (96, 146, 78), "basalto": (40, 36, 46),
    "basalto2": (56, 50, 62), "basalto3": (30, 28, 34), "lava": (255, 120, 30),
    "lava2": (255, 190, 60), "mata": (66, 148, 68), "mata2": (54, 128, 60),
    "mata3": (92, 170, 80), "flor": (255, 128, 160), "flor2": (255, 214, 92),
    "flor3": (250, 250, 255), "marmol": (244, 241, 234), "marmol2": (224, 219, 210),
    "marmol3": (206, 200, 190), "oro": (255, 212, 90), "oro2": (230, 172, 52),
}
NOMBRES = list(COLORES)
CELDA, LADO = 32, 8

def hacer_paleta():
    img = bpy.data.images.get("PropsMapa_color") or bpy.data.images.new("PropsMapa_color", 256, 256)
    px = [0.0] * (256 * 256 * 4)
    for i, n in enumerate(NOMBRES):
        cx, cy = (i % LADO) * CELDA, (i // LADO) * CELDA
        r, g, b = (c / 255 for c in COLORES[n])
        for y in range(cy, cy + CELDA):
            for x in range(cx, cx + CELDA):
                k = (y * 256 + x) * 4
                px[k:k + 4] = [r, g, b, 1.0]  # la imagen ya es sRGB: va tal cual
    img.pixels = px
    img.filepath_raw = TEX
    img.file_format = 'PNG'
    os.makedirs(os.path.dirname(TEX), exist_ok=True)
    img.save()
    return img

def uv_de(nombre):
    i = NOMBRES.index(nombre)
    return V((((i % LADO) + 0.5) / LADO, ((i // LADO) + 0.5) / LADO))

def pintar(bm, cara, nombre):
    uv = bm.loops.layers.uv.verify()
    c = uv_de(nombre)
    for l in cara.loops:
        l[uv].uv = c

# --- Piezas ---------------------------------------------------------------------------
def anillo(bm, centro, radio, lados, giro=0.0, eje=V((0, 0, 1)), ruido=0.0):
    q = eje.to_track_quat('Z', 'Y')
    vs = []
    for k in range(lados):
        a = giro + 2 * math.pi * k / lados
        r = radio * (1 + ruido * rnd.uniform(-1, 1))
        vs.append(bm.verts.new(centro + q @ V((math.cos(a) * r, math.sin(a) * r, 0))))
    return vs

def unir(bm, a, b, color):
    n = len(a)
    for k in range(n):
        f = bm.faces.new((a[k], a[(k + 1) % n], b[(k + 1) % n], b[k]))
        pintar(bm, f, color(k) if callable(color) else color)

def tapa(bm, ring, color, centro=None):
    if centro is None:
        f = bm.faces.new(ring)
        pintar(bm, f, color)
        return
    c = bm.verts.new(centro)
    for k in range(len(ring)):
        f = bm.faces.new((ring[k], ring[(k + 1) % len(ring)], c))
        pintar(bm, f, color)

def esfera(bm, centro, radio, color, sub=1, aplastar=V((1, 1, 1)), ruido=0.0, semilla=0.0):
    r = bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=radio)
    for v in r["verts"]:
        d = noise.noise(v.co * 1.7 + V((semilla, semilla * 2, 0)))
        v.co = V((v.co.x * aplastar.x, v.co.y * aplastar.y, v.co.z * aplastar.z)) * (1 + ruido * d) + centro
    caras = {f for v in r["verts"] for f in v.link_faces}
    for f in caras:
        pintar(bm, f, color(f) if callable(color) else color)
    return r["verts"]

def objeto(nombre, bm, material):
    me = bpy.data.meshes.new(nombre)
    bm.normal_update()
    bm.to_mesh(me); bm.free()
    facetado = nombre.startswith(("Roca", "Cresta"))  # piedra tallada: caras planas
    for p in me.polygons:
        p.use_smooth = not facetado
    o = bpy.data.objects.new(nombre, me)
    o.data.materials.append(material)
    bpy.context.scene.collection.objects.link(o)
    return o

def palmera(nombre, alto, inclina, hojas, semilla):
    rnd.seed(semilla)
    bm = bmesh.new()
    segs, lados = 7, 8
    prev = None
    puntos = []
    for i in range(segs + 1):
        t = i / segs
        p = V((inclina * alto * t * t, 0, alto * t))
        puntos.append(p)
    for i, p in enumerate(puntos):
        t = i / segs
        r = 0.75 * (1 - 0.45 * t)
        eje = (puntos[min(i + 1, segs)] - puntos[max(i - 1, 0)]).normalized()
        baja = anillo(bm, p, r * 1.08, lados, i * 0.4, eje)          # anillo ancho (nudo)
        if prev:
            unir(bm, prev, baja, "tronco" if i % 2 else "tronco2")
        else:
            tapa(bm, list(reversed(baja)), "tronco3")
        if i < segs:
            alta = anillo(bm, p + eje * (alto / segs) * 0.25, r * 0.92, lados, i * 0.4, eje)
            unir(bm, baja, alta, "tronco3")
            prev = alta
        else:
            prev = baja
    top = puntos[-1]
    tapa(bm, prev, "tronco3", top + V((0, 0, 0.2)))
    # Cocos bajo las hojas.
    for k in range(3):
        a = k * 2.1 + 0.3
        esfera(bm, top + V((math.cos(a) * 0.55, math.sin(a) * 0.55, -0.45)), 0.42, "coco", 1)
    # Hojas: tira con forma de V, doble cara (arriba y abajo), cae en arco.
    for h in range(hojas):
        phi = 2 * math.pi * h / hojas + rnd.uniform(-0.2, 0.2)
        largo = alto * rnd.uniform(0.48, 0.6)
        sube = rnd.uniform(0.25, 0.55)
        d = V((math.cos(phi), math.sin(phi), 0))
        lado = V((-math.sin(phi), math.cos(phi), 0))
        n = 14
        filas = []
        for s in range(n + 1):
            u = s / n
            c = top + d * (u * largo) + V((0, 0, (sube * u - 1.45 * u * u) * largo * 0.55))
            w = largo * 0.17 * (math.sin(math.pi * min(u * 1.1, 1)) ** 0.6) + 0.02
            w *= 1.0 if s % 2 else 0.45  # bordes en sierra: se ve como hoja de palmera
            dobla = V((0, 0, w * 0.35))
            filas.append((c - lado * w - dobla * 0.2, c + dobla * 0.6, c + lado * w - dobla * 0.2))
        for cara, off in ((1, 0.0), (-1, -0.06)):
            vs = [[bm.verts.new(p + V((0, 0, off))) for p in fila] for fila in filas]
            for s in range(n):
                for j in range(2):
                    q = (vs[s][j], vs[s][j + 1], vs[s + 1][j + 1], vs[s + 1][j])
                    f = bm.faces.new(q if cara == 1 else tuple(reversed(q)))
                    pintar(bm, f, ("hoja2" if j == 0 else "hoja") if cara == 1 else "hoja3")
    return bm

def roca(semilla, musgo=False, aplastar=V((1.3, 1.0, 0.75))):
    bm = bmesh.new()
    def color(f):
        if musgo and f.calc_center_median().z > 0.25:
            return "musgo"
        return rnd.choice(("roca", "roca2", "roca3"))
    rnd.seed(semilla)
    esfera(bm, V((0, 0, 0)), 1.0, color, 3, aplastar, 0.45, semilla)
    bmesh.ops.translate(bm, verts=bm.verts[:], vec=V((0, 0, -min(v.co.z for v in bm.verts))))
    return bm

def cresta(semilla, alto):
    rnd.seed(semilla)
    bm = bmesh.new()
    lados, pisos = 7, 7
    prev = None
    for i in range(pisos + 1):
        t = i / pisos
        r = 4.8 * (1 - t) ** 0.9 + 0.9
        c = V((rnd.uniform(-0.6, 0.6) * t * 3, rnd.uniform(-0.6, 0.6) * t * 3, alto * t))
        ring = anillo(bm, c, r, lados, i * 0.7, ruido=0.28)
        if prev:
            unir(bm, prev, ring, lambda k, i=i: ("basalto", "basalto2", "basalto3")[(k + i) % 3])
        else:
            tapa(bm, list(reversed(ring)), "basalto3")
        prev = ring
    tapa(bm, prev, "basalto2", prev[0].co * 0 + sum((v.co for v in prev), V()) / len(prev) + V((0, 0, 1.2)))
    for k in range(3):  # rocas al pie
        a = rnd.uniform(0, 6.28)
        esfera(bm, V((math.cos(a) * 4.6, math.sin(a) * 4.6, 0.6)), rnd.uniform(1.0, 1.6),
               lambda f: rnd.choice(("basalto", "basalto2")), 1, V((1.3, 1, 0.8)), 0.3, a)
    return bm

def arbusto(semilla):
    rnd.seed(semilla)
    bm = bmesh.new()
    for k in range(5):
        s = rnd.uniform(0.9, 1.4)
        c = V((rnd.uniform(-1.2, 1.2), rnd.uniform(-1.2, 1.2), s * 0.75))
        esfera(bm, c, s, lambda f: rnd.choice(("mata", "mata2", "mata3")), 3, V((1, 1, 0.85)), 0.25, k + semilla)
    for k in range(7):
        a = rnd.uniform(0, 6.28); r = rnd.uniform(0.8, 1.9)
        esfera(bm, V((math.cos(a) * r, math.sin(a) * r, rnd.uniform(1.1, 1.9))), 0.22,
               rnd.choice(("flor", "flor2", "flor3")), 1)
    bmesh.ops.translate(bm, verts=bm.verts[:], vec=V((0, 0, -min(v.co.z for v in bm.verts))))
    return bm

def borde(R, segs):
    """Perfil (radio, alto) que gira: borde ancho redondeado, losa y filo de oro."""
    dentro, fuera, losa = R - 2.2, R + 1.5, R + 6.1
    perfil = [  # (radio, z, color de la cara que empieza en este punto)
        (dentro, -2.2, "marmol2"), (dentro, 0.8, "marmol"), (dentro + 0.35, 1.2, "marmol"),
        (fuera - 0.35, 1.2, "marmol"), (fuera, 0.8, "marmol2"), (fuera, 0.25, "marmol2"),
        (losa - 0.4, 0.25, "oro"), (losa - 0.4, 0.42, "oro"), (losa, 0.42, "oro2"),
        (losa, -0.4, "marmol3"),
    ]
    bm = bmesh.new()
    rings = []
    for k in range(segs):
        a = 2 * math.pi * k / segs
        rings.append([bm.verts.new(V((math.cos(a) * r, math.sin(a) * r, z))) for r, z, _ in perfil])
    for k in range(segs):
        a, b = rings[k], rings[(k + 1) % segs]
        for j in range(len(perfil) - 1):
            f = bm.faces.new((a[j], b[j], b[j + 1], a[j + 1]))
            color = perfil[j][2] if j != 0 else ("marmol2" if k % 2 else "marmol3")  # bloques por dentro
            pintar(bm, f, color)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bmesh.ops.translate(bm, verts=bm.verts[:], vec=V((0, 0, 2.2)))
    return bm

# --- Armar todo -----------------------------------------------------------------------
def construir():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    img = hacer_paleta()
    mat = bpy.data.materials.get("PropsMapa") or bpy.data.materials.new("PropsMapa")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    tex = nt.nodes.new("ShaderNodeTexImage"); tex.image = img; tex.interpolation = 'Closest'
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.8
    objs = []
    for i, (alto, inc, hojas) in enumerate(((14, 0.18, 9), (12, 0.28, 8), (16, 0.12, 10))):
        objs.append(objeto(f"Palmera{i + 1}", palmera(f"Palmera{i + 1}", alto, inc, hojas, 40 + i), mat))
    objs.append(objeto("Arbusto1", arbusto(5), mat))
    objs.append(objeto("Arbusto2", arbusto(9), mat))
    objs.append(objeto("Roca1", roca(3), mat))
    objs.append(objeto("Roca2", roca(17, aplastar=V((1.0, 1.1, 0.95))), mat))
    objs.append(objeto("Roca3", roca(23, musgo=True), mat))
    objs.append(objeto("Cresta1", cresta(7, 26), mat))
    objs.append(objeto("Cresta2", cresta(31, 20), mat))
    objs.append(objeto("BordeEstanque", borde(12.5, 64), mat))
    objs.append(objeto("BordeSagrado", borde(18, 80), mat))
    # En fila para revisarlos.
    x = 0
    for o in objs:
        o.location = V((x, 0, 0))
        x += max(o.dimensions.x, 4) + 4
    return objs

def exportar(objs):
    for o in bpy.data.objects:
        o.select_set(o in objs)
    for o in objs:
        o.location = V((0, 0, 0))
    win = bpy.context.window_manager.windows[0]
    area = next(a for a in win.screen.areas if a.type == 'VIEW_3D')
    with bpy.context.temp_override(window=win, area=area, region=next(r for r in area.regions if r.type == 'WINDOW')):
        bpy.ops.export_scene.fbx(filepath=FBX, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
            path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y", bake_space_transform=True,
            mesh_smooth_type="FACE", object_types={'MESH'})

OBJS = construir()
tris = {o.name: sum(len(p.vertices) - 2 for p in o.data.polygons) for o in OBJS}
print("TRIS", tris)
if globals().get("EXPORTAR"):
    exportar(OBJS)
    print("EXPORTADO", FBX)
