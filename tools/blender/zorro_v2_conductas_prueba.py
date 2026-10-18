r"""
Vista rápida de las conductas del Zorro de agua v2 (src/shared/Zorro/Conductas) con la cuenta del
cuerpo que hoy tiene tools/blender/zorro_v2_poses_cuerpo.py (Pose.apply): posa las piezas rígidas
en los cuadros que se le pasan, revisa choques con revisar() y saca una foto de cada uno.

Las poses NO se recalculan aquí: salen del Luau del juego (la única fuente), muestreadas en Studio
y guardadas en un JSON:
    {"etapa": 3, "poses": [{"nombre": "rascarse_050", "pose": {"lookYaw": 0.3, ...}}, ...]}
Las claves que la cuenta de Blender todavía no conoce (sit, lie, curl, scratch, pawL...) se ignoran:
lo que se ve es cabeza, orejas, tronco, bow, crouch, pasos, sacudida y dy. Cuando
zorro_v2_poses_cuerpo.py sume las claves nuevas de la ola 3, esta misma vista las muestra.

Uso (desde la raíz del repo):
    blender -b --factory-startup --python tools/blender/zorro_v2_conductas_prueba.py -- \
        --etapa 3 --poses <archivo.json> [--salida <carpeta>]
Sin --salida, escribe en renders/zorro_v2_e<n>/conductas/ (fotos y resumen.json).
"""
import bpy, json, math, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def _arg(nombre, defecto=None):
    return ARGS[ARGS.index(nombre) + 1] if nombre in ARGS else defecto


_src = open(os.path.join(HERE, "zorro_v2_poses.py"), encoding="utf-8").read()
exec(_src[:_src.index("# === PRINCIPAL")], globals())  # armar(), posar(), revisar(), foto()...

# Las claves que hoy entiende locales() de zorro_v2_poses_cuerpo.py (más t, para la sacudida).
CONOCIDAS = {"lean", "sway", "breathe", "lookYaw", "lookPitch", "tilt", "jaw", "earL", "earR", "bow",
             "crouch", "stepFL", "stepFR", "stepHL", "stepHR", "shake", "dy", "t"}

with open(_arg("--poses"), encoding="utf-8") as fh:
    ENTRADA = json.load(fh)
CARPETA = _arg("--salida") or os.path.join(RAIZ, "renders", f"zorro_v2_e{ETAPA}", "conductas")
os.makedirs(CARPETA, exist_ok=True)

armar()
posar({})
ALTO_BU = alto_bu()
reposo = medir()
sc, cam, sol = estudio(ALTO_BU)
sc.cycles.samples = 8
resumen = {"etapa": ETAPA, "ignoradas": {}, "poses": {}}
for item in ENTRADA["poses"]:
    pose = item["pose"]
    usadas = {k: v for k, v in pose.items() if k in CONOCIDAS}
    resumen["ignoradas"][item["nombre"]] = sorted(k for k in pose if k not in CONOCIDAS)
    posar(usadas)
    atraviesa, juntas, sueltas = revisar(reposo)
    resumen["poses"][item["nombre"]] = {"atraviesa": atraviesa, "junta": juntas, "hueco": sueltas,
                                        "bajo_piso": bajo_piso()}
    foto(item["nombre"], sc, cam, sol, item.get("angulo", 35), item.get("elev", 12), CARPETA)
with open(os.path.join(CARPETA, "resumen.json"), "w", encoding="utf-8", newline="\n") as fh:
    json.dump(resumen, fh, indent=2, ensure_ascii=False)
print("CONDUCTAS", json.dumps({n: [len(d[k]) for k in ("atraviesa", "junta", "hueco")]
                               for n, d in resumen["poses"].items()}))
