r"""
Lo que viste el fondo y el borde del hábitat de la Orca fantasma: coral muerto blanco,
cadenas, anclas, tablas y redes en la repisa; lápidas en hileras inclinadas y faroles en
postes torcidos a lo largo del borde. Piezas baratas (pocos triángulos), porque son muchas.
"""
import math
from mathutils import Matrix, Vector as V
import habitats as H
from habitats import T
from habitat_orcafantasma_piezas import piso, piso_en, polar, ejes, marco, abierta, tope_nado


def coral(m, ang, r, alto, rnd):
    """Coral muerto de ramas: tronco corto que se abre en ramas que se vuelven a abrir."""
    base = polar(ang, r, piso(r) - 0.6)
    alto = min(alto, tope_nado(r) - base.z - 0.3)
    if alto < 1.5:
        return

    def rama(p, d, largo, grueso, nivel):
        q = p + d * largo
        m.tubo([p, p.lerp(q, 0.5) + V((0, 0, largo * 0.08)), q], [grueso, grueso * 0.8, grueso * 0.55], 4,
               "coralm" if rnd.random() < 0.7 else "coralm2")
        if nivel < 2:
            for _ in range(2):
                a = rnd.uniform(0, 6.28)
                nd = (d + V((math.cos(a), math.sin(a), 0)) * 0.7).normalized()
                rama(q, nd, largo * 0.65, grueso * 0.6, nivel + 1)

    rama(base, V((0, 0, 1)), alto * 0.4, 0.35 * alto ** 0.6, 0)


def domo(m, ang, r, radio, rnd):
    """Coral cerebro muerto: un domo blanco bajo."""
    z = min(piso(r) - radio * 0.15, tope_nado(r) - radio * 0.65)
    m.roca(T(*polar(ang, r, z)), radio, rnd.choice(("coralm", "coralm2")), 1, 0.2, rnd.uniform(0, 9), (1.1, 1.0, 0.6))


def cadena(m, pts, rnd):
    """Cadena tirada en el fondo por los puntos `pts` (xy); cada eslabón son cuatro barras."""
    eslabon = 3.4
    largo = sum((b - a).length for a, b in zip(pts, pts[1:]))
    n = int(largo / eslabon)
    tramo, acum = 0, 0.0
    for k in range(n):
        d = k * eslabon
        while tramo < len(pts) - 2 and acum + (pts[tramo + 1] - pts[tramo]).length < d:
            acum += (pts[tramo + 1] - pts[tramo]).length
            tramo += 1
        a, b = pts[tramo], pts[tramo + 1]
        t = min(1.0, (d - acum) / max(0.01, (b - a).length))
        c = a.lerp(b, t)
        eje = (b - a).normalized()
        c = V((c.x, c.y, piso_en(c) + (0.9 if k % 2 else 0.5)))
        lado = V((0, 0, 1)).cross(eje) if k % 2 == 0 else V((0, 0, 1))
        g = Matrix((eje, lado, eje.cross(lado))).transposed().to_4x4()
        color = "hierro" if k % 2 else "hierro2"
        for sgn in (-1, 1):
            m.caja(T(*(c + lado * sgn * 0.85)) @ g, (eslabon + 0.4, 0.6, 0.6), color)
            m.caja(T(*(c + eje * sgn * (eslabon / 2))) @ g, (0.6, 2.3, 0.6), color)


def ancla(m, M):
    """Ancla de hierro en coordenadas locales (z arriba, 18 de alto)."""
    m.tubo([M @ V((0, 0, 1.0)), M @ V((0, 0, 9.0)), M @ V((0, 0, 17.0))], [0.9, 0.85, 0.8], 6, "hierro")  # caña
    m.caja(M @ T(0, 0, 15.0), (11.0, 1.1, 1.1), "hierro2")  # cepo
    aro = [M @ V((0, 1.9 * math.cos(a), 18.6 + 1.9 * math.sin(a))) for a in [2 * math.pi * k / 10 for k in range(11)]]
    m.tubo(aro, [0.4] * 11, 4, "hierro2")
    brazo = [M @ V((7.5 * math.sin(a), 0, 4.2 - 3.4 * math.cos(a))) for a in [-1.2 + 2.4 * k / 6 for k in range(7)]]
    m.tubo(brazo, [0.8, 0.95, 1.0, 1.1, 1.0, 0.95, 0.8], 6, "hierro")
    for sgn in (-1, 1):  # uñas
        x = 7.5 * math.sin(1.2) * sgn
        m.placa(M @ T(x, 0, 4.2 - 3.4 * math.cos(1.2)) @ H.girar("Y", -0.6 * sgn),
                [(-1.6, -0.6), (1.6, -0.6), (0, 3.4)], 0.5, "hierro2")


def tabla(m, p, rnd):
    largo = rnd.uniform(5, 13)
    z = min(piso_en(p) + 0.35, tope_nado(p.xy.length) - 0.5)
    g = H.girar("Z", rnd.uniform(0, 6.28)) @ H.girar("X", rnd.uniform(-0.15, 0.15)) @ H.girar("Y", rnd.uniform(-0.12, 0.12))
    m.caja(T(p.x, p.y, z) @ g, (largo, rnd.uniform(1.4, 2.2), 0.5), rnd.choice(("madera", "madera2", "madera3", "seco")))


def red(m, ang, r, ancho, rnd):
    """Red de pesca tirada en el fondo: lámina a cuadros de cabo y hueco oscuro, con pliegues."""
    n = 7
    x, y, _ = ejes(ang)
    giro = rnd.uniform(0, 6.28)
    u = x * math.cos(giro) + y * math.sin(giro)
    w = x * -math.sin(giro) + y * math.cos(giro)
    c = polar(ang, r)
    vs = []
    for i in range(n + 1):
        fila = []
        for j in range(n + 1):
            p = c + u * ancho * (i / n - 0.5) + w * ancho * (j / n - 0.5)
            p.z = piso_en(p) + 0.3 + 0.9 * abs(math.sin(i * 1.3 + j * 0.7))
            fila.append(m.v(p))
        vs.append(fila)
    for i in range(n):
        for j in range(n):
            abierta(m, (vs[i][j], vs[i + 1][j], vs[i + 1][j + 1], vs[i][j + 1]), "red" if (i + j) % 2 else "red2")


def lapida(m, M, cruz, rnd):
    """Lápida barata (una placa y un relieve), sin rocas alrededor. 12 de alto a escala 1."""
    if cruz:
        w = 1.2
        cont = [(-w, -1), (w, -1), (w, 7), (3.2, 7), (3.2, 9.2), (w, 9.2), (w, 12), (-w, 12), (-w, 9.2),
                (-3.2, 9.2), (-3.2, 7), (-w, 7)]
        m.placa(M, cont, 2.0, "lapida", "lapida2")
    else:
        cont = [(-3.2, -1), (3.2, -1), (3.2, 7.2)] + \
               [(3.2 * math.cos(math.pi * k / 7), 7.2 + 2.6 * math.sin(math.pi * k / 7)) for k in range(1, 7)] + [(-3.2, 7.2)]
        m.placa(M, cont, 1.6, rnd.choice(("lapida", "lapida2")), "lapida2")
        m.caja(M @ T(0, 0.85, 6.4), (0.6, 0.3, 3.6), "lapida3")
        m.caja(M @ T(0, 0.85, 7.3), (2.2, 0.3, 0.6), "lapida3")
    m.caja(M @ T(0, 0, 0.2), (7.5 if not cruz else 5.0, 3.4, 1.2), "musgo2")


def hilera(m, ang0, ang1, r, escala, rnd):
    """Hilera de lápidas a lo largo del borde, cada una torcida a su modo."""
    n = max(2, int(abs(ang1 - ang0) * math.radians(1) * r / (8.5 * escala)))
    for k in range(n):
        ang = ang0 + (ang1 - ang0) * (k + rnd.uniform(0.3, 0.7)) / n
        rr = r + rnd.uniform(-1.2, 1.2)
        M = marco(ang, rr, piso(rr) - 1.2, escala * rnd.uniform(0.85, 1.1), rnd.uniform(-14, 14))
        M = M @ H.girar("X", rnd.uniform(-0.28, 0.2)) @ H.girar("Y", rnd.uniform(-0.3, 0.3))
        lapida(m, M, rnd.random() < 0.35, rnd)


def farol(m, brillo, ang, r, alto, rnd):
    """Farol en un poste torcido; el farol cuelga hacia el lago. Devuelve dónde está la luz."""
    x, y, _ = ejes(ang)
    pie = polar(ang, r, piso(r - 1.5) - 0.5)
    tuerce = y * rnd.uniform(-1, 1)
    pts = [pie, pie + V((0, 0, alto * 0.35)) + tuerce * 0.8, pie + V((0, 0, alto * 0.7)) - x * 1.2 + tuerce * 1.5,
           pie + V((0, 0, alto * 0.95)) - x * 2.6 + tuerce, pie + V((0, 0, alto)) - x * 5.0 + tuerce * 0.6]
    m.tubo(pts, [0.5, 0.42, 0.36, 0.3, 0.26], 5, "hierro")
    m.tubo([pie, pie + V((0, 0, 1.2))], [1.6, 1.2], 6, "lapida2")
    c = pts[-1] + V((0, 0, -3.0))
    m.caja(T(*(c + V((0, 0, 1.8)))), (2.2, 2.2, 0.5), "hierro")
    m.caja(T(*(c - V((0, 0, 1.6)))), (1.8, 1.8, 0.4), "hierro")
    for k in range(4):
        a = math.pi / 4 + k * math.pi / 2
        m.caja(T(*(c + V((math.cos(a), math.sin(a), 0)) * 1.0)), (0.25, 0.25, 3.2), "hierro2")
    brillo.caja(T(*c), (1.3, 1.3, 2.2), "cian")
    return c
