r"""
Minotauro v2 en estilo de bloques, cualquier etapa: bloques, placas y cuñas sobre la
cuadrícula de docs/estilo_modelos.md (cuñas con pendiente 1:1, 1:2 o 2:1, bisel de un
segmento). Lo propio de cada etapa vive en minotauro_v2_e<n>_geometria.py:
    CELDA           módulo de la etapa en BU (múltiplo de 0.1: los bloques crecen con el cuerpo)
    ALTO_JUEGO      alto de la etapa en el juego (studs)
    COLORES         paleta lineal {nombre: (r, g, b)}
    construir()     las piezas, con bloque() y par() en celdas del módulo
    ARTICULACIONES  [(hueso, padre, (x, y, z))] en celdas; {l} = lado (Izq en +x)
    COLAS           {hueso: (x, y, z)} hacia dónde apunta cada hueso
    PUNTOS          huesos sin pesos: {"Raiz": (padre, cabeza, cola), "Boca": ...}
El bisel es BISEL_CELDAS del módulo (0.012 BU en la E1).

Cada parte es un objeto rígido con el nombre del hueso que la va a mover (contrato de
huesos de docs/inventario_modelos.md) y su colección (Cabeza, Mandibula, Torso, Brazos,
Piernas, Cola, Orejas, Faldon). obj["hueso"] guarda ese hueso.
Ejes: x = izquierda del personaje, -y = frente, z arriba; parado en z = 0, centrado en x.
Sin textura ni rig: solo colores planos de la paleta para revisar la forma.

Otras criaturas (--criatura, sin él el minotauro): carga <criatura>_v2_e<n>_geometria.py, que
además puede traer
    MODELO          nombre del modelo en el juego (la colección es <MODELO>E<n>_v2)
    PREFIJO         prefijo de los materiales (el del minotauro es MinoV2_)
    CONTRATO        lista de huesos del contrato y CONTRATO_SIN_PESOS (si no, los del minotauro)
    LARGO_JUEGO     se mide por su dimensión más larga (studs) en vez del alto: el encuadre
                    toma la caja entera y studs_por_bu sale de esa dimensión (el dragón)
    VISTAS_EXTRA    más vistas (nombre, ángulo, alto); con alto negativo, desde abajo y sin piso
    PISO_BAJO       cuánto más abajo va el piso (en las medidas de la E1), para que no parezca posado

Uso (desde la raíz del repo; sin --etapa, la 1):
    blender -b --factory-startup --python tools/blender/minotauro_v2_bloques.py -- --etapa 2
    blender -b --factory-startup --python tools/blender/minotauro_v2_bloques.py -- --criatura dragon
Salidas: assets/blender/<criatura>_v2/e<n>_bloques.blend y renders/<criatura>_v2_e<n>/.
"""
import bpy, bmesh, json, math, os, sys
import numpy as np
from mathutils import Vector as V

HERE = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(HERE, "minotauro_v2_revision.py"), encoding="utf-8").read(), globals())
RAIZ = os.path.normpath(os.path.join(HERE, "..", ".."))
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
ETAPA = int(ARGS[ARGS.index("--etapa") + 1]) if "--etapa" in ARGS else 1
# La criatura: la fija el script que carga este archivo (dragon_v2_poses.py) o --criatura.
CRIATURA = globals().get("CRIATURA") or (ARGS[ARGS.index("--criatura") + 1] if "--criatura" in ARGS
                                         else "minotauro")
exec(open(os.path.join(HERE, f"{CRIATURA}_v2_e{ETAPA}_geometria.py"), encoding="utf-8").read(), globals())
BLEND = os.path.join(RAIZ, "assets", "blender", f"{CRIATURA}_v2", f"e{ETAPA}_bloques.blend")
RENDERS = os.path.join(RAIZ, "renders", f"{CRIATURA}_v2_e{ETAPA}")
MODELO = globals().get("MODELO", "Minotauro")
PREFIJO = globals().get("PREFIJO", "MinoV2_")
if "CONTRATO" in globals():  # si no, el contrato del minotauro (minotauro_v2_revision.py)
    HUESOS, SIN_PESOS = list(CONTRATO), set(CONTRATO_SIN_PESOS)
BISEL_CELDAS = 0.12
BISEL = BISEL_CELDAS * CELDA
PENDIENTES = (0.5, 1.0, 2.0)  # celdas que se mete el lado / celdas de largo

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


# --- Mallas ----------------------------------------------------------------------------
def material(nombre):
    m = bpy.data.materials.get(PREFIJO + nombre)
    if m:
        return m
    m = bpy.data.materials.new(PREFIJO + nombre)
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


def _muestras(f):
    """Puntos que cubren la cara (rejilla de 1/5 de celda + vértices), apenas por fuera del
    bloque. Todo en proporción al módulo: en la E1, rejilla de 0.02 BU y 0.001 BU afuera."""
    paso = 0.2 * CELDA
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
    return np.array([tuple(c + u * x + v * y + n * 0.01 * CELDA) for x, y in pts])


def quitar_ocultas(solidos):
    """Borra las caras de un bloque tapadas por completo por otros bloques de la MISMA pieza
    (la pieza es rígida: nunca se separan). Se compara contra la cuña sin bisel, así que en
    la ranura del bisel entre dos vecinos puede quedar una rendija del ancho del bisel: no se ve."""
    quitadas = 0
    for s in solidos:
        cajas = []
        for o in solidos:
            if o is s:
                continue
            N = np.array([tuple(n) for n, _ in o["caras"]])
            D = np.array([n.dot(pts[0]) for n, pts in o["caras"]])
            todos = np.array([tuple(p) for _, pts in o["caras"] for p in pts])
            cajas.append((N, D, todos.min(axis=0) - 0.02 * CELDA, todos.max(axis=0) + 0.02 * CELDA))
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
    construir()
    raiz = bpy.data.collections.new(f"{MODELO}E{ETAPA}_v2")
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
    } | medidas_por_largo(objetos)


def medidas_por_largo(objetos):
    """Criaturas que se miden por su dimensión más larga (LARGO_JUEGO): esa dimensión y los
    studs por BU que salen de ella (reemplazan a los del alto)."""
    if "LARGO_JUEGO" not in globals():
        return {}
    pts = np.array([tuple(o.matrix_world @ v.co) for o in objetos for v in o.data.vertices])
    dims = pts.max(axis=0) - pts.min(axis=0)
    return {"studs_por_bu": round(LARGO_JUEGO / dims.max(), 4),
            "dimensiones_bu": {"ancho_x": round(dims[0], 4), "largo_y": round(dims[1], 4),
                               "alto_z": round(dims[2], 4)},
            "dimension_mayor_bu": round(dims.max(), 4)}


def alto_bu():
    """Alto de las piezas armadas (BU)."""
    zs = [(o.matrix_world @ v.co).z for o in bpy.data.objects if o.type == "MESH" and "hueso" in o
          for v in o.data.vertices]
    return max(zs) - min(zs)


def estudio(alto=3.1):
    """Luz, fondo, piso y cámara ortográfica de las revisiones (medidas para un cuerpo de
    `alto` BU; con 3.1, las de la E1)."""
    k = alto / 3.1
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
    bpy.ops.mesh.primitive_plane_add(size=12 * k, location=(0, 0, -globals().get("PISO_BAJO", 0) * k))
    piso = bpy.context.active_object
    piso.data.materials.append(bpy.data.materials.new("Piso"))
    piso.data.materials[0].diffuse_color = (0.3, 0.33, 0.36, 1)
    sol = bpy.data.objects.new("Sol", bpy.data.lights.new("Sol", "SUN"))
    sol.data.energy, sol.data.angle = 3.2, math.radians(8)
    sol.rotation_euler = (math.radians(50), 0, math.radians(-35))
    sc.collection.objects.link(sol)
    cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
    cam.data.type, cam.data.ortho_scale = "ORTHO", 3.7 * k
    cam.data.clip_end = 100 * k
    sc.collection.objects.link(cam)
    sc.camera = cam
    return sc, cam, sol


def encuadre():
    """Centro de la cámara y k, las medidas de la E1 del minotauro (3.1 BU de alto) en proporción:
    al alto, parado en z = 0; con LARGO_JUEGO, a la caja entera (el dragón vuela)."""
    if "LARGO_JUEGO" not in globals():
        alto = alto_bu()
        return V((0, 0, 1.55 * alto / 3.1)), alto / 3.1
    pts = np.array([tuple(o.matrix_world @ v.co) for o in bpy.data.objects
                    if o.type == "MESH" and "hueso" in o for v in o.data.vertices])
    lo, hi = pts.min(axis=0), pts.max(axis=0)
    return V(tuple((lo + hi) / 2)), (hi - lo).max() / 3.1


VISTAS = (("frente", 0, 0), ("perfil", 90, 0), ("tres_cuartos", 35, 0.35), ("atras", 180, 0))
VISTAS += tuple(globals().get("VISTAS_EXTRA", ()))


def renders(carpeta):
    os.makedirs(carpeta, exist_ok=True)
    centro, k = encuadre()
    sc, cam, sol = estudio(k * 3.1)
    vistas(sc, cam, sol, centro, carpeta, "", k)
    materiales_diagnostico([m.name for m in bpy.data.materials if m.name.startswith(PREFIJO)])
    sc.cycles.samples = 8
    vistas(sc, cam, sol, centro, carpeta, "diagnostico_", k)


def vistas(sc, cam, sol, centro, carpeta, prefijo, k=1.0):
    piso = bpy.data.objects.get("Plane")
    for nombre, angulo, alto in VISTAS:
        a = math.radians(angulo)
        cam.location = centro + V((math.sin(a) * 10, -math.cos(a) * 10, alto * 10)) * k
        cam.rotation_euler = (centro - cam.location).to_track_quat("-Z", "Y").to_euler()
        sol.rotation_euler = (math.radians(50), 0, a + math.radians(-35))
        if piso:
            piso.hide_render = alto < 0  # desde abajo, sin piso
        sc.render.filepath = os.path.join(carpeta, f"{prefijo}{nombre}.png")
        bpy.ops.render.render(write_still=True)


# === PRINCIPAL (los otros scripts cargan este archivo hasta aquí) ===
objetos = armar()
datos = estadisticas(objetos)
os.makedirs(os.path.dirname(BLEND), exist_ok=True)
bpy.context.preferences.filepaths.save_version = 0  # sin copia .blend1
bpy.ops.wm.save_as_mainfile(filepath=BLEND)
renders(RENDERS)
with open(os.path.join(RENDERS, "estadisticas.json"), "w", encoding="utf-8") as f:
    json.dump(datos, f, indent=2, ensure_ascii=False)
print("ESTADISTICAS", json.dumps({k: v for k, v in datos.items() if "por_parte" not in k}, ensure_ascii=False))
