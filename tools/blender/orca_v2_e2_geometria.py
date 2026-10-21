r"""
Orca v2, etapa 2 (joven): los datos de la etapa para minotauro_v2_bloques.py (--criatura orca).
Sale de la E3 (orca_v2_e3_geometria.py, la maestra) con la biblia orca_ref/BIBLIA.md, 4b: la
misma orca de bloques a medio camino entre la cría y la adulta. Se está estirando: el cuerpo es
más corto que el de la adulta (la cabeza pesa más, ~28 % del largo), la dorsal ya está echada
hacia atrás pero es más baja, las pectorales son largas y finas (un poco desgarbada), la boca
abierta lleva menos dientes, la hilera de púas es chica y tiene una sola cicatriz, un percebe y
una alga. Cuencas medianas, más altas (menos rasgadas) que las de la E3.

Proporciones (28 módulos de alto: de la punta de las pectorales a la de la dorsal):
    pectorales  hasta z 0       panza z 3..6 (blanca, después gris)
    cabeza      y -27..-12      mandíbula z 3..7, boca abierta z 6..11, cráneo z 11..18
    cuerpo      y -12..22       Pecho y Cola1..Cola5, de 14 a 4 de ancho
    dorsal      z 14..28        cola en V hasta y 27 (54 de largo)
Las articulaciones del rig (ARTICULACIONES, COLAS y PUNTOS) van al final; las usan orca_v2_poses.py y
rig_orca_v2.py. La cabeza está en orca_v2_e2_cabeza.py, el cuerpo y las aletas en orca_v2_e2_cuerpo.py y las formas que no son
bloques (prisma, par_prisma, espinas) en dragon_v2_formas.py.
Ejes: x = izquierda de la orca, -y = frente, z arriba; la punta de las pectorales en z = 0.
"""
CELDA = 0.3  # BU por celda (módulo de la etapa; docs/estilo_modelos.md, "Escala")
ALTO_JUEGO = 44  # studs: 8 x 5.5 (Config/Giants.luau); 28 módulos = 8.4 BU, 44.7 studs a 5.32
MODELO = "Orca"
PREFIJO = "OrcaV2_"
# En el juego se la ve desde la orilla, más arriba que ella: el lomo es lo que más se mira.
VISTAS_EXTRA = (("arriba", 180, 8), ("tres_cuartos_alto", 35, 0.9))
ENCUADRE_CAJA = True  # es casi el doble de larga que de alta: la cámara toma la caja entera

for _f in ("dragon_v2_formas.py", "orca_v2_e2_cabeza.py", "orca_v2_e2_cuerpo.py"):
    exec(open(os.path.join(HERE, _f), encoding="utf-8").read(), globals())

# Piezas con los nombres de la Orca actual (rig_orca.py), para que el rig de después los herede.
_LADOS = ("Izq", "Der")
CONTRATO = ["Raiz", "Pecho", "Cabeza", "Mandibula", "Boca", "Espiraculo", "Dorsal"]
CONTRATO += [f"Cola{n}" for n in range(1, 6)]
CONTRATO += [f"{h}{l}{k}" for l in _LADOS for h, k in (("Aleta", ""), ("Aleta", "2"), ("AletaCola", ""))]
# Ojo{l}Mira: el punto de cada ojo para las pupilas por código (GiantEyes), sin pesos.
_OJOS = [f"Ojo{l}Mira" for l in _LADOS]
CONTRATO += _OJOS
CONTRATO_SIN_PESOS = ["Raiz", "Boca", "Espiraculo"] + _OJOS


# --- Paleta (sRGB, BIBLIA.md, 4b, columna E2; lo demás como la E3) -------------------------
def _lineal(hexa):
    """sRGB "#RRGGBB" -> color lineal (lo que espera el Principled BSDF)."""
    c = [int(hexa[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return tuple(round(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4, 4) for x in c)


COLORES = {n: _lineal(h) for n, h in {
    "cuerpo": "#232A38",  # negro azulado, un poco más claro que el de la adulta
    "placa": "#323B4E",  # placas del lomo y de la frente
    "branquia": "#12161E",
    "blanco": "#E4E8EE",  # mandíbula y garganta (sin blanco puro)
    "panza": "#B4BCC8",
    "panza_osc": "#7D8696",
    "aleta": "#243A66",  # azul marino: dorsal y cola
    "pectoral": "#2D3545",
    "pua": "#555E6E",
    "ceja": "#3A4250",
    "cuenca": "#0A0C10",  # fondo oscuro del ojo: la pupila roja de Neon la pone el código
    "brillo": "#45E3FF",  # mancha de orca y puntos (Neon)
    "boca": "#4E1520",
    "lengua": "#8C2C3C",
    "diente": "#EEE9DD",
    "cicatriz": "#B8323A",
    "percebe": "#CFC2A8",
    "alga": "#3E8040",
}.items()}


def construir():
    cabeza(); cuerpo(); dorsal(); pectorales(); cola(); adornos()


# --- Rig (orca_ref/CONTRATO_RIG_NADO.md, 1) ------------------------------------------------
# Hueso -> (padre, articulación en celdas). {l}: Izq en +x y Der espejado; el padre antes que el
# hijo; sin padre, cuelga de Raiz. La cola cuelga del Pecho, en cadena. Las reglas son las de la E3.
ARTICULACIONES = [
    ("Pecho", None, (0, -7.5, 10.5)),  # centro del anillo de adelante
    ("Cabeza", "Pecho", (0, -12, 14)),  # la nuca: en la cara de unión, 4 celdas bajo el lomo
    ("Mandibula", "Cabeza", (0, -16, 5)),  # bisagra: en medio de la cuña de atrás, bajo la mejilla
    ("Aleta{l}", "Pecho", (5, -8, 8)),  # hombro: en la cara de adentro, a 3/4 de su alto
    ("Aleta{l}2", "Aleta{l}", (10, -7.5, 4)),  # codo: una celda dentro de la punta del primer tramo
    # Columna: en el centro de la celda de solape con el anillo anterior y a media altura del
    # anillo más chico (el de atrás).
    ("Cola1", "Pecho", (0, -3.5, 10.5)),
    ("Cola2", "Cola1", (0, 3.5, 10.5)),
    ("Cola3", "Cola2", (0, 9.5, 10.5)),
    ("Cola4", "Cola3", (0, 14.5, 10.5)),
    ("Cola5", "Cola4", (0, 18.5, 10.5)),
    ("Dorsal", "Cola1", (0, -2, 16)),  # base metida en el lomo, una celda bajo el de la Cola1
    ("AletaCola{l}", "Cola5", (2, 21.5, 10)),  # raíz del lóbulo, en el costado de la Cola5
]
# Cola de cada hueso (celdas, lado izquierdo): hacia el hijo, o hacia donde apunta la pieza.
COLAS = {
    "Pecho": (0, -3.5, 10.5), "Cabeza": (0, -27, 12), "Mandibula": (0, -26, 4),
    "Aleta{l}": (10, -7.5, 4), "Aleta{l}2": (18, -6, 0.5),
    "Cola1": (0, 3.5, 10.5), "Cola2": (0, 9.5, 10.5), "Cola3": (0, 14.5, 10.5),
    "Cola4": (0, 18.5, 10.5), "Cola5": (0, 22, 10.5), "Dorsal": (0, -3.5, 28),
    "AletaCola{l}": (10, 26, 10),
}
# Huesos sin pesos: (padre, cabeza, cola). Raiz en el centro del largo a media altura del cuerpo;
# Boca entre los dientes de adelante; Espiraculo sobre la frente, detrás de la púa. Ojo{l}Mira en
# el centro de la cara de la cuenca (UIConfig/GiantEyesData, OrcaE2: (±2.0964, -7.2036, 4.05) BU),
# con la cola a lo largo de su normal (±0.7071, -0.7071, 0).
_OJO, _NORMAL = (2.0964 / CELDA, -7.2036 / CELDA, 4.05 / CELDA), (0.7071, -0.7071, 0)
PUNTOS = {
    "Raiz": (None, (0, 0, 10.5), (0, -3, 10.5)),
    "Boca": ("Cabeza", (0, -26, 8.5), (0, -28, 8.5)),
    "Espiraculo": ("Cabeza", (0, -16, 18), (0, -16, 20)),
}
for _s, _l in ((1, "Izq"), (-1, "Der")):
    _c = (_s * _OJO[0], _OJO[1], _OJO[2])
    PUNTOS[f"Ojo{_l}Mira"] = ("Cabeza", _c, (_c[0] + _s * _NORMAL[0] * 2, _c[1] + _NORMAL[1] * 2, _c[2]))
