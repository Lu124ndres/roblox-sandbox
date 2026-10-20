r"""
Cabeza de la Orca v2, etapa 1 (cría): cráneo alto y redondeado, hocico corto, cuencas grandes
para los ojos (la pupila la pone el código) con las cejas apenas fruncidas, la mancha de orca
en cian y la boca entreabierta con dientes chicos. Lo carga orca_v2_e1_geometria.py con exec;
usa bloque(), par() (de minotauro_v2_bloques.py) y prisma(), par_prisma() (de
dragon_v2_formas.py). Todo en celdas.

Como en la E3, pero la boca solo entreabierta (z 6..10, con el paladar en z 9..10) y los dientes
de una celda de alto: los de arriba bajan hasta z 9 y los de abajo suben hasta z 7, intercalados.
El hocico queda bajo (hasta z 16) para que se vea la frente: ahí van las cejas, de frente.
"""


def cabeza():
    c = "Cabeza"
    # Hocico corto, una celda más angosto que el cráneo: la punta con los cantos achaflanados y el
    # borde de arriba en cuña.
    bloque(c, c, "cuerpo", (-10, 10), (-24, -21), (10, 15))
    bloque(c, c, "cuerpo", (-10, 10), (-25, -24), (10, 15), eje="y", fin="-", recorte={"x-": 1, "x+": 1})
    bloque(c, c, "cuerpo", (-10, 10), (-24, -21), (15, 16), recorte={"y-": 1, "x-": 1, "x+": 1})
    # Cráneo grande (más ancho y más alto que el Pecho), la frente alta y redondeada en dos
    # escalones, y la placa de arriba.
    # En la franja de los ojos (z 16..20, sobre el hocico) el cráneo va en tres piezas que dejan
    # libre la esquina de adelante a cada lado: ahí va la cuenca (cuencas()).
    bloque(c, c, "cuerpo", (-11, 11), (-21, -8), (10, 16))
    bloque(c, c, "cuerpo", (-7, 7), (-21, -8), (16, 20))
    par(c, c, "cuerpo", (7, 11), (-17, -8), (16, 20))
    bloque(c, c, "cuerpo", (-11, 11), (-21, -8), (20, 21))
    bloque(c, c, "cuerpo", (-11, 11), (-21, -8), (21, 22), recorte={"x-": 1, "x+": 1, "y-": 1})
    bloque(c, c, "cuerpo", (-10, 10), (-20, -8), (22, 23), recorte={"x-": 1, "x+": 1, "y-": 1})
    bloque(c, c, "placa", (-7, 7), (-19, -9), (23, 24), recorte={"y-": 1})
    # Mejillas: cierran la boca atrás, bajo los ojos.
    bloque(c, c, "cuerpo", (-11, 11), (-16, -8), (6, 10))
    # Por dentro, roja: la pared del fondo y el paladar.
    bloque(c, c, "boca", (-9, 9), (-17, -16), (6, 10))
    bloque(c, c, "boca", (-9, 9), (-23, -17), (9, 10))
    # Cuencas grandes de cría (4 de alto), hundidas en la esquina de la frente: una sola cara
    # oscura por ojo que mira afuera y adelante en cuña 1:1 (x - y = 28), para la pupila de Neon
    # que pone el código. Las enmarca el cráneo arriba, abajo, adentro y atrás; ya no asoman.
    par_prisma(c, c, "cuenca", [(7, -21), (11, -17), (7, -17)], (16, 20))
    # Ceja apenas fruncida: baja 2:1 hacia adentro, sobre el ojo; la punta de afuera queda dentro
    # del chaflán del cráneo (si llegaba al costado, asomaba como un cuerno).
    par_prisma(c, c, "ceja", [(4, 19), (6, 19), (10, 21), (10, 22)], (-23, -19), eje="y")
    # La mancha de orca, en cian, detrás del ojo y subiendo hacia atrás; empieza donde termina la
    # cuenca (y -17): una celda antes, su punta tapaba la esquina de atrás del ojo.
    par_prisma(c, c, "brillo", [(-17, 15), (-15, 15), (-11, 17), (-11, 19), (-13, 19), (-17, 17)],
               (11, 12), eje="x")
    dientes_arriba(c)
    mandibula()


def _diente(arriba, a):
    """Triángulo de 2 de ancho y 1 de alto: cuelga de z 10 o sube desde z 6."""
    if arriba:
        return [(a, 10), (a + 2, 10), (a + 1, 9)]
    return [(a, 6), (a + 2, 6), (a + 1, 7)]


def dientes_arriba(c):
    for a in (1, 4, 7):  # adelante, una celda detrás de la cara del hocico
        par_prisma(c, c, "diente", _diente(True, a), (-24, -23), eje="y")
    for a in (-24, -20):  # a los costados, al ras del hocico
        par_prisma(c, c, "diente", _diente(True, a), (9, 10), eje="x")


def mandibula():
    m = "Mandibula"
    # Quijada blanca con el borde de abajo y la barbilla achaflanados; termina en la garganta.
    bloque(m, m, "blanco", (-10, 10), (-24, -10), (2, 5))
    bloque(m, m, "blanco", (-10, 10), (-24, -10), (1, 2), fin="-", recorte={"x-": 1, "x+": 1, "y-": 1})
    # Borde blanco (los costados y adelante) y el piso rojo con la lengua.
    par(m, m, "blanco", (9, 10), (-24, -10), (5, 6))
    bloque(m, m, "blanco", (-9, 9), (-24, -22), (5, 6))
    bloque(m, m, "boca", (-9, 9), (-22, -10), (5, 6))
    bloque(m, m, "lengua", (-4, 4), (-21, -14), (6, 7))
    # Dientes de abajo, entre los de arriba.
    prisma(m, m, "diente", _diente(False, -1), (-23, -22), eje="y")
    for b in (2, 5):
        par_prisma(m, m, "diente", _diente(False, b), (-23, -22), eje="y")
    for b in (-22, -18):
        par_prisma(m, m, "diente", _diente(False, b), (9, 10), eje="x")
