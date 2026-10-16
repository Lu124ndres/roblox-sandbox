"""
Arma un traje de personaje (Marinero, DiosVolcan, ReyDelMar) con huesos que el
juego mueve copiando el esqueleto R15 escondido del jugador (client/Outfits):
    Raiz > Cadera > Pecho > Cabeza
                  > Pecho > BrazoIzq > CodoIzq > ManoIzq   (y Der)
          Cadera > PiernaIzq > RodillaIzq > PieIzq          (y Der)
Los pesos salen por zonas (brazos fuera del ancho del torso, piernas bajo la
cadera) y, dentro de cada brazo o pierna, del segmento más cercano con mezcla
suave en codos y rodillas. Un objeto en la mano (el tridente) va entero a la mano.
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

def soft(p, segs, sharp=0.025):
    d = {n: seg_dist(p, a, b) for n, (a, b) in segs.items()}
    m = min(d.values())
    w = {n: math.exp(-(dv - m) / sharp) for n, dv in d.items()}
    t = sum(w.values()); return {n: val / t for n, val in w.items()}

def add(w, part, k):
    for n, val in part.items(): w[n] = w.get(n, 0) + val * k

prop = P.get("prop")
def in_prop(p):
    if not prop: return False
    a, b = V(prop["a"]), V(prop["b"])
    r = prop["headR"] if p.z > prop["headZ"] else prop["r"]
    return p.z > a.z - 0.05 and seg_dist(p, a, b) < r

arm_bottom = {s: min(ARMS[s][3].z, P["handBottom"]) - 0.05 for s in ("Izq", "Der")}
import bmesh
bm = bmesh.new(); bm.from_mesh(o.data); bm.verts.ensure_lookup_table()
# El objeto en la mano: se llena desde las puntas por la malla, cerca de su eje,
# más las islas sueltas que estén cerca (remolinos de agua).
held = set()
if prop:
    a, b = V(prop["a"]), V(prop["b"])
    def near(p, extra=0.0):
        r = (prop["headR"] if p.z > prop["headZ"] else prop["r"]) + extra
        return p.z > a.z - 0.05 and seg_dist(p, a, b) < r
    seen = set(); islands = []
    for v in bm.verts:
        if v.index in seen: continue
        st = [v]; comp = []; seen.add(v.index)
        while st:
            q = st.pop(); comp.append(q)
            for e in q.link_edges:
                r = e.other_vert(q)
                if r.index not in seen: seen.add(r.index); st.append(r)
        islands.append(comp)
    islands.sort(key=len, reverse=True)
    for comp in islands[1:]:
        c = sum((q.co for q in comp), V()) / len(comp)
        if near(c, 0.15): held.update(q.index for q in comp)
    tip = max((q for q in bm.verts if near(q.co)), key=lambda q: q.co.z)
    st = [tip]; held.add(tip.index)
    while st:
        q = st.pop()
        for e in q.link_edges:
            r = e.other_vert(q)
            if r.index not in held and near(r.co):
                held.add(r.index); st.append(r)
    print("HELD", len(held))

def arm_weight(p, xr):
    ax = abs(xr)
    if p.z > P["armTop"]:
        if p.z < P.get("armTop2", 0) and ax > P.get("headHalf", 9):
            return 1.0
        return 0.0
    if p.z > P["shoulderCut"]:  # hombreras: todo lo de afuera del cuello va con el brazo
        return smooth((ax - P["padInner"] + 0.015) / 0.03)
    if p.z < arm_bottom["Izq" if xr > 0 else "Der"]:
        return 0.0
    return smooth((ax - P["tw"] + 0.02) / 0.04)

skirt = P.get("skirt")
groups = {n: o.vertex_groups.new(name=n) for n in B if n != "Raiz"}
stats = {}
hip = LEGS["Izq"][0].z
for v in o.data.vertices:
    p = v.co; xr = p.x - x0; s = "Izq" if xr > 0 else "Der"
    w = {}
    if v.index in held:
        w = {"ManoDer": 1.0}
    else:
        warm = arm_weight(p, xr)
        a = ARMS[s]
        if warm > 0:
            add(w, soft(p, {"Brazo" + s: (a[0], a[1]), "Codo" + s: (a[1], a[2]), "Mano" + s: (a[2], a[3])}), warm)
        rest = 1 - warm
        if rest > 0:
            wleg = smooth((hip + 0.05 - p.z) / 0.1)
            if skirt and skirt["low"] < p.z and abs(p.y - y0) > skirt["depth"]:
                wleg *= 0.2  # faldón: cuelga de la cadera, apenas sigue a las piernas
            if wleg > 0:
                side_w = smooth(xr / 0.06 * 0.5 + 0.5)
                for side, k in (("Izq", side_w), ("Der", 1 - side_w)):
                    if k > 0:
                        l = LEGS[side]
                        add(w, soft(p, {"Pierna" + side: (l[0], l[1]), "Rodilla" + side: (l[1], l[2]), "Pie" + side: (l[2], l[3])}), rest * wleg * k)
            body = rest * (1 - wleg)
            if body > 0:
                wh = smooth((p.z - P["neck"] + 0.03) / 0.06)
                wp = smooth((p.z - P["waist"] + 0.05) / 0.1) * (1 - wh)
                add(w, {"Cabeza": wh, "Pecho": wp, "Cadera": 1 - wh - wp}, body)
    top = sorted(w.items(), key=lambda kv: -kv[1])[:4]
    t = sum(val for _, val in top)
    for n, val in top:
        if val / t > 0.01:
            groups[n].add([v.index], val / t, 'REPLACE'); stats[n] = stats.get(n, 0) + 1
print("STATS", json.dumps(stats))

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
