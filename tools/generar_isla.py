"""
Genera world/Isla.model.json: las piezas de la isla (madera, piedra, decoración).

El terreno (arena, pasto, agua con olas, laguna) no está aquí: lo construye el servidor
al arrancar con src/server/World/TerrainBuilder.luau. Ambos leen la misma geometría de
src/shared/WorldLayoutData.json, así que piezas y terreno siempre coinciden.

    python tools/generar_isla.py

Lenguaje visual (ver docs/alcance.md):
    turquesa = pescar (alfombras en los muelles; se pesca desde toda la orilla)
    coral    = alimentar (las 8 cubetas alrededor de la laguna)

Unidades en studs. Ángulos en grados sobre XZ (0 = +X, 90 = +Z). El gigante vive en el
centro de la laguna (0, 0) y mira hacia -Z, hacia la aparición.
"""

import json
import math
import random
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
L = json.loads((RAIZ / "src" / "shared" / "WorldLayoutData.json").read_text(encoding="utf-8"))
SALIDA = RAIZ / "world" / "Isla.model.json"
GUARIDA = RAIZ / "world" / "GuaridaDescanso.model.json"
rng = random.Random(11)  # semilla fija: el mapa sale idéntico en cada corrida

# --- Paleta --------------------------------------------------------------------------
MADERA_CLARA = (196, 148, 98)
MADERA_MEDIA = (168, 120, 76)
MADERA_OSCURA = (108, 76, 50)
PAJA = (222, 190, 118)
TRONCO = ((150, 110, 70), (172, 130, 86))
HOJAS = ((74, 172, 88), (52, 142, 74))
ARBUSTO = ((70, 150, 70), (58, 132, 62), (88, 168, 80))
FLORES = ((255, 128, 160), (255, 214, 92), (250, 250, 255), (190, 140, 255))
COCO = (112, 76, 46)
ROCA = ((132, 136, 142), (110, 114, 122), (96, 101, 110))
CORAL_VIVO = ((255, 120, 140), (255, 160, 90), (190, 110, 220))
TURQUESA = (54, 196, 184)
CORAL = (255, 122, 100)
CREMA = (255, 241, 216)
ROJO_BOYA = (230, 64, 56)
LUZ_CALIDA = (255, 196, 110)
ESPUMA = (246, 252, 255)
CONCHA = ((255, 214, 200), (255, 236, 214), (240, 190, 170))

AGUA_Y = L["waterLevel"]
CUBIERTA_Y = L["deckHeight"]

# --- Matemática de CFrame ------------------------------------------------------------
I3 = ((1, 0, 0), (0, 1, 0), (0, 0, 1))


def mat(a, b):
    return tuple(tuple(sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)) for i in range(3))


def aplicar(r, v):
    return tuple(sum(r[i][k] * v[k] for k in range(3)) for i in range(3))


def rx(g):
    c, s = math.cos(math.radians(g)), math.sin(math.radians(g))
    return ((1, 0, 0), (0, c, -s), (0, s, c))


def ry(g):
    c, s = math.cos(math.radians(g)), math.sin(math.radians(g))
    return ((c, 0, s), (0, 1, 0), (-s, 0, c))


def rz(g):
    c, s = math.cos(math.radians(g)), math.sin(math.radians(g))
    return ((c, -s, 0), (s, c, 0), (0, 0, 1))


def norm(v):
    m = math.sqrt(sum(x * x for x in v))
    return tuple(x / m for x in v)


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def add(a, b, k=1.0):
    return tuple(a[i] + b[i] * k for i in range(3))


def columnas(x, y, z):
    return ((x[0], y[0], z[0]), (x[1], y[1], z[1]), (x[2], y[2], z[2]))


def base_con_x(u):
    """Rotación cuyo eje X local apunta a u (los cilindros de Roblox crecen en X)."""
    ref = (0, 0, 1) if abs(u[2]) < 0.9 else (1, 0, 0)
    y = norm(cross(ref, u))
    return columnas(u, y, cross(u, y))


def base_con_z(d):
    """Rotación cuyo eje Z local apunta a d, con Y lo más vertical posible."""
    x = norm(cross((0, 1, 0), d))
    return columnas(x, cross(d, x), d)


def direccion(angulo):
    a = math.radians(angulo)
    return (math.cos(a), 0, math.sin(a))


def polar(angulo, radio, y):
    d = direccion(angulo)
    return (d[0] * radio, y, d[2] * radio)


def altura_terreno(r):
    """Misma curva que TerrainBuilder.heightAt."""
    if r <= L["plateauRadius"]:
        return L["plateauHeight"]
    if r <= L["beachEndRadius"]:
        t = (r - L["plateauRadius"]) / (L["beachEndRadius"] - L["plateauRadius"])
        return L["plateauHeight"] + (L["beachEndHeight"] - L["plateauHeight"]) * t
    return L["beachEndHeight"]


VERTICAL = rz(90)  # cilindro de pie


def cf(pos, r=I3):
    return [round(v, 4) for v in (*pos, *r[0], *r[1], *r[2])]


def color(rgb):
    return [round(c / 255, 4) for c in rgb]


def pieza(nombre, tam, pos, rgb, material="SmoothPlastic", r=I3, forma=None, clase="Part", **extra):
    props = {
        "Anchored": True,
        "Size": [round(v, 3) for v in tam],
        "CFrame": cf(pos, r),
        "Color": color(rgb),
        "Material": material,
        "TopSurface": "Smooth",
        "BottomSurface": "Smooth",
    }
    if forma:
        props["Shape"] = forma
    props.update(extra)
    return {"name": nombre, "className": clase, "properties": props}


def grupo(nombre, hijos, clase="Model"):
    return {"name": nombre, "className": clase, "children": hijos}


def ancla(prop, base, tam, r=I3, ajuste="alto", reemplaza=""):
    """Pieza invisible que server/World/PropDresser cambia por el modelo 3D `prop` de
    ServerStorage.PropsMapa (Blender), apoyado en `base`; borra las piezas cuyo nombre
    empieza con algún prefijo de `reemplaza`. Sin el modelo quedan las primitivas."""
    centro = add(base, aplicar(r, (0, tam[1] / 2, 0)))
    nodo = pieza("Ancla", tam, centro, (255, 255, 255), "SmoothPlastic", r, **INVISIBLE, CanCollide=False)
    nodo["attributes"] = {"Prop": prop, "Ajuste": ajuste, "Reemplaza": reemplaza}
    return nodo


def con_prop(nodo, prop, ajuste="caja"):
    """La pieza misma se cambia por el modelo 3D `prop` (rocas)."""
    nodo["attributes"] = {"Prop": prop, "Ajuste": ajuste}
    return nodo


def mover(nodo, r, p):
    """Lleva un grupo construido en coordenadas locales al mundo: mundo = (r, p) * local."""
    props = nodo.get("properties", {})
    if "CFrame" in props:
        v = props["CFrame"]
        pos, rot = v[:3], (tuple(v[3:6]), tuple(v[6:9]), tuple(v[9:12]))
        props["CFrame"] = cf(add(p, aplicar(r, pos)), mat(r, rot))
    for hijo in nodo.get("children", []):
        mover(hijo, r, p)
    return nodo


def variar(rgb, cuanto=8):
    d = rng.randint(-cuanto, cuanto)
    return tuple(max(0, min(255, c + d)) for c in rgb)


DECORADO = {"CanQuery": False, "CanTouch": False}
FANTASMA = {"CanCollide": False, "CanQuery": False, "CanTouch": False, "CastShadow": False}
INVISIBLE = {"Transparency": 1, "CanQuery": False, "CanTouch": False, "CastShadow": False}


def muro(nombre, a, b, y_base=CUBIERTA_Y, alto=7):
    """Pared invisible entre a y b (x, z): nadie cae al agua por accidente."""
    dx, dz = b[0] - a[0], b[1] - a[1]
    centro = ((a[0] + b[0]) / 2, y_base + alto / 2, (a[1] + b[1]) / 2)
    return pieza(nombre, (0.6, alto, math.hypot(dx, dz)), centro, MADERA_CLARA, r=ry(math.degrees(math.atan2(dx, dz))), **INVISIBLE)


def poste(nombre, x, z, y_arriba, y_abajo, diam=1.2, rgb=MADERA_OSCURA):
    largo = y_arriba - y_abajo
    return pieza(nombre, (largo, diam, diam), (x, (y_arriba + y_abajo) / 2, z), rgb, "Wood", VERTICAL, "Cylinder")


def luz(rango=16, brillo=1.4, rgb=LUZ_CALIDA):
    return {"name": "Brillo", "className": "PointLight",
            "properties": {"Brightness": brillo, "Range": rango, "Color": color(rgb), "Shadows": False}}


def farol(nombre, x, z, y_base=CUBIERTA_Y, alto=6):
    caja = pieza("Luz", (1, 1.4, 1), (x, y_base + alto + 0.5, z), LUZ_CALIDA, "Neon", **DECORADO)
    caja["children"] = [luz()]
    return grupo(nombre, [
        poste("Poste", x, z, y_base + alto, y_base, 0.5),
        caja,
        pieza("Techo", (1.6, 0.3, 1.6), (x, y_base + alto + 1.35, z), MADERA_OSCURA, "Wood", **DECORADO),
    ])


# --- Temática volcánica: arco de entrada, plaza de aparición y carteles -------------------
# Como la interfaz (Interface/Kit): basalto oscuro con grietas de lava, filos de oro mate y
# letras de oro con contorno marrón. El resto de la isla sigue con su mármol y su madera.
ROCA_VOLCANICA = (56, 50, 58)  # fustes, vigas y pedestales
ROCA_VOLCANICA_OSCURA = (40, 36, 44)  # zócalos, capiteles y marcos
PIEDRA_NEGRA = (22, 19, 24)  # fondo de placas y tableros: el oro resalta encima
VETA_LAVA = (255, 110, 30)  # grietas y filos encendidos (Neon)
ORO_MATE = (200, 150, 64)  # molduras finas
CONTORNO_ORO = (42, 22, 8)  # = Kit.GOLD_OUTLINE
DEGRADADO_ORO = ((0, (255, 246, 170)), (0.45, (255, 214, 82)), (1, (222, 128, 30)))  # = Kit.GOLD
FREDOKA = {"Font": {"family": "rbxasset://fonts/families/FredokaOne.json", "weight": "Regular", "style": "Normal"}}


def letras_oro(texto, cara, alto, relleno=(0.94, 0.8), ppe=40):
    """SurfaceGui con letras de oro, como Kit.gold: texto blanco teñido por un degradado
    vertical (el degradado multiplica el color) y contorno marrón según el alto."""
    w, h = relleno
    grosor = max(2, round(alto * ppe * h * 0.05, 1))
    puntos = [{"time": t, "color": color(c)} for t, c in DEGRADADO_ORO]
    return {
        "name": "Texto", "className": "SurfaceGui",
        "properties": {"Face": cara, "SizingMode": "PixelsPerStud", "PixelsPerStud": ppe, "LightInfluence": 0},
        "children": [{
            "name": "Etiqueta", "className": "TextLabel",
            "properties": {
                "Size": {"UDim2": [[w, 0], [h, 0]]}, "Position": {"UDim2": [[round((1 - w) / 2, 4), 0], [round((1 - h) / 2, 4), 0]]},
                "BackgroundTransparency": 1, "Text": texto, "TextScaled": True, "TextColor3": [1, 1, 1], "FontFace": FREDOKA,
            },
            "children": [
                {"name": "Contorno", "className": "UIStroke",
                 "properties": {"Color": color(CONTORNO_ORO), "Thickness": grosor, "LineJoinMode": "Round"}},
                {"name": "Oro", "className": "UIGradient",
                 "properties": {"Rotation": 90, "Color": {"ColorSequence": {"keypoints": puntos}}}},
            ],
        }],
    }


def placa_volcanica(nombre, tam, pos, r, texto, cara):
    """Placa de piedra casi negra con letras de oro, un filo de lava encendida y un marco de
    basalto escalonados por detrás (más delgados: solo asoman por el borde)."""
    ancho, alto, fondo = tam
    tabla = pieza(nombre, tam, pos, PIEDRA_NEGRA, "Slate", r, **DECORADO)
    tabla["children"] = [letras_oro(texto, cara, alto)]
    return [
        pieza(f"{nombre}Marco", (ancho + 0.7, alto + 0.7, fondo * 0.5), pos, ROCA_VOLCANICA_OSCURA, "Basalt", r, **DECORADO),
        pieza(f"{nombre}Lava", (ancho + 0.24, alto + 0.24, fondo * 0.75), pos, VETA_LAVA, "Neon", r, **FANTASMA),
        tabla,
    ]


def grieta(nombre, p, r, ancho, y0, y1, caras, tramos=3, espejo=1):
    """Veta de lava en zigzag sobre las caras ±Z locales de un fuste cuadrado de `ancho`
    centrado en p: pocas piezas Neon finas, como las grietas de la piedra de la interfaz."""
    xs = [x * ancho * espejo for x in (0.12, -0.18, 0.2, -0.06)][: tramos + 1]
    ys = [y0 + (y1 - y0) * k / tramos for k in range(tramos + 1)]
    hijos = []
    for cara in caras:
        for k in range(tramos):
            dx, dy = (xs[k + 1] - xs[k]) * cara, ys[k + 1] - ys[k]
            centro = add(p, aplicar(r, ((xs[k] + xs[k + 1]) / 2 * cara, (ys[k] + ys[k + 1]) / 2, cara * ancho / 2)))
            giro = mat(r, rz(math.degrees(math.atan2(-dx, dy))))
            hijos.append(pieza(f"{nombre}{'Frente' if cara > 0 else 'Fondo'}{k}", (0.18, math.hypot(dx, dy) + 0.12, 0.08),
                               centro, VETA_LAVA, "Neon", giro, **FANTASMA))
    return hijos


def cartel(nombre, pos, r, texto, ancho, alto, cara="Front"):
    """Cartel del mundo (puente, cabaña, estanque sagrado): placa volcánica con letras de oro."""
    return grupo(nombre, placa_volcanica("Tabla", (ancho, alto, 0.4), pos, r, texto, cara))


# --- Zona de entrenamiento ------------------------------------------------------------
# Un color por estanque, del más débil (verde) al más fuerte (dorado). Las piezas de la zona
# de entrenamiento salen de tools/estanques.
COLORES_ESTANQUE = (
    (120, 220, 120), (90, 210, 200), (90, 170, 255), (130, 120, 255), (190, 110, 255),
    (255, 110, 200), (255, 90, 90), (255, 150, 60), (255, 205, 60), (255, 245, 170),
    (120, 245, 255),  # 11: el sagrado del centro (solo Robux)
)
ORO = (255, 200, 70)


def anillo_tallado(nombre, cx, cz, radio, n, ancho, alto, y_tope, colores, material, **extra):
    """Anillo de bloques tallados alrededor de (cx, cz): local X radial, Z tangente."""
    hijos = []
    largo = 2 * math.pi * radio / n + 0.12
    for k in range(n):
        th = k * 360 / n
        p = add((cx, 0, cz), polar(th, radio, 0))
        rgb = colores[k % len(colores)] if isinstance(colores[0], tuple) else colores
        hijos.append(pieza(f"{nombre}{k}", (ancho, alto, largo), (p[0], y_tope - alto / 2, p[2]), rgb, material, ry(-th), **extra))
    return hijos


def zona_entrenamiento():
    """Jardín de entrenamiento con estanques naturales: vive en tools/estanques."""
    from estanques import zona_entrenamiento as jardin  # importa este módulo: va adentro

    return jardin()


# --- Muelles y puntos de pesca ---------------------------------------------------------
def tablones_z(nombre, x0, x1, z0, z1):
    """Tablones que cruzan en X y se repiten a lo largo de Z."""
    hijos, z, i = [], z0, 0
    while z < z1 - 0.01:
        hijos.append(pieza(f"Tablon{i}", (x1 - x0, 0.5, 1.8), ((x0 + x1) / 2, CUBIERTA_Y - 0.25, z + 1),
                           variar(MADERA_CLARA if i % 2 else MADERA_MEDIA, 6), "WoodPlanks"))
        z, i = z + 2, i + 1
    hijos.append(pieza("Base", (x1 - x0 - 0.4, 0.4, z1 - z0 - 0.4), ((x0 + x1) / 2, CUBIERTA_Y - 0.7, (z0 + z1) / 2), MADERA_OSCURA, "Wood"))
    return grupo(nombre, hijos)


def tablones_x(nombre, x0, x1, z0, z1):
    hijos, x, i = [], x0, 0
    while x < x1 - 0.01:
        hijos.append(pieza(f"Tablon{i}", (1.8, 0.5, z1 - z0), (x + 1, CUBIERTA_Y - 0.25, (z0 + z1) / 2),
                           variar(MADERA_CLARA if i % 2 else MADERA_MEDIA, 6), "WoodPlanks"))
        x, i = x + 2, i + 1
    hijos.append(pieza("Base", (x1 - x0 - 0.4, 0.4, z1 - z0 - 0.4), ((x0 + x1) / 2, CUBIERTA_Y - 0.7, (z0 + z1) / 2), MADERA_OSCURA, "Wood"))
    return grupo(nombre, hijos)


def punto_de_pesca(nombre, x, z, yaw):
    """Alfombra turquesa, farol y cebo: marca los mejores lugares, aunque se puede
    pescar desde cualquier punto de la orilla o del muelle."""
    r = ry(yaw)
    lado = aplicar(r, (1, 0, 0))
    hijos = [
        pieza("Alfombra", (5, 0.12, 5), (x, CUBIERTA_Y + 0.06, z), TURQUESA, "Fabric", r, **DECORADO, CanCollide=False),
        pieza("Borde", (5.6, 0.14, 5.6), (x, CUBIERTA_Y + 0.03, z), CREMA, "Fabric", r, **DECORADO, CanCollide=False),
        farol("Farol", *(lambda p: (p[0], p[2]))(add((x, 0, z), lado, 3.2))),
        pieza("Cebo", (1.4, 1.2, 1.4), add((x, CUBIERTA_Y + 0.6, z), lado, -2.6), CORAL, "SmoothPlastic", VERTICAL, "Cylinder", **DECORADO),
    ]
    return grupo(nombre, hijos)


def muelle(indice, angulo):
    """Se arma en coordenadas locales (+Z hacia el mar) y luego se rota a su ángulo."""
    largo = L["pierLength"]
    fin = largo - 12  # empieza la plataforma
    hijos = [tablones_z("Pasarela", -5, 5, 0, fin), tablones_x("Plataforma", -13, 13, fin, largo)]
    for i, z in enumerate(range(6, largo + 1, 8)):
        for lado in (-1, 1):
            x = 5.3 * lado if z < fin else 13.3 * lado
            hijos.append(poste(f"Poste{i}_{lado}", x, z, CUBIERTA_Y + 0.6, L["seaFloorHeight"] + 2))
    hijos.append(poste("PosteFinI", -13.3, largo - 0.3, CUBIERTA_Y + 0.6, L["seaFloorHeight"] + 2))
    hijos.append(poste("PosteFinD", 13.3, largo - 0.3, CUBIERTA_Y + 0.6, L["seaFloorHeight"] + 2))
    # Cuerda baja a los lados de la pasarela.
    for lado in (-1, 1):
        for i, z in enumerate(range(6, fin, 6)):
            hijos.append(poste(f"Bolardo{i}_{lado}", 5.2 * lado, z, CUBIERTA_Y + 2.2, CUBIERTA_Y, 0.6))
        hijos.append(pieza(f"Cuerda{lado}", (0.25, 0.25, fin - 6), (5.2 * lado, CUBIERTA_Y + 1.9, (fin + 6) / 2), PAJA, "Fabric", **DECORADO))
        hijos.append(muro(f"MuroPasarela{lado}", (5.4 * lado, 8), (5.4 * lado, fin)))
    hijos += [
        muro("MuroFin", (-13.5, largo + 0.3), (13.5, largo + 0.3)),
        muro("MuroI", (-13.5, fin), (-13.5, largo)),
        muro("MuroD", (13.5, fin), (13.5, largo)),
        muro("MuroAtrasI", (-13.5, fin), (-5.4, fin)),
        muro("MuroAtrasD", (5.4, fin), (13.5, fin)),
    ]
    puntos = [
        punto_de_pesca("PuntoIzq", -10, fin + 6, 90),
        punto_de_pesca("PuntoDer", 10, fin + 6, -90),
        punto_de_pesca("PuntoFin", 0, largo - 2.6, 180),
    ]
    hijos.append(grupo("PuntosDePesca", puntos, "Folder"))
    d = direccion(angulo)
    return mover(grupo(f"Muelle{indice}", hijos), base_con_z(d), polar(angulo, L["pierStartRadius"], 0))


# --- Aparición, entrada y cabaña ----------------------------------------------------------
# La plaza grande sigue de mármol claro con oro; la aparición y el arco de entrada son de
# basalto con lava (ver "Temática volcánica" arriba).
MARMOL_CLARO = (238, 233, 224)
HIERRO_NEGRO = (40, 40, 46)
LUZ_FAROLA = (255, 214, 150)
SETO = ((52, 122, 64), (62, 138, 72))
ANGULOS_CAMINO = [L["spawnAngle"], L["shopAngle"], L["campAngle"], L["lighthouseAngle"], L["bridgeAngle"]] + L["pierAngles"]


def sobre_camino(angulo, margen):
    return any(abs((angulo - b + 180) % 360 - 180) < margen for b in ANGULOS_CAMINO)


def anillo_con_huecos(nombre, radio, n, ancho, alto, y_tope, colores, material, margen, **extra):
    """anillo_tallado alrededor del origen, sin los bloques que caen sobre un camino."""
    piezas = anillo_tallado(nombre, 0, 0, radio, n, ancho, alto, y_tope, colores, material, **extra)
    return [p for k, p in enumerate(piezas) if not sobre_camino(k * 360 / n, margen)]


def farola(nombre, x, z, y, alto=8, piedra=(MARMOL_CLARO, "Marble"), oro=ORO):
    """Farola: base de piedra (mármol o basalto), poste de hierro negro, anillo de oro y farol
    de luz cálida."""
    farol_ = pieza("Farol", (1.1, 1.5, 1.1), (x, y + alto + 0.75, z), LUZ_FAROLA, "Neon", **DECORADO)
    farol_["children"] = [luz(18, 0.8, LUZ_FAROLA)]  # suave: el mármol blanco no se encandila
    largo = alto - 1
    return grupo(nombre, [
        pieza("Base", (1.8, 1, 1.8), (x, y + 0.5, z), *piedra),
        pieza("Poste", (largo, 0.45, 0.45), (x, y + 1 + largo / 2, z), HIERRO_NEGRO, "Metal", VERTICAL, "Cylinder"),
        pieza("Anillo", (0.3, 0.9, 0.9), (x, y + alto - 0.1, z), oro, "Metal", VERTICAL, "Cylinder", **DECORADO),
        farol_,
        pieza("Techo", (1.6, 0.25, 1.6), (x, y + alto + 1.6, z), HIERRO_NEGRO, "Metal", **DECORADO),
        pieza("Remate", (0.55, 0.55, 0.55), (x, y + alto + 2, z), oro, "Metal", ry(45), **DECORADO),
    ])


def placa(nombre, pos, r, texto, ancho, alto, cara="Back"):
    """Placa volcánica de la entrada (título del arco y del salón de la fama)."""
    return placa_volcanica(nombre, (ancho, alto, 0.5), pos, r, texto, cara)


def pilar(nombre, p, y0, alto, ancho=2.4, r=I3, caras=(), tramos=3, espejo=1):
    """Pilar cuadrado de basalto con zócalo, bandas de oro mate, capitel y, en `caras`
    (±1: +Z o -Z local de r), una grieta de lava en el fuste."""
    hijos = [
        pieza("Zocalo", (ancho + 1, 1.2, ancho + 1), (p[0], y0 + 0.6, p[2]), ROCA_VOLCANICA_OSCURA, "Basalt"),
        pieza("Fuste", (ancho, alto, ancho), (p[0], y0 + 1.2 + alto / 2, p[2]), ROCA_VOLCANICA, "Basalt"),
        pieza("BandaBaja", (ancho + 0.3, 0.3, ancho + 0.3), (p[0], y0 + 1.5, p[2]), ORO_MATE, "Metal", **DECORADO),
        pieza("BandaAlta", (ancho + 0.3, 0.3, ancho + 0.3), (p[0], y0 + alto + 0.9, p[2]), ORO_MATE, "Metal", **DECORADO),
        pieza("Capitel", (ancho + 0.8, 0.8, ancho + 0.8), (p[0], y0 + alto + 1.6, p[2]), ROCA_VOLCANICA_OSCURA, "Basalt"),
    ]
    if caras:
        hijos += grieta("Grieta", (p[0], 0, p[2]), r, ancho, y0 + 2.4, y0 + 1.2 + alto * 0.7, caras, tramos, espejo)
    return grupo(nombre, hijos)


def aparicion():
    """Plataforma redonda de basalto donde se aparece (mira hacia la laguna)."""
    a = L["spawnAngle"]
    d = direccion(a)
    return {
        "name": "Aparicion", "className": "SpawnLocation",
        "properties": {
            "Anchored": True, "Neutral": True, "Duration": 0, "Size": [1, 14, 14], "Shape": "Cylinder",
            # Cilindro de pie que sigue mirando a la laguna: su LookVector (-Z local) apunta al centro.
            "CFrame": cf(polar(a, L["spawnRadius"], L["plateauHeight"] + 0.3), mat(base_con_z(d), rz(90))),
            "Color": color(ROCA_VOLCANICA), "Material": "Basalt", "TopSurface": "Smooth", "BottomSurface": "Smooth",
        },
    }


def plaza_aparicion():
    """Escalón de basalto con filo de oro mate alrededor de la aparición, un círculo de lava
    sobre la plataforma y cuatro farolas de basalto."""
    a = L["spawnAngle"]
    c = polar(a, L["spawnRadius"], 0)
    y = L["plateauHeight"]
    hijos = anillo_tallado("Oro", c[0], c[2], 7.05, 48, 0.4, 0.9, y + 0.85, ORO_MATE, "Metal", **DECORADO)
    hijos += anillo_tallado("Escalon", c[0], c[2], 9.2, 48, 4.2, 0.7, y + 0.35, ROCA_VOLCANICA_OSCURA, "Basalt")
    hijos += anillo_tallado("Emblema", c[0], c[2], 4.5, 32, 0.35, 0.1, y + 0.83, VETA_LAVA, "Neon", **FANTASMA)
    for k in range(4):
        p = add(c, polar(a + 45 + k * 90, 12.5, 0))
        hijos.append(farola(f"Farola{k}", p[0], p[2], y, 7, (ROCA_VOLCANICA_OSCURA, "Basalt"), ORO_MATE))
    return grupo("PlazaAparicion", hijos)


def tablero(nombre, pos, r, ancho, alto):
    """Tablero del ranking (lo dibuja RankingBoards por la cara de adelante, -Z local, la que
    mira al centro de la isla): piedra casi negra con un filo de oro mate y un marco de basalto."""
    return [
        pieza(nombre, (ancho, alto, 0.5), pos, PIEDRA_NEGRA, "Slate", r),
        pieza(f"Marco{nombre}", (ancho + 1, alto + 1, 0.3), pos, ROCA_VOLCANICA_OSCURA, "Basalt", r, **DECORADO),
        pieza(f"Filo{nombre}", (ancho + 0.24, alto + 0.24, 0.4), pos, ORO_MATE, "Metal", r, **DECORADO),
    ]


def arco_entrada():
    """Arco de basalto con grietas de lava, molduras de oro mate y la placa de la laguna, y
    el salón de la fama:
    los tableros grandes del ranking global (Leaderboards / RankingBoards) a los lados
    del arco (poder y monstruos) y sobre él (renacimientos)."""
    a = L["spawnAngle"]
    r = base_con_z(direccion(a))
    base = polar(a, L["plazaRadius"] + 3, 0)
    y = L["plateauHeight"]
    hijos = []
    for lado in (-1, 1):
        hijos.append(pilar(f"Pilar{lado}", add(base, aplicar(r, (8 * lado, 0, 0))), y, 13, r=r, caras=(1, -1), espejo=lado))
    hijos.append(pieza("Viga", (19.5, 1.8, 3), add(base, (0, y + 16.4, 0)), ROCA_VOLCANICA, "Basalt", r))
    for k, dy in enumerate((15.45, 17.35)):
        hijos.append(pieza(f"Moldura{k}", (19.7, 0.3, 3.2), add(base, (0, y + dy, 0)), ORO_MATE, "Metal", r, **DECORADO))
    # El texto mira hacia afuera (+Z local = hacia la aparición).
    hijos += placa("Cartel", add(base, (0, y + 12.6, 0)), r, "LAGUNA DE LOS GIGANTES", 12.6, 2.6)
    # Salón de la fama: dos tableros grandes a los lados del arco y uno sobre él. Miran hacia
    # adentro (-Z local, cara Front): se leen desde la zona de entrenamiento del centro.
    for lado, nombre, titulo in ((-1, "TableroPoder", "TOP PODER"), (1, "TableroKills", "TOP MONSTRUOS")):
        p = add(base, aplicar(r, (18 * lado, 0, 2)))
        hijos.append(pieza(f"Pedestal{nombre}", (14, 3.2, 3), (p[0], y + 1.6, p[2]), ROCA_VOLCANICA, "Basalt", r))
        hijos.append(pieza(f"Banda{nombre}", (14.3, 0.35, 3.3), (p[0], y + 3, p[2]), ORO_MATE, "Metal", r, **DECORADO))
        hijos += tablero(nombre, (p[0], y + 10.4, p[2]), r, 12, 14)
        for k in (-1, 1):
            hijos.append(pilar(f"Pilar{nombre}{k}", add(p, aplicar(r, (7.6 * k, 0, 0))), y, 17, 1.6, r, (-1,), 2, k))
        hijos += placa(f"Titulo{nombre}", (p[0], y + 19.2, p[2]), r, titulo, 11, 2, "Front")
    hijos.append(pieza("BaseTablero", (19, 1, 3), add(base, (0, y + 18, 0)), ROCA_VOLCANICA_OSCURA, "Basalt", r))
    hijos += tablero("TableroRenacimientos", add(base, (0, y + 22.6, 0)), r, 17, 8)
    hijos += placa("TituloTableroRenacimientos", add(base, (0, y + 28, 0)), r, "TOP RENACIMIENTOS", 13, 2, "Front")
    return grupo("ArcoEntrada", hijos)


def cabana():
    """Cabaña de la tienda: en el Mostrador se abre con E (ShopService)."""
    a = L["shopAngle"]
    d = direccion(a)
    y = L["plateauHeight"]
    hijos = [tablones_x("Piso", -7, 7, -5, 5)]
    for i, (x, z) in enumerate(((-6.5, -4.5), (6.5, -4.5), (-6.5, 4.5), (6.5, 4.5))):
        hijos.append(poste(f"Poste{i}", x, z, y + 9, y, 0.9))
    for lado in (-1, 1):  # techo de paja a dos aguas
        hijos.append(pieza(f"Techo{lado}", (16, 0.6, 7.6), (0, y + 10.3, 2.6 * lado), PAJA, "Grass", rx(-26 * lado), **DECORADO))
    hijos.append(pieza("Cumbrera", (16.4, 0.8, 0.8), (0, y + 11.9, 0), MADERA_OSCURA, "Wood", **DECORADO))
    hijos.append(pieza("Mostrador", (11, 2.6, 1.6), (0, y + 1.9, -3.8), MADERA_MEDIA, "WoodPlanks"))
    hijos.append(cartel("Cartel", (0, y + 7.8, -4.9), I3, "TIENDA", 9, 1.8))
    for i, rgb in enumerate(((96, 170, 214), (255, 196, 84), (255, 128, 160))):
        hijos.append(pieza(f"Frasco{i}", (1.2, 1.4, 1.2), (-3 + i * 3, y + 3.9, -3.8), rgb, "Glass", VERTICAL, "Cylinder", Transparency=0.2, **DECORADO))
    return mover(grupo("Cabana", hijos), base_con_z(d), polar(a, L["shopRadius"], 0))


# --- Decoración ------------------------------------------------------------------------
def palmera(nombre, base, yaw, inclinacion=4.5, segmentos=6):
    hijos, punta = [], base
    for i in range(segmentos):
        a = math.radians(inclinacion * (i + 1))
        h = direccion(yaw)
        u = (h[0] * math.sin(a), math.cos(a), h[2] * math.sin(a))
        largo, diam = 3.2, 1.9 - i * 0.12
        hijos.append(pieza(f"Tronco{i}", (largo + 0.3, diam, diam), add(punta, u, largo / 2), TRONCO[i % 2], "Wood", base_con_x(u), "Cylinder", **DECORADO))
        punta = add(punta, u, largo)
    for capa, (n, caida, largo, ancho) in enumerate(((7, 18, 9.5, 2.6), (6, 42, 7.5, 2.2))):
        for i in range(n):
            phi = math.radians(i * 360 / n + capa * 25 + rng.uniform(-8, 8))
            c = math.cos(math.radians(caida))
            d = norm((math.cos(phi) * c, -math.sin(math.radians(caida)), math.sin(phi) * c))
            hijos.append(pieza(f"Hoja{capa}_{i}", (ancho, 0.25, largo), add(punta, d, largo / 2 - 0.4), HOJAS[capa], "Grass", base_con_z(d), **DECORADO))
    for i in range(3):
        ang = math.radians(i * 120 + 20)
        hijos.append(pieza(f"Coco{i}", (1.2, 1.2, 1.2), add(punta, (math.cos(ang) * 0.8, -0.9, math.sin(ang) * 0.8)), COCO, forma="Ball", **DECORADO))
    # Modelo 3D: tronco curvo hacia `yaw` (en Blender se inclina hacia +X). Variante por número.
    variante = 1 + int("".join(c for c in nombre if c.isdigit()) or 0) % 3
    alto = segmentos * 3.2 + 2.5
    hijos.append(ancla(f"Palmera{variante}", base, (4, alto, 4), ry(-yaw), "alto", "Tronco,Hoja,Coco"))
    # Choque del tronco (el modelo 3D no choca): un cilindro invisible al pie.
    hijos.append(pieza("Colision", (alto * 0.55, 1.6, 1.6), add(base, (0, alto * 0.27, 0)), TRONCO[0], "Wood", VERTICAL, "Cylinder",
                       **INVISIBLE))
    return grupo(nombre, hijos)


def lejos_de_caminos(angulo, margen):
    caminos = list(L["pierAngles"]) + [L["spawnAngle"], L["shopAngle"], L["lighthouseAngle"], L["campAngle"], L["bridgeAngle"]]
    return all(abs((angulo - c + 180) % 360 - 180) > margen for c in caminos)


def sitios(cantidad, r_min, r_max, margen):
    elegidos = []
    while len(elegidos) < cantidad:
        a, r = rng.uniform(0, 360), rng.uniform(r_min, r_max)
        if lejos_de_caminos(a, margen) and all(math.dist(polar(a, r, 0), polar(b, s, 0)) > 8 for b, s in elegidos):
            elegidos.append((a, r))
    return elegidos


def arbusto(nombre, pos):
    hijos = []
    for i in range(3):
        s = rng.uniform(2.6, 4)
        p = add(pos, (rng.uniform(-1.6, 1.6), s * 0.3, rng.uniform(-1.6, 1.6)))
        hijos.append(pieza(f"Hojas{i}", (s, s, s), p, ARBUSTO[i % 3], "Grass", forma="Ball", **DECORADO))
    for i in range(5):
        p = add(pos, (rng.uniform(-2.2, 2.2), rng.uniform(1.2, 2.4), rng.uniform(-2.2, 2.2)))
        hijos.append(pieza(f"Flor{i}", (0.7, 0.7, 0.7), p, FLORES[rng.randrange(4)], "SmoothPlastic", forma="Ball", **DECORADO, CanCollide=False))
    variante = 1 + int("".join(c for c in nombre if c.isdigit()) or 0) % 2
    hijos.append(ancla(f"Arbusto{variante}", pos, (5, 3.8, 5), ry(int("".join(c for c in nombre if c.isdigit()) or 0) * 47), "alto", "Hojas,Flor"))
    return grupo(nombre, hijos)


def rocas(nombre, centro, cantidad, escala=1.0):
    hijos = []
    for i in range(cantidad):
        s = escala * rng.uniform(2, 5)
        p = (centro[0] + rng.uniform(-4, 4) * escala, altura_terreno(math.hypot(*centro)) + s * 0.15, centro[1] + rng.uniform(-4, 4) * escala)
        r = mat(ry(rng.uniform(0, 360)), mat(rx(rng.uniform(-14, 14)), rz(rng.uniform(-14, 14))))
        hijos.append(con_prop(pieza(f"Roca{i}", (s * rng.uniform(1, 1.4), s * rng.uniform(0.6, 0.9), s), p, ROCA[i % 3], "Slate", r),
                              f"Roca{1 + i % 3}"))
    return grupo(nombre, hijos)


def boyas():
    hijos = []
    for i in range(8):
        a = 22.5 + i * 45
        p = polar(a, L["shelfRadius"] - 8, AGUA_Y)
        luz_boya = pieza("Luz", (0.8, 0.8, 0.8), add(p, (0, 4.4, 0)), (255, 240, 200), "Neon", forma="Ball", **FANTASMA)
        luz_boya["children"] = [luz(14, 1, (255, 230, 170))]
        hijos.append(grupo(f"Boya{i + 1}", [
            pieza("Cuerpo", (3, 3.2, 3.2), add(p, (0, 0.6, 0)), ROJO_BOYA, "SmoothPlastic", VERTICAL, "Cylinder", **FANTASMA),
            pieza("Franja", (0.9, 3.3, 3.3), add(p, (0, 1.4, 0)), CREMA, "SmoothPlastic", VERTICAL, "Cylinder", **FANTASMA),
            pieza("Mastil", (2.4, 0.35, 0.35), add(p, (0, 3.2, 0)), (60, 60, 66), "Metal", VERTICAL, "Cylinder", **FANTASMA),
            luz_boya,
        ]))
    return grupo("Boyas", hijos, "Folder")


def anillo_espuma(nombre, centro, radio, n):
    """Espuma donde el agua toca la orilla. El cliente la anima."""
    hijos = []
    for capa, (offset, transp, ancho) in enumerate(((0.6, 0.3, 2.4), (3.2, 0.65, 1.8))):
        r = radio + offset
        cuerda = 2 * r * math.sin(math.pi / n) + 0.3
        for i in range(n):
            a = (i + 0.5 * capa) * 360 / n
            hijos.append(pieza(f"{nombre}{capa}_{i}", (cuerda, 0.12, ancho), add(centro, polar(a, r, AGUA_Y + 0.08 + capa * 0.02)),
                               ESPUMA, "SmoothPlastic", base_con_z(direccion(a)), Transparency=transp, **FANTASMA))
    return hijos


def espuma():
    hijos = anillo_espuma("Isla", (0, 0, 0), L["shoreRadius"], 96)
    # Orilla exterior del cráter: donde su ladera corta el agua.
    fin_paseo = L["craterCliffRadius"] + L["craterWalkWidth"]
    t = ((RIM_Y - AGUA_Y) / (RIM_Y - L["seaFloorHeight"])) ** (1 / 1.6)
    rho = fin_paseo + t * (L["craterBaseRadius"] - fin_paseo)
    hijos += anillo_espuma("Crater", CRATER, rho, 110)
    return grupo("Espuma", hijos, "Folder")


def limites():
    hijos, n, r = [], 48, L["boundaryRadius"]
    centro = (L["boundaryCenter"][0], 0, L["boundaryCenter"][1])
    for i in range(n):
        p0, p1 = add(centro, polar(i * 360 / n, r, 0)), add(centro, polar((i + 1) * 360 / n, r, 0))
        hijos.append(muro(f"Limite{i}", (p0[0], p0[2]), (p1[0], p1[2]), L["seaFloorHeight"], 110))
    return grupo("Limites", hijos, "Folder")


E = L["plateauRadius"] / 125  # la isla creció: más palmeras y arbustos en el mismo espacio


def decoracion():
    hijos = []
    hijos.append(grupo("Palmeras", [
        palmera(f"Palmera{i}", polar(a, r, altura_terreno(r) - 0.6), rng.uniform(0, 360), rng.uniform(3.5, 6.5), rng.choice((5, 6, 7)))
        for i, (a, r) in enumerate(sitios(round(46 * E * E), L["plazaRadius"] + 8, 136 * E, 8))
    ], "Folder"))
    hijos.append(grupo("Arbustos", [
        arbusto(f"Arbusto{i}", polar(a, r, L["plateauHeight"])) for i, (a, r) in enumerate(sitios(round(34 * E * E), L["plazaRadius"] + 8, 120 * E, 7))
    ], "Folder"))
    hijos.append(grupo("Rocas", [
        rocas(f"Rocas{i}", (math.cos(math.radians(a + s)) * (L["pierStartRadius"] + 2), math.sin(math.radians(a + s)) * (L["pierStartRadius"] + 2)), 4)
        for i, (a, s) in enumerate((x, sgn) for x in L["pierAngles"] for sgn in (-14, 14))
    ], "Folder"))
    conchas = []
    for i, (a, r) in enumerate(sitios(round(60 * E), L["plateauRadius"] + 3, L["shoreRadius"] - 1, 4)):
        conchas.append(pieza(f"Concha{i}", (0.9, 0.5, 0.9), polar(a, r, altura_terreno(r) + 0.15), CONCHA[i % 3], "SmoothPlastic", ry(rng.uniform(0, 360)), forma="Ball", **DECORADO, CanCollide=False))
    hijos.append(grupo("Conchas", conchas, "Folder"))
    return grupo("Decoracion", hijos)


# --- Faro y campamento -----------------------------------------------------------------
ROJO_FARO = (214, 62, 58)
BLANCO_FARO = (246, 244, 238)


def faro():
    """Faro sobre el promontorio. El cliente hace girar el Haz de luz."""
    x, _, z = polar(L["lighthouseAngle"], L["lighthouseRadius"], 0)
    y = L["lighthouseBaseHeight"]
    hijos = [pieza("Base", (1.4, 16, 16), (x, y + 0.2, z), (150, 146, 140), "Cobblestone", VERTICAL, "Cylinder")]
    altura, diam = y + 0.9, 9.0
    for i in range(6):
        hijos.append(pieza(f"Torre{i}", (4.6, diam, diam), (x, altura + 2.3, z), ROJO_FARO if i % 2 == 0 else BLANCO_FARO,
                           "SmoothPlastic", VERTICAL, "Cylinder"))
        altura += 4.6
        diam -= 0.55
    hijos.append(pieza("Puerta", (3.2, 5.5, 0.6), (x + 4.4, y + 3.6, z), MADERA_OSCURA, "Wood", ry(90), **DECORADO))
    hijos.append(pieza("Balcon", (0.8, diam + 4.5, diam + 4.5), (x, altura + 0.4, z), (70, 74, 82), "Metal", VERTICAL, "Cylinder"))
    for i in range(16):
        a = i * 360 / 16
        p = polar(a, (diam + 4.5) / 2 - 0.3, 0)
        hijos.append(poste(f"Baranda{i}", x + p[0], z + p[2], altura + 2.6, altura + 0.8, 0.25, (70, 74, 82)))
    hijos.append(pieza("Linterna", (4.4, diam - 0.6, diam - 0.6), (x, altura + 3, z), (220, 240, 255), "Glass", VERTICAL, "Cylinder",
                       Transparency=0.45, **DECORADO))
    lampara = pieza("Lampara", (2.6, 2.6, 2.6), (x, altura + 3, z), (255, 236, 160), "Neon", forma="Ball", **DECORADO)
    lampara["children"] = [luz(70, 2.2, (255, 236, 170))]
    hijos.append(lampara)
    # Haz de luz: cilindro a lo largo de X que nace en la lámpara. El cliente lo gira.
    hijos.append(pieza("Haz", (60, 2.2, 2.2), (x + 30, altura + 3, z), (255, 244, 200), "Neon", I3, "Cylinder",
                       Transparency=0.82, **FANTASMA))
    for i, (alto, d) in enumerate(((1.4, diam + 0.6), (1.2, diam - 1.6), (1.1, diam - 3.6), (1.0, 1.4))):
        hijos.append(pieza(f"Techo{i}", (alto, d, d), (x, altura + 5.8 + i * 1.15, z), ROJO_FARO, "SmoothPlastic", VERTICAL, "Cylinder"))
    # Modelo 3D de Blender (tools/blender/faro.py, 39.25 de alto, linterna a 31.65 del piso,
    # puerta a +X en Blender, que en Roblox queda en -X: se gira 180° para que mire a la isla):
    # reemplaza la torre de primitivas; la Lampara y el Haz quedan.
    hijos.append(ancla("Faro", (x, y - 0.15, z), (17, 39.25, 17), ry(180), ajuste="alto",
                       reemplaza="Base,Torre,Puerta,Balcon,Baranda,Linterna,Techo"))
    return grupo("Faro", hijos)


def campamento():
    """Fogata con troncos para sentarse y una hamaca entre dos palmeras."""
    a = L["campAngle"]
    r = base_con_z(direccion(a))
    y = L["plateauHeight"]
    hijos = []
    for i in range(9):  # anillo de piedras
        p = polar(i * 40, 2.6, y + 0.3)
        hijos.append(pieza(f"Piedra{i}", (1.3, 0.8, 1.1), p, ROCA[i % 3], "Slate", ry(i * 40)))
    for i in range(3):  # leños cruzados
        hijos.append(pieza(f"Leno{i}", (3.4, 0.6, 0.6), (0, y + 0.55, 0), MADERA_OSCURA, "Wood", ry(i * 60)))
    llama = pieza("Llama", (1, 1, 1), (0, y + 1.2, 0), LUZ_CALIDA, **INVISIBLE, CanCollide=False)
    llama["children"] = [
        {"name": "Fuego", "className": "Fire",
         "properties": {"Size": 5, "Heat": 9, "Color": color((255, 140, 50)), "SecondaryColor": color((255, 226, 110))}},
        {"name": "Humo", "className": "Smoke",
         "properties": {"Size": 2, "Opacity": 0.08, "RiseVelocity": 4, "Color": color((210, 210, 210))}},
        luz(26, 2),
    ]
    hijos.append(llama)
    for i in range(4):  # troncos para sentarse
        ang = 45 + i * 90
        p = polar(ang, 7, y + 0.8)
        hijos.append(pieza(f"Banco{i}", (5, 1.6, 1.6), p, TRONCO[i % 2], "Wood", ry(-ang + 90), "Cylinder"))
    # Hamaca entre dos palmeras, a un costado.
    for lado in (-1, 1):
        hijos.append(palmera(f"PalmeraHamaca{lado}", (14 * lado, y - 0.4, 12), 90 - 70 * lado, 3, 6))
    for i, (lado, caida) in enumerate(((-1, 1.4), (0, 2.0), (1, 1.4))):
        hijos.append(pieza(f"Hamaca{i}", (7.4, 0.25, 2.6), (6.5 * lado, y + 5.6 - caida, 12),
                           (255, 150, 120) if i % 2 == 0 else CREMA, "Fabric", rz(12 * lado), **DECORADO))
    return mover(grupo("Campamento", hijos), r, polar(a, L["campRadius"], 0))


# --- Puente y Cráter del Abismo -------------------------------------------------------
PIEDRA_PUENTE = (150, 146, 140)
BASALTO = ((38, 34, 42), (48, 44, 54), (30, 28, 34))
AZUL_PODER = (150, 200, 255)  # color del poder (UIConfig.Colors.Power)
PIZARRA_OSCURA = (58, 56, 66)
HUESO = (232, 224, 204)
HIERRO = (54, 56, 62)
LUZ_ROJA = (255, 50, 40)
CRISTAL_MORADO = (170, 70, 255)

CRATER = (L["craterCenter"][0], 0, L["craterCenter"][1])
RIM_Y = L["craterRimHeight"]
DECK_ABISMO = L["craterDeckHeight"]


def fondo_lago(rho):
    """Misma curva que WorldZones.lakeFloor: plataforma clara junto al acantilado y pozo hondo."""
    inicio = L["craterLakeRadius"] - L["craterShelfWidth"]
    plataforma = AGUA_Y - L["craterShelfDepth"]
    if rho >= inicio:
        t = min((rho - inicio) / L["craterShelfWidth"], 1)
        return plataforma + (L["craterShelfDepth"] - 3) * t
    t = max(rho - L["craterFlatRadius"], 0) / (inicio - L["craterFlatRadius"])
    return L["craterFloor"] + (plataforma - L["craterFloor"]) * (1 - math.cos(math.pi * t)) / 2


def _suave(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


def _puerta(a):
    """1 en la puerta del puente, 0 lejos (a en radianes)."""
    puerta = math.radians(L["bridgeAngle"] + 180)
    d = math.degrees(abs((a - puerta + math.pi) % (2 * math.pi) - math.pi))
    return 1 - _suave((d - 14) / 12)


def _cumbre(a):
    forma = 0.55 + 0.3 * math.sin(5 * a + 1.3) + 0.15 * math.sin(11 * a + 0.4) + 0.08 * math.sin(23 * a) + 0.1 * abs(math.sin(37 * a + 0.7))
    return L["craterPeakHeight"] * max(forma, 0.15) * (1 - _puerta(a))


def altura_crater(rho, angulo):
    """Misma curva que CraterShape.height (angulo en grados sobre XZ)."""
    a = math.radians(angulo)
    if rho < L["craterLakeRadius"]:
        return fondo_lago(rho)
    if rho < L["craterCliffRadius"]:
        pie = fondo_lago(L["craterLakeRadius"])
        t = (rho - L["craterLakeRadius"]) / (L["craterCliffRadius"] - L["craterLakeRadius"])
        return pie + (RIM_Y - pie) * t ** 0.6
    fin_paseo = L["craterCliffRadius"] + L["craterWalkWidth"]
    if rho < fin_paseo:
        return RIM_Y
    t = min((rho - fin_paseo) / (L["craterBaseRadius"] - fin_paseo), 1)
    ladera = RIM_Y + (L["seaFloorHeight"] - RIM_Y) * t ** 1.6
    alto = ladera + _cumbre(a) * math.sin(math.pi * min(t / 0.6, 1)) ** 1.3
    if rho < L["craterRimOuter"]:
        alto += (max(alto, RIM_Y) - alto) * _puerta(a)
    return alto


def polar_crater(angulo, rho, y):
    return add(CRATER, polar(angulo, rho, y))


def puente():
    """Puente de piedra de una sola rampa lisa y ancha desde la isla hasta la puerta del
    cráter. Misma geometría que WorldZones.bridgeEnds. Sobre él se camina más rápido
    (BridgeBoost en el cliente)."""
    d = direccion(L["bridgeAngle"])
    inicio = polar(L["bridgeAngle"], L["bridgeStartRadius"], CUBIERTA_Y)
    fin = add(CRATER, d, -(L["craterRimOuter"] - 2))
    fin = (fin[0], DECK_ABISMO, fin[2])
    largo = math.dist((inicio[0], inicio[2]), (fin[0], fin[2]))
    subida = fin[1] - inicio[1]
    largo3d = math.hypot(largo, subida)
    pendiente = math.degrees(math.atan2(subida, largo))
    r = mat(base_con_z(d), rx(-pendiente))  # +Z local sube hacia el cráter
    ancho = L["bridgeWidth"]
    medio = tuple((inicio[k] + fin[k]) / 2 for k in range(3))

    def sobre(x, y, z):
        """Punto en el plano del puente: x lateral, y sobre la cubierta, z a lo largo."""
        return add(medio, aplicar(r, (x, y, z)))

    hijos = [pieza("Cubierta", (ancho, 1.2, largo3d + 2), sobre(0, -0.6, 0), PIEDRA_PUENTE, "Cobblestone", r)]
    for lado in (-1, 1):
        hijos.append(pieza(f"Bordillo{lado}", (1.8, 2.6, largo3d + 2), sobre(lado * (ancho / 2 - 0.9), 1.3, 0), variar(PIEDRA_PUENTE, 12), "Cobblestone", r))
        hijos.append(pieza(f"Remate{lado}", (2.2, 0.5, largo3d + 2), sobre(lado * (ancho / 2 - 0.9), 2.85, 0), variar(PIEDRA_PUENTE, 20), "Slate", r))
        hijos.append(pieza(f"Muro{lado}", (0.6, 8, largo3d + 2), sobre(lado * (ancho / 2 - 0.6), 4, 0), PIEDRA_PUENTE, r=r, **INVISIBLE))
    for k in range(1, 5):  # pilares hasta el fondo del mar, uno a cada lado
        t = k / 5
        for lado in (-1, 1):
            p = sobre(lado * (ancho / 2 - 4), -1.2, -largo3d / 2 + largo3d * t)
            hijos.append(pieza(f"Pilar{k}_{lado}", (7, p[1] - L["seaFloorHeight"], 7), (p[0], (p[1] + L["seaFloorHeight"]) / 2, p[2]),
                               variar(PIEDRA_PUENTE, 8), "Cobblestone", base_con_z(d)))
    for k in range(7):  # faroles: cálidos cerca de la isla, verdes y fríos cerca del cráter
        t = (k + 0.5) / 7
        tono = tuple(int(LUZ_CALIDA[c] + ((120, 255, 170)[c] - LUZ_CALIDA[c]) * t) for c in range(3))
        for lado in (-1, 1):
            p = sobre(lado * (ancho / 2 - 0.6), 1.8, -largo3d / 2 + largo3d * t)
            caja = pieza(f"Luz{k}_{lado}", (1, 1.4, 1), (p[0], p[1] + 5, p[2]), tono, "Neon", **DECORADO)
            caja["children"] = [luz(18, 1.2, tono)]
            hijos += [poste(f"Farol{k}_{lado}", p[0], p[2], p[1] + 4.5, p[1], 0.5, HIERRO), caja]
    # Cartel junto a la entrada, legible desde la plaza.
    hijos.append(cartel("Cartel", (inicio[0] - ancho / 2 - 4, CUBIERTA_Y + 4, inicio[2] - 1), I3, "AL CRÁTER DEL ABISMO", 9, 1.8))
    return grupo("Puente", hijos)


def calavera(nombre, centro, escala):
    hijos = [pieza("Craneo", (escala, escala, escala), centro, HUESO, "SmoothPlastic", forma="Ball")]
    for lado in (-1, 1):
        ojo = pieza(f"Ojo{lado}", (escala * 0.22,) * 3, add(centro, (lado * escala * 0.2, escala * 0.05, -escala * 0.42)), LUZ_ROJA, "Neon",
                    forma="Ball", **DECORADO)
        if lado == 1:
            ojo["children"] = [luz(18, 2, LUZ_ROJA)]
        hijos.append(ojo)
    hijos.append(pieza("Mandibula", (escala * 0.7, escala * 0.3, escala * 0.6), add(centro, (0, -escala * 0.45, -escala * 0.1)), HUESO, "SmoothPlastic"))
    return grupo(nombre, hijos)


def puerta_abismo():
    """Puerta de basalto con calaveras de ojos rojos donde el puente toca el cráter."""
    a = L["bridgeAngle"] + 180  # del cráter hacia la isla
    r = base_con_z(direccion(a))  # +Z local apunta a la isla
    base = polar_crater(a, L["craterRimOuter"] - 3, 0)
    hijos = []
    for lado in (-1, 1):
        p = add(base, aplicar(r, (lado * (L["bridgeWidth"] / 2 + 2.5), 0, 0)))
        for k, (alto, ancho) in enumerate(((10, 6), (9, 5), (8, 4))):
            y0 = RIM_Y + sum(h for h, _ in ((10, 6), (9, 5), (8, 4))[:k])
            hijos.append(pieza(f"Columna{lado}_{k}", (ancho, alto, ancho), (p[0], y0 + alto / 2, p[2]), BASALTO[k % 3], "Basalt",
                               mat(r, ry(k * 17 * lado))))
        hijos.append(calavera(f"Calavera{lado}", (p[0], RIM_Y + 29.5, p[2]), 4.2))
    viga = add(base, (0, RIM_Y + 24, 0))
    hijos.append(pieza("Viga", (L["bridgeWidth"] + 12, 2.2, 2.4), viga, BASALTO[0], "Basalt", r))
    hijos += placa_volcanica("Letrero", (16, 3, 0.4), add(viga, (0, -2.6, 0)), r, "CRÁTER DEL ABISMO", "Back")
    for lado in (-1, 1):  # cadenas colgando de la viga
        for k in range(6):
            p = add(viga, aplicar(r, (lado * 4.5, -2 - k * 1.3, 0.8)))
            hijos.append(pieza(f"Eslabon{lado}_{k}", (0.35, 1.2, 0.7), p, HIERRO, "Metal", mat(r, ry(90 * (k % 2))), **DECORADO))
    return grupo("PuertaDelAbismo", hijos)


def cresta(nombre, angulo, rho, humo=False):
    """Cresta de roca volcánica en el borde exterior del cráter: un pico de bloques de
    basalto que se afinan hacia arriba (como una montaña chica) y rocas sueltas al pie;
    algunas echan humo por la punta."""
    y = altura_crater(rho + 5, angulo) - 2
    base = polar_crater(angulo, rho, 0)
    hijos, ancho = [], rng.uniform(10, 15)
    alto_total = rng.uniform(16, 34)
    for k in range(3):
        alto = alto_total * (0.42, 0.33, 0.25)[k] + 1
        p = (base[0] + rng.uniform(-1.5, 1.5), y + alto / 2, base[2] + rng.uniform(-1.5, 1.5))
        giro = mat(ry(rng.uniform(0, 90)), mat(rx(rng.uniform(-9, 9)), rz(rng.uniform(-9, 9))))
        roca = pieza(f"Pico{k}", (ancho, alto, ancho * rng.uniform(0.7, 0.95)), p, BASALTO[k % 3], "Basalt", giro)
        if k == 2 and humo:
            roca["children"] = [{"name": "Humo", "className": "Smoke", "properties": {
                "Color": color((70, 62, 62)), "Opacity": 0.14, "RiseVelocity": 7, "Size": 16}}]
        hijos.append(roca)
        y += alto - 1
        ancho *= 0.62
    for k in range(rng.randint(1, 2)):  # rocas sueltas al pie
        s = rng.uniform(4, 7)
        q = add(base, polar(rng.uniform(0, 360), rng.uniform(7, 10), altura_crater(rho + 5, angulo) - 1 + s * 0.3))
        hijos.append(con_prop(pieza(f"Roca{k}", (s * 1.3, s, s), q, BASALTO[(k + 1) % 3], "Basalt", mat(ry(rng.uniform(0, 90)), rx(rng.uniform(-15, 15)))),
                              f"Roca{1 + k % 2}"))
    # Modelo 3D del pico (Cresta1/2 de Blender) en lugar de los bloques; el humo va aparte.
    n = int("".join(c for c in nombre if c.isdigit()) or 0)
    hijos.append(ancla(f"Cresta{1 + n % 2}", (base[0], altura_crater(rho + 5, angulo) - 2, base[2]), (12, alto_total + 2, 12),
                       ry(n * 37), "alto", "Pico"))
    if humo:
        hijos.append({"name": "Humo", "className": "Part", "properties": {
            **pieza("Humo", (2, 2, 2), (base[0], altura_crater(rho + 5, angulo) - 2 + alto_total, base[2]), BASALTO[0], **INVISIBLE,
                    CanCollide=False)["properties"]},
            "children": [{"name": "Humo", "className": "Smoke", "properties": {
                "Color": color((70, 62, 62)), "Opacity": 0.14, "RiseVelocity": 7, "Size": 16}}]})
    return grupo(nombre, hijos)


def cascada_lava(nombre, angulo):
    """Río de lava que baja por la ladera exterior hasta el mar, con vapor al tocar el agua."""
    rho0, rho1 = L["craterRimOuter"] - 2, L["craterBaseRadius"] - 14
    pasos, ancho = 9, rng.uniform(3.2, 4.6)
    hijos, puntos = [], []
    for k in range(pasos + 1):
        rho = rho0 + (rho1 - rho0) * k / pasos
        a = angulo + math.sin(k * 0.9 + angulo) * 1.3
        puntos.append(polar_crater(a, rho, max(altura_crater(rho, a), AGUA_Y) + 0.3))
    for k in range(pasos):
        p0, p1 = puntos[k], puntos[k + 1]
        d = norm(tuple(p1[i] - p0[i] for i in range(3)))
        largo = math.dist(p0, p1) + 0.8
        medio = tuple((p0[i] + p1[i]) / 2 for i in range(3))
        tramo = pieza(f"Tramo{k}", (ancho * (1 + k * 0.04), 0.5, largo), medio, LAVA, "Neon", base_con_z(d), **FANTASMA)
        if k % 4 == 1:
            tramo["children"] = [luz(18, 1.1, LAVA)]
        hijos.append(tramo)
    fin = puntos[-1]
    charco = pieza("Charco", (0.4, 10, 10), (fin[0], AGUA_Y + 0.1, fin[2]), LAVA, "Neon", VERTICAL, "Cylinder", **FANTASMA)
    charco["children"] = [{"name": "Vapor", "className": "Smoke", "properties": {
        "Color": color((235, 235, 240)), "Opacity": 0.12, "RiseVelocity": 5, "Size": 9}}]
    hijos.append(charco)
    return grupo(nombre, hijos)


def paseo_crater():
    """Paseo de obsidiana pulida al borde del acantilado (desde aquí se alimenta), con
    filos de oro y obeliscos con fuego cada 30 grados (menos en la puerta)."""
    rho0, rho1 = L["craterCliffRadius"] + 1.2, L["craterCliffRadius"] + 10
    cx, cz = CRATER[0], CRATER[2]
    hijos = anillo_tallado("Losa", cx, cz, (rho0 + rho1) / 2, 120, rho1 - rho0, 0.6, RIM_Y + 0.3, MARMOL_NEGRO, "Marble")
    hijos += anillo_tallado("OroDentro", cx, cz, rho0 + 0.2, 120, 0.4, 0.65, RIM_Y + 0.35, ORO, "Metal", **DECORADO)
    hijos += anillo_tallado("OroFuera", cx, cz, rho1, 120, 0.4, 0.65, RIM_Y + 0.35, ORO, "Metal", **DECORADO)
    llegada = L["bridgeAngle"] + 180
    for k in range(12):
        a = k * 30 + 15
        if abs((a - llegada + 180) % 360 - 180) > 20:
            hijos.append(obelisco(f"Obelisco{k + 1}", a, rho1 - 2, RIM_Y + 0.3))
    return grupo("Paseo", hijos)


def esqueleto(nombre, angulo, rho, largo):
    """Esqueleto de un pez gigante tirado sobre el anillo."""
    a = math.radians(angulo)
    tang = (-math.sin(a), 0, math.cos(a))
    centro = polar_crater(angulo, rho, RIM_Y + 0.6)
    r = base_con_z(tang)
    hijos = [pieza("Columna", (1.4, 1.4, largo), add(centro, (0, 1.2, 0)), HUESO, "SmoothPlastic", r)]
    n = int(largo / 3.2)
    for k in range(n):
        z = -largo / 2 + 3 + k * 3.2
        alto = 6 * math.sin(math.pi * (k + 1) / (n + 1)) + 2
        for lado in (-1, 1):
            p = add(centro, aplicar(r, (lado * alto * 0.35, 1.2 + alto / 2 - 0.4, z)))
            hijos.append(pieza(f"Costilla{k}_{lado}", (0.6, alto, 0.6), p, HUESO, "SmoothPlastic", mat(r, rz(-lado * 28)), **DECORADO))
    hijos.append(calavera("Calavera", add(centro, aplicar(r, (0, 3, -largo / 2 - 2.5))), 6))
    for k in range(3):
        hijos.append(pieza(f"Cola{k}", (0.5, 4 - k, 3.4 - k * 0.8), add(centro, aplicar(r, (0, 1.6, largo / 2 + 1 + k * 1.6))), HUESO,
                           "SmoothPlastic", mat(r, rx(30 * (k - 1))), **DECORADO))
    return grupo(nombre, hijos)


def cristales(nombre, angulo, rho):
    base = polar_crater(angulo, rho, RIM_Y)
    hijos = []
    for k in range(6):
        alto = rng.uniform(3, 8)
        p = add(base, (rng.uniform(-2.5, 2.5), alto / 2 - 0.5, rng.uniform(-2.5, 2.5)))
        hijos.append(pieza(f"Cristal{k}", (1.2, alto, 1.2), p, CRISTAL_MORADO, "Neon", mat(ry(rng.uniform(0, 90)), rz(rng.uniform(-25, 25))), **DECORADO))
    hijos[0]["children"] = [luz(26, 2, CRISTAL_MORADO)]
    return grupo(nombre, hijos)


def crater():
    hijos = []
    tope = L["pedestalTop"]
    # Sin pedestal ni rocas en el centro: el lago queda libre para que el gigante nade.
    # Anclaje del gigante: invisible, mira hacia -Z (hacia el puente y la isla).
    hijos.append(pieza("GuaridaGigante", (2, 1, 2), (CRATER[0], tope, CRATER[2]), CORAL, **INVISIBLE, CanCollide=False))
    hijos.append(puerta_abismo())
    llegada = L["bridgeAngle"] + 180

    def libre(a, margen):
        return abs((a - llegada + 180) % 360 - 180) > margen

    hijos.append(paseo_crater())
    # Corona de crestas de roca en el borde exterior (con hueco en la puerta).
    crestas, n = [], 40
    for k in range(n):
        a = k * 360 / n + rng.uniform(-3, 3)
        if libre(a, 18):
            rho = L["craterRimOuter"] + rng.uniform(-3, 2)
            crestas.append(cresta(f"Cresta{k}", a, rho, humo=k % 5 == 0))
    hijos.append(grupo("Crestas", crestas, "Folder"))
    hijos.append(grupo("Lava", [cascada_lava(f"Cascada{k}", a) for k, a in enumerate((20, 62, 108, 150, 192, 228, 318, 345))], "Folder"))
    hijos.append(esqueleto("Esqueleto1", llegada + 55, L["craterCliffRadius"] + 26, 26))
    hijos.append(esqueleto("Esqueleto2", llegada - 120, L["craterCliffRadius"] + 25, 20))
    hijos.append(grupo("Cristales", [cristales(f"Cristales{k}", llegada + d, L["craterCliffRadius"] + L["craterWalkWidth"] - 6) for k, d in enumerate((30, 95, 160, 205, 250, 320))], "Folder"))
    # Pared invisible al borde del acantilado, sin huecos: nadie cae al abismo.
    muros, m = [], 72
    rho = L["craterCliffRadius"] + 0.5
    for k in range(m):
        a0, a1 = k * 360 / m, (k + 1) * 360 / m
        p0, p1 = polar_crater(a0, rho, 0), polar_crater(a1, rho, 0)
        muros.append(muro(f"Muro{k}", (p0[0], p0[2]), (p1[0], p1[2]), RIM_Y, 8))
    hijos.append(grupo("Borde", muros, "Folder"))
    # Línea coral brillante en el borde: se alimenta desde cualquier punto de la orilla.
    orilla, rho = [], L["craterCliffRadius"] + 2.6
    for k in range(m):
        a0, a1 = k * 360 / m, (k + 1) * 360 / m
        p0, p1 = polar_crater(a0, rho, 0), polar_crater(a1, rho, 0)
        dx, dz = p1[0] - p0[0], p1[2] - p0[2]
        centro = ((p0[0] + p1[0]) / 2, RIM_Y + 0.34, (p0[2] + p1[2]) / 2)
        orilla.append(pieza(f"Brillo{k}", (3.6, 0.1, math.hypot(dx, dz) + 0.3), centro, CORAL, "Neon",
                            ry(math.degrees(math.atan2(dx, dz))), Transparency=0.25, **FANTASMA))
    hijos.append(grupo("OrillaAlimentar", orilla, "Folder"))
    return grupo("Crater", hijos)


LAVA = (255, 120, 40)
OBSIDIANA = (26, 22, 30)
MARMOL_NEGRO = ((34, 30, 38), (30, 27, 34))


def obelisco(nombre, angulo, radio, y):
    """Obelisco de obsidiana sobre el muro, con bandas de oro, una veta de lava hacia
    adentro y fuego en la punta."""
    x, _, z = polar_crater(angulo, radio, 0)
    giro = ry(-angulo)
    alto = 9
    fuego = pieza("Llama", (0.6, 0.6, 0.6), (x, y + alto + 1.3, z), LAVA, **INVISIBLE, CanCollide=False)
    fuego["children"] = [
        {"name": "Fuego", "className": "Fire",
         "properties": {"Size": 3.5, "Heat": 7, "Color": color((255, 150, 50)), "SecondaryColor": color((255, 70, 20))}},
        luz(10, 0.6, LAVA),  # suave: de noche no tiñe todo de rojo
    ]
    adentro = polar_crater(angulo, radio - 1.21, 0)
    return grupo(nombre, [
        pieza("Zocalo", (3.2, 1.2, 3.2), (x, y + 0.6, z), MARMOL_NEGRO[1], "Marble", giro),
        pieza("Fuste", (2.4, alto, 2.4), (x, y + alto / 2, z), MARMOL_NEGRO[0], "Marble", giro),
        pieza("BandaBaja", (2.6, 0.3, 2.6), (x, y + 2.75, z), ORO, "Metal", giro, **DECORADO),
        pieza("BandaAlta", (2.6, 0.3, 2.6), (x, y + alto - 0.6, z), ORO, "Metal", giro, **DECORADO),
        pieza("Veta", (0.06, alto - 4.4, 0.35), (adentro[0], y + 2.9 + (alto - 4.4) / 2 + 0.2, adentro[2]), LAVA, "Neon", giro, **FANTASMA),
        pieza("Cuenco", (0.8, 3.2, 3.2), (x, y + alto + 0.4, z), ORO, "Metal", VERTICAL, "Cylinder", **DECORADO),
        pieza("Brasas", (0.15, 2.6, 2.6), (x, y + alto + 0.82, z), LAVA, "Neon", VERTICAL, "Cylinder", **FANTASMA),
        fuego,
    ])


def linea(nombre, a, b, y, ancho, alto, rgb, material, **extra):
    """Pieza recta del punto a al b (x, z) a la altura y (centro)."""
    dx, dz = b[0] - a[0], b[1] - a[1]
    return pieza(nombre, (ancho, alto, math.hypot(dx, dz)), ((a[0] + b[0]) / 2, y, (a[1] + b[1]) / 2), rgb, material,
                 ry(math.degrees(math.atan2(dx, dz))), **extra)


def guarida_descanso():
    """Templo de obsidiana que sube desde el fondo del lago durante el descanso y lo llena de
    pared a pared (radio restArenaRadius: ahí la pared del pozo llega a la altura del piso):
    un círculo de mármol negro pulido con incrustaciones de oro y finas líneas de lava, todo
    en orden (anillos y radios como una brújula). Muro bajo con remate de oro (no te caes) y
    12 obeliscos con fuego sobre él. La base baja hasta el fondo (no queda hueco debajo).
    Mientras no hay descanso queda enterrada restArenaSink studs más abajo (RestArena). En el centro, un estrado de dos escalones con el núcleo de
    poder y el cristal flotando sobre un haz de luz. No tiene rampas: se llega con el botón
    IR A LA GUARIDA. Vive en ServerStorage; RestArena la clona al derrotar al monstruo. Solo
    en ella se gana poder en el descanso (WorldZones.isInRestArena)."""
    R, top = L["restArenaRadius"], L["restArenaTop"]
    cx, cz = CRATER[0], CRATER[2]
    piso = top + 0.1  # cara de arriba del piso
    hijos = [
        pieza("Cimiento", (12, (R - 4) * 2, (R - 4) * 2), (cx, top - 14, cz), BASALTO[2], "Basalt", VERTICAL, "Cylinder"),
        pieza("Base", (8, R * 2, R * 2), (cx, top - 4.2, cz), MARMOL_NEGRO[0], "Marble", VERTICAL, "Cylinder"),
        # Costado: una franja de oro arriba y una línea de lava más abajo, parejas.
        pieza("Aro", (0.6, R * 2 + 0.5, R * 2 + 0.5), (cx, top - 0.9, cz), ORO, "Metal", VERTICAL, "Cylinder"),
        pieza("LineaLava", (0.3, R * 2 + 0.3, R * 2 + 0.3), (cx, top - 3.4, cz), LAVA, "Neon", VERTICAL, "Cylinder", **FANTASMA),
        pieza("Piso", (0.4, R * 2 - 0.6, R * 2 - 0.6), (cx, top - 0.1, cz), OBSIDIANA, "Marble", VERTICAL, "Cylinder",
              Reflectance=0.1),
    ]
    # Incrustaciones del piso (apenas sobresalen): anillos de oro, radios y una línea de lava.
    sobre = piso + 0.03
    hijos += anillo_tallado("AnilloInterior", cx, cz, 16, 64, 0.5, 0.06, sobre + 0.03, ORO, "Metal", **FANTASMA)
    hijos += anillo_tallado("AnilloMedio", cx, cz, 33, 96, 0.6, 0.06, sobre + 0.03, ORO, "Metal", **FANTASMA)
    hijos += anillo_tallado("AnilloExterior", cx, cz, 58, 128, 0.7, 0.06, sobre + 0.03, ORO, "Metal", **FANTASMA)
    # Con la guarida grande (más arriba, el pozo es más ancho) un anillo más llena la franja de afuera.
    if R > 100:
        hijos += anillo_tallado("AnilloBorde", cx, cz, (58 + R - 7) / 2, 160, 0.7, 0.06, sobre + 0.03, ORO, "Metal", **FANTASMA)
    hijos += anillo_tallado("AnilloLava", cx, cz, R - 7, 120, 0.3, 0.06, sobre + 0.03, LAVA, "Neon", **FANTASMA)
    for k in range(8):
        a = k * 45
        p0, p1 = polar_crater(a, 16.3, 0), polar_crater(a, 32.7, 0)
        hijos.append(linea(f"Radio{k}", (p0[0], p0[2]), (p1[0], p1[2]), sobre, 0.4, 0.06, ORO, "Metal", **FANTASMA))
        q = polar_crater(a + 22.5, 40, sobre)
        hijos.append(pieza(f"Rombo{k}", (1.6, 0.06, 1.6), q, ORO, "Metal", ry(-(a + 22.5) + 45), **FANTASMA))
        p2, p3 = polar_crater(a + 22.5, 33.7, 0), polar_crater(a + 22.5, 57.3, 0)
        hijos.append(linea(f"RadioExt{k}", (p2[0], p2[2]), (p3[0], p3[2]), sobre, 0.5, 0.06, ORO, "Metal", **FANTASMA))
        q2 = polar_crater(a, 70, sobre)
        hijos.append(pieza(f"RomboExt{k}", (2.4, 0.06, 2.4), q2, ORO, "Metal", ry(-a + 45), **FANTASMA))
    # Estrado central de dos escalones con labio de oro y el núcleo de poder.
    for nivel, (radio, alto) in enumerate(((12, 0.7), (8, 1.4)), start=1):
        hijos.append(pieza(f"Estrado{nivel}", (alto, radio * 2, radio * 2), (cx, piso + alto / 2, cz), MARMOL_NEGRO[nivel % 2],
                           "Marble", VERTICAL, "Cylinder"))
        hijos.append(pieza(f"Labio{nivel}", (0.2, radio * 2 + 0.5, radio * 2 + 0.5), (cx, piso + alto - 0.12, cz), ORO, "Metal",
                           VERTICAL, "Cylinder", **DECORADO))
    tope = piso + 1.4
    hijos.append(pieza("NucleoOro", (0.1, 10, 10), (cx, tope + 0.04, cz), ORO, "Metal", VERTICAL, "Cylinder", **FANTASMA))
    hijos.append(pieza("Nucleo", (0.12, 9, 9), (cx, tope + 0.07, cz), AZUL_PODER, "Neon", VERTICAL, "Cylinder", **FANTASMA))
    hijos.append(pieza("Haz", (7, 1.6, 1.6), (cx, tope + 3.6, cz), AZUL_PODER, "Neon", VERTICAL, "Cylinder",
                       Transparency=0.75, **FANTASMA))
    cristal = pieza("CristalPoder", (3.6, 3.6, 3.6), (cx, top + 9, cz), AZUL_PODER, "Neon", mat(rx(45), rz(35)), **FANTASMA)
    cristal["children"] = [luz(20, 1.2, AZUL_PODER)]
    hijos.append(cristal)
    for k in range(4):
        p = polar_crater(k * 90 + 45, 5.5, top + 9)
        hijos.append(pieza(f"Orbita{k}", (1, 1, 1), p, AZUL_PODER, "Neon", mat(rx(45), rz(35)), **FANTASMA))
    # Muro bajo alrededor, con remate de oro (más la pared invisible alta, abajo).
    hijos += anillo_tallado("Parapeto", cx, cz, R - 0.9, 64, 1.6, 2.6, top + 2.7, (BASALTO[1], BASALTO[0]), "Basalt")
    hijos += anillo_tallado("Remate", cx, cz, R - 0.9, 64, 2, 0.35, top + 3, ORO, "Metal", **DECORADO)
    for k in range(12):  # obeliscos con fuego sobre el muro
        hijos.append(obelisco(f"Obelisco{k + 1}", k * 30 + 15, R - 0.9, piso))
    # Pared invisible alta al borde, sin huecos: nadie se cae al lago.
    muros, m = [], 64
    for k in range(m):
        a0, a1 = k * 360 / m, (k + 1) * 360 / m
        p0, p1 = polar_crater(a0, R + 0.2, 0), polar_crater(a1, R + 0.2, 0)
        muros.append(muro(f"Muro{k}", (p0[0], p0[2]), (p1[0], p1[2]), top, 8))
    hijos.append(grupo("Borde", muros, "Folder"))
    return grupo("GuaridaDescanso", hijos)


def main():
    isla = grupo("Isla", [
        zona_entrenamiento(),
        puente(),
        crater(),
        grupo("Muelles", [muelle(i + 1, a) for i, a in enumerate(L["pierAngles"])], "Folder"),
        aparicion(),
        plaza_aparicion(),
        arco_entrada(),
        cabana(),
        faro(),
        campamento(),
        decoracion(),
        boyas(),
        espuma(),
        limites(),
    ])
    del isla["name"]  # Rojo toma el nombre del archivo (Isla)
    # Con streaming activo, la isla completa llega siempre al cliente: la espuma, las
    # boyas y el faro se animan en el cliente y tienen que existir desde el inicio.
    isla["properties"] = {"ModelStreamingMode": "Persistent"}
    SALIDA.parent.mkdir(parents=True, exist_ok=True)
    SALIDA.write_text(json.dumps(isla, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    partes = json.dumps(isla).count('"className": "Part"')
    print(f"{SALIDA.name}: {partes} partes")
    # La guarida del descanso va aparte, a ServerStorage: no existe en el mapa hasta que se
    # derrota al monstruo (RestArena la clona, la hace emerger y la hunde al terminar).
    guarida = guarida_descanso()
    del guarida["name"]
    guarida["className"] = "Model"
    GUARIDA.write_text(json.dumps(guarida, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    partes = json.dumps(guarida).count('"className": "Part"')
    print(f"{GUARIDA.name}: {partes} partes")


if __name__ == "__main__":
    main()
