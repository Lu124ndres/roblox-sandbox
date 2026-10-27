r"""
Hábitat completo de la Orca fantasma (contrato docs/contrato_habitat_completo.md, 2026-10-23,
segunda pasada): un cementerio marino fantasmal en una sola escena, que reemplaza a los props
sueltos de Config.Habitats.byGiant.OrcaFantasma. El cráter es de agua con el fondo de cuenco.
    protagonistas  el barco hundido grande, partido en V, con el casco abierto y dos mástiles
                   caídos que se cruzan (ángulo 205); la ballena colosal, cuya columna se
                   arquea sobre el agua como un puente de costillas desde el pie del
                   acantilado hasta la ladera (28 a 72); el faro hundido y torcido contra el
                   acantilado (125);
    suelo          una lámina de arena oscura y lodo en toda la repisa y la ladera (r 128 a
                   190), con rocas grandes, coral muerto blanco, cadenas, anclas, tablas y redes;
    ladera         costillas gigantes sueltas, rocas y algas pálidas altas hasta la superficie;
    borde          lápidas en hileras inclinadas, faroles en postes torcidos, dos ataúdes, dos
                   calabazas chicas y musgo pálido colgando del acantilado;
    almas          columnas de almas violetas que suben en espiral.
La cría nada en la superficie hasta r ≈ 175: entre r 148 y 182 solo pasan de Y 0 el barco, la
ballena y una columna de almas (el informe del script lo cuenta por sector).

Reusa props de tools/blender/habitats_orcafantasma.py (barco, calabaza, ataúd) y la paleta de
tools/blender/habitats.py, más unos colores nuevos. Mallas (todas con la misma caja, un
cubito mínimo en cada esquina; ninguna pasa de 9.800 triángulos; no chocan):
    OrcaFantasmaHabitat1        el barco, el faro, las calabazas y las cadenas
    OrcaFantasmaHabitat2        la ballena, las costillas sueltas y las anclas
    OrcaFantasmaHabitat3        el suelo de arena y lodo, las rocas y el coral cerebro
    OrcaFantasmaHabitat4        coral muerto de ramas, tablas y redes
    OrcaFantasmaHabitat5        lápidas, faroles y ataúdes
    OrcaFantasmaHabitat6        algas pálidas y musgo
    OrcaFantasmaHabitatBrillo1  Neon cian: faroles, faro, ventanas del barco, cuencas, ataúdes
    OrcaFantasmaHabitatBrillo2  Neon violeta: las almas y las caras de las calabazas
Coordenadas: 1 unidad = 1 stud, origen en el centro del cráter a Y = 0 del mundo, Z de
Blender = Y del mundo (absoluta); un ángulo `a` de Config.Habitats queda en (r·cos a, -r·sin a).
Exporta assets/blender/habitat_orcafantasma/OrcaFantasmaHabitat.fbx (textura embebida),
assets/textures/OrcaFantasmaHabitat_color.png, assets/blender/habitat_orcafantasma/
OrcaFantasmaHabitat.json y los renders en renders/habitat_orcafantasma/.

Uso sin abrir Blender:
    blender -b --factory-startup --python tools/blender/habitat_orcafantasma.py -- exportar render
"""
import bpy, bmesh, json, math, os, random, sys
from mathutils import Vector

V = Vector
AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
RAIZ = os.path.dirname(os.path.dirname(AQUI))
os.environ.setdefault("RAIZ", RAIZ)
import habitats as H  # noqa: E402
import habitat_orcafantasma_escena as E  # noqa: E402

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
ID = "OrcaFantasma"
SALIDA = os.path.join(RAIZ, "assets", "blender", "habitat_orcafantasma")
FBX = os.path.join(SALIDA, ID + "Habitat.fbx")
JSON = os.path.join(SALIDA, ID + "Habitat.json")
H.TEX = os.path.join(RAIZ, "assets", "textures", ID + "Habitat_color.png")
MAX_TRIS = 9800

for nombre, rgb in {"algapalida": (176, 204, 182), "algapalida2": (138, 170, 152), "musgopalido": (156, 176, 158),
                    "rocaf": (50, 48, 62), "rocaf2": (68, 66, 84), "rocaf3": (40, 38, 50),
                    "lodo": (58, 52, 56), "lodo2": (46, 42, 48), "arenaosc": (88, 80, 78), "arenaosc2": (72, 66, 68),
                    "coralm": (232, 228, 216), "coralm2": (198, 194, 182), "red": (150, 138, 108),
                    "red2": (62, 56, 52)}.items():
    H.COLORES[nombre] = rgb
    H.NOMBRES.append(nombre)

BRILLOS = {"Brillo1": (110, 230, 255), "Brillo2": (175, 110, 255)}


def revisar(pts):
    """Zonas prohibidas del contrato: nada desde el paseo (r >= 205), nada sobre Y = 30 en el
    acantilado y nada en el santuario ni en el centro (aquí no hay nada adentro de r 124)."""
    for p in pts:
        r = p.xy.length
        assert r < 204.9, f"entra al paseo: {tuple(p)}"
        assert r < 190 or p.z <= 30.0, f"pasa de Y = 30 en el acantilado: {tuple(p)}"
        assert r >= 124, f"dentro del santuario: {tuple(p)}"
    print("ZONAS ok: r de", round(min(p.xy.length for p in pts), 1), "a", round(max(p.xy.length for p in pts), 1),
          "| Y máx en el acantilado", round(max((p.z for p in pts if p.xy.length >= 190), default=0), 1))


def nado(mallas):
    """Sectores de 10° donde algo pasa de Y 0 entre r 150 y 180 (donde nada la cría)."""
    sectores = {}
    for n, m in mallas.items():
        for v in m.bm.verts:
            r = v.co.xy.length
            if 150 <= r <= 180 and v.co.z > 0:
                a = int((math.degrees(math.atan2(-v.co.y, v.co.x)) % 360) // 10) * 10
                sectores.setdefault(a, set()).add(n.replace(ID + "Habitat", ""))
    print("NADO sobre Y 0 entre r 150 y 180:", {a: sorted(s) for a, s in sorted(sectores.items())})
    return sectores


def objeto(nombre, malla, mat):
    """Como Malla.objeto, pero sin recalcular la normal de las láminas abiertas (suelo, redes),
    que ya miran hacia arriba."""
    bm = malla.bm
    capa = bm.faces.layers.int.get("abierta")
    bmesh.ops.recalc_face_normals(bm, faces=[f for f in bm.faces if not (capa and f[capa])])
    lisos = [f[malla.liso] == 1 for f in bm.faces]
    me = bpy.data.meshes.new(nombre)
    bm.to_mesh(me)
    bm.free()
    for p, liso in zip(me.polygons, lisos):
        p.use_smooth = liso
    if hasattr(me, "set_sharp_from_angle"):
        me.set_sharp_from_angle(angle=math.radians(40))
    o = bpy.data.objects.new(nombre, me)
    o.data.materials.append(mat)
    bpy.context.scene.collection.objects.link(o)
    return o


def construir():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    rnd = random.Random(31)
    nombres = ["Habitat1", "Habitat2", "Habitat3", "Habitat4", "Habitat5", "Habitat6", "HabitatBrillo1", "HabitatBrillo2"]
    mallas = {ID + n: H.Malla(k + 1) for k, n in enumerate(nombres)}
    luces = E.armar(list(mallas.values()), rnd)
    pts = [v.co for m in mallas.values() for v in m.bm.verts]
    revisar(pts)
    sectores = nado(mallas)
    # Caja común, simétrica en X e Y alrededor del eje del cráter.
    a = max(max(abs(p.x), abs(p.y)) for p in pts) + 0.5
    lo = V((-a, -a, min(p.z for p in pts) - 0.5))
    hi = V((a, a, max(p.z for p in pts) + 0.5))
    for m in mallas.values():
        for esquina, sgn in ((lo, 1), (hi, -1)):
            m.caja(H.T(*(esquina + V((0.02, 0.02, 0.02)) * sgn)), (0.04, 0.04, 0.04), "rocaf3")
    mat = H.material()
    mat.name = ID + "Habitat"
    objs = [objeto(n, m, mat) for n, m in mallas.items()]
    tris = {o.name: H.tris(o) for o in objs}
    assert all(t <= MAX_TRIS for t in tris.values()), f"una malla pasa de {MAX_TRIS} triángulos: {tris}"
    return objs, lo, hi, tris, luces, sectores


def exportar(objs, lo, hi, luces):
    os.makedirs(SALIDA, exist_ok=True)
    for x in bpy.data.objects:
        x.select_set(x in objs)
    bpy.ops.export_scene.fbx(filepath=FBX, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
                             path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y",
                             bake_space_transform=True, mesh_smooth_type="OFF", object_types={'MESH'})

    def mundo(p):  # Blender (x, y, z) -> mundo relativo al cráter (dx, y, dz)
        return [round(p.x, 2), round(p.z, 2), round(-p.y, 2)]

    datos = {
        "ancho": round(hi.x - lo.x, 3), "alto": round(hi.z - lo.z, 3), "centroY": round((hi.z + lo.z) / 2, 3),
        "mallas": [{"nombre": o.name, "brillo": next((list(c) for k, c in BRILLOS.items() if o.name.endswith(k)), None)}
                   for o in objs],
        "luces": [{"pos": mundo(p), "color": list(c), "rango": r} for p, c, r in luces],
        "fuegos": [],
    }
    with open(JSON, "w", encoding="utf-8") as f:
        json.dump(datos, f, indent=1, ensure_ascii=False)
        f.write("\n")


OBJS, LO, HI, TRIS, LUCES, _ = construir()
print("HABITAT tris", TRIS, "total", sum(TRIS.values()), "caja", tuple(round(v, 2) for v in LO),
      tuple(round(v, 2) for v in HI), "luces", len(LUCES))
assert len(LUCES) <= 12
if "exportar" in ARGS:
    exportar(OBJS, LO, HI, LUCES)
    print("EXPORTADO", FBX)
if "render" in ARGS:
    import habitat_orcafantasma_vista as VISTA
    VISTA.renders(OBJS, BRILLOS, LUCES, os.path.join(RAIZ, "renders", "habitat_orcafantasma"))
