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
    - cada tramo va más atrás en y que el anterior y comparte con él al menos una celda. El paso
      crece de la cola de arriba a la de abajo (A 2, B 3, C 4): de perfil el abanico se abre
      hacia atrás y arriba como un abanico, no como una escalera;
    - las raíces arrancan en el borde de atrás de la grupa (y 7 y 8) y los planos y de A, B y C
      están elegidos para que dos colas distintas que se tocan o se solapan un poco nunca tengan
      caras en el mismo plano con la misma orientación. Una cola y su espejo comparten planos:
      no se tocan.
El pivote de cada tramo es el centro del borde donde nace (en y, el medio de la celda que comparte
con el tramo anterior). Cada tramo lleva una veta clara de una celda a lo largo, en la misma línea
que la del anterior: se lee como una franja de luz. La punta es de espuma y rompe como ola: una
cresta que sube y un labio que se enrula hacia arriba y afuera, con cristalitos de hielo.
"""

# Direcciones de la cuadrícula (paso en x, paso en z), con x hacia afuera.
# (Ojo: V es el Vector de mathutils en el armador; no se pisa.)
VERT, P12, P11, P21, HORIZ = (0, 1), (1, 2), (1, 1), (2, 1), (1, 0)
# (izquierda, espejo, centro de la raíz (x, z), y del primer tramo, paso en y, hondo,
#  [(dirección, borde, ancho, largo)])
COLAS_ABANICO = [
    ("Cola3", "Cola4", (3, 12), 7, 2, 4,  # A, la central: sube vertical y se abre 1:2 -> 1:1
     [(VERT, "h", 4, 3), (VERT, "h", 6, 4), (P12, "h", 4, 3), (P12, "h", 6, 3), (P11, "h", 4, 2)]),
    ("Cola2", "Cola5", (4, 9), 8, 3, 4,  # B, la del medio: 1:2 -> 1:1 -> 2:1 y la punta se levanta
     [(P12, "h", 4, 3), (P12, "h", 6, 3), (P11, "h", 4, 3), (P21, "v", 6, 2), (P11, "h", 4, 2)]),
    ("Cola1", "Cola6", (3, 7), 8, 4, 5,  # C, la de abajo: 1:1 -> 2:1 -> horizontal y la punta sube
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
    afuera y vuela por encima del costado. Dos cristalitos de hielo: adelante del labio y atrás."""
    (xl, zt), (xr, _) = sorted(pol[2:], key=lambda p: p[0])
    cresta = [(xl, zt), (xr, zt), (xr + 1, zt + 2), (xl + 1, zt + 2)]
    labio = [(xl + 1, zt + 2), (xr + 1, zt + 2), (xr + 3, zt + 3), (xr + 2, zt + 4), (xl + 3, zt + 4)]
    prisma(nombre, "Cola", "espuma", pieza(cresta), y, "y")
    prisma(nombre, "Cola", "espuma", pieza(labio), y, "y")
    cubo = lambda x, z: [(x, z), (x + 1, z), (x + 1, z + 1), (x, z + 1)]
    prisma(nombre, "Cola", "hielo", pieza(cubo(xr + 1, zt + 2)), (y[0] - 1, y[0]), "y")
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
