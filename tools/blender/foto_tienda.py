r"""
Foto de un gigante v2 con fondo transparente para íconos y miniaturas de la página del juego
(publicar/tienda/). Abre el <criatura>_v2/e<n>_rig.blend en reposo, pone una cámara en perspectiva
desde abajo (se ve más grande), luz de frente, contraluz y relleno, y renderiza un PNG RGBA.

Uso (desde la raíz del repo):
    blender -b assets/blender/zorro_v2/e4_rig.blend --python tools/blender/foto_tienda.py -- \
        --salida publicar/tienda/fuentes/zorro_e4.png --angulo 30 --elev 8 --lente 50
--angulo: 0 = de frente, positivo = gira hacia la izquierda del modelo. --elev en grados.
No guarda el .blend.
"""
import bpy, math, os, sys
from mathutils import Vector


def argumento(nombre, defecto):
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    return type(defecto)(a[a.index(nombre) + 1]) if nombre in a else defecto


SALIDA = argumento("--salida", "foto.png")
ANGULO = math.radians(argumento("--angulo", 30.0))
ELEV = math.radians(argumento("--elev", 8.0))
LENTE = argumento("--lente", 50.0)
LADO = argumento("--lado", 1600)

sc = bpy.context.scene
mallas = []
for o in sc.objects:
    if o.type == "MESH":
        # el piso del estudio no va: solo las piezas que mueve el rig
        o.hide_render = not (o.parent and o.parent.type == "ARMATURE")
        if not o.hide_render:
            mallas.append(o)
pts = [o.matrix_world @ Vector(c) for o in mallas for c in o.bound_box]
lo = Vector([min(p[i] for p in pts) for i in range(3)])
hi = Vector([max(p[i] for p in pts) for i in range(3)])
centro, tam = (lo + hi) / 2, (hi - lo).length

# El frente de los modelos es -y en Blender (Rig.bind: frente -Z de Roblox)
d = Vector((math.sin(ANGULO) * math.cos(ELEV), -math.cos(ANGULO) * math.cos(ELEV), math.sin(ELEV)))
cam = sc.camera or bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
cam.data.type = "PERSP"
cam.data.lens = LENTE
mitad = math.atan(18 / LENTE)  # medio ángulo de visión con sensor de 36 mm
cam.location = centro + d * (tam / 2) / math.tan(mitad) * 1.05
cam.data.clip_end = tam * 10
cam.rotation_euler = (centro - cam.location).to_track_quat("-Z", "Y").to_euler()
sc.camera = cam


def luz(nombre, tipo, energia, giro, color=(1, 1, 1)):
    ob = bpy.data.objects.get(nombre)
    if ob is None:
        ob = bpy.data.objects.new(nombre, bpy.data.lights.new(nombre, tipo))
        sc.collection.objects.link(ob)
    ob.data.energy, ob.data.color = energia, color
    ob.rotation_euler = giro


luz("Sol", "SUN", 4.0, (math.radians(50), 0, ANGULO - math.radians(35)))
luz("Contraluz", "SUN", 3.0, (math.radians(-60), 0, ANGULO + math.radians(20)), (0.75, 0.9, 1.0))
luz("Relleno", "SUN", 1.0, (math.radians(70), 0, ANGULO + math.radians(60)), (1.0, 0.92, 0.8))

sc.render.film_transparent = True
sc.render.resolution_x = sc.render.resolution_y = LADO
sc.render.image_settings.file_format = "PNG"
sc.render.image_settings.color_mode = "RGBA"
sc.cycles.samples = 64
sc.view_settings.view_transform = "Standard"
sc.render.filepath = os.path.abspath(SALIDA)
bpy.ops.render.render(write_still=True)
print("FOTO", SALIDA)
