r"""
Dragón marino v2, etapa 1 (cría): los datos de la etapa para minotauro_v2_bloques.py
(--criatura dragon). Un dragón que se lee como dragón a primera vista: cabeza con hocico largo,
dos cuernos hacia atrás y cejas, cuello alzado en arco, púas en sierra por el lomo y la cola, alas
de murciélago (brazo, muñeca con garra y tres dedos en abanico con la membrana entre ellos y el
festón cóncavo), cola larga que termina en pala, placas en la panza y patas gruesas recogidas.
Del mar quedan los colores (turquesa, panza menta, membrana agua clara), las aletitas de las
mejillas y la pala de la cola; del fuego, el brillo naranja de la garganta.
Tierno igual: ojos grandes con brillo, cabeza grande, patas cortas.
Llega en pose de PLANEO, como espera Dragon/Rig: cuerpo horizontal, alas extendidas con un poco
de diedro (cada segmento del ala va una celda más arriba que el anterior), patas recogidas hacia
atrás y cola estirada.

Juntas (docs/estilo_modelos.md y docs/plan_dragon_v2.md, "Juntas"):
  - Cola: cada segmento mete una cuña 1:2 dentro del anterior (tapa la V que se abre al girar).
  - Alas: tejas. Cada segmento empieza una celda adentro del anterior y una celda más arriba;
    la bisagra va en la cara de contacto. La membrana es una lámina por segmento (partida en
    piezas convexas con las costuras bajo los dedos o las tejas) y los dedos van encima en relieve.
  - Cuello y cola salen de adentro de una pieza más grande (pecho, cadera, cabeza).
  - Ninguna cara de dos bloques en el mismo plano y mirando al mismo lado (parpadean): las piezas
    que se tocan lo hacen de frente, y dos piezas a la misma altura no se solapan.
Todo en celdas del módulo de la etapa (CELDA). Ejes: x = izquierda del dragón, -y = frente
(hocico), z arriba; centrado en x. Mide 36 celdas del hocico a la punta de la cola y 36 de punta a
punta de las alas. Las alas están en dragon_v2_e1_alas.py y las formas que no son bloques
(prismas, membranas, púas) en dragon_v2_formas.py.
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

for _f in ("dragon_v2_formas.py", "dragon_v2_e1_alas.py"):
    exec(open(os.path.join(HERE, _f), encoding="utf-8").read(), globals())


# --- Paleta (sRGB, docs/plan_dragon_v2.md) -----------------------------------------------
def _lineal(hexa):
    """sRGB "#RRGGBB" -> color lineal (lo que espera el Principled BSDF)."""
    c = [int(hexa[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return tuple(round(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4, 4) for x in c)


COLORES = {n: _lineal(h) for n, h in {
    "cuerpo": "#2FB9A2",  # turquesa verde: lomo, cabeza, patas, brazo y dedos del ala
    "panza": "#C9F2D4",  # placas de la panza y el cuello, mandíbula (menta clara)
    "aleta": "#62D8E6",  # membrana del ala, púas, aletitas y pala de la cola (agua clara)
    "cuerpo_osc": "#1C8C86",  # narinas
    "membrana_osc": "#45C2D9",  # la membrana junto al cuerpo, apenas más oscura
    "ojo": "#F4FAF7", "pupila": "#16222E",  # alto contraste, sin negro ni blanco puros
    "boca": "#B83A50", "garganta": "#FF8A3D",  # el fuego de la cría: brillo en la garganta
    "diente": "#F6EFDC", "garra": "#EDE3C6",  # garras y cuernos
}.items()}


# --- La cría, en celdas ------------------------------------------------------------------
def cabeza():
    c = "Cabeza"
    # Cráneo (8 de ancho) con la capa de abajo partida: boca y garganta en el medio.
    bloque(c, c, "cuerpo", (-4, 4), (-14, -9), (18, 22))
    bloque(c, c, "cuerpo", (-4, 4), (-14, -9), (22, 23), recorte={"x-": 1, "x+": 1})
    par(c, c, "cuerpo", (2, 4), (-14, -9), (17, 18))
    bloque(c, c, "boca", (-2, 2), (-14, -12), (17, 18))
    bloque(c, c, "garganta", (-2, 2), (-12, -9), (17, 18))
    # Hocico largo, más angosto y más bajo que el cráneo (4 celdas por delante de los ojos), con
    # la punta en cuña, las narinas oscuras arriba y la sonrisa roja con colmillitos.
    bloque(c, c, "cuerpo", (-3, 3), (-16, -14), (18, 21))
    bloque(c, c, "cuerpo", (-3, 3), (-18, -16), (18, 21), eje="y", fin="-",
           recorte={"x-": 1, "x+": 1, "z+": 1})
    par(c, c, "cuerpo_osc", (1, 2), (-17, -16), (20, 21))
    bloque(c, c, "boca", (-3, 3), (-18, -16), (17, 18), eje="y", fin="-", recorte={"x-": 1, "x+": 1})
    bloque(c, c, "boca", (-2, 2), (-16, -14), (17, 18))
    par(c, c, "diente", (2, 3), (-16, -15), (17, 18))
    par(c, c, "boca", (2, 3), (-15, -14), (17, 18))
    # Ojos a los costados del cráneo (3 x 3): pupila de 2 x 2 adelante y abajo con un brillo.
    par(c, c, "ojo", (4, 5), (-12, -11), (19, 22))
    par(c, c, "ojo", (4, 5), (-14, -12), (21, 22))
    par(c, c, "pupila", (4, 5), (-14, -13), (19, 21))
    par(c, c, "pupila", (4, 5), (-13, -12), (19, 20))
    par(c, c, "ojo", (4, 5), (-13, -12), (20, 21))  # brillo
    # Ceja en cuña sobre cada ojo, dos cuernos que suben y se curvan hacia atrás (la señal de
    # dragón más fuerte; la punta, más fina y hacia afuera) y una púa en la nuca, entre ellos.
    par_prisma(c, c, "cuerpo", [(-15, 22), (-11, 22), (-11, 24), (-13, 24)], (4, 5), eje="x")
    par_prisma(c, c, "garra", [(-12, 23), (-9, 23), (-8, 25), (-11, 25)], (2, 4), eje="x")
    par_prisma(c, c, "garra", [(-11, 25), (-8, 25), (-5, 28)], (3, 4), eje="x")
    espinas(c, "Puas", "aleta", [(-11, 23, 2)])
    # Aletitas de las mejillas, detrás de la mandíbula.
    par_prisma(c, "Aletas", "aleta", [(4, -13), (4, -10), (6, -9)], (17, 18))
    # Mandíbula: encías claras y la lengua en el medio (se ve al abrir); la punta en cuña. Termina
    # una celda antes del cuello (al girar la cabeza no lo toca) y la esquina de atrás y abajo va
    # en cuña 1:1: al abrir, gira por arriba y esa esquina pasa por delante del cuello.
    m = "Mandibula"
    bloque(m, m, "panza", (-3, 3), (-16, -12), (15, 16))
    bloque(m, m, "panza", (-3, 3), (-12, -11), (15, 16), eje="y", recorte={"z-": 1})
    bloque(m, m, "panza", (-3, 3), (-18, -16), (15, 16), eje="y", fin="-", recorte={"x-": 1, "x+": 1})
    par(m, m, "panza", (2, 3), (-16, -11), (16, 17))
    bloque(m, m, "boca", (-2, 2), (-16, -11), (16, 17))
    bloque(m, m, "panza", (-3, 3), (-18, -16), (16, 17), eje="y", fin="-", recorte={"x-": 1, "x+": 1})


def cuello_y_torso():
    t = "Torso"
    # Cuello en arco: sale del pecho y sube hasta la cabeza, que queda bien arriba del lomo. La
    # base es más ancha (6) que la punta (4): así la punta se mete en la base sin que sus
    # costados queden en el mismo plano. Placas de la panza en franjas por delante.
    bloque("Cuello1", t, "cuerpo", (-3, 3), (-8, -4), (8, 15))
    for z in ((8, 10), (11, 13)):
        bloque("Cuello1", t, "panza", (-2, 2), (-9, -8), z)
    bloque("Cuello2", t, "cuerpo", (-2, 2), (-10, -6), (13, 20))  # la punta, adentro de la cabeza
    # Pecho y cadera con la panza en cuña y las placas debajo.
    bloque("Pecho", t, "cuerpo", (-4, 4), (-7, -1), (5, 11))
    bloque("Pecho", t, "cuerpo", (-4, 4), (-7, -1), (4, 5), fin="-", recorte={"x-": 1, "x+": 1})
    bloque("Pecho", t, "panza", (-3, 3), (-8, -7), (5, 7))
    for y in ((-7, -5), (-4, -2)):
        bloque("Pecho", t, "panza", (-2, 2), y, (3, 4))
    bloque("Cadera", t, "cuerpo", (-3, 3), (-2, 4), (5, 10))
    bloque("Cadera", t, "cuerpo", (-3, 3), (-1, 4), (4, 5), fin="-", recorte={"x-": 1, "x+": 1})
    for y in ((-1, 1), (2, 4)):
        bloque("Cadera", t, "panza", (-2, 2), y, (3, 4))
    # Púas en sierra de la nuca a la cola, más chicas hacia la punta.
    espinas("Cuello2", "Puas", "aleta", [(-9, 20, 2)])
    espinas("Cuello1", "Puas", "aleta", [(-6, 15, 2)])
    espinas("Pecho", "Puas", "aleta", [(-4, 11, 3)])
    espinas("Cadera", "Puas", "aleta", [(-1, 10, 3), (2, 10, 2)])


def cola():
    c = "Cola"
    # (hueso, y desde, y hasta, medio ancho, z, púa) de cada segmento: se afina hacia la punta.
    segmentos = [("Cola1", 4, 6, 2, (5, 9), (4, 9, 2)), ("Cola2", 6, 8, 2, (6, 9), (6, 9, 2)),
                 ("Cola3", 8, 10, 1, (6, 9), (8, 9, 1)), ("Cola4", 10, 12, 1, (6, 8), (10, 8, 1)),
                 ("Cola5", 12, 14, 1, (6, 8), (12, 8, 1))]
    for h, y0, y1, w, z, pua in segmentos:
        bloque(h, c, "cuerpo", (-w, w), (y0, y1), z)
        bloque(h, c, "cuerpo", (-w, w), (y0 - 2, y0), z, eje="y", fin="-",
               recorte={"x-": 1, "x+": 1, "z-": 1, "z+": 1})  # cuña 1:2 metida en el anterior
        espinas(h, "Puas", "aleta", [pua])
    # Punta: la pala en rombo (punta de flecha de mar), plana para que se lea de arriba, con el
    # lomo de la cola que sigue encima.
    bloque("Cola6", c, "cuerpo", (-1, 1), (12, 14), (6, 8), eje="y", fin="-",
           recorte={"x-": 1, "x+": 1, "z-": 1, "z+": 1})
    prisma("Cola6", "Aletas", "aleta", [(-1, 14), (1, 14), (3, 15), (0, 18), (-3, 15)], (6, 7))
    prisma("Cola6", c, "cuerpo", [(-1, 14), (1, 14), (1, 15), (0, 17), (-1, 15)], (7, 8))


def patas():
    p = "Patas"
    # Recogidas hacia atrás, debajo del cuerpo (al quedarse quieto, Pose las cuelga), con garras
    # marfil. Todas adentro de x = 4: el ala gira por el hombro (x = 4) y al bajar no las toca.
    par("Brazo{lado}", p, "cuerpo", (1, 4), (-6, -3), (2, 5))
    par("Antebrazo{lado}", p, "cuerpo", (2, 4), (-3, 0), (1, 3))
    par("Mano{lado}", p, "cuerpo", (2, 4), (0, 2), (1, 2))
    par("Mano{lado}", p, "garra", (2, 4), (2, 3), (1, 2), eje="y", recorte={"z+": 1})
    par("Muslo{lado}", p, "cuerpo", (2, 4), (1, 5), (3, 7))  # bajo: la membrana pasa por encima al bajar
    par("Pierna{lado}", p, "cuerpo", (2, 4), (5, 8), (2, 4))
    par("Pie{lado}", p, "cuerpo", (2, 4), (8, 10), (2, 3))
    par("Pie{lado}", p, "garra", (2, 4), (10, 11), (2, 3), eje="y", recorte={"z+": 1})


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
    ("Cola3", "Cola2", (0, 8, 7.5)),
    ("Cola4", "Cola3", (0, 10, 7)),
    ("Cola5", "Cola4", (0, 12, 7)),
    ("Cola6", "Cola5", (0, 14, 7)),
    # Alas: bisagras en la cara de contacto de las tejas. El hombro, en el borde de arriba del
    # pecho y en el brazo del ala (si gira más atrás, el brazo se separa del pecho al plegar); las
    # otras dos, a la mitad del ala de adelante hacia atrás: al girar hacia atrás (aleteo y
    # picada) el borde de atrás barre la mitad que si girara por el borde de adelante.
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
    "Cabeza": (0, -18, 19), "Mandibula": (0, -18, 17),
    "Cola1": (0, 6, 7.5), "Cola2": (0, 8, 7.5), "Cola3": (0, 10, 7), "Cola4": (0, 12, 7),
    "Cola5": (0, 14, 7), "Cola6": (0, 18, 7),
    "Ala{l}1": (10.5, 0, 11), "Ala{l}2": (14.5, 0, 12), "Ala{l}3": (18, 0, 13),
    "Brazo{l}": (3, -3, 2.5), "Antebrazo{l}": (3, 0, 1.5), "Mano{l}": (3, 3, 1.5),
    "Muslo{l}": (3, 5, 3.5), "Pierna{l}": (3, 8, 2.5), "Pie{l}": (3, 11, 2.5),
}
# Huesos sin pesos: Raiz en el centro del cuerpo (el modelo gira alrededor de ella en las
# volteretas) y Boca en la punta del hocico, entre las mandíbulas (de ahí sale el fuego).
PUNTOS = {"Raiz": (None, (0, -2, 8), (0, -2, 11)), "Boca": ("Cabeza", (0, -18, 17), (0, -19, 17))}
