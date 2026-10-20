r"""
Cuerpo de la Orca v2, etapa 2 (joven): los seis anillos del cuerpo (Pecho y Cola1..Cola5), la
aleta dorsal, las pectorales, la cola en V, la hilera chica de púas y los pocos adornos. Lo carga
orca_v2_e2_geometria.py con exec; usa bloque(), par() (de minotauro_v2_bloques.py) y prisma(),
par_prisma(), espinas() (de dragon_v2_formas.py). Todo en celdas.

Juntas, como en la E3: cada anillo nace una celda dentro del anterior y es más chico en todos los
lados (una celda menos de ancho por lado y una menos arriba y abajo), así no comparte plano con
él y tapa la V que se abre al ondular. Los anillos tienen el mismo ancho que los de la adulta,
pero son más cortos (de 9 a 4 de largo): el cuerpo mide 34 y no 42. La dorsal nace metida en el
lomo (z 14) y las pectorales salen de adentro del Pecho, con el segundo tramo más fino que el
primero.
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
    anillo("Pecho", (-12, -3), 7, (3, 18), "blanco", 3, (5, (-11, -4)))
    # Garganta blanca entre la mandíbula y el pecho.
    bloque("Pecho", t, "blanco", (-6, 6), (-14, -12), (3, 6))
    anillo("Cola1", (-4, 4), 6, (4, 17), "panza", 2, (4, (-3, 3)))
    anillo("Cola2", (3, 10), 5, (5, 16), "panza_osc", 2, (3, (4, 9)))
    anillo("Cola3", (9, 15), 4, (6, 15), placa=(2, (10, 14)))
    anillo("Cola4", (14, 19), 3, (7, 14))
    anillo("Cola5", (18, 22), 2, (8, 13))
    # Hilera chica de púas, todas de 2 de alto (en la adulta, de 2 y 3): una en la frente y una por
    # anillo detrás de la dorsal. En el Pecho, que queda delante de la dorsal, solo un par chico a
    # los lados: al medio, la púa quedaba pegada al borde de ataque.
    espinas("Cabeza", "Cabeza", "pua", [(-20, 18, 2)])
    espinas("Cola2", t, "pua", [(7, 17, 2)])
    espinas("Cola3", t, "pua", [(11, 16, 2)])
    espinas("Cola4", t, "pua", [(15, 14, 2)])
    espinas("Cola5", t, "pua", [(19, 13, 2)])
    par_prisma("Pecho", t, "pua", [(-10, 19), (-8, 19), (-8, 21)], (3, 4), eje="x")


def dorsal():
    # Echada hacia atrás como la de la adulta, pero más baja: 10 sobre el lomo (la E3, 13). El
    # borde de ataque sube 1:2 de punta a punta y el de salida es cóncavo (baja recto, después 2:1,
    # 1:1 y recto); en piezas convexas cortadas en z 20 y 24, y la punta en cara plana (en cuña, el
    # bisel la bajaría y la orca no mediría 28).
    d, a = "Dorsal", "Aletas"
    prisma(d, a, "aleta", [(-11, 14), (5, 14), (5, 18), (1, 20), (-8, 20)], (-1, 1), eje="x")
    prisma(d, a, "aleta", [(-8, 20), (1, 20), (-3, 24), (-6, 24)], (-1, 1), eje="x")
    prisma(d, a, "aleta", [(-6, 24), (-3, 24), (-3, 28), (-4, 28)], (-1, 1), eje="x")


def pectorales():
    # Largas y finas (la joven está desgarbada): bajan hacia afuera 2:1 desde el costado del
    # Pecho y cuelgan 3 celdas por debajo de la panza. El segundo tramo, de 2 de grueso y corrido
    # hacia atrás, nace dentro del primero y llega a z 0 con la punta en cara plana.
    a = "Aletas"
    par_prisma("Aleta{lado}", a, "pectoral", [(5, 9), (5, 5), (11, 2), (11, 6)], (-11, -6), eje="y")
    par_prisma("Aleta{lado}2", a, "pectoral", [(9, 4), (17, 0), (18, 0), (18, 1), (17, 2), (9, 6)],
               (-10, -4), eje="y")
    # Placa clara sobre el segundo tramo, apoyada en su cara de arriba.
    par_prisma("Aleta{lado}2", a, "pua", [(11, 5), (15, 3), (15, 4), (11, 6)], (-9, -5), eje="y")


def cola():
    # Cola en V, horizontal: cada lóbulo nace dentro de la Cola5 y se abre 1:1 hacia atrás; entre
    # los dos queda la muesca del medio.
    par_prisma("AletaCola{lado}", "Aletas", "aleta",
               [(1, 19), (4, 19), (10, 25), (10, 27), (2, 23), (1, 22)], (9, 11))


def adornos():
    t = "Torso"
    # Branquias oscuras detrás de la cabeza (tres; la adulta, cuatro) y puntos cian que brillan.
    for y in (-11, -9, -7):
        par("Pecho", t, "branquia", (7, 8), (y, y + 1), (9, 13))
    par("Pecho", t, "brillo", (7, 8), (-5, -4), (10, 11))
    par("Pecho", t, "brillo", (7, 8), (-4, -3), (7, 8))
    par("Cola1", t, "brillo", (6, 7), (2, 3), (8, 9))
    # Una sola cicatriz roja, en el costado izquierdo (el que se ve de tres cuartos).
    prisma("Cola1", t, "cicatriz", [(-1, 8), (0, 8), (2, 12), (1, 12)], (6, 7), eje="x")
    # Un percebe en el lomo, al lado de la placa del Pecho.
    bloque("Pecho", t, "percebe", (5, 6), (-7, -5), (18, 19))
    bloque("Pecho", t, "percebe", (5, 6), (-6, -5), (19, 20))
    # Una alga que cuelga en zigzag en un costado de la Cola2.
    bloque("Cola2", t, "alga", (5, 6), (6, 7), (7, 10))
    bloque("Cola2", t, "alga", (5, 6), (5, 6), (10, 12))
