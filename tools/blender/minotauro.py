"""
Minotauro de Gigantes en 4 etapas: crece y se vuelve más feroz.
    E1  becerro: rechoncho, cabeza grande, cuernitos, pelaje claro
    E2  joven: más alto, cuernos medianos, taparrabos
    E3  adulto: musculoso, cuernos grandes, hombrera, cinturón y aro en la nariz
    E4  forma final: enorme, pelaje negro rojizo, armadura dorada, ojos y grietas de lava
Requiere criaturas.py cargado antes (exec). construir_minotauro(etapa) -> lista de objetos.
"""
import math

ETAPAS = {
    1: dict(m=0.78, k=1.75, c=0.3, panza=1.25, pelo=(0.3, 0.16, 0.08), ojos="oscuros",
            taparrabos=False, hombrera=False, aro=False, armadura=False, lava=False),
    2: dict(m=0.95, k=1.5, c=0.55, panza=1.0, pelo=(0.18, 0.09, 0.045), ojos="oscuros",
            taparrabos=True, hombrera=False, aro=False, armadura=False, lava=False),
    3: dict(m=1.15, k=1.42, c=0.8, panza=0.92, pelo=(0.1, 0.05, 0.028), ojos="ambar",
            taparrabos=True, hombrera=True, aro=True, armadura=False, lava=False),
    4: dict(m=1.32, k=1.38, c=1.0, panza=0.88, pelo=(0.045, 0.024, 0.018), ojos="lava",
            taparrabos=True, hombrera=True, aro=True, armadura=True, lava=True),
}


def _cuerpo(e):
    m, k, p = e["m"], e["k"], e["panza"]
    b = []
    # Columna, cuello y cola.
    b.append(piel("Columna", [(0, 0.06, 1.4, 0.34 * m), (0, 0.02, 1.68, 0.32 * m * p),
                              (0, 0.0, 2.0, 0.42 * m), (0, 0.02, 2.3, 0.46 * m),
                              (0, -0.06, 2.55, 0.3 * m), (0, HY, HZ - 0.12, 0.26 * k)]))
    b.append(piel("Cola", [(0, 0.32, 1.4, 0.07), (0, 0.6, 1.15, 0.05), (0, 0.72, 0.85, 0.04),
                           (0, 0.74, 0.62, 0.035)], subdiv=1))
    b.append(masa("Mechon", (0, 0.75, 0.55), (0.07, 0.07, 0.14)))
    # Torso musculoso.
    b.append(masa("Panza", (0, -0.12, 1.72), (0.36 * m * p, 0.3 * m * p, 0.34)))
    b.append(masa("Abdomen", (0, -0.25 * m, 1.85), (0.2 * m, 0.13 * m, 0.3)))
    b.append(masa("Trapecio", (0, 0.12, 2.5), (0.42 * m, 0.3 * m, 0.24 * m)))
    b += simetrico(lambda s: [
        masa(f"Pectoral{s}", (s * 0.22 * m, -0.27 * m, 2.2), (0.27 * m, 0.16 * m, 0.19 * m), (0, 0, s * 8)),
        masa(f"Dorsal{s}", (s * 0.4 * m, 0.08, 2.05), (0.17 * m, 0.24 * m, 0.33)),
        masa(f"Deltoide{s}", (s * 0.64 * m, -0.02, 2.36), (0.21 * m, 0.21 * m, 0.23 * m)),
        masa(f"Biceps{s}", (s * 0.78 * m, -0.1, 2.08), (0.19 * m, 0.19 * m, 0.27), (0, s * -10, 0)),
        masa(f"Triceps{s}", (s * 0.8 * m, 0.08, 2.08), (0.17 * m, 0.17 * m, 0.25)),
        masa(f"Antebrazo{s}", (s * 0.94 * m, -0.12, 1.62), (0.19 * m, 0.19 * m, 0.27), (0, s * -8, 0)),
        masa(f"Mano{s}", (s * 0.99 * m, -0.18, 1.3), (0.1 * m, 0.12 * m, 0.12 * m)),
        masa(f"Gluteo{s}", (s * 0.22 * m, 0.22, 1.32), (0.22 * m, 0.18, 0.22)),
        masa(f"Muslo{s}", (s * 0.36 * m, -0.06, 1.08), (0.24 * m, 0.25 * m, 0.34), (s * 0, 0, 0)),
        masa(f"Pantorrilla{s}", (s * 0.36 * m, 0.1, 0.55), (0.13 * m, 0.14 * m, 0.22)),
    ])
    # Dedos gruesos, un poco cerrados (mano de garra), y pulgar.
    for s_ in (1, -1):
        for i in range(3):
            x = s_ * (0.95 + 0.05 * i) * m
            b.append(piel(f"Dedo{s_}{i}", [(x, -0.24 * m, 1.3, 0.042 * m), (x, -0.33 * m, 1.22, 0.036 * m),
                                           (x, -0.33 * m, 1.12, 0.03 * m), (x, -0.28 * m, 1.06, 0.022 * m)], subdiv=1))
        b.append(piel(f"Pulgar{s_}", [(s_ * 0.92 * m, -0.2 * m, 1.34, 0.04 * m),
                                      (s_ * 0.9 * m, -0.3 * m, 1.3, 0.032 * m),
                                      (s_ * 0.91 * m, -0.34 * m, 1.24, 0.024 * m)], subdiv=1))
    # Brazos y piernas (huesos), piernas de toro con corvejón hacia atrás.
    b += simetrico(lambda s: [
        piel(f"Brazo{s}", [(s * 0.6 * m, 0.0, 2.38, 0.17 * m), (s * 0.86 * m, -0.04, 1.86, 0.13 * m),
                           (s * 0.96 * m, -0.14, 1.42, 0.11 * m), (s * 0.99 * m, -0.2, 1.28, 0.12 * m)]),
        piel(f"Pierna{s}", [(s * 0.3 * m, 0.04, 1.38, 0.24 * m), (s * 0.36 * m, -0.14, 0.8, 0.15 * m),
                            (s * 0.35 * m, 0.14, 0.42, 0.11 * m), (s * 0.34 * m, 0.02, 0.16, 0.09 * m),
                            (s * 0.34 * m, -0.04, 0.09, 0.1 * m)]),
    ])
    b += cabeza_toro(k)
    return b


HZ = 2.74  # alto del centro de la cabeza
HY = -0.22  # la cabeza va adelantada sobre el cuello (postura de embestida)


def cabeza_toro(k):
    """Cabeza de toro: cráneo ancho y plano, frente inclinada, hocico ancho y
    chato, mandíbula, carrillos, cejas óseas y orejas de lado."""
    def P(x, y, z):
        return (x * k, HY + y * k, HZ + z * k)
    b = [
        masa("Craneo", P(0, 0, 0.08), (0.27 * k, 0.25 * k, 0.2 * k)),
        masa("Testuz", P(0, 0.02, 0.22), (0.22 * k, 0.13 * k, 0.08 * k)),
        masa("Frente", P(0, -0.25, 0.02), (0.2 * k, 0.22 * k, 0.14 * k), (-25, 0, 0)),
        masa("Hocico", P(0, -0.55, -0.12), (0.19 * k, 0.2 * k, 0.15 * k), (-8, 0, 0)),
        masa("Morro", P(0, -0.73, -0.14), (0.2 * k, 0.07 * k, 0.13 * k)),
        masa("Mandibula", P(0, -0.48, -0.27), (0.14 * k, 0.25 * k, 0.07 * k), (-6, 0, 0)),
        masa("Papada", P(0, 0.05, -0.28), (0.2 * k, 0.18 * k, 0.15 * k)),
    ]
    b += simetrico(lambda s: [
        masa(f"Carrillo{s}", P(s * 0.16, -0.3, -0.12), (0.11 * k, 0.17 * k, 0.13 * k)),
        masa(f"Ceja{s}", P(s * 0.16, -0.37, 0.08), (0.1 * k, 0.07 * k, 0.05 * k), (0, 0, s * -20)),
        masa(f"Oreja{s}", P(s * 0.36, -0.1, 0.05), (0.15 * k, 0.05 * k, 0.07 * k), (s * 15, 0, s * -15)),
    ])
    return b


def _colores(e, hz=2.88):
    pelo = tuple(c * c * 1.6 for c in e["pelo"])  # a lineal: los colores de ETAPAS son "a ojo"
    claro = tuple(min(1, c * 1.8 + 0.01) for c in pelo)
    morro = (0.12, 0.075, 0.06) if e["c"] < 0.9 else (0.05, 0.03, 0.025)
    nariz = (0.05, 0.04, 0.04)
    k = e["k"]

    def regla(pos, normal):
        c = pelo
        # Pecho y panza un poco más claros; lomo y hombros más oscuros.
        c = mezcla(c, claro, max(0, -normal.y) * 0.35 * (1 if 1.5 < pos.z < 2.4 else 0.3))
        c = mezcla(c, tuple(x * 0.6 for x in pelo), max(0, normal.y) * 0.4)
        # Patas oscuras abajo (calcetín de toro).
        c = mezcla(c, tuple(x * 0.5 for x in pelo), (0.55 - pos.z) / 0.4)
        # Hocico claro y nariz negra.
        c = mezcla(c, morro, cerca(pos, (0, HY - 0.64 * k, HZ - 0.15 * k), 0.24 * k))
        c = mezcla(c, nariz, cerca(pos, (0, HY - 0.8 * k, HZ - 0.14 * k), 0.12 * k, 0.4))
        # Variación natural del pelaje.
        v = 0.85 + 0.3 * ruido(pos, 4.0)
        return tuple(min(1, x * v) for x in c)
    return regla


def tela(nombre, centro, medio, inclinacion):
    """Paño de cuero: caja delgada con bordes redondeados, un poco inclinada."""
    bpy.ops.mesh.primitive_cube_add(location=centro)
    obj = bpy.context.active_object
    obj.name = nombre
    obj.scale = medio
    obj.rotation_euler = (math.radians(inclinacion), 0, 0)
    bisel = obj.modifiers.new("Bisel", "BEVEL")
    bisel.width = 0.015
    bisel.segments = 3
    bpy.ops.object.shade_smooth()
    return obj


def _detalles(e, etapa, hz=2.88):
    m, k, c = e["m"], e["k"], e["c"]
    o = []
    cuerno_mat = mat_cuerno(f"MinoCuerno{etapa}", eje="Y")
    oscuro = mat_simple(f"MinoPezuna{etapa}", (0.04, 0.035, 0.035), 0.35)
    ojos = {"oscuros": ((0.005, 0.004, 0.004), None, 0),
            "ambar": ((0.9, 0.5, 0.05), (0.9, 0.45, 0.05), 3),
            "lava": ((1.0, 0.25, 0.02), (1.0, 0.25, 0.02), 12)}[e["ojos"]]
    ojo_mat = mat_simple(f"MinoOjo{etapa}", ojos[0], 0.1, emision=ojos[1], fuerza=ojos[2])

    def cuerno(s):
        y0, z0 = HY - 0.06 * k, HZ + 0.2 * k
        pts = [(s * 0.18 * k, y0, z0, 0.1 * k),
               (s * (0.2 + 0.25 * c) * k, y0 + 0.02 * k, z0 + 0.03 * k, 0.085 * k),
               (s * (0.22 + 0.46 * c) * k, y0 - 0.04 * k, z0 + 0.12 * c * k, 0.065 * k),
               (s * (0.24 + 0.56 * c) * k, y0 - 0.18 * c * k, z0 + 0.32 * c * k, 0.04 * k),
               (s * (0.22 + 0.52 * c) * k, y0 - 0.34 * c * k, z0 + 0.48 * c * k, 0.008)]
        h = piel(f"Cuerno{s}", pts, subdiv=2)
        aplicar(h)
        pintar(h, lambda p, n: mezcla((0.82, 0.74, 0.58), (0.16, 0.12, 0.09),
                                      (abs(p.x) - 0.25 * k) / max(0.2, 0.5 * c * k)))
        return asignar(h, cuerno_mat)

    o += simetrico(cuerno)
    o += simetrico(lambda s: asignar(masa(f"Ojo{s}", (s * 0.205 * k, HY - 0.4 * k, HZ + 0.0 * k),
                                          (0.03 * k, 0.05 * k, 0.04 * k), (0, 0, s * -30)), ojo_mat))
    o += simetrico(lambda s: asignar(masa(f"Narina{s}", (s * 0.08 * k, HY - 0.8 * k, HZ - 0.12 * k),
                                          (0.04 * k, 0.02 * k, 0.03 * k)), oscuro))
    # Pezuñas partidas.
    o += simetrico(lambda s: [asignar(masa(f"Pezuna{s}{t}", (s * 0.34 * m + t * 0.055 * m, -0.07, 0.07),
                                           (0.07 * m, 0.14 * m, 0.07)), oscuro) for t in (-1, 1)])
    cuero = mat_simple(f"MinoCuero{etapa}", (0.035, 0.02, 0.01), 0.75, rayones=0.15)
    metal = mat_simple(f"MinoMetal{etapa}", (0.95, 0.68, 0.22) if e["armadura"] else (0.5, 0.5, 0.54),
                       0.28, metal=1.0, rayones=0.12)
    if e["taparrabos"]:
        o.append(asignar(piel("Cinturon", [(0, 0.02, 1.47, (0.42 * m, 0.36 * m)),
                                           (0, 0.02, 1.4, (0.43 * m, 0.37 * m))], subdiv=1), cuero))
        o.append(asignar(tela("Taparrabos", (0, -0.37 * m, 1.12), (0.2 * m, 0.02, 0.3), 8), cuero))
        o.append(asignar(tela("TaparrabosAtras", (0, 0.42 * m, 1.14), (0.22 * m, 0.02, 0.28), -8), cuero))
        o.append(asignar(masa("Hebilla", (0, -0.38 * m, 1.44), (0.09, 0.03, 0.07)), metal))
    if e["hombrera"]:
        lados = (1, -1) if e["armadura"] else (1,)
        for s in lados:
            o.append(asignar(masa(f"Hombrera{s}", (s * 0.66 * m, 0.0, 2.5), (0.3 * m, 0.28 * m, 0.17 * m), (0, s * 20, 0)), metal))
            for i in range(3):
                pua = piel(f"Pua{s}{i}", [(s * (0.58 + 0.11 * i) * m, -0.08 + 0.08 * i, 2.62, 0.055),
                                          (s * (0.66 + 0.15 * i) * m, -0.06 + 0.08 * i, 2.95, 0.006)], subdiv=1)
                o.append(asignar(pua, metal))
    if e["aro"]:
        bpy.ops.mesh.primitive_torus_add(location=(0, HY - 0.81 * k, HZ - 0.24 * k), major_radius=0.08 * k,
                                         minor_radius=0.016 * k, rotation=(math.radians(90), 0, 0))
        aro = bpy.context.active_object
        aro.name = "AroNariz"
        bpy.ops.object.shade_smooth()
        o.append(asignar(aro, metal))
    if e["armadura"]:
        o += simetrico(lambda s: asignar(piel(f"Brazal{s}", [(s * 0.95 * m, -0.13, 1.68, 0.17 * m),
                                                              (s * 0.98 * m, -0.18, 1.42, 0.15 * m)], subdiv=1), metal))
        o.append(asignar(piel("Collar", [(0, -0.02, 2.5, (0.36 * m, 0.32 * m)),
                                         (0, -0.04, 2.58, (0.34 * m, 0.3 * m))], subdiv=1), metal))
    return o


def construir_minotauro(etapa, voxel=0.016):
    e = ETAPAS[etapa]
    cuerpo = fusionar(f"MinotauroE{etapa}_Cuerpo", _cuerpo(e), voxel=voxel)
    detalle(cuerpo, fuerza=0.008, escala=0.04)
    pintar(cuerpo, _colores(e))
    if e["lava"]:
        # Grietas de lava: vetas de ruido en brazos, pecho y piernas (capa "Brillo").
        def grietas(pos, normal):
            v = abs(noise.noise(Vector(pos) * 3.0))
            fuerza = max(0.0, 1 - v / 0.035) * (1 if pos.z < 2.5 else 0)
            return (fuerza, fuerza * 0.28, 0.0)
        pintar(cuerpo, grietas, capa="Brillo")
        cuerpo.data.color_attributes.active_color = cuerpo.data.color_attributes["Color"]
    asignar(cuerpo, mat_pelaje(f"MinoPelaje{etapa}", capa_brillo="Brillo" if e["lava"] else None))
    return [cuerpo] + _detalles(e, etapa)
