# Pipeline de Blender a Roblox

> **Este pipeline NO se usa hasta que la fase 1 esté terminada.** Durante la fase 1
> todo se construye con partes primitivas. Ver `CLAUDE.md`, sección "Visuales y fases".

## Reglas de exportación

- **Máximo 10,000 triángulos por MeshPart.**
- **Aplicar transformaciones antes de exportar** (`Ctrl+A` → All Transforms).
- **Origen en el punto de anclaje lógico** del objeto (la base de un árbol, la bisagra
  de una puerta), no en el centro geométrico por defecto.
- **UVs desplegados** y sin solapamientos en la textura principal.
- **Texturas de 1024x1024** con albedo plano: sin sombras ni iluminación horneada.
  La iluminación la pone el motor.
- **Escala en metros** en la configuración de la escena.
- **Formato `.fbx` o `.glb`**, exportado a `assets/blender/`.
- **Texturas embebidas en el FBX**: Path Mode en **Copy**, **Embed Textures** activado y
  Apply Scalings en **FBX Unit Scale**. Si la textura solo se referencia por ruta, Studio
  importa el modelo sin color.
- **PNG finales de textura en `assets/textures/`** (`Nombre_color.png`, `_normal`,
  `_roughness`). Los archivos de origen pesados (exportaciones de Meshy) no van al repo.
- **Nombres en PascalCase que coincidan con el MeshPart en código.**
  Si el código busca `CoinGenerator`, el archivo es `CoinGenerator.fbx`.

## Texturas: ForgeGUI o Blender

Las texturas **tileables** (piso, pasto, ladrillo) pueden venir de ForgeGUI.
Las texturas de **objeto específico** se pintan en Blender sobre los UVs reales, porque
un generador de imágenes no conoce el unwrap del modelo.

## Checklist previa a cada exportación

- [ ] Conteo de triángulos ≤ 10,000 (Overlay → Statistics).
- [ ] Transformaciones aplicadas (rotación 0, escala 1).
- [ ] Origen en el punto de anclaje lógico.
- [ ] UVs desplegados y revisados.
- [ ] Textura 1024x1024, albedo plano, sin luz horneada.
- [ ] Escala de escena en metros.
- [ ] Nombre del objeto y del archivo en PascalCase, igual al MeshPart en código.
- [ ] Exportado a `assets/blender/` como `.fbx` o `.glb`, con texturas embebidas.
- [ ] Al subirlo, ID registrado en `src/shared/Assets.luau` y reemplazo anotado en
      `docs/devlog.md`.

## Monstruos por código (`tools/blender/`)

Los monstruos se modelan con scripts de Python que corren en Blender 5.2 (por el MCP o
pegándolos en la consola de Python de Blender):

| Archivo | Qué hace |
|---|---|
| `criaturas.py` | Bloques comunes: cadenas de piel (Skin), masas, fusionar (remesh por vóxeles + suavizado), pintar colores por vértice, materiales de pelaje/escamas/cuerno, estudio y render. |
| `minotauro.py`, `dragon.py`, `zorro.py` | Un monstruo en 4 etapas: `construir_<monstruo>(etapa, voxel)` devuelve sus objetos. |
| `vista_etapas.py` | `vista_etapas(construir, alto, ruta, voxel, angulo=8)`: las 4 etapas lado a lado (cámara ortográfica que encuadra todo) para revisar el diseño. Renders en `assets/blender/render/`. |
| `exportar.py` | `exportar_monstruo(nombre, objetos, proyecto)`: una malla ≤ 9,800 triángulos, UVs automáticas, color + brillo + normales horneados a 1024 y FBX con texturas embebidas. |
| `exportar_todos.py` | `exportar_cola([("Minotauro", 2), ...])`: exporta varios en cola, cada uno en su temporizador (Blender no se congela) y deja `log_<Nombre>.json` y `cola.json`. Cada uno tarda ~5 min. |

Los llamados largos por el MCP se cortan a los 60 s aunque Blender siga trabajando: para
renders y exportaciones se usa `bpy.app.timers.register` y se espera el archivo.

En el juego, cada etapa es un Model `<modelBase>E<n>` en ServerStorage (ver
`GiantTemplates`); su tamaño real no importa: `GiantBody` lo escala a 3, 8, 15 y 30
veces el alto de un jugador.

**Orientación:** el modelo tiene que llegar a Studio parado (Y hacia arriba). Desde
Blender, exportar con `bake_space_transform=True` (ya está en `exportar.py`). Con Meshy,
confirmar en la vista previa de "Importar 3D" que esté parado y mirando al frente.
