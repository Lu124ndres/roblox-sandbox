r"""
El suelo de hielo del hábitat del zorro de agua (habitat_zorrodeagua.py): toda la repisa, de
r 125 a 190, cubierta, menos el agua que rodea los lugares del zorro.
    banquisa     placas de hielo a ras del agua en anillos, con grietas finas entre ellas (por ahí
                 se ve el agua) y parches de nieve. Desde r 160 bajan hasta el fondo (varadas);
                 más adentro flotan (malla aparte: el juego las sube y hunde con el lago)
    crestas      bancos de hielo grandes y altos, varados sobre la banquisa
    ventisqueros nieve amontonada contra el pie del acantilado, en rampa
    icebergs     bloques de 15 a 25 sobre el agua (flotan), con la falda bajo el agua
"""
import math
import habitat_zorrodeagua_glaciar as glaciar
from habitat_zorrodeagua_base import (AGUA, LAGO, V, choca_spot, contorno, ejes, ocupar, polar, rnd, suelo, zona_ok,
                                      OCUPADO)

VARADA_R = 160.0  # desde aquí la banquisa baja hasta el fondo (el fondo está a -6 o más arriba)
ANILLO = 8.0  # ancho de cada anillo de placas
PLACA = 10.0  # largo de cada placa a lo largo del anillo
GRIETA = 0.45  # medio ancho de las grietas entre placas


def _tapado(p, rad):
    if glaciar.toca(p, rad, 0.5):
        return True
    return any((p.xy - c).length < rad + rc - 1 for c, rc in OCUPADO)


def banquisa(varada, flota):
    r0 = 125.0
    while r0 < LAGO - 1:
        r1 = min(r0 + ANILLO * rnd.uniform(0.85, 1.15), LAGO + 1.5)
        rc = (r0 + r1) / 2
        n = max(12, round(math.tau * rc / PLACA))
        corrido = rnd.random()
        for k in range(n):
            a0 = (k + corrido + rnd.uniform(-0.12, 0.12)) * 360 / n
            a1 = (k + 1 + corrido + rnd.uniform(-0.12, 0.12)) * 360 / n
            c = polar((a0 + a1) / 2, rc, 0)
            if choca_spot(c, 6, True) or _tapado(c, 5) or rnd.random() < 0.04:
                continue
            ga, gb = math.degrees(GRIETA / r0), math.degrees(GRIETA / r1)
            puntos = [polar(a0 + ga, r0 + GRIETA, 0), polar(a1 - ga, r0 + GRIETA, 0),
                      polar(a1 - gb, r1 - GRIETA, 0), polar(a0 + gb, r1 - GRIETA, 0)]
            # La cara de arriba en sentido antihorario visto desde arriba (los ángulos del cráter
            # crecen al revés en Blender).
            puntos = [V((q.x - c.x, q.y - c.y)) for q in reversed(puntos)]
            top = AGUA + rnd.uniform(0.15, 0.5)
            arriba = rnd.choice(("hielo", "hielo", "escarcha", "nieve"))
            if rc >= VARADA_R:
                varada.prisma(c, puntos, suelo(r0) - 0.6, top, arriba, "hielo4")
                m = varada
            else:
                flota.prisma(c, puntos, AGUA - 1.3, top, arriba, "hielo2")
                m = flota
            if rnd.random() < 0.2:
                m.prisma(c + V((rnd.uniform(-1.5, 1.5), rnd.uniform(-1.5, 1.5), 0)), contorno(2.6, 6, 0.4), top - 0.1,
                         top + rnd.uniform(0.3, 0.8), "nieve", "nieve")
        r0 = r1


def ventisqueros(m):
    """Rampas de nieve contra el pie de la pared, casi corridas."""
    paso = math.degrees(8.0 / 187)
    a = rnd.uniform(0, paso)
    while a < 360:
        ang = a + rnd.uniform(-0.4, 0.4)
        r = 187.0 + rnd.uniform(-0.8, 0.8)
        if not _tapado(polar(ang, r, 0), 3) and not choca_spot(polar(ang, r, 0), 4, True):
            top = AGUA + rnd.uniform(3, 7)
            fondo = suelo(r - 4) - 0.5
            m.bloque(polar(ang, r, (top + fondo) / 2), (8, rnd.uniform(8.5, 10.5), top - fondo), "nieve", "escarcha",
                     ejes(ang, rnd.uniform(0.25, 0.45), rnd.uniform(-0.12, 0.12)))
        a += paso


def crestas(m, cuantas=7):
    """Bancos de hielo grandes y altos, varados en la repisa (r 160 a 186)."""
    hechas = 0
    for _ in range(400):
        if hechas >= cuantas:
            break
        rad = rnd.uniform(10, 17)
        r = rnd.uniform(VARADA_R + rad * 0.5, LAGO - 4 - rad * 0.4)
        p = polar(rnd.uniform(0, 360), r, 0)
        top = AGUA + rnd.uniform(2.5, 5)
        if not zona_ok(p, rad * 1.1, top, 2) or glaciar.toca(p, rad * 1.1, 2):
            continue
        forma = contorno(rad, rnd.randint(8, 10), rnd.uniform(0.25, 0.55))
        fondo = suelo(r - rad * 1.2) - 0.6
        m.prisma(p, forma, fondo, top, rnd.choice(("nieve", "hielo", "escarcha")), "hielo2")
        m.prisma(p + V((rnd.uniform(-2, 2), rnd.uniform(-2, 2), 0)), [q * 0.6 for q in forma], top - 0.2,
                 top + rnd.uniform(1.2, 2.6), "nieve", "hielo")
        ocupar(p, rad * 1.1)
        hechas += 1


def icebergs(m, cuantos=5):
    """Icebergs altos que flotan, donde los lugares del zorro dejan lugar."""
    hechos = 0
    for _ in range(1500):
        if hechos >= cuantos:
            break
        rad = rnd.uniform(8, 12)
        r = rnd.uniform(126 + rad * 1.3, 176 - rad * 1.3)
        p = polar(rnd.uniform(0, 360), r, 0)
        alto = rnd.uniform(15, 25)
        if not zona_ok(p, rad * 1.3, AGUA + alto, 4) or glaciar.toca(p, rad * 1.3, 4):
            continue
        falda = max(AGUA - 6, suelo(r + rad * 1.3) + 0.6)
        if falda > AGUA - 1.5:
            continue
        forma = contorno(rad, 8, 0.3)
        m.prisma(p, [q * 1.3 for q in forma], falda, AGUA - 0.3, "hielo3", "hielo3")
        z0 = AGUA - 0.5
        pisos = 4
        for k in range(pisos):
            z1 = AGUA + alto * (k + 1) / pisos
            esc = 1 - 0.2 * k
            corr = V((rnd.uniform(-1, 1), rnd.uniform(-1, 1), 0)) * rad * 0.12 * k
            m.prisma(p + corr, [q * esc for q in contorno(rad, 7, 0.3, 0.12)], z0, z1,
                     "nieve" if k == pisos - 1 else rnd.choice(("nieve", "hielo")), "hielo" if k % 2 else "hielo2")
            z0 = z1 - 0.4
        for _ in range(2):  # agujas encima
            q = p + V((rnd.uniform(-1, 1), rnd.uniform(-1, 1), 0)) * rad * 0.25
            h = rnd.uniform(3, 6)
            g = ejes(rnd.uniform(0, 360), rnd.uniform(-0.3, 0.3), rnd.uniform(0, 3))
            m.bloque(q + V((0, 0, AGUA + alto + h / 2 - 1)), (rad * 0.35, rad * 0.3, h), "nieve", "hielo", g)
        ocupar(p, rad * 1.3)
        hechos += 1


def construir(varada, flota):
    """Primero lo alto (ocupa su lugar); al final, la banquisa alrededor."""
    icebergs(flota)
    crestas(varada)
    ventisqueros(varada)
    banquisa(varada, flota)
