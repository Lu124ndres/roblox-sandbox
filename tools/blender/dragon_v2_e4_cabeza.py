r"""
Cabeza y mandíbula del anciano del dragón marino v2 (la carga dragon_v2_e4_geometria.py).

Cabeza en cuña de 6 celdas de largo (y -17..-11): cráneo de 6 de ancho, hocico de 4 cuya cara de
arriba baja 2:1 hasta la punta, que se afina en cuña, frente plana entre dos cejas marcadas que bajan hacia
adelante (ceño), ojos turquesa claro chicos y fieros bajo las cejas. La boca es una costura de lava
entre el hocico y la mandíbula (al ras del hocico y metida una celda bajo el cráneo: se ve de
costado, de frente y desde abajo) con colmillos marfil arriba y abajo. Corona de cuernos hacia
atrás, pegados a la línea de la cabeza: el par grande sale de atrás del cráneo, por fuera del
cuello, y va hacia atrás subiendo 2:1 con la punta curvada arriba; un par en las mejillas hacia
atrás y afuera, y la púa de la nuca con brasa entre los grandes. Aletitas turquesa (dos rayos) a
los lados de la mandíbula.
"""


def cabeza():
    c = "Cabeza"
    # Cráneo (z 13..16) sobre la costura de lava de la boca (z 12..13).
    bloque(c, c, "cuerpo", (-3, 3), (-14, -11), (13, 16))
    bloque(c, c, "lava", (-2, 2), (-16, -12), (12, 13))
    bloque(c, c, "lava", (-1, 1), (-17, -16), (12, 13))
    par(c, c, "marfil", (1, 2), (-17, -16), (12, 13))  # colmillos de adelante
    # Hocico en cuña: la cara de arriba baja 2:1 hacia la punta y la punta se afina en cuña 1:1
    # por los costados y por arriba.
    prisma(c, c, "cuerpo", [(-16, 13), (-14, 13), (-14, 16), (-16, 15)], (-2, 2), eje="x")
    bloque(c, c, "cuerpo", (-2, 2), (-17, -16), (13, 15), eje="y", fin="-", recorte={"x-": 1, "x+": 1, "z+": 1})
    # Cejas: cuña sobre cada ojo que baja hacia adelante (ceño); la frente plana entre ellas.
    par_prisma(c, c, "cuerpo_osc", [(-15, 15), (-13, 15), (-11, 16), (-11, 17), (-13, 17)], (2, 4), eje="x")
    # Ojos chicos: el turquesa claro con el centro casi blanco, bajo la ceja.
    par(c, c, "ojo", (3, 4), (-14, -13), (14, 15))
    par(c, c, "ojo_claro", (3, 4), (-13, -12), (14, 15))
    # Corona: cuernos grandes que salen de atrás del cráneo, por fuera del cuello, y van hacia
    # atrás subiendo apenas (2:1) con la punta curvada arriba; cuernos de las mejillas hacia atrás
    # y afuera, y la púa de la nuca.
    par_prisma(c, "Cuernos", "marfil", [(-13, 15), (-11, 15), (-9, 16), (-11, 16)], (3, 5), eje="x")
    par_prisma(c, "Cuernos", "marfil", [(-11, 16), (-9, 16), (-7, 18)], (4, 5), eje="x")
    par_prisma(c, "Cuernos", "marfil", [(3, -13), (4, -13), (6, -9), (5, -9)], (13, 14))
    espina_brasa(c, -13, 16, 2, 2, 2, 1)
    # Mandíbula: placas del vientre por debajo, la garganta de lava por dentro (se ve al abrir) y
    # colmillos que suben a los lados. Termina una celda antes del cuello y la esquina de atrás y
    # abajo va en cuña 1:1: al abrir (gira por arriba) no toca el cuello.
    m = "Mandibula"
    bloque(m, m, "vientre", (-2, 2), (-16, -14), (10, 11))
    bloque(m, m, "vientre", (-2, 2), (-14, -13), (10, 11), eje="y", recorte={"z-": 1})
    bloque(m, m, "vientre", (-2, 2), (-17, -16), (10, 11), eje="y", fin="-", recorte={"x-": 1, "x+": 1})
    bloque(m, m, "garganta", (-1, 1), (-16, -13), (11, 12))
    for y, col in (((-16, -15), "marfil"), ((-15, -14), "cuerpo"), ((-14, -13), "marfil")):
        par(m, m, col, (1, 2), y, (11, 12))
    bloque(m, m, "cuerpo", (-2, 2), (-17, -16), (11, 12), eje="y", fin="-", recorte={"x-": 1, "x+": 1})
    # Aletitas de pez a los lados de la mandíbula: dos rayos (el de atrás más oscuro).
    par_prisma(m, "Aletas", "turquesa", [(2, -16), (4, -14), (2, -14)], (10, 11))
    par_prisma(m, "Aletas", "turquesa_osc", [(2, -14), (4, -14), (5, -13), (2, -13)], (10, 11))
