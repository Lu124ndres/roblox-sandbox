r"""
Formas del dragón v2 que no salen de un bloque con recorte: prismas de cualquier polígono convexo
sobre la cuadrícula (cuernos, púas, dedos y membrana del ala, la pala de la cola). La cargan los
dragon_v2_e<n>_geometria.py; usa PARTES, CELDA y V de minotauro_v2_bloques.py.

    prisma(parte, coleccion, color, poligono, rango, eje="z")
        Un polígono convexo en el plano perpendicular a `eje` (eje z: puntos (x, y); eje x: (y, z);
        eje y: (x, z)), extruido en `rango` = (desde, hasta) a lo largo de `eje`. Cada lado del
        polígono va en una dirección de la regla (recto, 1:1, 1:2 o 2:1) y los vértices caen en la
        cuadrícula, así que sus caras cumplen lo mismo que las cuñas de bloque().
    par_prisma(...)     el mismo prisma a la izquierda (x+) y espejado; `parte` lleva {lado}.
    lamina(...), par_lamina(...)
        Un contorno cualquiera (cóncavo, como la membrana con el festón) en el plano xy: lo parte en
        polígonos convexos (trocear) y pone un prisma por cada uno.
    espinas(parte, coleccion, color, lista)
        Púas en sierra sobre el lomo, de x -1 a 1: (y del pie de adelante, z de la base, alto). El
        frente sube 1:1 y la espalda es recta. Van apoyadas encima (no metidas): en la cola, que
        mide 2 de ancho como la púa, una base metida dejaría sus costados en el mismo plano.
"""
from fractions import Fraction

# Direcciones de corte al trocear, en orden de preferencia: rectas (la costura queda a lo largo
# del ala o del cuerpo), después en diagonal.
DIRECCIONES = [(0, -1), (0, 1), (1, 0), (-1, 0), (1, 1), (-1, -1), (1, -1), (-1, 1), (1, 2), (-1, -2),
               (1, -2), (-1, 2), (2, 1), (-2, -1), (2, -1), (-2, 1)]


def _cruz(a, b):
    return a[0] * b[1] - a[1] * b[0]


def _menos(p, q):
    return (p[0] - q[0], p[1] - q[1])


def _lado_valido(a, b):
    dx, dy = abs(b[0] - a[0]), abs(b[1] - a[1])
    return dx == 0 or dy == 0 or dx == dy or dx == 2 * dy or dy == 2 * dx


def _limpiar(pol):
    """Sin puntos repetidos ni intermedios en línea recta; antihorario."""
    pol = [p for i, p in enumerate(pol) if p != pol[i - 1]]
    cambio = True
    while cambio and len(pol) > 3:
        cambio = False
        for i in range(len(pol)):
            a, v, b = pol[i - 1], pol[i], pol[(i + 1) % len(pol)]
            if _cruz(_menos(v, a), _menos(b, v)) == 0:
                del pol[i]
                cambio = True
                break
    if sum(_cruz(p, q) for p, q in zip(pol, pol[1:] + pol[:1])) < 0:
        pol.reverse()
    return pol


def _rayo(pol, i, d):
    """Primer punto del borde que toca el rayo desde pol[i] en la dirección d: (t, punto, lado)."""
    v, mejor, n = pol[i], None, len(pol)
    for j in range(n):
        if j in (i, (i - 1) % n):
            continue
        p, q = pol[j], pol[(j + 1) % n]
        e = _menos(q, p)
        den = _cruz(d, e)
        if den == 0:
            continue
        t, s = _cruz(_menos(p, v), e) / den, _cruz(_menos(p, v), d) / den
        if t > 0 and 0 <= s <= 1 and (mejor is None or t < mejor[0]):
            mejor = (t, (v[0] + t * d[0], v[1] + t * d[1]), j)
    return mejor


def trocear(pol):
    """Parte un polígono simple en convexos: desde cada vértice hundido traza un corte (en una
    dirección de la regla que caiga en la cuadrícula) hasta el borde de enfrente."""
    pol = _limpiar([(Fraction(x), Fraction(y)) for x, y in pol])
    n = len(pol)
    for i in range(n):
        a, v, b = pol[i - 1], pol[i], pol[(i + 1) % n]
        if _cruz(_menos(v, a), _menos(b, v)) >= 0:
            continue
        for d in DIRECCIONES:
            if not (_cruz(_menos(b, v), d) > 0 and _cruz(d, _menos(a, v)) > 0):
                continue
            hit = _rayo(pol, i, d)
            if not hit or any(c.denominator != 1 for c in hit[1]):
                continue
            h, j = hit[1], hit[2]
            uno = [pol[(i + k) % n] for k in range((j - i) % n + 1)] + [h]
            otro = [h] + [pol[(j + 1 + k) % n] for k in range((i - j - 1) % n + 1)]
            return trocear(uno) + trocear(otro)
        raise ValueError(f"no hay corte en la cuadrícula desde el vértice {tuple(map(float, v))}")
    return [[(int(x), int(y)) for x, y in pol]]


def prisma(parte, coleccion, color, poligono, rango, eje="z"):
    pol = _limpiar([(Fraction(x), Fraction(y)) for x, y in poligono])
    for k, p in enumerate(pol):
        q, r = pol[(k + 1) % len(pol)], pol[(k + 2) % len(pol)]
        assert _lado_valido(p, q), f"{parte}: lado {p}-{q} fuera de la regla"
        assert _cruz(_menos(q, p), _menos(r, q)) > 0, f"{parte}: polígono no convexo"
    a, b = [e for e in "xyz" if e != eje]
    puntos = []
    for u, w in pol:
        for z in rango:
            c = {eje: z, a: float(u), b: float(w)}
            puntos.append(V((c["x"], c["y"], c["z"])) * CELDA)
    PARTES.setdefault(parte, {"coleccion": coleccion, "bloques": []})["bloques"].append((puntos, color))


def par_prisma(parte, coleccion, color, poligono, rango, eje="z"):
    for s, lado in ((1, "Izq"), (-1, "Der")):
        if s > 0:
            pol, r = poligono, rango
        elif eje == "x":
            pol, r = poligono, (-rango[1], -rango[0])
        else:  # la primera coordenada del polígono es x
            pol, r = [(-u, w) for u, w in poligono], rango
        prisma(parte.format(lado=lado), coleccion, color, pol, r, eje)


def lamina(parte, coleccion, color, contorno, rango):
    for pieza in trocear(contorno):
        prisma(parte, coleccion, color, pieza, rango)


def par_lamina(parte, coleccion, color, contorno, rango):
    for pieza in trocear(contorno):
        par_prisma(parte, coleccion, color, pieza, rango)


def espinas(parte, coleccion, color, lista):
    for y0, z0, alto in lista:
        pol = [(y0, z0), (y0 + alto, z0), (y0 + alto, z0 + alto)]
        prisma(parte, coleccion, color, pol, (-1, 1), eje="x")
