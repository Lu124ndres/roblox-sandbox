r"""
Columnas y caras de la isla de bloques (sin bpy). Columnas de CELDA x CELDA studs con la
altura en escalones de PASO studs (el mismo módulo que el volcán), y el acabado del volcán:
bisel de BISEL studs en el borde de arriba de cada columna que da a un vecino más bajo, cara
de arriba en tres tonos por manchas y los lados de otro color (tierra bajo el pasto, con una
franja de pasto arriba).
Para pesar poco, las caras de arriba de las columnas sin bisel se juntan en rectángulos de la
misma altura y color (greedy meshing) y los lados en tiras a lo largo de cada borde.
    columnas(muestra, alzar, n) -> (alto, material, tono, base)
    caras(alto, material, tono, piso) -> {(sx, sz): [(vértices Roblox, color, normal)]}
"""
import math

CELDA = 4  # studs por columna (como el volcán)
PASO = 2  # studs por escalón: 6, 2 y -18 caen justo
PASO_JARDIN = 1  # el pasto del jardín ondula en escalones de 1
SECTOR = 128  # studs por lado de cada malla
BISEL = 0.4  # 10 % de la celda
FRANJA = 0.5  # pasto que baja por el lado antes de la tierra
CON_FRANJA = {"pasto", "jardin"}
VECINOS = ((1, 0, (1, 0, 0)), (-1, 0, (-1, 0, 0)), (0, 1, (0, 0, 1)), (0, -1, (0, 0, -1)))


def tono(i, j):
    """Manchas de tres tonos (no un tablero): ruido suave sobre la cuadrícula."""
    n = math.sin(i * 0.37 + j * 0.11) + 0.8 * math.sin(j * 0.29 - i * 0.19) + 0.6 * math.sin((i + j) * 0.53)
    return 1 if n > 0.9 else 2 if n < -0.9 else 0


def columnas(muestra, alzar, n, agua, piso, elevar=None):
    alto, mat, ton, base = {}, {}, {}, {}
    for i in range(-n, n):
        for j in range(-n, n):
            x, z = (i + 0.5) * CELDA, (j + 0.5) * CELDA
            h0, m, _ = muestra(x, z)
            if elevar:
                h0, m = elevar(x, z, h0, m)  # parte de la forma: la apertura no lo toca
            h, m = alzar(i, j, x, z, h0, m)
            paso = PASO_JARDIN if m == "jardin" else PASO
            h = round(h / paso) * paso
            if h <= piso:
                continue
            if m == "arena" and h < agua:
                m = "mojada"  # arena bajo el mar, más oscura
            alto[i, j], mat[i, j], ton[i, j] = h, m, tono(i, j)
            base[i, j] = round(h0 / paso) * paso
    sin_sueltos(alto, base)
    return alto, mat, ton, base


def sin_sueltos(alto, base):
    """Nada de bloques sueltos ni crestas finas: a lo que el relieve agregó (alto - base) se le
    hace una apertura (erosión y después dilatación en la vecindad de 4). Desaparece todo lo
    que mide menos de 3 columnas de ancho; las lomas grandes quedan igual."""
    def vecindad(c):
        return (c, (c[0] + 1, c[1]), (c[0] - 1, c[1]), (c[0], c[1] + 1), (c[0], c[1] - 1))

    agregado = {c: alto[c] - base[c] for c in alto}
    erosion = {c: min(agregado.get(v, 0) for v in vecindad(c)) for c in agregado}
    for c in agregado:
        alto[c] = base[c] + max(erosion.get(v, 0) for v in vecindad(c) if v in agregado)


def _sector(i, j):
    k = SECTOR // CELDA
    return (math.floor(i / k), math.floor(j / k))


def caras(alto, mat, ton, piso):
    sectores = {}

    def agregar(clave, quad, color, normal):
        sectores.setdefault(clave, []).append((quad, color, normal))

    def bajo(i, j, di, dj):
        return alto.get((i + di, j + dj), piso) < alto[i, j]

    # Arriba sin bisel: rectángulos de igual altura y color, dentro de un sector.
    llano = {c for c in alto if not any(bajo(*c, di, dj) for di, dj, _ in VECINOS)}
    clave = lambda c: (alto[c], mat[c], ton[c], _sector(*c))
    hecho = set()
    for c in sorted(llano, key=lambda c: (c[1], c[0])):
        if c in hecho:
            continue
        i, j = c
        ancho = 1
        while (i + ancho, j) in llano and (i + ancho, j) not in hecho and clave((i + ancho, j)) == clave(c):
            ancho += 1
        largo = 1
        while all((i + k, j + largo) in llano and (i + k, j + largo) not in hecho
                  and clave((i + k, j + largo)) == clave(c) for k in range(ancho)):
            largo += 1
        for k in range(ancho):
            for m in range(largo):
                hecho.add((i + k, j + m))
        h = alto[c]
        x0, x1, z0, z1 = i * CELDA, (i + ancho) * CELDA, j * CELDA, (j + largo) * CELDA
        agregar(_sector(i, j), ((x0, h, z0), (x1, h, z0), (x1, h, z1), (x0, h, z1)),
                f"{mat[c]}_arriba{ton[c]}", (0, 1, 0))
    # Columnas con bisel: la cara de arriba se mete BISEL en cada lado que baja.
    for c in alto:
        if c in llano:
            continue
        i, j = c
        h = alto[c]
        x0, x1, z0, z1 = i * CELDA, (i + 1) * CELDA, j * CELDA, (j + 1) * CELDA
        e, o, nn, s = bajo(i, j, 1, 0), bajo(i, j, -1, 0), bajo(i, j, 0, 1), bajo(i, j, 0, -1)
        a0, a1 = x0 + (BISEL if o else 0), x1 - (BISEL if e else 0)
        b0, b1 = z0 + (BISEL if s else 0), z1 - (BISEL if nn else 0)
        sec = _sector(i, j)
        agregar(sec, ((a0, h, b0), (a1, h, b0), (a1, h, b1), (a0, h, b1)), f"{mat[c]}_arriba{ton[c]}", (0, 1, 0))
        hb = h - BISEL
        canto = f"{mat[c]}_canto"
        if e:
            agregar(sec, ((a1, h, b0), (x1, hb, z0), (x1, hb, z1), (a1, h, b1)), canto, (1, 1, 0))
        if o:
            agregar(sec, ((a0, h, b0), (x0, hb, z0), (x0, hb, z1), (a0, h, b1)), canto, (-1, 1, 0))
        if nn:
            agregar(sec, ((a0, h, b1), (x0, hb, z1), (x1, hb, z1), (a1, h, b1)), canto, (0, 1, 1))
        if s:
            agregar(sec, ((a0, h, b0), (x0, hb, z0), (x1, hb, z0), (a1, h, b0)), canto, (0, 1, -1))
        # Tapas: donde un bisel termina recto contra una vecina de la misma altura que no baja de
        # ese lado (esquina de adentro), la punta del bisel queda abierta; un triángulo la cierra.
        altura = lambda di, dj: alto.get((i + di, j + dj), piso)
        for (di, dj, _), lado in zip(VECINOS, (e, o, nn, s)):
            if not lado:
                continue
            for pi, pj in ((dj, di), (-dj, -di)):
                if bajo(i, j, pi, pj) or altura(pi, pj) != h or altura(di + pi, dj + pj) < h:
                    continue
                borde = (x1 if di > 0 else x0) if di else (z1 if dj > 0 else z0)
                punta = (x1 if pi > 0 else x0) if pi else (z1 if pj > 0 else z0)
                if di:
                    tapa = ((borde - di * BISEL, h, punta), (borde, h, punta), (borde, hb, punta))
                else:
                    tapa = ((punta, h, borde - dj * BISEL), (punta, h, borde), (punta, hb, borde))
                agregar(sec, tapa, canto, (-pi, 0, -pj))
    # Lados: de abajo del bisel hasta el vecino, en tiras a lo largo de cada borde.
    tiras = {}
    for (i, j), h in alto.items():
        for di, dj, normal in VECINOS:
            abajo = alto.get((i + di, j + dj), piso)
            if abajo >= h:
                continue
            linea = i + max(di, 0) if di else j + max(dj, 0)  # coordenada del borde (en celdas)
            paso = j if di else i  # a lo largo del borde
            k = (di, dj, linea, h, abajo, mat[i, j], _sector(i, j))
            tiras.setdefault(k, []).append(paso)
    for (di, dj, linea, h, abajo, m, sec), pasos in tiras.items():
        pasos.sort()
        inicio = previo = pasos[0]
        for p in pasos[1:] + [None]:
            if p is not None and p == previo + 1:
                previo = p
                continue
            _lado(agregar, sec, di, dj, linea, inicio, previo + 1, h, abajo, m, piso)
            if p is not None:
                inicio = previo = p
    return sectores


def _lado(agregar, sec, di, dj, linea, desde, hasta, h, abajo, m, piso):
    arriba = h - BISEL
    # Un bisel más abajo que la vecina: tapa el triángulo de su bisel (si no, queda una muesca).
    abajo = abajo if abajo <= piso else abajo - BISEL
    cortes = [(arriba, max(arriba - FRANJA, abajo), f"{m}_canto")] if m in CON_FRANJA else []
    tope = cortes[0][1] if cortes else arriba
    if tope > abajo:
        cortes.append((tope, abajo, f"{m}_lado"))
    normal = (di, 0, dj)
    for y1, y0, color in cortes:
        if di:
            x = linea * CELDA
            quad = ((x, y1, desde * CELDA), (x, y0, desde * CELDA), (x, y0, hasta * CELDA), (x, y1, hasta * CELDA))
        else:
            z = linea * CELDA
            quad = ((desde * CELDA, y1, z), (desde * CELDA, y0, z), (hasta * CELDA, y0, z), (hasta * CELDA, y1, z))
        agregar(sec, quad, color, normal)


def orientar(quad, normal):
    """Ordena los vértices para que la cara mire hacia `normal` (en ejes de Roblox)."""
    p0, p1, p2 = quad[0], quad[1], quad[2]
    u = [p1[k] - p0[k] for k in range(3)]
    v = [p2[k] - p1[k] for k in range(3)]
    n = (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
    return quad if sum(n[k] * normal[k] for k in range(3)) >= 0 else tuple(reversed(quad))
