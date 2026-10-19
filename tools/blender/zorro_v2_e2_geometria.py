r"""
Zorro de agua v2, etapa 2 (joven): los datos de la etapa para minotauro_v2_bloques.py
(--criatura zorro). Sale de la E3 (zorro_v2_e3_geometria.py, la maestra aprobada): el mismo
zorro de bloques hecho de agua, con la misma cara, pechera en V, orejas con el interior azul
oscuro y patas que se oscurecen hacia abajo. Lo que lo hace adolescente: patas largas, cuerpo fino
y corto, frente alta y tres colas en vez de seis (una central que sube vertical y se inclina hacia
atrás y un par que se abre en arco a los costados). Sin hielo: es desde el adulto (BIBLIA.md, 2).

Proporciones (28 módulos de alto: la espuma de la cola central):
    patas    z 0..10        cuerpo z 10..14, grupa z 9..13 (y -8..7, ancho 8: 15 de largo)
    cabeza   z 16..23       hocico hasta y -17 (11 de largo), orejas hasta z 27
    colas    hasta z 28     la central de y 5 a y 24; el par hasta x ±21 e y 22, z 24
El cuerpo está en zorro_v2_e2_cuerpo.py, las colas en zorro_v2_e2_colas.py y las formas que no son
bloques (prisma, par_prisma) en dragon_v2_formas.py.
Ejes: x = izquierda del zorro, -y = frente, z arriba; parado en z = 0, centrado en x.
"""
CELDA = 0.3  # BU por celda (módulo de la etapa; docs/estilo_modelos.md, "Escala")
ALTO_JUEGO = 44  # studs: 8 x 5.5 (Config/Giants.luau); 28 x 0.3 = 8.4 BU, 44.7 studs a 5.32
MODELO = "ZorroDeAgua"
PREFIJO = "ZorroV2_"
VISTAS_EXTRA = (("arriba", 180, 8),)  # la cabeza queda arriba en la imagen

for _f in ("dragon_v2_formas.py", "zorro_v2_e2_cuerpo.py", "zorro_v2_e2_colas.py"):
    exec(open(os.path.join(HERE, _f), encoding="utf-8").read(), globals())

# Contrato de huesos (BIBLIA.md, 7): el de la E3 con tres colas de 5 tramos (46 huesos).
_LADOS = ("Izq", "Der")
CONTRATO = ["Raiz", "Cadera", "Columna", "Pecho", "Cuello1", "Cuello2", "Cabeza", "Mandibula", "Boca"]
CONTRATO += [f"{h}{l}" for l in _LADOS for h in ("Oreja", "OrejaPunta", "Parpado", "Hombro", "Brazo",
                                                 "Antebrazo", "Mano", "Muslo", "Pierna", "Tobillo", "Pie")]
CONTRATO += [f"Cola{n}_{k}" for n in range(1, 4) for k in range(1, 6)]
CONTRATO_SIN_PESOS = ["Raiz", "Boca"]


# --- Paleta (sRGB, columna E2 de la biblia) ----------------------------------------------
def _lineal(hexa):
    """sRGB "#RRGGBB" -> color lineal (lo que espera el Principled BSDF)."""
    c = [int(hexa[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return tuple(round(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4, 4) for x in c)


COLORES = {n: _lineal(h) for n, h in {
    "cuerpo": "#3DB4EC",  # agua: torso, cabeza, cuello y orejas
    "claro": "#6AD8F2",  # vetas, placa del hombro y cuarto tramo de las colas
    "verde": "#55DDCF",  # verde agua de los flancos
    "pata": "#2A7FDA",
    "pata_osc": "#2460BE",  # manos y pies
    "raiz": "#2C88DC",  # primer tramo de las colas
    "espuma": "#E6F7FF",  # pechera, mejillas, mandíbula y punta de las colas (sin blanco puro)
    "sombra": "#C4EAF8",  # sombra de la espuma: la veta de la punta
    "ojo": "#E8FFFF",  # ojos (en Roblox, Neon)
    "marca": "#CFF6FF",  # marca de la frente (Neon)
    "oreja": "#2256B4",  # interior de las orejas
    "nariz": "#14305C",
    "boca": "#173A6E",
}.items()}


def construir():
    patas(); torso(); cabeza(); orejas(); colas()


# --- Rig ------------------------------------------------------------------------------
# Hueso -> (padre, articulación en celdas). {l}: Izq en +x y Der espejado; el padre antes que
# el hijo. Los de la E3 llevados al cuerpo del joven; el del brazo, media celda debajo del pecho,
# y el de la oreja, media arriba de la cabeza (ver zorro_v2_e2_cuerpo.py); los de las colas, en
# el centro del borde donde nace cada tramo.
ARTICULACIONES = [
    ("Cadera", None, (0, 3, 11)),
    ("Columna", "Cadera", (0, -1, 12)),
    ("Pecho", "Columna", (0, -3, 12)),
    ("Cuello1", "Pecho", (0, -5, 14)),
    ("Cuello2", "Cuello1", (0, -6.5, 16)),
    ("Cabeza", "Cuello2", (0, -8, 17)),
    ("Mandibula", "Cabeza", (0, -11, 16)),
    ("Oreja{l}", "Cabeza", (2.5, -9, 23.5)),  # media celda arriba de la cabeza
    ("OrejaPunta{l}", "Oreja{l}", (2.5, -9, 25)),
    # Bisagra del párpado, detrás del ojo: abierto es una ceja fina; cerrado (1.4 rad, Cara/Parpadeo)
    # tapa el ojo entero, de z 18.9 (apoyado en el hocico) a 21.9.
    ("Parpado{l}", "Cabeza", (2.5, -12.75, 20)),
    ("Hombro{l}", "Pecho", (2.5, -5.5, 13)),
    ("Brazo{l}", "Hombro{l}", (2.5, -5.5, 9.5)),  # media celda debajo del pecho
    ("Antebrazo{l}", "Brazo{l}", (2.5, -5.5, 5)),
    ("Mano{l}", "Antebrazo{l}", (2.5, -5.5, 2)),
    ("Muslo{l}", "Cadera", (3, 3, 11)),
    ("Pierna{l}", "Muslo{l}", (2.5, 4.5, 8)),
    ("Tobillo{l}", "Pierna{l}", (2.5, 3.5, 5)),
    ("Pie{l}", "Tobillo{l}", (2.5, 3, 1)),
]
_ARTS_COLAS, _PUNTAS_COLAS = articulaciones_colas()
ARTICULACIONES += _ARTS_COLAS
# Cola de cada hueso (celdas, lado izquierdo): hacia el hijo, o hacia donde apunta la pieza.
COLAS = {
    "Cadera": (0, -1, 12), "Columna": (0, -3, 12), "Pecho": (0, -5, 14), "Cuello1": (0, -6.5, 16),
    "Cuello2": (0, -8, 17), "Cabeza": (0, -8, 23), "Mandibula": (0, -15, 16),
    "Oreja{l}": (2.5, -9, 25), "OrejaPunta{l}": (3, -9, 27), "Parpado{l}": (2.5, -14, 21.5),
    "Hombro{l}": (2.5, -5.5, 9.5), "Brazo{l}": (2.5, -5.5, 5), "Antebrazo{l}": (2.5, -5.5, 2),
    "Mano{l}": (2.5, -8, 1), "Muslo{l}": (2.5, 4.5, 8), "Pierna{l}": (2.5, 3.5, 5),
    "Tobillo{l}": (2.5, 3, 1), "Pie{l}": (2.5, 1, 1),
} | _PUNTAS_COLAS
# Huesos sin pesos: Raiz en la base y Boca entre el hocico y la mandíbula, en la punta.
PUNTOS = {"Raiz": (None, (0, 0, 0), (0, 0, 3)), "Boca": ("Cabeza", (0, -15, 17), (0, -16, 17))}
