"""
Rehace los huesos y pesos de una etapa del dragón (DragonMarinoE1..E4) a partir de su
FBX. La versión anterior dejaba de reposo las alas arriba (arriba del aleteo); al
planear, que es lo que más hace, el ala quedaba en su pose más forzada. Ahora:

1. Con el rig que trae el FBX se posan las alas en PLANEO (horizontales, con un poco
   de diedro) y se hornea esa pose en la malla: es el nuevo reposo. El aleteo sube y
   baja simétrico alrededor de ella.
2. Se arma un esqueleto nuevo en esa pose con los mismos nombres:
       Raiz > Cadera > Pecho > Cuello1 > Cuello2 > Cabeza > Mandibula, Boca
              Cadera > Cola1 > ... > Cola6
              Pecho > AlaIzq1 > AlaIzq2 > AlaIzq3        (y Der)
              Pecho > BrazoIzq > AntebrazoIzq > ManoIzq  (y Der)
              Cadera > MusloIzq > PiernaIzq > PieIzq     (y Der)
3. Pesos por calor, suavizados (sin tocar la boca) y en 4 influencias (Roblox).

Uso: blender -b --factory-startup --python rig_dragon.py -- <entrada.fbx> <salida.fbx> <Nombre> [diedro_grados]
"""
import bpy, sys, math, json, mathutils

V = mathutils.Vector
args = sys.argv[sys.argv.index("--") + 1:]
SRC, OUT, NAME = args[0], args[1], args[2]
DIHEDRAL = float(args[3]) if len(args) > 3 else 8.0

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=SRC)
old = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
mesh = next(o for o in bpy.data.objects if o.type == 'MESH')
for o in list(bpy.data.objects):
    if o not in (old, mesh):
        bpy.data.objects.remove(o)
AW = old.matrix_world


def world(p):
    return AW @ p


# --- 1. Alas en planeo ------------------------------------------------------------
bpy.context.view_layer.objects.active = old
bpy.ops.object.mode_set(mode='POSE')
pb = old.pose.bones


def rotate_chain(name, axis_world, angle):
    b = pb[name]
    bpy.context.view_layer.update()
    head = b.head.copy()
    ax = (AW.inverted().to_3x3() @ V(axis_world)).normalized()
    R = mathutils.Matrix.Rotation(angle, 4, ax)
    b.matrix = mathutils.Matrix.Translation(head) @ R @ mathutils.Matrix.Translation(-head) @ b.matrix
    bpy.context.view_layer.update()


for s in ("Izq", "Der"):
    bpy.context.view_layer.update()
    root = world(pb[f"Ala{s}1"].head)
    tip = world(pb[f"Ala{s}3"].tail)
    span = tip - root
    side = 1 if span.x > 0 else -1
    # Ángulo actual del ala alrededor del eje largo del cuerpo (Y): 0 = horizontal.
    current = math.atan2(span.z, abs(span.x))
    target = math.radians(DIHEDRAL)
    # Girar alrededor de +Y sube el lado -X: el signo depende del lado.
    rotate_chain(f"Ala{s}1", (0, 1, 0), (current - target) * side)
    # La mano un poco abierta hacia atrás, como al planear.
    bpy.context.view_layer.update()
bpy.ops.object.mode_set(mode='OBJECT')

# Hornea la pose en la malla y guarda dónde quedó cada hueso.
bpy.context.view_layer.update()
posed = {b.name: (world(b.head).copy(), world(b.tail).copy(), b.parent.name if b.parent else None)
         for b in pb}
bpy.context.view_layer.objects.active = mesh
mesh.select_set(True)
mod = next(m for m in mesh.modifiers if m.type == 'ARMATURE')
bpy.ops.object.modifier_apply(modifier=mod.name)
mesh.parent = None
mesh.matrix_world = mesh.matrix_world.copy()
bpy.data.objects.remove(old)
bpy.ops.object.select_all(action='DESELECT')
mesh.select_set(True)
bpy.context.view_layer.objects.active = mesh
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
mesh.vertex_groups.clear()
mesh.name = NAME

# --- 2. Esqueleto nuevo ------------------------------------------------------------
NODEFORM = {"Raiz", "Boca"}
arm_data = bpy.data.armatures.new("Rig" + NAME)
arm = bpy.data.objects.new("Rig" + NAME, arm_data)
bpy.context.scene.collection.objects.link(arm)
bpy.ops.object.select_all(action='DESELECT')
bpy.context.view_layer.objects.active = arm
arm.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
eb = arm_data.edit_bones
for n, (h, t, p) in posed.items():
    b = eb.new(n)
    b.head, b.tail = h, t
    if (t - h).length < 1e-4:
        b.tail = h + V((0, 0, 0.02))
    b.align_roll(V((0, 0, 1)))
    b.use_deform = n not in NODEFORM
for n, (h, t, p) in posed.items():
    if p:
        eb[n].parent = eb[p]
        eb[n].use_connect = False
bpy.ops.object.mode_set(mode='OBJECT')

# --- 3. Pesos -------------------------------------------------------------------------
bpy.ops.object.select_all(action='DESELECT')
mesh.select_set(True)
arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.parent_set(type='ARMATURE_AUTO')

names = [n for n in posed if n not in NODEFORM]


def seg_dist(p, a, b):
    ab = b - a
    t = max(0, min(1, (p - a).dot(ab) / max(ab.length_squared, 1e-9)))
    return (p - (a + ab * t)).length


gi = {g.index: g.name for g in mesh.vertex_groups}
empty = 0
for v in mesh.data.vertices:
    if sum(g.weight for g in v.groups if gi.get(g.group) in names) < 1e-3:
        n = min(names, key=lambda k: seg_dist(v.co, posed[k][0], posed[k][1]))
        mesh.vertex_groups[n].add([v.index], 1.0, 'REPLACE')
        empty += 1

bpy.ops.object.select_all(action='DESELECT')
mesh.select_set(True)
bpy.context.view_layer.objects.active = mesh
# Suaviza todo menos la mandíbula (si no, el labio de abajo arrastra al de arriba).
for g in mesh.vertex_groups:
    g.lock_weight = g.name == "Mandibula"
bpy.ops.object.mode_set(mode='WEIGHT_PAINT')
bpy.ops.object.vertex_group_smooth(group_select_mode='BONE_DEFORM', factor=0.5, repeat=2, expand=0.0)
for g in mesh.vertex_groups:
    g.lock_weight = False
bpy.ops.object.vertex_group_limit_total(group_select_mode='ALL', limit=4)
bpy.ops.object.vertex_group_normalize_all(group_select_mode='ALL', lock_active=False)
bpy.ops.object.mode_set(mode='OBJECT')

# Base en z = 0 y centrado (la pose nueva cambió la caja).
bb = [mesh.matrix_world @ V(c) for c in mesh.bound_box]
mn = V([min(p[i] for p in bb) for i in range(3)])
mx = V([max(p[i] for p in bb) for i in range(3)])
shift = V(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z))
mesh.data.transform(mathutils.Matrix.Translation(-shift))
bpy.ops.object.select_all(action='DESELECT')
arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='EDIT')
for b in arm_data.edit_bones:
    b.head -= shift
    b.tail -= shift
bpy.ops.object.mode_set(mode='OBJECT')

stats = {g.name: 0 for g in mesh.vertex_groups}
for v in mesh.data.vertices:
    for ge in v.groups:
        if ge.weight > 0.01:
            stats[mesh.vertex_groups[ge.group].name] += 1
print("RIG", NAME, "sin_calor", empty, "dims", [round(d, 3) for d in mesh.dimensions], json.dumps(stats))

bpy.ops.wm.save_as_mainfile(filepath=OUT.replace(".fbx", "_rig.blend"))
bpy.ops.object.select_all(action='DESELECT')
mesh.select_set(True)
arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.fbx(filepath=OUT, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
    path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y", bake_space_transform=False,
    mesh_smooth_type="FACE", add_leaf_bones=False, use_armature_deform_only=False, bake_anim=False,
    primary_bone_axis='Y', secondary_bone_axis='X', object_types={'ARMATURE', 'MESH'})
