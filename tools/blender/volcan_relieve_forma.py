r"""
Forma de la versión 7 del volcán (volcan_relieve.py): la v6 con dos arreglos. Lo carga
volcan_relieve.py con exec después de volcan_entrada_forma.py.

1. Sin hueco rectangular alrededor del arco:
    silueta()   el contorno del modelo del arco (tools/blender/arco_volcan.py: pilares, arco de
                radio 29.5 sobre 26, pico central a 72.7, picos a los costados a 60.6, cuernos
                hasta 48) más un margen: el techo del hueco del arco la sigue columna por columna,
                con escalones de distinta altura, en vez de cortarse plano a 104
    alero       delante del arco, columnas de roca que vuelan sobre el rellano a distinta
                profundidad (VUELO) y a distinta altura: el borde de arriba queda quebrado
    garganta    detrás del arco, el túnel se ensancha y sube en escalones irregulares hasta el
                hueco del arco (GARGANTA studs), sin marco rectangular
2. Relieve en la cara que mira a la isla (CARA grados a cada lado):
    contrafuertes, barrancos, cornisas, hombros y picos secundarios que rompen la silueta
    vista desde la plaza, y dos coladas de lava que bajan por barrancos hacia los lados del
    arco (nunca sobre el arco ni el puente). ladera() se reemplaza: el resto de la v6 lo usa.
"""

VUELO = (0, 4, 8)  # cuánto vuela cada columna del alero delante del arco
GARGANTA = 26  # largo del ensanche del túnel detrás del arco
CARA = 105  # grados a cada lado del eje del puente con relieve
# Contrafuertes: (grados desde el eje del puente, alto extra, medio ancho)
CONTRAFUERTES = ((-62, 30, 20), (-33, 24, 16), (31, 26, 18), (52, 34, 22), (82, 22, 16))
# Barrancos: (grados, hondura, medio ancho); los dos con lava llevan una colada al fondo
BARRANCOS = ((-47, 20, 10), (-21, 16, 8), (16, 14, 7), (41, 22, 11), (66, 18, 9), (-80, 16, 9))
COLADAS_CARA = ((-21, 0.15, 0.82), (41, 0.1, 0.92))  # (grados, desde u, hasta u)
# Hombros y picos secundarios: (grados, radio, alto extra, radio del bulto)
HOMBROS = ((-76, 330, 78, 52), (-58, 430, 34, 34), (-92, 400, 48, 40), (64, 370, 62, 44),
           (86, 300, 40, 36), (100, 420, 34, 34), (24, 300, 22, 26))

_ladera_v6 = ladera  # el cono natural de la v4 (volcan_cueva_forma.py)


def _desvio_cara(a):
    """Grados con signo desde el eje del puente (hacia la isla)."""
    return (math.degrees(a) - PUERTA_DEG + 180) % 360 - 180


def ladera(rho, a):
    natural = _ladera_v6(rho, a)
    if natural is None:
        return None
    h, H, canal, largo, u = natural
    d = _desvio_cara(a)
    if u < 0 or abs(d) > CARA:
        return natural
    cara = 1 - smooth((abs(d) - (CARA - 30)) / 30)
    medio = math.sin(math.pi * min(max(u, 0.0), 1.0))  # el relieve es más fuerte a media ladera
    extra = 0.0
    for g, alto, ancho in CONTRAFUERTES:
        dist = abs(math.radians(d - g)) * rho
        if dist < ancho:
            extra = max(extra, alto * (1 - (dist / ancho) ** 2) * medio)
    for g, r, alto, radio in HOMBROS:
        gx, gz = r * math.cos(math.radians(g)), r * math.sin(math.radians(g))
        px, pz = rho * math.cos(math.radians(d)), rho * math.sin(math.radians(d))
        dist = math.hypot(px - gx, pz - gz)
        if dist < radio:
            extra = max(extra, alto * (1 - (dist / radio) ** 1.6))
    hondo, en_colada = 0.0, False
    for g, prof, ancho in BARRANCOS:
        centro = g + math.degrees(5 * math.sin(rho * 0.05 + g) / max(rho, 1))
        dist = abs(math.radians(d - centro)) * rho
        if dist < ancho:
            hondo = max(hondo, prof * (1 - (dist / ancho) ** 2) * medio)
            for cg, desde, hasta in COLADAS_CARA:
                if cg == g and desde < u < hasta and dist < 4.5:
                    en_colada = True
    h = h + (extra - hondo) * cara
    # Cornisas: la ladera baja en escalones de distinto alto (cada uno con su repisa).
    banda = 22 + 8 * math.sin(d * 0.07)
    h -= 0.35 * ((h - MAR) % banda) * cara * medio
    h += 4 * _hash(rho // 8, d // 2, 3) * cara - 4
    if en_colada and h > L["waterLevel"] + 3:
        return h, H, 1.0, 1.0, u
    return h, H, 0.0, 0.0, u


def silueta(lateral):
    """Alto (sobre el paseo) que ocupa el arco en esa columna, con margen."""
    x = lateral + 2  # el borde de afuera de la columna
    arco = 26 + math.sqrt(29.5 ** 2 - x ** 2) if x < 29.5 else 0.0
    centro = 72.7 if x <= 7.5 else 0.0
    lados = 60.6 if abs(x - 20) <= 6 else 0.0
    cuernos = 48.0 if 25 <= x <= 36 else 0.0
    return max(arco, centro, lados, cuernos, 30.0) + 3


def piso_rellano(avance, lateral):
    if lateral <= L["bridgeWidth"] / 2 + 2:
        tablero = L["craterDeckHeight"] - (L["craterDeckHeight"] - L["deckHeight"]) * (avance - R_A) / PUENTE_LARGO
        return min(PASEO, ESCALON * math.floor((tablero - 1) / ESCALON))
    return PASEO


def cueva(dx, dz):
    rho, a = math.hypot(dx, dz), math.atan2(dz, dx)
    if rho < WALK_END:
        piso = height(rho, a)
        return piso, material(rho, a, piso), None
    avance, lado = lado_puerta(dx, dz)
    lateral = abs(lado)
    salto = 2 * _hash(lado // 4 + 5, avance // 4, 3)  # escalones de 0, 2 o 4
    vuelo = VUELO[_hash(lado // 4 + 11, 1, 3)]
    if lateral <= 36 and R_A - ARCO_HONDO <= avance <= R_A + ARCO_HONDO + vuelo:
        techo = PASEO + silueta(lateral) + salto
        if avance > R_A + ARCO_HONDO:  # el alero: vuela sobre el rellano
            return piso_rellano(avance, lateral), "basalto", techo + 4
        return PASEO, "basalto", techo
    if R_A - ARCO_HONDO - GARGANTA <= avance < R_A - ARCO_HONDO:
        t = (avance - (R_A - ARCO_HONDO - GARGANTA)) / GARGANTA
        signo = 1 if lado >= 0 else -1
        ancho = pared(avance, signo) + (36 - pared(avance, signo)) * t + salto - 2
        if lateral <= ancho:
            techo = techo_tunel(avance) * (1 - t) + (PASEO + silueta(lateral)) * t + salto
            return PASEO, "basalto", max(techo, techo_tunel(avance))
    if WALK_END - 6 <= avance < R_A - ARCO_HONDO and lateral <= pared(avance, 1 if lado >= 0 else -1):
        return PASEO, "basalto", techo_tunel(avance)
    return None


def fotos_cueva(cam, grilla):
    plaza = -(R_A + ARCO_Z_ISLA + 120)  # Roblox (0, 12, -120): la plaza, mirando al arco
    foto(cam, "1_desde_la_plaza", punto(0, plaza, 12), punto(0, -R_A * 0.5, 150), 22)
    foto(cam, "2_arco_de_cerca", punto(-22, -(R_A + 110), 46), punto(6, -R_A, 78), 26)
    foto(cam, "3_aerea", punto(950, -(R_A + 950), 760), punto(0, -R_A * 0.45, 110), 28)


BLEND = os.path.join(RAIZ, "assets", "blender", "volcan_v2", "volcan_bloques_4f.blend")
RENDERS = os.path.join(RAIZ, "renders", "volcan_v2g")
