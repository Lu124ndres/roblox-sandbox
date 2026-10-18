r"""
Zorro de agua v2, etapa 1 (cría): los datos de la etapa para minotauro_v2_bloques.py
(--criatura zorro). Sale de la maestra (zorro_v2_e3_*.py, aprobada): el mismo zorro de agua en
bloques, más chico y tierno. Misma cara (ojos rasgados que brillan, marca blanca en la frente,
hocico en cuña con la parte de abajo blanca y la nariz azul marino, mejillas blancas simples),
misma pechera de espuma en V, mismas patas que se oscurecen hacia abajo y las mismas vetas claras
y verde agua en los flancos. Lo de cría: cabeza y ojos grandes, orejas grandes, cuerpo compacto,
patas cortas y gruesas y UNA sola cola que sale de la grupa hacia atrás, se curva hacia arriba
y rompe en espuma. Sin hielo: el hielo es desde el adulto.

Proporciones (31 módulos de alto: la punta de las orejas y la espuma de la cola):
    patas    z 0..8 (placas hasta 12)  cuerpo z 8..16 (y -7..7, ancho 10)
    cabeza   z 16..25 (9 de alto)     hocico hasta y -20 (12 de largo), orejas hasta z 31
    cola     hasta z 31               de y 6 a y 24, en el plano y-z (zorro_v2_e1_colas.py)
El cuerpo está en zorro_v2_e1_cuerpo.py, la cola en zorro_v2_e1_colas.py y las formas que no son
bloques (prisma, par_prisma) en dragon_v2_formas.py.
Ejes: x = izquierda del zorro, -y = frente, z arriba; parado en z = 0, centrado en x.
"""
CELDA = 0.1  # BU por celda (módulo de la etapa; docs/estilo_modelos.md, "Escala")
ALTO_JUEGO = 16.5  # studs: 3 x 5.5 (Config/Giants.luau); 16.5 / 3.1 = 5.32 studs por BU
MODELO = "ZorroDeAgua"
PREFIJO = "ZorroV2_"
VISTAS_EXTRA = (("arriba", 180, 8),)  # la cabeza queda arriba en la imagen

for _f in ("dragon_v2_formas.py", "zorro_v2_e1_cuerpo.py", "zorro_v2_e1_colas.py"):
    exec(open(os.path.join(HERE, _f), encoding="utf-8").read(), globals())

# Contrato de huesos (BIBLIA.md, 7): el de la E3 con una sola cola de 5 tramos (36 huesos).
_LADOS = ("Izq", "Der")
CONTRATO = ["Raiz", "Cadera", "Columna", "Pecho", "Cuello1", "Cuello2", "Cabeza", "Mandibula", "Boca"]
CONTRATO += [f"{h}{l}" for l in _LADOS for h in ("Oreja", "OrejaPunta", "Parpado", "Hombro", "Brazo",
                                                 "Antebrazo", "Mano", "Muslo", "Pierna", "Tobillo", "Pie")]
CONTRATO += [f"Cola1_{k}" for k in range(1, 6)]
CONTRATO_SIN_PESOS = ["Raiz", "Boca"]


# --- Paleta (sRGB, columna E1 de la biblia) ----------------------------------------------
def _lineal(hexa):
    """sRGB "#RRGGBB" -> color lineal (lo que espera el Principled BSDF)."""
    c = [int(hexa[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return tuple(round(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4, 4) for x in c)


COLORES = {n: _lineal(h) for n, h in {
    "cuerpo": "#5CC8F2",  # agua: torso, cabeza, cuello y orejas
    "claro": "#8FE3F7",  # vetas, placa del hombro y cuarto tramo de la cola
    "verde": "#6FE6D6",  # verde agua de los flancos
    "pata": "#3D8FE0",
    "pata_osc": "#2F6FCC",  # manos y pies
    "raiz": "#3F98E4",  # primer tramo de la cola
    "espuma": "#E6F7FF",  # pechera, mejillas, mandíbula y punta de la cola (sin blanco puro)
    "sombra": "#C4EAF8",  # sombra de la espuma: la gota que cuelga de la ola
    "ojo": "#E8FFFF",  # ojos (en Roblox, Neon)
    "marca": "#CFF6FF",  # marca de la frente (Neon)
    "oreja": "#2A5FBE",  # interior de las orejas
    "nariz": "#14305C",
    "boca": "#173A6E",
}.items()}


def construir():
    patas(); torso(); cabeza(); orejas(); colas()


# --- Rig ------------------------------------------------------------------------------
# Hueso -> (padre, articulación en celdas). {l}: Izq en +x y Der espejado; el padre antes que
# el hijo. Los mismos lugares que en la E3, medidos sobre las piezas de la cría; los de la cola,
# en el centro del borde donde nace cada tramo.
ARTICULACIONES = [
    ("Cadera", None, (0, 4, 12)),
    ("Columna", "Cadera", (0, 1, 12)),
    ("Pecho", "Columna", (0, -1, 12)),
    ("Cuello1", "Pecho", (0, -5, 15)),
    ("Cuello2", "Cuello1", (0, -6, 16)),
    ("Cabeza", "Cuello2", (0, -7, 17)),  # detrás del cráneo: al girar no entra en el cuello
    ("Mandibula", "Cabeza", (0, -11, 16)),
    ("Oreja{l}", "Cabeza", (3.5, -11, 25)),
    ("OrejaPunta{l}", "Oreja{l}", (4.5, -11, 29)),
    # Bisagra del párpado: abierto es una ceja fina sobre el ojo (z 23..24) y se esconde en la
    # frente; girando 90° sobre x baja delante del ojo (y -18..-17) y lo tapa entero (z 20..23).
    ("Parpado{l}", "Cabeza", (3, -15.5, 21.5)),
    # Hombro y brazo giran en el mismo lugar: el centro de la espiga, en el borde de abajo del
    # pecho. El muslo, igual, en el borde de abajo de la cadera.
    ("Hombro{l}", "Pecho", (3, -4, 8)),
    ("Brazo{l}", "Hombro{l}", (3, -4, 8)),
    ("Antebrazo{l}", "Brazo{l}", (3, -4, 5)),
    ("Mano{l}", "Antebrazo{l}", (3, -4, 2)),
    ("Muslo{l}", "Cadera", (3, 4, 8)),
    ("Pierna{l}", "Muslo{l}", (3, 5, 6)),
    ("Tobillo{l}", "Pierna{l}", (3, 4, 4)),
    ("Pie{l}", "Tobillo{l}", (3, 5, 1)),
]
_ARTS_COLA, _PUNTAS_COLA = articulaciones_cola()
ARTICULACIONES += _ARTS_COLA
# Cola de cada hueso (celdas, lado izquierdo): hacia el hijo, o hacia donde apunta la pieza.
COLAS = {
    "Cadera": (0, 1, 12), "Columna": (0, -1, 12), "Pecho": (0, -5, 15), "Cuello1": (0, -6, 16),
    "Cuello2": (0, -7, 17), "Cabeza": (0, -7, 24), "Mandibula": (0, -18, 16),
    "Oreja{l}": (3.5, -11, 29), "OrejaPunta{l}": (4.5, -11, 31), "Parpado{l}": (3, -17, 23.5),
    "Hombro{l}": (3, -4, 11), "Brazo{l}": (3, -4, 5), "Antebrazo{l}": (3, -4, 2),
    "Mano{l}": (3, -7, 1), "Muslo{l}": (3, 5, 6), "Pierna{l}": (3, 4, 4),
    "Tobillo{l}": (3, 5, 1), "Pie{l}": (3, 3, 1),
} | _PUNTAS_COLA
# Huesos sin pesos: Raiz en la base y Boca entre el hocico y la mandíbula, en la punta.
PUNTOS = {"Raiz": (None, (0, 0, 0), (0, 0, 3)), "Boca": ("Cabeza", (0, -18, 17), (0, -19, 17))}
