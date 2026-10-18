"""
Roca con grietas de lava para los dibujos de los trajes v2 (Dios del Volcán): celdas de
Voronoi (cada piedra con su tono) separadas por grietas que brillan. Se calcula el campo a un
cuarto de la resolución y se agranda suave antes de cortar, así las grietas salen nítidas sin
calcular millones de distancias. Va en color y en la máscara de brillo.
"""
import numpy as np
from PIL import Image


def _campo(L, semilla, celda):
    """Distancia al borde de celda (d2 - d1, en studs) y celda más cercana, a 1/4 de resolución."""
    W, H = L.tam()
    w, h = max(8, W // 4), max(8, H // 4)
    a0, b0 = L.a_studs(0, 0)
    a1, b1 = L.a_studs(W, H)
    rng = np.random.default_rng(semilla)
    lo, hi = np.array([min(a0, a1), min(b0, b1)]), np.array([max(a0, a1), max(b0, b1)])
    n = max(4, int(np.prod(hi - lo) / celda**2))
    # Semillas en cuadrícula sacudida: piedras parejas, sin huecos grandes ni amontonadas.
    lado = int(np.ceil(np.sqrt(n)))
    gx, gy = np.meshgrid((np.arange(lado) + 0.5) / lado, (np.arange(lado) + 0.5) / lado)
    base = np.stack([gx.ravel(), gy.ravel()], 1)
    semillas = lo + (base + rng.uniform(-0.42, 0.42, base.shape) / lado) * (hi - lo)
    A, B = np.meshgrid(np.linspace(a0, a1, w), np.linspace(b0, b1, h))
    d1 = np.full((h, w), np.inf)
    d2 = np.full((h, w), np.inf)
    cual = np.zeros((h, w), dtype=np.int32)
    for i in range(0, len(semillas), 48):
        s = semillas[i:i + 48]
        d = np.hypot(A[..., None] - s[:, 0], B[..., None] - s[:, 1])
        for j in range(d.shape[2]):
            dj = d[..., j]
            menor = dj < d1
            d2 = np.where(menor, d1, np.minimum(d2, dj))
            cual = np.where(menor, i + j, cual)
            d1 = np.where(menor, dj, d1)
    return d2 - d1, cual, rng.uniform(0.78, 1.18, len(semillas))


def _agrandar(arr, W, H, metodo):
    return np.asarray(Image.fromarray(arr.astype(np.float32), "F").resize((W, H), metodo))


def grietas(L, semilla, celda=0.5, ancho=0.022, roca=(40, 34, 37), lava=(255, 110, 20),
            lava_clara=(255, 220, 120), brillo=1.0):
    """Llena la región del lienzo con roca agrietada (color y brillo)."""
    W, H = L.tam()
    borde, cual, tonos = _campo(L, semilla, celda)
    borde = _agrandar(borde, W, H, Image.BILINEAR)
    tono = _agrandar(tonos[cual], W, H, Image.NEAREST)
    nucleo = np.clip(1 - borde / ancho, 0, 1)  # el centro de la grieta
    halo = np.clip(1 - borde / (ancho * 3), 0, 1) ** 2  # el resplandor alrededor
    bisel = np.clip(borde / (celda * 0.6), 0, 1) ** 0.5  # cada piedra más clara en el medio
    rgb = np.array(roca, np.float32) * (tono * (0.72 + 0.28 * bisel))[..., None]
    rgb = rgb * (1 - halo[..., None]) + np.array(lava, np.float32) * halo[..., None] * 0.7
    rgb = rgb * (1 - nucleo[..., None]) + np.array(lava_clara, np.float32) * nucleo[..., None]
    mascara = np.clip(nucleo + halo * 0.45, 0, 1) * brillo * 255
    L.pegar(Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB"),
            Image.fromarray(mascara.astype(np.uint8), "L"))


def magma(L, semilla, celda=0.25, costra=(70, 22, 8), lava=(255, 120, 18), lava_clara=(255, 226, 120)):
    """Llena la región con lava viva: islas de costra oscura flotando sobre lava que brilla."""
    W, H = L.tam()
    borde, cual, tonos = _campo(L, semilla, celda)
    borde = _agrandar(borde, W, H, Image.BILINEAR)
    tono = _agrandar(tonos[cual], W, H, Image.NEAREST)
    isla = np.clip((borde - celda * 0.18) / (celda * 0.35), 0, 1) ** 1.5  # 0 en la lava, 1 en la costra
    caliente = np.clip(1 - borde / (celda * 0.12), 0, 1)  # los ríos más calientes
    rgb = np.array(lava, np.float32) * (1 - caliente[..., None]) + np.array(lava_clara, np.float32) * caliente[..., None]
    rgb = rgb * (1 - isla[..., None]) + np.array(costra, np.float32) * (tono * 0.9)[..., None] * isla[..., None]
    mascara = np.clip(1 - isla * 0.85, 0, 1) * 255
    L.pegar(Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB"),
            Image.fromarray(mascara.astype(np.uint8), "L"))
