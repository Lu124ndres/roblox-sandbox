r"""
Rig del Zorro de agua v2 (bloques), cualquier etapa, y FBX para Roblox. Hace lo mismo que
rig_minotauro_v2.py (usa sus funciones: unir, paleta, esqueleto, enlazar, error_maximo,
revisar_pesos, escalar, exportar) con lo propio del zorro:
  - la cuenta de las poses es la de zorro_v2_poses.py (Zorro/Rig, Zorro/Pose y Zorro/Colas), y la
    base sube o baja con `dy` (aquí, moviendo el hueso Raiz);
  - el esqueleto es el CONTRATO de la geometría (BIBLIA.md, 7): Raiz > Cadera > Columna > Pecho >
    Cuello1 > Cuello2 > Cabeza > Mandibula, Boca, Oreja{l} > OrejaPunta{l}, Parpado{l}; Pecho >
    Hombro > Brazo > Antebrazo > Mano; Cadera > Muslo > Pierna > Tobillo > Pie; Cadera > Cola<n>_1
    .. _5. Raiz y Boca sin pesos. 36, 46, 61 y 76 huesos en E1..E4 (1, 3, 6 y 9 colas);
  - escala de exportación medida por el ALTO (camina): ALTO_JUEGO / alto en reposo, 5.32 studs por
    BU en las cuatro etapas (82.5 / 15.5 en la E3).
Revisa que la malla movida por los huesos coincida con las piezas rígidas en todas las poses.

Uso (desde la raíz del repo; sin --etapa, la 3):
    blender -b --factory-startup --python tools/blender/rig_zorro_v2.py -- --etapa 3
Salidas: assets/blender/ZorroDeAguaE<n>_v2.fbx, assets/blender/zorro_v2/e<n>_rig.blend,
assets/textures/ZorroDeAguaE<n>_v2_color.png y renders/zorro_v2_e<n>/rig/ (PNG y rig.json).
"""
import bpy, json, math, os

CRIATURA = "zorro"
HERE = os.path.dirname(os.path.abspath(__file__))
_src = open(os.path.join(HERE, "zorro_v2_poses.py"), encoding="utf-8").read()
exec(_src[:_src.index("# === PRINCIPAL")], globals())  # armar_y_medir(), giros(), matrices(), POSES
colas_geometria = colas  # construir() de la geometría arma las colas con colas(); rig_minotauro_v2.py
_src = open(os.path.join(HERE, "rig_minotauro_v2.py"), encoding="utf-8").read()
exec(_src[:_src.index("# === PRINCIPAL")], globals())  # unir(), paleta(), esqueleto()...
colas_huesos = colas  # usa el mismo nombre para la cola de cada hueso (la pide esqueleto())
NOMBRE = f"{MODELO}E{ETAPA}_v2"
FBX = os.path.join(RAIZ, "assets", "blender", NOMBRE + ".fbx")
BLEND = os.path.join(RAIZ, "assets", "blender", f"{CRIATURA}_v2", f"e{ETAPA}_rig.blend")
PNG = os.path.join(RAIZ, "assets", "textures", NOMBRE + "_color.png")
REVISION = os.path.join(RENDERS, "rig")
VISTAS_RIG = ["reposo", "aullido_boca_max", "reverencia", "sentado", "dormir_echado", "rascarse_oreja",
              "colas_abanico_max", "colas_plegadas_correr"]


def posar_huesos(arm, p, faldon=0.0):
    """La pose de matrices() puesta en los huesos: el giro del mundo de cada hueso pasado a sus ejes
    de reposo (lo que hace Rig.bind) y la subida de la base en Raiz."""
    r = giros(p)
    for pb in arm.pose.bones:
        b = pb.bone.matrix_local.to_3x3().to_4x4()
        if pb.name in r:
            pb.matrix_basis = b.inverted() @ r[pb.name] @ b
        elif pb.name == "Raiz":
            pb.matrix_basis = b.inverted() @ Matrix.Translation((0, 0, subida(p))) @ b
        else:
            pb.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()


def caja(nombres=None):
    """Caja de la malla deformada por los huesos (la de zorro_v2_poses.py mira las piezas)."""
    ev = malla.evaluated_get(bpy.context.evaluated_depsgraph_get()).data
    pts = np.array([tuple(malla.matrix_world @ v.co) for v in ev.vertices])
    return V(tuple(pts.min(axis=0))), V(tuple(pts.max(axis=0)))


# === PRINCIPAL ===
colas = colas_geometria
armar_y_medir()
colas = colas_huesos
partes = piezas()
# Las piezas se unen en su reposo de la geometría. posar({}) ya no sirve para esto: desde
# que Patas tiene IK, la pose vacía deja las patas y las colas posadas (el FBX salía mal).
from mathutils import Matrix

for _pieza in partes:
    _pieza.matrix_world = Matrix.Identity(4)
bpy.context.view_layer.update()
ESCALA = ALTO_JUEGO / ALTO_BU  # studs por BU: por el alto, como GiantTemplates mide a los que caminan
malla = unir(partes)
colores = paleta(malla)
arm = esqueleto()
enlazar(malla, arm)
reposo_v = [v.co.copy() for v in malla.data.vertices]
errores = {n: round(error_maximo(malla, arm, p[0], 0, reposo_v), 6) for n, p in POSES.items()}
for nombre, lista in BARRIDOS.items():
    errores[f"barrido_{nombre}"] = round(max(error_maximo(malla, arm, e, 0, reposo_v) for _, e in lista), 6)
os.makedirs(REVISION, exist_ok=True)
sc, cam, sol = estudio(ALTO_BU)
sc.cycles.samples = 16
for nombre in VISTAS_RIG:
    entrada, angulo, elev = POSES.get(nombre, ({}, 35, 15))[:3]
    posar_huesos(arm, entrada)
    foto(nombre, sc, cam, sol, angulo, elev, REVISION)
posar_huesos(arm, {})
nombres = {b.name for b in arm.data.bones}
grupos = {g.index: g.name for g in malla.vertex_groups}
datos = {
    "triangulos": sum(len(p.vertices) - 2 for p in malla.data.polygons),
    "huesos": len(arm.data.bones),
    "huesos_que_deforman": sum(b.use_deform for b in arm.data.bones),
    "huesos_del_contrato_que_faltan": sorted(set(CONTRATO) - nombres),
    "huesos_fuera_del_contrato": sorted(nombres - set(CONTRATO)),
    "sin_pesos": {n: {"deforma": arm.data.bones[n].use_deform,
                      "vertices": sum(1 for v in malla.data.vertices if grupos[v.groups[0].group] == n)}
                  for n in CONTRATO_SIN_PESOS if n in nombres},
    "colores_en_la_paleta": colores,
    "pesos": revisar_pesos(malla),
    "error_maximo_celdas_por_pose": errores,
    "error_maximo_celdas": max(errores.values()),
    "escala_studs_por_bu": round(ESCALA, 4),
}
escalar(malla, arm)
dims = [round(d, 3) for d in malla.dimensions]
datos["medidas_studs"] = {"ancho_x": dims[0], "largo_y": dims[1], "alto_z": dims[2]}
os.makedirs(os.path.dirname(BLEND), exist_ok=True)
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=BLEND)
exportar(malla, arm)
with open(os.path.join(REVISION, "rig.json"), "w", encoding="utf-8", newline="\n") as fh:
    json.dump(datos, fh, indent=2, ensure_ascii=False)
print("RIG", json.dumps({k: v for k, v in datos.items() if k != "error_maximo_celdas_por_pose"}, ensure_ascii=False))
