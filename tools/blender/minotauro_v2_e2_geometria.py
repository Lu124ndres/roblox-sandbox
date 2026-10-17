r"""
Minotauro v2, etapa 2 (joven): los datos de la etapa para minotauro_v2_bloques.py.
El mismo personaje que el becerro (minotauro_v2_e1_geometria.py), creciendo: joven fanfarrón
que saca músculo y todavía baila. Cabeza más chica respecto del cuerpo, pecho ancho con
pectorales, cintura más angosta (V), bíceps, cuernos más largos, ojos ámbar con cejas bravas
y su pieza propia: el tirante de cuero cruzado en X sobre el pecho, con hebilla de oro (va
en `Pecho`). Todo en celdas del módulo de la etapa (CELDA).
Ejes: x = izquierda del personaje, -y = frente, z arriba; parado en z = 0, centrado en x.

Proporciones (28 módulos de alto, contando los cuernos):
    piernas hasta la cadera  z 0..10   36 %  (becerro 32 %)
    tronco                   z 10..19  32 %  (becerro 29 %)
    cabeza                   z 19..26  25 %  (becerro 32 %); cuernos y mechón hasta z 28
    hombro a hombro          x ±13     0.93 del alto (becerro 0.84)
"""
CELDA = 0.3  # BU por celda (módulo de la etapa; docs/estilo_modelos.md, "Escala")
ALTO_JUEGO = 44.0  # studs: 8 x 5.5 (Config/Giants.luau)
# Pisotón (minotauro_v2_pisoton.py): celdas que el frente del cinturón y el faldón salen
# hacia adelante. Como en la E1 (aprobado): la bisagra del faldón queda fuera del recorrido
# de la rodilla. Las piernas y la cadera miden lo mismo en módulos que las del becerro.
ADELANTE = 1


# --- Paleta -----------------------------------------------------------------------------
def _lineal(hexa):
    """sRGB "#RRGGBB" -> color lineal (lo que pide Blender en Base Color)."""
    def canal(c):
        c /= 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return tuple(round(canal(c), 4) for c in bytes.fromhex(hexa[1:]))


# docs/estilo_modelos.md, sección 2 (columna E2 y comunes). Los que no están en la tabla
# salen del modelo actual (minotauro_etapas.py, E2): pelo oscuro (osc), hocico (hocico_col)
# e iris ámbar; negro y pezuña son los del becerro.
COLORES = {nombre: _lineal(h) for nombre, h in {
    "pelo": "#7C462B", "pelo_osc": "#452719", "crema": "#D7AA7C", "hocico": "#E1AD95",
    "rosa": "#EA999B", "nariz": "#893038", "cuero": "#613C27", "cuero_rojo": "#7C2C27",
    "oro": "#FFCE61", "marfil": "#EFE2C5", "negro": "#191616", "blanco": "#E6E6E6",
    "pezuna": "#383030", "ambar": "#FFBC3F",
}.items()}


# --- El joven, en celdas --------------------------------------------------------------
def piernas():
    # Las del becerro: con el cuerpo más bajo en módulos, se leen más largas (36 % del alto).
    par("Pie{lado}", "Piernas", "pezuna", (1, 5), (-4, 2), (0, 2), recorte={"y-": 1})
    par("Pierna{lado}", "Piernas", "pelo", (1, 5), (-2, 2), (2, 6))
    par("Muslo{lado}", "Piernas", "pelo", (1, 5), (-2, 2), (6, 11))
    par("Muslo{lado}", "Piernas", "pelo_osc", (1, 5), (-3, -2), (5, 7))  # rodillera


def torso():
    t = "Torso"
    a = ADELANTE
    bloque("Cadera", t, "pelo", (-4, 4), (-3, 3), (9, 10))
    bloque("Cadera", t, "cuero", (-7, 7), (-4 - a, 4), (10, 12))  # cinturón
    bloque("Cadera", t, "oro", (-2, 2), (-5 - a, -4 - a), (10, 12))  # hebilla
    bloque("Cadera", t, "cuero_rojo", (-1, 1), (-6 - a, -5 - a), (10, 12))
    # Cintura más angosta que el pecho (V): panza chica (una fila, partida en dos) y lomo.
    bloque("Columna", t, "pelo", (-5, 5), (-3, 3), (12, 13))
    par("Columna", t, "crema", (0, 4), (-4, -3), (12, 13))  # abdominales
    bloque("Columna", t, "pelo_osc", (-4, 4), (3, 4), (12, 13))  # lomo
    # Pecho ancho y alto (lleva el tirante) con pectorales (la ranura del bisel los separa al
    # medio) y joroba.
    bloque("Pecho", t, "pelo", (-6, 6), (-3, 3), (13, 18))
    bloque("Pecho", t, "pelo", (-6, 6), (-3, 3), (18, 19), recorte={"x-": 1, "x+": 1})
    par("Pecho", t, "crema", (0, 5), (-4, -3), (14, 18))  # pectorales
    bloque("Pecho", t, "pelo_osc", (-5, 5), (3, 5), (16, 17))  # joroba
    bloque("Pecho", t, "pelo_osc", (-5, 5), (3, 5), (17, 19), recorte={"y+": 2})
    bloque("Cuello", t, "pelo", (-3, 3), (-2, 2), (17, 20))
    tirante()


def tirante():
    """Tirantes cruzados en X (simétricos, del Pecho): bajan de cada hombrera en escalera, se
    cruzan bajo la hebilla (una fila por debajo del aro de la nariz) y dan la vuelta a la
    espalda hasta la joroba. Cuero rojo: el del cinturón se confunde con el pelaje."""
    t = "Torso"
    par("Pecho", t, "cuero_rojo", (4, 7), (-5, -4), (17, 18))  # bajan de los hombros
    par("Pecho", t, "cuero_rojo", (2, 5), (-5, -4), (16, 17))
    bloque("Pecho", t, "cuero_rojo", (-2, 2), (-5, -4), (14, 17))  # cruce
    par("Pecho", t, "cuero_rojo", (2, 5), (-5, -4), (14, 15))
    par("Pecho", t, "cuero_rojo", (4, 6), (-5, -3), (13, 14))  # siguen al costado contrario
    par("Pecho", t, "cuero_rojo", (6, 7), (-5, 4), (13, 14))  # costados
    par("Pecho", t, "cuero_rojo", (4, 6), (3, 4), (13, 14))  # espalda, hasta la joroba
    par("Pecho", t, "cuero_rojo", (2, 5), (3, 4), (14, 15))
    bloque("Pecho", t, "cuero_rojo", (-2, 2), (3, 4), (14, 16))
    bloque("Pecho", t, "oro", (-1, 1), (-6, -5), (14, 16))  # hebilla


def brazos():
    b = "Brazos"
    # Hombrera partida como en la E1: la mitad de adentro es del pecho y no se mueve; la tapa
    # va con el brazo, que gira por su borde de adentro (x = 8, z = 17). Una celda por debajo
    # de la cabeza (z 19).
    par("Pecho", b, "pelo_osc", (5, 8), (-4, 4), (16, 18))
    par("Brazo{lado}", b, "pelo_osc", (8, 12), (-4, 4), (16, 18), recorte={"x+": 2})
    par("Brazo{lado}", b, "pelo", (9, 12), (-2, 1), (13, 17))
    par("Brazo{lado}", b, "pelo", (9, 12), (-3, -2), (14, 16))  # bíceps
    par("Brazo{lado}", b, "pelo_osc", (8, 13), (-3, 2), (12, 14))  # codera
    par("Antebrazo{lado}", b, "pelo", (9, 12), (-2, 1), (10, 13))
    par("Antebrazo{lado}", b, "oro", (8, 13), (-3, 2), (9, 10))  # brazalete
    par("Mano{lado}", b, "pelo", (8, 13), (-3, 2), (6, 9))
    par("Mano{lado}", b, "pelo_osc", (8, 13), (-4, -3), (7, 9))  # nudillos


def cabeza():
    c = "Cabeza"
    bloque("Cabeza", c, "pelo", (-5, 5), (-4, 4), (19, 25))
    bloque("Cabeza", c, "pelo", (-5, 5), (-4, 4), (25, 26), recorte={"x-": 1, "x+": 1})
    par("Cabeza", c, "pelo_osc", (5, 6), (-3, 1), (20, 23))  # mejillas
    bloque("Cabeza", c, "pelo_osc", (-3, 3), (4, 5), (20, 24))  # nuca, en escalones
    bloque("Cabeza", c, "pelo_osc", (-1, 1), (5, 6), (21, 23))
    # Ojos ámbar con la pupila hacia adentro y un brillo; cejas bravas en cuña (bajan al medio).
    par("Cabeza", c, "negro", (1, 2), (-5, -4), (22, 24))
    par("Cabeza", c, "ambar", (2, 4), (-5, -4), (22, 23))
    par("Cabeza", c, "ambar", (2, 3), (-5, -4), (23, 24))
    par("Cabeza", c, "blanco", (3, 4), (-5, -4), (23, 24))
    par("Cabeza", c, "pelo_osc", (1, 3), (-5, -4), (24, 25), eje="x", fin="-", recorte={"z+": 1})
    par("Cabeza", c, "pelo_osc", (3, 5), (-5, -4), (24, 25))
    # Hocico: base, cuña hacia los ojos, frente angosta con las narinas y el aro de oro.
    bloque("Cabeza", c, "hocico", (-4, 4), (-7, -4), (19, 21))
    bloque("Cabeza", c, "hocico", (-4, 4), (-7, -4), (21, 22), recorte={"y-": 1})
    bloque("Cabeza", c, "hocico", (-3, 3), (-8, -7), (19, 21))
    par("Cabeza", c, "nariz", (1, 3), (-9, -8), (20, 21))  # narinas
    par("Cabeza", c, "oro", (1, 2), (-9, -8), (18, 20))  # aro de la nariz
    bloque("Cabeza", c, "oro", (-2, 2), (-9, -8), (17, 18))
    # Mechón: base sobre la frente, cuña encima y la punta que cae entre los ojos.
    bloque("Cabeza", c, "pelo_osc", (-2, 2), (-5, -4), (25, 26))
    bloque("Cabeza", c, "pelo_osc", (-2, 2), (-5, -1), (26, 28), recorte={"y+": 2})
    bloque("Cabeza", c, "pelo_osc", (-1, 1), (-6, -4), (23, 27))
    # Cuernos más largos que los del becerro: salen de lado, anillo de oro, suben y terminan
    # en punta.
    par("Cabeza", c, "marfil", (5, 10), (-2, 1), (23, 25))
    par("Cabeza", c, "oro", (6, 7), (-3, 2), (22, 26))  # anillo
    par("Cabeza", c, "marfil", (8, 10), (-2, 1), (25, 26))
    par("Cabeza", c, "marfil", (8, 10), (-2, 1), (26, 28), recorte={"x-": 1, "y-": 1, "y+": 1})
    bloque("Mandibula", "Mandibula", "crema", (-3, 3), (-7, -4), (17, 19))


def orejas_cola_faldon():
    par("Oreja{lado}", "Orejas", "pelo", (6, 9), (-1, 2), (20, 22))
    par("Oreja{lado}", "Orejas", "pelo", (9, 11), (-1, 2), (19, 21), eje="x", recorte={"z+": 1})
    par("Oreja{lado}", "Orejas", "rosa", (6, 9), (-2, -1), (20, 22))
    bloque("Cola1", "Cola", "pelo", (-1, 1), (3, 6), (9, 11))
    bloque("Cola2", "Cola", "pelo", (-1, 1), (6, 8), (7, 10))
    bloque("Cola3", "Cola", "pelo", (-1, 1), (7, 9), (4, 7))
    bloque("Cola3", "Cola", "pelo_osc", (-2, 2), (6, 10), (2, 4))  # borla
    bloque("Cola3", "Cola", "pelo_osc", (-2, 2), (6, 10), (1, 2), fin="-",
           recorte={"x-": 1, "x+": 1, "y-": 1, "y+": 1})
    # Faldón: el del becerro (aprobado con ADELANTE = 1).
    for x, largo in (((-4, -2), 4), ((-1, 1), 5), ((2, 4), 4)):
        a = ADELANTE
        bloque("FaldonFrente", "Faldon", "cuero_rojo", x, (-5 - a, -4 - a), (10 - largo, 10))
        bloque("FaldonFrente", "Faldon", "oro", x, (-6 - a, -5 - a), (9, 10))
    for y in ((-3, -1), (0, 2)):
        par("Faldon{lado}", "Faldon", "cuero_rojo", (6, 7), y, (6, 10))
        par("Faldon{lado}", "Faldon", "oro", (7, 8), y, (9, 10))


def construir():
    piernas(); torso(); brazos(); cabeza(); orejas_cola_faldon()


# --- Rig ------------------------------------------------------------------------------
# Hueso -> (padre, articulación en celdas). {l}: Izq en +x y Der espejado; el padre antes
# que el hijo. El hombro está en el borde de adentro de la tapa de la hombrera (la otra
# mitad es del pecho) y el brazo gira por el centro de su sección (y = -0.5).
ARTICULACIONES = [
    ("Cadera", None, (0, 0, 10)),
    ("Columna", "Cadera", (0, 0, 12)),
    ("Pecho", "Columna", (0, 0, 13)),
    ("Cuello", "Pecho", (0, 0, 18)),
    ("Cabeza", "Cuello", (0, 0, 19)),
    ("Mandibula", "Cabeza", (0, -4, 19)),
    ("Oreja{l}", "Cabeza", (6, 0.5, 21)),
    ("Brazo{l}", "Pecho", (8, -0.5, 17)),
    ("Antebrazo{l}", "Brazo{l}", (10.5, -0.5, 13)),
    ("Mano{l}", "Antebrazo{l}", (10.5, -0.5, 9)),
    ("Muslo{l}", "Cadera", (3, 0, 10)),
    ("Pierna{l}", "Muslo{l}", (3, 0, 6)),
    ("Pie{l}", "Pierna{l}", (3, 0, 2)),
    ("Cola1", "Cadera", (0, 3, 10)),
    ("Cola2", "Cola1", (0, 6, 9)),
    ("Cola3", "Cola2", (0, 7.5, 7)),
    ("FaldonFrente", "Cadera", (0, -5 - ADELANTE, 10)),  # bisagra: borde de adelante y arriba
    ("Faldon{l}", "Cadera", (6.5, 0, 10)),
]
# Cola de cada hueso (celdas, lado izquierdo): hacia el hijo, o hacia donde apunta la pieza.
COLAS = {
    "Cadera": (0, 0, 12), "Columna": (0, 0, 13),"Pecho": (0, 0, 18), "Cuello": (0, 0, 19),
    "Cabeza": (0, 0, 26), "Mandibula": (0, -7, 18), "Oreja{l}": (11, 0.5, 20),
    "Brazo{l}": (10.5, -0.5, 13), "Antebrazo{l}": (10.5, -0.5, 9), "Mano{l}": (10.5, -0.5, 6),
    "Muslo{l}": (3, 0, 6), "Pierna{l}": (3, 0, 2), "Pie{l}": (3, -4, 0.5),
    "Cola1": (0, 6, 9), "Cola2": (0, 7.5, 7), "Cola3": (0, 8, 2),
    "FaldonFrente": (0, -6, 6), "Faldon{l}": (6.5, 0, 6),
}
# Huesos sin pesos (punto): Raiz en la base y Boca entre el hocico y la mandíbula.
PUNTOS = {"Raiz": (None, (0, 0, 0), (0, 0, 3)), "Boca": ("Cabeza", (0, -7.5, 18.5), (0, -8.5, 18.5))}
