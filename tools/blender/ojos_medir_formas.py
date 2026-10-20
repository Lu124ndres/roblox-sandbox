r"""
Formas de ojos_medir.py (lo carga con exec): áreas, la pieza del ojo, punto dentro de un polígono
y el rectángulo más grande dentro de la máscara de lo que se ve.
"""


def area(P, p):
    """Área de un polígono (índices en P)."""
    v = p[0]
    return sum((P[v[i]] - P[v[0]]).cross(P[v[i + 1]] - P[v[0]]).length / 2 for i in range(1, len(v) - 1))


def pieza(P, cand, celda):
    """Los polígonos que se tocan (cajas a menos de 0.05 celda) forman piezas: la de más área."""
    cajas = [(V([min(P[k][i] for k in p[0]) for i in range(3)]), V([max(P[k][i] for k in p[0]) for i in range(3)]))
             for p in cand]
    padre = list(range(len(cand)))

    def raiz(i):
        while padre[i] != i:
            padre[i] = padre[padre[i]]
            i = padre[i]
        return i

    tol = celda * 0.05
    for i in range(len(cand)):
        for j in range(i + 1, len(cand)):
            if all(cajas[i][0][k] - tol <= cajas[j][1][k] and cajas[j][0][k] - tol <= cajas[i][1][k] for k in range(3)):
                padre[raiz(i)] = raiz(j)
    grupos = {}
    for i, p in enumerate(cand):
        grupos.setdefault(raiz(i), []).append(p)
    return max(grupos.values(), key=lambda g: sum(area(P, p) for p in g)) if grupos else []


def dentro(poli, a, b):
    """Punto dentro de un polígono convexo (en 2D, de cualquier orientación)."""
    signo = 0
    for (x0, y0), (x1, y1) in zip(poli, poli[1:] + poli[:1]):
        c = (x1 - x0) * (b - y0) - (y1 - y0) * (a - x0)
        if abs(c) > 1e-9:
            if signo and (c > 0) != (signo > 0):
                return False
            signo = c
    return True


def rectangulo(mask):
    """(i, j, ancho, alto) en celdas de la grilla: mejor área × raíz del aspecto dentro de la máscara."""
    S = np.zeros((mask.shape[0] + 1, mask.shape[1] + 1), dtype=np.int32)
    S[1:, 1:] = mask.astype(np.int32).cumsum(0).cumsum(1)
    ci, cj = (np.argwhere(mask).mean(axis=0) if mask.any() else (0, 0))
    tamaños = [(w, h) for w in range(1, mask.shape[0] + 1) for h in range(1, mask.shape[1] + 1)]
    tamaños.sort(key=lambda t: (-round(t[0] * t[1] * math.sqrt(min(t) / max(t)), 6), t[1] > t[0]))
    for w, h in tamaños:
        suma = S[w:, h:] - S[:-w, h:] - S[w:, :-h] + S[:-w, :-h]
        libres = np.argwhere(suma == w * h)
        if len(libres):
            i, j = min(libres, key=lambda q: (q[0] + w / 2 - 0.5 - ci) ** 2 + (q[1] + h / 2 - 0.5 - cj) ** 2)
            return int(i), int(j), w, h
    return None
