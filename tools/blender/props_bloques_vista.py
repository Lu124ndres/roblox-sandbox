r"""
Vista de revisión de los props de bloques (la carga props_bloques.py): los pone en fila al
alto que tienen en el juego, arma un estudio de arena con cielo y sol, y saca el render.
    en_fila(objetos)                 los acomoda en fila (cada uno a su alto del juego)
    render(objetos, archivo, lejos)  estudio, cámara que abarca la fila y render a `archivo`
"""
import bpy, bmesh, math
from mathutils import Vector as V

# Alto de cada prop en el juego (studs), por el comienzo del nombre.
ALTOS = {"Palmera": 14, "Arbusto": 3.8, "Roca": 3.5, "Cresta": 20}


def alto_de(nombre):
    for prefijo, alto in ALTOS.items():
        if nombre.startswith(prefijo):
            return alto
    return 4


def en_fila(objetos):
    x = 0.0
    for o in objetos:
        bpy.context.view_layer.update()
        o.scale = o.scale * (alto_de(o.name) / o.dimensions.z)
        bpy.context.view_layer.update()
        abajo = min((o.matrix_world @ V(c)).z for c in o.bound_box)
        o.location.z -= abajo
        ancho = max(o.dimensions.x, o.dimensions.y)
        o.location.x = x + ancho / 2
        x += ancho + 3


def _estudio():
    sc = bpy.context.scene
    motores = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    sc.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in motores else "BLENDER_EEVEE"
    sc.render.resolution_x, sc.render.resolution_y = 1800, 800
    sc.view_settings.view_transform = "Standard"
    if not sc.world or sc.world.name != "Cielo":
        mundo = bpy.data.worlds.new("Cielo")
        mundo.use_nodes = True
        mundo.node_tree.nodes["Background"].inputs[0].default_value = (0.42, 0.62, 0.86, 1)
        mundo.node_tree.nodes["Background"].inputs[1].default_value = 0.8
        sc.world = mundo
    if "Piso" not in bpy.data.objects:
        datos = bpy.data.meshes.new("Piso")
        bm = bmesh.new()
        bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=120)
        bm.to_mesh(datos)
        bm.free()
        piso = bpy.data.objects.new("Piso", datos)
        mat = bpy.data.materials.new("Arena")
        mat.use_nodes = True
        mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.84, 0.66, 0.36, 1)
        piso.data.materials.append(mat)
        sc.collection.objects.link(piso)
        for nombre, energia, color, rot in (("Sol", 4.5, (1.0, 0.95, 0.86), (50, 0, 35)),
                                            ("Relleno", 1.2, (1, 1, 1), (65, 0, -140))):
            luz = bpy.data.objects.new(nombre, bpy.data.lights.new(nombre, "SUN"))
            luz.data.energy, luz.data.color = energia, color
            luz.rotation_euler = tuple(math.radians(a) for a in rot)
            sc.collection.objects.link(luz)
    return sc


def render(objetos, archivo):
    sc = _estudio()
    bpy.context.view_layer.update()
    xs = [(o.matrix_world @ V(c)).x for o in objetos for c in o.bound_box]
    alto = max(o.dimensions.z for o in objetos)
    centro = V(((min(xs) + max(xs)) / 2, 0, alto * 0.4))
    cam = bpy.data.objects.get("Camara")
    if not cam:
        cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
        sc.collection.objects.link(cam)
    cam.data.lens = 42
    # Entra toda la fila: a 42 mm el cuadro mide ~0.86 x la distancia de ancho (más margen).
    distancia = max((max(xs) - min(xs)) / 0.86 * 1.08, 24)
    cam.location = centro + V((0, -distancia, distancia * 0.22))
    cam.rotation_euler = (centro - cam.location).to_track_quat("-Z", "Y").to_euler()
    sc.camera = cam
    sc.render.filepath = archivo
    bpy.ops.render.render(write_still=True)
