"""Temas de los estanques 1 a 5 (los primeros: naturaleza tranquila). Cada uno devuelve sus
nenúfares, su orilla y la pieza que lo distingue, puesta hacia su hueco de jardín
(base.angulo_tema)."""
import generar_isla as gi
from estanques import agua, especiales, tierra
from estanques.base import angulo_tema, hacia, nenufares, orilla
from estanques.forma import AGUA, centro, elipsoide, en_agua, punto

BLANCAS = ((250, 250, 255), (255, 246, 214), (255, 255, 255))
AMARILLAS = ((255, 214, 92), (255, 180, 70), (255, 236, 140))
AZULES = ((110, 120, 255), (150, 110, 240), (90, 160, 255))
ROSAS = ((255, 150, 190), (255, 190, 215), (250, 130, 175))
VIOLETAS = ((190, 110, 255), (150, 90, 230), (220, 140, 255))


def prado(i, tono, rng):
    """1 · Charca del Prado: margaritas por todos lados y una ranita sobre una hoja."""
    t = angulo_tema(i)
    hijos = nenufares(i, rng, (255, 255, 255), 7) + orilla(i, rng, BLANCAS, rocas=4, macizos=3)
    hijos.append(tierra.flores("Margaritas", punto(i, t, 3), rng, BLANCAS, n=12, radio=3))
    hijos.append(gi.arbusto("Arbusto1", punto(i, t + 25, 5)))
    p = en_agua(i, t + 150, 0.62)
    hijos.append(agua.nenufar("HojaRana", p, 2.8, rng))
    hijos.append(especiales.rana("Rana", p))
    return hijos


def juncos(i, tono, rng):
    """2 · Estanque de los Juncos: un juncal tupido de totoras y un muellecito de madera."""
    t = angulo_tema(i)
    muelle = t + 180
    hijos = nenufares(i, rng, (255, 200, 220), 6)
    hijos += orilla(i, rng, AMARILLAS, rocas=3, matas=3, macizos=1, evitar=(muelle,))
    for k in range(4):
        hijos.append(agua.juncos(f"Juncal{k}", punto(i, t - 40 + k * 27, -1.2, AGUA - 1.2), rng, n=6, alto=(4, 6.5)))
    o = punto(i, muelle, 1.2)
    hijos.append(especiales.muelle("Muelle", o, hacia(o, centro(i))))
    return hijos


def lirios(i, tono, rng):
    """3 · Laguna de los Lirios: lirios azules altos, hortensias y piedras para cruzar."""
    t = angulo_tema(i)
    hijos = nenufares(i, rng, (200, 210, 255), 7) + orilla(i, rng, AZULES, rocas=3, macizos=2, evitar=(t + 180,))
    for k in range(3):
        hijos.append(tierra.flores(f"Lirios{k}", punto(i, t - 30 + k * 30, 2.4), rng, AZULES, n=8, radio=1.6, alto=(1.8, 2.6)))
    hortensia = []
    base = punto(i, t, 5.5)
    for k in range(7):
        p = gi.add(base, (rng.uniform(-1.6, 1.6), rng.uniform(0.6, 2), rng.uniform(-1.6, 1.6)))
        hortensia.append(gi.pieza(f"Bola{k}", (1.5, 1.5, 1.5), p, rng.choice(AZULES), "SmoothPlastic", forma="Ball", **gi.FANTASMA))
    hijos.append(gi.grupo("Hortensia", hortensia))
    pasos = [en_agua(i, t + 140 + k * 20, 0.74) for k in range(5)]
    hijos.append(agua.piedras_paso("Piedras", pasos, rng))
    return hijos


def bambu(i, tono, rng):
    """4 · Estanque de Bambú: un bosquecito de bambú y un farol de piedra junto al agua."""
    t = angulo_tema(i)
    hijos = nenufares(i, rng, (255, 255, 255), 6) + orilla(i, rng, BLANCAS, rocas=5, macizos=1)
    hijos.append(tierra.bambu("Bambu", punto(i, t, 5), rng, n=8))
    hijos.append(tierra.bambu("BambuChico", punto(i, t + 42, 4), rng, n=4, alto=(6, 9)))
    hijos.append(tierra.farol_piedra("Farol", punto(i, t - 38, 2.4)))
    return hijos


def hongos(i, tono, rng):
    """5 · Estanque de los Hongos: hongos gigantes que brillan en violeta y otros chicos en la
    orilla."""
    t = angulo_tema(i)
    hijos = nenufares(i, rng, VIOLETAS[2], 7) + orilla(i, rng, VIOLETAS, rocas=4, matas=1, macizos=1)
    grandes = []
    for k, (dx, dz, alto, s) in enumerate(((0, 0, 4.2, 4.6), (2.6, 1.8, 2.8, 3.2), (-2.4, 1.2, 2.2, 2.6))):
        b = gi.add(punto(i, t, 5), (dx, 0, dz))
        grandes.append(tierra.hongo(f"Hongo{k}", b, alto, s, rng, rng.choice(VIOLETAS)))
    hijos.append(gi.grupo("HongosGrandes", grandes))
    for k in range(4):
        b = punto(i, t + 70 + k * 55, 1.2)
        hijos.append(tierra.hongo(f"Hongito{k}", b, rng.uniform(0.7, 1.3), rng.uniform(0.9, 1.5), rng,
                                  rng.choice(VIOLETAS) if k % 2 == 0 else None))
    hijos.append(tierra.helecho("HelechoHongos", punto(i, t + 35, 3.5), rng, 3.2))
    return hijos


def petalos(nombre, i, rng, colores, n=14):
    """Pétalos o hojas sueltas flotando en el agua."""
    hijos = []
    for k in range(n):
        p = en_agua(i, rng.uniform(0, 360), rng.uniform(0.25, 0.92), AGUA + 0.05)
        hijos.append(elipsoide(f"Petalo{k}", p, (0.55, 0.05, 0.42), rng.choice(colores), "SmoothPlastic",
                               gi.ry(rng.uniform(0, 360)), **gi.FANTASMA))
    return gi.grupo(nombre, hijos)
