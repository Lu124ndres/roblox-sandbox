"""Forma de los estanques naturales y utilidades de piezas que comparten los módulos del jardín.

La orilla ondulada es la misma que WorldZones.pondEdge (el terreno de server/World/GardenShape):
si cambia allá, cambia acá.
"""
import math

import generar_isla as gi

L = gi.L
SAGRADO = L["trainingPondCount"] + 1  # mismo índice que WorldZones.SACRED_POND
AGUA = L["trainingPondWaterTop"]
SUELO = L["plateauHeight"]


def centro(i):
    """Centro del estanque i a la altura del agua (WorldZones.pondCenter)."""
    if i == SAGRADO:
        return (0, AGUA, 0)
    a = math.radians(angulo(i))
    r = L["trainingPondRingRadius"]
    return (math.cos(a) * r, AGUA, math.sin(a) * r)


def angulo(i):
    """Dirección del estanque desde el centro de la isla, en grados (WorldZones.pondAngle)."""
    paso = 360 / L["trainingPondCount"]
    return L["spawnAngle"] + paso / 2 + (i - 1) * paso


def radio(i):
    return L["sacredPondRadius"] if i == SAGRADO else L["trainingPondRadius"]


def radio_max(i):
    return radio(i) * (1 + sum(L["pondWobble"]))


def borde(i, ang):
    """Radio del agua del estanque i en la dirección ang (radianes, atan2(dz, dx))."""
    w = L["pondWobble"]
    forma = 1 + w[0] * math.sin(2 * ang + 1.7 * i) + w[1] * math.sin(3 * ang + 2.9 * i) + w[2] * math.sin(5 * ang + 0.8 * i)
    return radio(i) * forma


def en_agua(i, grados, fraccion, y=AGUA):
    """Punto dentro del agua, a `fraccion` del radio de la orilla en esa dirección."""
    a = math.radians(grados)
    c = centro(i)
    d = borde(i, a) * fraccion
    return (c[0] + math.cos(a) * d, y, c[2] + math.sin(a) * d)


def elipsoide(nombre, pos, medidas, rgb, material="SmoothPlastic", r=gi.I3, **extra):
    """Pieza redondeada de `medidas` (x, y, z): una esfera estirada con SpecialMesh."""
    nodo = gi.pieza(nombre, (1, 1, 1), pos, rgb, material, r, **extra)
    nodo["children"] = [{"name": "Forma", "className": "SpecialMesh",
                         "properties": {"MeshType": "Sphere", "Scale": [round(v, 3) for v in medidas]}}]
    return nodo


def orientar(x, arriba=(0, 1, 0)):
    """Rotación con el eje X local hacia x y el Y lo más cerca posible de `arriba` (pétalos,
    hojas: su lado plano mira hacia arriba)."""
    x = gi.norm(x)
    k = sum(a * b for a, b in zip(arriba, x))
    y = gi.norm(tuple(arriba[n] - k * x[n] for n in range(3)))
    return gi.columnas(x, y, gi.cross(x, y))
