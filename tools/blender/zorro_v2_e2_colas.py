r"""
Colas del Zorro de agua v2, etapa 2 (joven): tres colas de cinco tramos. Salen de las de la E3
(zorro_v2_e3_colas.py, la maestra) con las reglas de juntas de la E1 (colas gruesas). Cada cola es
una cadena de tramos en el plano x-z (u = x hacia afuera, z arriba), extruidos en y:
    - cada tramo nace DOS CELDAS por debajo de la punta del anterior (dos pasos en vertical, 1:1 u
      horizontal; uno en 1:2 o 2:1) y a dos o más celdas de su base, centrado en esa línea: al
      doblarse 45° la junta queda tapada;
    - dos tramos seguidos en la misma dirección nunca miden lo mismo de ancho (4, 6, ...) y ninguno
      con hijo pasa de 8 de ancho ni de grueso (hondo 4);
    - cada tramo va 3 celdas más atrás en y que el anterior y comparte una con él: el tramo k y el
      k + 2 nunca comparten franja de y, así una cola no se dobla sobre sí misma;
    - mismos colores de la raíz a la espuma, una veta clara de una celda a lo largo de cada tramo
      y la punta que rompe como ola, con la cresta enrulada hacia arriba. Sin hielo (es del adulto).
Las tres colas:
    - Cola1, la central: la A de la E3 centrada (x simétrica). Sube vertical desde arriba del borde
      de atrás de la grupa (z 12, y 5..9, detrás de los muslos; el segundo tramo nace dos celdas
      arriba de la grupa y no se mete en ella al girar) y, con el paso en y, se inclina hacia atrás.
      La veta va al medio (x -1..1); la punta es clara y la ola, de tres celdas, rompe hacia atrás
      (en el plano y-z): la espuma (z 25..28, y 17..24) queda dos celdas arriba de la cabeza y es lo
      más alto del zorro.
    - Cola2 y Cola3, el par: la C de la E3 (1:1 -> 2:1 -> horizontal -> 2:1 y la punta sube 1:2),
      que se abre en arco a cada lado desde la grupa, más abajo y una celda más atrás que la
      central (z 10, y 6..10). Sus tramos quedan por debajo de la cuerda raíz-punta: al plegarse
      (Colas dobla cada cola alrededor del eje perpendicular a esa cuerda) se quedan afuera en vez
      de juntarse en el medio. Entre el par y la central hay 1.1 rad de abanico y tres celdas o más
      en x. Cola3 es el espejo.
El pivote de cada tramo es el centro del borde donde nace y, en y, el medio de la celda que comparte
con el tramo anterior.
"""

# Direcciones de la cuadrícula (paso en u, paso en z), con u hacia afuera.
# (Ojo: V es el Vector de mathutils en el armador; no se pisa.)
VERT, P12, P11, P21, HORIZ = (0, 1), (1, 2), (1, 1), (2, 1), (1, 0)
# (nombre, espejo o None, centro de la raíz (x, z), y del primer tramo, paso en y, hondo, tramos
#  [(dirección, borde, ancho, largo)])
COLAS_E2 = [
    ("Cola1", None, (0, 12), 5, 3, 4,  # la central: sube vertical, 4 y 6 de ancho
     [(VERT, "h", 4, 5), (VERT, "h", 6, 4), (VERT, "h", 4, 4), (VERT, "h", 6, 4), (VERT, "h", 4, 4)]),
    ("Cola2", "Cola3", (5, 10), 6, 3, 4,  # el par: 1:1 -> 2:1 -> horizontal -> 2:1, punta 1:2
     [(P11, "h", 4, 4), (P21, "v", 6, 2), (HORIZ, "v", 4, 4), (P21, "v", 6, 2), (P12, "h", 4, 3)]),
]
COLOR_TRAMO = ("raiz", "cuerpo", "cuerpo", "claro", "espuma")
COLOR_VETA = ("cuerpo", "claro", "claro", "verde", "sombra")


def cadena(raiz, lista):
    """Los tramos de una cola en su plano (u, z): [(polígono, centro del borde donde nace,
    centro de la punta, dirección, ancho)]. El polígono empieza por el borde: a, b, b + n·d, a + n·d.
    El siguiente nace dos celdas adentro de la punta (dos pasos si el paso mide 1, uno si mide 2)."""
    c, salida = raiz, []
    for k, (d, borde, w, n) in enumerate(lista):
        e = (1, 0) if borde == "h" else (0, 1)  # a lo largo del borde de nacimiento
        a = (c[0] - w // 2 * e[0], c[1] - w // 2 * e[1])
        b = (c[0] + w // 2 * e[0], c[1] + w // 2 * e[1])
        pol = [a, b, (b[0] + n * d[0], b[1] + n * d[1]), (a[0] + n * d[0], a[1] + n * d[1])]
        fin = (c[0] + n * d[0], c[1] + n * d[1])  # centro de la punta del tramo
        salida.append((pol, c, fin, d, w))
        pasos = 2 if max(d) == 1 else 1
        if k < len(lista) - 1:
            assert (n - pasos) * max(d) >= 2 and w <= 8, f"tramo {k + 1}: junta fuera de la regla"
        c = (fin[0] - pasos * d[0], fin[1] - pasos * d[1])
    return salida


def colas_locales():
    """[(nombre, eje de extrusión, lado, tramos)], con tramos [(polígono u-z, rango en y,
    pivote (u, y, z), punta (u, y, z), dirección, ancho)]. lado 0: la central (simétrica)."""
    salida = []
    for izq, der, raiz, y_raiz, paso, hondo, lista in COLAS_E2:
        t = []
        for k, (pol, c, f, d, w) in enumerate(cadena(raiz, lista)):
            y0 = y_raiz + paso * k
            t.append((pol, (y0, y0 + hondo), (c[0], y0 + 0.5, c[1]), (f[0], y0 + 0.5, f[1]), d, w))
        salida += [(izq, "y", 1 if der else 0, t)] + ([(der, "y", -1, t)] if der else [])
    return salida


def a_mundo(eje, lado, p):
    """Punto de la cola (u, y, z) -> (x, y, z) del zorro."""
    u, r, z = p
    return ((lado or 1) * u, r, z)


def franjas(pol, rango, w, centro):
    """El tramo partido a lo largo en tres: [(polígono, rango, es_veta)]. La veta, de una celda, va
    a la izquierda del centro (como en la E3); en la central, al medio y de dos (x -1..1)."""
    a, b, c, d = pol
    paso = ((b[0] - a[0]) // w, (b[1] - a[1]) // w)
    o, o1 = (w // 2 - 1, w // 2 + 1) if centro else (w // 2 - 1, w // 2)
    corte = lambda t: ((a[0] + t * paso[0], a[1] + t * paso[1]), (d[0] + t * paso[0], d[1] + t * paso[1]))
    piezas = []
    for t0, t1, veta in ((0, o, False), (o, o1, True), (o1, w, False)):
        if t1 > t0:
            (p0, q0), (p1, q1) = corte(t0), corte(t1)
            piezas.append(([p0, p1, q1, q0], rango, veta))
    return piezas


def _ola(nombre, ul, ur, zt, rango, eje, pieza=lambda pol: pol, alta=2):
    """Cresta de espuma sobre la punta (de ul a ur, arriba en zt): sube `alta` celdas inclinada
    1:2 (o una, 1:1) hacia afuera (+u) y encima el labio, de dos celdas, que se enrula hacia
    arriba y afuera."""
    h = alta
    cresta = [(ul, zt), (ur, zt), (ur + 1, zt + h), (ul + 1, zt + h)]
    labio = [(ul + 1, zt + h), (ur + 1, zt + h), (ur + 3, zt + h + 1), (ur + 2, zt + h + 2), (ul + 3, zt + h + 2)]
    prisma(nombre, "Cola", "espuma", pieza(cresta), rango, eje)
    prisma(nombre, "Cola", "espuma", pieza(labio), rango, eje)


def colas():
    for nombre, eje, lado, t in colas_locales():
        pieza = lambda pol, s=lado: pol if s >= 0 else [(-u, z) for u, z in pol]
        for k, (pol, rango, _, _, _, w) in enumerate(t):
            for parte, r, veta in franjas(pol, rango, w, lado == 0):
                color = COLOR_VETA[k] if veta else COLOR_TRAMO[k]
                if lado == 0 and k == 4:  # la punta de la central, clara: la espuma empieza arriba
                    color = "verde" if veta else "claro"  # de la cabeza y no se lee como un gorro
                prisma(f"{nombre}_{k + 1}", "Cola", color, pieza(parte), r, "y")
        pol, (y0, y1) = t[-1][0], t[-1][1]
        (ul, zt), (ur, _) = sorted(pol[2:], key=lambda p: p[0])
        if lado == 0:  # la central rompe hacia atrás: la ola en el plano y-z, del grueso de la punta
            _ola(f"{nombre}_5", y0, y1, zt, (ul, ur), "x", alta=1)
        else:
            _ola(f"{nombre}_5", ul, ur, zt, (y0, y1), "y", pieza)


def articulaciones_colas():
    """[(hueso, padre, pivote)] y {hueso: punta} de las tres colas, en celdas del zorro."""
    arts, puntas = [], {}
    for nombre, eje, lado, t in colas_locales():
        for k, (_, _, piv, punta, _, _) in enumerate(t):
            hueso = f"{nombre}_{k + 1}"
            arts.append((hueso, "Cadera" if k == 0 else f"{nombre}_{k}", a_mundo(eje, lado, piv)))
            puntas[hueso] = a_mundo(eje, lado, punta)
    return arts, puntas
