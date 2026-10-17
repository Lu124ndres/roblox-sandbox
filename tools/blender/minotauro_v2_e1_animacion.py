r"""
Los trucos del Minotauro v2 E1 en video, con las poses que calcula el código del juego.

Las poses salen de Studio: los módulos de src/shared/Minotauro corridos en Edit por el MCP
(Pose.idle + el truco + Cuerpo.plant + Resortes, cuadro a cuadro a 60 por segundo y guardados
a 30), en un JSON {"keys": [...], "fps": 30, "trucos": {nombre: {"frames": [[...], ...]}}}.
Aquí se ponen en el rig de assets/blender/minotauro_v2/e1_rig.blend con la misma cuenta que
Pose.apply y Rig.turn (cabeceo por la derecha del cuerpo, giro por arriba, alabeo por
adelante, en los ejes de reposo de cada hueso), se sube el cuerpo con dy y se arma un GIF por
truco con ffmpeg.

Uso (desde la raíz del repo):
    blender -b --factory-startup --python tools/blender/minotauro_v2_e1_animacion.py -- <poses.json>
Las poses de la última revisión están en renders/minotauro_v2_e1/animaciones/poses_juego.json
(etapa 1, con el código del commit que las acompaña).
Salida: renders/minotauro_v2_e1/animaciones/<truco>.gif
"""
import bpy, json, math, os, shutil, subprocess, sys, tempfile
from mathutils import Matrix, Vector as V

HERE = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.normpath(os.path.join(HERE, "..", ".."))
BLEND = os.path.join(RAIZ, "assets", "blender", "minotauro_v2", "e1_rig.blend")
SALIDA = os.path.join(RAIZ, "renders", "minotauro_v2_e1", "animaciones")
POSES = sys.argv[sys.argv.index("--") + 1]
ALTO = 16.5  # studs: el rig ya está escalado
CAMARA = {"Pisoton": -35, "Salto": -70}  # grados alrededor del cuerpo (0 = de frente); 35 si no está
LADO = 400


def giros(p):
    """Pose.apply: hueso -> (cabeceo, giro, alabeo)."""
    v = lambda k: p.get(k, 0.0)
    lean, breathe, sway = v("lean"), v("breathe"), v("sway")
    r = {
        "Cadera": (0, 0, sway),
        "Columna": (lean * 0.5 + breathe, 0, -sway * 0.5),
        "Pecho": (lean * 0.5 + breathe * 0.6, v("lookYaw") * 0.2, 0),
        "Cuello": (v("lookPitch") * 0.4, v("lookYaw") * 0.35, v("tilt") * 0.3),
        "Cabeza": (v("lookPitch") * 0.6 - breathe * 0.5, v("lookYaw") * 0.45, v("tilt") * 0.7),
        "Mandibula": (-0.5 * min(max(v("jaw"), 0), 1.2), 0, 0),
        "FaldonFrente": (v("faldonF"), 0, 0),
        "Cola1": (-v("tailUp"), v("tail1"), 0),
        "Cola2": (-v("tailUp") * 0.5, v("tail2"), 0),
        "Cola3": (0, v("tail3"), 0),
    }
    for s, l, afuera in (("L", "Izq", 1), ("R", "Der", -1)):  # afuera = -(rig.side)
        knee = v("knee" + s)
        r["Oreja" + l] = (0, 0, v("ear" + s) * afuera)
        r["Brazo" + l] = (v("arm" + s), 0, v("out" + s) * afuera)
        r["Antebrazo" + l] = (v("elbow" + s), 0, v("elbowOut" + s) * afuera)
        r["Mano" + l] = (v("elbow" + s) * 0.2, 0, 0)
        r["Muslo" + l] = (v("leg" + s), 0, 0)
        r["Pierna" + l] = (-knee, 0, 0)
        r["Pie" + l] = (knee * 0.5 - v("leg" + s) * 0.4, 0, 0)
        r["Faldon" + l] = (0, 0, v("faldon" + s) * afuera)
    return r


def posar(arm, p):
    """Rig.turn en los ejes del cuerpo (derecha = -x, arriba = z, adelante = -y)."""
    r = giros(p)
    for pb in arm.pose.bones:
        a, g, b = r.get(pb.name, (0, 0, 0))
        mundo = Matrix.Rotation(-a, 4, "X") @ Matrix.Rotation(g, 4, "Z") @ Matrix.Rotation(-b, 4, "Y")
        base = pb.bone.matrix_local.to_3x3().to_4x4()
        pb.matrix_basis = base.inverted() @ mundo @ base
    arm.location.z = p.get("dy", 0.0) * ALTO


def escena():
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sc.display.shading.light = "STUDIO"
    sc.display.shading.color_type = "TEXTURE"
    sc.display.shading.show_shadows = True
    sc.display.shading.shadow_intensity = 0.4
    sc.render.resolution_x = sc.render.resolution_y = LADO
    sc.view_settings.view_transform = "Standard"
    mundo = bpy.data.worlds.new("Fondo")
    mundo.color = (0.32, 0.36, 0.42)
    sc.world = mundo
    bpy.ops.mesh.primitive_plane_add(size=60, location=(0, 0, 0))
    cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
    cam.data.type, cam.data.ortho_scale = "ORTHO", 26
    sc.collection.objects.link(cam)
    sc.camera = cam
    return sc, cam


def apuntar(cam, grados):
    centro = V((0, 0, 10))
    a = math.radians(grados)
    cam.location = centro + V((math.sin(a) * 60, -math.cos(a) * 60, 18))
    cam.rotation_euler = (centro - cam.location).to_track_quat("-Z", "Y").to_euler()


def gif(cuadros, fps, destino):
    filtro = (f"fps={fps},scale={LADO}:-1:flags=lanczos,split[a][b];"
              "[a]palettegen=max_colors=96[p];[b][p]paletteuse=dither=bayer:bayer_scale=4")
    subprocess.run([shutil.which("ffmpeg"), "-y", "-loglevel", "error", "-framerate", str(fps), "-i",
                    os.path.join(cuadros, "c_%04d.png"), "-vf", filtro, destino], check=True)


bpy.ops.wm.open_mainfile(filepath=BLEND)
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
datos = json.load(open(POSES, encoding="utf-8"))
claves = datos["keys"]
sc, cam = escena()
os.makedirs(SALIDA, exist_ok=True)
hechos = {}
for nombre, truco in datos["trucos"].items():
    apuntar(cam, CAMARA.get(nombre, 35))
    with tempfile.TemporaryDirectory() as tmp:
        for i, fila in enumerate(truco["frames"]):
            posar(arm, dict(zip(claves, fila)))
            sc.render.filepath = os.path.join(tmp, f"c_{i:04d}.png")
            bpy.ops.render.render(write_still=True)
        gif(tmp, datos["fps"], os.path.join(SALIDA, nombre.lower() + ".gif"))
    hechos[nombre] = len(truco["frames"])
print("ANIMACION", json.dumps(hechos))
