r"""
Cabeza de la Orca v2, etapa 2 (joven): la de la E3 (orca_v2_e3_cabeza.py) corrida 4 celdas hacia
atrás, con la quijada una celda más fina, las cuencas de los ojos más altas (menos rasgadas), las
cejas más suaves y menos dientes. Lo carga orca_v2_e2_geometria.py con exec; usa bloque(), par() (de
minotauro_v2_bloques.py) y prisma(), par_prisma() (de dragon_v2_formas.py). Todo en celdas.

La boca queda abierta en reposo (z 6..11, como la de la adulta): los dientes de arriba bajan
hasta z 9 y los de abajo suben hasta z 8, intercalados para que no se crucen. Son 11 (la E3
lleva 15): adelante, un par arriba y uno solo abajo, al medio; a los costados, dos arriba y dos
abajo, alternados a lo largo. Por dentro es roja: el paladar, la pared del fondo y el piso de la
mandíbula. Los dientes van apoyados (no metidos) en el borde de la quijada.
"""


def cabeza():
    c = "Cabeza"
    # Hocico romo, una celda más angosto que el cráneo, con el borde de arriba en cuña.
    bloque(c, c, "cuerpo", (-6, 6), (-27, -23), (11, 14))
    bloque(c, c, "cuerpo", (-6, 6), (-27, -23), (14, 16), recorte={"y-": 1})
    # Cráneo con los bordes de arriba achaflanados y la placa de la frente.
    bloque(c, c, "cuerpo", (-7, 7), (-23, -12), (11, 16))
    bloque(c, c, "cuerpo", (-7, 7), (-23, -12), (16, 17), recorte={"x-": 1, "x+": 1})
    bloque(c, c, "placa", (-5, 5), (-22, -13), (17, 18), recorte={"y-": 1})
    # Mejillas: cierran la boca atrás, bajo los ojos.
    bloque(c, c, "cuerpo", (-7, 7), (-17, -12), (6, 11))
    # Por dentro, roja: la pared del fondo y el paladar.
    bloque(c, c, "boca", (-5, 5), (-18, -17), (6, 11))
    bloque(c, c, "boca", (-5, 5), (-25, -18), (10, 11))
    cuencas(c)
    # Ceja de enojo, más suave que la de la adulta: una celda de alto y baja 2:1 hacia adentro.
    par_prisma(c, c, "ceja", [(5, 15), (8, 15), (8, 16), (7, 16)], (-25, -20), eje="y")
    # La mancha de orca, en cian, detrás del ojo y subiendo hacia atrás.
    par_prisma(c, c, "brillo", [(-20, 12), (-17, 12), (-13, 14), (-13, 15), (-16, 15), (-20, 13)],
               (7, 8), eje="x")
    dientes_arriba(c)
    mandibula()


def cuencas(c):
    """La cuenca de cada ojo, como la de la adulta pero de 3 de alto (la de ella, 2: rasgada): una
    sola cara oscura que mira afuera y adelante en cuña 1:1 (x - y = 31), para la pupila de Neon
    que pone el código. Hundida en un marco que asoma una celda como la ceja: la ceja arriba, la
    mejilla abajo (z 11..12), el poste de atrás y, del lado de adentro, el costado del hocico."""
    par_prisma(c, c, "cuenca", [(6, -25), (8, -23), (6, -23)], (12, 15))
    par(c, c, "cuerpo", (7, 8), (-23, -20), (12, 15))  # poste de atrás
    par(c, c, "cuerpo", (7, 8), (-25, -20), (11, 12))  # mejilla, y su punta junto al hocico
    par(c, c, "cuerpo", (6, 7), (-25, -23), (11, 12))


def _diente(arriba, a):
    """Triángulo de 2 de ancho y 2 de alto: cuelga de z 11 o sube desde z 6."""
    if arriba:
        return [(a, 11), (a + 2, 11), (a + 1, 9)]
    return [(a, 6), (a + 2, 6), (a + 1, 8)]


def dientes_arriba(c):
    # Adelante, un par, una celda detrás de la cara del hocico.
    par_prisma(c, c, "diente", _diente(True, 2), (-26, -25), eje="y")
    for a in (-25, -21):  # a los costados, al ras del hocico
        par_prisma(c, c, "diente", _diente(True, a), (5, 6), eje="x")


def mandibula():
    m = "Mandibula"
    # Quijada blanca con el borde de abajo achaflanado. Termina una celda antes de la garganta
    # (y -15; la garganta es del Pecho y empieza en y -14) y atrás sube en cuña 1:2 por abajo: al
    # abrir la boca, la esquina de atrás y abajo gira hacia la garganta (guía, 4, "Mandíbula").
    # La cuña lleva todo el alto de la quijada (z 4..6) en sus dos últimas celdas.
    bloque(m, m, "blanco", (-6, 6), (-26, -17), (4, 5))
    bloque(m, m, "blanco", (-6, 6), (-26, -17), (3, 4), fin="-", recorte={"x-": 1, "x+": 1})
    bloque(m, m, "blanco", (-6, 6), (-17, -15), (4, 6), eje="y", recorte={"z-": 1})
    # Borde blanco (los costados y adelante) y el piso rojo con la lengua.
    par(m, m, "blanco", (5, 6), (-26, -17), (5, 6))
    bloque(m, m, "blanco", (-5, 5), (-26, -24), (5, 6))
    bloque(m, m, "boca", (-5, 5), (-24, -17), (5, 6))
    bloque(m, m, "lengua", (-3, 3), (-22, -16), (6, 7))
    # Dientes de abajo, entre los de arriba: uno al medio y dos a cada costado.
    prisma(m, m, "diente", _diente(False, -1), (-25, -24), eje="y")
    for b in (-23, -19):
        par_prisma(m, m, "diente", _diente(False, b), (5, 6), eje="x")
