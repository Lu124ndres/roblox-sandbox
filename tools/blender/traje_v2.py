"""
Arma un traje de bloques v2 (Marinero, Rey del Mar, Dios del Volcán) desde su ficha
(traje_v2_<clave>.py): una sola malla de bloques redondeados (traje_v2_cuerpo.py), colores
planos de una paleta y regiones dibujadas (traje_v2_textura.py), y opcionalmente una máscara
de brillo (lava, gemas, ojos). Los huesos son los 16 que mueve el juego
(src/client/Trajes/Rig.luau) más los extra de la ficha (la capa del Rey del Mar), que mueve el
estilo del traje.

Uso (desde la raíz del repo; antes, la textura con Python normal):
    python tools/blender/traje_v2_textura.py --traje <clave>
    blender -b --factory-startup --python tools/blender/traje_v2.py -- --traje <clave>
Claves: marinero, rey_del_mar, dios_del_volcan.
Salida: assets/blender/<carpeta>/<clave>.blend y assets/blender/Traje<Nombre>_v2.fbx
"""
import bmesh, bpy, importlib, os, sys
from mathutils import Vector as V

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import traje_v2_base as B  # noqa: E402
import traje_v2_cuerpo as C  # noqa: E402

RAIZ = os.path.normpath(os.path.join(HERE, "..", ".."))
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
CLAVE = ARGS[ARGS.index("--traje") + 1] if "--traje" in ARGS else "marinero"
F = importlib.import_module("traje_v2_" + CLAVE)
CARPETA = os.path.join(RAIZ, "assets", "blender", F.CARPETA)
TEXTURA = os.path.join(CARPETA, f"{F.ARCHIVO}_color.png")
BRILLO = os.path.join(CARPETA, f"{F.ARCHIVO}_brillo.png")
SALIDA_FBX = os.path.join(RAIZ, "assets", "blender", f"Traje{F.ARCHIVO}_v2.fbx")


def malla():
    bm = bmesh.new()
    A = C.armar(bm, F)
    C.pintar(A, F)
    bm.verts.index_update()
    partes = C.parte_de_vertice(A)
    abiertas = sum(1 for e in bm.edges if len(e.link_faces) != 2)
    degeneradas = sum(1 for f in bm.faces if f.calc_area() < 1e-6)  # normal indefinida: negro
    tris = sum(len(f.verts) - 2 for f in bm.faces)
    print(f"MALLA {F.ARCHIVO} vertices={len(bm.verts)} triangulos={tris} aristas_abiertas={abiertas} "
          f"caras_degeneradas={degeneradas}")
    me = bpy.data.meshes.new(F.ARCHIVO)
    pesos = {v.index: C.pesos(A, partes[v.index], v.co.copy()) for v in bm.verts}
    bm.to_mesh(me)
    bm.free()
    if "parte" in me.attributes:
        me.attributes.remove(me.attributes["parte"])
    obj = bpy.data.objects.new(F.ARCHIVO, me)
    bpy.context.scene.collection.objects.link(obj)
    return obj, pesos


def material(obj):
    mat = bpy.data.materials.new(F.ARCHIVO)
    if not mat.node_tree:
        mat.use_nodes = True
    nodos, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = next(n for n in nodos if n.type == "BSDF_PRINCIPLED")
    tex = nodos.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(TEXTURA)
    links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.8
    if os.path.exists(BRILLO):  # solo para los renders: en Studio va en la SurfaceAppearance
        mascara = nodos.new("ShaderNodeTexImage")
        mascara.image = bpy.data.images.load(BRILLO)
        mascara.image.colorspace_settings.name = "Non-Color"
        fuerza = nodos.new("ShaderNodeMath")
        fuerza.operation = "MULTIPLY"
        fuerza.inputs[1].default_value = 1.6
        links.new(mascara.outputs["Color"], fuerza.inputs[0])
        links.new(tex.outputs["Color"], bsdf.inputs["Emission Color"])
        links.new(fuerza.outputs["Value"], bsdf.inputs["Emission Strength"])
    obj.data.materials.append(mat)


def esqueleto(obj, pesos):
    huesos = dict(B.HUESOS)
    huesos.update(getattr(F, "HUESOS_EXTRA", {}))
    datos = bpy.data.armatures.new("Rig" + F.ARCHIVO)
    rig = bpy.data.objects.new("Rig" + F.ARCHIVO, datos)
    bpy.context.scene.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    for n, (h, t, _) in huesos.items():
        b = datos.edit_bones.new(n)
        b.head, b.tail, b.roll = V(h), V(t), 0
    for n, (_, _, p) in huesos.items():
        if p:
            datos.edit_bones[n].parent = datos.edit_bones[p]
            datos.edit_bones[n].use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    grupos = {n: obj.vertex_groups.new(name=n) for n in huesos if n != "Raiz"}
    for i, ws in pesos.items():
        for hueso, w in ws.items():
            if w > 1e-4:
                grupos[hueso].add([i], w, "REPLACE")
    obj.parent = rig
    obj.modifiers.new("Armature", "ARMATURE").object = rig
    return rig


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj, pesos = malla()
    material(obj)
    rig = esqueleto(obj, pesos)
    os.makedirs(CARPETA, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(CARPETA, f"{F.CARPETA}.blend"))
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
