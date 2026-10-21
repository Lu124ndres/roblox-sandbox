r"""
Orca v2, etapa 3 (adulto, la maestra): los datos de la etapa para minotauro_v2_bloques.py
(--criatura orca). La biblia es orca_ref/BIBLIA.md (fuera del repo): una orca monstruo de bloques,
un torpedo largo de placas negro azuladas en anillos que se escalonan hacia la cola, la aleta
dorsal alta echada hacia atrás, la boca abierta con dos filas de dientes, cuencas de los ojos
(la pupila roja la pone el código) con cejas de enojo y la mancha de orca en cian que brilla, púas
grises por todo el lomo, pectorales largas que bajan hacia afuera y la cola en V. Detalles: branquias, puntos cian, cicatrices, percebes y algas.

Proporciones (31 módulos de alto: de la punta de las pectorales a la de la dorsal):
    pectorales  hasta z 0       panza z 2..5 (blanca, después gris)
    cabeza      y -31..-16      mandíbula z 3..7, boca abierta z 7..10, cráneo z 10..18
    cuerpo      y -16..26       Pecho y Cola1..Cola5, de 14 a 4 de ancho
    dorsal      z 14..31        cola en V hasta y 33
Las articulaciones del rig (ARTICULACIONES, COLAS y PUNTOS) van al final; las usan orca_v2_poses.py y
rig_orca_v2.py. La cabeza está en
orca_v2_e3_cabeza.py, el cuerpo y las aletas en orca_v2_e3_cuerpo.py y las formas que no son
bloques (prisma, par_prisma, espinas) en dragon_v2_formas.py.
Ejes: x = izquierda de la orca, -y = frente, z arriba; la punta de las pectorales en z = 0.
"""
CELDA = 0.5  # BU por celda (módulo de la etapa; docs/estilo_modelos.md, "Escala")
ALTO_JUEGO = 82.5  # studs: 15 x 5.5 (Config/Giants.luau); 82.5 / 15.5 = 5.32 studs por BU
MODELO = "Orca"
PREFIJO = "OrcaV2_"
# En el juego se la ve desde la orilla, más arriba que ella: el lomo es lo que más se mira.
VISTAS_EXTRA = (("arriba", 180, 8), ("tres_cuartos_alto", 35, 0.9))
ENCUADRE_CAJA = True  # es el doble de larga que de alta: la cámara toma la caja entera

for _f in ("dragon_v2_formas.py", "orca_v2_e3_cabeza.py", "orca_v2_e3_cuerpo.py"):
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


# --- Paleta (sRGB, BIBLIA.md, 2) -----------------------------------------------------------
def _lineal(hexa):
    """sRGB "#RRGGBB" -> color lineal (lo que espera el Principled BSDF)."""
    c = [int(hexa[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return tuple(round(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4, 4) for x in c)


COLORES = {n: _lineal(h) for n, h in {
    "cuerpo": "#1B202B",  # negro azulado: cabeza y anillos del cuerpo
    "placa": "#2A3242",  # placas del lomo y de la frente
    "branquia": "#12161E",
    "blanco": "#E4E8EE",  # mandíbula y garganta (sin blanco puro)
    "panza": "#B4BCC8",
    "panza_osc": "#7D8696",
    "aleta": "#1E3054",  # azul marino: dorsal y cola
    "pectoral": "#262D3A",
    "pua": "#555E6E",
    "ceja": "#3A4250",
    "cuenca": "#0A0C10",  # fondo oscuro del ojo: la pupila roja de Neon la pone el código
    "brillo": "#45E3FF",  # mancha de orca y puntos (Neon)
    "boca": "#4E1520",
    "lengua": "#8C2C3C",
    "diente": "#EEE9DD",
    "cicatriz": "#C0343C",
    "percebe": "#CFC2A8",
    "alga": "#3E8040",
}.items()}


def construir():
    cabeza(); cuerpo(); dorsal(); pectorales(); cola(); adornos()


# --- Rig (orca_ref/CONTRATO_RIG_NADO.md, 1) ------------------------------------------------
# Hueso -> (padre, articulación en celdas). {l}: Izq en +x y Der espejado; el padre antes que el
# hijo; sin padre, cuelga de Raiz. La cola cuelga del Pecho, en cadena.
ARTICULACIONES = [
    ("Pecho", None, (0, -10, 10)),  # centro del anillo de adelante
    ("Cabeza", "Pecho", (0, -16, 14)),  # la nuca: en la cara de unión, 4 celdas bajo el lomo
    ("Mandibula", "Cabeza", (0, -20, 5)),  # bisagra: una celda delante de la cuña de atrás, bajo la mejilla
    ("Aleta{l}", "Pecho", (5, -11, 7.75)),  # hombro: en la cara de adentro, cerca del borde de arriba
    ("Aleta{l}2", "Aleta{l}", (10, -10, 3.5)),  # codo: una celda dentro de la punta del primer tramo
    # Columna: en el centro de la celda de solape con el anillo anterior y a media altura del
    # anillo más chico (el de atrás).
    ("Cola1", "Pecho", (0, -4.5, 10)),
    ("Cola2", "Cola1", (0, 3.5, 10)),
    ("Cola3", "Cola2", (0, 10.5, 10)),
    ("Cola4", "Cola3", (0, 16.5, 10)),
    ("Cola5", "Cola4", (0, 21.5, 10)),
    ("Dorsal", "Cola1", (0, -2, 16)),  # base metida en el lomo, una celda bajo el de la Cola1
    ("AletaCola{l}", "Cola5", (2, 25, 10)),  # raíz del lóbulo, en el costado de la Cola5
]
# Cola de cada hueso (celdas, lado izquierdo): hacia el hijo, o hacia donde apunta la pieza.
COLAS = {
    "Pecho": (0, -4.5, 10), "Cabeza": (0, -31, 12), "Mandibula": (0, -30, 4),
    "Aleta{l}": (10, -10, 3.5), "Aleta{l}2": (17, -9, 1),
    "Cola1": (0, 3.5, 10), "Cola2": (0, 10.5, 10), "Cola3": (0, 16.5, 10), "Cola4": (0, 21.5, 10),
    "Cola5": (0, 26, 10), "Dorsal": (0, -4, 31), "AletaCola{l}": (12, 32, 10),
}
# Huesos sin pesos: (padre, cabeza, cola). Raiz en el centro del largo a media altura del cuerpo;
# Boca entre los dientes de adelante; Espiraculo sobre la frente. Ojo{l}Mira en el centro de la
# cara de la cuenca (UIConfig/GiantEyesData, OrcaE3: (±3.494, -14.006, 6.5) BU), con la cola a lo
# largo de su normal (±0.7071, -0.7071, 0).
_OJO, _NORMAL = (3.494 / CELDA, -14.006 / CELDA, 6.5 / CELDA), (0.7071, -0.7071, 0)
PUNTOS = {
    "Raiz": (None, (0, 1, 10), (0, -2, 10)),
    "Boca": ("Cabeza", (0, -30, 8.5), (0, -32, 8.5)),
    "Espiraculo": ("Cabeza", (0, -22, 18), (0, -22, 20)),
}
for _s, _l in ((1, "Izq"), (-1, "Der")):
    _c = (_s * _OJO[0], _OJO[1], _OJO[2])
    PUNTOS[f"Ojo{_l}Mira"] = ("Cabeza", _c, (_c[0] + _s * _NORMAL[0] * 2, _c[1] + _NORMAL[1] * 2, _c[2]))
