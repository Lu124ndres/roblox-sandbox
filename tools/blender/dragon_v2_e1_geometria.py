r"""
Dragón marino v2, etapa 1 (cría): los datos de la etapa para minotauro_v2_bloques.py
(--criatura dragon). Mezcla de mar y fuego: turquesa claro, panza menta, aletas de pez en la
cabeza, el lomo y la cola; de fuego, solo un brillo naranja en la garganta (se ve al abrir la
boca). Tierno: cabeza grande con ojos enormes, cuello corto, patitas recogidas.
Llega en pose de PLANEO, como espera Dragon/Rig: cuerpo horizontal, alas extendidas con un
poco de diedro (cada segmento del ala va una celda más arriba que el anterior), patas
recogidas hacia atrás y cola estirada.

Juntas (docs/estilo_modelos.md): las piezas se solapan o una pieza tapa la junta.
  - Cola: cada segmento mete una cuña 1:2 dentro del anterior (tapa la V que se abre al girar).
  - Alas: tejas. Cada segmento empieza una celda adentro del anterior y una celda más arriba;
    la bisagra va en la cara de contacto, así al aletear siempre queda uno sobre el otro.
  - Cuello y cola salen de adentro de una pieza más grande (pecho, cadera).
Todo en celdas del módulo de la etapa (CELDA). Ejes: x = izquierda del dragón, -y = frente
(hocico), z arriba; centrado en x. Mide 36 celdas del hocico a la punta de la cola.
"""
CELDA = 0.1  # BU por celda (módulo de la etapa; docs/plan_dragon_v2.md, "Escala")
MODELO = "DragonMarino"
PREFIJO = "DragonV2_"
ALTO_JUEGO = 16.5  # studs: alto de la etapa (3 x 5.5, Config/Giants.luau)
LARGO_JUEGO = 0.6 * ALTO_JUEGO  # Dragon.LENGTH: GiantTemplates mide a los que vuelan a lo largo
VISTAS_EXTRA = (("arriba", 180, 8), ("abajo", 180, -8))  # la cabeza queda arriba en la imagen
PISO_BAJO = 1.0  # el piso más abajo: vuela

# Contrato de huesos del dragón (tools/blender/rig_dragon.py, Dragon/Rig y Dragon/Pose).
CONTRATO = ["Raiz", "Cadera", "Pecho", "Cuello1", "Cuello2", "Cabeza", "Mandibula", "Boca"]
CONTRATO += [f"Cola{i}" for i in range(1, 7)]
CONTRATO += [f"Ala{l}{i}" for l in ("Izq", "Der") for i in (1, 2, 3)]
CONTRATO += [f"{h}{l}" for l in ("Izq", "Der") for h in ("Brazo", "Antebrazo", "Mano", "Muslo", "Pierna", "Pie")]
CONTRATO_SIN_PESOS = ["Raiz", "Boca"]


# --- Paleta (sRGB, docs/plan_dragon_v2.md) -----------------------------------------------
def _lineal(hexa):
    """sRGB "#RRGGBB" -> color lineal (lo que espera el Principled BSDF)."""
    c = [int(hexa[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return tuple(round(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4, 4) for x in c)


COLORES = {n: _lineal(h) for n, h in {
    "cuerpo": "#2FB9A2",  # turquesa verde: lomo, cabeza, patas
    "cuerpo_osc": "#1C8C86",  # narinas (y rayas en las etapas grandes)
    "panza": "#C9F2D4",  # panza, pecho y mandíbula (menta clara)
    "aleta": "#62D8E6",  # aletas y membrana del ala (agua clara)
    "aleta_osc": "#2E9FC0",  # rayos de las aletas
    "ojo": "#F4FAF7", "pupila": "#16222E",  # alto contraste, sin negro ni blanco puros
    "mejilla": "#F59FAE",
    "boca": "#B83A50", "garganta": "#FF8A3D",  # el fuego de la cría: brillo en la garganta
    "diente": "#F6EFDC", "garra": "#EDE3C6",
}.items()}


# --- La cría, en celdas ------------------------------------------------------------------
def cabeza():
    c = "Cabeza"
    # Cráneo: la capa de abajo se parte para dejar la boca y la garganta en el medio.
    bloque("Cabeza", c, "cuerpo", (-5, 5), (-14, -9), (7, 13))
    bloque("Cabeza", c, "cuerpo", (-5, 5), (-14, -9), (13, 14), recorte={"x-": 1, "x+": 1})
    par("Cabeza", c, "cuerpo", (2, 5), (-14, -9), (6, 7))
    bloque("Cabeza", c, "boca", (-2, 2), (-14, -12), (6, 7))
    bloque("Cabeza", c, "garganta", (-2, 2), (-12, -9), (6, 7))
    # Hocico: la capa de abajo es la boca (la raya roja de la sonrisa) y arriba una cuña.
    bloque("Cabeza", c, "boca", (-3, 3), (-17, -14), (6, 7))
    bloque("Cabeza", c, "boca", (-1, 1), (-18, -17), (6, 7))
    par("Cabeza", c, "diente", (1, 2), (-18, -17), (6, 7))  # colmillitos
    par("Cabeza", c, "boca", (2, 3), (-18, -17), (6, 7))
    bloque("Cabeza", c, "cuerpo", (-3, 3), (-18, -14), (7, 10))
    bloque("Cabeza", c, "cuerpo", (-3, 3), (-18, -14), (10, 11), recorte={"y-": 1})
    par("Cabeza", c, "cuerpo_osc", (1, 2), (-17, -16), (11, 12))  # narinas
    # Ojos grandes en las esquinas de adelante: se ven de frente, de lado y de arriba.
    # Pupila de 2 x 3 hacia afuera (se ve también de lado) con un brillo arriba.
    par("Cabeza", c, "ojo", (2, 4), (-15, -12), (9, 13))
    par("Cabeza", c, "ojo", (4, 6), (-13, -12), (9, 13))
    par("Cabeza", c, "ojo", (4, 6), (-15, -13), (12, 13))
    par("Cabeza", c, "pupila", (4, 6), (-15, -13), (9, 11))
    par("Cabeza", c, "pupila", (5, 6), (-15, -13), (11, 12))
    par("Cabeza", c, "pupila", (4, 5), (-14, -13), (11, 12))
    par("Cabeza", c, "ojo", (4, 5), (-15, -14), (11, 12))  # brillo
    par("Cabeza", c, "mejilla", (3, 5), (-15, -14), (7, 8))
    # Aletas de pez: una en abanico a cada lado y una cresta arriba.
    # Las de los lados se abren hacia arriba desde z = 12 (el alto del borde del ala): al girar
    # la cabeza pasan por encima del hombro.
    par("Cabeza", "Aletas", "aleta", (5, 7), (-11, -9), (12, 15), eje="x", fin="-", recorte={"z+": 1})
    par("Cabeza", "Aletas", "aleta_osc", (7, 9), (-11, -9), (12, 16), eje="x", fin="-", recorte={"z+": 1})
    bloque("Cabeza", "Aletas", "aleta", (-1, 1), (-13, -9), (14, 16), recorte={"y-": 2})
    # Mandíbula: encías claras y la lengua en el medio (se ve al abrir).
    bloque("Mandibula", "Mandibula", "panza", (-3, 3), (-18, -11), (4, 5))
    par("Mandibula", "Mandibula", "panza", (2, 3), (-18, -11), (5, 6))
    bloque("Mandibula", "Mandibula", "boca", (-2, 2), (-18, -11), (5, 6))


def cuello_y_torso():
    t = "Torso"
    bloque("Cuello1", t, "cuerpo", (-2, 2), (-8, -5), (6, 12))
    bloque("Cuello1", t, "panza", (-1, 1), (-8, -5), (5, 6))
    bloque("Cuello2", t, "cuerpo", (-2, 2), (-10, -8), (7, 12))  # la mitad adentro de la cabeza
    bloque("Pecho", t, "cuerpo", (-4, 4), (-6, -1), (5, 11))
    bloque("Pecho", t, "cuerpo", (-4, 4), (-6, -1), (4, 5), fin="-", recorte={"x-": 1, "x+": 1})
    bloque("Pecho", t, "panza", (-2, 2), (-6, -1), (3, 4))
    bloque("Pecho", t, "panza", (-3, 3), (-7, -6), (4, 10))
    bloque("Pecho", "Aletas", "aleta", (-1, 1), (-5, -2), (11, 14), recorte={"y-": 3})
    bloque("Cadera", t, "cuerpo", (-3, 3), (-2, 4), (5, 10))
    bloque("Cadera", t, "panza", (-2, 2), (-1, 4), (4, 5))
    bloque("Cadera", "Aletas", "aleta", (-1, 1), (0, 2), (10, 12), recorte={"y-": 2})


def cola():
    c = "Cola"
    # (hueso, y desde, y hasta, medio ancho, z) del cuerpo de cada segmento.
    segmentos = [("Cola1", 3, 7, 2, (6, 9)), ("Cola2", 7, 9, 2, (6, 9)), ("Cola3", 9, 11, 2, (6, 8)),
                 ("Cola4", 11, 13, 1, (6, 8)), ("Cola5", 13, 15, 1, (6, 8)), ("Cola6", 15, 16, 1, (6, 8))]
    for i, (h, y0, y1, w, z) in enumerate(segmentos):
        bloque(h, c, "cuerpo", (-w, w), (y0, y1), z)
        if i:  # cuña 1:2 metida en el segmento anterior
            bloque(h, c, "cuerpo", (-w, w), (y0 - 2, y0), z, eje="y", fin="-",
                   recorte={"x-": 1, "x+": 1, "z-": 1, "z+": 1})
    bloque("Cola1", "Aletas", "aleta", (-1, 1), (4, 6), (9, 10), recorte={"y-": 1})
    bloque("Cola3", "Aletas", "aleta", (-1, 1), (9, 11), (8, 9), recorte={"y-": 2}, eje="z")
    # Aleta de la punta: dos lóbulos en abanico (horquilla), planos: se leen de arriba y abajo.
    par("Cola6", "Aletas", "aleta", (1, 5), (14, 18), (6, 7), eje="y", fin="-", recorte={"x+": 2})
    par("Cola6", "Aletas", "aleta_osc", (2, 3), (15, 18), (7, 8))


def alas():
    a = "Alas"
    # Cada segmento: borde de ataque grueso adelante, membrana atrás con una costilla oscura
    # (el "dedo" del ala) y el borde de fuga en cuña. Tejas: cada segmento empieza una celda
    # adentro del anterior y una celda más arriba (el diedro).
    # Ala1 (brazo del ala), del hombro, arriba del pecho.
    par("Ala{lado}1", a, "cuerpo", (4, 10), (-6, -4), (10, 12))
    par("Ala{lado}1", a, "aleta", (4, 6), (-4, 4), (10, 11))
    par("Ala{lado}1", a, "aleta_osc", (6, 7), (-4, 5), (10, 11))
    par("Ala{lado}1", a, "aleta", (7, 10), (-4, 2), (10, 11))
    par("Ala{lado}1", a, "aleta", (7, 10), (2, 4), (10, 11), eje="y", recorte={"x+": 2})
    # Ala2.
    par("Ala{lado}2", a, "cuerpo", (9, 15), (-5, -3), (11, 13))
    par("Ala{lado}2", a, "aleta", (9, 11), (-3, 3), (11, 12))
    par("Ala{lado}2", a, "aleta_osc", (11, 12), (-3, 4), (11, 12))
    par("Ala{lado}2", a, "aleta", (12, 15), (-3, 1), (11, 12))
    par("Ala{lado}2", a, "aleta", (12, 15), (1, 3), (11, 12), eje="y", recorte={"x+": 2})
    # Ala3 (punta): el borde termina en una garra y la membrana se afina hacia afuera.
    par("Ala{lado}3", a, "cuerpo", (14, 16), (-4, -2), (12, 14))
    par("Ala{lado}3", a, "garra", (16, 18), (-4, -2), (12, 14), eje="x", recorte={"y+": 1, "z+": 1})
    par("Ala{lado}3", a, "aleta", (14, 18), (-2, 2), (12, 13), eje="x", recorte={"y+": 2})


def patas():
    p = "Patas"
    # Recogidas hacia atrás, debajo del cuerpo (al quedarse quieto, Pose las cuelga).
    # Todas adentro de x = 4: el ala gira por el hombro (x = 4) y al bajar no las toca.
    par("Brazo{lado}", p, "cuerpo", (1, 4), (-5, -2), (2, 5))
    par("Antebrazo{lado}", p, "cuerpo", (2, 4), (-2, 1), (2, 4))
    par("Mano{lado}", p, "panza", (2, 4), (1, 3), (2, 3))
    par("Mano{lado}", p, "garra", (2, 4), (3, 4), (2, 3))
    par("Muslo{lado}", p, "cuerpo", (2, 4), (1, 5), (4, 8))
    par("Pierna{lado}", p, "cuerpo", (2, 4), (5, 7), (3, 5))
    par("Pie{lado}", p, "panza", (2, 4), (7, 9), (3, 4))
    par("Pie{lado}", p, "garra", (2, 4), (9, 10), (3, 4))


def construir():
    cabeza(); cuello_y_torso(); cola(); alas(); patas()


# --- Rig ------------------------------------------------------------------------------
# Hueso -> (padre, articulación en celdas). {l}: Izq en +x y Der espejado. Cadera y Cabeza a
# la misma altura: Dragon/Rig toma "adelante" de la cadera a la cabeza, y así es -y exacto.
ARTICULACIONES = [
    ("Cadera", None, (0, 1, 9)),
    ("Pecho", "Cadera", (0, -1, 9)),
    ("Cuello1", "Pecho", (0, -6, 9)),
    ("Cuello2", "Cuello1", (0, -8, 9)),
    ("Cabeza", "Cuello2", (0, -9, 9)),
    ("Mandibula", "Cabeza", (0, -11, 6)),  # borde de atrás y arriba de la mandíbula
    ("Cola1", "Cadera", (0, 4, 7.5)),
    ("Cola2", "Cola1", (0, 7, 7.5)),
    ("Cola3", "Cola2", (0, 9, 7)),
    ("Cola4", "Cola3", (0, 11, 7)),
    ("Cola5", "Cola4", (0, 13, 7)),
    ("Cola6", "Cola5", (0, 15, 7)),
    ("Ala{l}1", "Pecho", (4, -5, 11)),  # hombro: borde de arriba del pecho
    ("Ala{l}2", "Ala{l}1", (9.5, -4, 11)),  # bisagra en la cara de contacto de las tejas
    ("Ala{l}3", "Ala{l}2", (14.5, -3, 12)),
    ("Brazo{l}", "Pecho", (2.5, -3.5, 5)),
    ("Antebrazo{l}", "Brazo{l}", (3, -2, 3)),
    ("Mano{l}", "Antebrazo{l}", (3, 1, 2.5)),
    ("Muslo{l}", "Cadera", (3, 3, 7)),
    ("Pierna{l}", "Muslo{l}", (3, 5, 4)),
    ("Pie{l}", "Pierna{l}", (3, 7, 3.5)),
]
# Cola de cada hueso (celdas, lado izquierdo): hacia el hijo, o hacia donde apunta la pieza.
COLAS = {
    "Cadera": (0, 4, 9), "Pecho": (0, -6, 9), "Cuello1": (0, -8, 9), "Cuello2": (0, -9, 9),
    "Cabeza": (0, -18, 9), "Mandibula": (0, -18, 5),
    "Cola1": (0, 7, 7.5), "Cola2": (0, 9, 7), "Cola3": (0, 11, 7), "Cola4": (0, 13, 7),
    "Cola5": (0, 15, 7), "Cola6": (0, 18, 7),
    "Ala{l}1": (9.5, -4, 11), "Ala{l}2": (14.5, -3, 12), "Ala{l}3": (18, -3, 13),
    "Brazo{l}": (3, -2, 3), "Antebrazo{l}": (3, 1, 2.5), "Mano{l}": (3, 4, 2.5),
    "Muslo{l}": (3, 5, 4), "Pierna{l}": (3, 7, 3.5), "Pie{l}": (3, 10, 3.5),
}
# Huesos sin pesos: Raiz en el centro del cuerpo (el modelo gira alrededor de ella en las
# volteretas) y Boca en la punta del hocico, entre las mandíbulas (de ahí sale el fuego).
PUNTOS = {"Raiz": (None, (0, -2, 8), (0, -2, 11)), "Boca": ("Cabeza", (0, -18, 6), (0, -19, 6))}
