r"""
Suaviza un traje ya armado con rig_traje.py para que no se abra en las
articulaciones al caminar ("se corta"): rig_traje separa la malla en piezas
rígidas, y cuando el codo o la rodilla se doblan aparece un hueco con la tapa a
la vista. Aquí:
  1. Se borran las tapas (caras con todas sus UV iguales: así las hizo rig_traje).
  2. Se vuelven a unir los vértices de cada corte (misma posición).
  3. Pesos: en la costura de cada corte, mitad y mitad entre los dos huesos; en
     codos, muñecas, rodillas y tobillos además una zona de transición suave
     (smoothstep) a cada lado del plano de la articulación.
  4. El esqueleto se rehace igual que en rig_traje (mismas puntas, roll 0) y se
     exporta con las mismas opciones, para que el juego lo mueva igual.
Uso desde el MCP de Blender (o la consola):
  NOMBRE, ENTRADA, SALIDA = "Marinero", r"...\TrajeMarinero.fbx", r"...\TrajeMarinero.fbx"
  exec(open(r"...\tools\blender\suavizar_traje.py", encoding="utf-8").read())
  (si SALIDA no es None, exporta al terminar; probar antes posando los huesos)
"""
import bpy, bmesh, json, mathutils, os

V = mathutils.Vector
WIN = bpy.context.window_manager.windows[0]
AREA = next(a for a in WIN.screen.areas if a.type == 'VIEW_3D')
CTX = dict(window=WIN, area=AREA, region=next(r for r in AREA.regions if r.type == 'WINDOW'))
ZONA = {"Codo": 0.07, "Mano": 0.045, "Rodilla": 0.08, "Pie": 0.05}  # ancho de la transición
PADRE = {"Codo": "Brazo", "Mano": "Codo", "Rodilla": "Pierna", "Pie": "Rodilla"}

for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
with bpy.context.temp_override(**CTX):
    bpy.ops.import_scene.fbx(filepath=ENTRADA)
malla = next(o for o in bpy.data.objects if o.type == 'MESH')
rig_viejo = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
HUESOS = {b.name: (b.head_local.copy(), b.tail_local.copy(), b.parent.name if b.parent else None)
          for b in rig_viejo.data.bones}

# Hueso de cada vértice (las piezas son rígidas: peso 1 a uno solo).
nombres = {g.index: g.name for g in malla.vertex_groups}
def clave(co):
    return (round(co.x, 4), round(co.y, 4), round(co.z, 4))
grupos_en = {}
for v in malla.data.vertices:
    if v.groups:
        g = max(v.groups, key=lambda x: x.weight)
        grupos_en.setdefault(clave(v.co), set()).add(nombres[g.group])

bm = bmesh.new(); bm.from_mesh(malla.data)
uv = bm.loops.layers.uv.active
tapas = [f for f in bm.faces if len({(round(l[uv].uv.x, 6), round(l[uv].uv.y, 6)) for l in f.loops}) == 1]
bmesh.ops.delete(bm, geom=tapas, context='FACES')
bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=0.0002)
bm.to_mesh(malla.data); malla.data.update(); bm.free()

malla.vertex_groups.clear()
G = {n: malla.vertex_groups.new(name=n) for n in HUESOS if n != "Raiz"}

def smooth(t):
    t = max(0.0, min(1.0, t)); return t * t * (3 - 2 * t)

def seg_dist(p, a, b):
    ab = b - a; t = max(0.0, min(1.0, (p - a).dot(ab) / max(ab.length_squared, 1e-9)))
    return (p - (a + ab * t)).length

RADIO = 0.16  # solo lo que está pegado al hueso (no el tridente que pasa por la mano)

def plano(hijo):
    h, t, _ = HUESOS[hijo]
    ph, pt, _ = HUESOS[HUESOS[hijo][2]]
    n = (pt - ph).normalized() + (t - h).normalized()
    return h, n.normalized()

costuras = 0
for v in malla.data.vertices:
    dueños = grupos_en.get(clave(v.co)) or {"Cadera"}
    pesos = {}
    if len(dueños) > 1:  # costura de un corte: se reparte
        costuras += 1
        for n in dueños:
            pesos[n] = 1.0 / len(dueños)
    else:
        pesos[next(iter(dueños))] = 1.0
    # Transición suave en codos, muñecas, rodillas y tobillos.
    for hijo_base, ancho in ZONA.items():
        for lado in ("Izq", "Der"):
            hijo, padre = hijo_base + lado, PADRE[hijo_base] + lado
            if not (set(pesos) <= {hijo, padre}):
                continue
            h, t, _ = HUESOS[hijo]
            ph, _, _ = HUESOS[padre]
            if min(seg_dist(v.co, h, t), seg_dist(v.co, ph, h)) > RADIO:
                continue
            c, n = plano(hijo)
            w = smooth(((v.co - c).dot(n) + ancho) / (2 * ancho))
            pesos = {hijo: w, padre: 1 - w}
    if not any(n in G for n in pesos):  # solo la Raiz: va a la cadera
        pesos = {"Cadera": 1.0}
    for n, w in pesos.items():
        if w > 0.001 and n in G:
            G[n].add([v.index], w, 'REPLACE')

# El objeto en la mano (tridente) va entero y rígido a la mano, como en rig_traje:
# desde su punta por la malla, cerca de su eje, más las islas chicas que toca.
RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(ENTRADA))))
PROP = json.load(open(os.path.join(RAIZ, "tools", "blender", "trajes.json"), encoding="utf-8"))[NOMBRE].get("prop")
if PROP:
    a, b = V(PROP["a"]), V(PROP["b"])
    def cerca(p):
        r = PROP["headR"] if p.z > PROP["headZ"] else PROP["r"]
        return p.z > a.z - 0.05 and seg_dist(p, a, b) < r
    bm = bmesh.new(); bm.from_mesh(malla.data); bm.verts.ensure_lookup_table()
    punta = max((q for q in bm.verts if cerca(q.co)), key=lambda q: q.co.z)
    mano, pila = {punta.index}, [punta]
    while pila:
        q = pila.pop()
        for e in q.link_edges:
            r = e.other_vert(q)
            if r.index not in mano and cerca(r.co):
                mano.add(r.index); pila.append(r)
    vistos = set()
    for v0 in bm.verts:
        if v0.index in vistos:
            continue
        isla, pila = [v0.index], [v0]; vistos.add(v0.index)
        while pila:
            q = pila.pop()
            for e in q.link_edges:
                r = e.other_vert(q)
                if r.index not in vistos:
                    vistos.add(r.index); isla.append(r.index); pila.append(r)
        if len(isla) < 300 and any(cerca(bm.verts[i].co) for i in isla):
            mano.update(isla)
    bm.free()
    for i in mano:
        for g in G.values():
            g.remove([i])
        G["ManoDer"].add([i], 1.0, 'REPLACE')
    print("TRIDENTE", len(mano))

# Esqueleto nuevo, idéntico al de rig_traje (roll 0).
bpy.data.objects.remove(rig_viejo)
datos = bpy.data.armatures.new("Rig" + NOMBRE)
rig = bpy.data.objects.new("Rig" + NOMBRE, datos)
bpy.context.scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
with bpy.context.temp_override(**CTX, active_object=rig, object=rig):
    bpy.ops.object.mode_set(mode='EDIT')
    for n, (h, t, p) in HUESOS.items():
        b = datos.edit_bones.new(n); b.head = h; b.tail = t; b.roll = 0
    for n, (h, t, p) in HUESOS.items():
        if p:
            datos.edit_bones[n].parent = datos.edit_bones[p]; datos.edit_bones[n].use_connect = False
    bpy.ops.object.mode_set(mode='OBJECT')
malla.parent = rig
malla.modifiers.clear()
mod = malla.modifiers.new("Armature", "ARMATURE"); mod.object = rig
print("COSTURAS", costuras, "TAPAS", len(tapas))

def exportar(ruta):
    for pb in rig.pose.bones:  # en reposo
        pb.rotation_euler = (0, 0, 0); pb.rotation_quaternion = (1, 0, 0, 0); pb.location = (0, 0, 0)
    for o in bpy.data.objects:
        o.select_set(o in (malla, rig))
    bpy.context.view_layer.objects.active = rig
    with bpy.context.temp_override(**CTX):
        bpy.ops.export_scene.fbx(filepath=ruta, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
            path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y", bake_space_transform=False,
            mesh_smooth_type="FACE", add_leaf_bones=False, use_armature_deform_only=False, bake_anim=False,
            primary_bone_axis='Y', secondary_bone_axis='X', object_types={'ARMATURE', 'MESH'})


if SALIDA:
    exportar(SALIDA)
