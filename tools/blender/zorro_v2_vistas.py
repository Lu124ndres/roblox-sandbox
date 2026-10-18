r"""
Vistas del Zorro de agua v2 con la cámara más abierta: el encuadre del armador común
(minotauro_v2_bloques.py) se calcula para un cuerpo de 31 módulos de alto y corta el abanico de
colas, que es más ancho que alto. Este script no arma nada: abre el .blend que dejó el armador y
renderiza las mismas vistas con una cámara ortográfica que toma la caja entera del modelo, más una
vista de tres cuartos desde adelante a la altura de un jugador (cámara en perspectiva) y la cara
de cerca (de frente y en tres cuartos).

Uso (desde la raíz del repo; sin --etapa, la 3):
    blender -b --factory-startup --python tools/blender/zorro_v2_vistas.py -- --etapa 3
Salida: renders/zorro_v2_e<n>/vistas/*.png
"""
import bpy, math, os, sys
from mathutils import Vector as V

HERE = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.normpath(os.path.join(HERE, "..", ".."))
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
ETAPA = int(ARGS[ARGS.index("--etapa") + 1]) if "--etapa" in ARGS else 3
BLEND = os.path.join(RAIZ, "assets", "blender", "zorro_v2", f"e{ETAPA}_bloques.blend")
SALIDA = os.path.join(RAIZ, "renders", f"zorro_v2_e{ETAPA}", "vistas")
STUDS_POR_BU = 5.32
OJOS_JUGADOR = 5.0 / STUDS_POR_BU  # altura de los ojos de un jugador (BU)

# (nombre, ángulo alrededor de z desde el frente, elevación en grados)
VISTAS = (("frente", 0, 0), ("perfil", 90, 0), ("tres_cuartos", 35, 20), ("atras", 180, 0),
          ("tres_cuartos_atras", 145, 20), ("arriba", 180, 89))


def caja():
    pts = [o.matrix_world @ v.co for o in bpy.data.objects if o.type == "MESH" and "hueso" in o
           for v in o.data.vertices]
    lo = V(tuple(min(p[i] for p in pts) for i in range(3)))
    hi = V(tuple(max(p[i] for p in pts) for i in range(3)))
    return lo, hi


def estudio(lo, hi):
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 48
    sc.cycles.use_denoising = True
    sc.view_settings.view_transform = "Standard"
    sc.render.resolution_x = sc.render.resolution_y = 1000
    mundo = bpy.data.worlds.new("Estudio")
    mundo.use_nodes = True
    mundo.node_tree.nodes["Background"].inputs["Color"].default_value = (0.32, 0.36, 0.42, 1)
    mundo.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.9
    sc.world = mundo
    lado = (hi - lo).length * 3
    bpy.ops.mesh.primitive_plane_add(size=lado, location=(0, 0, 0))
    piso = bpy.context.active_object
    piso.data.materials.append(bpy.data.materials.new("Piso"))
    piso.data.materials[0].diffuse_color = (0.3, 0.33, 0.36, 1)
    sol = bpy.data.objects.new("Sol", bpy.data.lights.new("Sol", "SUN"))
    sol.data.energy, sol.data.angle = 3.2, math.radians(8)
    sc.collection.objects.link(sol)
    cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
    cam.data.clip_end = lado * 4
    sc.collection.objects.link(cam)
    sc.camera = cam
    return sc, cam, sol, piso


def mirar(cam, desde, hacia):
    cam.location = desde
    cam.rotation_euler = (hacia - desde).to_track_quat("-Z", "Y").to_euler()


def main():
    bpy.ops.wm.open_mainfile(filepath=BLEND)
    os.makedirs(SALIDA, exist_ok=True)
    lo, hi = caja()
    centro, tam = (lo + hi) / 2, hi - lo
    sc, cam, sol, piso = estudio(lo, hi)
    lejos = tam.length * 2
    for nombre, angulo, elev in VISTAS:
        a, e = math.radians(angulo), math.radians(elev)
        direccion = V((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e)))
        cam.data.type = "ORTHO"
        # Lo que ocupa el modelo visto desde ahí (la caja proyectada), con margen.
        ancho = abs(math.cos(a)) * tam.x + abs(math.sin(a)) * tam.y
        alto = tam.z * math.cos(e) + (abs(math.sin(a)) * tam.x + abs(math.cos(a)) * tam.y) * abs(math.sin(e))
        cam.data.ortho_scale = max(ancho, alto) * 1.08
        mirar(cam, centro + direccion * lejos, centro)
        sol.rotation_euler = (math.radians(50), 0, a + math.radians(-35))
        piso.hide_render = elev > 80
        sc.render.filepath = os.path.join(SALIDA, f"{nombre}.png")
        bpy.ops.render.render(write_still=True)
    # Un jugador parado adelante y a la izquierda del zorro, mirándolo hacia arriba.
    cam.data.type, cam.data.lens = "PERSP", 18
    ojo = V((0.45 * tam.x, lo.y - 0.3 * tam.y, OJOS_JUGADOR))
    mirar(cam, ojo, V((0, centro.y, tam.z * 0.45)))
    sol.rotation_euler = (math.radians(50), 0, math.radians(-10))
    piso.hide_render = False
    sc.render.filepath = os.path.join(SALIDA, "jugador.png")
    bpy.ops.render.render(write_still=True)
    # La cara de cerca: de frente y en tres cuartos (centro en el ojo, medidas en celdas de 0.5).
    cam.data.type, cam.data.ortho_scale = "ORTHO", 7.5
    ojo = V((0, -12 * 0.5, 19.5 * 0.5))
    for nombre, angulo in (("cara", 0), ("cara_tres_cuartos", 35)):
        a = math.radians(angulo)
        mirar(cam, ojo + V((math.sin(a), -math.cos(a), 0.25)) * lejos, ojo)
        sol.rotation_euler = (math.radians(50), 0, a + math.radians(-35))
        sc.render.filepath = os.path.join(SALIDA, f"{nombre}.png")
        bpy.ops.render.render(write_still=True)


main()
