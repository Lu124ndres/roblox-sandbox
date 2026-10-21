r"""
Rig de la Orca v2 (bloques), cualquier etapa, y FBX para Roblox. Hace lo mismo que
rig_minotauro_v2.py (usa sus funciones: unir, paleta, esqueleto, enlazar, posar_huesos, error_maximo,
revisar_pesos, escalar, exportar) con lo propio de la orca:
  - la cuenta de las poses es la de orca_v2_poses.py (OrcaMotion/Rig.turnBone: pitch por la derecha
    del modelo, yaw por arriba y roll por el eje largo; las cadenas se suman);
  - el esqueleto es el del contrato (orca_ref/CONTRATO_RIG_NADO.md, 1): Raiz > Pecho > Cabeza >
    Mandibula, Boca, Espiraculo, Ojo{l}Mira; Pecho > Aleta{l} > Aleta{l}2; Pecho > Cola1 > .. > Cola5;
    Cola1 > Dorsal; Cola5 > AletaCola{l}. Raiz, Boca, Espiraculo y Ojo{l}Mira sin pesos: 20 huesos,
    15 con pesos. Las articulaciones son ARTICULACIONES, COLAS y PUNTOS de orca_v2_e<n>_geometria.py;
  - escala de exportación medida por el ALTO (nada): ALTO_JUEGO / alto en reposo, 5.32 studs por BU
    en la E1, la E3 y la E4 y 44 studs exactos en la E2 (5.24 studs por BU), como el zorro.
Revisa que la malla movida por los huesos coincida con las piezas rígidas en todas las poses de
orca_v2_poses_lista.py y en el tope de cada barrido, y vuelve a abrir el FBX para contar los huesos.

Uso (desde la raíz del repo; sin --etapa, la 3):
    blender -b --factory-startup --python tools/blender/rig_orca_v2.py -- --etapa 3
Salidas: assets/blender/OrcaE<n>_v2.fbx, assets/blender/orca_v2/e<n>_rig.blend,
assets/textures/OrcaE<n>_v2_color.png y renders/orca_v2_e<n>/rig/ (PNG y rig.json).
"""
import bpy, json, math, os

CRIATURA = "orca"
HERE = os.path.dirname(os.path.abspath(__file__))
_src = open(os.path.join(HERE, "orca_v2_poses.py"), encoding="utf-8").read()
exec(_src[:_src.index("# === PRINCIPAL")], globals())  # armar_y_medir(), giros(), matrices(), POSES
_src = open(os.path.join(HERE, "rig_minotauro_v2.py"), encoding="utf-8").read()
exec(_src[:_src.index("# === PRINCIPAL")], globals())  # unir(), paleta(), esqueleto()...
NOMBRE = f"{MODELO}E{ETAPA}_v2"
FBX = os.path.join(RAIZ, "assets", "blender", NOMBRE + ".fbx")
BLEND = os.path.join(RAIZ, "assets", "blender", f"{CRIATURA}_v2", f"e{ETAPA}_rig.blend")
PNG = os.path.join(RAIZ, "assets", "textures", NOMBRE + "_color.png")
REVISION = os.path.join(RENDERS, "rig")
VISTAS_RIG = ["nado_cola_arriba", "giro_cerrado_izq", "arco_zambullida", "boca_max", "saludo", "aletazo"]


def caja_malla():
    """Caja de la malla deformada por los huesos."""
    ev = malla.evaluated_get(bpy.context.evaluated_depsgraph_get()).data
    pts = np.array([tuple(malla.matrix_world @ v.co) for v in ev.vertices])
    return V(tuple(pts.min(axis=0))), V(tuple(pts.max(axis=0)))


def topes_medidos():
    """Cada barrido en su tope limpio (de renders/<c>_v2_e<n>/poses/poses.json, si ya se midió)."""
    ruta = os.path.join(SALIDA, "poses.json")
    if not os.path.exists(ruta):
        return {}
    t = json.load(open(ruta, encoding="utf-8")).get("topes", {})
    return {f"tope_{n}": f(t[n]["limpio_hasta"]) for n, f, _ in TOPES if n in t}


def releer_fbx():
    """Abre el FBX en una escena vacía: huesos que llegan y medidas (studs)."""
    bpy.ops.wm.read_homefile(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=FBX)
    arms = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    mallas = [o for o in bpy.data.objects if o.type == "MESH"]
    pts = np.array([tuple(o.matrix_world @ v.co) for o in mallas for v in o.data.vertices])
    dims = pts.max(axis=0) - pts.min(axis=0)
    return {"huesos": sum(len(a.data.bones) for a in arms), "mallas": len(mallas),
            "medidas_studs": {"ancho_x": round(dims[0], 3), "largo_y": round(dims[1], 3), "alto_z": round(dims[2], 3)}}


# === PRINCIPAL ===
armar_y_medir()
partes = piezas()
ESCALA = ALTO_JUEGO / ALTO_BU  # studs por BU: por el alto, como GiantTemplates mide a los que nadan
malla = unir(partes)
colores = paleta(malla)
arm = esqueleto()
enlazar(malla, arm)
reposo_v = [v.co.copy() for v in malla.data.vertices]
pruebas = {n: e for n, (e, _, _) in POSES.items()} | topes_medidos()
errores = {n: round(error_maximo(malla, arm, e, 0, reposo_v), 6) for n, e in pruebas.items()}
os.makedirs(REVISION, exist_ok=True)
sc, cam, sol = estudio(ALTO_BU)
sc.cycles.samples = 16
sc.render.resolution_x = sc.render.resolution_y = 800
bpy.data.objects["Plane"].hide_render = True
for nombre in VISTAS_RIG:
    entrada, angulo, elev = POSES[nombre]
    posar_huesos(arm, entrada)
    foto(nombre, sc, cam, sol, angulo, elev, REVISION, caja_malla)
posar_huesos(arm, {})
nombres = {b.name for b in arm.data.bones}
grupos = {g.index: g.name for g in malla.vertex_groups}
datos = {
    "triangulos": sum(len(p.vertices) - 2 for p in malla.data.polygons),
    "huesos": len(arm.data.bones),
    "huesos_que_deforman": sum(b.use_deform for b in arm.data.bones),
    "arbol": {b.name: b.parent.name if b.parent else None for b in arm.data.bones},
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
datos["fbx_releido"] = releer_fbx()
with open(os.path.join(REVISION, "rig.json"), "w", encoding="utf-8", newline="\n") as fh:
    json.dump(datos, fh, indent=2, ensure_ascii=False)
print("RIG", json.dumps({k: v for k, v in datos.items() if k not in ("error_maximo_celdas_por_pose", "arbol")},
                        ensure_ascii=False))
