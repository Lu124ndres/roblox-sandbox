r"""
Minotauro v2, etapa 3 (adulto): los datos de la etapa para minotauro_v2_bloques.py.
El mismo personaje que el becerro (minotauro_v2_e1_geometria.py), ya adulto: pesado, pisa y
ruge. Cabeza más chica respecto del cuerpo, piernas más largas, espalda y brazos más anchos,
puños grandes. Piezas propias: hombreras de oro con púas de marfil (la tapa, con las púas, es
del brazo; la mitad de adentro, del pecho), cuernos grandes con punta de oro, cejas bravas,
ojos ámbar, pectorales y brazaletes anchos de oro. Todo en celdas del módulo de la etapa
(CELDA).
Ejes: x = izquierda del personaje, -y = frente, z arriba; parado en z = 0, centrado en x.

Proporciones (31 módulos de alto, contando los cuernos):
    cabeza   z 22..29  7 módulos (23 %; el becerro, 32 %)
    cadera   z 12      12 módulos (39 %; el becerro, 32 %)
    ancho    x ±16     32 módulos con los puños (1.03 del alto; el becerro, 0.84)
"""
CELDA = 0.5  # BU por celda (módulo de la etapa; docs/estilo_modelos.md, "Escala")
ALTO_JUEGO = 82.5  # studs: 15 x 5.5 (Config/Giants.luau)
# Pisotón (minotauro_v2_pisoton.py): celdas que el frente del cinturón y el faldón salen
# hacia adelante, como en la E1. La bisagra queda a 7 celdas de la cadera, fuera del
# recorrido de la rodilla (6.7: la rodillera tiene la punta de abajo achaflanada).
ADELANTE = 1


def _lineal(hexa):
    """sRGB '#RRGGBB' -> color lineal (r, g, b), como los guarda COLORES."""
    c = [int(hexa[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return tuple(round(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4, 4) for x in c)


# --- Paleta (docs/estilo_modelos.md, sección 2; lineal) -----------------------------------
COLORES = {
    "pelo": _lineal("#5D3521"), "pelo_osc": (0.035, 0.012, 0.007),  # de minotauro_etapas.py (E3)
    "crema": _lineal("#BC8E65"), "hocico": _lineal("#BC8E65"),  # panza y hocico: un solo tono
    "rosa": _lineal("#EA999B"), "nariz": _lineal("#893038"), "boca": _lineal("#893038"),
    "cuero": _lineal("#613C27"), "cuero_rojo": _lineal("#7C2C27"), "oro": _lineal("#FFCE61"),
    "marfil": _lineal("#EFE2C5"), "negro": (0.01, 0.008, 0.008),
    "ambar": (1.0, 0.45, 0.04),  # acento de la etapa: ojos (en Roblox, Neon)
    "pezuna": (0.04, 0.03, 0.03),
}


# --- El adulto, en celdas ----------------------------------------------------------------
def piernas():
    par("Pie{lado}", "Piernas", "pezuna", (1, 6), (-6, 2), (0, 2), recorte={"y-": 1})
    par("Pierna{lado}", "Piernas", "pelo", (1, 6), (-2, 2), (2, 7))
    # Muslo grueso abajo y más angosto cerca de la cadera (z 11..13, dentro del cinturón): sus
    # esquinas de arriba quedan a 2.2 celdas de la cadera, como en la E1, y al doblar la pierna
    # no suben hasta la columna (z = 14) en el salto, la caminata ni la rodilla a 120°.
    par("Muslo{lado}", "Piernas", "pelo", (1, 6), (-3, 2), (7, 11))
    par("Muslo{lado}", "Piernas", "pelo", (1, 6), (-2, 2), (11, 13))
    # Rodillera: tapa la rodilla (z = 7) por delante. La punta de abajo va achaflanada para
    # que su recorrido (6.7 celdas desde la cadera) no llegue a la bisagra del faldón (7).
    par("Muslo{lado}", "Piernas", "pelo_osc", (1, 6), (-4, -3), (6, 8), fin="-", recorte={"y-": 1})


def torso():
    t = "Torso"
    a = ADELANTE
    bloque("Cadera", t, "pelo", (-5, 5), (-4, 4), (11, 12))
    bloque("Cadera", t, "cuero", (-8, 8), (-5 - a, 5), (12, 14))  # cinturón
    bloque("Cadera", t, "oro", (-3, 3), (-6 - a, -5 - a), (12, 14))  # hebilla
    bloque("Cadera", t, "cuero_rojo", (-1, 1), (-7 - a, -6 - a), (12, 14))
    bloque("Columna", t, "pelo", (-7, 7), (-4, 4), (14, 17))
    bloque("Columna", t, "crema", (-4, 4), (-5, -4), (14, 17))  # panza
    bloque("Columna", t, "pelo_osc", (-5, 5), (4, 5), (14, 19))  # placa del lomo
    bloque("Pecho", t, "pelo", (-8, 8), (-4, 4), (17, 21))
    bloque("Pecho", t, "pelo", (-8, 8), (-4, 4), (21, 22), recorte={"x-": 1, "x+": 1})
    par("Pecho", t, "pelo", (8, 9), (-3, 3), (17, 20))  # dorsales
    par("Pecho", t, "crema", (1, 6), (-6, -4), (18, 20), fin="-", recorte={"y-": 1})  # pectorales
    bloque("Pecho", t, "pelo_osc", (-6, 6), (4, 7), (18, 22), recorte={"y+": 2})  # joroba
    bloque("Cuello", t, "pelo", (-4, 4), (-2, 2), (21, 23))


def brazos():
    b = "Brazos"
    # Hombrera partida (como en la E1): la mitad de adentro es del pecho y no se mueve; la
    # tapa de oro va con el brazo, que gira por su borde de adentro (x = 10, z = 20). Arriba
    # en z = 21, una celda por debajo de la cabeza (z = 22).
    par("Pecho", b, "pelo_osc", (5, 10), (-5, 5), (19, 21))
    par("Brazo{lado}", b, "oro", (10, 15), (-5, 5), (19, 21), recorte={"x+": 2})
    # Púas de marfil en la cuña de afuera de la tapa, inclinadas hacia afuera: al abrir el
    # brazo quedan lejos de la cabeza y de las orejas (la punta está a 5 celdas del hombro
    # hacia afuera y solo 2 hacia arriba).
    for y in ((-4, -2), (-1, 1), (2, 4)):
        par("Brazo{lado}", b, "marfil", (13, 15), y, (20, 22), recorte={"x-": 2, "y-": 1, "y+": 1})
    par("Brazo{lado}", b, "pelo", (11, 15), (-3, 2), (16, 20))
    par("Brazo{lado}", b, "pelo_osc", (10, 16), (-4, 3), (14, 16))  # codera
    par("Antebrazo{lado}", b, "pelo", (11, 15), (-3, 2), (12, 14))
    par("Antebrazo{lado}", b, "oro", (10, 16), (-4, 3), (11, 13))  # brazalete ancho
    par("Mano{lado}", b, "pelo", (10, 16), (-4, 3), (8, 11))
    par("Mano{lado}", b, "pelo_osc", (10, 16), (-5, -4), (8, 10))  # nudillos


def cabeza():
    c = "Cabeza"
    bloque("Cabeza", c, "pelo", (-5, 5), (-5, 3), (22, 28))
    bloque("Cabeza", c, "pelo", (-5, 5), (-5, 3), (28, 29), recorte={"x-": 1, "x+": 1})
    par("Cabeza", c, "pelo_osc", (5, 6), (-4, 0), (22, 25))  # mejillas
    bloque("Cabeza", c, "pelo_osc", (-4, 4), (3, 4), (23, 28))  # nuca
    # Ojos de 3 x 2 celdas (30 % del ancho de la cara) que asoman 1 celda, como en la E1: un
    # solo bloque ámbar con la pupila negra delante (asoma 1 celda más). El ceño es otra celda
    # delante de la esquina de adentro: con la punta del mechón forma una V brava. La ceja de
    # afuera va al ras de los ojos, encima, para no echarles sombra.
    par("Cabeza", c, "ambar", (1, 4), (-6, -5), (26, 28))
    par("Cabeza", c, "negro", (2, 3), (-7, -6), (26, 27))  # pupila
    par("Cabeza", c, "pelo_osc", (1, 2), (-7, -6), (27, 28))  # ceño
    par("Cabeza", c, "pelo_osc", (3, 5), (-6, -5), (28, 29))  # ceja (a los lados del copete)
    # Hocico largo: base, cuña hacia los ojos y frente (más angosta: así la cara de adelante
    # de la base no queda tapada entera y la junta no abre una rendija) con narinas y aro.
    bloque("Cabeza", c, "hocico", (-4, 4), (-9, -5), (22, 25))
    bloque("Cabeza", c, "hocico", (-4, 4), (-9, -5), (25, 26), recorte={"y-": 1})
    bloque("Cabeza", c, "hocico", (-3, 3), (-10, -9), (22, 25))
    par("Cabeza", c, "nariz", (1, 3), (-11, -10), (23, 25))  # narinas
    par("Cabeza", c, "oro", (1, 2), (-11, -10), (21, 23))  # aro de la nariz
    bloque("Cabeza", c, "oro", (-2, 2), (-11, -10), (20, 21))
    # Mechón: copete sobre la cabeza y la punta que cae entre las cejas.
    bloque("Cabeza", c, "pelo_osc", (-3, 3), (-6, -1), (28, 30), recorte={"y+": 2})
    bloque("Cabeza", c, "pelo_osc", (-1, 1), (-7, -6), (26, 29))
    # Cuernos grandes: salen de lado, anillo de oro, suben en escalón y terminan en oro. El
    # tramo de afuera arranca en z = 27, así no baja hasta la hombrera al ladear la cabeza.
    par("Cabeza", c, "marfil", (4, 8), (-2, 1), (25, 27))
    par("Cabeza", c, "oro", (8, 9), (-3, 2), (24, 28))  # anillo, por fuera de la oreja
    par("Cabeza", c, "marfil", (9, 12), (-2, 1), (27, 29))
    par("Cabeza", c, "oro", (10, 12), (-2, 1), (29, 31), recorte={"x-": 1, "y-": 1, "y+": 1})
    # Boca: bajo el hocico, escondida dentro de la mandíbula; se ve al rugir. (En bloques de la
    # mandíbula, las juntas de arriba abrían una rendija de bisel que se veía bajo el hocico.)
    bloque("Cabeza", c, "boca", (-2, 2), (-8, -6), (21, 22))
    # Mandíbula: termina una celda delante del pecho (y = -4), como en la E1; al abrirse, su
    # esquina de atrás no se mete en él.
    bloque("Mandibula", "Mandibula", "crema", (-3, 3), (-9, -5), (20, 22))


def orejas_cola_faldon():
    # Orejas cortas y casi horizontales: con la punta en x = 9 no tocan la tapa de la hombrera
    # al abrir el brazo (músculo, rascarse) ni se apoyan en el yugo al caer (rugido).
    # Van justo detrás del cuerno (y 0..3), con el rosa adelante, bajo el anillo de oro.
    par("Oreja{lado}", "Orejas", "pelo", (5, 8), (1, 3), (23, 25))
    par("Oreja{lado}", "Orejas", "pelo", (8, 9), (1, 3), (23, 25), eje="x", recorte={"z+": 1})
    par("Oreja{lado}", "Orejas", "rosa", (6, 8), (0, 1), (23, 25))
    bloque("Cola1", "Cola", "pelo", (-1, 1), (4, 8), (11, 13))
    bloque("Cola2", "Cola", "pelo", (-1, 1), (8, 10), (8, 12))
    bloque("Cola3", "Cola", "pelo", (-1, 1), (9, 11), (5, 8))
    bloque("Cola3", "Cola", "pelo_osc", (-2, 2), (8, 12), (2, 5))  # borla
    bloque("Cola3", "Cola", "pelo_osc", (-2, 2), (8, 12), (1, 2), fin="-",
           recorte={"x-": 1, "x+": 1, "y-": 1, "y+": 1})
    # Faldón: tres tiras adelante y tres a cada lado, con remaches de oro.
    a = ADELANTE
    for x, largo in (((-5, -3), 5), ((-1, 1), 6), ((3, 5), 5)):
        bloque("FaldonFrente", "Faldon", "cuero_rojo", x, (-6 - a, -5 - a), (12 - largo, 12))
        bloque("FaldonFrente", "Faldon", "oro", x, (-7 - a, -6 - a), (11, 12))
    for y in ((-4, -2), (-1, 1), (2, 4)):
        par("Faldon{lado}", "Faldon", "cuero_rojo", (7, 8), y, (7, 12))
        par("Faldon{lado}", "Faldon", "oro", (8, 9), y, (11, 12))


def construir():
    piernas(); torso(); brazos(); cabeza(); orejas_cola_faldon()


# --- Rig ------------------------------------------------------------------------------
# Hueso -> (padre, articulación en celdas). {l}: Izq en +x y Der espejado; el padre antes
# que el hijo. El hombro está en el borde de adentro de la tapa de la hombrera y el brazo
# gira por el centro de su sección (y = -0.5), como en la E1.
ARTICULACIONES = [
    ("Cadera", None, (0, 0, 12)),
    ("Columna", "Cadera", (0, 0, 14)),
    ("Pecho", "Columna", (0, 0, 17)),
    ("Cuello", "Pecho", (0, 0, 21)),
    ("Cabeza", "Cuello", (0, 0, 22)),
    ("Mandibula", "Cabeza", (0, -5, 22)),
    ("Oreja{l}", "Cabeza", (5, 1.5, 24)),
    ("Brazo{l}", "Pecho", (10, -0.5, 20)),
    ("Antebrazo{l}", "Brazo{l}", (13, -0.5, 15)),
    ("Mano{l}", "Antebrazo{l}", (13, -0.5, 11)),
    ("Muslo{l}", "Cadera", (3.5, 0, 12)),
    ("Pierna{l}", "Muslo{l}", (3.5, 0, 7)),
    ("Pie{l}", "Pierna{l}", (3.5, 0, 2)),
    ("Cola1", "Cadera", (0, 4, 12)),
    ("Cola2", "Cola1", (0, 8, 11)),
    ("Cola3", "Cola2", (0, 10, 8)),
    ("FaldonFrente", "Cadera", (0, -6 - ADELANTE, 12)),  # bisagra: borde de adelante y arriba
    ("Faldon{l}", "Cadera", (7.5, 0, 12)),
]
# Cola de cada hueso (celdas, lado izquierdo): hacia el hijo, o hacia donde apunta la pieza.
COLAS = {
    "Cadera": (0, 0, 14), "Columna": (0, 0, 17), "Pecho": (0, 0, 21), "Cuello": (0, 0, 22),
    "Cabeza": (0, 0, 29), "Mandibula": (0, -9, 21), "Oreja{l}": (9, 1.5, 23.5),
    "Brazo{l}": (13, -0.5, 15), "Antebrazo{l}": (13, -0.5, 11), "Mano{l}": (13, -0.5, 8),
    "Muslo{l}": (3.5, 0, 7), "Pierna{l}": (3.5, 0, 2), "Pie{l}": (3.5, -5, 0.5),
    "Cola1": (0, 8, 11), "Cola2": (0, 10, 8), "Cola3": (0, 10, 2),
    "FaldonFrente": (0, -7, 7), "Faldon{l}": (7.5, 0, 7),
}
# Huesos sin pesos (punto): Raiz en la base y Boca entre el hocico y la mandíbula.
PUNTOS = {"Raiz": (None, (0, 0, 0), (0, 0, 3)), "Boca": ("Cabeza", (0, -9.5, 21.5), (0, -10.5, 21.5))}
