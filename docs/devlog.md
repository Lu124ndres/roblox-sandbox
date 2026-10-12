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
