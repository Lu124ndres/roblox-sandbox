# Tareas para Claude Code

Este archivo coordina a dos asistentes que trabajan en el mismo repositorio:

| Quién | Qué hace | Carpetas suyas |
|---|---|---|
| **Claude Code** (en la PC, con MCP de Studio) | Scripts y programación: `src/` (menos `src/shared/Assets/`), `default.project.json`, pruebas en Studio, balance, UI | `src/`, `docs/` (menos `blender-pipeline.md`) |
| **Claude Cowork** (en la nube) | Diseño y modelos: Blender, texturas, íconos, importar modelos a `ServerStorage` y anotar sus IDs | `tools/blender/`, `tools/productos/`, `assets/`, `src/shared/Assets/`, `docs/blender-pipeline.md` |

Antes de empezar, leer `CLAUDE.md` (reglas: `--!strict`, módulos ≤ 200 líneas, IDs solo en
`Assets`, balance solo en `Config`, el servidor decide todo) y lo último de `docs/devlog.md`.

## Cómo trabajar sin pisarse

- **Mismo repositorio, misma rama (`main`).** Hacer `git status` antes de cada commit y
  agregar **solo los archivos propios** (`git add <archivo>...`, nunca `git add -A` ni `.`).
- **No tocar las carpetas del otro.** Si hace falta un cambio ahí, pedirlo abajo en
  "Pedidos para Cowork".
- **Un commit por tarea**, mensaje en español. Al terminar una tarea: marcarla `[x]`, poner
  el hash del commit y una nota corta; agregar una entrada en `docs/devlog.md`.
- **Studio:** el lugar es `PescaYAlimentaGigantes.rbxl` (carpeta del proyecto), con Rojo
  conectado. Guardar con Ctrl+S (o `execute_luau` no guarda: avisar al usuario). No publicar.
  Lo que vive solo en el `.rbxl` (modelos en `ServerStorage`) no se borra; lo viejo va a
  `ServerStorage.Respaldos`.
- **Pruebas por MCP:** `start_stop_play`, y en el cliente
  `game.ReplicatedStorage.Remotes.AdminCommand:FireServer('giant', 'Minotauro:1')` pone ese
  monstruo y etapa. Para simular que alguien le da de comer, en el servidor:
  `Remotes.GiantFed:FireAllClients({{userId = <id del jugador>}})` cada 0.25 s.
- **Lint antes de cada commit:** `stylua src`, `rojo sourcemap default.project.json -o sourcemap.json`
  y `luau-lsp analyze` (o `selene src`), y que ningún `.luau` pase de 200 líneas.

Estados: `[ ]` pendiente · `[~]` en curso · `[x]` hecha · `[!]` trabada (explicar).

## Tareas de Claude Code

- [~] **C1. Minotauro por etapa (código).** Hoy `src/shared/Minotauro` (Rig, Pose, Trucos) y
      `src/client/Giant/MinoStand.luau` animan a `MinotauroE1` (becerro). Cowork va a modelar
      E2 (joven), E3 (adulto) y E4 (forma final) **con los mismos nombres de huesos** (abajo).
      Crear `src/shared/Minotauro/Etapas.luau` (como `src/shared/Dragon/Etapas.luau`): por
      etapa, ritmo de respiración y cola, velocidad de giro, cuánto se mece, voz del rugido
      (E1 agudo 1.35 → E4 grave 0.7), fuerza del pisotón (temblor y ola), qué trucos hace y
      cada cuántos segundos (E1 baila y salta; E4 ruge y pisa más, sin bailar). Elegir el perfil
      por el nombre del modelo (`MinotauroE<n>`), como hace el dragón.
- [ ] **C2. Probar al minotauro por MCP.** Con `Minotauro:1`: que gire hacia quien le da de
      comer (simular GiantFed), que muerda, que los 6 trucos corran sin errores en la consola y
      que los eventos (stomp, roar, land, flex, happy) suenen y salpiquen. Arreglar lo que falle.
- [ ] **C3. Ventanas en teléfono.** En el emulador de Studio (iPhone XR y un Android chico):
      el Pack de inicio (`Menus/StarterOffer.luau`) cortaba el texto de abajo; en Misiones
      (forma ancha) los textos largos quedan muy chicos; en Renacer el pez tapa el número de la
      tarjeta "AL RENACER". Revisar también Tienda, Mejoras, Colección y Ajustes. Usar
      `Menus/WindowLayout.luau` (forma ancha en táctil).
- [ ] **C4. Revisión de errores.** Jugar 5 minutos por MCP (pescar, alimentar, renacer,
      ruleta, comprar en la tienda de monedas) y revisar la consola. Arreglar errores y
      advertencias nuestras (no las de CorePackages).

## Contrato de huesos del minotauro (lo respeta Cowork en cada etapa)

`Raiz` (sin pesos) > `Cadera` > `Columna` > `Pecho` > `Cuello` > `Cabeza` > `Mandibula`,
`Boca` (punto, sin pesos), `OrejaIzq`, `OrejaDer`; `Pecho` > `BrazoIzq` > `AntebrazoIzq` >
`ManoIzq` (y Der); `Cadera` > `MusloIzq` > `PiernaIzq` > `PieIzq` (y Der); `Cadera` > `Cola1` >
`Cola2` > `Cola3`. Modelo parado, mirando a -Z, pivote en la base. `Izq` = izquierda del
personaje (-X en Roblox).

## Tareas de Cowork (para saber qué viene)

- [~] **W1.** MinotauroE2, E3 y E4 en Blender con huesos y texturas, importados a
      `ServerStorage` (reemplazan a los viejos sin huesos).
- [ ] **W2.** Zorro de agua E1..E4 (hoy es la orca teñida).

## Pedidos para Cowork

(Claude Code escribe aquí lo que necesite de modelos, texturas, íconos o IDs.)

## Notas de Claude Code

(Lo que Cowork tiene que saber: cambios de contrato, problemas, ideas.)
