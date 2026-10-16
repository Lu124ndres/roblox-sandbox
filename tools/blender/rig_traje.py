"""
Arma un traje de personaje (Marinero, DiosVolcan, ReyDelMar) con huesos que el
juego mueve copiando el esqueleto R15 escondido del jugador (client/Outfits):
    Raiz > Cadera > Pecho > Cabeza
                  > Pecho > BrazoIzq > CodoIzq > ManoIzq   (y Der)
          Cadera > PiernaIzq > RodillaIzq > PieIzq          (y Der)
Piezas rígidas, como un avatar R15: la malla se corta con planos en cada
articulación (hombro, codo, muñeca, cadera, rodilla, tobillo, cintura, cuello),
cada pieza va entera a su hueso y los cortes se tapan. Así nada se estira.
Un objeto en la mano (el tridente) va entero a la mano; un faldón, a la cadera.
Uso: python3 -I rig_traje.py -- <modelo.blend> <salida.fbx> <params.json> <Nombre>
"""
import bpy, json, sys, math, os, mathutils
SRC, OUT, PARAMS, NAME = sys.argv[-4], sys.argv[-3], sys.argv[-2], sys.argv[-1]
P = json.load(open(PARAMS))[NAME]
bpy.ops.wm.open_mainfile(filepath=SRC)
TEXDIR = os.path.join(os.path.dirname(os.path.abspath(SRC)), "tex")
for img in bpy.data.images:
    path = os.path.join(TEXDIR, os.path.basename(img.filepath or img.name))
    if os.path.exists(path):
        img.filepath = path; img.reload(); img.pack()
o = [x for x in bpy.context.scene.objects if x.type == 'MESH'][0]
for x in list(bpy.context.scene.objects):
    if x is not o:
        bpy.data.objects.remove(x)
V = mathutils.Vector
x0 = P["x0"]
torso = [v.co.y for v in o.data.vertices if P["waist"] < v.co.z < P["neck"] and abs(v.co.x - x0) < P["tw"] * 0.7]
y0 = (min(torso) + max(torso)) / 2
print("Y0", y0)

def clamp(t): return max(0.0, min(1.0, t))
def smooth(t):
    t = clamp(t); return t * t * (3 - 2 * t)

def arm_chain(side):
    s = 1 if side == "Izq" else -1
    pts = P["arm"].get(side)
    if pts is None:
        pts = [[-p[0], p[1], p[2]] for p in P["arm"]["Izq"]]
    return [V((x0 + (p[0] if side == "Izq" or "Der" in P["arm"] else s * abs(p[0])) , y0 + p[1], p[2])) for p in pts]

def leg_chain(side):
    s = 1 if side == "Izq" else -1
    (hx, hz), (kx, kz), (ax, az) = P["leg"]
    return [V((x0 + s * hx, y0, hz)), V((x0 + s * kx, y0, kz)), V((x0 + s * ax, y0, az)), V((x0 + s * ax, y0 + P["toe"], 0.02))]

ARMS = {s: arm_chain(s) for s in ("Izq", "Der")}
LEGS = {s: leg_chain(s) for s in ("Izq", "Der")}
B = {
    "Raiz": (V((x0, y0, 0)), V((x0, y0, 0.15)), None),
    "Cadera": (V((x0, y0, LEGS["Izq"][0].z + 0.06)), V((x0, y0, P["waist"])), "Raiz"),
    "Pecho": (V((x0, y0, P["waist"])), V((x0, y0, P["neck"])), "Cadera"),
    "Cabeza": (V((x0, y0, P["neck"])), V((x0, y0, P["neck"] + 0.3)), "Pecho"),
}
for s in ("Izq", "Der"):
    a, l = ARMS[s], LEGS[s]
    B["Brazo" + s] = (a[0], a[1], "Pecho"); B["Codo" + s] = (a[1], a[2], "Brazo" + s); B["Mano" + s] = (a[2], a[3], "Codo" + s)
    B["Pierna" + s] = (l[0], l[1], "Cadera"); B["Rodilla" + s] = (l[1], l[2], "Pierna" + s); B["Pie" + s] = (l[2], l[3], "Rodilla" + s)

def seg_dist(p, a, b):
    ab = b - a; t = clamp((p - a).dot(ab) / max(ab.length_squared, 1e-9))
    return (p - (a + ab * t)).length

import bmesh
bm = bmesh.new(); bm.from_mesh(o.data)

# Planos de corte de cada cadena: en cada articulación, normal hacia la punta.
def joint_planes(chain):
    planes = []
    for i in (1, 2):
        d = (chain[i] - chain[i - 1]).normalized() + (chain[i + 1] - chain[i]).normalized()
        planes.append((chain[i].copy(), d.normalized()))
    return planes
PLANES = {}
for s in ("Izq", "Der"):
    PLANES["arm" + s] = joint_planes(ARMS[s])
    PLANES["leg" + s] = joint_planes(LEGS[s])
hip = LEGS["Izq"][0].z
arm_low = min(min(ARMS[s][3].z for s in ARMS), P["handBottom"]) - 0.05
# Cada plano corta solo la zona donde separa piezas (si no, se multiplican los triángulos).
def zone(zmin, zmax, xmin=-9, xmax=9):
    return lambda p: zmin - 0.02 <= p.z <= zmax + 0.02 and xmin - 0.02 <= abs(p.x - x0) <= xmax + 0.02
Z = V((0, 0, 1)); X = V((1, 0, 0))
cuts = [((V((0, 0, hip)), Z), zone(hip, hip, 0, P["tw"])),
        ((V((0, 0, P["waist"])), Z), zone(P["waist"], P["waist"], 0, P["tw"])),
        ((V((0, 0, P["neck"])), Z), zone(P["neck"], P["neck"], 0, P["padInner"])),
        ((V((0, 0, P["shoulderCut"])), Z), zone(P["shoulderCut"], P["shoulderCut"], P["padInner"], P["tw"])),
        ((V((x0, 0, 0)), X), zone(-1, hip))]
for sg in (1, -1):
    cuts.append(((V((x0 + sg * P["tw"], 0, 0)), X), zone(arm_low, P["shoulderCut"])))
    cuts.append(((V((x0 + sg * P["padInner"], 0, 0)), X), zone(P["shoulderCut"], P["armTop"])))
skirt = P.get("skirt")
if skirt:
    for sg in (1, -1):
        cuts.append(((V((0, y0 + sg * skirt["depth"], 0)), V((0, 1, 0))), zone(skirt["low"], hip)))
for s_ in ("Izq", "Der"):
    for plane in PLANES["arm" + s_]:
        cuts.append((plane, lambda p: abs(p.x - x0) > P["tw"] - 0.03 and p.z < P["armTop"]))
    for plane in PLANES["leg" + s_]:
        cuts.append((plane, lambda p: p.z < hip + 0.03))
for (co, no), inside in cuts:
    faces = [f for f in bm.faces if inside(f.calc_center_median())]
    edges = list({e for f in faces for e in f.edges}); verts = list({v for f in faces for v in f.verts})
    if faces:
        bmesh.ops.bisect_plane(bm, geom=verts + edges + faces, plane_co=co, plane_no=no)
bmesh.ops.triangulate(bm, faces=bm.faces[:])
bm.verts.ensure_lookup_table(); bm.faces.ensure_lookup_table()

# El objeto en la mano: desde la punta por la malla, cerca de su eje.
prop = P.get("prop")
held = set()
if prop:
    a, b = V(prop["a"]), V(prop["b"])
    def near(p):
        r = prop["headR"] if p.z > prop["headZ"] else prop["r"]
        return p.z > a.z - 0.05 and seg_dist(p, a, b) < r
    tip = max((q for q in bm.verts if near(q.co)), key=lambda q: q.co.z)
    st = [tip]; held.add(tip.index)
    while st:
        q = st.pop()
        for e in q.link_edges:
            r = e.other_vert(q)
            if r.index not in held and near(r.co):
                held.add(r.index); st.append(r)
    print("HELD", len(held))

def chain_part(p, planes, names):
    (c1, n1), (c2, n2) = planes
    if (p - c2).dot(n2) > 0: return names[2]
    if (p - c1).dot(n1) > 0: return names[1]
    return names[0]

def region(p, fallback_held=False):
    xr = p.x - x0; s = "Izq" if xr > 0 else "Der"; ax = abs(xr)
    arm = False
    if p.z > P["armTop"]:
        arm = P.get("armTop2", 0) > p.z and ax > P.get("headHalf", 9)
    elif p.z > P["shoulderCut"]:
        arm = ax > P["padInner"]
    elif p.z > min(ARMS[s][3].z, P["handBottom"]) - 0.05:
        arm = ax > P["tw"]
    if arm:
        return chain_part(p, PLANES["arm" + s], ("Brazo" + s, "Codo" + s, "Mano" + s))
    if p.z < hip:
        if skirt and p.z > skirt["low"] and abs(p.y - y0) > skirt["depth"]:
            return "Cadera"
        return chain_part(p, PLANES["leg" + s], ("Pierna" + s, "Rodilla" + s, "Pie" + s))
    if p.z > P["neck"]: return "Cabeza"
    if p.z > P["waist"]: return "Pecho"
    return "Cadera"

names = [n for n in B if n != "Raiz"]
layer = bm.faces.layers.int.new("hueso")
for f in bm.faces:
    if held and all(v.index in held for v in f.verts):
        f[layer] = names.index("ManoDer")
    else:
        f[layer] = names.index(region(f.calc_center_median()))
cut = [e for e in bm.edges if len(e.link_faces) == 2 and e.link_faces[0][layer] != e.link_faces[1][layer]]
def key(e):
    return frozenset(tuple(round(c, 5) for c in v.co) for v in e.verts)
before = {key(e) for e in bm.edges if len(e.link_faces) == 1}  # bordes que ya traía la malla
bmesh.ops.split_edges(bm, edges=cut)
uv = bm.loops.layers.uv.active
holes = [e for e in bm.edges if len(e.link_faces) == 1 and key(e) not in before]
filled = bmesh.ops.holes_fill(bm, edges=holes, sides=0)["faces"]
for f in filled:
    ring = [l for e in f.edges for l in e.link_loops if l.face is not f]
    if ring:
        mu = sum((l[uv].uv for l in ring), mathutils.Vector((0, 0))) / len(ring)
        for l in f.loops: l[uv].uv = mu
        f[layer] = ring[0].face[layer]
bmesh.ops.triangulate(bm, faces=filled)
print("TAPAS", len(filled))
bm.to_mesh(o.data); o.data.update(); bm.free()
o.vertex_groups.clear()
groups = {n: o.vertex_groups.new(name=n) for n in names}
attr = o.data.attributes["hueso"]
votes = {}
for poly in o.data.polygons:
    n = names[attr.data[poly.index].value]
    for vi in poly.vertices:
        votes.setdefault(vi, {}); votes[vi][n] = votes[vi].get(n, 0) + 1
stats = {}
for vi, vv in votes.items():
    n = max(vv, key=vv.get)
    groups[n].add([vi], 1.0, 'REPLACE'); stats[n] = stats.get(n, 0) + 1
o.data.attributes.remove(attr)
tris = sum(len(p.vertices) - 2 for p in o.data.polygons)
print("STATS", tris, json.dumps(stats))
arm_data = bpy.data.armatures.new("Rig" + NAME)
arm = bpy.data.objects.new("Rig" + NAME, arm_data)
bpy.context.scene.collection.objects.link(arm)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='EDIT')
eb = arm_data.edit_bones
for n, (h, t, par) in B.items():
    b = eb.new(n); b.head = h; b.tail = t; b.roll = 0
for n, (h, t, par) in B.items():
    if par: eb[n].parent = eb[par]; eb[n].use_connect = False
bpy.ops.object.mode_set(mode='OBJECT')
o.parent = arm
mod = o.modifiers.new("Armature", "ARMATURE"); mod.object = arm
bpy.ops.wm.save_as_mainfile(filepath=OUT.replace(".fbx", "_rig.blend"))
bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.fbx(filepath=OUT, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
    path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y", bake_space_transform=False,
    mesh_smooth_type="FACE", add_leaf_bones=False, use_armature_deform_only=False, bake_anim=False,
    primary_bone_axis='Y', secondary_bone_axis='X', object_types={'ARMATURE', 'MESH'})
