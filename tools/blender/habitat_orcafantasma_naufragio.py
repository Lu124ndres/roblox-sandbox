r"""
Naufragios del hábitat de la Orca fantasma:
    barco   el BarcoHundido de habitats_orcafantasma.py, más grande y partido en dos mitades
            que se abren en V hacia el lago; la proa se levanta, el casco queda abierto con
            las cuadernas al aire en el corte y dos mástiles largos caídos que se cruzan;
    faro    un faro hundido en la repisa y torcido contra el acantilado (sin pasar de Y 30),
            con la linterna apagada que brilla en cian.
"""
import math
from mathutils import Matrix, Vector as V
import habitats as H
from habitats import T
import habitats_orcafantasma as P
import habitat_orcafantasma_piezas as Z

L, B, ALTO = 56.0, 17.0, 13.0  # medidas del barco antes de escalar (el prop suelto: 46, 15, 11)
MB = T(0, 0, -2.4) @ H.girar("Y", math.radians(16)) @ H.girar("X", math.radians(-7))  # la escora del prop


def cuadernas(m, M, desde, hacia, rnd):
    """Cuadernas (costillas de madera) al aire, saliendo del corte del casco."""
    for k in range(1, 4):
        y = desde + (hacia - desde) * k / 3
        completa = 1.0 - 0.22 * k
        pts = []
        for j in range(9):
            u = -1 + 2 * j / 8
            if abs(u) > completa and j not in (0, 8):
                continue
            x = B / 2 * math.sin(u * math.pi / 2) * 0.96
            z = ALTO * (1 - math.cos(u * math.pi / 2)) * 0.95 + 0.4
            pts.append(M @ MB @ V((x, y, z)))
        if len(pts) > 2:
            m.tubo(pts, [0.55] * len(pts), 4, "madera2" if k % 2 else "madera")


def barco(m, brillo, ang, r, s, rnd):
    """Devuelve la luz del farol de popa y los puntos donde apoyar rocas bajo la proa."""
    x, y, z = Z.ejes(ang)
    giro = Matrix((-x, -y, z)).transposed().to_4x4()  # +X del barco hacia el lago: escora hacia adentro
    base = Z.polar(ang, r, Z.piso(r) - 3.0)
    luz, rocas = None, []
    for proa in (False, True):
        b = P.barco(3, L, B, ALTO)
        corte = 1.0 if proa else -1.0
        Z.recortar(b["malla"], proa, corte)
        Z.recortar(b["brillo"], proa, corte)
        if proa:
            local = T(0, 1, 0) @ H.girar("Z", math.radians(-16)) @ H.girar("X", math.radians(13)) @ T(0, -1, 0)
        else:
            local = T(0, -1, 0) @ H.girar("Z", math.radians(17)) @ H.girar("X", math.radians(-5)) @ T(0, 1, 0)
        M = T(*(base - y * (14 if proa else -14))) @ giro @ Matrix.Scale(s, 4) @ local
        Z.volcar(m, b["malla"], M, apoyar=False)
        Z.volcar(brillo, b["brillo"], M, apoyar=False)
        cuadernas(m, M, corte, corte - 7 if proa else corte + 7, rnd)
        if proa:
            rocas = [M @ V((0, yy, 0)) for yy in (14, 22)]
        else:
            luz = M @ V(b["llama"])
    # Dos mástiles largos caídos que se cruzan en X sobre el corte, con jarcia rota.
    centro = base + V((0, 0, 0))
    for sgn, alto, color in ((1, 40.0, "madera2"), (-1, 34.0, "madera")):
        pie = centro + y * (sgn * 20) + x * (sgn * 4) + V((0, 0, 4))
        punta = centro - y * (sgn * 22) - x * 6 + V((0, 0, alto))
        medio = pie.lerp(punta, 0.5) + V((0, 0, 1.5))
        m.tubo([pie, medio, punta], [1.7, 1.5, 1.1], 6, color)
        verga = punta.lerp(pie, 0.22)
        m.tubo([verga - x * 9 + y * 2, verga, verga + x * 8 - y * 2], [0.5, 0.65, 0.5], 5, "madera2")
        m.placa(T(*(verga - V((0, 0, 1.0)))) @ Matrix(((x.x, y.x, 0, 0), (x.y, y.y, 0, 0), (0, 0, 1, 0), (0, 0, 0, 1))),
                [(-7, 0), (6, 0.4), (5, -3.6), (2.6, -6.5), (0.4, -4.4), (-2.4, -8.0), (-4, -4.8), (-6.6, -5.6)],
                0.25, "tela", "tela2")
        for t in (0.35, 0.7):
            cabo = punta.lerp(pie, t)
            m.tubo([cabo, cabo + V((rnd.uniform(-3, 3), rnd.uniform(-3, 3), -cabo.z + Z.piso_en(cabo) + 0.5))],
                   [0.18, 0.18], 3, "tela2")
    return luz, rocas


def faro(m, brillo, ang, r, inclina, alto):
    """Faro de piedra hundido y torcido hacia el acantilado. Devuelve dónde está la luz."""
    M = Z.marco(ang, r, Z.piso(r) - 4.0, 1.0, 0) @ H.girar("X", -math.radians(inclina))
    franjas = 7
    radios = [7.6 - 3.0 * k / franjas for k in range(franjas + 1)]
    for k in range(franjas):
        z0, z1 = alto * k / franjas, alto * (k + 1) / franjas
        m.torno(M @ T(0, 0, z0), [(radios[k], 0), (radios[k + 1], z1 - z0)], 8,
                "lapida3" if k % 2 else "rojo2", base=(k == 0), giro=math.pi / 8)
    for k in range(3):  # ventanitas negras
        m.caja(M @ H.girar("Z", 1.1 * k) @ T(0, radios[2 * k + 1] - 0.2, alto * (2 * k + 1.5) / franjas), (1.2, 0.6, 2.0), "negro")
    top = alto
    m.torno(M @ T(0, 0, top), [(radios[-1] + 2.0, 0), (radios[-1] + 2.0, 0.9)], 8, "lapida2", giro=math.pi / 8)
    for k in range(8):  # baranda rota: faltan dos barrotes
        if k in (2, 3):
            continue
        a = 2 * math.pi * k / 8
        m.caja(M @ T((radios[-1] + 1.6) * math.cos(a), (radios[-1] + 1.6) * math.sin(a), top + 1.9), (0.3, 0.3, 2.2), "hierro")
    luz_local = V((0, 0, top + 3.2))
    brillo.torno(M @ T(0, 0, top + 0.9), [(2.3, 0), (2.3, 4.4)], 8, "cian", giro=math.pi / 8)
    for k in range(4):
        a = math.pi / 4 + k * math.pi / 2
        m.caja(M @ T(2.4 * math.cos(a), 2.4 * math.sin(a), top + 3.1), (0.5, 0.5, 4.4), "hierro")
    m.torno(M @ T(0, 0, top + 5.3), [(3.4, 0), (0.3, 2.4)], 8, "hierro2", giro=math.pi / 8)
    # escombros al pie
    return M @ luz_local, M @ V((0, 0, 0))
