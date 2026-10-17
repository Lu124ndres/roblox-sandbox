r"""
Las etapas del Minotauro v2 lado a lado, a su tamaño real, para revisar que se lean como el
mismo personaje creciendo (docs/plan_minotauro_v2.md, paso 9). Toma las piezas de
assets/blender/minotauro_v2/e<n>_bloques.blend (las etapas que existan), las pone en fila de
la más chica a la más grande y renderiza:
    frente.png        de frente, con sus colores
    tres_cuartos.png  de tres cuartos
    proporciones.png  todas al mismo alto, para comparar cabeza, piernas y hombros
    silueta.png       lo mismo en negro sobre blanco (la guía pide que la silueta se lea así)
en renders/minotauro_v2_alineacion/. No guarda nada más.

Uso (desde la raíz del repo):
    blender -b --factory-startup --python tools/blender/minotauro_v2_alineacion.py
"""
import bpy, json, math, os
from mathutils import Matrix, Vector as V

HERE = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.normpath(os.path.join(HERE, "..", ".."))
SALIDA = os.path.join(RAIZ, "renders", "minotauro_v2_alineacion")
HUECO = 0.25  # separación entre etapas, en fracción del ancho de la más grande vecina


def cargar(etapa):
    """Objetos con hueso del .blend de la etapa, linkeados a la escena; None si no existe."""
    ruta = os.path.join(RAIZ, "assets", "blender", "minotauro_v2", f"e{etapa}_bloques.blend")
    if not os.path.exists(ruta):
        return None
    with bpy.data.libraries.load(ruta, link=False) as (desde, hacia):
        hacia.objects = list(desde.objects)
    objs = [o for o in hacia.objects if o is not None and o.type == "MESH" and "hueso" in o]
    for o in objs:
        bpy.context.scene.collection.objects.link(o)
        for m in o.data.materials:  # Workbench pinta con el color de vista, no con el del nodo
            nodo = m.node_tree.nodes.get("Principled BSDF") if m.node_tree else None
            if nodo:
                m.diffuse_color = nodo.inputs["Base Color"].default_value
    return objs


def caja(objs):
    pts = [o.matrix_world @ v.co for o in objs for v in o.data.vertices]
    lo = V((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = V((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return lo, hi


def escena(ancho, alto):
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sc.display.shading.light = "STUDIO"
    sc.display.shading.color_type = "MATERIAL"
    sc.display.shading.show_shadows = True
    sc.display.shading.shadow_intensity = 0.35
    sc.view_settings.view_transform = "Standard"
    sc.render.resolution_x, sc.render.resolution_y = 1800, 900
    mundo = bpy.data.worlds.new("Fondo")
    mundo.color = (0.32, 0.36, 0.42)
    sc.world = mundo
    bpy.ops.mesh.primitive_plane_add(size=ancho * 3, location=(ancho / 2, 0, 0))
    cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = max(ancho * 1.08, alto * 2.15)
    cam.data.clip_end = ancho * 20
    sc.collection.objects.link(cam)
    sc.camera = cam
    return sc, cam


def apuntar(cam, centro, grados, distancia, alto_ojo):
    a = math.radians(grados)
    cam.location = centro + V((math.sin(a) * distancia, -math.cos(a) * distancia, alto_ojo))
    cam.rotation_euler = (centro - cam.location).to_track_quat("-Z", "Y").to_euler()


for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
etapas = {n: objs for n in (1, 2, 3, 4) if (objs := cargar(n))}
x, fila = 0.0, {}
anterior = 0.0
for n, objs in etapas.items():
    lo, hi = caja(objs)
    ancho = hi.x - lo.x
    x += (anterior + ancho) / 2 * (1 + HUECO) if fila else 0
    for o in objs:
        o.location.x += x - (lo.x + hi.x) / 2
    fila[n] = {"alto_bu": round(hi.z - lo.z, 3), "ancho_bu": round(ancho, 3), "x": round(x, 3)}
    anterior = ancho
bpy.context.view_layer.update()  # si no, matrix_world sigue en el lugar de antes
lo, hi = caja([o for objs in etapas.values() for o in objs])
ancho, alto = hi.x - lo.x, hi.z - lo.z
sc, cam = escena(ancho, alto)
centro = V(((lo.x + hi.x) / 2, 0, alto / 2))
os.makedirs(SALIDA, exist_ok=True)
for nombre, grados, ojo in (("frente", 0, 0.0), ("tres_cuartos", 30, 0.25)):
    apuntar(cam, centro, grados, ancho * 4, ancho * 4 * ojo)
    sc.render.filepath = os.path.join(SALIDA, nombre + ".png")
    bpy.ops.render.render(write_still=True)
# Proporciones: todas al alto de la más grande, en fila, para comparar cabeza, piernas y hombros.
mayor = max(f["alto_bu"] for f in fila.values())
x, anterior = 0.0, 0.0
for i, (n, objs) in enumerate(etapas.items()):
    lo, hi = caja(objs)
    k = mayor / (hi.z - lo.z)
    base = V(((lo.x + hi.x) / 2, 0, lo.z))
    ancho_k = (hi.x - lo.x) * k
    x += (anterior + ancho_k) / 2 * (1 + HUECO) if i else 0
    for o in objs:
        o.matrix_world = (Matrix.Translation(V((x, 0, 0))) @ Matrix.Scale(k, 4)
                          @ Matrix.Translation(-base) @ o.matrix_world)
    anterior = ancho_k
lo, hi = caja([o for objs in etapas.values() for o in objs])
ancho = hi.x - lo.x
cam.data.ortho_scale = max(ancho * 1.08, mayor * 2.15)
centro = V(((lo.x + hi.x) / 2, 0, mayor / 2))
bpy.data.objects["Plane"].location.x = centro.x
apuntar(cam, centro, 0, ancho * 4, 0)
sc.render.filepath = os.path.join(SALIDA, "proporciones.png")
bpy.ops.render.render(write_still=True)
# Silueta: sin luz ni sombra, todo negro sobre blanco.
sc.display.shading.light = "FLAT"
sc.display.shading.color_type = "SINGLE"
sc.display.shading.single_color = (0, 0, 0)
sc.display.shading.show_shadows = False
bpy.data.objects["Plane"].hide_render = True
sc.world.color = (1, 1, 1)
sc.render.filepath = os.path.join(SALIDA, "silueta.png")
bpy.ops.render.render(write_still=True)
print("ALINEACION", json.dumps(fila))
