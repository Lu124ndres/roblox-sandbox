r"""
Cabeza y mandíbula de la cría del dragón marino v2 (la carga dragon_v2_e1_geometria.py).

Vista de perfil, en celdas (-y = hocico, z arriba):
  - Cráneo de 6 de ancho (x -3..3, y -13..-9, z 17..22), frente plana.
  - Hocico más angosto (4) que baja en cuña desde la frente (1:1) y termina en punta (1:2), con
    las narinas oscuras arriba y la boca roja con un colmillito marfil a cada lado.
  - Ojos turquesa grandes (3 x 3) a los costados, con la pupila en rendija y un brillo; la ceja
    en cuña encima (la cara fiera de la referencia, en cría).
  - Cuernitos marfil que salen de atrás del cráneo hacia atrás, pegados a la línea de la cabeza.
  - Aletitas turquesa de pez (dos rayos) en las mejillas, debajo de los ojos.
  - Mandíbula: placa de brasa abajo (garganta), boca y colmillitos arriba; termina una celda
    antes del cuello y la esquina de atrás y abajo va en cuña 1:1 (al abrir no toca el cuello).
"""


def cabeza():
    c = "Cabeza"
    # Cráneo con la capa de abajo partida: boca en el medio.
    bloque(c, c, "cuerpo", (-3, 3), (-13, -9), (18, 22))
    par(c, c, "cuerpo", (1, 3), (-13, -9), (17, 18))
    bloque(c, c, "boca", (-1, 1), (-13, -9), (17, 18))
    # Hocico: baja de la frente en cuña 1:1 y termina en punta 1:2.
    bloque(c, c, "cuerpo", (-2, 2), (-15, -13), (18, 20))
    prisma(c, c, "cuerpo", [(-15, 20), (-13, 20), (-13, 22)], (-2, 2), eje="x")
    bloque(c, c, "cuerpo", (-2, 2), (-17, -15), (18, 20), eje="y", fin="-",
           recorte={"x-": 1, "x+": 1, "z+": 1})
    par(c, c, "cuerpo_osc", (1, 2), (-16, -15), (19, 20))  # narinas
    # Boca: la línea roja de la sonrisa con un colmillito a cada lado.
    bloque(c, c, "boca", (-2, 2), (-17, -15), (17, 18), eje="y", fin="-", recorte={"x-": 1, "x+": 1})
    bloque(c, c, "boca", (-1, 1), (-15, -13), (17, 18))
    par(c, c, "garra", (1, 2), (-15, -14), (17, 18))
    par(c, c, "boca", (1, 2), (-14, -13), (17, 18))
    # Ojos (3 x 3): pupila en rendija y brillo arriba y atrás.
    par(c, c, "ojo", (3, 4), (-13, -12), (18, 21))
    par(c, c, "pupila", (3, 4), (-12, -11), (18, 20))
    par(c, c, "ojo", (3, 4), (-12, -11), (20, 21))
    par(c, c, "ojo", (3, 4), (-11, -10), (18, 20))
    par(c, c, "brillo", (3, 4), (-11, -10), (20, 21))
    # Ceja en cuña sobre cada ojo y cuernitos hacia atrás.
    par_prisma(c, c, "cuerpo_osc", [(-14, 21), (-9, 21), (-9, 22), (-13, 22)], (3, 4), eje="x")
    par_prisma(c, c, "garra", [(-11, 22), (-9, 22), (-5, 24), (-9, 24), (-11, 23)], (2, 3), eje="x")
    # Aletitas de las mejillas: dos rayos hacia atrás y afuera.
    par_prisma(c, "Aletas", "turquesa", [(3, -12), (5, -11), (3, -11)], (17, 18))
    par_prisma(c, "Aletas", "turquesa", [(3, -11), (4, -11), (6, -9), (3, -9)], (17, 18))
    # Mandíbula.
    m = "Mandibula"
    bloque(m, m, "vientre", (-2, 2), (-15, -12), (15, 16))
    par(m, m, "cuerpo", (1, 2), (-15, -14), (16, 17))
    par(m, m, "cuerpo", (1, 2), (-13, -12), (16, 17))
    bloque(m, m, "boca", (-1, 1), (-15, -12), (16, 17))
    par(m, m, "garra", (1, 2), (-14, -13), (16, 17))
    bloque(m, m, "cuerpo", (-2, 2), (-12, -11), (15, 17), eje="y", recorte={"z-": 1})
    bloque(m, m, "vientre", (-2, 2), (-17, -15), (15, 16), eje="y", fin="-", recorte={"x-": 1, "x+": 1})
    bloque(m, m, "boca", (-2, 2), (-17, -15), (16, 17), eje="y", fin="-", recorte={"x-": 1, "x+": 1})
