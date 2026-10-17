r"""
Minotauro v2, etapa 1 (becerro) en estilo de bloques: bloques, placas y cuñas sobre la
cuadrícula de docs/estilo_modelos.md (celda de 0.1 BU, bisel de 0.012 en un segmento,
cuñas con pendiente 1:1, 1:2 o 2:1). Mantiene la estética del becerro actual: cabeza
grande, hocico crema con aro de oro, cuernitos de marfil con anillo de oro, orejas caídas,
mechón, cinturón con hebilla, faldón de tiras de cuero rojo, brazaletes y pezuñas.

Cada parte es un objeto rígido con el nombre del hueso que la va a mover (contrato de
huesos de docs/inventario_modelos.md) y su colección (Cabeza, Mandibula, Torso, Brazos,
Piernas, Cola, Orejas, Faldon). obj["hueso"] guarda ese hueso.
Ejes: x = izquierda del personaje, -y = frente, z arriba; parado en z = 0, centrado en x.
Sin textura ni rig: solo colores planos de la paleta para revisar la forma.

Uso (desde la raíz del repo):
    blender -b --factory-startup --python tools/blender/minotauro_v2_e1_bloques.py -- \
        [salida.blend] [carpeta de renders]
"""
import bpy, bmesh, json, math, os, sys
import numpy as np
from mathutils import Vector as V

HERE = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(HERE, "minotauro_v2_revision.py"), encoding="utf-8").read(), globals())
RAIZ = os.path.normpath(os.path.join(HERE, "..", ".."))
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
BLEND = ARGS[0] if ARGS else os.path.join(RAIZ, "assets", "blender", "minotauro_v2", "e1_bloques.blend")
RENDERS = ARGS[1] if len(ARGS) > 1 else os.path.join(RAIZ, "renders", "minotauro_v2_e1")

CELDA = 0.1
BISEL = 0.012
PENDIENTES = (0.5, 1.0, 2.0)  # celdas que se mete el lado / celdas de largo
ALTO_JUEGO = 16.5  # studs: 3 x 5.5 (Config/Giants.luau)
# Pisotón (minotauro_v2_e1_pisoton.py): celdas que el frente del cinturón y el
# faldón salen hacia adelante (aprobado: 1, así la bisagra del faldón queda fuera
# del recorrido de la rodilla; con 0 la rodilla atraviesa la raíz de las tiras).
ADELANTE = 1

# --- Paleta (lineal, la misma de minotauro_e1.py) ---------------------------------------
COLORES = {
    "pelo": (0.26, 0.085, 0.03), "pelo_osc": (0.085, 0.028, 0.012), "crema": (0.78, 0.5, 0.27),
    "hocico": (0.85, 0.5, 0.38), "rosa": (0.82, 0.32, 0.33), "nariz": (0.25, 0.03, 0.04),
    "cuero": (0.12, 0.045, 0.02), "cuero_rojo": (0.2, 0.025, 0.02), "oro": (1.0, 0.62, 0.12),
    "marfil": (0.86, 0.76, 0.56), "negro": (0.01, 0.008, 0.008), "blanco": (0.9, 0.9, 0.9),
    "pezuna": (0.04, 0.03, 0.03),
}
PARTES = {}  # nombre -> {"coleccion", "bloques": [(puntos, color)]}
EJES = "xyz"


def bloque(parte, coleccion, color, x, y, z, eje="z", fin="+", recorte=None):
    """Un bloque de x, y, z = (desde, hasta) en celdas. recorte {"x-": n, "y+": n, ...}:
    cuántas celdas se mete cada lado en el extremo `fin` del `eje` (así se hace una cuña)."""
    rangos = {"x": x, "y": y, "z": z}
    largo = rangos[eje][1] - rangos[eje][0]
    for k, n in (recorte or {}).items():
        assert n / largo in PENDIENTES, f"{parte}: pendiente {n}:{largo} fuera de la cuadrícula"
    puntos = []
    for extremo in (0, 1):
        r = {e: list(v) for e, v in rangos.items()}
        if (extremo == 1) == (fin == "+"):
            for k, n in (recorte or {}).items():
                r[k[0]][0 if k[1] == "-" else 1] += n if k[1] == "-" else -n
        for e in EJES:
            assert r[e][0] <= r[e][1], f"{parte}: recorte demasiado grande"
        a, b = [e for e in EJES if e != eje]
        for i in r[a]:
            for j in r[b]:
                p = {eje: rangos[eje][extremo], a: i, b: j}
                puntos.append(V((p["x"], p["y"], p["z"])) * CELDA)
    PARTES.setdefault(parte, {"coleccion": coleccion, "bloques": []})["bloques"].append((puntos, color))


def par(parte, coleccion, color, x, y, z, eje="z", fin="+", recorte=None):
    """El mismo bloque a la izquierda (x+) y espejado a la derecha. `parte` lleva {lado}."""
    for s, lado in ((1, "Izq"), (-1, "Der")):
        xs = x if s > 0 else (-x[1], -x[0])
        rec = {(k if s > 0 or k[0] != "x" else "x" + ("+" if k[1] == "-" else "-")): n
               for k, n in (recorte or {}).items()}
        f = fin if s > 0 or eje != "x" else ("-" if fin == "+" else "+")
        bloque(parte.format(lado=lado), coleccion, color, xs, y, z, eje, f, rec)


# --- El becerro, en celdas ------------------------------------------------------------
def piernas():
    par("Pie{lado}", "Piernas", "pezuna", (1, 5), (-4, 2), (0, 2), recorte={"y-": 1})
    par("Pierna{lado}", "Piernas", "pelo", (1, 5), (-2, 2), (2, 6))
    par("Muslo{lado}", "Piernas", "pelo", (1, 5), (-2, 2), (6, 11))
    par("Muslo{lado}", "Piernas", "pelo_osc", (1, 5), (-3, -2), (5, 7))  # rodillera


def torso():
    t = "Torso"
    bloque("Cadera", t, "pelo", (-4, 4), (-3, 3), (9, 10))
    a = ADELANTE
    bloque("Cadera", t, "cuero", (-7, 7), (-4 - a, 4), (10, 12))  # cinturón
    bloque("Cadera", t, "oro", (-2, 2), (-5 - a, -4 - a), (10, 12))  # hebilla
    bloque("Cadera", t, "cuero_rojo", (-1, 1), (-6 - a, -5 - a), (10, 12))
    bloque("Columna", t, "pelo", (-5, 5), (-3, 3), (12, 15))
    bloque("Columna", t, "crema", (-4, 4), (-5, -3), (12, 15))  # panza
    bloque("Columna", t, "pelo_osc", (-4, 4), (3, 4), (12, 17))  # placa del lomo
    bloque("Columna", t, "pelo_osc", (-2, 2), (4, 5), (13, 16))
    bloque("Pecho", t, "pelo", (-5, 5), (-3, 3), (15, 18))
    bloque("Pecho", t, "pelo", (-5, 5), (-3, 3), (18, 19), recorte={"x-": 1, "x+": 1})
    bloque("Pecho", t, "crema", (-3, 3), (-4, -3), (15, 18))
    bloque("Pecho", t, "pelo_osc", (-4, 4), (3, 5), (17, 19), recorte={"y+": 2})  # joroba
    bloque("Cuello", t, "pelo", (-3, 3), (-2, 2), (17, 20))


def brazos():
    b = "Brazos"
    # Hombrera partida (minotauro_v2_e1_poses.py): la mitad de adentro es del pecho y no se
    # mueve; la tapa va con el brazo, que gira por su borde de adentro (x = 8, z = 17). Una
    # celda por debajo de la cabeza, así las mejillas no la tocan al ladearla.
    par("Pecho", b, "pelo_osc", (4, 8), (-4, 4), (16, 18))
    par("Brazo{lado}", b, "pelo_osc", (8, 12), (-4, 4), (16, 18), recorte={"x+": 2})
    par("Brazo{lado}", b, "pelo", (9, 12), (-2, 1), (14, 17))
    par("Brazo{lado}", b, "pelo_osc", (8, 13), (-3, 2), (13, 15))  # codera
    par("Antebrazo{lado}", b, "pelo", (9, 12), (-2, 1), (11, 14))
    par("Antebrazo{lado}", b, "oro", (8, 13), (-3, 2), (10, 11))  # brazalete
    par("Mano{lado}", b, "pelo", (8, 13), (-3, 2), (7, 10))
    par("Mano{lado}", b, "pelo_osc", (8, 13), (-4, -3), (8, 10))  # nudillos


def cabeza():
    c = "Cabeza"
    bloque("Cabeza", c, "pelo", (-6, 6), (-5, 4), (19, 28))
    bloque("Cabeza", c, "pelo", (-6, 6), (-5, 4), (28, 29), recorte={"x-": 1, "x+": 1})
    bloque("Cabeza", c, "pelo_osc", (-5, 5), (-6, -5), (26, 28))  # frente
    par("Cabeza", c, "pelo_osc", (6, 7), (-4, 1), (20, 24))  # mejillas
    bloque("Cabeza", c, "pelo_osc", (-4, 4), (4, 5), (21, 27))  # nuca, en escalones
    bloque("Cabeza", c, "pelo_osc", (-2, 2), (5, 6), (22, 26))
    par("Cabeza", c, "negro", (1, 4), (-6, -5), (23, 25))  # ojos
    par("Cabeza", c, "negro", (1, 3), (-6, -5), (25, 26))
    par("Cabeza", c, "blanco", (3, 4), (-6, -5), (25, 26))
    # Hocico: base, cuña hacia los ojos y frente con las narinas.
    bloque("Cabeza", c, "hocico", (-4, 4), (-8, -5), (19, 22))
    bloque("Cabeza", c, "hocico", (-4, 4), (-8, -5), (22, 23), recorte={"y-": 1})
    bloque("Cabeza", c, "hocico", (-4, 4), (-9, -8), (19, 22))
    par("Cabeza", c, "nariz", (1, 3), (-10, -9), (20, 22))  # narinas
    par("Cabeza", c, "oro", (1, 2), (-10, -9), (18, 20))  # aro de la nariz
    bloque("Cabeza", c, "oro", (-2, 2), (-10, -9), (17, 18))
    # Mechón y cuernitos.
    # El mechón se apoya sobre la cabeza (no se mete en la cuña de arriba): base sobre la
    # frente, cuña encima y la punta que cae por delante.
    bloque("Cabeza", c, "pelo_osc", (-3, 3), (-6, -5), (28, 29))
    bloque("Cabeza", c, "pelo_osc", (-3, 3), (-6, -1), (29, 31), recorte={"y+": 2})
    bloque("Cabeza", c, "pelo_osc", (-2, 2), (-7, -6), (26, 30))
    par("Cabeza", c, "marfil", (6, 9), (-2, 1), (25, 27))  # sale de lado
    par("Cabeza", c, "oro", (7, 8), (-3, 2), (24, 28))  # anillo
    par("Cabeza", c, "marfil", (8, 10), (-2, 1), (27, 29))  # sube
    par("Cabeza", c, "marfil", (8, 10), (-2, 1), (29, 31), recorte={"x-": 1, "y-": 1, "y+": 1})
    bloque("Mandibula", "Mandibula", "crema", (-3, 3), (-8, -4), (17, 19))


def orejas_cola_faldon():
    par("Oreja{lado}", "Orejas", "pelo", (7, 10), (-1, 2), (22, 24))
    par("Oreja{lado}", "Orejas", "pelo", (10, 12), (-1, 2), (21, 23), eje="x", recorte={"z+": 1})
    par("Oreja{lado}", "Orejas", "rosa", (7, 10), (-2, -1), (22, 24))
    bloque("Cola1", "Cola", "pelo", (-1, 1), (3, 6), (9, 11))
    bloque("Cola2", "Cola", "pelo", (-1, 1), (6, 8), (7, 10))
    bloque("Cola3", "Cola", "pelo", (-1, 1), (7, 9), (4, 7))
    bloque("Cola3", "Cola", "pelo_osc", (-2, 2), (6, 10), (2, 4))  # borla
    bloque("Cola3", "Cola", "pelo_osc", (-2, 2), (6, 10), (1, 2), fin="-",
           recorte={"x-": 1, "x+": 1, "y-": 1, "y+": 1})
    # Faldón: tres tiras adelante y dos a cada lado, con remaches de oro.
    for x, largo in (((-4, -2), 4), ((-1, 1), 5), ((2, 4), 4)):
        a = ADELANTE
        bloque("FaldonFrente", "Faldon", "cuero_rojo", x, (-5 - a, -4 - a), (10 - largo, 10))
        bloque("FaldonFrente", "Faldon", "oro", x, (-6 - a, -5 - a), (9, 10))
    for y in ((-3, -1), (0, 2)):
        par("Faldon{lado}", "Faldon", "cuero_rojo", (6, 7), y, (6, 10))
        par("Faldon{lado}", "Faldon", "oro", (7, 8), y, (9, 10))


# --- Mallas ----------------------------------------------------------------------------
def material(nombre):
    m = bpy.data.materials.get("MinoV2_" + nombre)
    if m:
        return m
    m = bpy.data.materials.new("MinoV2_" + nombre)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*COLORES[nombre], 1)
    bsdf.inputs["Roughness"].default_value = 0.35 if nombre == "oro" else 0.65
    bsdf.inputs["Metallic"].default_value = 0.8 if nombre == "oro" else 0.0
    return m


def solido(parte, color, puntos):
    """Bloque convexo: sus caras sin bisel (para revisar) y la malla con bisel."""
    b = bmesh.new()
    unicos = {tuple(round(c, 6) for c in p) for p in puntos}
    bmesh.ops.convex_hull(b, input=[b.verts.new(p) for p in unicos])
    bmesh.ops.dissolve_limit(b, angle_limit=math.radians(1), verts=b.verts[:], edges=b.edges[:])
    bmesh.ops.recalc_face_normals(b, faces=b.faces[:])
    caras = [(f.normal.copy(), [v.co.copy() for v in f.verts]) for f in b.faces]
    antes = (len(b.faces), len(b.edges), len(b.verts))
    bmesh.ops.bevel(b, geom=b.edges[:], offset=BISEL, segments=1, affect="EDGES",
                    profile=0.5, clamp_overlap=True)
    bmesh.ops.recalc_face_normals(b, faces=b.faces[:])
    return {"parte": parte, "color": color, "b": b, "caras": caras, "antes": antes,
            "despues": len(b.faces)}


def _muestras(f, paso=0.02):
    """Puntos que cubren la cara (rejilla + vértices), apenas por fuera del bloque."""
    n, c = f.normal, f.calc_center_median()
    u = n.orthogonal().normalized()
    v = n.cross(u)
    poli = [((p.co - c).dot(u), (p.co - c).dot(v)) for p in f.verts]
    xs, ys = [p[0] for p in poli], [p[1] for p in poli]
    pts = [(x * 0.98, y * 0.98) for x, y in poli] + [(0.0, 0.0)]
    for x in np.arange(min(xs), max(xs), paso):
        for y in np.arange(min(ys), max(ys), paso):
            if all((b[0] - a[0]) * (y - a[1]) - (b[1] - a[1]) * (x - a[0]) >= 0
                   for a, b in zip(poli, poli[1:] + poli[:1])):
                pts.append((x, y))
    return np.array([tuple(c + u * x + v * y + n * 1e-3) for x, y in pts])


def quitar_ocultas(solidos):
    """Borra las caras de un bloque tapadas por completo por otros bloques de la MISMA pieza
    (la pieza es rígida: nunca se separan). Se compara contra la cuña sin bisel, así que en
    la ranura del bisel entre dos vecinos puede quedar una rendija de 0.012 BU: no se ve."""
    quitadas = 0
    for s in solidos:
        cajas = []
        for o in solidos:
            if o is s:
                continue
            N = np.array([tuple(n) for n, _ in o["caras"]])
            D = np.array([n.dot(pts[0]) for n, pts in o["caras"]])
            todos = np.array([tuple(p) for _, pts in o["caras"] for p in pts])
            cajas.append((N, D, todos.min(axis=0) - 2e-3, todos.max(axis=0) + 2e-3))
        borrar = []
        for f in s["b"].faces:
            pts = _muestras(f)
            cubierto = np.zeros(len(pts), dtype=bool)
            for N, D, lo, hi in cajas:
                if ((pts >= lo) & (pts <= hi)).all(axis=1).any():
                    cubierto |= (pts @ N.T - D <= 1e-6).all(axis=1)
            if cubierto.all():
                borrar.append(f)
        quitadas += sum(len(f.verts) - 2 for f in borrar)
        bmesh.ops.delete(s["b"], geom=borrar, context="FACES_ONLY")
    return quitadas


def malla(nombre, solidos):
    bm = bmesh.new()
    colores = []
    for s in solidos:
        if s["color"] not in colores:
            colores.append(s["color"])
        copia = {v: bm.verts.new(v.co) for v in s["b"].verts}
        for f in s["b"].faces:
            bm.faces.new([copia[v] for v in f.verts]).material_index = colores.index(s["color"])
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    me = bpy.data.meshes.new(nombre)
    bm.to_mesh(me)
    bm.free()
    for c in colores:
        me.materials.append(material(c))
    return me


def armar():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    piernas(); torso(); brazos(); cabeza(); orejas_cola_faldon()
    raiz = bpy.data.collections.new("MinotauroE1_v2")
    bpy.context.scene.collection.children.link(raiz)
    for nombre, parte in PARTES.items():
        col = bpy.data.collections.get(parte["coleccion"])
        if not col:
            col = bpy.data.collections.new(parte["coleccion"])
            raiz.children.link(col)
        parte["solidos"] = [solido(nombre, c, p) for p, c in parte["bloques"]]
        parte["tris_ocultos"] = quitar_ocultas(parte["solidos"])
        o = bpy.data.objects.new(nombre, malla(nombre, parte["solidos"]))
        o["hueso"] = nombre  # las piezas del faldón van a sus huesos opcionales (hijos de Cadera)
        col.objects.link(o)
    return [o for o in raiz.all_objects]


# --- Revisión: estadísticas y renders ----------------------------------------------------
def estadisticas(objetos):
    solidos = [s for p in PARTES.values() for s in p["solidos"]]
    tris = {o.name: sum(len(p.vertices) - 2 for p in o.data.polygons) for o in objetos}
    zs = [(o.matrix_world @ v.co).z for o in objetos for v in o.data.vertices]
    alto = max(zs) - min(zs)
    return {
        "bloques": len(solidos),
        "bloques_por_parte": {n: len(p["bloques"]) for n, p in PARTES.items()},
        "triangulos": sum(tris.values()),
        "triangulos_ocultos_quitados": {n: p["tris_ocultos"] for n, p in PARTES.items() if p["tris_ocultos"]},
        "triangulos_por_parte": tris,
        "partes": len(objetos),
        "alto_bu": round(alto, 4),
        "studs_por_bu": round(ALTO_JUEGO / alto, 4),
        "caras_coplanares": coplanares(solidos),
        "normales_hacia_adentro": normales(solidos),
        "bisel": bisel(solidos),
        "pendientes": pendientes(solidos, CELDA),
        "huesos": huesos(objetos),
    }


def estudio():
    """Luz, fondo, piso y cámara ortográfica de las revisiones."""
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 48
    sc.cycles.use_denoising = True
    sc.view_settings.view_transform = "Standard"
    sc.render.resolution_x = sc.render.resolution_y = 1000
    mundo = bpy.data.worlds.new("Estudio")
    mundo.use_nodes = True
    mundo.node_tree.nodes["Background"].inputs["Color"].default_value = (0.32, 0.36, 0.42, 1)
    mundo.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.9
    sc.world = mundo
    bpy.ops.mesh.primitive_plane_add(size=12, location=(0, 0, 0))
    piso = bpy.context.active_object
    piso.data.materials.append(bpy.data.materials.new("Piso"))
    piso.data.materials[0].diffuse_color = (0.3, 0.33, 0.36, 1)
    sol = bpy.data.objects.new("Sol", bpy.data.lights.new("Sol", "SUN"))
    sol.data.energy, sol.data.angle = 3.2, math.radians(8)
    sol.rotation_euler = (math.radians(50), 0, math.radians(-35))
    sc.collection.objects.link(sol)
    cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
    cam.data.type, cam.data.ortho_scale = "ORTHO", 3.7
    sc.collection.objects.link(cam)
    sc.camera = cam
    return sc, cam, sol


def renders(carpeta):
    os.makedirs(carpeta, exist_ok=True)
    sc, cam, sol = estudio()
    centro = V((0, 0, 1.55))
    vistas(sc, cam, sol, centro, carpeta, "")
    materiales_diagnostico([m.name for m in bpy.data.materials if m.name.startswith("MinoV2_")])
    sc.cycles.samples = 8
    vistas(sc, cam, sol, centro, carpeta, "diagnostico_")


def vistas(sc, cam, sol, centro, carpeta, prefijo):
    for nombre, angulo, alto in (("frente", 0, 0), ("perfil", 90, 0), ("tres_cuartos", 35, 0.35),
                                 ("atras", 180, 0)):
        a = math.radians(angulo)
        cam.location = centro + V((math.sin(a) * 10, -math.cos(a) * 10, alto * 10))
        cam.rotation_euler = (centro - cam.location).to_track_quat("-Z", "Y").to_euler()
        sol.rotation_euler = (math.radians(50), 0, a + math.radians(-35))
        sc.render.filepath = os.path.join(carpeta, f"{prefijo}{nombre}.png")
        bpy.ops.render.render(write_still=True)


objetos = armar()
datos = estadisticas(objetos)
os.makedirs(os.path.dirname(BLEND), exist_ok=True)
bpy.context.preferences.filepaths.save_version = 0  # sin copia .blend1
bpy.ops.wm.save_as_mainfile(filepath=BLEND)
renders(RENDERS)
with open(os.path.join(RENDERS, "estadisticas.json"), "w", encoding="utf-8") as f:
    json.dump(datos, f, indent=2, ensure_ascii=False)
print("ESTADISTICAS", json.dumps({k: v for k, v in datos.items() if "por_parte" not in k}, ensure_ascii=False))
