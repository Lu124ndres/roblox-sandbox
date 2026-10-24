"""Posproducción del video tutorial: de la captura de la ventana de Studio al video final.

    python tools/trailer/grabar.py <captura.mp4> <salida.mp4>

La captura (ffmpeg gdigrab de la ventana entera de Studio) trae los paneles alrededor del
juego. El director (Director.client) pinta la pantalla de magenta al principio y al final:
con el primer destello se encuentra el rectángulo del juego (para recortar los paneles) y
el momento de inicio; con el último, el fin. Después recorta a 16:9, escala a 1920x1080 y
codifica H.264 a 30 fps sin audio (los videos de la página del juego van en silencio).
"""
import json
import subprocess
import sys
from pathlib import Path

import numpy as np

MAGENTA_SHARE = 0.25  # fracción de la imagen en magenta para contar como destello
STEP = 0.1            # segundos entre muestras al buscar los destellos
MARGIN = 0.15         # segundos que se dejan fuera después del destello inicial y antes del final


def run(*args):
    subprocess.run(args, check=True)


def size(path):
    out = subprocess.check_output(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
                                   "stream=width,height", "-of", "csv=p=0", str(path)])
    w, h = out.decode().strip().split(",")
    return int(w), int(h)


def frames(path):
    """(t, imagen) cada STEP segundos, leyendo el video una sola vez."""
    w, h = size(path)
    proc = subprocess.Popen(["ffmpeg", "-v", "error", "-i", str(path), "-vf", f"fps={1 / STEP}",
                             "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], stdout=subprocess.PIPE)
    k = 0
    while True:
        raw = proc.stdout.read(w * h * 3)
        if len(raw) < w * h * 3:
            break
        yield k * STEP, np.frombuffer(raw, np.uint8).reshape(h, w, 3).astype(int)
        k += 1
    proc.wait()


def magenta_mask(img):
    r, g, b = img[..., 0], img[..., 1], img[..., 2]
    return (r > 200) & (b > 200) & (g < 80)


def find_flashes(path):
    """(t_inicio, caja_del_juego, t_fin): el primer y el último destello magenta."""
    first, box, last = None, None, None
    for t, img in frames(path):
        mask = magenta_mask(img)
        if mask.mean() > MAGENTA_SHARE:
            ys, xs = np.where(mask)
            if first is None:
                first = t
                box = (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)
            last = t
    if first is None or last is None or last - first < 5:
        raise SystemExit("no encontré los dos destellos magenta en la captura")
    return first, box, last


def main():
    source, target = Path(sys.argv[1]), Path(sys.argv[2])
    start, (x0, y0, x1, y1), end = find_flashes(source)
    # Hasta el final del primer destello (no empieza en magenta) y hasta antes del último.
    start_at = start + STEP * 6 + MARGIN
    end_at = end - MARGIN
    w, h = x1 - x0, y1 - y0
    w -= w % 2
    h -= h % 2
    # A 16:9 recortando lo que sobre (centrado) y a 1080p.
    if w / h > 16 / 9:
        cw, ch = int(h * 16 / 9) // 2 * 2, h
    else:
        cw, ch = w, int(w * 9 / 16) // 2 * 2
    cx, cy = x0 + (w - cw) // 2, y0 + (h - ch) // 2
    print(json.dumps({"inicio": round(start_at, 2), "fin": round(end_at, 2), "juego": [x0, y0, x1, y1],
                      "recorte": [cx, cy, cw, ch]}))
    run("ffmpeg", "-v", "error", "-y", "-ss", f"{start_at:.3f}", "-to", f"{end_at:.3f}", "-i", str(source),
        "-vf", f"crop={cw}:{ch}:{cx}:{cy},scale=1920:1080:flags=lanczos,fps=30",
        "-an", "-c:v", "libx264", "-preset", "slow", "-crf", "17", "-pix_fmt", "yuv420p",
        "-movflags", "+faststart", str(target))
    print("listo:", target, f"{end_at - start_at:.1f} s")


if __name__ == "__main__":
    main()
