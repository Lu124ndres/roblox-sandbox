r"""
Cola del Zorro de agua v2, etapa 1 (cría): una sola cola de cinco tramos, central, gruesa y
esponjosa, que sale de la grupa hacia atrás, se curva hacia arriba y rompe en una cresta de espuma
enrulada. La carga zorro_v2_e1_geometria.py con exec; usa prisma() de dragon_v2_formas.py.

Las mismas reglas que el abanico de la maestra (zorro_v2_e3_colas.py; BIBLIA.md, 8), pero la cola
de la cría está en el plano y-z (y hacia atrás, z arriba) y se extruye en x, centrada: así se curva
hacia atrás sin torcerse a un lado. Cada tramo va en una dirección exacta de la cuadrícula
(vertical, 1:2, 1:1, 2:1 u horizontal) y es un paralelogramo extruido en x; el borde donde nace es
horizontal (h) en los tramos empinados y vertical (v) en los tendidos. Juntas:
    - el tramo siguiente nace DOS CELDAS ADENTRO de la punta del anterior (desde el centro de su
      punta, en la dirección del anterior: dos pasos si va vertical, 1:1 u horizontal y uno si va
      1:2 o 2:1) y centrado en esa línea: tapa la junta al doblarse. En la maestra es un paso
      (una celda), pero la cola de la cría es gruesa: a 45° una esquina se levanta la mitad del
      ancho (o del grueso) por sen 45°, y con 8 celdas son 2.8; metida 2, sale 0.8 (umbral 1);
    - dos tramos seguidos en la misma dirección nunca miden lo mismo de ancho (6, 8, ...) y
      ningún tramo que tenga hijo pasa de 8 de ancho ni de grueso (por la cuenta de arriba). El
      hijo también nace a 2 celdas o más de la base del tramo (si no, al doblarse para el otro
      lado la esquina sale por abajo);
    - con las poses del juego (zorro_v2_poses.py): entre un tramo y el que está dos más allá
      quedan 2 celdas libres, 3 entre el tercero y la punta (si se tocan, cualquier curva los
      mete uno en otro), y solo la raíz entra en la grupa: los demás tramos van 2 celdas o más
      detrás de ella (el meneo gira alrededor de y y no los acerca);
    - dos tramos que se tocan nunca tienen el mismo grueso en x (4, 6, 8, 6, 8): sus costados
      nunca quedan en el mismo plano. La raíz es fina y la cola engorda hacia la punta.
El pivote de cada tramo es el centro del borde donde nace, en x = 0. Cada tramo lleva una veta
clara de una celda a lo largo, en la misma línea que la del anterior (se lee de perfil como una
franja de luz). La punta es de espuma y rompe como ola hacia atrás: una cresta que sube y un labio
que se enrula hacia arriba y atrás. Sin cristalitos de hielo (son desde el adulto).
"""

# Direcciones de la cuadrícula (paso en y, paso en z), con y hacia atrás.
# (Ojo: V es el Vector de mathutils en el armador; no se pisa.)
VERT, P12, P11, P21, HORIZ = (0, 1), (1, 2), (1, 1), (2, 1), (1, 0)
RAIZ_COLA = (6, 11)  # centro del borde donde nace el primer tramo (y, z), dentro de la grupa
# [(dirección, borde, ancho, largo, grueso en x)]: la raíz sale recta hacia atrás de la grupa y la
# cola se curva hacia atrás y arriba (1:1 -> 1:2 -> vertical), lejos de la grupa: al enroscarse
# hacia adelante (sentado, dormido) la punta queda detrás del cuerpo y no entra en él.
TRAMOS_COLA = [(HORIZ, "v", 4, 7, 4), (P11, "h", 4, 6, 6), (P12, "h", 6, 3, 8), (VERT, "h", 6, 7, 6),
               (VERT, "h", 8, 3, 8)]
METIDA = 2  # celdas que el tramo siguiente nace por debajo de la punta del anterior
COLOR_TRAMO = ("raiz", "cuerpo", "cuerpo", "claro", "espuma")
COLOR_VETA = ("cuerpo", "claro", "claro", "verde", "sombra")


def tramos(raiz=RAIZ_COLA, lista=TRAMOS_COLA):
    """Los tramos de la cola: [(polígono y-z, (x0, x1), pivote, punta, dirección, borde)].
    El polígono empieza por el borde donde nace: a, b, b + n·d, a + n·d."""
    c, salida = raiz, []
    for d, borde, w, n, grueso in lista:
        e = (1, 0) if borde == "h" else (0, 1)  # a lo largo del borde de nacimiento
        a = (c[0] - w // 2 * e[0], c[1] - w // 2 * e[1])
        b = (c[0] + w // 2 * e[0], c[1] + w // 2 * e[1])
        pol = [a, b, (b[0] + n * d[0], b[1] + n * d[1]), (a[0] + n * d[0], a[1] + n * d[1])]
        fin = (c[0] + n * d[0], c[1] + n * d[1])  # centro de la punta del tramo
        x = (-grueso // 2, grueso // 2)
        salida.append((pol, x, (0, c[0], c[1]), (0, fin[0], fin[1]), d, borde))
        pasos = METIDA // max(d)  # un paso 1:2 o 2:1 ya mete 2 celdas; uno 1:1 o recto, 1
        c = (fin[0] - pasos * d[0], fin[1] - pasos * d[1])  # el siguiente nace adentro
    return salida


def franjas(pol, w):
    """El tramo partido a lo largo en tres: hasta la veta, la veta (1 celda, adelante del centro)
    y el resto. Devuelve [(polígono, es_veta)]."""
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


def ola(nombre, pol, x):
    """Cresta de espuma sobre la punta (borde de arriba horizontal, de yl a yr): sube dos celdas
    inclinada 1:2 hacia atrás y encima el labio, de dos celdas, que se enrula hacia arriba y
    atrás y vuela por detrás del tramo."""
    (yl, zt), (yr, _) = sorted(pol[2:], key=lambda p: p[0])
    cresta = [(yl, zt), (yr, zt), (yr + 1, zt + 2), (yl + 1, zt + 2)]
    labio = [(yl + 1, zt + 2), (yr + 1, zt + 2), (yr + 3, zt + 3), (yr + 2, zt + 4), (yl + 3, zt + 4)]
    prisma(nombre, "Cola", "espuma", cresta, x, "x")
    prisma(nombre, "Cola", "espuma", labio, x, "x")


def colas():
    t = tramos()
    for k, (pol, x, _, _, _, _) in enumerate(t):
        for parte, veta in franjas(pol, TRAMOS_COLA[k][2]):
            color = COLOR_VETA[k] if veta else COLOR_TRAMO[k]
            prisma(f"Cola1_{k + 1}", "Cola", color, parte, x, "x")
    ola("Cola1_5", t[-1][0], t[-1][1])


def articulaciones_cola():
    """[(hueso, padre, pivote)] y {hueso: punta} de la cola, en celdas."""
    arts, puntas = [], {}
    for k, (_, _, piv, punta, _, _) in enumerate(tramos()):
        hueso = f"Cola1_{k + 1}"
        arts.append((hueso, "Cadera" if k == 0 else f"Cola1_{k}", piv))
        puntas[hueso] = punta
    return arts, puntas
