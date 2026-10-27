r"""
Rocas, cuevas y cristales del hábitat del zorro de agua (habitat_zorrodeagua.py):
    rocas     peñones de piedra fría en la repisa, como IceRocks (cima de lajas, corona bajada,
              laderas que se abren hacia el fondo, escarcha cerca del agua, nieve arriba, un
              racimo de cristales hacia el lago y costra de hielo a ras del agua)
    cuevas    arcos de hielo contra el pie del acantilado, con la boca hacia el lago: adentro,
              fondo oscuro, cristales que brillan y carámbanos colgando del labio
    racimos   cristales grandes (Neon celeste) al pie del acantilado
Los cristales van en la malla de brillo; su montículo de nieve, en la de piedra.
"""
import math
from mathutils import Matrix
from habitat_zorrodeagua_base import (AGUA, ROCAS, TECHO, V, afuera, contorno, ejes, ocupar, polar, rnd, suelo)

# Rocas de la repisa: ángulo del cráter, radio, alto de la cima sobre el agua, radio de la cima.
# Lejos de la puerta, del glaciar, de las cuevas y de los lugares del zorro (base.SPOTS).
ROCAS_REPISA = ((128, 175, 18, 14), (180, 177, 13, 10), (236, 176, 15, 12))
CUEVAS = ((298, 181, 1.25),)  # ángulo, radio de la boca y escala (la grande está en el glaciar)
CRISTALES = ((112, 187, 1.7), (150, 187, 1.8), (325, 187, 1.6))  # al pie del acantilado: 17 a 20 de alto
LUZ = (170, 220, 255)
LUCES = []  # (posición Blender, rango): las cuevas y los racimos grandes


def racimo(b, p, base, eje, escala):
    """Un cristal grande en el medio, cinco alrededor inclinados hacia afuera y esquirlas al pie
    (malla de brillo `b`); un montículo de nieve en la piedra `p`."""
    e = V(eje).normalized()
    a = e.orthogonal().normalized()
    b2 = e.cross(a)
    b.cristal(base - e * 1.0 * escala, e, 1.8 * escala, 11 * escala, "cristal")
    for k in range(5):
        t = k / 5 * math.tau + rnd.uniform(-0.35, 0.35)
        lado = a * math.cos(t) + b2 * math.sin(t)
        inclina = math.radians(rnd.uniform(18, 44))
        ej = (e * math.cos(inclina) + lado * math.sin(inclina)).normalized()
        b.cristal(base + lado * 1.6 * escala - e * 0.6 * escala, ej, rnd.uniform(0.9, 1.4) * escala,
                  rnd.uniform(4, 8) * escala, "cristal")
    for _ in range(3):
        t = rnd.uniform(0, math.tau)
        lado = a * math.cos(t) + b2 * math.sin(t)
        ej = (e * 0.4 + lado).normalized()
        b.cristal(base + lado * 3.2 * escala - e * 0.4 * escala, ej, 0.5 * escala, rnd.uniform(1.6, 2.6) * escala,
                  "cristal", 4)
    if p is not None:
        g = Matrix((a, b2, e)).transposed()
        p.bloque(base - e * 0.5 * escala, (5.4 * escala, 4.6 * escala, 1.6 * escala), "nieve", "escarcha", g)


def _piedra(p, centro, tam, giro, z_arriba=None):
    if V(centro).xy.length + max(tam[0], tam[1]) / 2 > 203.5 or centro[2] + tam[2] / 2 > TECHO:
        return  # contra el acantilado: no se asoma al paseo
    if centro[2] + tam[2] / 2 < suelo(V(centro).xy.length) - 0.5:
        return  # enterrada entera en el fondo o en la pared
    color = rnd.choice(ROCAS)
    lados = "rocaesc" if centro[2] < AGUA + 4 else color
    arriba = "nieve" if (z_arriba is not None and rnd.random() < 0.5) else lados
    p.bloque(centro, tam, arriba, lados, giro)


def roca(p, b, a, r, alto, size):
    c = polar(a, r, 0)
    top = AGUA + alto
    f1, f2 = rnd.uniform(0, math.tau), rnd.uniform(0, math.tau)

    def borde(t):
        return size * (1.1 + 0.08 * math.sin(2 * t + f1) + 0.06 * math.sin(3 * t + f2))

    def alrededor(t, d, z):
        return V((c.x + math.cos(t) * d, c.y + math.sin(t) * d, z))

    # Núcleo escondido y cima de lajas en escalones (la primera, justo en `top`).
    p.prisma(c, [V((math.cos(k * math.tau / 7), math.sin(k * math.tau / 7))) * size * 0.95 for k in range(7)],
             suelo(r - size) - 1.5, top - 3.4, "escarcha", "roca3")
    for k in range(5):
        d = 0 if k == 0 else size * 0.3 * rnd.random()
        t = rnd.uniform(0, math.tau)
        g = Matrix.Rotation(rnd.uniform(0, math.pi), 3, "Z")
        tam = (size * rnd.uniform(1.4, 1.7), size * rnd.uniform(1.0, 1.2), 3)
        p.bloque(alrededor(t, d, top - 0.18 * k - 1.5), tam, "escarcha" if k else "nieve", rnd.choice(ROCAS), g)
    for _ in range(2):  # parches de nieve
        t, d = rnd.uniform(0, math.tau), size * 0.45 * rnd.random()
        p.bloque(alrededor(t, d, top + 0.2), (size * rnd.uniform(0.5, 0.8), size * rnd.uniform(0.4, 0.7), 0.5),
                 "nieve", "nieve", Matrix.Rotation(rnd.uniform(0, math.pi), 3, "Z"))
    # Corona: bloques torcidos bajo la cima, hacia afuera.
    n = max(9, round(math.tau * size / 9))
    for i in range(n):
        t = (i + rnd.uniform(-0.3, 0.3)) / n * math.tau
        tam = (rnd.uniform(5, 8), rnd.uniform(7, 11), rnd.uniform(4, 8))
        z = top - rnd.uniform(0.9, 3.5) - tam[2] / 2
        cen = alrededor(t, borde(t) - tam[0] * 0.15, z)
        _piedra(p, cen, tam, ejes(math.degrees(-t), rnd.uniform(0.1, 0.45), rnd.uniform(-0.25, 0.25)), True)
    # Laderas: hileras que se abren hacia el fondo; abajo, escarchadas.
    z = top - 4
    fondo = suelo(r - size - 8)  # del lado del lago el fondo está más abajo
    while z > fondo + 1:
        flare = 1 + (top - z) / max(top - fondo, 1) * 8
        n = max(7, round(math.tau * (size + flare) / 10))
        corrido = rnd.random()
        for i in range(n):
            t = (i + corrido + rnd.uniform(-0.25, 0.25)) / n * math.tau
            tam = (rnd.uniform(6, 10), rnd.uniform(9, 14), rnd.uniform(6, 9.6))
            d = borde(t) + flare - tam[0] * 0.3 + rnd.uniform(-1.5, 1.5)
            zz = z - tam[2] / 2 + rnd.uniform(-1, 1)
            _piedra(p, alrededor(t, d, zz), tam, ejes(math.degrees(-t), rnd.uniform(0.05, 0.35),
                                                        rnd.uniform(-0.2, 0.2)))
        z -= 6
    # Costra de hielo a ras del agua, en losas sueltas.
    for k in range(5):
        t = (k + rnd.uniform(-0.25, 0.25)) / 5 * math.tau
        d = borde(t) + 6.5
        q = alrededor(t, d, 0)
        lado = rnd.uniform(4, 7)
        p.prisma(q, contorno(lado, 6, 0.3), AGUA - 0.6, AGUA + 0.25 + k * 0.04, "hielo", "hielo2")
    ocupar(c, size * 1.1 + 9)


def cueva(p, b, a, r0, e=1.0, monticulo=True):
    """Arco de hielo con la boca hacia el lago, de escala `e`. Ejes locales: u hacia el
    acantilado, t a lo largo de la orilla, z arriba; el centro del arco, a ras del agua.
    `monticulo`: hielo y nieve a los lados y encima (no hace falta dentro del glaciar)."""
    u = afuera(a)
    t = V((0, 0, 1)).cross(u)
    z = V((0, 0, 1))
    zc = AGUA - 0.5
    piso = suelo(r0) - 0.5
    for s in range(4):
        du = s * 3.3 * e
        ri = (7.5 + rnd.uniform(-0.4, 0.4) - (0.6 if s == 0 else 0)) * e
        ro = ri + (4.8 + (1.2 if s == 0 else 0)) * e
        n = 9 if e < 1.2 else 11
        for k in range(n):
            phi = math.pi * (k + 0.5) / n
            rad = t * math.cos(phi) + z * math.sin(phi)
            tan = -t * math.sin(phi) + z * math.cos(phi)
            g = Matrix((rad, u, tan)).transposed()
            rm = (ri + ro) / 2
            cen = polar(a, r0 + du, zc) + rad * rm
            m_arco = math.pi * rm / n * 1.08
            arriba = "nieve" if s > 0 and 2 <= k <= n - 3 else "hielo"
            lados = rnd.choice(("hielo2", "hielo4")) if s else "hielo"
            p.bloque(cen, (ro - ri, 3.5 * e, m_arco), arriba, lados, g)
        for lado in (-1, 1):  # patas del arco hasta el fondo
            cen = polar(a, r0 + du, (piso + zc) / 2) + t * lado * (ri + ro) / 2
            p.bloque(cen, ((ro - ri) * 1.05, 3.5 * e, zc - piso + 0.6), "hielo", "hielo2", ejes(a, 0, math.pi / 2))
    # Fondo oscuro de la cueva.
    alto_fondo = zc + 8.2 * e
    p.bloque(polar(a, r0 + 8.5 * e, (piso + alto_fondo) / 2), (1.2, 17 * e, alto_fondo - piso), "cueva", "cueva",
             ejes(a))
    if monticulo:
        for lado in (-1, 1):
            for k in range(2):
                alto = (rnd.uniform(7, 11) - k * 2) * e
                cen = (polar(a, r0 + (3 + k * 5) * e, (piso + AGUA + alto) / 2)
                       + t * lado * (13.5 + k * 2 + rnd.uniform(0, 2)) * e)
                p.bloque(cen, (7 * e, 6 * e, AGUA + alto - piso), "nieve", rnd.choice(("hielo2", "hielo4")),
                         ejes(a, rnd.uniform(-0.1, 0.1), rnd.uniform(-0.3, 0.3)))
        for k in range(3):
            cen = (polar(a, r0 + (3 + k * 3.5) * e, zc + 12.6 * e + rnd.uniform(-0.3, 0.6))
                   + t * rnd.uniform(-3, 3) * e)
            p.bloque(cen, (5 * e, rnd.uniform(9, 13) * e, 1.4), "nieve", "escarcha",
                     ejes(a, 0, rnd.uniform(-0.3, 0.3)))
    # Carámbanos colgando del labio y cristales adentro (con su luz).
    for k in range(round(7 * e)):
        phi = math.pi * (0.25 + 0.5 * (k + rnd.uniform(0.2, 0.8)) / round(7 * e))
        base = polar(a, r0 - 0.6, zc) + (t * math.cos(phi) + z * math.sin(phi)) * 6.8 * e
        p.cristal(base + z * 0.4, V((0, 0, -1)), rnd.uniform(0.35, 0.6) * e, rnd.uniform(1.8, 3.6) * e, "hielo", 4)
    for lado, du in ((-1, 6.0), (0.2, 7.2), (1, 5.4)):
        base = polar(a, r0 + du * e, suelo(r0 + du * e)) + t * lado * 4.2 * e
        racimo(b, None, base, (z * 1.6 - u * 0.6 + t * lado * 0.3).normalized(), 0.55 * e)
    LUCES.append((polar(a, r0 + 4 * e, AGUA + 4 * e), round(26 * e)))
    ocupar(polar(a, r0 + 4 * e, 0), 20 * e)


def cristales_grandes(p, b):
    for a, r, escala in CRISTALES:
        base = polar(a, r, suelo(r) + 0.4)
        racimo(b, p, base, (V((0, 0, 1)) - afuera(a) * 0.4).normalized(), escala)
        LUCES.append((base + V((0, 0, 10)), 34))
        ocupar(base, 6 * escala)


def construir(p, b):
    for a, r, e in CUEVAS:
        cueva(p, b, a, r, e)
    cristales_grandes(p, b)
    for a, r, alto, size in ROCAS_REPISA:
        roca(p, b, a, r, alto, size)
