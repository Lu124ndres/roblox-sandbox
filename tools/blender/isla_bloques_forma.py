r"""
Forma de la isla principal como campo de alturas, en Python: la misma que arma el terreno
del juego (src/server/World/IslandShape.luau, función mainIsland, y GardenShape.luau), así
el suelo de bloques queda a la altura de las piezas que ya están apoyadas (estanques,
caminos, faro, puente, vitrinas). Sin el cráter: ese lo modela el volcán aparte.
Sin bpy: se puede probar con Python suelto.

    cargar(ruta_json)              lee WorldLayoutData.json
    muestra(x, z) -> (alto, material, agua)
        alto      altura del suelo en studs (Y de Roblox)
        material  "pasto", "jardin", "arena", "camino", "barro" o "roca" (los del terreno)
        agua      hasta dónde llega el agua en ese punto (el mar o el de un estanque)
Ejes: (x, z) son los de Roblox, la isla centrada en el origen.
"""
import json, math

L = {}
CAMINOS = []  # segmentos (a, b) de los caminos de piedra de la meseta
RAYOS = []  # senderos rectos del jardín
ESTANQUES = []  # (índice, centro, radio base)
FARO = (0.0, 0.0)
ANCHO_CAMINO = 4.5  # medio ancho de los caminos de piedra (IslandShape.PATH_HALF_WIDTH)
ONDULA_SENDERO = 0.6  # GardenShape.PATH_WIGGLE
LABIO_HOYA = 0.6  # GardenShape.BOWL_LIP


def polar(angulo, radio):
    a = math.radians(angulo)
    return (math.cos(a) * radio, math.sin(a) * radio)


def cargar(ruta):
    global FARO
    with open(ruta, encoding="utf-8") as f:
        L.update(json.load(f))
    CAMINOS.clear()
    for angulo, hasta in (
        (L["spawnAngle"], L["plateauRadius"] - 2),
        (L["shopAngle"], L["shopRadius"] - 4),
        (L["campAngle"], L["campRadius"] - 8),
        (L["lighthouseAngle"], L["plateauRadius"] - 2),
        (L["bridgeAngle"], L["bridgeStartRadius"] + 4),
    ):
        CAMINOS.append((polar(angulo, L["plazaRadius"] - 2), polar(angulo, hasta)))
    RAYOS.clear()
    for angulo in L["gardenSpokeAngles"]:
        RAYOS.append((polar(angulo, L["gardenClearingRadius"]), polar(angulo, L["gardenRingRadius"])))
    FARO = polar(L["lighthouseAngle"], L["lighthouseRadius"])
    # Estanques: 1..trainingPondCount y el sagrado (trainingPondCount + 1) en el centro.
    ESTANQUES.clear()
    sagrado = L["trainingPondCount"] + 1
    quitados = set(L.get("removedPonds", []))
    for indice in range(1, sagrado + 1):
        if indice in quitados:
            continue  # los quitados quedan como pasto (WorldZones.pondExists)
        if indice == sagrado:
            ESTANQUES.append((indice, (0.0, 0.0), L["sacredPondRadius"]))
        else:
            x, z = L["pondPositions"][indice - 1]
            ESTANQUES.append((indice, (x, z), L["trainingPondRadius"]))


def distancia_segmento(p, a, b):
    abx, abz = b[0] - a[0], b[1] - a[1]
    t = ((p[0] - a[0]) * abx + (p[1] - a[1]) * abz) / (abx * abx + abz * abz)
    t = min(max(t, 0.0), 1.0)
    return math.hypot(p[0] - (a[0] + abx * t), p[1] - (a[1] + abz * t))


def perfil(radio):
    """IslandShape.baseHeight: meseta, playa y repisa que baja al fondo del mar."""
    if radio <= L["plateauRadius"]:
        return L["plateauHeight"]
    if radio <= L["beachEndRadius"]:
        t = (radio - L["plateauRadius"]) / (L["beachEndRadius"] - L["plateauRadius"])
        return L["plateauHeight"] + (L["beachEndHeight"] - L["plateauHeight"]) * t
    if radio <= L["shelfRadius"]:
        t = (radio - L["beachEndRadius"]) / (L["shelfRadius"] - L["beachEndRadius"])
        return L["beachEndHeight"] + (L["seaFloorHeight"] - L["beachEndHeight"]) * t
    return L["seaFloorHeight"]


def borde_estanque(indice, radio, angulo):
    """WorldZones.pondEdge: la orilla ondula en 2, 3 y 5 lóbulos."""
    w = L["pondWobble"]
    forma = (1 + w[0] * math.sin(2 * angulo + 1.7 * indice) + w[1] * math.sin(3 * angulo + 2.9 * indice)
             + w[2] * math.sin(5 * angulo + 0.8 * indice))
    return radio * forma


def tipo_sendero(p):
    """Qué sendero del jardín pisa el punto: "anillo", "claro" (alrededor del sagrado), "rayo"
    (la cruz) o None. Misma regla que GardenShape.onPath."""
    ondula = (math.sin(p[0] * 0.21) + math.sin(p[1] * 0.17)) * ONDULA_SENDERO / 2
    medio = L["gardenPathHalfWidth"] + ondula
    radio = math.hypot(*p)
    if abs(radio - L["gardenRingRadius"]) <= medio:
        return "anillo"
    if radio <= L["gardenClearingRadius"] + ondula:
        return "claro"
    return "rayo" if any(distancia_segmento(p, a, b) <= medio for a, b in RAYOS) else None


def en_rayo(p):
    """¿El punto cae en la franja de un rayo de la cruz, prolongada hasta el centro?"""
    ondula = (math.sin(p[0] * 0.21) + math.sin(p[1] * 0.17)) * ONDULA_SENDERO / 2
    medio = L["gardenPathHalfWidth"] + ondula
    for angulo in L["gardenSpokeAngles"]:
        dx, dz = polar(angulo, 1)
        if p[0] * dx + p[1] * dz >= 0 and abs(p[1] * dx - p[0] * dz) <= medio:
            return True
    return False


def en_sendero(p):
    return tipo_sendero(p) is not None


def estanque_de(p):
    """(índice, distancia al centro, orilla en esa dirección) del estanque cuya orilla de barro
    toca el punto, o None."""
    for indice, centro, radio in ESTANQUES:
        dx, dz = p[0] - centro[0], p[1] - centro[1]
        distancia = math.hypot(dx, dz)
        orilla = borde_estanque(indice, radio, math.atan2(dz, dx))
        if distancia < orilla + L["pondBankWidth"]:
            return indice, distancia, orilla
    return None


def jardin(p, alto):
    """GardenShape.sample: pasto con senderos de arena y hoyas de barro con agua."""
    material = "arena" if en_sendero(p) else "jardin"
    for indice, centro, radio in ESTANQUES:
        dx, dz = p[0] - centro[0], p[1] - centro[1]
        distancia = math.hypot(dx, dz)
        orilla = borde_estanque(indice, radio, math.atan2(dz, dx))
        if distancia < orilla:
            hoya = (distancia / orilla) ** 2
            hondo = L["trainingPondWaterTop"] - L["trainingPondFloor"] - LABIO_HOYA
            return L["trainingPondFloor"] + hoya * hondo, "barro", L["trainingPondWaterTop"]
        if distancia < orilla + L["pondBankWidth"]:
            material = "barro"
    return alto, material, L["waterLevel"]


def muestra(x, z):
    """IslandShape.mainIsland en el punto (x, z)."""
    p = (x, z)
    radio = math.hypot(x, z)
    alto = perfil(radio)
    material = "pasto" if radio <= L["plateauRadius"] - 2 else "arena"
    for hx, hz, hr in L["hills"]:
        d = math.hypot(x - hx, z - hz)
        if d < hr * 1.6:
            loma = L["plateauHeight"] + hr * 0.55 * math.cos(d / (hr * 1.6) * math.pi / 2)
            if loma > alto:
                alto, material = loma, "pasto"
    for rx, rz, rr in L["shoreRocks"]:
        d = math.hypot(x - rx, z - rz)
        if d < rr:
            tope = perfil(math.hypot(rx, rz)) + rr * 0.8 * (1 - (d / rr) ** 2)
            if tope > alto:
                alto, material = tope, "roca"
    desde_faro = math.hypot(x - FARO[0], z - FARO[1])
    if desde_faro < L["lighthouseMoundRadius"]:
        t = min(max((L["lighthouseMoundRadius"] - desde_faro) / (L["lighthouseMoundRadius"] - 9), 0), 1)
        tope = L["waterLevel"] - 3 + t * (L["lighthouseBaseHeight"] - L["waterLevel"] + 3)
        if tope > alto:
            alto = tope
            material = "camino" if desde_faro < 10 else "roca"
    if radio <= L["plazaRadius"]:
        return jardin(p, alto)
    if radio <= L["plateauRadius"]:
        if any(distancia_segmento(p, a, b) <= ANCHO_CAMINO for a, b in CAMINOS):
            material = "camino"
    return alto, material, L["waterLevel"]


def alcance():
    """Radio fuera del cual todo es fondo de mar (como IslandShape.touches, sin el cráter)."""
    r = L["shelfRadius"]
    for hx, hz, hr in L["hills"]:
        r = max(r, math.hypot(hx, hz) + hr * 1.6)
    for rx, rz, rr in L["shoreRocks"]:
        r = max(r, math.hypot(rx, rz) + rr)
    return max(r, math.hypot(*FARO) + L["lighthouseMoundRadius"])
