r"""
Cuerpo de la Orca v2, etapa 3 (adulto): los seis anillos del cuerpo (Pecho y Cola1..Cola5), la
aleta dorsal, las pectorales, la cola en V, las púas del lomo y los adornos. Lo carga
orca_v2_e3_geometria.py con exec; usa bloque(), par() (de minotauro_v2_bloques.py) y prisma(),
par_prisma(), espinas() (de dragon_v2_formas.py). Todo en celdas.

Juntas: cada anillo nace una celda dentro del anterior y es más chico en todos los lados (una
celda menos de ancho por lado y una menos arriba y abajo), así no comparte plano con él y tapa la
V que se abre al ondular. La dorsal nace metida en el lomo (z 14) y las pectorales salen de
adentro del Pecho, con el segundo tramo más fino que el primero.
"""


def anillo(parte, y, ancho, z, panza=None, alto_panza=0, placa=None):
    """Un tramo del cuerpo de y = (desde, hasta), medio ancho `ancho` y z = (abajo, arriba): los
    bordes de arriba y de abajo achaflanados, la banda de la panza (si tiene) y la placa del lomo
    placa = (medio ancho, (y desde, y hasta))."""
    t = "Torso"
    x, (z0, z1) = (-ancho, ancho), z
    abajo = panza or "cuerpo"
    bloque(parte, t, abajo, x, y, (z0, z0 + 1), fin="-", recorte={"x-": 1, "x+": 1})
    medio = z0 + max(alto_panza, 1)
    if alto_panza > 1:
        bloque(parte, t, panza, x, y, (z0 + 1, medio))
    bloque(parte, t, "cuerpo", x, y, (medio, z1 - 1))
    bloque(parte, t, "cuerpo", x, y, (z1 - 1, z1), recorte={"x-": 1, "x+": 1})
    if placa:
        bloque(parte, t, "placa", (-placa[0], placa[0]), placa[1], (z1, z1 + 1))


def cuerpo():
    t = "Torso"
    anillo("Pecho", (-16, -4), 7, (2, 18), "blanco", 3, (5, (-15, -5)))
    # Garganta blanca entre la mandíbula y el pecho.
    bloque("Pecho", t, "blanco", (-6, 6), (-18, -16), (2, 6))
    anillo("Cola1", (-5, 4), 6, (3, 17), "panza", 2, (4, (-3, 3)))
    anillo("Cola2", (3, 11), 5, (4, 16), "panza_osc", 2, (3, (4, 10)))
    anillo("Cola3", (10, 17), 4, (5, 15), placa=(2, (11, 16)))
    anillo("Cola4", (16, 22), 3, (6, 14))
    anillo("Cola5", (21, 26), 2, (7, 13))
    # El lomo sube detrás de la cabeza (z 18) y la panza baja (z 2): de ahí, cada anillo baja una
    # celda arriba y sube una abajo hasta la cola.
    # Púas del lomo, de la frente a la cola; en el Pecho y la Cola1, además, un par a los lados.
    espinas("Cabeza", "Cabeza", "pua", [(-24, 18, 2), (-20, 18, 2)])
    espinas("Pecho", t, "pua", [(-15, 19, 3)])
    espinas("Cola2", t, "pua", [(8, 17, 2)])
    espinas("Cola3", t, "pua", [(12, 16, 3)])
    espinas("Cola4", t, "pua", [(17, 14, 3)])
    espinas("Cola5", t, "pua", [(22, 13, 2)])
    par_prisma("Pecho", t, "pua", [(-11, 19), (-9, 19), (-9, 21)], (3, 5), eje="x")
    par_prisma("Cola1", t, "pua", [(-1, 18), (1, 18), (1, 20)], (3, 4), eje="x")


def dorsal():
    # Alta y echada hacia atrás: el borde de ataque sube 1:2 y el de salida es cóncavo (baja
    # recto, después 1:2, 1:1 y 2:1); en piezas convexas cortadas en z 19, 23 y 27. Del mismo grueso
    # de arriba abajo: con la base más gruesa, su escalón quedaba en el plano de la placa del Pecho.
    d, a = "Dorsal", "Aletas"
    prisma(d, a, "aleta", [(-12, 14), (7, 14), (7, 17), (3, 19), (-10, 19), (-12, 15)], (-1, 1), eje="x")
    prisma(d, a, "aleta", [(-10, 19), (3, 19), (-1, 23), (-8, 23)], (-1, 1), eje="x")
    prisma(d, a, "aleta", [(-8, 23), (-1, 23), (-3, 27), (-6, 27)], (-1, 1), eje="x")
    prisma(d, a, "aleta", [(-6, 27), (-3, 27), (-3, 31), (-4, 31)], (-1, 1), eje="x")


def pectorales():
    # Bajan hacia afuera 2:1 desde el costado del Pecho; el segundo tramo, más fino y corrido
    # hacia atrás, nace dentro del primero y llega a z 0 con la punta en cara plana (en cuña, el
    # bisel la subiría y la orca no mediría 31).
    a = "Aletas"
    par_prisma("Aleta{lado}", a, "pectoral", [(5, 9), (5, 4), (11, 1), (11, 6)], (-14, -8), eje="y")
    par_prisma("Aleta{lado}2", a, "pectoral", [(9, 6), (9, 3), (15, 0), (17, 0), (17, 2)], (-13, -6),
               eje="y")
    # Placa clara sobre el segundo tramo, apoyada en su cara de arriba.
    par_prisma("Aleta{lado}2", a, "pua", [(11, 5), (15, 3), (15, 4), (11, 6)], (-12, -8), eje="y")


def cola():
    # Cola en V, horizontal: cada lóbulo nace dentro de la Cola5 y se abre 1:1 hacia atrás; entre
    # los dos queda la muesca del medio.
    par_prisma("AletaCola{lado}", "Aletas", "aleta",
               [(1, 23), (4, 23), (12, 31), (12, 33), (2, 28), (1, 27)], (9, 11))


def adornos():
    t = "Torso"
    # Branquias oscuras detrás de la cabeza y puntos cian que brillan.
    for y in (-15, -13, -11, -9):
        par("Pecho", t, "branquia", (7, 8), (y, y + 1), (9, 13))
    par("Pecho", t, "brillo", (7, 8), (-7, -6), (10, 11))
    par("Pecho", t, "brillo", (7, 8), (-6, -5), (7, 8))
    par("Cola1", t, "brillo", (6, 7), (-2, -1), (9, 10))
    # Cicatrices rojas, sin espejar: una por lado.
    prisma("Cola1", t, "cicatriz", [(0, 8), (1, 8), (3, 12), (2, 12)], (6, 7), eje="x")
    prisma("Pecho", t, "cicatriz", [(-7, 12), (-6, 12), (-4, 16), (-5, 16)], (-8, -7), eje="x")
    # Percebes sueltos en el lomo, la frente y la cola.
    bloque("Pecho", t, "percebe", (5, 6), (-8, -6), (18, 19))
    bloque("Pecho", t, "percebe", (5, 6), (-7, -6), (19, 20))
    bloque("Cabeza", "Cabeza", "percebe", (5, 6), (-21, -19), (17, 18))
    bloque("Cabeza", "Cabeza", "percebe", (-6, -5), (-24, -22), (17, 18))
    bloque("Cola3", t, "percebe", (2, 3), (13, 14), (15, 16))
    # Algas que cuelgan en zigzag: en las mejillas y en un costado de la Cola2.
    par("Cabeza", "Cabeza", "alga", (7, 8), (-20, -19), (7, 10))
    par("Cabeza", "Cabeza", "alga", (7, 8), (-19, -18), (10, 12))
    bloque("Cola2", t, "alga", (5, 6), (6, 7), (6, 9))
    bloque("Cola2", t, "alga", (5, 6), (5, 6), (9, 11))
