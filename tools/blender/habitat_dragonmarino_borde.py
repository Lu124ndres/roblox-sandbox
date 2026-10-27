r"""
Hábitat del DragonMarino: el acantilado y sus dos protagonistas (fijo, malla 2).
    acantilado  columnas pegadas a la pared, por grupos de alturas muy distintas (bajos, medios
                y altos, con el más alto al medio o corrido a un lado), huecos donde se ve la
                pared y derrumbes (columnas partidas y tambores caídos al pie). Nunca sobre
                Y = 29 ni más afuera de r 202. Libres: la puerta, las cascadas y el cráneo;
    cráneo      un cráneo de dragón colosal tallado en la roca, frente a la puerta (90°): cuernos
                que se recuestan en la pared, cuencas con cristales de fuego, mandíbula abierta
                apoyada en la repisa y lava que le cae de la boca;
    arco        un arco de basalto sobre la repisa (127° a 143°, r 176), con una veta de lava
                por debajo;
    cristales   tres racimos en el acantilado (60°, 200°, 345°).
"""
import math, random
from mathutils import Matrix, Vector
from habitat_dragonmarino_malla import (ARCO, CASCADAS, CRANEO, CRISTALES_PARED, PIEDRA, PUERTA, PUERTA_HUECO, TAU, V,
                                        dif, ejes, en, piso, racimo, radio_de)

Z = V((0, 0, 1))
TOPE = 29.0
C = 3.3
FRENTE, ATRAS, BAJA = 192.4, 198.6, 187.6  # radios de las tres filas
CRANEO_HUECO = 9  # grados libres a cada lado del cráneo


def libre_pared(a):
    return (dif(a, PUERTA) >= PUERTA_HUECO and all(dif(a, x) >= 5 for x in CASCADAS)
            and dif(a, CRANEO[0]) >= CRANEO_HUECO)


def columna_pared(m, rnd, a, r, z, c=C):
    z = min(z, TOPE)
    fondo = piso(r - c) - 1.5
    if z < fondo + 1:
        return
    m.columna(en(a, r, fondo), z - fondo, c * 0.93, rnd.choice(PIEDRA), rnd.choice(("cima", "cima2", "basalto2")),
              giro=-math.radians(a) + math.pi / 6)


def acantilado(m, b2, rnd):
    """Recorre la pared de la puerta a la puerta armando grupos, huecos y derrumbes."""
    paso = math.degrees(math.sqrt(3) * C / FRENTE)
    a = PUERTA + PUERTA_HUECO
    fin = PUERTA - PUERTA_HUECO + 360
    while a < fin:
        tipo = rnd.choices(("grupo", "hueco", "derrumbe"), (0.62, 0.16, 0.22))[0]
        n = rnd.randint(3, 9) if tipo == "grupo" else rnd.randint(1, 3) if tipo == "hueco" else rnd.randint(2, 4)
        nivel = rnd.choice(((0.05, 0.3), (0.35, 0.6), (0.7, 1.0), (0.7, 1.0)))
        nivel = rnd.uniform(*nivel)
        pico = rnd.uniform(0.2, 0.8)  # dónde queda la más alta del grupo
        for i in range(n):
            ai = a + i * paso
            if ai >= fin:
                break
            if not libre_pared(ai) or tipo == "hueco":
                continue
            u = i / max(n - 1, 1)
            if tipo == "grupo":
                h = min(max(nivel * (1 - 0.7 * abs(u - pico)) + rnd.uniform(-0.08, 0.08), 0.02), 1)
                columna_pared(m, rnd, ai + paso * 0.5, ATRAS + rnd.uniform(-0.4, 0.4), 13 + 16 * h)
                if rnd.random() < 0.8:
                    columna_pared(m, rnd, ai, FRENTE + rnd.uniform(-0.4, 0.4), 1 + 26 * h * rnd.uniform(0.55, 1.0))
                if h < 0.45 and rnd.random() < 0.5:
                    columna_pared(m, rnd, ai + paso * 0.3, BAJA, -0.5 + 6 * rnd.random(), 2.8)
            else:  # derrumbe: muñones partidos y lo que se cayó
                columna_pared(m, rnd, ai + paso * 0.5, ATRAS, rnd.uniform(14, 19))
                if rnd.random() < 0.5:
                    columna_pared(m, rnd, ai, FRENTE, rnd.uniform(1, 6))
                for _ in range(2):
                    aa, rr = ai + rnd.uniform(-1, 1), rnd.uniform(182, 189)
                    eje = (Z + V((rnd.uniform(-1, 1), rnd.uniform(-1, 1), 0)) * rnd.uniform(0.6, 2.5)).normalized()
                    m.columna(en(aa, rr, piso(rr) - 0.8), rnd.uniform(3, 7), rnd.uniform(2.4, 3.0), rnd.choice(PIEDRA),
                              "cima", eje=eje, fondo=True, giro=rnd.uniform(0, TAU))
        a += n * paso
    for a, e in CRISTALES_PARED:
        r = 196.0
        base = en(a, r, piso(r) - 0.3)
        adentro = -V((base.x, base.y, 0)).normalized()
        m.bloque(base - Z * 0.6, (8, 8, 2.2), "basalto3", Matrix.Rotation(-math.radians(a), 3, "Z"))
        racimo(b2, m, base + Z * 0.4, adentro * 0.45 + Z, e, rnd)


def craneo(m, b1, b2, rnd):
    """El cráneo colosal tallado en la roca. Devuelve la luz de sus cuencas."""
    ang, r = CRANEO
    o = en(ang, r, 0)
    f = -V((o.x, o.y, 0)).normalized()  # hacia el centro del cráter
    s = f.cross(Z)  # de costado
    g = Matrix((s, f, Z)).transposed()
    roca, roca2 = "hueso3", "ceniza3"
    suelo = piso(r - 18)
    m.esfera(o + f * 1 + Z * 15, (13, 10, 10.5), roca, sub=2, giro=g)  # bóveda, ancha y chata
    m.esfera(o + f * 4 + Z * 10, (12, 8, 5.5), roca2, sub=1, giro=g)  # pómulos
    # Hocico largo y chato de reptil: tres bloques que se afinan y bajan hacia el lago.
    for k, (ancho, alto, adelante, z) in enumerate(((14, 8, 10, 10.5), (11.5, 6.5, 17, 9), (9, 5, 23.5, 7.8))):
        m.bloque(o + f * adelante + Z * z, (ancho, 7.6, alto), roca if k % 2 == 0 else roca2,
                 g @ Matrix.Rotation(-0.1, 3, "X"))
        m.cristal(o + f * adelante + Z * (z + alto / 2 - 0.4), (Z - f * 0.6).normalized(), 1.0, 3.2 - 0.6 * k, "cuerno")
    for lado in (-1, 1):
        m.esfera(o + f * 27 + Z * 9 + s * lado * 2.2, (1.2, 0.9, 0.8), "obsidiana", sub=1)  # narinas
        m.bloque(o + f * 9 + Z * 21 + s * lado * 6.5, (10, 4, 3), roca2, g @ Matrix.Rotation(lado * 0.3, 3, "Y"))  # ceja
        cuenca = o + f * 9.2 + Z * 16.5 + s * lado * 6.0
        m.esfera(cuenca, (3.8, 2.2, 3.0), "obsidiana", sub=1, giro=g)
        racimo(b2, m, cuenca + f * 0.6, f + Z * 0.3 + s * lado * 0.2, 0.55, rnd, pie="obsidiana")
        # Cuernos que se van para atrás y se recuestan en la pared, y un par menor en los pómulos.
        m.tubo([o + Z * 21 + s * lado * 8 + f * 2, o + Z * 24 + s * lado * 12 - f * 3, o + Z * 26 + s * lado * 14 - f * 7,
                o + Z * 26.5 + s * lado * 17 - f * 8], [3.2, 2.4, 1.4, 0.4], 6, "cuerno")
        m.tubo([o + Z * 12 + s * lado * 11 + f * 2, o + Z * 13.5 + s * lado * 16 - f * 2, o + Z * 15 + s * lado * 20 - f * 5],
               [2.0, 1.3, 0.3], 5, "cuerno")
        for k in range(3):  # púas de la mejilla
            m.cristal(o + Z * (9 + k * 2.2) + s * lado * (11.5 - k * 0.5) + f * (3 - k), (s * lado - f * 0.8).normalized(),
                      0.8, 3.5 - 0.6 * k, "cuerno")
        for k in range(5):  # dientes de arriba y de abajo
            arriba = o + f * (12 + 3 * k) + Z * (6.2 - 0.4 * k) + s * lado * (5.4 - 0.6 * k)
            m.cristal(arriba, -Z, 0.9, 4.2 - 0.4 * k, "hueso2")
            abajo = o + f * (13 + 3 * k) + Z * (suelo + 2.6) + s * lado * (4.8 - 0.6 * k)
            m.cristal(abajo, Z, 0.8, 3.4 - 0.3 * k, "hueso2")
    for k in range(3):  # cresta sobre la bóveda
        m.cristal(o + Z * (24 - k * 0.6) + f * (5 - 4 * k), (Z - f * 0.7).normalized(), 1.2, 4.0 - 0.5 * k, "cuerno")
    m.bloque(o + f * 19 + Z * (suelo + 1.2), (12, 22, 3), roca2, g @ Matrix.Rotation(0.05, 3, "X"))  # mandíbula
    m.bloque(o + f * 4 + Z * 3, (16, 8, 8), "basalto3", g)  # la roca de donde sale
    # Lava que le cae de la boca y hace charco en la repisa.
    boca = o + f * 20 + Z * 5.5
    pie_lava = o + f * 22 + Z * (suelo + 2.9)
    b1.barra(boca, pie_lava, 3.2, 1.0, "lava")
    charco = o + f * 27
    b1.columna(V((charco.x, charco.y, piso(radio_de(charco)) - 0.5)), 0.9, 4.5, "lava", lados=12, giro=0.0)
    b1.barra(pie_lava, V((charco.x, charco.y, piso(radio_de(charco)) + 0.3)), 2.4, 0.9, "lava")
    return {"pos": [round(o.x + f.x * 12, 2), round(17.0, 2), round(-(o.y + f.y * 12), 2)], "color": [255, 176, 64],
            "rango": 28}


def arco(m, b1, rnd):
    """Arco de basalto en la repisa: dos patas de columnas y un dintel de dovelas torcidas."""
    a0, a1, r = ARCO
    for a in (a0, a1):
        c = en(a, r, 0)
        for k in range(7):
            off = V((0, 0, 0)) if k == 0 else V((math.cos(TAU * k / 6), math.sin(TAU * k / 6), 0)) * 4.4
            p = c + off
            s = piso(radio_de(p)) - 1.0
            alto = (25.5 if k == 0 else rnd.uniform(9, 22)) - s
            m.columna(V((p.x, p.y, s)), alto, 2.6, rnd.choice(PIEDRA), rnd.choice(("cima", "cima2")),
                      giro=rnd.uniform(0, TAU))
    n = 11
    for k in range(n):
        u = (k + 0.5) / n
        a = a0 + (a1 - a0) * u
        z = 23.0 + 3.0 * math.sin(math.pi * u)
        cuerda = math.radians(a1 - a0) * r / n
        theta = -math.radians(a)
        # Las dovelas siguen la curva: +Y local va hacia ángulos menores, donde el arco baja si u < 0.5.
        pendiente = -math.atan(3.0 * math.pi * math.cos(math.pi * u) / (math.radians(a1 - a0) * r))
        m.bloque(en(a, r, z), (6.0, cuerda + 0.7, 4.4), rnd.choice(("basalto", "basalto3", "obsidiana2", "basalto2")),
                 ejes(theta) @ Matrix.Rotation(pendiente + rnd.uniform(-0.06, 0.06), 3, "X"))
    # Veta encendida por debajo del dintel.
    pts = [en(a0 + (a1 - a0) * (k / 8), r, 23.0 + 3.0 * math.sin(math.pi * k / 8) - 2.3) for k in range(9)]
    for p, q in zip(pts, pts[1:]):
        b1.barra(p, q, 1.2, 0.4, "lava")
