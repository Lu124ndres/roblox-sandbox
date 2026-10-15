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


def antorcha(nombre, x, z, y_base=CUBIERTA_Y, color_fuego=((255, 150, 60), (255, 230, 120)), color_luz=LUZ_CALIDA):
    """Antorcha tiki: fuego real (Fire) y luz. Se ve de día y de noche."""
    arriba = y_base + 6.5
    fuego = pieza("Llama", (0.6, 0.6, 0.6), (x, arriba + 0.6, z), LUZ_CALIDA, **INVISIBLE, CanCollide=False)
    fuego["children"] = [
        {"name": "Fuego", "className": "Fire",
         "properties": {"Size": 3.2, "Heat": 7, "Color": color(color_fuego[0]), "SecondaryColor": color(color_fuego[1])}},
        luz(20, 1.8, color_luz),
    ]
    return grupo(nombre, [
        poste("Palo", x, z, arriba, y_base, 0.55, MADERA_MEDIA),
        pieza("Amarre", (0.5, 0.75, 0.75), (x, arriba - 1.2, z), PAJA, "Fabric", VERTICAL, "Cylinder", **DECORADO),
        pieza("Cuenco", (1.1, 1.8, 1.8), (x, arriba + 0.15, z), MADERA_OSCURA, "Wood", VERTICAL, "Cylinder", **DECORADO),
        fuego,
    ])


def cartel(nombre, pos, r, texto, ancho, alto, cara="Front"):
    tabla = pieza("Tabla", (ancho, alto, 0.4), pos, MADERA_CLARA, "WoodPlanks", r, **DECORADO)
    tabla["children"] = [{
        "name": "Texto", "className": "SurfaceGui",
        "properties": {"Face": cara, "SizingMode": "PixelsPerStud", "PixelsPerStud": 40, "LightInfluence": 1},
        "children": [{
            "name": "Etiqueta", "className": "TextLabel",
            "properties": {
                "Size": {"UDim2": [[1, 0], [1, 0]]}, "BackgroundTransparency": 1, "Text": texto, "TextScaled": True,
                "TextColor3": color(MADERA_OSCURA),
                "FontFace": {"Font": {"family": "rbxasset://fonts/families/FredokaOne.json", "weight": "Regular", "style": "Normal"}},
            },
        }],
    }]
    return tabla


# --- Zona de entrenamiento ------------------------------------------------------------
# Un color por estanque, del más débil (verde) al más fuerte (dorado).
COLORES_ESTANQUE = (
    (120, 220, 120), (90, 210, 200), (90, 170, 255), (130, 120, 255), (190, 110, 255),
    (255, 110, 200), (255, 90, 90), (255, 150, 60), (255, 205, 60), (255, 245, 170),
    (120, 245, 255),  # 11: el sagrado del centro (solo Robux)
)
SAGRADO = L["trainingPondCount"] + 1  # mismo índice que WorldZones.SACRED_POND
ORO = (255, 200, 70)


def angulo_estanque(i):
    """Misma fórmula que WorldZones.pondAngle (i empieza en 1)."""
    paso = 360 / L["trainingPondCount"]
    return L["spawnAngle"] + paso / 2 + (i - 1) * paso


PIEDRA_TALLADA = ((190, 176, 152), (176, 162, 140), (164, 150, 130))
PIEDRA_ESCALON = (112, 104, 98)
HOJA_LOTO = ((70, 150, 70), (90, 170, 80))


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


def farol_piedra(nombre, x, z, y, tono, alto=4.2):
    """Farol de piedra con la luz del color del estanque."""
    return grupo(nombre, [
        pieza("Base", (1.6, 0.5, 1.6), (x, y + 0.25, z), PIEDRA_ESCALON, "Slate"),
        pieza("Pilar", (0.7, alto - 1.6, 0.7), (x, y + 0.5 + (alto - 1.6) / 2, z), PIEDRA_TALLADA[1], "Limestone"),
        dict(pieza("Lampara", (1.1, 1, 1.1), (x, y + alto - 0.6, z), tono, "Neon", Transparency=0.15, **DECORADO), children=[luz(14, 1.1, tono)]),
        pieza("Techo", (1.8, 0.35, 1.8), (x, y + alto + 0.05, z), PIEDRA_ESCALON, "Slate", **DECORADO),
        pieza("Remate", (0.6, 0.4, 0.6), (x, y + alto + 0.4, z), PIEDRA_ESCALON, "Slate", ry(45), **DECORADO),
    ])


def estanque(i):
    """Estanque i: anillo de piedra tallada con una línea que brilla del color de su nivel,
    escalón exterior, círculo de runas bajo el agua, cristal flotante en el centro (lo anima
    PondFx), nenúfares y 4 faroles de piedra. Los niveles altos suman cristales y órbitas.
    El agua es terreno (TerrainBuilder). La pieza "Estanque" lleva el ProximityPrompt."""
    sagrado = i == SAGRADO
    a = 90 if sagrado else angulo_estanque(i)
    centro = (0, 0, 0) if sagrado else polar(a, L["trainingPondRingRadius"], 0)
    cx, cz = centro[0], centro[2]
    y = L["plateauHeight"]
    agua = L["trainingPondWaterTop"]
    R = L["sacredPondRadius"] if sagrado else L["trainingPondRadius"]
    n = 32 if sagrado else 20  # bloques del anillo
    tono = COLORES_ESTANQUE[(i - 1) % len(COLORES_ESTANQUE)]
    piedra = ((255, 214, 110), (240, 196, 90)) if i >= 10 else PIEDRA_TALLADA
    hijos = []
    hijos += anillo_tallado("Borde", cx, cz, R + 0.9, n, 1.7, 1.5, y + 1.1, piedra, "Limestone")
    hijos += anillo_tallado("BrilloTope", cx, cz, R + 0.3, n, 0.18, 0.08, y + 1.14, tono, "Neon", **FANTASMA)
    hijos += anillo_tallado("Brillo", cx, cz, R + 0.02, n, 0.2, 0.14, agua + 0.12, tono, "Neon", **FANTASMA)
    hijos += anillo_tallado("Escalon", cx, cz, R + 2.4, n, 1.3, 0.8, y + 0.45, PIEDRA_ESCALON, "Slate")
    # Tapa invisible apenas bajo el agua: se camina por el estanque sin hundirse.
    tapa_y = agua - L["pondCoverDepth"] - 0.5
    hijos.append(pieza("Tapa", (1, 2 * R + 1, 2 * R + 1), (cx, tapa_y, cz), tono, "SmoothPlastic", VERTICAL, "Cylinder",
                       Transparency=1, CanQuery=False, CanTouch=False, CastShadow=False))
    # Runas bajo el agua: brillan a través de ella.
    hijos += anillo_tallado("Runa", cx, cz, R * 0.55, 16, 0.3, 0.15, agua - 1.4, tono, "Neon", **FANTASMA)
    for k in range(6):
        p = add((cx, 0, cz), polar(k * 60 + 30, R * 0.38, 0))
        hijos.append(pieza(f"Trazo{k}", (2.2, 0.15, 0.35), (p[0], agua - 1.4, p[2]), tono, "Neon", ry(-(k * 60 + 30)), **FANTASMA))
    if sagrado:  # el pez dorado de la plaza, ahora en medio del agua sagrada
        hijos.append(estatua_central(1.2, agua))
    # Cristal flotante (diamante) en el centro; crece con el nivel.
    lado = 1.1 + i * 0.12
    cristal = pieza("CristalFlotante", (lado, lado, lado), (cx, agua + 3.4, cz), tono, "Neon", mat(rx(45), rz(35)), **FANTASMA)
    cristal["children"] = [luz(18, 1.3, tono)]
    cristal["attributes"] = {"Indice": i}
    if not sagrado:
        hijos.append(cristal)
    if i >= 7:  # órbitas de cristalitos (en el sagrado, alrededor de la estatua)
        for k in range(6 if sagrado else 3):
            p = add((cx, 0, cz), polar(k * (60 if sagrado else 120), 7 if sagrado else 2.6, 0))
            hijos.append(pieza(f"Orbita{k + 1}", (0.6, 0.6, 0.6), (p[0], agua + 3.4, p[2]), tono, "Neon", mat(rx(45), rz(35)), **FANTASMA))
    # Nenúfares (y flores en algunos).
    for k in range(9 if sagrado else 5):
        th, rho = i * 37 + k * 72 + rng.uniform(-12, 12), R * rng.uniform(0.5 if sagrado else 0.45, 0.82)
        p = add((cx, 0, cz), polar(th, rho, 0))
        d = rng.uniform(1.6, 2.4)
        hijos.append(pieza(f"Nenufar{k}", (0.12, d, d), (p[0], agua + 0.08, p[2]), HOJA_LOTO[k % 2], "Grass", VERTICAL, "Cylinder", **FANTASMA))
        if k % 2 == 0:
            hijos.append(pieza(f"Flor{k}", (0.7, 0.45, 0.7), (p[0], agua + 0.35, p[2]), (255, 170, 210), "SmoothPlastic", forma="Ball", **FANTASMA))
            hijos.append(pieza(f"Centro{k}", (0.3, 0.3, 0.3), (p[0], agua + 0.5, p[2]), (255, 230, 120), "Neon", forma="Ball", **FANTASMA))
    # Faroles de piedra entre el borde y el escalón.
    faroles = 8 if sagrado else 4
    for k in range(faroles):
        p = add((cx, 0, cz), polar(a + 45 + k * 360 / faroles, R + 3.6, 0))
        hijos.append(farol_piedra(f"Farol{k + 1}", p[0], p[2], y, tono))
        if i >= 4:  # racimo de cristales al pie del farol
            for m in range(3):
                q = add(p, polar(m * 120 + k * 30, 1.1, 0))
                alto = rng.uniform(0.8, 1.6) + i * 0.08
                hijos.append(pieza(f"Racimo{k}_{m}", (0.45, alto, 0.45), (q[0], y + alto / 2, q[2]), tono, "Neon",
                                   mat(ry(rng.uniform(0, 90)), rz(rng.uniform(-20, 20))), **FANTASMA))
    # Pieza del ProximityPrompt en el centro del agua; alcanza a todo el borde. El sagrado es
    # más grande: lleva 4 alrededor de la estatua para que el prompt llegue desde cualquier lado.
    puntos = [polar(45 + k * 90, R * 0.62, 0) for k in range(4)] if sagrado else [(0, 0, 0)]
    for k, q in enumerate(puntos):
        marcador = pieza("Estanque", (2, 1, 2), (cx + q[0], agua + 1, cz + q[2]), tono, **INVISIBLE, CanCollide=False)
        marcador["attributes"] = {"Indice": i}
        hijos.append(marcador)
    return grupo(f"Estanque{i}", hijos)


def estatua_central(e=1.8, agua=None):
    """Pez dorado sobre un pedestal: el centro de la zona de entrenamiento. e = escala.
    Con `agua`, sale del estanque sagrado: una columna desde el fondo en lugar de la base."""
    y = L["plateauHeight"]
    giro = mat(ry(30), rx(-35))
    fondo = L["trainingPondFloor"]
    base = (pieza("Base", (1.2, 14 * e, 14 * e), (0, y + 0.6, 0), (150, 146, 140), "Cobblestone", VERTICAL, "Cylinder")
            if agua is None else
            pieza("Columna", (y + 1.2 - fondo, 6.6 * e, 6.6 * e), (0, (y + 1.2 + fondo) / 2, 0), (176, 170, 160), "Marble", VERTICAL, "Cylinder"))
    hijos = [
        base,
        pieza("Pedestal", (6 * e, 6 * e, 6 * e), (0, y + 1.2 + 3 * e, 0), (200, 194, 184), "Marble", VERTICAL, "Cylinder"),
        pieza("Corona", (0.8 * e, 7.4 * e, 7.4 * e), (0, y + 1.2 + 6.2 * e, 0), ORO, "Metal", VERTICAL, "Cylinder"),
    ]
    centro = (0, y + 1.2 + 10.5 * e, 0)
    cuerpo = pieza("PezDorado", (1, 1, 1), centro, ORO, "Metal", giro)
    cuerpo["children"] = [{"name": "Forma", "className": "SpecialMesh",
                           "properties": {"MeshType": "Sphere", "Scale": [3.4 * e, 4.6 * e, 10 * e]}}]
    hijos.append(cuerpo)
    hijos.append(pieza("Cola", (0.5 * e, 5 * e, 3.6 * e), add(centro, aplicar(giro, (0, 0, 5.6 * e))), ORO, "Metal", mat(giro, rz(45))))
    brillo = pieza("Brillo", (1, 1, 1), centro, ORO, **INVISIBLE, CanCollide=False)
    brillo["children"] = [luz(26, 1, ORO)]
    hijos.append(brillo)
    hijos.append(cartel("Cartel", (0, y + 1.2 + 2.2 * e, -3.1 * e), I3, "ZONA DE ENTRENAMIENTO" if agua is None else "ESTANQUE SAGRADO", 4.4 * e, 0.9 * e))
    return grupo("Estatua", hijos)


def zona_entrenamiento():
    y = L["plateauHeight"]
    hijos = [grupo("Estanques", [estanque(i + 1) for i in range(SAGRADO)], "Folder")]
    antorchas = []
    for i in range(12):
        p = polar(15 + i * 30, L["plazaRadius"] - 2, 0)
        antorchas.append(antorcha(f"Antorcha{i + 1}", p[0], p[2], y))
    hijos.append(grupo("Antorchas", antorchas, "Folder"))
    return grupo("ZonaEntrenamiento", hijos)


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
def aparicion():
    a = L["spawnAngle"]
    d = direccion(a)
    return {
        "name": "Aparicion", "className": "SpawnLocation",
        "properties": {
            "Anchored": True, "Neutral": True, "Duration": 0, "Size": [12, 1, 12],
            # Mira hacia la laguna: su LookVector (-Z local) apunta al centro.
            "CFrame": cf(polar(a, L["spawnRadius"], L["plateauHeight"] + 0.3), base_con_z(d)),
            "Color": color(MADERA_CLARA), "Material": "WoodPlanks", "TopSurface": "Smooth", "BottomSurface": "Smooth",
        },
    }


def arco_entrada():
    a = L["spawnAngle"]
    r = base_con_z(direccion(a))
    base = polar(a, L["plazaRadius"] + 3, 0)
    hijos = []
    for lado in (-1, 1):
        p = add(base, aplicar(r, (6.5 * lado, 0, 0)))
        hijos.append(poste(f"Columna{lado}", p[0], p[2], L["plateauHeight"] + 13, L["plateauHeight"] - 1, 1.6))
    hijos.append(pieza("Viga", (16, 1.2, 1.4), add(base, (0, L["plateauHeight"] + 12.6, 0)), MADERA_OSCURA, "Wood", r))
    # El texto mira hacia afuera (+Z local = hacia la aparición).
    hijos.append(cartel("Cartel", add(base, (0, L["plateauHeight"] + 10.6, 0)), r, "LAGUNA DE LOS GIGANTES", 13, 2.6, "Back"))
    # Tableros del ranking global a los lados del camino (Leaderboards / RankingBoards).
    for lado, nombre, titulo in ((-1, "TableroPoder", "TOP PODER"), (1, "TableroKills", "TOP KILLS")):
        p = add(polar(a, L["plazaRadius"] + 9, 0), aplicar(r, (13 * lado, 0, 0)))
        y = L["plateauHeight"]
        for k in (-1, 1):
            q = add(p, aplicar(r, (4.6 * k, 0, 0)))
            hijos.append(poste(f"Poste{nombre}{k}", q[0], q[2], y + 11, y - 1, 0.8))
        hijos.append(pieza(nombre, (10, 8.5, 0.5), (p[0], y + 6, p[2]), MADERA_OSCURA, "Wood", r))
        hijos.append(cartel(f"Titulo{nombre}", (p[0], y + 11.2, p[2]), r, titulo, 9, 1.6, "Back"))
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
    return grupo(nombre, hijos)


def rocas(nombre, centro, cantidad, escala=1.0):
    hijos = []
    for i in range(cantidad):
        s = escala * rng.uniform(2, 5)
        p = (centro[0] + rng.uniform(-4, 4) * escala, altura_terreno(math.hypot(*centro)) + s * 0.15, centro[1] + rng.uniform(-4, 4) * escala)
        r = mat(ry(rng.uniform(0, 360)), mat(rx(rng.uniform(-14, 14)), rz(rng.uniform(-14, 14))))
        hijos.append(pieza(f"Roca{i}", (s * rng.uniform(1, 1.4), s * rng.uniform(0.6, 0.9), s), p, ROCA[i % 3], "Slate", r))
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
    rho = L["craterRimOuter"] + (RIM_Y - AGUA_Y) / (RIM_Y - L["seaFloorHeight"]) * (L["craterBaseRadius"] - L["craterRimOuter"])
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
        for i, (a, r) in enumerate(sitios(round(46 * E * E), 84 * E, 136 * E, 8))
    ], "Folder"))
    hijos.append(grupo("Arbustos", [
        arbusto(f"Arbusto{i}", polar(a, r, L["plateauHeight"])) for i, (a, r) in enumerate(sitios(round(34 * E * E), 84 * E, 120 * E, 7))
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
MADERA_NEGRA = (62, 48, 42)
HIERRO = (54, 56, 62)
FUEGO_AZUL = ((70, 150, 255), (170, 230, 255))
LUZ_AZUL = (110, 170, 255)
LUZ_ROJA = (255, 50, 40)
CRISTAL_MORADO = (170, 70, 255)

CRATER = (L["craterCenter"][0], 0, L["craterCenter"][1])
RIM_Y = L["craterRimHeight"]
DECK_ABISMO = L["craterDeckHeight"]


def altura_crater(rho):
    """Misma curva que IslandShape.craterHeight."""
    if rho < L["craterLakeRadius"]:
        return L["craterFloor"] + (rho / L["craterLakeRadius"]) ** 2 * 10
    if rho < L["craterCliffRadius"]:
        t = (rho - L["craterLakeRadius"]) / (L["craterCliffRadius"] - L["craterLakeRadius"])
        return L["craterFloor"] + 10 + (RIM_Y - L["craterFloor"] - 10) * t
    if rho < L["craterRimOuter"]:
        return RIM_Y
    t = (rho - L["craterRimOuter"]) / (L["craterBaseRadius"] - L["craterRimOuter"])
    return RIM_Y + (L["seaFloorHeight"] - RIM_Y) * t


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
    letrero = pieza("Letrero", (16, 3, 0.4), add(viga, (0, -2.6, 0)), BASALTO[2], "Basalt", r, **DECORADO)
    letrero["children"] = [{
        "name": "Texto", "className": "SurfaceGui",
        "properties": {"Face": "Back", "SizingMode": "PixelsPerStud", "PixelsPerStud": 40, "LightInfluence": 0},
        "children": [{"name": "Etiqueta", "className": "TextLabel", "properties": {
            "Size": {"UDim2": [[1, 0], [1, 0]]}, "BackgroundTransparency": 1, "Text": "CRÁTER DEL ABISMO", "TextScaled": True,
            "TextColor3": color((255, 70, 50)), "TextStrokeTransparency": 0, "TextStrokeColor3": color((20, 0, 0)),
            "FontFace": {"Font": {"family": "rbxasset://fonts/families/Creepster.json", "weight": "Regular", "style": "Normal"}},
        }}],
    }]
    hijos.append(letrero)
    for lado in (-1, 1):  # cadenas colgando de la viga
        for k in range(6):
            p = add(viga, aplicar(r, (lado * 4.5, -2 - k * 1.3, 0.8)))
            hijos.append(pieza(f"Eslabon{lado}_{k}", (0.35, 1.2, 0.7), p, HIERRO, "Metal", mat(r, ry(90 * (k % 2))), **DECORADO))
    return grupo("PuertaDelAbismo", hijos)


def muelle_abismo(indice, angulo):
    """Muelle de madera negra que entra al abismo, con un mirador en la punta."""
    rho0, rho1 = L["craterCliffRadius"] + 2, L["craterPierTipRadius"]
    largo = rho0 - rho1
    hijos = []
    # Local: +Z hacia el centro del cráter, origen sobre el anillo.
    z, i = 0, 0
    while z < largo - 0.01:
        hijos.append(pieza(f"Tablon{i}", (10, 0.5, 1.8), (0, DECK_ABISMO - 0.25, z + 1), variar(MADERA_NEGRA, 6), "WoodPlanks"))
        z, i = z + 2, i + 1
    plat = largo - 7
    hijos.append(pieza("Plataforma", (18, 0.6, 14), (0, DECK_ABISMO - 0.3, plat), variar(MADERA_NEGRA, 4), "WoodPlanks"))
    for k, zz in enumerate(range(8, int(largo) - 10, 12)):
        for lado in (-1, 1):
            hijos.append(poste(f"Poste{k}_{lado}", 5.3 * lado, zz, DECK_ABISMO + 0.6, L["craterFloor"], 1.1, HIERRO))
    for lado in (-1, 1):
        for esquina in (plat - 6.5, plat + 6.5):
            hijos.append(poste(f"Pata{lado}_{esquina:.0f}", 9 * lado, esquina, DECK_ABISMO + 0.6, L["craterFloor"], 1.3, HIERRO))
    # Paredes invisibles: nadie cae al abismo por accidente.
    hijos += [
        muro("MuroI", (-5.4, 0), (-5.4, plat - 7), DECK_ABISMO), muro("MuroD", (5.4, 0), (5.4, plat - 7), DECK_ABISMO),
        muro("MuroPI", (-9.3, plat - 7), (-9.3, plat + 7), DECK_ABISMO), muro("MuroPD", (9.3, plat - 7), (9.3, plat + 7), DECK_ABISMO),
        muro("MuroPunta", (-9.3, plat + 7), (9.3, plat + 7), DECK_ABISMO),
        muro("MuroAtrasI", (-9.3, plat - 7), (-5.4, plat - 7), DECK_ABISMO), muro("MuroAtrasD", (5.4, plat - 7), (9.3, plat - 7), DECK_ABISMO),
    ]
    for lado in (-1, 1):  # baranda baja de hierro
        hijos.append(pieza(f"Riel{lado}", (0.3, 0.3, plat - 7), (5.2 * lado, DECK_ABISMO + 2.2, (plat - 7) / 2), HIERRO, "Metal", **DECORADO))
    for lado in (-1, 1):
        hijos.append(antorcha(f"Antorcha{lado}", 8 * lado, plat + 6, DECK_ABISMO, FUEGO_AZUL, LUZ_AZUL))
    d = direccion(angulo + 180)  # del borde hacia el centro
    origen = polar_crater(angulo, rho0, 0)
    return mover(grupo(f"MuelleAbismo{indice}", hijos), base_con_z(d), origen)


def aguja(nombre, base, alto):
    """Aguja de basalto: bloques apilados que se afinan y se tuercen."""
    hijos, y, ancho = [], base[1], rng.uniform(4, 6.5)
    tramos = 3 if alto > 20 else 2
    for k in range(tramos):
        h = alto / tramos
        hijos.append(pieza(f"Tramo{k}", (ancho, h + 0.4, ancho * rng.uniform(0.7, 1)), (base[0] + rng.uniform(-0.6, 0.6), y + h / 2, base[2] + rng.uniform(-0.6, 0.6)),
                           BASALTO[k % 3], "Basalt", mat(ry(rng.uniform(0, 90)), rz(rng.uniform(-8, 8)))))
        y += h
        ancho *= 0.62
    return grupo(nombre, hijos)


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
    hijos.append(pieza("Pedestal", (tope - L["craterFloor"], 34, 34), (CRATER[0], (tope + L["craterFloor"]) / 2, CRATER[2]),
                       BASALTO[1], "Basalt", VERTICAL, "Cylinder"))
    for k in range(9):  # rocas alrededor del pedestal
        a, s = k * 40 + rng.uniform(-10, 10), rng.uniform(5, 9)
        p = polar_crater(a, rng.uniform(16, 21), tope - s * 0.4)
        hijos.append(pieza(f"RocaPedestal{k}", (s * 1.3, s, s), p, BASALTO[k % 3], "Basalt", mat(ry(rng.uniform(0, 360)), rx(rng.uniform(-15, 15)))))
    # Anclaje del gigante: invisible, mira hacia -Z (hacia el puente y la isla).
    hijos.append(pieza("GuaridaGigante", (2, 1, 2), (CRATER[0], tope, CRATER[2]), CORAL, **INVISIBLE, CanCollide=False))
    n = L["craterPierCount"]
    angulos_muelle = [22.5 + k * 360 / n for k in range(n)]
    hijos.append(grupo("MuellesDelAbismo", [muelle_abismo(k + 1, a) for k, a in enumerate(angulos_muelle)], "Folder"))
    hijos.append(puerta_abismo())
    llegada = L["bridgeAngle"] + 180

    def libre(a, margen):
        return all(abs((a - b + 180) % 360 - 180) > margen for b in angulos_muelle + [llegada])

    agujas, k = [], 0
    while len(agujas) < 30:
        a = rng.uniform(0, 360)
        if libre(a, 7):
            rho = rng.uniform(L["craterCliffRadius"] + 4, L["craterRimOuter"] - 2)
            agujas.append(aguja(f"Aguja{k}", polar_crater(a, rho, RIM_Y - 1), rng.uniform(12, 42)))
            k += 1
    hijos.append(grupo("Agujas", agujas, "Folder"))
    hijos.append(esqueleto("Esqueleto1", llegada + 55, L["craterCliffRadius"] + 10, 26))
    hijos.append(esqueleto("Esqueleto2", llegada - 120, L["craterCliffRadius"] + 9, 20))
    hijos.append(grupo("Cristales", [cristales(f"Cristales{k}", llegada + d, L["craterCliffRadius"] + 12) for k, d in enumerate((30, 95, 160, 205, 250, 320))], "Folder"))
    # Pared invisible al borde del acantilado, con hueco solo en cada muelle.
    muros, m = [], 72
    rho = L["craterCliffRadius"] + 0.5
    for k in range(m):
        a0, a1 = k * 360 / m, (k + 1) * 360 / m
        medio = (a0 + a1) / 2
        if any(abs((medio - b + 180) % 360 - 180) <= 4 for b in angulos_muelle):
            continue
        p0, p1 = polar_crater(a0, rho, 0), polar_crater(a1, rho, 0)
        muros.append(muro(f"Muro{k}", (p0[0], p0[2]), (p1[0], p1[2]), RIM_Y, 8))
    hijos.append(grupo("Borde", muros, "Folder"))
    # Línea coral brillante en el borde: se alimenta desde cualquier punto de la orilla.
    orilla, rho = [], L["craterCliffRadius"] + 2.6
    for k in range(m):
        a0, a1 = k * 360 / m, (k + 1) * 360 / m
        p0, p1 = polar_crater(a0, rho, 0), polar_crater(a1, rho, 0)
        dx, dz = p1[0] - p0[0], p1[2] - p0[2]
        centro = ((p0[0] + p1[0]) / 2, RIM_Y + 0.05, (p0[2] + p1[2]) / 2)
        orilla.append(pieza(f"Brillo{k}", (3.6, 0.1, math.hypot(dx, dz) + 0.3), centro, CORAL, "Neon",
                            ry(math.degrees(math.atan2(dx, dz))), Transparency=0.25, **FANTASMA))
    hijos.append(grupo("OrillaAlimentar", orilla, "Folder"))
    return grupo("Crater", hijos)


LAVA = (255, 120, 40)
OBSIDIANA = (26, 22, 30)


def brasero(nombre, x, z, y):
    """Brasero de basalto con fuego de lava: rodean la guarida."""
    arriba = y + 3.2
    fuego = pieza("Llama", (0.6, 0.6, 0.6), (x, arriba + 0.8, z), LAVA, **INVISIBLE, CanCollide=False)
    fuego["children"] = [
        {"name": "Fuego", "className": "Fire",
         "properties": {"Size": 4, "Heat": 8, "Color": color((255, 140, 40)), "SecondaryColor": color((255, 60, 20))}},
        luz(9, 0.7, LAVA),  # suave: de noche ocho braseros teñían todo de rojo
    ]
    return grupo(nombre, [
        pieza("Pilar", (1.8, 2.8, 1.8), (x, y + 1.4, z), BASALTO[1], "Basalt"),
        pieza("Cuenco", (1, 3.4, 3.4), (x, arriba, z), BASALTO[0], "Basalt", VERTICAL, "Cylinder", **DECORADO),
        pieza("Brasas", (0.2, 2.8, 2.8), (x, arriba + 0.5, z), LAVA, "Neon", VERTICAL, "Cylinder", **FANTASMA),
        fuego,
    ])


def guarida_descanso():
    """Santuario que emerge en el centro del lago durante el descanso: un círculo grande de
    basalto con vetas de lava, piso de obsidiana con un anillo de losas y una grieta de lava,
    muro bajo de basalto con remate de oro (no te caes), braseros y, en el centro, un altar
    con el cristal del poder flotando. No tiene rampas: se llega con el botón IR A LA GUARIDA.
    Vive en ServerStorage; RestArena la clona al derrotar al monstruo. Solo en ella se gana
    poder en el descanso (WorldZones.isInRestArena)."""
    R, top = L["restArenaRadius"], L["restArenaTop"]
    cx, cz = CRATER[0], CRATER[2]
    hijos = [
        pieza("Base", (8, R * 2, R * 2), (cx, top - 4.2, cz), BASALTO[0], "Basalt", VERTICAL, "Cylinder"),
        # Aro de oro un poco más abajo que el piso: solo asoma en el borde.
        pieza("Aro", (0.8, R * 2 + 0.6, R * 2 + 0.6), (cx, top - 0.5, cz), ORO, "Metal", VERTICAL, "Cylinder"),
        pieza("Piso", (0.4, R * 2 - 2.4, R * 2 - 2.4), (cx, top - 0.1, cz), OBSIDIANA, "SmoothPlastic", VERTICAL, "Cylinder",
              Reflectance=0.12),
    ]
    # Anillo de losas y grieta de lava en el piso.
    hijos += anillo_tallado("Losa", cx, cz, R * 0.6, 32, R * 0.4, 0.2, top + 0.18, (BASALTO[1], (70, 58, 52)), "Slate")
    hijos += anillo_tallado("Grieta", cx, cz, R - 4.2, 40, 0.5, 0.1, top + 0.16, LAVA, "Neon", Transparency=0.35, **FANTASMA)
    # Muro bajo alrededor, con remate de oro (más la pared invisible alta, abajo).
    hijos += anillo_tallado("Parapeto", cx, cz, R - 0.9, 48, 1.6, 2.6, top + 2.7, (BASALTO[1], BASALTO[0]), "Basalt")
    hijos += anillo_tallado("Remate", cx, cz, R - 0.9, 48, 2, 0.35, top + 3, ORO, "Metal", **DECORADO)
    # Vetas de lava por el costado de la base.
    for k in range(24):
        a = k * 15 + rng.uniform(-4, 4)
        alto = rng.uniform(3, 6.5)
        hijos.append(pieza(f"Veta{k}", (0.3, alto, 0.5), polar_crater(a, R + 0.05, top - 0.6 - alto / 2), LAVA, "Neon",
                           mat(ry(-a), rx(rng.uniform(-12, 12))), Transparency=0.2, **FANTASMA))
    # Altar central con el cristal del poder flotando y sus órbitas.
    hijos.append(pieza("Altar", (1.4, 18, 18), (cx, top + 0.8, cz), BASALTO[2], "Basalt", VERTICAL, "Cylinder"))
    # Banda azul alrededor del altar (no encima: de lejos se veía como un disco blanco).
    hijos.append(pieza("AltarBrillo", (0.35, 18.4, 18.4), (cx, top + 0.8, cz), AZUL_PODER, "Neon", VERTICAL, "Cylinder", **FANTASMA))
    cristal = pieza("CristalPoder", (3.6, 3.6, 3.6), (cx, top + 9, cz), AZUL_PODER, "Neon", mat(rx(45), rz(35)), **FANTASMA)
    cristal["children"] = [luz(20, 1.2, AZUL_PODER)]
    hijos.append(cristal)
    for k in range(4):
        p = polar_crater(k * 90 + 45, 5.5, top + 9)
        hijos.append(pieza(f"Orbita{k}", (1, 1, 1), p, AZUL_PODER, "Neon", mat(rx(45), rz(35)), **FANTASMA))
    for k in range(8):  # runas alrededor del altar
        p = polar_crater(k * 45, 13, top + 0.14)
        hijos.append(pieza(f"Runa{k}", (1.6, 0.12, 3.4), p, AZUL_PODER, "Neon", ry(-k * 45), **DECORADO, CanCollide=False))
    for k in range(8):  # braseros junto al muro
        p = polar_crater(k * 45 + 22.5, R - 5, 0)
        hijos.append(brasero(f"Brasero{k + 1}", p[0], p[2], top + 0.1))
    # Pared invisible alta al borde, sin huecos: nadie se cae al lago.
    muros, m = [], 48
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
