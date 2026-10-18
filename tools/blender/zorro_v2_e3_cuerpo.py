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
    # Arriba, cuñas 1:1 adelante y atrás bajo el pecho: al girar la pata (pivote dentro del pecho)
    # las esquinas no suben dentro de él.
    par("Brazo{lado}", p, "cuerpo", (1, 4), (-7, -4), (6, 7))
    par("Brazo{lado}", p, "cuerpo", (1, 4), (-7, -4), (7, 8), recorte={"y-": 1, "y+": 1})
    # Espiga dentro del pecho, de 1 x 1 sobre el lomo de la cuña: tapa la junta y, como queda a dos
    # celdas del costado del pecho, al girar nunca se mete más hondo que en reposo.
    par("Brazo{lado}", p, "cuerpo", (2, 3), (-6, -5), (8, 10))
    # Placa del hombro, clara, sobre el flanco.
    par("Hombro{lado}", p, "claro", (4, 5), (-7, -3), (9, 12))
    # Trasera en zigzag: el anca sobresale del flanco, la pierna va hacia atrás, el tobillo
    # adelante y el pie apoya con la punta en cuña.
    par("Muslo{lado}", p, "cuerpo", (1, 5), (3, 7), (7, 11))
    # La esquina de arriba y adelante en cuña 1:1: al ir adelante (sentarse) sube y no toca la raíz
    # de la cola central, que nace en el lomo justo encima.
    par("Muslo{lado}", p, "cuerpo", (1, 5), (3, 7), (11, 12), recorte={"y-": 1})
    par("Pierna{lado}", p, "pata", (1, 4), (5, 8), (4, 7))
    par("Tobillo{lado}", p, "pata", (1, 4), (4, 7), (2, 4))
    par("Pie{lado}", p, "pata_osc", (1, 4), (3, 7), (0, 2), recorte={"y-": 1})


def torso():
    t = "Torso"
    # El lomo (z 9..14) va de y -3 a 2 y la grupa (z 8..13) de 2 a 8, pero la junta Cadera/Columna
    # está en y -1: el tramo de atrás del lomo es de la Cadera, así el muslo (que gira dentro de la
    # Cadera) no entra en la Columna al ir adelante (sentarse, echarse, rascarse).
    bloque("Pecho", t, "cuerpo", (-4, 4), (-9, -3), (8, 14))
    bloque("Columna", t, "cuerpo", (-4, 4), (-3, -1), (9, 14))
    bloque("Cadera", t, "cuerpo", (-4, 4), (-1, 2), (9, 14))
    bloque("Cadera", t, "cuerpo", (-4, 4), (2, 8), (8, 13))
    # Base de las colas: una losa bajo la grupa, de la cara de atrás hasta la raíz de la C (la
    # capa de más atrás). La tapan las raíces de las colas.
    bloque("Cadera", t, "cuerpo", (-3, 3), (8, 15), (8, 10))
    # Vetas de agua en los flancos: placas de una celda, claras y verde agua.
    par("Pecho", t, "verde", (4, 5), (-9, -7), (12, 13))
    par("Columna", t, "claro", (4, 5), (-3, -1), (12, 13))
    par("Cadera", t, "claro", (4, 5), (-1, 1), (12, 13))
    par("Cadera", t, "verde", (4, 5), (-1, 2), (10, 11))
    par("Cadera", t, "claro", (4, 5), (2, 5), (12, 13))  # termina antes de la cola central
    bloque("Columna", t, "claro", (-1, 1), (-2, -1), (14, 15))  # veta del lomo
    bloque("Cadera", t, "claro", (-1, 1), (-1, 1), (14, 15))
    # Pechera de espuma: un babero en V delante del pecho.
    # Hasta el lomo y con el borde de arriba en cuña: la cabeza y la mandíbula bajan sin tocarlo.
    bloque("Pecho", t, "espuma", (-4, 4), (-11, -9), (12, 14), recorte={"y-": 1})
    bloque("Pecho", t, "espuma", (-3, 3), (-11, -9), (10, 12))
    bloque("Pecho", t, "espuma", (-3, 3), (-11, -9), (8, 10), fin="-", recorte={"x-": 2, "x+": 2})
    # Cuello: casi escondido por la pechera.
    bloque("Cuello1", t, "cuerpo", (-2, 2), (-8, -4), (13, 15))  # deja lugar al cráneo al mirar arriba
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
    # de z 19 a 22: tapa también el borde de arriba del ojo. (Pasa por dentro del ojo al bajar.)
    par_prisma("Parpado{lado}", c, "cuerpo", [(-15, 21), (-12, 21), (-14, 22), (-15, 22)], (1, 4), eje="x")
    # Mandíbula de espuma: termina una celda antes del cuello, con la esquina de atrás en cuña.
    m = "Mandibula"
    bloque(m, m, "espuma", (-2, 2), (-16, -14), (15, 17))
    bloque(m, m, "espuma", (-2, 2), (-14, -12), (15, 16))
    bloque(m, m, "espuma", (-2, 2), (-12, -11), (15, 16), eje="y", recorte={"z-": 1})


def orejas():
    o = "Orejas"
    # Oreja alta y en punta: el costado de afuera sube recto y se cierra 1:2; el de adentro sube
    # 1:2 de punta a punta. El interior azul oscuro asoma una celda por delante.
    # La base, de una celda, con cuñas 1:1 adelante y atrás: al echar la oreja adelante o atrás
    # sus esquinas no se hunden en el cráneo.
    par("Oreja{lado}", o, "cuerpo", (1, 4), (-11, -8), (22, 23), fin="-", recorte={"y-": 1, "y+": 1})
    par_prisma("Oreja{lado}", o, "cuerpo", [(1, 23), (4, 23), (4, 25), (2, 25)], (-11, -8), eje="y")
    # (Empieza una celda más arriba: al echar la oreja adelante no se hunde en el cráneo.)
    par_prisma("Oreja{lado}", o, "oreja", [(2, 23), (3, 23), (3, 25), (2, 24)], (-12, -11), eje="y")
    par_prisma("OrejaPunta{lado}", o, "cuerpo", [(2, 25), (4, 25), (3, 27)], (-11, -8), eje="y")
