r"""
Relieve natural de la isla de bloques: lomas suaves de baja frecuencia (ruido determinista
con SEMILLA) que crecen hacia el borde de la meseta y la costa, y tramos de la orilla donde la
meseta sigue un poco más y cae en un acantilado bajo a la playa. Nada de picos sueltos.

Las zonas de juego quedan planas y a su altura actual (peso 0, y sube a 1 en CAIDA celdas):
el jardín entero (GardenShape), los caminos de piedra con 2 celdas de margen, la tienda, el
campamento, el faro, la entrada del puente con su pasillo, los muelles y la huella de cada
pieza de world/Isla.model.json apoyada en el suelo (se lee el archivo).
Sin bpy.
    preparar(ruta_mundo, celda, n)    marca las zonas planas en la cuadrícula de -n..n-1
    alzar(i, j, x, z, alto, material) -> (alto, material)   el relieve en esa columna
Lo de adentro del jardín (senderos elevados, estanques y ondulaciones) es isla_bloques_jardin.py.
"""
import json, math
from collections import deque
import isla_bloques_forma as F

SEMILLA = 7
ONDA = (80.0, 0.6), (40.0, 0.4)  # (studs entre lomas, peso) de cada octava
UMBRAL = (0.3, 0.66)  # el ruido sube de 0 a 1 entre estos valores: lomas sueltas y redondas
FUERZA = (6, 10)  # alto de las lomas al salir del jardín y en el borde de la meseta (studs)
CAIDA = 3  # celdas en que el relieve pasa de nada a todo al salir de una zona plana
CAIDA_ADORNO = 2  # lo mismo alrededor de un adorno de la meseta
# Grupos de Isla.model.json con piezas apoyadas: las construcciones dejan plano su alrededor
# (una celda y la caída); la decoración (palmeras, arbustos, rocas, conchas) apoyada en la
# meseta, lo que pisa y una caída corta (la de la playa no: ahí no hay que aplanar).
CONSTRUCCIONES = {"ZonaEntrenamiento", "Puente", "Aparicion", "ArcoEntrada", "Cabana", "Faro", "Campamento"}
DECORACION = {"Decoracion"}
PESO = {}  # (i, j) -> 0..1


def _hash(ix, iz):
    v = math.sin(ix * 127.1 + iz * 311.7 + SEMILLA * 74.7) * 43758.5453
    return v - math.floor(v)


def _suave(t):
    return t * t * (3 - 2 * t)


def _valor(x, z, paso):
    gx, gz = x / paso, z / paso
    ix, iz = math.floor(gx), math.floor(gz)
    tx, tz = _suave(gx - ix), _suave(gz - iz)
    a, b = _hash(ix, iz), _hash(ix + 1, iz)
    c, d = _hash(ix, iz + 1), _hash(ix + 1, iz + 1)
    return (a + (b - a) * tx) + ((c + (d - c) * tx) - (a + (b - a) * tx)) * tz


def ruido(x, z):
    return sum(_valor(x, z, paso) * peso for paso, peso in ONDA)


def _entre(t, a, b):
    return _suave(min(max((t - a) / (b - a), 0.0), 1.0))


def _huellas(ruta_mundo, grupos, solo_meseta=False):
    """Cajas (x0, x1, z0, z1) de las piezas de esos grupos apoyadas en el suelo (o en la meseta)."""
    with open(ruta_mundo, encoding="utf-8") as f:
        mundo = json.load(f)
    cajas = []

    def recorrer(nodo):
        p = nodo.get("properties") or {}
        cf, tam = p.get("CFrame"), p.get("Size")
        if cf and tam:
            x, y, z = cf[:3]
            r = cf[3:]
            ex = sum(abs(r[k]) * tam[k] / 2 for k in range(3))
            ey = sum(abs(r[3 + k]) * tam[k] / 2 for k in range(3))
            ez = sum(abs(r[6 + k]) * tam[k] / 2 for k in range(3))
            base = y - ey
            if abs(base - F.muestra(x, z)[0]) < 2 and (not solo_meseta or abs(base - F.L["plateauHeight"]) <= 1.5):
                cajas.append((x - ex, x + ex, z - ez, z + ez))
        for hijo in nodo.get("children", []):
            recorrer(hijo)

    for grupo in mundo.get("children", []):
        if grupo.get("name") in grupos:
            recorrer(grupo)
    return cajas


def _plano(x, z, celda):
    """¿El centro de la columna cae en una zona de juego?"""
    r = math.hypot(x, z)
    L = F.L
    if r <= L["plazaRadius"] + celda:
        return True
    if any(F.distancia_segmento((x, z), a, b) <= F.ANCHO_CAMINO + 2 * celda for a, b in F.CAMINOS):
        return True
    for angulo, radio, alcance in ((L["shopAngle"], L["shopRadius"], 22), (L["campAngle"], L["campRadius"], 24),
                                   (L["bridgeAngle"], L["bridgeStartRadius"], 26)):
        px, pz = F.polar(angulo, radio)
        if math.hypot(x - px, z - pz) <= alcance:
            return True
    if math.hypot(x - F.FARO[0], z - F.FARO[1]) <= L["lighthouseMoundRadius"] + 2 * celda:
        return True
    # Pasillos: el del puente (ancho bridgeWidth) y el de cada muelle, desde la meseta.
    for angulo, medio in [(L["bridgeAngle"], L["bridgeWidth"] / 2 + celda)] + [(a, 8 + celda) for a in L["pierAngles"]]:
        dx, dz = F.polar(angulo, 1)
        largo = x * dx + z * dz
        if largo >= L["plazaRadius"] and abs(-x * dz + z * dx) <= medio:
            return True
    return False


def _celdas(caja, celda, margen):
    x0, x1, z0, z1 = caja
    for i in range(math.floor(x0 / celda) - margen, math.floor(x1 / celda) + 1 + margen):
        for j in range(math.floor(z0 / celda) - margen, math.floor(z1 / celda) + 1 + margen):
            yield i, j


def preparar(ruta_mundo, celda, n):
    cajas = _huellas(ruta_mundo, CONSTRUCCIONES)
    adornos = _huellas(ruta_mundo, DECORACION, solo_meseta=True)
    planas = set()
    for i in range(-n, n):
        for j in range(-n, n):
            if _plano((i + 0.5) * celda, (j + 0.5) * celda, celda):
                planas.add((i, j))
    for caja in cajas:  # la huella de cada construcción, con una celda de margen
        planas.update(_celdas(caja, celda, 1))
    # Distancia (en celdas) a la zona plana más cercana, por vecindad.
    distancia = {c: 0 for c in planas}
    cola = deque(planas)
    while cola:
        i, j = cola.popleft()
        d = distancia[i, j]
        if d >= CAIDA:
            continue
        for v in ((i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)):
            if -n <= v[0] < n and -n <= v[1] < n and v not in distancia:
                distancia[v] = d + 1
                cola.append(v)
    PESO.clear()
    for c, d in distancia.items():
        PESO[c] = d / CAIDA
    for caja in adornos:  # bajo cada adorno, plano, y una caída corta alrededor
        for i, j in _celdas(caja, celda, CAIDA_ADORNO):
            borde = max(abs(i - min(max(i, math.floor(caja[0] / celda)), math.floor(caja[1] / celda))),
                        abs(j - min(max(j, math.floor(caja[2] / celda)), math.floor(caja[3] / celda))))
            PESO[i, j] = min(PESO.get((i, j), 1.0), borde / (CAIDA_ADORNO + 1))
    return len(planas), len(cajas) + len(adornos)


def alzar(i, j, x, z, alto, material):
    peso = min(PESO.get((i, j), 1.0), 1.0)
    if peso <= 0:
        return alto, material
    L = F.L
    r = math.hypot(x, z)
    # Fuerza: FUERZA[0] al salir del jardín, FUERZA[1] en el borde de la meseta, 0 mar adentro.
    fuerza = FUERZA[0] + (FUERZA[1] - FUERZA[0]) * _entre(r, L["plazaRadius"], L["plateauRadius"])
    fuerza *= 1 - _entre(r, L["shoreRadius"] - 2, L["shoreRadius"] + 18)
    loma = fuerza * _entre(ruido(x, z), *UMBRAL) * peso
    # Acantilado bajo: en algunos tramos la meseta sigue hasta 16 studs más y cae a la playa.
    angulo = math.atan2(z, x)
    tramo = _valor(math.cos(angulo) * 300, math.sin(angulo) * 300, 70)
    sobra = 16 * _entre(tramo, 0.55, 0.8)
    if L["plateauRadius"] - 2 < r < L["plateauRadius"] + sobra:
        meseta = L["plateauHeight"] + loma
        if meseta > alto:
            return alto + (meseta - alto) * peso, "pasto"
    if loma > 0 and alto + loma > L["waterLevel"]:
        return alto + loma, material
    return alto, material
