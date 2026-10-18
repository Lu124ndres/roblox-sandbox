r"""
Alas de murciélago del dragón marino v2 adulto (la carga dragon_v2_e3_geometria.py): lo que manda
en la silueta, como en la referencia del usuario.

Vista de arriba del ala izquierda, en celdas (x hacia afuera, -y hacia el hocico):
  - Brazo (Ala1): grueso, por el borde de adelante del hombro (x 3) a la muñeca (x 7), 1:2 hacia
    adelante. La muñeca queda cerca del cuerpo, como en la referencia: los dedos son lo largo.
  - Muñeca (Ala2): un nudo alto con la garra del pulgar hacia adelante. Queda detrás de la
    cabeza y de los cuernos: al subir el ala no llega a las mejillas.
  - Tres dedos larguísimos en abanico desde la muñeca: el 1 derecho hacia afuera hasta la punta
    del ala (el borde de adelante, grueso; termina en cara plana en x = 18 para que la envergadura
    mida exacto y de ahí sale el gancho hacia atrás), el 2 hacia atrás y afuera (1:2) y el 3
    derecho hacia atrás. El 2 y el 3 son las venas: en relieve sobre la membrana, de brasa.
  - Membrana llena entre los dedos con el borde de atrás muy festoneado: arcos cóncavos hondos
    entre punta y punta (se meten hacia la muñeca) y cada punta de dedo sale en gancho más allá
    de la membrana. La de Ala1 nace del costado del cuerpo y llega hasta la cadera.
  - El borde de atrás es una tira de brasa: el festón corrido una celda hacia afuera (borde()).
Tejas (docs/plan_dragon_v2.md, "Juntas"): Ala1 va de x 3 a 8 (membrana en z 9), Ala2 de 7 a 13
(z 10) y Ala3 de 12 a 18 (z 11); cada uno empieza una celda adentro del anterior y una más
arriba. Los huesos (brazo, nudo y dedos) de cada segmento no pasan del borde donde empieza el
siguiente, así nunca quedan dos caras en el mismo plano.
Alturas de cada segmento (z0 = abajo de la membrana): membrana y borde z0..z0+1, venas en relieve
z0+1..z0+2, dedo de adelante z0..z0+2, nudo de la muñeca z0..z0+3.
"""


def borde(parte, coleccion, color, festón, d, rango):
    """Tira del borde de la membrana: entre el festón (polilínea de la cuadrícula) y el mismo
    festón corrido `d` celdas hacia afuera, un paralelogramo por tramo. Los vecinos comparten el
    lado corrido, así que la tira no se solapa ni deja huecos; los tramos paralelos a `d` no tienen
    ancho y se saltan."""
    for p, q in zip(festón, festón[1:]):
        e = (q[0] - p[0], q[1] - p[1])
        if e[0] * d[1] - e[1] * d[0] == 0:
            continue
        par_prisma(parte, coleccion, color, [p, q, (q[0] + d[0], q[1] + d[1]), (p[0] + d[0], p[1] + d[1])],
                   rango)


def alas():
    a = "Alas"
    # Ala1: brazo y la membrana junto al cuerpo, del hombro a la cadera.
    h = "Ala{lado}1"
    par_prisma(h, a, "cuerpo", [(3, -3), (7, -5), (7, -2), (3, 0)], (9, 11))
    festón = [(7, 7), (6, 5), (5, 4), (4, 4), (3, 5)]
    par_lamina(h, a, "membrana", [(3, 0), (7, -2), (7, -4), (8, -4), (8, 7)] + festón, (9, 10))
    borde(h, a, "borde", festón, (-1, 1), (9, 10))
    # Ala2: muñeca con el pulgar, el comienzo de los dedos 1 y 2 y el dedo 3 entero.
    h = "Ala{lado}2"
    par_prisma(h, a, "cuerpo_osc", [(7, -7), (9, -7), (9, -4), (7, -4)], (10, 13))  # nudo
    par_prisma(h, a, "garra", [(7, -7), (9, -7), (8, -8)], (10, 12))  # pulgar
    par_prisma(h, a, "cuerpo", [(9, -7), (12, -7), (12, -5), (9, -5)], (10, 12))  # dedo 1
    par_prisma(h, a, "borde", [(9, -4), (10, -4), (12, -2), (12, -1)], (11, 12))  # dedo 2
    par_prisma(h, a, "borde", [(7, -4), (8, -4), (8, 8), (7, 7)], (11, 12))  # dedo 3, en gancho
    festón = [(12, 2), (10, 3), (9, 5), (8, 7)]
    par_lamina(h, a, "membrana", [(7, -4), (9, -4), (9, -5), (13, -5), (13, 1)] + festón + [(7, 7)],
               (10, 11))
    borde(h, a, "borde", festón, (1, 1), (10, 11))
    # Ala3: la punta del dedo 1 (la del ala, con el gancho hacia atrás) y la del dedo 2. El borde de
    # atrás va en diagonal de la punta hacia el cuerpo, como en la referencia.
    h = "Ala{lado}3"
    par_prisma(h, a, "cuerpo", [(12, -7), (17, -7), (17, -5), (12, -5)], (11, 13))  # dedo 1
    par_prisma(h, a, "cuerpo", [(17, -7), (18, -6), (18, -4), (17, -5)], (11, 13))  # punta
    par_prisma(h, a, "pua", [(17, -5), (18, -4), (17, -2)], (11, 13))  # gancho de la punta
    par_prisma(h, a, "borde", [(12, -2), (15, 1), (14, 1), (12, -1)], (12, 13))  # dedo 2
    par_prisma(h, a, "pua", [(14, 1), (15, 1), (15, 3)], (12, 13))  # gancho del dedo 2
    afuera = [(17, -2), (15, -2), (14, -1), (15, 1)]  # entre las puntas 1 y 2
    atras = [(14, 1), (12, 2)]  # entre la punta 2 y la 3
    par_lamina(h, a, "membrana", [(12, -5), (17, -5)] + afuera + atras, (11, 12))
    borde(h, a, "borde", afuera, (1, 1), (11, 12))
    borde(h, a, "borde", atras, (1, 1), (11, 12))
