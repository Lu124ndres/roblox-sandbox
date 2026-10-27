r"""
Hábitat del DragonMarino: lo FIJO, de la orilla del lago de lava al acantilado.
    orilla      seis peñascos de columnas que salen del lago (r >= 124.5: el santuario del
                descanso sube por dentro), costra encendida sobre la playa (r 134 a 150, apoyada
                en el fondo: sin lava no flota nada), columnas caídas y cascajo en la repisa;
    fumarolas   tres conos de ceniza con la boca de lava (el juego pone el fuego arriba);
    esqueleto   un dragón antiguo tirado en la repisa, con escamas mudadas alrededor;
    cristales   los racimos de la repisa (LairCrystals);
    agujas      tres agujas de basalto (hasta Y 38 a 48) con cristales en la punta: la silueta alta
                del anillo, lejos de los peñones, los ríos y las bocas;
    cascadas    las de LairFalls con el mismo recorrido (grieta, caída, charco, río y derrame).
Todo se apoya en el fondo del contrato (piso) y deja libres las rocas que suben, las bocas de
los géiseres (LairVents), los ríos y la puerta.
"""
import math, random
from mathutils import Matrix, Vector
from habitat_dragonmarino_malla import (AGUJAS, ARCO, CASCADAS, CRANEO, CRISTALES, DROP, ESQUELETO, FALL, FLARE,
                                        FUMAROLAS, GAP, LAVA, PENASCOS, PERCHES, PIEDRA, RIVER, TAU, V, VENTS, en,
                                        girar_al_azar, hexagonos, lado_de, perch_top, piso, racimo, radio_de)

Z = V((0, 0, 1))
SANTUARIO = 124.5  # nada fijo más adentro (contrato: r < 124 con Y > -84)


def zonas():
    """Lugares que el cascajo y las columnas caídas no pisan: (x, y, radio) en Blender."""
    z = []
    for perch in PERCHES:
        cima, size = perch_top(perch)
        z.append((cima.x, cima.y, size * 1.25 + FLARE + 6))
    for a, r in VENTS:
        p = en(a, r, 0)
        z.append((p.x, p.y, 14))
    for a in CASCADAS:
        for r, desvio in RIVER:
            p = en(a, r, 0) + lado_de(a) * desvio
            z.append((p.x, p.y, 8))
        for r in DROP + FALL:
            p = en(a, r, 0)
            z.append((p.x, p.y, 7))
    for a, r, e in FUMAROLAS:
        p = en(a, r, 0)
        z.append((p.x, p.y, 9 * e + 4))
    for a, r, _ in CRISTALES:
        p = en(a, r, 0)
        z.append((p.x, p.y, 8))
    for a, r, radio, _ in PENASCOS:
        p = en(a, r, 0)
        z.append((p.x, p.y, radio * 1.2 + 3))
    p = en(*ESQUELETO, 0)
    z.append((p.x, p.y, 36))
    for a, r, _ in AGUJAS:
        p = en(a, r, 0)
        z.append((p.x, p.y, 13))
    p = en(CRANEO[0], CRANEO[1] - 16, 0)  # la mandíbula y el charco del cráneo
    z.append((p.x, p.y, 18))
    for a in ARCO[:2]:
        p = en(a, ARCO[2], 0)
        z.append((p.x, p.y, 10))
    return z


def libre(p, zs, margen=0.0):
    return all(math.hypot(p.x - x, p.y - y) > r + margen for x, y, r in zs)


def normal_piso(p):
    """Normal del fondo en p (el cuenco sube hacia afuera)."""
    r = radio_de(p)
    pendiente = piso(r + 0.5) - piso(r - 0.5)
    afuera = V((p.x, p.y, 0)).normalized()
    return (Z - afuera * pendiente).normalized()


# --- Orilla ------------------------------------------------------------------------------
def penasco(m, ang, rc, radio, cima, rnd):
    """Peñasco de columnas que sale de la lava: cima dentada y las columnas abiertas en abanico."""
    centro = en(ang, rc, 0)
    p1, p2 = rnd.uniform(0, TAU), rnd.uniform(0, TAU)
    abanico = V((rnd.uniform(-1, 1), rnd.uniform(-1, 1), 0)) * 0.06
    c = 3.0
    for x, y in hexagonos(radio * 1.25, c):
        d, a = math.hypot(x, y), math.atan2(y, x)
        borde = radio * (1 + 0.12 * math.sin(2 * a + p1) + 0.08 * math.sin(3 * a + p2))
        if d > borde:
            continue
        p = centro + V((x, y, 0))
        rp = radio_de(p)
        if rp - c < SANTUARIO:
            continue
        t = d / borde
        z = cima - t ** 1.6 * (cima - LAVA + 3) - rnd.uniform(0, 3.0)
        fondo = piso(rp - c) - 1.0
        if z < fondo + 1.5:
            continue
        eje = (Z + abanico * (0.5 + t) + V((x, y, 0)).normalized() * 0.05 * t).normalized()
        arriba = V((p.x, p.y, fondo)) + eje * (z - fondo) / eje.z
        if radio_de(arriba) - c < SANTUARIO:
            continue
        color = rnd.choice(PIEDRA) if z > LAVA + 2 else rnd.choice(("caliente", "caliente2", "basalto3"))
        m.columna(V((p.x, p.y, fondo)), (z - fondo) / eje.z, c * 0.92, color, rnd.choice(("cima", "cima2", "basalto2")),
                  eje=eje)


def costra(m, b, rnd, zs):
    """La playa de lava (r 134 a 150): placas de costra sobre el fondo y grietas encendidas."""
    for k in range(70):
        a = rnd.uniform(0, 360)
        r = rnd.uniform(134.5, 150)
        p = en(a, r, 0)
        if not libre(p, zs, -3):
            continue
        n = normal_piso(p)
        m.columna(V((p.x, p.y, piso(r) - 0.5)), 0.85, rnd.uniform(3, 5.5), rnd.choice(("costra", "costra2", "caliente2")),
                  lados=7, giro=rnd.uniform(0, TAU), eje=n)
        if rnd.random() < 0.55:  # una grieta encendida al costado
            q = en(a + rnd.uniform(-2.5, 2.5), r + rnd.uniform(3, 6), 0)
            pa, pb = V((p.x, p.y, piso(r) + 0.05)), V((q.x, q.y, piso(radio_de(q)) + 0.05))
            b.barra(pa, pb, rnd.uniform(0.5, 0.9), 0.5, "lava", arriba=n)


def caidas(m, rnd, zs):
    """Columnas caídas en la repisa, enteras o partidas, y cascajo."""
    puestas = 0
    for _ in range(200):
        if puestas >= 12:
            break
        a, r = rnd.uniform(0, 360), rnd.uniform(152, 184)
        p = en(a, r, 0)
        if not libre(p, zs, 4):
            continue
        puestas += 1
        radio = rnd.uniform(2.4, 3.2)
        rumbo = rnd.uniform(0, TAU)
        eje = V((math.cos(rumbo), math.sin(rumbo), rnd.uniform(-0.08, 0.12))).normalized()
        largo = rnd.uniform(7, 15)
        z = piso(r) + radio * 0.6
        partes = 2 if rnd.random() < 0.5 else 1
        tramo = largo / partes
        for k in range(partes):
            inicio = V((p.x, p.y, z)) + eje * (k * (tramo + 0.8) - largo / 2)
            torcido = (eje + V((0, 0, rnd.uniform(-0.1, 0.1)))).normalized()
            m.columna(inicio, tramo, radio, rnd.choice(PIEDRA), "cima", eje=torcido, fondo=True,
                      giro=rnd.uniform(0, TAU))
        zs.append((p.x, p.y, largo / 2 + 2))
    for _ in range(260):
        a, r = rnd.uniform(0, 360), rnd.uniform(146, 188)
        p = en(a, r, 0)
        if not libre(p, zs, 1):
            continue
        s = rnd.uniform(1.4, 4.2)
        m.bloque((p.x, p.y, piso(r) + s * 0.15), (s, s * rnd.uniform(0.6, 1), s * rnd.uniform(0.4, 0.8)),
                 rnd.choice(PIEDRA + ("ceniza", "obsidiana")), girar_al_azar(rnd, 0.4))


def fumarola(m, b, ang, r, e, rnd):
    """Cono de ceniza con la boca de lava (Habitats: Fumarola). Devuelve dónde va el fuego."""
    base = en(ang, r, piso(r) - 1.0)
    perfil = [(9 * e, 0), (7.4 * e, 2.4 * e + 1), (5.2 * e, 6 * e + 1), (3.6 * e, 9 * e + 1), (3.2 * e, 10 * e + 1)]
    m.torno(base, perfil, 12, ("ceniza", "ceniza2", "ceniza", "basalto2"), giro=rnd.uniform(0, 1), ruido=0.06, rnd=rnd)
    boca = base + Z * (10 * e + 1)
    b.columna(boca - Z * 0.3, 0.45, 2.6 * e, "lava", lados=12, giro=0.0)
    for k in range(5):  # chorreadas de lava por la ladera
        a = TAU * k / 5 + 0.3
        pts = [base + V((math.cos(a) * rr * e, math.sin(a) * rr * e, z * e + 1 + 0.15))
               for rr, z in ((3.3, 9.6), (4.6, 7.4), (6.0, 4.6), (7.8, 1.6), (8.8, 0.2))]
        b.tubo(pts, [0.7 * e, 0.6 * e, 0.5 * e, 0.4 * e, 0.3 * e], 4, "lava")
    for k in range(6):
        a = TAU * k / 6 + rnd.uniform(-0.2, 0.2)
        p = base + V((math.cos(a), math.sin(a), 0)) * 9.6 * e
        q = V((p.x, p.y, piso(radio_de(p)) + 0.4))
        m.esfera(q, (2.0 * e, 1.8 * e, 1.3 * e), rnd.choice(("obsidiana", "basalto3")), sub=1, rnd=rnd, ruido=0.2,
                 giro=Matrix.Rotation(rnd.uniform(0, TAU), 3, "Z"))
    return boca


def esqueleto(m, rnd, largo=62.0):
    """Esqueleto de un dragón antiguo tirado en la repisa: espina en arco, costillas que se apoyan
    en el fondo, cráneo con cuernos al frente y la cola que se pierde en la ceniza."""
    ang, r = ESQUELETO
    centro = en(ang, r, 0)
    t = lado_de(ang)  # a lo largo del esqueleto
    afuera = V((centro.x, centro.y, 0)).normalized()
    lado = t.cross(Z)
    base = piso(r)
    espina = [centro + t * (-largo / 2 + largo * i / 12) + Z * (base + 1.6 + 8.5 * math.sin(math.pi * i / 12))
              for i in range(13)]
    m.tubo(espina, [1.2 + 0.8 * math.sin(math.pi * i / 12) for i in range(13)], 7, "hueso2")
    for i, p in enumerate(espina[1:-1], 1):
        m.columna(p, 3.4 + 1.2 * math.sin(math.pi * i / 12), 0.7, "hueso3", eje=(Z - t * 0.3).normalized(), arriba=0.15,
                  lados=4)
    for i in range(2, 11):
        s = i / 12
        p = espina[i]
        ancho = 5 + 8 * math.sin(math.pi * s)
        for signo in (-1, 1):
            pts = []
            for j in range(8):
                u = j / 7
                q = p + afuera * signo * (0.8 + ancho * math.sin(math.pi * u / 2)) + t * 1.2 * u
                suelo = piso(radio_de(q)) + 0.3
                z = (p.z - base) * (1 - u) + 4.5 * math.sin(math.pi * u) * (1 - 0.3 * u)
                pts.append(V((q.x, q.y, base + z + (suelo - base) * u)))  # la punta apoya en el fondo
            m.tubo(pts, [0.85 - 0.06 * j for j in range(8)], 5, "hueso" if i % 2 else "hueso2")
    # El cráneo, al frente, medio caído sobre la ceniza.
    craneo = espina[-1] + t * 6 + Z * (base + 3.0 - espina[-1].z)
    giro = Matrix((lado, t, Z)).transposed()
    m.esfera(craneo, (4.4, 5.6, 3.4), "hueso", sub=1, giro=giro, rnd=rnd, ruido=0.08)
    m.tubo([craneo + t * 3, craneo + t * 7.5 - Z * 0.6, craneo + t * 11 - Z * 1.2], [3.0, 2.2, 1.2], 6, "hueso2")
    m.bloque(craneo + t * 6.5 - Z * 2.6, (4.2, 9.5, 1.2), "hueso3", giro @ Matrix.Rotation(-0.15, 3, "X"))  # mandíbula
    for s in (-1, 1):
        m.esfera(craneo + lado * s * 2.6 + t * 2.0 + Z * 1.3, (1.3, 1.3, 1.1), "carbon", sub=1)
        m.tubo([craneo + lado * s * 2.4 - t * 1.5 + Z * 2.2, craneo + lado * s * 4.4 - t * 6 + Z * 4.6,
                craneo + lado * s * 4.0 - t * 10.5 + Z * 5.6], [1.0, 0.6, 0.15], 5, "cuerno")
        for k in range(4):  # dientes
            m.cristal(craneo + lado * s * 1.7 + t * (5.5 + k * 1.4) - Z * 1.0, -Z, 0.3, 1.4, "hueso")
    for k in range(6):  # la cola, vértebras que se achican hacia la ceniza
        p = espina[0] - t * (2.5 + k * 2.4)
        s = 2.2 - k * 0.3
        m.bloque(V((p.x, p.y, base + s * 0.25)), (s, s * 1.1, s * 0.8), "hueso2" if k % 2 else "hueso3",
                 Matrix.Rotation(rnd.uniform(-0.3, 0.3), 3, "Z") @ giro)
    escamas(m, rnd, centro, 24, 30)


def escamas(m, rnd, centro, n, alcance):
    """Escamas mudadas del dragón marino: placas hexagonales verde azulado clavadas en la ceniza."""
    for _ in range(n):
        a, d = rnd.uniform(0, TAU), rnd.uniform(4, alcance)
        p = centro + V((math.cos(a) * d, math.sin(a) * d, 0))
        rp = radio_de(p)
        if rp < 150 or rp > 186:
            continue
        eje = (Z + V((rnd.uniform(-1, 1), rnd.uniform(-1, 1), 0)) * rnd.uniform(0.6, 1.6)).normalized()
        radio = rnd.uniform(1.8, 3.4)
        m.columna(V((p.x, p.y, piso(rp) - radio * 0.35)), 0.55, radio, rnd.choice(("escama", "escama2", "escama3")),
                  rnd.choice(("escama3", "escama")), eje=eje, fondo=True, giro=rnd.uniform(0, TAU))


def orilla(m, b1, b2, rnd):
    """Todo lo de la orilla y la repisa. Devuelve (luces, fuegos) en coordenadas del mundo."""
    zs = zonas()
    for k, (a, r, radio, cima) in enumerate(PENASCOS):
        penasco(m, a, r, radio, cima, random.Random(70 + k))
    costra(m, b1, rnd, zs)
    caidas(m, rnd, zs)
    esqueleto(m, rnd)
    luces, fuegos = [], []
    for a, r, e in FUMAROLAS:
        boca = fumarola(m, b1, a, r, e, rnd)
        fuegos.append({"pos": mundo(boca + Z * 0.6), "tam": round(5 * e, 1)})
        luces.append({"pos": mundo(boca + Z * 4), "color": [255, 98, 22], "rango": 26})
    for k, (a, r, e) in enumerate(CRISTALES):
        base = en(a, r, piso(r) - 0.4)
        racimo(b2, m, base, Z + V((rnd.uniform(-1, 1), rnd.uniform(-1, 1), 0)) * 0.15, e, rnd)
        if k % 2 == 0:
            luces.append({"pos": mundo(base + Z * 6), "color": [255, 176, 64], "rango": 20})
    for k, (a, r, punta) in enumerate(AGUJAS):
        tip = aguja(m, b1, b2, a, r, punta, random.Random(90 + k))
        luces.append({"pos": mundo(tip + Z * 4), "color": [255, 176, 64], "rango": 30})
    return luces, fuegos


def aguja(m, b1, b2, ang, r, punta, rnd):
    """Aguja de basalto: un haz de columnas que se afina hacia arriba (la del medio llega a
    `punta`, el anillo a media altura y otro bajo al pie), algo inclinada, con una veta de lava
    que baja por un costado y un racimo de cristales en la punta. Devuelve la punta."""
    centro = en(ang, r, 0)
    suelo = piso(r) - 1.0
    inclina = V((rnd.uniform(-1, 1), rnd.uniform(-1, 1), 0)).normalized() * 0.07
    eje = (Z + inclina).normalized()
    alto = punta - suelo
    # La del medio: tres tramos que se afinan.
    tramos = ((0.0, 0.55, 3.0, 2.7), (0.55, 0.82, 2.5, 2.0), (0.82, 1.0, 1.9, 1.1))
    for desde, hasta, r0, r1 in tramos:
        base = V((centro.x, centro.y, suelo)) + eje * (alto * desde / eje.z)
        m.columna(base, alto * (hasta - desde) / eje.z, r0, rnd.choice(PIEDRA), "cima", arriba=r1,
                  eje=eje, giro=rnd.uniform(0, TAU))
    for k in range(6):  # el anillo del medio
        a = TAU * k / 6 + rnd.uniform(-0.15, 0.15)
        off = V((math.cos(a), math.sin(a), 0)) * 4.6
        h = alto * rnd.uniform(0.35, 0.7)
        e2 = (eje + off.normalized() * 0.04).normalized()
        m.columna(V((centro.x, centro.y, suelo)) + off, h / e2.z, rnd.uniform(2.1, 2.6), rnd.choice(PIEDRA),
                  rnd.choice(("cima", "cima2")), eje=e2, giro=rnd.uniform(0, TAU))
    for k in range(9):  # el pie
        a = TAU * k / 9 + rnd.uniform(-0.2, 0.2)
        off = V((math.cos(a), math.sin(a), 0)) * rnd.uniform(8, 10)
        p = centro + off
        s = piso(radio_de(p)) - 1.0
        m.columna(V((p.x, p.y, s)), rnd.uniform(2, alto * 0.22), rnd.uniform(1.8, 2.5), rnd.choice(PIEDRA),
                  rnd.choice(("cima", "cima2", "basalto2")), giro=rnd.uniform(0, TAU))
    tip = V((centro.x, centro.y, suelo)) + eje * (alto / eje.z)
    racimo(b2, m, tip - eje * 0.8, eje, 1.5, rnd)
    # Veta de lava por el costado de la del medio, de la punta al pie.
    lado = V((math.cos(rnd.uniform(0, TAU)), math.sin(rnd.uniform(0, TAU)), 0)).normalized()
    pts = []
    for k in range(6):
        t = k / 5
        z = alto * (0.92 - 0.9 * t)
        radio = 1.3 + (2.9 - 1.3) * (1 - z / alto)
        giro = Matrix.Rotation(0.5 * t, 3, "Z")
        pts.append(V((centro.x, centro.y, suelo)) + eje * (z / eje.z) + (giro @ lado) * (radio + 0.15))
    b1.tubo(pts, [0.45, 0.5, 0.55, 0.55, 0.5, 0.4], 4, "lava")
    return tip


def mundo(p):
    """Blender -> mundo relativo al centro del cráter (dx, y, dz)."""
    return [round(p.x, 2), round(p.z, 2), round(-p.y, 2)]


# --- Cascadas ----------------------------------------------------------------------------
def cascadas(m, b1):
    """Las cascadas de LairFalls, mismo recorrido: grieta en la pared, caída pegada a ella,
    charco al pie, río serpenteando por la repisa y derrame hasta la lava."""
    def tramo(a, b, ancho):
        estira = (b - a).normalized() * 0.6  # un poco más largo: sin huecos en los codos
        b1.barra(a - estira, b + estira, ancho, 1.2, "lava")

    for ang in CASCADAS:
        afuera = en(ang, 1, 0)
        lado = lado_de(ang)
        giro = Matrix((lado, afuera, Z)).transposed()
        fuente = en(ang, FALL[0] - GAP, piso(FALL[0]) + 1)
        b1.bloque(fuente + afuera * 1.2, (9, 2, 5), "lava", giro)  # la grieta encendida
        m.bloque(fuente + afuera * 2.0 + Z * 0.2, (13, 2.5, 7), "costra", giro)
        antes = fuente
        for k in range(1, len(FALL)):
            sigue = en(ang, FALL[k] - GAP, piso(FALL[k]) + 0.4)
            tramo(antes, sigue, 6 + (k + 1) * 0.5)
            antes = sigue
        charco = en(ang, RIVER[0][0], piso(RIVER[0][0]))
        tramo(antes, charco + Z * 0.25, 7.5)
        b1.columna(charco - Z * 0.6, 1.0, 6, "lava", lados=12, giro=0.0)
        antes = charco + Z * 0.25
        for r, desvio in RIVER[1:]:
            sigue = en(ang, r, piso(r) + 0.25) + lado * desvio
            tramo(antes, sigue, 6.5)
            antes = sigue
        for k, r in enumerate(DROP[1:], 1):
            y = LAVA if k == len(DROP) - 1 else piso(r) + 1.2
            sigue = en(ang, r, y) + lado * RIVER[-1][1]
            tramo(antes, sigue, 6)
            antes = sigue
