r"""
Pintura del zorro de agua E4 (versión de Claude Code): color por vértice y una capa de
brillo (las marcas cian que se encienden) sobre el modelo detallado de zorro_e4_code.py.
Después rig_zorro_e4_code.py hornea todo a texturas de la malla liviana.

pintar_zorro_e4(objs) -> asigna materiales: pelaje (cuerpo, mechones, orejas, colas con su
capa de brillo), oro (aros, colgante), cristal (gemas), ojos y nariz.
Requiere criaturas.py y zorro_e4_code.py (exec antes).
"""
import math
from mathutils import Vector, noise

V = Vector

# Paleta: la del dibujo de referencia, pasada a agua.
AGUA = (0.04, 0.46, 0.78)
AGUA_CLARA = (0.16, 0.66, 0.92)
LOMO = (0.02, 0.24, 0.58)
BLANCO = (0.9, 0.97, 1.0)
MEDIA = (0.03, 0.11, 0.34)
PROFUNDO = (0.03, 0.2, 0.52)
CIAN = (0.35, 1.0, 0.95)
NEGRO = (0.0, 0.0, 0.0)


def suave(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def mezclar(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(x + (y - x) * t for x, y in zip(a, b))


def n3(p, escala, semilla=0.0):
    return noise.noise(V(p) * escala + V((semilla, semilla * 1.7, semilla * 2.3)))


def _capa(obj, nombre):
    me = obj.data
    return me.color_attributes.get(nombre) or me.color_attributes.new(nombre, "FLOAT_COLOR", "POINT")


def pintar_cuerpo(obj):
    """Pelaje del cuerpo, mechones y orejas: regiones + marcas que brillan."""
    col, bri = _capa(obj, "Color"), _capa(obj, "Brillo")
    for i, v in enumerate(obj.data.vertices):
        p, n = v.co, v.normal
        x, y, z = abs(p.x), p.y, p.z
        # Base: lomo oscuro arriba, costados claros, con variación suave de mechones.
        alto = suave(0.9, 1.45, z)
        c = mezclar(AGUA_CLARA, LOMO, alto * max(0.0, n.z) * 1.2)
        c = mezclar(c, AGUA, 0.4 + 0.12 * n3(p, 4))
        # Blanco: pechera y gola (adelante), mejillas bajas, debajo del hocico, panza.
        borde = 0.06 * n3(p, 18, 3.1)  # borde en zigzag, como el dibujo
        pecho = suave(-0.48 + borde, -0.62 + borde, y) * suave(0.7, 0.9, z) * (1 - suave(1.82, 1.9, z))
        mejilla = suave(0.13, 0.2, x) * suave(1.86 + borde, 1.8 + borde, z) * suave(-0.86, -0.95, y)
        hocico = suave(-1.06, -1.16, y) * suave(1.83 + borde * 0.3, 1.79, z) * suave(0.3, -0.2, n.z)
        panza = suave(1.02, 0.92, z) * suave(0.16, 0.08, x) * suave(0.6, 0.4, y)
        blanco = max(pecho, mejilla, hocico, panza)
        c = mezclar(c, BLANCO, blanco)
        # Medias azul marino en las patas (borde irregular).
        if y < -0.25:
            media = suave(0.5 + borde, 0.38 + borde, z) * suave(0.1, 0.14, x)
        else:
            media = suave(0.44 + borde, 0.32 + borde, z) * suave(0.12, 0.16, x)
        c = mezclar(c, MEDIA, media)
        # Orejas: interior claro, puntas oscuras.
        if z > 2.02 and x > 0.08:
            punta = suave(2.38, 2.58, z)
            adentro = suave(-0.2, -0.6, n.y) * (1 - suave(2.3, 2.45, z))
            c = mezclar(mezclar(AGUA, MEDIA, punta), mezclar(BLANCO, AGUA_CLARA, 0.55), adentro)
        col.data[i].color = (*c, 1.0)
        # Marcas que brillan.
        g = 0.0
        # Chevrón en la frente, debajo de la gema.
        if 1.92 < z < 2.08 and y < -1.02:
            g = max(g, suave(0.025, 0.0, abs(z - (2.0 - x * 0.6) ) ) * suave(0.12, 0.08, x))
        # Rayas desde el rabillo del ojo hacia atrás y arriba.
        if 1.88 < z < 2.06 and 0.1 < x < 0.26 and -1.12 < y < -0.86:
            linea = (z - 1.95) - (x - 0.13) * 0.55 - (y + 1.08) * 0.3
            g = max(g, suave(0.018, 0.004, abs(linea)))
        # Dos puntos arriba de los ojos (los del dibujo).
        for s in (1, -1):
            d = (p - V((0.07 * s, -1.1, 2.07))).length
            g = max(g, suave(0.03, 0.018, d))
        # Ondas en las patas, arriba de las medias.
        if z < 0.75 and x > 0.1:
            onda = z - (0.6 if y < -0.25 else 0.54) - 0.03 * math.sin(math.atan2(p.y - (-0.54 if y < -0.25 else 0.5), p.x) * 3)
            g = max(g, suave(0.02, 0.006, abs(onda)))
        # Crestas a lo largo del lomo (de la cruz a la cola).
        if z > 1.3 and x < 0.14 and -0.45 < y < 0.75:
            fase = (y + 0.45) / 0.2
            cresta = abs((fase % 1.0) - 0.5 - x * 1.8)
            g = max(g, suave(0.08, 0.03, cresta) * suave(0.12, 0.06, x) * suave(1.32, 1.38, z))
        bri.data[i].color = (*(cc * g for cc in CIAN), 1.0)
    obj.data.color_attributes.active_color = col


def pintar_cola(obj, puntos):
    """Ola: base del color del cuerpo, cuerpo azul profundo con vetas, punta de espuma."""
    col, bri = _capa(obj, "Color"), _capa(obj, "Brillo")
    pts = [V(q[:3]) for q in puntos]
    largo = [0.0]
    for a, b in zip(pts, pts[1:]):
        largo.append(largo[-1] + (b - a).length)
    total = largo[-1]
    for i, v in enumerate(obj.data.vertices):
        p = v.co
        mejor, u, radial, eje = 1e9, 0.0, V((1, 0, 0)), V((0, 0, 1))
        for k in range(len(pts) - 1):  # el punto más cercano de la línea de la cola
            a, b = pts[k], pts[k + 1]
            ab = b - a
            t = max(0.0, min(1.0, (p - a).dot(ab) / max(ab.length_squared, 1e-9)))
            q = a + ab * t
            d = (p - q).length
            if d < mejor:
                mejor, u, radial, eje = d, (largo[k] + ab.length * t) / total, p - q, ab.normalized()
        # Ángulo alrededor de la cola: las vetas corren A LO LARGO (y giran un poco, como agua).
        # Referencia estable: las colas viven en el plano x-z, así que y es perpendicular a todas.
        b1 = eje.cross(V((0, 1, 0))).normalized()
        b2 = eje.cross(b1)
        ang = math.atan2(radial.dot(b2), radial.dot(b1))
        veta = suave(0.45, 0.9, 0.5 + 0.5 * math.sin(ang * 3 + u * 5 + n3(p, 2.5) * 1.0))
        c = mezclar(AGUA, PROFUNDO, suave(0.1, 0.45, u))
        c = mezclar(c, AGUA_CLARA, 0.55 * veta * suave(0.15, 0.4, u))
        corte = 0.72 + 0.06 * n3(p, 14, 7.0)  # espuma en zigzag
        espuma = suave(corte, corte + 0.05, u)
        c = mezclar(c, BLANCO, espuma)
        col.data[i].color = (*c, 1.0)
        brillo = 0.35 * suave(0.6, 0.72, u) * (1 - espuma) * veta  # la ola brilla antes de romper
        bri.data[i].color = (*(cc * brillo for cc in CIAN), 1.0)
    obj.data.color_attributes.active_color = col


def pintar_ojo(obj, centro, frente):
    """Iris cian con pupila rasgada vertical y un brillo; atrás, oscuro."""
    col, bri = _capa(obj, "Color"), _capa(obj, "Brillo")
    frente = V(frente).normalized()
    arriba = V((0, 0, 1))
    costado = frente.cross(arriba).normalized()
    M = obj.matrix_world  # la esfera guarda la escala y el giro en el objeto
    for i, v in enumerate(obj.data.vertices):
        rel = M @ v.co - V(centro)
        a, b = rel.dot(costado) / 0.045, rel.dot(arriba) / 0.03
        r = math.hypot(a, b)
        delante = rel.dot(frente) > -0.004
        c, g = NEGRO, 0.0
        if delante:
            c = mezclar((0.6, 1.0, 0.98), (0.05, 0.55, 0.7), suave(0.1, 0.9, r))
            g = 0.5 * (1 - suave(0.3, 0.9, r))
            if abs(a) < 0.16 * (1 - r) and r < 0.75:  # pupila rasgada
                c, g = (0.01, 0.03, 0.06), 0.0
            if math.hypot(a + 0.3, b - 0.35) < 0.18:  # brillo
                c, g = (1.0, 1.0, 1.0), 0.6
            c = mezclar(c, (0.01, 0.03, 0.06), suave(0.85, 1.0, r))  # contorno oscuro
        col.data[i].color = (*c, 1.0)
        bri.data[i].color = (*(cc * g for cc in CIAN), 1.0)
    obj.data.color_attributes.active_color = col


def mat_ojo(nombre):
    mat = mat_pelaje(nombre, rugosidad=0.08, bulto=0.0, brillo_pelo=0.0, capa_brillo="Brillo")
    return mat


def pintar_zorro_e4(objs):
    pelo = mat_pelaje("ZorroPelo", rugosidad=0.8, bulto=0.35, escala_pelo=260, brillo_pelo=0.3,
                      capa_brillo="Brillo")
    cola = mat_pelaje("ZorroCola", rugosidad=0.45, bulto=0.25, escala_pelo=200, brillo_pelo=0.25,
                      capa_brillo="Brillo")
    oro = mat_simple("ZorroOro", (1.0, 0.72, 0.28), rugosidad=0.25, metal=1.0)
    cristal = mat_simple("ZorroCristal", (0.45, 1.0, 1.0), rugosidad=0.05, emision=(0.3, 1.0, 0.95), fuerza=3.0)
    nariz = mat_simple("ZorroNariz", (0.02, 0.05, 0.12), rugosidad=0.25)
    ojo_mat = mat_ojo("ZorroOjo")
    for o in objs:
        n = o.name
        if n.startswith("Cola"):
            idx = int("".join(ch for ch in n if ch.isdigit())) - 1
            pintar_cola(o, PUNTOS_COLA[idx])
            asignar(o, cola)
        elif n.startswith(("Aro", "Medallon")):
            asignar(o, oro)
        elif n.startswith(("Gema",)):
            asignar(o, cristal)
        elif n.startswith("Nariz"):
            asignar(o, nariz)
        elif n.startswith("Ojo"):
            s = 1 if n.endswith("Izq") else -1
            pintar_ojo(o, (0.114 * s, -1.125, 1.962), (0.5 * s, -0.86, 0.05))
            asignar(o, ojo_mat)
        else:
            pintar_cuerpo(o)
            asignar(o, pelo)
