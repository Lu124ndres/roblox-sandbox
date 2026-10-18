"""Puerta del Cráter del Abismo, donde el puente toca el borde del cráter.

Es el arco volcánico de Blender (tools/blender/arco_volcan.py, referencia del usuario del
2026-10-18): dos mallas con la misma caja que PropDresser pone con ajuste "caja", la piedra
(ArcoVolcan) y la lava en Neon naranja (ArcoVolcanLava, atributo Brillo). Las piezas de acá:
    respaldo  pilares y dintel de basalto por si el modelo no está en PropsMapa
              (el modelo los borra al ponerse)
    cartel    colgado bajo la clave del arco con dos cadenas, letras blancas enormes con
              borde negro (estilo simulador, la otra referencia del usuario)
    picos     fuego y humo en la cima de los tres picos del arco
    umbral    franja de lava en degradado de lado a lado
El paso queda libre: el hueco del arco mide 37 (el puente, 34) y el cartel cuelga arriba.
Lo usa tools/generar_isla.py.
"""
import generar_isla as gi

L = gi.L
# Medidas del modelo (lo imprime arco_volcan.py): caja (ancho, alto, hondo) y cima de cada pico
# (x, alto). Si se cambia el modelo, se copian de su salida.
CAJA = (69.35, 72.84, 18.15)
PICOS = ((0, 72.74), (-20, 60.57), (20, 60.57))
HUECO, PILAR_ALTO, R_ADENTRO = 37.0, 26.0, 18.5
LAVA_NEON = (255, 110, 30)
NEGRO = (20, 16, 24)
PLACA = (38, 30, 38)
LAVA = ((255, 60, 30), (255, 120, 30), (255, 196, 50), (255, 236, 110), (255, 196, 50), (255, 120, 30), (255, 60, 30))
FUEGO = {"Size": 9, "Heat": 12, "Color": gi.color((255, 110, 30)), "SecondaryColor": gi.color((255, 220, 120))}
HUMO = {"Color": gi.color((70, 64, 66)), "Opacity": 0.3, "RiseVelocity": 7, "Size": 6}


class Marco:
    """Ejes de la puerta: x de lado a lado, y hacia arriba desde el borde, +z hacia la isla."""

    def __init__(self):
        a = L["bridgeAngle"] + 180  # del cráter hacia la isla
        self.r = gi.base_con_z(gi.direccion(a))
        base = gi.polar_crater(a, L["craterRimOuter"] - 3, 0)
        self.base = (base[0], gi.RIM_Y, base[2])

    def en(self, x, y, z=0):
        return gi.add(self.base, gi.aplicar(self.r, (x, y, z)))


def letras(texto, cara, alto, ppe=24):
    """SurfaceGui con letras blancas grandes y borde negro grueso."""
    grosor = max(3, round(alto * ppe * 0.07, 1))
    return {
        "name": f"Texto{cara}", "className": "SurfaceGui",
        "properties": {"Face": cara, "SizingMode": "PixelsPerStud", "PixelsPerStud": ppe, "LightInfluence": 0},
        "children": [{
            "name": "Etiqueta", "className": "TextLabel",
            "properties": {
                "Size": {"UDim2": [[0.94, 0], [0.84, 0]]}, "Position": {"UDim2": [[0.03, 0], [0.08, 0]]},
                "BackgroundTransparency": 1, "Text": texto, "TextScaled": True, "TextColor3": [1, 1, 1], "FontFace": gi.FREDOKA,
            },
            "children": [{"name": "Borde", "className": "UIStroke",
                          "properties": {"Color": gi.color(NEGRO), "Thickness": grosor, "LineJoinMode": "Round"}}],
        }],
    }


def arco(m):
    """Las dos anclas del modelo, con la caja del modelo y apoyadas en el borde."""
    piedra = gi.ancla("ArcoVolcan", m.base, CAJA, m.r, "caja", "Respaldo")
    lava = gi.ancla("ArcoVolcanLava", m.base, CAJA, m.r, "caja")
    lava["attributes"]["Brillo"] = {"Color3": gi.color(LAVA_NEON)}
    return [piedra, lava]


def respaldo(m):
    x = HUECO / 2 + 5.5
    hijos = [gi.pieza(f"RespaldoPilar{lado}", (11, PILAR_ALTO, 10), m.en(lado * x, PILAR_ALTO / 2), gi.BASALTO[0], "Basalt", m.r)
             for lado in (-1, 1)]
    hijos.append(gi.pieza("RespaldoDintel", (CAJA[0] - 9, 11, 9), m.en(0, PILAR_ALTO + R_ADENTRO + 5.5), gi.BASALTO[1], "Basalt", m.r))
    return hijos


def cartel(m):
    """Cartel colgado bajo la clave del arco, con letras por las dos caras."""
    clave = PILAR_ALTO + R_ADENTRO
    y, ancho, alto = clave - 6.4, 25, 6
    placa = gi.pieza("Letrero", (ancho, alto, 1.2), m.en(0, y), PLACA, "Slate", m.r)
    placa["children"] = [letras("CRÁTER DEL ABISMO", cara, alto) for cara in ("Back", "Front")]
    hijos = [gi.pieza("LetreroContorno", (ancho + 1.2, alto + 1.2, 0.9), m.en(0, y), NEGRO, "SmoothPlastic", m.r), placa]
    for lado in (-1, 1):  # cadenas hasta la clave
        for k in range(4):
            p = m.en(lado * (ancho / 2 - 2), y + alto / 2 + 0.6 + k * 0.85)
            hijos.append(gi.pieza(f"Eslabon{lado}_{k}", (0.3, 1, 0.6), p, gi.HIERRO, "Metal", gi.mat(m.r, gi.ry(90 * (k % 2))),
                                  **gi.FANTASMA))
    return hijos


def picos(m):
    hijos = []
    for k, (x, alto) in enumerate(PICOS):
        fuego = gi.pieza(f"FuegoPico{k}", (1, 1, 1), m.en(x, alto + 0.6), LAVA_NEON, **gi.INVISIBLE, CanCollide=False)
        fuego["children"] = [
            {"name": "Fuego", "className": "Fire", "properties": FUEGO if k == 0 else dict(FUEGO, Size=6)},
            {"name": "Humo", "className": "Smoke", "properties": HUMO},
            gi.luz(36, 1.6, (255, 140, 60)),
        ]
        hijos.append(fuego)
    return hijos


def umbral(m):
    paso = L["bridgeWidth"] / len(LAVA)
    return [gi.pieza(f"Lava{k}", (paso + 0.05, 0.1, 3), m.en(-L["bridgeWidth"] / 2 + paso * (k + 0.5), 0.66), tono, "Neon", m.r,
                     **gi.FANTASMA) for k, tono in enumerate(LAVA)]


def puerta_abismo():
    m = Marco()
    hijos = arco(m) + respaldo(m) + cartel(m) + picos(m) + umbral(m)
    return gi.grupo("PuertaDelAbismo", hijos)
