r"""
Minotauro v2, etapa 1 (becerro): los datos de la etapa para minotauro_v2_bloques.py.
Mantiene la estética del becerro actual: cabeza grande, hocico crema con aro de oro,
cuernitos de marfil con anillo de oro, orejas caídas, mechón, cinturón con hebilla, faldón de
tiras de cuero rojo, brazaletes y pezuñas. Todo en celdas del módulo de la etapa (CELDA).
Ejes: x = izquierda del personaje, -y = frente, z arriba; parado en z = 0, centrado en x.
"""
CELDA = 0.1  # BU por celda (módulo de la etapa; docs/estilo_modelos.md, "Escala")
ALTO_JUEGO = 16.5  # studs: 3 x 5.5 (Config/Giants.luau)
# Pisotón (minotauro_v2_pisoton.py): celdas que el frente del cinturón y el
# faldón salen hacia adelante (aprobado: 1, así la bisagra del faldón queda fuera
# del recorrido de la rodilla; con 0 la rodilla atraviesa la raíz de las tiras).
ADELANTE = 1

# --- Paleta (lineal, la misma de minotauro_e1.py) ---------------------------------------
COLORES = {
    "pelo": (0.26, 0.085, 0.03), "pelo_osc": (0.085, 0.028, 0.012), "crema": (0.78, 0.5, 0.27),
    "hocico": (0.85, 0.5, 0.38), "rosa": (0.82, 0.32, 0.33), "nariz": (0.25, 0.03, 0.04),
    "cuero": (0.12, 0.045, 0.02), "cuero_rojo": (0.2, 0.025, 0.02), "oro": (1.0, 0.62, 0.12),
    "marfil": (0.86, 0.76, 0.56), "negro": (0.01, 0.008, 0.008), "blanco": (0.9, 0.9, 0.9),
    "pezuna": (0.04, 0.03, 0.03),
}


# --- El becerro, en celdas ------------------------------------------------------------
def piernas():
    par("Pie{lado}", "Piernas", "pezuna", (1, 5), (-4, 2), (0, 2), recorte={"y-": 1})
    par("Pierna{lado}", "Piernas", "pelo", (1, 5), (-2, 2), (2, 6))
    par("Muslo{lado}", "Piernas", "pelo", (1, 5), (-2, 2), (6, 11))
    par("Muslo{lado}", "Piernas", "pelo_osc", (1, 5), (-3, -2), (5, 7))  # rodillera


def torso():
    t = "Torso"
    bloque("Cadera", t, "pelo", (-4, 4), (-3, 3), (9, 10))
    a = ADELANTE
    bloque("Cadera", t, "cuero", (-7, 7), (-4 - a, 4), (10, 12))  # cinturón
    bloque("Cadera", t, "oro", (-2, 2), (-5 - a, -4 - a), (10, 12))  # hebilla
    bloque("Cadera", t, "cuero_rojo", (-1, 1), (-6 - a, -5 - a), (10, 12))
    bloque("Columna", t, "pelo", (-5, 5), (-3, 3), (12, 15))
    bloque("Columna", t, "crema", (-4, 4), (-5, -3), (12, 15))  # panza
    bloque("Columna", t, "pelo_osc", (-4, 4), (3, 4), (12, 17))  # placa del lomo
    bloque("Columna", t, "pelo_osc", (-2, 2), (4, 5), (13, 16))
    bloque("Pecho", t, "pelo", (-5, 5), (-3, 3), (15, 18))
    bloque("Pecho", t, "pelo", (-5, 5), (-3, 3), (18, 19), recorte={"x-": 1, "x+": 1})
    bloque("Pecho", t, "crema", (-3, 3), (-4, -3), (15, 18))
    bloque("Pecho", t, "pelo_osc", (-4, 4), (3, 5), (17, 19), recorte={"y+": 2})  # joroba
    bloque("Cuello", t, "pelo", (-3, 3), (-2, 2), (17, 20))


def brazos():
    b = "Brazos"
    # Hombrera partida (minotauro_v2_poses.py): la mitad de adentro es del pecho y no se
    # mueve; la tapa va con el brazo, que gira por su borde de adentro (x = 8, z = 17). Una
    # celda por debajo de la cabeza, así las mejillas no la tocan al ladearla.
    par("Pecho", b, "pelo_osc", (4, 8), (-4, 4), (16, 18))
    par("Brazo{lado}", b, "pelo_osc", (8, 12), (-4, 4), (16, 18), recorte={"x+": 2})
    par("Brazo{lado}", b, "pelo", (9, 12), (-2, 1), (14, 17))
    par("Brazo{lado}", b, "pelo_osc", (8, 13), (-3, 2), (13, 15))  # codera
    par("Antebrazo{lado}", b, "pelo", (9, 12), (-2, 1), (11, 14))
    par("Antebrazo{lado}", b, "oro", (8, 13), (-3, 2), (10, 11))  # brazalete
    par("Mano{lado}", b, "pelo", (8, 13), (-3, 2), (7, 10))
    par("Mano{lado}", b, "pelo_osc", (8, 13), (-4, -3), (8, 10))  # nudillos


def cabeza():
    c = "Cabeza"
    bloque("Cabeza", c, "pelo", (-6, 6), (-5, 4), (19, 28))
    bloque("Cabeza", c, "pelo", (-6, 6), (-5, 4), (28, 29), recorte={"x-": 1, "x+": 1})
    bloque("Cabeza", c, "pelo_osc", (-5, 5), (-6, -5), (26, 28))  # frente
    par("Cabeza", c, "pelo_osc", (6, 7), (-4, 1), (20, 24))  # mejillas
    bloque("Cabeza", c, "pelo_osc", (-4, 4), (4, 5), (21, 27))  # nuca, en escalones
    bloque("Cabeza", c, "pelo_osc", (-2, 2), (5, 6), (22, 26))
    par("Cabeza", c, "negro", (1, 4), (-6, -5), (23, 25))  # ojos
    par("Cabeza", c, "negro", (1, 3), (-6, -5), (25, 26))
    par("Cabeza", c, "blanco", (3, 4), (-6, -5), (25, 26))
    # Hocico: base, cuña hacia los ojos y frente con las narinas.
    bloque("Cabeza", c, "hocico", (-4, 4), (-8, -5), (19, 22))
    bloque("Cabeza", c, "hocico", (-4, 4), (-8, -5), (22, 23), recorte={"y-": 1})
    bloque("Cabeza", c, "hocico", (-4, 4), (-9, -8), (19, 22))
    par("Cabeza", c, "nariz", (1, 3), (-10, -9), (20, 22))  # narinas
    par("Cabeza", c, "oro", (1, 2), (-10, -9), (18, 20))  # aro de la nariz
    bloque("Cabeza", c, "oro", (-2, 2), (-10, -9), (17, 18))
    # Mechón y cuernitos.
    # El mechón se apoya sobre la cabeza (no se mete en la cuña de arriba): base sobre la
    # frente, cuña encima y la punta que cae por delante.
    bloque("Cabeza", c, "pelo_osc", (-3, 3), (-6, -5), (28, 29))
    bloque("Cabeza", c, "pelo_osc", (-3, 3), (-6, -1), (29, 31), recorte={"y+": 2})
    bloque("Cabeza", c, "pelo_osc", (-2, 2), (-7, -6), (26, 30))
    par("Cabeza", c, "marfil", (6, 9), (-2, 1), (25, 27))  # sale de lado
    par("Cabeza", c, "oro", (7, 8), (-3, 2), (24, 28))  # anillo
    par("Cabeza", c, "marfil", (8, 10), (-2, 1), (27, 29))  # sube
    par("Cabeza", c, "marfil", (8, 10), (-2, 1), (29, 31), recorte={"x-": 1, "y-": 1, "y+": 1})
    bloque("Mandibula", "Mandibula", "crema", (-3, 3), (-8, -4), (17, 19))


def orejas_cola_faldon():
    par("Oreja{lado}", "Orejas", "pelo", (7, 10), (-1, 2), (22, 24))
    par("Oreja{lado}", "Orejas", "pelo", (10, 12), (-1, 2), (21, 23), eje="x", recorte={"z+": 1})
    par("Oreja{lado}", "Orejas", "rosa", (7, 10), (-2, -1), (22, 24))
    bloque("Cola1", "Cola", "pelo", (-1, 1), (3, 6), (9, 11))
    bloque("Cola2", "Cola", "pelo", (-1, 1), (6, 8), (7, 10))
    bloque("Cola3", "Cola", "pelo", (-1, 1), (7, 9), (4, 7))
    bloque("Cola3", "Cola", "pelo_osc", (-2, 2), (6, 10), (2, 4))  # borla
    bloque("Cola3", "Cola", "pelo_osc", (-2, 2), (6, 10), (1, 2), fin="-",
           recorte={"x-": 1, "x+": 1, "y-": 1, "y+": 1})
    # Faldón: tres tiras adelante y dos a cada lado, con remaches de oro.
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
    ("Pecho", "Columna", (0, 0, 15)),
    ("Cuello", "Pecho", (0, 0, 18)),
    ("Cabeza", "Cuello", (0, 0, 19)),
    ("Mandibula", "Cabeza", (0, -4, 19)),
    ("Oreja{l}", "Cabeza", (7, 0.5, 23)),
    ("Brazo{l}", "Pecho", (8, -0.5, 17)),
    ("Antebrazo{l}", "Brazo{l}", (10.5, -0.5, 14)),
    ("Mano{l}", "Antebrazo{l}", (10.5, -0.5, 10)),
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
    "Cadera": (0, 0, 12), "Columna": (0, 0, 15), "Pecho": (0, 0, 18), "Cuello": (0, 0, 19),
    "Cabeza": (0, 0, 28), "Mandibula": (0, -8, 18), "Oreja{l}": (12, 0.5, 22),
    "Brazo{l}": (10.5, -0.5, 14), "Antebrazo{l}": (10.5, -0.5, 10), "Mano{l}": (10.5, -0.5, 7),
    "Muslo{l}": (3, 0, 6), "Pierna{l}": (3, 0, 2), "Pie{l}": (3, -4, 0.5),
    "Cola1": (0, 6, 9), "Cola2": (0, 7.5, 7), "Cola3": (0, 8, 2),
    "FaldonFrente": (0, -6, 6), "Faldon{l}": (6.5, 0, 6),
}
# Huesos sin pesos (punto): Raiz en la base y Boca entre el hocico y la mandíbula.
PUNTOS = {"Raiz": (None, (0, 0, 0), (0, 0, 3)), "Boca": ("Cabeza", (0, -8.5, 18.5), (0, -9.5, 18.5))}
