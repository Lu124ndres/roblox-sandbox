r"""
Zorro de agua v2, etapa 3 (adulto, la maestra): los datos de la etapa para minotauro_v2_bloques.py
(--criatura zorro). La biblia es zorro_ref/BIBLIA.md (fuera del repo): un zorro de bloques hecho de
agua, en cuatro patas, con seis colas de ola en abanico que rompen en espuma. Cuerpo en caja, patas
rectas y largas que se oscurecen hacia abajo, pechera de espuma en V, orejas altas con el interior
azul oscuro, ojos que brillan rasgados hacia arriba, marca blanca en la frente, hocico en cuña con
la nariz azul marino y vetas claras y verde agua en los flancos. Desde el adulto, cristalitos de
hielo en la espuma de las puntas.

Proporciones (31 módulos de alto: la espuma de las colas más altas):
    patas    z 0..10        cuerpo z 8..14 (y -9..8, ancho 8)
    cabeza   z 16..22       hocico hasta y -18, orejas hasta z 27
    colas    hasta z 31     abanico curvo en tres capas de y 4 a y 25 y de x -19 a 19 (zorro_v2_e3_colas.py)
El cuerpo está en zorro_v2_e3_cuerpo.py, las colas en zorro_v2_e3_colas.py y las formas que no son
bloques (prisma, par_prisma) en dragon_v2_formas.py.
Ejes: x = izquierda del zorro, -y = frente, z arriba; parado en z = 0, centrado en x.
"""
CELDA = 0.5  # BU por celda (módulo de la etapa; docs/estilo_modelos.md, "Escala")
ALTO_JUEGO = 82.5  # studs: 15 x 5.5 (Config/Giants.luau); 82.5 / 15.5 = 5.32 studs por BU
MODELO = "ZorroDeAgua"
PREFIJO = "ZorroV2_"
VISTAS_EXTRA = (("arriba", 180, 8),)  # la cabeza queda arriba en la imagen

for _f in ("dragon_v2_formas.py", "zorro_v2_e3_cuerpo.py", "zorro_v2_e3_colas.py"):
    exec(open(os.path.join(HERE, _f), encoding="utf-8").read(), globals())

# Contrato de huesos (BIBLIA.md, 7): base + detalle (OrejaPunta, Parpado), 6 colas de 5 tramos.
_LADOS = ("Izq", "Der")
CONTRATO = ["Raiz", "Cadera", "Columna", "Pecho", "Cuello1", "Cuello2", "Cabeza", "Mandibula", "Boca"]
CONTRATO += [f"{h}{l}" for l in _LADOS for h in ("Oreja", "OrejaPunta", "Parpado", "Hombro", "Brazo",
                                                 "Antebrazo", "Mano", "Muslo", "Pierna", "Tobillo", "Pie")]
CONTRATO += [f"Cola{n}_{k}" for n in range(1, 7) for k in range(1, 6)]
CONTRATO_SIN_PESOS = ["Raiz", "Boca"]


# --- Paleta (sRGB, columna E3 de la biblia) ----------------------------------------------
def _lineal(hexa):
    """sRGB "#RRGGBB" -> color lineal (lo que espera el Principled BSDF)."""
    c = [int(hexa[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return tuple(round(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4, 4) for x in c)


COLORES = {n: _lineal(h) for n, h in {
    "cuerpo": "#2A9BE0",  # agua: torso, cabeza, cuello y orejas
    "claro": "#4CCBEA",  # vetas, placa del hombro y cuarto tramo de las colas
    "verde": "#3FD6C6",  # verde agua de los flancos
    "pata": "#1E6FD0",
    "pata_osc": "#1A4FAE",  # manos y pies
    "raiz": "#1F78D6",  # primer tramo de las colas
    "espuma": "#E6F7FF",  # pechera, mejillas, mandíbula y punta de las colas (sin blanco puro)
    "sombra": "#C4EAF8",  # sombra de la espuma: la gota que cuelga de la ola
    "ojo": "#E8FFFF",  # ojos (en Roblox, Neon)
    "marca": "#CFF6FF",  # marca de la frente y rayas del hocico (Neon)
    "oreja": "#1C4BA8",  # interior de las orejas
    "nariz": "#14305C",
    "boca": "#173A6E",
    "hielo": "#BFF3FF",  # cristalitos en la espuma de las puntas (desde el adulto)
}.items()}


def construir():
    patas(); torso(); cabeza(); orejas(); colas()


# --- Rig ------------------------------------------------------------------------------
# Hueso -> (padre, articulación en celdas). {l}: Izq en +x y Der espejado; el padre antes que
# el hijo. Pivotes de BIBLIA.md, 7; los de las colas, en el centro del borde donde nace cada tramo.
ARTICULACIONES = [
    ("Cadera", None, (0, 5, 11)),
    ("Columna", "Cadera", (0, -1, 11)),  # el tramo de atrás del lomo es de la Cadera
    ("Pecho", "Columna", (0, -3, 11)),
    ("Cuello1", "Pecho", (0, -7, 14)),
    ("Cuello2", "Cuello1", (0, -8, 16)),
    ("Cabeza", "Cuello2", (0, -9, 17)),
    ("Mandibula", "Cabeza", (0, -11, 16)),
    ("Oreja{l}", "Cabeza", (2.5, -9.5, 22)),
    ("OrejaPunta{l}", "Oreja{l}", (2.5, -9.5, 25)),
    ("Parpado{l}", "Cabeza", (2.5, -14, 20)),  # bisagra detrás del ojo: abierto, ceja fina
    ("Hombro{l}", "Pecho", (2.5, -5.5, 12)),
    ("Brazo{l}", "Hombro{l}", (2.5, -5.5, 10)),
    ("Antebrazo{l}", "Brazo{l}", (2.5, -5.5, 6)),
    ("Mano{l}", "Antebrazo{l}", (2.5, -5.5, 2)),
    ("Muslo{l}", "Cadera", (3, 5, 11)),
    ("Pierna{l}", "Muslo{l}", (2.5, 6.5, 7)),
    ("Tobillo{l}", "Pierna{l}", (2.5, 6, 4)),
    ("Pie{l}", "Tobillo{l}", (2.5, 5, 1)),
]
_ARTS_COLAS, _PUNTAS_COLAS = articulaciones_colas()
ARTICULACIONES += _ARTS_COLAS
# Cola de cada hueso (celdas, lado izquierdo): hacia el hijo, o hacia donde apunta la pieza.
COLAS = {
    "Cadera": (0, -1, 11), "Columna": (0, -3, 11), "Pecho": (0, -7, 14), "Cuello1": (0, -8, 16),
    "Cuello2": (0, -9, 17), "Cabeza": (0, -9, 22), "Mandibula": (0, -16, 16),
    "Oreja{l}": (2.5, -9.5, 25), "OrejaPunta{l}": (3, -9.5, 27), "Parpado{l}": (2.5, -15, 21.5),
    "Hombro{l}": (2.5, -5.5, 10), "Brazo{l}": (2.5, -5.5, 6), "Antebrazo{l}": (2.5, -5.5, 2),
    "Mano{l}": (2.5, -8, 1), "Muslo{l}": (2.5, 6.5, 7), "Pierna{l}": (2.5, 6, 4),
    "Tobillo{l}": (2.5, 5, 1), "Pie{l}": (2.5, 3, 1),
} | _PUNTAS_COLAS
# Huesos sin pesos: Raiz en la base y Boca entre el hocico y la mandíbula, en la punta.
PUNTOS = {"Raiz": (None, (0, 0, 0), (0, 0, 3)), "Boca": ("Cabeza", (0, -16, 17), (0, -17, 17))}
