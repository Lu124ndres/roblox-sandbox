# Devlog

Bitácora de desarrollo. Cada sesión agrega una entrada al inicio del archivo
(la más reciente arriba) con este formato:

```
## AAAA-MM-DD — Título corto
**Qué se hizo:**
**Qué se rompió:**
**Qué sigue:**
```

---

## 2026-10-11 — Configuración del entorno base

**Qué se hizo:**

- Estructura de carpetas (`src/server`, `src/client`, `src/shared`, `assets/`, `docs/`).
- `default.project.json` de Rojo mapeando server, shared y client a sus servicios.
- Prueba de humo: `Hello.server.luau` y `Hello.client.luau` imprimen al conectarse.
- Módulos compartidos vacíos y tipados: `Config.luau`, `Assets.luau`, `UIConfig.luau`.
- Configuración de selene, stylua y wally; `.gitignore`; licencia MIT.
- Documentación: `CLAUDE.md`, README, setup, decisiones, ideas, ui-assets,
  pipeline de Blender.

**Qué se rompió:** nada todavía. El build, el linting y la prueba en Studio no se
han ejecutado en esta sesión.

**Qué sigue:**

- Conectar el plugin de Rojo, el MCP de Studio y verificar la prueba de humo.
- Correr el checklist completo (`rojo build`, `selene src`, `stylua src`).
- Definir el juego y crear `docs/backlog.md`.

---

## 2026-10-12 — Corrección del nombre del repositorio

**Qué se hizo:**

- El repositorio se llama `roblox-sandbox`, no `sandbox`. Se corrigió en `README.md`
  el título, la URL y el `cd` del comando de clonado, y en `docs/setup.md` el nombre
  del repositorio remoto a crear.
- Se revisó el resto de la documentación: no quedan otras referencias al nombre anterior.

**Qué se rompió:** nada.

**Qué sigue:** lo pendiente de la sesión anterior (Rojo, MCP de Studio, checklist).

---

## 2026-10-12 — Fin de línea, checklist de calidad y limpieza del repositorio

**Qué se hizo:**

- `.gitattributes` con `* text=auto eol=lf`. `git add --renormalize .` no cambió ningún
  archivo: el índice ya tenía LF.
- Checklist de calidad:
  - `rojo build --output build/test.rbxl`: **pasa**. La primera corrida falló porque
    la carpeta `build/` no existía (está en `.gitignore`); hubo que crearla.
  - `selene src`: **pasa**, 0 errores y 0 warnings.
  - `stylua --check src`: **pasa**, sin diferencias.
- `docs/setup.md`: el MCP de Studio se activa desde el panel Asistente (viene
  integrado); se quitó la instalación desde `studio-rust-mcp-server`, que está
  descontinuado. Se agregó una advertencia sobre versiones duplicadas del plugin de
  Rojo y se completó la URL de `git remote add`.
- Se borraron 30 `tmp_obj_*` y 2 `stale-*` de `.git`; `git fsck` limpio.

**Qué se rompió / qué no se verificó:**

- **Prueba de humo en Studio: no ejecutada.** El MCP de Studio no estaba disponible en
  la sesión del asistente, así que no se comprobó `ServerScriptService.Server`,
  `ReplicatedStorage.Shared` ni el `require` de los módulos compartidos.
- `default.project.json` todavía tiene `"name": "sandbox"` (no es documentación; queda
  sin tocar).

**Qué sigue:**

- Activar el MCP de Studio y repetir la prueba de humo.
- Definir el juego y crear `docs/backlog.md`.

---

## 2026-10-12 — Registro del MCP de Studio en el proyecto

**Qué se hizo:**

- `.mcp.json` en la raíz: servidor `roblox-studio` (stdio) que ejecuta
  `cmd.exe /c ${LOCALAPPDATA}\Roblox\mcp.bat`.
- Verificado: el JSON es válido, `mcp.bat` existe y el `StudioMCP.exe` al que apunta
  también.
- `docs/setup.md`: dónde vive la configuración y que hay que recargar VS Code.

**Qué se rompió / qué no se verificó:** la conexión no se probó todavía. El servidor
solo se carga al recargar VS Code, así que la prueba de humo en Studio sigue pendiente.

**Qué sigue:** recargar VS Code, aprobar el servidor y repetir la prueba de humo.

---

## 2026-10-12 — Intento de prueba de humo en Studio por MCP

**Qué se hizo:**

- README: en "Cómo levantarlo" se indica que hay que crear `build/` antes del primer
  `rojo build`, porque está en `.gitignore` y no viene en el clon.

**Qué se rompió / qué no se verificó:**

- **Prueba de humo en Studio: no ejecutada.** Tras recargar VS Code, el servidor
  `roblox-studio` aparece conectado en la sesión del asistente, pero no expone ninguna
  herramienta ni recurso. Sin herramientas no se pudo comprobar
  `ServerScriptService.Server`, `ReplicatedStorage.Shared` ni el `require` de los
  módulos de `src/shared`.

**Qué sigue:**

- Revisar por qué el MCP no publica herramientas: confirmar en `/mcp` el estado y la
  lista de herramientas de `roblox-studio`, y que el MCP siga activo en el panel
  Asistente de Studio con el lugar abierto.
- Repetir la prueba de humo cuando las herramientas estén disponibles.

---

## 2026-10-12 — Prueba de humo en Studio por MCP

**Qué se hizo:** con el MCP de Studio ya publicando herramientas, se ejecutó la prueba
de humo sobre `sandbox.rbxl` (modo Edit y luego Play).

**Resultado:**

- **Estructura: pasa.** `ServerScriptService.Server` (Folder) contiene `Hello` (Script);
  `ReplicatedStorage.Shared` (Folder) contiene `Assets`, `Config` y `UIConfig`
  (ModuleScript); `StarterPlayerScripts.Client` (Folder) contiene `Hello` (LocalScript).
- **Contenido: pasa.** El `Source` de los cinco scripts mide exactamente los mismos
  bytes que los archivos de `src/` y todos empiezan con `--!strict`.
- **`require` de `src/shared`: pasa.** Los tres módulos cargan sin error, devuelven
  tablas congeladas (`table.isfrozen`) con las claves esperadas:
  `Assets` (MISSING, UI, Textures, Animations), `Config` (Economy, Progression,
  Gameplay), `UIConfig` (Colors, Fonts, TextSizes, Spacing, Tweens).
- **Play: pasa.** Output muestra `servidor conectado via Rojo` y
  `cliente conectado via Rojo`.

**Qué se rompió / qué no se verificó:**

- El plugin de Rojo avisó en Output `Couldn't connect to the Rojo server` y no había
  ningún proceso `rojo serve` corriendo. El contenido de Studio es el que se sincronizó
  antes (coincide con `src/`), pero la **sincronización en vivo no se verificó** en esta
  sesión.
- `mcp.bat` (generado por Studio) imprime `"else" no se reconoce...` al terminar: el
  `else` está en otra línea que el `)`. No afecta hoy; el respaldo por registro fallará
  cuando Studio se actualice.

**Qué sigue:**

- Levantar `rojo serve`, reconectar el plugin y confirmar que un cambio en `src/` llega a
  Studio.
- Definir el juego y crear `docs/backlog.md`.

---

## 2026-10-12 — Prueba de humo repetida con Rojo conectado

**Qué se hizo:** con `rojo serve` 7.7.1 escuchando en el puerto 34872 y el plugin
conectado, se repitió la prueba de humo completa por MCP.

**Resultado: todo pasa.**

- **Sincronización en vivo:** se creó `src/shared/SyncProbe.luau` y apareció en
  `ReplicatedStorage.Shared` al instante con el `Source` correcto; al borrarlo,
  desapareció de Studio. El archivo de prueba no quedó en el repositorio.
- **Estructura, contenido y `require`:** mismos resultados que en la entrada anterior
  (carpetas y clases correctas, `Source` idéntico en bytes a `src/`, `--!strict` en los
  cinco scripts, los tres módulos compartidos cargan congelados con sus claves).
- **Play:** Output muestra solo `servidor conectado via Rojo` y
  `cliente conectado via Rojo`, sin avisos de Rojo.

**Qué se rompió:** nada. Queda abierto solo el bug de `mcp.bat` anotado antes.

**Qué sigue:** definir el juego y crear `docs/backlog.md`.

---

## 2026-10-12 — Preparación del modelo OrcaE1 en Blender

**Qué se hizo:**

- Importado `assets/blender/OrcaE1_meshy/` (FBX de Meshy con texturas embebidas y
  4 PNG de 2048×2048: color, metallic, normal, roughness) en una escena nueva de Blender
  5.2. Original: 46,748 triángulos, una sola pieza cerrada, sin esqueleto, sin geometría
  suelta ni duplicada, normales consistentes, 0.67 × 1.90 × 1.12 m.
- Limpieza: transformaciones aplicadas, origen en la base (entre los pies) y centrado.
- Escala: 4.2 m de alto = 15 studs (3 personajes de 5 studs, 1 stud = 0.28 m).
  Queda en 15 × 9.0 × 25.5 studs (alto × ancho × largo).
- Polígonos: límite usado **10,000** (el de `blender-pipeline.md`; Roblox permite
  20,000 por malla según su documentación de especificaciones de modelado).
  Reducido a **9,806** triángulos en dos zonas: cara 0.30, cuerpo 0.19.
- Texturas horneadas desde el original a 1024×1024 con UVs nuevas: color, normal y
  rugosidad (8 bits en escala de grises). Metallic descartado: el mapa de Meshy es ≈ 0
  (máximo 0.09, media 0.002).
- Exportado `assets/blender/OrcaE1.fbx` con `OrcaE1_Color.png`, `OrcaE1_Normal.png`
  y `OrcaE1_Roughness.png` al lado (rutas relativas). Verificado reimportando el FBX.
- Capturas antes/después de frente y de lado en `docs/capturas/`.

**Qué se rompió:**

- El primer horneado salió con manchas blancas en la cara interna de las aletas: Smart
  UV Project (66°) metió los dos lados de cada aleta en la misma isla y 296 triángulos se
  solapaban en las UVs. Con 35° quedan 0 solapes.
- Meshy trae normales personalizadas que el decimate dejó corruptas (99 esquinas de
  hasta 166°). Se borraron; la malla reducida usa sombreado suave normal.

**No verificado:**

- No se importó en Roblox Studio todavía. Pendiente: confirmar que la orca mira hacia
  donde se espera (exportado con forward −Z, up Y) y que el importador la lea en metros.
- Este trabajo adelanta la fase 2 por pedido explícito; el modelo no se integra al juego
  hasta que la fase 1 esté terminada.

**Qué sigue:** importar `OrcaE1.fbx` en Studio y revisar orientación, escala y
`SurfaceAppearance`.

---

## 2026-10-12 — Texturas de OrcaE1 embebidas en el FBX

**Qué se hizo:**

- Diagnóstico: la orca importaba en Studio sin color porque `OrcaE1.fbx` se exportó con
  las texturas referenciadas por ruta relativa, no embebidas. Los PNG horneados sí
  existían, pero en `assets/blender/`.
- Texturas finales movidas a `assets/textures/`: `OrcaE1_color.png`,
  `OrcaE1_normal.png`, `OrcaE1_roughness.png` (1024×1024). El color se revisó: atlas con
  las islas UV en azul pizarra, blanco y celeste; 18 % de fondo negro entre islas.
- El material de la orca en Blender apunta a esos tres archivos y se ve con color.
- `OrcaE1.fbx` reexportado con Path Mode Copy, Embed Textures y Apply Scalings en FBX
  Unit Scale (3 MB). Reimportado en Blender: las tres texturas vienen empaquetadas y
  conectadas a color, normal y rugosidad.
- Los archivos de Meshy salen del repo (siguen en disco) y quedan en `.gitignore`.
- `blender-pipeline.md`: regla de texturas embebidas y ubicación de los PNG finales.

**No verificado:** la importación en Studio con el FBX nuevo.

**Qué sigue:** reimportar `OrcaE1.fbx` en Studio y confirmar color, orientación y escala.
