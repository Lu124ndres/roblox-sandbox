r"""
Canastas v4 (íconos de la tienda llevados a 3D) que se cargan como mochila en la espalda.
Piloto: la canasta 24 (cofre del trueno).

Medidas en studs. Ejes de Blender: X a la derecha del jugador, Z arriba e +Y hacia atrás
(lejos de la espalda). El origen es el punto de la espalda donde se apoya, al medio del ancho y
del alto, así que en Roblox va justo en el centro de la cara de atrás del torso. Al exportar
(-Z adelante, Y arriba) +Y de Blender queda como +Z de Roblox, que es la espalda del torso.
Más grande que la de primitivas (pedido del usuario: "más grandes y llamativas").

Uso (consola), junto con la caña para importar las dos juntas:
    blender.exe -b -P tools\blender\canastas_v4.py -- 24
Deja renders/canastas_v4/<nivel>_*.png y assets/blender/canastas_v4/Canasta<nivel>.fbx; además,
assets/blender/EquipoPrueba.fbx con la caña 24 y la canasta 24.
"""
import bpy, bmesh, json, math, os, sys
from mathutils import Vector as V

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
sys.path.insert(0, os.path.dirname(__file__))
import canas_v4 as C  # noqa: E402  (materiales, tubos, bolas, render)

ANCHO, ALTO, FONDO = 2.4, 1.7, 1.5  # cuerpo del cofre (sin la tapa)
SEPARA = 0.12  # aire entre la espalda y el cofre


def caja(nombre, centro, medidas, bisel=0.08):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1)
    for v in bm.verts:
        v.co = V((v.co.x * medidas[0], v.co.y * medidas[1], v.co.z * medidas[2])) + centro
    bmesh.ops.bevel(bm, geom=list(bm.edges), offset=bisel, segments=2, affect="EDGES")
    ob = C.malla(nombre, bm)
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def tapa(nombre, centro, ancho, fondo, alto, segs=16):
    """Media caña a lo largo de X: la tapa abombada del cofre."""
    bm = bmesh.new()
    lados = []
    for sx in (-1, 1):
        lado = []
        for k in range(segs + 1):
            a = math.pi * k / segs
            lado.append(bm.verts.new(centro + V((sx * ancho / 2, math.cos(a) * fondo / 2, math.sin(a) * alto))))
        lados.append(lado)
    for k in range(segs):
        bm.faces.new((lados[0][k], lados[0][k + 1], lados[1][k + 1], lados[1][k]))
    bm.faces.new(list(reversed(lados[0])))
    bm.faces.new(lados[1])
    ob = C.malla(nombre, bm)
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def rayo(nombre, centro, alto, grosor, y_cara):
    """Rayo en zigzag, plano y con grosor, pegado a una cara que mira a +Y."""
    pts = [(-0.15, 0.5), (0.25, 0.5), (0.02, 0.08), (0.28, 0.08), (-0.2, -0.5), (-0.02, -0.08), (-0.28, -0.08)]
    bm = bmesh.new()
    delante = [bm.verts.new(centro + V((x * alto, y_cara + grosor, y * alto))) for x, y in pts]
    atras = [bm.verts.new(centro + V((x * alto, y_cara, y * alto))) for x, y in pts]
    bm.faces.new(delante)
    bm.faces.new(list(reversed(atras)))
    n = len(pts)
    for i in range(n):
        bm.faces.new((atras[i], atras[(i + 1) % n], delante[(i + 1) % n], delante[i]))
    return C.malla(nombre, bm)


def canasta_trueno():
    piedra = C.mat("PiedraTormenta", (58, 60, 66), rugoso=0.85)
    oro = C.mat("Oro", (222, 166, 52), metal=1.0, rugoso=0.3)
    nube = C.mat("Nube", (70, 72, 82), rugoso=0.95)
    luz = C.mat("Rayo", (255, 214, 40), brillo=5.0)
    cuero = C.mat("Cuero", (96, 62, 36), rugoso=0.7)
    piezas = []
    cy = SEPARA + FONDO / 2  # centro del cofre en Y
    base_z = -ALTO / 2

    # Cuerpo de piedra oscura con grietas doradas (vetas) y la tapa abombada.
    piezas.append(C.poner(caja("Cuerpo", V((0, cy, 0)), (ANCHO, FONDO, ALTO)), piedra))
    piezas.append(C.poner(tapa("Tapa", V((0, cy, ALTO / 2)), ANCHO, FONDO, 0.55), piedra))

    # Marco de oro: aristas, bandas que cruzan la tapa y esquineros.
    for sx in (-1, 1):
        for sy in (-1, 1):
            piezas.append(C.poner(caja(f"Arista{sx}{sy}", V((sx * ANCHO / 2, cy + sy * FONDO / 2, 0)),
                                       (0.16, 0.16, ALTO + 0.08), 0.05), oro))
        for zz in (base_z, ALTO / 2):
            piezas.append(C.poner(caja(f"Borde{sx}{zz:.1f}", V((0, cy + sx * FONDO / 2, zz)),
                                       (ANCHO + 0.1, 0.16, 0.16), 0.05), oro))
    for x in (-ANCHO * 0.3, ANCHO * 0.3):
        arco = [V((x, cy + math.cos(math.pi * k / 10) * (FONDO / 2 + 0.04), ALTO / 2 + math.sin(math.pi * k / 10) * 0.6))
                for k in range(11)]
        piezas.append(C.poner(C.tubo(f"BandaTapa{x:.1f}", arco, [0.09] * 11, segs=8), oro))
    for sx in (-1, 1):  # bordes de los costados de la tapa
        arco = [V((sx * ANCHO / 2, cy + math.cos(math.pi * k / 12) * (FONDO / 2 + 0.03), ALTO / 2 + math.sin(math.pi * k / 12) * 0.58))
                for k in range(13)]
        piezas.append(C.poner(C.tubo(f"CantoTapa{sx}", arco, [0.08] * 13, segs=8), oro))

    # Rayo grande en la cara de atrás (la que se ve) y cerradura.
    cara = cy + FONDO / 2
    piezas.append(C.poner(rayo("RayoFrente", V((0, 0, 0.0)), 1.45, 0.08, cara), luz))
    piezas.append(C.poner(caja("Cerradura", V((0, cara + 0.06, ALTO / 2 - 0.12)), (0.36, 0.14, 0.42), 0.05), oro))

    # Grietas doradas sobre la piedra (tubitos finos que zigzaguean).
    for i, (x0, z0) in enumerate(((-0.85, 0.45), (0.8, -0.35), (-0.7, -0.5), (0.75, 0.5))):
        pts = [V((x0 + 0.12 * k * (1 if i % 2 else -1), cara + 0.005, z0 - 0.12 * k + 0.06 * (k % 2))) for k in range(4)]
        piezas.append(C.poner(C.tubo(f"Grieta{i}", pts, [0.025] * 4, segs=5), luz))

    # Nube de tormenta sobre la tapa, con rayitos que caen.
    top = ALTO / 2 + 0.55
    for i, (x, y, z, r) in enumerate(((0, 0.1, 0.35, 0.45), (-0.45, -0.05, 0.25, 0.35), (0.45, 0.0, 0.22, 0.36),
                                      (-0.2, 0.25, 0.5, 0.32), (0.25, 0.2, 0.52, 0.3), (0.0, -0.2, 0.4, 0.3))):
        piezas.append(C.poner(C.bola(f"Nube{i}", V((x, cy + y, top + z)), (r * 1.3, r, r * 0.85)), nube))
    for i, x in enumerate((-0.6, 0.55)):
        zig = [V((x, cy + 0.3, top + 0.15)), V((x + 0.12, cy + 0.35, top - 0.1)), V((x - 0.05, cy + 0.4, top - 0.3)),
               V((x + 0.1, cy + 0.45, top - 0.55))]
        piezas.append(C.poner(C.tubo(f"Chispa{i}", zig, [0.05, 0.05, 0.04, 0.005], segs=5), luz))

    # Correas de cuero que pasan por los hombros (del cofre hacia adelante, sobre el torso).
    for sx in (-1, 1):
        x = sx * 0.55
        correa = [V((x, SEPARA + 0.05, ALTO * 0.35)), V((x, -0.1, ALTO * 0.62)), V((x, -0.7, ALTO * 0.7)),
                  V((x, -1.15, ALTO * 0.45)), V((x, -1.2, ALTO * 0.1))]
        piezas.append(C.poner(C.tubo(f"Correa{sx}", correa, [0.09] * 5, segs=6), cuero))
        piezas.append(C.poner(C.aro(f"Hebilla{sx}", V((x, -1.18, ALTO * 0.3)), V((0, 1, 0)), 0.11, 0.03, segs=10, lados=5), oro))
    return piezas


CANASTAS = {24: canasta_trueno}


def hacer(nivel):
    C.limpiar()
    ob = C.unir(f"Canasta{nivel:02d}", CANASTAS[nivel]())
    C.escena_render()
    salida = os.path.join(RAIZ, "renders", "canastas_v4")
    os.makedirs(salida, exist_ok=True)
    centro = V((0, SEPARA + FONDO / 2, 0.3))
    C.render(os.path.join(salida, f"{nivel:02d}_atras.png"), C.camara("Atras", centro + V((4, 8, 3.5)), centro, ortho=4.6))
    C.render(os.path.join(salida, f"{nivel:02d}_lado.png"), C.camara("Lado", centro + V((9, 0, 1)), centro + V((0, -0.4, 0)), ortho=5))
    carpeta = os.path.join(RAIZ, "assets", "blender", "canastas_v4")
    os.makedirs(carpeta, exist_ok=True)
    cuenta = C.tris(ob)
    piezas, colores = C.separar(ob)
    C.exportar(os.path.join(carpeta, f"Canasta{nivel:02d}.fbx"), piezas)
    print(f"LISTO canasta {nivel}: {cuenta} triángulos, colores {colores}")


def prueba():
    """Caña 24 y canasta 24 en un solo FBX, para importar las dos juntas en Studio."""
    C.limpiar()
    cana = C.unir("Cana24", C.CANAS[24]())
    canasta = C.unir("Canasta24", CANASTAS[24]())
    piezas_cana, colores = C.separar(cana)
    piezas_canasta, colores2 = C.separar(canasta)
    colores.update(colores2)
    C.exportar(os.path.join(RAIZ, "assets", "blender", "EquipoPrueba.fbx"), piezas_cana + piezas_canasta)
    print("LISTO EquipoPrueba.fbx", len(piezas_cana) + len(piezas_canasta), "piezas")
    print("COLORES", json.dumps(colores))


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else ["24"]
    for a in args:
        hacer(int(a))
    prueba()
