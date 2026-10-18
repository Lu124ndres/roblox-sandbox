"""Puente al Cráter del Abismo: una sola rampa lisa y ancha de la isla a la puerta del cráter.

La superficie por donde se camina no cambia (misma geometría que WorldZones.bridgeEnds e
isOnBridge: la corriente de BridgeBoost y la cara de los monstruos dependen de ella). Encima
y alrededor, la temática volcánica de la entrada:
    portal      columnas de basalto con vetas de lava, braseros y el cartel en el dintel
    calzada     basalto con un camino central de losas y dos canales de lava a los lados,
                del naranja de la isla al rojo del cráter
    baranda     bordillo con filo de oro, pilares con braseros encendidos y estandartes
    arcos       pilas hasta el fondo del mar y arcos de piedra entre ellas
Lo usa tools/generar_isla.py.
"""
import math

import generar_isla as gi

L = gi.L
CAMINO = (92, 86, 92)
JUNTA = (34, 30, 36)
ESTANDARTE = (150, 30, 34)
LAVA_ISLA, LAVA_CRATER = (255, 176, 64), (255, 60, 22)
FUEGO = {"Size": 4, "Heat": 8, "Color": gi.color((255, 110, 30)), "SecondaryColor": gi.color((255, 220, 120))}
PILAS = (30, 52, 74, 96)  # distancia horizontal desde la entrada (studs)


def mezcla(a, b, t):
    return tuple(int(a[c] + (b[c] - a[c]) * t) for c in range(3))


class Marco:
    """Ejes del puente: `inclinado` sigue la rampa (+Z sube al cráter); `recto` es vertical."""

    def __init__(self):
        self.d = gi.direccion(L["bridgeAngle"])
        self.inicio = gi.polar(L["bridgeAngle"], L["bridgeStartRadius"], gi.CUBIERTA_Y)
        fin = gi.add(gi.CRATER, self.d, -(L["craterRimOuter"] - 2))
        self.fin = (fin[0], gi.DECK_ABISMO, fin[2])
        self.largo = math.dist((self.inicio[0], self.inicio[2]), (self.fin[0], self.fin[2]))
        self.subida = self.fin[1] - self.inicio[1]
        self.largo3d = math.hypot(self.largo, self.subida)
        self.recto = gi.base_con_z(self.d)
        self.inclinado = gi.mat(self.recto, gi.rx(-math.degrees(math.atan2(self.subida, self.largo))))
        self.medio = tuple((self.inicio[k] + self.fin[k]) / 2 for k in range(3))
        self.ancho = L["bridgeWidth"]

    def sobre(self, x, y, z):
        """Punto en el plano de la rampa: x lateral, y sobre la cubierta, z a lo largo."""
        return gi.add(self.medio, gi.aplicar(self.inclinado, (x, y, z)))

    def cubierta_y(self, s):
        """Altura de la cubierta a `s` studs (horizontales) de la entrada."""
        return self.inicio[1] + self.subida * s / self.largo

    def en(self, s, x, y):
        """Punto a `s` studs horizontales de la entrada, `x` al costado, a la altura `y`."""
        p = gi.add(gi.add(self.inicio, self.d, s), gi.aplicar(self.recto, (x, 0, 0)))
        return (p[0], y, p[2])


def calzada(m):
    a, L3 = m.ancho, m.largo3d
    hijos = [gi.pieza("Cubierta", (a, 1.2, L3 + 2), m.sobre(0, -0.6, 0), gi.ROCA_VOLCANICA, "Basalt", m.inclinado),
             gi.pieza("Camino", (10, 0.1, L3), m.sobre(0, 0.04, 0), CAMINO, "Slate", m.inclinado, **gi.FANTASMA)]
    for k in range(int(L3 // 7)):
        z = -L3 / 2 + 3.5 + k * 7
        hijos.append(gi.pieza(f"Junta{k}", (10.05, 0.12, 0.25), m.sobre(0, 0.05, z), JUNTA, "Slate", m.inclinado, **gi.FANTASMA))
    tramos = 10
    for k in range(tramos):
        t = (k + 0.5) / tramos
        tono = mezcla(LAVA_ISLA, LAVA_CRATER, t)
        for lado in (-1, 1):
            hijos.append(gi.pieza(f"Lava{lado}_{k}", (0.8, 0.1, L3 / tramos + 0.05), m.sobre(lado * (a / 2 - 3.6), 0.05, -L3 / 2 + L3 * t),
                                  tono, "Neon", m.inclinado, **gi.FANTASMA))
    return gi.grupo("Calzada", hijos)


def pilar_baranda(m, nombre, base, brasero):
    """Pilar de basalto sobre el bordillo; con `brasero`, un cuenco de hierro con fuego."""
    r = m.recto
    y = base[1]
    hijos = [
        gi.pieza("Fuste", (2.2, 4.2, 2.2), (base[0], y + 2.1, base[2]), gi.ROCA_VOLCANICA, "Basalt", r),
        gi.pieza("Banda", (2.4, 0.3, 2.4), (base[0], y + 3.5, base[2]), gi.ORO_MATE, "Metal", r, **gi.DECORADO),
        gi.pieza("Capitel", (2.9, 0.6, 2.9), (base[0], y + 4.5, base[2]), gi.ROCA_VOLCANICA_OSCURA, "Basalt", r),
    ]
    if brasero:
        llama = gi.pieza("Llama", (1.5, 1.5, 1.5), (base[0], y + 5.9, base[2]), gi.VETA_LAVA, "Neon", forma="Ball", **gi.FANTASMA)
        llama["children"] = [gi.luz(20, 1.4, (255, 150, 70)), {"name": "Fuego", "className": "Fire", "properties": FUEGO}]
        hijos += [gi.pieza("Cuenco", (1.1, 2.8, 2.8), (base[0], y + 5.35, base[2]), gi.HIERRO, "Metal", gi.VERTICAL, "Cylinder",
                           **gi.DECORADO), llama]
    else:
        hijos.append(gi.pieza("Punta", (1.3, 1.3, 1.3), (base[0], y + 5.2, base[2]), gi.ROCA_VOLCANICA_OSCURA, "Basalt",
                              gi.mat(r, gi.mat(gi.ry(45), gi.rx(35))), **gi.DECORADO))
    return gi.grupo(nombre, hijos)


def estandarte(m, nombre, arriba, lado):
    """Estandarte rojo con fleco de oro y un rombo de lava, colgado del lado del camino."""
    r = m.recto
    p = gi.add(arriba, gi.aplicar(r, (-lado * 1.2, 0, 0)))
    return gi.grupo(nombre, [
        gi.pieza("Tela", (0.15, 3.6, 1.9), gi.add(p, (0, -1.8, 0)), ESTANDARTE, "Fabric", r, **gi.FANTASMA),
        gi.pieza("Fleco", (0.2, 0.25, 1.95), gi.add(p, (0, -3.6, 0)), gi.ORO_MATE, "Metal", r, **gi.FANTASMA),
        gi.pieza("Rombo", (0.22, 0.8, 0.8), gi.add(gi.add(p, (0, -1.7, 0)), gi.aplicar(r, (-lado * 0.05, 0, 0))), gi.VETA_LAVA, "Neon",
                 gi.mat(r, gi.rx(45)), **gi.FANTASMA),
    ])


def baranda(m):
    a, L3 = m.ancho, m.largo3d
    hijos = []
    for lado in (-1, 1):
        x = lado * (a / 2 - 0.9)
        hijos.append(gi.pieza(f"Bordillo{lado}", (1.8, 2.6, L3 + 2), m.sobre(x, 1.3, 0), gi.ROCA_VOLCANICA_OSCURA, "Basalt", m.inclinado))
        hijos.append(gi.pieza(f"Remate{lado}", (2.2, 0.5, L3 + 2), m.sobre(x, 2.85, 0), gi.ROCA_VOLCANICA, "Basalt", m.inclinado))
        hijos.append(gi.pieza(f"Filo{lado}", (0.3, 0.12, L3 + 2), m.sobre(x - lado * 1.05, 3.08, 0), gi.ORO_MATE, "Metal", m.inclinado,
                              **gi.FANTASMA))
        hijos.append(gi.pieza(f"Muro{lado}", (0.6, 8, L3 + 2), m.sobre(lado * (a / 2 - 0.6), 4, 0), gi.ROCA_VOLCANICA, r=m.inclinado,
                              **gi.INVISIBLE))
        n = 13
        for k in range(n):
            z = -L3 / 2 + 9 + k * (L3 - 13) / (n - 1)
            base = m.sobre(x, 3.1, z)
            hijos.append(pilar_baranda(m, f"Pilar{lado}_{k}", base, k % 3 == 0))
            if k % 3 == 2:
                hijos.append(estandarte(m, f"Estandarte{lado}_{k}", gi.add(base, (0, 4.1, 0)), lado))
    return gi.grupo("Baranda", hijos)


def veta(m, nombre, s, x, y0, y1):
    """Veta de lava en zigzag sobre la cara lateral (x) de una pila."""
    zs = (0.0, 0.9, -0.7, 0.5)
    hijos = []
    for k in range(3):
        a = m.en(s + zs[k], x, y0 + (y1 - y0) * k / 3)
        b = m.en(s + zs[k + 1], x, y0 + (y1 - y0) * (k + 1) / 3)
        u = gi.norm(tuple(b[n] - a[n] for n in range(3)))
        centro = tuple((a[n] + b[n]) / 2 for n in range(3))
        hijos.append(gi.pieza(f"{nombre}{k}", (0.1, math.dist(a, b) + 0.15, 0.25), centro, gi.VETA_LAVA, "Neon",
                              gi.columnas(gi.aplicar(m.recto, (1, 0, 0)), u, gi.cross(gi.aplicar(m.recto, (1, 0, 0)), u)), **gi.FANTASMA))
    return hijos


def arco(m, nombre, s0, s1):
    """Arco de medio punto entre dos pilas, en las dos caras del puente, con el relleno de los
    hombros (enjutas) un poco hundido detrás del aro."""
    a = m.ancho
    sc, R = (s0 + s1) / 2, (s1 - s0) / 2
    clave = m.cubierta_y(sc) - 1.2 - 3  # bajo el faldón
    yc = clave - R
    n = 9
    hijos = []
    for lado in (-1, 1):
        for k in range(n):
            phi = math.radians((k + 0.5) * 180 / n)
            p = m.en(sc - R * math.cos(phi), lado * (a / 2 - 1.1), yc + R * math.sin(phi))
            cuerda = 2 * R * math.sin(math.radians(90 / n)) + 0.25
            hijos.append(gi.pieza(f"Dovela{lado}_{k}", (2.2, 1.4, cuerda), p, gi.ROCA_VOLCANICA_OSCURA if k % 2 else gi.ROCA_VOLCANICA,
                                  "Basalt", gi.mat(m.recto, gi.rx(math.degrees(phi) - 90))))
        for lado_s in (-1, 1):  # enjutas: escalones que llenan el hombro hasta el faldón
            for j, (f0, f1) in enumerate(((0.85, 1.0), (0.6, 0.85))):
                bajo = yc + R * math.sqrt(max(0, 1 - f0 * f0))
                p = m.en(sc + lado_s * R * (f0 + f1) / 2, lado * (a / 2 - 1.0), (bajo + clave) / 2)
                hijos.append(gi.pieza(f"Enjuta{lado}_{lado_s}_{j}", (1.2, clave - bajo, R * (f1 - f0) + 0.1), p, gi.ROCA_VOLCANICA,
                                      "Basalt", m.recto))
    return gi.grupo(nombre, hijos)


def arcos(m):
    a, L3 = m.ancho, m.largo3d
    hijos = []
    for lado in (-1, 1):  # faldón: el canto grueso de la cubierta
        hijos.append(gi.pieza(f"Faldon{lado}", (1.6, 3, L3 + 2), m.sobre(lado * (a / 2 - 0.8), -2.7, 0), gi.ROCA_VOLCANICA_OSCURA,
                              "Basalt", m.inclinado))
    fondo = L["seaFloorHeight"]
    grosor = 4.5
    for k, s in enumerate(PILAS):
        tope = m.cubierta_y(s) - 1.2
        hijos.append(gi.pieza(f"Pila{k}", (a - 1, tope - fondo, grosor), m.en(s, 0, (tope + fondo) / 2), gi.ROCA_VOLCANICA, "Basalt",
                              m.recto))
        for lado in (-1, 1):
            hijos += veta(m, f"Veta{k}_{lado}", s, lado * (a / 2 - 0.45), L["waterLevel"] + 1, tope - 3.5)
    for k in range(len(PILAS) - 1):
        hijos.append(arco(m, f"Arco{k}", PILAS[k] + grosor / 2, PILAS[k + 1] - grosor / 2))
    return gi.grupo("Arcos", hijos)


def portal(m):
    """Entrada desde la isla: dos columnas de basalto con vetas y braseros, y el dintel con el
    cartel (legible desde la plaza: mira a -Z, hacia la isla)."""
    a = m.ancho
    s = 3
    suelo = L["plateauHeight"]
    hijos = []
    for lado in (-1, 1):
        x = lado * (a / 2 + 2.4)
        base = m.en(s, x, suelo)
        hijos += [
            gi.pieza(f"Zocalo{lado}", (5.4, 1.4, 5.4), gi.add(base, (0, 0.7, 0)), gi.ROCA_VOLCANICA_OSCURA, "Basalt", m.recto),
            gi.pieza(f"Columna{lado}", (4.2, 22.6, 4.2), gi.add(base, (0, 12.7, 0)), gi.ROCA_VOLCANICA, "Basalt", m.recto),
            gi.pieza(f"Anillo{lado}", (4.5, 0.4, 4.5), gi.add(base, (0, 14.6, 0)), gi.ORO_MATE, "Metal", m.recto, **gi.DECORADO),
            gi.pieza(f"Capitel{lado}", (5, 0.8, 5), gi.add(base, (0, 24.2, 0)), gi.ROCA_VOLCANICA_OSCURA, "Basalt", m.recto),
        ]
        hijos += gi.grieta(f"Grieta{lado}", base, m.recto, 4.2, 2.4, 12.5, (-1,), 3, lado)
        llama = gi.pieza(f"Llama{lado}", (2.2, 2.2, 2.2), gi.add(base, (0, 25.9, 0)), gi.VETA_LAVA, "Neon", forma="Ball", **gi.FANTASMA)
        llama["children"] = [gi.luz(28, 1.6, (255, 150, 70)), {"name": "Fuego", "className": "Fire", "properties": dict(FUEGO, Size=6)}]
        hijos += [gi.pieza(f"Cuenco{lado}", (1.4, 4, 4), gi.add(base, (0, 25.2, 0)), gi.HIERRO, "Metal", gi.VERTICAL, "Cylinder",
                           **gi.DECORADO), llama]
    dintel = m.en(s, 0, suelo + 18)
    hijos.append(gi.pieza("Dintel", (a + 10, 3, 3.4), dintel, gi.ROCA_VOLCANICA, "Basalt", m.recto))
    hijos.append(gi.pieza("Corona", (a + 11, 0.9, 4), gi.add(dintel, (0, 1.95, 0)), gi.ROCA_VOLCANICA_OSCURA, "Basalt", m.recto))
    hijos += gi.placa_volcanica("Letrero", (22, 2.6, 0.4), gi.add(dintel, gi.aplicar(m.recto, (0, 0, -1.9))), m.recto,
                                "AL CRÁTER DEL ABISMO", "Front")
    return gi.grupo("Portal", hijos)


def puente():
    m = Marco()
    return gi.grupo("Puente", [calzada(m), baranda(m), arcos(m), portal(m)])
