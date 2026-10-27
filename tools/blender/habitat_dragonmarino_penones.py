r"""
Hábitat del DragonMarino: los peñones donde se posa el dragón (Dragon/Guarida.perches) y el
nido sobre el central. Van en las mallas que SUBEN con la lava (LairLift), armadas en su lugar
final: la cima de cada peñón queda en Guarida.point() (LAVA + top).

Cada peñón es un racimo de columnas de basalto hexagonales:
    cima    las columnas con centro hasta `size + 2.5` del eje, todas cortadas a la altura exacta
            de la cima o hasta 0.5 más abajo (las juntas se ven sobre un núcleo de obsidiana);
            nada sobresale de ahí salvo el nido;
    flancos un muro casi a ras de la cima (2.6 más abajo de golpe, como supone Posado.surface)
            con tajos hondos, salientes a media altura y el pie saliendo de la lava; tres o
            cuatro espolones (contrafuertes) llegan más lejos, con losas que sobresalen, y
            columnas sueltas salen de la lava alrededor: se lee como una torre, no como un disco;
    lava    canales sin columnas por donde baja la lava hasta el lago y grietas verticales en el
            muro, con una lámina encendida al fondo (Neon);
    pie     costra y cascajo a la altura de la lava, y la roca sigue BAJO studs bajo ella.
"""
import math, random
from mathutils import Matrix, Vector
from habitat_dragonmarino_malla import (BAJO, FLARE, LAVA, NIDO_OFFSET, PIEDRA, TAU, V, ejes, hexagonos, perch_top,
                                        racimo)

C = 3.4  # radio circunscrito de las columnas
JUNTA = 0.92  # las columnas se achican un poco: se ven las juntas
EXTRA_CIMA = 2.5  # las columnas de la cima llegan hasta size + esto (cubren el radio size)
CORTE = 2.6  # el primer escalón de la ladera, bajo la cima
TAPAS = ("cima", "cima2", "cima", "basalto2", "ceniza", "cima", "ceniza2")  # la cima no es un piso parejo
Z = V((0, 0, 1))


def penon(m, l, perch, semilla):
    """Un peñón en la malla `m` (roca) y `l` (lava que sube)."""
    rnd = random.Random(semilla)
    cima_p, size = perch_top(perch)
    cx, cy, top = cima_p.x, cima_p.y, cima_p.z
    alto = top - LAVA
    fondo = LAVA - BAJO
    plano = size + EXTRA_CIMA
    p1, p2 = rnd.uniform(0, TAU), rnd.uniform(0, TAU)

    def borde(a):
        return size * (1.1 + 0.08 * math.sin(2 * a + p1) + 0.06 * math.sin(3 * a + p2)) + FLARE

    n_espolones = 4 if size > 30 else 3
    primero = rnd.uniform(0, TAU)
    espolones = [primero + TAU * (k + rnd.uniform(-0.15, 0.15)) / n_espolones for k in range(n_espolones)]

    def angulo(a, b):
        return abs((a - b + math.pi) % TAU - math.pi)

    def borde_total(a):
        """El contorno con los espolones: contrafuertes que bajan más lejos, hacia la lava."""
        return borde(a) + ESPOLON * max(0.0, 1 - min(angulo(a, e) for e in espolones) / 0.3)

    def perfil(d, a):
        """Liso para los canales: cae rápido desde el borde de la cima hasta la lava."""
        t = min(max((d - plano) / (borde_total(a) - plano), 0.0), 1.0)
        return top - CORTE - t ** 0.5 * (alto - CORTE - 0.6), t

    n_canales = 3 if size > 30 else 2
    canales = [e + TAU / n_espolones / 2 for e in espolones[:n_canales]]
    grietas = [e + TAU / n_espolones / 2 for e in espolones[n_canales:]] + \
        [e + rnd.uniform(0.35, 0.55) for e in espolones]

    def en_ranura(d, a, lista, ancho, hasta):
        if d <= plano or d > hasta(a):
            return False
        for c in lista:
            da = (a - c + math.pi) % TAU - math.pi
            if abs(da) < math.pi / 2 and abs(d * math.sin(da)) < ancho:
                return True
        return False

    def hasta_grieta(a):
        return plano + (borde_total(a) - plano) * 0.75

    for x, y in hexagonos(size * 1.25 + FLARE + ESPOLON + 1, C):
        d, a = math.hypot(x, y), math.atan2(y, x)
        if d > borde_total(a) or en_ranura(d, a, canales, 2.4, borde_total) or \
                en_ranura(d, a, grietas, 1.6, hasta_grieta):
            continue
        base = V((cx + x, cy + y, 0))
        if d <= plano:
            z = top if rnd.random() < 0.4 else top - rnd.uniform(0.08, 0.5)
            adentro = d < plano - 2 * C  # sus costados no se ven: solo la tapa
            m.columna(base + Z * (z - CORTE), CORTE, C * JUNTA, rnd.choice(PIEDRA), rnd.choice(TAPAS), solo_tapa=adentro)
            continue
        t = (d - plano) / (borde_total(a) - plano)
        if t < 0.45:  # el muro: casi a ras de la cima, con algún tajo hondo
            z = top - CORTE - rnd.uniform(0, 1.5)
            if rnd.random() < 0.18:
                z -= rnd.uniform(4, alto * 0.5)
        elif t < 0.75:  # salientes a media altura
            z = top - alto * rnd.uniform(0.3, 0.58)
        else:  # el pie, saliendo de la lava
            z = LAVA + rnd.uniform(0.6, max(alto * 0.28, 1.5))
        z = max(z, LAVA + 0.6)
        color = "caliente" if t > 0.6 and rnd.random() < 0.45 else rnd.choice(PIEDRA)
        afuera = V((x, y, 0)).normalized()
        eje = (Z + afuera * rnd.uniform(0, 0.08) * t).normalized()
        largo = (z - fondo) / eje.z
        m.columna(base + Z * fondo, largo, C * JUNTA, color, rnd.choice(("cima", "cima2", "basalto2")), eje=eje)
        if t > 0.4 and rnd.random() < 0.25:  # un tambor roto, torcido, encima
            arriba = base + Z * fondo + eje * largo
            torcido = (Z + V((rnd.uniform(-1, 1), rnd.uniform(-1, 1), 0)) * 0.35).normalized()
            m.columna(arriba - Z * 0.3, rnd.uniform(1.2, 2.0), C * 0.85, color, "cima", eje=torcido)
    # Núcleo: lo que se ve en las juntas de la cima.
    m.columna(V((cx, cy, fondo)), top - 0.9 - fondo, plano + 0.5, "obsidiana", "obsidiana", lados=16, giro=0.0)
    for c in canales:
        canal(m, l, cx, cy, c, perfil, borde_total, plano)
    for g in grietas:
        grieta(m, l, cx, cy, g, top, alto, plano, borde_total)
    for e in espolones:
        salientes(m, rnd, cx, cy, e, top, alto, plano, borde_total)
    satelites(m, rnd, cx, cy, top, alto, fondo, borde_total, canales)
    pie(m, rnd, cx, cy, borde_total)
    # Cristales en los salientes de los espolones.
    for k in range(2 if size > 30 else 1):
        a = espolones[k] + 0.12
        d = plano + (borde_total(a) - plano) * 0.6
        afuera = V((math.cos(a), math.sin(a), 0))
        racimo(l, m, V((cx, cy, 0)) + afuera * d + Z * (top - alto * 0.3), afuera * 0.9 + Z, rnd.uniform(0.85, 1.0),
               rnd, color="lava", pie="obsidiana")


ESPOLON = 9.0  # cuánto más lejos llegan los contrafuertes


def grieta(m, l, cx, cy, a, top, alto, plano, borde_total):
    """Grieta vertical en el muro: una lámina de lava al fondo de la ranura, de la cima a media
    altura, y de ahí una cinta que baja hasta el lago."""
    afuera = V((math.cos(a), math.sin(a), 0))
    lado = V((-afuera.y, afuera.x, 0))
    centro = V((cx, cy, 0))
    fondo_ranura = centro + afuera * (plano + 3.4)
    medio = top - alto * 0.62
    g = Matrix((afuera, lado, Z)).transposed()
    arriba = top - 2.9
    l.bloque(fondo_ranura + Z * (arriba + medio) / 2, (0.5, 2.6, arriba - medio), "lava", g)
    m.bloque(fondo_ranura - afuera * 1.0 + Z * (arriba + medio) / 2, (1.6, 4.2, arriba - medio + 1), "caliente", g)
    p = fondo_ranura + Z * medio
    q = centro + afuera * (borde_total(a) + 3) + Z * (LAVA - 0.3)
    estira = (q - p).normalized() * 0.5
    l.barra(p - estira, q + estira, 2.2, 0.9, "lava")
    m.barra(p - estira - Z * 1.8, q + estira - Z * 1.8, 3.6, 3.0, "caliente")


def salientes(m, rnd, cx, cy, a, top, alto, plano, borde_total):
    """Losas que sobresalen del espolón a media altura, recostadas hacia la lava."""
    for k in range(2):
        aa = a + rnd.uniform(-0.12, 0.12)
        afuera = V((math.cos(aa), math.sin(aa), 0))
        d = plano + (borde_total(aa) - plano) * rnd.uniform(0.45, 0.7)
        z = top - alto * rnd.uniform(0.35, 0.55)
        largo = rnd.uniform(8, 12)
        m.bloque(V((cx, cy, 0)) + afuera * (d + largo * 0.3) + Z * z, (largo, rnd.uniform(4.5, 6.5), rnd.uniform(2.4, 3.4)),
                 rnd.choice(("basalto3", "obsidiana2", "basalto")), ejes(aa, rnd.uniform(0.08, 0.2)))


def satelites(m, rnd, cx, cy, top, alto, fondo, borde_total, canales):
    """Columnas sueltas que salen de la lava alrededor del peñón (rompen el contorno redondo)."""
    puestas = 0
    for _ in range(40):
        if puestas >= 5:
            break
        a = rnd.uniform(0, TAU)
        if any(abs((a - c + math.pi) % TAU - math.pi) < 0.35 for c in canales):
            continue
        puestas += 1
        d = borde_total(a) + rnd.uniform(3, 8)
        centro = V((cx + math.cos(a) * d, cy + math.sin(a) * d, fondo))
        for j in range(rnd.randint(2, 4)):
            off = V((rnd.uniform(-1, 1), rnd.uniform(-1, 1), 0)) * 3.2 if j else V((0, 0, 0))
            z = LAVA + alto * rnd.uniform(0.25, 0.6) * (1 if j == 0 else 0.6)
            eje = (Z + V((rnd.uniform(-1, 1), rnd.uniform(-1, 1), 0)) * 0.06).normalized()
            m.columna(centro + off, (z - fondo) / eje.z, rnd.uniform(2.2, 3.0), rnd.choice(PIEDRA),
                      rnd.choice(("cima", "cima2")), eje=eje, giro=rnd.uniform(0, TAU))


def canal(m, l, cx, cy, a, perfil, borde, plano):
    """La lava que baja por una grieta de la ladera, del borde de la cima al lago, 1.6 bajo
    las columnas de al lado: lecho oscuro y cinta de Neon encima."""
    afuera = V((math.cos(a), math.sin(a), 0))
    centro = V((cx, cy, 0))
    camino = []
    desde = plano + 0.8
    for k in range(7):
        d = desde + (borde(a) - desde) * k / 6
        z, _ = perfil(d, a)
        camino.append(centro + afuera * d + Z * max(z - 1.6, LAVA - 0.2))
    camino.append(centro + afuera * (borde(a) + 4) + Z * (LAVA - 0.3))
    for p, q in zip(camino, camino[1:]):
        estira = (q - p).normalized() * 0.5
        l.barra(p - estira, q + estira, 2.6, 1.0, "lava")
        m.barra(p - estira - Z * 2.0, q + estira - Z * 2.0, 4.0, 3.2, "caliente")
    l.bloque(camino[0] + Z * 0.4, (2.2, 2.2, 1.2), "lava")  # de donde brota


def pie(m, rnd, cx, cy, borde):
    """Costra a la altura de la lava (discos corridos, no un círculo) y cascajo medio hundido."""
    for k in range(9):
        a = TAU * (k + rnd.uniform(-0.3, 0.3)) / 9
        r = borde(a) + rnd.uniform(-1, 3)
        p = V((cx + math.cos(a) * r, cy + math.sin(a) * r, LAVA - 0.5))
        m.columna(p, 0.8 + rnd.uniform(0, 0.3), rnd.uniform(4, 7), rnd.choice(("costra", "costra2", "caliente")),
                  lados=7, giro=rnd.uniform(0, TAU))
    for k in range(7):
        a = rnd.uniform(0, TAU)
        r = borde(a) + rnd.uniform(1, 5)
        s = rnd.uniform(2.5, 5.5)
        g = (Matrix.Rotation(rnd.uniform(0, TAU), 3, "Z") @ Matrix.Rotation(rnd.uniform(-0.6, 0.6), 3, "X"))
        m.bloque((cx + math.cos(a) * r, cy + math.sin(a) * r, LAVA + s * 0.1), (s, s * 0.8, s * 0.7),
                 rnd.choice(("basalto3", "caliente", "obsidiana")), g)


# --- El nido (LairNest) ------------------------------------------------------------------
# Huevos: x, z del mundo desde el centro del nido, alto y color.
HUEVOS = ((0, 1.2, 7.6, "cascara"), (3.7, -1.2, 6.4, "cascara2"), (-3.6, -1.0, 6.2, "cascara3"))
BORDE_NIDO = 8.0


def centro_nido(perch):
    cima, _ = perch_top(perch)
    dx, _, dz = NIDO_OFFSET
    return cima + V((dx, -dz, 0))


def nido(m, l, centro, semilla=23):
    rnd = random.Random(semilla)
    c = V(centro)
    m.columna(c - Z * 0.05, 0.65, BORDE_NIDO + 0.6, "ceniza", "ceniza2", lados=14, giro=0.0)  # cama de ceniza
    l.columna(c + Z * 0.5, 0.2, BORDE_NIDO - 2.5, "lava", lados=12, giro=0.0)  # brasas
    for k in range(14):  # piedras quemadas del borde, inclinadas hacia afuera
        a = TAU * k / 14
        p = c + V((math.cos(a), math.sin(a), 0)) * BORDE_NIDO + Z * 1.1
        m.bloque(p, (2.4, rnd.uniform(3.8, 4.8), rnd.uniform(2.2, 3.0)), "obsidiana2" if k % 3 == 0 else "carbon",
                 ejes(a, math.radians(20)))
    for k in range(8):  # huesos cruzados sobre el borde
        a = TAU * k / 8 + rnd.uniform(-0.2, 0.2)
        medio = c + V((math.cos(a), math.sin(a), 0)) * (BORDE_NIDO + 0.3) + Z * 2.6
        largo = V((-math.sin(a), math.cos(a), rnd.uniform(-0.2, 0.2))) * rnd.uniform(2, 3.2)
        m.barra(medio - largo, medio + largo, 0.6, 0.6, "hueso" if k % 2 == 0 else "carbon")
    for x, z, alto, color in HUEVOS:
        huevo(m, l, c + V((x, -z, 0)), alto, color, rnd)
    abierto(m, l, c + V((0.6, 5.4, 0)), rnd)
    for _ in range(6):  # cáscaras sueltas
        a, r = rnd.uniform(0, TAU), rnd.uniform(4, 11)
        g = Matrix.Rotation(rnd.uniform(0, TAU), 3, "Z") @ Matrix.Rotation(rnd.uniform(-0.4, 0.4), 3, "X")
        m.bloque(c + V((math.cos(a) * r, math.sin(a) * r, 0.75)), (1.6, 1.2, 0.25), rnd.choice(("cascara", "cascara2")), g)


def huevo(m, l, base, alto, color, rnd):
    a, b = alto * 0.35, alto * 0.5
    giro = (Matrix.Rotation(rnd.uniform(0, TAU), 3, "Z") @ Matrix.Rotation(rnd.uniform(-0.15, 0.15), 3, "X"))
    centro = base + Z * (0.6 + b * 0.9)
    m.esfera(centro, (a, a, b), color, sub=2, giro=giro)

    def superficie(phi, v, k=1.0):
        anillo = a * k * math.sqrt(max(1 - v * v, 0))
        local = V((math.cos(phi) * anillo, math.sin(phi) * anillo, v * b * k))
        normal = V((local.x / (a * a), local.y / (a * a), local.z / (b * b))).normalized()
        return centro + giro @ local, (giro @ normal).normalized()

    for k in range(4):  # manchas
        p, n = superficie(k * 1.7 + rnd.uniform(0, 0.6), rnd.uniform(-0.4, 0.6))
        m.columna(p - n * 0.15, 0.3, alto * rnd.uniform(0.07, 0.1), "mancha" if k % 2 == 0 else "mancha2", eje=n)
    for k in range(2):  # grietas de fuego en zigzag
        phi = k * math.pi + rnd.uniform(-0.5, 0.5)
        antes, _ = superficie(phi, 0.55, 1.02)
        for paso in range(1, 4):
            phi += rnd.uniform(-0.35, 0.35)
            p, n = superficie(phi, 0.55 - paso * 0.3, 1.02)
            l.barra(antes, p, 0.3, 0.2, "lava", arriba=n)
            antes = p


def abierto(m, l, base, rnd):
    """El huevo abierto: la base rota de la cáscara con su resplandor."""
    for k in range(7):
        a = TAU * k / 7
        alto = rnd.uniform(1.3, 2.6)
        p = base + V((math.cos(a), math.sin(a), 0)) * 2.1 + Z * (0.6 + alto / 2)
        m.bloque(p, (0.3, 1.9, alto), ("cascara", "cascara2", "cascara3")[k % 3], ejes(a, math.radians(14)))
    l.columna(base + Z * 0.55, 0.4, 1.9, "lava", lados=10, giro=0.0)
