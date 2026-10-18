r"""
La cara de cerca del Zorro de agua v2, etapa 2 (joven), de frente y en tres cuartos.
zorro_v2_vistas.py ya hace estas dos vistas, pero con la cámara puesta en la cara de la E3 (celdas
de 0.5 BU): en la E2 (celdas de 0.3) apunta por encima de la cabeza. Este script usa el mismo
estudio (sin correr su main) y apunta a la cara de la E2 (y -11, z 19.5 en celdas), con el encuadre
en proporción (7.5 BU en la E3 -> 4.5 en la E2). Reemplaza vistas/cara*.png.

Uso (desde la raíz del repo, después de zorro_v2_vistas.py -- --etapa 2):
    blender -b --factory-startup --python tools/blender/zorro_v2_e2_cara.py -- --etapa 2
"""
import bpy, math, os
from mathutils import Vector as V

HERE = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(HERE, "zorro_v2_vistas.py"), encoding="utf-8").read().replace("\nmain()\n", "\n"))
CELDA = 0.3


def cara():
    bpy.ops.wm.open_mainfile(filepath=BLEND)
    lo, hi = caja()
    sc, cam, sol, piso = estudio(lo, hi)
    lejos = (hi - lo).length * 2
    cam.data.type, cam.data.ortho_scale = "ORTHO", 15 * CELDA
    ojo = V((0, -11 * CELDA, 19.5 * CELDA))
    for nombre, angulo in (("cara", 0), ("cara_tres_cuartos", 35)):
        a = math.radians(angulo)
        mirar(cam, ojo + V((math.sin(a), -math.cos(a), 0.25)) * lejos, ojo)
        sol.rotation_euler = (math.radians(50), 0, a + math.radians(-35))
        sc.render.filepath = os.path.join(SALIDA, f"{nombre}.png")
        bpy.ops.render.render(write_still=True)


cara()
