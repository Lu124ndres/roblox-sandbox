"""
Arma un dragón (etapas DragonMarinoE1..E4) para volar:
    Raiz > Cadera > Pecho > Cuello1 > Cuello2 > Cabeza > Mandibula, Boca
           Cadera > Cola1 > ... > Cola6
           Pecho > AlaIzq1 > AlaIzq2 > AlaIzq3        (y Der)   alas
           Pecho > BrazoIzq > AntebrazoIzq > ManoIzq  (y Der)   patas delanteras
           Cadera > MusloIzq > PiernaIzq > PieIzq     (y Der)   patas traseras
Los huesos siguen la línea central de cada parte (centro.py). Los pesos los
calcula Blender por calor (suaves, la membrana de las alas sigue a sus huesos).
Después se le pone la POSE DE VUELO y se guarda como pose de reposo: cola
estirada hacia atrás, patas recogidas, cuello adelante y alas arriba y
abiertas (arriba del aleteo). El juego anima desde ahí (Shared.Dragon).
Uso: python3 -I rig_dragon.py -- <modelo.blend> <joints.json> <salida.fbx> <Nombre> [params.json]
"""
import bpy, json, sys, math, os, mathutils
SRC, JOINTS, OUT, NAME = sys.argv[-4], sys.argv[-3], sys.argv[-2], sys.argv[-1]
J = json.load(open(JOINTS))
PRM = J.get("pose", {})
V = mathutils.Vector
bpy.ops.wm.open_mainfile(filepath=SRC)
TEXDIR = os.path.join(os.path.dirname(os.path.abspath(SRC)), "tex")
for img in bpy.data.images:
    path = os.path.join(TEXDIR, os.path.basename(img.filepath or img.name))
    if os.path.exists(path):
        img.filepath = path; img.reload(); img.pack()
o = [x for x in bpy.context.scene.objects if x.type == 'MESH'][0]
for x in list(bpy.context.scene.objects):
    if x is not o: bpy.data.objects.remove(x)
L = {k: [V(p) for p in v] for k, v in J["limbs"].items()}
P, C = V(J["P"]), V(J["C"])
M = (P + C) / 2
B = {}  # nombre: (cabeza, cola, padre)
B["Raiz"] = (M - V((0, 0, 0.12)), M - V((0, 0, 0.02)), None)
B["Cadera"] = (P, M, "Raiz")
B["Pecho"] = (M, C, "Cadera")
def chain(names, pts, parent):
    for i, n in enumerate(names):
        B[n] = (pts[i], pts[i + 1], parent if i == 0 else names[i - 1])
chain(["Cuello1", "Cuello2", "Cabeza"], L["Cuello"], "Pecho")
chain([f"Cola{i}" for i in range(1, 7)], L["Cola"], "Cadera")
for s in ("Izq", "Der"):
    chain([f"Ala{s}1", f"Ala{s}2", f"Ala{s}3"], L["Ala" + s], "Pecho")
    chain([f"Brazo{s}", f"Antebrazo{s}", f"Mano{s}"], L["PataDel" + s], "Pecho")
    chain([f"Muslo{s}", f"Pierna{s}", f"Pie{s}"], L["PataTras" + s], "Cadera")
jh, jt = V(J["jaw"][0]), V(J["jaw"][1])
B["Mandibula"] = (jh, jt, "Cabeza")
boca = V(J["boca"])
B["Boca"] = (boca, boca + (jt - jh).normalized() * 0.05, "Cabeza")
NODEFORM = {"Raiz", "Boca"}

arm_data = bpy.data.armatures.new("Rig" + NAME)
arm = bpy.data.objects.new("Rig" + NAME, arm_data)
bpy.context.scene.collection.objects.link(arm)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='EDIT')
eb = arm_data.edit_bones
for n, (h, t, par) in B.items():
    b = eb.new(n); b.head = h; b.tail = t; b.roll = 0
    b.use_deform = n not in NODEFORM
for n, (h, t, par) in B.items():
    if par: eb[n].parent = eb[par]; eb[n].use_connect = False
bpy.ops.object.mode_set(mode='OBJECT')

# Pesos por calor.
bpy.ops.object.select_all(action='DESELECT')
o.select_set(True); arm.select_set(True); bpy.context.view_layer.objects.active = arm
bpy.ops.object.parent_set(type='ARMATURE_AUTO')
names = [n for n in B if n not in NODEFORM]
def seg_dist(p, a, b):
    ab = b - a; t = max(0, min(1, (p - a).dot(ab) / max(ab.length_squared, 1e-9)))
    return (p - (a + ab * t)).length
gi = {g.index: g.name for g in o.vertex_groups}
empty = 0
for v in o.data.vertices:
    total = sum(g.weight for g in v.groups if gi[g.group] in names)
    if total < 1e-3:  # el calor no llegó: al hueso más cercano
        n = min(names, key=lambda k: seg_dist(v.co, B[k][0], B[k][1]))
        o.vertex_groups[n].add([v.index], 1.0, 'REPLACE'); empty += 1
# Máximo 4 influencias y normalizado (Roblox).
bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active = o
bpy.ops.object.vertex_group_limit_total(group_select_mode='ALL', limit=4)
bpy.ops.object.vertex_group_normalize_all(group_select_mode='ALL', lock_active=False)
print("SIN_CALOR", empty)

# Pose de vuelo.
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='POSE')
pb = arm.pose.bones
def aim(name, direction):
    b = pb[name]
    bpy.context.view_layer.update()
    head = b.head.copy(); cur = (b.tail - b.head).normalized()
    d = V(direction).normalized()
    q = cur.rotation_difference(d)
    m = mathutils.Matrix.Translation(head) @ q.to_matrix().to_4x4() @ mathutils.Matrix.Translation(-head) @ b.matrix
    b.matrix = m
    bpy.context.view_layer.update()
def turn_chain(first, axis, deg):
    """Gira una cadena entera alrededor de un eje del mundo por su raíz."""
    b = pb[first]; bpy.context.view_layer.update()
    head = b.head.copy()
    R = mathutils.Matrix.Rotation(math.radians(deg), 4, V(axis))
    b.matrix = mathutils.Matrix.Translation(head) @ R @ mathutils.Matrix.Translation(-head) @ b.matrix
    bpy.context.view_layer.update()
droop = PRM.get("tailDroop", -0.12)
for i in range(1, 7):
    aim(f"Cola{i}", (0, 1, droop * (1 + i * 0.15)))
for n, d in zip(("Cuello1", "Cuello2", "Cabeza"), PRM.get("neck", [(0, -0.8, 0.6), (0, -0.95, 0.3), (0, -1, -0.08)])):
    aim(n, d)
for s, sg in (("Izq", 1), ("Der", -1)):
    for n, d in zip((f"Brazo{s}", f"Antebrazo{s}", f"Mano{s}"), [(0, 0.45, -0.9), (0, 0.9, -0.45), (0, 1, -0.1)]):
        aim(n, (d[0] * sg, d[1], d[2]))
    for n, d in zip((f"Muslo{s}", f"Pierna{s}", f"Pie{s}"), [(0, 0.55, -0.85), (0, 1, -0.25), (0, 1, 0.15)]):
        aim(n, (d[0] * sg, d[1], d[2]))
    spread = PRM.get("wingSpread", 0)
    if spread:  # abre el ala hacia el costado (gira alrededor de la vertical)
        turn_chain(f"Ala{s}1", (0, 0, 1), -spread * sg)
    lift = PRM.get("wingLift", 0)
    if lift:  # sube el ala (gira alrededor del eje largo del cuerpo)
        turn_chain(f"Ala{s}1", (0, 1, 0), -lift * sg)
bpy.ops.object.mode_set(mode='OBJECT')
# Hornea la pose en la malla y la deja como reposo.
bpy.context.view_layer.objects.active = o
mod = [m for m in o.modifiers if m.type == 'ARMATURE'][0]
bpy.ops.object.modifier_apply(modifier=mod.name)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='POSE')
bpy.ops.pose.armature_apply(selected=False)
bpy.ops.object.mode_set(mode='OBJECT')
mod = o.modifiers.new("Armature", "ARMATURE"); mod.object = arm
# Base en z=0 otra vez y centrado (la pose cambió la caja).
bb = [o.matrix_world @ V(c) for c in o.bound_box]
mn = V([min(v[i] for v in bb) for i in range(3)]); mx = V([max(v[i] for v in bb) for i in range(3)])
shift = V(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z))
o.data.transform(mathutils.Matrix.Translation(-shift))
bpy.ops.object.select_all(action='DESELECT'); arm.select_set(True); bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='EDIT')
for b in arm_data.edit_bones:
    b.head -= shift; b.tail -= shift
bpy.ops.object.mode_set(mode='OBJECT')
print("DIMS", [round(d, 3) for d in o.dimensions])
bpy.ops.wm.save_as_mainfile(filepath=OUT.replace(".fbx", "_rig.blend"))
bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.fbx(filepath=OUT, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
    path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y", bake_space_transform=False,
    mesh_smooth_type="FACE", add_leaf_bones=False, use_armature_deform_only=False, bake_anim=False,
    primary_bone_axis='Y', secondary_bone_axis='X', object_types={'ARMATURE', 'MESH'})
