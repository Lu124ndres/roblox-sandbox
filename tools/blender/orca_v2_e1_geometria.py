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
Solo el modelo para revisar la forma: todavía sin articulaciones ni rig. La cabeza está en
orca_v2_e1_cabeza.py, el cuerpo y las aletas en orca_v2_e1_cuerpo.py y las formas que no son
bloques (prisma, par_prisma) en dragon_v2_formas.py.
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
