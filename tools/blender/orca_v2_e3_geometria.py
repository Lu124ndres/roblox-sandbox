r"""
Orca v2, etapa 3 (adulto, la maestra): los datos de la etapa para minotauro_v2_bloques.py
(--criatura orca). La biblia es orca_ref/BIBLIA.md (fuera del repo): una orca monstruo de bloques,
un torpedo largo de placas negro azuladas en anillos que se escalonan hacia la cola, la aleta
dorsal alta echada hacia atrás, la boca abierta con dos filas de dientes, ojos rojos con cejas de
enojo y la mancha de orca en cian que brilla, púas grises por todo el lomo, pectorales largas que
bajan hacia afuera y la cola en V. Detalles: branquias, puntos cian, cicatrices, percebes y algas.

Proporciones (31 módulos de alto: de la punta de las pectorales a la de la dorsal):
    pectorales  hasta z 0       panza z 2..5 (blanca, después gris)
    cabeza      y -31..-16      mandíbula z 3..7, boca abierta z 7..10, cráneo z 10..18
    cuerpo      y -16..26       Pecho y Cola1..Cola5, de 14 a 4 de ancho
    dorsal      z 14..31        cola en V hasta y 33
Solo el modelo para revisar la forma: todavía sin articulaciones ni rig. La cabeza está en
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
CONTRATO_SIN_PESOS = ["Raiz", "Boca", "Espiraculo"]


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
    "ojo": "#FF2B2B",  # en Roblox, Neon
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
