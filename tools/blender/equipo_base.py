r"""
Piezas 3D del equipo (sin textura: el juego les pone color y material), para que la
caña de la mano y la canasta de la espalda se vean redondeadas en vez de bloques:
    MangoCorcho     mango de corcho con anillos marcados y puntas redondeadas
    CarreteBobina   bobina del carrete con el hilo enrollado en vueltas
    CarretePlato    plato lateral del carrete con agujeros (rayos)
    Anilla          anilla (guía) de la caña: aro con su pata
    CajaRedondeada  caja con bordes biselados (cuerpo y borde de las canastas)
Todas miden 1 x 1 x 1 y su eje largo es X (como los cilindros de Roblox), centradas en el
origen. Exporta assets/blender/EquipoBase.fbx; en Studio van a ReplicatedStorage.ModelosEquipo
y client/Effects/MeshKit las usa en lugar de las piezas de primitivas.
Uso desde el MCP de Blender:  RAIZ = r"C:\...\JuegoRoblox"; exec(open(RAIZ + r"\tools\blender\equipo_base.py").read())
"""
import bpy, bmesh, math, os
from mathutils import Vector as V, Matrix

FBX = os.path.join(RAIZ, "assets", "blender", "EquipoBase.fbx")

def revolver(perfil, segs, nombre):
    """Gira un perfil [(x, radio)] alrededor del eje X."""
    bm = bmesh.new()
    anillos = []
    for x, r in perfil:
        anillos.append([bm.verts.new(V((x, math.cos(2 * math.pi * k / segs) * r, math.sin(2 * math.pi * k / segs) * r)))
                        for k in range(segs)])
    for a, b in zip(anillos, anillos[1:]):
        for k in range(segs):
            bm.faces.new((a[k], a[(k + 1) % segs], b[(k + 1) % segs], b[k]))
    for ring, x in ((anillos[0], perfil[0][0]), (anillos[-1], perfil[-1][0])):
        if perfil[0][1] > 0.001:
            c = bm.verts.new(V((x, 0, 0)))
            for k in range(segs):
                bm.faces.new((ring[k], ring[(k + 1) % segs], c))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    return objeto(nombre, bm)

def objeto(nombre, bm, suave=True):
    me = bpy.data.meshes.new(nombre)
    bm.to_mesh(me); bm.free()
    for p in me.polygons:
        p.use_smooth = suave
    o = bpy.data.objects.new(nombre, me)
    bpy.context.scene.collection.objects.link(o)
    return o

def normalizar(o):
    """Centra en el origen y lleva el tamaño a 1 x 1 x 1."""
    me = o.data
    lo = V([min(v.co[i] for v in me.vertices) for i in range(3)])
    hi = V([max(v.co[i] for v in me.vertices) for i in range(3)])
    c, t = (lo + hi) / 2, hi - lo
    for v in me.vertices:
        v.co = V(((v.co.x - c.x) / t.x, (v.co.y - c.y) / t.y, (v.co.z - c.z) / t.z))

def mango():
    perfil = [(-0.5, 0.0), (-0.5, 0.3), (-0.48, 0.42), (-0.44, 0.47)]
    n = 8
    for k in range(n):  # corcho con anillos marcados
        x0 = -0.44 + 0.88 * k / n
        perfil += [(x0 + 0.01, 0.47), (x0 + 0.045, 0.5), (x0 + 0.065, 0.5), (x0 + 0.1, 0.47)]
    perfil += [(0.44, 0.47), (0.48, 0.42), (0.5, 0.3), (0.5, 0.0)]
    return revolver(perfil, 20, "MangoCorcho")

def bobina():
    perfil = [(-0.5, 0.0), (-0.5, 0.22), (-0.46, 0.26)]
    for k in range(7):  # vueltas de hilo
        x = -0.4 + 0.8 * k / 6
        perfil += [(x - 0.04, 0.4), (x, 0.44), (x + 0.04, 0.4)]
    perfil += [(0.46, 0.26), (0.5, 0.22), (0.5, 0.0)]
    return revolver(perfil, 24, "CarreteBobina")

def plato():
    bm = bmesh.new()
    segs, rayos = 32, 6
    def v(x, a, r):
        return bm.verts.new(V((x, math.cos(a) * r, math.sin(a) * r)))
    for x, signo in ((-0.5, -1), (0.5, 1)):
        afuera = [v(x, 2 * math.pi * k / segs, 0.5) for k in range(segs)]
        adentro = [v(x, 2 * math.pi * k / segs, 0.36) for k in range(segs)]
        centro = [v(x, 2 * math.pi * k / segs, 0.12) for k in range(segs)]
        for k in range(segs):
            q = (afuera[k], afuera[(k + 1) % segs], adentro[(k + 1) % segs], adentro[k])
            bm.faces.new(q if signo > 0 else tuple(reversed(q)))
            if k % (segs // rayos) < 2:  # rayos: entre ellos queda el agujero
                q = (adentro[k], adentro[(k + 1) % segs], centro[(k + 1) % segs], centro[k])
                bm.faces.new(q if signo > 0 else tuple(reversed(q)))
        c = bm.verts.new(V((x, 0, 0)))
        for k in range(segs):
            t = (centro[k], centro[(k + 1) % segs], c)
            bm.faces.new(t if signo > 0 else tuple(reversed(t)))
        if x < 0:
            cara_a = (afuera, adentro, centro)
        else:
            cara_b = (afuera, adentro, centro)
    for k in range(segs):  # canto de afuera
        a0, b0 = cara_a[0], cara_b[0]
        bm.faces.new((a0[k], b0[k], b0[(k + 1) % segs], a0[(k + 1) % segs]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    return objeto("CarretePlato", bm)

def anilla():
    bm = bmesh.new()
    r_mayor, r_menor, segs, lados = 0.36, 0.12, 24, 8
    anillos = []
    for i in range(segs):
        a = 2 * math.pi * i / segs
        c = V((0, math.cos(a) * r_mayor, math.sin(a) * r_mayor))
        n = V((0, math.cos(a), math.sin(a)))
        anillos.append([bm.verts.new(c + n * math.cos(2 * math.pi * j / lados) * r_menor + V((1, 0, 0)) * math.sin(2 * math.pi * j / lados) * r_menor)
                        for j in range(lados)])
    for i in range(segs):
        a, b = anillos[i], anillos[(i + 1) % segs]
        for j in range(lados):
            bm.faces.new((a[j], a[(j + 1) % lados], b[(j + 1) % lados], b[j]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    return objeto("Anilla", bm)

def caja():
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.bevel(bm, geom=bm.edges[:] + bm.verts[:], offset=0.12, segments=3, affect='EDGES', profile=0.5)
    return objeto("CajaRedondeada", bm)

def construir():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    objs = [mango(), bobina(), plato(), anilla(), caja()]
    for o in objs:
        normalizar(o)
    for i, o in enumerate(objs):
        o.location = V((0, i * 2.0, 0))
    return objs

def exportar(objs):
    for o in bpy.data.objects:
        o.select_set(o in objs)
    for o in objs:
        o.location = V((0, 0, 0))
    win = bpy.context.window_manager.windows[0]
    area = next(a for a in win.screen.areas if a.type == 'VIEW_3D')
    with bpy.context.temp_override(window=win, area=area, region=next(r for r in area.regions if r.type == 'WINDOW')):
        bpy.ops.export_scene.fbx(filepath=FBX, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
            axis_forward="-Z", axis_up="Y", bake_space_transform=True, mesh_smooth_type="FACE", object_types={'MESH'})

OBJS = construir()
print("TRIS", {o.name: sum(len(p.vertices) - 2 for p in o.data.polygons) for o in OBJS})
if globals().get("EXPORTAR"):
    exportar(OBJS)
    print("EXPORTADO", FBX)
