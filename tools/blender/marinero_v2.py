"""
Marinero v2: el traje que llevan todos los jugadores, modelado desde cero (antes salía de
Meshy, con la textura horneada en pedacitos y piezas cortadas en hombros y cadera).

Una sola malla cerrada de bloques redondeados (marinero_v2_cuerpo.py), colores planos de una
paleta y tres regiones dibujadas (cara, pecho y espalda: marinero_v2_textura.py). Los huesos
son los mismos 16 de rig_traje.py (Raiz, Cadera, Pecho, Cabeza, Brazo/Codo/Mano y
Pierna/Rodilla/Pie, Izq/Der), así que el juego lo mueve igual (src/client/Trajes/Rig.luau).
Pesos: cada articulación mezcla sus dos huesos en una franja corta (smoothstep); hombros,
caderas y cuello giran sobre su puente, que está justo en el pivote.

Uso (desde la raíz del repo; antes, la textura con Python normal):
    python tools/blender/marinero_v2_textura.py
    blender -b --factory-startup --python tools/blender/marinero_v2.py
Salida: assets/blender/marinero_v2/marinero_v2.blend y assets/blender/TrajeMarinero_v2.fbx
"""
import bmesh, bpy, os, sys
from mathutils import Vector as V

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import marinero_v2_datos as D  # noqa: E402
import marinero_v2_cuerpo as C  # noqa: E402

RAIZ = os.path.normpath(os.path.join(HERE, "..", ".."))
CARPETA = os.path.join(RAIZ, "assets", "blender", "marinero_v2")
TEXTURA = os.path.join(CARPETA, "Marinero_color.png")
SALIDA_FBX = os.path.join(RAIZ, "assets", "blender", "TrajeMarinero_v2.fbx")

# Huesos: (cabeza, cola, padre). La izquierda del personaje está en +X.
HUESOS = {
    "Raiz": ((0, 0, 0), (0, 0, 0.15), None),
    "Cadera": ((0, 0, 2.0), (0, 0, D.CINTURA[0]), "Raiz"),
    "Pecho": ((0, 0, D.CINTURA[0]), (0, 0, D.CUELLO_Z), "Cadera"),
    "Cabeza": ((0, 0, D.CUELLO_Z), (0, 0, D.CUELLO_Z + 0.3), "Pecho"),
}
for lado, s in (("Izq", 1), ("Der", -1)):
    bx, px = s * D.BRAZO["cx"], s * D.PIERNA["cx"]
    HUESOS["Brazo" + lado] = ((s * 1.015, 0, D.HOMBRO_Z), (bx, D.CODO_Y, D.CODO[0]), "Pecho")
    HUESOS["Codo" + lado] = ((bx, D.CODO_Y, D.CODO[0]), (bx, 0, D.MUNECA[0]), "Brazo" + lado)
    HUESOS["Mano" + lado] = ((bx, 0, D.MUNECA[0]), (bx, 0, 2.0), "Codo" + lado)
    HUESOS["Pierna" + lado] = ((px, 0, D.CADERA_Z), (px, D.RODILLA_Y, D.RODILLA[0]), "Cadera")
    HUESOS["Rodilla" + lado] = ((px, D.RODILLA_Y, D.RODILLA[0]), (px, 0, D.TOBILLO[0]), "Pierna" + lado)
    HUESOS["Pie" + lado] = ((px, 0, D.TOBILLO[0]), (px, -0.55, 0.02), "Rodilla" + lado)


def suave(z, junta):
    """0 debajo de la articulación, 1 encima, con una transición corta."""
    centro, medio = junta
    t = max(0.0, min(1.0, (z - centro + medio) / (2 * medio)))
    return t * t * (3 - 2 * t)


def pesos(co, parte):
    z = co.z
    if parte == C.TORSO:
        t = suave(z, D.CINTURA)
        return {"Pecho": t, "Cadera": 1 - t}
    if parte in (C.CABEZA, C.GORRA):
        return {"Cabeza": 1.0}
    if parte in (C.BRAZO_I, C.BRAZO_D):
        lado = "Izq" if parte == C.BRAZO_I else "Der"
        te, tm = suave(z, D.CODO), suave(z, D.MUNECA)
        return {"Brazo" + lado: te, "Codo" + lado: (1 - te) * tm, "Mano" + lado: 1 - tm}
    lado = "Izq" if parte == C.PIERNA_I else "Der"
    # Arriba de la pierna, parte del peso queda en la cadera: así el borde de arriba casi no
    # se inclina y no se abre una cuña bajo el torso al caminar.
    cadera = max(0.0, min(0.5, (z - 1.70) / (1.98 - 1.70) * 0.5))
    tr, tt = suave(z, D.RODILLA), suave(z, D.TOBILLO)
    return {"Cadera": cadera, "Pierna" + lado: tr * (1 - cadera),
            "Rodilla" + lado: (1 - tr) * tt, "Pie" + lado: 1 - tt}


def malla():
    bm = bmesh.new()
    etiqueta = bm.faces.layers.int.new("parte")
    C.armar(bm, etiqueta)
    C.pintar(bm, etiqueta)
    bm.verts.index_update()
    partes = C.parte_de_vertice(bm, etiqueta)
    abiertas = sum(1 for e in bm.edges if len(e.link_faces) != 2)
    degeneradas = sum(1 for f in bm.faces if f.calc_area() < 1e-6)  # normal indefinida: negro
    tris = sum(len(f.verts) - 2 for f in bm.faces)
    print(f"MALLA vertices={len(bm.verts)} triangulos={tris} aristas_abiertas={abiertas} "
          f"caras_degeneradas={degeneradas}")
    me = bpy.data.meshes.new("Marinero")
    bm.to_mesh(me)
    bm.free()
    if "parte" in me.attributes:
        me.attributes.remove(me.attributes["parte"])
    obj = bpy.data.objects.new("Marinero", me)
    bpy.context.scene.collection.objects.link(obj)
    return obj, partes


def material(obj):
    mat = bpy.data.materials.new("Marinero")
    if not mat.node_tree:
        mat.use_nodes = True
    nodos = mat.node_tree.nodes
    bsdf = next(n for n in nodos if n.type == "BSDF_PRINCIPLED")
    tex = nodos.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(TEXTURA)
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.8
    obj.data.materials.append(mat)


def esqueleto(obj, partes):
    datos = bpy.data.armatures.new("RigMarinero")
    rig = bpy.data.objects.new("RigMarinero", datos)
    bpy.context.scene.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    for n, (h, t, _) in HUESOS.items():
        b = datos.edit_bones.new(n)
        b.head, b.tail, b.roll = V(h), V(t), 0
    for n, (_, _, p) in HUESOS.items():
        if p:
            datos.edit_bones[n].parent = datos.edit_bones[p]
            datos.edit_bones[n].use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    grupos = {n: obj.vertex_groups.new(name=n) for n in HUESOS if n != "Raiz"}
    for v in obj.data.vertices:
        for hueso, w in pesos(v.co, partes[v.index]).items():
            if w > 1e-4:
                grupos[hueso].add([v.index], w, "REPLACE")
    obj.parent = rig
    obj.modifiers.new("Armature", "ARMATURE").object = rig
    return rig


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj, partes = malla()
    material(obj)
    rig = esqueleto(obj, partes)
    os.makedirs(CARPETA, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(CARPETA, "marinero_v2.blend"))
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.export_scene.fbx(filepath=SALIDA_FBX, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
                             path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y",
                             bake_space_transform=False, mesh_smooth_type="FACE", add_leaf_bones=False,
                             use_armature_deform_only=False, bake_anim=False, primary_bone_axis="Y",
                             secondary_bone_axis="X", object_types={"ARMATURE", "MESH"})
    print("LISTO", SALIDA_FBX)


main()
