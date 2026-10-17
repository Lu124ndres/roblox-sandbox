r"""
Minotauro v2, etapa 4 (forma final): los datos de la etapa para minotauro_v2_bloques.py.
El mismo personaje que el becerro (minotauro_v2_e1_geometria.py), crecido: enorme y lento,
ruge y pisa. Pelaje casi negro con grietas de lava, ojos de lava, cuernos enormes, hombreras
de cuero con borde de oro, colmillos y más oro que las etapas anteriores.
Las grietas son bloques de lava que asoman un módulo sobre el pelaje (brazos, piernas, lomo)
o que quedan un módulo metidos entre placas (pecho y panza): nunca en el plano de otra cara.
Todo en celdas del módulo de la etapa (CELDA): 31 de alto, como el becerro.
Ejes: x = izquierda del personaje, -y = frente, z arriba; parado en z = 0, centrado en x.
"""
CELDA = 1.0  # BU por celda (módulo de la etapa; docs/estilo_modelos.md, "Escala")
ALTO_JUEGO = 165.0  # studs: 30 x 5.5 (Config/Giants.luau)
# Pisotón (minotauro_v2_pisoton.py): celdas que el frente del cinturón y el faldón salen
# delante de la panza (en la E1, 1). Con 2, la bisagra del faldón queda a 8 celdas de la
# cadera: fuera del recorrido de la rodilla (la rodillera llega a 6.4) y también del frente
# de la canilla con muslo y rodilla a 90° (y = -8); con 1, esa pose no tenía salida.
ADELANTE = 2


# --- Paleta (docs/estilo_modelos.md, sección 2: E4 y comunes) ------------------------
def _lineal(hexa):
    """sRGB "#RRGGBB" -> color lineal (lo que espera el Principled BSDF)."""
    c = [int(hexa[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return tuple(round(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4, 4) for x in c)


COLORES = {n: _lineal(h) for n, h in {
    "pelo": "#381F19", "pelo_osc": "#1F110D",  # mechón, nuca, codos, nudillos
    "panza": "#6F4535",  # panza, pecho y hocico (un solo color en la E4)
    "lava": "#FF9938",  # ojos y grietas: en Roblox brilla con Neon o luz
    "lava_clara": "#FFE2A0",  # brillo de los ojos (el blanco del becerro)
    "rosa": "#EA999B", "nariz": "#893038", "cuero": "#613C27", "cuero_rojo": "#7C2C27",
    "oro": "#FFCE61", "marfil": "#EFE2C5", "pezuna": "#382F2F",
}.items()}


# --- La forma final, en celdas ------------------------------------------------------------
def piernas():
    p = "Piernas"
    par("Pie{lado}", p, "pezuna", (2, 8), (-6, 2), (0, 2), recorte={"y-": 1})
    # Tobillera: sale por delante y por detrás, no a los lados (a x = 9 tocaría las tiras de
    # los costados del faldón al subir la pierna más de 75°).
    par("Pierna{lado}", p, "oro", (2, 8), (-4, 3), (2, 3))
    par("Pierna{lado}", p, "pelo", (2, 8), (-3, 2), (3, 7))
    # Grieta de la canilla: escalones de lava que asoman un módulo por delante.
    par("Pierna{lado}", p, "lava", (5, 6), (-4, -3), (3, 4))
    par("Pierna{lado}", p, "lava", (4, 5), (-4, -3), (4, 5))
    par("Pierna{lado}", p, "lava", (5, 6), (-4, -3), (5, 6))
    par("Pierna{lado}", p, "lava", (3, 4), (2, 3), (4, 5))  # y otra en la pantorrilla
    par("Pierna{lado}", p, "lava", (4, 5), (2, 3), (5, 6))
    par("Muslo{lado}", p, "pelo", (2, 8), (-3, 3), (7, 13))
    par("Muslo{lado}", p, "pelo_osc", (3, 7), (-4, -3), (7, 9))  # rodillera
    par("Muslo{lado}", p, "lava", (4, 6), (-4, -3), (9, 10))  # grieta del muslo
    par("Muslo{lado}", p, "lava", (5, 7), (-4, -3), (10, 11))


def torso():
    t = "Torso"
    a = ADELANTE
    bloque("Cadera", t, "pelo", (-6, 6), (-2, 2), (11, 12))
    bloque("Cadera", t, "cuero", (-10, 10), (-5 - a, 5), (12, 14))  # cinturón
    bloque("Cadera", t, "oro", (-3, 3), (-6 - a, -5 - a), (12, 14))  # hebilla
    bloque("Cadera", t, "lava", (-1, 1), (-7 - a, -6 - a), (12, 14))  # piedra de lava
    # Panza y pecho: placas con la lava metida un módulo en las juntas (una línea por el
    # medio, del cinturón al cuello, y una junta en cada pectoral).
    bloque("Columna", t, "pelo", (-7, 7), (-4, 4), (14, 17))
    bloque("Columna", t, "lava", (-4, 4), (-5, -4), (14, 17))
    par("Columna", t, "panza", (1, 4), (-6, -5), (14, 17))
    bloque("Columna", t, "pelo_osc", (-5, 5), (4, 5), (14, 18))  # placa del lomo
    # Grieta del lomo: sube por el medio y se abre en dos hacia la joroba.
    bloque("Columna", t, "lava", (-1, 1), (5, 6), (14, 16))
    par("Columna", t, "lava", (1, 3), (5, 6), (16, 17))
    par("Columna", t, "lava", (3, 4), (5, 6), (17, 18))
    bloque("Pecho", t, "pelo", (-8, 8), (-5, 4), (17, 21))
    bloque("Pecho", t, "pelo", (-8, 8), (-5, 4), (21, 22), recorte={"x-": 1, "x+": 1})
    bloque("Pecho", t, "lava", (-7, 7), (-6, -5), (17, 21))
    par("Pecho", t, "panza", (1, 4), (-7, -6), (17, 21))
    par("Pecho", t, "panza", (5, 7), (-7, -6), (17, 20))
    # Joroba: el lomo sube detrás de la cabeza, una celda por debajo de ella.
    bloque("Pecho", t, "pelo_osc", (-6, 6), (4, 7), (18, 22), recorte={"y+": 2})
    bloque("Cuello", t, "pelo", (-4, 4), (-4, 1), (21, 24))


def brazos():
    b = "Brazos"
    # Hombrera partida (como la E1): la mitad de adentro es del pecho y no se mueve; la tapa
    # va con el brazo, que gira por su borde de adentro (x = 11) una celda por debajo de su
    # tope (z = 21, como en la E1: al subir el brazo, la tapa casi no entra en el pecho). Las
    # dos bajan en cuña hacia adelante y atrás; arriba quedan una celda por debajo de la
    # cabeza (z 23).
    # La mitad de adentro, una celda más baja que la tapa: ahí caen las orejas al ladear.
    par("Pecho", b, "cuero", (8, 11), (-5, 4), (18, 21), recorte={"y-": 3, "y+": 3})
    par("Brazo{lado}", b, "cuero", (11, 17), (-5, 4), (18, 22),
        recorte={"x+": 2, "y-": 2, "y+": 2})
    par("Brazo{lado}", b, "oro", (11, 17), (-6, 5), (17, 18))  # borde de la hombrera
    par("Brazo{lado}", b, "pelo", (12, 16), (-3, 2), (15, 19))
    par("Brazo{lado}", b, "lava", (16, 17), (-2, 0), (15, 17))  # grieta del brazo
    par("Brazo{lado}", b, "pelo_osc", (11, 17), (-4, 3), (13, 15))  # codera
    par("Antebrazo{lado}", b, "pelo", (12, 16), (-3, 2), (10, 14))
    par("Antebrazo{lado}", b, "lava", (13, 14), (-4, -3), (11, 12))  # grieta del antebrazo
    par("Antebrazo{lado}", b, "lava", (14, 15), (-4, -3), (12, 13))
    par("Antebrazo{lado}", b, "lava", (16, 17), (-2, 0), (10, 12))
    par("Antebrazo{lado}", b, "oro", (11, 17), (-4, 3), (9, 10))  # brazalete
    par("Mano{lado}", b, "pelo", (11, 17), (-4, 3), (6, 9))
    par("Mano{lado}", b, "pelo_osc", (11, 17), (-5, -4), (7, 9))  # nudillos


def cabeza():
    c = "Cabeza"
    bloque("Cabeza", c, "pelo", (-6, 6), (-6, 2), (23, 28))
    bloque("Cabeza", c, "pelo", (-6, 6), (-6, 2), (28, 29), recorte={"x-": 1, "x+": 1})
    par("Cabeza", c, "pelo_osc", (6, 7), (-5, -2), (23, 26))  # mejillas
    bloque("Cabeza", c, "pelo_osc", (-4, 4), (2, 4), (23, 28))  # nuca
    # Ojos de lava de 3 x 2 (un cuarto de la cara, como los del becerro) que asoman una celda.
    # Con el brillo claro arriba y afuera, donde el becerro tiene el blanco. Van por encima
    # del hocico (así no los tapa de tres cuartos), con una celda de pelaje entre ellos y el
    # anillo del cuerno, y el ceño va al ras, sin alero que les haga sombra; entre los ceños,
    # la base del mechón.
    par("Cabeza", c, "lava", (2, 4), (-7, -6), (26, 28))
    par("Cabeza", c, "lava", (4, 5), (-7, -6), (26, 27))
    par("Cabeza", c, "lava_clara", (4, 5), (-7, -6), (27, 28))
    par("Cabeza", c, "pelo_osc", (3, 6), (-7, -6), (28, 29))
    # Mechón, como el del becerro: base sobre la frente, cuña encima y la punta que cae.
    bloque("Cabeza", c, "pelo_osc", (-3, 3), (-7, -6), (28, 29))
    bloque("Cabeza", c, "pelo_osc", (-3, 3), (-7, -2), (29, 31), recorte={"y+": 2})
    bloque("Cabeza", c, "pelo_osc", (-1, 1), (-8, -7), (27, 30))  # angosta: no tapa los ojos
    # Hocico: base, cuña hacia los ojos, narinas y el aro de oro.
    bloque("Cabeza", c, "panza", (-3, 3), (-9, -6), (23, 25))
    bloque("Cabeza", c, "panza", (-3, 3), (-9, -6), (25, 26), recorte={"y-": 1})
    par("Cabeza", c, "nariz", (1, 3), (-10, -9), (23, 25))  # narinas
    par("Cabeza", c, "oro", (1, 2), (-10, -9), (21, 23))  # aro de la nariz
    bloque("Cabeza", c, "oro", (-2, 2), (-10, -9), (20, 21))
    # Cuernos: salen de lado con un anillo de oro, suben en escalones y terminan en oro.
    par("Cabeza", c, "marfil", (6, 10), (-3, 0), (26, 28))
    par("Cabeza", c, "oro", (7, 8), (-4, 1), (25, 29))  # anillo
    par("Cabeza", c, "marfil", (10, 13), (-3, 0), (27, 29))
    par("Cabeza", c, "marfil", (13, 15), (-3, 0), (28, 30))
    par("Cabeza", c, "oro", (13, 15), (-3, 0), (30, 31), recorte={"x-": 1, "x+": 1, "y-": 1, "y+": 1})
    # Mandíbula con colmillos de marfil que suben por fuera del hocico.
    bloque("Mandibula", "Mandibula", "panza", (-3, 3), (-9, -5), (21, 23))
    par("Mandibula", "Mandibula", "marfil", (3, 4), (-9, -8), (22, 24))


def orejas_cola_faldon():
    par("Oreja{lado}", "Orejas", "pelo", (6, 9), (-2, 1), (23, 25))
    # Cortas (4 celdas desde la cabeza): caídas casi no entran en la hombrera, a 1 celda abajo.
    par("Oreja{lado}", "Orejas", "pelo", (9, 10), (-2, 1), (23, 25), eje="x", recorte={"z+": 1})
    par("Oreja{lado}", "Orejas", "rosa", (7, 9), (-3, -2), (23, 25))
    bloque("Cola1", "Cola", "pelo", (-1, 1), (5, 9), (11, 13))
    bloque("Cola2", "Cola", "pelo", (-1, 1), (9, 11), (8, 12))
    bloque("Cola3", "Cola", "pelo", (-1, 1), (10, 12), (4, 8))
    bloque("Cola3", "Cola", "pelo_osc", (-2, 2), (9, 13), (3, 5))  # borla
    bloque("Cola3", "Cola", "lava", (-2, 2), (9, 13), (2, 3), fin="-",
           recorte={"x-": 1, "x+": 1, "y-": 1, "y+": 1})
    # Faldón: cinco tiras adelante y tres a cada lado, con remaches de oro.
    a = ADELANTE
    for x, largo in (((-1, 1), 6), ((2, 4), 5), ((-4, -2), 5), ((5, 7), 4), ((-7, -5), 4)):
        bloque("FaldonFrente", "Faldon", "cuero_rojo", x, (-6 - a, -5 - a), (12 - largo, 12))
        bloque("FaldonFrente", "Faldon", "oro", x, (-7 - a, -6 - a), (11, 12))
    for y in ((-4, -2), (-1, 1), (2, 4)):
        par("Faldon{lado}", "Faldon", "cuero_rojo", (9, 10), y, (7, 12))
        par("Faldon{lado}", "Faldon", "oro", (10, 11), y, (11, 12))


def construir():
    piernas(); torso(); brazos(); cabeza(); orejas_cola_faldon()


# --- Rig ------------------------------------------------------------------------------
# Hueso -> (padre, articulación en celdas). {l}: Izq en +x y Der espejado; el padre antes
# que el hijo. El hombro está en el borde de adentro de la tapa de la hombrera (la otra
# mitad es del pecho) y el brazo gira por el centro de su sección (y = -0.5).
ARTICULACIONES = [
    ("Cadera", None, (0, 0, 12)),
    ("Columna", "Cadera", (0, 0, 14)),
    ("Pecho", "Columna", (0, 0, 17)),
    ("Cuello", "Pecho", (0, -1, 22)),
    ("Cabeza", "Cuello", (0, -1, 23)),
    ("Mandibula", "Cabeza", (0, -5, 23)),
    ("Oreja{l}", "Cabeza", (6.5, -0.5, 24)),
    ("Brazo{l}", "Pecho", (11, -0.5, 21)),
    ("Antebrazo{l}", "Brazo{l}", (14, -0.5, 14)),
    ("Mano{l}", "Antebrazo{l}", (14, -0.5, 9)),
    ("Muslo{l}", "Cadera", (5, 0, 12)),
    ("Pierna{l}", "Muslo{l}", (5, 0, 7)),
    ("Pie{l}", "Pierna{l}", (5, 0, 2)),
    ("Cola1", "Cadera", (0, 5, 12)),
    ("Cola2", "Cola1", (0, 9, 11)),
    ("Cola3", "Cola2", (0, 10.5, 8)),
    ("FaldonFrente", "Cadera", (0, -6 - ADELANTE, 12)),  # bisagra: borde de adelante y arriba
    ("Faldon{l}", "Cadera", (9.5, 0, 12)),
]
# Cola de cada hueso (celdas, lado izquierdo): hacia el hijo, o hacia donde apunta la pieza.
COLAS = {
    "Cadera": (0, 0, 14), "Columna": (0, 0, 17), "Pecho": (0, -1, 22), "Cuello": (0, -1, 23),
    "Cabeza": (0, -1, 29), "Mandibula": (0, -9, 22), "Oreja{l}": (10, -0.5, 23.5),
    "Brazo{l}": (14, -0.5, 14), "Antebrazo{l}": (14, -0.5, 9), "Mano{l}": (14, -0.5, 6),
    "Muslo{l}": (5, 0, 7), "Pierna{l}": (5, 0, 2), "Pie{l}": (5, -6, 0.5),
    "Cola1": (0, 9, 11), "Cola2": (0, 10.5, 8), "Cola3": (0, 11, 2),
    "FaldonFrente": (0, -7, 6), "Faldon{l}": (9.5, 0, 7),
}
# Huesos sin pesos (punto): Raiz en la base y Boca entre el hocico y la mandíbula.
PUNTOS = {"Raiz": (None, (0, 0, 0), (0, 0, 3)), "Boca": ("Cabeza", (0, -9.5, 23), (0, -10.5, 23))}
