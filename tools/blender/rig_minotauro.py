"""
Del modelo detallado (alto.blend, de minotauro_e1.py) al MinotauroE1 para Roblox:
  1. copia reducida de cada pieza (el cuerpo a ~11k triángulos, las piezas chicas
     casi enteras) y todo junto en una malla;
  2. UVs nuevas y color + normales horneados a 1024 desde el modelo detallado;
  3. esqueleto (PUNTOS de minotauro_e1.py): Raiz > Cadera > Columna > Pecho > Cuello >
     Cabeza > Mandibula, Boca (punto), OrejaIzq/Der; Pecho > Brazo/Antebrazo/Mano;
     Cadera > Muslo/Pierna/Pie; Cadera > Cola1..3;
  4. pesos: el cuerpo por calor (suaves); cada pieza (ojos, cuernos, aros, faldón...)
     entera a su hueso; máximo 4 huesos por vértice;
  5. FBX con texturas embebidas y PNG en assets.
Uso: python3 -I rig_minotauro.py -- alto.blend <salida.fbx> <carpeta de texturas>
"""
import bpy, bmesh, sys, os, math
from mathutils import Vector as V

SRC, OUT, TEXDIR = sys.argv[-3], sys.argv[-2], sys.argv[-1]
HERE = os.path.dirname(os.path.abspath(__file__))
g = globals()
exec(open(os.path.join(HERE, "criaturas.py"), encoding="utf-8").read(), g)
exec(open(os.path.join(HERE, "minotauro_e1.py"), encoding="utf-8").read(), g)
bpy.ops.wm.open_mainfile(filepath=SRC)
import json
NAME = bpy.context.scene.get("nombre", "MinotauroE1")
if "puntos" in bpy.context.scene:  # etapas 2-4: articulaciones deformadas (minotauro_etapas.py)
    PUNTOS = {k: V(v) for k, v in json.loads(bpy.context.scene["puntos"]).items()}
bpy.ops.preferences.addon_enable(module="cycles")
altos = [o for o in bpy.data.objects if o.type == "MESH"]
CUERPO_TRIS = 9000
TOPE = {"Ojo": 700, "Mechon": 900, "Cuerno": 450, "Anillo": 220, "Aro": 220, "Brazalete": 260,
        "Borla": 320, "Mandibula": 500, "Pezuna": 380, "Remache": 48, "Cinturon": 360}

def tris(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)

# 1. Copias reducidas.
bajos = []
for o in altos:
    c = o.copy(); c.data = o.data.copy(); c.name = o.name + "_bajo"
    bpy.context.collection.objects.link(c)
    t = tris(c)
    tope = next((v for k, v in TOPE.items() if o.name.startswith(k)), 700)
    meta = CUERPO_TRIS if o["hueso"] == "" else min(t, tope)
    if t > meta:
        d = c.modifiers.new("Reducir", "DECIMATE"); d.ratio = meta / t
        bpy.ops.object.select_all(action="DESELECT"); c.select_set(True); bpy.context.view_layer.objects.active = c
        bpy.ops.object.modifier_apply(modifier=d.name)
    if o["hueso"]:
        vg = c.vertex_groups.new(name="R_" + o["hueso"])
        vg.add(list(range(len(c.data.vertices))), 1.0, "REPLACE")
    bajos.append(c)
bpy.ops.object.select_all(action="DESELECT")
for c in bajos: c.select_set(True)
bpy.context.view_layer.objects.active = bajos[0]
bpy.ops.object.join()
bajo = bpy.context.view_layer.objects.active
bajo.name = bajo.data.name = NAME
for a in list(bajo.data.color_attributes): bajo.data.color_attributes.remove(a)
print("TRIS", tris(bajo))

# 2. UVs y horneado.
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.003, area_weight=0.6)
bpy.ops.uv.pack_islands(margin=0.003, rotate=True)
bpy.ops.object.mode_set(mode="OBJECT")
def imagen(n, color=True):
    img = bpy.data.images.new(n, 1024, 1024, alpha=False)
    img.colorspace_settings.name = "sRGB" if color else "Non-Color"
    return img
img_c, img_n = imagen(NAME + "_color"), imagen(NAME + "_normal", False)
mat = bpy.data.materials.new(NAME + "_Mat"); mat.use_nodes = True
nt = mat.node_tree; bsdf = nt.nodes["Principled BSDF"]
tc = nt.nodes.new("ShaderNodeTexImage"); tc.image = img_c
tn = nt.nodes.new("ShaderNodeTexImage"); tn.image = img_n
nm = nt.nodes.new("ShaderNodeNormalMap")
nt.links.new(tc.outputs["Color"], bsdf.inputs["Base Color"])
nt.links.new(tn.outputs["Color"], nm.inputs["Color"]); nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
bsdf.inputs["Roughness"].default_value = 0.7
bajo.data.materials.clear(); bajo.data.materials.append(mat)
scn = bpy.context.scene
scn.render.engine = "CYCLES"; scn.cycles.device = "CPU"; scn.cycles.samples = 4
bk = scn.render.bake
bk.use_selected_to_active = True; bk.cage_extrusion = 0.015; bk.max_ray_distance = 0.06; bk.margin = 6
def hornear(tipo, nodo):
    nt.nodes.active = nodo
    bpy.ops.object.select_all(action="DESELECT")
    for o in altos: o.select_set(True)
    bajo.select_set(True); bpy.context.view_layer.objects.active = bajo
    if tipo == "DIFFUSE":
        bk.use_pass_direct = bk.use_pass_indirect = False; bk.use_pass_color = True
    bpy.ops.object.bake(type=tipo)
for m in bpy.data.materials:  # el color de un metal sale negro en el horneado: sin metal
    for nd in (m.node_tree.nodes if m.node_tree else []):
        if nd.type == "BSDF_PRINCIPLED" and m is not mat:
            nd.inputs["Metallic"].default_value = 0.0
hornear("DIFFUSE", tc)
hornear("NORMAL", tn)
# En Roblox el pelaje se veía oscuro y frío: más luz, más color y un poco más cálido.
import numpy as np
px = np.array(img_c.pixels[:], dtype=np.float32).reshape(-1, 4)
rgb = px[:, :3] * 1.3
gris = rgb.mean(axis=1, keepdims=True)
rgb = gris + (rgb - gris) * 1.12
rgb *= np.array([1.05, 1.0, 0.92], dtype=np.float32)
px[:, :3] = np.clip(rgb, 0, 1)
img_c.pixels[:] = px.ravel()
img_c.update()
os.makedirs(TEXDIR, exist_ok=True)
for img, suf in ((img_c, "color"), (img_n, "normal")):
    img.filepath_raw = os.path.join(TEXDIR, f"{NAME}_{suf}.png"); img.file_format = "PNG"; img.save()
for o in altos: bpy.data.objects.remove(o)

# 3. Esqueleto.
Pt = PUNTOS
def lado(p, s): return V((p.x * s, p.y, p.z))
B = {
    "Raiz": (V((0, 0.02, 0.0)), V((0, 0.02, 0.3)), None),
    "Cadera": (Pt["cadera"], Pt["columna"], "Raiz"),
    "Columna": (Pt["columna"], Pt["pecho"], "Cadera"),
    "Pecho": (Pt["pecho"], Pt["cuello"], "Columna"),
    "Cuello": (Pt["cuello"], Pt["cabeza"], "Pecho"),
    "Cabeza": (Pt["cabeza"], Pt["coronilla"], "Cuello"),
    "Mandibula": (Pt["bisagra"], Pt["menton"], "Cabeza"),
    "Boca": (Pt["boca"], Pt["boca"] + V((0, -0.08, 0)), "Cabeza"),
    "Cola1": (Pt["cola0"], Pt["cola1"], "Cadera"),
    "Cola2": (Pt["cola1"], Pt["cola2"], "Cola1"),
    "Cola3": (Pt["cola2"], Pt["cola3"], "Cola2"),
}
for s, n in ((1, "Izq"), (-1, "Der")):
    B["Oreja" + n] = (lado(Pt["oreja"], s), lado(Pt["oreja_punta"], s), "Cabeza")
    B["Brazo" + n] = (lado(Pt["hombro"], s), lado(Pt["codo"], s), "Pecho")
    B["Antebrazo" + n] = (lado(Pt["codo"], s), lado(Pt["muneca"], s), "Brazo" + n)
    B["Mano" + n] = (lado(Pt["muneca"], s), lado(Pt["mano"], s), "Antebrazo" + n)
    B["Muslo" + n] = (lado(Pt["muslo"], s), lado(Pt["rodilla"], s), "Cadera")
    B["Pierna" + n] = (lado(Pt["rodilla"], s), lado(Pt["tobillo"], s), "Muslo" + n)
    B["Pie" + n] = (lado(Pt["tobillo"], s), lado(Pt["punta_pie"], s), "Pierna" + n)
NODEFORM = {"Raiz", "Boca"}
arm_data = bpy.data.armatures.new("Rig" + NAME)
arm = bpy.data.objects.new("Rig" + NAME, arm_data)
bpy.context.scene.collection.objects.link(arm)
bpy.ops.object.select_all(action="DESELECT"); arm.select_set(True); bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="EDIT")
for n, (h, t, par) in B.items():
    b = arm_data.edit_bones.new(n); b.head, b.tail, b.roll = h, t, 0; b.use_deform = n not in NODEFORM
for n, (h, t, par) in B.items():
    if par: arm_data.edit_bones[n].parent = arm_data.edit_bones[par]
bpy.ops.object.mode_set(mode="OBJECT")

# 4. Pesos.
bpy.ops.object.select_all(action="DESELECT")
bajo.select_set(True); arm.select_set(True); bpy.context.view_layer.objects.active = arm
bpy.ops.object.parent_set(type="ARMATURE_AUTO")
deform = [n for n in B if n not in NODEFORM]
gi = {gr.index: gr.name for gr in bajo.vertex_groups}
def seg(p, a, b):
    ab = b - a; t = max(0, min(1, (p - a).dot(ab) / max(ab.length_squared, 1e-9)))
    return (p - (a + ab * t)).length
rigid, empty = 0, 0
for v in bajo.data.vertices:
    r = [gi[x.group][2:] for x in v.groups if gi[x.group].startswith("R_") and x.weight > 0.5]
    if r:
        for n in deform: bajo.vertex_groups[n].remove([v.index])
        bajo.vertex_groups[r[0]].add([v.index], 1.0, "REPLACE"); rigid += 1
        continue
    total = sum(x.weight for x in v.groups if gi[x.group] in deform)
    if total < 1e-3:
        n = min(deform, key=lambda k: seg(v.co, B[k][0], B[k][1]))
        bajo.vertex_groups[n].add([v.index], 1.0, "REPLACE"); empty += 1
for gr in list(bajo.vertex_groups):
    if gr.name.startswith("R_"): bajo.vertex_groups.remove(gr)
bpy.ops.object.select_all(action="DESELECT"); bajo.select_set(True); bpy.context.view_layer.objects.active = bajo
bpy.ops.object.vertex_group_limit_total(group_select_mode="ALL", limit=4)
bpy.ops.object.vertex_group_normalize_all(group_select_mode="ALL", lock_active=False)
print("RIGIDOS", rigid, "SIN_CALOR", empty)
bpy.ops.wm.save_as_mainfile(filepath=OUT.replace(".fbx", "_rig.blend"))

# 5. FBX.
bpy.ops.object.select_all(action="DESELECT"); bajo.select_set(True); arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.fbx(filepath=OUT, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
    path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y", bake_space_transform=False,
    mesh_smooth_type="FACE", add_leaf_bones=False, use_armature_deform_only=False, bake_anim=False,
    primary_bone_axis="Y", secondary_bone_axis="X", object_types={"ARMATURE", "MESH"})
print("FBX", OUT)
