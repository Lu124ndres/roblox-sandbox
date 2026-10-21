r"""
Adornos de la Orca v2, etapa 4 (anciana): púas en hilera doble, arpones viejos con cabos rotos,
la herida con costillas, cicatrices, costras de percebes y algas largas. Lo carga
orca_v2_e4_geometria.py con exec; usa bloque() (de minotauro_v2_bloques.py) y prisma(),
par_prisma() (de dragon_v2_formas.py). Todo en celdas.

Cada adorno va en la pieza que lo lleva (el arpón en el anillo donde está clavado, la púa en su
anillo) y apoyado encima de su cara, no metido: así no comparte plano con ella. Los que se tocan
lo hacen cara con cara (normales opuestas). Lo asimétrico (arpones, herida, cicatrices, costras)
va repartido a los dos lados, con lo más grande a la izquierda, que es la que muestran los renders.
"""


def _pua(parte, col, y0, z0, x=None, alta=True):
    """Púa en garfio echada hacia atrás: pie de 2 en z0 y la punta 2 celdas detrás del pie,
    4 arriba (2 si no es alta). x = (desde, hasta): un par; sin x, una en el medio (x -1..1)."""
    pol = [(y0, z0), (y0 + 2, z0), (y0 + 4, z0 + (4 if alta else 2))]
    if x:
        par_prisma(parte, col, "pua", pol, x, eje="x")
    else:
        prisma(parte, col, "pua", pol, (-1, 1), eje="x")


def puas():
    # Hilera doble sobre las placas del lomo, de la frente a la cola (una sola en los anillos
    # finos). Cada pie va sobre una placa, nunca sobre una grieta.
    for y0 in (-25, -20):
        _pua("Cabeza", "Cabeza", y0, 19, (2, 4), alta=False)
    # Junto a la dorsal (y -10..8) son bajas, para que ella siga siendo lo más alto del lomo.
    for parte, z0, ys in (("Pecho", 20, (-15, -11, -7)), ("Cola1", 19, (-3, 1)), ("Cola2", 18, (6, 10))):
        for y0 in ys:
            _pua(parte, "Torso", y0, z0, (2, 4), alta=not -12 < y0 < 8)
    _pua("Cola3", "Torso", 14, 17, (1, 3))
    _pua("Cola4", "Torso", 19, 16)
    _pua("Cola5", "Torso", 24, 15)


def arpones():
    t, p = "Torso", "Pecho"
    # El grande, en el Pecho a la izquierda: el asta echada hacia atrás 2:1, un anillo de óxido y
    # el cabo que baja por el costado hasta deshilacharse.
    prisma(p, t, "arpon", [(-10, 18), (-9, 18), (-5, 26), (-6, 26)], (6, 7), eje="x")
    bloque(p, t, "oxido", (5, 8), (-9, -6), (22, 23))
    prisma(p, t, "cabo", [(6, 22), (7, 22), (9, 18), (8, 18)], (-7, -6), eje="y")
    bloque(p, t, "cabo", (8, 9), (-7, -6), (12, 18))
    bloque(p, t, "cabo", (8, 9), (-8, -7), (10, 13))
    # En la Cola1 a la derecha, echado hacia adelante, con el cabo roto colgando.
    c = "Cola1"
    prisma(c, t, "arpon", [(4, 17), (5, 17), (2, 23), (1, 23)], (-6, -5), eje="x")
    bloque(c, t, "oxido", (-7, -4), (2, 4), (20, 21))
    bloque(c, t, "cabo", (-8, -7), (2, 3), (14, 21))
    bloque(c, t, "cabo", (-8, -7), (3, 4), (12, 15))
    # En la Cola2 a la izquierda, el asta partida: astilla de óxido arriba y la vuelta de cabo
    # en la base, con la punta que cuelga.
    c = "Cola2"
    prisma(c, t, "arpon", [(9, 16), (10, 16), (12, 20), (11, 20)], (5, 6), eje="x")
    prisma(c, t, "oxido", [(11, 20), (12, 20), (12, 21)], (5, 6), eje="x")
    bloque(c, t, "cabo", (4, 7), (10, 12), (18, 19))
    bloque(c, t, "cabo", (6, 7), (11, 12), (13, 18))


def herida():
    # Herida vieja en la Cola1, a la izquierda: la placa del medio es carne (anillo(), herida=) y
    # encima asoman tres costillas que bajan hacia adelante.
    for y in (-3, -1, 1):
        prisma("Cola1", "Torso", "hueso", [(y, 8), (y + 1, 8), (y + 3, 12), (y + 2, 12)], (7, 8), eje="x")


def cicatrices():
    t = "Torso"
    # Tres zarpazos paralelos en el Pecho, a la izquierda, sobre las placas de arriba.
    for y in (-15, -13, -11):
        prisma("Pecho", t, "cicatriz", [(y, 13), (y + 1, 13), (y + 3, 17), (y + 2, 17)], (8, 9), eje="x")
    prisma("Cola2", t, "cicatriz", [(6, 13), (7, 13), (10, 16), (9, 16)], (-7, -6), eje="x")
    prisma("Cola3", t, "cicatriz", [(13, 6), (14, 6), (17, 9), (16, 9)], (5, 6), eje="x")
    prisma("Cola4", t, "cicatriz", [(19, 11), (20, 11), (22, 13), (21, 13)], (-5, -4), eje="x")
    prisma("Dorsal", "Aletas", "cicatriz", [(-3, 21), (-2, 21), (0, 23), (-1, 23)], (-2, -1), eje="x")
    prisma("Mandibula", "Mandibula", "cicatriz", [(-24, 3), (-23, 3), (-21, 5), (-22, 5)], (6, 7), eje="x")
    # La del hocico, una celda delante de la mejilla derecha (bajo la cuenca), para no meterse en ella.
    prisma("Cabeza", "Cabeza", "cicatriz", [(-30, 12), (-29, 12), (-28, 14), (-29, 14)], (-7, -6), eje="x")
    # Una banda de través sobre la pectoral izquierda, apoyada en su cara de arriba.
    prisma("AletaIzq2", "Aletas", "cicatriz", [(15, 4), (17, 3), (17, 4), (15, 5)], (-10, -9), eje="y")


def percebes():
    t = "Torso"
    # Costras: una base de una celda y un bulto encima.
    for parte, col, base, bulto in (
            ("Pecho", t, ((4, 6), (-13, -10), (20, 21)), ((4, 5), (-12, -11), (21, 22))),
            ("Pecho", t, ((-6, -4), (-10, -7), (20, 21)), ((-5, -4), (-9, -8), (21, 22))),
            ("Cabeza", "Cabeza", ((-5, -1), (-29, -28), (15, 16)), ((-4, -3), (-29, -28), (16, 17))),
            ("Mandibula", "Mandibula", ((-7, -6), (-27, -24), (3, 5)), ((-8, -7), (-26, -25), (3, 4))),
            ("Cola3", t, ((5, 6), (15, 18), (12, 14)), ((6, 7), (16, 17), (12, 13))),
            ("Pecho", t, ((-9, -8), (-14, -11), (13, 15)), ((-10, -9), (-13, -12), (13, 14))),
            ("Cola4", t, ((4, 5), (19, 22), (11, 13)), ((5, 6), (20, 21), (11, 12)))):
        bloque(parte, col, "percebe", *base)
        bloque(parte, col, "percebe", *bulto)
    bloque("Cabeza", "Cabeza", "percebe", (-8, -7), (-20, -17), (16, 17))
    bloque("Dorsal", "Aletas", "percebe", (-2, -1), (-5, -3), (20, 22))
    prisma("AletaIzq2", "Aletas", "percebe", [(11, 6), (13, 5), (13, 6), (11, 7)], (-12, -10), eje="y")


def algas():
    # Algas largas que cuelgan en zigzag: dos tramos de una celda, el de abajo corrido una celda.
    for parte, col, x, (y, arriba, medio, abajo) in (
            ("Cabeza", "Cabeza", (7, 8), (-19, 11, 6, 2)),
            ("Cabeza", "Cabeza", (-8, -7), (-20, 10, 5, 3)),
            ("Pecho", "Torso", (8, 9), (-5, 8, 4, 1)),
            ("Pecho", "Torso", (-9, -8), (-5, 9, 3, 1)),  # detrás de la pectoral: en y -6 la tocaba
            ("Cola2", "Torso", (6, 7), (10, 8, 3, 1)),
            ("Cola4", "Torso", (-5, -4), (21, 9, 5, 2)),
            ("Dorsal", "Aletas", (1, 2), (-3, 29, 24, 20))):
        bloque(parte, col, "alga", x, (y, y + 1), (medio, arriba))
        bloque(parte, col, "alga", x, (y + 1, y + 2), (abajo, medio + 1))
    bloque("AletaIzq2", "Aletas", "alga", (13, 14), (-5, -4), (1, 4))
    bloque("AletaDer", "Aletas", "alga", (-12, -11), (-7, -6), (1, 5))
    bloque("Mandibula", "Mandibula", "alga", (2, 3), (-27, -26), (0, 2))
