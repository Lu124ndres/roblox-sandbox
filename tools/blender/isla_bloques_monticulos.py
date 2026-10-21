r"""
Montículos de pasto alrededor de cada estanque, en la isla de bloques (sin bpy): justo por
fuera del aro de piedras, lomitas irregulares de 1 a 3 studs (escalones de 1, como el resto del
jardín) que abrazan el estanque, más altas pegadas al aro y bajando hacia afuera, con entrantes
y cortes (ruido según el ángulo) y dos aberturas planas por estanque, hacia los dos senderos más
cercanos, para entrar caminando. El sagrado no lleva aberturas (se llega por la cruz) y sus
montículos quedan fuera del claro.
No se tocan: la celda bajo las piedras (el aro apoya parejo), los senderos con una celda de
margen y las huellas de las piezas de Isla.model.json (sin la Tapa, el marcador Estanque ni los
Brillo del borde, que son invisibles o los reemplaza el aro). Se calcula una vez en la
cuadrícula: así la apertura morfológica del relieve no lo aplana, y los sueltos se limpian acá.
    preparar(ruta_mundo, celda, n)
    altura(x, z) -> studs que sube esa columna
    MATAS: [(x, y, z)] matas de hojas sobre algunos montículos
    APERTURAS: {índice: [ángulos en radianes]}
"""
import json, math
import isla_bloques_forma as F
import isla_bloques_relieve as R

ARO = 5.0  # studs que ocupa el aro por fuera del agua (escala con el estanque)
ANCHO = 14.0  # studs de montículo por fuera del aro: tres celdas y media
ALTO_MAX = 3.0
APERTURA = 0.42  # radianes a cada lado del eje de la abertura (unos 24 grados)
SUAVE = 0.3  # radianes en que la abertura vuelve a subir
SIN_HUELLA = ("Tapa", "Estanque", "Brillo")  # piezas de estanque que no cuentan como huella
MATA = 0.07  # probabilidad de una mata de hojas en un montículo de 2 o más

MONTICULO = {}  # (i, j) -> studs
MATAS = []
APERTURAS = {}
_CELDA = [4]


def _huellas(ruta_mundo, celda):
    with open(ruta_mundo, encoding="utf-8") as f:
        mundo = json.load(f)
    celdas = set()

    def recorrer(nodo):
        p = nodo.get("properties") or {}
        cf, tam = p.get("CFrame"), p.get("Size")
        if cf and tam and not str(nodo.get("name", "")).startswith(SIN_HUELLA):
            x, y, z = cf[:3]
            r = cf[3:]
            ex = sum(abs(r[k]) * tam[k] / 2 for k in range(3))
            ey = sum(abs(r[3 + k]) * tam[k] / 2 for k in range(3))
            ez = sum(abs(r[6 + k]) * tam[k] / 2 for k in range(3))
            if abs((y - ey) - F.muestra(x, z)[0]) < 2:
                celdas.update(R._celdas((x - ex, x + ex, z - ez, z + ez), celda, 0))
        for hijo in nodo.get("children", []):
            recorrer(hijo)

    for grupo in mundo.get("children", []):
        if grupo.get("name") in R.CONSTRUCCIONES | R.DECORACION:
            recorrer(grupo)
    return celdas


def _aperturas(centro):
    """Ángulos hacia los dos senderos más cercanos (un rayo de la cruz o el anillo)."""
    destinos = []
    for a, b in F.RAYOS:
        abx, abz = b[0] - a[0], b[1] - a[1]
        t = min(max(((centro[0] - a[0]) * abx + (centro[1] - a[1]) * abz) / (abx * abx + abz * abz), 0), 1)
        destinos.append((a[0] + abx * t, a[1] + abz * t))
    d = math.hypot(*centro)
    destinos.append((centro[0] / d * F.L["gardenRingRadius"], centro[1] / d * F.L["gardenRingRadius"]))
    destinos.sort(key=lambda p: math.hypot(p[0] - centro[0], p[1] - centro[1]))
    return [math.atan2(p[1] - centro[1], p[0] - centro[0]) for p in destinos[:2]]


def _diferencia(a, b):
    return abs((a - b + math.pi) % math.tau - math.pi)


def _alto(x, z):
    mejor = 0.0
    for indice, centro, radio in F.ESTANQUES:
        dx, dz = x - centro[0], z - centro[1]
        angulo = math.atan2(dz, dx)
        escala = math.sqrt(radio / F.L["trainingPondRadius"])
        s = math.hypot(dx, dz) - (F.borde_estanque(indice, radio, angulo) + ARO * escala)
        if s < 0 or s >= ANCHO:
            continue
        ruido = R._valor(math.cos(angulo) * 40 + indice * 97, math.sin(angulo) * 40, 18)
        forma = 0.0 if ruido < 0.16 else 0.55 + 0.9 * ruido  # entrantes y alturas variadas
        for abre in APERTURAS.get(indice, []):
            diferencia = _diferencia(angulo, abre)
            forma *= 0.0 if diferencia < APERTURA else min((diferencia - APERTURA) / SUAVE, 1.0)
        mejor = max(mejor, ALTO_MAX * (1 - s / ANCHO) * forma)
    return mejor


def preparar(ruta_mundo, celda, n):
    _CELDA[0] = celda
    sagrado = F.L["trainingPondCount"] + 1
    APERTURAS.clear()
    for indice, centro, _ in F.ESTANQUES:
        if indice != sagrado:
            APERTURAS[indice] = _aperturas(centro)
    bloqueo = _huellas(ruta_mundo, celda)
    for i in range(-n, n):
        for j in range(-n, n):
            x, z = (i + 0.5) * celda, (j + 0.5) * celda
            if math.hypot(x, z) <= F.L["plazaRadius"] and (F.tipo_sendero((x, z)) or F.en_rayo((x, z))):
                bloqueo.update((i + a, j + b) for a in (-1, 0, 1) for b in (-1, 0, 1) if abs(a) + abs(b) <= 1)
    MONTICULO.clear()
    for i in range(-n, n):
        for j in range(-n, n):
            x, z = (i + 0.5) * celda, (j + 0.5) * celda
            if (i, j) in bloqueo or math.hypot(x, z) > F.L["plazaRadius"] or F.muestra(x, z)[1] != "jardin":
                continue
            h = min(round(_alto(x, z)), int(ALTO_MAX))
            if h > 0:
                MONTICULO[i, j] = h
    for _ in range(2):  # sin sueltos: un montículo necesita al menos dos vecinos con montículo
        for (i, j) in list(MONTICULO):
            vecinos = sum(1 for v in ((i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)) if v in MONTICULO)
            if vecinos < 2:
                del MONTICULO[i, j]
    MATAS.clear()
    for (i, j), h in sorted(MONTICULO.items()):
        if h >= 2 and R._hash(i * 3 + 1, j * 7 + 2) < MATA:
            MATAS.append(((i + 0.5) * celda, F.L["plateauHeight"] + h, (j + 0.5) * celda))
    return len(MONTICULO)


def altura(x, z):
    return MONTICULO.get((math.floor(x / _CELDA[0]), math.floor(z / _CELDA[0])), 0)
