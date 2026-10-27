"""Arma el video del previo de la cutscene con ffmpeg a partir de los cuadros de intro_previo.py:
acabado de imagen (contraste, brillo que se corre en las luces, aberración, viñeta y grano),
barras de cine, destellos en los cortes y en los golpes fuertes, el cartel de jefe de cada
gigante (nombre, apodo y una barra que se llena) y el título. Todo sale de intro_planos.py.
En el juego: ColorCorrection + Bloom + la interfaz del cartel con TweenService.

Uso (desde la raíz del repo):
  python tools/blender/intro_video.py <carpeta_cuadros> <salida.mp4>
  python tools/blender/intro_video.py --foto <entrada.png> <salida.png>  (solo el acabado)"""
import os
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import intro_planos as IP  # noqa: E402

FPS = IP.MUESTRAS_POR_SEGUNDO
BARRA = 68  # alto de cada barra de cine a 540 de alto (2.39:1)
FUENTE = "C\\:/Windows/Fonts/georgiab.ttf"
ORO, CREMA, ROJO = "0xF4C76A", "0xE8D9B0", "0xC42A10"
TITULO = "ALIMENTA A LOS GIGANTES"


def separar(texto):
    """Letras separadas, como los carteles de jefe ("O R C A")."""
    return "  ".join(" ".join(palabra) for palabra in texto.split())


def acabado():
    return (
        "eq=contrast=1.25:saturation=1.3:gamma=0.85,format=gbrp,split[base][luz];"  # eq solo en YUV; la mezcla, en RGB
        "[luz]lutrgb=r='if(gt(val,150),val,0)':g='if(gt(val,150),val,0)':b='if(gt(val,150),val,0)',"
        "gblur=sigma=16[brillo];"
        "[base][brillo]blend=all_mode=screen:all_opacity=0.85,"
        "rgbashift=rh=-2:bh=2,vignette=angle=0.62,noise=alls=7:allf=t+u"
    )


def texto(t, tam, color, y, desde, hasta, borde=2):
    alfa = f"min(1\\,(t-{desde})/0.25)"
    return (f",drawtext=fontfile='{FUENTE}':text='{t}':fontsize={tam}:fontcolor={color}:"
            f"borderw={borde}:bordercolor=0x2A0E00:shadowx=0:shadowy=3:shadowcolor=black@0.7:"
            f"x=(w-text_w)/2:y={y}:alpha='{alfa}':enable='between(t\\,{desde}\\,{hasta})'")


def caja(x, y, w, h, color, desde, hasta, relleno=True):
    return (f",drawbox=x={x}:y={y}:w={w}:h={h}:color={color}:t={'fill' if relleno else 1}:"
            f"enable='between(t\\,{desde}\\,{hasta})'")


def adornos():
    f = f",drawbox=x=0:y=0:w=iw:h={BARRA}:color=black:t=fill,drawbox=x=0:y=ih-{BARRA}:w=iw:h={BARRA}:color=black:t=fill"
    t0 = 0.0
    for i, p in enumerate(IP.PLANOS):
        if i > 0:  # destello en el corte
            f += caja(0, 0, "iw", "ih", "white@0.6", t0, t0 + 0.07)
        for t, fuerza in p.get("golpes", []):
            if fuerza >= 1:
                f += caja(0, 0, "iw", "ih", "white@0.35", t0 + t, t0 + t + 0.05)
        if "cartel" in p:
            nombre, apodo, a, b = p["cartel"]
            a, b = t0 + a, t0 + b
            f += texto(separar(nombre), 44, ORO, BARRA + 18, a, b)
            f += texto(f"—  {separar(apodo)}  —", 14, CREMA, BARRA + 72, a + 0.1, b, 1)
            llena = f"300*min(1\\,(t-{a + 0.15})/0.6)"
            f += (f",drawbox=x=(iw-300)/2:y={BARRA + 96}:w='{llena}':h=7:color={ROJO}:t=fill:"
                  f"enable='between(t\\,{a + 0.15}\\,{b})'")
            f += caja("(iw-304)/2", BARRA + 94, 304, 11, ORO, a + 0.15, b, relleno=False)
        if "titulo" in p:
            a, b = t0 + p["titulo"][0], t0 + p["titulo"][1]
            f += texto(separar(TITULO), 36, ORO, "(h-text_h)/2-40", a, b, 3)
        t0 += p["segundos"]
    return f


def correr(args, filtro):
    with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False, encoding="utf-8") as g:
        g.write(filtro)
    try:
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", *args[0], "-/filter_complex", g.name,
                        *args[1]], check=True)
    finally:
        os.remove(g.name)


def main():
    if sys.argv[1] == "--foto":
        correr((["-i", sys.argv[2]], ["-frames:v", "1", sys.argv[3]]), "[0:v]" + acabado())
        return
    entrada, salida = sys.argv[1], sys.argv[2]
    correr((["-framerate", str(FPS), "-i", os.path.join(entrada, "%04d.png")],
            ["-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "17", salida]),
           "[0:v]" + acabado() + adornos())


if __name__ == "__main__":
    main()
