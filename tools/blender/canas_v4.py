r"""
Cañas v4 (íconos de la tienda llevados a 3D): una malla por nivel, detallada y redondeada,
con el color de cada pieza en su material (sin textura). Piloto: la caña 24 (del dragón).

Medidas en studs (1 unidad de Blender = 1 stud). La caña apunta a +Y: el mango en el
origen y la punta en y = LARGO. Más larga que la de primitivas (9.5): pedido del usuario,
"más grandes y llamativas".

Uso (consola):
    "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b -P tools\blender\canas_v4.py -- 24
Deja renders/canas_v4/<nivel>_*.png y assets/blender/canas_v4/Cana<nivel>.fbx.
"""
import bpy, bmesh, math, os, sys
from mathutils import Vector as V, Matrix

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
LARGO = 10.5  # punta de la vara
SEGS = 14  # lados de los cilindros (pocos triángulos: la lleva cada jugador)


# ---------- materiales ----------
def mat(nombre, rgb, metal=0.0, rugoso=0.5, brillo=0.0):
    m = bpy.data.materials.get(nombre) or bpy.data.materials.new(nombre)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    # Los colores de los íconos están en sRGB; Blender trabaja en lineal.
    col = tuple(((c / 255) / 12.92) if c / 255 <= 0.04045 else (((c / 255) + 0.055) / 1.055) ** 2.4 for c in rgb) + (1,)
    b.inputs["Base Color"].default_value = col
    b.inputs["Metallic"].default_value = metal
    b.inputs["Roughness"].default_value = rugoso
    if brillo > 0:
        b.inputs["Emission Color"].default_value = col
        b.inputs["Emission Strength"].default_value = brillo
    return m


def poner(obj, m):
    obj.data.materials.clear()
    obj.data.materials.append(m)
    return obj


# ---------- formas ----------
def malla(nombre, bm):
    me = bpy.data.meshes.new(nombre)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(nombre, me)
    bpy.context.collection.objects.link(ob)
    return ob


def tubo(nombre, puntos, radios, segs=SEGS, tapas=True):
    """Tubo que sigue una línea de puntos con un radio en cada punto."""
    bm = bmesh.new()
    anillos = []
    for i, (p, r) in enumerate(zip(puntos, radios)):
        a = puntos[min(i + 1, len(puntos) - 1)] - puntos[max(i - 1, 0)]
        d = a.normalized()
        ref = V((0, 0, 1)) if abs(d.z) < 0.9 else V((1, 0, 0))
        u = d.cross(ref).normalized()
        w = d.cross(u).normalized()
        anillos.append([bm.verts.new(p + (u * math.cos(t) + w * math.sin(t)) * r)
                        for t in (2 * math.pi * k / segs for k in range(segs))])
    for a, b in zip(anillos, anillos[1:]):
        for k in range(segs):
            bm.faces.new((a[k], a[(k + 1) % segs], b[(k + 1) % segs], b[k]))
    if tapas:
        bm.faces.new(list(reversed(anillos[0])))
        bm.faces.new(anillos[-1])
    ob = malla(nombre, bm)
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def bola(nombre, centro, radios, sub=2):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=1)
    for v in bm.verts:
        v.co = V((v.co.x * radios[0], v.co.y * radios[1], v.co.z * radios[2])) + centro
    ob = malla(nombre, bm)
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def cono(nombre, base, punta, r, segs=8):
    return tubo(nombre, [base, base.lerp(punta, 0.5), punta], [r, r * 0.55, 0.01], segs)


def aro(nombre, centro, eje, r, grosor, segs=20, lados=6):
    """Toro: anillas, bandas y el plato del carrete."""
    bm = bmesh.new()
    eje = eje.normalized()
    ref = V((0, 0, 1)) if abs(eje.z) < 0.9 else V((1, 0, 0))
    u = eje.cross(ref).normalized()
    w = eje.cross(u).normalized()
    anillos = []
    for i in range(segs):
        t = 2 * math.pi * i / segs
        c = centro + (u * math.cos(t) + w * math.sin(t)) * r
        radial = (c - centro).normalized()
        anillos.append([bm.verts.new(c + (radial * math.cos(s) + eje * math.sin(s)) * grosor)
                        for s in (2 * math.pi * k / lados for k in range(lados))])
    for i in range(segs):
        a, b = anillos[i], anillos[(i + 1) % segs]
        for k in range(lados):
            bm.faces.new((a[k], a[(k + 1) % lados], b[(k + 1) % lados], b[k]))
    ob = malla(nombre, bm)
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def curva(p0, p1, p2, n):
    """Bezier cuadrática de n puntos."""
    return [p0 * (1 - t) ** 2 + p1 * 2 * (1 - t) * t + p2 * t * t for t in (i / (n - 1) for i in range(n))]


# ---------- la vara ----------
def eje_vara(t):
    """Punto de la vara a la altura t (0..1): se curva un poco hacia +X en la punta."""
    return V((0.35 * t ** 2.2, LARGO * t, 0))


def radio_vara(t, grueso=0.42, fino=0.1):
    return grueso + (fino - grueso) * t ** 0.8


# ---------- caña 24: del dragón ----------
def cana_dragon():
    rojo = mat("Rojo", (178, 34, 22), rugoso=0.45)
    escama = mat("RojoOscuro", (110, 18, 12), rugoso=0.4)
    oro = mat("Oro", (222, 166, 52), metal=1.0, rugoso=0.3)
    hueso = mat("Cuerno", (238, 214, 160), rugoso=0.6)
    ojo = mat("Ojo", (255, 214, 40), brillo=4.0)
    fuego = mat("Fuego", (255, 120, 20), brillo=3.0)
    hilo = mat("Hilo", (220, 200, 160), rugoso=0.8)
    piezas = []

    # Vara con escamas: anillos de escamas que sobresalen un poco, cada 0.35.
    n = 40
    pts = [eje_vara(i / (n - 1)) for i in range(n)]
    piezas.append(poner(tubo("Vara", pts, [radio_vara(i / (n - 1)) for i in range(n)]), rojo))
    t = 0.06
    while t < 0.93:
        c, r = eje_vara(t), radio_vara(t)
        d = (eje_vara(t + 0.01) - c).normalized()
        piezas.append(poner(tubo(f"Escama{t:.2f}", [c - d * 0.12, c + d * 0.05, c + d * 0.13],
                                 [r * 1.0, r * 1.18, r * 1.0], segs=10, tapas=False), escama))
        t += 0.35 / LARGO
    # Bandas de oro en las uniones y anillas.
    for tb in (0.18, 0.42, 0.64, 0.84):
        c = eje_vara(tb)
        d = (eje_vara(tb + 0.01) - c).normalized()
        piezas.append(poner(aro(f"Banda{tb}", c, d, radio_vara(tb) * 1.12, radio_vara(tb) * 0.22), oro))
    for ta in (0.3, 0.52, 0.72, 0.9, 0.99):
        c = eje_vara(ta)
        d = (eje_vara(ta + 0.01) - c).normalized()
        r = radio_vara(ta)
        pie = c + V((r + 0.12, 0, 0))
        piezas.append(poner(tubo(f"Pata{ta}", [c, pie], [0.03, 0.03], segs=6), oro))
        piezas.append(poner(aro(f"Anilla{ta}", pie + V((0.12, 0, 0)), d, 0.12, 0.025, segs=12, lados=5), oro))

    # Cabeza de dragón en la contera: mira hacia -Y (abajo del mango), hocico largo y
    # anguloso, ceño marcado, cuernos de oro que barren hacia atrás y la boca entreabierta.
    cab = V((0, -0.75, 0))
    piezas.append(poner(bola("Craneo", cab, (0.5, 0.55, 0.42)), rojo))
    piezas.append(poner(tubo("Hocico", [cab + V((0, -0.2, 0.05)), cab + V((0, -0.75, 0.0)), cab + V((0, -1.15, -0.05))],
                             [0.36, 0.27, 0.16], segs=10), rojo))
    piezas.append(poner(tubo("Mandibula", [cab + V((0, -0.1, -0.22)), cab + V((0, -0.65, -0.32)), cab + V((0, -1.0, -0.36))],
                             [0.28, 0.19, 0.1], segs=10), escama))
    for lado in (-1, 1):
        piezas.append(poner(bola(f"Ojo{lado}", cab + V((lado * 0.3, -0.38, 0.2)), (0.07, 0.13, 0.05), 1), ojo))
        ceja = [cab + V((lado * 0.18, -0.6, 0.27)), cab + V((lado * 0.36, -0.3, 0.36)), cab + V((lado * 0.42, 0.0, 0.42))]
        piezas.append(poner(tubo(f"Ceja{lado}", ceja, [0.05, 0.09, 0.05], segs=6), escama))
        cuerno = curva(cab + V((lado * 0.3, -0.05, 0.3)), cab + V((lado * 0.55, 0.45, 0.7)),
                       cab + V((lado * 0.35, 1.25, 0.55)), 8)
        piezas.append(poner(tubo(f"Cuerno{lado}", cuerno, [0.14, 0.13, 0.11, 0.09, 0.07, 0.05, 0.03, 0.005], segs=8), oro))
        for k in range(3):  # aletas de la gola
            base = cab + V((lado * 0.42, 0.05 + k * 0.2, -0.08 - k * 0.05))
            piezas.append(poner(cono(f"Gola{lado}{k}", base, base + V((lado * 0.45, 0.3, -0.1)), 0.09), escama))
        piezas.append(poner(bola(f"Narina{lado}", cab + V((lado * 0.09, -1.12, 0.06)), (0.045, 0.05, 0.035), 1), escama))
        for k in range(3):  # colmillos
            base = cab + V((lado * (0.1 + k * 0.05), -0.95 + k * 0.18, -0.12))
            piezas.append(poner(cono(f"Diente{lado}{k}", base, base + V((0, 0, -0.17)), 0.035, segs=5), hueso))
    for k in range(5):  # cresta de oro sobre la cabeza y el cuello
        base = cab + V((0, -0.15 + k * 0.3, 0.38 - k * 0.03))
        piezas.append(poner(cono(f"Cresta{k}", base, base + V((0, 0.2, 0.3 - k * 0.03)), 0.08, segs=6), oro))

    # Carrete de oro: plato con rayos, bobina y manivela.
    rc = eje_vara(0.12) + V((0.7, 0, 0))
    eje = V((1, 0, 0))
    piezas.append(poner(tubo("PieCarrete", [eje_vara(0.12) + V((0.3, 0, 0)), rc - V((0.12, 0, 0))], [0.1, 0.1], segs=8), oro))
    piezas.append(poner(aro("Plato", rc, eje, 0.55, 0.09), oro))
    piezas.append(poner(tubo("Bobina", [rc - V((0.12, 0, 0)), rc + V((0.12, 0, 0))], [0.24, 0.24]), escama))
    for k in range(6):
        a = 2 * math.pi * k / 6
        p = rc + V((0.05, math.cos(a) * 0.52, math.sin(a) * 0.52))
        piezas.append(poner(tubo(f"Rayo{k}", [rc + V((0.05, 0, 0)), p], [0.035, 0.035], segs=6), oro))
    piezas.append(poner(bola("Centro", rc + V((0.1, 0, 0)), (0.1, 0.1, 0.1), 1), fuego))
    man = rc + V((0.2, 0, 0))
    piezas.append(poner(tubo("Manivela", [man, man + V((0, -0.05, -0.5))], [0.04, 0.04], segs=6), oro))
    piezas.append(poner(tubo("Perilla", [man + V((0, -0.05, -0.5)), man + V((0.25, -0.05, -0.5))], [0.08, 0.08], segs=8), escama))

    # Hilo y anzuelo-garra en llamas.
    punta = eje_vara(0.99) + V((0.24, 0, 0))
    gancho = punta + V((0.15, -2.4, 0))
    piezas.append(poner(tubo("Hilo", [punta, gancho], [0.012, 0.012], segs=4), hilo))
    garra = curva(gancho, gancho + V((0.05, -1.05, 0)), gancho + V((0.75, -0.8, 0)), 8)
    garra += curva(garra[-1], garra[-1] + V((0.25, 0.15, 0)), garra[-1] + V((0.12, 0.6, 0)), 5)[1:]
    radios = [0.1 + 0.05 * math.sin(math.pi * i / (len(garra) - 1)) for i in range(len(garra))]
    radios[-1] = 0.005
    piezas.append(poner(tubo("Garra", garra, radios, segs=8), rojo))
    piezas.append(poner(aro("Ojal", gancho + V((0, 0.05, 0)), V((0, 0, 1)), 0.08, 0.025, segs=10, lados=5), oro))
    for k in range(3):  # llamitas en el anzuelo
        base = garra[3 + k * 2]
        piezas.append(poner(cono(f"Llama{k}", base, base + V((-0.2 + 0.12 * k, -0.45, 0.05)), 0.09, segs=6), fuego))
    return piezas


CANAS = {24: cana_dragon}


# ---------- escena, render y exportación ----------
def limpiar():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def unir(nombre, piezas):
    bpy.ops.object.select_all(action="DESELECT")
    for p in piezas:
        p.select_set(True)
    bpy.context.view_layer.objects.active = piezas[0]
    bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    ob.name = nombre
    return ob


def camara(nombre, pos, mira, ortho=None):
    cam = bpy.data.cameras.new(nombre)
    if ortho:
        cam.type = "ORTHO"
        cam.ortho_scale = ortho
    ob = bpy.data.objects.new(nombre, cam)
    bpy.context.collection.objects.link(ob)
    ob.location = pos
    ob.rotation_euler = (V(mira) - V(pos)).to_track_quat("-Z", "Y").to_euler()
    return ob


def escena_render():
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.resolution_x = sc.render.resolution_y = 900
    sc.render.film_transparent = False
    w = bpy.data.worlds.new("Mundo")
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (0.16, 0.13, 0.16, 1)
    w.node_tree.nodes["Background"].inputs[1].default_value = 0.6
    sc.world = w
    for nombre, rot, energia in (("Sol", (0.9, 0.2, 0.6), 4.0), ("Relleno", (1.2, 0, -2.4), 1.5)):
        luz = bpy.data.lights.new(nombre, "SUN")
        luz.energy = energia
        ob = bpy.data.objects.new(nombre, luz)
        bpy.context.collection.objects.link(ob)
        ob.rotation_euler = rot
    sc.view_settings.view_transform = "Standard"


def render(ruta, cam):
    sc = bpy.context.scene
    sc.camera = cam
    sc.render.filepath = ruta
    bpy.ops.render.render(write_still=True)


def separar(ob):
    """Una pieza por material (Roblox no guarda colores por cara en una MeshPart) y un cubito
    "<nombre>_Origen" en el origen, para saber dónde va el mango o el punto de la espalda.
    Devuelve las piezas y {material: (r, g, b, metal, brillo)} para pintarlas en Studio."""
    nombre = ob.name
    colores = {}
    for m in ob.data.materials:
        b = m.node_tree.nodes["Principled BSDF"]
        lin = b.inputs["Base Color"].default_value
        srgb = [round(255 * (c * 12.92 if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055)) for c in lin[:3]]
        colores[m.name] = srgb + [round(b.inputs["Metallic"].default_value, 2), round(b.inputs["Emission Strength"].default_value, 2)]
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.separate(type="MATERIAL")
    bpy.ops.object.mode_set(mode="OBJECT")
    piezas = [o for o in bpy.context.selected_objects]
    for o in piezas:
        o.name = f"{nombre}_{o.data.materials[0].name}"
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=0.05)
    piezas.append(malla(f"{nombre}_Origen", bm))
    return piezas, colores


def exportar(ruta, piezas):
    bpy.ops.object.select_all(action="DESELECT")
    for o in piezas:
        o.select_set(True)
    bpy.ops.export_scene.fbx(filepath=ruta, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
                             axis_forward="-Z", axis_up="Y")


def tris(ob):
    return sum(len(p.vertices) - 2 for p in ob.data.polygons)


def hacer(nivel):
    limpiar()
    piezas = CANAS[nivel]()
    ob = unir(f"Cana{nivel:02d}", piezas)
    escena_render()
    salida = os.path.join(RAIZ, "renders", "canas_v4")
    os.makedirs(salida, exist_ok=True)
    centro = V((0.3, LARGO / 2 - 1.5, 0))
    render(os.path.join(salida, f"{nivel:02d}_lado.png"), camara("Lado", centro + V((0, 0, 20)), centro, ortho=16))
    render(os.path.join(salida, f"{nivel:02d}_tres_cuartos.png"),
           camara("TresCuartos", centro + V((9, -6, 9)), centro, ortho=15))
    cab = V((0, -1.0, 0))
    render(os.path.join(salida, f"{nivel:02d}_cabeza.png"), camara("Cabeza", cab + V((3, -3, 2.2)), cab + V((0, 0.4, 0)), ortho=4))
    fbx = os.path.join(RAIZ, "assets", "blender", "canas_v4")
    os.makedirs(fbx, exist_ok=True)
    cuenta = tris(ob)
    piezas, colores = separar(ob)
    exportar(os.path.join(fbx, f"Cana{nivel:02d}.fbx"), piezas)
    print(f"LISTO cana {nivel}: {cuenta} triángulos, colores {colores}")


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else ["24"]
    for a in args:
        hacer(int(a))
