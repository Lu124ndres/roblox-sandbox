r"""
Rampas de entrada a los senderos elevados del jardín (sin bpy): en cada una de las cuatro
salidas de la cruz, donde el sendero (a 8) se encuentra con el camino de piedra de afuera (a 6),
una cuña de bloques en lugar del escalón: arena arriba, bisel a los costados y el lado de piedra
gris, del ancho del sendero. Empieza un bisel adentro del sendero (tapa su canto) y baja LARGO
studs (pendiente 1:4).
    rampas(alto, material, celda, bisel) -> {nombre: [(polígono Roblox, color, normal)]}
"""
import isla_bloques_forma as F

LARGO = 8.0  # studs que baja la rampa: dos celdas
ABAJO = 0.5  # los lados siguen un poco bajo el suelo (no se ve el borde)


def _salida(alto, material, celda, di, dj):
    """Última columna de sendero a lo largo de la dirección (di, dj) y su ancho de costado."""
    lejos, costados = None, []
    for (i, j), m in material.items():
        if m != "sendero":
            continue
        along, lado = i * di + j * dj, j if di else i  # a lo largo del eje y de costado
        if abs((lado + 0.5) * celda) > F.L["gardenPathHalfWidth"] + 1:  # solo la franja del rayo
            continue
        if lejos is None or along > lejos:
            lejos, costados = along, [lado]
        elif along == lejos:
            costados.append(lado)
    return lejos, min(costados), max(costados)


def rampas(alto, material, celda, bisel):
    resultado = {}
    for angulo in F.L["gardenSpokeAngles"]:
        dx, dz = F.polar(angulo, 1)
        di, dj = round(dx), round(dz)
        lejos, lado0, lado1 = _salida(alto, material, celda, di, dj)
        sentido = 1 if di + dj > 0 else -1
        borde = sentido * (lejos + (1 if sentido > 0 else 0)) * celda  # coordenada del borde de afuera
        arriba = max(h for (i, j), h in alto.items() if material[i, j] == "sendero")
        abajo = arriba - 2
        v0, v1 = lado0 * celda, (lado1 + 1) * celda  # costados (coordenada perpendicular)
        u0, u1 = -bisel, LARGO

        def punto(u, v, y):
            a = borde + sentido * u  # a lo largo del eje
            return (a, y, v) if di else (v, y, a)

        def altura(u):
            return arriba - (arriba - abajo) * max(u, 0) / LARGO

        normal_afuera = lambda lado: (0, 0, lado) if di else (lado, 0, 0)
        caras = [((punto(u0, v0 + bisel, arriba), punto(u1, v0 + bisel, abajo),
                   punto(u1, v1 - bisel, abajo), punto(u0, v1 - bisel, arriba)),
                  "sendero_arriba0", (sentido * di * 0.25, 1, sentido * dj * 0.25))]
        for v_borde, v_adentro, lado in ((v0, v0 + bisel, -1), (v1, v1 - bisel, 1)):
            caras.append(((punto(u0, v_adentro, arriba), punto(u1, v_adentro, abajo),
                           punto(u1, v_borde, abajo - bisel), punto(u0, v_borde, arriba - bisel)),
                          "sendero_canto", (normal_afuera(lado)[0], 1, normal_afuera(lado)[2])))
            caras.append(((punto(u0, v_borde, arriba - bisel), punto(u1, v_borde, abajo - bisel),
                           punto(u1, v_borde, abajo - ABAJO), punto(u0, v_borde, abajo - ABAJO)),
                          "sendero_lado", normal_afuera(lado)))
        resultado[f"RampaSendero_{angulo}"] = caras
    return resultado
