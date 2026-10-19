# CLAUDE.md

Instrucciones de trabajo para este repositorio. Aplican a cualquier sesión,
humana o asistida, que escriba código o documentación aquí.

## Estilo de respuesta

- Sin saludos, confirmaciones ni resúmenes finales. Ve directo a la solución.
- Explicaciones breves, pero completas cuando se trate de bugs, red o tipos.
- Edita los archivos directamente; no pegues scripts completos en el chat.
- Si algo es ambiguo y cambia el diseño, pregunta antes de implementar.

## Stack

- **Luau puro** con `--!strict`. Sin roblox-ts ni transpiladores.
- **Rojo 7.7.1** sincroniza `src/` con Studio. El código vive en el sistema de archivos.
- **MCP de Studio** para inspeccionar y probar el juego en Studio desde el asistente.
- **Blender**: instalado, sin usar todavía. Entra en la fase 2.
- Herramientas gestionadas con **Rokit** (`rokit.toml`): rojo, selene, stylua, wally.

## Mapa de carpetas

| Ruta | Destino en Studio | Qué va aquí |
|---|---|---|
| `src/server/` | `ServerScriptService.Server` | Lógica autoritativa: estado de jugadores, economía, validación de remotes, guardado. |
| `src/client/` | `StarterPlayer.StarterPlayerScripts.Client` | Input, UI, efectos visuales locales. Solo presenta y pide. |
| `src/shared/` | `ReplicatedStorage.Shared` | Módulos que usan ambos lados: `Config/`, `Assets`, `UIConfig/`, `WorldLayout`, tipos, utilidades puras. `Config` y `UIConfig` son carpetas con `init.luau` y secciones. |
| `assets/blender/` | — | Archivos `.blend` y exportaciones `.fbx`/`.glb` (fase 2). |
| `assets/textures/` | — | PNG fuente de texturas y UI antes de subirlos a Roblox. |
| `world/` | `Workspace` | Piezas de la isla (`Isla.model.json`). Generado, no se edita a mano. |
| `tools/` | — | Scripts de desarrollo (`generar_isla.py`). No corren en el juego. |
| `docs/` | — | Documentación del proyecto (ver abajo). |
| `docs/capturas/` | — | Capturas para el README y el devlog. |

Documentos en `docs/`:

- `setup.md`: herramientas instaladas y pasos manuales pendientes.
- `decisiones.md`: registro de decisiones técnicas no obvias.
- `devlog.md`: bitácora por sesión.
- `ideas.md`: ideas fuera de alcance. No se implementan.
- `ui-assets.md`: seguimiento de assets visuales de ForgeGUI.
- `blender-pipeline.md`: reglas de exportación (fase 2).
- `guia_crear_monstruo.md`: cómo se hace un gigante completo (modelo, rig, animación, hábitat,
  sonidos, VFX). La sigue la skill local `/crear-monstruo`.
- `alcance.md`: qué es el juego, qué entra en la v1 y con qué números (calibración).
- `roadmap.md`: versiones públicas (v1 y eventos).
- `backlog.md`: lista de tareas por hito.

## Reglas no negociables

1. **El cliente nunca decide estado autoritativo** (dinero, progresión, inventario). Solo pide.
2. **Todo RemoteEvent valida en el servidor**: tipo de cada argumento, rango de valores y
   derecho del jugador a ejecutar esa acción. Se asume que todo argumento puede ser malicioso.
3. **Nada de `while true do` sin espera.** Usar eventos de `RunService` o `task.wait`.
4. **Nunca editar en Studio lo que existe en `src/` o `world/`.** Rojo sobrescribe
   cualquier cambio hecho ahí. Las piezas se cambian en `tools/generar_isla.py`, el
   terreno en `src/server/World/` y las medidas de ambos en `WorldLayoutData.json`.
5. **Un módulo, una responsabilidad.** Si un archivo pasa de 200 líneas, se divide.
6. **Todo `rbxassetid` vive en `src/shared/Assets.luau`**, nunca inline.
7. **Todos los números de balance viven en `src/shared/Config.luau`**, nunca mágicos.
8. **`--!strict` en todos los archivos Luau.**

## Rojo: fuente de verdad

- Todo el código Luau vive en disco y se sincroniza con Rojo (rutas en el mapa de carpetas).
- NUNCA escribas ni sobreescribas scripts desde el MCP de Roblox Studio.
- Para crear servicios, carpetas o instancias, edita `default.project.json` o crea archivos
  `.model.json` / `.meta.json`.
- Propiedades de servicios (Lighting, SoundService, etc.) también se definen en
  `default.project.json` cuando sea posible.

## MCP de Roblox Studio: solo lectura

- Úsalo para inspeccionar propiedades en tiempo de ejecución (posiciones, escalas, UI) y leer
  el Output para depurar.
- Puede modificar únicamente contenido de runtime que Rojo no gestiona (ej. objetos temporales
  en Workspace).
- Permitido en runtime: Play/Stop, simular input y disparar AdminCommand para pruebas.
  Prohibido editar cualquier instancia gestionada por Rojo.
- La prohibición aplica a cambios persistentes en modo Edit sobre instancias de Rojo. En Play
  todo está permitido porque se descarta al parar. En Edit se permite clonar módulos para
  pruebas solo dentro de una carpeta temporal fuera de Rojo, destruyendo el clon al terminar y
  verificando que no quedó.

## Estándares Luau

- `--!strict` al inicio de todo archivo nuevo o modificado de forma importante.
- Tipa funciones, parámetros, retornos y tablas. Los tipos compartidos van en
  `src/shared/Config/Types.luau` (o junto a su sección, como `Config/GiantTypes.luau`).
- Solo `task.wait`, `task.spawn`, `task.defer`, `task.delay`. Prohibido `wait()`, `spawn()`,
  `delay()`.
- Obtén servicios con `game:GetService()`.
- Desconecta conexiones y limpia instancias cuando un objeto o jugador se va (evita fugas de
  memoria).
- Prefiere ModuleScripts para la lógica; los Scripts/LocalScripts solo inicializan.

## Seguridad de red

- El servidor nunca confía en el cliente.
- En cada RemoteEvent/RemoteFunction del servidor, valida:
  - tipo de cada argumento (`typeof`), rangos y longitudes,
  - que el jugador tenga permiso o posesión sobre lo que pide,
  - distancias o cooldowns cuando aplique (anti-spam / anti-exploit).
- El servidor calcula los resultados importantes (daño, monedas, inventario); el cliente solo
  los solicita.
- En el cliente, maneja `Players.LocalPlayer` y `Character` de forma defensiva (pueden no
  existir aún o reaparecer).

## Blender (MCP)

- No generes mallas ni vértices complejos con Python.
- Uso permitido: armatures, restricciones de huesos, pivotes y transformaciones compatibles con
  Roblox, y automatizar exportación `.fbx`/`.gltf` (escala correcta, transformaciones
  aplicadas, UVs dentro de 0–1).
- Antes de exportar, confirma conmigo la escala objetivo si no está definida.

## Diseño

- Las decisiones de diseño (UI, mapas, estética, mecánicas, modelos) son mías. Propón opciones,
  no impongas.

## Verificación

- Tras cambios de código, delega en el subagente `infra`: `rojo build`, `selene src` y
  `stylua --check src`.
- No des una tarea por terminada si el build falla.

## Delegación

- Tareas rutinarias (build, búsquedas, lectura de archivos, lint) → subagente `infra`.
- Revisión de seguridad de remotes antes de cerrar un sistema de red → subagente
  `remote-auditor`.
- Arquitectura, sistemas de juego y Blender → agente principal.
- Nunca delegues diseño, escritura de código ni diagnóstico de bugs complejos a `infra`.

## Convenciones

- **PascalCase** para módulos y archivos (`InventoryService.luau`).
- **camelCase** para variables y funciones (`local playerData`, `function addCoins()`).
- Scripts: `Nombre.server.luau` y `Nombre.client.luau`. Módulos: `Nombre.luau`.

## Visuales y fases

- **FASE 1**: todo con partes primitivas y colores planos. Cubos y cilindros. Nada de
  Blender, nada de assets. El objetivo es un juego completo y feo.
- **FASE 2** (solo cuando la fase 1 esté terminada): reemplazar primitivas por modelos
  de Blender, de una en una. Seguir `docs/blender-pipeline.md`.
- **Animación**: solo TweenService y CFrame por código (girar, flotar, deslizar paneles).
  Nada de rigs ni keyframes en este proyecto.
- Si aparece la tentación de mejorar lo visual antes de terminar la fase 1, la idea va a
  `docs/ideas.md` y **no se implementa**.
- **Excepción: los gigantes.** Usan su modelo final en cuanto existe (hoy, `OrcaE1`), con
  un marcador de primitivas si falta. Ver `docs/decisiones.md`.
- **Ambiente y efectos (decidido el 2026-10-12):** el terreno de Roblox, las partículas y
  los sonidos ya entran en el vertical slice. Las piezas siguen siendo primitivas
  generadas por script; los modelos de Blender siguen siendo fase 2.

## Assets

- Todo `rbxassetid` vive en `src/shared/Assets.luau`. Si falta uno, se deja como
  `"rbxassetid://0"` (`Assets.MISSING`) y se anota en `docs/ui-assets.md`.
- UI 2D y texturas tileables: **ForgeGUI**. Texturas de mesh y modelos: **Blender**.
- ForgeGUI no genera animaciones. Es solo imagen estática.

## Documentación y commits

- Repositorio público y portafolio. El código se escribe para ser leído.
- Commits en español, imperativos y descriptivos: `agrega sistema de producción pasiva`,
  no `cambios` ni `fix`.
- Un commit por tarea, no uno gigante al final.
- Al terminar una tarea: marcarla en el backlog y agregar entrada en `docs/devlog.md`.
- Decisiones técnicas no obvias van a `docs/decisiones.md`.
- Si el README deja de describir el estado real, se actualiza.

## Checklist antes de dar una tarea por terminada

1. `rojo build --output build/test.rbxl` compila.
2. `selene src` sin warnings.
3. `stylua src` aplicado.
4. Probado en Studio vía MCP, no solo "debería funcionar".
