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
Solo el modelo para revisar la forma: todavía sin articulaciones ni rig. La cabeza está en
orca_v2_e2_cabeza.py, el cuerpo y las aletas en orca_v2_e2_cuerpo.py y las formas que no son
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
