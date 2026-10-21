r"""
Lo que arma el juego al correr (no está en world/Isla.model.json) y se apoya a plateauHeight:
la isla de bloques lo deja plano. Sin bpy.
    piezas_del_juego() -> [(x, z, radio)]
    en_pieza_del_juego(x, z) -> bool
"""
import math
import isla_bloques_forma as F

# La ruleta del mundo no está en WorldLayout: client/Ambient/SpinStand.luau (ANGLE, RADIUS).
RULETA = (250, 128, 10)  # ángulo, radio y cuánto ocupa (studs)
VITRINA = 16  # studs planos alrededor de cada vitrina de traje


def piezas_del_juego():
    """(x, z, radio) de lo que arma el juego al correr y se apoya a plateauHeight: las dos
    vitrinas de los trajes (server/Social/Showcase.luau) y el puesto de la ruleta."""
    afuera = F.polar(F.L["showcaseAngle"], 1)
    costado = (-afuera[1], afuera[0])
    zonas = []
    for lado in (-1, 1):
        x = afuera[0] * F.L["showcaseRadius"] + costado[0] * F.L["showcaseSide"] * lado
        z = afuera[1] * F.L["showcaseRadius"] + costado[1] * F.L["showcaseSide"] * lado
        zonas.append((x, z, VITRINA))
    x, z = F.polar(RULETA[0], RULETA[1])
    zonas.append((x, z, RULETA[2]))
    return zonas


def en_pieza_del_juego(x, z):
    return any(math.hypot(x - px, z - pz) <= radio for px, pz, radio in piezas_del_juego())
