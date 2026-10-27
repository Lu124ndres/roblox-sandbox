"""Cuentas de la cámara de la cutscene a partir de intro_planos.py: curva Catmull-Rom por los
puntos, curva de tiempo, temblor de mano y golpes (sacudón que se apaga y un golpe de lente en
el campo de visión). Las usa el previo de Blender y se hornean para el juego (hornear_json),
así los dos ven exactamente la misma cámara.
Uso suelto: python tools/blender/intro_camara.py <salida.json>  (hornea las muestras)."""
import json
import math
import sys

import intro_planos as IP

GOLPE_STUDS = 1.6  # sacudón de un golpe de fuerza 1
GOLPE_FOV = 4.0  # grados que se abre el lente en un golpe de fuerza 1


def curva(nombre, u):
    if nombre == "suave":
        return u * u * (3 - 2 * u)
    if nombre == "sale":
        return 1 - (1 - u) ** 3
    if nombre == "entra":
        return u ** 3
    return u


def catmull(puntos, u):
    """Punto de la curva Catmull-Rom que pasa por `puntos` (u de 0 a 1 en toda la curva)."""
    if len(puntos) == 1:
        return tuple(puntos[0])
    tramos = len(puntos) - 1
    i = min(int(u * tramos), tramos - 1)
    t = u * tramos - i
    p0 = puntos[max(i - 1, 0)]
    p1, p2 = puntos[i], puntos[i + 1]
    p3 = puntos[min(i + 2, tramos)]
    return tuple(
        0.5 * (2 * p1[k] + (-p0[k] + p2[k]) * t + (2 * p0[k] - 5 * p1[k] + 4 * p2[k] - p3[k]) * t * t
               + (-p0[k] + 3 * p1[k] - 3 * p2[k] + p3[k]) * t ** 3)
        for k in range(3)
    )


def temblor(amplitud, s):
    """Cámara en mano: suma de senos lentos."""
    if amplitud <= 0:
        return (0.0, 0.0, 0.0)
    return (
        amplitud * (math.sin(s * 1.7) + 0.5 * math.sin(s * 4.3 + 1.1)),
        amplitud * (math.sin(s * 2.3 + 0.7) + 0.5 * math.sin(s * 5.1)),
        amplitud * (math.sin(s * 1.3 + 2.0) + 0.5 * math.sin(s * 3.7 + 0.4)),
    )


def golpes(lista, s):
    """Sacudón rápido que se apaga después de cada golpe (segundo, fuerza); y el lente."""
    dx = dy = dz = lente = 0.0
    for t0, fuerza in lista:
        d = s - t0
        if d < 0:
            continue
        caida = fuerza * math.exp(-5 * d)
        dx += caida * GOLPE_STUDS * math.sin(d * 47)
        dy += caida * GOLPE_STUDS * math.sin(d * 53 + 1)
        dz += caida * GOLPE_STUDS * math.sin(d * 41 + 2)
        lente += fuerza * GOLPE_FOV * math.exp(-8 * d)
    return (dx, dy, dz), lente


def camara_en(plano, segundos):
    """(posición, mira, fov) del plano a `segundos` de su principio."""
    u = curva(plano["curva"], min(max(segundos / plano["segundos"], 0.0), 1.0))
    if "orbita" in plano:
        o = plano["orbita"]
        ang = math.radians(o["desde"] + (o["hasta"] - o["desde"]) * u)
        pos = IP.C(math.cos(ang) * o["radio"], o["alto"], math.sin(ang) * o["radio"])
    else:
        pos = catmull(plano["camara"], u)
    mira = catmull(plano["mira"], u)
    mano = temblor(plano["temblor"], segundos)
    sacudon, lente = golpes(plano.get("golpes", []), segundos)
    pos = tuple(pos[k] + mano[k] + sacudon[k] for k in range(3))
    fov = plano["fov"][0] + (plano["fov"][1] - plano["fov"][0]) * u + lente
    return pos, mira, fov


def duracion():
    return sum(p["segundos"] for p in IP.PLANOS)


def hornear_json(ruta):
    """Muestras de cámara por plano para el juego: [x, y, z, mx, my, mz, fov] a 30 por segundo."""
    salida = {"muestrasPorSegundo": IP.MUESTRAS_POR_SEGUNDO, "planos": []}
    for p in IP.PLANOS:
        cuadros = round(p["segundos"] * IP.MUESTRAS_POR_SEGUNDO)
        muestras = []
        for i in range(cuadros + 1):
            pos, mira, fov = camara_en(p, i / IP.MUESTRAS_POR_SEGUNDO)
            muestras.append([round(v, 2) for v in (*pos, *mira, fov)])
        salida["planos"].append({
            "nombre": p["nombre"],
            "segundos": p["segundos"],
            "gigante": p["gigante"] or "",
            "tono": p["tono"],
            "relampagos": p["relampagos"],
            "golpes": [list(g) for g in p.get("golpes", [])],
            "cartel": list(p.get("cartel", ())),
            "titulo": list(p.get("titulo", ())),
            "muestras": muestras,
        })
    with open(ruta, "w", encoding="utf-8") as f:
        json.dump(salida, f, ensure_ascii=False, separators=(",", ":"))


if __name__ == "__main__":
    hornear_json(sys.argv[1])
