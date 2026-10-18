r"""
Alas de murciélago de la cría del dragón marino v2 (la carga dragon_v2_e1_geometria.py): lo que
domina la silueta, como en la referencia del usuario. 36 celdas de punta a punta (x -18..18).

Vista de arriba del ala izquierda, en celdas (x hacia afuera, -y hacia el hocico):
  - Brazo (Ala1): el borde de adelante, grueso, sube del hombro (x 4, detrás de la mitad del
    pecho) a la muñeca (x 10), 1:2 hacia adelante. La muñeca queda detrás de la cabeza.
  - Muñeca (Ala2): nudo alto con la garra del pulgar en gancho hacia adelante.
  - Tres dedos en abanico desde la muñeca: el 1 (borde de adelante, grueso) hasta la punta del
    ala, que termina en un gancho marfil hacia atrás; el 2 hacia atrás y afuera (1:2) y el 3
    derecho hacia atrás. El 2 y el 3 van en relieve sobre la membrana, color de brasa (venas).
  - Membrana llena entre los dedos, del costado del cuerpo a la cadera, con el borde de atrás
    muy festoneado: entre punta y punta un arco cóncavo se mete hacia la muñeca (el más hondo, 12
    celdas detrás del borde de adelante) y las puntas de los dedos quedan afiladas. El borde de
    atrás de cada arco lleva una franja de brasa (la luz de abajo de la referencia).
Tejas (docs/plan_dragon_v2.md, "Juntas"): Ala1 va de x 4 a 11 (membrana en z 10), Ala2 de 10 a
15 (z 11) y Ala3 de 14 a 18 (z 12); cada uno empieza una celda adentro del anterior y una más
arriba. Los huesos (brazo, nudo y dedos) de cada segmento no pasan del borde donde empieza el
siguiente, así nunca quedan dos caras en el mismo plano.
Alturas de cada segmento (z0 = abajo de la membrana): membrana z0..z0+1, dedos en relieve
z0+1..z0+2, borde de adelante z0..z0+2, nudo de la muñeca z0..z0+3.
"""


def membrana(h, contorno, desde, hasta, z, color="membrana"):
    """La lámina de un segmento con la franja de brasa en el borde de atrás: contorno[desde..hasta]
    es el festón (sin lados verticales; sus dos puntas sobre lados verticales del contorno). La
    franja es el festón y el mismo corrido una celda hacia adelante (-y); la membrana, el resto."""
    cola = contorno[desde:hasta + 1]
    for p, q in zip(cola, cola[1:]):
        assert p[0] != q[0], f"{h}: lado vertical en el festón {p}-{q}"
    corrido = [(x, y - 1) for x, y in cola]
    par_lamina(h, "Alas", color, contorno[:desde] + corrido + contorno[hasta + 1:], z)
    par_lamina(h, "Alas", "borde", cola + corrido[::-1], z)


def alas():
    a = "Alas"
    # Ala1: brazo y la membrana junto al cuerpo (del hombro a la cadera), con el arco de adentro.
    h = "Ala{lado}1"
    par_prisma(h, a, "cuerpo", [(4, -3), (10, -6), (10, -4), (4, -1)], (10, 12))
    membrana(h, [(4, -1), (10, -4), (11, -4), (11, 8), (10, 10), (9, 8), (8, 6), (6, 5), (4, 4)], 3, 8,
             (10, 11))
    # Ala2: muñeca con el pulgar, el comienzo de los dedos 1 y 2 y el dedo 3 entero.
    h = "Ala{lado}2"
    par_prisma(h, a, "cuerpo", [(10, -6), (12, -6), (12, -3), (10, -3)], (11, 14))  # nudo
    par_prisma(h, a, "garra", [(10, -6), (12, -6), (11, -7)], (11, 13))  # pulgar
    par_prisma(h, a, "cuerpo", [(12, -6), (14, -5), (14, -3), (12, -4)], (11, 13))  # dedo 1
    par_prisma(h, a, "borde", [(11, -3), (12, -3), (14, 1), (14, 3)], (12, 13))  # dedo 2
    par_prisma(h, a, "borde", [(10, -3), (11, -3), (11, 8), (10, 10)], (12, 13))  # dedo 3
    membrana(h, [(10, -3), (12, -3), (12, -4), (14, -3), (15, -3), (15, 7), (14, 6), (12, 6), (11, 8),
                 (10, 10)], 5, 9, (11, 12))
    # Ala3: la punta del dedo 1 (la del ala, con el gancho) y la del dedo 2, con el festón entre
    # ellas y el arco que sigue hacia el dedo 3.
    h = "Ala{lado}3"
    par_prisma(h, a, "cuerpo", [(14, -5), (18, -3), (16, -2), (14, -3)], (12, 14))  # dedo 1
    par_prisma(h, a, "cuerpo", [(16, -2), (18, -3), (18, -1), (17, 1), (16, 0)], (12, 14))  # gancho
    par_prisma(h, a, "borde", [(14, 1), (16, 5), (16, 8), (14, 4)], (13, 14))  # dedo 2
    membrana(h, [(14, -3), (16, -2), (15, 0), (15, 2), (16, 4), (16, 8), (15, 7), (14, 6)], 5, 7,
             (12, 13))
