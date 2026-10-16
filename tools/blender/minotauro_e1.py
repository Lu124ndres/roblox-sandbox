r"""
Minotauro etapa 1 (becerro) al estilo de la orca y el dragón: chibi de cabeza grande,
ojos enormes y brillantes, pelaje castaño con panza y hocico crema, mechón en la frente,
cuernitos de marfil con anillo de oro, aro de oro en la nariz, orejas caídas, cinturón
de cuero con hebilla de oro, faldón de tiras, brazaletes de oro, pezuñas y cola con borla.
Mira a -Y, parado en z = 0, ~3.1 de alto. Requiere criaturas.py (exec antes).

construir_minotauro_e1() -> (objetos, partes) donde partes = {objeto: hueso rígido o None}
    None = se pesa por calor (el cuerpo); un nombre = la pieza sigue entera a ese hueso.
PUNTOS: las articulaciones que usa rig_minotauro.py (en las mismas coordenadas).
"""
import math
import bmesh
from mathutils import Vector, noise

V = Vector

# --- Articulaciones (x = izquierda del personaje, -y = frente, z arriba) ----------------
PUNTOS = {
    "cadera": V((0, 0.02, 0.98)), "columna": V((0, 0.0, 1.32)), "pecho": V((0, -0.02, 1.66)),
    "cuello": V((0, -0.03, 1.88)), "cabeza": V((0, -0.06, 2.06)), "coronilla": V((0, -0.06, 2.8)),
    "bisagra": V((0, -0.16, 2.02)), "menton": V((0, -0.58, 1.93)), "boca": V((0, -0.66, 2.02)),
    "hombro": V((0.45, 0.0, 1.76)), "codo": V((0.63, 0.03, 1.4)), "muneca": V((0.69, -0.04, 1.1)),
    "mano": V((0.71, -0.08, 0.86)),
    "muslo": V((0.27, 0.0, 0.98)), "rodilla": V((0.29, -0.06, 0.54)), "tobillo": V((0.29, 0.02, 0.17)),
    "punta_pie": V((0.29, -0.16, 0.04)),
    "cola0": V((0, 0.38, 1.02)), "cola1": V((0, 0.56, 0.86)), "cola2": V((0, 0.67, 0.67)),
    "cola3": V((0, 0.71, 0.47)),
    "oreja": V((0.43, -0.02, 2.48)), "oreja_punta": V((0.78, 0.0, 2.36)),
}
P = PUNTOS
K_CABEZA = 1.16
PIVOTE_CABEZA = V((0, -0.04, 1.96))


def H(p):
    """Lleva un punto de la cabeza a la cabeza agrandada."""
    return PIVOTE_CABEZA + (V(p) - PIVOTE_CABEZA) * K_CABEZA


def agrandar(objs):
    for o in objs:
        for v in o.data.vertices:
            v.co = H(v.co)
    return objs


P_ORIG = {k: v.copy() for k, v in PUNTOS.items()}
for _k in ("cabeza", "coronilla", "bisagra", "menton", "boca", "oreja", "oreja_punta"):
    PUNTOS[_k] = H(PUNTOS[_k])

# --- Colores (lineales) -----------------------------------------------------------------
PELO = (0.26, 0.085, 0.03)
PELO_OSC = (0.085, 0.028, 0.012)
CREMA = (0.78, 0.5, 0.27)
HOCICO = (0.85, 0.5, 0.38)
ROSA = (0.82, 0.32, 0.33)
BOCA = (0.25, 0.03, 0.04)
LENGUA = (0.85, 0.25, 0.3)
CUERO = (0.12, 0.045, 0.02)
CUERO_ROJO = (0.2, 0.025, 0.02)
ORO = (1.0, 0.62, 0.12)
MARFIL = (0.86, 0.76, 0.56)


def suave(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


def cuerpo_bloques():
    b = []
    # Tronco en pera: cadera ancha, panza redonda, pecho y hombros.
    b.append(masa("Pelvis", (0, 0.03, 1.02), (0.44, 0.38, 0.3)))
    b.append(masa("Panza", (0, -0.07, 1.27), (0.5, 0.46, 0.42)))
    b.append(masa("Pecho", (0, -0.02, 1.6), (0.46, 0.36, 0.3)))
    b.append(masa("Hombros", (0, 0.03, 1.75), (0.5, 0.3, 0.17)))
    b.append(masa("Cuello", (0, -0.02, 1.9), (0.26, 0.24, 0.16)))
    b += simetrico(lambda s: [
        masa(f"Deltoide{s}", (s * 0.44, 0.0, 1.73), (0.17, 0.17, 0.17)),
        masa(f"Gluteo{s}", (s * 0.2, 0.18, 1.0), (0.24, 0.2, 0.22)),
        masa(f"Muslo{s}", (s * 0.28, -0.04, 0.78), (0.2, 0.21, 0.27)),
        masa(f"Pantorrilla{s}", (s * 0.29, 0.03, 0.38), (0.14, 0.15, 0.19)),
        masa(f"Biceps{s}", (s * 0.55, 0.0, 1.55), (0.16, 0.16, 0.21), (0, s * -22, 0)),
        masa(f"Antebrazo{s}", (s * 0.66, -0.01, 1.24), (0.17, 0.17, 0.2), (0, s * -10, 0)),
        masa(f"Mano{s}", (s * 0.71, -0.07, 0.95), (0.17, 0.16, 0.16)),
    ])
    # Huesos de brazos, piernas y la cola (cadenas de piel).
    b += simetrico(lambda s: [
        piel(f"Brazo{s}", [(s * P["hombro"].x, 0.0, P["hombro"].z, 0.13), (s * P["codo"].x, P["codo"].y, P["codo"].z, 0.11),
                           (s * P["muneca"].x, P["muneca"].y, P["muneca"].z, 0.1)]),
        piel(f"Pierna{s}", [(s * 0.27, 0.0, 0.96, 0.19), (s * 0.29, -0.06, 0.54, 0.14),
                            (s * 0.29, 0.02, 0.2, 0.12), (s * 0.29, -0.02, 0.1, 0.13)]),
    ])
    # Dedos gorditos (tres y pulgar), un poco cerrados.
    for s in (1, -1):
        for i, dx in enumerate((-0.07, 0.0, 0.07)):
            x = s * (0.72 + dx * 0.4)
            y = -0.13 + abs(dx) * 0.4
            b.append(piel(f"Dedo{s}{i}", [(x + s * dx * 0.3, y, 0.92, 0.055), (x + s * dx * 0.5, y - 0.06, 0.84, 0.05),
                                          (x + s * dx * 0.55, y - 0.04, 0.77, 0.042)], subdiv=1))
        b.append(piel(f"Pulgar{s}", [(s * 0.62, -0.13, 1.0, 0.05), (s * 0.6, -0.2, 0.95, 0.042)], subdiv=1))
    b.append(piel("Cola", [(0, 0.3, 1.04, 0.07), (0, 0.5, 0.92, 0.05), (0, 0.62, 0.74, 0.04),
                           (0, 0.68, 0.56, 0.035), (0, 0.7, 0.48, 0.03)], subdiv=1))
    for o in cabeza_bloques():
        o.location = H(o.location)
        o.scale = o.scale * K_CABEZA
        b.append(o)
    return b


def cabeza_bloques():
    b = [
        masa("Craneo", (0, -0.04, 2.38), (0.5, 0.45, 0.44)),
        masa("Frente", (0, -0.2, 2.47), (0.4, 0.3, 0.3)),
        masa("Carrillos", (0, -0.22, 2.18), (0.47, 0.34, 0.26)),
        masa("Hocico", (0, -0.42, 2.12), (0.36, 0.27, 0.22), (-6, 0, 0)),
        masa("Morro", (0, -0.6, 2.13), (0.3, 0.12, 0.17)),
        masa("Nuca", (0, 0.12, 2.22), (0.36, 0.3, 0.3)),
    ]
    b += simetrico(lambda s: [
        masa(f"Ceja{s}", (s * 0.24, -0.4, 2.6), (0.15, 0.09, 0.06), (0, s * -12, s * -18)),
        masa(f"Mejilla{s}", (s * 0.3, -0.34, 2.22), (0.16, 0.14, 0.13)),
    ])
    return b


def colores_cuerpo(pos, nrm):
    x, y, z = pos
    c = PELO
    # Lomo y nuca un poco más oscuros.
    c = mezcla(c, PELO_OSC, max(0.0, nrm.y) * 0.35 * (1 if z > 0.9 else 0.4))
    # Panza y pecho crema (óvalo al frente).
    panza = cerca(pos, (0, -0.42, 1.33), 0.46, 0.55) * suave(-nrm.y * 1.6 + 0.2)
    c = mezcla(c, CREMA, panza)
    # Marcas doradas en los hombros (como las de la orca): dos arcos alrededor del deltoide.
    if 1.45 < z < 1.95 and abs(x) > 0.28:
        d = (V((abs(x), y, z)) - V((0.46, 0.0, 1.76))).length
        marca = max(0.0, 1 - abs(d - 0.12) / 0.022) + max(0.0, 1 - abs(d - 0.2) / 0.018) * (1 if z > 1.68 else 0)
        c = mezcla(c, (1.0, 0.5, 0.08), min(1.0, marca) * suave(nrm.z * 2 + abs(nrm.x)))
    # Calcetines oscuros en manos y patas.
    c = mezcla(c, PELO_OSC, suave((0.36 - z) / 0.18))
    if abs(x) > 0.5 and z < 1.6:
        c = mezcla(c, PELO_OSC, suave((1.18 - z) / 0.2))
    # Cabeza: hocico crema-rosado, nariz rosa, boca roja por dentro, estrella en la frente.
    if z > 1.85:
        hocico = cerca(pos, H((0, -0.5, 2.12)), 0.46, 0.5) * suave(-nrm.y * 1.5 + 0.5)
        c = mezcla(c, HOCICO, hocico)
        c = mezcla(c, ROSA, cerca(pos, H((0, -0.72, 2.15)), 0.23, 0.35))
        estrella = cerca(pos, H((0, -0.34, 2.62)), 0.23, 0.3) * suave(-nrm.y * 2)
        c = mezcla(c, CREMA, estrella)
        # Línea de la boca y la boca por dentro (debajo del hocico, se ve al abrir la mandíbula).
        if z < H((0, 0, 2.03)).z and nrm.z < -0.35 and y < -0.3:
            c = mezcla(c, BOCA, suave((-nrm.z - 0.35) * 3))
    v = 0.9 + 0.2 * ruido(pos, 5.0)
    return tuple(min(1.0, k * v) for k in c)


def mechon():
    """Mechón esponjoso entre los cuernos: varias puntas que se curvan hacia adelante."""
    piezas = []
    for i, (dx, dy, alto, inclina) in enumerate(((0, -0.02, 0.36, 0.2), (0.13, 0.04, 0.28, 0.12),
                                                  (-0.13, 0.04, 0.28, 0.12), (0.07, -0.12, 0.24, 0.32),
                                                  (-0.07, -0.12, 0.24, 0.32), (0, 0.12, 0.22, 0.05))):
        base = V((dx, -0.06 + dy, 2.74))
        pts = [(base.x, base.y, base.z, 0.11),
               (base.x * 1.2, base.y - inclina * 0.4, base.z + alto * 0.55, 0.07),
               (base.x * 1.35, base.y - inclina, base.z + alto * 0.85, 0.035),
               (base.x * 1.4, base.y - inclina * 1.5, base.z + alto * 0.8, 0.008)]
        piezas.append(piel(f"Mechon{i}", pts, subdiv=2))
    m = unir("Mechon", piezas)
    pintar(m, lambda p, n: mezcla(PELO_OSC, PELO, suave((p.z - 2.8) / 0.25) * 0.6))
    return m


def oreja(s):
    o0, o1 = P_ORIG["oreja"], P_ORIG["oreja_punta"]
    pts = [(s * o0.x, o0.y, o0.z, (0.06, 0.1)), (s * (o0.x + 0.14), o0.y - 0.01, o0.z - 0.02, (0.06, 0.13)),
           (s * (o1.x - 0.08), o1.y - 0.01, o1.z + 0.02, (0.045, 0.1)), (s * o1.x, o1.y, o1.z, (0.02, 0.03))]
    o = piel(f"Oreja{s}", pts, subdiv=2)
    aplicar(o)
    # Rosa por dentro (cara de adelante), pelo por fuera.
    pintar(o, lambda p, n: mezcla(PELO, ROSA, suave(-n.y * 2.2 - 0.3) * suave((abs(p.x) - 0.5) / 0.08)))
    return o


def cuerno(s):
    pts = [(s * 0.27, -0.06, 2.66, 0.1), (s * 0.4, -0.08, 2.78, 0.085), (s * 0.5, -0.12, 2.93, 0.065),
           (s * 0.52, -0.18, 3.06, 0.04), (s * 0.48, -0.22, 3.12, 0.008)]
    h = piel(f"Cuerno{s}", pts, subdiv=2)
    aplicar(h)
    pintar(h, lambda p, n: mezcla(MARFIL, (0.98, 0.93, 0.82), suave((p.z - 2.8) / 0.3)))
    return h


def anillo(nombre, centro, radio_mayor, radio_menor, rot=(0, 0, 0), escala=(1, 1, 1), color=ORO):
    bpy.ops.mesh.primitive_torus_add(location=centro, major_radius=radio_mayor, minor_radius=radio_menor,
                                     major_segments=32, minor_segments=10,
                                     rotation=tuple(math.radians(a) for a in rot))
    o = bpy.context.active_object
    o.name = nombre
    o.scale = escala
    bpy.ops.object.shade_smooth()
    aplicar(o)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    pintar(o, lambda p, n: tuple(k * (0.85 + 0.3 * max(0.0, n.z)) for k in color))
    return o


def ojo(s):
    """Ojo enorme y brillante: blanco, iris ámbar con borde oscuro, pupila y dos brillos."""
    centro = V((s * 0.245, -0.4, 2.43))
    frente = V((s * 0.38, -1.0, 0.04)).normalized()
    o = masa(f"Ojo{s}", tuple(centro), (0.15, 0.13, 0.165), segmentos=48)
    aplicar(o)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    arriba = V((0, 0, 1))
    derecha = frente.cross(arriba).normalized()
    arriba = derecha.cross(frente).normalized()

    def color(p, n):
        d = (V(p) - centro).normalized()
        ang = math.acos(max(-1.0, min(1.0, d.dot(frente))))
        lx, ly = d.dot(derecha), d.dot(arriba)
        if ang > 0.78:
            return (0.92, 0.92, 0.95)
        if ang > 0.7:
            return (0.08, 0.03, 0.01)
        if ang < 0.34:
            c = (0.01, 0.006, 0.004)
        else:
            t = (ang - 0.34) / 0.36
            c = mezcla((1.0, 0.55, 0.06), (0.55, 0.18, 0.02), t)
            c = mezcla(c, (0.35, 0.1, 0.01), suave(ly * 2.5))  # arriba más oscuro
        # Brillos: uno grande arriba a un lado y uno chico abajo al otro.
        if (lx + s * 0.22) ** 2 + (ly - 0.28) ** 2 < 0.018 or (lx - s * 0.18) ** 2 + (ly + 0.22) ** 2 < 0.005:
            return (1.0, 1.0, 1.0)
        return c
    pintar(o, color)
    return o


def pezuna(s):
    o = masa(f"Pezuna{s}", (s * 0.29, -0.04, 0.06), (0.15, 0.19, 0.09), segmentos=32)
    aplicar(o)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    pintar(o, lambda p, n: (0.04, 0.03, 0.03) if abs(p.x - s * 0.29) > 0.012 or p.y > -0.1 else (0.01, 0.01, 0.01))
    return o


def tira(nombre, angulo, largo, ancho):
    """Tira de cuero del faldón, colgando del cinturón con un remache de oro."""
    a = math.radians(angulo)
    rx, ry = 0.47, 0.42
    base = V((math.sin(a) * rx, -math.cos(a) * ry, 0.98))
    bpy.ops.mesh.primitive_cube_add(location=base - V((0, 0, largo / 2)))
    o = bpy.context.active_object
    o.name = nombre
    o.scale = (ancho / 2, 0.025, largo / 2)
    o.rotation_euler = (math.radians(-6), 0, a)
    bis = o.modifiers.new("Bisel", "BEVEL")
    bis.width, bis.segments = 0.02, 2
    aplicar(o)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    # Empuja la tira hacia afuera con el largo (falda en campana).
    for v in o.data.vertices:
        caida = max(0.0, 0.98 - v.co.z)
        v.co.x += math.sin(a) * caida * 0.25
        v.co.y += -math.cos(a) * caida * 0.25
    pintar(o, lambda p, n: mezcla(CUERO_ROJO, (0.06, 0.012, 0.01), suave((0.98 - p.z) / largo - 0.4)))
    return o


def remache(nombre, angulo):
    a = math.radians(angulo)
    o = masa(nombre, (math.sin(a) * 0.5, -math.cos(a) * 0.45, 0.9), (0.035, 0.035, 0.035), segmentos=12)
    aplicar(o)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    pintar(o, lambda p, n: ORO)
    return o


def accesorios():
    o = []
    # Cinturón de cuero (anillo aplastado) y hebilla de oro con un aro.
    o.append(anillo("Cinturon", (0, 0.02, 1.0), 0.45, 0.06, escala=(1.02, 0.92, 1.0), color=CUERO))
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.12, depth=0.06, location=(0, -0.42, 1.0),
                                        rotation=(math.radians(90), 0, 0))
    heb = bpy.context.active_object
    heb.name = "Hebilla"
    bis = heb.modifiers.new("Bisel", "BEVEL")
    bis.width, bis.segments = 0.02, 3
    aplicar(heb)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    pintar(heb, lambda p, n: ORO if (V((p.x, 0, p.z - 1.0)).length > 0.06 or n.y > -0.5) else (0.6, 0.06, 0.04))
    o.append(heb)
    # Faldón de tiras (de adelante a los costados; atrás va la cola).
    for i, ang in enumerate((-110, -80, -52, -26, 0, 26, 52, 80, 110)):
        o.append(tira(f"Tira{i}", ang, 0.32 if abs(ang) < 60 else 0.26, 0.17))
        o.append(remache(f"Remache{i}", ang))
    # Brazaletes de oro en las muñecas y aro en la nariz.
    for s in (1, -1):
        o.append(anillo(f"Brazalete{s}", (s * 0.685, -0.03, 1.13), 0.135, 0.035, rot=(0, s * -8, 0)))
    o.append(anillo("AroNariz", (0, -0.73, 2.05), 0.075, 0.018, rot=(90, 0, 0)))
    return o


def mandibula():
    m = masa("Mandibula", (0, -0.4, 1.97), (0.27, 0.22, 0.09), (-4, 0, 0))
    aplicar(m)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    pintar(m, lambda p, n: LENGUA if n.z > 0.5 else mezcla(HOCICO, PELO, suave((p.y + 0.3) / 0.15)))
    return m


def borla():
    """Borla de pelo oscuro al final de la cola."""
    piezas = []
    for i in range(6):
        a = i * math.tau / 6
        pts = [(0, 0.71, 0.5, 0.05), (math.cos(a) * 0.05, 0.71 + math.sin(a) * 0.05, 0.4, 0.05),
               (math.cos(a) * 0.08, 0.72 + math.sin(a) * 0.08, 0.3, 0.02)]
        piezas.append(piel(f"Borla{i}", pts, subdiv=1))
    b = unir("Borla", piezas)
    pintar(b, lambda p, n: PELO_OSC)
    return b


def construir_minotauro_e1(voxel=0.014):
    cuerpo = fusionar("MinoE1_Cuerpo", cuerpo_bloques(), voxel=voxel, suavizado=24)
    detalle(cuerpo, fuerza=0.006, escala=0.035)
    pintar(cuerpo, colores_cuerpo)
    pelaje = mat_pelaje("MinoE1_Pelaje", rugosidad=0.8, bulto=0.35, escala_pelo=260.0)
    asignar(cuerpo, pelaje)
    brillo = mat_simple("MinoE1_Brillo", (1, 1, 1), 0.2)
    _vc(brillo)
    metal = mat_simple("MinoE1_Oro", (1, 1, 1), 0.3, metal=1.0)
    _vc(metal)
    cuero = mat_simple("MinoE1_Cuero", (1, 1, 1), 0.75)
    _vc(cuero)
    partes = {cuerpo: None}
    cabeza = []
    for s, lado in ((1, "Izq"), (-1, "Der")):
        cabeza.append(asignar(oreja(s), pelaje)); partes[cabeza[-1]] = f"Oreja{lado}"
        cabeza.append(asignar(cuerno(s), brillo)); partes[cabeza[-1]] = "Cabeza"
        cabeza.append(asignar(ojo(s), brillo)); partes[cabeza[-1]] = "Cabeza"
        cabeza.append(asignar(anillo(f"AnilloCuerno{s}", (s * 0.47, -0.12, 2.9), 0.075, 0.025, rot=(0, s * 30, 0)), metal))
        partes[cabeza[-1]] = "Cabeza"
        partes[asignar(pezuna(s), brillo)] = f"Pie{lado}"
    cabeza.append(asignar(mechon(), pelaje)); partes[cabeza[-1]] = "Cabeza"
    cabeza.append(asignar(mandibula(), pelaje)); partes[cabeza[-1]] = "Mandibula"
    partes[asignar(borla(), pelaje)] = "Cola3"
    for a in accesorios():
        hueso = "Cadera"
        if a.name.startswith("Brazalete"):
            hueso = "AntebrazoDer" if a.name.endswith("-1") else "AntebrazoIzq"
        elif a.name == "AroNariz":
            hueso = "Cabeza"
        dorado = a.name == "Hebilla" or a.name.startswith(("Brazalete", "Aro", "Remache"))
        partes[asignar(a, metal if dorado else cuero)] = hueso
        if a.name == "AroNariz":
            cabeza.append(a)
    agrandar(cabeza)
    for o, hueso in partes.items():
        o["hueso"] = hueso or ""
    return list(partes), {o.name: h for o, h in partes.items()}


def _vc(mat):
    """El color base sale del color por vértice ("Color")."""
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    col = nt.nodes.new("ShaderNodeVertexColor")
    col.layer_name = "Color"
    nt.links.new(col.outputs["Color"], bsdf.inputs["Base Color"])
