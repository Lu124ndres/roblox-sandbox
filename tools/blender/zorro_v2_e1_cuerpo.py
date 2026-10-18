r"""
Cuerpo del Zorro de agua v2, etapa 1 (cría): patas, torso con la pechera de espuma, cuello,
cabeza y orejas. Lo carga zorro_v2_e1_geometria.py con exec; usa bloque(), par() (de
minotauro_v2_bloques.py) y prisma(), par_prisma() (de dragon_v2_formas.py). Todo en celdas.

Las mismas piezas que la maestra (zorro_v2_e3_cuerpo.py), con medidas de cría: patas cortas y
gruesas (4 de ancho), cuerpo compacto de 10 de ancho, cabeza de 12 de ancho y 9 de alto, ojos de
3 x 3 y orejas de 6 de alto. Juntas probadas con las poses del juego (zorro_v2_poses.py):
    - brazo, muslo y oreja giran sobre una articulación en el borde de la pieza padre y meten en
      ella una espiga redonda (medio octógono de radio 2 con el centro en la articulación): al
      girar, sus esquinas pasan por dentro de la espiga y no entran más hondo que en reposo;
    - las placas del hombro y del anca van afuera, en el flanco, y giran con la pata;
    - el codo lleva cuñas 1:1 de una celda; el cráneo, una cuña atrás y abajo; el babero es bajo.
Nada comparte plano con un vecino y la mandíbula termina antes del cuello.
"""


def patas():
    p = "Patas"
    # Delantera: corta y gruesa, más oscura hacia abajo. El codo y la muñeca llevan una cuña 1:1
    # de una celda adelante y atrás en cada lado de la junta: al doblarse, la esquina no entra en
    # la otra pieza (y la mano queda con la punta en cuña).
    par("Mano{lado}", p, "pata_osc", (1, 5), (-7, -2), (0, 1))
    par("Mano{lado}", p, "pata_osc", (1, 5), (-7, -2), (1, 2), recorte={"y-": 1, "y+": 1})
    par("Antebrazo{lado}", p, "pata", (1, 5), (-6, -2), (2, 3), fin="-", recorte={"y-": 1, "y+": 1})
    par("Antebrazo{lado}", p, "pata", (1, 5), (-6, -2), (3, 4))
    par("Antebrazo{lado}", p, "pata", (1, 5), (-6, -2), (4, 5), recorte={"y-": 1, "y+": 1})
    par("Brazo{lado}", p, "cuerpo", (1, 5), (-6, -2), (5, 6), fin="-", recorte={"y-": 1, "y+": 1})
    par("Brazo{lado}", p, "cuerpo", (1, 5), (-6, -2), (6, 8))
    # Espiga redonda dentro del pecho: medio octógono con el centro en la articulación (y -4,
    # z 8). Al girar el brazo, sus esquinas de arriba pasan por dentro de ella y no entran más
    # hondo en el pecho que la espiga en reposo.
    par_prisma("Brazo{lado}", p, "cuerpo", ESPIGA_BRAZO, (2, 4), eje="x")
    # Placa del hombro, clara, sobre el flanco: gira con el brazo (misma articulación), afuera.
    par("Hombro{lado}", p, "claro", (5, 6), (-6, -2), (8, 12))
    # Trasera en zigzag: el muslo cuelga debajo de la cadera con su espiga redonda adentro y la
    # placa del anca afuera, en el flanco; la pierna va hacia atrás, el tobillo adelante y el pie
    # apoya con la punta en cuña.
    par("Muslo{lado}", p, "cuerpo", (1, 5), (2, 6), (6, 8))
    par_prisma("Muslo{lado}", p, "cuerpo", ESPIGA_MUSLO, (2, 4), eje="x")
    par("Muslo{lado}", p, "cuerpo", (5, 6), (2, 6), (8, 12))  # placa del anca
    par("Pierna{lado}", p, "pata", (1, 5), (3, 7), (4, 6))
    par("Tobillo{lado}", p, "pata", (1, 5), (2, 6), (2, 4))
    par("Pie{lado}", p, "pata_osc", (1, 5), (3, 7), (0, 2), recorte={"y-": 1})


# Espigas (y, z): radio 2 alrededor de la articulación, con las esquinas en cuña 1:1.
ESPIGA_BRAZO = [(-6, 8), (-2, 8), (-2, 9), (-3, 10), (-5, 10), (-6, 9)]
ESPIGA_MUSLO = [(2, 8), (6, 8), (6, 9), (5, 10), (3, 10), (2, 9)]


def torso():
    t = "Torso"
    bloque("Pecho", t, "cuerpo", (-5, 5), (-7, -1), (8, 16))
    bloque("Columna", t, "cuerpo", (-5, 5), (-1, 1), (9, 16))
    bloque("Cadera", t, "cuerpo", (-5, 5), (1, 7), (8, 15))
    # Vetas de agua en los flancos: placas de una celda, claras y verde agua, por encima de lo
    # que barren las placas del hombro y del anca al girar (radio 4.5 desde z 8).
    par("Pecho", t, "verde", (5, 6), (-7, -4), (14, 15))
    par("Columna", t, "claro", (5, 6), (-1, 1), (14, 15))
    par("Cadera", t, "claro", (5, 6), (1, 6), (13, 14))
    bloque("Columna", t, "claro", (-1, 1), (-1, 1), (16, 17))  # veta del lomo
    # Pechera de espuma: un babero en V delante del pecho, bajo (hasta z 15) para que la cabeza
    # y el cuello no entren en él al mirar abajo.
    bloque("Pecho", t, "espuma", (-5, 5), (-9, -7), (12, 15))
    bloque("Pecho", t, "espuma", (-4, 4), (-9, -7), (10, 12))
    bloque("Pecho", t, "espuma", (-4, 4), (-9, -7), (8, 10), fin="-", recorte={"x-": 2, "x+": 2})
    # Cuello: nace dentro del pecho; el de arriba, con la esquina de adelante y abajo en cuña 1:1.
    bloque("Cuello1", t, "cuerpo", (-2, 2), (-6, -3), (14, 17))
    prisma("Cuello2", t, "cuerpo", [(-8, 17), (-8, 18), (-5, 18), (-5, 15), (-6, 15)], (-3, 3), eje="x")


def cabeza():
    c = "Cabeza"
    # Cráneo grande con el borde de arriba de la frente achaflanado y la esquina de atrás y abajo
    # en cuña 1:1 (al mirar arriba no baja sobre el cuello).
    bloque(c, c, "cuerpo", (-6, 6), (-16, -10), (16, 18))
    bloque(c, c, "cuerpo", (-6, 6), (-10, -8), (16, 18), eje="y", recorte={"z-": 2})
    bloque(c, c, "cuerpo", (-6, 6), (-16, -8), (18, 24))
    bloque(c, c, "cuerpo", (-6, 6), (-16, -14), (24, 25), recorte={"x-": 1, "x+": 1})
    bloque(c, c, "cuerpo", (-6, 6), (-14, -8), (24, 25))
    # Hocico en cuña, corto: arriba azul y baja hacia la nariz azul marino; abajo, blanco.
    bloque(c, c, "espuma", (-3, 3), (-19, -16), (17, 18))
    bloque(c, c, "cuerpo", (-3, 3), (-19, -16), (18, 20))
    bloque(c, c, "cuerpo", (-1, 1), (-18, -16), (20, 21), eje="y", fin="-", recorte={"z+": 1})
    bloque(c, c, "nariz", (-1, 1), (-20, -19), (19, 20))
    # Mejillas de espuma simples, que se van hacia atrás pegadas a la cabeza.
    par_prisma(c, c, "espuma", [(-15, 16), (-11, 16), (-9, 17), (-9, 18), (-15, 18)], (6, 7), eje="x")
    # Ojos grandes (3 x 3) que brillan, rasgados hacia arriba y afuera, y la marca de la frente.
    ojo = [(1, 20), (4, 20), (5, 22), (5, 23), (2, 23), (1, 21)]
    par_prisma(c, c, "ojo", ojo, (-17, -16), eje="y")
    bloque(c, c, "marca", (-1, 1), (-17, -16), (22, 25))
    # Párpado: abierto es una ceja fina encima del ojo, al ras de su cara, y se esconde en la frente.
    par_prisma("Parpado{lado}", c, "cuerpo", [(-17, 23), (-14, 23), (-15, 24), (-17, 24)], (1, 5), eje="x")
    # Mandíbula de espuma, más angosta que el hocico: termina antes del cuello, con la esquina de
    # atrás en cuña.
    m = "Mandibula"
    bloque(m, m, "espuma", (-2, 2), (-18, -15), (15, 17))
    bloque(m, m, "espuma", (-2, 2), (-15, -12), (15, 16))
    bloque(m, m, "espuma", (-2, 2), (-12, -11), (15, 16), eje="y", recorte={"z-": 1})


def orejas():
    o = "Orejas"
    # Oreja grande y en punta: el costado de afuera sube recto y el de adentro sube 1:2 hasta la
    # punta, que se cierra 1:2 y termina plana (una celda: el bisel no le come el alto).
    # El interior azul oscuro asoma una celda por delante.
    par_prisma("Oreja{lado}", o, "cuerpo", [(1, 25), (6, 25), (6, 29), (3, 29)], (-13, -9), eje="y")
    # Espiga redonda dentro del cráneo (radio 2 alrededor de la articulación): al mover la oreja,
    # el borde de abajo entra en la cabeza menos que la espiga en reposo.
    par_prisma("Oreja{lado}", o, "cuerpo", [(-13, 25), (-9, 25), (-9, 24), (-10, 23), (-12, 23), (-13, 24)],
               (2, 5), eje="x")
    par_prisma("Oreja{lado}", o, "oreja", [(2, 25), (5, 25), (5, 29), (4, 29)], (-14, -13), eje="y")
    par_prisma("OrejaPunta{lado}", o, "cuerpo", [(3, 29), (6, 29), (5, 31), (4, 31)], (-13, -9), eje="y")
