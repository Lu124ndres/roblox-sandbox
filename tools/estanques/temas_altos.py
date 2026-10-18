"""Temas de los estanques 6 a 10 y el sagrado: cada vez más mágicos (árboles en flor, una
cascada, kois dorados, rocas que flotan)."""
import generar_isla as gi
from estanques import agua, especiales, tierra
from estanques.base import angulo_tema, hacia, nenufares, orilla
from estanques.forma import SAGRADO, centro, en_agua, punto, radio
from estanques.temas import AMARILLAS, BLANCAS, ROSAS, petalos

ROJOS = ((220, 60, 50), (240, 104, 44), (196, 40, 44))
NARANJAS = ((255, 150, 60), (255, 180, 80), (255, 120, 40))
DORADOS = ((255, 205, 60), (255, 225, 110), (240, 180, 40))
CELESTES = ((240, 248, 255), (255, 245, 200), (220, 240, 255))
SAGRADOS = ((200, 250, 255), (150, 235, 250), (235, 255, 255))


def cerezo(i, tono, rng):
    """6 · Estanque del Cerezo: un cerezo en flor y sus pétalos rosados en el agua."""
    t = angulo_tema(i)
    hijos = nenufares(i, rng, ROSAS[1], 7) + orilla(i, rng, ROSAS, rocas=4, macizos=2)
    hijos.append(tierra.arbol("Cerezo", punto(i, t, 5.5), rng, 9, 6, ROSAS))
    hijos.append(tierra.farol_piedra("Farol", punto(i, t + 40, 2.4)))
    hijos.append(petalos("PetalosAgua", i, rng, ROSAS, 16))
    return hijos


def arce(i, tono, rng):
    """7 · Estanque del Arce: dos arces rojos de otoño, hojas en el agua y luciérnagas."""
    t = angulo_tema(i)
    hijos = nenufares(i, rng, (255, 230, 230), 7) + orilla(i, rng, NARANJAS, rocas=5, macizos=1)
    hijos.append(tierra.arbol("Arce", punto(i, t, 5.5), rng, 9, 5.5, ROJOS))
    hijos.append(tierra.arbol("ArceChico", punto(i, t + 48, 4.5), rng, 6.5, 4, ROJOS))
    hijos.append(petalos("HojasAgua", i, rng, ROJOS, 14))
    return hijos


def cascada(i, tono, rng):
    """8 · Estanque de la Cascada: un montículo de rocas con agua que cae y farolillos de papel."""
    t = angulo_tema(i)
    hijos = nenufares(i, rng, NARANJAS[1], 7) + orilla(i, rng, NARANJAS, rocas=3, macizos=2)
    pie = punto(i, t, 1.6)
    hijos.append(especiales.cascada("Cascada", pie, hacia(pie, centro(i)), rng))
    for k, g in enumerate((t + 70, t + 180, t - 70)):
        hijos.append(tierra.farolillo(f"Farolillo{k}", punto(i, g, 2.6), NARANJAS[k % 3]))
    return hijos


def dorado(i, tono, rng):
    """9 · Estanque Dorado: lotos de oro que brillan y kois que nadan en círculos."""
    t = angulo_tema(i)
    hijos = nenufares(i, rng, DORADOS[0], 8, neon=True, cada=2) + orilla(i, rng, AMARILLAS, rocas=4, macizos=2)
    c = centro(i)
    for k in range(4):
        hijos.append(agua.koi(f"Koi{k}", c, radio(i) * rng.uniform(0.5, 0.75), k * 90 + rng.uniform(-20, 20), rng))
    for k, g in enumerate((t, t + 120)):
        hijos.append(tierra.farol_piedra(f"Farol{k}", punto(i, g, 2.6), DORADOS[0]))
    return hijos


def celestial(i, tono, rng):
    """10 · Estanque Celestial: rocas que flotan con cristales, lotos blancos que brillan."""
    t = angulo_tema(i)
    hijos = nenufares(i, rng, CELESTES[0], 8, neon=True, cada=2) + orilla(i, rng, BLANCAS, rocas=3, macizos=2)
    for k in range(3):
        p = en_agua(i, t + k * 120 + 60, 0.62)
        hijos.append(especiales.roca_flotante(f"RocaFlotante{k}", p, rng.uniform(5, 7.5), tono, rng))
    for k, g in enumerate((t, t + 35)):
        hijos.append(especiales.cristales(f"Cristales{k}", punto(i, g, 3), rng, tono, 5, (1.6, 3.4)))
    return hijos


def sagrado(i, tono, rng):
    """11 · Estanque Sagrado (centro, solo Robux): el pez dorado salta de un islote con musgo,
    lotos que brillan en celeste, kois, cuatro faroles de piedra y dos árboles sagrados."""
    hijos = [especiales.islote_sagrado(centro(i), rng)]
    hijos += nenufares(i, rng, SAGRADOS[1], 12, neon=True, cada=2)
    hijos += orilla(i, rng, BLANCAS, rocas=4, matas=2, macizos=2, evitar=(45, 135, 225, 315), margen=16)
    c = centro(i)
    for k in range(5):
        hijos.append(agua.koi(f"Koi{k}", c, radio(i) * rng.uniform(0.55, 0.8), k * 72, rng))
    for k, g in enumerate((45, 135, 225, 315)):
        hijos.append(tierra.farol_piedra(f"Farol{k}", punto(i, g, 2.6), SAGRADOS[1], 1.25))
    for k, g in enumerate((18, 162)):
        hijos.append(tierra.arbol(f"ArbolSagrado{k}", punto(i, g, 6), rng, 12, 7.5, SAGRADOS, neon=2))
    return hijos


TEMAS = {6: cerezo, 7: arce, 8: cascada, 9: dorado, 10: celestial, SAGRADO: sagrado}
