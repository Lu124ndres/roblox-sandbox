r"""
Rig del Dragón marino v2 (bloques), cualquier etapa, y FBX para Roblox. Hace lo mismo que
rig_minotauro_v2.py (usa sus funciones: unir, paleta, esqueleto, posar_huesos, error_maximo,
escalar, exportar) con lo propio del dragón:
  - la cuenta de las poses es la de dragon_v2_poses.py (Dragon/Rig y Dragon/Pose);
  - el esqueleto es el contrato de 32 huesos (rig_dragon.py): Raiz > Cadera > Pecho > Cuello1 >
    Cuello2 > Cabeza > Mandibula, Boca; Cadera > Cola1..Cola6; Pecho > Ala{Izq,Der}1..3;
    Pecho > Brazo/Antebrazo/Mano; Cadera > Muslo/Pierna/Pie. Raiz y Boca sin pesos;
  - escala de exportación: la dimensión más larga mide Dragon.LENGTH x el alto de la etapa
    (LARGO_JUEGO), que es como lo mide GiantTemplates (2.75 studs por BU; plan_dragon_v2.md).
Revisa que la malla movida por los huesos coincida con las piezas rígidas en todas las poses.

Uso (desde la raíz del repo; sin --etapa, la 1):
    blender -b --factory-startup --python tools/blender/rig_dragon_v2.py -- --etapa 1
Salidas: assets/blender/DragonMarinoE<n>_v2.fbx, assets/blender/dragon_v2/e<n>_rig.blend,
assets/textures/DragonMarinoE<n>_v2_color.png y renders/dragon_v2_e<n>/rig/ (PNG y rig.json).
"""
import bpy, json, math, os

CRIATURA = "dragon"
HERE = os.path.dirname(os.path.abspath(__file__))
_src = open(os.path.join(HERE, "dragon_v2_poses.py"), encoding="utf-8").read()
exec(_src[:_src.index("# === PRINCIPAL")], globals())  # armar(), giros(), matrices(), POSES
_src = open(os.path.join(HERE, "rig_minotauro_v2.py"), encoding="utf-8").read()
exec(_src[:_src.index("# === PRINCIPAL")], globals())  # unir(), paleta(), esqueleto()...
NOMBRE = f"{MODELO}E{ETAPA}_v2"
FBX = os.path.join(RAIZ, "assets", "blender", NOMBRE + ".fbx")
BLEND = os.path.join(RAIZ, "assets", "blender", f"{CRIATURA}_v2", f"e{ETAPA}_rig.blend")
PNG = os.path.join(RAIZ, "assets", "textures", NOMBRE + "_color.png")
REVISION = os.path.join(RENDERS, "rig")
TRUCOS = ["planeo", "aletazo_abajo_max", "aletazo_arriba_max", "truco_rugido", "truco_fuego",
          "alas_plegadas_picada", "comer"]


piezas = [o for o in armar() if o.type == "MESH"]
posar({})
ENCUADRE = encuadre()
ESCALA = LARGO_JUEGO / (ENCUADRE[1] * 3.1)  # studs por BU: la dimensión más larga
malla = unir(piezas)
colores = paleta(malla)
arm = esqueleto()
enlazar(malla, arm)
reposo = [v.co.copy() for v in malla.data.vertices]
errores = {n: round(error_maximo(malla, arm, entrada, 0, reposo), 6) for n, (entrada, _, _) in POSES.items()}
os.makedirs(REVISION, exist_ok=True)
sc, cam, sol = estudio(ENCUADRE[1] * 3.1)
sc.cycles.samples = 24
for nombre in TRUCOS:
    entrada, angulo, alto = POSES[nombre]
    posar_huesos(arm, entrada)
    render_pose(nombre, sc, cam, sol, angulo, alto, REVISION)
posar_huesos(arm, {})
datos = {
    "triangulos": sum(len(p.vertices) - 2 for p in malla.data.polygons),
    "huesos": len(arm.data.bones),
    "huesos_que_deforman": sum(b.use_deform for b in arm.data.bones),
    "huesos_del_contrato_que_faltan": sorted(set(CONTRATO) - {b.name for b in arm.data.bones}),
    "colores_en_la_paleta": colores,
    "pesos": revisar_pesos(malla),
    "error_maximo_celdas_por_pose": errores,
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
print("RIG", json.dumps(datos, ensure_ascii=False))
