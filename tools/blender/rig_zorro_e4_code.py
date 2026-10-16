r"""
Del zorro de agua E4 detallado (zorro_e4_code.py + zorro_e4_pintura.py) al modelo de Roblox:
  1. arma y pinta el modelo detallado;
  2. copia liviana de cada pieza (≤ 19,500 triángulos en total: el tope de Roblox es 20k);
  3. UVs nuevas y texturas de 1024 horneadas del detallado: color (con las marcas que
     brillan sumadas), normales, rugosidad y metal;
  4. esqueleto de 65 huesos:
        Raiz > Cadera > Columna > Pecho > Cuello1 > Cuello2 > Cabeza > Mandibula, Boca (punto),
               OrejaIzq, OrejaDer
        Pecho > Hombro > Brazo > Antebrazo > Mano          (Izq/Der, patas delanteras)
        Cadera > Muslo > Pierna > Tobillo > Pie            (Izq/Der, patas traseras)
        Cadera > Cola<n>_1 > _2 > _3 > _4                  (n = 1..9, de izquierda a derecha)
  5. pesos: el cuerpo por calor (sin los huesos de las colas, para que no se le peguen);
     cada cola solo a sus 4 huesos, mezclados a lo largo de la cola; las piezas rígidas
     (ojos, gema, oro, orejas) enteras a su hueso; 4 influencias por vértice;
  6. FBX con texturas embebidas y PNG.
Izq = izquierda del zorro (+x en Blender). Mira a -Y, parado en z = 0.

Uso: blender -b --factory-startup --python rig_zorro_e4_code.py -- <salida.fbx> <carpeta de texturas> [vista.png]
"""
import bpy, sys, os, math
import numpy as np
from mathutils import Vector as V

args = sys.argv[sys.argv.index("--") + 1:]
OUT, TEXDIR = args[0], args[1]
VISTA = args[2] if len(args) > 2 else None
NAME = "ZorroDeAguaE4"
HERE = os.path.dirname(os.path.abspath(__file__))
g = globals()
for f in ("criaturas.py", "zorro_e4_code.py", "zorro_e4_pintura.py"):
    src = open(os.path.join(HERE, f), encoding="utf-8").read()
    if "__main__" in src:
        src = src[:src.index('if __name__ == "__main__":')]
    exec(src, g)

bpy.ops.preferences.addon_enable(module="cycles")
limpiar_escena()
altos, partes = construir_zorro_e4()
pintar_zorro_e4(altos)
for o in altos:
    o["hueso"] = partes.get(o, "")

TOPE = {"Cuerpo": 8200, "Cola": 880, "Oreja": 520, "OrejaPelo": 90, "Ojo": 160, "Nariz": 80, "Gema": 80,
        "Aro": 64, "Medallon": 96, "MedallonBorde": 160, "GemaMedallon": 80}


def tris(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)


def tope(nombre):
    claves = sorted(TOPE, key=len, reverse=True)  # la clave más específica primero
    return next((TOPE[k] for k in claves if nombre.startswith(k)), 120)


# --- 2. Copias livianas -------------------------------------------------------------------
bajos = []
for o in altos:
    c = o.copy()
    c.data = o.data.copy()
    c.name = o.name + "_bajo"
    bpy.context.collection.objects.link(c)
    bpy.ops.object.select_all(action="DESELECT")
    c.select_set(True)
    bpy.context.view_layer.objects.active = c
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    t, meta = tris(c), tope(o.name)
    if t > meta:
        d = c.modifiers.new("Reducir", "DECIMATE")
        d.ratio = meta / t
        bpy.ops.object.modifier_apply(modifier=d.name)
    c["hueso"] = o["hueso"]
    c["origen"] = o.name
    bajos.append(c)
print("TRIS_BAJO", sum(tris(c) for c in bajos))

# --- 4. Esqueleto (antes de unir: las colas se pesan pieza por pieza) ------------------------
Pt = PUNTOS


def lado(p, s):
    return V((p.x * s, p.y, p.z))


B = {
    "Raiz": (V((0, 0.05, 0.0)), V((0, 0.05, 0.3)), None),
    "Cadera": (Pt["cadera"], Pt["lomo"], "Raiz"),
    "Columna": (Pt["lomo"], Pt["pecho"], "Cadera"),
    "Pecho": (Pt["pecho"], Pt["cuello"], "Columna"),
    "Cuello1": (Pt["cuello"], Pt["cuello2"], "Pecho"),
    "Cuello2": (Pt["cuello2"], Pt["cabeza"], "Cuello1"),
    "Cabeza": (Pt["cabeza"], Pt["coronilla"], "Cuello2"),
    "Mandibula": (Pt["bisagra"], Pt["menton"], "Cabeza"),
    "Boca": (Pt["boca"], Pt["boca"] + V((0, -0.06, 0)), "Cabeza"),
}
for s, n in ((1, "Izq"), (-1, "Der")):
    B["Oreja" + n] = (lado(Pt["oreja"], s), lado(Pt["oreja_punta"], s), "Cabeza")
    B["Hombro" + n] = (lado(V((0.17, -0.38, 1.36)), s), lado(Pt["hombro"], s), "Pecho")
    B["Brazo" + n] = (lado(Pt["hombro"], s), lado(Pt["codo"], s), "Hombro" + n)
    B["Antebrazo" + n] = (lado(Pt["codo"], s), lado(Pt["muneca"], s), "Brazo" + n)
    B["Mano" + n] = (lado(Pt["muneca"], s), lado(Pt["mano"], s), "Antebrazo" + n)
    B["Muslo" + n] = (lado(Pt["muslo"], s), lado(Pt["rodilla"], s), "Cadera")
    B["Pierna" + n] = (lado(Pt["rodilla"], s), lado(Pt["tobillo"], s), "Muslo" + n)
    B["Tobillo" + n] = (lado(Pt["tobillo"], s), lado(Pt["pie"], s), "Pierna" + n)
    B["Pie" + n] = (lado(Pt["pie"], s), lado(Pt["punta_pie"], s), "Tobillo" + n)
CORTES = (0, 4, 8, 12, 15)  # puntos de la cola donde empieza cada hueso
for i, pts in enumerate(PUNTOS_COLA):
    for k in range(4):
        a, b = V(pts[CORTES[k]][:3]), V(pts[CORTES[k + 1]][:3])
        B[f"Cola{i + 1}_{k + 1}"] = (a, b, "Cadera" if k == 0 else f"Cola{i + 1}_{k}")
NODEFORM = {"Raiz", "Boca"}
COLAS = {n for n in B if n.startswith("Cola")}

arm_data = bpy.data.armatures.new("Rig" + NAME)
arm = bpy.data.objects.new("Rig" + NAME, arm_data)
bpy.context.scene.collection.objects.link(arm)
bpy.ops.object.select_all(action="DESELECT")
arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="EDIT")
for n, (h, t, par) in B.items():
    b = arm_data.edit_bones.new(n)
    b.head, b.tail = h, t
    b.align_roll(V((0, 0, 1)) if abs((t - h).normalized().z) < 0.9 else V((0, -1, 0)))
    b.use_deform = n not in NODEFORM
for n, (h, t, par) in B.items():
    if par:
        arm_data.edit_bones[n].parent = arm_data.edit_bones[par]
bpy.ops.object.mode_set(mode="OBJECT")


def seg(p, a, b):
    ab = b - a
    t = max(0, min(1, (p - a).dot(ab) / max(ab.length_squared, 1e-9)))
    return (p - (a + ab * t)).length, t


def suave01(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


# Colas: cada vértice entre los 2 huesos más cercanos de SU cola, mezclados a lo largo.
for c in bajos:
    if not c["origen"].startswith("Cola"):
        continue
    i = int("".join(ch for ch in c["origen"] if ch.isdigit()))
    nombres = [f"Cola{i}_{k}" for k in range(1, 5)]
    grupos = {nm: c.vertex_groups.new(name=nm) for nm in nombres}
    base = c.vertex_groups.new(name="Cadera")
    for v in c.data.vertices:
        mejor = min(range(4), key=lambda k: seg(v.co, B[nombres[k]][0], B[nombres[k]][1])[0])
        _, t = seg(v.co, B[nombres[mejor]][0], B[nombres[mejor]][1])
        w = {mejor: 1.0}
        if t < 0.35 and mejor > 0:  # mezcla con el anterior cerca de la articulación
            f = suave01(0.5 + t / 0.7)
            w = {mejor: f, mejor - 1: 1 - f}
        elif t > 0.65 and mejor < 3:
            f = suave01(0.5 + (1 - t) / 0.7)
            w = {mejor: f, mejor + 1: 1 - f}
        if mejor == 0 and t < 0.25:  # la raíz de la cola se funde con la cadera
            f = suave01(t / 0.25)
            w = {0: f, -1: 1 - f}
        for k, val in w.items():
            (base if k == -1 else grupos[nombres[k]]).add([v.index], val, "REPLACE")
    c.vertex_groups.active_index = 0

# Piezas rígidas: enteras a su hueso.
for c in bajos:
    if c["hueso"]:
        gr = c.vertex_groups.new(name=c["hueso"])
        gr.add(list(range(len(c.data.vertices))), 1.0, "REPLACE")

# Cuerpo: por calor, sin los huesos de las colas.
cuerpo_bajo = next(c for c in bajos if c["origen"] == "Cuerpo")
for n in COLAS:
    arm_data.bones[n].use_deform = False
bpy.ops.object.select_all(action="DESELECT")
cuerpo_bajo.select_set(True)
arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.parent_set(type="ARMATURE_AUTO")
for n in COLAS:
    arm_data.bones[n].use_deform = True
deform = [n for n in B if n not in NODEFORM and n not in COLAS]
gi = {gr.index: gr.name for gr in cuerpo_bajo.vertex_groups}
vacios = 0
for v in cuerpo_bajo.data.vertices:
    if sum(x.weight for x in v.groups if gi.get(x.group) in deform) < 1e-3:
        n = min(deform, key=lambda k: seg(v.co, B[k][0], B[k][1])[0])
        cuerpo_bajo.vertex_groups[n].add([v.index], 1.0, "REPLACE")
        vacios += 1
print("SIN_CALOR", vacios)

# Unir todo en una malla.
bpy.ops.object.select_all(action="DESELECT")
for c in bajos:
    c.select_set(True)
    for m in list(c.modifiers):
        c.modifiers.remove(m)
bpy.context.view_layer.objects.active = cuerpo_bajo
bpy.ops.object.join()
bajo = bpy.context.view_layer.objects.active
bajo.name = bajo.data.name = NAME
bajo.parent = None
for a in list(bajo.data.color_attributes):
    bajo.data.color_attributes.remove(a)
bpy.ops.object.vertex_group_limit_total(group_select_mode="ALL", limit=4)
bpy.ops.object.vertex_group_normalize_all(group_select_mode="ALL", lock_active=False)
print("TRIS", tris(bajo))

# --- 3. UVs y horneado ----------------------------------------------------------------------
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.uv.smart_project(angle_limit=math.radians(62), island_margin=0.003, area_weight=0.6)
bpy.ops.uv.pack_islands(margin=0.003, rotate=True)
bpy.ops.object.mode_set(mode="OBJECT")


def imagen(n, color=True):
    img = bpy.data.images.new(n, 1024, 1024, alpha=False)
    img.colorspace_settings.name = "sRGB" if color else "Non-Color"
    return img


imgs = {k: imagen(f"{NAME}_{k}", k == "color") for k in ("color", "brillo", "normal", "roughness", "metalness")}
mat = bpy.data.materials.new(NAME + "_Mat")
mat.use_nodes = True
nt = mat.node_tree
bsdf = nt.nodes["Principled BSDF"]
nodos = {}
for k, img in imgs.items():
    tn = nt.nodes.new("ShaderNodeTexImage")
    tn.image = img
    nodos[k] = tn
nm = nt.nodes.new("ShaderNodeNormalMap")
nt.links.new(nodos["color"].outputs["Color"], bsdf.inputs["Base Color"])
nt.links.new(nodos["normal"].outputs["Color"], nm.inputs["Color"])
nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
nt.links.new(nodos["roughness"].outputs["Color"], bsdf.inputs["Roughness"])
nt.links.new(nodos["metalness"].outputs["Color"], bsdf.inputs["Metallic"])
bajo.data.materials.clear()
bajo.data.materials.append(mat)

scn = bpy.context.scene
scn.render.engine = "CYCLES"
scn.cycles.device = "CPU"
scn.cycles.samples = 4
bk = scn.render.bake
bk.use_selected_to_active = True
bk.cage_extrusion = 0.02
bk.max_ray_distance = 0.08
bk.margin = 6


def hornear(tipo, clave):
    nt.nodes.active = nodos[clave]
    bpy.ops.object.select_all(action="DESELECT")
    for o in altos:
        o.select_set(True)
    bajo.select_set(True)
    bpy.context.view_layer.objects.active = bajo
    if tipo == "DIFFUSE":
        bk.use_pass_direct = bk.use_pass_indirect = False
        bk.use_pass_color = True
    bpy.ops.object.bake(type=tipo)


metal = {}
for m in bpy.data.materials:  # el color de un metal sale negro en el horneado: sin metal
    for nd in (m.node_tree.nodes if m.node_tree else []):
        if nd.type == "BSDF_PRINCIPLED" and m is not mat:
            metal[m.name] = nd.inputs["Metallic"].default_value
            nd.inputs["Metallic"].default_value = 0.0
hornear("DIFFUSE", "color")
hornear("EMIT", "brillo")
hornear("NORMAL", "normal")
hornear("ROUGHNESS", "roughness")
# Metal: emisión blanca en lo que era metal, negra en lo demás, y se hornea la emisión.
guardado = {}
for m in bpy.data.materials:
    if m is mat or not m.node_tree:
        continue
    for nd in m.node_tree.nodes:
        if nd.type == "BSDF_PRINCIPLED":
            guardado[m.name] = (tuple(nd.inputs["Emission Color"].default_value),
                                nd.inputs["Emission Strength"].default_value,
                                [l for l in m.node_tree.links if l.to_socket == nd.inputs["Emission Color"]])
            for l in list(m.node_tree.links):
                if l.to_socket == nd.inputs["Emission Color"]:
                    m.node_tree.links.remove(l)
            v = 1.0 if metal.get(m.name, 0) > 0.5 else 0.0
            nd.inputs["Emission Color"].default_value = (v, v, v, 1)
            nd.inputs["Emission Strength"].default_value = 1.0
hornear("EMIT", "metalness")

# Color final = color + brillo (las marcas cian se ven encendidas en Roblox) y un poco más vivo.
px = np.array(imgs["color"].pixels[:], dtype=np.float32).reshape(-1, 4)
br = np.array(imgs["brillo"].pixels[:], dtype=np.float32).reshape(-1, 4)
rgb = px[:, :3] * 1.02 + br[:, :3] * 0.9
gris = rgb.mean(axis=1, keepdims=True)
rgb = gris + (rgb - gris) * 1.25  # más vivo: en Roblox la luz del cráter lo apaga
px[:, :3] = np.clip(rgb, 0, 1)
imgs["color"].pixels[:] = px.ravel()
imgs["color"].update()
os.makedirs(TEXDIR, exist_ok=True)
for k in ("color", "normal", "roughness", "metalness"):
    img = imgs[k]
    img.filepath_raw = os.path.join(TEXDIR, f"{NAME}_code_{k}.png")
    img.file_format = "PNG"
    img.save()
for o in altos:
    bpy.data.objects.remove(o)
nt.nodes.remove(nodos["brillo"])

# --- 5. Unir al esqueleto y exportar ---------------------------------------------------------
bpy.ops.object.select_all(action="DESELECT")
bajo.select_set(True)
arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.parent_set(type="ARMATURE_NAME")  # usa los grupos ya pesados
for m in list(bajo.modifiers)[:-1]:
    bajo.modifiers.remove(m)
bpy.ops.wm.save_as_mainfile(filepath=OUT.replace(".fbx", "_rig.blend"))
bpy.ops.object.select_all(action="DESELECT")
bajo.select_set(True)
arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.fbx(filepath=OUT, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
    path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y", bake_space_transform=False,
    mesh_smooth_type="FACE", add_leaf_bones=False, use_armature_deform_only=False, bake_anim=False,
    primary_bone_axis="Y", secondary_bone_axis="X", object_types={"ARMATURE", "MESH"})
print("FBX", OUT)
if VISTA:
    estudio(3.0, distancia=8, angulo=35, fondo=(0.55, 0.62, 0.7))
    scn.view_settings.exposure = -0.6  # la misma que los renders del detallado: se comparan
    scn.cycles.samples = 32
    renderizar(VISTA, 800, 800, muestras=32, motor="CYCLES")
