r"""
Huesos del hábitat de la Orca fantasma: la ballena colosal (la columna se arquea sobre el
agua como un puente de costillas, del pie del acantilado a la ladera) y las costillas sueltas
que asoman de la ladera.
"""
import math
from mathutils import Matrix, Vector as V
import habitats as H
from habitats import T
from habitat_orcafantasma_piezas import piso, piso_en, polar


def ballena(m, brillo, camino, alto, ancho, grosor, cabeza, rnd):
    """Esqueleto tendido sobre la panza a lo largo de `camino(s)` (s 0 = cabeza, 1 = cola).
    La columna sube detrás del cráneo hasta `alto` sobre el fondo y baja a la cola; las
    costillas se arquean a los dos lados y entran en el fondo. Devuelve dónde quedó el cráneo."""
    n = 34
    for i in range(n + 1):
        s = i / n
        p = camino(s)
        suelo = piso_en(p)
        dir_ = (camino(min(1.0, s + 0.02)) - camino(max(0.0, s - 0.02)))
        dir_.z = 0
        dir_.normalize()
        lado = dir_.cross(V((0, 0, 1)))
        h = alto * math.sin(math.pi * min(1.0, max(0.0, (s - 0.06) / 0.84))) ** 0.65
        k = grosor * (1.5 - 0.9 * s)
        c = p + V((0, 0, suelo + max(h, 1.8 * k)))
        g = Matrix((dir_, lado, V((0, 0, 1)))).transposed().to_4x4() @ H.girar("Z", rnd.uniform(-0.06, 0.06))
        if s > 0.05:
            m.caja(T(*c) @ g, (3.4 * k, 3.0 * k, 3.4 * k), "hueso2")
            m.caja(T(*(c + V((0, 0, 3.0 * k)))) @ g @ H.girar("Y", 0.4), (2.4 * k, 1.0 * k, 4.8 * k), "hueso")
            m.caja(T(*c) @ g, (1.1 * k, 9.4 * k, 1.1 * k), "hueso3")
        if 0.1 <= s <= 0.68 and i % 2 == 0:
            w = ancho * (0.6 + 0.5 * math.sin(math.pi * (s - 0.06) / 0.66))
            for sgn in (-1, 1):
                costilla(m, c, dir_, lado * sgn, w, k, rnd)
    return craneo(m, brillo, camino(0.0), -(camino(0.03) - camino(0.0)).normalized(), cabeza)


def costilla(m, c, atras, lado, ancho, k, rnd):
    pts, rad = [], []
    pasos = 8
    for j in range(pasos + 1):
        a = math.pi / 2 * j / pasos
        p = c + lado * (ancho * math.sin(a)) + atras * (4.0 * j / pasos)  # se echan hacia la cola
        if p.xy.length < 127:  # no entra al santuario (r < 124)
            p.xy = p.xy.normalized() * 127
        suelo = piso_en(p) - 1.2
        p.z = c.z - (c.z - suelo) * (1 - math.cos(a)) ** 1.25
        pts.append(p)
        rad.append((2.4 - 1.1 * j / pasos) * k)
    m.tubo(pts, rad, 5, "hueso" if rnd.random() < 0.6 else "hueso2")


def craneo(m, brillo, base, adelante, e):
    """Cráneo de bloques: caja ancha y baja, hocico que se afina hacia `adelante`, cuencas
    negras con brillo cian y las dos mandíbulas tiradas en el fondo, abiertas."""
    adelante = V((adelante.x, adelante.y, 0)).normalized()
    lado = V((0, 0, 1)).cross(adelante)
    g = Matrix((adelante, lado, V((0, 0, 1)))).transposed().to_4x4()
    base = V((base.x, base.y, piso_en(base) - 1.0 * e))
    pie = lambda dr, dt, dz: base + (adelante * dr + lado * dt) * e + V((0, 0, dz * e))
    m.caja(T(*pie(-1, 0, 4.0)) @ g @ H.girar("Y", -0.12), (11 * e, 17 * e, 9 * e), "hueso2")
    m.caja(T(*pie(-3, 0, 8.6)) @ g @ H.girar("Y", -0.2), (7 * e, 12 * e, 3 * e), "hueso")
    for j, (dr, w, h) in enumerate(((7, 12, 6), (12, 9, 4.6), (16.5, 6, 3.4))):
        m.caja(T(*pie(dr, 0, h / 2 + 0.6)) @ g, (5.4 * e, w * e, h * e), "hueso" if j % 2 else "hueso2")
    ojo = None
    for sgn in (-1, 1):
        m.caja(T(*pie(2.5, sgn * 7.6, 5.4)) @ g, (4.2 * e, 2.6 * e, 3.6 * e), "negro")
        ojo = pie(2.7, sgn * 8.4, 5.4)
        brillo.caja(T(*ojo) @ g, (2.0 * e, 1.2 * e, 1.6 * e), "cian")
        pts = []
        for j in range(6):
            s = j / 5
            p = pie(-4 + 22 * s, sgn * (9 + 7 * math.sin(math.pi * s)), 0)
            p.z = piso_en(p) + 0.6 + 1.2 * math.sin(math.pi * s)
            pts.append(p)
        m.tubo(pts, [x * e for x in (1.8, 1.7, 1.5, 1.3, 1.0, 0.7)], 6, "hueso2")
    return ojo


def costilla_suelta(m, ang, r, largo, alto, rnd):
    """Una costilla gigante que sale de la ladera y vuelve a entrar (un arco tangente)."""
    giro = math.radians(rnd.uniform(-35, 35))
    pts, rad = [], []
    for j in range(9):
        s = j / 8
        d = (s - 0.5) * largo
        a = math.radians(ang) + d / r * math.cos(giro)
        rr = max(128.0, r + d * math.sin(giro))  # fuera del santuario
        p = V((rr * math.cos(a), -rr * math.sin(a), 0))
        p.z = piso(rr) - 1.5 + alto * math.sin(math.pi * s) ** 0.8
        pts.append(p)
        rad.append(1.9 - 0.9 * s)
    m.tubo(pts, rad, 5, rnd.choice(("hueso", "hueso2", "hueso3")))
    return pts
