"""Agrega a default.project.json (ServerStorage) cada assets/modelos/*.rbxm.
Los modelos de los monstruos se importan en Studio (Importar 3D), se guardan
con "Guardar en un archivo" en assets/modelos/ y Rojo los pone en ServerStorage."""
import json
import os

raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ruta = os.path.join(raiz, "default.project.json")
with open(ruta, encoding="utf-8") as f:
    proyecto = json.load(f)
storage = proyecto["tree"].setdefault("ServerStorage", {"$className": "ServerStorage"})
carpeta = os.path.join(raiz, "assets", "modelos")
for archivo in sorted(os.listdir(carpeta)):
    if archivo.endswith(".rbxm"):
        storage[archivo[:-5]] = {"$path": f"assets/modelos/{archivo}"}
with open(ruta, "w", encoding="utf-8") as f:
    json.dump(proyecto, f, indent="\t", ensure_ascii=False)
    f.write("\n")
print(sorted(k for k in storage if not k.startswith("$")))
