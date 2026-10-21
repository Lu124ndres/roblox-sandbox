r"""
La revisión de la Orca v2 que se suma a la de la guía (minotauro_v2_poses.py: medir() y revisar()).
La carga orca_v2_poses.py con exec, después de minotauro_v2_poses.py:
    medir_todo()   el reposo: cruces y huecos de la guía y lo hondo de cada muestra (_hondos)
    revisar()      la de la guía y, además, atraviesa por muestra; los pares de JUNTAS_CRUZADAS se
                   revisan como junta
"""

_revisar_guia = revisar
# Pares sin articulación directa que se revisan como junta (1.0 celda, por muestra): la base de la
# dorsal (de la Cola1) va metida en el lomo del Pecho, cruzando la junta Pecho/Cola1; al doblarse la
# Cola1 o mecerse la dorsal se hunde un poco más en el Pecho, como en su propio lomo.
JUNTAS_CRUZADAS = [("Pecho", "Dorsal")]


def _hondos():
    """Por cada par de piezas sin articulación entre ellas que se tocan: lo hondo (celdas) de cada
    muestra de una dentro de la otra (0 si está afuera)."""
    nombres = list(HUESOS)
    t = {n: arbol(ob[n]) for n in nombres}
    out = {}
    for i, a in enumerate(nombres):
        for b in nombres[i + 1:]:
            if HUESOS[a][0] == b or HUESOS[b][0] == a or not t[a].overlap(t[b]):
                continue
            par = []
            for x, arb in ((a, t[b]), (b, t[a])):
                d = []
                for q in muestras(ob[x]):
                    loc, nor, _, dist = arb.find_nearest(q)
                    d.append(dist / C if loc is not None and (q - loc).dot(nor) < 0 else 0.0)
                par.append(np.array(d))
            out[(a, b)] = par
    return out


def medir_todo():
    """El reposo para revisar(): lo de la guía (cruces y huecos, medir()) y lo hondo de cada muestra."""
    return (*medir(), _hondos())


def revisar(reposo):
    """revisar() de la guía y, además, atraviesa por muestra: la guía toma lo más hondo de cada par,
    así que una pieza muy metida en reposo (la dorsal, 4 celdas en el Pecho) tapaba lo que se metía
    en otro lado. Aquí cada muestra se compara con ella misma en reposo."""
    atraviesa, juntas, sueltas = _revisar_guia(reposo[:2])
    cruzadas = {frozenset(p) for p in JUNTAS_CRUZADAS}
    atraviesa = [a for a in atraviesa if frozenset(a["piezas"]) not in cruzadas]
    ya = {frozenset(a["piezas"]) for a in atraviesa}
    for (a, b), ahora in _hondos().items():
        antes = reposo[2].get((a, b), [np.zeros(len(x)) for x in ahora])
        mas = max(float((x - y).max()) for x, y in zip(ahora, antes))
        junta = frozenset((a, b)) in cruzadas
        if mas > (JUNTA if junta else PENETRA) and frozenset((a, b)) not in ya:
            (juntas if junta else atraviesa).append({"piezas": [a, b], "celdas": round(mas, 2), "por_muestra": True})
    return atraviesa, juntas, sueltas
