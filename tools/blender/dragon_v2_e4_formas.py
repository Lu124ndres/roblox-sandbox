r"""
Formas propias del anciano del dragón marino v2 (la carga dragon_v2_e4_geometria.py; usa bloque(),
par(), prisma() y par_prisma() de minotauro_v2_bloques.py y dragon_v2_formas.py).

    acorazado(parte, coleccion, caja, venas, caras, abiertas, lado, franjas)
        Un bloque acorazado: un núcleo de lava envuelto en placas de una celda de grueso. Las VETAS
        son rebanadas de una celda que se quitan de la cáscara: el núcleo asoma por ellas, metido una
        celda, en líneas continuas que siguen las juntas entre placas (como el pecho del Minotauro E4,
        pero en todo el cuerpo). venas = [(eje, a, caras, tramo)]: la rebanada eje = a, solo en las
        caras de la lista (None: en todas, un anillo) y, si hay tramo (eje2, desde, hasta), solo en
        ese tramo: así las juntas se cruzan en T como placas de verdad y no en rayas. Las caras en
        `abiertas` no llevan placa (quedan dentro de otra pieza). Las celdas de placa se juntan en
        bloques grandes; si la caja está centrada en x se juntan en la mitad izquierda y se espejan.
    espina_brasa(parte, y0, z0, base, alto, caida, brasa, x)
        Púa del lomo inclinada hacia atrás (perfil en yz): pie de y0 a y0+base en z0 y la punta
        `caida` celdas detrás del pie de atrás, `alto` arriba. La punta (las últimas `brasa` celdas
        de alto) es de color brasa.
    lamina_celdas(parte, coleccion, celdas, rango, colores)
        Una lámina hecha de celdas sueltas {(x, y): color} (el ala izquierda; se espeja): junta las
        del mismo color en rectángulos y pone un bloque por cada uno. El borde en escalones de la
        membrana sale de ahí.
    rasterizar(poligono)
        Celdas (x, y) cuyo centro cae dentro del polígono (cualquiera, cóncavo): los bordes en
        diagonal quedan en escalones de una celda, como una membrana desgarrada.
"""
ORDEN_CARAS = ("z+", "z-", "x+", "x-", "y+", "y-")
COLOR_CARA = {"z+": "cuerpo_osc", "z-": "vientre", "x+": "cuerpo", "x-": "cuerpo",
              "y+": "cuerpo", "y-": "cuerpo"}


def _fusionar(celdas, simetrico):
    """Celdas {(i, j, k): color} -> bloques [(color, x, y, z)]: crece en y, después en x y en z."""
    trabajo = {c: v for c, v in celdas.items() if not simetrico or c[0] >= 0}
    hechas, cajas = set(), []
    libre = lambda p, col: p in trabajo and p not in hechas and trabajo[p] == col
    for c in sorted(trabajo, key=lambda c: (c[2], c[0], c[1])):
        if c in hechas:
            continue
        col = trabajo[c]
        i, j, k = c
        j1 = j
        while libre((i, j1 + 1, k), col):
            j1 += 1
        i1 = i
        while all(libre((i1 + 1, jj, k), col) for jj in range(j, j1 + 1)):
            i1 += 1
        k1 = k
        while all(libre((ii, jj, k1 + 1), col) for ii in range(i, i1 + 1) for jj in range(j, j1 + 1)):
            k1 += 1
        hechas |= {(ii, jj, kk) for ii in range(i, i1 + 1) for jj in range(j, j1 + 1)
                   for kk in range(k, k1 + 1)}
        y, z = (j, j1 + 1), (k, k1 + 1)
        if not simetrico:
            cajas.append((col, (i, i1 + 1), y, z))
        elif i == 0:
            cajas.append((col, (-(i1 + 1), i1 + 1), y, z))
        else:
            cajas += [(col, (i, i1 + 1), y, z), (col, (-(i1 + 1), -i), y, z)]
    return cajas


def _en_veta(c, en, veta):
    e, a, cs = veta[:3]
    tramo = veta[3] if len(veta) > 3 else None
    if c[e] != a or (cs is not None and not set(en) & set(cs)):
        return False
    return tramo is None or tramo[1] <= c[tramo[0]] < tramo[2]


def acorazado(parte, coleccion, caja, venas=(), caras=None, abiertas=(), lado=False, nucleo="lava",
              franjas=()):
    """franjas = [(eje, a, caras, color)]: la fila eje = a de esas caras, de otro color (turquesa)."""
    (x0, x1), (y0, y1), (z0, z1) = caja
    color = COLOR_CARA | (caras or {})
    lim = {"x-": x0, "x+": x1 - 1, "y-": y0, "y+": y1 - 1, "z-": z0, "z+": z1 - 1}
    celdas = {}
    for i in range(x0, x1):
        for j in range(y0, y1):
            for k in range(z0, z1):
                c = {"x": i, "y": j, "z": k}
                en = [f for f in ORDEN_CARAS if f not in abiertas and c[f[0]] == lim[f]]
                if not en:
                    continue  # núcleo
                if any(_en_veta(c, en, v) for v in venas):
                    continue  # veta: asoma el núcleo
                celdas[(i, j, k)] = color[en[0]]
                for e, a, cs, col in franjas:
                    if c[e] == a and en[0] in cs:
                        celdas[(i, j, k)] = col
    hundir = lambda f, v, d: v if f in abiertas else v + d
    nuc = ((hundir("x-", x0, 1), hundir("x+", x1, -1)), (hundir("y-", y0, 1), hundir("y+", y1, -1)),
           (hundir("z-", z0, 1), hundir("z+", z1, -1)))
    poner = par if lado else bloque
    poner(parte, coleccion, nucleo, *nuc)
    for col, x, y, z in _fusionar(celdas, simetrico=not lado and x0 == -x1):
        poner(parte, coleccion, col, x, y, z)


def espina_brasa(parte, y0, z0, base, alto, caida, brasa, x=(-1, 1)):
    f = (alto - brasa) / alto
    yf, yb, zt = y0 + (base + caida) * f, y0 + base + caida * f, z0 + alto - brasa
    assert yf == int(yf) and yb == int(yb), f"{parte}: la brasa no cae en la cuadrícula"
    prisma(parte, "Puas", "pua", [(y0, z0), (y0 + base, z0), (yb, zt), (yf, zt)], x, eje="x")
    prisma(parte, "Puas", "pua_brasa", [(yf, zt), (yb, zt), (y0 + base + caida, z0 + alto)], x, eje="x")


def rasterizar(poligono):
    """Celdas (x, y) con el centro dentro del polígono (regla par-impar)."""
    xs, ys = [p[0] for p in poligono], [p[1] for p in poligono]
    dentro = set()
    for i in range(int(min(xs)), int(max(xs))):
        for j in range(int(min(ys)), int(max(ys))):
            px, py, n = i + 0.5, j + 0.5, False
            for (ax, ay), (bx, by) in zip(poligono, poligono[1:] + poligono[:1]):
                if (ay > py) != (by > py) and px < ax + (py - ay) * (bx - ax) / (by - ay):
                    n = not n
            if n:
                dentro.add((i, j))
    return dentro


def _rectangulos(celdas):
    """Celdas {(x, y): color} -> [(color, (x0, x1), (y0, y1))]: cada vez el rectángulo más grande
    de un solo color (menos bloques y menos costuras que juntar en tiras)."""
    libres, rects = dict(celdas), []
    while libres:
        mejor = None
        for (i, j), col in libres.items():
            for orden in ("xy", "yx"):  # crece primero en un eje y después en el otro
                i1, j1 = i, j
                for eje in orden:
                    while True:
                        if eje == "x":
                            nuevo = [(i1 + 1, jj) for jj in range(j, j1 + 1)]
                        else:
                            nuevo = [(ii, j1 + 1) for ii in range(i, i1 + 1)]
                        if not all(libres.get(c) == col for c in nuevo):
                            break
                        i1, j1 = (i1 + 1, j1) if eje == "x" else (i1, j1 + 1)
                area = (i1 - i + 1) * (j1 - j + 1)
                if not mejor or area > mejor[0]:
                    mejor = (area, col, (i, i1 + 1), (j, j1 + 1))
        _, col, x, y = mejor
        for ii in range(*x):
            for jj in range(*y):
                del libres[(ii, jj)]
        rects.append((col, x, y))
    return rects


def lamina_celdas(parte, coleccion, celdas, rango):
    """celdas {(x, y): color} del lado izquierdo; `parte` lleva {lado}."""
    for col, x, y in _rectangulos(celdas):
        par(parte, coleccion, col, x, y, rango)
