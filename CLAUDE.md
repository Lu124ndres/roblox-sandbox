# CLAUDE.md

Instrucciones de trabajo para este repositorio. Aplican a cualquier sesión,
humana o asistida, que escriba código o documentación aquí.

## Estilo de respuesta

- Sin saludos, confirmaciones ni resúmenes finales. Ve directo a la solución.
- Explicaciones breves, pero completas cuando se trate de bugs, red o tipos.
- Edita los archivos directamente; no pegues scripts completos en el chat.

## Stack

- **Luau puro**. Sin roblox-ts ni transpiladores.
- **Rojo 7.7.1** sincroniza `src/` con Studio. El código vive en el sistema de archivos.
- **MCP de Studio** para inspeccionar y probar el juego en Studio desde el asistente.
- **Blender 5.2**: se usa a diario por scripts en `tools/blender/` (monstruos, trajes, props, rigs y FBX).
- Herramientas gestionadas con **Rokit** (`rokit.toml`): rojo, selene, stylua, wally.

## Mapa de carpetas

| Ruta | Destino en Studio | Qué va aquí |
|---|---|---|
| `src/server/` | `ServerScriptService.Server` | Lógica autoritativa: estado de jugadores, economía, validación de remotes, guardado. |
| `src/client/` | `StarterPlayer.StarterPlayerScripts.Client` | Input, UI, efectos visuales locales. Solo presenta y pide. |
| `src/first/` | `ReplicatedFirst` | Lo que corre antes de que cargue el juego: la pantalla de carga (`LoadingScreen/`). Solo puede pedir módulos de `Shared` sin require (ver `docs/decisiones.md`). |
| `src/shared/` | `ReplicatedStorage.Shared` | Módulos que usan ambos lados: `Config/`, `Assets`, `UIConfig/`, `WorldLayout`, tipos, utilidades puras. `Config` y `UIConfig` son carpetas con `init.luau` y secciones. |
| `assets/blender/` | — | Archivos `.blend` y exportaciones `.fbx`/`.glb`. |
| `assets/textures/` | — | PNG fuente de texturas y UI antes de subirlos a Roblox. |
| `world/` | `Workspace` | Piezas de la isla (`Isla.model.json`). Generado, no se edita a mano. |
| `tools/` | — | Scripts de desarrollo (`generar_isla.py`, `tools/blender/`). No corren en el juego. |
| `docs/` | — | Documentación del proyecto (ver abajo). |
| `docs/capturas/` | — | Capturas para el README y el devlog. |

Documentos en `docs/`:

- `setup.md`: herramientas instaladas y pasos manuales pendientes.
- `decisiones.md`: registro de decisiones técnicas no obvias.
- `devlog.md`: bitácora por sesión.
- `ideas.md`: ideas fuera de alcance. No se implementan.
- `ui-assets.md`: seguimiento de los assets visuales de la interfaz.
- `blender-pipeline.md`: reglas de exportación.
- `guia_crear_monstruo.md`: cómo se hace un gigante completo (modelo, rig, animación, hábitat,
  sonidos, VFX). La sigue la skill local `/crear-monstruo`.
- `alcance.md`: qué es el juego, qué entra en la v1 y con qué números (calibración).
- `roadmap.md`: versiones públicas (v1 y eventos).
- `backlog.md`: lista de tareas por hito.

## Reglas no negociables

1. **El cliente nunca decide estado autoritativo** (dinero, progresión, inventario, daño).
   Solo pide; el servidor calcula el resultado.
2. **Todo RemoteEvent/RemoteFunction valida en el servidor**: tipo (`typeof`) de cada
   argumento, rangos y longitudes, derecho o posesión del jugador sobre lo que pide, y
   distancias o cooldowns cuando aplique. Se asume que todo argumento puede ser malicioso.
3. **Nada de `while true do` sin espera.** Usar eventos de `RunService` o `task.wait`.
4. **Nunca editar en Studio lo que existe en `src/` o `world/`.** Rojo sobrescribe
   cualquier cambio hecho ahí. Las piezas se cambian en `tools/generar_isla.py`, el
   terreno en `src/server/World/` y las medidas de ambos en `WorldLayoutData.json`.
5. **Un módulo, una responsabilidad.** Si un archivo pasa de 200 líneas, se divide.
6. **Todo `rbxassetid` vive en `src/shared/Assets/`** (`init.luau`, `Textures.luau`, `Products.luau`,
   `Sounds.luau`, `Loading.luau`), nunca inline.
7. **Todos los números de balance viven en `src/shared/Config/`**, nunca mágicos.
8. **`--!strict` en todos los archivos Luau.**

## Rojo: fuente de verdad

- Para crear servicios, carpetas o instancias, edita `default.project.json` o crea archivos
  `.model.json` / `.meta.json`.
- Propiedades de servicios (Lighting, SoundService, etc.) también se definen en
  `default.project.json` cuando sea posible.

## MCP de Roblox Studio

- Úsalo para inspeccionar propiedades en tiempo de ejecución (posiciones, escalas, UI) y leer
  el Output para depurar.
- **Edit:** prohibido cualquier cambio persistente sobre instancias gestionadas por Rojo,
  scripts incluidos. Solo se puede tocar contenido que Rojo no gestiona (ej. objetos
  temporales en Workspace). Se permite clonar módulos para pruebas solo dentro de una carpeta
  temporal fuera de Rojo, destruyendo el clon al terminar y verificando que no quedó.
  También se permite revisar los modelos que el usuario importa (huesos, tamaño, orientación) y
  moverlos a `ServerStorage` dentro de `ChangeHistoryService` (`TryBeginRecording` /
  `FinishRecording`), para que se pueda deshacer.
- **Play:** todo está permitido porque se descarta al parar (Play/Stop, simular input,
  disparar AdminCommand para pruebas).

## Estándares Luau

- Tipa funciones, parámetros, retornos y tablas. Los tipos compartidos van en
  `src/shared/Config/Types.luau` (o junto a su sección, como `Config/GiantTypes.luau`).
- Solo `task.wait`, `task.spawn`, `task.defer`, `task.delay`. Prohibido `wait()`, `spawn()`,
  `delay()`.
- Obtén servicios con `game:GetService()`.
- Desconecta conexiones y limpia instancias cuando un objeto o jugador se va (evita fugas de
  memoria).
- Prefiere ModuleScripts para la lógica; los Scripts/LocalScripts solo inicializan.
- En el cliente, maneja `Players.LocalPlayer` y `Character` de forma defensiva (pueden no
  existir aún o reaparecer).

## Blender

- Los monstruos se modelan por código con el método de bloques de `docs/guia_crear_monstruo.md`
  (skill `/crear-monstruo`). Prohibido modelar formas orgánicas libres vértice por vértice
  fuera de ese método.
- Uso permitido además: armatures, restricciones de huesos, pivotes y transformaciones
  compatibles con Roblox, y automatizar exportación `.fbx`/`.gltf` (escala correcta,
  transformaciones aplicadas, UVs dentro de 0–1).
- Antes de exportar, confirma conmigo la escala objetivo si no está definida.

## Diseño

- Las decisiones de diseño (UI, mapas, estética, mecánicas, modelos) son mías. Propón opciones,
  no impongas. Si algo es ambiguo y cambia el diseño, pregunta antes de implementar.

## Delegación

- `rojo build` y `stylua --check src` se corren directamente, sin subagente.
- Salidas largas (`selene` con muchos avisos, búsquedas grandes en `src/`) → subagente `infra`.
- Revisión de seguridad de remotes antes de cerrar un sistema de red → subagente
  `remote-auditor`.
- Una idea nueva (para este juego o un juego nuevo): skill `/nueva-idea`. Investigar, ver si es
  viable y proponer opciones → subagente `disenador` (no escribe código; decide el usuario).
- Probar en Studio lo que se construyó (Play, dispositivos, consola) → subagente `tester`.
- Lo visual (mapa, modelos, rig, animación, efectos, interfaz) lo producen `mapeador`,
  `modelador`, `rigger`, `animador`, `vfx` y `artista-ui`, y **todo cambio visual pasa por
  `director-arte` con capturas antes de cerrarse**. Para mejorar cómo se ve algo: `/pulido-visual`.
- Cambios al guardado o a las compras → `guardian-datos`. La experiencia de un jugador nuevo →
  `jugador`. Antes de publicar: `/revision-final`.
- Diseño, escritura de código, arquitectura, Blender y diagnóstico de bugs complejos los hace el
  agente principal o los agentes de una ola (`docs/guia_crear_monstruo.md`, sección 12), en su
  worktree y sin commit; nunca `infra`.

## Modelos y costo de los agentes

Cada agente tiene un modelo por defecto en su archivo (`.claude/agents/`): `haiku` para lo
mecánico (infra, sonidista), `sonnet` para casi todo y `opus` donde un error sale caro
(rigger, guardian-datos, director-arte). Al lanzar uno, el agente principal elige el modelo
para **esa** tarea con el parámetro `model` de `Agent`, sin preguntarle al usuario:

| Bajar a `haiku` | Dejar el de su archivo | Subir a `opus` |
|---|---|---|
| Buscar, leer, contar, listar, correr comandos, revisar un cambio de pocas líneas, textos cortos y repetidos | El trabajo típico del agente | Sistemas nuevos o grandes, criaturas y rigs nuevos, guardado y compras, seguridad de un sistema de red completo, veredicto de un juego nuevo, revisión visual antes de publicar |

- Si un agente responde «PEDIR MODELO MAYOR», o su resultado no convence en algo crítico, se
  relanza una vez con el siguiente modelo, con lo que ya encontró.
- Varios agentes en paralelo solo cuando el trabajo de verdad es independiente; un agente con
  un encargo claro y delimitado gasta mucho menos que uno con un encargo vago.
- Nunca se usa el modelo más caro "por si acaso": se sube cuando la tarea lo pide.

## Convenciones

- **PascalCase** para módulos y archivos (`InventoryService.luau`).
- **camelCase** para variables y funciones (`local playerData`, `function addCoins()`).
- Scripts: `Nombre.server.luau` y `Nombre.client.luau`. Módulos: `Nombre.luau`.

## Visuales y fases

- **FASE 1**: todo con partes primitivas y colores planos. Cubos y cilindros. Nada de
  Blender, nada de assets. El objetivo es un juego completo y feo.
- **FASE 2** (solo cuando la fase 1 esté terminada): reemplazar primitivas por modelos
  de Blender, de una en una. Seguir `docs/blender-pipeline.md`.
- **Animación**: todo por código, sin keyframes. TweenService y CFrame para la interfaz y los
  objetos (girar, flotar, deslizar paneles); los gigantes y los trajes usan rigs con huesos que
  se animan con `Bone.Transform` (ver `docs/guia_crear_monstruo.md`, sección 7).
- Si aparece la tentación de mejorar lo visual antes de terminar la fase 1, la idea va a
  `docs/ideas.md` y **no se implementa**.
- **Excepción: los gigantes, los trajes de los pases y piezas clave del mundo** (como el arco
  del volcán). Usan su modelo de Blender en cuanto existe (los gigantes, modelos v2 de
  bloques), con un marcador de primitivas si falta. Cada excepción nueva se anota en
  `docs/decisiones.md`; el resto del mundo sigue en primitivas.
- **Ambiente y efectos (decidido el 2026-10-12):** el terreno de Roblox, las partículas y
  los sonidos ya entran en el vertical slice. Las piezas siguen siendo primitivas
  generadas por script; los modelos de Blender siguen siendo fase 2, salvo las excepciones de
  arriba.

## Assets

- Si falta un `rbxassetid`, se deja como `"rbxassetid://0"` (`Assets.MISSING`) y se anota en
  `docs/ui-assets.md`.
- UI 2D e íconos: **Canva** (MCP de Canva), con la temática de piedra volcánica. Texturas de
  mesh y modelos: **Blender**.
- Las piezas de Canva son imagen estática; las animaciones de la interfaz van por código.

## Documentación y commits

- Repositorio público y portafolio. El código se escribe para ser leído.
- Nunca escribir claves, tokens ni webhooks en el repo; van en variables de entorno o en los
  Secrets de Roblox.
- Commits en español, imperativos y descriptivos: `agrega sistema de producción pasiva`,
  no `cambios` ni `fix`.
- Siempre con rutas explícitas (`git commit -m "..." -- <rutas>`): otras sesiones comparten el
  índice de git y un `git commit` a secas se lleva lo que ellas dejaron preparado.
- Un commit por tarea, no uno gigante al final.
- Al terminar una tarea: marcarla en el backlog y agregar entrada en `docs/devlog.md`.
- Decisiones técnicas no obvias van a `docs/decisiones.md`.
- Si el README deja de describir el estado real, se actualiza.

## Checklist antes de dar una tarea por terminada

1. `rojo build --output build/test.rbxl` compila.
2. `selene src` sin warnings.
3. `stylua src` aplicado (`stylua --check src` limpio).
4. Probado en Studio vía MCP, no solo "debería funcionar".
