r"""
Versión 5 del volcán en bloques: la montaña entera con la copa de lava y la cueva de la v4, y
el arco al pie del lado de la isla con un túnel largo hasta la cueva (la forma está en
volcan_pie_forma.py). La isla se aleja: el arco queda donde está hoy respecto de ella y el
puente mide lo mismo. Imprime el nuevo craterCenter.

Uso (desde la raíz del repo):
    blender -b --factory-startup --python tools/blender/volcan_pie.py
Salidas: assets/blender/volcan_v2/volcan_bloques_4d.blend y renders en renders/volcan_v2e/.
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
SOLO_FUNCIONES_CUEVA = True
__file__ = os.path.join(HERE, "volcan_cueva.py")  # volcan_cueva.py busca a sus vecinos desde acá
exec(open(__file__, encoding="utf-8").read(), globals())
exec(open(os.path.join(HERE, "volcan_pie_forma.py"), encoding="utf-8").read(), globals())

print("R_A", R_A, "CRATER_CENTER_ROBLOX", (0, CRATER_Z_ROBLOX), "TUNEL",
      R_A - ARCO_HONDO - (WALK_END - 6))
main_cueva()
