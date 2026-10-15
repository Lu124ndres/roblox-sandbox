"""
Arma una etapa de la orca para animarla desde el juego (Shared.Orca):
    Raiz > Cabeza > Mandibula, Boca, Espiraculo
    Raiz > Cola1 > Cola2 > Cola3 > Cola4     (Cola4 = aletas de la cola)
    Raiz > AletaIzq, AletaDer, Dorsal
Los huesos siguen la línea media del cuerpo (medida en la malla) y los pesos se
mezclan con curvas suaves para que el cuerpo ondule sin quiebres. Cada modelo da
su boca y sus aletas en un JSON (tools/blender/orcas.json).
Uso: blender -b --python rig_orca.py -- <modelo.blend> <salida.fbx> <params.json> <Nombre>
Al importar en Studio: marcar "Mantener huesos de influencia cero".
"""
import bpy, json, sys, mathutils
SRC, OUT, PARAMS, NAME = sys.argv[-4], sys.argv[-3], sys.argv[-2], sys.argv[-1]
P = json.load(open(PARAMS))[NAME]
bpy.ops.wm.open_mainfile(filepath=SRC)
import os
TEXDIR = os.path.join(os.path.dirname(os.path.abspath(SRC)), "tex")
for img in bpy.data.images:  # las texturas se guardaron con ruta relativa: se vuelven a cargar
    path = os.path.join(TEXDIR, os.path.basename(img.filepath or img.name))
    if os.path.exists(path):
        img.filepath = path
        img.reload()
        img.pack()
o = [x for x in bpy.context.scene.objects if x.type == 'MESH'][0]
for x in list(bpy.context.scene.objects):
    if x is not o:
        bpy.data.objects.remove(x)
verts = [v.co.copy() for v in o.data.vertices]

def mid(y):
    """Altura de la línea media del cuerpo en y (centro de la franja central)."""
    s = [v.z for v in verts if abs(v.y - y) < 0.04 and abs(v.x) < 0.12]
    return (min(s) + max(s)) / 2 if s else P["center"]

def top(y):
    s = [v.z for v in verts if abs(v.y - y) < 0.04 and abs(v.x) < 0.06]
    return max(s) if s else P["center"] + 0.3

def clamp(v):
    return max(0.0, min(1.0, v))

def smooth(t):
    t = clamp(t)
    return t * t * (3 - 2 * t)

hy, hz = P["hinge"]
line = P["mouth"]  # [[y, z], [y, z]]: la línea entre los labios, de la punta a la comisura

def mouth_z(y):
    (y0, z0), (y1, z1) = line
    t = clamp((y - y0) / (y1 - y0))
    return z0 + (z1 - z0) * t

SPINE = [("Cabeza", -0.42), ("Raiz", -0.15), ("Raiz", 0.08), ("Cola1", 0.26), ("Cola2", 0.44), ("Cola3", 0.62), ("Cola4", 0.80)]
fy0, fy1 = P["fin_y"]
fx0, fx1 = P["fin_x"]
fin_root = (fy0 + fy1) / 2
B = {
    "Raiz": ((0, 0.0, mid(0.0)), (0, -0.15, mid(-0.15)), None),
    "Cabeza": ((0, -0.30, mid(-0.30)), (0, -0.60, mid(-0.60)), "Raiz"),
    "Mandibula": ((0, hy, hz), (0, line[0][0], line[0][1] - 0.04), "Cabeza"),
    "Boca": ((0, (line[0][0] * 2 + hy) / 3, mouth_z(line[0][0] * 0.66 + hy * 0.34)), (0, line[0][0], line[0][1]), "Cabeza"),
    "Espiraculo": ((0, -0.22, top(-0.22) + 0.02), (0, -0.22, top(-0.22) + 0.1), "Cabeza"),
    "Dorsal": ((0, 0.1, top(0.1) - 0.1), (0, 0.1, top(0.1)), "Raiz"),
    "Cola1": ((0, 0.20, mid(0.20)), (0, 0.38, mid(0.38)), "Raiz"),
    "Cola2": ((0, 0.38, mid(0.38)), (0, 0.55, mid(0.55)), "Cola1"),
    "Cola3": ((0, 0.55, mid(0.55)), (0, 0.70, mid(0.70)), "Cola2"),
    "Cola4": ((0, 0.70, mid(0.70)), (0, 0.95, mid(0.85)), "Cola3"),
    "AletaIzq": ((fx0, fin_root, P["fin_z"]), (fx1 + 0.1, fin_root + 0.08, P["fin_z"] - 0.2), "Raiz"),
    "AletaDer": ((-fx0, fin_root, P["fin_z"]), (-fx1 - 0.1, fin_root + 0.08, P["fin_z"] - 0.2), "Raiz"),
}
arm_data = bpy.data.armatures.new("Rig" + NAME)
arm = bpy.data.objects.new("Rig" + NAME, arm_data)
bpy.context.scene.collection.objects.link(arm)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='EDIT')
eb = arm_data.edit_bones
for n, (h, t, p) in B.items():
    b = eb.new(n); b.head = h; b.tail = t; b.roll = 0
for n, (h, t, p) in B.items():
    if p:
        eb[n].parent = eb[p]; eb[n].use_connect = False
bpy.ops.object.mode_set(mode='OBJECT')
groups = {n: o.vertex_groups.new(name=n) for n in B if n not in ("Boca", "Espiraculo", "Dorsal")}
stats = {}
for v in o.data.vertices:
    x, y, z = v.co
    w = {}
    if y <= SPINE[0][1]:
        w = {SPINE[0][0]: 1}
    elif y >= SPINE[-1][1]:
        w = {SPINE[-1][0]: 1}
    else:
        for (a, ya), (b, yb) in zip(SPINE, SPINE[1:]):
            if ya <= y <= yb:
                t = smooth((y - ya) / (yb - ya))
                w[a] = w.get(a, 0) + 1 - t
                w[b] = w.get(b, 0) + t
                break
    if y < hy + 0.06 and z < mouth_z(y):
        wj = clamp((hy + 0.06 - y) / 0.08)
        w = {k: val * (1 - wj) for k, val in w.items()}
        w["Mandibula"] = w.get("Mandibula", 0) + wj
    if z < P["fin_z_max"] and fy0 < y < fy1:
        wf = smooth((abs(x) - fx0) / (fx1 - fx0))
        if wf > 0:
            side = "AletaIzq" if x > 0 else "AletaDer"
            w = {k: val * (1 - wf) for k, val in w.items()}
            w[side] = wf
    for k, val in w.items():
        if val > 1e-4:
            groups[k].add([v.index], val, 'REPLACE'); stats[k] = stats.get(k, 0) + 1
o.parent = arm
mod = o.modifiers.new("Armature", "ARMATURE"); mod.object = arm
print("STATS", json.dumps(stats))
bpy.ops.wm.save_as_mainfile(filepath=OUT.replace(".fbx", "_rig.blend"))
bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.fbx(filepath=OUT, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
    path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y", bake_space_transform=False,
    mesh_smooth_type="FACE", add_leaf_bones=False, use_armature_deform_only=False, bake_anim=False,
    primary_bone_axis='Y', secondary_bone_axis='X', object_types={'ARMATURE', 'MESH'})
