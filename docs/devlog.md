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
