r"""
Cuerpo de la Orca v2, etapa 4 (anciana): los seis anillos acorazados (Pecho y Cola1..Cola5), la
aleta dorsal desgarrada, las pectorales con garras y la cola en V mordida y con púas. Lo carga
orca_v2_e4_geometria.py con exec; usa bloque(), par() (de minotauro_v2_bloques.py) y prisma(),
par_prisma(), lamina(), par_lamina(), trocear() (de dragon_v2_formas.py). Todo en celdas.

Anillo acorazado: un núcleo cian (las grietas) una celda más chico que el anillo, envuelto en placas
de una celda de grueso. Las vetas son las juntas entre placas, de una celda: a lo largo (surcos) y
de través (cortes, distintos en cada banda, para que se crucen en T, y a dos celdas o más de las
puntas del anillo: más cerca dejan una placa de una celda); los cortes de la banda de arriba siguen
por el lomo, por la cuña y la placa. Por ahí asoma el núcleo, una celda adentro.
Juntas: como en la E3, cada anillo nace una celda dentro del anterior y es más chico en todos los
lados. El núcleo termina una celda antes del final del anillo: ese hueco lo llena justo el anillo
siguiente, así el costado de su placa no queda en el plano del núcleo de este (la Cola5, que es la
última, lo tapa con una placa).
"""


def tramos(y, cortes):
    """Los tramos de y = (desde, hasta) que dejan los cortes (cada uno, de c a c + 1)."""
    salida, a = [], y[0]
    for c in cortes:
        if c > a:
            salida.append((a, c))
        a = c + 1
    if y[1] > a:
        salida.append((a, y[1]))
    return salida


def anillo(parte, y, ancho, z, surcos, cortes, colores, placa, sigue=True, frente=False, herida=None):
    """Un tramo del cuerpo de y = (desde, hasta), medio ancho `ancho` y z = (abajo, arriba).
    surcos: z de las vetas a lo largo; cortes: por banda (de abajo arriba), las y de las vetas de
    través; colores: el de cada banda (el de abajo también tiñe la cuña de la panza); placa: medio
    ancho de la placa del lomo; herida = (banda, tramo, color): esa placa, solo a la izquierda."""
    t = "Torso"
    (y0, y1), w, (z0, z1) = y, ancho, z
    bloque(parte, t, "brillo", (1 - w, w - 1), (y0 + frente, y1 - 1), (z0 + 1, z1 - 1))
    if frente:  # el Pecho: tapa de adelante, detrás de la cabeza
        bloque(parte, t, "cuerpo", (1 - w, w - 1), (y0, y0 + 1), (z0 + 1, z1 - 1))
    if not sigue:  # la Cola5: tapa de atrás, entre los lóbulos de la cola
        bloque(parte, t, "cuerpo", (1 - w, w - 1), (y1 - 1, y1), (z0 + 1, z1 - 1))
    # La primera celda va dentro del anillo anterior: ahí las cuñas de arriba y de abajo son
    # cajas, que llenan su hueco hasta las esquinas (si no, por el chaflán asoma su núcleo).
    entra = 0 if frente else 1
    if entra:
        bloque(parte, t, colores[0], (-w, w), (y0, y0 + 1), (z0, z0 + 1))
        bloque(parte, t, "cuerpo", (-w, w), (y0, y0 + 1), (z1 - 1, z1))
    bloque(parte, t, colores[0], (-w, w), (y0 + entra, y1), (z0, z0 + 1), fin="-",
           recorte={"x-": 1, "x+": 1})
    bajos = [z0 + 1] + [s + 1 for s in surcos]
    altos = list(surcos) + [z1 - 1]
    for k, banda in enumerate(zip(bajos, altos)):
        for i, ys in enumerate(tramos(y, cortes[k])):
            if herida and herida[:2] == (k, i):
                bloque(parte, t, herida[2], (w - 1, w), ys, banda)
                bloque(parte, t, colores[k], (-w, 1 - w), ys, banda)
            else:
                par(parte, t, colores[k], (w - 1, w), ys, banda)
    for ys in tramos((y0 + entra, y1), cortes[-1]):
        bloque(parte, t, "cuerpo", (-w, w), ys, (z1 - 1, z1), recorte={"x-": 1, "x+": 1})
    for ys in tramos((y0 + 1, y1 - 1), cortes[-1]):
        bloque(parte, t, "placa", (-placa, placa), ys, (z1, z1 + 1))
    # Por el medio del lomo, la grieta de través sube al ras de la placa (se ve desde arriba);
    # en los hombros queda metida.
    for c in cortes[-1]:
        bloque(parte, t, "brillo", (-placa, placa), (c, c + 1), (z1 - 1, z1 + 1))


def cuerpo():
    # El lomo sube detrás de la cabeza (z 19 y la placa hasta 20) y la panza baja (z 2): de ahí,
    # cada anillo baja una celda arriba y sube una abajo hasta la cola.
    anillo("Pecho", (-16, -3), 8, (2, 19), [6, 12], [[-6], [-8], [-12]],
           ["blanco", "cuerpo", "placa"], 6, frente=True)
    bloque("Pecho", "Torso", "blanco", (-6, 6), (-18, -16), (2, 6))  # garganta
    anillo("Cola1", (-4, 6), 7, (3, 18), [7, 12], [[-1], [3], [0]], ["panza", "cuerpo", "placa"], 5,
           herida=(1, 0, "boca"))
    anillo("Cola2", (5, 13), 6, (4, 17), [8, 12], [[8], [], [9]], ["panza_osc", "cuerpo", "placa"], 4)
    anillo("Cola3", (12, 19), 5, (5, 16), [10], [[], [16]], ["cuerpo", "placa"], 3)
    anillo("Cola4", (18, 24), 4, (6, 15), [10], [[], [21]], ["cuerpo", "placa"], 2)
    anillo("Cola5", (23, 28), 3, (7, 14), [10], [[], []], ["cuerpo", "placa"], 1, sigue=False)
    # Branquias oscuras detrás de la cabeza, sobre la pectoral.
    for y in (-15, -13, -11):
        par("Pecho", "Torso", "branquia", (8, 9), (y, y + 1), (9, 12))


def dorsal():
    # Alta, echada hacia atrás y desgarrada: el borde de ataque sube 2:1 con una mordida a media
    # altura, el de salida es cóncavo (1:2, 1:1 y 2:1) con otra mordida, y la punta queda en cara
    # plana (z 31). Contorno en yz partido en piezas convexas; del mismo grueso de arriba abajo.
    contorno = [(-10, 16), (8, 16), (8, 18), (4, 20), (3, 21), (1, 21), (0, 22), (1, 23), (0, 24),
                (-2, 28), (-2, 31), (-3, 31), (-6, 25), (-4, 24), (-4, 23), (-6, 21),
                (-8, 21), (-10, 17)]
    for pieza in trocear(contorno):
        prisma("Dorsal", "Aletas", "aleta", pieza, (-1, 1), eje="x")


def pectorales():
    # Bajan hacia afuera 2:1 desde el costado del Pecho; el segundo tramo, más fino y corrido
    # hacia atrás, nace dentro del primero y llega a z 0 con la punta en cara plana. En la punta,
    # tres garras echadas hacia atrás.
    a = "Aletas"
    par_prisma("Aleta{lado}", a, "pectoral", [(6, 10), (6, 5), (12, 2), (12, 7)], (-14, -7), eje="y")
    par_prisma("Aleta{lado}2", a, "pectoral", [(9, 7), (9, 3), (15, 0), (19, 0), (19, 2)], (-13, -5),
               eje="y")
    for y0 in (-13, -10, -7):
        par_prisma("Aleta{lado}2", a, "pua", [(19, y0), (19, y0 + 2), (21, y0 + 4)], (0, 2))


def cola():
    # Cola en V, horizontal: cada lóbulo nace dentro de la Cola5 y se abre 1:1 hacia atrás, con
    # una mordida en el borde de salida y dos púas en el de ataque.
    lobulo = [(1, 24), (4, 24), (13, 33), (11, 33), (9, 32), (8, 30), (5, 30), (3, 29), (1, 28)]
    par_lamina("AletaCola{lado}", "Aletas", "aleta", lobulo, (10, 12))
    for pua in ([(6, 26), (8, 28), (10, 26)], [(9, 29), (11, 31), (13, 29)]):
        par_prisma("AletaCola{lado}", "Aletas", "pua", pua, (10, 12))
