"""
Vistas y poses del Marinero v2 para revisarlo antes de llevarlo a Studio: frente, perfil, tres
cuartos y atrás en reposo, y poses extremas (caminar, brazos arriba, sentado, la caña y
saludar) para ver que no se abra ni se estire en las articulaciones.

Cada pose gira los huesos igual que el juego (src/client/Trajes/Rig.luau): un giro D en el
espacio del personaje, respecto del padre, se aplica al hueso como R⁻¹·D·R (R = su reposo).
Ejes del personaje: +X su izquierda, -Y su frente, +Z arriba.

Uso (desde la raíz del repo, después de marinero_v2.py):
    blender -b --factory-startup --python tools/blender/marinero_v2_vistas.py
Salida: renders/marinero_v2/*.png
"""
import bpy, math, os
from mathutils import Quaternion, Vector as V

HERE = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.normpath(os.path.join(HERE, "..", ".."))
BLEND = os.path.join(RAIZ, "assets", "blender", "marinero_v2", "marinero_v2.blend")
SALIDA = os.path.join(RAIZ, "renders", "marinero_v2")
X, Y, Z = V((1, 0, 0)), V((0, 1, 0)), V((0, 0, 1))

# Pose: hueso -> lista de (eje, grados). Adelante es girar en -X (brazos y piernas).
POSES = {
    "reposo": {},
    "caminar": {"BrazoIzq": [(X, 40)], "BrazoDer": [(X, -40)], "CodoDer": [(X, -20)],
                "PiernaIzq": [(X, -40)], "PiernaDer": [(X, 40)], "RodillaDer": [(X, 35)]},
    "brazos_arriba": {"BrazoIzq": [(Y, -165)], "BrazoDer": [(Y, 165)]},
    "sentado": {"PiernaIzq": [(X, -90)], "PiernaDer": [(X, -90)], "RodillaIzq": [(X, 90)],
                "RodillaDer": [(X, 90)], "BrazoIzq": [(X, -30)], "BrazoDer": [(X, -30)]},
    "agachado": {"PiernaIzq": [(X, -60)], "PiernaDer": [(X, -60)], "RodillaIzq": [(X, 80)],
                 "RodillaDer": [(X, 80)], "BrazoIzq": [(X, -20)], "CodoIzq": [(X, -90)],
                 "BrazoDer": [(X, -20)], "CodoDer": [(X, -90)]},
    "cana": {"BrazoDer": [(X, -75)], "CodoDer": [(X, -25)], "Pecho": [(Z, 12)], "Cabeza": [(X, 10)]},
    "saludo": {"BrazoIzq": [(Y, -150)], "CodoIzq": [(Y, -40)], "Cabeza": [(Z, -20)]},
}
# (archivo, pose, ángulo alrededor de z desde el frente, elevación)
TOMAS = [("frente", "reposo", 0, 0), ("perfil", "reposo", 90, 0), ("tres_cuartos", "reposo", 35, 15),
         ("atras", "reposo", 180, 0), ("caminar_perfil", "caminar", 90, 0),
         ("caminar_tres_cuartos", "caminar", -40, 15), ("caminar_atras", "caminar", 150, 10),
         ("brazos_arriba", "brazos_arriba", 20, 10), ("sentado", "sentado", 60, 10),
         ("sentado_perfil", "sentado", 90, 0), ("agachado", "agachado", 60, 10),
         ("agachado_perfil", "agachado", 90, 0),
         ("cana", "cana", -35, 10), ("saludo", "saludo", 25, 5)]


def posar(rig, pose):
    for pb in rig.pose.bones:
        pb.rotation_mode = "QUATERNION"
        q = Quaternion()
        for eje, grados in pose.get(pb.name, []):
            q = Quaternion(eje, math.radians(grados)) @ q
        rest = pb.bone.matrix_local.to_quaternion()
        pb.rotation_quaternion = rest.inverted() @ q @ rest
    bpy.context.view_layer.update()


def estudio():
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 32
    sc.cycles.use_denoising = True
    sc.view_settings.view_transform = "Standard"
    sc.render.resolution_x, sc.render.resolution_y = 700, 900
    mundo = bpy.data.worlds.new("Estudio")
    mundo.use_nodes = True
    fondo = mundo.node_tree.nodes["Background"]
    fondo.inputs["Color"].default_value = (0.32, 0.36, 0.42, 1)
    fondo.inputs["Strength"].default_value = 0.9
    sc.world = mundo
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0))
    piso = bpy.context.active_object
    piso.data.materials.append(bpy.data.materials.new("Piso"))
    piso.data.materials[0].diffuse_color = (0.3, 0.33, 0.36, 1)
    sol = bpy.data.objects.new("Sol", bpy.data.lights.new("Sol", "SUN"))
    sol.data.energy, sol.data.angle = 3.2, math.radians(8)
    sc.collection.objects.link(sol)
    cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
    cam.data.type, cam.data.ortho_scale = "ORTHO", 7.6
    sc.collection.objects.link(cam)
    sc.camera = cam
    return sc, cam, sol


def main():
    bpy.ops.wm.open_mainfile(filepath=BLEND)
    os.makedirs(SALIDA, exist_ok=True)
    rig = bpy.data.objects["RigMarinero"]
    sc, cam, sol = estudio()
    centro = V((0, 0, 2.9))
    for archivo, pose, angulo, elev in TOMAS:
        posar(rig, POSES[pose])
        a, e = math.radians(angulo), math.radians(elev)
        direccion = V((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e)))
        cam.location = centro + direccion * 20
        cam.rotation_euler = (-direccion).to_track_quat("-Z", "Y").to_euler()
        sol.rotation_euler = (math.radians(50), 0, a - math.radians(35))
        sc.render.filepath = os.path.join(SALIDA, f"{archivo}.png")
        bpy.ops.render.render(write_still=True)


main()
