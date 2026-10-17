r"""
Rig del Minotauro v2 (bloques), cualquier etapa, y FBX para Roblox (docs/plan_minotauro_v2.md,
pasos 5 y 7):
  1. arma las piezas (minotauro_v2_bloques.py) y las une en una malla; cada pieza va entera
     a su hueso (peso 1, un hueso por vértice);
  2. color plano por paleta: una textura con un cuadro de 64 px por color y todas las UVs de
     cada cara en el centro de su cuadro (las UVs por costuras y el horneado son otro paso);
  3. esqueleto: los 25 huesos del contrato más FaldonFrente/Izq/Der (hijos de Cadera), cada
     uno con la cabeza en su articulación (ARTICULACIONES de minotauro_v2_e<n>_geometria.py),
     la cola en COLAS y roll 0; Raiz y Boca son PUNTOS, sin pesos;
  4. revisa que el esqueleto dé lo mismo que las piezas rígidas en todas las poses de
     minotauro_v2_poses.py (error máximo por vértice) y renderiza los trucos con los huesos;
  5. escala de exportación 5.32 studs por BU aplicada (docs/import_minotauro_v2.md) y FBX con
     las mismas opciones que los otros rigs (bake_space_transform=False, -Z adelante, Y arriba).
No toca los modelos actuales (MinotauroE<n>). rig_dragon_v2.py usa estas funciones con las
poses del dragón (carga el archivo hasta "PRINCIPAL"). Uso (desde la raíz del repo; sin --etapa, la 1):
    blender -b --factory-startup --python tools/blender/rig_minotauro_v2.py -- --etapa 2
Salidas: assets/blender/MinotauroE<n>_v2.fbx, assets/blender/minotauro_v2/e<n>_rig.blend,
assets/textures/MinotauroE<n>_v2_color.png, renders/minotauro_v2_e<n>/rig/ (PNG y rig.json).
"""
import bpy, json, math, os
import numpy as np
from mathutils import Matrix, Vector as V

HERE = os.path.dirname(os.path.abspath(__file__))
if "giros" not in globals():  # rig_dragon_v2.py ya cargó las poses del dragón
    _src = open(os.path.join(HERE, "minotauro_v2_poses.py"), encoding="utf-8").read()
    exec(_src[:_src.index("\narmar()\n")], globals())  # armar(), estudio(), HUESOS, POSES, matrices()
NOMBRE = f"MinotauroE{ETAPA}_v2"
FBX = os.path.join(RAIZ, "assets", "blender", NOMBRE + ".fbx")
BLEND = os.path.join(RAIZ, "assets", "blender", "minotauro_v2", f"e{ETAPA}_rig.blend")
PNG = os.path.join(RAIZ, "assets", "textures", NOMBRE + "_color.png")
REVISION = os.path.join(RAIZ, "renders", f"minotauro_v2_e{ETAPA}", "rig")
ESCALA = 5.3226  # studs por BU (docs/import_minotauro_v2.md)
CUADRO = 64  # px por color en la textura de la paleta
SIN_PESOS = set(PUNTOS)  # COLAS y PUNTOS: de minotauro_v2_e<n>_geometria.py
TRUCOS = ["truco_musculo", "truco_rugido", "truco_rascarse", "truco_baile", "comer", "rodilla_120"]


def colas():
    out = {}
    for n, (x, y, z) in COLAS.items():
        for s, l in ((1, "Izq"), (-1, "Der")) if "{l}" in n else ((1, ""),):
            out[n.format(l=l)] = V((x * s, y, z)) * C
    return out


def unir(piezas):
    """Una malla; cada pieza en el grupo de su hueso con peso 1."""
    for o in piezas:
        o.vertex_groups.new(name=o["hueso"]).add(list(range(len(o.data.vertices))), 1.0, "REPLACE")
    bpy.ops.object.select_all(action="DESELECT")
    for o in piezas:
        o.select_set(True)
    bpy.context.view_layer.objects.active = piezas[0]
    bpy.ops.object.join()
    malla = bpy.context.view_layer.objects.active
    malla.name = malla.data.name = NOMBRE
    return malla


def srgb(c):
    return c * 12.92 if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055


def paleta(malla):
    """Textura con un cuadro por color y las UVs de cada cara en el centro del suyo."""
    nombres = list(COLORES)
    lado = math.ceil(math.sqrt(len(nombres)))  # cuadros por lado (4 x 4 en la E1)
    LADO = lado * CUADRO
    px = np.ones((LADO, LADO, 4), dtype=np.float32)
    centro = {}
    for i, n in enumerate(nombres):
        cx, cy = i % lado, i // lado
        px[cy * CUADRO:(cy + 1) * CUADRO, cx * CUADRO:(cx + 1) * CUADRO, :3] = [srgb(c) for c in COLORES[n]]
        centro[n] = ((cx + 0.5) * CUADRO / LADO, (cy + 0.5) * CUADRO / LADO)
    img = bpy.data.images.new(NOMBRE + "_color", LADO, LADO, alpha=False)
    img.colorspace_settings.name = "sRGB"
    img.pixels[:] = px.ravel()
    os.makedirs(os.path.dirname(PNG), exist_ok=True)
    img.filepath_raw, img.file_format = PNG, "PNG"
    img.save()
    me = malla.data
    uv = me.uv_layers.new(name="UVMap")
    color_de = [m.name.removeprefix(PREFIJO) for m in me.materials]
    for p in me.polygons:
        u = centro[color_de[p.material_index]]
        for li in p.loop_indices:
            uv.data[li].uv = u
    mat = bpy.data.materials.new(NOMBRE + "_Mat")
    mat.use_nodes = True
    nt = mat.node_tree
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"
    bsdf = nt.nodes["Principled BSDF"]
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.65
    me.materials.clear()
    me.materials.append(mat)
    for p in me.polygons:
        p.material_index = 0
    return len(nombres)


def esqueleto():
    datos = bpy.data.armatures.new("Rig" + NOMBRE)
    arm = bpy.data.objects.new("Rig" + NOMBRE, datos)
    bpy.context.scene.collection.objects.link(arm)
    bpy.ops.object.select_all(action="DESELECT")
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    cola = colas()
    huesos = {n: (p or "Raiz", piv, cola[n]) for n, (p, piv) in HUESOS.items()}
    huesos.update({n: (p, V(h) * C, V(t) * C) for n, (p, h, t) in PUNTOS.items()})
    for n, (_, h, t) in huesos.items():
        b = datos.edit_bones.new(n)
        b.head, b.tail, b.roll = h, t, 0
        b.use_deform = n not in SIN_PESOS
    for n, (p, _, _) in huesos.items():
        if p:
            datos.edit_bones[n].parent = datos.edit_bones[p]
    bpy.ops.object.mode_set(mode="OBJECT")
    return arm


def enlazar(malla, arm):
    malla.parent = arm
    mod = malla.modifiers.new("Armature", "ARMATURE")
    mod.object = arm


def posar_huesos(arm, p, faldon=0.0):
    """La misma pose que matrices() de poses.py, puesta en los huesos: el giro del mundo de
    cada hueso pasado a sus ejes de reposo (lo mismo que hace Rig.bind con los ejes)."""
    r = giros(p, faldon)
    for pb in arm.pose.bones:
        if pb.name in r:
            b = pb.bone.matrix_local.to_3x3().to_4x4()
            pb.matrix_basis = b.inverted() @ r[pb.name] @ b
        else:
            pb.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()


def error_maximo(malla, arm, p, faldon, reposo):
    """Distancia máxima (celdas) entre la malla deformada por los huesos y las piezas rígidas."""
    posar_huesos(arm, p, faldon)
    m = matrices(p, faldon)
    dg = bpy.context.evaluated_depsgraph_get()
    ev = malla.evaluated_get(dg).data
    grupo = {g.index: g.name for g in malla.vertex_groups}
    peor = 0.0
    for v, ve in zip(malla.data.vertices, ev.vertices):
        esperado = m[grupo[v.groups[0].group]] @ reposo[v.index]
        peor = max(peor, (ve.co - esperado).length)
    return peor / C


def render(nombre, sc, cam, sol, angulo):
    k = ALTO / 3.1  # las medidas de la E1, en proporción al alto
    centro = V((0, 0, 1.55 * k))
    a = G(angulo)
    cam.location = centro + V((math.sin(a) * 10, -math.cos(a) * 10, 2.5)) * k
    cam.rotation_euler = (centro - cam.location).to_track_quat("-Z", "Y").to_euler()
    sol.rotation_euler = (G(50), 0, a + G(-35))
    sc.render.filepath = os.path.join(REVISION, nombre + ".png")
    bpy.ops.render.render(write_still=True)


def revisar_pesos(malla):
    """Cada vértice con un solo hueso, peso 1, y ninguno en los huesos sin pesos."""
    malos = [v.index for v in malla.data.vertices
             if len(v.groups) != 1 or abs(v.groups[0].weight - 1) > 1e-6]
    en_puntos = [g.name for g in malla.vertex_groups if g.name in SIN_PESOS]
    return {"vertices_con_mas_de_un_hueso": len(malos), "grupos_en_huesos_sin_pesos": en_puntos}


def escalar(malla, arm):
    """Aplica ESCALA a los vértices y al reposo de los huesos (en el FBX ya miden lo del juego)."""
    malla.data.transform(Matrix.Scale(ESCALA, 4))
    bpy.ops.object.select_all(action="DESELECT")
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    for b in arm.data.edit_bones:
        b.head, b.tail = b.head * ESCALA, b.tail * ESCALA
    bpy.ops.object.mode_set(mode="OBJECT")


def exportar(malla, arm):
    bpy.ops.object.select_all(action="DESELECT")
    malla.select_set(True)
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.export_scene.fbx(filepath=FBX, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
                             path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y",
                             bake_space_transform=False, mesh_smooth_type="FACE", add_leaf_bones=False,
                             use_armature_deform_only=False, bake_anim=False, primary_bone_axis="Y",
                             secondary_bone_axis="X", object_types={"ARMATURE", "MESH"})


# === PRINCIPAL (rig_dragon_v2.py carga este archivo hasta aquí) ===
piezas = [o for o in armar() if o.type == "MESH"]
ALTO = alto_bu()
faldon = {n: faldon_minimo(pose) or 0 for n, (pose, _) in POSES.items()}  # con las piezas sueltas
posar({})
malla = unir(piezas)
colores = paleta(malla)
arm = esqueleto()
enlazar(malla, arm)
reposo = [v.co.copy() for v in malla.data.vertices]
errores = {n: round(error_maximo(malla, arm, pose, faldon[n], reposo), 6) for n, (pose, _) in POSES.items()}
os.makedirs(REVISION, exist_ok=True)
sc, cam, sol = estudio(ALTO)
sc.cycles.samples = 24
for nombre in ["reposo"] + TRUCOS:
    pose, angulo = POSES.get(nombre, ({}, 35))
    posar_huesos(arm, pose, faldon.get(nombre, 0))
    render(nombre, sc, cam, sol, angulo)
posar_huesos(arm, {})
datos = {
    "triangulos": sum(len(p.vertices) - 2 for p in malla.data.polygons),
    "huesos": len(arm.data.bones),
    "huesos_que_deforman": sum(b.use_deform for b in arm.data.bones),
    "colores_en_la_paleta": colores,
    "pesos": revisar_pesos(malla),
    "error_maximo_celdas_por_pose": errores,
    "escala_studs_por_bu": ESCALA,
}
escalar(malla, arm)
zs = [(malla.matrix_world @ v.co).z for v in malla.data.vertices]
datos["alto_studs"] = round(max(zs) - min(zs), 3)
os.makedirs(os.path.dirname(BLEND), exist_ok=True)
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=BLEND)
exportar(malla, arm)
with open(os.path.join(REVISION, "rig.json"), "w", encoding="utf-8") as fh:
    json.dump(datos, fh, indent=2, ensure_ascii=False)
print("RIG", json.dumps(datos, ensure_ascii=False))
