r"""
Exporta la isla de bloques (assets/blender/isla_v2/isla_bloques_4g.blend) para el juego:
    assets/blender/IslaBloques.fbx                  las mallas: sectores del suelo (IslaSector_*),
                                                    aros de piedra (AroEstanque_*), agua de color
                                                    de los estanques (Lamina_*), rampas de los
                                                    senderos (RampaSendero_*) y matas (MatasMonticulos)
    assets/blender/isla_v2/IslaBloques_piezas.json  dónde va el centro de cada malla en Roblox
                                                    (x, y, z), para acomodarlas después de importar

Misma configuración de FBX que props_mapa.py (studs, -Z adelante, Y arriba, textura embebida),
así Blender (x, y, z) = Roblox (x, z, -y). El mar de referencia (Mar) no se exporta.
Al importarlo en Studio (Importar 3D) cada malla queda girada 180° sobre su propio centro
(convención de ejes del importador): después de importar, cada MeshPart va a
CFrame.new(centro) * CFrame.Angles(0, math.pi, 0), con el centro de este JSON.

Uso (desde la raíz del repo):
    blender -b --factory-startup assets/blender/isla_v2/isla_bloques_4g.blend \
        --python tools/blender/isla_bloques_exportar.py
"""
import bpy, json, os
from mathutils import Vector as V

HERE = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.normpath(os.path.join(HERE, "..", ".."))
FBX = os.path.join(RAIZ, "assets", "blender", "IslaBloques.fbx")
PIEZAS = os.path.join(RAIZ, "assets", "blender", "isla_v2", "IslaBloques_piezas.json")
PREFIJOS = ("IslaSector_", "AroEstanque_", "Lamina_", "RampaSendero_", "MatasMonticulos")


def centro_roblox(o):
    esquinas = [o.matrix_world @ V(c) for c in o.bound_box]
    medio = sum(esquinas, V()) / 8
    tam = o.dimensions
    return [round(medio.x, 3), round(medio.z, 3), round(-medio.y, 3)], [
        round(tam.x, 3), round(tam.z, 3), round(tam.y, 3)]


def main():
    objetos = [o for o in bpy.data.objects if o.type == "MESH" and o.name.startswith(PREFIJOS)]
    piezas = {}
    for o in bpy.data.objects:
        o.select_set(o in objetos)
    for o in objetos:
        centro, tam = centro_roblox(o)
        tris = sum(len(p.vertices) - 2 for p in o.data.polygons)
        piezas[o.name] = {"centro": centro, "tam": tam, "tris": tris}
    bpy.ops.export_scene.fbx(filepath=FBX, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
        path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y",
        bake_space_transform=True, mesh_smooth_type="FACE", object_types={"MESH"})
    with open(PIEZAS, "w", encoding="utf-8", newline="\n") as f:
        json.dump(piezas, f, indent=1, sort_keys=True)
    print("EXPORTADO", FBX, len(piezas), "piezas", sum(p["tris"] for p in piezas.values()), "triángulos")
    print("MAYOR", max(piezas.items(), key=lambda kv: kv[1]["tris"]))


main()
