"""
Dragón marino de Gigantes en 4 etapas. Sale del agua: el cuerpo de
serpiente sube en S desde la base (línea del agua) hasta la cabeza.
    E1  cría: cuerpo corto, ojos grandes, aletitas, cuernitos
    E2  joven: más largo, cresta de aleta en el lomo y bigotes
    E3  adulto: púas en el lomo, aletas laterales grandes, colmillos
    E4  forma final: corona de cuernos, melena de aletas y manchas que brillan
Requiere criaturas.py. construir_dragon(etapa, voxel) -> lista de objetos.
"""
import math

DRAGON = {
    1: dict(largo=0.8, grosor=0.85, cabeza=1.35, cuerno=0.35, cresta=False, puas=False, aletas=0.6,
            colmillos=False, corona=False, brillo=False, lomo=(0.05, 0.32, 0.4), panza=(0.55, 0.62, 0.42)),
    2: dict(largo=1.0, grosor=1.0, cabeza=1.15, cuerno=0.6, cresta=True, puas=False, aletas=0.85,
            colmillos=False, corona=False, brillo=False, lomo=(0.03, 0.24, 0.36), panza=(0.5, 0.56, 0.38)),
    3: dict(largo=1.12, grosor=1.15, cabeza=1.05, cuerno=0.95, cresta=True, puas=True, aletas=1.1,
            colmillos=True, corona=False, brillo=False, lomo=(0.02, 0.14, 0.26), panza=(0.42, 0.46, 0.3)),
    4: dict(largo=1.22, grosor=1.3, cabeza=1.0, cuerno=1.25, cresta=True, puas=True, aletas=1.35,
            colmillos=True, corona=True, brillo=True, lomo=(0.015, 0.06, 0.16), panza=(0.32, 0.34, 0.24)),
}


def _espina(e):
    L = e["largo"]
    # Curva en S: base ancha en el agua, cuerpo hacia atrás, cuello hacia adelante, cabeza arriba.
    # Curva en S de lado a lado (se ve de frente), saliendo del agua, cabeza mirando al frente.
    return [(0.0, 0.25 * L, 0.0), (0.55 * L, 0.3 * L, 0.6 * L), (-0.4 * L, 0.15 * L, 1.35 * L),
            (0.3 * L, 0.0, 2.05 * L), (0.0, -0.15 * L, 2.6 * L), (0.0, -0.3 * L, 2.95 * L)]


def _cuerpo_dragon(e):
    g = e["grosor"]
    control = _espina(e)
    pts = curva_puntos(control, 22, lambda t: (0.62 - 0.4 * t) * g * (1.15 if t < 0.15 else 1))
    b = [piel("Serpiente", pts, subdiv=2)]
    # Anillos del cuerpo enroscados en el agua, alrededor de la base.
    anillo = [(math.cos(a) * 0.95 * g, 0.25 + math.sin(a) * 0.95 * g, 0.12 + 0.05 * math.sin(3 * a), 0.3 * g)
              for a in [i * math.tau / 14 for i in range(15)]]
    b.append(piel("Anillo", anillo, subdiv=2))
    # Aletas-brazo delanteras (como una foca gigante) en la parte alta del cuerpo.
    alto = Vector(control[3])
    b += simetrico(lambda s: piel(f"Brazo{s}", [(alto.x + s * 0.25 * g, alto.y - 0.1, alto.z - 0.1, 0.16 * g),
                                                 (alto.x + s * 0.6 * g, alto.y - 0.35, alto.z - 0.35, 0.11 * g),
                                                 (alto.x + s * 0.8 * g, alto.y - 0.55, alto.z - 0.55, 0.07 * g)]))
    cabeza = Vector(control[-1])
    b += cabeza_dragon(cabeza, e)
    return b, control


def cabeza_dragon(c, e):
    k = e["cabeza"] * e["grosor"] * 1.4
    def P(x, y, z):
        return (c.x + x * k, c.y + y * k, c.z + z * k)
    b = [
        masa("Craneo", P(0, 0, 0.05), (0.3 * k, 0.34 * k, 0.24 * k)),
        masa("Hocico", P(0, -0.45, -0.02), (0.2 * k, 0.36 * k, 0.15 * k), (-6, 0, 0)),
        masa("Nariz", P(0, -0.8, 0.0), (0.15 * k, 0.1 * k, 0.1 * k)),
        masa("Mandibula", P(0, -0.42, -0.2), (0.17 * k, 0.36 * k, 0.08 * k), (8, 0, 0)),
    ]
    b += simetrico(lambda s: [
        masa(f"Ceja{s}", P(s * 0.17, -0.2, 0.16), (0.12 * k, 0.17 * k, 0.07 * k), (0, 0, s * -10)),
        masa(f"Pomulo{s}", P(s * 0.2, -0.1, -0.06), (0.12 * k, 0.16 * k, 0.12 * k)),
    ])
    return b


def _colores_dragon(e, control):
    lomo, panza = e["lomo"], e["panza"]
    cab = Vector(control[-1])
    def regla(pos, normal):
        # Vientre: solo una franja angosta al frente; el resto del cuerpo es lomo oscuro.
        t = min(1.0, max(0.0, -normal.y - 0.82) * 6 * max(0.0, 1 - abs(normal.x) * 3.0))
        c = mezcla(lomo, panza, t)
        # Placas del vientre (bandas) y rayas suaves en el lomo.
        placas = 0.7 + 0.3 * (1 if math.sin(pos.z * 14.0) > 0 else 0)
        franja = 0.75 + 0.25 * math.sin(pos.z * 9.0 + ruido(pos, 2) * 3)
        c = tuple(x * (franja if t < 0.5 else placas) for x in c)
        # Manchas claras en el lomo.
        c = mezcla(c, tuple(min(1, x * 2.2 + 0.05) for x in lomo), max(0, ruido(pos, 3.5) - 0.62) * 3)
        # Hocico y ojeras.
        c = mezcla(c, tuple(x * 0.5 for x in lomo), cerca(pos, cab + Vector((0, -0.75 * e["cabeza"], 0)), 0.2))
        return c
    return regla


def _brillo_dragon(e):
    def regla(pos, normal):
        if not e["brillo"]:
            return (0, 0, 0)
        v = ruido(pos, 7.0)
        lado = abs(normal.x) > 0.55
        f = 1.0 if (v > 0.74 and lado) else 0.0
        return (0.1 * f, 0.9 * f, 1.0 * f)
    return regla


def _aleta(nombre, centro, medio, rot):
    """Aleta: elipse muy plana con borde ondulado (bisel suave)."""
    obj = masa(nombre, centro, medio, rot, segmentos=24)
    return obj


def _detalles_dragon(e, control, etapa):
    o = []
    L, g = e["largo"], e["grosor"]
    cab = Vector(control[-1])
    k = e["cabeza"] * g * 1.4
    aleta_mat = mat_simple(f"DragonAleta{etapa}", (0.05, 0.45, 0.55) if not e["brillo"] else (0.02, 0.35, 0.5),
                           0.3, emision=(0.05, 0.6, 0.8) if e["brillo"] else None, fuerza=1.5 if e["brillo"] else 0)
    cuerno_mat = mat_cuerno(f"DragonCuerno{etapa}", eje="Z")
    ojo_mat = mat_simple(f"DragonOjo{etapa}", (1.0, 0.75, 0.1), 0.05,
                         emision=(1.0, 0.7, 0.1) if etapa >= 3 else None, fuerza=6 if etapa >= 3 else 0)
    diente = mat_simple(f"DragonDiente{etapa}", (0.9, 0.88, 0.8), 0.3)
    # Ojos almendrados metidos bajo la ceja, con pupila de reptil (raya negra).
    pupila = mat_simple(f"DragonPupila{etapa}", (0.01, 0.01, 0.01), 0.1)
    o += simetrico(lambda s: [
        asignar(masa(f"Ojo{s}", (cab.x + s * 0.235 * k, cab.y - 0.3 * k, cab.z + 0.09 * k),
                     (0.045 * k, 0.075 * k, 0.035 * k), (0, s * 10, s * -30)), ojo_mat),
        asignar(masa(f"Pupila{s}", (cab.x + s * 0.27 * k, cab.y - 0.32 * k, cab.z + 0.09 * k),
                     (0.012 * k, 0.02 * k, 0.03 * k), (0, 0, s * -30)), pupila),
    ])
    # Cuernos hacia atrás.
    c = e["cuerno"]
    def cuerno(s, dx=0.18, alto=0.0, largo=1.0):
        pts = [(cab.x + s * dx * k, cab.y + 0.1 * k, cab.z + (0.18 + alto) * k, 0.07 * k),
               (cab.x + s * (dx + 0.08) * k, cab.y + (0.1 + 0.35 * c * largo) * k, cab.z + (0.32 + alto) * k, 0.05 * k),
               (cab.x + s * (dx + 0.12) * k, cab.y + (0.1 + 0.7 * c * largo) * k, cab.z + (0.38 + alto + 0.12 * c) * k, 0.008)]
        h = piel(f"Cuerno{s}{dx}", pts, subdiv=2)
        aplicar(h)
        pintar(h, lambda p, n: mezcla((0.85, 0.8, 0.65), (0.15, 0.12, 0.1), (p.y - cab.y - 0.1 * k) / max(0.2, 0.7 * c * k)))
        return asignar(h, cuerno_mat)
    o += simetrico(cuerno)
    if e["corona"]:
        for dx, alto, largo in ((0.08, 0.06, 0.8), (0.28, -0.04, 0.7)):
            o += simetrico(lambda s: cuerno(s, dx, alto, largo))
    # Aletas laterales de la cabeza (orejas de aleta).
    a = e["aletas"]
    o += simetrico(lambda s: asignar(_aleta(f"AletaCabeza{s}", (cab.x + s * 0.36 * k, cab.y + 0.12 * k, cab.z),
                                            (0.22 * a * k, 0.03 * k, 0.12 * a * k), (0, 25 * s, s * -30)), aleta_mat))
    # Bigotes (E2+).
    if etapa >= 2:
        for s in (1, -1):
            pts = [(cab.x + s * 0.15 * k, cab.y - 0.7 * k, cab.z - 0.05 * k, 0.02 * k),
                   (cab.x + s * 0.4 * k, cab.y - 0.6 * k, cab.z - 0.2 * k, 0.012 * k),
                   (cab.x + s * 0.55 * k, cab.y - 0.4 * k, cab.z - 0.45 * k, 0.004)]
            o.append(asignar(piel(f"Bigote{s}", pts, subdiv=2), aleta_mat))
    # Colmillos (E3+).
    if e["colmillos"]:
        for s in (1, -1):
            for i, dy in enumerate((-0.62, -0.45)):
                pts = [(cab.x + s * 0.12 * k, cab.y + dy * k, cab.z - 0.1 * k, 0.03 * k),
                       (cab.x + s * 0.13 * k, cab.y + (dy - 0.03) * k, cab.z - 0.26 * k, 0.004)]
                o.append(asignar(piel(f"Colmillo{s}{i}", pts, subdiv=1), diente))
    # Cresta del lomo (E2+) y púas (E3+): a lo largo de la espalda.
    espina = curva_puntos(_espina(e), 16, lambda t: 0)
    if e["cresta"]:
        for i in range(2, 14):
            x, y, z, _ = espina[i]
            sig = espina[i + 1]
            ang = math.degrees(math.atan2(sig[2] - z, sig[1] - y))
            tam = (1 - i / 16) * 0.35 * g + 0.1
            o.append(asignar(_aleta(f"Cresta{i}", (x, y + (0.55 - 0.35 * i / 16) * g, z),
                                    (0.02, tam * 0.8, tam), (ang - 90, 0, 0)), aleta_mat))
    if e["puas"]:
        for i in range(1, 15, 2):
            x, y, z, _ = espina[i]
            r = (0.62 - 0.4 * i / 16) * g
            for s in (1, -1):
                pts = [(x + s * r * 0.7, y + r * 0.6, z, 0.06 * g), (x + s * r * 1.1, y + r * 1.05, z + 0.12, 0.006)]
                o.append(asignar(piel(f"Pua{i}{s}", pts, subdiv=1), cuerno_mat))
    # Aletas grandes a los lados del cuerpo (tipo ala).
    o += simetrico(lambda s: asignar(_aleta(f"AletaCuerpo{s}", (s * 0.6 * g, 0.45 * L, 1.0 * L),
                                            (0.55 * a, 0.03, 0.32 * a), (0, s * 35, s * -20)), aleta_mat))
    return o


def construir_dragon(etapa, voxel=0.02):
    e = DRAGON[etapa]
    bloques, control = _cuerpo_dragon(e)
    cuerpo = fusionar(f"DragonMarinoE{etapa}_Cuerpo", bloques, voxel=voxel)
    detalle(cuerpo, fuerza=0.004, escala=0.03)
    pintar(cuerpo, _colores_dragon(e, control))
    if e["brillo"]:
        pintar(cuerpo, _brillo_dragon(e), capa="Brillo")
        cuerpo.data.color_attributes.active_color = cuerpo.data.color_attributes["Color"]
    asignar(cuerpo, mat_escamas(f"DragonEscamas{etapa}", capa_brillo="Brillo" if e["brillo"] else None))
    return [cuerpo] + _detalles_dragon(e, control, etapa)
