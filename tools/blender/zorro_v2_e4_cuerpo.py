r"""
Cuerpo del Zorro de agua v2, etapa 4 (forma final): patas, torso con la pechera de espuma, cuello,
cabeza con la corona de hielo y orejas. Lo carga zorro_v2_e4_geometria.py con exec; usa bloque(),
par() (de minotauro_v2_bloques.py) y prisma(), par_prisma() (de dragon_v2_formas.py). Todo en celdas.

Sale de la maestra (zorro_v2_e3_cuerpo.py) pieza por pieza, con las mismas juntas: el torso pierde
una fila (lomo en z 12), la cabeza también (5 de alto y 10 de largo con el hocico) y las patas
bajan una fila con el cuerpo, así la cabeza queda chica y el abanico gana altura. La cara es la
misma: cabeza azul, abajo del hocico, mandíbula y mejillas blancas, ojos rasgados, la marca de la
frente y la ceja que es el párpado. Lo propio de la forma final: la corona de tres cristales de
hielo sobre la frente.
"""


def patas():
    p = "Patas"
    # Delantera: pata recta y larga, más oscura hacia abajo; la mano con la punta en cuña.
    par("Mano{lado}", p, "pata_osc", (1, 4), (-8, -4), (0, 2), recorte={"y-": 1})
    par("Antebrazo{lado}", p, "pata", (1, 4), (-7, -4), (2, 5))
    # Arriba, cuñas 1:1 adelante y atrás bajo el pecho: al girar la pata (pivote dentro del pecho)
    # las esquinas no suben dentro de él.
    par("Brazo{lado}", p, "cuerpo", (1, 4), (-7, -4), (5, 6))
    par("Brazo{lado}", p, "cuerpo", (1, 4), (-7, -4), (6, 7), recorte={"y-": 1, "y+": 1})
    # Espiga dentro del pecho, de 1 x 1 sobre el lomo de la cuña: tapa la junta y, como queda a dos
    # celdas del costado del pecho, al girar nunca se mete más hondo que en reposo.
    par("Brazo{lado}", p, "cuerpo", (2, 3), (-6, -5), (7, 9))
    # Placa del hombro, clara, sobre el flanco.
    par("Hombro{lado}", p, "claro", (4, 5), (-7, -3), (8, 11))
    # Trasera en zigzag: el anca sobresale del flanco, la pierna va hacia atrás, el tobillo
    # adelante y el pie apoya con la punta en cuña. La esquina de arriba y adelante del anca, en
    # cuña 1:1: al ir adelante (sentarse) sube sin tocar las raíces de las colas de encima.
    par("Muslo{lado}", p, "cuerpo", (1, 5), (3, 7), (6, 9))
    par("Muslo{lado}", p, "cuerpo", (1, 5), (3, 7), (9, 10), recorte={"y-": 1})
    par("Pierna{lado}", p, "pata", (1, 4), (5, 8), (4, 5))
    par("Pierna{lado}", p, "pata", (1, 4), (5, 8), (5, 6), recorte={"y-": 1, "y+": 1})  # rodilla
    par("Tobillo{lado}", p, "pata", (1, 4), (4, 7), (2, 4))
    par("Pie{lado}", p, "pata_osc", (1, 4), (3, 7), (0, 2), recorte={"y-": 1})


def torso():
    t = "Torso"
    # El lomo (z 8..12) va de y -3 a 2 y la grupa (z 7..11) de 2 a 8, pero la junta Cadera/Columna
    # está en y -1: el tramo de atrás del lomo es de la Cadera, así el muslo (que gira dentro de la
    # Cadera) no entra en la Columna al ir adelante (sentarse, echarse, rascarse).
    bloque("Pecho", t, "cuerpo", (-4, 4), (-9, -3), (8, 12))
    bloque("Pecho", t, "cuerpo", (-4, 4), (-9, -3), (7, 8), fin="-", recorte={"y-": 1})  # la pata pasa
    bloque("Columna", t, "cuerpo", (-4, 4), (-3, -1), (8, 12))
    bloque("Cadera", t, "cuerpo", (-4, 4), (-1, 2), (8, 12))
    bloque("Cadera", t, "cuerpo", (-4, 4), (2, 8), (7, 11))
    # Base de las colas: una losa bajo la grupa, de la cara de atrás hasta las raíces de las capas
    # de atrás (zorro_v2_e4_colas.py). La tapan las raíces de las colas.
    bloque("Cadera", t, "cuerpo", BASE_X, BASE_Y, BASE_Z)
    # Vetas de agua en los flancos: placas de una celda, claras y verde agua.
    par("Pecho", t, "verde", (4, 5), (-9, -7), (11, 12))
    par("Columna", t, "claro", (4, 5), (-3, -1), (11, 12))
    par("Cadera", t, "claro", (4, 5), (-1, 0), (11, 12))  # termina antes de la raíz de la A
    par("Cadera", t, "verde", (4, 5), (-1, 2), (9, 10))
    par("Cadera", t, "claro", (4, 5), (2, 5), (10, 11))
    bloque("Columna", t, "claro", (-1, 1), (-2, -1), (12, 13))  # veta del lomo
    bloque("Cadera", t, "claro", (-1, 1), (-1, 1), (12, 13))
    # Pechera de espuma: un babero en V delante del pecho, hasta el lomo y con el borde de arriba en
    # cuña: la cabeza y la mandíbula bajan sin tocarlo.
    bloque("Pecho", t, "espuma", (-4, 4), (-11, -9), (10, 12), recorte={"y-": 1})
    bloque("Pecho", t, "espuma", (-3, 3), (-11, -9), (8, 10))
    bloque("Pecho", t, "espuma", (-3, 3), (-11, -9), (7, 8), fin="-", recorte={"x-": 2, "x+": 2})
    # Cuello: casi escondido por la pechera, una celda bajo el cráneo (deja lugar al mirar arriba).
    bloque("Cuello1", t, "cuerpo", (-2, 2), (-8, -4), (11, 14))
    bloque("Cuello2", t, "cuerpo", (-3, 3), (-10, -6), (14, 16))


def cabeza():
    c = "Cabeza"
    # Cráneo azul con el borde de arriba de la frente achaflanado (las cejas apoyan en él) y la esquina
    # de atrás y abajo en cuña 1:1 de dos celdas: al mirar arriba 45° no se mete en el Cuello1.
    bloque(c, c, "cuerpo", (-4, 4), (-13, -10), (15, 17))
    bloque(c, c, "cuerpo", (-4, 4), (-10, -7), (15, 17), fin="-", recorte={"y+": 2})
    bloque(c, c, "cuerpo", (-4, 4), (-13, -7), (17, 19))
    bloque(c, c, "cuerpo", (-4, 4), (-13, -11), (19, 20), recorte={"x-": 1, "x+": 1})
    bloque(c, c, "cuerpo", (-4, 4), (-11, -7), (19, 20))
    # Hocico en cuña: arriba azul y baja hacia la nariz azul marino; la parte de abajo, blanca.
    bloque(c, c, "espuma", (-2, 2), (-16, -13), (15, 16))
    bloque(c, c, "cuerpo", (-2, 2), (-16, -13), (16, 17))
    bloque(c, c, "cuerpo", (-1, 1), (-15, -13), (17, 18), eje="y", fin="-", recorte={"z+": 1})
    bloque(c, c, "nariz", (-1, 1), (-17, -16), (16, 17))
    # Mejillas de espuma simples, que se van hacia atrás.
    par_prisma(c, c, "espuma", [(-11, 15), (-7, 15), (-5, 16), (-6, 17), (-11, 17)], (4, 5), eje="x")
    # Ojos grandes (2 de alto) que brillan, rasgados hacia arriba y afuera, y la marca de la frente.
    par_prisma(c, c, "ojo", [(1, 17), (3, 17), (4, 19), (2, 19)], (-14, -13), eje="y")
    bloque(c, c, "marca", (-1, 1), (-14, -13), (18, 20))
    # Párpado: abierto es una ceja encima del ojo que asoma una celda por delante, y se esconde en la
    # frente. Con la bisagra en y = -13.5, z = 18 baja 90° y queda media celda delante del ojo,
    # de z 16.5 a 19.5: lo tapa entero.
    par_prisma("Parpado{lado}", c, "cuerpo", [(-15, 19), (-12, 19), (-13, 20), (-15, 20)], (1, 4), eje="x")
    # Corona de hielo: un cristal central en cuña, alto y derecho, y dos prismas inclinados hacia
    # afuera, sobre las cejas: las puntas de las orejas, al ir adelante, no llegan a ellos.
    prisma(c, c, "hielo", [(-1, 20), (1, 20), (1, 22), (0, 24), (-1, 22)], (-13, -11), "y")
    par_prisma(c, c, "hielo", [(1, 20), (2, 20), (3, 22), (2, 22)], (-15, -14), eje="y")
    # Mandíbula de espuma: termina dos celdas antes del cuello (al bajar la cabeza no entra en el
    # babero), con la esquina de atrás en cuña.
    m = "Mandibula"
    bloque(m, m, "espuma", (-2, 2), (-15, -13), (13, 15))
    bloque(m, m, "espuma", (-2, 2), (-13, -12), (13, 15), eje="y", recorte={"z-": 1})


def orejas():
    o = "Orejas"
    # Oreja alta y en punta: el costado de afuera sube recto y se cierra 1:2; el de adentro sube
    # 1:2. La base, de una celda, con cuñas 1:1 adelante y atrás: al echar la oreja adelante o atrás
    # sus esquinas no se hunden en el cráneo. El interior azul oscuro asoma una celda por delante.
    par("Oreja{lado}", o, "cuerpo", (1, 4), (-11, -8), (20, 21), fin="-", recorte={"y-": 1, "y+": 1})
    par_prisma("Oreja{lado}", o, "cuerpo", [(1, 21), (4, 21), (4, 23), (2, 23)], (-11, -8), eje="y")
    par_prisma("Oreja{lado}", o, "oreja", [(2, 21), (3, 21), (3, 23), (2, 22)], (-12, -11), eje="y")
    par_prisma("OrejaPunta{lado}", o, "cuerpo", [(2, 23), (4, 23), (3, 25)], (-11, -8), eje="y")
