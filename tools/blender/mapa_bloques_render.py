"""Render de revisión del mapa entero en bloques (todavía sin incorporar al juego): la isla
(isla_bloques.py) y el volcán (volcan_bloques.py y sus capas), las piezas de primitivas de
world/Isla.model.json y los props de bloques (props_bloques.py, más el arco y el faro de
Blender) puestos como los pone server/World/PropDresser (Ajuste caja / alto / ancho).
Oculta el aro de color de los estanques (BrilloOrilla), que reemplaza el aro de piedras.

Uso (desde la raíz del repo):
  blender -b --factory-startup --python tools/blender/mapa_bloques_render.py --       <raiz_repo> <isla.blend> <volcan.blend> <carpeta_salida> [z_del_crater]
  z_del_crater: el volcán separado de la isla va en 722 (hoy craterCenter es 520); las piezas
  del cráter se corren con él, el arco (PuertaDelAbismo) y el puente se quedan.
  Con la variable VISTAS=<json de mapa_bloques_vistas.py> saca esas cámaras (las mismas de
  docs/capturas/mapa_antes_despues); sin ella, un juego de vistas de revisión.
Ejes: Blender (x, y, z) = Roblox (x, -z, y). El volcán viene con el origen en craterCenter."""
import bpy, bmesh, json, math, os, sys
from mathutils import Vector as V, Matrix

ARGS = sys.argv[sys.argv.index("--") + 1:]
RAIZ, ISLA, VOLCAN, SALIDA = ARGS[:4]
LAYOUT = json.load(open(os.path.join(RAIZ, "src", "shared", "WorldLayoutData.json"), encoding="utf-8"))
CX, CZ = LAYOUT["craterCenter"]
# Opcional: un 5.º argumento con la nueva z del centro del cráter (el volcán se separa de la isla).
# Las piezas del cráter se corren con él; el arco (PuertaDelAbismo) y el puente quedan.
DZ = 0.0
if len(ARGS) > 4:
    DZ = float(ARGS[4]) - CZ
    CZ = float(ARGS[4])
P = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))  # Roblox -> Blender


def a_blender(cframe):
    """CFrame de Rojo [x, y, z, r00..r22] -> matriz 4x4 de Blender (sin escala)."""
    x, y, z = cframe[:3]
    r = cframe[3:]
    R = Matrix(((r[0], r[1], r[2]), (r[3], r[4], r[5]), (r[6], r[7], r[8])))
    rot = P @ R @ P.transposed()
    m = rot.to_4x4()
    m.translation = P @ V((x, y, z))
    return m


def limpiar():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)


def traer_blend(blend, desplazar, excluir=("agua", "puente", "referencia", "piso", "water", "camara", "sol")):
    with bpy.data.libraries.load(blend) as (origen, destino):
        destino.objects = list(origen.objects)
    salida = []
    for o in destino.objects:
        if o is None or o.type != "MESH":
            continue
        enRef = any(c.name.lower().startswith("referencia") for c in o.users_collection)
        if enRef or any(p in o.name.lower() for p in excluir):
            continue
        bpy.context.scene.collection.objects.link(o)
        o.location += desplazar
        salida.append(o)
    return salida


# --- Plantillas: props de bloques, arco y faro (con la base y el centro de su caja) ------------
def plantillas():
    tpl = {}
    props = os.path.join(RAIZ, "assets", "blender", "props_v2", "props_bloques.blend")
    with bpy.data.libraries.load(props) as (origen, destino):
        destino.objects = [n for n in origen.objects if n[:-1] in ("Palmera", "Arbusto", "Roca", "Cresta")]
    for o in destino.objects:
        if o:
            tpl[o.name] = o.data
    for fbx, nombres in (("ArcoVolcan.fbx", ("ArcoVolcan", "ArcoVolcanLava")), ("Faro.fbx", ("Faro",))):
        ruta = os.path.join(RAIZ, "assets", "blender", fbx)
        if not os.path.exists(ruta):
            continue
        antes = set(bpy.data.objects)
        bpy.ops.import_scene.fbx(filepath=ruta)
        for o in [o for o in bpy.data.objects if o not in antes]:
            if o.type == "MESH" and o.name.split(".")[0] in nombres:
                malla = o.data.copy()
                malla.transform(o.matrix_world)
                tpl[o.name.split(".")[0]] = malla
            bpy.data.objects.remove(o)
    cajas = {}
    for nombre, malla in tpl.items():
        xs = [v.co for v in malla.vertices]
        mn = V((min(c.x for c in xs), min(c.y for c in xs), min(c.z for c in xs)))
        mx = V((max(c.x for c in xs), max(c.y for c in xs), max(c.z for c in xs)))
        cajas[nombre] = (mn, mx)
    return tpl, cajas


def poner_prop(nombre, props, tpl, cajas):
    malla = tpl.get(nombre)
    if not malla:
        return
    mn, mx = cajas[nombre]
    dims = mx - mn
    sx, sy, sz = props["Size"]  # Roblox: X ancho, Y alto, Z fondo
    base = a_blender(props["CFrame"])
    ajuste = props.get("_ajuste", "alto")
    if ajuste == "caja":
        escala = Matrix.Diagonal((sx / dims.x, sz / dims.y, sy / dims.z, 1))
        m = base @ escala @ Matrix.Translation(-(mn + mx) / 2)
    else:
        k = sy / dims.z if ajuste != "ancho" else sx / dims.x
        pie = base @ Matrix.Translation(V((0, 0, -sy / 2)))
        m = pie @ Matrix.Diagonal((k, k, k, 1)) @ Matrix.Translation(-V(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z)))
    o = bpy.data.objects.new(nombre, malla)
    o.matrix_world = m
    bpy.context.scene.collection.objects.link(o)


# --- Piezas de primitivas -----------------------------------------------------------------------
FORMAS = {}


def forma(tipo):
    if tipo in FORMAS:
        return FORMAS[tipo]
    bm = bmesh.new()
    if tipo == "Ball":
        bmesh.ops.create_uvsphere(bm, u_segments=12, v_segments=8, radius=0.5)
    elif tipo == "Cylinder":  # en Roblox el eje del cilindro es X
        bmesh.ops.create_cone(bm, cap_ends=True, segments=12, radius1=0.5, radius2=0.5, depth=1.0)
        bmesh.ops.rotate(bm, verts=bm.verts, matrix=Matrix.Rotation(math.radians(90), 3, "Y"))
    else:
        bmesh.ops.create_cube(bm, size=1.0)
    malla = bpy.data.meshes.new(tipo)
    bm.to_mesh(malla)
    bm.free()
    FORMAS[tipo] = malla
    return malla


MATS = {}


def material(color, neon):
    clave = (round(color[0], 2), round(color[1], 2), round(color[2], 2), neon)
    if clave not in MATS:
        m = bpy.data.materials.new("M")
        m.use_nodes = True
        b = m.node_tree.nodes["Principled BSDF"]
        b.inputs["Base Color"].default_value = (*[c ** 2.2 for c in color], 1)
        if neon:
            b.inputs["Emission Color"].default_value = (*[c ** 2.2 for c in color], 1)
            b.inputs["Emission Strength"].default_value = 3.0
        MATS[clave] = m
    return MATS[clave]


def poner_pieza(nodo, props):
    """Una pieza de primitivas: la malla de su forma (compartida) con el color en el objeto."""
    sx, sy, sz = props["Size"]
    malla = forma(props.get("Shape", "Block"))
    if not malla.materials:
        malla.materials.append(None)  # un hueco: cada objeto pone el suyo
    o = bpy.data.objects.new(nodo.get("name", "Pieza"), malla)
    o.matrix_world = a_blender(props["CFrame"]) @ Matrix.Diagonal((sx, sz, sy, 1))
    bpy.context.scene.collection.objects.link(o)
    o.material_slots[0].link = "OBJECT"
    o.material_slots[0].material = material(props.get("Color", [0.6, 0.6, 0.6]), props.get("Material") == "Neon")


# Piezas del mapa que reemplaza la isla de bloques (el aro de color de cada estanque).
OCULTAR = {"BrilloOrilla"}


def correr(props, dz):
    if not dz or "CFrame" not in props:
        return props
    cf = list(props["CFrame"])
    cf[2] += dz
    return dict(props, CFrame=cf)


def mapa(tpl, cajas):
    def visitar(nodo, corrido=0.0):
        hijos = nodo.get("children", [])
        quitar = set()
        for h in hijos:  # las anclas borran a sus hermanos de primitivas (Reemplaza)
            a = h.get("attributes") or {}
            if "Reemplaza" in a and a["Reemplaza"]:
                prefijos = a["Reemplaza"].split(",")
                for otro in hijos:
                    if otro is not h and any(otro.get("name", "").startswith(p) for p in prefijos if p):
                        quitar.add(id(otro))
        for h in hijos:
            if id(h) in quitar or h.get("name") in OCULTAR:
                continue
            a = h.get("attributes") or {}
            p = h.get("properties") or {}
            if "Prop" in a and "Size" in p:
                p = dict(p, _ajuste=a.get("Ajuste", "alto"))
                if a["Prop"] in tpl:
                    poner_prop(a["Prop"], correr(p, corrido), tpl, cajas)
                    continue
            if "Size" in p and "CFrame" in p and p.get("Transparency", 0) < 1:
                poner_pieza(h, correr(p, corrido))
            mio = corrido
            if h.get("name") == "Crater" and "name" not in nodo:  # la raíz del modelo no tiene nombre
                mio = DZ
            if h.get("name") == "PuertaDelAbismo":
                mio = 0.0
            visitar(h, mio)
    visitar(json.load(open(os.path.join(RAIZ, "world", "Isla.model.json"), encoding="utf-8")))


# --- Escena y renders ---------------------------------------------------------------------------
def escena():
    sc = bpy.context.scene
    motores = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    sc.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in motores else "BLENDER_EEVEE"
    sc.render.resolution_x, sc.render.resolution_y = 1920, 1080
    sc.view_settings.view_transform = "Standard"
    mundo = bpy.data.worlds.new("Cielo")
    mundo.use_nodes = True
    mundo.node_tree.nodes["Background"].inputs[0].default_value = (0.45, 0.66, 0.9, 1)
    sc.world = mundo
    bpy.ops.mesh.primitive_plane_add(size=3200, location=(0, -CZ / 2, LAYOUT["waterLevel"]))
    agua = bpy.context.active_object
    m = bpy.data.materials.new("Agua")
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (0.03, 0.3, 0.55, 1)
    b.inputs["Alpha"].default_value = 0.72
    b.inputs["Roughness"].default_value = 0.12
    agua.data.materials.append(m)
    # Agua de los estanques (en el juego es agua de terreno a trainingPondWaterTop).
    quitados = set(LAYOUT.get("removedPonds", []))
    estanques = [(p, LAYOUT["trainingPondRadius"]) for i, p in enumerate(LAYOUT["pondPositions"], 1) if i not in quitados]
    estanques.append(((0, 0), LAYOUT["sacredPondRadius"]))
    if any(o.name.startswith("Lamina_") for o in bpy.data.objects):
        estanques = []  # la isla trae su agua de color por estanque
    m2 = m.copy()
    m2.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.05, 0.42, 0.62, 1)
    for (x, z), radio in estanques:
        bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=radio + 1, depth=0.2,
                                            location=(x, -z, LAYOUT["trainingPondWaterTop"] - 0.1))
        bpy.context.active_object.data.materials.append(m2)
    sol =bpy.data.objects.new("Sol", bpy.data.lights.new("Sol", "SUN"))
    sol.data.energy, sol.data.color = 4.0, (1.0, 0.95, 0.86)
    sol.rotation_euler = (math.radians(48), 0, math.radians(30))
    sc.collection.objects.link(sol)
    cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
    cam.data.clip_end = 6000
    sc.collection.objects.link(cam)
    sc.camera = cam
    return sc, cam


def main():
    limpiar()
    traer_blend(ISLA, V((0, 0, 0)))
    traer_blend(VOLCAN, V((CX, -CZ, 0)))
    tpl, cajas = plantillas()
    mapa(tpl, cajas)
    sc, cam = escena()
    os.makedirs(SALIDA, exist_ok=True)
    vistas_json = os.environ.get("VISTAS")
    if vistas_json:
        # Las mismas cámaras que las fotos de Studio: Roblox (x, y, z) -> Blender (x, -z, y),
        # campo vertical de 70° y la proporción de la ventana de Studio.
        sc.render.resolution_x, sc.render.resolution_y = 1754, 952
        cam.data.sensor_fit = "VERTICAL"
        cam.data.angle_y = math.radians(70)
        for v in json.load(open(vistas_json, encoding="utf-8")):
            px, py, pz = v["pos"]
            mx, my, mz = v["mira"]
            pos, mira = V((px, -pz, py)), V((mx, -mz, my))
            cam.location = pos
            cam.rotation_euler = (mira - pos).to_track_quat("-Z", "Y").to_euler()
            sc.render.filepath = os.path.join(SALIDA, v["nombre"] + ".png")
            bpy.ops.render.render(write_still=True)
        return
    volcan = V((CX, -CZ, 30))
    vistas = (
        ("mapa_aerea.png", V((-560, 360, 430)), V((CX * 0.5, -CZ * 0.45, 0)), 28),
        ("mapa_plaza_al_volcan.png", V((0, 120, 12)), volcan, 24),
        ("mapa_playa.png", V((150, 210, 8)), V((0, 0, 8)), 24),
        ("mapa_cenital.png", V((CX * 0.5, -CZ * 0.5, 1700)), V((CX * 0.5, -CZ * 0.5, 0)), 32),
        # La plaza y los estanques (Roblox (x, z) -> Blender (x, -z)).
        ("plaza_desde_la_aparicion.png", V((0, 165, 48)), V((0, 0, 4)), 24),
        ("plaza_desde_arriba.png", V((120, 120, 150)), V((0, 0, 0)), 26),
        ("camino_elevado.png", V((104, 3, 10)), V((0, 0, 7)), 26),
        ("estanque_de_cerca.png", V((56, -50, 11)), V((31, -76, 5)), 28),
        ("estanque_sagrado.png", V((34, 30, 12)), V((0, 0, 5)), 26),
    )
    for nombre, pos, mira, lente in vistas:
        cam.location, cam.data.lens = pos, lente
        cam.rotation_euler = (mira - pos).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(SALIDA, nombre)
        bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SALIDA, "mapa_completo.blend"))


main()
