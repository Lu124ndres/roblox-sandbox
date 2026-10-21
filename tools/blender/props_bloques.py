r"""
Props del mapa en estilo de bloques, como las fotos del juego y los gigantes v2: bloques
biselados de un segmento sobre una cuadrícula, la cara de arriba más clara que los lados y
colores saturados. Misma idea que props_mapa.py: una sola textura de paleta (cada cara pinta
un cuadrito de color), el origen en el centro de la base y los mismos nombres, así
server/World/PropDresser los pone en el mapa igual que a los de ahora:
    Palmera1..3   tronco con anillos que se curva, copa y diez hojas que caen, cocos
    Arbusto1..2   matas de cubos con flores
    Roca1..3      piedras de bloques apilados (la 3 con musgo, la 2 chata)
    Cresta1..2    picos de basalto escalonados del volcán con vetas de lava
Las formas están en props_bloques_formas.py y el render de revisión en props_bloques_vista.py.
Saca dos renders con la misma fila: los de ahora (PropsMapa.fbx) y los nuevos. Todavía no
exporta: primero el usuario aprueba el estilo.

Uso (desde la raíz del repo):
    blender -b --factory-startup --python tools/blender/props_bloques.py
Salidas: assets/blender/props_v2/props_bloques.blend, assets/textures/PropsBloques_color.png,
renders/props_v2/antes.png, despues.png y cerca.png (cuatro de cerca).
"""
import bpy, bmesh, math, os
from mathutils import Vector as V, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.normpath(os.path.join(HERE, "..", ".."))
BLEND = os.path.join(RAIZ, "assets", "blender", "props_v2", "props_bloques.blend")
TEX = os.path.join(RAIZ, "assets", "textures", "PropsBloques_color.png")
RENDERS = os.path.join(RAIZ, "renders", "props_v2")
ACTUALES = os.path.join(RAIZ, "assets", "blender", "PropsMapa.fbx")

CELDA = 0.5  # BU por celda: todo bloque mide celdas enteras
BISEL = 0.12 * CELDA

# --- Paleta (sRGB): cada color con su tono de arriba, de lado y de abajo ----------------
COLORES = {
    "tronco": ((186, 132, 80), (146, 98, 58), (104, 70, 42)),
    "tronco2": ((158, 108, 64), (122, 80, 46), (90, 60, 36)),
    "hoja": ((112, 206, 78), (66, 158, 60), (44, 118, 50)),
    "hoja2": ((88, 184, 70), (52, 136, 54), (36, 100, 46)),
    "coco": ((132, 90, 52), (104, 70, 40), (78, 52, 30)),
    "roca": ((176, 170, 160), (132, 126, 118), (98, 94, 90)),
    "roca2": ((150, 144, 136), (112, 108, 102), (84, 80, 78)),
    "musgo": ((116, 184, 80), (84, 146, 64), (60, 110, 50)),
    "mata": ((92, 190, 70), (58, 146, 58), (40, 108, 46)),
    "mata2": ((76, 170, 64), (48, 128, 52), (34, 96, 42)),
    "mata3": ((122, 204, 84), (84, 160, 66), (58, 120, 52)),
    "flor": ((255, 132, 168), (226, 100, 140), (180, 76, 110)),
    "flor2": ((255, 216, 92), (232, 180, 60), (190, 140, 40)),
    "flor3": ((252, 250, 255), (220, 220, 232), (180, 180, 196)),
    "basalto": ((84, 74, 82), (54, 48, 58), (36, 32, 40)),
    "basalto2": ((68, 60, 70), (44, 40, 48), (30, 28, 34)),
    "lava": ((255, 196, 70), (255, 132, 36), (220, 84, 24)),
}
LADOS = ("arriba", "lado", "abajo")
NOMBRES = [f"{c}_{l}" for c in COLORES for l in LADOS]
PX, POR_FILA = 32, 8


def paleta():
    lado = PX * POR_FILA
    img = bpy.data.images.new("PropsBloques_color", lado, lado)
    px = [0.0] * (lado * lado * 4)
    for i, nombre in enumerate(NOMBRES):
        color, cara = nombre.rsplit("_", 1)
        r, g, b = (c / 255 for c in COLORES[color][LADOS.index(cara)])
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


def uv_de(nombre):
    i = NOMBRES.index(nombre)
    return V((((i % POR_FILA) + 0.5) / POR_FILA, ((i // POR_FILA) + 0.5) / POR_FILA))


def caja(bm, color, centro, medida, giro=0.0, inclina=0.0, centrado=False, bisel=BISEL):
    """Un bloque biselado de `medida` celdas (x ancho, y largo, z grueso). Con la base en
    `centro` (o el centro, con centrado). giro: grados sobre z (el largo apunta a giro + 90);
    inclina: grados que sube la punta del largo (las hojas que caen van con inclina < 0)."""
    tam = V(medida) * CELDA
    nuevo = bmesh.new()
    bmesh.ops.create_cube(nuevo, size=1.0)
    bmesh.ops.scale(nuevo, vec=tam, verts=nuevo.verts)
    if not centrado:
        bmesh.ops.translate(nuevo, vec=V((0, 0, tam.z / 2)), verts=nuevo.verts)
    if bisel > 0:  # las piezas chicas van sin bisel: pesan la cuarta parte
        bmesh.ops.bevel(nuevo, geom=nuevo.edges[:], offset=bisel, segments=1, affect="EDGES")
    giro_m = Matrix.Rotation(math.radians(giro), 4, "Z") @ Matrix.Rotation(math.radians(inclina), 4, "X")
    bmesh.ops.transform(nuevo, matrix=Matrix.Translation(V(centro)) @ giro_m, verts=nuevo.verts)
    uv = nuevo.loops.layers.uv.verify()
    nuevo.normal_update()
    for cara in nuevo.faces:
        z = cara.normal.z
        lado = "arriba" if z > 0.6 else "abajo" if z < -0.6 else "lado"
        punto = uv_de(f"{color}_{lado}")
        for l in cara.loops:
            l[uv].uv = punto
    datos = bpy.data.meshes.new("tmp")
    nuevo.to_mesh(datos)
    nuevo.free()
    bm.from_mesh(datos)
    bpy.data.meshes.remove(datos)


def objeto(nombre, bm, material):
    malla = bpy.data.meshes.new(nombre)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0001)
    bm.normal_update()
    bm.to_mesh(malla)
    bm.free()
    for p in malla.polygons:
        p.use_smooth = False  # bloques: caras planas
    o = bpy.data.objects.new(nombre, malla)
    o.data.materials.append(material)
    bpy.context.scene.collection.objects.link(o)
    return o


def material(img):
    mat = bpy.data.materials.new("PropsBloques")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.85
    return mat


exec(open(os.path.join(HERE, "props_bloques_formas.py"), encoding="utf-8").read(), globals())
exec(open(os.path.join(HERE, "props_bloques_vista.py"), encoding="utf-8").read(), globals())

# Nombre -> forma. Mismos nombres que PropsMapa (los que el mapa usa hoy).
PROPS = {
    "Palmera1": lambda: palmera(40, segmentos=10, inclina=2.6),
    "Palmera2": lambda: palmera(41, segmentos=9, inclina=3.8),
    "Palmera3": lambda: palmera(42, segmentos=11, inclina=1.4),
    "Arbusto1": lambda: arbusto(5),
    "Arbusto2": lambda: arbusto(9),
    "Roca1": lambda: roca(3),
    "Roca2": lambda: roca(17, chata=True),
    "Roca3": lambda: roca(23, musgo=True),
    "Cresta1": lambda: cresta(7, pisos=9),
    "Cresta2": lambda: cresta(31, pisos=7),
}


def actuales():
    """Los props de ahora (PropsMapa.fbx), en el mismo orden que PROPS."""
    antes = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=ACTUALES)
    por_nombre = {}
    for o in [o for o in bpy.data.objects if o not in antes]:
        nombre = o.name.split(".")[0]
        if o.type == "MESH" and nombre in PROPS:
            o.parent = None
            por_nombre[nombre] = o
        else:
            bpy.data.objects.remove(o)
    return [por_nombre[n] for n in PROPS if n in por_nombre]


def main():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    os.makedirs(RENDERS, exist_ok=True)
    viejos = actuales() if os.path.exists(ACTUALES) else []
    if viejos:
        en_fila(viejos)
        render(viejos, os.path.join(RENDERS, "antes.png"))
        for o in viejos:
            bpy.data.objects.remove(o)
    mat = material(paleta())
    nuevos = [objeto(nombre, forma(), mat) for nombre, forma in PROPS.items()]
    en_fila(nuevos)
    render(nuevos, os.path.join(RENDERS, "despues.png"))
    cerca = [o for o in nuevos if o.name in ("Palmera1", "Arbusto1", "Roca3", "Cresta1")]
    for o in nuevos:
        o.hide_render = o not in cerca
    en_fila(cerca)
    render(cerca, os.path.join(RENDERS, "cerca.png"))
    for o in nuevos:
        o.hide_render = False
    os.makedirs(os.path.dirname(BLEND), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=BLEND)
    print("TRIS", {o.name: sum(len(p.vertices) - 2 for p in o.data.polygons) for o in nuevos})


main()
