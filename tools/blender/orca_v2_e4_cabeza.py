r"""
Cabeza de la Orca v2, etapa 4 (anciana): hocico bajo y romo, cráneo acorazado con las grietas
cian en cruz, cejas en V, cuencas rasgadas para los ojos (la pupila la pone el código) con una
cicatriz que cruza la izquierda, la mancha de orca y la boca bien abierta con filas de colmillos largos (uno roto). Lo carga
orca_v2_e4_geometria.py con exec; usa bloque(), par() (de minotauro_v2_bloques.py) y prisma(),
par_prisma() (de dragon_v2_formas.py). Todo en celdas.

La boca queda bien abierta en reposo (z 6..12, más que en la E3): los colmillos de arriba bajan
cuatro celdas hasta z 8 y los de abajo suben hasta z 10, en capas de profundidad distintas (y) o
corridos a lo largo para que no compartan plano. Las grietas de la frente van al ras de las placas:
metidas, su cara quedaría en el plano de la cuña del cráneo.
"""


def cabeza():
    c = "Cabeza"
    # Hocico bajo y romo, una celda más angosto que el cráneo, con el borde de arriba en cuña.
    bloque(c, c, "cuerpo", (-6, 6), (-30, -26), (12, 14))
    bloque(c, c, "cuerpo", (-6, 6), (-30, -26), (14, 15), recorte={"y-": 1})
    # Cráneo con los bordes de arriba achaflanados; arriba, cuatro placas y la grieta en cruz.
    bloque(c, c, "cuerpo", (-7, 7), (-26, -16), (12, 17))
    bloque(c, c, "cuerpo", (-7, 7), (-26, -16), (17, 18), recorte={"x-": 1, "x+": 1})
    for ys in ((-25, -22), (-21, -17)):
        par(c, c, "placa", (1, 5), ys, (18, 19))
    bloque(c, c, "brillo", (-1, 1), (-25, -17), (18, 19))
    par(c, c, "brillo", (1, 4), (-22, -21), (18, 19))
    # Mejillas: cierran la boca atrás, bajo los ojos.
    bloque(c, c, "cuerpo", (-7, 7), (-21, -16), (6, 12))
    # Por dentro, roja: la pared del fondo y el paladar.
    bloque(c, c, "boca", (-5, 5), (-22, -21), (6, 12))
    bloque(c, c, "boca", (-5, 5), (-29, -22), (11, 12))
    # Cejas acorazadas en V: bajan hacia el medio y salen por los costados sobre los ojos.
    par_prisma(c, c, "ceja", [(2, 15), (4, 15), (8, 17), (8, 19), (6, 19)], (-28, -25), eje="y")
    cuencas(c)
    # Cicatriz que cruza el ojo izquierdo de arriba abajo, en relieve sobre la ceja y la mejilla:
    # se corta en la cuenca para no taparla.
    bloque(c, c, "cicatriz", (8, 9), (-27, -26), (17, 19))
    bloque(c, c, "cicatriz", (8, 9), (-27, -26), (12, 14))
    bloque(c, c, "cicatriz", (-9, -7), (-23, -22), (13, 18))  # y otra, más corta, en el derecho
    # La mancha de orca, en cian, detrás del ojo y subiendo hacia atrás.
    par_prisma(c, c, "brillo", [(-20, 12), (-18, 12), (-16, 13), (-16, 16), (-17, 16), (-20, 13)],
               (7, 8), eje="x")
    colmillos_arriba(c)
    mandibula()


def cuencas(c):
    """La cuenca de cada ojo: una sola cara oscura que mira afuera y adelante en cuña 1:1
    (x - y = 34), para la pupila de Neon que pone el código. Rasgada y feroz: un paralelogramo de 2
    de alto que sube 2:1 hacia afuera, entre el plano de abajo de la ceja en V y una mejilla con la
    misma pendiente. La enmarcan la ceja arriba, la mejilla abajo, el poste de atrás y, del lado de
    adentro, el hocico y una cuña que llena el hueco bajo la punta de la ceja (si no, se veía el
    costado de la cuenca). No es un prisma: va como casco convexo de sus seis esquinas."""
    for s in (1, -1):
        esquinas = [(6, -28, 14), (8, -26, 15), (6, -26, 14), (6, -28, 16), (8, -26, 17), (6, -26, 16)]
        PARTES.setdefault(c, {"coleccion": c, "bloques": []})["bloques"].append(
            ([V((s * x, y, z)) * CELDA for x, y, z in esquinas], "cuenca"))
    par_prisma(c, c, "cuerpo", [(6, 12), (8, 12), (8, 15), (6, 14)], (-28, -26), eje="y")  # mejilla
    par(c, c, "cuerpo", (7, 8), (-26, -24), (12, 17))  # poste de atrás, hasta dentro de la ceja
    par_prisma(c, c, "cuerpo", [(4, 15), (6, 15), (6, 16)], (-28, -26), eje="y")  # bajo la ceja


def _colmillo(arriba, a, forma="largo"):
    """Colmillo de 2 de ancho que cuelga de z 12 o sube desde z 6: largo (4 celdas, punta 2:1),
    corto (2) o roto (el corte en bisel 1:2)."""
    base, s = (12, -1) if arriba else (6, 1)
    if forma == "largo":
        return [(a, base), (a + 2, base), (a + 2, base + 2 * s), (a + 1, base + 4 * s), (a, base + 2 * s)]
    if forma == "corto":
        return [(a, base), (a + 2, base), (a + 1, base + 2 * s)]
    return [(a, base), (a + 2, base), (a + 2, base + 2 * s), (a, base + s)]


def colmillos_arriba(c):
    # Fila de adelante, al ras del hocico: largos en el medio, cortos en las esquinas y uno roto
    # (el de la derecha del medio).
    prisma(c, c, "diente", _colmillo(True, 1), (-30, -29), eje="y")
    prisma(c, c, "diente", _colmillo(True, -3, "roto"), (-30, -29), eje="y")
    par_prisma(c, c, "diente", _colmillo(True, 4, "corto"), (-30, -29), eje="y")
    # Segunda fila, detrás de la de abajo: cortos que asoman entre los largos.
    par_prisma(c, c, "diente", _colmillo(True, 0, "corto"), (-28, -27), eje="y")
    # A los costados, al ras del hocico y del cráneo.
    for a in (-28, -24):
        par_prisma(c, c, "diente", _colmillo(True, a), (5, 6), eje="x")


def mandibula():
    m = "Mandibula"
    # Quijada blanca con el borde de abajo achaflanado. Termina una celda antes de la garganta
    # (y -19; la garganta es del Pecho y empieza en y -18) y atrás sube en cuña 1:2 por abajo: al
    # abrir la boca, la esquina de atrás y abajo gira hacia la garganta (guía, 4, "Mandíbula").
    bloque(m, m, "blanco", (-6, 6), (-30, -21), (3, 5))
    bloque(m, m, "blanco", (-6, 6), (-30, -21), (2, 3), fin="-", recorte={"x-": 1, "x+": 1})
    bloque(m, m, "blanco", (-6, 6), (-21, -19), (3, 5), eje="y", recorte={"z-": 1})
    # Borde blanco (los costados y adelante) y el piso rojo con la lengua.
    par(m, m, "blanco", (5, 6), (-30, -19), (5, 6))
    bloque(m, m, "blanco", (-5, 5), (-30, -28), (5, 6))
    bloque(m, m, "boca", (-5, 5), (-28, -19), (5, 6))
    bloque(m, m, "lengua", (-3, 3), (-26, -20), (6, 7))
    # Colmillos de abajo, entre los de arriba: el del medio y un par, largos; a los costados,
    # corridos media cuña respecto de los de arriba.
    prisma(m, m, "diente", _colmillo(False, -1), (-29, -28), eje="y")
    par_prisma(m, m, "diente", _colmillo(False, 3), (-29, -28), eje="y")
    for b in (-26, -22):
        par_prisma(m, m, "diente", _colmillo(False, b), (5, 6), eje="x")
