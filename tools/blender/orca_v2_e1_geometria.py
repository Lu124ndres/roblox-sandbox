r"""
Orca v2, etapa 1 (cría): los datos de la etapa para minotauro_v2_bloques.py (--criatura orca).
Sale de la maestra (orca_v2_e3_*.py, aprobada): la misma orca de bloques, con las mismas piezas y
el mismo método (anillos que nacen una celda dentro del anterior, dorsal de canto, pectorales en
dos tramos, cola en V horizontal, boca con dientes intercalados). Lo de cría (BIBLIA.md, 4b):
cabeza grande (un 35 % del largo) con la frente alta, cuencas grandes para los ojos y las cejas
apenas fruncidas, boca entreabierta con dientes chicos, cuerpo corto y rechoncho, panza blanca
grande, dorsal baja y redondeada, aletas cortas y anchas y tres bultitos en vez de púas. Sin
cicatrices ni percebes: solo una alguita.

Proporciones (31 módulos de alto: de la panza a la punta de la dorsal):
    panza       z 0         blanca hasta z 7 en el Pecho
    cabeza      y -25..-8   mandíbula z 1..6, boca entreabierta z 6..10, cráneo z 10..24
                            (22 de ancho: más ancha y más alta que el Pecho)
    cuerpo      y -8..20    Pecho y Cola1..Cola5, de 20 a 6 de ancho
    dorsal      z 16..31    cola en V hasta y 25 (50 de largo)
Las articulaciones del rig (ARTICULACIONES, COLAS y PUNTOS) van al final; las usan
orca_v2_poses.py y rig_orca_v2.py. La cabeza está en orca_v2_e1_cabeza.py, el cuerpo y las aletas
en orca_v2_e1_cuerpo.py y las formas que no son bloques (prisma, par_prisma) en dragon_v2_formas.py.
Ejes: x = izquierda de la orca, -y = frente, z arriba; la panza en z = 0.
"""
CELDA = 0.1  # BU por celda (módulo de la etapa; docs/estilo_modelos.md, "Escala")
ALTO_JUEGO = 16.5  # studs: 3 x 5.5 (Config/Giants.luau); 16.5 / 3.1 = 5.32 studs por BU
MODELO = "Orca"
PREFIJO = "OrcaV2_"
# En el juego se la ve desde la orilla, más arriba que ella: el lomo es lo que más se mira.
VISTAS_EXTRA = (("arriba", 180, 8), ("tres_cuartos_alto", 35, 0.9))
ENCUADRE_CAJA = True  # más larga que alta: la cámara toma la caja entera

for _f in ("dragon_v2_formas.py", "orca_v2_e1_cabeza.py", "orca_v2_e1_cuerpo.py"):
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


# --- Paleta (sRGB, columna E1 de BIBLIA.md, 4b; lo que no está ahí, como la E3) -------------
def _lineal(hexa):
    """sRGB "#RRGGBB" -> color lineal (lo que espera el Principled BSDF)."""
    c = [int(hexa[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return tuple(round(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4, 4) for x in c)


COLORES = {n: _lineal(h) for n, h in {
    "cuerpo": "#2E3748",  # negro azulado, más claro que en la E3: cabeza y anillos
    "placa": "#3C4659",  # placas del lomo y de la frente
    "branquia": "#12161E",
    "blanco": "#E4E8EE",  # mandíbula, garganta y panza (sin blanco puro)
    "panza": "#B4BCC8",
    "panza_osc": "#7D8696",
    "aleta": "#2C4374",  # azul marino: dorsal y cola
    "pectoral": "#353E50",
    "pua": "#555E6E",  # bultitos
    "ceja": "#3A4250",
    "cuenca": "#0A0C10",  # fondo oscuro del ojo: la pupila roja de Neon la pone el código
    "brillo": "#45E3FF",  # mancha de orca y puntos (Neon)
    "boca": "#4E1520",
    "lengua": "#8C2C3C",
    "diente": "#EEE9DD",
    "alga": "#3E8040",
}.items()}


def construir():
    cabeza(); cuerpo(); dorsal(); pectorales(); cola(); adornos()


# --- Rig (orca_ref/CONTRATO_RIG_NADO.md, 1) ------------------------------------------------
# Hueso -> (padre, articulación en celdas). {l}: Izq en +x y Der espejado; el padre antes que el
# hijo; sin padre, cuelga de Raiz. La cola cuelga del Pecho, en cadena.
ARTICULACIONES = [
    ("Pecho", None, (0, -3, 10.5)),  # centro del anillo de adelante
    ("Cabeza", "Pecho", (0, -8, 17)),  # la nuca: en la cara de unión, a 2/3 de la cara de atrás
    ("Mandibula", "Cabeza", (0, -13, 5)),  # bisagra: en medio de la cuña de atrás, bajo el borde
    ("Aleta{l}", "Pecho", (8, -3, 5.4)),  # hombro: en la cara de adentro, abajo (barrido de z)
    ("Aleta{l}2", "Aleta{l}", (11, -2.5, 5)),  # codo: una celda dentro de la punta del primer tramo
    # Columna: en el centro de la celda de solape con el anillo anterior y a media altura del
    # anillo más chico (el de atrás).
    ("Cola1", "Pecho", (0, 1.5, 10.5)),
    ("Cola2", "Cola1", (0, 6.5, 10.5)),
    ("Cola3", "Cola2", (0, 10.5, 10.5)),
    ("Cola4", "Cola3", (0, 13.5, 10.5)),
    ("Cola5", "Cola4", (0, 16.5, 10.5)),
    ("Dorsal", "Cola1", (0, 2, 19)),  # base metida en el lomo, una celda bajo el de la Cola1
    ("AletaCola{l}", "Cola5", (3, 19, 11)),  # raíz del lóbulo, en el costado de la Cola5
]
# Cola de cada hueso (celdas, lado izquierdo): hacia el hijo, o hacia donde apunta la pieza.
COLAS = {
    "Pecho": (0, 1.5, 10.5), "Cabeza": (0, -25, 13), "Mandibula": (0, -24, 3),
    "Aleta{l}": (11, -2.5, 5), "Aleta{l}2": (17, -1, 2.5),
    "Cola1": (0, 6.5, 10.5), "Cola2": (0, 10.5, 10.5), "Cola3": (0, 13.5, 10.5),
    "Cola4": (0, 16.5, 10.5), "Cola5": (0, 20, 10.5), "Dorsal": (0, 4.5, 31), "AletaCola{l}": (9, 24, 11),
}
# Huesos sin pesos: (padre, cabeza, cola). Raiz en el centro del largo a media altura del cuerpo;
# Boca entre los dientes de adelante; Espiraculo sobre la frente, detrás del bultito. Ojo{l}Mira en
# el centro de la cara de la cuenca (UIConfig/GiantEyesData, OrcaE1: (±0.9226, -1.8774, 1.7938)
# BU), con la cola a lo largo de su normal (±0.7071, -0.7071, 0).
_OJO, _NORMAL = (0.9226 / CELDA, -1.8774 / CELDA, 1.7938 / CELDA), (0.7071, -0.7071, 0)
PUNTOS = {
    "Raiz": (None, (0, 0, 10.5), (0, -3, 10.5)),
    "Boca": ("Cabeza", (0, -24, 8), (0, -26, 8)),
    "Espiraculo": ("Cabeza", (0, -12, 24), (0, -12, 26)),
}
for _s, _l in ((1, "Izq"), (-1, "Der")):
    _c = (_s * _OJO[0], _OJO[1], _OJO[2])
    PUNTOS[f"Ojo{_l}Mira"] = ("Cabeza", _c, (_c[0] + _s * _NORMAL[0] * 2, _c[1] + _NORMAL[1] * 2, _c[2]))
