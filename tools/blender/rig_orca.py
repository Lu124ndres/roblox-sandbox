"""
Arma una etapa de la orca desde cero para animarla desde el juego (Shared.Orca).
Parte del FBX de la etapa (se le quitan los huesos viejos y se rehacen):

    Raiz > Pecho > Cabeza > Mandibula          (Boca y Espiraculo: puntos)
    Pecho > AletaIzq > AletaIzq2   (y Der)      pectorales con "codo"
    Raiz > Dorsal                               la aleta del lomo se mece
    Raiz > Cola1 > Cola2 > Cola3 > Cola4 > AletaColaIzq, AletaColaDer

La columna sigue la línea media del cuerpo (medida en la malla) con huesos más
cortos hacia la cola, así la onda del nado se curva parejo. Los pesos los calcula
Blender por calor, se suavizan y se dejan en 4 influencias por vértice (el tope de
Roblox). La mandíbula se corta a mano por la línea entre los labios (orcas.json),
si no el calor pega el labio de abajo con el de arriba.

Uso: blender -b --factory-startup --python rig_orca.py -- <entrada.fbx> <salida.fbx> <orcas.json> <Nombre>
Al importar en Studio: marcar "Mantener huesos de influencia cero" (Boca, Espiraculo).
"""
import bpy, json, sys, math, mathutils

SRC, OUT, PARAMS, NAME = sys.argv[-4], sys.argv[-3], sys.argv[-2], sys.argv[-1]
P = json.load(open(PARAMS))[NAME]
V = mathutils.Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=SRC)
mesh = next(o for o in bpy.data.objects if o.type == 'MESH')
for o in list(bpy.data.objects):
    if o is not mesh:
        bpy.data.objects.remove(o)
for m in list(mesh.modifiers):
    mesh.modifiers.remove(m)
mesh.vertex_groups.clear()
bpy.context.view_layer.objects.active = mesh
mesh.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
mesh.name = NAME
verts = [v.co.copy() for v in mesh.data.vertices]
LENGTH = max(v.y for v in verts) - min(v.y for v in verts)
NOSE = min(v.y for v in verts)


def band(y, half=0.03, width=0.12):
    return [v for v in verts if abs(v.y - y) < half and abs(v.x) < width]


def mid(y):
    """Altura de la línea media del cuerpo en y (centro entre panza y lomo)."""
    s = band(y)
    return (min(v.z for v in s) + max(v.z for v in s)) / 2 if s else P["center"]


def spine(y):
    return V((0, y, mid(y)))


# --- Huesos -----------------------------------------------------------------------
hy, hz = P["hinge"]
(chin_y, chin_z), (corner_y, corner_z) = P["mouth"]
fy0, fy1 = P["fin_y"]
fx0, fx1 = P["fin_x"]

# Pectoral: raíz en el costado, punta = el vértice de la aleta más lejano de la raíz.
fin_root = V((fx0, (fy0 + fy1) / 2, P["fin_z"]))
fin_verts = [v for v in verts if v.x > fx0 and fy0 < v.y < fy1 and v.z < P["fin_z_max"]]
fin_tip = max(fin_verts, key=lambda v: (v - fin_root).length) if fin_verts else fin_root + V((0.15, 0.1, -0.25))
fin_mid = fin_root.lerp(fin_tip, 0.5)

# Dorsal: base en el lomo, punta = el vértice más alto detrás de la cabeza.
back = [v for v in verts if v.y > -0.15 and abs(v.x) < 0.08]
dorsal_tip = max(back, key=lambda v: v.z)
dorsal_base = V((0, dorsal_tip.y - 0.05, mid(dorsal_tip.y) + 0.12))

# Aletas de la cola: punta = el vértice más afuera en el último 15% del largo.
fluke_y = NOSE + LENGTH * 0.88
flukes = [v for v in verts if v.y > fluke_y]
fluke_tip = max(flukes, key=lambda v: v.x)
tail_end = spine(NOSE + LENGTH * 0.86)

Y = lambda f: NOSE + LENGTH * f  # fracción del largo, desde la nariz
B = {  # nombre: (cabeza, cola, padre, deforma)
    "Raiz": (spine(Y(0.50)), spine(Y(0.38)), None, True),
    "Pecho": (spine(Y(0.38)), spine(Y(0.24)), "Raiz", True),
    "Cabeza": (spine(Y(0.24)), V((0, NOSE, mid(Y(0.06)))), "Pecho", True),
    "Mandibula": (V((0, hy, hz)), V((0, chin_y, chin_z - 0.03)), "Cabeza", True),
    "Boca": (V((0, (chin_y * 2 + hy) / 3, (chin_z * 2 + hz) / 3)), V((0, chin_y, chin_z)), "Cabeza", False),
    "Espiraculo": (V((0, Y(0.33), max(v.z for v in band(Y(0.33), 0.03, 0.06)) + 0.01)), None, "Cabeza", False),
    "Dorsal": (dorsal_base, dorsal_tip, "Raiz", True),
    "Cola1": (spine(Y(0.50)), spine(Y(0.62)), "Raiz", True),
    "Cola2": (spine(Y(0.62)), spine(Y(0.72)), "Cola1", True),
    "Cola3": (spine(Y(0.72)), spine(Y(0.80)), "Cola2", True),
    "Cola4": (spine(Y(0.80)), tail_end, "Cola3", True),
    "AletaColaIzq": (tail_end, V((fluke_tip.x, fluke_tip.y, tail_end.z)), "Cola4", True),
    "AletaColaDer": (tail_end, V((-fluke_tip.x, fluke_tip.y, tail_end.z)), "Cola4", True),
    "AletaIzq": (fin_root, fin_mid, "Pecho", True),
    "AletaIzq2": (fin_mid, fin_tip, "AletaIzq", True),
    "AletaDer": (V((-fin_root.x, fin_root.y, fin_root.z)), V((-fin_mid.x, fin_mid.y, fin_mid.z)), "Pecho", True),
    "AletaDer2": (V((-fin_mid.x, fin_mid.y, fin_mid.z)), V((-fin_tip.x, fin_tip.y, fin_tip.z)), "AletaDer", True),
}
espi = B["Espiraculo"][0]
B["Espiraculo"] = (espi, espi + V((0, 0, 0.08)), "Cabeza", False)

arm_data = bpy.data.armatures.new("Rig" + NAME)
arm = bpy.data.objects.new("Rig" + NAME, arm_data)
bpy.context.scene.collection.objects.link(arm)
bpy.ops.object.select_all(action='DESELECT')
bpy.context.view_layer.objects.active = arm
arm.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
eb = arm_data.edit_bones
for n, (h, t, p, d) in B.items():
    b = eb.new(n)
    b.head, b.tail = h, t
    b.align_roll(V((0, 0, 1)))  # el eje Z de cada hueso mira arriba (o adelante si es vertical)
    b.use_deform = d
for n, (h, t, p, d) in B.items():
    if p:
        eb[n].parent = eb[p]
        eb[n].use_connect = False
bpy.ops.object.mode_set(mode='OBJECT')

# --- Pesos --------------------------------------------------------------------------
bpy.ops.object.select_all(action='DESELECT')
mesh.select_set(True)
arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.parent_set(type='ARMATURE_AUTO')
heat_ok = any(len(v.groups) for v in mesh.data.vertices)
if not heat_ok:  # malla no cerrada: el calor no encuentra solución → por distancia
    bpy.ops.object.parent_set(type='ARMATURE_ENVELOPE')

bpy.context.view_layer.objects.active = mesh
bpy.ops.object.mode_set(mode='WEIGHT_PAINT')
bpy.ops.object.vertex_group_smooth(group_select_mode='ALL', factor=0.5, repeat=3, expand=0.0)
bpy.ops.object.mode_set(mode='OBJECT')

groups = {g.name: g for g in mesh.vertex_groups}
for n in ("Mandibula",):
    if n not in groups:
        groups[n] = mesh.vertex_groups.new(name=n)


def clamp(t):
    return max(0.0, min(1.0, t))


def mouth_z(y):
    t = clamp((y - chin_y) / (corner_y - chin_y))
    return chin_z + (corner_z - chin_z) * t


# Mandíbula: lo que está debajo de la línea de los labios y delante de la bisagra.
for v in mesh.data.vertices:
    x, y, z = v.co
    if y < hy + 0.06 and z < mouth_z(y) and abs(x) < 0.45:
        wj = clamp((hy + 0.06 - y) / 0.08) * clamp((mouth_z(y) - z) / 0.03 + 0.2)
        if wj <= 0:
            continue
        for ge in list(v.groups):
            g = mesh.vertex_groups[ge.group]
            if g.name != "Mandibula":
                g.add([v.index], ge.weight * (1 - wj), 'REPLACE')
        groups["Mandibula"].add([v.index], wj, 'ADD')
    elif y < hy and z > mouth_z(y) and "Mandibula" in groups:
        groups["Mandibula"].remove([v.index])  # el labio de arriba nunca sigue a la mandíbula

bpy.context.view_layer.objects.active = mesh
bpy.ops.object.mode_set(mode='WEIGHT_PAINT')
bpy.ops.object.vertex_group_limit_total(group_select_mode='ALL', limit=4)
bpy.ops.object.vertex_group_normalize_all(group_select_mode='ALL', lock_active=False)
bpy.ops.object.mode_set(mode='OBJECT')

stats = {g.name: 0 for g in mesh.vertex_groups}
empty = 0
for v in mesh.data.vertices:
    ws = [ge for ge in v.groups if ge.weight > 0.01]
    if not ws:
        empty += 1
    for ge in ws:
        stats[mesh.vertex_groups[ge.group].name] += 1
print("RIG", NAME, "heat" if heat_ok else "envelope", "sin_pesos", empty, json.dumps(stats))

bpy.ops.wm.save_as_mainfile(filepath=OUT.replace(".fbx", "_rig.blend"))
bpy.ops.object.select_all(action='DESELECT')
mesh.select_set(True)
arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.fbx(filepath=OUT, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
    path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y", bake_space_transform=False,
    mesh_smooth_type="FACE", add_leaf_bones=False, use_armature_deform_only=False, bake_anim=False,
    primary_bone_axis='Y', secondary_bone_axis='X', object_types={'ARMATURE', 'MESH'})
