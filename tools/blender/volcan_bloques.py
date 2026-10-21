r"""
El volcán (Cráter del Abismo) en estilo de bloques, como las fotos del juego: columnas de
bloques sobre una cuadrícula, con la cara de arriba más clara que los lados, un bisel de un
segmento en el borde de arriba de cada bloque y las vetas de lava aparte (en Roblox van en
Neon). Reemplazaría al terreno liso del cráter; el agua del lago y del mar sigue siendo
agua de Roblox.

La forma sale de los mismos datos y fórmulas que el terreno de ahora, así el puente, el arco,
el paseo del borde, el hábitat del lago y la guarida siguen calzando:
    WorldLayoutData.json      medidas (craterCenter, radios, alturas)
    CraterShape.height        lago, acantilado, paseo, montañas (peak) y puerta (gate)
    WorldZones.lakeFloor      plataforma clara junto al acantilado y pozo hondo
    CraterShape.material      caliza, basalto, roca, vetas de lava y cumbres
Cada columna toma la altura del centro de su celda, redondeada a ESCALON: el paseo y la
puerta (30) y el fondo del mar (-18) quedan exactos; lo demás se mueve hasta un stud.
Celda de 4 x 4 y escalón de 2, como la isla, para que los dos se vean del mismo estilo.

Peso: las columnas vecinas de igual altura y color se juntan en rectángulos (greedy meshing)
y los lados van en tiras. El bisel va en el borde de cada rectángulo; la variación de tono
por columna (basalto y cumbres) los deja chicos, así cada bloque se sigue leyendo.

Ejes: 1 BU = 1 stud, el origen en craterCenter a la altura 0. Blender (x, y, z) = Roblox
(dx, -dz, y): exportado a FBX con forward -Z y up Y vuelve a los ejes de Roblox.

Mallas por sectores de SECTOR x SECTOR columnas (Volcan_<fila>_<columna>, menos de 20,000
triángulos cada una: el límite de MeshPart) y la lava en una malla aparte (VolcanLava): solo
la tapa de las columnas de lava, para que se vea como vetas y no como pilares; sus lados son
de piedra caliente. Sin caras ocultas: los lados de una columna solo bajan hasta la vecina
más baja y no hay caras de abajo.

Uso (desde la raíz del repo; --forma cono arma la v3, el volcán grande):
    blender -b --factory-startup --python tools/blender/volcan_bloques.py
    blender -b --factory-startup --python tools/blender/volcan_bloques.py -- --forma cono
Salidas: assets/blender/volcan_v2/volcan_bloques_4.blend (cono: volcan_bloques_4b.blend),
assets/textures/VolcanBloques_color.png y renders en renders/volcan_v2b/ (cono: volcan_v2c/). El agua y el puente de los renders van en la colección
Referencia: no se exportan.
"""
import bpy, bmesh, json, math, os, sys
from mathutils import Vector as V

HERE = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.normpath(os.path.join(HERE, "..", ".."))
L = json.load(open(os.path.join(RAIZ, "src", "shared", "WorldLayoutData.json"), encoding="utf-8"))
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
# anillo: el cráter de ahora (v2); cono: el volcán grande que se cierra hacia la boca (v3,
# volcan_cono_forma.py).
FORMA = ARGS[ARGS.index("--forma") + 1] if "--forma" in ARGS else "anillo"
SALIDA = {"anillo": ("volcan_bloques_4.blend", "volcan_v2b"), "cono": ("volcan_bloques_4b.blend", "volcan_v2c")}
BLEND = os.path.join(RAIZ, "assets", "blender", "volcan_v2", SALIDA[FORMA][0])
TEX = os.path.join(RAIZ, "assets", "textures", "VolcanBloques_color.png")
RENDERS = os.path.join(RAIZ, "renders", SALIDA[FORMA][1])

CELDA = 4.0  # studs por columna en x y z de Roblox (como la isla)
ESCALON = 2.0  # las alturas se redondean a esto (30, el paseo, y -18, el fondo del mar, caen justo)
BISEL = 0.4  # el borde de arriba de cada rectángulo (0.1 de la celda, como el de los gigantes)
SECTOR = 32  # columnas por lado de cada malla
LIMITE_TRIS = 20000

# --- La forma: CraterShape y WorldZones en Python -----------------------------------------
GATE = math.radians(L["bridgeAngle"] + 180)  # del cráter hacia la isla
RIDGE_END = 0.6


def smooth(t):
    t = min(max(t, 0.0), 1.0)
    return t * t * (3 - 2 * t)


def gate(angle):
    d = math.degrees(abs((angle - GATE + math.pi) % (2 * math.pi) - math.pi))
    return 1 - smooth((d - 14) / 12)


def peak(angle):
    shape = (0.55 + 0.3 * math.sin(5 * angle + 1.3) + 0.15 * math.sin(11 * angle + 0.4)
             + 0.08 * math.sin(23 * angle) + 0.1 * abs(math.sin(37 * angle + 0.7)))
    return L["craterPeakHeight"] * max(shape, 0.15) * (1 - gate(angle))


def lake_floor(rho):
    shelf_start = L["craterLakeRadius"] - L["craterShelfWidth"]
    shelf = L["waterLevel"] - L["craterShelfDepth"]
    if rho >= shelf_start:
        t = min((rho - shelf_start) / L["craterShelfWidth"], 1)
        return shelf + (L["craterShelfDepth"] - 3) * t
    t = max(rho - L["craterFlatRadius"], 0) / (shelf_start - L["craterFlatRadius"])
    return L["craterFloor"] + (shelf - L["craterFloor"]) * (1 - math.cos(math.pi * t)) / 2


def height(rho, angle):
    if rho >= L["craterBaseRadius"]:
        return None
    if rho < L["craterLakeRadius"]:
        return lake_floor(rho)
    if rho < L["craterCliffRadius"]:
        foot = lake_floor(L["craterLakeRadius"])
        t = (rho - L["craterLakeRadius"]) / (L["craterCliffRadius"] - L["craterLakeRadius"])
        return foot + (L["craterRimHeight"] - foot) * t ** 0.6
    walk_end = L["craterCliffRadius"] + L["craterWalkWidth"]
    if rho < walk_end:
        return L["craterRimHeight"]
    t = (rho - walk_end) / (L["craterBaseRadius"] - walk_end)
    slope = L["craterRimHeight"] + (L["seaFloorHeight"] - L["craterRimHeight"]) * t ** 1.6
    ridge = peak(angle) * math.sin(math.pi * min(t / RIDGE_END, 1)) ** 1.3
    h = slope + ridge
    if rho < L["craterRimOuter"]:
        h += (max(h, L["craterRimHeight"]) - h) * gate(angle)
    return h


def lava_vein(angle, rho):
    return math.sin(angle * 11 + rho * 0.35) + math.sin(angle * 5 - rho * 0.2) > 1.45


def material(rho, angle, h):
    """Como CraterShape.material, con nombres de la paleta."""
    if rho < L["craterLakeRadius"]:
        shelf_start = L["craterLakeRadius"] - L["craterShelfWidth"] - 12
        return "caliza" if rho >= shelf_start else "pozo"
    if rho < L["craterCliffRadius"] + L["craterWalkWidth"]:
        return "basalto"
    if h < L["waterLevel"] + 3:
        return "roca"
    if lava_vein(angle, rho):
        return "lava"
    if h > L["craterRimHeight"] + L["craterPeakHeight"] * 0.55:
        return "cumbre"
    return "basalto"


# --- Paleta (sRGB): arriba y lado de cada material ------------------------------------------
COLORES = {
    "basalto": ((100, 86, 88), (58, 49, 55)),
    "basalto2": ((114, 96, 94), (68, 57, 61)),  # variación por columna: que no se vea liso
    "cumbre": ((80, 66, 70), (46, 38, 44)),
    "cumbre2": ((94, 77, 79), (54, 44, 50)),
    "pozo": ((52, 46, 54), (36, 32, 40)),
    "caliza": ((76, 132, 126), (54, 98, 96)),  # bajo el agua se ve turquesa
    "roca": ((150, 140, 128), (112, 104, 96)),
    "lava": ((255, 136, 44), (92, 50, 42)),  # lado: piedra caliente (la lava va arriba)
}
VARIANTES = {"basalto": "basalto2", "cumbre": "cumbre2"}
CARAS = ("arriba", "lado")
NOMBRES = [f"{c}_{l}" for c in COLORES for l in CARAS]
PX, POR_FILA = 32, 6


def paleta():
    lado = PX * POR_FILA
    img = bpy.data.images.new("VolcanBloques_color", lado, lado)
    px = [0.0] * (lado * lado * 4)
    for i, nombre in enumerate(NOMBRES):
        color, cara = nombre.rsplit("_", 1)
        r, g, b = (c / 255 for c in COLORES[color][CARAS.index(cara)])
        cx, cy = (i % POR_FILA) * PX, (i // POR_FILA) * PX
        for y in range(cy, cy + PX):
            for x in range(cx, cx + PX):
                k = (y * lado + x) * 4
                px[k : k + 4] = [r, g, b, 1.0]
    img.pixels = px
    img.filepath_raw = TEX
    img.file_format = "PNG"
    os.makedirs(os.path.dirname(TEX), exist_ok=True)
    img.save()
    return img


def uv_de(nombre):
    i = NOMBRES.index(nombre)
    return V((((i % POR_FILA) + 0.5) / POR_FILA, ((i // POR_FILA) + 0.5) / POR_FILA))


# --- La cuadrícula de columnas -------------------------------------------------------------
# Lo que cambia con la forma (volcan_cono_forma.py redefine estas cuatro cosas):
R_MAX = L["craterBaseRadius"]  # radio hasta donde puede haber columnas


def forma(dx, dz):
    """(altura, material) del suelo en (dx, dz) desde el centro del cráter, o None."""
    rho, angle = math.hypot(dx, dz), math.atan2(dz, dx)
    h = height(rho, angle)
    return None if h is None else (h, material(rho, angle, h))


def bloque(dx, dz):
    """Columnas por lado que comparten una altura (menos detalle lejos): 1 en el anillo."""
    return 1


def variante(i, j):
    """Tono alternativo en manchas irregulares de pocas columnas: varía por columna sin
    partir todo en cuadritos (los rectángulos de igual color quedan más grandes)."""
    campo = math.sin(i * 0.83 + 1.1) + math.sin(j * 0.71 + 0.4) + math.sin((i - j) * 0.53 + 2.3)
    return campo > 0.9


def columnas():
    """{(i, j): (altura, material)} con i, j de -N a N-1; la celda (i, j) va de i*CELDA a
    (i+1)*CELDA en x de Roblox y de j*CELDA a (j+1)*CELDA en z. Donde bloque() da k > 1, las
    k x k columnas del bloque toman la altura y el color de su centro (se juntan solas)."""
    grilla = {}
    for i in range(-N, N):
        for j in range(-N, N):
            k = bloque((i + 0.5) * CELDA, (j + 0.5) * CELDA)
            i0, j0 = (i // k) * k, (j // k) * k
            muestra = forma((i0 + k / 2) * CELDA, (j0 + k / 2) * CELDA)
            if muestra is None:
                continue
            h, mat = muestra
            if mat in VARIANTES and variante(i0, j0):
                mat = VARIANTES[mat]
            grilla[(i, j)] = (round(h / ESCALON) * ESCALON, mat)
    return grilla


def punto(x, z, y):
    """Roblox (x, y, z) relativo al cráter -> Blender."""
    return V((x, -z, y))


class Malla:
    """Caras sueltas (los colores son por cara) con su UV; cada cara se orienta hacia afuera
    con la normal que se le pide (no se recalculan: con uniones en T podrían darse vuelta)."""

    def __init__(self):
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.verify()

    def cara(self, puntos, color, normal):
        vs = [self.bm.verts.new(p) for p in puntos]
        f = self.bm.faces.new(vs)
        f.normal_update()
        if f.normal.dot(V(normal)) < 0:
            f.normal_flip()
        c = uv_de(color)
        for l in f.loops:
            l[self.uv].uv = c

    def tris(self):
        return sum(len(f.verts) - 2 for f in self.bm.faces)


def rectangulos(grilla, celdas):
    """Junta las columnas vecinas de igual altura y color en rectángulos (greedy meshing):
    [(i, j, ancho, largo, (altura, material))]. La variación de tono por columna los deja
    chicos, así el bloque se sigue leyendo."""
    restantes = set(celdas)
    rects = []
    for i, j in sorted(celdas, key=lambda c: (c[1], c[0])):
        if (i, j) not in restantes:
            continue
        clave = grilla[(i, j)]
        ancho = 1
        while (i + ancho, j) in restantes and grilla[(i + ancho, j)] == clave:
            ancho += 1
        largo = 1
        while all((i + k, j + largo) in restantes and grilla[(i + k, j + largo)] == clave
                  for k in range(ancho)):
            largo += 1
        for k in range(ancho):
            for m in range(largo):
                restantes.discard((i + k, j + m))
        rects.append((i, j, ancho, largo, clave))
    return rects


ARRIBA = (0, 0, 1)


def rectangulo(malla, brasa, grilla, i, j, ancho, largo, clave):
    """Tapa con bisel en todo el borde del rectángulo y los lados que se ven, en tiras: cada
    tira baja hasta la vecina más baja (o al fondo del mar en el borde del volcán). La tapa y
    el bisel de la lava van a `brasa` (en Roblox, Neon); sus lados, a `malla`."""
    alto, mat = clave
    tapa = brasa if mat == "lava" else malla
    x0, x1 = i * CELDA, (i + ancho) * CELDA
    z0, z1 = j * CELDA, (j + largo) * CELDA
    b, hb = BISEL, alto - BISEL
    arriba, lado = f"{mat}_arriba", f"{mat}_lado"
    # Lados en orden: -z, +x, +z, -x (celdas vecinas, cómo ubicar el tramo k, normal).
    bordes = (
        ([(i + k, j - 1) for k in range(ancho)], lambda k, y: punto(x0 + k * CELDA, z0, y), (0, -1)),
        ([(i + ancho, j + m) for m in range(largo)], lambda k, y: punto(x1, z0 + k * CELDA, y), (1, 0)),
        ([(i + k, j + largo) for k in range(ancho)], lambda k, y: punto(x0 + k * CELDA, z1, y), (0, 1)),
        ([(i - 1, j + m) for m in range(largo)], lambda k, y: punto(x0, z0 + k * CELDA, y), (-1, 0)),
    )
    # Sin bisel donde todas las vecinas son más altas: su pared tapa ese borde (y ahorra caras).
    bisel = [any(grilla.get(c, (-1e9,))[0] < alto + ESCALON for c in vecinas) for vecinas, _, _ in bordes]
    sx0 = b if bisel[3] else 0.0
    sx1 = b if bisel[1] else 0.0
    sz0 = b if bisel[0] else 0.0
    sz1 = b if bisel[2] else 0.0
    t = [punto(x0 + sx0, z0 + sz0, alto), punto(x1 - sx1, z0 + sz0, alto),
         punto(x1 - sx1, z1 - sz1, alto), punto(x0 + sx0, z1 - sz1, alto)]
    tapa.cara(t, arriba, ARRIBA)
    e = [punto(x0, z0, hb), punto(x1, z0, hb), punto(x1, z1, hb), punto(x0, z1, hb)]
    afuera = [punto(0, -1, 1), punto(1, 0, 1), punto(0, 1, 1), punto(-1, 0, 1)]
    for k in range(4):
        if bisel[k]:
            tapa.cara([e[k], e[(k + 1) % 4], t[(k + 1) % 4], t[k]], arriba, afuera[k])
    for vecinas, en, (nx, nz) in bordes:
        normal = punto(nx, nz, 0)
        pisos = []
        for c in vecinas:
            vecina = grilla.get(c)
            piso = vecina[0] - b if vecina else L["seaFloorHeight"] - ESCALON
            pisos.append(piso if piso < hb else None)
        k = 0
        while k < len(pisos):  # tiras: tramos seguidos con el mismo piso
            if pisos[k] is None:
                k += 1
                continue
            fin = k
            while fin + 1 < len(pisos) and pisos[fin + 1] == pisos[k]:
                fin += 1
            piso = pisos[k]
            malla.cara([en(k, piso), en(fin + 1, piso), en(fin + 1, hb), en(k, hb)], lado, normal)
            k = fin + 1


def objeto(nombre, malla, mat):
    me = bpy.data.meshes.new(nombre)
    bmesh.ops.remove_doubles(malla.bm, verts=malla.bm.verts, dist=0.001)
    malla.bm.normal_update()
    malla.bm.to_mesh(me)
    malla.bm.free()
    for p in me.polygons:
        p.use_smooth = False
    o = bpy.data.objects.new(nombre, me)
    o.data.materials.append(mat)
    bpy.context.scene.collection.objects.link(o)
    return o


def material_paleta(img, nombre, emision=0.0):
    mat = bpy.data.materials.new(nombre)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.9
    if emision > 0:
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = emision
    return mat


def construir():
    img = paleta()
    roca = material_paleta(img, "VolcanBloques")
    lava = material_paleta(img, "VolcanLava", emision=2.5)  # en Roblox: Neon
    grilla = columnas()
    sectores = {}
    for (i, j) in grilla:
        clave = ((j + N) // SECTOR, (i + N) // SECTOR)
        sectores.setdefault(clave, []).append((i, j))
    objetos, informe = [], {}
    brasa = Malla()  # toda la lava en una malla: son pocas caras
    for (fila, col), celdas in sorted(sectores.items()):
        piedra = Malla()
        for rect in rectangulos(grilla, celdas):
            rectangulo(piedra, brasa, grilla, *rect)
        nombre = f"Volcan_{fila}_{col}"
        informe[nombre] = piedra.tris()
        assert informe[nombre] < LIMITE_TRIS, f"{nombre}: {informe[nombre]} triángulos"
        objetos.append(objeto(nombre, piedra, roca))
    informe["VolcanLava"] = brasa.tris()
    assert informe["VolcanLava"] < LIMITE_TRIS
    objetos.append(objeto("VolcanLava", brasa, lava))
    return objetos, informe, grilla


# --- Revisión: agua, puente de referencia, luz y cámaras -----------------------------------
def referencia(o):
    """Lo que solo sirve para revisar va en la colección Referencia (se puede ocultar)."""
    coleccion = bpy.data.collections.get("Referencia")
    if coleccion is None:
        coleccion = bpy.data.collections.new("Referencia")
        bpy.context.scene.collection.children.link(coleccion)
    coleccion.objects.link(o)
    return o


def plano_agua():
    me = bpy.data.meshes.new("Agua")
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=R_MAX + 400)
    bmesh.ops.translate(bm, vec=V((0, 0, L["waterLevel"])), verts=bm.verts)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new("Agua (solo revisión)", me)
    mat = bpy.data.materials.new("Agua")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.02, 0.22, 0.42, 1)
    bsdf.inputs["Alpha"].default_value = 0.55
    bsdf.inputs["Roughness"].default_value = 0.08
    mat.blend_method = "BLEND" if hasattr(mat, "blend_method") else mat.blend_method
    if hasattr(mat, "surface_render_method"):
        mat.surface_render_method = "BLENDED"
    o.data.materials.append(mat)
    referencia(o)
    return o


def puente():
    """El puente hasta la puerta (solo para ubicarse en los renders)."""
    d = V((math.cos(math.radians(L["bridgeAngle"])), math.sin(math.radians(L["bridgeAngle"]))))
    # del cráter hacia la isla en Roblox es -d; largo hasta la meseta
    largo = math.hypot(L["craterCenter"][0], L["craterCenter"][1]) - L["craterRimOuter"] - L["bridgeStartRadius"] + 2
    me = bpy.data.meshes.new("Puente")
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1)
    bmesh.ops.scale(bm, vec=V((L["bridgeWidth"], largo, 1.2)), verts=bm.verts)
    centro_dz = -(L["craterRimOuter"] - 2 + largo / 2)  # dz desde el cráter (la isla está en -z)
    bmesh.ops.translate(bm, vec=punto(0, centro_dz, L["craterDeckHeight"] - 0.6), verts=bm.verts)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new("Puente (solo revisión)", me)
    mat = bpy.data.materials.new("Madera")
    mat.use_nodes = True
    mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.36, 0.2, 0.09, 1)
    o.data.materials.append(mat)
    referencia(o)
    return o


def escena():
    sc = bpy.context.scene
    motores = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    sc.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in motores else "BLENDER_EEVEE"
    sc.render.resolution_x, sc.render.resolution_y = 1600, 900
    sc.view_settings.view_transform = "Standard"
    mundo = bpy.data.worlds.new("Cielo")
    mundo.use_nodes = True
    mundo.node_tree.nodes["Background"].inputs[0].default_value = (0.36, 0.58, 0.86, 1)
    mundo.node_tree.nodes["Background"].inputs[1].default_value = 0.9
    sc.world = mundo
    sol = bpy.data.objects.new("Sol", bpy.data.lights.new("Sol", "SUN"))
    sol.data.energy = 4.0
    sol.data.color = (1.0, 0.93, 0.82)
    sol.data.angle = math.radians(3)
    sol.rotation_euler = (math.radians(48), 0, math.radians(30))
    sc.collection.objects.link(sol)
    relleno = bpy.data.objects.new("Relleno", bpy.data.lights.new("Relleno", "SUN"))
    relleno.data.energy = 1.0
    relleno.rotation_euler = (math.radians(70), 0, math.radians(-150))
    sc.collection.objects.link(relleno)
    cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
    cam.data.clip_end = 5000
    sc.collection.objects.link(cam)
    sc.camera = cam
    return cam


def foto(cam, nombre, desde, hacia, lente=35):
    cam.location = desde
    cam.rotation_euler = (V(hacia) - V(desde)).to_track_quat("-Z", "Y").to_euler()
    cam.data.lens = lente
    sc = bpy.context.scene
    sc.render.filepath = os.path.join(RENDERS, f"{nombre}.png")
    bpy.ops.render.render(write_still=True)


def referencias():
    plano_agua()
    puente()


def fotos(cam, grilla):
    rim = L["craterRimHeight"]
    # Desde la isla, del lado del puente (la isla queda hacia +y en Blender).
    foto(cam, "1_desde_la_isla", punto(140, -520, 70), punto(0, 0, 20), 30)
    foto(cam, "2_cenital", V((0, 0, 1250)), V((0, 0.01, 0)), 40)
    # Desde el paseo del borde (lado de la puerta, a la altura de los ojos), mirando el lago.
    paseo = L["craterCliffRadius"] + 6
    foto(cam, "3_desde_el_paseo", punto(10, -paseo, rim + 14), punto(0, 140, -20), 26)
    # De cerca, una ladera con vetas: busca una columna de lava a media altura.
    # La ladera de afuera con más lava, vista desde el mar (como al llegar por el puente).
    lavas = [(i, j) for (i, j), (h, m) in grilla.items() if m == "lava" and 20 < h < 60]
    mejor = max(lavas, key=lambda c: sum(1 for d in range(-4, 5) for e in range(-4, 5)
                                          if grilla.get((c[0] + d, c[1] + e), (0, ""))[1] == "lava"))
    cx, cz = (mejor[0] + 0.5) * CELDA, (mejor[1] + 0.5) * CELDA
    afuera = V((cx, cz)).normalized()
    alto = grilla[mejor][0]
    desde = punto(cx + afuera.x * 130, cz + afuera.y * 130, alto + 40)
    foto(cam, "4_vetas_de_lava", desde, punto(cx, cz, alto - 5), 35)


if FORMA == "cono":
    exec(open(os.path.join(HERE, "volcan_cono_forma.py"), encoding="utf-8").read(), globals())
N = int(math.ceil(R_MAX / CELDA))  # columnas desde el centro hasta el borde


def main():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    objetos, informe, grilla = construir()
    referencias()
    cam = escena()
    os.makedirs(RENDERS, exist_ok=True)
    fotos(cam, grilla)
    os.makedirs(os.path.dirname(BLEND), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=BLEND)
    total = sum(informe.values())
    print("SECTORES", json.dumps(informe))
    print("TOTAL_TRIS", total, "COLUMNAS", len(grilla), "MAX", max(informe.values()),
          "ALTO_MAX", max(h for h, _ in grilla.values()))


if not globals().get("SOLO_FUNCIONES"):  # volcan_cueva.py lo carga solo por sus funciones
    main()
