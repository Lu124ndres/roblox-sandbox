"""Lo que tienen todos los estanques: la tapa para caminar por el agua, la pieza del
ProximityPrompt, el espíritu de luz sobre un loto grande en el centro, nenúfares, rocas de
orilla, juncos y flores. Cada tema (estanques.temas) le suma lo suyo encima."""
import generar_isla as gi
from estanques import agua, tierra
from estanques.forma import AGUA, L, SAGRADO, angulo, centro, en_agua, punto, radio, radio_max

LUCIERNAGA = (230, 255, 150)


def lado_jardin(i):
    """Hacia qué costado del estanque queda el hueco de jardín sin sendero (+1 o -1).
    Los senderos rectos (gardenSpokeAngles) caen en un hueco sí y uno no."""
    return 1 if i % 2 == 1 else -1


def angulo_tema(i):
    """Dirección (grados, desde el centro del estanque) donde va la pieza grande del tema: hacia
    su hueco de jardín, un poco hacia adentro en los impares y hacia afuera en los pares, así
    los dos estanques que comparten un hueco no se pisan."""
    return angulo(i) + lado_jardin(i) * (105 if i % 2 == 1 else 75)


def tapa_y_prompt(i, tono):
    """Tapa invisible apenas bajo el agua (se entrena parado en el estanque sin hundirse) y la
    pieza "Estanque" del ProximityPrompt (TrainingService). El sagrado lleva cuatro piezas
    alrededor del islote para que el prompt llegue desde cualquier orilla."""
    c = centro(i)
    tapa_y = AGUA - L["pondCoverDepth"] - 0.5
    d = 2 * radio_max(i) + 1
    hijos = [gi.pieza("Tapa", (1, d, d), (c[0], tapa_y, c[2]), tono, "SmoothPlastic", gi.VERTICAL, "Cylinder",
                      Transparency=1, CanQuery=False, CanTouch=False, CastShadow=False)]
    puntos = [gi.polar(45 + k * 90, radio(i) * 0.62, 0) for k in range(4)] if i == SAGRADO else [(0, 0, 0)]
    for q in puntos:
        marcador = gi.pieza("Estanque", (2, 1, 2), (c[0] + q[0], AGUA + 1, c[2] + q[2]), tono, **gi.INVISIBLE, CanCollide=False)
        marcador["attributes"] = {"Indice": i}
        hijos.append(marcador)
    return hijos


def espiritu(i, tono):
    """Loto grande en el centro y, encima, el espíritu del estanque: una esfera de luz del color
    de su nivel que crece con él (la anima Training/PondFx). Desde el 7, luciérnagas alrededor."""
    c = centro(i)
    flor = tuple(min(255, int(v * 0.6 + 255 * 0.4)) for v in tono)
    hijos = [gi.pieza("HojaCentro", (0.14, 4.6, 4.6), (c[0], AGUA + 0.06, c[2]), agua.NENUFAR[0], "SmoothPlastic", gi.VERTICAL,
                      "Cylinder", **gi.FANTASMA),
             agua.loto("LotoCentro", (c[0], AGUA + 0.15, c[2]), 1.5, flor, i >= 9)]
    lado = 1.8 + i * 0.12
    bola = gi.pieza("Espiritu", (lado, lado, lado), (c[0], AGUA + 4, c[2]), tono, "Neon", forma="Ball", **gi.FANTASMA)
    bola["children"] = [gi.luz(18, 1.3, tono)]
    bola["attributes"] = {"Indice": i}
    hijos.append(bola)
    if i >= 7:
        for k in range(3):
            p = gi.add(c, gi.polar(k * 120, 2.8, 4))
            hijos.append(gi.pieza(f"Luciernaga{k + 1}", (0.35, 0.35, 0.35), p, LUCIERNAGA, "Neon", forma="Ball", **gi.FANTASMA))
    return hijos


def nenufares(i, rng, flor, n=8, neon=False, cada=3):
    """Hojas flotando entre el centro y la orilla; una de cada `cada` lleva flor."""
    hijos = []
    for k in range(n):
        g = k * 360 / n + rng.uniform(-14, 14)
        p = en_agua(i, g, rng.uniform(0.42, 0.82))
        hijos.append(agua.nenufar(f"Nenufar{k}", p, rng.uniform(1.8, 3.1), rng, flor if k % cada == 0 else None, neon))
    return hijos


def orilla(i, rng, flores_rgb, rocas=5, matas=2, macizos=2, evitar=(), margen=34):
    """Rocas medio hundidas, juncos y macizos de flores repartidos por la orilla, lejos de la
    pieza grande del tema y de las direcciones de `evitar` (grados, con `margen` a cada lado)."""
    lejos = (angulo_tema(i), *evitar)
    huecos = [k * 22.5 + rng.uniform(-6, 6) for k in range(16)]
    huecos = [g for g in huecos if all(abs((g - a + 180) % 360 - 180) > margen for a in lejos)]
    rng.shuffle(huecos)
    hijos = []
    pedidos = rocas + matas + macizos
    assert len(huecos) >= pedidos, f"estanque {i}: no caben {pedidos} cosas en la orilla"
    for k in range(rocas):
        g = huecos.pop()
        hijos.append(agua.roca(f"Roca{k}", punto(i, g, -0.4), rng.uniform(1.6, 2.8), rng))
    for k in range(matas):
        g = huecos.pop()
        hijos.append(agua.juncos(f"Juncos{k}", punto(i, g, -1.0, AGUA - 1.2), rng))
    for k in range(macizos):
        g = huecos.pop()
        hijos.append(tierra.flores(f"Flores{k}", punto(i, g, 2.0), rng, flores_rgb))
    if huecos:
        hijos.append(tierra.helecho("Helecho", punto(i, huecos.pop(), 1.6), rng))
    return hijos


def hacia(desde, hasta):
    """Dirección horizontal de un punto a otro."""
    return (hasta[0] - desde[0], 0, hasta[2] - desde[2])
