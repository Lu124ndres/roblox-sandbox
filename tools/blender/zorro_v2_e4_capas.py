r"""
Capas de profundidad de las nueve colas del Zorro de agua v2, etapa 4: busca, para cada cola, la y de
la raíz, el paso en y por tramo y el hondo (CAPAS en zorro_v2_e4_colas.py) con las reglas que dejaron
limpia la E3. No usa Blender: lee las formas x-z de zorro_v2_e4_colas.py y lista los pares de tramos
cercanos antes de fijar números.

Reglas:
    - dos tramos de colas distintas que se solapan en x-z: entre sus franjas en y queda al menos una
      celda; si solo se tocan o están a menos de 1.5 celdas, no comparten franja (en la E4, más
      densa, también una celda, y "cerca" es a menos de CERCA celdas);
    - lo mismo dos tramos no seguidos de una misma cola; dos seguidos comparten al menos una celda
      (hondo 3 con paso 2, u hondo 2 con paso 1);
    - si la punta de una cola cae sobre los tramos medios de otra, la de la punta va detrás;
    - una cola y su espejo comparten capa y van separados al menos 2 celdas en x (se avisa si no);
    - la raíz de cada cola tiene un rango de y permitido (RAICES): donde se apoya en el cuerpo y deja
      una celda al muslo.
Se elige la combinación que deja el abanico menos hondo (la y más atrás) y, a igualdad, la de menos
y en total.

Uso (sin Blender; desde la raíz del repo):  python tools/blender/zorro_v2_e4_capas.py
"""
import itertools, math, os

HERE = os.path.dirname(os.path.abspath(__file__))
OPCIONES = [(1, 2), (2, 3)]  # (paso, hondo)
# Con nueve colas el abanico es más denso que en la E3: dos tramos a menos de CERCA celdas en x-z
# (o que se solapan) dejan HUECO celdas entre sus franjas, también dentro de una misma cola.
CERCA, HUECO, HUECO_PUNTA = 2.5, 1, 3
# Rango de la y de la raíz de cada cola: la A sale del lomo (encima del anca, con una celda de aire);
# las otras, de la cara de atrás de la grupa (y 8) o de la base de las colas, detrás.
RAICES = {"Cola1": range(8, 30), "Cola2": range(0, 7), "Cola4": range(8, 30), "Cola6": range(8, 30),
          "Cola8": range(8, 30)}


def formas():
    """{(cola, tramo): [polígonos x-z]} de las nueve colas (las capas no cambian las formas)."""
    piezas = {}
    g = {"prisma": lambda parte, col, color, pol, y, eje: piezas.setdefault(
        (parte.rsplit("_", 1)[0], int(parte.rsplit("_", 1)[1])), []).append([tuple(p) for p in pol])}
    exec(open(os.path.join(HERE, "zorro_v2_e4_colas.py"), encoding="utf-8").read(), g)
    g["CAPAS"] = {k: (0, 1, 2) for k in g["CAPAS"]}
    g["colas"]()
    tipo = {}
    for izq, der, *_ in g["COLAS_ABANICO"]:
        tipo[izq] = izq
        if der:
            tipo[der] = izq
    return piezas, tipo


def _area(p):
    return sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(p, p[1:] + p[:1])) / 2


def _ccw(p):
    return p if _area(p) > 0 else p[::-1]


def _recortar(poli, clip):
    for a, b in zip(clip, clip[1:] + clip[:1]):
        lado = lambda p: (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0])
        nuevo = []
        for p, q in zip(poli, poli[1:] + poli[:1]):
            sp, sq = lado(p), lado(q)
            if sp >= 0:
                nuevo.append(p)
            if (sp >= 0) != (sq >= 0):
                t = sp / (sp - sq)
                nuevo.append((p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t))
        poli = nuevo
        if not poli:
            break
    return poli


def _dist_seg(p, a, b):
    ab = (b[0] - a[0], b[1] - a[1])
    t = max(0, min(1, ((p[0] - a[0]) * ab[0] + (p[1] - a[1]) * ab[1]) / (ab[0] ** 2 + ab[1] ** 2)))
    return math.hypot(p[0] - a[0] - t * ab[0], p[1] - a[1] - t * ab[1])


def relacion(pa, pb):
    """2 si se solapan, 1 si están a menos de CERCA celdas, 0 si están lejos."""
    for a in pa:
        for b in pb:
            r = _recortar(_ccw(a), _ccw(b))
            if len(r) >= 3 and abs(_area(r)) > 1e-6:
                return 2
    d = min(_dist_seg(p, q[i], q[(i + 1) % len(q)]) for x, y in ((pa, pb), (pb, pa))
            for a in x for p in a for q in y for i in range(len(q)))
    return 1 if d < CERCA else 0


def pares():
    """[(tipo_a, tramo_a, tipo_b, tramo_b, relación)] de los tramos cercanos, y los avisos de espejo."""
    piezas, tipo = formas()
    claves = sorted(piezas)
    out, avisos = [], []
    for (ca, ka), (cb, kb) in itertools.combinations(claves, 2):
        if ca == cb and abs(ka - kb) < 2:
            continue
        r = relacion(piezas[(ca, ka)], piezas[(cb, kb)])
        if not r:
            continue
        if ca != cb and tipo[ca] == tipo[cb]:
            avisos.append(f"{ca}_{ka} y su espejo {cb}_{kb} están cerca: deben ir a 2 celdas en x")
            continue
        out.append((tipo[ca], ka, tipo[cb], kb, r))
    return out, avisos


def franja(capa, k):
    r, p, h = capa
    return r + p * (k - 1), r + p * (k - 1) + h


def cumple(capas, lista):
    for ta, ka, tb, kb, rel in lista:
        if ta in capas and tb in capas:
            (a0, a1), (b0, b1) = franja(capas[ta], ka), franja(capas[tb], kb)
            hueco = max(b0 - a1, a0 - b1)
            punta = ta != tb and 5 in (ka, kb)  # las puntas, lejos de la raíz, se mueven más
            if hueco < (HUECO_PUNTA if punta else HUECO):
                return False
            # La punta de una cola que se solapa con los tramos medios de otra: la de la punta va detrás.
            if rel == 2 and ta != tb and ka == 5 and 2 <= kb <= 4 and a0 - b1 < HUECO:
                return False
            if rel == 2 and ta != tb and kb == 5 and 2 <= ka <= 4 and b0 - a1 < HUECO:
                return False
    return True


def buscar():
    lista, avisos = pares()
    tipos = list(RAICES)
    opciones = {t: [(r, p, h) for r in RAICES[t] for p, h in OPCIONES] for t in tipos}
    mejor = [None]

    def fondo(capas):
        return max(franja(c, 5)[1] for c in capas.values())

    def paso(i, capas):
        if mejor[0] and fondo(capas) > mejor[0][0]:
            return
        if i == len(tipos):
            clave = (fondo(capas), sum(c[0] for c in capas.values()))
            if not mejor[0] or clave < mejor[0][:2]:
                mejor[0] = (*clave, dict(capas))
            return
        for op in opciones[tipos[i]]:
            capas[tipos[i]] = op
            if cumple(capas, lista):
                paso(i + 1, capas)
            del capas[tipos[i]]

    paso(0, {})
    return lista, avisos, mejor[0]


if __name__ == "__main__":
    lista, avisos, mejor = buscar()
    print("Pares de tramos cercanos (2 = se solapan, 1 = a menos de 1.5 celdas):")
    for ta, ka, tb, kb, rel in lista:
        print(f"    {ta}_{ka} / {tb}_{kb}: {rel}")
    for a in avisos:
        print("AVISO", a)
    print("CAPAS =", mejor and mejor[2], " fondo y =", mejor and mejor[0])
