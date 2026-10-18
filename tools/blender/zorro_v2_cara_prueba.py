r"""
Prueba de la cara del Zorro de agua v2, cualquier etapa: posa los párpados y las puntas de las orejas con
los mismos ángulos que src/shared/Zorro/Cara (Rig.turn: cabeceo, giro y alabeo en los ejes del cuerpo) y
mide cuánto del ojo se ve. Arma las piezas con zorro_v2_poses.py (hasta su parte principal) y no guarda
el .blend.

    visible   parte del ojo izquierdo que se ve desde tres direcciones (de frente, de frente desde
              arriba y de tres cuartos), tirando rayos desde la cara del ojo hacia la cámara: un rayo
              que choca con el párpado (o con la cabeza) es ojo tapado
    ceja      cuánto sube (+) o baja (-) cada punta del párpado izquierdo (adentro y afuera, celdas)
              respecto del reposo, para ver hacia dónde se inclina la ceja del enojo
    choques   las piezas que el párpado o la punta atraviesan más que en reposo (revisar())
    barrido_cierre  lo visible y los choques del párpado cerrado con otros ángulos de cierre

Los ángulos son los de Cara: párpado cerrado = cabeceo -LID_CLOSED * lid (LID_CLOSED por etapa); ceja =
alabeo +brow * BROW * (1 - lid) en el izquierdo y el opuesto en el derecho (BROW = 0.45); punta =
cabeceo -TIP * tip (TIP = 0.6). Los casos de CASOS salen de la tabla de Cara/Gestos.
Renderiza cada caso en renders/zorro_v2_e<n>/cara/ y guarda cara.json.

Uso (desde la raíz del repo; sin --etapa, la 3):
    blender -b --factory-startup --python tools/blender/zorro_v2_cara_prueba.py -- --etapa 3
"""
import bpy, json, math, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
if "--etapa" not in sys.argv:
    sys.argv += (["--"] if "--" not in sys.argv else []) + ["--etapa", "3"]
_src = open(os.path.join(HERE, "zorro_v2_poses.py"), encoding="utf-8").read()
exec(_src[:_src.index("# === PRINCIPAL")], globals())  # piezas, HUESOS, posar(), revisar(), foto()
from mathutils.bvhtree import BVHTree

LID_CLOSED = {1: 1.4, 2: 1.4, 3: 1.65, 4: 1.4}[ETAPA]  # Cara: LID_CLOSED[etapa]
BROW, TIP = 0.45, 0.6
# (párpado 0..1, ceja, punta): la calma, un parpadeo a medias, los gestos y cerrado.
CASOS = {
    "abierto": (0.0, 0.0, 0.0),
    "parpadeo_medio": (0.5, 0.0, 0.0),
    "feliz": (0.3, -0.1, 0.15),
    "enojo": (0.25, 0.3, -0.45),
    "sueno": (0.55, -0.05, 0.4),
    "asco": (0.4, 0.15, -0.2),
    "cerrado": (1.0, 0.0, 0.0),
}
DIRECCIONES = {  # hacia la cámara, desde el ojo izquierdo (+x es su izquierda, -y el frente)
    "frente": V((0, -1, 0)),
    "frente_alto": V((0, -math.cos(G(25)), math.sin(G(25)))),
    "tres_cuartos": V((math.sin(G(35)), -math.cos(G(35)), 0)),
}


def entrada(lid, brow, tip):
    ceja = brow * BROW * (1 - lid)
    huesos = {"ParpadoIzq": (-LID_CLOSED * lid, 0, ceja), "ParpadoDer": (-LID_CLOSED * lid, 0, -ceja)}
    for l in ("Izq", "Der"):
        huesos[f"OrejaPunta{l}"] = (-TIP * tip, 0, 0)
    return {"huesos": huesos}


def muestras_ojo():
    """Puntos sobre las caras del ojo izquierdo (material ojo de la Cabeza), con su normal."""
    o = ob["Cabeza"]
    mw = o.matrix_world
    nombre = PREFIJO + "ojo"
    idx = [i for i, m in enumerate(o.data.materials) if m and m.name == nombre]
    pts = []
    for q in o.data.polygons:
        if q.material_index not in idx or (mw @ q.center).x <= 0:
            continue
        vs = [mw @ o.data.vertices[i].co for i in q.vertices]
        n = (mw.to_3x3() @ q.normal).normalized()
        c = sum(vs, V((0, 0, 0))) / len(vs)
        for v in vs:
            for k in (0.15, 0.5, 0.85):
                pts.append((c.lerp(v, k), n))
        pts.append((c, n))
    return pts


def visible(pts, d):
    """Parte de los puntos del ojo que miran a `d` y que se ven (el rayo no choca con nada)."""
    arboles = [BVHTree.FromPolygons([o.matrix_world @ v.co for v in o.data.vertices],
                                    [q.vertices[:] for q in o.data.polygons])
               for o in piezas()]
    vistos = total = 0
    for p, n in pts:
        if n.dot(d) <= 0.1:
            continue
        total += 1
        origen = p + n * (0.02 * C)
        if not any(a.ray_cast(origen, d, 50 * C)[0] is not None for a in arboles):
            vistos += 1
    return round(vistos / total, 3) if total else None


def ceja():
    """Alto (celdas) de la punta de adentro y la de afuera del párpado izquierdo."""
    o = ob["ParpadoIzq"]
    vs = [o.matrix_world @ v.co for v in o.data.vertices]
    xs = sorted(v.x for v in vs)
    adentro = [v.z for v in vs if v.x <= xs[0] + 0.3 * C]
    afuera = [v.z for v in vs if v.x >= xs[-1] - 0.3 * C]
    return sum(adentro) / len(adentro) / C, sum(afuera) / len(afuera) / C


armar()
posar({})
reposo = medir()
salida = os.path.join(RENDERS, "cara")
os.makedirs(salida, exist_ok=True)
pts = muestras_ojo()
adentro0, afuera0 = ceja()
datos = {"etapa": ETAPA, "muestras_ojo": len(pts), "casos": {}}
sc, cam, sol = estudio(alto_bu())
sc.cycles.samples = 16
for nombre, (lid, brow, tip) in CASOS.items():
    posar(entrada(lid, brow, tip))
    adentro, afuera = ceja()
    atraviesa, juntas, sueltas = revisar(reposo)
    datos["casos"][nombre] = {
        "visible": {k: visible(pts, d) for k, d in DIRECCIONES.items()},
        "ceja_celdas": {"adentro": round(adentro - adentro0, 2), "afuera": round(afuera - afuera0, 2)},
        "choques": [c for c in atraviesa + juntas if any(p.startswith(("Parpado", "OrejaPunta")) for p in c["piezas"])],
    }
    foto(nombre, sc, cam, sol, 15, 10, salida, ["Cabeza", "Mandibula", "OrejaIzq", "OrejaDer", "OrejaPuntaIzq",
                                                "OrejaPuntaDer", "ParpadoIzq", "ParpadoDer"])
# Barrido del cierre: qué ángulo tapa más el ojo en esta etapa (y si choca con algo).
datos["barrido_cierre"] = {}
for ang in (1.3, 1.4, 1.5, math.pi / 2, 1.65, 1.75):
    posar({"huesos": {"ParpadoIzq": (-ang, 0, 0), "ParpadoDer": (-ang, 0, 0)}})
    atraviesa, juntas, _ = revisar(reposo)
    datos["barrido_cierre"][f"{ang:.2f}"] = {
        "visible": {k: visible(pts, d) for k, d in DIRECCIONES.items()},
        "choques": len([c for c in atraviesa + juntas if any(p.startswith("Parpado") for p in c["piezas"])]),
    }
with open(os.path.join(salida, "cara.json"), "w", encoding="utf-8", newline="\n") as fh:
    json.dump(datos, fh, indent=2, ensure_ascii=False)
print("CARA", json.dumps(datos, ensure_ascii=False))
