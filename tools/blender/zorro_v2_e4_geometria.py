r"""
Zorro de agua v2, etapa 4 (forma final): los datos de la etapa para minotauro_v2_bloques.py
(--criatura zorro). La biblia es zorro_ref/BIBLIA.md (fuera del repo). Sale de la maestra (la E3,
zorro_v2_e3_geometria.py): el mismo zorro de bloques hecho de agua, con la misma cara, pechera,
orejas y patas que se oscurecen, pero majestuoso: cabeza chica en proporción, cuerpo largo, patas
largas y nueve colas de ola en el abanico de la referencia, lleno y alto. Paleta más profunda
(columna E4) y, como toques propios, una corona de tres cristales de hielo en la frente y
cristalitos en las crestas de las colas.

Proporciones (31 módulos de alto: la espuma de la cola central):
    patas    z 0..9         cuerpo z 7..12 (y -9..8, ancho 8)
    cabeza   z 15..20       hocico hasta y -17, orejas hasta z 25, corona hasta z 24
    colas    hasta z 31     abanico de x -27 a 27, en capas de y 0 a 37 (zorro_v2_e4_colas.py),
                            con la base de las colas (losa de la Cadera) de y 8 a 28
El cuerpo está en zorro_v2_e4_cuerpo.py, las colas en zorro_v2_e4_colas.py y las formas que no son
bloques (prisma, par_prisma) en dragon_v2_formas.py.
Ejes: x = izquierda del zorro, -y = frente, z arriba; parado en z = 0, centrado en x.
"""
CELDA = 1.0  # BU por celda (módulo de la etapa; docs/estilo_modelos.md, "Escala")
ALTO_JUEGO = 165  # studs: 30 x 5.5 (Config/Giants.luau); 165 / 31 = 5.32 studs por BU
MODELO = "ZorroDeAgua"
PREFIJO = "ZorroV2_"
VISTAS_EXTRA = (("arriba", 180, 8),)  # la cabeza queda arriba en la imagen

for _f in ("dragon_v2_formas.py", "zorro_v2_e4_cuerpo.py", "zorro_v2_e4_colas.py"):
    exec(open(os.path.join(HERE, _f), encoding="utf-8").read(), globals())

# Contrato de huesos (BIBLIA.md, 7): el de la E3 con nueve colas de 5 tramos. 76 huesos, 6 más que
# el tope de la guía: excepción aceptada por las colas.
_LADOS = ("Izq", "Der")
CONTRATO = ["Raiz", "Cadera", "Columna", "Pecho", "Cuello1", "Cuello2", "Cabeza", "Mandibula", "Boca"]
CONTRATO += [f"{h}{l}" for l in _LADOS for h in ("Oreja", "OrejaPunta", "Parpado", "Hombro", "Brazo",
                                                 "Antebrazo", "Mano", "Muslo", "Pierna", "Tobillo", "Pie")]
CONTRATO += [f"Cola{n}_{k}" for n in range(1, 10) for k in range(1, 6)]
CONTRATO_SIN_PESOS = ["Raiz", "Boca"]


# --- Paleta (sRGB, columna E4 de la biblia) ----------------------------------------------
def _lineal(hexa):
    """sRGB "#RRGGBB" -> color lineal (lo que espera el Principled BSDF)."""
    c = [int(hexa[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return tuple(round(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4, 4) for x in c)


COLORES = {n: _lineal(h) for n, h in {
    "cuerpo": "#1F7FCF",  # agua: torso, cabeza, cuello y orejas
    "claro": "#3BB8E6",  # vetas, placa del hombro y cuarto tramo de las colas
    "verde": "#2FC8BC",  # verde agua de los flancos
    "pata": "#1858BC",
    "pata_osc": "#143E96",  # manos y pies
    "raiz": "#1864C4",  # primer tramo de las colas
    "espuma": "#E6F7FF",  # pechera, mejillas, mandíbula y punta de las colas (sin blanco puro)
    "sombra": "#B0DDF2",  # sombra de la espuma: la gota que cuelga de la ola
    "ojo": "#E8FFFF",  # ojos (en Roblox, Neon)
    "marca": "#CFF6FF",  # marca de la frente (Neon)
    "oreja": "#163E92",  # interior de las orejas
    "nariz": "#14305C",
    "boca": "#173A6E",
    "hielo": "#BFF3FF",  # corona de la frente y cristalitos en la espuma de las puntas
}.items()}


def construir():
    patas(); torso(); cabeza(); orejas(); colas()


# --- Rig ------------------------------------------------------------------------------
# Hueso -> (padre, articulación en celdas). {l}: Izq en +x y Der espejado; el padre antes que
# el hijo. Los mismos pivotes que la E3 (BIBLIA.md, 7), bajados con el cuerpo; los de las colas,
# en el centro del borde donde nace cada tramo.
ARTICULACIONES = [
    ("Cadera", None, (0, 5, 10)),
    ("Columna", "Cadera", (0, -1, 10)),  # el tramo de atrás del lomo es de la Cadera
    ("Pecho", "Columna", (0, -3, 10)),
    ("Cuello1", "Pecho", (0, -7, 12)),
    ("Cuello2", "Cuello1", (0, -8, 15)),
    ("Cabeza", "Cuello2", (0, -9, 16)),
    ("Mandibula", "Cabeza", (0, -12, 15)),
    ("Oreja{l}", "Cabeza", (2.5, -9.5, 20)),
    ("OrejaPunta{l}", "Oreja{l}", (2.5, -9.5, 23)),
    ("Parpado{l}", "Cabeza", (2.5, -13.5, 18)),  # bisagra detrás del ojo: abierto, ceja fina
    ("Hombro{l}", "Pecho", (2.5, -5.5, 11)),
    ("Brazo{l}", "Hombro{l}", (2.5, -5.5, 9)),
    ("Antebrazo{l}", "Brazo{l}", (2.5, -5.5, 5)),
    ("Mano{l}", "Antebrazo{l}", (2.5, -5.5, 2)),
    ("Muslo{l}", "Cadera", (3, 5, 9)),
    ("Pierna{l}", "Muslo{l}", (2.5, 6.5, 6)),
    ("Tobillo{l}", "Pierna{l}", (2.5, 6, 4)),
    ("Pie{l}", "Tobillo{l}", (2.5, 5, 1)),
]
_ARTS_COLAS, _PUNTAS_COLAS = articulaciones_colas()
ARTICULACIONES += _ARTS_COLAS
# Cola de cada hueso (celdas, lado izquierdo): hacia el hijo, o hacia donde apunta la pieza.
COLAS = {
    "Cadera": (0, -1, 10), "Columna": (0, -3, 10), "Pecho": (0, -7, 12), "Cuello1": (0, -8, 15),
    "Cuello2": (0, -9, 16), "Cabeza": (0, -9, 20), "Mandibula": (0, -15, 15),
    "Oreja{l}": (2.5, -9.5, 23), "OrejaPunta{l}": (3, -9.5, 25), "Parpado{l}": (2.5, -15, 19.5),
    "Hombro{l}": (2.5, -5.5, 9), "Brazo{l}": (2.5, -5.5, 5), "Antebrazo{l}": (2.5, -5.5, 2),
    "Mano{l}": (2.5, -8, 1), "Muslo{l}": (2.5, 6.5, 6), "Pierna{l}": (2.5, 6, 4),
    "Tobillo{l}": (2.5, 5, 1), "Pie{l}": (2.5, 3, 1),
} | _PUNTAS_COLAS
# Huesos sin pesos: Raiz en la base y Boca entre el hocico y la mandíbula, en la punta.
PUNTOS = {"Raiz": (None, (0, 0, 0), (0, 0, 3)), "Boca": ("Cabeza", (0, -15, 15), (0, -16, 15))}
