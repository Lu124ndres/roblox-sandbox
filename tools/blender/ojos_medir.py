r"""
Mide dónde están los ojos de los gigantes v2 y escribe src/shared/UIConfig/GiantEyesData.luau, los
datos de las pupilas que siguen al jugador (las mueve src/client/Giant/GiantEyes.luau).

Por cada modelo (<Modelo>E<n> en el juego) abre assets/blender/<c>_v2/e<n>_rig.blend (si no hay
rig, e<n>_bloques.blend) y mide la malla tal como se exporta al FBX: pose de bind, ejes de Blender
(x = izquierda del personaje, -y = frente, z arriba) y las BU de ese archivo (las del rig ya vienen
escaladas a studs; el código del juego solo usa proporciones de la caja, así que da igual).
  - Ojo: los polígonos de sus colores (más la pupila pintada, si lleva tapa) dentro de la caja del
    hueso de la cabeza, de cada lado y mirando hacia afuera. Los brillos no cuentan como ojo.
  - Máscara: lo que se ve de frente a esa cara. Un rayo hacia afuera desde la cara del ojo; si
    choca con otra pieza (un ceño, una ceja), ese punto queda afuera.
  - Rectángulo: el más grande dentro de la máscara, puntuado por área × raíz del aspecto (prefiere
    los casi cuadrados; empate: el más ancho). Ahí se mueve la pupila. Con tapa, va delante de la
    cara más adelantada (la de la pupila pintada).
El color de cada cara sale de su UV (la paleta del rig: un cuadro por color en el orden de
COLORES) y se comprueba contra la textura. La caja es la de toda la malla y, con rig, se compara
con la del FBX importado (ojos_medir_salida.py). Deja un render por modelo en renders/ojos_medir/.

Uso (desde la raíz del repo; --criatura limita los renders, la medida es siempre de todas):
    blender -b --factory-startup --python tools/blender/ojos_medir.py -- [--criatura zorro]
"""
import bpy, math, os, sys
import numpy as np
from mathutils import Vector as V
from mathutils.bvhtree import BVHTree

HERE = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.normpath(os.path.join(HERE, "..", ".."))
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SOLO = ARGS[ARGS.index("--criatura") + 1] if "--criatura" in ARGS else None
HUESO = "Cabeza"
FRENTE, COSTADO = (0, -1, 0), (1, 0, 0)  # hacia dónde mira el ojo izquierdo (+x)
# criatura: (modelo, normal del ojo izquierdo o None = la de su cara más grande,
#            {etapa: (colores del ojo, pupila pintada)}, requiresBone). Con pupila pintada hay tapa
#            del primer color del ojo.
CRIATURAS = {
    "minotauro": ("Minotauro", FRENTE, {1: (["negro"], []), 2: (["ambar"], ["negro"]),
                                        3: (["ambar"], ["negro"]), 4: (["lava"], [])}, None),
    "dragon": ("DragonMarino", COSTADO, {1: (["ojo"], ["pupila"]), 2: (["ojo"], []), 3: (["ojo"], []),
                                         4: (["ojo", "ojo_claro"], [])}, None),
    "zorro": ("ZorroDeAgua", FRENTE, {n: (["ojo"], []) for n in range(1, 5)}, None),
    "orca": ("Orca", None, {n: (["cuenca"], []) for n in range(1, 5)}, "OjoIzqMira"),
}
exec(open(os.path.join(HERE, "ojos_medir_formas.py"), encoding="utf-8").read(), globals())
exec(open(os.path.join(HERE, "ojos_medir_salida.py"), encoding="utf-8").read(), globals())
exec(open(os.path.join(HERE, "ojos_medir_vista.py"), encoding="utf-8").read(), globals())


def geometria(c, n):
    """COLORES, CELDA y ARTICULACIONES de <c>_v2_e<n>_geometria.py (sin armar nada)."""
    ruta = os.path.join(HERE, f"{c}_v2_e{n}_geometria.py")
    if not os.path.exists(ruta):
        return None
    ns = {"HERE": HERE, "os": os, "math": math, "bpy": bpy, "__name__": "geometria"}
    exec(open(ruta, encoding="utf-8").read(), ns)
    return ns


def malla_rig(geo, png):
    """Polígonos de la malla del rig: el color por la UV (y la textura) y el hueso por el grupo."""
    o = next(o for o in bpy.data.objects if o.type == "MESH" and o.find_armature())
    me, mw = o.data, o.matrix_world
    nombres = list(geo["COLORES"])
    lado = math.ceil(math.sqrt(len(nombres)))
    img = bpy.data.images.load(png, check_existing=True)
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    grupo = {g.index: g.name for g in o.vertex_groups}
    hueso = [grupo[v.groups[0].group] if v.groups else None for v in me.vertices]
    uv, pols, peor = me.uv_layers.active.data, [], 0.0
    for p in me.polygons:
        u, v = uv[p.loop_indices[0]].uv
        color = nombres[int(v * lado) * lado + int(u * lado)]
        real = px[int(v * h), int(u * w), :3]
        peor = max(peor, max(abs(srgb(a) - b) for a, b in zip(geo["COLORES"][color], real)))
        pols.append((list(p.vertices), color, {hueso[k] for k in p.vertices}))
    if peor > 3 / 255:
        raise RuntimeError(f"la paleta de COLORES no coincide con {png} (error {peor:.3f})")
    arm = o.find_armature()
    piv = next(V(a[2]) for a in geo["ARTICULACIONES"] if a[0] == HUESO)
    celda = (arm.matrix_world @ arm.data.bones[HUESO].head_local).length / piv.length
    return [mw @ v.co for v in me.vertices], pols, celda


def malla_bloques(geo):
    """Polígonos de las piezas sueltas: el color por el material y el hueso por obj["hueso"]."""
    P, pols = [], []
    for o in (o for o in bpy.data.objects if o.type == "MESH" and "hueso" in o):
        base = len(P)
        P += [o.matrix_world @ v.co for v in o.data.vertices]
        for p in o.data.polygons:
            color = o.data.materials[p.material_index].name.split("_", 1)[1]
            pols.append(([base + k for k in p.vertices], color, {o["hueso"]}))
    return P, pols, geo["CELDA"]


def medir_ojo(P, pols, bvh, colores, n_izq, lado, celda, caja):
    """Un ojo (lado = 1 el izquierdo, -1 el derecho): centro, normal, up, tamaño y lo de revisar."""
    lo, hi = caja
    cen = lambda p: sum((P[k] for k in p[0]), V()) / len(p[0])
    cand = [p for p in pols if p[1] in colores and lado * cen(p).x > 0
            and all(lo[i] <= cen(p)[i] <= hi[i] for i in range(3))]
    cand = pieza(P, cand, celda)  # la pieza de esos colores más grande (no una grieta de lava)
    if not cand:
        return None
    normal = lambda p: (P[p[0][1]] - P[p[0][0]]).cross(P[p[0][-1]] - P[p[0][0]]).normalized()
    # Sin normal fija (la cuenca de la orca): la de su cara más grande que mire afuera o adelante.
    caras = [p for p in cand if abs(normal(p).z) < 0.7 and normal(p).dot(V((lado, -1, 0))) > 0]
    n = V((n_izq[0] * lado, n_izq[1], n_izq[2])) if n_izq else normal(max(caras or cand, key=lambda p: area(P, p)))
    cand = [p for p in cand if normal(p).dot(n) > 0.3]
    up = (V((0, 0, 1)) - n * n.z).normalized()
    der = up.cross(n) * lado  # el derecho, espejado: la grilla y los empates salen simétricos
    planos = [([(P[k].dot(der), P[k].dot(up)) for k in p[0]], P[p[0][0]], normal(p), p) for p in cand]
    us = [q[0] for pl in planos for q in pl[0]]
    vs = [q[1] for pl in planos for q in pl[0]]
    paso = celda / 8
    nu, nv = round((max(us) - min(us)) / paso), round((max(vs) - min(vs)) / paso)
    mask = np.zeros((nu, nv), dtype=bool)
    huesos = {}
    for i in range(nu):
        for j in range(nv):
            a, b = min(us) + (i + 0.5) * paso, min(vs) + (j + 0.5) * paso
            punto = der * a + up * b
            frente = None
            for poli, q0, pn, p in planos:
                if dentro(poli, a, b):
                    t = (q0 - punto).dot(pn) / n.dot(pn)
                    if frente is None or t > frente[0]:
                        frente = (t, p)
            if frente is None:
                continue
            _, _, idx, _ = bvh.ray_cast(punto + n * (frente[0] + celda * 1e-3), n, celda * 4)
            if idx is None or pols[idx][1] in colores:
                mask[i, j] = True
                for hb in frente[1][2]:
                    huesos[hb] = huesos.get(hb, 0) + 1
    r = rectangulo(mask)
    if r is None:
        return None
    i, j, w, h = r
    a, b = min(us) + (i + w / 2) * paso, min(vs) + (j + h / 2) * paso
    fondo = max(P[k].dot(n) for p in cand for k in p[0])
    return {"center": der * a + up * b + n * fondo, "normal": n, "up": up, "size": (w * paso, h * paso),
            "huesos": huesos, "celdas": (w / 8, h / 8), "mascara": float(mask.mean())}


def medir(c, n):
    """Mide un modelo; None si faltan sus archivos o el material de los ojos."""
    modelo, n_izq, etapas, requiere = CRIATURAS[c]
    colores, pintada = etapas[n]
    carpeta = os.path.join(RAIZ, "assets", "blender", f"{c}_v2")
    rig, bloques = (os.path.join(carpeta, f"e{n}_{k}.blend") for k in ("rig", "bloques"))
    geo = geometria(c, n)
    if geo is None or not (os.path.exists(rig) or os.path.exists(bloques)):
        return None
    bpy.ops.wm.open_mainfile(filepath=rig if os.path.exists(rig) else bloques)
    if os.path.exists(rig):
        png = os.path.join(RAIZ, "assets", "textures", f"{modelo}E{n}_v2_color.png")
        P, pols, celda = malla_rig(geo, png)
    else:
        P, pols, celda = malla_bloques(geo)
    if not any(p[1] in colores for p in pols):
        print(f"OJOS {modelo}E{n}: sin {colores} en la malla, se salta")
        return None
    del_hueso = [P[k] for p in pols if p[2] == {HUESO} for k in p[0]]
    caja = [V([f(q[i] for q in del_hueso) for i in range(3)]) for f in (min, max)]
    bvh = BVHTree.FromPolygons(P, [p[0] for p in pols])
    ojos = [medir_ojo(P, pols, bvh, colores + pintada, n_izq, s, celda, caja) for s in (1, -1)]
    if None in ojos:
        print(f"OJOS {modelo}E{n}: no encontré los dos ojos, se salta")
        return None
    e = {"bone": HUESO, "boundsMin": V([min(q[i] for q in P) for i in range(3)]),
         "boundsMax": V([max(q[i] for q in P) for i in range(3)]), "eyes": ojos, "celda": celda,
         "fuente": os.path.relpath(rig if os.path.exists(rig) else bloques, RAIZ), "requiresBone": requiere}
    if pintada:
        e["cover"] = tuple(round(srgb(x) * 255) for x in geo["COLORES"][colores[0]])
    if SOLO in (None, c):
        vista(os.path.join(RAIZ, "renders", "ojos_medir", f"{modelo}E{n}.png"), ojos, celda)
    if os.path.exists(rig):
        e["fbx"] = comparar_fbx(os.path.join(RAIZ, "assets", "blender", f"{modelo}E{n}_v2.fbx"), P, e)
    return e


datos = {}
for c in CRIATURAS:
    for n in range(1, 5):
        e = medir(c, n)
        if e:
            datos[f"{CRIATURAS[c][0]}E{n}"] = e
            informe(f"{CRIATURAS[c][0]}E{n}", e)
escribir_luau(os.path.join(RAIZ, "src", "shared", "UIConfig", "GiantEyesData.luau"), datos)
