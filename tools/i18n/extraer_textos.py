"""Junta los textos en español que puede ver el jugador para traducirlos al inglés.

Recorre src/ buscando literales de Luau ("...", '...' y `...` con {expresiones}) que parezcan
texto de interfaz: llevan espacios, tildes, ¡/¿ o son una palabra en MAYÚSCULAS. Descarta
nombres de instancias (CamelCase sin espacios), rutas y rbxassetid. Las {expresiones} de los
backticks quedan como {} para que cuenten como plantilla.

Uso (desde la raíz del repo):
    python tools/i18n/extraer_textos.py            # lista los textos que faltan en el diccionario
    python tools/i18n/extraer_textos.py --todos    # lista todos, con archivo y línea
"""
import json, os, re, sys

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(RAIZ, "src")
DICC = os.path.join(RAIZ, "src", "shared", "Lang")

LITERAL = re.compile(r'"((?:[^"\\\n]|\\.)*)"|\'((?:[^\'\\\n]|\\.)*)\'|`((?:[^`\\]|\\.)*)`')
IDENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_.]*$")
MAYUS = re.compile(r"^[A-ZÁÉÍÓÚÑÜ¡!¿?]{3,}[!?]?$")
LETRAS = re.compile(r"[A-Za-zÁÉÍÓÚÑÜáéíóúñü]")
NO = ("rbxassetid", "rbxasset", "http", "Enum.", "%s:%s", "ReplicatedStorage", "Workspace")
# Carpetas sin texto para el jugador: rigs, animación, geometría y herramientas de admin
SALTAR = ("Orca/OrcaMotion", "Zorro/", "Rig", "Admin", "Analytics", "World/", "Bones")


def es_texto(s):
    if not LETRAS.search(s) or any(n in s for n in NO):
        return False
    if s.startswith("--") or s.startswith("%") and " " not in s:
        return False
    if IDENT.match(s):
        return bool(MAYUS.match(s)) and s.upper() == s
    return " " in s.strip() or bool(re.search(r"[áéíóúñÁÉÍÓÚÑ¡¿]", s))


def plantilla(s):
    return re.sub(r"\{[^{}]*\}", "{}", s)


def literales(ruta):
    rel = os.path.relpath(ruta, RAIZ).replace("\\", "/")
    with open(ruta, encoding="utf-8") as f:
        texto = f.read()
    sin_comentarios = re.sub(r"--\[(=*)\[.*?\]\1\]", lambda m: "\n" * m.group(0).count("\n"), texto, flags=re.S)
    for n, linea in enumerate(sin_comentarios.split("\n"), 1):
        codigo = re.sub(r"--(?!\[).*$", "", linea) if '"' not in linea.split("--")[0][-1:] else linea
        for m in LITERAL.finditer(codigo):
            s = m.group(1) or m.group(2) or (plantilla(m.group(3)) if m.group(3) is not None else None)
            if s and es_texto(s):
                yield s, f"{rel}:{n}"


def ya_traducidos():
    hechos = set()
    if os.path.isdir(DICC):
        for raiz, _, archivos in os.walk(DICC):
            for a in archivos:
                if a.endswith(".luau"):
                    with open(os.path.join(raiz, a), encoding="utf-8") as f:
                        for m in re.finditer(r'^\s*\["((?:[^"\\]|\\.)*)"\]\s*=', f.read(), re.M):
                            hechos.add(m.group(1))
    return hechos


def main():
    todos = {}
    for raiz, _, archivos in os.walk(SRC):
        rel = os.path.relpath(raiz, SRC).replace("\\", "/")
        if any(s in rel + "/" for s in SALTAR) or rel.startswith("shared/Lang"):
            continue
        for a in archivos:
            if a.endswith(".luau"):
                for s, donde in literales(os.path.join(raiz, a)):
                    todos.setdefault(s, []).append(donde)
    hechos = set() if "--todos" in sys.argv else ya_traducidos()
    faltan = {s: d for s, d in sorted(todos.items()) if s not in hechos}
    json.dump(faltan, sys.stdout, ensure_ascii=False, indent=1)
    print(f"\n{len(faltan)} de {len(todos)} textos", file=sys.stderr)


if __name__ == "__main__":
    main()
