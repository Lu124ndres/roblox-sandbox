r"""
La cara de cerca del Zorro de agua v2, etapa 1 (cría). zorro_v2_vistas.py centra las vistas
"cara" y "cara_tres_cuartos" en el ojo de la E3 (celdas de 0.5 BU): en la E1 quedan vacías. Este
script usa su estudio y su cámara (sin correr su main) y las vuelve a hacer con las medidas de la
cría: centro en el ojo (y -16, z 21.5 celdas de 0.1) y un encuadre de 20 celdas (la cabeza mide 12
de ancho). Se corre después de zorro_v2_vistas.py y pisa esas dos imágenes.

Uso (desde la raíz del repo; el .blend lo deja minotauro_v2_bloques.py --criatura zorro --etapa 1):
    blender -b --factory-startup --python tools/blender/zorro_v2_e1_cara.py
Salida: renders/zorro_v2_e1/vistas/cara.png y cara_tres_cuartos.png
"""
import bpy, math, os, sys
from mathutils import Vector as V

HERE = os.path.dirname(os.path.abspath(__file__))
sys.argv += ["--", "--etapa", "1"] if "--" not in sys.argv else ["--etapa", "1"]
exec(open(os.path.join(HERE, "zorro_v2_vistas.py"), encoding="utf-8").read().replace("\nmain()\n", "\n"))
CELDA = 0.1


def cara():
    bpy.ops.wm.open_mainfile(filepath=BLEND)
    lo, hi = caja()
    sc, cam, sol, piso = estudio(lo, hi)
    lejos = (hi - lo).length * 2
    cam.data.type, cam.data.ortho_scale = "ORTHO", 20 * CELDA
    ojo = V((0, -16 * CELDA, 21.5 * CELDA))
    for nombre, angulo in (("cara", 0), ("cara_tres_cuartos", 35)):
        a = math.radians(angulo)
        mirar(cam, ojo + V((math.sin(a), -math.cos(a), 0.25)) * lejos, ojo)
        sol.rotation_euler = (math.radians(50), 0, a + math.radians(-35))
        sc.render.filepath = os.path.join(SALIDA, f"{nombre}.png")
        bpy.ops.render.render(write_still=True)


cara()
