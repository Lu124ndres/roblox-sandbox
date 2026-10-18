r"""
Colas del Zorro de agua v2, etapa 3 (adulto): seis colas de cinco tramos en un abanico lleno que
sube y se abre en arco. La carga zorro_v2_e3_geometria.py con exec; usa prisma() de
dragon_v2_formas.py.

Cada cola es una cadena de tramos en el plano x-z (x hacia afuera, z arriba), cada uno en una
dirección exacta de la cuadrícula: vertical, 1:2, 1:1, 2:1 u horizontal. Cambiar de dirección de
un tramo al siguiente curva la cola. Cada tramo es un paralelogramo extruido en y; el borde donde
nace es horizontal (h) en los tramos empinados y vertical (v) en los tendidos. Reglas de las juntas
(BIBLIA.md, 8):
    - el tramo siguiente nace UN PASO ADENTRO del anterior (un paso en la dirección del anterior,
      desde el centro de su punta) y centrado en esa línea: tapa la junta al doblarse;
    - dos tramos seguidos en la misma dirección nunca miden lo mismo de ancho (4, 6, ...): sus
      costados nunca quedan en el mismo plano;
    - cada tramo va más atrás en y que el anterior y comparte con él al menos una celda;
Reglas de las franjas (para que las colas no se crucen al moverse): cada cola vive en su capa de
profundidad. Una cola se mueve en el abanico girando alrededor del eje y, así que si dos tramos
que se tapan en x-z tienen franjas y separadas, el abanico nunca los cruza:
    - dos tramos de colas distintas que se solapan en x-z no comparten franja: entre ellos queda
      al menos una celda en y (si solo se tocan o están a menos de 1.5 celdas, no comparten);
    - lo mismo dos tramos no seguidos de una misma cola (el 2 y el 4 de la B se solapan): el paso
      por tramo es al menos la mitad del hondo más media celda;
    - capas, de adelante hacia atrás: A (y 4), B (y 8) y C (y 13). La B da pasos de 2 y la A de 1:
      la distancia entre las dos crece hacia arriba, donde la A se tapa con tramos más altos de la
      B. La punta de la C se curva sobre los tramos medios de la B, por eso la C va detrás;
    - hondo de 3 o menos (2 en la A, que da pasos de 1), así las capas caben detrás de la grupa;
    - la raíz de la B toca la cara de atrás de la grupa (y 8) y deja una celda al muslo; la de la A
      sube del lomo (z 13) y la de la C apoya en la base de las colas (Cadera, zorro_v2_e3_cuerpo.py).
La cola central y su espejo comparten capa: van separadas 2 celdas en x (raíz en x 4).
"""

# Direcciones de la cuadrícula (paso en x, paso en z), con x hacia afuera.
# (Ojo: V es el Vector de mathutils en el armador; no se pisa.)
VERT, P12, P11, P21, HORIZ = (0, 1), (1, 2), (1, 1), (2, 1), (1, 0)
# (izquierda, espejo, centro de la raíz (x, z), y del primer tramo, paso en y, hondo,
#  [(dirección, borde, ancho, largo)])
COLAS_ABANICO = [
    ("Cola3", "Cola4", (4, 13), 4, 1, 2,  # A, la central: sube vertical y se abre 1:2 -> 1:1
     [(VERT, "h", 4, 3), (VERT, "h", 6, 3), (P12, "h", 4, 3), (P12, "h", 6, 3), (P11, "h", 4, 2)]),
    ("Cola2", "Cola5", (4, 9), 8, 2, 3,  # B, la del medio: 1:2 -> 1:1 -> 2:1 y la punta se levanta
     [(P12, "h", 4, 3), (P12, "h", 6, 3), (P11, "h", 4, 3), (P21, "v", 6, 2), (P11, "h", 4, 2)]),
    ("Cola1", "Cola6", (3, 7), 13, 2, 3,  # C, la de abajo: 1:1 -> 2:1 -> horizontal y la punta sube
     [(P11, "h", 4, 2), (P21, "v", 6, 2), (HORIZ, "v", 6, 3), (HORIZ, "v", 4, 3), (P12, "h", 4, 3)]),
]
COLOR_TRAMO = ("raiz", "cuerpo", "cuerpo", "claro", "espuma")
COLOR_VETA = ("cuerpo", "claro", "claro", "verde", "sombra")


def tramos(raiz, y_raiz, paso_y, hondo, lista):
    """Los tramos de una cola izquierda: [(polígono x-z, (y0, y1), pivote, punta, dirección, borde)].
    El polígono empieza por el borde donde nace: a, b, b + n·d, a + n·d."""
    c, salida = raiz, []
    for k, (d, borde, w, n) in enumerate(lista):
        e = (1, 0) if borde == "h" else (0, 1)  # a lo largo del borde de nacimiento
        a = (c[0] - w // 2 * e[0], c[1] - w // 2 * e[1])
        b = (c[0] + w // 2 * e[0], c[1] + w // 2 * e[1])
        pol = [a, b, (b[0] + n * d[0], b[1] + n * d[1]), (a[0] + n * d[0], a[1] + n * d[1])]
        y0 = y_raiz + paso_y * k
        fin = (c[0] + n * d[0], c[1] + n * d[1])  # centro de la punta del tramo
        salida.append((pol, (y0, y0 + hondo), (c[0], y0 + 0.5, c[1]), (fin[0], y0 + 0.5, fin[1]), d, borde))
        c = (fin[0] - d[0], fin[1] - d[1])  # el siguiente nace un paso adentro
    return salida


def _espejo(pol):
    return [(-x, z) for x, z in pol]


def franjas(pol, w):
    """El tramo partido a lo largo en tres: hasta la veta, la veta (1 celda, a la izquierda del
    centro) y el resto. Devuelve [(polígono, es_veta)]."""
    a, b, c, d = pol
    paso = ((b[0] - a[0]) // w, (b[1] - a[1]) // w)
    o = w // 2 - 1
    corte = lambda t: ((a[0] + t * paso[0], a[1] + t * paso[1]), (d[0] + t * paso[0], d[1] + t * paso[1]))
    piezas = []
    for t0, t1, veta in ((0, o, False), (o, o + 1, True), (o + 1, w, False)):
        if t1 > t0:
            (p0, q0), (p1, q1) = corte(t0), corte(t1)
            piezas.append(([p0, p1, q1, q0], veta))
    return piezas


def ola(nombre, pol, y, pieza):
    """Cresta de espuma sobre la punta (borde de arriba horizontal, de xl a xr): sube dos celdas
    inclinada 1:2 hacia afuera y encima el labio, de dos celdas, que se enrula hacia arriba y
    afuera y vuela por encima del costado. Dos cristalitos de hielo: uno bajo el rulo del labio
    (dentro de la franja si el hondo deja, así no invade la capa de la vecina de adelante) y otro
    asomando atrás."""
    (xl, zt), (xr, _) = sorted(pol[2:], key=lambda p: p[0])
    cresta = [(xl, zt), (xr, zt), (xr + 1, zt + 2), (xl + 1, zt + 2)]
    labio = [(xl + 1, zt + 2), (xr + 1, zt + 2), (xr + 3, zt + 3), (xr + 2, zt + 4), (xl + 3, zt + 4)]
    prisma(nombre, "Cola", "espuma", pieza(cresta), y, "y")
    prisma(nombre, "Cola", "espuma", pieza(labio), y, "y")
    cubo = lambda x, z: [(x, z), (x + 1, z), (x + 1, z + 1), (x, z + 1)]
    frente = (y[0] + 1, y[0] + 2) if y[1] - y[0] >= 3 else (y[0] - 1, y[0])
    prisma(nombre, "Cola", "hielo", pieza(cubo(xr + 1, zt + 2)), frente, "y")
    prisma(nombre, "Cola", "hielo", pieza(cubo(xl + 2, zt + 3)), (y[1], y[1] + 1), "y")


def colas():
    for izq, der, raiz, y_raiz, paso_y, hondo, lista in COLAS_ABANICO:
        t = tramos(raiz, y_raiz, paso_y, hondo, lista)
        for nombre, s in ((izq, 1), (der, -1)):
            pieza = lambda pol: pol if s > 0 else _espejo(pol)
            for k, (pol, y, _, _, _, _) in enumerate(t):
                for parte, veta in franjas(pol, lista[k][2]):
                    color = COLOR_VETA[k] if veta else COLOR_TRAMO[k]
                    prisma(f"{nombre}_{k + 1}", "Cola", color, pieza(parte), y, "y")
            ola(f"{nombre}_5", t[-1][0], t[-1][1], pieza)


def articulaciones_colas():
    """[(hueso, padre, pivote)] y {hueso: punta} de las seis colas, en celdas."""
    arts, puntas = [], {}
    for izq, der, raiz, y_raiz, paso_y, hondo, lista in COLAS_ABANICO:
        for nombre, s in ((izq, 1), (der, -1)):
            for k, (_, _, piv, punta, _, _) in enumerate(tramos(raiz, y_raiz, paso_y, hondo, lista)):
                hueso = f"{nombre}_{k + 1}"
                padre = "Cadera" if k == 0 else f"{nombre}_{k}"
                arts.append((hueso, padre, (s * piv[0], piv[1], piv[2])))
                puntas[hueso] = (s * punta[0], punta[1], punta[2])
    return arts, puntas
