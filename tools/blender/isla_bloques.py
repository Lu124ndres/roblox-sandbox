r"""
Suelo de la isla principal en bloques, como las fotos del juego (opción 3: el terreno liso
de Roblox pasa a mallas de bloques). Solo la isla: el volcán es otro modelo, con el mismo
módulo (columnas de 4 x 4 studs, escalones de 2) y el mismo acabado.
    isla_bloques_forma.py    la forma: la misma del terreno del juego (alturas y materiales)
    isla_bloques_relieve.py  lomas suaves y acantilados bajos, con las zonas de juego planas
    isla_bloques_jardin.py   senderos elevados, pozo de cada estanque y ondulaciones del pasto
    isla_bloques_monticulos.py  montículos de pasto alrededor de cada estanque
    isla_bloques_malla.py    columnas, bisel, caras de arriba en rectángulos y lados en tiras
    isla_bloques_aros.py     aro de piedras de cada estanque y su lámina
    isla_bloques_rampas.py   rampas de entrada a los senderos elevados
    isla_bloques_vistas.py   mar de mentira, luz, cámara y renders
Una sola textura de paleta, como props_mapa.py y props_bloques.py. Objetos:
    IslaSector_<x>_<z>  terreno en sectores de 128 x 128 studs (cada uno, una MeshPart)
    AroEstanque_<n>     piedras, matas y tierra del estanque n (va como prop/MeshPart)
    RampaSendero_<ang>  rampa de la salida del sendero en ese ángulo
    MatasMonticulos     matas de hojas sueltas sobre algunos montículos
    Lamina_<n>          la superficie del agua del estanque n, de su color (UIConfig/Ponds)
Ejes: 1 BU = 1 stud; Blender (x, y, z) = Roblox (X, -Z, Y), como exporta props_mapa.py
(axis_forward -Z, axis_up Y). Todavía no exporta: primero se aprueba.

Uso (desde la raíz del repo):
    blender -b --factory-startup --python tools/blender/isla_bloques.py -- \
        [--datos src/shared/WorldLayoutData.json] [--mundo world/Isla.model.json] \
        [--colores src/shared/UIConfig/Ponds.luau]
Salidas: assets/blender/isla_v2/isla_bloques_4g.blend, assets/textures/IslaBloques_color.png
y renders/isla_v2g/*.png.
"""
import bpy, math, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.normpath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
import isla_bloques_aros as A
import isla_bloques_forma as F
import isla_bloques_jardin as J
import isla_bloques_malla as M
import isla_bloques_monticulos as MO
import isla_bloques_rampas as RA
import isla_bloques_relieve as R
import isla_bloques_vistas as VI

ARGS = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []


def argumento(nombre, por_defecto):
    return ARGS[ARGS.index(nombre) + 1] if nombre in ARGS else por_defecto


DATOS = argumento("--datos", os.path.join(RAIZ, "src", "shared", "WorldLayoutData.json"))
MUNDO = argumento("--mundo", os.path.join(RAIZ, "world", "Isla.model.json"))
COLORES_ESTANQUE = argumento("--colores", os.path.join(RAIZ, "src", "shared", "UIConfig", "Ponds.luau"))
BLEND = os.path.join(RAIZ, "assets", "blender", "isla_v2", "isla_bloques_4g.blend")
TEX = os.path.join(RAIZ, "assets", "textures", "IslaBloques_color.png")
RENDERS = os.path.join(RAIZ, "renders", "isla_v2g")

# Paleta (sRGB): tres tonos de arriba, el canto (bisel y franja) y el lado.
COLORES = {
    "pasto": ((96, 184, 62), (106, 196, 68), (86, 170, 56), (70, 146, 50), (150, 104, 64)),
    "jardin": ((92, 178, 58), (102, 190, 64), (82, 164, 52), (66, 140, 48), (150, 104, 64)),
    "arena": ((238, 206, 140), (246, 216, 152), (228, 194, 128), (212, 178, 116), (204, 168, 108)),
    "mojada": ((206, 172, 114), (214, 180, 120), (196, 162, 106), (184, 150, 96), (174, 142, 92)),
    "camino": ((152, 144, 132), (164, 156, 142), (140, 132, 122), (124, 118, 108), (112, 106, 98)),
    # Senderos elevados del jardín: arriba la arena de siempre, el canto y el lado de piedra.
    "sendero": ((238, 206, 140), (246, 216, 152), (228, 194, 128), (150, 142, 130), (124, 118, 108)),
    "barro": ((122, 98, 68), (130, 106, 74), (112, 90, 62), (100, 80, 56), (90, 72, 50)),
    "roca": ((152, 146, 136), (162, 156, 144), (140, 134, 126), (122, 116, 108), (110, 104, 98)),
    # Aro de los estanques.
    "piedra": ((222, 206, 176), (232, 216, 186), (210, 194, 164), (182, 166, 140), (154, 140, 118)),
    "piedra2": ((204, 188, 160), (214, 198, 170), (192, 176, 150), (166, 152, 128), (140, 128, 108)),
    "tierra": ((74, 54, 38), (80, 60, 42), (68, 50, 34), (62, 46, 32), (56, 42, 30)),
    "hoja": ((112, 206, 78), (120, 214, 84), (104, 196, 72), (66, 158, 60), (44, 118, 50)),
    "hoja2": ((88, 184, 70), (96, 192, 76), (80, 174, 64), (52, 136, 54), (36, 100, 46)),
}
TONOS = ("arriba0", "arriba1", "arriba2", "canto", "lado")
NOMBRES = [f"{m}_{t}" for m in COLORES for t in TONOS]
PX, POR_FILA = 32, 16  # 512 x 512: entran hasta 256 colores


def paleta():
    lado = PX * POR_FILA
    img = bpy.data.images.new("IslaBloques_color", lado, lado)
    px = [0.0] * (lado * lado * 4)
    for i, nombre in enumerate(NOMBRES):
        material, tono = nombre.rsplit("_", 1)
        r, g, b = (c / 255 for c in COLORES[material][TONOS.index(tono)])
        cx, cy = (i % POR_FILA) * PX, (i // POR_FILA) * PX
        for y in range(cy, cy + PX):
            for x in range(cx, cx + PX):
                k = (y * lado + x) * 4
                px[k : k + 4] = [r, g, b, 1.0]
    img.pixels = px
    img.filepath_raw = TEX
    img.file_format = "PNG"
    os.makedirs(os.path.dirname(TEX), exist_ok=True)
    img.save()
    return img


def material(img):
    mat = bpy.data.materials.new("IslaBloques")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.9
    return mat


def malla(nombre, lista, mat):
    verts, faces, colores = [], [], []
    for poligono, color, normal in lista:
        base = len(verts)
        verts.extend((x, -z, y) for x, y, z in M.orientar(poligono, normal))  # Roblox -> Blender
        faces.append(tuple(range(base, base + len(poligono))))
        colores.append(color)
    me = bpy.data.meshes.new(nombre)
    me.from_pydata(verts, [], faces)
    uv = me.uv_layers.new(name="UVMap")
    for poly, color in zip(me.polygons, colores):
        i = NOMBRES.index(color) if color in NOMBRES else 0
        punto = (((i % POR_FILA) + 0.5) / POR_FILA, ((i // POR_FILA) + 0.5) / POR_FILA)
        for k in poly.loop_indices:
            uv.data[k].uv = punto
        poly.use_smooth = False
    me.update()
    o = bpy.data.objects.new(nombre, me)
    o.data.materials.append(mat)
    bpy.context.scene.collection.objects.link(o)
    return sum(len(p) - 2 for p, _, _ in lista)


def colores_estanque():
    """Los Color3.fromRGB de Ponds.Colors, en orden (el 11 es el sagrado)."""
    with open(COLORES_ESTANQUE, encoding="utf-8") as f:
        texto = f.read()
    bloque = texto[texto.index("Colors") : texto.index("Names")]
    return [tuple(int(v) / 255 for v in m) for m in re.findall(r"fromRGB\((\d+),\s*(\d+),\s*(\d+)\)", bloque)]


def lamina_material(indice, color):
    mat = bpy.data.materials.new(f"Lamina_{indice}")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Alpha"].default_value = 0.72
    bsdf.inputs["Roughness"].default_value = 0.1
    if hasattr(mat, "surface_render_method"):
        mat.surface_render_method = "BLENDED"
    return mat


def alzar(i, j, x, z, alto, material):
    return J.ondular(i, j, x, z, alto, material) if J.dentro(x, z) else R.alzar(i, j, x, z, alto, material)


def main():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    F.cargar(DATOS)
    n = math.ceil(F.alcance() / M.CELDA)
    R.preparar(MUNDO, M.CELDA, n)
    MO.preparar(MUNDO, M.CELDA, n)
    J.preparar(MUNDO, M.CELDA, n)
    piso = F.L["seaFloorHeight"]
    alto, mat, ton, base = M.columnas(F.muestra, alzar, n, F.L["waterLevel"], piso, J.elevar)
    paleta_mat = material(paleta())
    terreno = {f"IslaSector_{sx}_{sz}": malla(f"IslaSector_{sx}_{sz}", lista, paleta_mat)
               for (sx, sz), lista in sorted(M.caras(alto, mat, ton, piso).items())}
    aros = {f"AroEstanque_{k}": malla(f"AroEstanque_{k}", caras, paleta_mat) for k, caras in A.aros().items()}
    rampas = {k: malla(k, caras, paleta_mat) for k, caras in RA.rampas(alto, mat, M.CELDA, M.BISEL).items()}
    matas = []
    for k, (x, y, z) in enumerate(MO.MATAS):
        A._mata(matas, A.random.Random(k), x, y - 0.1, z, 1.0)
    tris_matas = malla("MatasMonticulos", matas, paleta_mat)
    tonos = colores_estanque()
    for indice, puntos in A.laminas().items():
        malla(f"Lamina_{indice}", [(tuple(puntos), "", (0, 1, 0))], lamina_material(indice, tonos[indice - 1]))
    VI.renders(VI.escena(F), F, M, alto, RENDERS)
    os.makedirs(os.path.dirname(BLEND), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=BLEND)
    print("TERRENO", sum(terreno.values()), "MAX", max(terreno.values()), "SECTORES", len(terreno))
    print("AROS", sum(aros.values()), aros)
    print("RAMPAS", sum(rampas.values()), rampas)
    print("MONTICULOS", len(MO.MONTICULO), "MATAS", len(MO.MATAS), tris_matas)


main()
