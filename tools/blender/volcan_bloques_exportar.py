r"""
Exporta el volcán de bloques (assets/blender/volcan_v2/volcan_bloques_4f.blend) para el juego:
    assets/blender/VolcanBloques.fbx                    las mallas: montaña (Volcan_*), cueva
                                                        (VolcanCueva_*), lava de afuera
                                                        (VolcanLava) y de la cueva (VolcanCuevaLava)
    assets/blender/volcan_v2/VolcanBloques_piezas.json  dónde va el centro de cada malla en
                                                        Roblox, relativo al centro del cráter
                                                        (dx, y, dz): se suma craterCenter

Misma configuración de FBX que props_mapa.py (studs, -Z adelante, Y arriba, textura embebida),
así Blender (x, y, z) = Roblox (x, z, -y). La colección "Referencia" (agua, puente, isla,
arco y luces de revisión) no se exporta.
Al importarlo en Studio (Importar 3D) cada malla queda girada 180° sobre su propio centro
(convención de ejes del importador): después de importar, cada MeshPart va a
CFrame.new(centro) * CFrame.Angles(0, math.pi, 0), con el centro de este JSON.

Uso (desde la raíz del repo):
    blender -b --factory-startup assets/blender/volcan_v2/volcan_bloques_4f.blend \
        --python tools/blender/volcan_bloques_exportar.py
"""
import bpy, json, os
from mathutils import Vector as V

HERE = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.normpath(os.path.join(HERE, "..", ".."))
FBX = os.path.join(RAIZ, "assets", "blender", "VolcanBloques.fbx")
PIEZAS = os.path.join(RAIZ, "assets", "blender", "volcan_v2", "VolcanBloques_piezas.json")
LIMITE = 20000  # triángulos por MeshPart en Roblox


def exportable(o):
    referencia = any(c.name.startswith("Referencia") for c in o.users_collection)
    return o.type == "MESH" and o.name.startswith("Volcan") and not referencia


def main():
    objetos = [o for o in bpy.data.objects if exportable(o)]
    piezas = {}
    for o in bpy.data.objects:
        o.select_set(o in objetos)
    for o in objetos:
        esquinas = [o.matrix_world @ V(c) for c in o.bound_box]
        medio = sum(esquinas, V()) / 8
        tris = sum(len(p.vertices) - 2 for p in o.data.polygons)
        assert tris < LIMITE, f"{o.name} tiene {tris} triángulos"
        piezas[o.name] = {
            "centro": [round(medio.x, 3), round(medio.z, 3), round(-medio.y, 3)],
            "tam": [round(o.dimensions.x, 3), round(o.dimensions.z, 3), round(o.dimensions.y, 3)],
            "tris": tris,
        }
    bpy.ops.export_scene.fbx(filepath=FBX, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
        path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y",
        bake_space_transform=True, mesh_smooth_type="FACE", object_types={"MESH"})
    with open(PIEZAS, "w", encoding="utf-8", newline="\n") as f:
        json.dump(piezas, f, indent=1, sort_keys=True)
    print("EXPORTADO", FBX, len(piezas), "piezas", sum(p["tris"] for p in piezas.values()), "triángulos")


main()
