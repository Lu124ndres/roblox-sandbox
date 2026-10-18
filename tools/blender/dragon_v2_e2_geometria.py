r"""
Dragón marino v2, etapa 2 (joven): los datos de la etapa para minotauro_v2_bloques.py
(--criatura dragon). Rediseño "referencia" (biblia del 2026-10-17): un dragón oscuro estilo wyvern
de alas enormes, en bloques, con toques marinos turquesa. El joven es la referencia en versión
adolescente: cuello y cola más largos que la cría, cabeza en cuña con ceja marcada y cuernos
medianos que salen de atrás del cráneo hacia atrás, púas filosas con la punta de brasa de la nuca a
la cola, alas de murciélago enormes con el festón hondo y las puntas en gancho, cola de látigo que
termina en un abanico de púas con aleta turquesa, ojos turquesa y aletitas turquesa en las mejillas.
Llega en pose de PLANEO, como espera Dragon/Rig: cuerpo horizontal, alas extendidas con diedro
(cada segmento del ala va una celda más arriba que el anterior), patas traseras colgando un poco
hacia atrás, delanteras recogidas bajo el pecho, cola estirada y cuello adelante con la cabeza
más alta que el lomo.

Juntas (docs/plan_dragon_v2.md, "Juntas"):
  - Cola: cada segmento mete una cuña 1:2 dentro del anterior (tapa la V que se abre al girar).
  - Alas en tejas (dragon_v2_e2_alas.py): cada segmento empieza una celda adentro del anterior y
    una más arriba; la bisagra va en la cara de contacto.
  - Cuello y cola salen de adentro de una pieza más grande (pecho, cadera, cabeza).
  - Ninguna cara de dos bloques en el mismo plano y mirando al mismo lado (parpadean): las piezas
    que se tocan lo hacen de frente, y dos piezas a la misma altura no se solapan.
Todo en celdas del módulo de la etapa (CELDA = 0.3 BU). Ejes: x = izquierda del dragón, -y = frente
(hocico), z arriba; centrado en x. Mide 32 celdas de punta a punta de las alas (9.6 BU = 26.4
studs) y 31 del hocico a la punta de la cola. Las alas están en dragon_v2_e2_alas.py y las formas
que no son bloques (prismas, membranas) en dragon_v2_formas.py.
"""
CELDA = 0.3  # BU por celda (módulo de la etapa; docs/plan_dragon_v2.md, "Escala")
MODELO = "DragonMarino"
PREFIJO = "DragonV2_"
ALTO_JUEGO = 44.0  # studs: alto de la etapa (8 x 5.5, Config/Giants.luau)
LARGO_JUEGO = 0.6 * ALTO_JUEGO  # Dragon.LENGTH: GiantTemplates mide a los que vuelan a lo largo
VISTAS_EXTRA = (("arriba", 180, 8), ("abajo", 180, -8))  # la cabeza queda arriba en la imagen
PISO_BAJO = 1.0  # el piso más abajo: vuela

# Contrato de huesos del dragón (tools/blender/rig_dragon.py, Dragon/Rig y Dragon/Pose).
CONTRATO = ["Raiz", "Cadera", "Pecho", "Cuello1", "Cuello2", "Cabeza", "Mandibula", "Boca"]
CONTRATO += [f"Cola{i}" for i in range(1, 7)]
CONTRATO += [f"Ala{l}{i}" for l in ("Izq", "Der") for i in (1, 2, 3)]
CONTRATO += [f"{h}{l}" for l in ("Izq", "Der") for h in ("Brazo", "Antebrazo", "Mano", "Muslo", "Pierna", "Pie")]
CONTRATO_SIN_PESOS = ["Raiz", "Boca"]

for _f in ("dragon_v2_formas.py", "dragon_v2_e2_alas.py"):
    exec(open(os.path.join(HERE, _f), encoding="utf-8").read(), globals())


# --- Paleta (sRGB, columna E2 de la biblia) ------------------------------------------------
def _lineal(hexa):
    """sRGB "#RRGGBB" -> color lineal (lo que espera el Principled BSDF)."""
    c = [int(hexa[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return tuple(round(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4, 4) for x in c)


COLORES = {n: _lineal(h) for n, h in {
    "cuerpo": "#43302A",  # lomo, cabeza, patas, brazo y dedo de adelante del ala
    "cuerpo_osc": "#33241F",  # dedos 2 y 3 del ala (en relieve), narinas
    "panza": "#C8693A",  # placas del vientre y del cuello (brasa clara)
    "membrana": "#5A2E24",  # membrana de las alas
    "borde": "#D2602E",  # franja del festón y puntas de las alas (el brillo del borde)
    "pua": "#2E1F1A", "brasa": "#FF8A3D",  # púas: base oscura y punta encendida
    "garra": "#DCCDAE",  # cuernos, garras y dientes
    "ojo": "#3FE6D2",  # ojos turquesa
    "turquesa": "#1F9A93",  # aletitas, aleta de la cola y franjas
    "boca": "#8E2A2A",
}.items()}


# --- Púas con la punta de brasa ----------------------------------------------------------------
def pua(parte, y0, z0, alta=False, coleccion="Puas"):
    """Una púa filosa apoyada encima del lomo (x -1..1) con la base en (y0, z0): la cara de adelante
    sube 1:1 (chica, 2 de alto) o 1:2 (alta, 4) y la de atrás es recta. La mitad de arriba es brasa."""
    h = 2 if alta else 1  # alto de cada mitad
    prisma(parte, coleccion, "pua", [(y0, z0), (y0 + 2, z0), (y0 + 2, z0 + h), (y0 + 1, z0 + h)], (-1, 1), eje="x")
    prisma(parte, coleccion, "brasa", [(y0 + 1, z0 + h), (y0 + 2, z0 + h), (y0 + 2, z0 + 2 * h)], (-1, 1), eje="x")


# --- El joven, en celdas -------------------------------------------------------------------
def cabeza():
    c = "Cabeza"
    # Cráneo de frente plana (4 de ancho) y las mejillas debajo, detrás de la mandíbula.
    bloque(c, c, "cuerpo", (-2, 2), (-13, -10), (14, 17))
    bloque(c, c, "cuerpo", (-2, 2), (-12, -10), (12, 14))
    # Hocico largo en cuña: se afina visto de arriba y baja en escalón hacia la punta.
    prisma(c, c, "cuerpo", [(-2, -13), (2, -13), (2, -14), (1, -16), (-1, -16), (-2, -14)], (13, 15))
    prisma(c, c, "cuerpo", [(-2, -13), (2, -13), (1, -15), (-1, -15)], (15, 16))
    par(c, c, "cuerpo_osc", (0, 1), (-16, -15), (15, 16))  # narinas
    # Colmillos que asoman a los costados de la mandíbula.
    for y in (-15, -14):
        par_prisma(c, c, "garra", [(y, 13), (y + 1, 13), (y + 1, 12)], (1, 2), eje="x")
    # Ojos chicos y fieros a los costados, bajo la ceja marcada que sobresale del cráneo.
    par(c, c, "ojo", (2, 3), (-13, -12), (15, 16))
    par_prisma(c, c, "cuerpo", [(-14, 17), (-11, 17), (-11, 18), (-13, 18)], (1, 3), eje="x")
    # Cuernos medianos: salen de atrás del cráneo hacia atrás, pegados a la línea de la cabeza, con
    # la púa de la nuca entre ellos (la corona).
    par_prisma(c, c, "garra", [(-11, 17), (-9, 17), (-7, 18), (-6, 19), (-7, 19)], (1, 2), eje="x")
    pua(c, -12, 17, coleccion=c)
    # Aletitas turquesa en las mejillas (dos rayos hacia atrás).
    par_prisma(c, "Aletas", "turquesa", [(2, -12), (4, -10), (4, -9), (2, -10)], (13, 14))
    par_prisma(c, "Aletas", "turquesa", [(2, -11), (3, -10), (3, -8), (2, -9)], (12, 13))
    # Mandíbula: angosta (cabe bajo el hocico), la boca roja por dentro y la esquina de atrás y abajo
    # en cuña. Termina una celda antes del cuello: al girar la cabeza no lo toca.
    m = "Mandibula"
    bloque(m, m, "cuerpo", (-1, 1), (-16, -15), (12, 13))
    bloque(m, m, "boca", (-1, 1), (-15, -12), (12, 13))
    bloque(m, m, "panza", (-1, 1), (-14, -12), (11, 12), eje="y", recorte={"z-": 1})


def pua_inclinada(parte, abajo, arriba):
    """Púa apoyada en un borde inclinado: `abajo` (oscura) y `arriba` (la punta de brasa)."""
    prisma(parte, "Puas", "pua", abajo, (-1, 1), eje="x")
    prisma(parte, "Puas", "brasa", arriba, (-1, 1), eje="x")


def cuello_y_torso():
    t = "Torso"
    # Cuello largo y fino que sube en arco: la base (4 de ancho) sale del pecho en 2:1 y la punta
    # (2 de ancho) sube 1:1 y se mete en la cabeza. Placas de brasa por debajo, con una franja
    # turquesa a los costados.
    prisma("Cuello1", t, "cuerpo", [(-3, 6), (-3, 10), (-7, 12), (-7, 8)], (-2, 2), eje="x")
    prisma("Cuello1", t, "panza", [(-7, 7), (-3, 5), (-3, 6), (-7, 8)], (-1, 1), eje="x")
    par_prisma("Cuello1", t, "turquesa", [(-7, 7), (-3, 5), (-3, 6), (-7, 8)], (1, 2), eje="x")
    prisma("Cuello2", t, "cuerpo", [(-6, 9), (-6, 13), (-9, 16), (-11, 16), (-11, 14)], (-1, 1), eje="x")
    prisma("Cuello2", t, "panza", [(-6, 8), (-6, 9), (-10, 13), (-10, 12)], (-1, 1), eje="x")
    # Pecho hondo con placas de brasa; la cadera, más angosta y baja (cintura), se mete en él.
    bloque("Pecho", t, "cuerpo", (-3, 3), (-4, -1), (5, 10))
    bloque("Pecho", t, "cuerpo", (-3, 3), (-1, 1), (5, 10), eje="y", recorte={"z-": 2})  # la panza sube
    bloque("Pecho", t, "panza", (-3, 3), (-5, -4), (5, 9))
    bloque("Pecho", t, "panza", (-2, 2), (-4, -2), (4, 5))
    bloque("Pecho", t, "turquesa", (-2, 2), (-2, -1), (4, 5))
    bloque("Cadera", t, "cuerpo", (-2, 2), (-1, 4), (6, 9))
    bloque("Cadera", t, "panza", (-1, 1), (1, 4), (5, 6))
    # Púas de la nuca a la cadera, más grandes en los hombros y la cadera. Las del cuello van
    # apoyadas en su borde inclinado.
    pua_inclinada("Cuello2", [(-8, 15), (-6, 13), (-6, 15)], [(-8, 15), (-6, 15), (-6, 16)])
    pua_inclinada("Cuello1", [(-5, 11), (-3, 10), (-3, 11)], [(-5, 11), (-3, 11), (-3, 12)])
    pua("Pecho", -3, 10, alta=True)
    pua("Pecho", -1, 10, alta=True)
    pua("Cadera", 2, 9, alta=True)


def cola():
    c = "Cola"
    # Látigo: (hueso, y desde, y hasta, medio ancho, z) de cada segmento; se afina y baja apenas.
    # La cuña 1:2 de cada uno se mete en el anterior (de su sección hacia adentro).
    segmentos = [("Cola1", 4, 6, 2, (6, 9)), ("Cola2", 6, 8, 1, (6, 8)), ("Cola3", 8, 10, 1, (6, 8)),
                 ("Cola4", 10, 12, 1, (5, 7)), ("Cola5", 12, 14, 1, (5, 7)), ("Cola6", 14, 15, 1, (4, 6))]
    for h, y0, y1, w, z in segmentos:
        bloque(h, c, "cuerpo", (-w, w), (y0, y1), z)
        bloque(h, c, "cuerpo", (-w, w), (y0 - 2, y0), z, eje="y", fin="-",
               recorte={"x-": 1, "x+": 1, "z-": 1, "z+": 1})
        if h != "Cola6":
            pua(h, y0, z[1])
    # Punta: abanico de púas con la punta de brasa y la aleta turquesa entre ellas, a los dos lados.
    par_prisma("Cola6", "Aletas", "turquesa", [(1, 12), (3, 12), (5, 14), (5, 15), (1, 15)], (4, 5))
    par_prisma("Cola6", "Puas", "pua", [(1, 12), (3, 12), (5, 13), (5, 14)], (5, 6))
    par_prisma("Cola6", "Puas", "brasa", [(5, 13), (7, 14), (5, 14)], (5, 6))
    par_prisma("Cola6", "Puas", "pua", [(1, 13), (2, 13), (3, 14), (2, 14)], (5, 6))
    par_prisma("Cola6", "Puas", "brasa", [(2, 14), (3, 14), (4, 15), (3, 15)], (5, 6))


def patas():
    p = "Patas"
    # Delanteras finas y cortas, recogidas bajo el pecho con la mano hacia adelante.
    par("Brazo{lado}", p, "cuerpo", (1, 2), (-4, -2), (2, 4))
    par("Antebrazo{lado}", p, "cuerpo", (1, 2), (-6, -4), (2, 3))
    par("Mano{lado}", p, "garra", (1, 2), (-7, -6), (2, 3), eje="y", fin="-", recorte={"z+": 1})
    # Traseras fuertes (muslo grueso) que cuelgan bajo la cadera y un poco hacia atrás, con garras.
    # Adentro de x = 3: el ala gira por el hombro (x = 3) y al bajar no las toca.
    par("Muslo{lado}", p, "cuerpo", (1, 3), (2, 4), (2, 6))
    par("Pierna{lado}", p, "cuerpo", (1, 3), (4, 6), (0, 3))
    par("Pie{lado}", p, "cuerpo", (1, 3), (6, 7), (0, 1))
    par("Pie{lado}", p, "garra", (1, 3), (7, 8), (0, 1), eje="y", recorte={"z+": 1})


def construir():
    cabeza(); cuello_y_torso(); cola(); alas(); patas()


# --- Rig ------------------------------------------------------------------------------
# Hueso -> (padre, articulación en celdas). {l}: Izq en +x y Der espejado. Cadera y Cabeza a la
# misma altura (z 15): Dragon/Rig toma "adelante" de la cadera a la cabeza, y así es -y exacto
# aunque la cabeza vaya arriba del lomo (la Cadera gira por encima del cuerpo).
ARTICULACIONES = [
    ("Cadera", None, (0, 1, 15)),
    ("Pecho", "Cadera", (0, 0, 8)),
    ("Cuello1", "Pecho", (0, -4, 8)),
    ("Cuello2", "Cuello1", (0, -7, 11)),
    ("Cabeza", "Cuello2", (0, -10, 15)),
    ("Mandibula", "Cabeza", (0, -12, 13)),  # borde de atrás y arriba de la mandíbula
    ("Cola1", "Cadera", (0, 4, 7.5)),
    ("Cola2", "Cola1", (0, 6, 7)),
    ("Cola3", "Cola2", (0, 8, 7)),
    ("Cola4", "Cola3", (0, 10, 6)),
    ("Cola5", "Cola4", (0, 12, 6)),
    ("Cola6", "Cola5", (0, 14, 5)),
    # Alas: el hombro en el borde de arriba del pecho, en el brazo del ala; las otras bisagras en la
    # cara de contacto de las tejas, a la mitad del ala de adelante hacia atrás.
    ("Ala{l}1", "Pecho", (3, -2, 10)),
    ("Ala{l}2", "Ala{l}1", (6.5, 2, 10)),
    ("Ala{l}3", "Ala{l}2", (10.5, 1, 11)),
    ("Brazo{l}", "Pecho", (1.5, -3, 4)),
    ("Antebrazo{l}", "Brazo{l}", (1.5, -4, 2.5)),
    ("Mano{l}", "Antebrazo{l}", (1.5, -6, 2.5)),
    ("Muslo{l}", "Cadera", (2, 3, 5.5)),
    ("Pierna{l}", "Muslo{l}", (2, 4, 2.5)),
    ("Pie{l}", "Pierna{l}", (2, 6, 0.5)),
]
# Cola de cada hueso (celdas, lado izquierdo): hacia el hijo, o hacia donde apunta la pieza.
COLAS = {
    "Cadera": (0, 4, 15), "Pecho": (0, -4, 8), "Cuello1": (0, -7, 11), "Cuello2": (0, -10, 15),
    "Cabeza": (0, -16, 16), "Mandibula": (0, -16, 13),
    "Cola1": (0, 6, 7), "Cola2": (0, 8, 7), "Cola3": (0, 10, 6), "Cola4": (0, 12, 6),
    "Cola5": (0, 14, 5), "Cola6": (0, 15, 5),
    "Ala{l}1": (6.5, 2, 10), "Ala{l}2": (10.5, 1, 11), "Ala{l}3": (16, 1, 12),
    "Brazo{l}": (1.5, -4, 2.5), "Antebrazo{l}": (1.5, -6, 2.5), "Mano{l}": (1.5, -7, 2.5),
    "Muslo{l}": (2, 4, 2.5), "Pierna{l}": (2, 6, 0.5), "Pie{l}": (2, 8, 0.5),
}
# Huesos sin pesos: Raiz en el centro del cuerpo (el modelo gira alrededor de ella en las
# volteretas) y Boca en la punta del hocico, entre las mandíbulas (de ahí sale el fuego).
PUNTOS = {"Raiz": (None, (0, -1, 7), (0, -1, 10)), "Boca": ("Cabeza", (0, -16, 13), (0, -17, 13))}
