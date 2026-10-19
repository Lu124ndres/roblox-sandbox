r"""
Cuerpo del Zorro de agua v2, etapa 2 (joven): patas, torso con la pechera de espuma, cuello,
cabeza y orejas. Sale de la E3 (zorro_v2_e3_cuerpo.py, la maestra) con la misma cara y los mismos
bloques; lo que lo hace adolescente: patas más largas (z 0..10 adelante, la grupa en z 9), cuerpo
más fino (4 de alto, z 10..14) y corto (15 de largo, y -8..7), cabeza de 7 de alto (frente alta) y
orejas de 4 para que la espuma de la cola central quede arriba de todo.
Lo carga zorro_v2_e2_geometria.py con exec; usa bloque(), par() (de minotauro_v2_bloques.py) y
prisma(), par_prisma() (de dragon_v2_formas.py). Todo en celdas.

Juntas que aguantan las poses del juego (zorro_v2_poses.py):
    - el borde Cadera/Columna va adelante (y -1) y el muslo mide 3 de hondo: al ir adelante hasta
      1.5 rad solo entra en la Cadera, que es su padre;
    - el brazo no entra en el pecho: arriba termina en una espiga de una celda con cuñas 1:2
      adelante y atrás, que gira media celda debajo del pecho (z 9.5); el codo y el pie, en cuña;
    - el cuello va detrás de la cabeza (no debajo: mirar arriba), la pechera termina una celda
      debajo del borde del pecho y la mandíbula tres celdas antes del cuello (mirar abajo 45°);
    - la oreja mide 2 de hondo y gira media celda arriba de la cabeza, y su interior empieza una
      celda más arriba: al echarla adelante o atrás no se mete en la cabeza;
    - la placa del hombro termina una celda antes de la columna (mirar a un lado).
"""


def patas():
    p = "Patas"
    # Delantera: pata recta y larga, más oscura hacia abajo; la mano con la punta en cuña. Arriba,
    # el brazo se angosta 1:2 hasta una espiga de una celda, que toca el pecho sin entrar.
    par("Mano{lado}", p, "pata_osc", (1, 4), (-8, -4), (0, 2), recorte={"y-": 1})
    par("Antebrazo{lado}", p, "pata", (1, 4), (-7, -4), (2, 4))
    par("Antebrazo{lado}", p, "pata", (1, 4), (-7, -4), (4, 5), recorte={"y-": 1, "y+": 1})  # codo en cuña
    par("Brazo{lado}", p, "cuerpo", (1, 4), (-7, -4), (5, 7))
    par("Brazo{lado}", p, "cuerpo", (1, 4), (-7, -4), (7, 9), recorte={"y-": 1, "y+": 1})
    par("Brazo{lado}", p, "cuerpo", (1, 4), (-6, -5), (9, 10))
    # Placa del hombro, clara, sobre el flanco.
    par("Hombro{lado}", p, "claro", (4, 5), (-7, -4), (10, 13))
    # Trasera en zigzag: el anca sobresale del flanco, la pierna va hacia atrás, el tobillo
    # adelante y el pie apoya con la punta en cuña.
    par("Muslo{lado}", p, "cuerpo", (1, 5), (2, 5), (8, 12))
    par("Pierna{lado}", p, "pata", (1, 4), (3, 6), (5, 8))
    par("Tobillo{lado}", p, "pata", (1, 4), (2, 5), (2, 5))
    par("Pie{lado}", p, "pata_osc", (1, 4), (1, 5), (0, 2), recorte={"y-": 1, "y+": 1})


def torso():
    t = "Torso"
    bloque("Pecho", t, "cuerpo", (-4, 4), (-8, -3), (10, 14))
    bloque("Columna", t, "cuerpo", (-4, 4), (-3, -1), (10, 14))
    bloque("Cadera", t, "cuerpo", (-4, 4), (-1, 7), (9, 13))
    # Vetas de agua en los flancos: placas de una celda, claras y verde agua.
    par("Pecho", t, "verde", (4, 5), (-8, -6), (13, 14))
    par("Columna", t, "claro", (4, 5), (-3, 0), (12, 13))
    par("Columna", t, "verde", (4, 5), (-2, 0), (10, 11))
    bloque("Columna", t, "claro", (-1, 1), (-3, 0), (14, 15))  # veta del lomo
    # Pechera de espuma: un babero en V delante del pecho, una celda debajo de su borde de arriba.
    bloque("Pecho", t, "espuma", (-4, 4), (-10, -8), (11, 13))
    bloque("Pecho", t, "espuma", (-3, 3), (-10, -8), (10, 11), fin="-", recorte={"x-": 1, "x+": 1})
    # Cuello: detrás de la cabeza (no debajo) y casi escondido por la pechera.
    bloque("Cuello1", t, "cuerpo", (-2, 2), (-6, -4), (13, 16))
    bloque("Cuello2", t, "cuerpo", (-3, 3), (-8, -5), (15, 17))


def cabeza():
    c = "Cabeza"
    # Cráneo azul con la frente una celda más alta que la del adulto: el borde de arriba de la
    # frente, achaflanado 1:2 en dos celdas (las cejas apoyan en él).
    bloque(c, c, "cuerpo", (-4, 4), (-13, -6), (16, 21))
    bloque(c, c, "cuerpo", (-4, 4), (-13, -11), (21, 23), recorte={"x-": 1, "x+": 1})
    bloque(c, c, "cuerpo", (-4, 4), (-11, -6), (21, 23))
    # Hocico en cuña: arriba azul y baja hacia la nariz azul marino; la parte de abajo, blanca.
    bloque(c, c, "espuma", (-2, 2), (-16, -13), (17, 18))
    bloque(c, c, "cuerpo", (-2, 2), (-16, -13), (18, 19))
    bloque(c, c, "cuerpo", (-1, 1), (-15, -13), (19, 20), eje="y", fin="-", recorte={"z+": 1})
    bloque(c, c, "nariz", (-1, 1), (-17, -16), (18, 19))
    # Mejillas de espuma simples, que se van hacia atrás.
    par_prisma(c, c, "espuma", [(-11, 16), (-7, 16), (-5, 17), (-6, 18), (-11, 18)], (4, 5), eje="x")
    # Ojos grandes (2 de alto) que brillan, rasgados hacia arriba y afuera, y la marca de la frente,
    # que sube hasta arriba de la frente alta del joven.
    par_prisma(c, c, "ojo", [(1, 19), (3, 19), (4, 21), (2, 21)], (-14, -13), eje="y")
    bloque(c, c, "marca", (-1, 1), (-14, -13), (20, 23))
    # Párpado: abierto es una ceja fina encima del ojo, al ras de su cara, y el resto se esconde en
    # la frente (3 celdas de hondo: cerrado tapa los 2 de alto del ojo y su borde de arriba).
    # Atrás, en cuña 2:1: lo que asoma por el chaflán de la frente, en la punta de afuera de la
    # ceja, es casi lo mismo que antes. Cerrado, arriba entra un poco en el ojo y tapa su borde.
    par_prisma("Parpado{lado}", c, "cuerpo", [(-14, 21), (-11, 21), (-13, 22), (-14, 22)], (1, 4), eje="x")
    # Mandíbula de espuma: termina tres celdas antes del cuello (al mirar abajo no llega a la
    # pechera), con la esquina de atrás en cuña.
    m = "Mandibula"
    bloque(m, m, "espuma", (-2, 2), (-15, -13), (15, 17))
    bloque(m, m, "espuma", (-2, 2), (-13, -12), (15, 16))
    bloque(m, m, "espuma", (-2, 2), (-12, -11), (15, 16), eje="y", recorte={"z-": 1})


def orejas():
    o = "Orejas"
    # Oreja alta y en punta, una celda más baja que la del adulto: el costado de afuera sube
    # recto y se cierra 1:2; el de adentro sube 1:2 de punta a punta. El interior azul oscuro
    # asoma una celda por delante, desde una celda arriba de la cabeza.
    par_prisma("Oreja{lado}", o, "cuerpo", [(1, 23), (4, 23), (4, 25), (2, 25)], (-10, -8), eje="y")
    par_prisma("Oreja{lado}", o, "oreja", [(2, 24), (3, 24), (3, 26)], (-11, -10), eje="y")
    par_prisma("OrejaPunta{lado}", o, "cuerpo", [(2, 25), (4, 25), (3, 27)], (-10, -8), eje="y")
