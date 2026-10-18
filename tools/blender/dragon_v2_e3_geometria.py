r"""
Dragón marino v2, etapa 3 (adulto): los datos de la etapa para minotauro_v2_bloques.py
(--criatura dragon). Es la referencia del usuario tal cual, en cubos: un dragón oscuro de alas
enormes de murciélago, cuello largo en S, cabeza en cuña con ceja marcada, cuernos y corona de púas
hacia atrás, una fila densa de púas con la punta encendida de la nuca a la cola, cola de látigo
que termina en un abanico de púas con aleta, patas traseras fuertes y delanteras finas recogidas.
El fuego sale de abajo: vientre de brasa, las puntas de las púas, las venas y el borde del ala, y
unas pocas grietas en el pecho (metidas un módulo entre placas, como el Minotauro E4). Del mar
quedan los ojos turquesa, las aletitas de las mejillas, la aleta del abanico de la cola y una
franja fina en el cuello.
Llega en pose de PLANEO, como espera Dragon/Rig: cuerpo horizontal, alas extendidas con un poco de
diedro (cada segmento del ala va una celda más arriba que el anterior), patas recogidas y cola
estirada.

Juntas (docs/plan_dragon_v2.md, "Juntas"): cola con cuñas 1:2 metidas en el segmento anterior,
alas en tejas, cuello y cola que salen de adentro de una pieza más grande (la punta del cuello baja
en cuña dentro de la base, por debajo de sus púas), mandíbula que termina una celda antes del
cuello con la esquina de atrás en cuña, púas apoyadas encima, patas adentro de x = 3 (el hombro)
con el muslo bajo, y nunca dos caras de bloques distintos en el mismo plano con área en común.
Todo en celdas del módulo (CELDA). Ejes: x = izquierda del dragón, -y = frente (hocico), z arriba;
centrado en x. Mide 36 celdas de punta a punta de las alas (la dimensión más larga) y 35 del hocico
a la punta de la cola. Las alas están en dragon_v2_e3_alas.py y las formas que no son bloques
(prismas, membranas) en dragon_v2_formas.py.
"""
CELDA = 0.5  # BU por celda (módulo de la etapa; docs/plan_dragon_v2.md, "Escala")
MODELO = "DragonMarino"
PREFIJO = "DragonV2_"
ALTO_JUEGO = 82.5  # studs: alto de la etapa (15 x 5.5, Config/Giants.luau)
LARGO_JUEGO = 0.6 * ALTO_JUEGO  # Dragon.LENGTH: GiantTemplates mide a los que vuelan a lo largo
VISTAS_EXTRA = (("arriba", 180, 8), ("abajo", 180, -8))  # la cabeza queda arriba en la imagen
PISO_BAJO = 1.0  # el piso más abajo: vuela

# Contrato de huesos del dragón (tools/blender/rig_dragon.py, Dragon/Rig y Dragon/Pose).
CONTRATO = ["Raiz", "Cadera", "Pecho", "Cuello1", "Cuello2", "Cabeza", "Mandibula", "Boca"]
CONTRATO += [f"Cola{i}" for i in range(1, 7)]
CONTRATO += [f"Ala{l}{i}" for l in ("Izq", "Der") for i in (1, 2, 3)]
CONTRATO += [f"{h}{l}" for l in ("Izq", "Der") for h in ("Brazo", "Antebrazo", "Mano", "Muslo", "Pierna", "Pie")]
CONTRATO_SIN_PESOS = ["Raiz", "Boca"]

for _f in ("dragon_v2_formas.py", "dragon_v2_e3_alas.py"):
    exec(open(os.path.join(HERE, _f), encoding="utf-8").read(), globals())


# --- Paleta (sRGB, columna E3 de la biblia del rediseño) ---------------------------------
def _lineal(hexa):
    """sRGB "#RRGGBB" -> color lineal (lo que espera el Principled BSDF)."""
    c = [int(hexa[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return tuple(round(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4, 4) for x in c)


COLORES = {n: _lineal(h) for n, h in {
    "cuerpo": "#2E211D",  # casi negro cálido: lomo, cabeza, patas, brazo y dedo de adelante del ala
    "cuerpo_osc": "#221816",  # ceja y nudo de la muñeca
    "vientre": "#B4502C",  # placas del vientre, el pecho, el cuello y la mandíbula (brasa apagada)
    "membrana": "#47231C",  # membrana del ala
    "borde": "#E0622A",  # venas y borde de la membrana: la brasa que asoma por el ala
    "pua": "#221714",  # base de las púas y ganchos del ala
    "brasa": "#FF7A2E",  # puntas encendidas de las púas y grietas del pecho
    "garra": "#CDBB98",  # cuernos, garras y dientes
    "ojo": "#3FE6D2",  # ojos turquesa brillante
    "turquesa": "#16808A",  # aletitas, aleta de la cola y franja del cuello
    "boca": "#7A2222",
}.items()}


# --- Ayudas: púas con la punta encendida ------------------------------------------------
def pua(parte, y0, z0, a, h, coleccion="Puas"):
    """Púa en sierra de x -1 a 1 que apunta hacia atrás: el frente sube de (y0, z0) a la punta
    (y0 + a, z0 + h) con pendiente h:a (1:1 o 2:1) y la espalda es recta. La última celda de
    alto (dos con 2:1) es la brasa."""
    t = 1 if h == a else 2
    base = [(y0, z0), (y0 + a, z0), (y0 + a, z0 + h - t), (y0 + a - 1, z0 + h - t)]
    prisma(parte, coleccion, "pua", base, (-1, 1), eje="x")
    prisma(parte, coleccion, "brasa", [(y0 + a - 1, z0 + h - t), (y0 + a, z0 + h - t), (y0 + a, z0 + h)],
           (-1, 1), eje="x")


def pua_en_cuesta(parte, y0, zt, coleccion="Puas"):
    """Púa sobre una cuesta 1:1 que baja hacia atrás (el cuello que sube hacia la cabeza): la base
    va por la cuesta de (y0, zt) a (y0 + 2, zt - 2) y la punta, encendida, en (y0 + 2, zt + 1)."""
    prisma(parte, coleccion, "pua", [(y0, zt), (y0 + 2, zt - 2), (y0 + 2, zt)], (-1, 1), eje="x")
    prisma(parte, coleccion, "brasa", [(y0, zt), (y0 + 2, zt), (y0 + 2, zt + 1)], (-1, 1), eje="x")


# --- El adulto, en celdas ------------------------------------------------------------------
def cabeza():
    c = "Cabeza"
    # Cráneo angosto (4 de ancho) con la frente plana, y el hocico largo que se afina en cuña,
    # una celda más bajo que la frente.
    bloque(c, c, "cuerpo", (-2, 2), (-14, -10), (11, 14))
    bloque(c, c, "cuerpo", (-2, 2), (-15, -14), (11, 13))
    bloque(c, c, "cuerpo", (-2, 2), (-17, -15), (11, 13), eje="y", fin="-",
           recorte={"x-": 1, "x+": 1, "z+": 1})
    # Ceja: el arco sobre el ojo sale una celda a cada lado y baja en cuña hacia el hocico.
    par_prisma(c, c, "cuerpo_osc", [(-15, 13), (-12, 13), (-12, 14), (-14, 14)], (2, 3), eje="x")
    # Ojos chicos y fieros bajo la ceja, y la mejilla con su púa hacia atrás.
    par(c, c, "ojo", (2, 3), (-14, -12), (12, 13))
    par(c, c, "cuerpo", (2, 3), (-12, -10), (11, 13))
    par_prisma(c, "Puas", "pua", [(-10, 11), (-9, 11), (-8, 12), (-10, 12)], (2, 3), eje="x")
    # Cuernos: salen de atrás del cráneo y van hacia atrás pegados a la línea de la cabeza, con la
    # punta apenas arriba. Terminan en y = -8: la muñeca del ala, al subir, pasa por detrás.
    par_prisma(c, c, "garra", [(-12, 13), (-10, 13), (-8, 14), (-10, 14)], (2, 3), eje="x")
    par_prisma(c, c, "garra", [(-10, 14), (-8, 14), (-8, 15)], (2, 3), eje="x")
    # Corona de púas detrás del cráneo, entre los cuernos.
    pua(c, -12, 14, 2, 2)
    # Aletitas de pez turquesa detrás de las mejillas.
    par_prisma(c, "Aletas", "turquesa", [(3, -12), (4, -11), (4, -9), (3, -10)], (11, 12))
    # Mandíbula: la cara de abajo de brasa, los dientes en el borde y la boca en el medio (se ve
    # al abrir); la punta en cuña. Termina una celda antes del cuello y la esquina de atrás y
    # abajo va en cuña 1:1.
    m = "Mandibula"
    bloque(m, m, "vientre", (-2, 2), (-15, -13), (9, 10))
    bloque(m, m, "vientre", (-2, 2), (-13, -12), (9, 10), eje="y", recorte={"z-": 1})
    bloque(m, m, "vientre", (-2, 2), (-17, -15), (9, 10), eje="y", fin="-", recorte={"x-": 1, "x+": 1})
    bloque(m, m, "boca", (-1, 1), (-15, -12), (10, 11))
    for y in ((-15, -14), (-13, -12)):
        par(m, m, "garra", (1, 2), y, (10, 11))
    par(m, m, "cuerpo", (1, 2), (-14, -13), (10, 11))
    bloque(m, m, "garra", (-2, 2), (-17, -15), (10, 11), eje="y", fin="-", recorte={"x-": 1, "x+": 1})
    par_prisma(m, "Puas", "pua", [(-13, 9), (-12, 9), (-11, 10), (-13, 10)], (2, 3), eje="x")


def cuello_y_torso():
    t = "Torso"
    # Cuello largo en S: la base sale baja del pecho, por debajo del ala, la punta sube 1:1 hasta
    # la nuca y el hocico baja otra vez (la cuña). La base es más ancha (4) que la punta (2), y la
    # punta entra en la base por debajo de su lomo (no toca sus púas).
    prisma("Cuello1", t, "cuerpo", [(-3, 5), (-3, 9), (-7, 9), (-7, 7)], (-2, 2), eje="x")
    prisma("Cuello1", t, "vientre", [(-5, 5), (-5, 6), (-7, 7), (-7, 6)], (-1, 1), eje="x")
    par_prisma("Cuello1", t, "turquesa", [(-5, 6), (-5, 7), (-7, 8), (-7, 7)], (2, 3), eje="x")
    bloque("Cuello2", t, "cuerpo", (-1, 1), (-7, -5), (7, 8))
    prisma("Cuello2", t, "cuerpo", [(-7, 7), (-7, 10), (-10, 13), (-11, 13), (-11, 11)], (-1, 1), eje="x")
    prisma("Cuello2", t, "vientre", [(-7, 6), (-7, 7), (-11, 11), (-11, 10)], (-1, 1), eje="x")
    par_prisma("Cuello2", t, "turquesa", [(-8, 8), (-8, 9), (-10, 11), (-10, 10)], (1, 2), eje="x")
    # Pecho hondo y cadera más angosta (cintura); el vientre de brasa debajo.
    bloque("Pecho", t, "cuerpo", (-3, 3), (-4, 0), (4, 10))
    bloque("Pecho", t, "vientre", (-3, 3), (-4, 0), (3, 4), fin="-", recorte={"x-": 1, "x+": 1})
    # Placas del pecho con la grieta de fuego metida un módulo entre ellas, y una grieta que asoma
    # en cada costado.
    bloque("Pecho", t, "brasa", (-3, 3), (-5, -4), (3, 5))
    par("Pecho", t, "vientre", (1, 3), (-6, -5), (3, 5))
    par("Pecho", t, "brasa", (3, 4), (-3, -2), (5, 6))
    par("Pecho", t, "brasa", (3, 4), (-2, -1), (4, 5))
    bloque("Cadera", t, "cuerpo", (-2, 2), (-1, 4), (5, 9))
    for y in ((0, 2), (2, 4)):
        bloque("Cadera", t, "vientre", (-1, 1), y, (4, 5))
    # Púas del lomo: densas, más grandes en los hombros y la cadera, con la punta encendida.
    pua_en_cuesta("Cuello2", -10, 13)
    pua("Cuello1", -7, 9, 2, 2)
    pua("Pecho", -4, 10, 2, 4)
    pua("Pecho", -2, 10, 2, 2)
    pua("Cadera", 0, 9, 2, 4)
    pua("Cadera", 2, 9, 2, 4)


def cola():
    c = "Cola"
    # (hueso, y desde, y hasta, medio ancho, z, recorte de la cuña): un látigo que se afina. Cada
    # cuña se mete 2 celdas en el segmento anterior y se recorta en los lados que quedarían en el
    # mismo plano que los de él.
    segmentos = [("Cola1", 4, 7, 2, (6, 9), {"x-": 1, "x+": 1, "z-": 1, "z+": 1}),
                 ("Cola2", 7, 9, 2, (6, 8), {"x-": 1, "x+": 1, "z-": 1}),
                 ("Cola3", 9, 11, 1, (6, 8), {"x-": 1, "x+": 1, "z-": 1, "z+": 1}),
                 ("Cola4", 11, 13, 1, (6, 8), {"x-": 1, "x+": 1, "z-": 1, "z+": 1}),
                 ("Cola5", 13, 15, 1, (6, 8), {"x-": 1, "x+": 1, "z-": 1, "z+": 1}),
                 ("Cola6", 15, 17, 1, (6, 7), None)]
    for h, y0, y1, w, z, rec in segmentos:
        bloque(h, c, "cuerpo", (-w, w), (y0, y1), z)
    for h, y0, y1, w, z, rec in segmentos[:-1]:
        bloque(h, c, "cuerpo", (-w, w), (y0 - 2, y0), z, eje="y", fin="-", recorte=rec)
    bloque("Cola6", c, "cuerpo", (-1, 1), (13, 15), (6, 7), eje="y", fin="-",
           recorte={"x-": 1, "x+": 1, "z-": 1})
    bloque("Cola6", c, "cuerpo", (-1, 1), (17, 18), (6, 7), eje="y", recorte={"x-": 1, "x+": 1})
    pua("Cola1", 4, 9, 3, 3)
    for h, y0, z0 in (("Cola2", 7, 8), ("Cola3", 9, 8), ("Cola4", 11, 8), ("Cola5", 13, 8), ("Cola6", 15, 7)):
        pua(h, y0, z0, 2, 2)
    # Punta: el abanico de púas encendidas con la aleta turquesa entre ellas, plano para que se
    # lea de arriba.
    par_prisma("Cola5", "Puas", "pua", [(1, 13), (3, 14), (3, 15), (1, 15)], (6, 7))
    par_prisma("Cola5", "Puas", "brasa", [(3, 14), (5, 15), (3, 15)], (6, 7))
    par_prisma("Cola6", "Aletas", "turquesa", [(3, 15), (5, 15), (5, 17), (3, 16)], (6, 7))
    par_prisma("Cola6", "Puas", "pua", [(1, 15), (3, 16), (3, 17), (1, 17)], (6, 7))
    par_prisma("Cola6", "Puas", "brasa", [(3, 16), (5, 17), (3, 17)], (6, 7))
    par_prisma("Cola6", "Puas", "brasa", [(1, 17), (2, 17), (3, 18)], (6, 7))
    par_prisma("Cola6", "Aletas", "turquesa", [(2, 17), (5, 17), (4, 18), (3, 18)], (6, 7))


def patas():
    p = "Patas"
    # Delanteras finas y cortas, recogidas bajo el pecho, con garras.
    par("Brazo{lado}", p, "cuerpo", (1, 2), (-3, -1), (1, 4))
    par("Antebrazo{lado}", p, "cuerpo", (1, 2), (-3, 0), (0, 1))
    par("Mano{lado}", p, "cuerpo", (1, 2), (0, 1), (0, 1))
    par("Mano{lado}", p, "garra", (1, 2), (1, 2), (0, 1), eje="y", recorte={"z+": 1})
    # Traseras fuertes de reptil: muslo grueso y bajo (la membrana pasa por encima al bajar),
    # pierna hacia atrás y pie con garras, colgando un poco hacia atrás.
    par_prisma("Muslo{lado}", p, "cuerpo", [(1, 6), (1, 4), (2, 3), (4, 3), (5, 4), (5, 5), (4, 6)], (1, 3), eje="x")
    par("Pierna{lado}", p, "cuerpo", (1, 3), (5, 7), (1, 5))
    par("Pie{lado}", p, "cuerpo", (1, 3), (6, 9), (0, 1))
    par("Pie{lado}", p, "garra", (1, 3), (9, 10), (0, 1), eje="y", recorte={"z+": 1})


def construir():
    cabeza(); cuello_y_torso(); cola(); alas(); patas()


# --- Rig ------------------------------------------------------------------------------
# Hueso -> (padre, articulación en celdas). {l}: Izq en +x y Der espejado. Cadera y Cabeza a
# la misma altura (z 12): Dragon/Rig toma "adelante" de la cadera a la cabeza, y así es -y exacto
# aunque la cabeza vaya arriba del lomo.
ARTICULACIONES = [
    ("Cadera", None, (0, 1, 12)),
    ("Pecho", "Cadera", (0, -0.5, 7)),
    ("Cuello1", "Pecho", (0, -3, 7)),
    ("Cuello2", "Cuello1", (0, -6, 8)),
    ("Cabeza", "Cuello2", (0, -11, 12)),
    ("Mandibula", "Cabeza", (0, -12, 11)),  # borde de atrás y arriba de la mandíbula
    ("Cola1", "Cadera", (0, 4, 7.5)),
    ("Cola2", "Cola1", (0, 7, 7)),
    ("Cola3", "Cola2", (0, 9, 7)),
    ("Cola4", "Cola3", (0, 11, 7)),
    ("Cola5", "Cola4", (0, 13, 7)),
    ("Cola6", "Cola5", (0, 15, 6.5)),
    # Alas: bisagras en la cara de contacto de las tejas; las de Ala2 y Ala3 a la mitad del ala.
    ("Ala{l}1", "Pecho", (3, -1, 10)),
    ("Ala{l}2", "Ala{l}1", (7.5, 0, 10)),
    ("Ala{l}3", "Ala{l}2", (12.5, -1, 11)),
    ("Brazo{l}", "Pecho", (1.5, -2, 3.5)),
    ("Antebrazo{l}", "Brazo{l}", (1.5, -2, 1)),
    ("Mano{l}", "Antebrazo{l}", (1.5, 0, 0.5)),
    ("Muslo{l}", "Cadera", (2, 1.5, 5)),
    ("Pierna{l}", "Muslo{l}", (2, 5, 4.5)),
    ("Pie{l}", "Pierna{l}", (2, 6.5, 1)),
]
# Cola de cada hueso (celdas, lado izquierdo): hacia el hijo, o hacia donde apunta la pieza.
COLAS = {
    "Cadera": (0, 4, 12), "Pecho": (0, -3, 7), "Cuello1": (0, -6, 8), "Cuello2": (0, -11, 12),
    "Cabeza": (0, -17, 12), "Mandibula": (0, -17, 10),
    "Cola1": (0, 7, 7), "Cola2": (0, 9, 7), "Cola3": (0, 11, 7), "Cola4": (0, 13, 7),
    "Cola5": (0, 15, 6.5), "Cola6": (0, 18, 6.5),
    "Ala{l}1": (7.5, 0, 10), "Ala{l}2": (12.5, -1, 11), "Ala{l}3": (18, -1, 12),
    "Brazo{l}": (1.5, -2, 1), "Antebrazo{l}": (1.5, 0, 0.5), "Mano{l}": (1.5, 2, 0.5),
    "Muslo{l}": (2, 5, 4.5), "Pierna{l}": (2, 6.5, 1), "Pie{l}": (2, 10, 0.5),
}
# Huesos sin pesos: Raiz en el centro del cuerpo (el modelo gira alrededor de ella en las
# volteretas) y Boca en la punta del hocico, entre las mandíbulas (de ahí sale el fuego).
PUNTOS = {"Raiz": (None, (0, -2, 7), (0, -2, 10)), "Boca": ("Cabeza", (0, -17, 10.5), (0, -18, 10.5))}
