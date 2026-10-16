r"""
Faro del mapa en 3D, estilo caricatura low-poly con una textura de paleta (igual que
props_mapa.py): zócalo de piedra con rocas al pie, torre cónica a franjas rojas y blancas
con rebordes, ventanas con marco, puerta de madera con escalón, balcón de metal con
ménsulas y baranda, linterna abierta (8 parantes: la Lampara de neón del juego se ve por
dentro) y cúpula roja con bola y punta de oro.
Origen en el centro de la base; la puerta mira a +X. Alto total ALTO; el centro de la
linterna queda a LAMPARA del piso (generar_isla.py pone la Lampara y el Haz ahí).
Exporta assets/blender/Faro.fbx (textura embebida) y assets/textures/Faro_color.png.
En Studio va a ServerStorage.PropsMapa como MeshPart "Faro" (lo pone PropDresser).
Uso desde el MCP de Blender:
    RAIZ = r"C:\...\JuegoRoblox"; EXPORTAR = True; exec(open(RAIZ + r"\tools\blender\faro.py").read())
"""
import bpy, bmesh, math, os, random
from mathutils import Vector, noise

V = Vector
rnd = random.Random(5)
TEX = os.path.join(RAIZ, "assets", "textures", "Faro_color.png")
FBX = os.path.join(RAIZ, "assets", "blender", "Faro.fbx")

COLORES = {
    "rojo": (214, 58, 52), "rojo2": (178, 40, 40), "rojo3": (236, 92, 76),
    "blanco": (248, 246, 240), "blanco2": (226, 222, 214), "blanco3": (206, 200, 192),
    "piedra": (150, 146, 140), "piedra2": (126, 122, 118), "piedra3": (176, 172, 164),
    "roca": (118, 122, 130), "roca2": (98, 102, 112), "musgo": (96, 150, 78),
    "metal": (54, 60, 70), "metal2": (78, 86, 98), "madera": (122, 78, 46),
    "madera2": (92, 58, 34), "oro": (255, 210, 84), "oro2": (226, 164, 48),
    "ventana": (52, 92, 140), "ventana2": (120, 190, 235), "hierro": (40, 40, 46),
}
NOMBRES = list(COLORES)
CELDA, LADO = 32, 8
LISOS = {"rojo", "rojo2", "rojo3", "blanco", "blanco2", "blanco3", "oro", "oro2"}

ZOCALO = 1.6          # alto del zócalo de piedra
TORRE = 27.0          # alto de la torre (6 franjas)
R_ABAJO, R_ARRIBA = 4.7, 3.35
LADOS = 20


def hacer_paleta():
    img = bpy.data.images.get("Faro_color") or bpy.data.images.new("Faro_color", 256, 256)
    px = [0.0] * (256 * 256 * 4)
    for i, n in enumerate(NOMBRES):
        cx, cy = (i % LADO) * CELDA, (i // LADO) * CELDA
        r, g, b = (c / 255 for c in COLORES[n])
        for y in range(cy, cy + CELDA):
            for x in range(cx, cx + CELDA):
                k = (y * 256 + x) * 4
                px[k:k + 4] = [r, g, b, 1.0]
    img.pixels = px
    img.filepath_raw = TEX
    img.file_format = 'PNG'
    os.makedirs(os.path.dirname(TEX), exist_ok=True)
    img.save()
    return img


def uv_de(nombre):
    i = NOMBRES.index(nombre)
    return V((((i % LADO) + 0.5) / LADO, ((i // LADO) + 0.5) / LADO))


class Malla:
    def __init__(self):
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.verify()
        self.liso = self.bm.faces.layers.int.new("liso")

    def pintar(self, cara, nombre):
        c = uv_de(nombre)
        for l in cara.loops:
            l[self.uv].uv = c
        cara[self.liso] = 1 if nombre in LISOS else 0

    def cara(self, vs, nombre):
        f = self.bm.faces.new(vs)
        self.pintar(f, nombre)
        return f

    def anillo(self, z, radio, lados=LADOS, giro=0.0, ruido=0.0):
        vs = []
        for k in range(lados):
            a = giro + 2 * math.pi * k / lados
            r = radio * (1 + ruido * rnd.uniform(-1, 1))
            vs.append(self.bm.verts.new(V((math.cos(a) * r, math.sin(a) * r, z))))
        return vs

    def unir(self, a, b, color):
        n = len(a)
        for k in range(n):
            self.cara((a[k], a[(k + 1) % n], b[(k + 1) % n], b[k]), color(k) if callable(color) else color)

    def tapa(self, ring, color, centro=None, abajo=False):
        ring = list(reversed(ring)) if abajo else ring
        if centro is None:
            self.cara(ring, color)
            return
        c = self.bm.verts.new(centro)
        for k in range(len(ring)):
            self.cara((ring[k], ring[(k + 1) % len(ring)], c), color)

    def caja(self, centro, tam, giro_z, colores, inclina=0.0):
        """Caja girada en Z; `colores`: {"frente": +X local, "resto": ...}."""
        r = bmesh.ops.create_cube(self.bm, size=1.0)
        vs = r["verts"]
        for v in vs:
            p = V((v.co.x * tam[0], v.co.y * tam[1], v.co.z * tam[2]))
            if inclina:
                p.z += p.x * inclina
            c, s = math.cos(giro_z), math.sin(giro_z)
            v.co = V((p.x * c - p.y * s, p.x * s + p.y * c, p.z)) + centro
        caras = {f for v in vs for f in v.link_faces}
        frente = V((math.cos(giro_z), math.sin(giro_z), 0))
        for f in caras:
            f.normal_update()
            es_frente = f.normal.dot(frente) > 0.9
            self.pintar(f, colores.get("frente", colores["resto"]) if es_frente else colores["resto"])

    def esfera(self, centro, radio, color, sub=1, aplastar=V((1, 1, 1)), ruido=0.0, semilla=0.0):
        r = bmesh.ops.create_icosphere(self.bm, subdivisions=sub, radius=radio)
        for v in r["verts"]:
            d = noise.noise(v.co * 1.7 + V((semilla, semilla * 2, 0)))
            v.co = V((v.co.x * aplastar.x, v.co.y * aplastar.y, v.co.z * aplastar.z)) * (1 + ruido * d) + centro
        for f in {f for v in r["verts"] for f in v.link_faces}:
            self.pintar(f, color(f) if callable(color) else color)


def radio_torre(z):
    t = (z - ZOCALO) / TORRE
    return R_ABAJO + (R_ARRIBA - R_ABAJO) * t


def zocalo(m):
    """Base octogonal de bloques de piedra en dos hiladas, con rocas al pie."""
    a = m.anillo(0, 7.4, 8, math.pi / 8)
    b = m.anillo(0.8, 7.3, 8, math.pi / 8)
    c = m.anillo(0.8, 6.9, 8, math.pi / 8)
    d = m.anillo(ZOCALO, 6.8, 8, math.pi / 8)
    m.tapa(a, "piedra2", abajo=True)
    m.unir(a, b, lambda k: "piedra" if k % 2 else "piedra2")
    m.unir(b, c, "piedra3")
    m.unir(c, d, lambda k: "piedra2" if k % 2 else "piedra")
    m.tapa(d, "piedra3")
    for k in range(9):
        ang = k * 2 * math.pi / 9 + rnd.uniform(-0.2, 0.2)
        if abs(math.atan2(math.sin(ang), math.cos(ang))) < 0.5:
            continue  # deja libre el frente de la puerta
        r = rnd.uniform(7.2, 8.0)
        tam = rnd.uniform(0.9, 1.6)
        m.esfera(V((math.cos(ang) * r, math.sin(ang) * r, 0.25)), tam,
                 lambda f: "musgo" if f.calc_center_median().z > 0.25 + tam * 0.55 else rnd.choice(("roca", "roca2")),
                 sub=1, aplastar=V((1.2, 1.0, 0.75)), ruido=0.25, semilla=k * 3.1)


def torre(m):
    """Seis franjas rojas y blancas, cónicas, con un reborde entre franja y franja."""
    alto = TORRE / 6
    z = ZOCALO
    prev = m.anillo(z, radio_torre(z))
    for i in range(6):
        color = "rojo" if i % 2 == 0 else "blanco"
        z2 = z + alto - 0.35
        top = m.anillo(z2, radio_torre(z2))
        m.unir(prev, top, color)
        if i < 5:  # reborde: sale, sube y vuelve
            r = radio_torre(z2)
            o1 = m.anillo(z2, r + 0.22)
            o2 = m.anillo(z2 + 0.35, r + 0.22)
            back = m.anillo(z2 + 0.35, radio_torre(z2 + 0.35))
            borde = "blanco2" if i % 2 == 0 else "rojo2"
            m.unir(top, o1, borde)
            m.unir(o1, o2, borde)
            m.unir(o2, back, borde)
            prev = back
        else:
            prev = top
        z = z2 + 0.35
    return prev


def ventanas_y_puerta(m):
    for z, ang in ((8.5, math.pi), (14.0, math.pi / 2), (19.5, -math.pi / 2), (24.5, math.pi * 0.85)):
        r = radio_torre(z)
        dirv = V((math.cos(ang), math.sin(ang), 0))
        m.caja(dirv * (r + 0.05) + V((0, 0, z)), (0.5, 1.5, 2.1), ang, {"resto": "blanco2"})
        m.caja(dirv * (r + 0.28) + V((0, 0, z + 0.05)), (0.12, 1.05, 1.6), ang, {"frente": "ventana", "resto": "blanco3"})
        m.caja(dirv * (r + 0.32) + V((0, 0, z - 1.1)), (0.45, 1.8, 0.22), ang, {"resto": "blanco3"})
    # Puerta (mira a +X): marco de piedra, hoja de madera y escalón.
    r = radio_torre(ZOCALO + 2.4)
    m.caja(V((r + 0.15, 0, ZOCALO + 2.45)), (0.9, 3.4, 4.9), 0, {"resto": "piedra3"})
    m.caja(V((r + 0.45, 0, ZOCALO + 2.2)), (0.5, 2.5, 4.2), 0, {"frente": "madera", "resto": "madera2"})
    m.caja(V((r + 0.72, 0.75, ZOCALO + 2.1)), (0.18, 0.26, 0.26), 0, {"resto": "oro"})  # pomo
    m.caja(V((r + 1.6, 0, ZOCALO - 0.35)), (2.0, 3.6, 0.7), 0, {"resto": "piedra3"})
    m.caja(V((r + 2.7, 0, ZOCALO - 0.95)), (1.6, 3.8, 0.7), 0, {"resto": "piedra"})


def balcon(m, z):
    """Piso de metal con ménsulas debajo y baranda redonda."""
    r_piso = 6.0
    a = m.anillo(z, r_piso, 24)
    b = m.anillo(z + 0.55, r_piso, 24)
    m.tapa(a, "metal", abajo=True)
    m.unir(a, b, "metal2")
    m.tapa(b, "metal")
    for k in range(12):
        ang = k * 2 * math.pi / 12
        rr = radio_torre(z) + 0.6
        m.caja(V((math.cos(ang) * rr, math.sin(ang) * rr, z - 0.45)), (1.5, 0.3, 0.9), ang, {"resto": "metal"}, inclina=0.45)
    top = z + 0.55
    for k in range(16):
        ang = k * 2 * math.pi / 16
        m.caja(V((math.cos(ang) * 5.7, math.sin(ang) * 5.7, top + 0.75)), (0.18, 0.18, 1.5), ang, {"resto": "hierro"})
    for zr, alto in ((top + 1.45, 0.2), (top + 0.75, 0.12)):
        oi, oo = m.anillo(zr, 5.55, 24), m.anillo(zr, 5.85, 24)
        ti, to = m.anillo(zr + alto, 5.55, 24), m.anillo(zr + alto, 5.85, 24)
        m.unir(oo, to, "hierro")
        m.unir(to, ti, "hierro")
        m.unir(ti, oi, "hierro")
        m.unir(oi, oo, "hierro")
    return top


def linterna(m, z):
    """Murete, 8 parantes abiertos (se ve la Lampara del juego) y aro de arriba."""
    r = 3.25
    a = m.anillo(z, r, 16)
    b = m.anillo(z + 0.75, r, 16)
    m.unir(a, b, "metal2")
    m.tapa(b, "metal")
    alto = 3.5
    for k in range(8):
        ang = k * 2 * math.pi / 8 + math.pi / 8
        m.caja(V((math.cos(ang) * (r - 0.15), math.sin(ang) * (r - 0.15), z + 0.75 + alto / 2)), (0.3, 0.3, alto), ang,
               {"resto": "metal"})
    z2 = z + 0.75 + alto
    c = m.anillo(z2, r + 0.1, 16)
    d = m.anillo(z2 + 0.5, r + 0.1, 16)
    m.tapa(c, "metal", abajo=True)
    m.unir(c, d, "metal2")
    return z2 + 0.5


def cupula(m, z):
    """Alero rojo y cúpula redondeada; bola y punta de oro."""
    alero_a = m.anillo(z, 4.1, LADOS)
    alero_b = m.anillo(z + 0.35, 4.1, LADOS)
    m.tapa(alero_a, "rojo2", abajo=True)
    m.unir(alero_a, alero_b, "rojo2")
    prev = alero_b
    pasos = 6
    for i in range(1, pasos + 1):
        t = i / pasos
        rr = 4.1 * math.cos(t * math.pi / 2) ** 0.9
        zz = z + 0.35 + 3.0 * math.sin(t * math.pi / 2)
        if i == pasos:
            m.tapa(prev, "rojo3", V((0, 0, zz)))
            break
        ring = m.anillo(zz, max(rr, 0.3), LADOS)
        m.unir(prev, ring, "rojo" if i < pasos - 1 else "rojo3")
        prev = ring
    tope = z + 3.35
    m.esfera(V((0, 0, tope + 0.45)), 0.6, "oro", sub=2)
    base = m.anillo(tope + 0.9, 0.22, 8)
    m.tapa(base, "oro2", abajo=True)
    m.tapa(base, "oro", V((0, 0, tope + 2.0)))
    return tope + 2.0


def construir():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    img = hacer_paleta()
    mat = bpy.data.materials.get("Faro") or bpy.data.materials.new("Faro")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    tex = nt.nodes.new("ShaderNodeTexImage"); tex.image = img; tex.interpolation = 'Closest'
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.7
    m = Malla()
    zocalo(m)
    tope_torre = torre(m)
    m.tapa(tope_torre, "metal", abajo=False)
    ventanas_y_puerta(m)
    z = balcon(m, ZOCALO + TORRE)
    centro_linterna = z + 0.75 + 3.5 / 2
    z = linterna(m, z)
    alto = cupula(m, z)
    bm = m.bm
    for v in bm.verts:  # las rocas no bajan del piso: la base del modelo es z = 0
        v.co.z = max(v.co.z, 0.0)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    me = bpy.data.meshes.new("Faro")
    bm.normal_update()
    lisos = [f[m.liso] == 1 for f in bm.faces]
    bm.to_mesh(me); bm.free()
    for p, liso in zip(me.polygons, lisos):
        p.use_smooth = liso
    if hasattr(me, "set_sharp_from_angle"):  # filos marcados: franjas y rebordes sin manchas
        me.set_sharp_from_angle(angle=math.radians(40))
    o = bpy.data.objects.new("Faro", me)
    o.data.materials.append(mat)
    bpy.context.scene.collection.objects.link(o)
    return o, alto, centro_linterna


def exportar(o):
    for x in bpy.data.objects:
        x.select_set(x == o)
    win = bpy.context.window_manager.windows[0]
    area = next(a for a in win.screen.areas if a.type == 'VIEW_3D')
    with bpy.context.temp_override(window=win, area=area, region=next(r for r in area.regions if r.type == 'WINDOW')):
        bpy.ops.export_scene.fbx(filepath=FBX, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
            path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y", bake_space_transform=True,
            mesh_smooth_type="OFF", object_types={'MESH'})


FARO, ALTO, LAMPARA = construir()
print("FARO tris", sum(len(p.vertices) - 2 for p in FARO.data.polygons), "alto", round(ALTO, 2),
      "lampara", round(LAMPARA, 2), "dims", tuple(round(d, 2) for d in FARO.dimensions))
if globals().get("EXPORTAR"):
    exportar(FARO)
    print("EXPORTADO", FBX)
