r"""
Versión 7 del volcán en bloques: la v6 (volcan_entrada.py) sin hueco rectangular alrededor del
arco y con relieve en la cara que mira a la isla. La forma nueva está en volcan_relieve_forma.py.

Uso (desde la raíz del repo):
    blender -b --factory-startup --python tools/blender/volcan_relieve.py
Salidas: assets/blender/volcan_v2/volcan_bloques_4f.blend y renders en renders/volcan_v2g/.
"""
import os, random

HERE = os.path.dirname(os.path.abspath(__file__))
SOLO_FUNCIONES_CUEVA = True
__file__ = os.path.join(HERE, "volcan_cueva.py")
exec(open(__file__, encoding="utf-8").read(), globals())
for parte in ("volcan_pie_forma.py", "volcan_entrada_forma.py", "volcan_relieve_forma.py"):
    exec(open(os.path.join(HERE, parte), encoding="utf-8").read(), globals())

print("R_A", R_A, "CRATER_CENTER_ROBLOX", (0, CRATER_Z_ROBLOX))
main_cueva()
