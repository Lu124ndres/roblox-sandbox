r"""
Las dos masas grandes de hielo de la repisa del hábitat del zorro de agua, a los costados de la
vista desde la puerta (270) para no taparla:
    arco    un arco natural de hielo (ángulo 200): dos torres de bloques torcidos y una bóveda
            de dovelas con nieve encima y carámbanos debajo; arriba llega a unos 34
    aguja   una aguja de hielo gigante (ángulo 345): un prisma central de unos 40 de alto con
            agujas menores alrededor, sobre un montículo de nieve
"""
import math
from mathutils import Matrix
from habitat_zorrodeagua_base import AGUA, V, afuera, contorno, ejes, ocupar, polar, rnd, suelo

ARCO = (200.0, 177.0)  # ángulo y radio del centro del arco (el témpano Puerta, 215, queda a 66 de cada pata)
ARCO_LUZ, ARCO_ZC, ARCO_GRUESO = 15.0, 13.0, 6.0  # radio de la bóveda por dentro, alto de su centro y grosor
AGUJA = (345.0, 180.0)  # ángulo y radio de la aguja (el témpano Orilla, 330, queda a 79)
AGUJA_ALTO = 40.0


def arco(m, luces):
    a, r0 = ARCO
    u = afuera(a)
    t = V((0, 0, 1)).cross(u)
    z = V((0, 0, 1))
    piso = suelo(r0 - 5) - 0.8
    centro = polar(a, r0, ARCO_ZC)
    rm = ARCO_LUZ + ARCO_GRUESO / 2
    # Torres: bloques apilados y torcidos, del fondo hasta el arranque de la bóveda.
    for lado in (-1, 1):
        zz = piso
        while zz < ARCO_ZC + 1:
            alto = rnd.uniform(4, 6)
            ancho = rnd.uniform(7.5, 9.5)
            g = ejes(a, rnd.uniform(-0.08, 0.08), rnd.uniform(-0.25, 0.25))
            cen = polar(a, r0 + rnd.uniform(-0.8, 0.8), zz + alto / 2) + t * lado * (rm + rnd.uniform(-0.6, 0.6))
            m.bloque(cen, (rnd.uniform(7, 9), ancho, alto), "nieve" if zz > AGUA else "hielo2",
                     rnd.choice(("hielo", "hielo2", "hielo4")), g)
            zz += alto - 0.4
        base = polar(a, r0, 0) + t * lado * rm
        m.prisma(base, contorno(9, 7, 0.3), suelo(r0 - 9) - 0.6, AGUA + 1.6, "nieve", "hielo2")
    # Bóveda: dovelas en medio círculo, más gruesas arriba.
    n = 13
    for k in range(n):
        phi = math.pi * (k + 0.5) / n
        rad = t * math.cos(phi) + z * math.sin(phi)
        tan = -t * math.sin(phi) + z * math.cos(phi)
        g = Matrix((rad, u, tan)).transposed()
        grueso = ARCO_GRUESO * (1 + 0.35 * math.sin(phi)) + rnd.uniform(-0.6, 0.6)
        cen = centro + rad * (ARCO_LUZ + grueso / 2) + u * rnd.uniform(-0.6, 0.6)
        largo = math.pi * (ARCO_LUZ + grueso / 2) / n * 1.12
        m.bloque(cen, (grueso, rnd.uniform(7, 9), largo), "nieve", rnd.choice(("hielo", "hielo2")), g)
        if 3 <= k <= n - 4:  # nieve encima y carámbanos debajo
            arriba = centro + rad * (ARCO_LUZ + grueso + 0.4)
            m.bloque(arriba, (1.2, 7.5, largo * 0.95), "nieve", "nieve", g)
            for _ in range(2):
                q = centro + rad * (ARCO_LUZ - 0.2) + u * rnd.uniform(-3, 3)
                m.cristal(q, V((0, 0, -1)), rnd.uniform(0.5, 0.8), rnd.uniform(2.5, 5), "hielo", 4)
    luces.append((polar(a, r0, ARCO_ZC), 30))
    ocupar(polar(a, r0, 0), rm + 10)


def aguja(m, luces):
    a, r0 = AGUJA
    base = polar(a, r0, 0)
    fondo = suelo(r0 - 12) - 1
    m.prisma(base, contorno(12, 9, 0.25), fondo, AGUA + 2.6, "nieve", "escarcha")
    m.prisma(base + V((rnd.uniform(-2, 2), rnd.uniform(-2, 2), 0)), contorno(7, 7, 0.3), AGUA + 2.4, AGUA + 4.2,
             "nieve", "nieve")
    eje = (V((0, 0, 1)) - afuera(a) * 0.08).normalized()
    m.cristal(V((base.x, base.y, fondo)), eje, 6.5, AGUJA_ALTO - fondo, "hielo", 6)
    for k in range(6):
        t = k / 6 * math.tau + rnd.uniform(-0.3, 0.3)
        lado = V((math.cos(t), math.sin(t), 0))
        inclina = math.radians(rnd.uniform(8, 24))
        ej = (V((0, 0, 1)) * math.cos(inclina) + lado * math.sin(inclina)).normalized()
        q = V((base.x, base.y, AGUA - 1)) + lado * rnd.uniform(5, 8)
        m.cristal(q, ej, rnd.uniform(2.2, 3.6), rnd.uniform(12, 26), rnd.choice(("hielo", "hielo2", "hielo4")), 5)
    luces.append((V((base.x, base.y, AGUA + 6)), 30))
    ocupar(base, 16)


def construir(m, luces):
    arco(m, luces)
    aguja(m, luces)
