# Rendimiento en móvil: medición (2026-10-19)

Medido en Studio con el emulador de dispositivo **Samsung Galaxy A06** (gama baja; pantalla
705 × 338, táctil) en Play, con el modo rápido apagado (`lowFx = false`), el monstruo en el
cráter y la cámara en la puerta. **Todavía no se optimizó nada:** las mejoras de abajo son
propuestas para elegir.

## Qué mide bien Studio y qué no

- **El emulador no emula el procesador ni la GPU del teléfono:** cambia la resolución, el
  táctil y la interfaz. Los tiempos son los de la PC.
- **El tiempo por cuadro de Studio no sirve:** con la ventana de Studio sin foco (el MCP manda
  las órdenes), Roblox limita a 15 fps; el cuadro dio 66.7 ms clavados con cualquier monstruo.
- **La memoria total (4,236 MB) es de todo Studio** (en Play corren cliente y servidor en el
  mismo proceso, más los plugins). Sirven las categorías propias del juego, no el total.
- Sí sirven: cuántas piezas, vóxeles, efectos y elementos de interfaz hay, la memoria por
  categoría gráfica y lo que tarda cada animador medido aparte (cronometrado en el cliente).
- **Hace falta la prueba en un teléfono real de gama baja** (agregada a `docs/lanzamiento.md`).

## Números

| Qué | Medido |
|---|---|
| Piezas (`BasePart`) en Workspace | **4,748**: 4,468 `Part`, 279 `MeshPart` |
| Por carpeta | `Isla` 3,570 · `GuaridaDescanso` 905 · `FlechasGuia` 64 · `AguaDelCrater` 38 · `Murcielagos` 36 · personaje 35 · `Vitrinas` 31 · hábitat 21 · gaviotas 16 |
| Terreno | **2,325,676 celdas** de vóxeles |
| Memoria gráfica del juego | terreno 77 MB + vóxeles 17 MB · texturas 72 MB · piezas 53 MB · interfaz 44 MB · partículas 16 MB · sonidos 8 MB |
| Luces (`Light`) | **83** |
| Emisores de partículas | 103 (1 activo en ese momento: la mayoría se encienden por evento o por cercanía) |
| Beams / Trails / Highlights | 2 / 2 / 4 (uno es el contorno del monstruo, siempre encendido) |
| Interfaz | 5 `ScreenGui`, **1,606** `GuiObject`, 584 imágenes |
| Sonidos | 16 (7 sonando) |
| Módulos en el cliente | 263 |
| Streaming | `StreamingEnabled = true` |
| Animador del Zorro E4 (76 huesos) | **0.30 ms/cuadro** con detalle de cara, 0.27 ms sin detalle |
| Animador del Dragón E4 (42 huesos) | **0.12 ms/cuadro** |

Los animadores de los gigantes son baratos: aun en un teléfono 5–10 veces más lento que la PC
quedan en 1.5–3 ms de un cuadro de 33 ms (30 fps).

## Los 5 mayores costos (estimados)

1. **Terreno: 2.3 M de celdas** (~94 MB entre gráficos y vóxeles). El mar se extiende hasta
   ±1536 studs con agua de terreno, y el agua de terreno es de lo más caro de dibujar en
   móvil (reflejos y olas).
2. **Piezas sueltas: 4,748**, sobre todo la isla (3,570 `Part` generadas por
   `tools/generar_isla.py`). Cada pieza es una llamada de dibujo y memoria de física.
3. **La guarida del descanso siempre en Workspace: 905 piezas** enterradas bajo el lago
   (`server/RestArena`), aunque solo se ve unos 60–120 s por ciclo.
4. **83 luces dinámicas.** En teléfonos de gama baja cada `PointLight`/`SpotLight` visible
   suma costo de sombreado; con `GlobalShadows = true` más todavía.
5. **Interfaz: 1,606 objetos y 584 imágenes** (44 MB de interfaz + parte de los 72 MB de
   texturas): las ventanas se construyen al empezar y quedan en memoria aunque estén cerradas.

## Propuestas ordenadas por impacto / esfuerzo

| # | Propuesta | Impacto | Esfuerzo |
|---|---|---|---|
| 1 | Sacar `GuaridaDescanso` de Workspace fuera del descanso (`Parent = nil` o `ServerStorage`, y ponerla un poco antes de que suba). | Medio (−905 piezas casi siempre) | Bajo |
| 2 | Luces por calidad: en modo rápido (y por defecto en táctil) apagar las luces decorativas lejanas y el contorno `Highlight` del monstruo; dejar solo las que cuentan algo (ojos, lava cercana). | Medio | Bajo |
| 3 | Ajustar el streaming: `StreamingTargetRadius` más chico y `ModelStreamingMode = Atomic` en los grupos de decoración de la isla, para que el teléfono no tenga toda la isla cargada a la vez. | Alto | Bajo–medio |
| 4 | Ventanas perezosas: construir cada ventana la primera vez que se abre y destruir las pesadas (tienda de Robux, colección) al cerrarlas. | Medio | Medio |
| 5 | Mar lejano sin terreno: agua de terreno solo cerca de la isla y el cráter; el resto, un plano o una malla de agua con textura. | Alto | Medio |
| 6 | Fusionar las piezas estáticas de la isla en mallas (fase 2, Blender): rocas, muelles, cabaña, decoración. | Alto | Alto |
| 7 | Bajar la resolución del terreno donde no se pisa (fondo del mar, lejos de la playa). | Medio | Medio |

## Cómo repetir la medición

En Studio, en Edit: `StudioDeviceSimulatorService:SetDeviceAsync("samsung_galaxy_a06")`,
entrar en Play y, en el cliente, contar con `workspace:GetDescendants()` (en tandas, con
`task.wait()` cada 5,000), `workspace.Terrain:CountCells()` y
`Stats:GetMemoryUsageMbForTag(...)`. El costo de un animador se mide creando su módulo
(`require(Shared.Zorro).new(centro)`) y cronometrando 300 llamadas a `step(1/60, info)` sobre
el modelo del cráter. Al terminar: `StopSimulationAsync()`.
