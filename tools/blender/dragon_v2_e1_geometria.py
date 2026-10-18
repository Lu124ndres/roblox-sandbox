r"""
Dragón marino v2, etapa 1 (cría): los datos de la etapa para minotauro_v2_bloques.py
(--criatura dragon). Rediseño "referencia" (2026-10-17): la cría es el dragón oscuro de la
referencia del usuario en chiquito, en cubos y con toques marinos.

Lo que se lee de la referencia: alas enormes de murciélago (lo más largo del modelo), cuello que
sube en S con la cabeza adelante y arriba del lomo, cabeza en cuña (hocico que se afina, frente
plana y ceja marcada), cuernos que salen de atrás del cráneo hacia atrás, fila de púas de la nuca
a la cola con la punta encendida, pecho hondo y cintura angosta, patas traseras fuertes y
delanteras chicas recogidas, cola de látigo que termina en un abanico de púas. Colores oscuros
(marrón cálido) con brasa abajo: placas del vientre, venas y borde de la membrana, puntas de
las púas.
Lo de cría: cabeza grande con ojos grandes, cuernitos cortos, púas romas, cuello y cola cortos.
Lo marino (~15 %): ojos turquesa, aletitas de pez en las mejillas, la aleta turquesa del abanico
de la cola y escamas turquesa en los bordes de las placas del vientre y del cuello.
Llega en PLANEO, como espera Dragon/Rig: cuerpo horizontal, alas extendidas con un poco de diedro
(cada segmento del ala una celda más arriba que el anterior), patas recogidas y cola estirada.

Juntas (docs/plan_dragon_v2.md, "Juntas"; las articulaciones son las de la E1 anterior):
  - Cola: cada segmento mete una cuña 1:2 dentro del anterior (tapa la V que se abre al girar).
  - Alas: tejas (dragon_v2_e1_alas.py).
  - Cuello: la base (6 de ancho) es más ancha que la punta (4), que se mete en el cráneo.
  - Mandíbula: termina una celda antes del cuello, con la esquina de atrás y abajo en cuña 1:1.
  - Púas apoyadas encima del lomo; patas adentro de x = 4 y muslo bajo.
  - Ninguna cara de dos bloques en el mismo plano y mirando al mismo lado (parpadean).
Todo en celdas del módulo de la etapa (CELDA). Ejes: x = izquierda del dragón, -y = frente
(hocico), z arriba; centrado en x. Mide 36 celdas de punta a punta de las alas (lo más largo) y
34 del hocico a la punta de la cola.
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

for _f in ("dragon_v2_formas.py", "dragon_v2_e1_cabeza.py", "dragon_v2_e1_alas.py"):
    exec(open(os.path.join(HERE, _f), encoding="utf-8").read(), globals())


# --- Paleta (sRGB, columna E1 de la biblia del rediseño) ---------------------------------
def _lineal(hexa):
    """sRGB "#RRGGBB" -> color lineal (lo que espera el Principled BSDF)."""
    c = [int(hexa[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return tuple(round(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4, 4) for x in c)


COLORES = {n: _lineal(h) for n, h in {
    "cuerpo": "#5A3C30",  # marrón cálido: cabeza, cuello, costados, patas, brazo del ala
    "cuerpo_osc": "#462E25",  # lomo y narinas
    "vientre": "#D9864C",  # placas del vientre, del pecho y del cuello, garganta (brasa clara)
    "membrana": "#6E3A2C",
    "borde": "#C8643A",  # borde de atrás de la membrana y venas (dedos) del ala
    "pua": "#3A2620", "brasa": "#FF9A4A",  # púas: base oscura y punta encendida
    "garra": "#E8DCC0",  # cuernos, garras, dientes y ganchos de las alas
    "ojo": "#3FE6D2", "brillo": "#F4FAF7", "pupila": "#16222E",  # turquesa con brillo
    "turquesa": "#2FB9A2",  # aletas de las mejillas y de la cola, escamas del vientre
    "boca": "#8E2A2A",
}.items()}


def puas(parte, lista):
    """Púas romas en sierra sobre el lomo (x -1..1), apoyadas encima: (y del pie de adelante,
    z de la base, alto). El frente sube 1:1 y la espalda es recta; la última celda de arriba es
    la punta encendida (brasa) y el resto, la base oscura."""
    for y0, z0, alto in lista:
        if alto > 1:
            prisma(parte, "Puas", "pua", [(y0, z0), (y0 + alto, z0), (y0 + alto, z0 + alto - 1),
                                          (y0 + alto - 1, z0 + alto - 1)], (-1, 1), eje="x")
        prisma(parte, "Puas", "brasa", [(y0 + alto - 1, z0 + alto - 1), (y0 + alto, z0 + alto - 1),
                                        (y0 + alto, z0 + alto)], (-1, 1), eje="x")


def placas(parte, y, z, ancho=3):
    """Placa del vientre en franja (x -ancho..ancho) con las puntas en escamas turquesa."""
    bloque(parte, "Torso", "vientre", (-ancho + 1, ancho - 1), y, z)
    par(parte, "Torso", "turquesa", (ancho - 1, ancho), y, z)


# --- La cría, en celdas ------------------------------------------------------------------
def cuello_y_torso():
    t = "Torso"
    # Cuello en S: la base (6 de ancho) sale de arriba del pecho; la punta (4) sube hasta la
    # cabeza, que queda bien por delante y por encima del lomo. Lomo oscuro, placas por delante.
    bloque("Cuello1", t, "cuerpo", (-3, 3), (-8, -4), (8, 14))
    bloque("Cuello1", t, "cuerpo_osc", (-3, 3), (-8, -4), (14, 15))
    for z in ((9, 11), (12, 14)):
        placas("Cuello1", (-9, -8), z)
    bloque("Cuello2", t, "cuerpo", (-2, 2), (-10, -6), (13, 19))
    bloque("Cuello2", t, "cuerpo_osc", (-2, 2), (-10, -6), (19, 20))
    # Pecho hondo y cadera más angosta (la cintura), con la panza en cuña y las placas debajo.
    bloque("Pecho", t, "cuerpo", (-4, 4), (-7, -1), (5, 10))
    bloque("Pecho", t, "cuerpo_osc", (-4, 4), (-7, -1), (10, 11))
    bloque("Pecho", t, "cuerpo", (-4, 4), (-7, -1), (4, 5), fin="-", recorte={"x-": 1, "x+": 1})
    for z in ((4, 6), (6, 8)):
        bloque("Pecho", t, "vientre", (-2, 2), (-8, -7), z)
    for y in ((-7, -5), (-4, -2)):
        bloque("Pecho", t, "vientre", (-3, 3), y, (3, 4))
    bloque("Cadera", t, "cuerpo", (-3, 3), (-2, 4), (5, 9))
    bloque("Cadera", t, "cuerpo_osc", (-3, 3), (-2, 4), (9, 10))
    bloque("Cadera", t, "cuerpo", (-3, 3), (-1, 4), (4, 5), fin="-", recorte={"x-": 1, "x+": 1})
    for y in ((-1, 1), (2, 4)):
        placas("Cadera", y, (3, 4), 2)
    # Fila densa de púas de la nuca a la cola, más grandes en los hombros y la cadera.
    puas("Cuello2", [(-9, 20, 2)])
    puas("Cuello1", [(-6, 15, 2)])
    puas("Pecho", [(-4, 11, 3)])
    puas("Cadera", [(-1, 10, 3), (2, 10, 2)])


def cola():
    c = "Cola"
    # Látigo: (hueso, y desde, y hasta, medio ancho, z, púa) de cada segmento; se afina hacia la
    # punta y lleva una púa por segmento (la fila sigue sin cortes).
    segmentos = [("Cola1", 4, 6, 2, (6, 9), (4, 9, 2)), ("Cola2", 6, 8, 1, (6, 9), (6, 9, 2)),
                 ("Cola3", 8, 10, 1, (6, 8), (8, 8, 2)), ("Cola4", 10, 12, 1, (6, 8), (10, 8, 2)),
                 ("Cola5", 12, 14, 1, (6, 8), (12, 8, 1))]
    for h, y0, y1, w, z, pua in segmentos:
        bloque(h, c, "cuerpo", (-w, w), (y0, y1), z)
        bloque(h, c, "cuerpo", (-w, w), (y0 - 2, y0), z, eje="y", fin="-",
               recorte={"x-": 1, "x+": 1, "z-": 1, "z+": 1})  # cuña 1:2 metida en el anterior
        puas(h, [pua])
    # Punta: abanico de púas (tres rayos encendidos) con la aleta turquesa entre ellos, plano
    # para que se lea de arriba; el lomo de la cola sigue encima de la aleta.
    h = "Cola6"
    bloque(h, c, "cuerpo", (-1, 1), (12, 14), (6, 8), eje="y", fin="-",
           recorte={"x-": 1, "x+": 1, "z-": 1, "z+": 1})
    bloque(h, c, "cuerpo", (-1, 1), (14, 15), (7, 8))
    lamina(h, "Aletas", "turquesa", [(-1, 14), (1, 14), (3, 16), (1, 15), (0, 17), (-1, 15), (-3, 16)],
           (6, 7))
    prisma(h, c, "brasa", [(-1, 15), (1, 15), (0, 17)], (7, 8))
    par_prisma(h, c, "pua", [(1, 14), (2, 14), (3, 16)], (7, 8))


def patas():
    p = "Patas"
    # Delanteras chicas, recogidas bajo el pecho; traseras fuertes (muslo grueso) colgando un poco
    # hacia atrás, con garras marfil. Todas adentro de x = 4: el ala gira por el hombro (x = 4) y
    # al bajar no las toca.
    par("Brazo{lado}", p, "cuerpo", (2, 4), (-6, -3), (2, 5))
    par("Antebrazo{lado}", p, "cuerpo", (2, 4), (-3, 0), (1, 3))
    par("Mano{lado}", p, "cuerpo", (2, 4), (0, 2), (1, 2))
    par("Mano{lado}", p, "garra", (2, 4), (2, 3), (1, 2), eje="y", recorte={"z+": 1})
    par("Muslo{lado}", p, "cuerpo", (2, 4), (1, 5), (3, 7))  # bajo: la membrana pasa por encima
    par("Pierna{lado}", p, "cuerpo", (2, 4), (5, 8), (2, 4))
    par("Pie{lado}", p, "cuerpo", (2, 4), (8, 10), (1, 3))
    par("Pie{lado}", p, "garra", (2, 4), (10, 11), (1, 3), eje="y", recorte={"z+": 1})


def construir():
    cabeza(); cuello_y_torso(); cola(); alas(); patas()


# --- Rig ------------------------------------------------------------------------------
# Hueso -> (padre, articulación en celdas). {l}: Izq en +x y Der espejado. Cadera y Cabeza a
# la misma altura (z 15): Dragon/Rig toma "adelante" de la cadera a la cabeza, y así es -y
# exacto aunque la cabeza vaya arriba del lomo (la Cadera gira por encima del cuerpo: solo se
# usa para cabecear todo el cuerpo un poco al subir o bajar).
ARTICULACIONES = [
    ("Cadera", None, (0, 1, 15)),
    ("Pecho", "Cadera", (0, -1, 9)),
    ("Cuello1", "Pecho", (0, -6, 10)),
    ("Cuello2", "Cuello1", (0, -8, 13)),
    ("Cabeza", "Cuello2", (0, -10, 15)),
    ("Mandibula", "Cabeza", (0, -11, 17)),  # borde de atrás y arriba de la mandíbula
    ("Cola1", "Cadera", (0, 4, 7)),
    ("Cola2", "Cola1", (0, 6, 7.5)),
    ("Cola3", "Cola2", (0, 8, 7)),
    ("Cola4", "Cola3", (0, 10, 7)),
    ("Cola5", "Cola4", (0, 12, 7)),
    ("Cola6", "Cola5", (0, 14, 7)),
    # Alas: bisagras en la cara de contacto de las tejas. El hombro, en el borde de arriba del
    # pecho y en el brazo del ala; las otras dos, a la mitad del ala de adelante hacia atrás.
    ("Ala{l}1", "Pecho", (4, -2, 11)),
    ("Ala{l}2", "Ala{l}1", (10.5, 0, 11)),
    ("Ala{l}3", "Ala{l}2", (14.5, 0, 12)),
    ("Brazo{l}", "Pecho", (3, -5, 5)),
    ("Antebrazo{l}", "Brazo{l}", (3, -3, 2.5)),
    ("Mano{l}", "Antebrazo{l}", (3, 0, 1.5)),
    ("Muslo{l}", "Cadera", (3, 2, 6)),
    ("Pierna{l}", "Muslo{l}", (3, 5, 3.5)),
    ("Pie{l}", "Pierna{l}", (3, 8, 2.5)),
]
# Cola de cada hueso (celdas, lado izquierdo): hacia el hijo, o hacia donde apunta la pieza.
COLAS = {
    "Cadera": (0, 4, 15), "Pecho": (0, -6, 9), "Cuello1": (0, -8, 13), "Cuello2": (0, -10, 15),
    "Cabeza": (0, -17, 19), "Mandibula": (0, -17, 16),
    "Cola1": (0, 6, 7.5), "Cola2": (0, 8, 7), "Cola3": (0, 10, 7), "Cola4": (0, 12, 7),
    "Cola5": (0, 14, 7), "Cola6": (0, 17, 7),
    "Ala{l}1": (10.5, 0, 11), "Ala{l}2": (14.5, 0, 12), "Ala{l}3": (18, 0, 13),
    "Brazo{l}": (3, -3, 2.5), "Antebrazo{l}": (3, 0, 1.5), "Mano{l}": (3, 3, 1.5),
    "Muslo{l}": (3, 5, 3.5), "Pierna{l}": (3, 8, 2.5), "Pie{l}": (3, 11, 2),
}
# Huesos sin pesos: Raiz en el centro del cuerpo (el modelo gira alrededor de ella en las
# volteretas) y Boca en la punta del hocico, entre las mandíbulas (de ahí sale el fuego).
PUNTOS = {"Raiz": (None, (0, -2, 8), (0, -2, 11)), "Boca": ("Cabeza", (0, -17, 17), (0, -18, 17))}
