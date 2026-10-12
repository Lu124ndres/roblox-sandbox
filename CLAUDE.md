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
| `src/shared/` | `ReplicatedStorage.Shared` | Módulos que usan ambos lados: `Config`, `Assets`, `UIConfig`, tipos, utilidades puras. |
| `assets/blender/` | — | Archivos `.blend` y exportaciones `.fbx`/`.glb` (fase 2). |
| `assets/textures/` | — | PNG fuente de texturas y UI antes de subirlos a Roblox. |
| `docs/` | — | Documentación del proyecto (ver abajo). |
| `docs/capturas/` | — | Capturas para el README y el devlog. |

Documentos en `docs/`:

- `setup.md`: herramientas instaladas y pasos manuales pendientes.
- `decisiones.md`: registro de decisiones técnicas no obvias.
- `devlog.md`: bitácora por sesión.
- `ideas.md`: ideas fuera de alcance. No se implementan.
- `ui-assets.md`: seguimiento de assets visuales de ForgeGUI.
- `blender-pipeline.md`: reglas de exportación (fase 2).
- `backlog.md`: lista de tareas. Se crea cuando se defina el juego.

## Reglas no negociables

1. **El cliente nunca decide estado autoritativo** (dinero, progresión, inventario). Solo pide.
2. **Todo RemoteEvent valida en el servidor**: tipo de cada argumento, rango de valores y
   derecho del jugador a ejecutar esa acción. Se asume que todo argumento puede ser malicioso.
3. **Nada de `while true do` sin espera.** Usar eventos de `RunService` o `task.wait`.
4. **Nunca editar en Studio lo que existe en `src/`.** Studio es para construir el nivel,
   no para escribir código. Rojo sobrescribe cualquier cambio hecho ahí.
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
