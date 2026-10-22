r"""
Exporta una sola lámina de agua de la isla de bloques, con la cara hacia arriba, sin rehacer
la isla: abre assets/blender/isla_v2/isla_bloques_4g.blend, da vuelta la cara de Lamina_<n>
si quedó mirando hacia abajo (lo que le pasó al estanque 6 antes de corregir
isla_bloques_malla.orientar, 2026-10-21) y la exporta sola, con la misma configuración que
isla_bloques_exportar.py. La forma queda igual a la que ya está en el juego.
    assets/blender/Lamina_<n>.fbx   para Importar 3D en Studio y reemplazar la MeshPart
Guarda el .blend corregido, así la próxima exportación completa ya sale bien.

Uso (desde la raíz del repo):
    blender -b --factory-startup assets/blender/isla_v2/isla_bloques_4g.blend \
        --python tools/blender/isla_bloques_lamina.py -- 6
"""
import bmesh, bpy, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.normpath(os.path.join(HERE, "..", ".."))
ARGS = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
INDICE = int(ARGS[0]) if ARGS else 6
NOMBRE = f"Lamina_{INDICE}"
FBX = os.path.join(RAIZ, "assets", "blender", f"{NOMBRE}.fbx")


def main():
    o = bpy.data.objects[NOMBRE]
    me = o.data
    # Blender (x, y, z) = Roblox (x, -z, y): "arriba" en Roblox es +Z en Blender.
    abajo = [p for p in me.polygons if p.normal.z < 0]
    if abajo:
        bm = bmesh.new()
        bm.from_mesh(me)
        bmesh.ops.reverse_faces(bm, faces=[f for f in bm.faces if f.normal.z < 0])
        bm.to_mesh(me)
        bm.free()
        me.update()
    print("CARAS DADAS VUELTA", len(abajo), "de", len(me.polygons))
    for other in bpy.data.objects:
        other.select_set(other == o)
    bpy.ops.export_scene.fbx(filepath=FBX, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
        path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y",
        bake_space_transform=True, mesh_smooth_type="FACE", object_types={"MESH"})
    bpy.ops.wm.save_mainfile()
    print("EXPORTADO", FBX)


main()
