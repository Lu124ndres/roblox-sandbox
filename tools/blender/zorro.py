"""
Zorro de agua de Gigantes en 4 etapas: un zorro sentado, de pelaje azul,
con colas de agua que se multiplican al crecer.
    E1  cachorro: cabeza grande, 1 cola
    E2  joven: 3 colas
    E3  adulto: 6 colas, aletas en las patas, ojos que brillan
    E4  forma final: 9 colas, marcas que brillan, melena y gema en la frente
Requiere criaturas.py. construir_zorro(etapa, voxel) -> lista de objetos.
"""
import math

ZORRO = {
    1: dict(k=1.6, m=0.8, colas=1, aletas=False, brillo=False, gema=False,
            pelo=(0.04, 0.24, 0.62), claro=(0.85, 0.93, 1.0)),
    2: dict(k=1.36, m=0.88, colas=3, aletas=False, brillo=False, gema=False,
            pelo=(0.03, 0.18, 0.55), claro=(0.85, 0.93, 1.0)),
    3: dict(k=1.22, m=0.97, colas=6, aletas=True, brillo=False, gema=False,
            pelo=(0.02, 0.13, 0.46), claro=(0.8, 0.92, 1.0)),
    4: dict(k=1.15, m=1.06, colas=9, aletas=True, brillo=True, gema=True,
            pelo=(0.012, 0.08, 0.34), claro=(0.75, 0.9, 1.0)),
}


def _cuerpo_zorro(e):
    m, k = e["m"], e["k"]
    b = [
        masa("Anca", (0, 0.25, 0.46), (0.38 * m, 0.5 * m, 0.42)),
        masa("Pecho", (0, -0.14, 1.08), (0.27 * m, 0.3 * m, 0.46), (14, 0, 0)),
        masa("Barriga", (0, 0.06, 0.72), (0.29 * m, 0.36 * m, 0.32)),
        masa("Collar", (0, -0.24, 1.4), (0.3 * m, 0.26 * m, 0.24)),
        masa("Pechera", (0, -0.36, 1.15), (0.17 * m, 0.12 * m, 0.3), (14, 0, 0)),
        piel("Cuello", [(0, 0.05, 0.9, 0.3 * m), (0, -0.2, 1.4, 0.22 * m), (0, -0.3, 1.65, 0.2)]),
    ]
    b += simetrico(lambda s: [
        piel(f"PataDelantera{s}", [(s * 0.16 * m, -0.24, 1.0, 0.11 * m), (s * 0.16 * m, -0.34, 0.5, 0.065 * m),
                                   (s * 0.16 * m, -0.38, 0.12, 0.055 * m)]),
        masa(f"Mano{s}", (s * 0.16 * m, -0.44, 0.05), (0.075 * m, 0.12 * m, 0.05)),
        masa(f"Muslo{s}", (s * 0.28 * m, 0.12, 0.4), (0.16 * m, 0.32 * m, 0.27), (-20, 0, 0)),
        masa(f"Pie{s}", (s * 0.3 * m, -0.18, 0.05), (0.08 * m, 0.19 * m, 0.05)),
    ])
    b += cabeza_zorro(k)
    return b


HZ, HY = 1.78, -0.32


def cabeza_zorro(k):
    def P(x, y, z):
        return (x * k, HY + y * k, HZ + z * k)
    # Cabeza triangular: frente ancha, mejillas con mechones en punta y un
    # hocico largo y fino (lo que la hace zorro y no oso).
    b = [
        masa("Craneo", P(0, 0, 0.03), (0.24 * k, 0.24 * k, 0.21 * k)),
        masa("Frente", P(0, -0.14, 0.08), (0.17 * k, 0.16 * k, 0.12 * k), (-15, 0, 0)),
        masa("Hocico", P(0, -0.42, -0.07), (0.085 * k, 0.3 * k, 0.075 * k), (-8, 0, 0)),
        masa("Nariz", P(0, -0.72, -0.07), (0.045 * k, 0.045 * k, 0.04 * k)),
        masa("Mandibula", P(0, -0.36, -0.15), (0.07 * k, 0.24 * k, 0.04 * k), (4, 0, 0)),
    ]
    b += simetrico(lambda s: [
        masa(f"Mejilla{s}", P(s * 0.2, -0.08, -0.08), (0.15 * k, 0.12 * k, 0.11 * k), (0, 0, s * -25)),
        piel(f"Pelusa{s}", [(s * 0.22 * k, HY - 0.05 * k, HZ - 0.1 * k, 0.09 * k),
                            (s * 0.36 * k, HY + 0.02 * k, HZ - 0.17 * k, 0.05 * k),
                            (s * 0.46 * k, HY + 0.08 * k, HZ - 0.26 * k, 0.008)], subdiv=2),
        piel(f"Oreja{s}", [(s * 0.14 * k, HY + 0.02 * k, HZ + 0.15 * k, (0.15 * k, 0.06 * k)),
                           (s * 0.21 * k, HY + 0.04 * k, HZ + 0.38 * k, (0.1 * k, 0.04 * k)),
                           (s * 0.26 * k, HY + 0.06 * k, HZ + 0.58 * k, (0.015, 0.012))], subdiv=2),
    ])
    return b


def _colores_zorro(e):
    pelo, claro = e["pelo"], e["claro"]
    k = e["k"]
    def regla(pos, normal):
        c = pelo
        # Pecho, hocico y mejillas blancos.
        c = mezcla(c, claro, cerca(pos, (0, -0.36, 1.12), 0.36, 0.3) * max(0.0, -normal.y))
        c = mezcla(c, claro, cerca(pos, (0, HY - 0.4 * k, HZ - 0.15 * k), 0.24 * k, 0.4) * (1 if normal.z < 0.3 else 0.3))
        for s in (1, -1):
            c = mezcla(c, claro, cerca(pos, (s * 0.34 * k, HY, HZ - 0.17 * k), 0.17 * k, 0.4))
            # Puntas de las orejas oscuras y su interior claro.
            c = mezcla(c, (0.01, 0.015, 0.05), cerca(pos, (s * 0.24 * k, HY + 0.06 * k, HZ + 0.62 * k), 0.16 * k, 0.4))
        c = mezcla(c, (0.005, 0.005, 0.01), cerca(pos, (0, HY - 0.72 * k, HZ - 0.07 * k), 0.07 * k, 0.5))
        # Patas oscuras abajo.
        c = mezcla(c, tuple(x * 0.35 for x in pelo), (0.3 - pos.z) / 0.25)
        v = 0.85 + 0.3 * ruido(pos, 5)
        return tuple(min(1, x * v) for x in c)
    return regla


def _brillo_zorro(e):
    def regla(pos, normal):
        if not e["brillo"]:
            return (0, 0, 0)
        # Franjas en los costados y la frente, como corrientes de agua.
        v = abs(math.sin(pos.z * 10 + ruido(pos, 3) * 4))
        f = 1.0 if (v < 0.12 and abs(normal.x) > 0.6) else 0.0
        return (0.2 * f, 0.9 * f, 1.0 * f)
    return regla


def _colas(e, etapa):
    """Colas de pelo esponjosas: base del color del lomo, medio celeste y punta
    blanca (en E3+ la punta brilla como agua). Abanico detrás, curvadas hacia afuera."""
    o = []
    n = e["colas"]
    m = e["m"]
    pelo = e["pelo"]
    celeste = (0.05, 0.42, 0.9)
    mat = mat_pelaje(f"ZorroCola{etapa}", capa_brillo="Brillo" if etapa >= 3 else None, escala_pelo=260.0)
    for i in range(n):
        ang = 0 if n == 1 else math.radians(-72 + 144 * i / (n - 1))
        largo = 1.35 * m * (1.0 if n < 6 else 0.92)
        sx, cz = math.sin(ang), math.cos(ang)
        base = Vector((0, 0.6 * m, 0.3))
        ctrl = [base,
                base + Vector((sx * 0.2, 0.4, 0.15 * cz + 0.1)) * largo,
                base + Vector((sx * 0.6, 0.55, 0.7 * cz + 0.25)) * largo,
                base + Vector((sx * 1.0, 0.4, 1.1 * cz + 0.45)) * largo,
                base + Vector((sx * 1.15, 0.25, 1.3 * cz + 0.5)) * largo]
        grosor = lambda t: (0.05 + 0.15 * math.sin(math.pi * min(1.0, t ** 0.7))) * m
        pts = curva_puntos([tuple(p) for p in ctrl], 12, grosor)
        cola = piel(f"Cola{i}", pts, subdiv=2)
        aplicar(cola)
        b0, punta = ctrl[0], ctrl[-1]
        total = (punta - b0).length

        def regla(p, nrm, b0=b0, total=total):
            t = min(1.0, (Vector(p) - b0).length / total)
            c = mezcla(pelo, celeste, t * 1.4)
            c = mezcla(c, (0.95, 0.98, 1.0), (t - 0.8) * 5)
            return tuple(x * (0.85 + 0.25 * ruido(p, 9)) for x in c)

        pintar(cola, regla)
        if etapa >= 3:
            pintar(cola, lambda p, nrm, b0=b0, total=total: tuple(
                x * max(0.0, ((Vector(p) - b0).length / total - 0.7) * 2.5) for x in (0.2, 0.8, 1.0)), capa="Brillo")
            cola.data.color_attributes.active_color = cola.data.color_attributes["Color"]
        o.append(asignar(cola, mat))
    return o


def _detalles_zorro(e, etapa):
    k, m = e["k"], e["m"]
    o = []
    ojos = mat_simple(f"ZorroOjo{etapa}", (0.1, 0.85, 1.0) if etapa >= 3 else (0.02, 0.02, 0.03), 0.05,
                      emision=(0.1, 0.8, 1.0) if etapa >= 3 else None, fuerza=6 if etapa >= 3 else 0)
    o += simetrico(lambda s: asignar(masa(f"Ojo{s}", (s * 0.12 * k, HY - 0.23 * k, HZ + 0.07 * k),
                                          (0.055 * k, 0.03 * k, 0.026 * k), (0, s * -18, s * -28)), ojos))
    o += _colas(e, etapa)
    if e["aletas"]:
        aleta = mat_simple(f"ZorroAleta{etapa}", (0.2, 0.7, 0.95), 0.1, emision=(0.2, 0.7, 1.0), fuerza=0.8)
        o += simetrico(lambda s: [asignar(masa(f"AletaPata{s}", (s * 0.28 * m, -0.25, 0.65),
                                               (0.03, 0.15, 0.2), (20, 0, 0)), aleta),
                                  asignar(masa(f"AletaCabeza{s}", (s * 0.3 * k, HY + 0.15 * k, HZ + 0.1 * k),
                                               (0.03, 0.18 * k, 0.1 * k), (0, s * 20, s * -10)), aleta)])
    if e["gema"]:
        gema = mat_simple(f"ZorroGema{etapa}", (0.1, 0.9, 1.0), 0.05, emision=(0.2, 0.9, 1.0), fuerza=10)
        o.append(asignar(masa("Gema", (0, HY - 0.2 * k, HZ + 0.2 * k), (0.06 * k, 0.03 * k, 0.07 * k), (-30, 0, 0)), gema))
        oro = mat_simple(f"ZorroOro{etapa}", (0.95, 0.7, 0.25), 0.25, metal=1.0)
        o.append(asignar(masa("Engarce", (0, HY - 0.19 * k, HZ + 0.2 * k), (0.08 * k, 0.025 * k, 0.09 * k), (-30, 0, 0)), oro))
    return o


def construir_zorro(etapa, voxel=0.016):
    e = ZORRO[etapa]
    cuerpo = fusionar(f"ZorroDeAguaE{etapa}_Cuerpo", _cuerpo_zorro(e), voxel=voxel)
    detalle(cuerpo, fuerza=0.006, escala=0.03)
    pintar(cuerpo, _colores_zorro(e))
    if e["brillo"]:
        pintar(cuerpo, _brillo_zorro(e), capa="Brillo")
        cuerpo.data.color_attributes.active_color = cuerpo.data.color_attributes["Color"]
    asignar(cuerpo, mat_pelaje(f"ZorroPelaje{etapa}", capa_brillo="Brillo" if e["brillo"] else None))
    return [cuerpo] + _detalles_zorro(e, etapa)
