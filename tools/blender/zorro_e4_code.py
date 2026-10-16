r"""
Zorro de agua, etapa 4 (forma final), versión de Claude Code: un kitsune de agua
parado en cuatro patas, elegante, con nueve colas que son olas esculpidas (suben,
se abren en abanico y rompen en una cresta de espuma), pelaje aguamarina con
pecho, hocico y mejillas blancas, medias azul profundo en las patas, marcas cian
que brillan en la cara, el lomo y las patas, gema de cristal en la frente, aros de
oro en las orejas y collar de oro con medallón.
Mira a -Y, parado en z = 0. x = izquierda del zorro.

construir_zorro_e4() -> (objetos, partes): partes = {objeto: hueso rígido o ""}
    "" = se pesa por calor (cuerpo, mechones y colas); un nombre = la pieza sigue
    entera a ese hueso (ojos, gema, aros, collar).
PUNTOS: las articulaciones del esqueleto (rig_zorro_e4_code.py), en las mismas coordenadas.
Requiere criaturas.py (exec antes).

Uso suelto (render de revisión, pintado con zorro_e4_pintura.py):
    blender -b --factory-startup --python zorro_e4_code.py -- <render.png> [alto.blend]
"""
import math
import bmesh
from mathutils import Vector

V = Vector
VOXEL = 0.012
PUNTA_MIN = 0.014  # las puntas de los mechones terminan redondeadas, no en espina

# --- Articulaciones ------------------------------------------------------------------
PUNTOS = {
    "cadera": V((0, 0.5, 1.3)), "lomo": V((0, 0.02, 1.36)), "pecho": V((0, -0.42, 1.36)),
    "cuello": V((0, -0.58, 1.42)), "cuello2": V((0, -0.76, 1.66)), "cabeza": V((0, -0.92, 1.86)),
    "coronilla": V((0, -0.95, 2.12)), "bisagra": V((0, -1.06, 1.82)), "menton": V((0, -1.4, 1.74)),
    "boca": V((0, -1.48, 1.8)),
    "hombro": V((0.21, -0.46, 1.22)), "codo": V((0.22, -0.52, 0.78)), "muneca": V((0.2, -0.56, 0.28)),
    "mano": V((0.2, -0.7, 0.06)),
    "muslo": V((0.24, 0.5, 1.18)), "rodilla": V((0.26, 0.32, 0.76)), "tobillo": V((0.25, 0.66, 0.4)),
    "pie": V((0.23, 0.58, 0.07)), "punta_pie": V((0.23, 0.44, 0.04)),
    "oreja": V((0.15, -0.88, 2.06)), "oreja_punta": V((0.32, -0.8, 2.64)),
    "cola_base": V((0, 0.8, 1.32)),
}
P = PUNTOS
N_COLAS = 9


def lado(p, s):
    return V((p.x * s, p.y, p.z))


def cono(nombre, base, punta, ancho, grueso, frente, hueco=0.0, anillos=10, lados=16, curva=0.0):
    """Cono de sección elíptica de base a punta (orejas, mechones): `ancho` a lo largo
    del costado, `grueso` hacia `frente`; `hueco` hunde la cara de adelante (oreja);
    `curva` arquea la punta hacia atrás (contra `frente`)."""
    base, punta, frente = V(base), V(punta), V(frente).normalized()
    eje = punta - base
    costado = eje.cross(frente).normalized()
    frente = costado.cross(eje).normalized()
    bm = bmesh.new()
    anillos_v = []
    for k in range(anillos):
        t = k / (anillos - 1)
        w = max(ancho * (1 - t) ** 0.85, PUNTA_MIN)
        d = max(grueso * (1 - t) ** 0.85, PUNTA_MIN)
        c = base + eje * t - frente * curva * t * t
        anillo = []
        for j in range(lados):
            a = 2 * math.pi * j / lados
            x, y = math.cos(a), math.sin(a)
            dy = d * y
            if hueco and y > 0:
                dy -= hueco * d * (1 - t) * y ** 1.5 * 2
            anillo.append(bm.verts.new(c + costado * w * x + frente * dy))
        anillos_v.append(anillo)
    for k in range(anillos - 1):
        for j in range(lados):
            bm.faces.new((anillos_v[k][j], anillos_v[k][(j + 1) % lados],
                          anillos_v[k + 1][(j + 1) % lados], anillos_v[k + 1][j]))
    bm.faces.new(list(reversed(anillos_v[0])))
    tip = bm.verts.new(punta - frente * curva)
    for j in range(lados):
        bm.faces.new((anillos_v[-1][j], anillos_v[-1][(j + 1) % lados], tip))
    # Caras hacia afuera: al fundir por vóxeles, una pieza al revés resta volumen (abre huecos).
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    for f in bm.faces:
        f.smooth = True  # si no, nace con caras planas y aristas filosas
    me = bpy.data.meshes.new(nombre)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(nombre, me)
    bpy.context.collection.objects.link(o)
    sub = o.modifiers.new("Suave", "SUBSURF")
    sub.levels = 2
    aplicar(o)
    o.data.shade_smooth()
    return o


def ajustar_collar(cuerpo_obj, centro, eje):
    """Radio del cuello en el plano del collar (medido en la malla fusionada)."""
    eje = V(eje).normalized()
    d = []
    for v in cuerpo_obj.data.vertices:
        rel = v.co - centro
        if abs(rel.dot(eje)) < 0.025:
            radial = rel - eje * rel.dot(eje)
            if radial.length < 0.45:
                d.append(radial.length)
    d.sort()
    return d[int(len(d) * 0.9)] if d else 0.24


# --- Colas: nueve colas gruesas en S que se abren a los lados y suben ----------------
def cola_puntos(i):
    """Puntos (x, y, z, radio) de la cola i (0..8) desde la base hasta la punta.
    Las de los extremos salen casi de costado y bajas; las del medio, hacia arriba.
    Cada una dibuja una S en su plano y termina en punta (como una llama de agua)."""
    t = (i - (N_COLAS - 1) / 2) / ((N_COLAS - 1) / 2)  # -1..1
    abre = math.radians(98) * t  # 0 = arriba, ±98° = de costado y un poco hacia abajo
    largo = 1.55 + 0.25 * (1 - abs(t)) + 0.06 * math.cos(i * 2.3)
    capa = 0.06 * ((i % 2) * 2 - 1)  # una adelante, una atrás: se leen como capas
    base = P["cola_base"] + V((0.07 * t, 0.0, -0.06 * abs(t)))
    afuera = V((math.sin(abre), 0.0, math.cos(abre)))  # dirección principal (en el plano x-z)
    normal = V((math.cos(abre), 0.0, -math.sin(abre)))  # hacia donde dobla la S
    if t < 0:
        normal = -normal
    pts = []
    n = 16
    for k in range(n):
        u = k / (n - 1)
        largo_u = largo * u
        # Primero va hacia atrás, después se abre; la S dobla hacia adentro y la punta hacia afuera.
        s_curva = 0.22 * math.sin(u * math.pi * 1.6 - 0.4) * largo * (0.4 + 0.6 * u)
        atras = (0.42 * math.sin(u * math.pi * 0.5) + capa) * largo
        p = base + afuera * largo_u * 0.95 + normal * s_curva + V((0, atras, 0))
        r = 0.09 + 0.17 * math.sin(math.pi * min(1.0, u * 1.25)) ** 0.6
        if u > 0.7:
            r *= max(0.02, 1 - ((u - 0.7) / 0.3) ** 1.3)
        pts.append((p.x, p.y, p.z, r))
    return pts


PUNTOS_COLA = [cola_puntos(i) for i in range(N_COLAS)]


def construir_zorro_e4():
    partes = {}

    def cuerpo(o):
        partes[o] = ""
        return o

    def rigido(o, hueso):
        partes[o] = hueso
        return o

    b = [
        masa("Costillar", (0, -0.34, 1.16), (0.29, 0.46, 0.35), (-4, 0, 0)),
        masa("Cintura", (0, 0.08, 1.18), (0.22, 0.42, 0.23)),
        masa("Anca", (0, 0.48, 1.2), (0.28, 0.34, 0.3)),
        masa("Lomo", (0, 0.05, 1.33), (0.19, 0.62, 0.1)),
        piel("Cuello", [(0, -0.45, 1.3, 0.3), (0, -0.62, 1.48, 0.27), (0, -0.78, 1.68, 0.23),
                        (0, -0.9, 1.84, 0.2)]),
        # Pechera: una masa esponjosa grande (la del dibujo) que baja hasta entre las patas.
        masa("Pechera", (0, -0.66, 1.2), (0.26, 0.2, 0.36), (12, 0, 0)),
        masa("PecheraBaja", (0, -0.62, 0.92), (0.18, 0.15, 0.2), (10, 0, 0)),
        # Gola: la pechera sube hasta debajo de la mandíbula y tapa la garganta (como en el dibujo).
        masa("Gola", (0, -0.86, 1.6), (0.21, 0.17, 0.26), (28, 0, 0)),
        masa("GolaAlta", (0, -0.98, 1.74), (0.16, 0.12, 0.12), (20, 0, 0)),
    ]
    for s in (1, -1):
        b += [
            masa(f"Hombro{s}", (0.19 * s, -0.44, 1.08), (0.13, 0.2, 0.27), (10, 0, 0)),
            piel(f"PataDel{s}", [(0.21 * s, -0.46, 1.14, 0.13), (0.22 * s, -0.52, 0.78, 0.095),
                                 (0.2 * s, -0.56, 0.3, 0.07), (0.2 * s, -0.62, 0.11, 0.074)]),
            masa(f"Mano{s}", (0.2 * s, -0.68, 0.07), (0.09, 0.13, 0.07)),
            masa(f"Muslo{s}", (0.23 * s, 0.48, 0.98), (0.16, 0.3, 0.34), (-20, 0, 0)),
            piel(f"PataTras{s}", [(0.24 * s, 0.48, 1.12, 0.16), (0.26 * s, 0.32, 0.76, 0.11),
                                  (0.25 * s, 0.66, 0.4, 0.075), (0.23 * s, 0.58, 0.12, 0.07)]),
            masa(f"Pie{s}", (0.23 * s, 0.5, 0.07), (0.09, 0.14, 0.07)),
        ]
        for d in range(4):
            dx = (d - 1.5) * 0.048
            b += [masa(f"DedoD{s}{d}", (0.2 * s + dx, -0.78, 0.05), (0.034, 0.048, 0.043)),
                  masa(f"DedoT{s}{d}", (0.23 * s + dx, 0.38, 0.05), (0.034, 0.048, 0.043))]
    # Cabeza de zorro: cráneo ancho, mejillas llenas, hocico fino y horizontal.
    b += [
        masa("Craneo", (0, -0.94, 1.94), (0.23, 0.21, 0.17)),
        masa("Frente", (0, -1.06, 1.99), (0.15, 0.13, 0.085), (-24, 0, 0)),
        # Hocico en punta: se afina desde la frente hasta la nariz (lo que la hace zorro).
        piel("Hocico", [(0, -1.02, 1.9, 0.13), (0, -1.2, 1.88, 0.085), (0, -1.36, 1.86, 0.058),
                        (0, -1.48, 1.85, 0.036)], subdiv=2),
        piel("MandibulaB", [(0, -1.04, 1.8, 0.09), (0, -1.22, 1.8, 0.055), (0, -1.38, 1.8, 0.03)], subdiv=2),
    ]
    for s in (1, -1):
        b += [
            masa(f"Mejilla{s}", (0.16 * s, -0.98, 1.82), (0.13, 0.13, 0.11)),
        ]
    # Mechones fundidos con el cuerpo (no sueltos): pechera, mejillas, codos y nuca.
    for fila, (n, z, ancho) in enumerate(((5, 1.36, 0.2), (4, 1.16, 0.17), (3, 0.96, 0.12))):
        for k in range(n):  # pechera en capas de mechones anchos y redondos, punta abajo
            a = (k - (n - 1) / 2) / max(1, (n - 1) / 2)
            raiz = V((a * ancho, -0.8 + fila * 0.03 + abs(a) * 0.05, z - abs(a) * 0.04))
            b.append(cono(f"Pechera{fila}{k}", raiz, raiz + V((a * 0.04, -0.06, -0.24)), 0.11, 0.06,
                          (0, -1, 0.1), curva=0.05))
    for s in (1, -1):
        for k in range(3):  # mejillas: mechones blancos anchos hacia afuera: cara triangular
            raiz = V((0.2 * s, -0.98 - k * 0.04, 1.82 - k * 0.07))
            b.append(cono(f"MejillaPelo{s}{k}", raiz, raiz + V((0.2 * s, 0.05, -0.1 - k * 0.04)),
                          0.1, 0.05, (0, -1, 0.15), curva=0.03))
        for k in range(2):  # flecos detrás de los codos
            raiz = V((0.22 * s, -0.4, 0.95 - k * 0.14))
            b.append(cono(f"Codo{s}{k}", raiz, raiz + V((0.03 * s, 0.16, -0.08)), 0.045, 0.03, (s, 0, 0)))
    for k in range(5):  # gola: mechones blancos que caen sobre el pecho
        a = (k - 2) / 2
        raiz = V((a * 0.13, -1.0 + abs(a) * 0.05, 1.66 - abs(a) * 0.05))
        b.append(cono(f"Gola{k}", raiz, raiz + V((a * 0.05, -0.04, -0.24)), 0.1, 0.055, (0, -1, 0.2), curva=0.05))
    for k in range(5):  # nuca
        a = (k - 2) / 2
        raiz = V((a * 0.13, -0.8, 1.86 - abs(a) * 0.08))
        b.append(cono(f"Nuca{k}", raiz, raiz + V((a * 0.06, 0.24, -0.12)), 0.08, 0.045, (0, 0, 1), curva=0.03))
    out = [cuerpo(fusionar("Cuerpo", b, voxel=VOXEL, suavizado=14))]

    # Orejas grandes, anchas y cóncavas, con aros de oro.
    for s, n in ((1, "Izq"), (-1, "Der")):
        base, punta = lado(P["oreja"], s), lado(P["oreja_punta"], s)
        oreja = cono(f"Oreja{n}", base, punta, 0.19, 0.12, (0.3 * s, -1, 0.1),
                     hueco=0.35, curva=0.05, anillos=14, lados=24)
        # Fundida y suavizada como el cuerpo: bordes redondeados en vez de filo de cartón.
        out.append(rigido(fusionar(f"Oreja{n}", [oreja], voxel=VOXEL * 0.8, suavizado=12), f"Oreja{n}"))
        # Pelo blanco adentro de la oreja.
        adentro = base.lerp(punta, 0.08) + V((0.02 * s, -0.05, 0))
        pelo_oreja = cono(f"OrejaPelo{n}", adentro, base.lerp(punta, 0.55) + V((-0.02 * s, -0.06, 0)),
                          0.09, 0.03, (0.3 * s, -1, 0.1), curva=0.02)
        out.append(rigido(pelo_oreja, f"Oreja{n}"))
        # Dos aretes de oro colgando del borde de afuera de la oreja.
        for k, f in enumerate((0.22, 0.38)):
            borde = base.lerp(punta, f) + V((0.15 * (1 - f) * s, 0.02, 0))
            bpy.ops.mesh.primitive_torus_add(major_radius=0.038, minor_radius=0.009,
                                             major_segments=24, minor_segments=8, location=borde)
            aro = bpy.context.active_object
            aro.name = f"Aro{n}{k}"
            aro.rotation_euler = (0, math.radians(90), math.radians(15 * s))
            out.append(rigido(aplicar(aro), f"Oreja{n}"))

    for s, n in ((1, "Izq"), (-1, "Der")):
        ojo = masa(f"Ojo{n}", (0.114 * s, -1.125, 1.962), (0.056, 0.026, 0.032), (0, -20 * s, 32 * s))
        out.append(rigido(aplicar(ojo), "Cabeza"))
    out.append(rigido(aplicar(masa("Nariz", (0, -1.51, 1.85), (0.04, 0.032, 0.03))), "Cabeza"))
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.06, location=(0, -1.165, 2.055))
    gema = bpy.context.active_object
    gema.name = "Gema"
    gema.scale = (0.75, 0.45, 1.3)
    gema.rotation_euler = (math.radians(-40), 0, 0)
    out.append(rigido(aplicar(gema), "Cabeza"))
    # Colgante de oro con una gema, apoyado en la pechera.
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=0.075, depth=0.03, location=(0, -1.07, 1.42))
    medalla = bpy.context.active_object
    medalla.name = "Medallon"
    medalla.rotation_euler = (math.radians(70), 0, 0)
    out.append(rigido(aplicar(medalla), "Cuello1"))
    bpy.ops.mesh.primitive_torus_add(major_radius=0.075, minor_radius=0.014, major_segments=32,
                                     minor_segments=8, location=(0, -1.075, 1.42))
    borde = bpy.context.active_object
    borde.name = "MedallonBorde"
    borde.rotation_euler = (math.radians(70), 0, 0)
    out.append(rigido(aplicar(borde), "Cuello1"))
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.058, location=(0, -1.09, 1.425))
    piedra = bpy.context.active_object
    piedra.name = "GemaMedallon"
    piedra.scale = (1, 0.5, 1)
    piedra.rotation_euler = (math.radians(70), 0, 0)
    out.append(rigido(aplicar(piedra), "Cuello1"))

    for i, pts in enumerate(PUNTOS_COLA):
        cola = piel(f"Cola{i + 1}", pts, subdiv=2)
        out.append(cuerpo(fusionar(f"Cola{i + 1}", [cola], voxel=VOXEL, suavizado=6)))
    return out, partes


if __name__ == "__main__":
    import sys, os
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    here = os.path.dirname(os.path.abspath(__file__))
    exec(open(os.path.join(here, "criaturas.py"), encoding="utf-8").read(), globals())
    limpiar_escena()
    objs, partes = construir_zorro_e4()
    print("TRIS", triangulos(objs))
    exec(open(os.path.join(here, "zorro_e4_pintura.py"), encoding="utf-8").read(), globals())
    pintar_zorro_e4(objs)
    estudio(3.0, distancia=8, angulo=35, fondo=(0.55, 0.62, 0.7))
    bpy.context.scene.view_settings.exposure = -0.6
    if len(args) > 1:
        bpy.ops.wm.save_as_mainfile(filepath=args[1])
    if args:
        cam = bpy.context.scene.camera
        centro = Vector((0, 0.1, 1.45))
        for nombre, d in (("tres", (0.55, -0.85, 0.25)), ("frente", (0, -1, 0.12)), ("lado", (1, 0, 0.1))):
            cam.location = centro + Vector(d).normalized() * 8
            cam.rotation_euler = (centro - cam.location).to_track_quat("-Z", "Y").to_euler()
            renderizar(args[0].replace(".png", f"_{nombre}.png"), 700, 700, muestras=32, motor="CYCLES")
