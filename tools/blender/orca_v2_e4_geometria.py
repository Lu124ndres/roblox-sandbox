r"""
Orca v2, etapa 4 (anciana, la forma final): los datos de la etapa para minotauro_v2_bloques.py
(--criatura orca). Sale de la E3 aprobada (orca_v2_e3_geometria.py): las mismas piezas y el mismo
método de juntas, en su versión más terrorífica y con más detalle (BIBLIA.md, 4b, columna E4):
  - El cuerpo casi negro, acorazado: cada anillo es un núcleo cian envuelto en placas de una celda
    de grueso, y las GRIETAS son las juntas entre placas (vetas continuas de una celda que se
    cruzan en T), por donde asoma el núcleo. Nunca puntos sueltos.
  - Cabeza masiva pero chica para el cuerpo (22 % del largo): hocico bajo, cejas acorazadas en V,
    cuencas rasgadas (la pupila roja la pone el código), una cicatriz que cruza la izquierda, la
    mancha de orca cian y la boca bien abierta con filas de colmillos largos (uno roto).
  - La dorsal alta y desgarrada, con dos mordidas; púas grandes en hilera doble por el lomo, que
    siguen por la cola (una sola en los anillos finos) y en el borde de la cola en V; garras en la
    punta de las pectorales.
  - Tres arpones viejos clavados en el lomo, con cabos rotos que cuelgan; una herida vieja con
    costillas que asoman; muchas cicatrices, costras de percebes y algas largas.

Proporciones (31 módulos de alto: de la punta de las pectorales a la de la dorsal):
    pectorales  hasta z 0       panza z 2 (blanca, después gris)
    cabeza      y -30..-16      mandíbula z 2..6, boca abierta z 6..12, cráneo z 12..19
    cuerpo      y -16..28       Pecho y Cola1..Cola5, de 16 a 6 de ancho; lomo z 20
    dorsal      z 16..31        cola en V hasta y 33 (63 de largo)
Solo el modelo para revisar la forma: todavía sin articulaciones ni rig. La cabeza está en
orca_v2_e4_cabeza.py, el cuerpo y las aletas en orca_v2_e4_cuerpo.py, los adornos en
orca_v2_e4_detalles.py y las formas que no son bloques (prisma, par_prisma, lamina) en
dragon_v2_formas.py.
Ejes: x = izquierda de la orca, -y = frente, z arriba; la punta de las pectorales en z = 0.
"""
CELDA = 1.0  # BU por celda (módulo de la etapa; docs/estilo_modelos.md, "Escala")
ALTO_JUEGO = 165.0  # studs: 30 x 5.5 (Config/Giants.luau); 165 / 31 = 5.32 studs por BU
MODELO = "Orca"
PREFIJO = "OrcaV2_"
# En el juego se la ve desde la orilla, más arriba que ella: el lomo es lo que más se mira.
VISTAS_EXTRA = (("arriba", 180, 8), ("tres_cuartos_alto", 35, 0.9))
ENCUADRE_CAJA = True  # es el doble de larga que de alta: la cámara toma la caja entera

for _f in ("dragon_v2_formas.py", "orca_v2_e4_cabeza.py", "orca_v2_e4_cuerpo.py",
           "orca_v2_e4_detalles.py"):
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


# --- Paleta (sRGB, BIBLIA.md, 2 y la columna E4 de 4b) -------------------------------------
def _lineal(hexa):
    """sRGB "#RRGGBB" -> color lineal (lo que espera el Principled BSDF)."""
    c = [int(hexa[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return tuple(round(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4, 4) for x in c)


COLORES = {n: _lineal(h) for n, h in {
    "cuerpo": "#13171F",  # casi negro: cabeza, cuñas y placas del medio
    "placa": "#232A36",  # placas acorazadas del lomo y de la frente
    "branquia": "#12161E",
    "blanco": "#E4E8EE",  # mandíbula y garganta (sin blanco puro)
    "panza": "#B4BCC8",
    "panza_osc": "#7D8696",
    "aleta": "#182746",  # azul marino: dorsal y cola
    "pectoral": "#1E242F",
    "pua": "#555E6E",
    "ceja": "#3A4250",
    "cuenca": "#0A0C10",  # fondo oscuro del ojo: la pupila roja de Neon la pone el código
    "brillo": "#5CF0FF",  # grietas, núcleo de los anillos y mancha de orca (Neon)
    "boca": "#4E1520",  # también la carne de la herida
    "lengua": "#8C2C3C",
    "diente": "#EEE9DD",
    "cicatriz": "#D23A3A",
    "percebe": "#CFC2A8",
    "alga": "#3E8040",
    "hueso": "#D9D2BF",  # costillas de la herida
    "arpon": "#7C838E",  # metal de los arpones
    "oxido": "#7A4A30",
    "cabo": "#9C8460",  # sogas rotas
}.items()}


def construir():
    cabeza(); cuerpo(); dorsal(); pectorales(); cola()
    puas(); arpones(); herida(); cicatrices(); percebes(); algas()
