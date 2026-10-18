r"""
Colas del Zorro de agua v2, etapa 4 (forma final): nueve colas de cinco tramos en el abanico de la
referencia, lleno y alto. La carga zorro_v2_e4_geometria.py con exec; usa prisma() de
dragon_v2_formas.py. Las reglas de la maestra (zorro_v2_e3_colas.py) con las correcciones que
pidieron las poses extremas (zorro_v2_poses.py):

Cada cola es una cadena de tramos en el plano x-z (x hacia afuera, z arriba), cada uno en una
dirección exacta de la cuadrícula. Cambiar de dirección de un tramo al siguiente curva la cola.
Cada tramo es un paralelogramo extruido en y; el borde donde nace es horizontal (h) en los tramos
empinados y vertical (v) en los tendidos. Juntas:
    - el tramo siguiente nace DOS CELDAS ADENTRO del anterior (RETRO), centrado en su línea, y a dos
      o más de su base: tapa la junta al doblarse 45° aunque el tramo sea ancho;
    - dos tramos seguidos en la misma dirección nunca miden lo mismo de ancho (4 y 6, nunca más
      de 8): sus costados nunca quedan en el mismo plano;
Capas de profundidad (las reglas que dejaron limpia la E3): el abanico gira alrededor de y, así que
si dos tramos que se tapan en x-z viven en franjas y separadas, nunca se cruzan:
    - dos tramos de colas distintas que se solapan en x-z dejan al menos una celda entre sus franjas
      en y; si solo se tocan o están a menos de 1.5 celdas, no comparten franja;
    - lo mismo dos tramos no seguidos de una misma cola: hondo 2 con paso 1 (dos seguidos comparten
      una celda);
    - CAPAS (y de la raíz, paso, hondo de cada cola) sale de zorro_v2_e4_capas.py, que lista los
      pares cercanos y busca la combinación menos honda; con nueve colas el abanico es más denso que
      en la E3, así que también dos tramos a menos de 2.5 celdas dejan una celda, las puntas tres, y
      la cola cuya punta tapa los tramos medios de otra va detrás. De adelante hacia atrás: A (y 0,
      sale del lomo, encima del anca con una celda de aire), B (y 8, toca la cara de atrás de la
      grupa), la central (y 12), C (y 20) y D (y 26), apoyadas en la base de las colas (BASE, una
      losa de la Cadera bajo la grupa);
    - una cola y su espejo comparten capa y van a 2 celdas o más en x; la central va sola;
    - los cristalitos de la punta no salen de su franja.
El abanico (BIBLIA.md, 8): la central (Cola1) sube vertical y es lo más alto (31); a cada lado
A (1:2 que se abre), B (1:1), C (2:1) y D (casi horizontal: cae y levanta la punta). Nombres:
Cola1 la central; Cola2/Cola3 A, Cola4/Cola5 B, Cola6/Cola7 C y Cola8/Cola9 D (izquierda, derecha).
El pivote de cada tramo es el centro del borde donde nace (en y, el medio de lo que comparte con el
tramo anterior; en la raíz, el medio de la franja). Cada tramo lleva una veta clara a lo largo, en
la misma línea que la del anterior (en la central, de dos celdas y centrada). La punta es de espuma y rompe como ola: una
cresta que sube y un labio que se enrula hacia arriba y afuera, con cristalitos de hielo; la
central termina en una aguja de espuma simétrica.
"""

# Direcciones de la cuadrícula (paso en x, paso en z), con x hacia afuera.
# (Ojo: V es el Vector de mathutils en el armador; no se pisa.)
VERT, P12, P11, P21, HORIZ = (0, 1), (1, 2), (1, 1), (2, 1), (1, 0)
CAE21 = (2, -1)  # la D baja 2:1 antes de levantar la punta
# Cuántos pasos atrás de la punta del anterior nace cada tramo: dos celdas (dos pasos en vertical,
# horizontal o 1:1; uno en 1:2 o 2:1). A 45° la esquina de un tramo ancho sube medio ancho x sen 45°.
RETRO = {VERT: 2, HORIZ: 2, P11: 2, P12: 1, P21: 1, CAE21: 1}
# Capas de profundidad (las reglas que dejaron limpia la E3; ver el docstring): CAPAS da, por
# cola, (y de la raíz, paso en y por tramo, hondo). Las calcula zorro_v2_e4_capas.py a partir de los
# pares de tramos que se tocan en x-z.
CAPAS = {"Cola1": (12, 2, 3), "Cola2": (0, 2, 3), "Cola4": (8, 2, 3), "Cola6": (20, 2, 3),
         "Cola8": (26, 2, 3)}
# Base de las colas (losa de la Cadera bajo la grupa) donde se apoyan las raíces de atrás.
BASE_X, BASE_Y, BASE_Z = (-4, 4), (8, 28), (7, 10)
# (izquierda, espejo o None, centro de la raíz (x, z), [(dirección, borde, ancho, largo)])
COLAS_ABANICO = [
    ("Cola1", None, (0, 9),  # central: sube vertical y es lo más alto
     [(VERT, "h", 4, 5), (VERT, "h", 6, 5), (VERT, "h", 4, 5), (VERT, "h", 6, 5), (VERT, "h", 4, 6)]),
    ("Cola2", "Cola3", (3, 11),  # A: 1:2 que se abre a 1:1 y levanta la punta
     [(P12, "h", 4, 2), (P12, "h", 6, 3), (P12, "h", 4, 2), (P11, "h", 6, 4), (P12, "h", 4, 2)]),
    ("Cola4", "Cola5", (5, 9),  # B: 1:1 y la punta se levanta
     [(P11, "h", 4, 5), (P11, "h", 6, 4), (P11, "h", 4, 4), (P11, "h", 6, 4), (P12, "h", 4, 2)]),
    ("Cola6", "Cola7", (3, 8),  # C: 2:1 -> horizontal y la punta sube
     [(P21, "v", 4, 4), (P21, "v", 6, 3), (HORIZ, "v", 4, 6), (P11, "h", 4, 4), (P12, "h", 6, 2)]),
    ("Cola8", "Cola9", (3, 7),  # D: horizontal, cae 2:1 y levanta la punta
     [(HORIZ, "v", 4, 5), (CAE21, "v", 4, 2), (HORIZ, "v", 6, 4), (P21, "v", 4, 4), (P11, "h", 4, 2)]),
]
COLOR_TRAMO = ("raiz", "cuerpo", "cuerpo", "claro", "espuma")
COLOR_VETA = ("cuerpo", "claro", "claro", "verde", "sombra")


def tramos(raiz, capa, lista):
    """Los tramos de una cola izquierda: [(polígono x-z, (y0, y1), pivote, punta, dirección, borde)].
    El polígono empieza por el borde donde nace: a, b, b + n·d, a + n·d."""
    (y_raiz, paso_y, hondo), c, salida = capa, raiz, []
    for k, (d, borde, w, n) in enumerate(lista):
        e = (1, 0) if borde == "h" else (0, 1)  # a lo largo del borde de nacimiento
        a = (c[0] - w // 2 * e[0], c[1] - w // 2 * e[1])
        b = (c[0] + w // 2 * e[0], c[1] + w // 2 * e[1])
        pol = [a, b, (b[0] + n * d[0], b[1] + n * d[1]), (a[0] + n * d[0], a[1] + n * d[1])]
        y0 = y_raiz + paso_y * k
        fin = (c[0] + n * d[0], c[1] + n * d[1])  # centro de la punta del tramo
        py = y0 + (hondo - paso_y) / 2 if k else y0 + hondo / 2  # el medio de lo que comparte
        salida.append((pol, (y0, y0 + hondo), (c[0], py, c[1]), (fin[0], py, fin[1]), d, borde))
        r = RETRO[d]  # el siguiente nace dos celdas adentro
        c = (fin[0] - r * d[0], fin[1] - r * d[1])
    return salida


def _espejo(pol):
    return [(-x, z) for x, z in pol]


def franjas(pol, w, central=False):
    """El tramo partido a lo largo en tres: hasta la veta, la veta y el resto. La veta mide una celda
    a la izquierda del centro; en la central, dos celdas centradas. Devuelve [(polígono, es_veta)]."""
    a, b, c, d = pol
    paso = ((b[0] - a[0]) // w, (b[1] - a[1]) // w)
    o, o2 = (w // 2 - 1, w // 2 + 1) if central else (w // 2 - 1, w // 2)
    corte = lambda t: ((a[0] + t * paso[0], a[1] + t * paso[1]), (d[0] + t * paso[0], d[1] + t * paso[1]))
    piezas = []
    for t0, t1, veta in ((0, o, False), (o, o2, True), (o2, w, False)):
        if t1 > t0:
            (p0, q0), (p1, q1) = corte(t0), corte(t1)
            piezas.append(([p0, p1, q1, q0], veta))
    return piezas


def _cubo(x, z):
    return [(x, z), (x + 1, z), (x + 1, z + 1), (x, z + 1)]


def ola(nombre, pol, y, pieza):
    """Cresta de espuma sobre la punta (borde de arriba horizontal, de xl a xr): sube dos celdas
    inclinada 1:2 hacia afuera y encima el labio, de dos celdas, que se enrula hacia arriba y
    afuera y vuela por encima del costado. Encima del labio, dos cristalitos de hielo, uno adelante
    y otro atrás, sin salir de la franja de la cola (no invaden la capa de la vecina)."""
    (xl, zt), (xr, _) = sorted(pol[2:], key=lambda p: p[0])
    cresta = [(xl, zt), (xr, zt), (xr + 1, zt + 2), (xl + 1, zt + 2)]
    labio = [(xl + 1, zt + 2), (xr + 1, zt + 2), (xr + 3, zt + 3), (xr + 2, zt + 4), (xl + 3, zt + 4)]
    prisma(nombre, "Cola", "espuma", pieza(cresta), y, "y")
    prisma(nombre, "Cola", "espuma", pieza(labio), y, "y")
    prisma(nombre, "Cola", "hielo", pieza(_cubo(xl + 3, zt + 4)), (y[0], y[0] + 1), "y")
    prisma(nombre, "Cola", "hielo", pieza(_cubo(xr + 1, zt + 4)), (y[1] - 1, y[1]), "y")


def aguja(nombre, pol, y):
    """La punta de la central: una cresta recta de dos celdas y encima una aguja que se cierra 1:2
    hasta un borde plano de dos celdas (el bisel no le come el alto). Cristalitos a cada lado."""
    (xl, zt), (xr, _) = sorted(pol[2:], key=lambda p: p[0])
    prisma(nombre, "Cola", "espuma", [(xl, zt), (xr, zt), (xr, zt + 2), (xl, zt + 2)], y, "y")
    prisma(nombre, "Cola", "espuma", [(xl, zt + 2), (xr, zt + 2), (xr - 1, zt + 4), (xl + 1, zt + 4)], y, "y")
    prisma(nombre, "Cola", "hielo", _cubo(xr, zt + 1), (y[0], y[0] + 1), "y")
    prisma(nombre, "Cola", "hielo", _cubo(xl - 1, zt + 1), (y[1] - 1, y[1]), "y")


def colas():
    for izq, der, raiz, lista in COLAS_ABANICO:
        t = tramos(raiz, CAPAS[izq], lista)
        lados = ((izq, 1),) if der is None else ((izq, 1), (der, -1))
        for nombre, s in lados:
            pieza = lambda pol: pol if s > 0 else _espejo(pol)
            for k, (pol, y, _, _, _, _) in enumerate(t):
                for parte, veta in franjas(pol, lista[k][2], der is None):
                    color = COLOR_VETA[k] if veta else COLOR_TRAMO[k]
                    prisma(f"{nombre}_{k + 1}", "Cola", color, pieza(parte), y, "y")
            if der is None:
                aguja(f"{nombre}_5", t[-1][0], t[-1][1])
            else:
                ola(f"{nombre}_5", t[-1][0], t[-1][1], pieza)


def articulaciones_colas():
    """[(hueso, padre, pivote)] y {hueso: punta} de las nueve colas, en celdas."""
    arts, puntas = [], {}
    for izq, der, raiz, lista in COLAS_ABANICO:
        lados = ((izq, 1),) if der is None else ((izq, 1), (der, -1))
        for nombre, s in lados:
            for k, (_, _, piv, punta, _, _) in enumerate(tramos(raiz, CAPAS[izq], lista)):
                hueso = f"{nombre}_{k + 1}"
                padre = "Cadera" if k == 0 else f"{nombre}_{k}"
                arts.append((hueso, padre, (s * piv[0], piv[1], piv[2])))
                puntas[hueso] = (s * punta[0], punta[1], punta[2])
    return arts, puntas
