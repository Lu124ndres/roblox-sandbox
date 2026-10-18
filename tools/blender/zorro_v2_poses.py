r"""
Poses extremas del Zorro de agua v2, cualquier etapa (docs/guia_crear_monstruo.md, 4 y 5): posa las
piezas rígidas con la misma cuenta que el juego y revisa que no se separen ni se crucen.

La cuenta es la de src/shared/Zorro:
    Rig.bind    ejes del CUERPO medidos en los huesos: derecha de HombroIzq a HombroDer (-x), arriba
                z, adelante = arriba x derecha (-y). Rig.turn: cabeceo por la derecha, giro por
                arriba y alabeo por adelante, en ese orden, cada hueso llevado por su padre.
    Pose.apply  tronco, cuello y cabeza, mandíbula, orejas y las cuatro patas (zorro_v2_poses_cuerpo.py).
    Colas       Mezcla, Estados, Cadena y Limites, simulados cuadro a cuadro con los pedidos de
                Colas/Prueba (zorro_v2_colas_sim.py y zorro_v2_colas_paso.py).
Las poses están en zorro_v2_poses_lista.py. medir() y revisar() son las de minotauro_v2_poses.py
(este archivo la carga hasta armar()), con los umbrales de la guía:
    atraviesa  dos piezas sin articulación entre ellas que se meten una en otra más de 0.3 celdas
               más que en reposo (una cola en otra, una pata en el pecho)
    junta      una pieza y su padre que se solapan 1.0 celda más que en reposo
    hueco      una pieza que se separa de su padre más de 0.2 celdas
Además anota las piezas que bajan del piso (z = 0) más de 0.3 celdas (no cuenta para "limpia": en
el juego el zorro está en el agua) y barre el ciclo de paso entero y cada escena de colas.
Renderiza cada pose en renders/zorro_v2_e<n>/poses/ y guarda poses.json. No guarda el .blend.

Uso (desde la raíz del repo; sin --etapa, la 3):
    blender -b --factory-startup --python tools/blender/zorro_v2_poses.py -- --etapa 3
"""
import bpy, json, math, os, sys
import numpy as np

CRIATURA = "zorro"
HERE = os.path.dirname(os.path.abspath(__file__))
if "--etapa" not in sys.argv:  # el armador común toma la 1 si no se le dice
    sys.argv += (["--"] if "--" not in sys.argv else []) + ["--etapa", "3"]
_src = open(os.path.join(HERE, "minotauro_v2_poses.py"), encoding="utf-8").read()
exec(_src[:_src.index("\narmar()\n")], globals())  # bloques del zorro, HUESOS, medir(), revisar()
for _f in ("zorro_v2_colas_sim.py", "zorro_v2_colas_paso.py", "zorro_v2_poses_cuerpo.py",
           "zorro_v2_poses_lista.py", "zorro_v2_poses_limites.py"):
    exec(open(os.path.join(HERE, _f), encoding="utf-8").read(), globals())
ALTO_BU = None  # alto en reposo: lo mide armar_y_medir()


def giros(p, faldon=0.0):
    """Rig.turn en los ejes del cuerpo (derecha -x, arriba z, adelante -y) y lo que escribe Colas
    en cada tramo de cola. Hueso -> matriz de giro (sin trasladar). `faldon` no se usa."""
    rot_ = locales(p)
    r = {}
    for nombre in HUESOS:
        a, g, b = rot_.get(nombre, (0, 0, 0))
        r[nombre] = Matrix.Rotation(-a, 4, "X") @ Matrix.Rotation(g, 4, "Z") @ Matrix.Rotation(-b, 4, "Y")
    for nombre, (fan, fold) in (p or {}).get("colas", {}).items():
        r[nombre] = Matrix(giro_tramo(MED, nombre, fan, fold).tolist()).to_4x4()
    return r


def subida(p):
    """Cuánto sube la base (BU): pose.dy x alto - crouch x alto x CROUCH_DROP, como Zorro/init."""
    p = p or {}
    return (p.get("dy", 0.0) - CROUCH_DROP * p.get("crouch", 0.0)) * (ALTO_BU or 0.0)


def matrices(p, faldon=0.0):
    """Matriz del mundo de cada pieza, heredando el giro del padre; la base sube `dy`."""
    r, m = giros(p), {}
    base0 = Matrix.Translation((0, 0, subida(p)))
    for nombre, (padre, piv) in HUESOS.items():
        base = m[padre] if padre else base0
        m[nombre] = base @ Matrix.Translation(piv) @ r[nombre] @ Matrix.Translation(-piv)
    return m


def piezas():
    return [o for o in bpy.data.objects if o.type == "MESH" and "hueso" in o]


def caja(nombres=None):
    """Caja de las piezas posadas (o solo de `nombres`)."""
    pts = np.array([tuple(o.matrix_world @ v.co) for o in piezas() if not nombres or o.name in nombres
                    for v in o.data.vertices])
    return V(tuple(pts.min(axis=0))), V(tuple(pts.max(axis=0)))


def bajo_piso():
    """Piezas que bajan del piso más de PENETRA celdas: {pieza: celdas}."""
    r = {}
    for o in piezas():
        z = min((o.matrix_world @ v.co).z for v in o.data.vertices) / C
        if z < -PENETRA:
            r[o.name] = round(-z, 2)
    return r


def foto(nombre, sc, cam, sol, angulo, elev, carpeta, enfoque=None):
    """Cámara ortográfica que toma la caja de la pose (o de las piezas de `enfoque`) desde `angulo`
    (0 = de frente) y `elev` grados de altura."""
    lo, hi = caja(enfoque)
    centro, tam = (lo + hi) / 2, hi - lo
    a, e = G(angulo), G(elev)
    d = V((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e)))
    cam.data.ortho_scale = max(tam) * 1.12
    cam.location = centro + d * tam.length * 2
    cam.rotation_euler = (centro - cam.location).to_track_quat("-Z", "Y").to_euler()
    sol.rotation_euler = (G(50), 0, a + G(-35))
    sc.render.filepath = os.path.join(carpeta, nombre + ".png")
    bpy.ops.render.render(write_still=True)


def resumen(atraviesa, juntas, sueltas):
    return {"atraviesa": atraviesa, "junta": juntas, "hueco": sueltas}


def armar_y_medir():
    """Arma las piezas, mide el alto en reposo y arma la lista de poses."""
    global ALTO_BU
    armar()
    posar({})
    ALTO_BU = alto_bu()
    preparar_choques(medir()[0])
    armar_poses()


# === PRINCIPAL (rig_zorro_v2.py carga este archivo hasta aquí) ===
armar_y_medir()
os.makedirs(SALIDA, exist_ok=True)
posar({})
reposo = medir()
datos = {
    "umbral_celdas": {"atraviesa": PENETRA, "junta": JUNTA, "hueco": HUECO},
    "rig": {"derecha": [-1, 0, 0], "arriba": [0, 0, 1], "adelante": [0, -1, 0], "alto_bu": round(ALTO_BU, 4)},
    "reposo": {"cruces": {f"{a}/{b}": round(d, 2) for (a, b), d in sorted(reposo[0].items())},
               "huecos": {h: round(d, 2) for h, d in reposo[1].items() if d > 0}},
    "colas_medidas": [{"cola": c["huesos"][0][:-2], "angulo_rad": round(c["angle"], 3), "out": round(c["out"], 3)}
                      for c in MED["colas"]],
    "juego": INFO,
    "poses": {},
    "barridos": {},
}
for nombre, lista in BARRIDOS.items():
    peor = {}
    for etiqueta, entrada in lista:
        posar(entrada)
        atraviesa, juntas, sueltas = revisar(reposo)
        if atraviesa or juntas or sueltas:
            peor[etiqueta] = resumen(atraviesa, juntas, sueltas)
    datos["barridos"][nombre] = {"muestras": len(lista), "con_problemas": peor}
datos["limites_cuerpo"] = limites_cuerpo(reposo)
datos["tolerancia_colas"] = tolerancia_colas(reposo)
datos["juntas_45_por_cola"] = juntas_por_cola(reposo)
sc, cam, sol = estudio(ALTO_BU)
sc.cycles.samples = 16
for nombre, (entrada, angulo, elev, *enfoque) in POSES.items():
    posar(entrada)
    datos["poses"][nombre] = dict(resumen(*revisar(reposo)), bajo_piso=bajo_piso())
    foto(nombre, sc, cam, sol, angulo, elev, SALIDA, *enfoque)
limpias = [n for n, d in datos["poses"].items() if not (d["atraviesa"] or d["junta"] or d["hueco"])]
datos["limpias"] = {"cuantas": len(limpias), "de": len(POSES), "nombres": limpias}
with open(os.path.join(SALIDA, "poses.json"), "w", encoding="utf-8", newline="\n") as fh:
    json.dump(datos, fh, indent=2, ensure_ascii=False)
print("POSES", json.dumps({n: [len(d[k]) for k in ("atraviesa", "junta", "hueco")]
                           for n, d in datos["poses"].items()}))
print("BARRIDOS", json.dumps({n: len(d["con_problemas"]) for n, d in datos["barridos"].items()}))
print("LIMPIAS", len(limpias), "de", len(POSES), "CONTACTO", json.dumps(INFO["contacto_celdas"]))
