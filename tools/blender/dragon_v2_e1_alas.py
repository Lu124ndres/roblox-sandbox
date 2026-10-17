r"""
Alas de murciélago de la cría del dragón marino v2 (la carga dragon_v2_e1_geometria.py).

Vista de arriba del ala izquierda, en celdas (x hacia afuera, -y hacia el hocico):
  - Brazo (Ala1): el borde de adelante sube del hombro (x 4, y -3, detrás de la mitad del
    pecho) a la muñeca (x 10), 1:2 hacia adelante. Al subir, el ala no llega a la cabeza: la
    muñeca queda detrás de las aletitas de las mejillas. Color del cuerpo, grueso (toda la
    altura del segmento).
  - Muñeca (Ala2): un nudo más alto con la garrita del pulgar hacia adelante.
  - Tres dedos en abanico desde la muñeca: el 1 hacia afuera (1:2 hacia atrás) hasta la punta del
    ala, el 2 hacia atrás y afuera (2:1) y el 3 derecho hacia atrás, sobre la teja de Ala1 y Ala2.
    El dedo 1 es el borde de adelante (grueso); el 2 y el 3 van en relieve sobre la membrana.
  - Membrana llena entre los dedos, con el borde de atrás en festón cóncavo: entre punta y punta
    se mete hacia la muñeca, y las puntas quedan en las puntas de los dedos. La de Ala1 (junto al
    cuerpo) es apenas más oscura y llega hasta la cadera.
Tejas (docs/plan_dragon_v2.md, "Juntas"): Ala1 va de x 4 a 11 (membrana en z 10), Ala2 de 10 a
15 (z 11) y Ala3 de 14 a 18 (z 12); cada uno empieza una celda adentro del anterior y una más
arriba. Los huesos (brazo, nudo y dedos) de cada segmento no pasan del borde donde empieza el
siguiente, así nunca quedan dos caras en el mismo plano.
Alturas de cada segmento (z0 = abajo de la membrana): membrana z0..z0+1, dedos en relieve
z0+1..z0+2, borde de adelante z0..z0+2, nudo de la muñeca z0..z0+3.
"""


def alas():
    a = "Alas"
    # Ala1: brazo y la membrana junto al cuerpo (del hombro a la cadera).
    h = "Ala{lado}1"
    par_prisma(h, a, "cuerpo", [(4, -3), (10, -6), (10, -4), (4, -1)], (10, 12))
    par_lamina(h, a, "membrana_osc", [(4, -1), (10, -4), (11, -4), (11, 9), (10, 11), (8, 9), (6, 7), (4, 6)],
               (10, 11))
    # Ala2: muñeca con el pulgar, el comienzo de los dedos 1 y 2 y el dedo 3 entero.
    h = "Ala{lado}2"
    par_prisma(h, a, "cuerpo", [(10, -6), (12, -6), (12, -3), (10, -3)], (11, 14))  # nudo
    par_prisma(h, a, "garra", [(10, -6), (12, -6), (11, -8)], (11, 13))  # pulgar
    par_prisma(h, a, "cuerpo", [(12, -6), (14, -5), (14, -3), (12, -4)], (11, 13))  # dedo 1
    par_prisma(h, a, "cuerpo", [(12, -3), (13, -3), (14, -1), (14, 1)], (12, 13))  # dedo 2
    par_prisma(h, a, "cuerpo", [(10, -3), (11, -3), (11, 9), (10, 11)], (12, 13))  # dedo 3
    par_lamina(h, a, "aleta", [(10, -3), (12, -3), (12, -4), (14, -3), (15, -3), (15, 6), (14, 6), (11, 9),
                               (10, 11)], (11, 12))
    # Ala3: la punta del dedo 1 (la del ala) y la del dedo 2, con el festón entre ellas.
    h = "Ala{lado}3"
    par_prisma(h, a, "cuerpo", [(14, -5), (18, -3), (16, -2), (14, -3)], (12, 14))  # dedo 1
    par_prisma(h, a, "cuerpo", [(14, -1), (17, 5), (17, 7), (14, 1)], (13, 14))  # dedo 2
    par_lamina(h, a, "aleta", [(14, -3), (16, -2), (18, -3), (16, 1), (18, 5), (17, 7), (15, 6), (14, 6)],
               (12, 13))
