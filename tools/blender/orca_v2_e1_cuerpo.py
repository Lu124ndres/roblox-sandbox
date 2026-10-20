r"""
Cuerpo de la Orca v2, etapa 1 (cría): los seis anillos del cuerpo (Pecho y Cola1..Cola5), la
aleta dorsal, las pectorales, la cola en V, los bultitos del lomo y los adornos. Lo carga
orca_v2_e1_geometria.py con exec; usa bloque(), par() (de minotauro_v2_bloques.py) y prisma(),
par_prisma() (de dragon_v2_formas.py). Todo en celdas.

Juntas como en la E3: cada anillo nace una celda dentro del anterior y es más chico en todos los
lados, así no comparte plano con él y tapa la V que se abre al ondular. Corto y rechoncho: los
anillos son cortos y después del Pecho se achican de a dos celdas, así la cola afina rápido. La
dorsal nace metida en el lomo (z 16) y las pectorales salen de adentro del Pecho, con el segundo
tramo más fino que el primero.
"""


def anillo(parte, y, ancho, z, panza=None, alto_panza=0, placa=None, redondeo=1):
    """Un tramo del cuerpo de y = (desde, hasta), medio ancho `ancho` y z = (abajo, arriba): los
    bordes de arriba y de abajo achaflanados en `redondeo` escalones 1:1 (dos en los anillos
    gordos, para que se lean redondos), la banda de la panza (si tiene) y la placa del lomo
    placa = (medio ancho, (y desde, y hasta))."""
    t = "Torso"
    z0, z1 = z
    abajo = panza or "cuerpo"
    for k in range(redondeo):  # de afuera hacia adentro: el más bajo es el más angosto
        a = ancho - redondeo + 1 + k
        bloque(parte, t, abajo, (-a, a), y, (z0 + k, z0 + k + 1), fin="-", recorte={"x-": 1, "x+": 1})
        a = ancho - k
        bloque(parte, t, "cuerpo", (-a, a), y, (z1 - redondeo + k, z1 - redondeo + k + 1),
               recorte={"x-": 1, "x+": 1})
    x = (-ancho, ancho)
    medio = z0 + max(alto_panza, redondeo)
    if alto_panza > redondeo:
        bloque(parte, t, panza, x, y, (z0 + redondeo, medio))
    bloque(parte, t, "cuerpo", x, y, (medio, z1 - redondeo))
    if placa:
        bloque(parte, t, "placa", (-placa[0], placa[0]), placa[1], (z1, z1 + 1))


def bultito(parte, y0, z0):
    """Un bulto romo de 3 de largo y 1 de alto sobre el lomo, de x -1 a 1 (las púas de la E3)."""
    prisma(parte, "Torso" if parte != "Cabeza" else "Cabeza", "pua",
           [(y0, z0), (y0 + 3, z0), (y0 + 2, z0 + 1), (y0 + 1, z0 + 1)], (-1, 1), eje="x")


def cuerpo():
    t = "Torso"
    # La panza blanca sube hasta z 7 en el Pecho y sigue, más gris, en la Cola1 y la Cola2.
    anillo("Pecho", (-8, 2), 10, (0, 21), "blanco", 7, (7, (-7, 1)), redondeo=2)
    # Garganta blanca entre la mandíbula y el pecho.
    bloque("Pecho", t, "blanco", (-9, 9), (-10, -8), (1, 6))
    anillo("Cola1", (1, 7), 9, (1, 20), "panza", 5, (6, (2, 6)), redondeo=2)
    anillo("Cola2", (6, 11), 7, (3, 18), "panza_osc", 3, (4, (7, 10)), redondeo=2)
    anillo("Cola3", (10, 14), 5, (5, 16))
    anillo("Cola4", (13, 17), 4, (7, 14))
    anillo("Cola5", (16, 20), 3, (8, 13))
    # Tres bultitos en vez de la hilera de púas: en la frente, delante de la dorsal y en la Cola3.
    bultito("Cabeza", -17, 24)
    bultito("Pecho", -7, 22)
    bultito("Cola3", 11, 16)


def dorsal():
    # Baja y redondeada, apenas echada hacia atrás: sube 2:1 adelante, redondea la punta (plana,
    # de 3 celdas, en z 31) con 1:1 y 1:2, y atrás baja recta hasta la Cola2. Es convexa: una
    # sola pieza.
    prisma("Dorsal", "Aletas", "aleta", [(-4, 16), (9, 16), (9, 26), (7, 30), (6, 31), (3, 31),
                                         (1, 29), (-4, 19)], (-1, 1), eje="x")


def pectorales():
    # Cortas y anchas: salen del costado del Pecho y bajan 2:1 hacia afuera; el segundo tramo,
    # más fino y corrido hacia atrás, nace dentro del primero y termina en cara plana (z 2).
    a = "Aletas"
    par_prisma("Aleta{lado}", a, "pectoral", [(8, 9), (8, 5), (12, 3), (12, 7)], (-6, 1), eje="y")
    par_prisma("Aleta{lado}2", a, "pectoral", [(11, 6), (11, 4), (15, 2), (17, 2), (17, 3)], (-5, 3),
               eje="y")


def cola():
    # Cola en V, horizontal y corta: cada lóbulo nace dentro de la Cola5 y se abre 1:1 hacia
    # atrás; entre los dos queda la muesca del medio.
    par_prisma("AletaCola{lado}", "Aletas", "aleta",
               [(1, 18), (4, 18), (9, 23), (9, 25), (1, 21)], (10, 12))


def adornos():
    t = "Torso"
    # Tres branquias oscuras detrás de la cabeza y un punto cian que brilla.
    for y in (-6, -4, -2):
        par("Pecho", t, "branquia", (10, 11), (y, y + 1), (11, 14))
    par("Pecho", t, "brillo", (10, 11), (0, 1), (12, 13))
    # Una sola alguita en zigzag, en el costado izquierdo de la Cola1.
    bloque("Cola1", t, "alga", (9, 10), (4, 5), (8, 11))
    bloque("Cola1", t, "alga", (9, 10), (3, 4), (11, 13))
