r"""
Aro de piedras de cada estanque y su lámina, en bloques (sin bpy). Como la foto de referencia
del usuario: un anillo continuo de piedras grandes una al lado de la otra, gris-beige con la cara
de arriba más clara, de distintos tamaños y con las esquinas cortadas (octógonos biselados), que
sigue la orilla real de cada estanque (la de GardenShape, con su pondWobble) justo por fuera del
agua, y tierra oscura asomando entre piedras abajo. Las piedras son bajas (1 a 1.5 studs sobre el
pasto): un jugador parado afuera ve la lámina de color por encima del aro. Unas pocas matas de
hojas de bloques (como las de las palmeras de props_bloques_formas.py), repartidas parejo:
MATAS_COMUN por aro y MATAS_SAGRADO en el del centro. Todos los estanques llevan el mismo aro
(misma semilla y paleta); el sagrado, más grande, a su escala en ancho y fondo (no en alto).
    aros() -> {índice: [(polígono Roblox (X, Y, Z), color, normal)]}
    laminas() -> {índice: [puntos del contorno a trainingPondWaterTop]}
"""
import math, random
import isla_bloques_forma as F

SEMILLA = 11
ANCHO = (3.0, 5.0)  # studs a lo largo de la orilla
FONDO = (3.2, 4.4)  # studs hacia afuera
ALTO = (1.4, 1.9)  # con lo hundido: 1 a 1.5 studs sobre el pasto
MORDIDA = 0.7  # cuánto se mete cada piedra sobre el agua (así no queda hueco con la lámina)
HUNDIDA = 0.4  # cuánto se entierra en el pasto
BISEL = 0.35
MATAS_COMUN = 2
MATAS_SAGRADO = 4
MUESTRAS = 180  # puntos del contorno


def _orilla(indice, centro, radio, angulo, mas=0.0):
    r = F.borde_estanque(indice, radio, angulo) + mas
    return centro[0] + math.cos(angulo) * r, centro[1] + math.sin(angulo) * r


def _marco(indice, centro, radio, angulo):
    """Punto de la orilla, tangente y normal hacia afuera (en XZ)."""
    a = _orilla(indice, centro, radio, angulo - 0.01)
    b = _orilla(indice, centro, radio, angulo + 0.01)
    p = _orilla(indice, centro, radio, angulo)
    t = (b[0] - a[0], b[1] - a[1])
    largo = math.hypot(*t)
    t = (t[0] / largo, t[1] / largo)
    n = (t[1], -t[0])
    if (p[0] - centro[0]) * n[0] + (p[1] - centro[1]) * n[1] < 0:
        n = (-n[0], -n[1])
    return p, t, n


def _octogono(medio_ancho, medio_fondo, corte):
    w, d, c = medio_ancho, medio_fondo, corte
    return [(-w + c, -d), (w - c, -d), (w, -d + c), (w, d - c), (w - c, d), (-w + c, d), (-w, d - c), (-w, -d + c)]


def _piedra(caras, color, p, t, n, ancho, fondo, alto, y0, tono):
    """Octógono biselado: arriba (más clara), el bisel y los lados; sin cara de abajo."""
    al_mundo = lambda u, v, y: (p[0] + u * t[0] + v * n[0], y, p[1] + u * t[1] + v * n[1])
    afuera = lambda u, v: (u * t[0] + v * n[0], 0, u * t[1] + v * n[1])
    corte = 0.28 * min(ancho, fondo)
    borde = _octogono(ancho / 2, fondo / 2, corte)
    tope = _octogono(ancho / 2 - BISEL, fondo / 2 - BISEL, max(corte - BISEL * 0.41, 0))
    y1, yb = y0 + alto, y0 + alto - BISEL
    caras.append((tuple(al_mundo(u, v, y1) for u, v in tope), f"{color}_arriba{tono}", (0, 1, 0)))
    for k in range(8):
        m = (k + 1) % 8
        normal = afuera((borde[k][0] + borde[m][0]) / 2, (borde[k][1] + borde[m][1]) / 2)
        caras.append(((al_mundo(*tope[k], y1), al_mundo(*tope[m], y1), al_mundo(*borde[m], yb),
                       al_mundo(*borde[k], yb)), f"{color}_canto", (normal[0], 1, normal[2])))
        caras.append(((al_mundo(*borde[k], yb), al_mundo(*borde[m], yb), al_mundo(*borde[m], y0),
                       al_mundo(*borde[k], y0)), f"{color}_lado", normal))


def _caja(caras, color, centro, giro, ancho, largo, grueso):
    """Bloquecito de hoja (sin bisel) con el largo hacia `giro` (radianes)."""
    cx, cy, cz = centro
    t = (math.cos(giro), math.sin(giro))
    n = (-t[1], t[0])
    esquinas = [(su * largo / 2, sv * ancho / 2) for su, sv in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    punto = lambda u, v, y: (cx + u * t[0] + v * n[0], y, cz + u * t[1] + v * n[1])
    for y, normal, tono in ((cy + grueso, (0, 1, 0), "arriba0"), (cy, (0, -1, 0), "lado")):
        caras.append((tuple(punto(u, v, y) for u, v in esquinas), f"{color}_{tono}", normal))
    for k in range(4):
        a, b = esquinas[k], esquinas[(k + 1) % 4]
        mu, mv = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
        normal = (mu * t[0] + mv * n[0], 0, mu * t[1] + mv * n[1])
        caras.append(((punto(*a, cy + grueso), punto(*b, cy + grueso), punto(*b, cy), punto(*a, cy)),
                      f"{color}_canto", normal))


def _mata(caras, rnd, x, y, z, escala):
    """Mata de hojas: un bloque en el medio y cinco hojas de dos tramos que caen."""
    _caja(caras, "hoja2", (x, y, z), rnd.uniform(0, 1), 1.3 * escala, 1.3 * escala, 0.8 * escala)
    giro0 = rnd.uniform(0, math.tau)
    for k in range(5):
        a = giro0 + k * math.tau / 5 + rnd.uniform(-0.2, 0.2)
        for paso, (lejos, sube) in enumerate(((0.9, 0.55), (1.9, 0.2))):
            centro = (x + math.cos(a) * lejos * escala, y + sube * escala, z + math.sin(a) * lejos * escala)
            _caja(caras, "hoja" if (k + paso) % 2 == 0 else "hoja2", centro, a,
                  0.8 * escala, 1.3 * escala, 0.32 * escala)


def _tierra(caras, indice, centro, radio, y):
    """Cinta de tierra oscura bajo las piedras: asoma solo entre una y otra."""
    for k in range(MUESTRAS):
        a0, a1 = math.tau * k / MUESTRAS, math.tau * (k + 1) / MUESTRAS
        adentro = [_orilla(indice, centro, radio, a, -MORDIDA) for a in (a0, a1)]
        afuera = [_orilla(indice, centro, radio, a, 2.6) for a in (a0, a1)]
        caras.append((((adentro[0][0], y, adentro[0][1]), (adentro[1][0], y, adentro[1][1]),
                       (afuera[1][0], y, afuera[1][1]), (afuera[0][0], y, afuera[0][1])), "tierra_arriba0", (0, 1, 0)))


def aros():
    suelo = F.L["plateauHeight"]
    resultado = {}
    for indice, centro, radio in F.ESTANQUES:
        rnd = random.Random(SEMILLA)  # el mismo aro en todos
        escala = math.sqrt(radio / F.L["trainingPondRadius"])
        caras = []
        _tierra(caras, indice, centro, radio, suelo + 0.12)
        # Largo de la orilla y piedras de ancho al azar que la cubren justo, sin huecos.
        puntos = [_orilla(indice, centro, radio, math.tau * k / MUESTRAS) for k in range(MUESTRAS + 1)]
        tramos = [math.hypot(puntos[k + 1][0] - puntos[k][0], puntos[k + 1][1] - puntos[k][1]) for k in range(MUESTRAS)]
        total = sum(tramos)
        anchos = []
        while sum(anchos) < total:
            anchos.append(rnd.uniform(*ANCHO) * escala)
        anchos = [a * total / sum(anchos) for a in anchos]
        sagrado = indice == F.L["trainingPondCount"] + 1
        cuantas = MATAS_SAGRADO if sagrado else MATAS_COMUN
        con_mata = {round((k + 0.37) * len(anchos) / cuantas) % len(anchos) for k in range(cuantas)}
        recorrido = 0.0
        for numero, ancho in enumerate(anchos):
            medio = recorrido + ancho / 2
            recorrido += ancho
            k, acumulado = 0, 0.0
            while k < MUESTRAS - 1 and acumulado + tramos[k] < medio:
                acumulado += tramos[k]
                k += 1
            angulo = math.tau * (k + (medio - acumulado) / tramos[k]) / MUESTRAS
            p, t, n = _marco(indice, centro, radio, angulo)
            fondo, alto = rnd.uniform(*FONDO) * escala, rnd.uniform(*ALTO)
            c = (p[0] + n[0] * (fondo / 2 - MORDIDA), p[1] + n[1] * (fondo / 2 - MORDIDA))
            tono = rnd.randrange(3)
            y0 = suelo - HUNDIDA
            _piedra(caras, "piedra", c, t, n, ancho + 0.3, fondo, alto, y0, tono)
            if numero in con_mata:
                _mata(caras, rnd, c[0], y0 + alto - 0.1, c[1], escala)
        resultado[indice] = caras
    return resultado


def laminas():
    agua = F.L["trainingPondWaterTop"]
    resultado = {}
    for indice, centro, radio in F.ESTANQUES:
        puntos = [_orilla(indice, centro, radio, math.tau * k / 72, 1.0) for k in range(72)]
        resultado[indice] = [(x, agua, z) for x, z in puntos]
    return resultado
