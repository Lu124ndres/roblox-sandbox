r"""
Poses extremas de la Orca v2, cualquier etapa (docs/guia_crear_monstruo.md, 4 y 5): posa las piezas
rígidas con la misma cuenta que el juego y revisa que no se separen ni se crucen.

La cuenta es la de src/shared/Orca/OrcaMotion/Rig.luau (orca_ref/CONTRATO_RIG_NADO.md, 2):
    Rig.bind      ejes del MODELO medidos en cada hueso: frente -Z y arriba +Y de Roblox, que en
                  Blender son -y y z (la derecha del modelo, +X, es -x)
    turnBone      pitch por la derecha, yaw por arriba y roll por el eje largo (atrás), en ese
                  orden, cada hueso llevado por su padre: los ángulos de una cadena se suman
La lista de poses y la cuenta del nado están en orca_v2_poses_lista.py, la revisión por muestra en
orca_v2_poses_revision.py y los topes en orca_v2_poses_limites.py. medir() y revisar() son las
de minotauro_v2_poses.py (este archivo la carga hasta armar()), con los umbrales de la guía:
    atraviesa  dos piezas sin articulación entre ellas que se meten una en otra más de 0.3 celdas
               más que en reposo (la quijada en la garganta, la Cola2 en la dorsal); además de lo
               más hondo de cada par (la guía), cada muestra contra ella misma en reposo
               (revisar()). La dorsal y el Pecho cuentan como junta (JUNTAS_CRUZADAS)
    junta      una pieza y su padre que se solapan 1.0 celda más que en reposo
    hueco      una pieza que se separa de su padre más de 0.2 celdas
Además:
    topes      por hueso y por eje, el ángulo más grande que queda limpio (pasos de 0.02 rad y
               bisección), con la primera falla; en el formato de OrcaMotion/Limites.luau
    cadenas    cadenaPitch y cadenaYaw: la suma de Cola1..Cola5 más grande que queda limpia,
               repartida como `arch` (ARCO) y como los topes de cada tramo
    barrido    una vuelta entera de la onda de nado al máximo
Renderiza cada pose en renders/orca_v2_e<n>/poses/ y guarda poses.json. No guarda el .blend.

Uso (desde la raíz del repo; sin --etapa, la 3; --sin-fotos para medir sin renderizar):
    blender -b --factory-startup --python tools/blender/orca_v2_poses.py -- --etapa 3
"""
import bpy, json, math, os, sys
import numpy as np

CRIATURA = "orca"
HERE = os.path.dirname(os.path.abspath(__file__))
if "--etapa" not in sys.argv:  # el armador común toma la 1 si no se le dice
    sys.argv += (["--"] if "--" not in sys.argv else []) + ["--etapa", "3"]
_src = open(os.path.join(HERE, "minotauro_v2_poses.py"), encoding="utf-8").read()
exec(_src[:_src.index("\narmar()\n")], globals())  # bloques de la orca, HUESOS, medir(), revisar()
for _f in ("orca_v2_poses_lista.py", "orca_v2_poses_revision.py", "orca_v2_poses_limites.py"):
    exec(open(os.path.join(HERE, _f), encoding="utf-8").read(), globals())
PASO = 0.02  # rad, paso de los barridos de topes
FASES = 24  # muestras de una vuelta del nado


def locales(p):
    return (p or {}).get("huesos", {})


def giros(p, faldon=0.0):
    """turnBone en los ejes del modelo: hueso -> matriz de giro (sin trasladar). `faldon` no se usa
    (lo pasan matrices() y posar() del minotauro)."""
    rot = locales(p)
    r = {}
    for nombre in HUESOS:
        a, g, b = rot.get(nombre, (0, 0, 0))
        r[nombre] = Matrix.Rotation(-a, 4, "X") @ Matrix.Rotation(g, 4, "Z") @ Matrix.Rotation(b, 4, "Y")
    return r


def piezas():
    return [o for o in bpy.data.objects if o.type == "MESH" and "hueso" in o]


def caja_piezas():
    pts = np.array([tuple(o.matrix_world @ v.co) for o in piezas() for v in o.data.vertices])
    return V(tuple(pts.min(axis=0))), V(tuple(pts.max(axis=0)))


def foto(nombre, sc, cam, sol, angulo, elev, carpeta, caja=caja_piezas):
    """Cámara ortográfica que toma la caja de la pose desde `angulo` (0 = de frente, 90 = el
    costado izquierdo) y `elev` grados de altura."""
    lo, hi = caja()
    centro, tam = (lo + hi) / 2, hi - lo
    a, e = G(angulo), G(elev)
    d = V((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e)))
    cam.data.ortho_scale = max(tam) * 1.12
    cam.location = centro + d * tam.length * 2
    cam.data.clip_end = tam.length * 5
    cam.rotation_euler = (centro - cam.location).to_track_quat("-Z", "Y").to_euler()
    sol.rotation_euler = (G(50), 0, a + G(-35))
    sc.render.filepath = os.path.join(carpeta, nombre + ".png")
    bpy.ops.render.render(write_still=True)


def resumen(atraviesa, juntas, sueltas):
    return {"atraviesa": atraviesa, "junta": juntas, "hueco": sueltas}



def barrido(reposo):
    peor = {}
    for i in range(FASES):
        f = 2 * math.pi * i / FASES
        r = fallas(nado(f), reposo)
        if any(r.values()):
            peor[f"{f:.2f}"] = r
    return peor


def armar_y_medir():
    """Arma las piezas en reposo (para rig_orca_v2.py: carga este archivo hasta aquí)."""
    global ALTO_BU
    armar()
    posar({})
    ALTO_BU = alto_bu()


# === PRINCIPAL (rig_orca_v2.py carga este archivo hasta aquí) ===
armar_y_medir()
os.makedirs(SALIDA, exist_ok=True)
reposo = medir_todo()
datos = {
    "umbral_celdas": {"atraviesa": PENETRA, "junta": JUNTA, "hueco": HUECO},
    "rig": {"pitch": "-x (derecha del modelo)", "yaw": "z", "roll": "+y (atrás)", "alto_bu": round(ALTO_BU, 4)},
    "reposo": {"cruces": {f"{a}/{b}": round(d, 2) for (a, b), d in sorted(reposo[0].items())},
               "huecos": {h: round(d, 2) for h, d in reposo[1].items() if d > 0}},
    "poses": {},
}
for nombre, (entrada, _, _) in POSES.items():
    datos["poses"][nombre] = fallas(entrada, reposo)
limpias = [n for n, d in datos["poses"].items() if not any(d.values())]
datos["limpias"] = {"cuantas": len(limpias), "de": len(POSES), "nombres": limpias}
print("LIMPIAS", len(limpias), "de", len(POSES), json.dumps({n: [len(d[k]) for k in ("atraviesa", "junta", "hueco")]
                                                              for n, d in datos["poses"].items()}))
datos["nado_maximo_por_fase"] = barrido(reposo)
datos["topes"] = medir_topes(reposo)
datos["limites"] = {"porHueso": limites(datos["topes"])}
datos["cadenas"] = medir_cadenas(datos["topes"], reposo)
print("TOPES", json.dumps({n: d["limpio_hasta"] for n, d in datos["topes"].items()}))
print("CADENAS", json.dumps({n: d["limpio_hasta"] for n, d in datos["cadenas"].items()}))
with open(os.path.join(SALIDA, "poses.json"), "w", encoding="utf-8", newline="\n") as fh:
    json.dump(datos, fh, indent=2, ensure_ascii=False)
if "--sin-fotos" not in sys.argv:
    sc, cam, sol = estudio(ALTO_BU)
    sc.cycles.samples = 16
    sc.render.resolution_x = sc.render.resolution_y = 800
    bpy.data.objects["Plane"].hide_render = True
    for nombre, (entrada, angulo, elev) in POSES.items():
        posar(entrada)
        foto(nombre, sc, cam, sol, angulo, elev, SALIDA)
print("NADO", json.dumps(list(datos["nado_maximo_por_fase"])))
