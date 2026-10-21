r"""
Adentro del jardín de entrenamiento, en la isla de bloques (sin bpy):
- Los senderos (la cruz del centro a las cuatro salidas y el anillo, unidos en el mismo nivel)
  quedan SUBE_SENDERO más altos que el pasto, de material "sendero" (arriba arena, el lado de
  piedra). La cruz sigue a esa altura por el claro del sagrado hasta meterse bajo el aro de
  piedras (así nace del estanque del centro); el resto del claro no sube. Las rampas de las
  cuatro salidas son isla_bloques_rampas.py.
- Cada estanque es un pozo: la hoya de barro baja hasta HOYA_TOPE (2 bajo el agua, así el barro
  no queda al ras de la lámina) y la orilla de barro de afuera pasa a pasto (la tapa el aro de
  piedras de isla_bloques_aros.py).
- Alrededor de cada estanque, montículos de pasto (isla_bloques_monticulos.py): se suman acá,
  como parte de la forma, y ahí no ondula.
- El pasto ondula de 1 a 2 studs (escalones de 1 solo acá: malla.PASO_JARDIN), en manchones de
  frecuencia media. Quedan planos los senderos, el claro, una celda junto a cada sendero, el
  pasto que rodea cada estanque hasta una celda más allá del aro, y las huellas de las piezas.
    preparar(ruta_mundo, celda, n)
    elevar(x, z, alto, material) -> (alto, material)   senderos, hoya y orilla
    ondular(i, j, x, z, alto, material) -> (alto, material)
    dentro(x, z) -> bool
"""
import math
from collections import deque
import isla_bloques_forma as F
import isla_bloques_piezas as P
import isla_bloques_monticulos as MO
import isla_bloques_relieve as R

SUBE_SENDERO = 2
HOYA_TOPE = 4  # lo más alto del fondo de un estanque (el agua está en 6)
AMPLITUD = 2  # studs que sube el pasto
ONDA = (22.0, 0.65), (11.0, 0.35)  # manchones de 3 a 8 celdas de 4 studs
UMBRAL = (0.38, 0.72)
ARO = 5  # studs que ocupa el aro de piedras por fuera del agua
FUERA_DEL_AGUA = 2.2  # la celda de la cruz más cercana al agua: entera por fuera (medio lado + algo)
PESO = {}  # (i, j) -> 0..1 dentro del jardín


def dentro(x, z):
    return math.hypot(x, z) <= F.L["plazaRadius"]


def elevar(x, z, alto, material):
    if not dentro(x, z):
        return alto, material
    tipo = F.tipo_sendero((x, z))
    if material == "barro":
        cerca = F.estanque_de((x, z))
        if cerca and cerca[1] < cerca[2]:
            return min(alto, HOYA_TOPE), material  # el pozo
        # La orilla de afuera: la tapa el aro. En el claro, arena (o la cruz que llega al aro).
        if tipo == "claro":
            material = "arena"
        else:
            return alto, "jardin"
    llega = tipo == "claro" and F.en_rayo((x, z)) and _fuera_del_agua(x, z)
    if material == "arena" and (tipo in ("rayo", "anillo") or llega):
        return alto + SUBE_SENDERO, "sendero"
    if material == "jardin":
        return alto + MO.altura(x, z), material
    return alto, material


def _fuera_del_agua(x, z):
    for indice, centro, radio in F.ESTANQUES:
        dx, dz = x - centro[0], z - centro[1]
        if math.hypot(dx, dz) < F.borde_estanque(indice, radio, math.atan2(dz, dx)) + FUERA_DEL_AGUA:
            return False
    return True


def _plano(x, z):
    """¿Esta columna del jardín queda plana? Senderos, claro, estanques con su aro y orilla, y
    lo que arma el juego al correr (vitrinas de los trajes)."""
    _, material, _ = F.muestra(x, z)
    if material != "jardin" or P.en_pieza_del_juego(x, z):
        return True
    for indice, centro, radio in F.ESTANQUES:
        dx, dz = x - centro[0], z - centro[1]
        if math.hypot(dx, dz) < F.borde_estanque(indice, radio, math.atan2(dz, dx)) + ARO:
            return True
    return False


def preparar(ruta_mundo, celda, n):
    semillas = set()
    for i in range(-n, n):
        for j in range(-n, n):
            x, z = (i + 0.5) * celda, (j + 0.5) * celda
            if dentro(x, z) and _plano(x, z):
                semillas.add((i, j))
    for caja in R._huellas(ruta_mundo, R.CONSTRUCCIONES | R.DECORACION):
        semillas.update(R._celdas(caja, celda, 0))
    # La celda pegada a lo plano también queda plana; después sube en una celda más.
    distancia = {c: 0 for c in semillas}
    cola = deque(semillas)
    while cola:
        i, j = cola.popleft()
        if distancia[i, j] >= 2:
            continue
        for v in ((i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)):
            if v not in distancia:
                distancia[v] = distancia[i, j] + 1
                cola.append(v)
    PESO.clear()
    for c, d in distancia.items():
        PESO[c] = 0.0 if d <= 1 else 0.5
    return len(semillas)


def ondular(i, j, x, z, alto, material):
    if material != "jardin" or MO.altura(x, z) > 0:
        return alto, material
    ruido = sum(R._valor(x, z, paso) * peso for paso, peso in ONDA)
    return alto + AMPLITUD * R._entre(ruido, *UMBRAL) * PESO.get((i, j), 1.0), material
