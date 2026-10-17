r"""
Poses extremas del Minotauro v2, cualquier etapa (docs/estilo_modelos.md, "Poses extremas") y el pico de
cada truco del juego (Minotauro/Trucos.luau y Pose.feeding, con su curva en 1 y sin el reposo
encima). Posa las piezas rígidas con la cadena de huesos del contrato y los mismos ejes que
Minotauro/Pose.luau (Pose.apply) y Minotauro/Rig.luau (Rig.turn), y revisa:
    atraviesa  dos piezas sin articulación entre ellas que se meten una en otra más de
               PENETRA celdas más que en reposo
    junta      una pieza y su padre que se solapan más de JUNTA celdas más que en reposo
               (en bloques rígidos la junta siempre se solapa un poco; se mira en el render)
    hueco      una pieza que se separa de su padre más de HUECO celdas
FaldonFrente se levanta lo justo para que las piernas no lo atraviesen (como en
minotauro_v2_pisoton.py). Renderiza cada pose en renders/minotauro_v2_e<n>/poses/ y guarda
poses.json. No guarda el .blend. Las articulaciones salen de ARTICULACIONES de
minotauro_v2_e<n>_geometria.py; los umbrales van en celdas del módulo de la etapa.

Uso (desde la raíz del repo; sin --etapa, la 1):
    blender -b --factory-startup --python tools/blender/minotauro_v2_poses.py -- --etapa 2
"""
import bpy, json, math, os
from mathutils import Matrix, Vector as V
from mathutils.bvhtree import BVHTree

HERE = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.normpath(os.path.join(HERE, "..", ".."))
_src = open(os.path.join(HERE, "minotauro_v2_bloques.py"), encoding="utf-8").read()
exec(_src[:_src.index("# === PRINCIPAL")], globals())  # armar(), estudio(), ETAPA y su geometría
SALIDA = os.path.join(RAIZ, "renders", f"minotauro_v2_e{ETAPA}", "poses")
C = CELDA
PENETRA = 0.3  # celdas
JUNTA = 1.0
HUECO = 0.2
G = math.radians

# Hueso -> (padre, articulación en BU), con los dos lados ya armados.
HUESOS = {}
for _n, _p, (_x, _y, _z) in ARTICULACIONES:
    for _s, _l in ((1, "Izq"), (-1, "Der")) if "{l}" in _n else ((1, ""),):
        HUESOS[_n.format(l=_l)] = ((_p or "").format(l=_l) or None, V((_x * _s, _y, _z)) * C)
PIERNAS = [p + l for p in ("Muslo", "Pierna", "Pie") for l in ("Izq", "Der")]
FALDON = ["FaldonFrente", "FaldonIzq", "FaldonDer"]

POSES = {  # nombre -> (pose con las claves de Pose.luau, ángulo de la cámara)
    # Guía. Cuello y torso no tienen ángulo en la guía: 45° y 0.4 rad (casi el doble del rugido).
    "brazos_arriba_150": ({"outL": G(150), "outR": G(150)}, 0),
    "brazos_adelante_cruzados": ({"armL": G(90), "armR": G(90), "outL": -G(25), "outR": -G(25)}, 35),
    "codo_140": ({"elbowL": G(140), "elbowR": G(140)}, 90),
    "rodilla_120": ({"legL": G(60), "legR": G(60), "kneeL": G(120), "kneeR": G(120)}, 90),
    "pierna_90": ({"legR": G(90), "kneeR": G(90)}, -90),
    "cuello_arriba_45": ({"lookPitch": G(45)}, 90),
    "cuello_abajo_45": ({"lookPitch": -G(45)}, 90),
    "cuello_izq_60": ({"lookYaw": G(60)}, 0),
    "cuello_der_60": ({"lookYaw": -G(60)}, 0),
    "mandibula_max": ({"jaw": 1.2}, 90),
    "cola_s_arriba": ({"tailUp": 0.6, "tail1": 0.5, "tail2": -0.6, "tail3": 0.6}, 150),
    "torso_atras": ({"lean": 0.4}, 90),
    "torso_adelante": ({"lean": -0.4}, 90),
    # Picos de los trucos (el pisotón está en minotauro_v2_pisoton.py).
    "truco_musculo": ({"outL": 1.25, "outR": 1.25, "elbowOutL": 1.62, "elbowOutR": 1.62,
                       "lean": 0.08, "lookYaw": 0.5, "tilt": 0.15, "jaw": 0.25}, 0),
    "truco_rugido": ({"lean": 0.22, "lookPitch": 0.49, "jaw": 1.1, "outL": 0.9, "outR": 0.9,
                      "armL": 0.4, "armR": 0.4, "elbowL": 0.5, "elbowR": 0.5, "earL": -0.6,
                      "earR": -0.6, "tailUp": 0.6}, 35),
    "truco_rascarse": ({"armR": 1.6, "outR": 0.7, "elbowR": 1.85, "tilt": -0.3,
                        "lookPitch": -0.1, "earL": 0.3, "jaw": 0.15}, -35),
    "truco_salto_agachado": ({"legL": 0.5, "legR": 0.5, "kneeL": 0.8, "kneeR": 0.8, "lean": -0.2}, 90),
    "truco_salto_aire": ({"legL": 0.3, "legR": 0.3, "kneeL": 0.5, "kneeR": 0.5, "lean": 0.1,
                          "outL": 1.1, "outR": 1.1, "armL": 0.5, "armR": 0.5, "jaw": 0.4,
                          "earL": 0.5, "earR": 0.5}, 35),
    "truco_baile": ({"sway": 0.16, "tilt": 0.25, "armL": 0.9, "armR": -0.9, "outL": 0.35,
                     "outR": 0.35, "elbowL": 0.6, "elbowR": 0.6, "legL": 0.25, "kneeL": 0.4,
                     "jaw": 0.3, "tail1": 0.5, "tail2": 0.6}, 35),
    "comer": ({"lean": -0.18, "lookPitch": -0.12, "armL": 0.6, "armR": 0.6, "outL": 0.15,
               "outR": 0.15, "elbowL": 0.7, "elbowR": 0.7, "jaw": 0.6, "earL": 0.35, "earR": 0.35,
               "tailUp": 0.3}, 35),
}
ob = bpy.data.objects


def locales(p):
    """Pose.apply: hueso -> (cabeceo, giro, alabeo) en radianes."""
    v = lambda k: p.get(k, 0.0)
    lean, sway = v("lean"), v("sway")
    r = {
        "Cadera": (0, 0, sway),
        "Columna": (lean * 0.5, 0, -sway * 0.5),
        "Pecho": (lean * 0.5, v("lookYaw") * 0.2, 0),
        "Cuello": (v("lookPitch") * 0.4, v("lookYaw") * 0.35, v("tilt") * 0.3),
        "Cabeza": (v("lookPitch") * 0.6, v("lookYaw") * 0.45, v("tilt") * 0.7),
        "Mandibula": (-0.5 * min(max(v("jaw"), 0), 1.2), 0, 0),
        "Cola1": (-v("tailUp"), v("tail1"), 0),
        "Cola2": (-v("tailUp") * 0.5, v("tail2"), 0),
        "Cola3": (0, v("tail3"), 0),
    }
    for s, l, afuera in (("L", "Izq", 1), ("R", "Der", -1)):  # afuera = -(rig.side)
        knee = v("knee" + s)
        r["Oreja" + l] = (0, 0, v("ear" + s) * afuera)
        r["Brazo" + l] = (v("arm" + s), 0, v("out" + s) * afuera)
        r["Antebrazo" + l] = (v("elbow" + s), 0, v("elbowOut" + s) * afuera)
        r["Mano" + l] = (v("elbow" + s) * 0.2, 0, 0)
        r["Muslo" + l] = (v("leg" + s), 0, 0)
        r["Pierna" + l] = (-knee, 0, 0)
        r["Pie" + l] = (knee * 0.5 - v("leg" + s) * 0.4, 0, 0)
    return r


def giros(p, faldon=0.0):
    """Rig.turn en ejes del mundo: cabeceo por la derecha del cuerpo (-x), giro por arriba (z)
    y alabeo por adelante (-y), en ese orden. Hueso -> matriz de giro (sin trasladar)."""
    rot = locales(p)
    r = {}
    for nombre in HUESOS:
        a, g, b = rot.get(nombre, (0, 0, 0))
        r[nombre] = Matrix.Rotation(-a, 4, "X") @ Matrix.Rotation(g, 4, "Z") @ Matrix.Rotation(-b, 4, "Y")
    r["FaldonFrente"] = Matrix.Rotation(G(-faldon), 4, "X")
    return r


def matrices(p, faldon=0.0):
    """Matriz del mundo de cada pieza, heredando el giro del padre."""
    r, m = giros(p, faldon), {}
    for nombre, (padre, piv) in HUESOS.items():
        base = m[padre] if padre else Matrix.Identity(4)
        m[nombre] = base @ Matrix.Translation(piv) @ r[nombre] @ Matrix.Translation(-piv)
    return m


def posar(p, faldon=0.0):
    for nombre, m in matrices(p, faldon).items():
        ob[nombre].matrix_world = m


def arbol(o):
    mw = o.matrix_world
    return BVHTree.FromPolygons([mw @ v.co for v in o.data.vertices], [q.vertices[:] for q in o.data.polygons])


def muestras(o):
    mw = o.matrix_world
    return [mw @ v.co for v in o.data.vertices] + [mw @ q.center for q in o.data.polygons]


def faldon_minimo(p):
    for f in range(0, 181):
        posar(p, f)
        if not any(arbol(ob[a]).overlap(arbol(ob[b])) for a in PIERNAS for b in FALDON):
            return f
    return None


def medir():
    """Profundidad (celdas) de cada par de piezas que se cruzan y separación de cada articulación."""
    t = {n: arbol(ob[n]) for n in HUESOS}
    s = {n: muestras(ob[n]) for n in HUESOS}
    nombres = list(HUESOS)
    cruces = {}
    for i, a in enumerate(nombres):
        for b in nombres[i + 1:]:
            if t[a].overlap(t[b]):
                d = 0.0
                for x, arb in ((a, t[b]), (b, t[a])):
                    for q in s[x]:
                        loc, nor, _, dist = arb.find_nearest(q)
                        if loc is not None and (q - loc).dot(nor) < 0:
                            d = max(d, dist)
                cruces[(a, b)] = d / C
    huecos = {}
    for hijo, (padre, _) in HUESOS.items():
        if padre and not t[hijo].overlap(t[padre]):
            huecos[hijo] = min(arb.find_nearest(q)[3] for x, arb in ((hijo, t[padre]), (padre, t[hijo]))
                               for q in s[x]) / C
        else:
            huecos[hijo] = 0.0
    return cruces, huecos


def revisar(reposo):
    cr0, hu0 = reposo
    cruces, huecos = medir()
    atraviesa, juntas = [], []
    for (a, b), d in sorted(cruces.items()):
        conectadas = HUESOS[a][0] == b or HUESOS[b][0] == a
        if d - cr0.get((a, b), 0.0) > (JUNTA if conectadas else PENETRA):
            (juntas if conectadas else atraviesa).append({"piezas": [a, b], "celdas": round(d, 2)})
    sueltas = [{"pieza": h, "padre": HUESOS[h][0], "celdas": round(d, 2)} for h, d in huecos.items()
               if d - hu0[h] > HUECO]
    return atraviesa, juntas, sueltas


def render(nombre, sc, cam, sol, angulo):
    k = ALTO / 3.1  # las medidas de la E1, en proporción al alto
    centro = V((0, 0, 1.55 * k))
    a = G(angulo)
    cam.location = centro + V((math.sin(a) * 10, -math.cos(a) * 10, 2.5)) * k
    cam.rotation_euler = (centro - cam.location).to_track_quat("-Z", "Y").to_euler()
    sol.rotation_euler = (G(50), 0, a + G(-35))
    sc.render.filepath = os.path.join(SALIDA, nombre + ".png")
    bpy.ops.render.render(write_still=True)


armar()
os.makedirs(SALIDA, exist_ok=True)
posar({})
ALTO = alto_bu()  # en reposo
reposo = medir()
datos = {"umbral_celdas": {"atraviesa": PENETRA, "junta": JUNTA, "hueco": HUECO},
         "reposo": {"cruces": {f"{a}/{b}": round(d, 2) for (a, b), d in sorted(reposo[0].items())},
                    "huecos": {h: round(d, 2) for h, d in reposo[1].items() if d > 0}},
         "poses": {}}
sc, cam, sol = estudio(ALTO)
sc.cycles.samples = 24
for nombre, (pose, angulo) in POSES.items():
    f = faldon_minimo(pose)
    posar(pose, f or 0)
    atraviesa, juntas, sueltas = revisar(reposo)
    datos["poses"][nombre] = {"faldon_levantado": f, "atraviesa": atraviesa, "junta": juntas,
                              "hueco": sueltas}
    render(nombre, sc, cam, sol, angulo)
with open(os.path.join(SALIDA, "poses.json"), "w", encoding="utf-8") as fh:
    json.dump(datos, fh, indent=2, ensure_ascii=False)
print("POSES", json.dumps({n: [len(d[k]) for k in ("atraviesa", "junta", "hueco")]
                           for n, d in datos["poses"].items()}))
