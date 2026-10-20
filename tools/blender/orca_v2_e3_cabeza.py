r"""
Cabeza de la Orca v2, etapa 3 (adulto): cráneo, hocico, cuencas de los ojos (la pupila la pone
el código del juego) con cejas de enojo, la mancha de orca
en cian y la boca abierta con dos filas de dientes. Lo carga orca_v2_e3_geometria.py con exec; usa
bloque(), par() (de minotauro_v2_bloques.py) y prisma(), par_prisma() (de dragon_v2_formas.py).
Todo en celdas.

La boca queda bien abierta en reposo (z 6..11, un tercio de la cabeza, como en la referencia):
los dientes de arriba bajan hasta z 9 y los de abajo suben hasta z 8, intercalados para que no se
crucen. Por dentro es roja: el paladar, la pared del fondo y el piso de la mandíbula. Los dientes
van apoyados (no metidos) en el borde de la quijada: metidos, su costado quedaría en el plano del
costado del hocico.
"""


def cabeza():
    c = "Cabeza"
    # Hocico romo, una celda más angosto que el cráneo, con el borde de arriba en cuña.
    bloque(c, c, "cuerpo", (-6, 6), (-31, -27), (11, 14))
    bloque(c, c, "cuerpo", (-6, 6), (-31, -27), (14, 16), recorte={"y-": 1})
    # Cráneo con los bordes de arriba achaflanados y la placa de la frente.
    bloque(c, c, "cuerpo", (-7, 7), (-27, -16), (11, 16))
    bloque(c, c, "cuerpo", (-7, 7), (-27, -16), (16, 17), recorte={"x-": 1, "x+": 1})
    bloque(c, c, "placa", (-5, 5), (-26, -17), (17, 18), recorte={"y-": 1})
    # Mejillas: cierran la boca atrás, bajo los ojos.
    bloque(c, c, "cuerpo", (-7, 7), (-21, -16), (6, 11))
    # Por dentro, roja: la pared del fondo y el paladar.
    bloque(c, c, "boca", (-5, 5), (-22, -21), (6, 11))
    bloque(c, c, "boca", (-5, 5), (-29, -22), (10, 11))
    cuencas(c)
    # Ceja de enojo: baja hacia adentro.
    par_prisma(c, c, "ceja", [(5, 14), (8, 14), (8, 16), (7, 16)], (-29, -24), eje="y")
    # La mancha de orca, en cian, detrás del ojo y subiendo hacia atrás.
    par_prisma(c, c, "brillo", [(-24, 12), (-21, 12), (-17, 14), (-17, 15), (-20, 15), (-24, 13)],
               (7, 8), eje="x")
    dientes_arriba(c)
    mandibula()


def cuencas(c):
    """La cuenca de cada ojo: una sola cara oscura, rasgada (2 de alto), que mira afuera y adelante
    en cuña 1:1 (x - y = 35), para que la pupila de Neon que pone el código se vea de frente y de
    costado. Va hundida en un marco que asoma una celda como la ceja: la ceja arriba, la mejilla
    abajo (z 11..12), el poste de atrás y, del lado de adentro, el costado del hocico. Las caras
    de la cuenca que no son la del ojo quedan tapadas por el marco, el cráneo y el hocico."""
    par_prisma(c, c, "cuenca", [(6, -29), (8, -27), (6, -27)], (12, 14))
    par(c, c, "cuerpo", (7, 8), (-27, -24), (12, 14))  # poste de atrás
    par(c, c, "cuerpo", (7, 8), (-29, -24), (11, 12))  # mejilla, y su punta junto al hocico
    par(c, c, "cuerpo", (6, 7), (-29, -27), (11, 12))


def _diente(arriba, a):
    """Triángulo de 2 de ancho y 2 de alto: cuelga de z 11 o sube desde z 6."""
    if arriba:
        return [(a, 11), (a + 2, 11), (a + 1, 9)]
    return [(a, 6), (a + 2, 6), (a + 1, 8)]


def dientes_arriba(c):
    for a in (1, 4):  # adelante, una celda detrás de la cara del hocico
        par_prisma(c, c, "diente", _diente(True, a), (-30, -29), eje="y")
    for a in (-29, -25):  # a los costados, al ras del hocico
        par_prisma(c, c, "diente", _diente(True, a), (5, 6), eje="x")


def mandibula():
    m = "Mandibula"
    # Quijada blanca con el borde de abajo achaflanado; termina en la garganta (y -18).
    bloque(m, m, "blanco", (-6, 6), (-30, -18), (3, 5))
    bloque(m, m, "blanco", (-6, 6), (-30, -18), (2, 3), fin="-", recorte={"x-": 1, "x+": 1})
    # Borde blanco (los costados y adelante) y el piso rojo con la lengua.
    par(m, m, "blanco", (5, 6), (-30, -18), (5, 6))
    bloque(m, m, "blanco", (-5, 5), (-30, -28), (5, 6))
    bloque(m, m, "boca", (-5, 5), (-28, -18), (5, 6))
    bloque(m, m, "lengua", (-3, 3), (-26, -20), (6, 7))
    # Dientes de abajo, entre los de arriba.
    prisma(m, m, "diente", _diente(False, -1), (-29, -28), eje="y")
    par_prisma(m, m, "diente", _diente(False, 2), (-29, -28), eje="y")
    for b in (-27, -23):
        par_prisma(m, m, "diente", _diente(False, b), (5, 6), eje="x")
