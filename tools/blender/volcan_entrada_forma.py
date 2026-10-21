r"""
Forma de la versión 6 del volcán (volcan_entrada.py): la v5 con la entrada asimétrica y un
túnel menos uniforme. Lo carga volcan_entrada.py con exec después de volcan_pie_forma.py.

La entrada (lado + = x positivo de Roblox, a la derecha mirando el arco desde el puente):
    peñasco    del lado +, tres picos dentados (PICOS) que se apoyan en la roca de encima del
               arco, que sube en diagonal de izquierda a derecha
    escalones  del lado -, terrazas más bajas que bajan hacia afuera, con rocas caídas al pie
               (sobre el borde de afuera del rellano, lejos del puente)
    espolón    corrido hacia + (ESPOLON_CENTRO) y con otra pendiente a cada lado
    vetas      del lado +, una veta larga que baja en diagonal por el peñasco; del lado -, dos
               bolsones cortos en las terrazas; el borde del rellano brilla solo en tramos
El arco y su vano, el rellano a 30 donde llega el puente y el túnel no se mueven.

El túnel: cada pared con su propio ancho (base TUNEL_BASE, salientes de distinto largo y
hondura que nunca bajan de TUNEL_MEDIO: el paso útil sigue en 46), un ensanche, el techo nunca
por debajo de TUNEL_ALTO en el centro y ríos de lava a intervalos distintos en cada pared.
"""

PICOS = ((52, 168, 30), (72, 146, 26), (92, 124, 22))  # peñasco: (lado, alto, radio)
ESPOLON_CENTRO = 16  # el espolón se corre hacia +
TUNEL_BASE = 27  # medio ancho de cada pared antes de las salientes
ENSANCHE = (R_A - 120, R_A - 92, 9)  # desde, hasta y cuánto más ancho (una pequeña sala)
_azar = random.Random(29)


def lado_puerta(dx, dz):
    """(avance hacia la isla, lado con signo: + a la derecha mirando el arco desde el puente)."""
    g = math.radians(PUERTA_DEG)
    return dx * math.cos(g) + dz * math.sin(g), -dx * math.sin(g) + dz * math.cos(g)


def _tramos(semilla):
    """Salientes de una pared: [(desde, hasta, hondura)] a lo largo del túnel."""
    r = random.Random(semilla)
    tramos, d = [], WALK_END
    while d < R_A:
        largo = r.choice((8, 12, 16, 20, 28))
        tramos.append((d, d + largo, r.choice((0, 0, 1, 2, 3, 4))))
        d += largo
    return tramos


def _venas(semilla):
    r = random.Random(semilla)
    venas, d = set(), WALK_END + r.randint(10, 30)
    while d < R_A - 12:
        venas.add(int(d // CELDA))
        d += r.choice((28, 36, 44, 60, 76))
    return venas


SALIENTES = {1: _tramos(7), -1: _tramos(13)}
VENAS = {1: _venas(3), -1: _venas(11)}


def pared(avance, signo):
    """Medio ancho del túnel de ese lado en ese punto."""
    ancho = TUNEL_BASE
    for desde, hasta, hondo in SALIENTES[signo]:
        if desde <= avance < hasta:
            ancho -= hondo
            break
    desde, hasta, extra = ENSANCHE
    if desde <= avance < hasta:
        ancho += extra * math.sin(math.pi * (avance - desde) / (hasta - desde))
    return max(ancho, TUNEL_MEDIO)


def techo_tunel(avance):
    alto = TUNEL_ALTO + 2 + 2 * round(2 * math.sin(avance * 0.11) + 1.5 * math.sin(avance * 0.29 + 2))
    desde, hasta, _ = ENSANCHE
    if desde <= avance < hasta:
        alto += 12
    return max(alto, TUNEL_ALTO)  # nunca más bajo que el techo de la v5 (86 a 94)


def cueva(dx, dz):
    rho, a = math.hypot(dx, dz), math.atan2(dz, dx)
    if rho < WALK_END:
        piso = height(rho, a)
        return piso, material(rho, a, piso), None
    avance, lado = lado_puerta(dx, dz)
    if abs(lado) <= ARCO_MEDIO and R_A - ARCO_HONDO <= avance <= R_A + ARCO_HONDO:
        return PASEO, "basalto", ARCO_ALTO
    if WALK_END - 6 <= avance < R_A - ARCO_HONDO and abs(lado) <= pared(avance, 1 if lado >= 0 else -1):
        return PASEO, "basalto", techo_tunel(avance)
    return None


def vena_pared(i, j):
    dx, dz = (i + 0.5) * CELDA, (j + 0.5) * CELDA
    if math.hypot(dx, dz) < WALK_END + 8:
        return math.sin(math.atan2(dz, dx) * 23 + 1.7) > 0.93
    avance, lado = lado_puerta(dx, dz)
    return int(avance // CELDA) in VENAS[1 if lado >= 0 else -1]


def zona_entrada(avance, lateral):
    return lateral <= 130 and R_A - ESPOLON_LARGO <= avance <= R_A + ARCO_HONDO + RELLANO + 14


def bloque_columna(dx, dz):
    avance, lateral = eje_puerta(dx, dz)
    if lateral <= 180 and avance >= R_A - ESPOLON_LARGO - 20:
        return 1
    return bloque_exterior(math.hypot(dx, dz))


def _hash(a, b, n):
    return (int(a) * 7919 + int(b) * 104729) % n


def exterior(dx, dz):
    rho, a = math.hypot(dx, dz), math.atan2(dz, dx)
    avance, lado = lado_puerta(dx, dz)
    lateral = abs(lado)
    natural = ladera(rho, a)
    h, H, canal, largo, u = natural if natural else (MAR, ALTO_CIMA, 0.0, 0.0, 1.0)
    isla = math.hypot(dx - ISLA[0], dz - ISLA[1])
    h = min(h, MAR + 16 + (isla - ISLA_AGUA) * 1.0)
    mat = None
    frente = R_A + ARCO_HONDO
    if zona_entrada(avance, lateral):
        # Espolón corrido hacia +, más ancho y tendido de ese lado, corto y empinado del otro.
        corrido = lado - ESPOLON_CENTRO
        ancho = 84 if corrido >= 0 else 46
        nariz = frente - (max(0.0, abs(corrido) - ARCO_MEDIO) / ancho) ** 2 * 50
        if avance <= nariz:
            caida = 0.55 if corrido >= 0 else 1.5
            alto = ARCO_ALTO + 26 + (R_A - avance) * (0.24 if corrido >= 0 else 0.42)
            alto -= max(0.0, abs(corrido) - 28) * caida
            alto += 6 * math.sin(avance * 0.13 + lado * 0.2) + 5 * math.sin(lado * 0.31 + 0.8)
            w = 1 - smooth((abs(corrido) - ancho) / 30)
            w *= 1 - smooth((R_A - ESPOLON_LARGO + 40 - avance) / 40)
            h = max(h, alto * w + h * (1 - w))
        # Sobre el vano la roca sube en diagonal hacia el peñasco (nunca menos de 24 encima).
        if lateral <= ARCO_MEDIO + 4 and R_A - ARCO_HONDO - 8 <= avance <= frente:
            sube = (lado + ARCO_MEDIO) * 0.45 + 10 * _hash(lado // 8, avance // 6, 3)
            sube -= 8 * _hash(lado // 4 + 3, avance // 4, 2)
            delante = max(0.0, avance - (R_A - 2)) * 1.8  # el frente, más bajo y escalonado
            h = max(h, ARCO_ALTO + 24 + max(0.0, sube - delante))
        # Peñasco del lado +: picos dentados de alturas distintas que se inclinan hacia el
        # puente (más bajos cuanto más adelante) y se apoyan en la roca de encima del arco.
        if 34 <= lado <= 104 and R_A - 44 <= avance <= frente + 10:
            alto = 0.0
            for centro, cima, radio in PICOS:
                d = math.hypot(lado - centro, (avance - (R_A - 10)) * 0.8)
                alto = max(alto, cima * (1 - (d / radio) ** 2))
            alto = max(alto, 96 - (lado - 34) * 0.5)  # la base del peñasco
            alto -= max(0.0, avance - R_A) * 1.6
            alto += 8 * _hash(lado // 8, avance // 8, 3) - 6 * _hash(lado // 4, avance // 4, 2)
            h = max(h, alto)
            # Veta larga: baja en diagonal por la cara del peñasco hacia el rellano.
            if abs(lado - (52 + (avance - (R_A - 40)) * 0.7)) < 4:
                mat = "lava"
        # Escalones del lado -: terrazas que bajan hacia afuera.
        if -110 <= lado <= -34 and R_A - 50 <= avance <= frente + 6:
            escalon = int((-lado - 34) // 14)
            alto = ARCO_ALTO + 8 - escalon * 16 - max(0.0, avance - R_A) * 1.2
            h = max(h, alto)
            if escalon in (1, 3) and _hash(lado // 6, avance // 6, 9) == 0:
                mat = "lava"  # bolsones de lava en las terrazas
        # Rellano a 30 (más angosto del lado del peñasco).
        borde = RELLANO_MEDIO - 8 if lado >= 0 else RELLANO_MEDIO + 6
        if lateral <= borde and frente < avance <= frente + RELLANO:
            h = PASEO
            mat = "basalto"
            if lateral >= borde - 5 and (lado < 0 or avance < frente + 8):
                mat = "lava"  # el borde brilla entero del lado -, solo al principio del +
            if lateral <= L["bridgeWidth"] / 2 + 2:
                tablero = L["craterDeckHeight"] - (L["craterDeckHeight"] - L["deckHeight"]) * (avance - R_A) / PUENTE_LARGO
                h = ESCALON * math.floor((tablero - 1) / ESCALON)
            elif lado < 0 and lateral >= borde - 14 and _hash(lado // 8, avance // 8, 3) == 0:
                h = PASEO + 4 + 4 * _hash(lado // 8, avance // 8 + 1, 2)  # rocas caídas
                mat = "cumbre"
        # Rocas caídas al pie de los escalones, sobre el agua (bloques de 8, bajos).
        if -100 <= lado <= -40 and frente < avance <= frente + RELLANO + 14 and lateral > borde:
            if _hash(lado // 8, avance // 8, 4) == 0:
                h = max(h, PASEO - 10 + 6 * _hash(lado // 8, avance // 8 + 3, 3))
                mat = mat or "cumbre"
    if rho < WALK_END + 36:
        h = max(h, TECHO_BORDE + 34)
    if h <= MAR + 0.5:
        return None
    return h, mat or material_ladera(h, H, canal, largo, u)


def fotos_cueva(cam, grilla):
    isla_x, isla_z = ISLA
    foto(cam, "1_arco_de_cerca", punto(-22, -(R_A + 110), 46), punto(6, -R_A, 78), 26)
    foto(cam, "2_desde_la_plaza", punto(isla_x + 30, isla_z + 40, L["plateauHeight"] + 5),
         punto(0, -R_A * 0.45, 170), 22)
    foto(cam, "3_tunel", punto(4, -(R_A - 22), PASEO + 8), punto(0, -(WALK_END - 20), PASEO + 14), 22)
    foto(cam, "4_aerea_entrada", punto(-260, -(R_A + 330), 260), punto(10, -R_A, 80), 30)


BLEND = os.path.join(RAIZ, "assets", "blender", "volcan_v2", "volcan_bloques_4e.blend")
RENDERS = os.path.join(RAIZ, "renders", "volcan_v2f")
