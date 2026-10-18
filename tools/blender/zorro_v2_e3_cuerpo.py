r"""
Cuerpo del Zorro de agua v2, etapa 3 (adulto): patas, torso con la pechera de espuma, cuello,
cabeza y orejas. Lo carga zorro_v2_e3_geometria.py con exec; usa bloque(), par() (de
minotauro_v2_bloques.py) y prisma(), par_prisma() (de dragon_v2_formas.py). Todo en celdas.

Juntas: las patas se apilan (como el minotauro), la pata de adelante sube dentro del pecho con
una espiga más angosta (su costado no queda en el plano del flanco) y la de atrás va en zigzag.
Nada comparte plano con un vecino: el cuello empieza una celda detrás de la cara del pecho y la
mandíbula termina una celda antes del cuello. La cara es limpia: cabeza azul, abajo del hocico,
mandíbula y mejillas blancas, ojos grandes y la marca de la frente.
"""


def patas():
    p = "Patas"
    # Delantera: pata recta y larga, más oscura hacia abajo; la mano con la punta en cuña.
    par("Mano{lado}", p, "pata_osc", (1, 4), (-8, -4), (0, 2), recorte={"y-": 1})
    par("Antebrazo{lado}", p, "pata", (1, 4), (-7, -4), (2, 6))
    par("Brazo{lado}", p, "cuerpo", (1, 4), (-7, -4), (6, 8))
    par("Brazo{lado}", p, "cuerpo", (1, 3), (-7, -4), (8, 10))  # espiga dentro del pecho
    # Placa del hombro, clara, sobre el flanco.
    par("Hombro{lado}", p, "claro", (4, 5), (-7, -3), (9, 12))
    # Trasera en zigzag: el anca sobresale del flanco, la pierna va hacia atrás, el tobillo
    # adelante y el pie apoya con la punta en cuña.
    par("Muslo{lado}", p, "cuerpo", (1, 5), (3, 7), (7, 12))
    par("Pierna{lado}", p, "pata", (1, 4), (5, 8), (4, 7))
    par("Tobillo{lado}", p, "pata", (1, 4), (4, 7), (2, 4))
    par("Pie{lado}", p, "pata_osc", (1, 4), (3, 7), (0, 2), recorte={"y-": 1})


def torso():
    t = "Torso"
    bloque("Pecho", t, "cuerpo", (-4, 4), (-9, -3), (8, 14))
    bloque("Columna", t, "cuerpo", (-4, 4), (-3, 2), (9, 14))
    bloque("Cadera", t, "cuerpo", (-4, 4), (2, 8), (8, 13))
    # Vetas de agua en los flancos: placas de una celda, claras y verde agua.
    par("Pecho", t, "verde", (4, 5), (-9, -7), (12, 13))
    par("Columna", t, "claro", (4, 5), (-3, 1), (12, 13))
    par("Columna", t, "verde", (4, 5), (-1, 2), (10, 11))
    par("Cadera", t, "claro", (4, 5), (2, 5), (12, 13))  # termina antes de la cola central
    bloque("Columna", t, "claro", (-1, 1), (-2, 1), (14, 15))  # veta del lomo
    # Pechera de espuma: un babero en V delante del pecho.
    bloque("Pecho", t, "espuma", (-4, 4), (-11, -9), (12, 15))
    bloque("Pecho", t, "espuma", (-3, 3), (-11, -9), (10, 12))
    bloque("Pecho", t, "espuma", (-3, 3), (-11, -9), (8, 10), fin="-", recorte={"x-": 2, "x+": 2})
    # Cuello: casi escondido por la pechera.
    bloque("Cuello1", t, "cuerpo", (-2, 2), (-8, -4), (13, 16))
    bloque("Cuello2", t, "cuerpo", (-3, 3), (-10, -6), (15, 17))


def cabeza():
    c = "Cabeza"
    # Cráneo azul con el borde de arriba de la frente achaflanado (las cejas apoyan en él).
    bloque(c, c, "cuerpo", (-4, 4), (-14, -7), (16, 21))
    bloque(c, c, "cuerpo", (-4, 4), (-14, -12), (21, 22), recorte={"x-": 1, "x+": 1})
    bloque(c, c, "cuerpo", (-4, 4), (-12, -7), (21, 22))
    # Hocico en cuña: arriba azul y baja hacia la nariz azul marino; la parte de abajo, blanca.
    bloque(c, c, "espuma", (-2, 2), (-17, -14), (17, 18))
    bloque(c, c, "cuerpo", (-2, 2), (-17, -14), (18, 19))
    bloque(c, c, "cuerpo", (-1, 1), (-16, -14), (19, 20), eje="y", fin="-", recorte={"z+": 1})
    bloque(c, c, "nariz", (-1, 1), (-18, -17), (18, 19))
    # Mejillas de espuma simples, que se van hacia atrás.
    par_prisma(c, c, "espuma", [(-12, 16), (-8, 16), (-6, 17), (-7, 18), (-12, 18)], (4, 5), eje="x")
    # Ojos grandes (2 de alto) que brillan, rasgados hacia arriba y afuera, y la marca de la frente.
    par_prisma(c, c, "ojo", [(1, 19), (3, 19), (4, 21), (2, 21)], (-15, -14), eje="y")
    bloque(c, c, "marca", (-1, 1), (-15, -14), (20, 22))
    # Párpado: abierto es una ceja fina encima del ojo, al ras de su cara (no le hace sombra), y
    # se esconde en la frente. Con la bisagra en y = -14, z = 20 baja 90° y queda delante del ojo,
    # de z 19 a 21. (Pasa por dentro del ojo al bajar.)
    par_prisma("Parpado{lado}", c, "cuerpo", [(-15, 21), (-13, 21), (-14, 22), (-15, 22)], (1, 4), eje="x")
    # Mandíbula de espuma: termina una celda antes del cuello, con la esquina de atrás en cuña.
    m = "Mandibula"
    bloque(m, m, "espuma", (-2, 2), (-16, -14), (15, 17))
    bloque(m, m, "espuma", (-2, 2), (-14, -12), (15, 16))
    bloque(m, m, "espuma", (-2, 2), (-12, -11), (15, 16), eje="y", recorte={"z-": 1})


def orejas():
    o = "Orejas"
    # Oreja alta y en punta: el costado de afuera sube recto y se cierra 1:2; el de adentro sube
    # 1:2 de punta a punta. El interior azul oscuro asoma una celda por delante.
    par_prisma("Oreja{lado}", o, "cuerpo", [(1, 22), (4, 22), (4, 25), (2, 25), (1, 23)], (-11, -8), eje="y")
    par_prisma("Oreja{lado}", o, "oreja", [(2, 22), (3, 22), (3, 25), (2, 23)], (-12, -11), eje="y")
    par_prisma("OrejaPunta{lado}", o, "cuerpo", [(2, 25), (4, 25), (3, 27)], (-11, -8), eje="y")
