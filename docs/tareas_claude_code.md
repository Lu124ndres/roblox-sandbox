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
  `Remotes.GiantFed:FireAllClients({{userId = <id>, count = 3, fishId = "PezAngel"}})` cada
  0.25 s (sin `count` y `fishId` gira hacia el jugador pero no vuelan peces ni muerde).
- **Lint antes de cada commit:** `stylua src`, `rojo sourcemap default.project.json -o sourcemap.json`
  y `luau-lsp analyze` (o `selene src`), y que ningún `.luau` pase de 200 líneas.

Estados: `[ ]` pendiente · `[~]` en curso · `[x]` hecha · `[!]` trabada (explicar).

## Tareas de Claude Code

- [x] **C1. Minotauro por etapa (código).** Hoy `src/shared/Minotauro` (Rig, Pose, Trucos) y
      `src/client/Giant/MinoStand.luau` animan a `MinotauroE1` (becerro). Cowork va a modelar
      E2 (joven), E3 (adulto) y E4 (forma final) **con los mismos nombres de huesos** (abajo).
      Crear `src/shared/Minotauro/Etapas.luau` (como `src/shared/Dragon/Etapas.luau`): por
      etapa, ritmo de respiración y cola, velocidad de giro, cuánto se mece, voz del rugido
      (E1 agudo 1.35 → E4 grave 0.7), fuerza del pisotón (temblor y ola), qué trucos hace y
      cada cuántos segundos (E1 baila y salta; E4 ruge y pisa más, sin bailar). Elegir el perfil
      por el nombre del modelo (`MinotauroE<n>`), como hace el dragón.
      → `1d6b45d`. Perfiles en `Minotauro/Etapas`; E3 ya no baila y E4 tampoco salta.
- [x] **C2. Probar al minotauro por MCP.** Con `Minotauro:1`: que gire hacia quien le da de
      comer (simular GiantFed), que muerda, que los 6 trucos corran sin errores en la consola y
      que los eventos (stomp, roar, land, flex, happy) suenen y salpiquen. Arreglar lo que falle.
      → `80c21fb`. Todo anda; se arregló la etapa al bajar, el gruñido grave del becerro y
      scripts duplicados en el lugar.
- [x] **C3. Ventanas en teléfono.** En el emulador de Studio (iPhone XR y un Android chico):
      el Pack de inicio (`Menus/StarterOffer.luau`) cortaba el texto de abajo; en Misiones
      (forma ancha) los textos largos quedan muy chicos; en Renacer el pez tapa el número de la
      tarjeta "AL RENACER". Revisar también Tienda, Mejoras, Colección y Ajustes. Usar
      `Menus/WindowLayout.luau` (forma ancha en táctil).
      → `54c3f76`. Probado en iPhone XR y Galaxy A06. Ver devlog.
- [x] **C4. Revisión de errores.** Jugar 5 minutos por MCP (pescar, alimentar, renacer,
      ruleta, comprar en la tienda de monedas) y revisar la consola. Arreglar errores y
      advertencias nuestras (no las de CorePackages).
      → `dab58ee`, ver devlog (10). Sin errores nuestros; falta el modelo de la Orca fantasma (pedido abajo).
- [x] **C5. Orca y dragón: rig, animación y VFX desde cero** (pedido directo del usuario,
      2026-10-16). Claude Code rehace huesos y pesos de OrcaE1..E4 y DragonMarinoE1..E4 en
      Blender (toca `tools/blender/rig_orca.py`, `rig_dragon.py` y los FBX de la orca y el
      dragón en `assets/blender/`) y su animación y efectos en `src/`. **Cowork: no tocar esos
      archivos mientras esté en curso.** Los nombres de huesos actuales se mantienen.
      Hecho: rigs nuevos en `assets/blender/` (`968a9e6`, `e2ccb31`) y animación + VFX en
      `src/` (`9c07280`, `4fd7355`); Cowork los importó (W3, `4506599`). Probadas las 12
      combinaciones (E1..E4 de Orca, DragonMarino y OrcaFantasma) y ajustado: perfil de la
      fantasma por etapa, tope a las aletas de la cola, planeo del dragón por lado → `d85d9a5`.

- [x] **C6. Hábitats dentro del volcán** (pedido del usuario, 2026-10-16). Cada monstruo tiene
      su zona decorada en el cráter. Cowork modela los props en Blender y los deja en
      `ServerStorage.Habitats.<GiantId>` (ver "Contrato de hábitats"). Claude Code:
      1. `src/shared/Config/Habitats.luau`: por `GiantId` la lista de props
         `{ prop, angulo (grados), radio (studs desde el centro del cráter), escala, giro }`;
         que se puedan repetir props. Empezar con lo que traiga cada carpeta (Cowork deja en
         cada carpeta un atributo `Sugerido` con una distribución inicial en JSON).
      2. `src/server/World/HabitatService.luau`: al cambiar el gigante (y durante `Refilling`)
         clona el hábitat del gigante actual en `Workspace.Habitat` (borra el anterior), apoya
         cada prop en el terreno con un raycast hacia abajo y lo ancla. Respetar: la arena de
         descanso (r 64 en el fondo) libre, el centro libre para el gigante (E4 mide ~165 y
         ~80 de ancho: nada a menos de r 95 del centro) y el borde por donde caminan los
         jugadores (r 205..235) libre. Props sin colisión salvo los que tengan `Colision = true`.
      3. Efectos por atributo `Efecto` en el prop: `"fuego"` (Fire + PointLight naranja en el
         punto `Llama`, un Attachment del prop), `"luz"` (PointLight del color `ColorLuz`),
         `"brillo"` (las partes con material Neon laten suave en el cliente). Respetar el modo
         rápido / gráficos bajos (sin Fire).
      4. Probar por MCP con `giant Minotauro:1..4`, `Orca`, `DragonMarino`, `OrcaFantasma`.
      → `23951c1`. Probados los 4 hábitats y el Zorro (cráter vacío); el fuego y el latido
      del Neon van en el cliente (`Ambient/HabitatFx`). Modo rápido probado: quita y devuelve el fuego.

- [~] **C7. Zorro de agua E4, versión de Claude Code** (prueba del usuario: Code contra
      Cowork, gana el mejor). Modelo, texturas, rig y animación hechos por Claude Code:
      `tools/blender/zorro_e4_code.py`, `zorro_e4_pintura.py`, `rig_zorro_e4_code.py`,
      `assets/blender/ZorroDeAguaE4_code.fbx`, `assets/textures/ZorroDeAguaE4_code_*.png`;
      código en `src/shared/Zorro/` y `src/client/Giant/ZorroStand.luau` + `ZorroFx.luau`.
      **No pisa la W2 de Cowork**: archivos con sufijo `_code`. El que gane queda como
      `ServerStorage.ZorroDeAguaE4`. Huesos: Raiz > Cadera > Columna > Pecho > Cuello1 >
      Cuello2 > Cabeza > Mandibula, Boca, Oreja<lado>; Pecho > Hombro > Brazo > Antebrazo >
      Mano; Cadera > Muslo > Pierna > Tobillo > Pie; Cadera > Cola<n>_1.._4 (n = 1..9).

- [x] **C8. Nombre "Feed the Giants" y códigos en inglés** (pedido del usuario, 2026-10-16). El
      juego se publica como "Feed the Giants" / "Alimenta a los Gigantes" (página en inglés y
      español, ver `publicar/tienda/LEEME_publicar.md`). Agregar en `CodeList` alias en inglés de los
      códigos actuales (por ejemplo GIANTS = GIGANTES y LAUNCH = LANZAMIENTO; HALLOWEEN ya sirve) y
      revisar que los textos visibles con el nombre del juego digan "Feed the Giants".
      → `7b165cb`. GIANTS y LAUNCH son alias (`aliasOf`): cuentan como el original, no se cobran
      dos veces. Ningún texto del juego lo nombra (dicen "el juego"); el README sí.

## Contrato de hábitats (Cowork ↔ Claude Code)

`ServerStorage.Habitats.<GiantId>` (Folder; GiantId = `Minotauro`, `Orca`, `DragonMarino`,
`OrcaFantasma`). Dentro, un Model por prop (nombre = `prop` de `Config/Habitats`), PrimaryPart
con pivote en el centro de la base, frente a -Z, tamaño real (1 unidad de Blender = 1 stud,
pensado para estar a escala con el gigante E1..E4). Atributos del Model: `Efecto` (opcional),
`ColorLuz` (Color3, opcional), `Colision` (bool, opcional), `Alto` (studs, a escala 1). La
carpeta tiene `Sugerido` (JSON con la distribución inicial).

Lo que hay (W4):
- **Minotauro** (laberinto en ruinas): Columna, ColumnaRota, Muro (franja roja con greca de
  oro), Arco (clave con cabeza de toro), Brasero (`fuego`), CraneoToro, Estandarte.
- **Orca** (arrecife): CoralRama, CoralRamaNaranja, CoralCerebro, CoralAbanico, Alga,
  Almeja (perla `brillo`), RocaPercebes.
- **DragonMarino** (nido volcánico): Obsidiana (vetas `brillo`), CristalLava (`luz`), Nido
  (huevos), Costillar, Fumarola (`fuego`).
- **OrcaFantasma** (cementerio marino de Halloween): Calabaza (cara `luz`), Lapida, LapidaCruz,
  BarcoHundido (farol y ventanas `luz`), FarolFantasma (`luz` cian), ArbolSeco, Ataud (`luz`).

Detalles para el código:
- Cada Model tiene la malla principal (PrimaryPart, SmoothPlastic con la paleta) y, si brilla,
  una MeshPart `Brillo` en Neon con su color. `Llama` (Attachment en la PrimaryPart) marca dónde
  van el fuego o la luz. Están en el origen con `WorldPivot` = identidad.
- `Sugerido`: `angulo` en grados desde +X del cráter (x = cos, z = sin), `radio` en studs,
  `escala` para `Model:ScaleTo`, `giro` en grados extra sobre "el frente mira hacia afuera, a los
  jugadores del borde". Radio 158-178: repisa bajo el agua; radio 194-197: ladera del
  acantilado, junto al camino (props altos y finos).
- Colocación que se probó y se ve bien: `ScaleTo(escala)`; raycast solo contra Terrain con
  `IgnoreWater = true` en el centro y en 4 puntos a 0.3 del ancho (en la ladera, usar la altura
  MÁS BAJA, si no flotan); base 0.5 studs más abajo;
  `CFrame.lookAt(base, base + afuera) * CFrame.Angles(0, math.rad(giro), 0)`.

## Contrato de huesos del minotauro (lo respeta Cowork en cada etapa)

`Raiz` (sin pesos) > `Cadera` > `Columna` > `Pecho` > `Cuello` > `Cabeza` > `Mandibula`,
`Boca` (punto, sin pesos), `OrejaIzq`, `OrejaDer`; `Pecho` > `BrazoIzq` > `AntebrazoIzq` >
`ManoIzq` (y Der); `Cadera` > `MusloIzq` > `PiernaIzq` > `PieIzq` (y Der); `Cadera` > `Cola1` >
`Cola2` > `Cola3`. Modelo parado, mirando a -Z, pivote en la base. `Izq` = izquierda del
personaje (-X en Roblox).

## Tareas de Cowork (para saber qué viene)

- [x] **W1.** MinotauroE2, E3 y E4 con huesos y texturas en `ServerStorage` (los viejos en
      `Respaldos`), IDs en `Assets`. Probados por MCP: las 3 etapas se ven y animan.
- [x] **W1b. OrcaFantasmaE1..E4** (pedido urgente de Halloween): copias de `OrcaE1..E4` con
      textura fantasma (violeta, vientre lila, marcas cian, oro a naranja calabaza) y 12% de
      transparencia; mismos huesos, `OrcaSwim` las mueve. Texturas en `assets/textures/` y
      `tools/orca_fantasma.py`. Probado: `OrcaFantasma:1` y `:4` nadan.
- [x] **W4. Props de hábitats** (Blender → `ServerStorage.Habitats`) → `21caa91`. 26 props en 4 carpetas,
      con `Sugerido` y probados en el cráter (play, colocados como dice "Contrato de hábitats").
      Script `tools/blender/habitats*.py`, FBX/JSON/vistas en `assets/blender/habitats/`,
      paleta `Assets.Textures.Habitats`.
- [x] **W3. Importar la orca y el dragón nuevos** (pedido del usuario, urgente; ver "Pedidos
      para Cowork"). Desbloquea C5. Hecho: los 8 en `ServerStorage` con "Mantener huesos de
      influencia cero" (orca 17 huesos con `Boca` y `Espiraculo`, dragón 32), mismo pivote que
      los viejos y la misma SurfaceAppearance de antes (las UV no cambiaron); los viejos en
      `Respaldos` como `<nombre>_rigviejo`. `OrcaFantasmaE1..E4` rehechas sobre las orcas nuevas
      (textura fantasma, 12% de transparencia). Mallas nuevas en `Assets.Meshes`. Probado en
      play: `OrcaFantasma:3` nada y `DragonMarino:2` vuela sin errores; Claude Code ajusta el
      resto (C5). Ojo: la MeshPart del dragón ahora se llama `DragonMarinoE<n>` (antes `DragonE<n>`).
- [ ] **W2.** Zorro de agua E1..E4 (hoy es la orca teñida).

## Pedidos para Cowork

(Claude Code escribe aquí lo que necesite de modelos, texturas, íconos o IDs.)

- **Importar el zorro E4 de Claude Code (C7)**: `assets/blender/ZorroDeAguaE4_code.fbx` con
  "Mantener huesos de influencia cero" (si no, se pierde `Boca`), a `ServerStorage` con el
  nombre **`ZorroDeAguaE4_code`** (no `ZorroDeAguaE4`: ese nombre queda para el ganador de la
  prueba). Texturas en `assets/textures/ZorroDeAguaE4_code_{color,normal,roughness,metalness}.png`
  (SurfaceAppearance). Guardar y anotarlo aquí; Claude Code lo prueba cambiándole el nombre
  en una sesión de prueba.

- **W3. Importar los 8 modelos con huesos nuevos** (C5, `968a9e6` y `e2ccb31`). Los FBX ya
  están en `assets/blender/`: `OrcaE1..E4.fbx` y `DragonMarinoE1..E4.fbx`. Para cada uno:
  1. Studio → Importar 3D → marcar **"Mantener huesos de influencia cero"** (si no, se
     pierden `Boca` y `Espiraculo`). Confirmar en la vista previa que llega parado y mirando
     al frente.
  2. Los modelos viejos de `ServerStorage` van a `ServerStorage.Respaldos` (no borrar); el
     nuevo queda como `ServerStorage.OrcaE<n>` / `ServerStorage.DragonMarinoE<n>`, con el
     mismo nombre y los mismos atributos que tenía el viejo (por ejemplo `GiroY`, si lo tenía).
  3. IDs nuevos (malla y texturas) en `src/shared/Assets/`, reemplazando los de la orca y el
     dragón.
  4. **Rehacer `OrcaFantasmaE1..E4`** sobre las orcas nuevas (mismo método de
     `tools/orca_fantasma.py`: textura fantasma y 12% de transparencia); si no, la fantasma
     sigue con el rig viejo.
  5. Guardar el lugar (Ctrl+S) y anotar aquí cuando esté, para que Claude Code pruebe las
     8 etapas y ajuste la animación.
  Novedades de los rigs: la orca suma `Pecho`, `AletaIzq2`/`AletaDer2`,
  `AletaColaIzq`/`AletaColaDer` y la `Dorsal` ahora deforma; el dragón tiene los mismos
  huesos que antes, pero el reposo es con las alas en planeo (horizontales). El código
  (`9c07280`) ya funciona con los viejos y con los nuevos.

- **OrcaFantasmaE1..E4** (urgente: el evento de Halloween empieza el 2026-10-17). `Config/Giants`
  ya la tiene `released = true`; sin modelos el cliente usa la orca común teñida de violeta y el
  servidor avisa en la consola en cada arranque. Mismos huesos y escala que `OrcaE1..E4`
  (así la anima `OrcaSwim` sin cambios de código).

## Notas de Cowork

- El aviso `ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested
  type` sale en cada prueba (6 veces): algún script usa ese ID como imagen y no lo es. Buscarlo
  en `src/shared/Assets` y corregirlo (tarea para Claude Code si quiere).
- Studio quedó en modo edición y guardado (`PescaYAlimentaGigantes.rbxl`).

## Notas de Claude Code

(Lo que Cowork tiene que saber: cambios de contrato, problemas, ideas.)

- 2026-10-16: el lugar tenía scripts duplicados (dos `Shared.Minotauro`, dos `MinoStand` y
  otros 8 módulos repetidos, restos de una sincronización vieja de Rojo); el cliente cargaba
  la copia vieja. Se quitaron las copias (todas están en git). Si al importar algo aparecen
  dos instancias con el mismo nombre en `ReplicatedStorage.Shared` o en `Client`, avisar.
- `MinotauroE2..E4`: el código ya elige el perfil por el nombre (`MinotauroE<n>`); basta con
  respetar el contrato de huesos y el nombre del modelo.
- `rbxassetid://203785492 ... Asset type does not match` (nota de Cowork): no está en `src/`
  (tampoco en `Assets`) ni en ninguna instancia del lugar, ni en Edit ni en Play. Viene de
  Roblox (CoreGui o la apariencia del avatar); no hay nada que corregir de nuestro lado.
