r"""
Versión 6 del volcán en bloques: la v5 (volcan_pie.py) con la entrada asimétrica (peñasco de un
lado, escalones y rocas caídas del otro, espolón corrido) y el túnel menos uniforme. La forma
nueva está en volcan_entrada_forma.py.

Uso (desde la raíz del repo):
    blender -b --factory-startup --python tools/blender/volcan_entrada.py
Salidas: assets/blender/volcan_v2/volcan_bloques_4e.blend y renders en renders/volcan_v2f/.
"""
import os, random

HERE = os.path.dirname(os.path.abspath(__file__))
SOLO_FUNCIONES_CUEVA = True
__file__ = os.path.join(HERE, "volcan_cueva.py")
exec(open(__file__, encoding="utf-8").read(), globals())
exec(open(os.path.join(HERE, "volcan_pie_forma.py"), encoding="utf-8").read(), globals())
exec(open(os.path.join(HERE, "volcan_entrada_forma.py"), encoding="utf-8").read(), globals())

print("R_A", R_A, "CRATER_CENTER_ROBLOX", (0, CRATER_Z_ROBLOX))
main_cueva()
