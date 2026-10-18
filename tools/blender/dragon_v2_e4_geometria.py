r"""
Dragón marino v2, etapa 4 (anciano, forma final): los datos de la etapa para minotauro_v2_bloques.py
(--criatura dragon). La referencia del usuario (un dragón oscuro estilo wyvern de alas enormes) en
su versión más épica y masiva, en bloques, con toques de mar:
  - Casi negro y acorazado, con GRIETAS DE LAVA en vetas continuas de una celda que siguen las
    juntas entre placas: cada parte del cuerpo es un núcleo de lava envuelto en placas y las vetas
    son las rendijas entre ellas, que se cruzan en T (acorazado(), dragon_v2_e4_formas.py). Nunca
    puntos sueltos.
  - Cabeza en cuña con cejas marcadas, ojos turquesa claro chicos y fieros, la boca con la costura
    de lava y colmillos, corona de cuernos hacia atrás y aletitas turquesa (dragon_v2_e4_cabeza.py).
  - Cuello largo en S con la garganta de lava (una veta por debajo, de la mandíbula al pecho) y una
    franja turquesa a cada lado; pecho hondo, cintura y cadera más angostas abajo, patas traseras
    fuertes que cuelgan y delanteras finas recogidas; fila de púas grandes con la punta de brasa
    (más grandes en los hombros y la cadera).
  - Cola de látigo larguísima que baja apenas y se afina, con la panza de lava y una púa con
    brasa en cada segmento, que termina en un abanico de púas con la aleta turquesa oscuro.
  - Alas descomunales (dragon_v2_e4_alas.py): festón en escalones, ganchos y borde de lava.
Llega en PLANEO (como espera Dragon/Rig): cuerpo horizontal, alas extendidas con diedro (cada
segmento una celda más arriba), patas traseras colgando y delanteras recogidas, cola estirada.

Juntas: las de docs/plan_dragon_v2.md ("Juntas"). Ejes: x = izquierda del dragón, -y = hocico,
z arriba; centrado en x. Todo en celdas del módulo (CELDA = 1 BU). Mide 36 celdas de punta a punta
de las alas (99 studs) y 35 del hocico (y -17) a la punta de la cola (y 18).
"""
CELDA = 1.0  # BU por celda (módulo de la etapa; docs/plan_dragon_v2.md, "Escala")
MODELO = "DragonMarino"
PREFIJO = "DragonV2_"
ALTO_JUEGO = 165.0  # studs: alto de la etapa (30 x 5.5, Config/Giants.luau)
LARGO_JUEGO = 0.6 * ALTO_JUEGO  # Dragon.LENGTH: GiantTemplates mide a los que vuelan a lo largo
VISTAS_EXTRA = (("arriba", 180, 8), ("abajo", 180, -8))  # la cabeza queda arriba en la imagen
PISO_BAJO = 1.0  # el piso más abajo: vuela

# Contrato de huesos del dragón (tools/blender/rig_dragon.py, Dragon/Rig y Dragon/Pose).
CONTRATO = ["Raiz", "Cadera", "Pecho", "Cuello1", "Cuello2", "Cabeza", "Mandibula", "Boca"]
CONTRATO += [f"Cola{i}" for i in range(1, 7)]
CONTRATO += [f"Ala{l}{i}" for l in ("Izq", "Der") for i in (1, 2, 3)]
CONTRATO += [f"{h}{l}" for l in ("Izq", "Der") for h in ("Brazo", "Antebrazo", "Mano", "Muslo", "Pierna", "Pie")]
CONTRATO_SIN_PESOS = ["Raiz", "Boca"]

for _f in ("dragon_v2_formas.py", "dragon_v2_e4_formas.py", "dragon_v2_e4_cabeza.py", "dragon_v2_e4_alas.py"):
    exec(open(os.path.join(HERE, _f), encoding="utf-8").read(), globals())


# --- Paleta (sRGB, columna E4 de la biblia del rediseño) ---------------------------------
def _lineal(hexa):
    """sRGB "#RRGGBB" -> color lineal (lo que espera el Principled BSDF)."""
    c = [int(hexa[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return tuple(round(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4, 4) for x in c)


COLORES = {n: _lineal(h) for n, h in {
    "cuerpo": "#1A1314",  # casi negro: costados, cabeza, patas, brazo y dedos del ala
    "cuerpo_osc": "#110C0D",  # placas del lomo y cejas
    "vientre": "#8E3A22",  # placas del vientre y el pecho, la mandíbula
    "membrana": "#2E1714",
    "lava": "#FF9938",  # vetas y borde de la membrana (en Roblox: Neon o luz)
    "garganta": "#FF7A2E",  # la boca por dentro
    "pua": "#150F0F", "pua_brasa": "#FFB050",
    "marfil": "#BFA982",  # cuernos, garras, dientes y ganchos de las alas
    "ojo": "#7FFFE8", "ojo_claro": "#E2FFF9",
    "turquesa": "#1C6A73", "turquesa_osc": "#124A52",  # aletas, abanico de la cola, franjas
}.items()}


# --- El anciano, en celdas ----------------------------------------------------------------
def torso():
    t = "Torso"
    lomo = [("x", 2, ["z+"]), ("x", -3, ["z+"])]  # juntas a lo largo del lomo, junto a las púas
    # Pecho hondo (8 de ancho, 7 de alto) con las placas del vientre por delante. Juntas: la línea
    # de la garganta sigue por el medio del pecho, por debajo y sube por detrás hasta la panza de
    # la cadera (una sola veta de la mandíbula a la punta de la cola); a cada costado una línea
    # (z 8) con las juntas de arriba y de abajo corridas (en T, como placas), y una que cruza el lomo.
    medio = [("x", 0, ["y-", "z-"]), ("x", -1, ["y-", "z-"]),
             ("x", 0, ["y+"], ("z", 4, 6)), ("x", -1, ["y+"], ("z", 4, 6))]
    acorazado("Pecho", t, ((-4, 4), (-4, 0), (4, 11)),
              lomo + medio + [("z", 8, ["x+", "x-"]), ("y", -2, ["x+", "x-", "z+"], ("z", 9, 11)),
                              ("y", -3, ["x+", "x-"], ("z", 4, 8))],
              caras={"y-": "vientre"})
    # Cadera: una celda más baja que el pecho (el lomo baja hacia la cola), con un escalón de lava
    # a cada costado bajo la raíz del ala (la línea del costado del pecho sigue por ahí): al bajar
    # el ala, la cara de abajo de la membrana barre hacia adentro por encima del escalón. Abajo,
    # más angosta (la cintura, debajo cuelgan los muslos). Las piezas que se mueven una contra
    # otra se tocan cara con cara o con un tapón chico que entra en la otra por un lugar macizo
    # (sin juntas de placas): ninguna cara queda en el plano de otra.
    acorazado("Cadera", t, ((-3, 3), (0, 4), (8, 10)),
              [("x", 1, ["z+"]), ("x", -2, ["z+"]), ("y", 2, ["x+", "x-", "z+"]), ("z", 9, ["y+"])],
              abiertas=["z-"])
    par("Cadera", t, "lava", (3, 4), (0, 4), (8, 9))
    bloque("Cadera", t, "cuerpo", (-3, 3), (0, 4), (7, 8))
    par("Cadera", t, "cuerpo", (1, 3), (0, 4), (6, 7))
    bloque("Cadera", t, "lava", (-1, 1), (0, 4), (6, 7))  # la panza de lava, metida: sigue en la cola
    # Cuello en S: la base (6 de ancho) sale del pecho y sube; la punta (4) sube más y entra en la
    # cabeza. Garganta de lava: una veta de dos de ancho por debajo, de punta a punta; un anillo
    # en cada uno y una franja turquesa a cada lado.
    acorazado("Cuello1", t, ((-3, 3), (-8, -4), (8, 13)),
              [("x", 0, ["z-"]), ("x", -1, ["z-"]), ("y", -6, None), ("z", 9, ["x+", "x-"])],
              franjas=[("z", 11, ["x+", "x-"], "turquesa")])
    bloque("Cuello1", t, "cuerpo", (-2, 2), (-6, -2), (7, 8))  # tapón en el pecho
    acorazado("Cuello2", t, ((-2, 2), (-12, -8), (11, 15)),
              [("x", 0, ["z-"]), ("x", -1, ["z-"]), ("y", -10, ["x+", "x-", "z+"])],
              franjas=[("z", 12, ["x+", "x-"], "turquesa")])
    bloque("Cuello2", t, "cuerpo", (-1, 1), (-9, -6), (10, 11))  # tapón en la base del cuello
    # Fila de púas con la punta de brasa, más grandes en los hombros y la cadera.
    espina_brasa("Cuello2", -10, 15, 2, 2, 2, 1)
    espina_brasa("Cuello1", -7, 13, 2, 2, 0, 1)
    espina_brasa("Cuello1", -5, 13, 2, 2, 0, 1)
    espina_brasa("Pecho", -3, 11, 2, 4, 2, 2)
    espina_brasa("Cadera", 0, 10, 2, 4, 2, 2)


def cola():
    c = "Cola"
    # (hueso, y desde, y hasta, medio ancho, z abajo, z arriba): látigo que se afina y baja
    # apenas, con la panza de lava (metida una celda en los segmentos anchos) y una púa con brasa.
    segmentos = [("Cola1", 4, 6, 2, 7, 10), ("Cola2", 6, 8, 2, 7, 10), ("Cola3", 8, 10, 1, 7, 9),
                 ("Cola4", 10, 12, 1, 7, 9), ("Cola5", 12, 14, 1, 7, 9)]
    for h, y0, y1, w, z0, z1 in segmentos:
        if w > 1:
            bloque(h, c, "cuerpo", (-w, w), (y0, y1), (z0 + 1, z1))
            par(h, c, "cuerpo", (1, w), (y0, y1), (z0, z0 + 1))
            bloque(h, c, "lava", (-1, 1), (y0, y1), (z0, z0 + 1))
        else:
            bloque(h, c, "cuerpo", (-w, w), (y0, y1), (z0 + 1, z1))
            bloque(h, c, "lava", (-w, w), (y0, y1), (z0, z0 + 1))  # la panza encendida
        # Cuña 1:2 con toda la sección, metida en el anterior (tapa la V que se abre al girar).
        bloque(h, c, "cuerpo", (-w, w), (y0 - 2, y0), (z0, z1), eje="y", fin="-",
               recorte={"x-": 1, "x+": 1, "z-": 1, "z+": 1})
        espina_brasa(h, y0, z1, 2, 2, 0, 1)
    # Punta (Cola6): abanico de púas (la del medio y dos por lado) con la aleta turquesa oscuro
    # entre ellas, plano para que se lea desde arriba.
    h = "Cola6"
    bloque(h, c, "cuerpo", (-1, 1), (14, 16), (8, 9))
    bloque(h, c, "lava", (-1, 1), (14, 16), (7, 8))
    bloque(h, c, "cuerpo", (-1, 1), (12, 14), (7, 9), eje="y", fin="-",
           recorte={"x-": 1, "x+": 1, "z-": 1, "z+": 1})
    espina_brasa(h, 14, 9, 2, 2, 0, 1)
    bloque(h, c, "pua", (-1, 1), (16, 17), (6, 9))
    prisma(h, c, "pua_brasa", [(-1, 17), (1, 17), (0, 18)], (6, 9))
    # La aleta llena entre las púas sin meterse en ellas (se tocan cara con cara).
    par_lamina(h, c, "turquesa_osc", [(1, 14), (2, 15), (4, 16), (2, 17), (2, 16), (1, 15)], (7, 8))
    par_prisma(h, c, "pua", [(1, 14), (3, 15), (2, 15)], (6, 9))
    par_prisma(h, c, "pua_brasa", [(2, 15), (3, 15), (5, 16), (4, 16)], (6, 9))
    par_prisma(h, c, "pua", [(1, 15), (2, 16), (1, 16)], (6, 9))
    par_prisma(h, c, "pua_brasa", [(1, 16), (2, 16), (2, 18)], (6, 9))


def patas():
    p = "Patas"
    # Delanteras finas y cortas, recogidas bajo el pecho, con garras marfil. Traseras fuertes de
    # reptil: el muslo acorazado con un anillo de lava, la pierna y el pie colgando un poco hacia
    # atrás. Todo adentro de x = 4: el ala gira por el hombro (x = 4) y al bajar no las toca.
    par("Brazo{lado}", p, "cuerpo", (1, 3), (-3, -1), (1, 4))
    par("Antebrazo{lado}", p, "cuerpo", (1, 3), (-1, 1), (0, 2))
    par("Mano{lado}", p, "cuerpo", (1, 3), (1, 2), (-1, 1))
    par("Mano{lado}", p, "marfil", (1, 3), (2, 3), (-1, 0), eje="y", recorte={"z+": 1})
    # El muslo cuelga debajo de la cintura, detrás del pecho: al colgar (quieto en el aire) gira
    # hacia adelante sin entrar en él.
    acorazado("Muslo{lado}", p, ((1, 4), (2, 5), (3, 6)), [("z", 4, ["x+", "y-", "y+"])],
              lado=True, caras={"z-": "cuerpo"})
    par("Pierna{lado}", p, "cuerpo", (2, 4), (4, 6), (0, 3))
    par("Pie{lado}", p, "cuerpo", (2, 4), (5, 8), (-1, 0))
    par("Pie{lado}", p, "marfil", (3, 4), (8, 10), (-1, 0), eje="y", recorte={"x-": 1})
    par("Pie{lado}", p, "marfil", (2, 3), (8, 9), (-1, 0), eje="y", recorte={"x+": 1})


def construir():
    cabeza(); torso(); cola(); alas(); patas()


# --- Rig ------------------------------------------------------------------------------
# Hueso -> (padre, articulación en celdas). {l}: Izq en +x y Der espejado. Cadera y Cabeza a la
# misma altura (z 14): Dragon/Rig toma "adelante" de la cadera a la cabeza, y así es -y exacto
# aunque la cabeza vaya arriba del lomo (la Cadera gira por encima del cuerpo: solo cabecea todo el
# cuerpo un poco al subir o bajar).
ARTICULACIONES = [
    ("Cadera", None, (0, 1, 14)),
    ("Pecho", "Cadera", (0, 0, 8)),
    ("Cuello1", "Pecho", (0, -4, 10)),
    ("Cuello2", "Cuello1", (0, -8, 12)),
    ("Cabeza", "Cuello2", (0, -11, 14)),
    ("Mandibula", "Cabeza", (0, -13, 12)),  # borde de atrás y arriba de la mandíbula
    ("Cola1", "Cadera", (0, 4, 8.5)),
    ("Cola2", "Cola1", (0, 6, 8.5)),
    ("Cola3", "Cola2", (0, 8, 8)),
    ("Cola4", "Cola3", (0, 10, 8)),
    ("Cola5", "Cola4", (0, 12, 7.5)),
    ("Cola6", "Cola5", (0, 14, 7)),
    # Alas: el hombro en el brazo del ala, en el borde de arriba del pecho; las otras dos bisagras en
    # la cara de contacto de las tejas, a la mitad del ala de adelante hacia atrás.
    ("Ala{l}1", "Pecho", (4, -3, 11)),
    ("Ala{l}2", "Ala{l}1", (9.5, 0, 11)),
    ("Ala{l}3", "Ala{l}2", (13.5, 0, 12)),
    ("Brazo{l}", "Pecho", (2, -2, 4)),
    ("Antebrazo{l}", "Brazo{l}", (2, -1, 1.5)),
    ("Mano{l}", "Antebrazo{l}", (2, 1, 0.5)),
    ("Muslo{l}", "Cadera", (2.5, 3.5, 5.5)),
    ("Pierna{l}", "Muslo{l}", (3, 5, 3)),
    ("Pie{l}", "Pierna{l}", (3, 5.5, 0)),
]
# Cola de cada hueso (celdas, lado izquierdo): hacia el hijo, o hacia donde apunta la pieza.
COLAS = {
    "Cadera": (0, 4, 14), "Pecho": (0, -4, 8), "Cuello1": (0, -8, 12), "Cuello2": (0, -11, 14),
    "Cabeza": (0, -17, 14), "Mandibula": (0, -17, 11),
    "Cola1": (0, 6, 8.5), "Cola2": (0, 8, 8), "Cola3": (0, 10, 8), "Cola4": (0, 12, 7.5),
    "Cola5": (0, 14, 7), "Cola6": (0, 18, 7),
    "Ala{l}1": (9.5, 0, 11), "Ala{l}2": (13.5, 0, 12), "Ala{l}3": (18, 0, 13),
    "Brazo{l}": (2, -1, 1.5), "Antebrazo{l}": (2, 1, 0.5), "Mano{l}": (2, 3, -0.5),
    "Muslo{l}": (3, 5, 3), "Pierna{l}": (3, 5.5, 0), "Pie{l}": (3, 10, -0.5),
}
# Huesos sin pesos: Raiz en el centro del cuerpo (el modelo gira alrededor de ella en las
# volteretas) y Boca en la punta del hocico, entre las mandíbulas (de ahí sale el fuego).
PUNTOS = {"Raiz": (None, (0, -2, 8), (0, -2, 11)), "Boca": ("Cabeza", (0, -17, 12), (0, -18, 12))}
