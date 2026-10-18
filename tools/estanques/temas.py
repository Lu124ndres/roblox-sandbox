"""Lo que distingue a cada estanque: el color de sus lotos, cuántas hojas flotan, si los lotos
brillan y si tiene kois. Todo vive en el agua: en la orilla no hay nada con qué chocar ni
dónde atorarse (pedido del usuario, 2026-10-18)."""
from estanques import agua
from estanques.base import nenufares
from estanques.forma import SAGRADO, centro, radio

# indice: (color de los lotos, hojas, lotos que brillan, una flor cada tantas hojas, kois)
TEMAS = {
    1: ((255, 255, 255), 7, False, 3, 0),  # Jade
    2: ((255, 200, 220), 7, False, 3, 0),  # Turquesa
    3: ((200, 210, 255), 8, False, 3, 0),  # Zafiro
    4: ((235, 225, 255), 8, False, 3, 0),  # Índigo
    5: ((220, 150, 255), 8, False, 2, 0),  # Amatista
    6: ((255, 190, 215), 9, False, 2, 0),  # Rosa
    7: ((255, 160, 150), 9, False, 2, 2),  # Rubí
    8: ((255, 190, 100), 9, False, 2, 3),  # Ámbar
    9: ((255, 205, 60), 10, True, 2, 4),  # Dorado
    10: ((240, 248, 255), 10, True, 2, 4),  # Celestial
    SAGRADO: ((150, 235, 250), 14, True, 2, 5),  # Sagrado
}


def tema(i, rng):
    flor, hojas, brillo, cada, kois = TEMAS[i]
    hijos = nenufares(i, rng, flor, hojas, brillo, cada)
    c = centro(i)
    for k in range(kois):
        hijos.append(agua.koi(f"Koi{k}", c, radio(i) * rng.uniform(0.5, 0.78), k * 360 / kois + rng.uniform(-15, 15), rng))
    return hijos
