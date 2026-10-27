r"""
El glaciar del hábitat del zorro de agua (habitat_zorrodeagua.py), el protagonista: una meseta
de hielo que sale del borde del paseo (Y 29) y se adelanta sobre la repisa casi frente a la
puerta, y termina en un muro de séracs vertical que cae hasta el agua, con grietas azules
hondas y una cueva grande en el medio del frente. La meseta se parte en losas (las hileras y
columnas hundidas son grietas). Todo apoya en el fondo de verdad (suelo()): si el lago se
vacía, el glaciar no queda colgando.
"""
import math
from mathutils import Matrix
from habitat_zorrodeagua_base import (AGUA, TECHO, V, afuera, angulo, cabe, choca_spot, dif, ejes, polar, rnd,
                                      suelo)

CENTRO = 60.0  # ángulo del cráter: a la derecha de enfrente de la puerta (270), lejos del témpano Fondo (100)
MEDIO = 45.0  # medio ancho (grados): de 15 a 105
FRENTE_R = 164.0  # radio del muro del frente en el medio
CURVA = 26.0  # cuánto se retira el frente hacia los costados (en el borde llega a 190)
TOPE_PASEO, TOPE_FRENTE = 29.2, 27.5  # alto de la meseta contra el paseo y en el frente
ARRIBA_R = 202.0  # la primera hilera, contra el paseo
FILA = 4.5  # alto radial de cada hilera de losas
COLUMNA = 7.5  # ancho de cada losa a lo largo de la orilla
PILAR = 6.0  # ancho de cada sérac del frente
CUEVA_E = 1.5  # escala de la cueva del frente (rocas.cueva)
CUEVA_MEDIO = 8.0  # grados del frente que ocupa su boca
CUEVA_TECHO = AGUA + 21  # la meseta encima de la cueva empieza aquí


def frente(da):
    """Radio del muro del frente según el desvío `da` (grados) del centro: redondeado."""
    return FRENTE_R + CURVA * (min(abs(da), MEDIO) / MEDIO) ** 2


def tope(r, da):
    """Altura de la meseta: casi plana, un poco más baja hacia el frente y en los costados."""
    rf = frente(da)
    s = min(max((r - rf) / (204 - rf), 0), 1)
    alto = TOPE_FRENTE + (TOPE_PASEO - TOPE_FRENTE) * s ** 0.7 - 9 * (abs(da) / MEDIO) ** 3
    return min(TECHO - 0.3, max(alto, suelo(r) + 1.5))


def dentro(p, margen=0.0):
    """¿El punto (Blender) cae sobre el glaciar (con `margen` studs de holgura)?"""
    r = p.xy.length
    da = abs(dif(angulo(p), CENTRO))
    return da <= MEDIO + math.degrees(margen / max(r, 1)) and r >= frente(da) - 8 - margen


def toca(p, rad, margen=4.0):
    for k in range(9):
        q = p.xy if k == 8 else p.xy + V((math.cos(k * math.pi / 4), math.sin(k * math.pi / 4))) * rad
        if dentro(V((q.x, q.y, 0)), margen):
            return True
    return False


def _ejes_sobre(a, r, da):
    """Ejes de una losa apoyada en la meseta: Z normal a la superficie, X hacia afuera."""
    sube_r = tope(r + 0.5, da) - tope(r - 0.5, da)
    paso = math.degrees(0.5 / r)
    sube_t = tope(r, da + paso) - tope(r, da - paso)
    x0, z0 = afuera(a), V((0, 0, 1))
    t0 = z0.cross(x0)
    n = (z0 - x0 * sube_r + t0 * sube_t).normalized()
    x = (x0 - n * x0.dot(n)).normalized()
    g = Matrix((x, n.cross(x), n)).transposed()
    tumbo = Matrix.Rotation(rnd.uniform(-0.05, 0.05), 3, g.col[1]) @ Matrix.Rotation(rnd.uniform(-0.06, 0.06), 3, n)
    return tumbo @ g, abs(sube_r)


def meseta(m):
    """Hileras de losas gruesas hasta el fondo, desde el paseo hasta el muro del frente; cada
    tercera hilera y cada sexta columna, hundidas (grietas azules)."""
    fila, r = 0, ARRIBA_R
    while r > FRENTE_R:
        n = max(2, math.ceil(math.radians(2 * MEDIO) * r / COLUMNA))
        corrido = 0.5 * (fila % 2)
        for j in range(n):
            da = -MEDIO + (j + corrido + rnd.uniform(-0.12, 0.12)) * 2 * MEDIO / n
            if abs(da) > MEDIO or r < frente(da) + PILAR * 0.6:
                continue
            a = CENTRO + da
            rr = r + rnd.uniform(-0.6, 0.6)
            if choca_spot(polar(a, rr, 0), 3):
                continue
            g, sube = _ejes_sobre(a, rr, da)
            grieta = (fila % 3 == 2 and rr < 200) or (j % 6 == 3 and rr < 198)
            alza = -3.5 if grieta else rnd.uniform(-0.6, 0.7) + (1.8 if rnd.random() < 0.08 else 0)
            top = min(tope(rr, da) + alza, TECHO - 0.5)
            fondo = min(suelo(rr - FILA / 2 - 0.3), suelo(rr)) - 1.5
            if abs(da) < CUEVA_MEDIO + 2 and rr < frente(da) + 15 * CUEVA_E:
                fondo = CUEVA_TECHO  # encima de la cueva
            grosor = max(top - fondo, 3.0)
            largo = FILA * (1 + sube * sube) ** 0.5 * 1.12
            ancho = math.radians(2 * MEDIO / n) * rr * rnd.uniform(1.02, 1.1)
            arriba = "grieta" if grieta else rnd.choice(("nieve", "nieve", "nieve", "escarcha", "hielo"))
            lados = "hielo3" if grieta else rnd.choice(("hielo", "hielo", "hielo2"))
            for _ in range(6):  # contra el paseo: se achica y se baja hasta que entra
                centro = polar(a, rr, top) - g.col[2] * (grosor / 2)
                if cabe(centro, (largo, ancho, grosor), g):
                    m.bloque(centro, (largo, ancho, grosor), arriba, lados, g)
                    break
                largo, rr, top = largo * 0.85, rr - 0.4, top - 0.5
        fila += 1
        r -= FILA


def muro(m):
    """El frente: séracs verticales del fondo hasta arriba de la meseta; cada tercero, hundido
    y azul oscuro (una grieta honda); algunos con una aguja torcida encima."""
    largo_frente = sum(math.radians(1) * frente(-MEDIO + k + 0.5) for k in range(int(2 * MEDIO)))
    n = round(largo_frente / PILAR)
    for k in range(n):
        da = -MEDIO + (k + 0.5) * 2 * MEDIO / n
        if abs(da) < CUEVA_MEDIO:
            continue
        a = CENTRO + da
        grieta = k % 3 == 1
        r = frente(da) + PILAR / 2 + (2.5 if grieta else rnd.uniform(-0.6, 0.6))
        if choca_spot(polar(a, r, 0), 4):
            continue
        top = tope(r, da) + (-4 if grieta else rnd.uniform(-1, 2.5))
        top = min(top, TECHO - 0.4 if r > 189 else 33)
        fondo = suelo(r - PILAR / 2) - 1
        ancho = math.radians(2 * MEDIO / n) * frente(da) * 1.04
        g = ejes(a, rnd.uniform(-0.04, 0.04), rnd.uniform(-0.08, 0.08))
        m.bloque(polar(a, r, (top + fondo) / 2), (PILAR, ancho, top - fondo), "grieta" if grieta else "nieve",
                 "grieta" if grieta else rnd.choice(("hielo", "hielo", "hielo2")), g)
        if not grieta and r < 189 and rnd.random() < 0.45:
            alto = rnd.uniform(3, 6)
            gg = ejes(a, rnd.uniform(-0.25, 0.1), rnd.uniform(0, 1.5))
            m.bloque(polar(a, r - 0.5, min(top + alto / 2 - 0.6, 37 - alto / 2)), (ancho * 0.55, ancho * 0.5, alto),
                     "nieve", "hielo", gg)
    # Encima de la boca de la cueva: el muro sigue desde su techo hasta la meseta.
    for k in range(5):
        da = -CUEVA_MEDIO + (k + 0.5) * 2 * CUEVA_MEDIO / 5
        a = CENTRO + da
        r = frente(da) + PILAR / 2
        top = tope(r, da) + rnd.uniform(-0.5, 1.5)
        ancho = math.radians(2 * CUEVA_MEDIO / 5) * r * 1.05
        m.bloque(polar(a, r, (top + CUEVA_TECHO - 1) / 2), (PILAR, ancho, top - CUEVA_TECHO + 1), "nieve", "hielo",
                 ejes(a, 0, rnd.uniform(-0.05, 0.05)))


def trozos(m):
    """Trozos caídos al pie del muro, apoyados en el fondo."""
    for _ in range(16):
        da = rnd.uniform(1 - MEDIO, MEDIO - 1)
        if abs(da) < CUEVA_MEDIO + 1:
            continue
        a = CENTRO + da
        r = frente(da) - rnd.uniform(2, 7)
        if r < 134 or choca_spot(polar(a, r, 0), 5):
            continue
        tam = V((rnd.uniform(3, 7), rnd.uniform(3, 7), 0))
        fondo = suelo(r - tam.x / 2) - 1
        top = AGUA + rnd.uniform(1, 4.5)
        g = ejes(a, rnd.uniform(-0.3, 0.3), rnd.uniform(0, math.pi))
        m.bloque(polar(a, r, (top + fondo) / 2), (tam.x, tam.y, top - fondo), "hielo", "hielo2", g)


def construir(m, b, cueva):
    """`cueva`: rocas.cueva (la cueva del frente se arma igual que las de la orilla)."""
    meseta(m)
    muro(m)
    trozos(m)
    cueva(m, b, CENTRO, frente(0) - 0.5, CUEVA_E, False)
