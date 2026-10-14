# CLAUDE.md

Instrucciones de trabajo para este repositorio. Aplican a cualquier sesión,
humana o asistida, que escriba código o documentación aquí.

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
