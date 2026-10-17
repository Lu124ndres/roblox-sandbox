r"""
Revisión de los modelos de bloques v2 (la usa minotauro_v2_e1_bloques.py con exec).

Cada bloque llega como sólido: {"parte", "color", "b" (bmesh con bisel y sin caras
ocultas), "caras" (caras de la cuña SIN bisel: (normal, vértices)), "antes" (caras,
aristas y vértices antes del bisel), "despues" (caras después del bisel)}.

    coplanares(solidos)     caras que quedan, de bloques distintos, en el mismo plano, con la
                            misma orientación y área en común: parpadean (z-fighting). Usa la
                            forma real de cada bloque (cuñas y bisel), no su caja.
    normales(solidos)       caras con la normal hacia adentro del bloque.
    bisel(solidos)          cuántos segmentos dejó el bisel y a qué distancia de la arista.
    pendientes(solidos)     cuñas fuera de 1:1, 1:2 o 2:1 y vértices fuera de la cuadrícula.
    huesos(objetos)         pieza -> hueso contra el contrato (25 huesos + 3 opcionales del faldón).
"""
import math
from mathutils import Vector as V

HUESOS = ["Raiz", "Cadera", "Columna", "Pecho", "Cuello", "Cabeza", "Mandibula", "Boca",
          "Cola1", "Cola2", "Cola3"] + [f"{h}{l}" for l in ("Izq", "Der") for h in (
              "Oreja", "Brazo", "Antebrazo", "Mano", "Muslo", "Pierna", "Pie")]
HUESOS += ["FaldonFrente", "FaldonIzq", "FaldonDer"]  # adición opcional v2, hijos de Cadera
SIN_PESOS = {"Raiz", "Boca"}


def _base(n):
    u = n.orthogonal().normalized()
    return u, n.cross(u)


def _area(poli):
    return 0.5 * sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(poli, poli[1:] + poli[:1]))


def _recortar(poli, clip):
    """Sutherland-Hodgman: poli recortado por el polígono convexo clip (ambos antihorarios)."""
    for a, b in zip(clip, clip[1:] + clip[:1]):
        if not poli:
            break
        lado = lambda p: (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0])
        nuevo = []
        for p, q in zip(poli, poli[1:] + poli[:1]):
            sp, sq = lado(p), lado(q)
            if sp >= 0:
                nuevo.append(p)
            if (sp >= 0) != (sq >= 0):
                t = sp / (sp - sq)
                nuevo.append((p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t))
        poli = nuevo
    return poli


def coplanares(solidos):
    grupos = {}
    for i, s in enumerate(solidos):
        for f in s["b"].faces:
            n = f.normal
            clave = (round(n.x, 3), round(n.y, 3), round(n.z, 3), round(n.dot(f.verts[0].co), 4))
            grupos.setdefault(clave, []).append((i, f))
    malos = set()
    for (nx, ny, nz, _), caras in grupos.items():
        if len({i for i, _ in caras}) < 2:
            continue
        u, v = _base(V((nx, ny, nz)).normalized())
        polis = [(i, [(p.co.dot(u), p.co.dot(v)) for p in f.verts]) for i, f in caras]
        for k, (i, a) in enumerate(polis):
            for j, b in polis[k + 1:]:
                if i != j and abs(_area(_recortar(a, b))) > 1e-6:
                    sa, sb = solidos[i], solidos[j]
                    malos.add(f"{sa['parte']}/{sa['color']} con {sb['parte']}/{sb['color']}")
    return sorted(malos)


def normales(solidos):
    malas = 0
    for s in solidos:
        centro = sum((p for _, pts in s["caras"] for p in pts), V()) / sum(len(p) for _, p in s["caras"])
        malas += sum(1 for f in s["b"].faces if (f.calc_center_median() - centro).dot(f.normal) <= 0)
    return malas


def _dist_segmento(p, a, b):
    ab = b - a
    t = max(0.0, min(1.0, (p - a).dot(ab) / ab.length_squared))
    return (p - (a + ab * t)).length


def bisel(solidos):
    """Un segmento: cada arista deja una cara y cada vértice otra (F + E + V caras). Distancia:
    de cada vértice de la cara plana que queda a la arista original más cercana."""
    distancias, segmentos_malos = [], []
    for s in solidos:
        f0, e0, v0 = s["antes"]
        if s["despues"] != f0 + e0 + v0:
            segmentos_malos.append(f"{s['parte']}/{s['color']}: {s['despues']} caras, esperadas {f0 + e0 + v0}")
        for n, pts in s["caras"]:
            d = n.dot(pts[0])
            for f in s["b"].faces:
                if f.normal.dot(n) > 0.9999 and abs(f.normal.dot(f.verts[0].co) - d) < 1e-6:
                    for p in f.verts:
                        distancias.append(min(_dist_segmento(p.co, a, b) for a, b in zip(pts, pts[1:] + pts[:1])))
    return {"min": round(min(distancias), 5), "max": round(max(distancias), 5),
            "segmentos_distintos_de_1": segmentos_malos}


def pendientes(solidos, celda):
    fuera, rejilla = [], []
    for s in solidos:
        for n, pts in s["caras"]:
            c = sorted((abs(x) for x in n if abs(x) > 1e-6), reverse=True)
            if len(c) == 3 or (len(c) == 2 and min(abs(c[0] / c[1] - 1), abs(c[0] / c[1] - 2)) > 1e-4):
                fuera.append(f"{s['parte']}/{s['color']}: normal {tuple(round(x, 3) for x in n)}")
            for p in pts:
                if any(abs(x / celda - round(x / celda)) > 1e-4 for x in p):
                    rejilla.append(f"{s['parte']}/{s['color']}: {tuple(round(x, 4) for x in p)}")
    return {"cunas_fuera_de_regla": sorted(set(fuera)), "vertices_fuera_de_cuadricula": sorted(set(rejilla))}


def huesos(objetos):
    tabla = {o.name: o["hueso"] for o in objetos}
    por_hueso = {h: sorted(p for p, x in tabla.items() if x == h) for h in HUESOS}
    return {
        "pieza_a_hueso": tabla,
        "piezas_sin_hueso_del_contrato": sorted(p for p, h in tabla.items() if h not in HUESOS),
        "huesos_sin_pieza": sorted(h for h, p in por_hueso.items() if not p),
        "huesos_con_varias_piezas": {h: p for h, p in por_hueso.items() if len(p) > 1},
        "huesos_sin_pesos_por_contrato": sorted(SIN_PESOS),
    }


def materiales_diagnostico(nombres):
    """Color plano (emisión) y la cara de atrás en rojo: un agujero o una normal al revés se ven rojos."""
    import bpy
    for nombre in nombres:
        m = bpy.data.materials.get(nombre)
        if not m:
            continue
        nt = m.node_tree
        bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
        color = tuple(bsdf.inputs["Base Color"].default_value)
        for n in list(nt.nodes):
            if n.type != "OUTPUT_MATERIAL":
                nt.nodes.remove(n)
        salida = next(n for n in nt.nodes if n.type == "OUTPUT_MATERIAL")
        plano, rojo = nt.nodes.new("ShaderNodeEmission"), nt.nodes.new("ShaderNodeEmission")
        plano.inputs["Color"].default_value = color
        rojo.inputs["Color"].default_value = (1, 0, 0, 1)
        mezcla, geo = nt.nodes.new("ShaderNodeMixShader"), nt.nodes.new("ShaderNodeNewGeometry")
        nt.links.new(geo.outputs["Backfacing"], mezcla.inputs["Fac"])
        nt.links.new(plano.outputs["Emission"], mezcla.inputs[1])
        nt.links.new(rojo.outputs["Emission"], mezcla.inputs[2])
        nt.links.new(mezcla.outputs["Shader"], salida.inputs["Surface"])
