r"""
Hábitats del volcán: biblioteca común (paleta, Malla y exportación).

Cada monstruo tiene su zona en el cráter, armada con props low-poly de caricatura que
comparten UNA textura de paleta (assets/textures/Habitats_color.png, 512x512, celdas de
32 px). Los props se modelan en tamaño real: 1 unidad de Blender = 1 stud. Frente a +Y de
Blender (= -Z en Roblox), origen en el centro de la base (z = 0 es el piso).

Un prop puede tener una segunda malla "<Prop>_Brillo" (partes que en Roblox van en Neon:
ojos de la calabaza, grietas de lava, perla...). Los datos de cada prop (efecto, punto de
la llama, color de la luz) quedan en assets/blender/habitats/<Habitat>.json; Studio los
usa al armar ServerStorage.Habitats.<GiantId> (ver docs/tareas_claude_code.md, C6).

Uso (Blender sin interfaz):
    blender -b -P tools/blender/habitats_construir.py -- <Habitat> [render]
Los props de cada hábitat están en habitats_<habitat>.py.
"""
import bpy, bmesh, math, os, random, json
from mathutils import Vector, Matrix, noise

V = Vector
RAIZ = os.environ.get("RAIZ", os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
TEX = os.path.join(RAIZ, "assets", "textures", "Habitats_color.png")

COLORES = {
    # piedra y ruinas
    "piedra": (200, 186, 160), "piedra2": (168, 152, 128), "piedra3": (224, 214, 192),
    "marmol": (236, 230, 216), "marmol2": (208, 200, 184), "marmol3": (182, 172, 156),
    "roca": (96, 92, 102), "roca2": (70, 66, 76), "roca3": (126, 122, 130),
    "musgo": (104, 156, 74), "musgo2": (72, 120, 58), "hiedra": (60, 140, 70),
    "rojo": (200, 52, 46), "rojo2": (150, 32, 36), "oro": (236, 172, 56), "oro2": (196, 128, 38),
    "madera": (130, 86, 52), "madera2": (96, 62, 38), "madera3": (160, 114, 72),
    "hueso": (240, 230, 204), "hueso2": (208, 194, 162), "hueso3": (176, 160, 128),
    "hierro": (54, 54, 62), "hierro2": (84, 86, 96), "cuerno": (230, 214, 176),
    "fuego": (255, 150, 40), "fuego2": (255, 92, 30), "brasa": (255, 212, 96), "carbon": (44, 36, 36),
    # arrecife
    "coral": (255, 118, 140), "coral2": (222, 82, 116), "coral3": (255, 160, 176),
    "naranja": (255, 148, 84), "naranja2": (230, 112, 60), "morado": (164, 98, 204), "morado2": (122, 70, 170),
    "amarillo": (250, 212, 88), "amarillo2": (222, 176, 60), "cerebro": (238, 172, 112), "cerebro2": (204, 132, 82),
    "alga": (72, 164, 92), "alga2": (44, 122, 82), "alga3": (124, 194, 102),
    "arena": (234, 216, 172), "arena2": (206, 186, 142), "almeja": (132, 112, 196), "almeja2": (92, 80, 160),
    "nacar": (252, 206, 226), "perla": (252, 248, 255), "percebe": (222, 220, 208), "percebe2": (178, 174, 164),
    "estrella": (255, 128, 62), "estrella2": (230, 90, 50), "azul": (70, 142, 214), "turquesa": (62, 204, 200),
    # volcán y dragón
    "obsidiana": (42, 36, 52), "obsidiana2": (66, 54, 78), "obsidiana3": (92, 78, 104),
    "lava": (255, 112, 32), "lava2": (255, 62, 22), "cristal": (255, 96, 64), "cristal2": (255, 176, 86),
    "huevo": (242, 224, 194), "huevo2": (84, 172, 162), "huevo3": (40, 120, 132),
    "nido": (112, 82, 62), "nido2": (84, 60, 46), "ceniza": (150, 140, 136), "ceniza2": (118, 108, 106),
    # Halloween
    "calabaza": (255, 130, 32), "calabaza2": (224, 96, 22), "calabaza3": (255, 166, 70), "tallo": (92, 112, 52),
    "fantasma": (182, 152, 255), "fantasma2": (124, 92, 204), "cian": (112, 240, 255), "verde": (130, 255, 150),
    "lapida": (142, 142, 162), "lapida2": (112, 112, 134), "lapida3": (172, 172, 190), "negro": (36, 30, 46),
    "vela": (255, 240, 200), "tela": (214, 204, 182), "tela2": (172, 162, 142), "violeta": (90, 54, 130),
    "seco": (78, 64, 66), "seco2": (56, 46, 50), "seco3": (104, 88, 88),
}
NOMBRES = list(COLORES)
LADO, CELDA = 16, 32
assert len(NOMBRES) <= LADO * LADO


def hacer_paleta(guardar=True):
    n = LADO * CELDA
    img = bpy.data.images.get("Habitats_color") or bpy.data.images.new("Habitats_color", n, n)
    import numpy as np
    px = np.ones((n, n, 4), dtype=np.float32)
    px[:, :, :3] = 0.5
    for i, nombre in enumerate(NOMBRES):
        cx, cy = (i % LADO) * CELDA, (i // LADO) * CELDA
        px[cy:cy + CELDA, cx:cx + CELDA, :3] = [c / 255 for c in COLORES[nombre]]
    img.pixels = px.ravel()
    if guardar:
        img.filepath_raw = TEX
        img.file_format = "PNG"
        os.makedirs(os.path.dirname(TEX), exist_ok=True)
        img.save()
    return img


def uv_de(nombre):
    i = NOMBRES.index(nombre)
    return V((((i % LADO) + 0.5) / LADO, ((i // LADO) + 0.5) / LADO))


def material():
    mat = bpy.data.materials.get("Habitats")
    if mat:
        return mat
    mat = bpy.data.materials.new("Habitats")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = hacer_paleta()
    tex.interpolation = "Closest"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.75
    return mat


def girar(eje, ang):
    return Matrix.Rotation(ang, 4, eje)


def T(x=0.0, y=0.0, z=0.0):
    return Matrix.Translation(V((x, y, z)))


class Malla:
    """Geometría de un prop. Cada primitiva recibe una matriz M (posición/giro/escala)."""

    def __init__(self, semilla=1):
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.verify()
        self.liso = self.bm.faces.layers.int.new("liso")
        self.rnd = random.Random(semilla)

    def pintar(self, cara, nombre, liso=False):
        c = uv_de(nombre)
        for l in cara.loops:
            l[self.uv].uv = c
        cara[self.liso] = 1 if liso else 0

    def cara(self, vs, nombre, liso=False):
        f = self.bm.faces.new(vs)
        self.pintar(f, nombre, liso)
        return f

    def v(self, p):
        return self.bm.verts.new(p)

    def color_de(self, color, k, f=None):
        return color(k) if callable(color) else color

    # ---- anillos y tubos -------------------------------------------------------------
    def anillo(self, M, radio, lados, giro=0.0, ruido=0.0, rx=1.0, ry=1.0):
        vs = []
        for k in range(lados):
            a = giro + 2 * math.pi * k / lados
            r = radio * (1 + ruido * self.rnd.uniform(-1, 1))
            vs.append(self.v(M @ V((math.cos(a) * r * rx, math.sin(a) * r * ry, 0))))
        return vs

    def unir(self, a, b, color, liso=False):
        n = len(a)
        for k in range(n):
            self.cara((a[k], a[(k + 1) % n], b[(k + 1) % n], b[k]), self.color_de(color, k), liso)

    def tapa(self, ring, color, centro=None, abajo=False, liso=False):
        ring = list(reversed(ring)) if abajo else ring
        if centro is None:
            self.cara(ring, color, liso)
            return
        c = self.v(centro)
        for k in range(len(ring)):
            self.cara((ring[k], ring[(k + 1) % len(ring)], c), self.color_de(color, k), liso)

    def torno(self, M, perfil, lados, color, liso=False, giro=0.0, ruido=0.0, punta=None, base=True):
        """Sólido de revolución: perfil = [(radio, z), ...] de abajo arriba."""
        prev = None
        primero = None
        for i, (r, z) in enumerate(perfil):
            ring = self.anillo(M @ T(0, 0, z), max(r, 0.02), lados, giro, ruido)
            if prev is None:
                primero = ring
            else:
                self.unir(prev, ring, color if not callable(color) else (lambda k, i=i: color(i, k)), liso)
            prev = ring
        if base:
            self.tapa(primero, color if not callable(color) else color(0, 0), abajo=True)
        cima = color if not callable(color) else color(len(perfil), 0)
        if punta is not None:
            self.tapa(prev, cima, M @ V((0, 0, punta)), liso=liso)
        else:
            self.tapa(prev, cima)
        return prev

    def tubo(self, puntos, radios, lados, color, liso=False, cerrar=True, ruido=0.0):
        """Tubo por una curva (ramas, algas, troncos). radios: uno por punto."""
        n = len(puntos)
        tang = [(puntos[min(i + 1, n - 1)] - puntos[max(i - 1, 0)]).normalized() for i in range(n)]
        ref = V((0, 0, 1)) if abs(tang[0].z) < 0.9 else V((1, 0, 0))
        u = tang[0].cross(ref).normalized()
        rings = []
        for i in range(n):
            if i:
                u = (u - tang[i] * u.dot(tang[i])).normalized()
            w = tang[i].cross(u)
            ring = []
            for k in range(lados):
                a = 2 * math.pi * k / lados
                r = radios[i] * (1 + ruido * self.rnd.uniform(-1, 1))
                ring.append(self.v(puntos[i] + (u * math.cos(a) + w * math.sin(a)) * r))
            rings.append(ring)
        for i in range(n - 1):
            self.unir(rings[i], rings[i + 1], self.color_de(color, i), liso)
        if cerrar:
            self.tapa(rings[0], self.color_de(color, 0), abajo=True)
            self.tapa(rings[-1], self.color_de(color, n - 1), puntos[-1] + tang[-1] * radios[-1] * 0.6, liso=liso)
        return rings

    # ---- sólidos ---------------------------------------------------------------------
    def caja(self, M, tam, color, liso=False, bisel=0.0):
        """Caja centrada en M de tamaño tam (x, y, z). color: nombre o {"+z": ..., "resto": ...}."""
        r = bmesh.ops.create_cube(self.bm, size=1.0)
        vs = r["verts"]
        for v in vs:
            p = V((v.co.x * tam[0], v.co.y * tam[1], v.co.z * tam[2]))
            if bisel:
                p += V((self.rnd.uniform(-1, 1), self.rnd.uniform(-1, 1), self.rnd.uniform(-1, 1))) * bisel
            v.co = M @ p
        caras = {f for v in vs for f in v.link_faces}
        for f in caras:
            if isinstance(color, dict):
                f.normal_update()
                n = (M.to_3x3().inverted() @ f.normal) if False else f.normal
                lado = "+z" if n.z > 0.7 else ("-z" if n.z < -0.7 else "lado")
                self.pintar(f, color.get(lado, color["resto"]), liso)
            else:
                self.pintar(f, color, liso)
        return vs

    def esfera(self, M, radio, color, sub=1, ruido=0.0, semilla=0.0, liso=False, escala=(1, 1, 1)):
        r = bmesh.ops.create_icosphere(self.bm, subdivisions=sub, radius=radio)
        for v in r["verts"]:
            d = noise.noise(v.co / max(radio, 0.01) * 1.7 + V((semilla, semilla * 2, 0)))
            p = V((v.co.x * escala[0], v.co.y * escala[1], v.co.z * escala[2])) * (1 + ruido * d)
            v.co = M @ p
        for f in {f for v in r["verts"] for f in v.link_faces}:
            f.normal_update()
            self.pintar(f, color(f) if callable(color) else color, liso)
        return r["verts"]

    def roca(self, M, radio, color, sub=1, ruido=0.35, semilla=0.0, escala=(1, 1, 0.7)):
        return self.esfera(M, radio, color, sub, ruido, semilla, False, escala)

    def placa(self, M, contorno, grosor, color, lado=None):
        """Prisma: polígono `contorno` [(x, z)] en el plano XZ, extruido en Y (grosor)."""
        a = [self.v(M @ V((x, -grosor / 2, z))) for x, z in contorno]
        b = [self.v(M @ V((x, grosor / 2, z))) for x, z in contorno]
        self.cara(a, color)
        self.cara(list(reversed(b)), color)
        n = len(a)
        for k in range(n):
            self.cara((a[(k + 1) % n], a[k], b[k], b[(k + 1) % n]), lado or color)
        return a, b

    # ---- salida ----------------------------------------------------------------------
    def objeto(self, nombre, x=0.0, piso=True, angulo_liso=40):
        bm = self.bm
        if piso:
            for v in bm.verts:
                v.co.z = max(v.co.z, 0.0)
        bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=0.0005)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
        lisos = [f[self.liso] == 1 for f in bm.faces]
        me = bpy.data.meshes.new(nombre)
        bm.normal_update()
        bm.to_mesh(me)
        bm.free()
        for p, liso in zip(me.polygons, lisos):
            p.use_smooth = liso
        if hasattr(me, "set_sharp_from_angle"):
            me.set_sharp_from_angle(angle=math.radians(angulo_liso))
        o = bpy.data.objects.new(nombre, me)
        o.data.materials.append(material())
        o.location.x = x
        bpy.context.scene.collection.objects.link(o)
        return o


def tris(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)
