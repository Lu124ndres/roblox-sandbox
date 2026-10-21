r"""
Formas de los props de bloques (las carga props_bloques.py, que trae caja(), CELDA y BISEL).
Medidas en celdas; cada forma devuelve un bmesh con la base en z = 0.
    palmera(semilla, segmentos, inclina)   tronco con anillos que se curva hacia +x, copa,
                                           diez hojas en dos pisos que caen, cocos
    arbusto(semilla)                       mata de cubos verdes con flores arriba
    roca(semilla, musgo, chata)            bloques de piedra apilados y girados
    cresta(semilla, pisos)                 pico de basalto escalonado con vetas de lava
"""
import bmesh, math, random
from mathutils import Vector as V

# Hoja: tramos de (ancho, cuánto sube en grados); cada tramo sale de la punta del anterior.
HOJA_LARGA = ((2.2, 22), (2.8, 6), (2.4, -14), (1.8, -32), (1.0, -50))
HOJA_CORTA = ((1.8, 40), (2.2, 22), (1.6, 0), (0.9, -22))
LARGO_TRAMO = 1.7


def hoja(bm, base, angulo, tramos, semilla):
    direccion = V((math.cos(math.radians(angulo)), math.sin(math.radians(angulo)), 0))
    costado = V((-direccion.y, direccion.x, 0))
    punto = base.copy()
    for j, (ancho, sube) in enumerate(tramos):
        tramo = direccion * math.cos(math.radians(sube)) + V((0, 0, math.sin(math.radians(sube))))
        centro = punto + tramo * LARGO_TRAMO * CELDA / 2
        color = "hoja" if (j + semilla) % 2 == 0 else "hoja2"
        caja(bm, color, centro, (ancho, LARGO_TRAMO + 0.3, 0.45), giro=angulo - 90, inclina=sube,
             centrado=True)
        if 1 <= j <= len(tramos) - 2:  # hojuelas a los costados: el borde dentado
            for lado in (-1, 1):
                al_lado = centro + costado * lado * (ancho / 2 + 0.35) * CELDA - V((0, 0, 0.15 * CELDA))
                caja(bm, "hoja2" if color == "hoja" else "hoja", al_lado, (0.9, 1.1, 0.35),
                     giro=angulo - 90 + lado * 25, inclina=sube - 10, centrado=True, bisel=0)
        punto = punto + tramo * LARGO_TRAMO * CELDA


def palmera(semilla, segmentos=10, inclina=2.6):
    rnd = random.Random(semilla)
    bm = bmesh.new()
    alto = 1.3
    tope = V((0, 0, 0))
    for i in range(segmentos):
        t = i / (segmentos - 1)
        ancho = 1.6 - 0.45 * t
        tope = V((inclina * t * t * CELDA, 0, i * alto * CELDA))
        caja(bm, "tronco", tope, (ancho, ancho, alto))
        caja(bm, "tronco2", tope, (ancho + 0.35, ancho + 0.35, 0.35), bisel=0)  # anillo
    copa = tope + V((0, 0, alto * CELDA))
    caja(bm, "hoja2", copa, (2.6, 2.6, 1.2), giro=10)
    caja(bm, "hoja", copa + V((0, 0, 1.2 * CELDA)), (1.8, 1.8, 0.9), giro=35)
    giro0 = rnd.uniform(0, 60)
    for k in range(6):  # piso de abajo: seis hojas largas que caen
        hoja(bm, copa + V((0, 0, 0.9 * CELDA)), giro0 + k * 60 + rnd.uniform(-8, 8), HOJA_LARGA, k)
    for k in range(4):  # piso de arriba: cuatro más cortas y paradas, entre las de abajo
        hoja(bm, copa + V((0, 0, 1.8 * CELDA)), giro0 + 30 + k * 90 + rnd.uniform(-10, 10), HOJA_CORTA, k + 1)
    for k in range(3):  # cocos bajo la copa
        angulo = math.radians(giro0 + 20 + k * 120)
        punto = copa + V((math.cos(angulo), math.sin(angulo), 0)) * 1.3 * CELDA - V((0, 0, 0.9 * CELDA))
        caja(bm, "coco", punto, (1.0, 1.0, 1.0), giro=k * 25)
    return bm


def arbusto(semilla):
    rnd = random.Random(semilla)
    bm = bmesh.new()
    matas = [((0, 0, 0), (4.2, 3.6, 2.6)), ((1.4, 1.0, 1.6), (2.8, 2.6, 2.2)),
             ((-1.5, 0.6, 1.2), (2.4, 2.4, 2.0)), ((0.3, -1.3, 1.4), (2.4, 2.0, 2.0)),
             ((-0.2, 0.2, 3.0), (2.2, 2.2, 1.6))]
    for i, (centro, medida) in enumerate(matas):
        caja(bm, ("mata", "mata2", "mata3")[i % 3], V(centro) * CELDA, medida, giro=rnd.uniform(-25, 25))
    for k in range(7):  # flores: cubitos de color sobre las matas
        angulo = rnd.uniform(0, 2 * math.pi)
        radio = rnd.uniform(0.6, 1.9)
        punto = V((math.cos(angulo) * radio, math.sin(angulo) * radio, rnd.uniform(3.4, 4.4))) * CELDA
        caja(bm, rnd.choice(("flor", "flor2", "flor3")), punto, (0.6, 0.6, 0.6), giro=rnd.uniform(0, 45), bisel=0)
    return bm


def roca(semilla, musgo=False, chata=False):
    rnd = random.Random(semilla)
    bm = bmesh.new()
    gordo = 0.22 * CELDA  # piedra: bisel más grueso que el de las hojas
    alto = 0.7 if chata else 1.0
    caja(bm, "roca", (0, 0, 0), (4.2, 3.2, 2.2 * alto), giro=rnd.uniform(-10, 10), bisel=gordo)
    caja(bm, "roca2", (1.6 * CELDA, 1.0 * CELDA, 0), (2.6, 2.2, 1.6 * alto), giro=rnd.uniform(-30, -10), bisel=gordo)
    giro = rnd.uniform(-15, 15)
    arriba = 2.1 * alto * CELDA
    caja(bm, "roca", (-0.4 * CELDA, -0.3 * CELDA, arriba), (2.8, 2.2, 1.4 * alto), giro=giro, inclina=6, bisel=gordo)
    if musgo:
        caja(bm, "musgo", (-0.5 * CELDA, -0.4 * CELDA, arriba + 1.35 * alto * CELDA), (2.2, 1.6, 0.35),
             giro=giro, inclina=6, bisel=0)
    caja(bm, "roca2", (-2.5 * CELDA, 1.2 * CELDA, 0), (1.4, 1.2, 0.9), giro=rnd.uniform(15, 40), bisel=gordo)
    caja(bm, "roca", (2.9 * CELDA, -1.3 * CELDA, 0), (0.9, 0.9, 0.6), giro=rnd.uniform(0, 30), bisel=0)
    return bm


def pico(bm, rnd, centro, pisos, ancho0):
    """Una torre de escalones de basalto que se achican, se corren y giran; algunas con una
    veta de lava asomando. Devuelve el alto."""
    z, corrido = 0.0, V((0, 0, 0))
    for i in range(pisos):
        t = i / max(pisos - 1, 1)
        ancho = ancho0 * (1 - t) ** 0.85 + 1.4
        alto = 2.2 + rnd.uniform(-0.4, 0.6)
        corrido += V((rnd.uniform(-0.7, 0.7), rnd.uniform(-0.7, 0.7), 0))
        base = centro + V((corrido.x * CELDA, corrido.y * CELDA, z))
        caja(bm, ("basalto", "basalto2")[i % 2], base, (ancho * rnd.uniform(0.8, 1.0), ancho * rnd.uniform(0.7, 1.0), alto),
             giro=rnd.uniform(-35, 35), inclina=rnd.uniform(-4, 4), bisel=0.18 * CELDA)
        if 0 < i < pisos - 2 and rnd.random() < 0.6:  # veta de lava asomando entre escalones
            lado = rnd.uniform(0, 2 * math.pi)
            veta = base + V((math.cos(lado), math.sin(lado), 0)) * ancho * 0.45 * CELDA + V((0, 0, alto * 0.15 * CELDA))
            caja(bm, "lava", veta, (3.0, 2.2, 0.8), giro=math.degrees(lado) + 90, bisel=0)
        z += alto * CELDA
    return z


def cresta(semilla, pisos=9):
    """Pico de basalto en escalones irregulares con vetas de lava, un pico más chico al lado
    y rocas al pie."""
    rnd = random.Random(semilla)
    bm = bmesh.new()
    pico(bm, rnd, V((0, 0, 0)), pisos, 9.0)
    lado = rnd.uniform(0, 2 * math.pi)
    pico(bm, rnd, V((math.cos(lado), math.sin(lado), 0)) * 3.6 * CELDA, max(pisos - 4, 3), 4.5)
    for k in range(3):  # rocas al pie
        angulo = rnd.uniform(0, 2 * math.pi)
        punto = V((math.cos(angulo), math.sin(angulo), 0)) * 5.8 * CELDA
        caja(bm, "basalto2", punto, (2.0, 1.6, 1.3), giro=rnd.uniform(0, 90), bisel=0.18 * CELDA)
    return bm
