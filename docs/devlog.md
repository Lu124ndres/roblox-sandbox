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

---

## 2026-10-12 — OrcaE1 importada en Roblox y registrada

**Qué se hizo:**

- El MCP de Studio no tiene ninguna herramienta para importar o subir `.fbx`
  (`insert_asset` solo inserta IDs existentes; `upload_image` solo sube imágenes). La
  importación se hizo a mano con **File → Import** y "Upload to Roblox".
- La orca quedó en `ServerStorage.OrcaE1` (Model) con un `MeshPart` `OrcaE1` y su
  `SurfaceAppearance` con ColorMap, NormalMap y RoughnessMap. Los cuatro assets existen
  en Roblox a nombre de la cuenta (`GetProductInfo`).
- IDs registrados en `src/shared/Assets.luau`: nueva sección `Meshes` y texturas
  `OrcaE1Color`, `OrcaE1Normal`, `OrcaE1Roughness`. Verificado en Studio que coinciden
  con los del `MeshPart`. Estados en `docs/ui-assets.md`: los cuatro `subido`; la
  moderación no se puede consultar desde Studio.
- Checklist: `rojo build`, `selene src` y `stylua --check src` pasan.

**Resultado de las verificaciones:**

- Frente: **pasa**. Mira a −Z (LookVector `0, 0, -1`; la cara se ve desde −Z).
- Color y textura en Studio: **pasa**.
- Escala: **no pasa**. Mide 4.2 studs de alto (2.53 × 4.2 × 7.14) en lugar de 15. Junto a
  un personaje R15 por defecto (5.46 studs) queda en 0.77×. El importador tomó los metros
  del archivo como studs. No se corrigió: queda a decisión.
- La copia temporal y el personaje de la prueba se borraron.

**Qué sigue:** decidir cómo corregir la escala (reimportar con Scale Unit en metros, o
fijar el tamaño del MeshPart a 15 studs de alto). Guardar el lugar en Studio: el modelo en
`ServerStorage` vive en el `.rbxl`, no en el repositorio.

---

## 2026-10-12 — Definición del juego y vertical slice: pescar y alimentar a la Orca

**Qué se hizo:**

- Diseño: `docs/alcance.md` (concepto, cuatro gigantes, barra de hambre, ataques,
  recompensa del ciclo y calibración de números), `docs/roadmap.md` (v1 con Orca y
  Minotauro; Dragón marino y Zorro de agua como eventos 1 y 2) y `docs/backlog.md`
  (hitos H1 a H5 y eventos).
- Mapa: `world/Playa.model.json` (504 partes) generado por `tools/generar_playa.py`:
  arena, orilla con espuma, agua, muelle con 4 puntos de pesca turquesa, plataforma con
  cubeta coral, isla de la guarida, palmeras, rocas, sombrillas, faroles con luz.
  `default.project.json` ahora mapea `Workspace.Playa` y la iluminación de tarde.
- Servidor: `PlayerData`, `FishingService`, `FeedingService`, `GiantService`,
  `GiantModel`, `Proximity`, `Remotes` y `Main.server`. Se borraron los `Hello` de la
  prueba de humo.
- Cliente: barra de hambre de 4 estados, monedas y carga, botón TIRA, corcho y sedal,
  avisos y banners.
- Compartido: `Config` (peces, pesca, cadena de gigantes), `Protocol` (nombres de
  remotes, atributos y piezas del mapa), `UIConfig` (paleta y animaciones).
- Checklist: `rojo build` pasa; `selene src` 0 errores y 0 warnings; `stylua --check`
  pasa; además `luau-lsp analyze` en modo estricto sin errores.

**Prueba en Studio (`sandbox.rbxl`, 1 jugador):**

- La playa se insertó a mano desde un `.rbxm` porque el `rojo serve` abierto se había
  levantado con el proyecto anterior y no recarga el árbol nuevo.
- Pescar: el prompt aparece, pica entre 2 y 5 s, el botón TIRA se ve grande al centro y
  Espacio también recoge. Capturas registradas (+1 Sardina, +1 Caballa), carga 3/5.
- Alimentar: con la carga vacía avisa "No llevas peces". Con 3 peces: +12 monedas,
  barra al 14 % (7 de comida / 48), la Orca (`ServerStorage.OrcaE1`) crece sobre la isla
  y mira al muelle.

**Qué se rompió:**

- El avatar caía al mar: los pasamanos están a 2.3 studs y un avatar bajo pasa por
  debajo, y la plataforma tenía un hueco en el frente. Se cerró el frente y se agregaron
  paredes invisibles en todo el borde del muelle.
- La primera versión del mapa no compilaba: Rojo pide `UDim2` explícito
  (`{"UDim2": [[1, 0], [1, 0]]}`) y `Font` con `weight` y `style`.

**No verificado:**

- Dos jugadores a la vez, ping simulado y emulador de móvil.
- La iluminación del proyecto: con el `rojo serve` viejo no se aplicó a `Lighting`.
- Cambios sin guardar en `sandbox.rbxl`: se borraron `Baseplate` y el `SpawnLocation`
  viejo y se quitó la copia importada de la playa. No se guardó el lugar.

**Qué sigue:** reiniciar `rojo serve`, guardar el lugar limpio y terminar H1 (dos
jugadores, ping, móvil). Después H2: despedida y relevo al Minotauro.

---

## 2026-10-12 — Isla grande, pesca desde la orilla, Orca animada, ambiente y sonido

**Qué se hizo:**

- Mapa nuevo: isla de ~250 studs con laguna central, anillo de madera con 8 cubetas y 8
  antorchas, 4 muelles, cabaña, campamento con fogata y hamaca, faro en un promontorio,
  34 palmeras, arbustos con flores, conchas, boyas y espuma. Piezas en
  `world/Isla.model.json` (2,071 partes) desde `tools/generar_isla.py`; terreno desde
  `src/server/World/` al arrancar. Medidas comunes en `src/shared/WorldLayoutData.json`.
- Pesca desde cualquier punto de la orilla o de los muelles (`ShoreCast`, remote
  `CastRequest`), con botón Pescar en pantalla y tecla F.
- Caña de primitivas, brazo animado por código, estela en la punta y en el corcho,
  ondas, "!" al picar, pez que salta hasta el jugador. Todos ven la pesca de todos
  (atributos `FishingState`, `FishingTarget`, `FishingCatch`).
- Orca dibujada en el cliente: crece suave, respira, se mece, mira alrededor, gira hacia
  quien la alimenta, rebota con corazones y salpicadura, salta en cada estado y echa
  agua por el espiráculo.
- Ambiente: ciclo de día y noche de 16 min con atardecer y estrellas, haz del faro,
  gaviotas, peces que saltan, destellos del sol, espuma que va y viene.
- Sonidos: olas, gaviota, latigazo, plop, burbuja, carrete, mordida, orca, fanfarria,
  monedas y clic (Tienda de creadores + sonidos instalados de Roblox).
- Checklist: `rojo build`, `selene src` (0/0), `stylua --check src` y `luau-lsp analyze`
  en estricto pasan.

**Prueba en Studio:** pesca desde la playa (3 peces: Caballa, Sardina...), alimentar desde
una cubeta del anillo (+5 monedas, barra al 8 %), la Orca reacciona. Los 11 sonidos con ID
cargan (`IsLoaded`) y el océano suena en bucle.

**Qué se rompió:**

- Con `FillCylinder` el suelo quedó 4 studs más alto de lo planeado (redondeo a la
  cuadrícula) y tapaba el anillo. Se pasó a `WriteVoxels` con ocupación exacta.
- El brazo no se movía: el avatar usa `AnimationConstraint` y el Animator pisa los
  cambios de `C0`/attachment; además cada avatar orienta la mano distinto y la caña salía
  de costado. Ahora la pose se suma al `Transform` después del Animator y la caña se
  orienta con el cuerpo.
- Rojo dejó una `Isla` y un `Sky` duplicados al cambiar propiedades de la raíz y de
  `Lighting` ("Could not swap instances"). Se borraron a mano en Studio.

**No verificado:** cómo suenan (no hay audio en la sesión remota), dos jugadores a la vez,
rendimiento en móvil.

**Qué sigue:** escuchar y ajustar volúmenes, prueba en móvil, guardar el lugar y seguir con
H2 (despedida y Minotauro).

---

## 2026-10-13 — Zona de entrenamiento, poder de pesca y Cráter del Abismo

**Qué se hizo:**

- Centro de la isla: zona de entrenamiento con 10 estanques (agua de terreno propia),
  estatua de un pez dorado, bancos y antorchas. `TrainingService` da poder AFK.
- Poder de pesca: leaderstats "Poder", HUD con el bonus por pez, carteles por estanque.
- Gigante por etapas (3, 8, 15 y 25 jugadores de alto) con rugido, temblor y olas.
- Cráter del Abismo al norte (centro en z = 420) con puente de piedra, muelles, puerta,
  agujas, esqueletos, cristales y lava. Ambiente que cambia al acercarse.
- Sonidos nuevos: rugido, ambiente de terror, trueno (Tienda de creadores).
- `Config` y `UIConfig` divididos en carpetas.

**Prueba en Studio:** entrenar en el estanque x1 (poder 0 → 22, bonus x1.05); carteles
x1 "Entrenar (E)" y x100 "Necesitas 600K"; la Orca en el cráter crece a la etapa 2 y a la
4 (simulado cambiando el progreso en el cliente); el rescate del abismo devuelve a la
puerta; el botón Pescar ya no aparece en el cráter.

**Qué se rompió:** la pared invisible del borde del acantilado tenía un hueco frente a la
puerta y se caía directo al lago; se dejó hueco solo en los muelles. Un `Part` del cráter
recibía la rotación en el lugar del material y Rojo no compilaba.

**No verificado:** alimentar en el cráter con peces reales, 2 jugadores, móvil.

## 2026-10-13 — Puente rápido, entrenamiento para 50, poder que acelera y gigante que se enoja

**Qué se hizo:**

- Puente al volcán rehecho: una sola rampa lisa (antes eran losas inclinadas al revés,
  en serrucho) con corriente: velocidad 44, cámara un poco más abierta y flechas turquesa
  que se encienden en onda. Calderos extra junto a la puerta. Sin portales.
- Isla y plaza más grandes; 10 estanques de 12.5 studs llenos hasta el borde. Cada
  jugador lanza el corcho frente a sí, así caben todos en el mismo estanque.
- Luz: brillo de día 3.1 → 2.2, bloom 0.5 → 0.25 (umbral 2.2), sin resplandor del sol,
  bruma más baja, exposición −0.15, piedra y arena más oscuras, cristales menos intensos.
- Poder de pesca: más velocidad de pique y más peces por pique; capacidad 20 x peces por
  pique (antes 5 fija). HUD: "Poder N · xV vel · P/pique" y "Peces n/capacidad".
- Hambre escalada hasta 50 jugadores.
- Enojo del gigante (`GiantMood`, `AngerMeter`, `GiantAttacks`): fila Calmada / Molesta /
  ¡FURIOSA! en el panel de hambre, carteles y rugidos, contorno rojo que late y se
  sacude, la barra baja sin encoger, Salpicón con círculo rojo de 3 s y empujón.

**Prueba en Studio:** HUD "Poder 0 · x1.0 vel · 1/pique", "Peces 0/20"; zona de
entrenamiento legible con la luz nueva; el enojo pasa a Molesta y a ¡FURIOSA! con su
cartel; en la puerta del cráter llegaron Salpicones (círculo rojo, empujón, aviso) sin
perder nada; sobre el puente WalkSpeed 44 y 100 studs subidos en 3 s.

**No verificado:** pescar con mucho poder (no hay forma de darse poder en el cliente),
calmar a la Orca entregando peces, varios jugadores en un estanque, móvil. Selene no corrió
(no pudo bajar el API dump de Roblox); luau-lsp estricto sin errores.

## 2026-10-13 — Alimentar desde toda la orilla y hambre recalibrada

**Qué se hizo:**

- `FeedRequest` + `client/Feeding/FeedController`: botón Alimentar (F) en cualquier punto
  de la orilla del volcán con peces encima; aviso al llegar. Línea coral brillante en el
  borde del cráter. `FeedThrow`: los peces vuelan en arco hasta la boca y el gigante
  muerde al llegar.
- `foodPerPlayer` 48/77/96/115 → 64/102/128/154; el hambre se multiplica por el ritmo
  medio de pesca de los conectados (`FishingPower.rateFactor`).
- Se quitó `maxFeedDistanceStuds` (la validación ahora es la orilla).

**Prueba en Studio:** pescar 1 sardina en un muelle, ir al borde del cráter del lado
opuesto a la puerta: aparece Alimentar; con F entrega (+1 moneda, barra 1 %) y la Orca
furiosa se calma. Un Salpicón que ya estaba en aviso golpeó después de calmarla: ahora
el servidor lo anula si el gigante ya no está furioso.

**No verificado:** el arco de los peces de cerca, el botón en móvil.

## 2026-10-13 — Comida fija, 12 peces con rarezas, animaciones, efectos y sonidos

**Qué se hizo:**

- Comida fija por gigante (2,500 / 15,000 / 75,000 / 300,000); se quitó la escala por
  jugadores y por poder.
- 12 peces en 6 rarezas con modelo propio (cuerpo de dos tonos, ojos con pupila, cola en
  V, aletas, rayas, púas, espada, farolito con luz, brillo, arcoíris).
- Captura: chapuzón según rareza, salto con giro, coletazos sobre la cabeza, cartel con
  la rareza, trofeo en un haz de luz, onda y temblor; el pez se guarda en la canasta.
- Canasta de mimbre en la espalda que se llena y brilla coral llena.
- Tarjeta de captura con el pez en 3D girando; monedas que saltan y vuelan al contador.
- Peces lanzados al gigante giran, con whoosh y destellos al llegar.
- Sonidos nuevos (Tienda de creadores): aleteo, pop, rareza rara/épica/legendaria, whoosh.

**Prueba en Studio:** los 12 modelos de cerca; captura legendaria de prueba (haz dorado
y cartel "¡LEGENDARIO!"); pescar una sardina real (tarjeta "Común · Sardina · +1 comida",
canasta 1/20); alimentar en la puerta (+1 moneda); ráfaga de monedas al contador; los 6
sonidos nuevos cargan (IsLoaded = true).

**No verificado:** el lanzamiento al gigante de cerca, móvil, 2+ jugadores.

## 2026-10-13 — Camino a publicar (7 etapas) y Etapa 1: guardado

**Qué se hizo:**

- Backlog reorganizado en 7 etapas hasta publicar (guardado, ciclo de gigantes, tienda,
  ataques y seguridad, retención, pruebas, publicación).
- `Save/SaveSchema`, `Save/SaveStore`, `Save/SaveService`: DataStore con reintentos,
  bloqueo de sesión, autoguardado, guardado al salir y al cerrar; versión de datos.
- `PlayerData` ahora recibe los datos del guardado (`attach`/`snapshot`/`detach`), cuenta
  especies atrapadas y estadísticas; atributo `DataLoaded`.
- Pescar y entrenar esperan a que carguen los datos.

**Prueba en Studio:** el lugar no está publicado (PlaceId 0), así que corre en modo
memoria con su aviso; el jugador carga (`DataLoaded = true`) y juega normal. Prueba de
`SaveStore` desde el servidor: abrir → 0 monedas; escribir 77 monedas, un Atún, un pez
inexistente y 2 Peces dorados; volver a abrir → 77 monedas, 1 pez (el inválido se
descartó) y 2 Peces dorados.

**No verificado:** DataStore real y el bloqueo entre dos servidores (necesita publicar).

## 2026-10-13 — Etapa 2: despedida, descanso del volcán y llegada

**Qué se hizo:**

- `GiantService` con fases (`feeding`, `farewell`, `rest`, `arriving`) y su fin en tiempo
  del servidor; `GiantCycle` corre el ciclo y reparte el poder del descanso.
- `GiantCycleFx`: despedida (salto, giro, zambullida, ola) y llegada desde el fondo.
- Panel de hambre con la cuenta regresiva; la fila del enojo dice el poder por segundo.
- `CycleView`: carteles, lago que brilla con destellos, avisos al entrar o salir.
- Ruleta preparada (`inRoulette`); por ahora solo entra la Orca.

**Prueba en Studio** (con comida 2 y descanso 25 s solo para la prueba, ya restaurados):
pescar 2 sardinas y entregarlas en la puerta → "¡La Orca se llenó!", la Orca se
zambulle; descanso con cuenta regresiva, "+2 poder" cada segundo dentro del volcán
(0 → 50 de poder en 25 s); "¡Llega la Orca!" y vuelve a la fase de comer con la barra en 0.

**Corregido:** los títulos decían "Orca se llenó" sin artículo; el cartel del descanso
mostraba los minutos con decimales.

## 2026-10-13 — Guarida del descanso y kills

**Qué se hizo:**

- Guarida del descanso en el mapa: plataforma de basalto con borde brillante, sello y
  runas en el centro del lago, 8 rampas desde la punta de los muelles y pared invisible
  al borde. `RestArena` la muestra en el descanso y la esconde al terminar, subiendo a la
  punta de un muelle a quien siga abajo. El caldero de cada muelle se movió atrás.
- El poder del descanso solo se gana sobre la guarida (`WorldZones.isInRestArena`).
- Kills: `GiantService` registra quién le dio de comer; `GiantCycle` reparte +1 kill.
  `SaveSchema` v2 guarda `kills` y `killsByGiant`. Tabla de jugadores: Poder y Kills.
- `CycleView`: la guarida aparece con una ola, destellos, aviso a los 10 s, "+1 Kill".
- `AbyssRescue` solo rescata a quien nada (la guarida está apenas sobre el agua y el
  rescate se activaba estando de pie en ella).

**Prueba en Studio** (comida 2 y descanso 40 s solo para la prueba, ya restaurados): llenar
a la Orca desde la punta de un muelle → Kills 1; la guarida emerge con sus rampas; bajar
caminando y ganar +2 poder/s sobre ella (0 → 70); al terminar aparecí en la punta del
muelle y volvió la Orca.

## 2026-10-13 — La guarida solo existe al derrotar al monstruo

**Qué se hizo:** la guarida del descanso salió del mapa (`world/Isla.model.json`) a su
propio archivo, `world/GuaridaDescanso.model.json`, que Rojo pone en `ServerStorage`.
`RestArena` la clona hundida 16 studs al empezar el descanso, la hace emerger en 3 s,
abre las puntas de los muelles cuando las rampas ya llegaron y, al terminar, sube a
todos a un muelle, la hunde en 2.5 s y la borra. En Studio (modo edición) y durante la
pelea ya no se ve.

`default.project.json` cambió (nuevo `ServerStorage.GuaridaDescanso`): hubo que reiniciar
`rojo serve`.

**Prueba en Studio** (con un script temporal que llenaba a la Orca, ya borrado): antes de
derrotarla no hay guarida en el lago; al llenarse emerge con sus rampas, dura el descanso
y al terminar se hunde y desaparece; vuelve la Orca.

## 2026-10-13 — Etapa 3: tienda de la cabaña

**Qué se hizo:**

- `Config/Shop.luau` (10 cañas, 6 canastas, 6 botas), `Shared/Upgrades` (niveles,
  descripciones), `ShopService` (compra en el servidor, E en el mostrador, velocidad).
- `PlayerData`: `spendCoins`, `setUpgrade`; `SaveSchema` v3 guarda los niveles.
- Efectos: poder x caña en estanques y descanso, suerte en la tirada de peces,
  capacidad x canasta (HUD y canasta de la espalda), velocidad de las botas.
- Caña con color y brillo por nivel (`UIConfig.RodLooks`).
- Ventana de la tienda (`ShopWindow`, `ShopController`) y botón Tienda en el HUD.
- Cartel de la cabaña: "TIENDA".

**Prueba en Studio** (con un script temporal que daba monedas, ya borrado): abrir la
tienda desde el HUD, comprar Caña de madera (150), Botas de playa (200) y Canasta
reforzada (300): monedas bajan a 9.3K, la canasta pasa a 0/30, WalkSpeed 18 y niveles
Rod/Basket/Boots = 2.

**Corregido:** la lista ordenaba por nombre (Nivel10 antes que Nivel2); ahora por nivel.

## 2026-10-13 — Todo con E, alimentar de 1 en 1, estanques y cañas nuevos, terreno a su altura

**Qué se hizo:**

- Controles de PC: E lanza, E tira y E alimenta (F sigue sirviendo). Los botones grandes
  quedan para móvil y muestran la tecla "E" si hay teclado. Se quitaron los
  ProximityPrompts de los calderos (chocaban con E).
- Alimentar de 1 en 1: `FeedingService` saca un pez a la vez de la canasta (en ~4 s en
  total, entre 0.06 y 0.3 s por pez); cada pez vuela a la boca con su especie
  (`GiantFed` lleva el id) y paga sus monedas. Se corta si sales de la orilla o se
  llena el gigante; lo que quede sigue en la canasta. El gigante muerde como mucho cada
  0.45 s para no saturar de efectos.
- Estanques rehechos: anillo de piedra tallada con línea brillante arriba y en el agua,
  escalón exterior, círculo de runas bajo el agua, cristal flotante que gira (`PondFx`),
  nenúfares con flores, 4 faroles de piedra; desde x5 racimos de cristales y desde x20
  cristalitos en órbita. Bloqueado: el cristal se ve apagado y quieto.
- Cañas rehechas (`RodBuilder`, `RodOrnaments`, `RodParts`): contera, mango con amarres,
  carrete con platos, virolas y anillas; cada nivel con su estilo (nudos de bambú,
  hilos, coral y perla, acero, oro con gemas, cristal con núcleo y destellos, vetas del
  abismo con humo, lava con chispas, aletas del leviatán con burbujas). La tienda muestra
  la caña en 3D en cada fila.
- La tarjeta de captura pasó a la izquierda (tapaba ¡TIRA!).
- **Terreno a su altura real:** medido en Studio, el suelo se dibujaba 2 studs más alto
  que lo diseñado (la superficie queda en el centro del vóxel + ocupación); los estanques
  quedaban 2 studs hundidos y las piezas del suelo (bancos, bordes) enterradas.
  `TerrainBuilder` ahora resta medio vóxel: plaza a 6, borde del cráter a 30, mar a 2.

**Prueba en Studio** (con monedas y poder de prueba, script ya borrado): alturas medidas
(plaza 5.8, cráter 29.8, mar 2, estanques 6); estanques nuevos con sus bordes, runas y
cristales (de noche); las 10 cañas alineadas; pescar con E (lanzar y tirar: Sardina x6);
alimentar con E: 6 peces de 1 en 1, +6 monedas y la Orca se calmó.

**No verificado:** cómo se ve todo el mapa con el terreno 2 studs más bajo (playa,
muelles, cabaña), la caña nueva en la mano de cerca, móvil.

## 2026-10-13 — Etapa 4: avisos de ataque, límites y AFK

**Qué se hizo:**

- `RateLimit` (cubeta de fichas por jugador y remote) en CastRequest, ReelIn,
  FeedRequest y BuyUpgrade; avisa en la salida si alguien abusa, nunca expulsa.
- `FishingService.interrupt`: un Salpicón hace escapar el pez que picaba.
- `GiantAttacks`: si el círculo cae sobre ti, cartel "¡Sal del círculo rojo!" y cuenta
  regresiva grande.
- `AfkNotice`: aviso desde los 14 min sin moverse (Roblox expulsa a los 20).
- El terreno se arma al final del arranque del servidor: ya no sale la advertencia de
  `EstadoGigante` en los clientes.
- No se puede pescar desde el puente.

**Prueba en Studio:** sin advertencias al arrancar; parado en la puerta del cráter con la
Orca furiosa: cartel, cuenta regresiva y empujón. Recorrido con el terreno corregido:
plaza, estanques, muelle y puente se ven a su altura.


## 2026-10-13 — Etapa 5: retención

**Qué se hizo:**

- Datos v4 (`SaveSchema`): especies, tutorial, racha diaria, ajustes, insignias.
  `ProfilePublish` publica todo en atributos del jugador.
- Botones del HUD en cuadrícula (`HudButtons`): Tienda, Peces, Premio, Ajustes; ventanas
  con `Window` (una abierta a la vez).
- Colección de peces (`FishDex`) con modelos 3D y siluetas; aviso y monedas al descubrir
  una especie (25 a 25,000 según rareza) y 100K al completar las 12.
- Tutorial de 4 misiones con flecha y distancia sobre el destino (`TutorialGuide`).
- Premio diario de 7 días (100 → 2,500); se abre solo si toca cobrar.
- Insignias con aviso en partida (`Badges`); BadgeService cuando haya IDs.
- Ranking de Poder y Kills en los tableros de la entrada; cada 120 s con DataStore,
  cada 10 s sin él.
- Ajustes (música, sonidos, temblor, efectos reducidos) con SoundGroups `Musica` y
  `Efectos`; efectos reducidos baja las partículas al 35 % y apaga rayos de sol.
- Música con licencia de Roblox: isla "The Fisherman's Small Boat", cráter "Tension Repeat
  Drones 29", descanso "Work Like A Champion".

**Prueba en Studio** (script de prueba ya borrado): el premio diario se abrió solo y
pagó 100; peces descubiertos con aviso y monedas, la colección muestra los 3 y siluetas;
la misión 1 se completó y pasó a la 2 con flecha; los tableros mostraron el poder del
jugador; las 3 pistas cargan (2:38, 2:04, 2:25) y suena la de la isla; ajustes sin
errores en la salida.

**No verificado:** insignias reales y ranking global (requieren lugar publicado),
la misión de entrenar/comprar de punta a punta, móvil.

## 2026-10-13 — Monetización

**Qué se hizo:**

- `Config.Monetization`: precios sugeridos y efectos. IDs en `Assets.GamePasses` y
  `Assets.Products` (en 0 hasta crearlos en el Creator Hub).
- Pases: x2 Poder (todo el poder, también en el descanso), x2 Monedas (entrega y
  descubrir peces), VIP (etiqueta dorada, +20 % de suerte, premio diario x2).
- Productos: x2 de entrenamiento para todo el servidor (15 min que se suman, cartel con
  cuenta regresiva y quién lo compró), llenar al monstruo 25/50/75 % o entero
  ("siguiente monstruo"; si está descansando queda en fila), estanques 2–10 para siempre
  (también se ofrecen al apretar E en un estanque bloqueado).
- `Perks` (compartido) calcula todo desde atributos que pone el servidor.
- `Receipts`: idempotente con el PurchaseId guardado (v5 del guardado) y `saveNow`.
- Tienda de Robux: botón ancho "R$ Robux" en el HUD.
- `FishDex` ya no frena el arranque del cliente mientras cargan los datos.

**Prueba en Studio** (script de prueba ya borrado): pases VIP y x2 Poder marcados como
"¡Tuyo!" y etiqueta VIP sobre la cabeza; x2 del servidor con cartel arriba a la derecha;
estanque x8 "Abierto"; llenar 25 % subió la barra de 0 a 0.25 con aviso; comprar con ID 0
avisa "Disponible cuando el juego esté publicado"; sin errores en la salida.

**Nota:** Rojo duplicó en Studio los archivos nuevos (dos `Monetization`, dos scripts de
prueba) tras la reconexión; desconectar y reconectar Rojo lo limpió.

## 2026-10-13 — Monetización escalonada y elegir monstruo

**Cambios pedidos:** x2 Poder y x2 Monedas pasan de pases a mejoras que se acumulan
(x2, x4, x8... 10 niveles, desde R$ 3); el x2 del servidor sube de nivel con cada compra y
reinicia sus 15 min; "siguiente monstruo" ahora es elegir cuál sale después del descanso
(Orca, Minotauro, Dragón marino, Zorro de agua).

- `Config.Monetization` reescrito; IDs de productos en `Assets/Products.luau` (42).
- Guardado v5 con `levels` (Power, Coins); atributos `NivelPower` / `NivelCoins`.
- `ServerBoost` por niveles; `GiantChoice` (fila de elecciones) que la ruleta usa primero.
- Tienda: cada fila muestra el siguiente nivel y su precio (`RobuxOffers`, `RobuxCards.offer`).

**Prueba en Studio** (script ya borrado): Poder y Monedas suben de nivel y la tienda pasa al
siguiente precio; entrenamiento del servidor subió de nivel y reinició el tiempo (cartel
x16); elegir Orca aparece en la fila; los monstruos sin modelo dicen "Pronto"; 0 errores.

## 2026-10-13 — Interfaz estilo simulador

Pedido: interfaz parecida a una captura de un simulador (números grandes con contorno,
íconos 3D, botones de Robux a la vista). Decisiones del usuario: íconos 3D hechos en el
juego, barra del monstruo arriba pero más chica, atajos de Poder/Monedas y Llenar 25/50/75 %.

- `Interface/Style` (texto con contorno negro grueso, degradados, insignia de Robux),
  `Interface/IconModels` + `Icon3D` (moneda, gema, calavera, canasta, regalo, engrane,
  cofre y peces, girando en ViewportFrames).
- `Interface/Layout`: columna izquierda (Monedas, Poder, Peces, Kills con su
  multiplicador; misión del tutorial), columna derecha (aviso del entrenamiento del
  servidor, Tienda, Robux, atajos x Poder / x Monedas) y botones redondos en la barra de
  Roblox (Peces, Premio, Ajustes) con `GuiService.TopbarInset`. Todo se escala con el alto
  de la pantalla (escala 1 a 600 px de alto, entre 0.55 y 1.2).
- Barra del monstruo compacta: "comida / total" grande, etapa, enojo y chips +25/+50/+75 %.
- En pantallas táctiles la misión va abajo al centro (a la izquierda tapaba el joystick).
- Pescar/Alimentar bajó 35 px para no chocar con la columna derecha en teléfonos.

**Prueba en Studio:** PC y simulador de iPhone XR sin encimarse; tarjeta de captura bajo
la misión; 0 errores (script de prueba ya borrado; Rojo reconectado para limpiar copias).

## 2026-10-13 — Íconos de imagen estilo 3D

El usuario prefirió imágenes quietas estilo 3D (como su referencia) a los modelos que
giraban. 9 íconos generados con IA en Canva, recortados (fondo blanco a transparente) y
juntados en una hoja de 3x3 subida con el Gestor de recursos (`Assets.UI.IconSheet`).
`Interface/Icons` los usa y deja `Icon3D` como reserva. Probado en Studio: se ven nítidos.

## 2026-10-13 — Títulos, amigos, códigos, regalo del grupo y canastas

- **Sobre la cabeza** (`Interface/Overhead`): pirámide dorada con las kills, "VIP", título
  según el poder (`Config.Social.titles`, 10 rangos de Novato a Dios del Mar, cada uno con
  su degradado) y el nombre. Medido en studs (se ve del tamaño del mundo). Reemplaza el
  nombre de Roblox y el antiguo `VipTags` (borrado).
- **Impulso de amigos** (`Social/FriendBoost`): +10 % de poder y monedas por amigo en el
  servidor, hasta +50 %; cartel abajo a la izquierda.
- **Códigos** (`Social/Codes`, lista solo en el servidor `Social/CodeList`): GIGANTES,
  ORCA, LANZAMIENTO. Ventana con el boleto en la barra de Roblox. Se guardan los usados.
- **Regalo del grupo** (`Social/GroupReward`): estar en el grupo + 15 min en la partida →
  1,500 monedas y 15 min de x2 poder, una vez. Falta poner `Config.Social.group.groupId`.
- **Impulso personal** x2 de poder (`boostUntil` en el guardado) para códigos y grupo.
- **Canastas** (`Effects/BasketBuilder` + `BasketStyles`): 6 estilos según la canasta
  comprada (mimbre, reforzada, pescador, baúl, red, abismo), al tamaño del avatar.
- 4 íconos nuevos (códigos, amigos, grupo, pirámide); hoja de íconos 4x4 (v2).

**Prueba en Studio** (scripts ya borrados): título CAPITÁN con 3 kills y VIP; +20 % de
amigos y los multiplicadores x1.2 / x2.4; código canjeado, repetido y falso; las 6
canastas; ventana del grupo en "Pronto" sin grupo; 0 errores.

## 2026-10-14 — TIENDA, MEJORAS y regalos estilo simulador

Rediseño pedido con 4 capturas de referencia (simulador de pirámides):

- **Ventanas** (`Menus/Window`): título enorme con contorno sobre la esquina, panel oscuro
  (o de madera) con borde negro grueso y X roja. Se escalan con el alto de la pantalla
  (`Window.fit`), así en un monitor de 1440 px no se ven chiquitas.
- **TIENDA** (antes "Robux"; se quitó ese botón): banner verde "¡Impulsa el entrenamiento
  del servidor!" (x1 → x2, tiempo en rosa, precio) y secciones con tarjetas de colores con
  rayos que giran (`OfferCard`, `ShopParts`): Para siempre (Poder, Monedas, VIP), Llenar
  al monstruo, Elige el siguiente monstruo y Estanques.
- **Regalos** (`GiftPicker`, `server/Monetization/Gifts`): botón rosa en Poder, Monedas,
  VIP y estanques. Se elige a otro jugador del servidor y se le compra SU siguiente nivel;
  el servidor anota el regalo 2 min (remote `SetGift`) y el recibo se lo entrega a él. Si
  se fue, se lo queda quien pagó. VIP se regala con el producto `GiftVIP` (queda en
  `save.gifts`, guardado v6).
- **MEJORAS** (antes tienda de la cabaña): filas de madera con la caña en 3D (ahora en
  diagonal) o el ícono, nivel, precio en monedas (verde) y en Robux (morado, productos
  `Rod/Basket/Boots<n>`). Se abre con el botón Mejoras o con E en el mostrador.
- **Premio diario**: 7 tarjetas de regalo con rayos (hecho en verde con ✓, hoy dorado) y
  botón ¡RECLAMAR!.
- `server/Monetization/Grants` separa qué da cada producto; `Receipts` queda con el cobro.
- Hoja 2 de íconos (12 nuevos + rayos), subida con el Gestor de recursos.

**Prueba en Studio** (scripts ya borrados): TIENDA completa, ventana de regalar ("No hay
más jugadores"), premio cobrado, MEJORAS en las 3 pestañas; productos entregados sin
comprar: Rod3, Boots4 (velocidad 23), GiftVIP (etiqueta VIP), Pond3, Basket2 (30 peces),
Power1 (x2). 0 errores.

## 2026-10-14 — Listo para 40–50 jugadores: red, rendimiento, móvil y balance

Revisión a fondo con tres revisores (servidor, cliente, diseño/móvil) y arreglos:

- **Comida que escala**: el monstruo pide `loadsPerPlayer × 2.75 × capacidades de los
  activos` (mínimo en `food`). Antes 50 jugadores con la canasta llena llenaban la Orca
  en ~4 s al llegar. Kill solo con ≥0.5 % de la barra. Descanso 60–120 s según jugadores.
- **Red**: la canasta se entrega por lotes de 0.25 s (máx. 4 s) y GiantFed va agrupado
  por alimentador (antes un evento a todos por pez: hasta ~90k envíos/s). La canasta se
  guarda como conteos por especie (guardado v7). Cada cambio publica solo su atributo;
  el leaderstat de poder cada 3 s. Amigos con GetFriendsAsync (antes n² llamadas).
  Guardado escalonado. Los jugadores no chocan entre sí.
- **Seguridad**: regalo del grupo sin doble cobro, distancia al estanque comprobada en
  el servidor, ranking sin ceros de jugadores cargando, pases con reintentos.
- **Cliente**: niveles de detalle por distancia (cañas, canastas, capturas), sonidos
  lejanos descartados, peces volando con tope (20, o 6 en calidad baja), una sola vuelta
  de render para cañas y vuelos, luz/espuma/gigante actualizados menos veces, fugas de
  conexiones al salir jugadores. Calidad baja automática en teléfonos y si baja de 35 FPS.
- **Móvil**: PESCAR/¡TIRA! junto al botón de salto, botones de 44 px o más, ventanas más
  grandes en pantallas táctiles, TIENDA en 2 columnas si es angosta, columna derecha
  centrada, se quitó la lista de jugadores de Roblox (tapaba TIENDA/MEJORAS).
- **Balance**: estanques 6–10 más caros, cañas 8–10 más baratas (ver `docs/balance.md`).

**Prueba en Studio** (scripts ya borrados): canasta de 160 → la Orca pidió 660 y se
entregó en ~4 s; etapa 2 alcanzada; 0 errores. Los modelos del Minotauro (acostados al
importar) se descartaron: los monstruos se harán con Meshy al final.

## 2026-10-15 — Orca etapa 1 con el modelo de Meshy

**Qué se hizo:**

- El modelo de Meshy (orca con armadura dorada, corona de coral y aleta de cristal) se
  redujo en Blender de 179,664 a 9,600 triángulos, con el origen en la base y texturas de
  1024 (color, normales, rugosidad y metalicidad) embebidas en `assets/blender/OrcaE1.fbx`.
- Importado en Studio como `ServerStorage.OrcaE1`; el anterior quedó como
  `OrcaE1_Respaldo`. IDs nuevos en `Assets` (malla y las 4 texturas).
- Atributo `GiroY` (grados) en el modelo de ServerStorage: `GiantTemplates` lo aplica al
  pivote para corregir modelos que llegan mirando al revés. La orca usa `GiroY = 180`.
- La luz roja del fondo del cráter (`BrilloDelAbismo`) ahora es más suave y menos
  saturada y está más honda: teñía de naranja al gigante.

**Qué se rompió:** nada. Probado en Studio: la orca mira a los jugadores.

**Qué sigue:** guardar/publicar el lugar (el modelo vive en el .rbxl). Las etapas 2–4
siguen usando el modelo escalado hasta tener los suyos.


## 2026-10-15 — La orca nada, salta y abre la boca para comer

**Qué se hizo:**

- OrcaE1 con huesos (`tools/blender/rig_orca.py`): Raiz, Cabeza, Mandibula, cola en 3
  partes, aletas pectorales y puntos Boca, Espiraculo y Dorsal. Pesos calculados por
  posición; se importó en Studio con "Mantener huesos de influencia cero".
- Dos módulos en `ReplicatedStorage.Shared.Orca`:
  - `OrcaMotion` (con Path, Steer, Feeders y Rig): nada por el lago en un recorrido que
    sale de la hora del servidor (todos la ven igual), sale a respirar, salta del agua
    con una vuelta en tramos al azar y, cuando alguien le da de comer, va a la orilla
    de quien alimenta, saca la cabeza y abre la boca (muerde con cada pez). Anima cola,
    cabeza, mandíbula y aletas con Bone.Transform.
  - `OrcaFx` (con Trails): burbujas turquesa, estela de espuma, brillo de la aleta de
    cristal, destellos dorados en la boca, chorro al respirar, salpicadura y ola al
    saltar y caer (con temblor cerca), llamados de orca. Usa los sonidos del juego.
- `Giant/OrcaSwim` une ambos con el cliente; GiantBody hace nadar a cualquier modelo con
  hueso Raiz. Los peces vuelan hasta la boca aunque se mueva (FeedFlights sigue la meta).
- GiantTemplates: con huesos, la caja y el PivotOffset salen de la pieza (el importador
  dejaba el pivote girado 90° y la orca quedaba parada).

**Qué se rompió:** al principio la orca nadaba de punta (ejes girados); corregido.

**Qué sigue:** guardar/publicar el lugar (OrcaE1 nuevo en ServerStorage). Ajustar ritmo
de saltos o profundidad si hace falta al verla con jugadores.

## 2026-10-15 — Volcán más grande, agua nueva y la orca en sus 4 etapas

**Qué se hizo:**

- Cráter más grande y hondo (`WorldLayoutData`): lago de 190 de radio, fondo a -90,
  centro en (0, 520); se quitó el pedestal y las rocas del centro (estorbaban al crecer).
  El terreno baja más solo donde hace falta (TerrainBuilder por bloque). Guarida de
  descanso de 64. Piezas regeneradas con `tools/generar_isla.py`.
- Agua del cráter (`Ambient/CraterWater` y `CraterVents`): jade turquesa con poco reflejo
  al entrar, motas bioluminiscentes, espuma y vapor contra el acantilado y 5 fumarolas
  con brillo de lava, columnas de burbujas y burbujones. Se quitó la luz roja del centro.
- Orca en 4 etapas de Meshy (bebé, joven, adulta, anciana): `procesar_meshy.py` +
  `rig_orca.py` con columna de 4 huesos en la cola y pesos suaves. ServerStorage.OrcaE1..E4.
- Animación nueva: onda de nado de la cabeza a la cola, resortes en altura/cabeceo/giro,
  planeo entre aletazos, aletas con retraso y timón, mordidas. Un script por etapa en
  `Shared/Orca/Etapas` (OrcaBebe, OrcaJoven, OrcaAdulta, OrcaAnciana) con su ritmo, voz y
  trucos: saltitos, persigue su cola, giros, asomarse, saltos con giro, coletazos,
  aletazos, zambullidas, rugido y emerger (Tricks/Jumps, Surface, Show). Los trucos se
  sincronizan con la hora del servidor (todos ven lo mismo).

**Qué se rompió:** nada visto en Studio (0 errores; probadas las 4 etapas y comer).

**Qué sigue:** guardar/publicar el lugar (los 4 modelos viven en el .rbxl).

## 2026-10-15 — Volcán con montañas, lago más hondo y agua turquesa

**Qué se hizo:**

- Forma del cráter en `server/World/CraterShape` (y `altura_crater` en el generador):
  plataforma poco honda junto al acantilado, pozo de 150 de hondo en el centro
  (`WorldZones.lakeFloor`), paseo plano de 30 y montañas de basalto de hasta 70 de alto
  con picos filosos, cumbres oscuras y vetas de lava; se abren en la puerta del puente.
  El terreno sube o baja por bloque solo donde hace falta.
- Agua: el agua de Roblox mostraba la bruma del cielo (beige) donde no veía fondo
  cerca. Ahora hay 7 discos oscuros apenas bajo la superficie (`CraterWater`) que dan
  el degradado de turquesa en la orilla a azul casi negro en el centro; el agua es más
  clara (0.82) y el gigante se ve entero cerca de la superficie. Menos bruma naranja
  en el cráter (`SkyMoods`). Fumarolas brillando sobre el abismo.
- Las orcas nadan un poco más arriba en su ciclo de respirar.

**Qué se rompió:** nada visto en Studio.

---

## 2026-10-15 — Lago de 400 de hondo que se vacía en el descanso

**Qué se hizo:**

- Lago del cráter de 400 de hondo con fondo plano de radio 75 (`craterFloor`,
  `craterFlatRadius`); agua oscura (azul petróleo) en el cráter.
- Arreglo: `IslandShape` solo ponía el fondo del cráter donde quedaba más alto que el
  fondo del mar, así que el pozo nunca pasaba de unos 18 de hondo. Ahora dentro del
  acantilado manda siempre el cráter.
- Descanso: el volcán se vacía (`client/Ambient/CraterDrain`, 8 s, con remolino,
  retumbo y temblor) y la guarida queda fija en el fondo (`restArenaTop` −386).
  "IR A LA GUARIDA" lleva al fondo cuando ya se vació. Al terminar, `RestArena.hide`
  regresa a la orilla de la puerta (junto al puente) a quien siga en el pozo y el agua
  vuelve a subir (6 s) mientras llega el siguiente monstruo. Atributo `VolcanVacio`.
- `AbyssRescue` no rescata a quien camina por el fondo vacío; `CycleView` usa el
  atributo para los avisos y los destellos ("¡El agua vuelve al volcán en 10 s!").

**Qué se rompió:** `fillSurface` recorría las tablas de `ReadVoxels` con `for in`
(traen `Size`) y fallaba; se cambió a bucles numéricos. Probado en Studio: vaciar,
entrenar en el fondo, regreso a la orilla y llenado, 0 errores.

**Qué sigue:** modelos de Meshy del Dios del Volcán y el Rey del Mar cuando estén.

---

## 2026-10-15 — Trajes de malla: Marinero para todos, Dios del Volcán y Rey del Mar

**Qué se hizo:**

- Los tres modelos de Meshy, reducidos y con esqueleto humanoide (`tools/blender/rig_traje.py`,
  medidas en `trajes.json`; el tridente va entero a la mano derecha). En ServerStorage como
  `TrajeMarinero`, `TrajeDiosDelVolcan` y `TrajeReyDelMar`; IDs en `Assets`.
- `Social/MeshOutfit`: el traje se suelda al HumanoidRootPart, escalado para que su cadera
  coincida con la del cuerpo, y el cuerpo queda invisible. Todos son Marinero; con el pase
  se ve el traje del pase. Si falta el modelo, `Outfits` usa los trajes de piezas de antes.
- Animación para todo el servidor (`client/Trajes`): cada cliente mueve los huesos de todos
  copiando el giro de cada parte del cuerpo escondido (animaciones de Roblox, pose de la caña,
  emotes). Encima, un script por traje (`Shared.Trajes.Estilos`): Marinero alegre y saluda;
  Dios pesado, inclinado, con humo y chispas del volcán, lava en las manos y brillo en el pecho,
  saca músculo y ruge; Rey erguido, tridente que brilla y gotea, burbujas, alza el tridente.
- Vitrinas (`Social/Showcase` + `client/Trajes/Vitrinas`): a los lados de la aparición, pedestal
  de mármol y oro con el traje en grande animado, cartel con nombre, precio y ventajas. E abre
  la compra; si ya lo tiene, E dice Ponerte o Quitarte (atributo `TrajeElegido`).
- La caña sale de la mano del traje; el cartel de la cabeza sube con los trajes altos.

**Qué se rompió:** en el cliente la vitrina giraba sobre el pivote del Model (acostado por el
importador): ahora gira sobre el marco medido con los huesos. Probado en Studio: los tres
trajes, caminar, vitrinas, Ponerte/Quitarte/Comprar; 0 errores.

**Qué sigue:** crear los pases en el Creator Dashboard y poner sus IDs en `Assets.GamePasses`
(con ID 0 la vitrina avisa que estará disponible al publicar).

---

## 2026-10-15 — Trajes sin estirarse, auras, dragón que vuela y volcán de lava

**Qué se hizo:**

- Texturas de los trajes y del dragón hechas de nuevo (`tools/blender/hornear.py`): UVs
  nuevas y horneado desde el modelo original (color, rugosidad, metal y normales). Las de
  antes se rompían al reducir la malla.
- Trajes sin estirarse: cada pedazo sigue a un solo hueso, con cortes planos en las
  articulaciones y tapas solo en los huecos nuevos (`rig_traje.py`).
- Auras de los trajes de pase (`Shared/Trajes/Aura`): Dios del Volcán envuelto en lenguas de
  fuego animadas, brasas, halo naranja y onda de calor en el piso; Rey del Mar con medialunas
  de agua que giran, burbujas, destellos, fuentecitas y halo azul. Contorno brillante sin
  relleno. Texturas de partículas propias (`tools/particulas/gen.py`, IDs en
  `Assets.Particles`): las de Roblox (fire_main) casi no se veían.
- Dragón marino (4 etapas) con huesos de alas, patas, cuello, cola y mandíbula
  (`rig_dragon.py`) y vuelo por código (`Shared/Dragon`): aletea, se ladea en las curvas,
  planea, ruge, escupe fuego, hace picadas y volteretas; para comer se queda flotando frente
  a quien lo alimenta y muerde. Cada etapa aletea distinto (la cría rápido, el anciano lento
  y pesado).
- Volcán de lava para el dragón (`CraterLava`): el lago es lava con costra, luz, brasas,
  burbujas y humo; baja en el descanso y sube cuando llega.
- Alimentar más satisfactorio (`FeedPop`): estela del color de la rareza, onda y destellos
  en la boca, "¡ÑAM! xN" que cambia y salta con el combo, mordida más aguda y temblor en los
  combos altos.

**Qué se rompió:** el traje del jugador a veces llegaba por partes y se quedaba sin rig ni
efectos: el servidor anota cuántos huesos trae (`TrajeHuesos`) y el cliente espera a
tenerlos. El fuego del dragón quedaba atrás (vuela más rápido que el chorro): ahora viaja
pegado a la boca. Cinco IDs de `Assets` leídos a ojo estaban mal: corregidos y comprobados
contra ServerStorage. Probado en Studio: los tres trajes, las 4 etapas volando, alimentar,
descanso y llegada con la lava; 0 errores nuestros.

**Qué sigue:** guardar el lugar en Studio (los modelos nuevos están en ServerStorage) y
crear los pases en el Creator Dashboard.

---

## 2026-10-15 — Panel admin: jugadores, monstruos por etapa y reiniciar

**Qué se hizo:**

- Arriba del panel se elige a quién se le aplican las órdenes (`AdminTarget`): "Yo" o
  cualquier jugador del servidor, con sus números en vivo (poder, monedas, kills,
  renacimientos, peces). Todo lo que se podía hacer a uno mismo ahora se puede hacer a otro;
  además "Ir con él" y "Traerlo".
- Tres pestañas (`AdminPages`): Jugador, Monstruos y Eventos. Los botones van en una grilla
  de 4 columnas iguales que salta de renglón (`AdminRows`): nada se sale del panel.
- Monstruos por etapa: cada monstruo con Etapa 1..4 (`giant` = "id:etapa"); si está
  comiendo cambia al momento en esa etapa (`GiantService.reset(def, etapa)`), si no, llega
  después. Barra (+25 %, +50 %, llenar) y descanso (terminar, +1 min).
- Reiniciar como jugador nuevo (`Admin/AdminReset`, pide tocar dos veces): "Progreso" deja
  todo en cero pero conserva lo comprado con Robux y los ajustes; "Todo" deja la cuenta como
  nueva (solo quedan los recibos de compras). Limpia tutorial, misiones, regalos por tiempo,
  lo hace reaparecer y guarda al momento.
- Servidor: `AdminCommands` reparte entre `AdminPlayer` (órdenes a un jugador) y
  `AdminWorld` (monstruo, barra, descanso, eventos). `AdminCommand` lleva el UserId del
  elegido; el aviso dice a quién se le aplicó.

**Qué se rompió:** nada. Probado en Studio con servidor y 2 jugadores: cambiar números,
peces y reiniciar al otro jugador, traerlo, monstruo en etapa 3, ir al volcán.

**Qué sigue:** nada pendiente del panel.

---

## 2026-10-16 — Cartel de la cabeza con insignias y vitrinas en la zona de entrenamiento

**Qué se hizo:**

- Cartel sobre la cabeza (`Interface/OverheadBadges`): monstruos llenados, VIP y Premium
  ahora van en pastillas redondas con fondo en degradado, marco y brillo. El colmillo se
  cambió por un ícono nuevo (monstruo panzón con un pez, hoja 3 de íconos); VIP lleva la
  corona sobre oro y Premium su ícono sobre fondo oscuro. Con efectos reducidos el marco se
  queda (solo se quitan los contornos del texto).
- Zona de entrenamiento más grande: plaza de 96 a 108 de radio y anillo de estanques de 70 a
  80. Se corrieron hacia afuera la aparición (126), la tienda (128), el campamento (130), las
  colinas cercanas y las palmeras/arbustos. Isla regenerada con `tools/generar_isla.py`.
- Las vitrinas del Rey del Mar y el Dios del Volcán pasaron a la zona de entrenamiento, a
  los lados del camino que baja de la aparición, más grandes (traje de 12 de alto).

**Qué se rompió:** nada. Probado en Studio: cartel con VIP y Premium, vista de la zona.

**Qué sigue:** la tienda con la foto de referencia.

---

## 2026-10-16 — Insignias en un solo marco y PERSONAJES en la TIENDA

**Qué se hizo:**

- Cartel de la cabeza: monstruos llenados, VIP y Premium ahora van todos dentro de una
  sola placa (azul noche, marco de oro y brillo) separados por líneas finas; la placa se
  ajusta a lo que se muestra.
- TIENDA más ancha con la sección PERSONAJES arriba (como la referencia): una tarjeta ancha
  por traje de pase (Dios del Volcán naranja, Rey del Mar azul) con rayos, el personaje en
  3D a la izquierda saliendo por arriba (copia de su vitrina), nombre grande, ventajas en
  dos líneas sacadas del pase, etiqueta inclinada "x2 Kills", botón verde con el precio o
  Equipar/Desequipar si ya lo tiene, y el regalo rosa. VIP sigue en "Para siempre".
- `Social/OutfitChoice` + remote `ElegirTraje`: ponerse o quitarse el traje desde la
  tienda (las vitrinas usan lo mismo).
- Los dos trajes se pueden regalar (`GiftReyDelMar`, `GiftDiosDelVolcan`; crear los
  productos en el Creator Dashboard y poner sus IDs en `Assets.Products`).

**Qué se rompió:** el personaje de la tarjeta salía acostado o vacío: ahora espera a que la
malla de la vitrina llegue y la pone de pie con el marco medido por los huesos. Probado en
Studio: cartel con VIP y Premium, tienda, Equipar/Desequipar.

---

## 2026-10-16 — VIP dorado y juego con mando (Xbox / PlayStation) y móvil

**Qué se hizo:**

- Cartel de la cabeza: sin corona; "VIP" en oro con degradado (claro arriba, naranja
  abajo) y contorno café.
- `Interface/InputHints`: sabe si se juega con teclado, mando o táctil (lo último que se
  tocó) y nombra los botones: E en PC, X en Xbox, Cuadrado en PlayStation. Las insignias de
  Pescar/Alimentar/¡TIRA! muestran la tecla o el dibujo del botón del mando (lo da Roblox,
  de Xbox o de PlayStation) y no se ven en táctil. Los avisos y la misión del tutorial dicen
  el botón correcto (en táctil no se dice tecla).
- Mando en el juego: lanzar y alimentar con X (Cuadrado) o R2; recoger con X, A o R2.
- `Menus/GamepadNav`: Y (Triángulo) entra al menú del HUD y la marca dorada recorre los
  botones (Tienda, Mejoras, Misiones...); A aprieta; B (Círculo) cierra la ventana o sale.
  Al abrirse una ventana la marca entra a su primer botón y no se sale de ella; al cerrarla
  vuelve al botón del HUD. Con mando, arriba de la columna derecha dice "Y Menú".
- `Window.onAnyChange` y `HudButtons.all` para que el mando sepa qué hay en pantalla.

**Qué se rompió:** nada. Probado en Studio: VIP dorado, marco dorado de la selección, Y del
emulador de mandos. Falta probar con un mando real y en un teléfono.

---

## 2026-10-16 — MEJORAS nueva con íconos, avisos sin amontonarse, pack de 19 R$ y Renacer

**Qué se hizo:**

- 48 íconos de equipo hechos en Canva (20 cañas, 14 canastas, 14 botas), en tres hojas
  subidas a Roblox; `Interface/GearIcons` pinta el de cada nivel y da su color de rareza.
- MEJORAS rehecha: pestañas con el ícono de lo que tienes y "Nv 3/20"; a la izquierda el
  panel grande del nivel elegido (`UpgradeDetail`: ícono sobre rayos, ahora → siguiente,
  barra de cuánto falta, botones de monedas y Robux); a la derecha la cuadrícula de todos
  los niveles (`UpgradeCard`: equipada, tienes, ¡SIGUIENTE! que late, bloqueada con
  precio). Tocar una tarjeta la muestra; solo se compra la siguiente. `Upgrades.stats`.
  Las miniaturas 3D viejas (RodPreview, GearPreview) quedaron sin uso y se movieron a
  `_to_delete/` (fuera del repo).
- Avisos: las tarjetas grandes (`ToastBanner`) ya no salen en medio de la pantalla sobre el
  cartel de la cabeza; van arriba bajo el panel de hambre, de a una y en fila, con ícono
  sobre rayos, brillo que cruza, chispas y desvanecido. Máximo dos cosas a la vez. "Nuevo
  en tu colección" junta el pez y las monedas en una sola tarjeta. Efectos en `ToastFx`.
- Cartel de la cabeza: el ícono de Premium ahora es la imagen que trae Roblox (el carácter
  de la fuente no se dibujaba).
- Pack de inicio a 19 R$ y con botas nivel 4 (también en `Grants`). Ventana nueva: regalo,
  sello de descuento que se mece (sale de los precios en Robux de MEJORAS: 93 R$ el equipo
  por separado), cinco tarjetas con los íconos del equipo, precio tachado y botón que late.
- Regalos por jugar: botón grande en la columna izquierda (`PlaytimeEntry`), rosa con la
  cuenta regresiva; listo se pone verde, late y el regalo se sacude.
- Renacer: tarjetas con pez y "+35%", barras con ícono que se ponen verdes, qué se
  reinicia y qué te quedas con íconos, y el botón late cuando alcanza (`RebirthParts`).

**Qué se rompió:** nada. Probado en Studio: MEJORAS (compra de la caña 2 incluida), avisos
en fila, Premium, pack de inicio, Renacer y el botón de regalos. Hay que poner el precio del
producto PackInicio en 19 R$ en el panel de Roblox.

**Qué sigue:** rediseñar las ventanas de premios diarios y regalos por jugar con la foto de
referencia.


---

## 2026-10-16 — Retratos de Orca y Dragón, panel de hambre nuevo y botones arriba a la derecha

**Qué se hizo:**

- Íconos nuevos de la Orca y el Dragón marino hechos en Canva describiendo sus modelos 3D
  (orca azul noche con marcas cian y corona de coral; dragón azul con cuernos blancos y
  bigotes). Reemplazan sus celdas en la hoja 2 (nuevo ID): se ven en el retrato del panel de
  hambre y en la tienda (elegir el siguiente monstruo).
- Panel de hambre rehecho: placa azul noche con marco dorado (`Interface/HungerLook`),
  medalla redonda del retrato con aro del color de la etapa, "Etapa 2/4", barra con brillo y
  carne. Los botones +25/+50/+75% llevan el precio en Robux adentro (sin insignia suelta).
- Los botones redondos (Premio, Peces, Códigos, Grupo, Ajustes, Admin) pasaron a la esquina
  derecha de la barra de Roblox y son más chicos (36 px en PC, 30 en táctil); el panel de
  hambre sube a la barra si cabe entre los botones de Roblox y los nuestros.
- Arreglo: el Zorro de agua (`released = false`) podía salir en la ruleta y venderse en
  "elegir el siguiente"; `GiantPool.available` ahora lo deja fuera.
- Revisión de balance y retención (simulación de un jugador nuevo); los hallazgos y
  propuestas quedan para decidir (entrega por canasta, comida según jugadores, estanques
  por poder, misiones jugables solo).

**Qué se rompió:** nada. Probado en Studio en PC y con el simulador de iPhone XR.

**Qué sigue:** decidir los cambios de balance propuestos.

---

## 2026-10-16 — Los trajes ya no se cortan al caminar

**Qué se hizo:**

- Los trajes (Marinero, Dios del Volcán, Rey del Mar) estaban hechos de piezas rígidas:
  al doblar codos y rodillas se abría un hueco y se veía la tapa del corte. Nuevo
  `tools/blender/suavizar_traje.py`: borra las tapas, une los cortes y reparte los pesos
  (mitad y mitad en las costuras, transición suave en codos, muñecas, rodillas y tobillos;
  el tridente sigue rígido en la mano). Reimportados en Studio; los viejos quedaron en
  `ServerStorage.Respaldos` como `Traje*_rigido`. IDs nuevos en `Assets`.
- Botones de llenar más chicos con la etiqueta verde de Robux; la ruleta vuelve a tener a
  todos los monstruos.
- Paquete de balance y retención (ver `docs/balance.md`): entrega por canasta, comida
  según el servidor (la Orca se llena en ~6 min), estanques por kills o poder, renacer con
  x1.25 permanente, misiones jugables solo, premios de colección, ruleta gratis cada 4 h.

**Qué se rompió:** nada. Probado en Studio (correr, ruleta, misiones, panel de hambre).
Hay que guardar el lugar en Studio para que los trajes nuevos queden en ServerStorage.

**Qué sigue:** modelos 3D del mapa y del equipo.

---

## 2026-10-16 — Mapa y equipo con modelos 3D de Blender

**Qué se hizo:**

- `tools/blender/props_mapa.py`: palmeras (3), arbustos con flores (2), rocas (3), crestas de
  basalto del volcán (2) y los bordes de mármol con losa y filo de oro de los estanques (normal
  y sagrado), low-poly con una textura de paleta. En Studio: `ServerStorage.PropsMapa`.
- `server/World/PropDresser` + anclas en `generar_isla.py`: al empezar, 411 piezas del mapa se
  cambian por los modelos 3D (las primitivas quedan de respaldo si falta el modelo).
- `tools/blender/equipo_base.py` + `client/Effects/MeshKit`: la caña de la mano lleva mango de
  corcho, carrete con hilo y platos con rayos y anillas redondas; las canastas, cuerpo y borde
  redondeados. En Studio: `ReplicatedStorage.ModelosEquipo`.

**Qué se rompió:** nada. Probado en Studio.

**Qué sigue:** guardar el lugar en Studio (los modelos viven en el .rbxl). Las botas no se
ven en el personaje (el traje las tapa), así que no llevan modelo.


---

## 2026-10-16 — Ruleta de simulador, racha, volcán en orden, carteles y trajes sin estirarse

**Qué se hizo:**

- Vuelven los íconos viejos de la Orca y el Dragón. Trajes: solo se cosen codos, muñecas,
  rodillas y tobillos (hombros y cadera vuelven a ser piezas: ya no se estira la ropa).
- Carteles de estanques como los simuladores ("25x" enorme con degradado y franja de luz).
- Ruleta nueva: rueda redonda (RuedaRuleta/PunteroRuleta) con %, giros guardados, Comprar 1
  (24 R$) y Comprar 5 (80 R$), rueda grande en el mundo junto a la aparición.
- Retención: giro gratis cada 6 h, +1 giro cada 15 min jugando (hasta 4), +1 giro con el
  diario (+3 el día 7) y racha diaria +10% monedas y poder por día (hasta +100%).
- Volcán: fondo a -150 (antes -400); el descanso cuenta 5 s después de ver la guarida y, tras
  la ruleta, el cráter se llena de agua o lava antes de que llegue el monstruo.
- Alimentar más rápido al principio (6 peces/s, canasta en 5 s), cartel de la cabeza más alto,
  brillo azul al entrenar como viñeta pareja, ventanas que caben en el teléfono.

**Qué se rompió:** el lugar abierto era una recuperación automática sin publicar (sin
DataStore): se guardó como `respaldo_lugar_2026-10-16.rbxl` (fuera de git) y hay que
publicarlo sobre el juego real. Ver `docs/lanzamiento.md`.


---

## 2026-10-16 (2) — Progresión más larga, ventanas para teléfono e íconos de productos

**Qué se hizo:**

- Estanques rebalanceados (`Config/Progression`): x1 → x1.5 → x2 → x3 → x4 → x6 → x8 → x12
  → x16 → x25 (sagrado x50), con kills y poder que suben más rápido. Simulado: estanque 2 a
  los ~7 min, 4 el día 2, 6 el día 5, 8 el día 12 y 10 cerca del día 29. Renacer más caro
  (crece x2.8 en monedas y x3 en poder). Detalle en `docs/balance.md`.
- Ventanas: la escala nunca deja que se salgan de la pantalla (`WindowLayout`); en táctil
  Renacer, Misiones y Grupo son anchas en dos columnas. Probado en el simulador iPhone XR
  (también Diario y Tienda ya caben).
- 73 íconos 512x512 para productos y pases en `assets/ui/productos/` (estilo Canva de la
  orca/zorro, con rayos de color y etiqueta). Script: `tools/productos/build.py`.

**Qué se rompió:** nada.

**Qué sigue:** publicar el lugar, crear los productos en el Creator Hub con sus íconos y
pasarme los IDs; poner el ID del grupo en `Config/Social`.


---

## 2026-10-16 (3) — Lugar guardado, íconos nítidos y pases más fuertes

**Qué se hizo:**

- El lugar más nuevo (el que estaba abierto como `respaldo_lugar_2026-10-16.rbxl`) se guardó
  como `PescaYAlimentaGigantes.rbxl` en la carpeta del proyecto (fuera de git).
- Íconos de productos rehechos desde fuentes escaladas x4 con ESRGAN (`assets/ui/iconos/hd/`,
  `tools/productos/upscale.js`): ya no se ven pixeleados.
- Lo pixeleado en Studio con el simulador de teléfono es del simulador: dibuja a la
  resolución lógica del aparato (iPhone XR 896x414) y la estira. En "Dispositivo actual" y en
  un teléfono de verdad las letras se ven nítidas.
- Pases: Rey del Mar pesca x2 (y x2 de fuerza), alimenta x2 y da x2 kills. Dios del Volcán
  pesca ultrarrápida (pican x5 y de un toque), alimenta x4 y da x4 kills
  (`feedSpeed` en `Config/Monetization`, `Perks.feedMultiplier`, `FeedingService`).

**Qué se rompió:** nada; lint limpio.


---

## 2026-10-16 (4) — Faro nuevo en 3D

**Qué se hizo:**

- `tools/blender/faro.py`: faro caricatura low-poly (2654 triángulos, 39 de alto): zócalo de
  piedra con rocas, torre a franjas rojas y blancas con rebordes, ventanas, puerta de madera
  con escalón, balcón con ménsulas y baranda, linterna abierta y cúpula roja con punta de oro.
  En Studio: `ServerStorage.PropsMapa.Faro` (malla 93817126470443, textura 87535138846026).
- `generar_isla.py`: ancla "Faro" (girada 180° para que la puerta mire a la isla) que
  reemplaza la torre de primitivas; la Lampara y el Haz siguen y se ven por la linterna.
- Alrededor del faro el terreno es adoquín (antes pasto alto que tapaba la puerta).

**Qué se rompió:** nada. Probado en Studio y lugar guardado (`PescaYAlimentaGigantes.rbxl`).


---

## 2026-10-16 (5) — Ratón con Select en Xbox

**Qué se hizo:**

- `StarterGui.VirtualCursorMode = Enabled` (puesto en Studio y guardado en el lugar; también en
  `default.project.json`, aunque Rojo no puede escribirlo porque no es accesible por script):
  con mando, Select (View en Xbox) saca el cursor virtual de Roblox, un ratón que se mueve con
  el stick izquierdo y aprieta con A. Select otra vez lo guarda.
- `Menus/GamepadHint` (sale de GamepadNav): la ayuda de mando ahora dice "Y Menú" y
  "Select Ratón".

**Qué se rompió:** nada. Falta probarlo con un mando de verdad (el simulador de Studio no
manda el botón Select).


---

## 2026-10-16 (6) — Minotauro bebé nuevo con huesos y animaciones

**Qué se hizo:**

- `tools/blender/minotauro_e1.py`: becerro chibi al estilo de la orca y el dragón: cabeza
  grande, ojos ámbar enormes con brillos, mechón, cuernitos de marfil con anillos de oro, aro
  en la nariz, orejas rosadas, panza y hocico crema, marcas doradas en los hombros, cinturón
  con hebilla de oro, faldón de tiras con remaches, brazaletes, pezuñas y cola con borla.
- `tools/blender/rig_minotauro_e1.py`: malla de 18k triángulos, color y normales horneados,
  24 huesos (cuerpo por calor, piezas rígidas a su hueso). `ServerStorage.MinotauroE1`
  (el anterior quedó en `Respaldos`). IDs en `Assets`.
- `Shared/Minotauro` + `client/Giant/MinoStand`: respira, se mece, mira alrededor, mueve
  cola y orejas, se da vuelta con pasitos; al comer gira hacia quien le da, se inclina,
  estira los brazos y mastica; trucos sincronizados cada 11 s: pisotón (ola y temblor),
  rugido, músculo (destellos), baile (corazones), rascarse y salto (salpica al caer).

**Qué se rompió:** nada. Probado en Studio (reposo, rugido y comer). Las etapas 2-4 siguen
con el modelo viejo (sin huesos): giran y saltan, pero no se animan.


---

## 2026-10-16 (7) — Minotauro por etapa

**Qué se hizo:**

- `Shared/Minotauro/Etapas` (como el del dragón): por etapa, ritmo de respiración y cola,
  velocidad de giro, cuánto se mece, voz del rugido (E1 1.35 → E4 0.7), fuerza del pisotón y
  la caída (temblor y ola) y qué trucos hace y cada cuánto (E1 baila y salta cada 11 s; E4 ruge
  y pisa cada 14 s, sin bailar ni saltar). Se elige por el nombre del modelo (`MinotauroE<n>`).
- `Pose.idle`, `Trucos.current` y `MinoStand` usan el perfil; se fueron las constantes fijas
  del becerro (`EVERY`, `ORDER`, `TURN_SPEED`, `VOICE`).

**Qué se rompió:** nada. Probado en Studio: los 6 trucos sobre el rig de E1 con los perfiles
de E1 y E4, cambio a `Minotauro:4` sin errores en la consola. Rojo no estaba conectado en
Studio: los scripts se copiaron a mano con el mismo contenido (verificado por largo).


---

## 2026-10-16 (8) — Minotauro probado por MCP

**Qué se probó (Minotauro:1):** gira hacia quien le da de comer (desde el oeste: mira a -X) y
vuelve a mirar alrededor al terminar; muerde cada pez que llega (12 mordidas y 13 "Chomp" en
7 s); los 6 trucos corren sin errores y sus eventos suenan y salpican: pisotón (salpicón y
ondas), rugido (agudo, 1.37), salto (salpicón al caer), músculo (destellos) y baile (corazones).

**Qué se arregló:**

- `GiantView`: si la etapa baja con el mismo monstruo (panel de admin, o el mismo monstruo de
  nuevo) el cliente se quedaba con el modelo grande; ahora rehace el cuerpo.
- `GiantView`: el gruñido de ambiente (tono fijo 0.8) ya no suena en los gigantes animados
  (orca, dragón, minotauro), que rugen con la voz de su etapa. Antes el becerro gruñía grave.
- En Studio había 10 scripts duplicados (restos de Rojo); el cliente usaba el `Minotauro`
  viejo. Se quitaron las copias y se verificó que todos los scripts coinciden con `src/`.

**Qué se rompió:** nada. Nota: para simular comida hace falta `count` y `fishId` en GiantFed.


---

## 2026-10-16 (9) — Ventanas en teléfono

**Probado** con el simulador de Studio (iPhone XR 896×414 y Samsung Galaxy A06 800×360): Pack de
inicio, Misiones, Renacer, Mejoras, Colección, Tienda, Ajustes y Premio diario. Todas entran
en pantalla; el Pack ya no corta el texto de abajo.

**Qué se arregló:**

- Misiones (forma ancha): el texto de cada misión puede ir en dos líneas y tiene más ancho
  (el premio necesita poco). Los largos pasaron de 10-12 px a 15 px.
- Renacer: en "AL RENACER" el pez tapaba el número; ahora el número empieza donde termina el
  pez (en píxeles) y el "+N%" va arriba del título, sin taparlo.
- Mejoras y Colección: forma ancha y más baja en táctil (`WindowLayout.size`): se ven ~15-20%
  más grandes, Mejoras gana una columna y en Colección entran todas las pestañas. La pestaña
  se ensancha con nombres largos ("Poco común", "Legendario").
- Ajustes: la ayuda de Modo rápido, más corta ("Menos efectos, más fluido").

**Qué queda:** en el A06 (338 px de alto) algunos rótulos decorativos siguen chicos (cinta
"¡SIGUIENTE!" de Mejoras, "Nv 1/20" de las pestañas, "¡SOLO UNA VEZ!"), pero se leen.


---

## 2026-10-16 (10) — Revisión de errores (5 min de juego por MCP)

**Qué se jugó** (un "bot" en el cliente que usa los mismos remotes que la UI): pescar en el
muelle (31 piques, 31 capturas, canasta llena 4 veces), alimentar desde el volcán (barra al
30%), premio diario, ruleta (salió x2 monedas 15 min), comprar caña, canasta y botas, renacer
con monedas y poder del panel admin, y argumentos basura a `BuyUpgrade`, `ClaimPlaytime` y
`Rebirth` (el servidor los rechaza sin errores).

**Consola:** ningún error nuestro. Lo que queda:

- `GiantTemplates: no hay modelos "OrcaFantasmaE1..E4"`: es real (el evento de Halloween
  empieza el 17/10 y falta el modelo); el texto decía "marcador" y en verdad el cliente usa la
  orca teñida de violeta. Se corrigió el texto y se pidió el modelo a Cowork.
- `rbxassetid://203785492 ... Asset type does not match` y los avisos de `UIBlox
  FoundationProvider`: vienen de Roblox (CoreGui/CorePackages), no de `src/` ni del lugar.

**Qué se rompió:** nada. `selene src` sigue con 29 avisos de estilo viejos (`UDim2.fromScale`,
etc.), ninguno en los archivos tocados hoy.


---

## 2026-10-16 (7) — Minotauro E2–E4 y Orca fantasma (Cowork)

**Qué se hizo:**

- `tools/blender/minotauro_etapas.py`: E2 joven, E3 adulto (hombrera, brazaletes dobles, puntas
  de oro) y E4 forma final (pelaje negro con grietas de lava, ojos de fuego, dos hombreras y
  collar). Se arman con los bloques del becerro y se deforma todo el espacio (piernas, tronco y
  hombros) junto con las articulaciones, así el mismo esqueleto calza. `rig_minotauro.py` sirve
  para las 4 etapas (lee las articulaciones guardadas en la escena). 18.6k a 19.9k triángulos.
- `ServerStorage.MinotauroE2..E4` (los viejos en `Respaldos`), IDs en `Assets`.
- `ServerStorage.OrcaFantasmaE1..E4`: orca con textura fantasma (`tools/orca_fantasma.py`) y
  algo de transparencia, para el evento de Halloween.
- Trabajo repartido con Claude Code (`docs/tareas_claude_code.md`).

**Qué se rompió:** nada. Probado por MCP: las 4 etapas del minotauro y la orca fantasma.


---

## 2026-10-16 (11) — Orca y dragón: huesos, animación y efectos nuevos (C5, Claude Code)

**Qué se hizo:**

- `tools/blender/rig_orca.py` desde cero: `Raiz > Pecho > Cabeza > Mandibula`, cola de 4 huesos
  más cortos hacia la punta, `AletaColaIzq/Der`, pectorales con codo (`AletaIzq2/Der2`) y la
  `Dorsal` ahora deforma. Pesos por calor, suavizados y en 4 influencias; la mandíbula se corta
  por la línea de los labios (ahora abre de verdad). `968a9e6`.
- `tools/blender/rig_dragon.py`: el reposo pasa a ser con las alas en planeo (ver decisiones);
  pesos recalculados en esa pose. La boca ahora cierra del todo. `e2ccb31`.
- `Shared/Resorte`: un número que persigue a otro con peso. Orca: aletas de la cola que reman
  contra la onda, pectorales con látigo, dorsal que se mece, cola que se dobla tarde en las
  curvas. Dragón: el ángulo de planeo del ala se mide del modelo (`Rig.neutral`), cola,
  cuello y patas con resortes. `9c07280`.
- VFX: estelas finas en las puntas de las alas del dragón al ir rápido o picar (`4fd7355`) y
  remolinos en las aletas de la cola de la orca bajo el agua.
- Cowork importó los 8 modelos (`4506599`); probado en juego `Orca:2` y `DragonMarino:3`.

**Qué se rompió:** las estelas del dragón salían como rayos (anchas como media ala): se
afinaron. Las pruebas de E1/E4 y la Orca fantasma las sigue otra sesión.


---

## 2026-10-16 (12) — Zorro de agua E4, versión de Claude Code (C7)

**Qué se hizo:**

- Prueba del usuario (Claude Code contra Cowork). Modelo por código en Blender
  (`zorro_e4_code.py`), siguiendo la referencia del usuario pasada a agua: kitsune parado,
  nueve colas en S con punta de espuma, pechera y gola blancas, orejas grandes, medias azul
  marino, marcas cian que brillan, gema en la frente y oro.
- Pintura por vértice con capa de brillo (`zorro_e4_pintura.py`) y `rig_zorro_e4_code.py`:
  17.8k triángulos, color/normales/rugosidad/metal horneados a 1024, 65 huesos (cada cola con
  4 propios, el cuerpo por calor sin los huesos de las colas).
- `Shared/Zorro` + `ZorroStand` + `ZorroFx`: parado sobre el agua; respira, pasa el peso,
  colas que ondulan como llamas con inercia, pasos cruzados al girar, come y muerde; trucos
  aullido, abanico, salto, sacudida, reverencia y fuegos fatuos, con luz en la gema, bruma
  en las colas, ondas al pisar y orbes. `49ae047`.
- `GiantTemplates`: un monstruo con una sola etapa modelada usa ese modelo en todas.

**Qué falta:** importarlo en Studio como `ServerStorage.ZorroDeAguaE4_code` y probarlo.
Aprendido: piezas de bmesh con caras al revés restan volumen al fundir por vóxeles, y una
esfera de `masa()` guarda escala y giro en el objeto (pintar en coordenadas del mundo).

---

## 2026-10-16 (13) — Orca, dragón y orca fantasma probados con los huesos nuevos (C5)

**Qué se hizo:**

- Probadas en Play por MCP las 12 combinaciones (`Orca`, `DragonMarino` y `OrcaFantasma`,
  etapas 1 a 4) con los modelos que importó Cowork (`4506599`): cada etapa carga su modelo,
  todos los huesos se mueven, los tamaños cuadran (la orca mide 16.5/44/82.5/165 de alto y
  el dragón E4, 99 de largo = 165 × 0.6) y no hay errores nuestros en la consola.
- Deformación revisada en Edit: clones quietos en el cielo con las poses extremas medidas
  en Play, aplicadas con el `Rig` y el `Pose` del juego. Sin roturas de malla.
- `Orca/Etapas`: el perfil se elegía por nombre exacto (`OrcaE<n>`), así que las cuatro
  `OrcaFantasmaE<n>` nadaban como la adulta; ahora se elige por el sufijo `E<n>`.
- Orca: tope de 0.4 rad a las aletas de la cola. La cría llegaba a 44° encima de la curva
  de la cola y la punta quedaba como un gancho.
- Dragón: el ángulo de planeo (`neutral`) se mide por lado. Algunos modelos tienen el
  cuerpo un poco torcido (la cadera del E3 está corrida a un lado) y con un solo valor
  promedio el E3 planeaba con un ala 22° más alta que la otra.

**Aprendido:** en `execute_luau` del servidor, `require` carga otra copia de los módulos,
no la del juego: la orden `giant` "funciona" pero no cambia nada y pisa los atributos de
`EstadoGigante`. Para cambiar de gigante hay que mandar `AdminCommand` desde el cliente.

---

## 2026-10-16 (14) — Hábitats dentro del volcán (C6)

**Qué se hizo:**

- `Config/Habitats.luau`: por gigante, la lista de props (`prop`, `angulo`, `radio`, `escala`,
  `giro`), copiada del atributo `Sugerido` que dejó Cowork (72 props en total). También tiene
  las zonas libres, los rayos y los números de luz, fuego y brillo.
- `World/HabitatPlacer`: coloca cada prop como dice el contrato (`ScaleTo`, rayos solo contra
  el terreno en el centro y en 4 puntos, el más bajo en la ladera, base 0.5 más abajo, frente
  hacia afuera más el giro). Descarta lo que caiga a menos de r 95 del centro o desde el
  acantilado (r 205) hacia afuera. Todo anclado; solo choca la malla principal de los props con
  `Colision = true`. Pone la PointLight de `fuego` y `luz` en el punto `Llama`.
- `World/HabitatService`: `Workspace.Habitat` con el hábitat del gigante actual; se rehace al
  cambiar de gigante y ya durante `VolcanLlenando` (el de `RuletaResultado`). El Zorro no tiene
  hábitat: el cráter queda vacío.
- `Ambient/HabitatFx` (cliente): Fire en `Llama` (sin modo rápido) y latido suave del Neon de
  los props `brillo`.

**Probado por MCP:** Orca (20 props), `Minotauro:1` (19, 4 fuegos), `Minotauro:4` (no se
rehace), `DragonMarino:2` (13), `OrcaFantasma:1` y `:3` (20, 11 luces), `ZorroDeAgua` (vacío).
El Neon late (transparencia 0.05 → 0.39). Sin errores nuestros en la consola. Modo rápido
(atributo `Settings` del jugador desde el servidor): el Minotauro pasa de 4 Fire a 0 con las 4
luces intactas, el dragón armado en modo rápido llega sin fuego y al quitarlo vuelven los 3.

**Qué se rompió:** nada. El cliente avisaba "Infinite yield" esperando `Workspace.Habitat`
(el servidor la crea después del terreno); ahora espera sin plazo.


---

## 2026-10-16 (13) — Aura nueva del Dios del Volcán

**Qué se hizo:** el aura tapaba el traje (lenguas de fuego por todo el cuerpo y un aro de llamas
en los pies). Ahora el poder está en el piso y en la silueta: sello de magma a sus pies (charco
de lava, aro de runas que gira y una onda de choque cada ~3.5 s), brasas ralas que suben más
alto que la cabeza, dos llamas chicas en los hombros, contorno y halo de lava, un hilo de humo
en el volcán de la cabeza. Nada de fuego encima del cuerpo.

**Qué se rompió:** nada. Probado en juego (plaza y borde del volcán).


---

## 2026-10-16 (14) — El minotauro camina para comer y guarida nueva

**Qué se hizo:**

- El minotauro solo giraba en el centro al ser alimentado (su código nunca lo movía). Ahora
  camina hasta la orilla de quien lo alimenta (`Minotauro/Caminar`: se para según su tamaño,
  acelera y frena), con piernas y brazos alternados (`Pose.walk`) y una salpicadura y una
  onda en cada pisada; come al llegar y vuelve caminando al centro. `adb42da`.
- Guarida del descanso: radio 90 (llena el fondo del pozo de pared a pared), base hasta el
  fondo, otro anillo de oro y 12 obeliscos. Queda enterrada 40 studs (`restArenaSink`)
  mientras se alimenta al monstruo; al vaciarse el lago sube con retumbo y brasas
  (`Ambient/GuaridaSube`, animada en el cliente con BulkMoveTo; el servidor la mueve de una
  vez) y al terminar el descanso se hunde. `30f4f37`.

**Qué se rompió:** nada. Probado en juego: `Minotauro:2` camina al oeste hasta x = -159 y
come; `fill 1` → la guarida sube a -136 mientras se vacía el lago; `skipRest` → baja a -176.

---

## 2026-10-16 (15) — Guarida más arriba, volcán más rápido y con luz

**Qué se hizo (pedido del usuario):**

- La guarida del descanso sube mucho más: el piso pasa de -136 a -60 y el radio de 90 a 119
  (a esa altura el pozo es más ancho y la guarida sigue tocando la pared). Queda enterrada 104
  studs (antes 40): con menos, el cristal del centro asomaba sobre el fondo del lago.
  `generar_isla.py` suma un anillo de oro (`AnilloBorde`) para la franja de afuera.
  `ServerStorage.GuaridaDescanso` se reemplazó con el JSON nuevo (la anterior en
  `Respaldos.GuaridaDescanso_r90`).
- El volcán se vacía en 3 s (antes 8) y se llena en 2 s (antes 6); la guarida sube en esos 3 s.
- Luz del volcán: de noche solo quedaba la luz ambiente con bruma naranja y no se veía al
  monstruo (en el descanso sí, porque el "amanecer" adelanta el reloj). Ahora el cráter tiene
  su propia hora de sol (`SkyMoods.craterHour`, 15:30): al cruzar el puente el cielo va
  hacia esa hora junto con el resto del ambiente. Algo más de luz ambiente y menos bruma.

**Probado por MCP (de noche, `HoraFija = 0`):** el cráter se ve claro; `fill 1` → el lago se
vacía y la guarida llega a -60, con el borde calzado contra la pared; `skipRest` → el agua
vuelve en 2.0 s y la guarida queda en -164 (lo más alto, el cristal, a -152: bajo el fondo).
Consola limpia.

**Qué se rompió:** nada.

---

## 2026-10-16 (16) — Mar más grande

**Qué se hizo (pedido del usuario):** el mar pasa de ±840 a ±1536 studs (antes el volcán
llegaba justo al borde y de ese lado se acababa el agua) y el muro invisible de 560 a 1000 studs
del centro, así se puede nadar mucho más lejos. En `TerrainBuilder`, los bloques de mar abierto
solo llevan una capa de fondo bajo el agua (antes, roca desde -40 que nadie ve): casi la mitad
de vóxeles en el mar nuevo.

**Probado por MCP:** el servidor tiene agua hasta ±1536 y el terreno queda listo a los 10 s de
juego. El cliente solo carga el terreno hasta unos 1000 studs de donde está (streaming de
Roblox): el borde que se ve en el horizonte ahora es ese límite, no el fin del mar.

**Qué se rompió:** nada.

---

## 2026-10-16 (17) — Feed the Giants: códigos en inglés (C8)

**Qué se hizo (tarea de Cowork):** el juego se publica como "Feed the Giants" / "Alimenta a
los Gigantes". `CodeList` suma alias en inglés: GIANTS (= GIGANTES) y LAUNCH (= LANZAMIENTO);
ORCA y HALLOWEEN sirven igual en los dos idiomas. Un alias (`aliasOf`) se anota y se paga como
su original, así quien canjeó GIGANTES no cobra de nuevo con GIANTS. Ningún texto del juego
nombra al juego (dicen "el juego"); el README ahora lo nombra.

**Probado por MCP:** `giants` → +500 monedas y después `GIGANTES` → "ya usado"; ` Launch ` →
+1000 y 10 min de x2, después `LANZAMIENTO` → "ya usado"; un código que no existe → inválido.

**Qué se rompió:** nada.

---

## 2026-10-16 (18) — Minotauro v2: guía de estilo de bloques y estado en Studio

**Qué se hizo (pedido del usuario):** `docs/estilo_modelos.md` fija lo aprobado para los
gigantes v2: estilo de bloques; cuadrícula de 0.1 BU con cuñas 1:1, 1:2 y 2:1 y bisel de
0.012; alto por etapa global (3, 8, 15 y 30 jugadores de 5.5 studs) con una sola escala de
exportación de 5.32 studs por BU; hasta 8,000 triángulos en E1 (E2..E4 por definir); piezas
rígidas con placas de unión y pesos de un solo hueso por vértice. Lista lo que sigue por
confirmar y suma "Estado del Minotauro en Studio". También se modeló el E1 de bloques
(`f659620`, `tools/blender/minotauro_v2_e1_bloques.py`): 92 bloques, 4,036 triángulos, 3.1 BU.

**Probado por MCP (solo lectura):** el juego usa `ServerStorage.MinotauroE1..E4` reales (25
huesos, 17,998 a 19,874 triángulos), no la orca teñida; el comentario de `Config/Giants.luau`
que dice lo contrario está desactualizado.

**Qué se rompió:** nada (no se tocó `src/` ni los modelos actuales).

---

## 2026-10-16 (19) — Minotauro v2 E1: revisión del modelo de bloques

**Qué se hizo (pedido del usuario):** `tools/blender/minotauro_v2_revision.py` revisa el
modelo con la forma real de cada bloque (cuñas y bisel, no su caja): caras coplanares que
parpadean, normales hacia adentro, bisel, pendientes de las cuñas, cuadrícula y la tabla
pieza → hueso. El script borra las caras tapadas por completo dentro de cada pieza (190
triángulos) y el mechón ya no se mete en la cuña de la cabeza: se apoya encima. Renders de
diagnóstico (color plano y caras de atrás en rojo) junto a los normales.

**Resultado:** 93 bloques, 3,890 triángulos, 3.1 BU; 0 coplanares, 0 normales al revés,
bisel de 0.012 en un segmento en todos los bloques, 0 cuñas fuera de regla. Los artefactos
negros del primer render eran caras coplanares de bloques solapados (se corrigió la
geometría en `f659620`); lo oscuro entre las piernas es la borla de la cola en sombra.

**Qué se rompió:** nada. El faldón (3 piezas) va al hueso `Cadera`: queda propuesto darle
huesos propios.

---

## 2026-10-16 (20) — Minotauro v2 E1: el faldón en el pisotón

**Qué se hizo (pedido del usuario):** `tools/blender/minotauro_v2_e1_pisoton.py` posa las
piezas como lo haría el rig y busca, con choques BVH entre la pierna y el faldón, los ángulos
del pisotón del juego (muslo 57°, rodilla 69°, brazos abiertos) y de la pose extrema (90°).
Con el modelo aprobado ninguna opción llega: la rodillera recorre un círculo de 5.8 celdas
alrededor de la cadera y la bisagra del faldón está a 5, así que la rodilla pasa por la raíz
de las tiras (levantar el faldón o recortarlo no alcanza). Con el cinturón y el faldón 1 celda
más adelante (`ADELANTE = 1`, propuesta; el modelo aprobado sigue en 0): opción a, el faldón
se levanta 55° en el pisotón y 91° en la pose extrema; opción b (rígido), el muslo llega a 29°
como mucho. Renders `pisoton_a.png`, `pisoton_b.png` y `pisoton_b_choque.png`. Los huesos del
faldón quedan anotados en `inventario_modelos.md` como adición propuesta.

**Qué se rompió:** nada; el modelo aprobado no cambió (93 bloques, 3,890 triángulos).

---

## 2026-10-16 (21) — Minotauro v2 E1: cinturón adelante y huesos del faldón

**Qué se hizo (aprobado por el usuario):** `ADELANTE = 1` en
`tools/blender/minotauro_v2_e1_bloques.py`: el frente del cinturón, la hebilla y las tiras del
frente salen 1 celda hacia adelante y la bisagra de `FaldonFrente` queda a 6 celdas de la
cadera, fuera del recorrido de la rodilla. Cada pieza del faldón va a su hueso opcional
(`FaldonFrente`, `FaldonIzq`, `FaldonDer`, hijos de `Cadera`, todavía sin animar); el
verificador acepta esos 3 huesos además de los 25 del contrato. Se regeneraron el `.blend` y
los renders de revisión. Guía de estilo: sección "Faldón y cinturón (E1)"; inventario: la
adición pasa de propuesta a aprobada.

**Resultado:** 93 bloques, 3,890 triángulos, 0 coplanares, 0 normales al revés, 0 cuñas fuera
de regla; cada hueso con una sola pieza.

**Qué se rompió:** nada; el modelo todavía no se exporta a Studio.

---

## 2026-10-16 (22) — Minotauro v2 E1: pisotón y caminata con el faldón aprobado

**Qué se hizo (pedido del usuario):** `tools/blender/minotauro_v2_e1_pisoton.py` deja de
comparar las opciones a y b y mide la opción a con el modelo aprobado: choques de las dos
piernas contra las tres piezas del faldón en el pisotón del juego, la pose extrema y toda la
caminata (`Pose.walk`), más la curva del faldón según el muslo del pisotón (40° a 70°).
Renders `pisoton_57.png`, `pisoton_perfil.png` (de perfil, sin el brazo derecho, que tapaba
el muslo) y `caminata.png`; se borraron `pisoton_a.png`, `pisoton_b.png` y
`pisoton_b_choque.png`.

**Resultado:** el faldón se levanta 55° en el pisotón, 91° en la pose extrema y 3° como mucho
en la caminata. Con el cinturón en su lugar anterior no había ángulo sin choque. Se propuso
bajar el pisotón a 55° y se descartó: pide 64° (ver `decisiones.md`). `Trucos.luau` no cambia.

**Qué se rompió:** nada.

---

## 2026-10-17 (1) — Minotauro v2 E1: hombrera partida y hombros más abajo

**Qué se hizo (aprobado por el usuario):** las poses extremas mostraron que la hombrera, del
brazo y de x 4 a 12, se separaba del pecho al abrir el brazo y se metía en la cabeza. Se
probaron tres arreglos fuera del repo (pivote en el borde del pecho, hombrera partida, y
partida con los hombros una celda más abajo) en los picos de los trucos del juego; quedó el
último. En `minotauro_v2_e1_bloques.py` la mitad de adentro es de `Pecho` (x 4..8), la tapa
es de `Brazo` (x 8..12) y las dos van en z 16..18; el hombro gira en (±8, −0.5, 17), también
en el script del pisotón. Guía de estilo: sección "Hombros (E1)".

**Resultado:** 95 bloques, 3,966 triángulos, 3.1 BU; 0 coplanares, 0 normales al revés, 0 cuñas
fuera de regla. El pisotón no cambia (faldón a 55°, 91° y 3°).

**Qué se rompió:** nada; de frente se ve la junta de la hombrera en x ±8.

---

## 2026-10-17 (2) — Minotauro v2 E1: poses extremas

**Qué se hizo:** `tools/blender/minotauro_v2_e1_poses.py` posa las piezas rígidas con la
cadena de huesos del contrato y los mismos ejes que `Pose.apply` / `Rig.turn` (así las poses
del juego se escriben con sus claves: `outL`, `elbowOutL`, `lookPitch`…). Prueba las 13 poses
de la guía y el pico de 7 trucos del juego (músculo, rugido, rascarse, salto agachado y en el
aire, baile, comer), levanta el faldón lo justo en cada una y guarda en `poses.json` qué
piezas se cruzan, qué juntas se solapan de más y qué piezas se separan. Las articulaciones del
v2 quedan anotadas en `inventario_modelos.md`. Renders en `renders/minotauro_v2_e1/poses/`.

**Resultado:** con la hombrera partida ninguna pieza se separa y los trucos del juego solo
dejan roces chicos (orejas sobre la hombrera, la mano en el brazo con el codo doblado). Lo
grande queda en poses de la guía que el juego no usa (brazos a 150°, mirar abajo 45°, pierna a
90°). Detalle en la guía de estilo, "Poses extremas".

**Qué se rompió:** nada.

---

## 2026-10-17 (3) — Minotauro v2 E1: rig y FBX

**Qué se hizo (pedido del usuario):** `tools/blender/rig_minotauro_v2_e1.py` une las piezas
de bloques en una malla con cada pieza entera a su hueso, arma el esqueleto de 28 huesos (los
25 del contrato y los 3 del faldón) en las articulaciones de las poses, pinta con una paleta
de 256 px (un cuadro por color) y exporta `assets/blender/MinotauroE1_v2.fbx` a 16.5 studs.
`minotauro_v2_e1_poses.py` separa `giros()` y `matrices()` de `posar()` para que el rig use
la misma cuenta.

**Resultado:** en las 20 poses, la malla movida por los huesos coincide con las piezas
rígidas (error máximo 0.00001 celdas); el FBX reimportado tiene los 28 huesos, la textura y
16.5 studs de alto. Detalle en `import_minotauro_v2.md`.

**Qué se rompió:** nada; `MinotauroE1` no se tocó.

**Qué sigue:** importar el FBX a `ServerStorage.MinotauroE1_v2` (a mano, con "Mantener
huesos de influencia cero") y el código para usarlo (paso 8 del plan).

---

## 2026-10-17 (4) — Minotauro: animaciones por código con resortes

**Qué se hizo (pedido del usuario, por código y no con keyframes):**

- `Minotauro/Trucos` pasa a carpeta: un módulo por truco y `Curvas` (llegar con rebote,
  impacto sin suavizar, parábola del salto…). Cada truco se rehizo con anticipación,
  aplastarse y estirarse con la pose y arcos: el pisotón se echa atrás, tiembla arriba y el
  golpe dobla las dos rodillas; el rugido toma aire antes; el músculo bombea mirando el brazo;
  el baile flexiona en cada tiempo y mueve los brazos en círculos; al rascarse golpetea el pie;
  el salto se aplasta, se estira, encoge las piernas y cae aplastándose. El pisotón sigue en 57°.
- `Minotauro/Resortes`: orejas, cola (en cadena), mandíbula y faldón persiguen su pose con
  retraso y los empuja la inercia del cuerpo (subir, bajar, girar, mecerse).
- `Minotauro/Cuerpo`: `plant` apoya el pie más bajo (al doblar las rodillas se agacha de verdad)
  y `skirt` levanta el faldón de adelante lo que pide el muslo (curva medida del pisotón).
- `Pose.apply` mueve los huesos opcionales del faldón; `Etapas` suma `pace` y `bounce` por
  etapa y reconoce los modelos `…E<n>_v2`.

**Probado en Studio por MCP:** los módulos corridos en Edit dan las poses de los 6 trucos; en
Play, con `Minotauro:1`, 25 s a 60 cuadros por segundo, la pierna llegó a 1.0 rad en un truco,
orejas, cola y mandíbula se movieron con los resortes y la consola no mostró errores. Checklist:
build, selene y stylua sin avisos en `Minotauro`.

**Qué se rompió:** nada. Visto en Edit: en el `MinotauroE1` actual la pierna casi no sube aunque
el hueso gira 1 rad (la rodilla de reposo está 2 studs delante de la cadera); es de los pesos de
ese modelo, no de este cambio.

---

## 2026-10-17 (5) — Minotauro v2 E1: los trucos en video

**Qué se hizo:** como el v2 todavía no está en Studio, las poses de los 6 trucos se calcularon
en Studio con los módulos del juego (Edit, por el MCP) y
`tools/blender/minotauro_v2_e1_animacion.py` las pone en el rig del v2 con la misma cuenta que
`Pose.apply` y arma un GIF por truco en `renders/minotauro_v2_e1/animaciones/` (con las poses
en `poses_juego.json`). Detalle: en Edit, `require` devuelve la copia que ya cargó aunque Rojo
cambie el código; hay que clonar la carpeta del módulo para que lo cargue de nuevo.

**Qué se rompió:** nada.

**Qué sigue:** importar `MinotauroE1_v2.fbx` a `ServerStorage.MinotauroE1_v2` (a mano) y el
interruptor para usarlo en el juego (paso 8 del plan).

---

## 2026-10-17 (6) — El Minotauro v2 E1 en el juego

**Qué se hizo:** el usuario importó el FBX; por el MCP se revisó (parado, mirando a −Z, 28
huesos, pivote en la base) y se movió a `ServerStorage.MinotauroE1_v2`. `modelSuffix = "_v2"`
en el Minotauro (`Config/Giants.luau`): `GiantTemplates` publica el v2 como `MinotauroE1`. IDs
en `Assets` (malla y textura de la paleta).

**Probado en Studio (Play, `Minotauro:1`):** se publica con 28 huesos y alto base 16.5; E2
sigue con el modelo actual; a 60 cuadros por segundo hizo salto y pisotón (muslo a 1.0 rad,
faldón de adelante a 1.38 rad, por encima de lo que pide el muslo); consola sin errores.

**Qué se rompió:** la cola se enroscaba (hasta 1.5 rad por segmento): el último resorte vibraba
al mismo ritmo que el baile y entraba en resonancia. Se endurecieron los tres resortes de la
cola, se bajó cuánto la empuja el vaivén y se le puso un tope de 0.9 rad por segmento; en 40 s
de Play quedó en 0.9.

**Qué sigue:** que el usuario vea el v2 en el juego; las etapas E2..E4 en bloques (paso 9).

---

## 2026-10-17 (7) — Minotauro v2: herramientas para cualquier etapa

**Qué se hizo (preparación para hacer E2, E3 y E4 a la vez):** los scripts del v2 dejan de ser de
la E1. `minotauro_v2_bloques.py` tiene lo común (bloques, cuñas, mallas, revisión, renders) y
carga `minotauro_v2_e<n>_geometria.py` con lo propio de la etapa (módulo, paleta, piezas,
articulaciones, colas de los huesos). Poses, pisotón, rig y video toman `--etapa <n>` y miden la
cámara, el piso y el muestreo de caras ocultas en proporción al módulo. El pisotón guarda además
`medidas.json` (muslo, pierna, cadera, pies y faldón según el muslo) y `Minotauro/Cuerpo` toma
esas medidas de cada etapa (`body` en `Etapas`; E2..E4 usan las de la E1 hasta tener su v2).
Guía: módulo por etapa (0.3 / 0.5 / 1.0 BU, los bloques crecen con el cuerpo) y presupuesto de
10k / 12k / 15k triángulos (aprobados por el usuario).

**Probado:** la E1 sale igual con los scripts nuevos (95 bloques, 3,966 triángulos, mismas caras
ocultas, pisotón 55° / 91° / 3°, `poses.json` idéntico, rig con error 0.00001); en Play, sin
errores y el pisotón sube el muslo a 1.0 rad. Checklist: build, selene y stylua.

**Qué se rompió:** nada. `pisoton.json` de la E1 cambia de formato y ya no trae la comparación con
el cinturón anterior (`ADELANTE = 0`): queda en `decisiones.md` y en el commit 9f18333.

---

## 2026-10-17 (8) — Minotauro v2 E2, E3 y E4 a la vez

**Qué se hizo (pedido del usuario: las tres etapas en paralelo):** una sesión por etapa, cada una en
su copia del repo y solo con los archivos de su etapa (`minotauro_v2_e<n>_geometria.py`, su
`.blend`, sus renders y su FBX). Primero el bloqueo con renders y el pisotón; el usuario aprobó las
siluetas lado a lado (`minotauro_v2_alineacion.py`) y pidió solo ojos más visibles. Después cada
sesión hizo los ojos, las poses extremas y el rig con FBX, y se unieron las tres ramas.

- E2 joven: tirante de cuero rojo en X sobre el pecho, ojos ámbar de 3×3 con pupila y brillo.
- E3 adulto: hombreras con púas en la tapa del brazo, puntas de oro en los cuernos, ojos ámbar.
- E4 forma final: pelaje casi negro con grietas de lava (que asoman o van metidas), ojos de lava
  con brillo claro, colmillos y hombreras de cuero con borde de oro; `ADELANTE = 2` (el faldón
  casi no se mueve, "enorme y lento").

Por las poses, cada una ajustó algo sin cambiar la silueta: E2 acortó la mandíbula (entraba en la
hebilla al abrirse) y subió orejas y cuernos; E3 bajó los pectorales y afinó las orejas; E4 acortó
las orejas, subió el hombro y bajó la mitad fija de la hombrera. Las medidas de cada etapa pasan a
`Minotauro/Medidas.luau` (Etapas las usa en `body`).

**Resultado:** cifras en `import_minotauro_v2.md`. En los trucos del juego ninguna etapa atraviesa
a la vista más que la E1 y ninguna pieza se separa. Checklist: build, selene y stylua.

**Qué se rompió:** nada. Propuestas de las sesiones para los scripts comunes, pendientes: que
`quitar_ocultas` conserve una de las dos caras de contacto (si no, por la rendija del bisel se ve
el interior), encuadrar el render del pisotón por el ancho del modelo (corta los cuernos de E2..E4)
y `use_nodes`, que desaparece en Blender 6.

**Qué sigue:** importar los tres FBX a Studio, moverlos a `ServerStorage.MinotauroE<n>_v2`, sus IDs
en `Assets`, probar las cuatro etapas en Play y los videos de los trucos de cada una.

---

## 2026-10-17 (9) — Minotauro v2 completo en el juego

**Qué se hizo:** el usuario importó los FBX de E2..E4; por el MCP se revisaron y se movieron a
`ServerStorage.MinotauroE<n>_v2`, y sus IDs entraron en `Assets`. Con `modelSuffix = "_v2"` el
Minotauro crece en bloques de la E1 a la E4, sin el salto al modelo orgánico.

**Probado en Studio (Play):** las cuatro etapas con `Minotauro:<n>`: 28 huesos, alto base correcto,
~60 cuadros por segundo, trucos con resortes y faldón; consola sin errores. Checklist: build,
selene y stylua.

**Qué se rompió:** nada.

**Videos:** las poses de los 6 trucos de E2..E4 salen de Studio con el perfil de cada etapa (ritmo
1.1 / 1.25 / 1.45 y su rebote) y `minotauro_v2_animacion.py --etapa <n>` los renderiza en
`renders/minotauro_v2_e<n>/animaciones/` (con `poses_juego.json`).

**Qué sigue:** que el usuario los vea y publicar.

---

## 2026-10-17 (10) — Minotauro: rutina, desierto, voces y evolución

**Qué se hizo (pedido del usuario; cuatro sesiones en paralelo, cada una con sus archivos):**

- **Rutina** (`Minotauro/Rutina`, `Habitos`, `Posturas/`, `Evolucion`, `Azar`): cuando no come, el
  minotauro pasea por el cráter, se sienta (y sentado se rasca, bosteza, mira o dormita), olfatea,
  se estira, mira al cielo o a un jugador y hace sus trucos (que pasan a ser una opción más: ya no
  hay `trickEvery`). Todo sale de la hora del servidor con un hash sin estado: todos lo ven igual.
  Cambia por etapa (el becerro trota e inquieto, la forma final casi no camina y se sienta pesado).
  Comer manda: se para, va a la orilla y vuelve a la rutina. Pose de evolución (se agacha, explota
  hacia arriba a los 1.3 s, ruge). Eventos nuevos: `sit`, `standup`, `snort`, `yawn`, `sniff`,
  `evolve`. `Cuerpo.plant` ahora cuenta la pezuña inclinada.
- **Desierto** (`client/Ambient`: `CraterMode`, `CraterSand`, `SandTerrain`, `SandShape`,
  `SandDisc`, `SandDecor`, `SandProps`, `DesertAir`, `DustDevils`, `LakeFill`): con `sand = true`
  el cráter es un desierto de terreno (dunas, ondas de viento, bancos y mesetas de arenisca, huesos
  y piedras) que sube con cortinas de arena al llegar el gigante y se escurre en el descanso; los
  props suben con la arena; viento con arena, polvo, vaho, remolinos y luz cálida. Todo local del
  cliente, como la lava.
- **Voces y polvo** (`client/Audio/MinoVoces`, `Giant/MinoSuelo`, `Effects/SandFx`): 14 sonidos de
  ProSoundEffects (bramido de toro por etapa con capas de gruñido y retumbo, resoplidos, pisadas en
  arena, golpes) y polvo de arena en pisadas, pisotón, caídas y al sentarse. `Assets.Sounds` pasa a
  `Assets/Sounds.luau`.
- **Evolución** (`Giant/EvolveFx`, `EvolveLook`, `GiantEvolution`, `Effects/Evolve*`): para todos
  los gigantes, con su color: carga con aura, energía y anillos (0..1.3 s), estallido con destello,
  columna de luz, onda en el suelo y chispas, y calma con chispas que caen. El cambio de modelo
  pasa en el destello, igual para todos.
- `Effects/GroundFx`: los peces que come, la llegada, la despedida y los ataques levantan arena en
  el desierto en vez de salpicar.

**Probado en Studio (Play):** el desierto sube con el minotauro; en 60 s la E1 estaba sentada, se
paró, caminó ~50 studs, se detuvo a hacer cosas y siguió; una evolución forzada (`fill 0.3`) se ve
con la carga dorada y pasa a la E2 en el destello; la E4 pasea a 48 studs del centro como mucho
(el desierto tiene 190) a 61 cuadros por segundo; consola sin errores ni avisos del juego.
Checklist: build, selene (28 avisos viejos, ninguno nuevo) y stylua.

**Qué se rompió:** nada visto. Pendiente de oír en el juego: volúmenes y el pico de la carga de la
evolución contra el estallido (`EvolveFx`). La arena se ve pálida de día (el color de terreno
Sand es global: también es el de las playas).

**Qué sigue:** que el usuario lo vea y escuche en el juego y publicar.


## 2026-10-17 (11) — Rocas naturales en la guarida del dragón

**Qué se hizo (pedido del usuario: "que parezcan naturales"):** las rocas donde se posa el dragón
eran columnas apiladas y parecían tambores. Ahora son peñones de bloques volcánicos
(`Ambient/LairRocks` y el nuevo `Ambient/LairCrag`):
- **Cima:** lajas giradas en escalones de 0.18; la primera queda justo en `Guarida.point()`.
- **Núcleo:** queda 3.5 más abajo y entre laja y laja se ve como una grieta.
- **Contorno:** una corona de bloques bajada con `LairCrag.under` para que nada sobresalga de la
  cima. Tiene bultos y entrantes, pero nunca más adentro que `size`, porque `Dragon/Posado` pisa
  plano hasta ahí.
- **Laderas:** hileras de bloques torcidos que se abren hacia la lava, con taludes en cuña,
  bloques sueltos, vetas de magma por las grietas y costra de discos corridos.
- **Materiales:** basalto y pizarra; la obsidiana es lisa y sin reflejo, porque el vidrio de
  Roblox reflejaba el cielo y se veía azul.

**Probado en Studio (Play):** la guarida con el dragón E2 se ve de día y al atardecer, sin errores
en la consola.
Checklist: build, selene (28 avisos viejos) y stylua.

## 2026-10-17 (12) — Dragón marino v2: la cría rediseñada para que se lea como dragón

**Qué se hizo (pedido del usuario: "más parecido a dragón"):** `dragon_v2_e1_geometria.py`, más los
nuevos `dragon_v2_e1_alas.py` y `dragon_v2_formas.py` (prismas convexos, membranas cóncavas y
púas, para E2..E4):
- **Cabeza:** hocico largo con narinas, cejas en cuña, ojos a los costados, dos cuernos marfil y
  aletitas en las mejillas.
- **Cuello:** en arco, con la cabeza sobre el lomo.
- **Alas:** de murciélago, con brazo, garrita en la muñeca, tres dedos en abanico y membrana
  sólida con festón cóncavo.
- **Cuerpo y cola:** púas de la nuca a la cola, placas ventrales menta y la cola con pala en
  rombo.
- **Patas:** más gruesas, con garras.

Usa 5,107 triángulos. La Cadera gira a la altura de la Cabeza para que `Rig.bind` siga dando
adelante = −y exacto.

**Qué sigue:**
- E2, E3 y E4 sobre esta base.
- Las brasas de `DragonEmbers` salen de la Cadera, que ahora está alta: conviene sacarlas del
  Pecho o de Cola1.

## 2026-10-17 (13) — Dragón marino v2: las cuatro etapas con la referencia del usuario

**Qué se hizo:** el usuario rechazó las E2..E4 del primer diseño ("no me gustaron") y pidió rehacer
las cuatro inspiradas en una imagen suya: un dragón oscuro estilo wyvern de alas enormes. Eligió
"referencia + toques marinos".
- **Guía común:** paleta por etapa (de marrón oscuro a casi negro, con brasa y ~15% de turquesa),
  proporciones, escala y reglas del rig, para que cuatro sesiones en paralelo hicieran el mismo
  dragón.
- **Etapas:** `dragon_v2_e<n>_geometria.py` y sus módulos, con FBX y textura de cada una. La E1
  reemplaza a la cría anterior.
- **Alineación:** `minotauro_v2_alineacion.py --criatura dragon`.
- **Detalle:** en `docs/plan_dragon_v2.md`.

**Resultado:**

| Etapa | Triángulos | Poses limpias |
|---|---|---|
| E1 | 6,796 | 19 de 24 |
| E2 | 6,814 | 20 de 24 |
| E3 | 7,282 | 20 de 24 |
| E4 | 10,908 | 20 de 24 |

- La envergadura mide exacta en las cuatro (9.9 / 26.4 / 49.5 / 99 studs).
- En las cuatro, adelante = −y y el aleteo al máximo del juego sale limpio.

**Qué quedó flojo (el usuario las aprobó así):**
- Las alas no dominan la silueta como en la referencia: el juego escala al dragón por su lado más
  largo.
- Las cuatro etapas no son del todo parejas entre sí.

**Qué sigue:** importar los cuatro FBX a Studio, poner sus IDs en `Assets` y `modelSuffix = "_v2"`
en el dragón, y probarlo.

## 2026-10-17 (14) — El dragón marino v2 en el juego

**Qué se hizo:** el usuario importó los cuatro FBX y los pasé a `ServerStorage.DragonMarinoE<n>_v2`.
- **Revisión por MCP:** 32 huesos, medidas exactas y orientación igual que el minotauro.
- **Código:** IDs de malla y textura en `Assets`, y `modelSuffix = "_v2"` en el dragón.
- **Juego:** `GiantTemplates` los publica con alto base 16.5 / 44 / 82.5 / 165.

**Probado en Studio (Play):** las cuatro etapas vuelan con su tamaño. La cría y el anciano comieron
12 peces cada uno, con raros. Consola sin errores.
Checklist: build, selene (28 avisos viejos) y stylua.

**Qué sigue:** guardar el lugar (los modelos viven en el `.rbxl`) y publicar.

## 2026-10-17 (15) — La interfaz en piedra tallada

**Qué se hizo:** el usuario pidió rehacer toda la interfaz (tienda, botones, etc.) con el estilo
de dos imágenes suyas: el panel del monstruo en pizarra con gemas, y MEJORAS de piedra gris con
texto dorado y TIENDA con marco de lava.
- **Kit:** `tools/ui/generar_kit_piedra.py` dibuja con PIL cinco 9-slice (panel, hueco, botón que
  se tiñe, lava y gema), subidos por el MCP. `Interface/Kit` arma las piezas (`skin`, `gold`,
  `gems`, `tint`, `press`).
- **Base:** `Style.button` pasa a ser piedra teñida y sigue a `BackgroundColor3`, así siguen
  andando los que apagan o pintan botones. Se suma `Style.lavaButton`. `Window` lleva panel de
  piedra, título dorado con gemas (`WindowTitle`) y X roja.
- **Cuatro sesiones en paralelo, cada una con sus archivos:**
  - HUD: panel del monstruo, botones laterales y de arriba, contadores, banners y toasts;
  - MEJORAS y las piezas compartidas (`CardParts`, `ShopParts`, nuevo `StoneSkin`);
  - tienda de Robux y ofertas (nuevo `ShopStone`), pack de inicio y regalar;
  - el resto de las ventanas: misiones, renacer, ajustes, códigos, diario, colección, ruleta,
    tiempo de juego y grupo.

**Probado en Studio (Play):** HUD, MEJORAS, Tienda, Pack de inicio, Diario, Ajustes y Colección,
con capturas y sin errores.

**Qué se rompió:** el título "TIENDA" salía cortado ("TIEND"): `WindowTitle` medía el texto
justo. Se le dio holgura.

Checklist: build, selene (21 avisos, antes 28) y stylua.

**Qué sigue:**
- Revisar en un teléfono, sobre todo el panel del monstruo dentro de la barra de Roblox y los
  bordes finos de las piezas chicas.
- `AngerMeter` y `Style.robuxBadge` siguen con el estilo anterior.

## 2026-10-17 (16) — La interfaz con piezas hechas en Canva

**Qué se hizo:** con una nueva referencia (la tienda MEJORAS en piedra volcánica con grietas de
lava y los botones MEJORAS y TIENDA), el usuario pidió las piezas "en Canva para mayor
exactitud".
- **Piezas:** siete, con la IA de Canva a partir de sus imágenes: panel, botón gris con canto
  dorado, botón de lava, casilla, hueco, cristales y pedestal. Se les quitó el fondo y se
  exportaron en alta.
- **Recorte:** se reescalaron para que el canto mida lo mismo que en el kit anterior
  (`tools/ui/recortar_kit_canva.py`).
- **Kit:** `Interface/Kit` las usa con sus nuevos cortes. Se suman la pieza `casilla` y
  `Kit.crystals` (en los títulos). El botón ya es gris, así que el tinte se ajusta: el gris lo
  deja igual y un color se aclara.
- **MEJORAS:** queda como la referencia:
  - pestañas de piedra oscura con canto dorado en la elegida;
  - casillas oscuras con "TIENES" en piedra gris;
  - pedestal volcánico detrás del detalle.

**Probado en Studio (Play):** MEJORAS, Tienda y HUD, con capturas y sin errores.
Checklist: build, selene (21 avisos) y stylua.

## 2026-10-17 (17) — Íconos pintados a mano y botones laterales volcánicos

**Qué se hizo:** al usuario no le gustaron los botones laterales y dijo que los íconos "se ven muy
IA". Pidió íconos nuevos en Canva con el mismo formato, y que la calavera de "monstruos
llenados" no tenía que ver. Eligió botones de casilla volcánica e íconos pintados a mano.
- **Ícono maestro:** la moneda (Canva media `MAHYVFfkyU0`). Dos sesiones generaron con ella como
  guía las dos hojas de 4x4, quitaron el fondo, exportaron y subieron:
  - HUD: `rbxassetid://135004623117532`;
  - hoja 2: `rbxassetid://89496859008486`.
- **Íconos que cambian de sujeto:** el contador de monstruos llenados lleva un monstruo verde
  contento con un pez en la boca, y la insignia `fed` sobre la cabeza es un cuenco de peces.
- **Botones laterales** (`HudButtons`): casillas volcánicas sin tinte; TIENDA sigue de lava.
  También pasan a casilla los botones de arriba y la placa "Próximo evento". `Style.robuxBadge`
  es ahora una placa chica de piedra verde.
- `Interface/Icons` apunta `fed` a la hoja 1.

**Probado en Studio (Play):** el HUD con los íconos nuevos, sin errores.
Checklist: build, selene (21 avisos) y stylua.

## 2026-10-17 (18) — Ruleta, pack de inicio y cartel de lava

**Qué se hizo (pedido del usuario):**
- **Ruleta:** usaba el mismo cofre que TIENDA. Tiene ícono propio, una rueda pintada a mano
  (Canva, media `MAHYVJpMS6g`), en la hoja HUD celda 14.
- **Pack de inicio:** un cofre con lazo violeta y el equipo adentro, pintado a mano (media
  `MAHYVEJ9RZ0`), en la celda 15. El popup lo usa en vez del regalo rosa.
- **Hoja HUD:** se volvió a subir: `rbxassetid://110280301406648`.
- **Cartel sobre la cabeza** (`OverheadBadges`): la placa es de lava, con `Kit.skin` "lava"
  como TIENDA. El ícono de monstruos es el monstruo alimentado del HUD (`fed` apunta a la celda
  3), no el cuenco de peces.

**Probado en Studio (Play):** el cartel, la ruleta del HUD y el pack de inicio, sin errores.

## 2026-10-17 (19) — Diario, regalos por jugar, ruleta y amigos

**Qué se hizo (pedido del usuario, con dos referencias de otro juego para el diario y los
regalos; solo se tomó el formato):**
- **Premio diario** (`DailyWindow` y el nuevo `DailyCard`): grilla de casillas volcánicas
  grandes, con el premio arriba, el ícono sobre rayos y el estado abajo:
  - hoy: lava con ¡RECLAMAR!;
  - cobrados: ¡RECLAMADO!;
  - mañana: "Mañana";
  - el resto: "Día N".

  El Día 7 es una tarjeta alta a la derecha, "¡GRAN PREMIO!", con el cofre sobre el pedestal y
  cristales. Arriba asoma un regalo y abajo hay un hueco con la racha. Se reclama desde la
  tarjeta de hoy.
- **Regalos por jugar** (`PlaytimeWindow` y el nuevo `PlaytimeCard`): grilla de casillas con el
  tiempo en una placa roja de piedra. La lista está en lava con ¡RECLAMAR!. El último regalo
  (2 h) va como franja ancha "¡PREMIO FINAL!". `PlaytimeEntry` es una casilla que se enciende en
  lava cuando hay regalo.
- **Ruleta** (`tools/ui/generar_ruleta.py` → `assets/ui/ruleta_v2/`):
  - rueda volcánica con la misma geometría que la anterior, medida por los ángulos de los
    separadores;
  - puntero de gema de lava;
  - ventana con resplandor de lava, Comprar de piedra gris, ¡Girar! de lava y el próximo giro
    en un hueco;
  - el soporte de la rueda del mundo pasa a basalto y lava.
- **Amigos** (`FriendBoostLabel`): placa de piedra en la esquina de abajo a la izquierda. En
  táctil va 210 px más arriba para no tapar el joystick.

**Probado en Studio (Play):** diario, regalos, ruleta (ventana y mundo) y la placa de amigos,
sin errores.
Checklist: build, selene (19 avisos) y stylua.

## 2026-10-17 (20) — Revisión: todas las tarjetas en casilla volcánica

**Qué se hizo (el usuario: "no todos tienen la misma temática nueva"):** varias pantallas seguían
con tarjetas de piedra gris teñida de colores fuertes (azul, naranja, violeta). La causa era
común: `ShopParts.sunburst`, que usan `CardParts.card` y `ShopStone.chip`, vestía la pieza
"boton" con el color pleno. Ahora es la casilla volcánica con solo un toque del color (`HINT`).
- **Arreglado de una vez:** Misiones, Renacer, Grupo, la ruleta de monstruos y los chips de la
  Tienda.
- **Colección:** las tarjetas pasan a casilla con el color de la rareza suave. Las pestañas son
  placas oscuras con el nombre en el color de su rareza y canto dorado en la elegida, como
  MEJORAS.

**Probado en Studio (Play):** Misiones, Renacer, Tienda y Colección, sin errores.

**Queda para decidir:** el mundo sigue con su estilo de mármol y oro, igual que antes: el arco
con los tableros, carteles y vitrinas.

## 2026-10-17 (21) — El arco, los tableros y los carteles del mundo en volcánico

**Qué se hizo (el usuario eligió: tableros del arco, carteles del mundo y el arco de mármol):**
- **Isla** (`tools/generar_isla.py`, regenerado `world/Isla.model.json`):
  - El arco de entrada, la plaza y la plataforma de aparición pasan a basalto con molduras de
    oro mate.
  - 20 grietas de lava (Neon) en los pilares; el emblema de la plataforma es un círculo de lava.
  - Los tableros tienen fondo de piedra casi negra con marco de basalto y filo dorado.
  - Placas nuevas (`placa_volcanica`) para los títulos TOP, "Laguna de los Gigantes", el letrero
    del abismo y los carteles de la cabaña, el puente y el estanque sagrado: piedra oscura, borde
    de lava y letras doradas con contorno (`letras_oro`).
  - Constantes nuevas (`ROCA_VOLCANICA`, `VETA_LAVA`, `ORO_MATE`…): `MARMOL_CLARO` y `ORO` siguen
    para el resto de la isla, que no cambió (comparado pieza por pieza).
- **Tableros** (`RankingBoards`): placa de piedra, cada puesto en un hueco tallado, 1-2-3 en
  oro, plata y bronce, contorno grueso. TOP RENACIMIENTOS va en dos columnas. Las filas toman el
  alto de los puestos que hay (mínimo 5): con pocos jugadores no quedan chicas.
- **Estanques** (`PondSigns`): placas de piedra con el multiplicador dorado. **Tutorial**
  (`TutorialGuide`): flecha dorada y la distancia en una placa de piedra.

**Probado en Studio (Play):** el arco con los tres tableros y el cartel del puente, sin errores.
Checklist: build, selene (17 avisos) y stylua.

---

## 2026-10-17 (22) — Zorro de agua v2: colas, hábitat de hielo, sonidos y VFX (ola 1)

**Qué se hizo:**

- Primer monstruo hecho con olas de agentes paralelos (guía, sección 12): cuatro agentes a la
  vez (geometría E3, código base y colas, hábitat, sonidos y VFX) y la integración y la prueba
  en la sesión principal.
- **Colas** (`Zorro/Colas/`, pedido del usuario: "animaciones perfectas para la cola"): una
  cadena de resortes por cola (más blanda hacia la punta, tope de 45° por junta), una onda de la
  raíz a la punta con tres senos inconmensurables y ruido (fase y ritmo por cola desde la hora
  del servidor), reacción al giro, la carrera, el salto y la sacudida, estados con mezcla suave
  (reposo, alerta, lucirse en cascada, correr, sentado, dormir, comer) y límites entre colas
  vecinas y contra el cuerpo. Es el único que escribe los huesos `Cola*_*`; los trucos y comer
  le piden un `Intent`. Sirve para 4 tramos (el zorro actual) y 5 (el v2). `Zorro/Etapas`
  reconoce el sufijo `_v2`.
- **Hábitat de agua con hielo** (modo `"ice"` de `CraterMode`, bandera `ice` en el
  `GiantDef`): témpanos, peñones con nieve, racimos de cristales, escarcha y costra en la
  orilla, nieve, niebla y luz fría. `Zorro/Guarida` es el contrato de los lugares donde se para
  o duerme, de frente a la rampa.
- **Sonidos** (19 de ProSoundEffects, en `Assets/Sounds`) con recetas por evento y etapa
  (`Audio/ZorroRecetas`), y **VFX** (`Effects/ZorroAgua`, `ZorroCubos`, `ZorroPuntas`,
  `ZorroRafagas`): cubitos de agua que flotan, espuma en las puntas, destellos de hielo y el
  brillo de los ojos. Los eventos del stand pasaron a `Giant/ZorroEventos`.

**Probado en Studio (Play, modelo actual `ZorroDeAguaE4_code` publicado a mano):** las 11
escenas de `Colas/Prueba` (junta máxima 0.79 rad, salto máximo entre cuadros 0.035 rad, ningún
choque); capturas de noche, de día desde la puerta y de costado; comida con raros; cambio a la
orca (el hielo se hunde y queda el agua) y al dragón (el hielo se va). Consola sin errores ni
avisos del juego.

**Qué se rompió:** nada visto. Pendiente: los témpanos grandes se ven casi octogonales, el zorro
queda de espaldas a la puerta (lo arregla la rutina de la ola 3), y sentado y dormido todavía no
tienen una conducta que los pida.

**Qué sigue:** aprobación de la E3 del modelo de bloques; después E1, E2, E4, poses y rig (ola 2).

---

## 2026-10-18 — Estadísticas del HUD alineadas y ranking hacia el entrenamiento

**Qué se hizo:**

- **Estadísticas del HUD**: el número y la línea chica van en un bloque (`Textos`) centrado a
  media altura de la placa, así las monedas (sin línea chica) ya no quedan pegadas arriba con
  un hueco abajo. El ícono se centra en el canto de la placa. La línea del poder pasó a
  `Vel. x107.4 · 209K/pique` para salir al mismo tamaño que las otras (antes se encogía a
  10 px). El regalo por jugar usa los mismos bordes y la misma columna de texto que las
  estadísticas (`Layout.STAT_PLATE_LEFT` / `STAT_TEXT_LEFT`).
- **Salón de la fama**: los tableros de poder, monstruos y renacimientos, sus títulos y las
  vetas de lava de sus pilares miran ahora al centro de la isla (cara `Front`), y se leen
  desde la zona de entrenamiento en vez de desde la aparición (`generar_isla.py`,
  `RankingBoards`).

**Probado en Studio (Play):** medidas de las placas (monedas centradas exacto, todas las líneas
chicas a 16 px, regalo con el mismo canto que las estadísticas) y captura de los tres tableros
desde el centro de la isla.

- **Etiqueta de amigos en táctil**: subía 210 px fijos desde abajo y en un teléfono acostado
  quedaba encima de las monedas, tapando su «x1.44». Ahora en táctil va arriba a la izquierda,
  bajo la barra de Roblox (el único hueco libre: abajo está el joystick y en el medio la
  columna). En PC sigue abajo a la izquierda.

**Probado en Studio (emulador iPhone XR):** número, ícono y placa con el mismo centro en las
cuatro filas, regalo alineado con las placas y la etiqueta de amigos sin encimarse. En PC la
etiqueta sigue abajo a la izquierda.

**Qué se rompió:** nada visto. Desde la aparición los tableros se ven ahora de espaldas (piedra
negra lisa).

**Qué sigue:** nada pendiente de esta tarea.

---

## 2026-10-18 (2) — La zona de entrenamiento es un jardín de estanques naturales

**Qué se hizo:**

- **Terreno** (`server/World/GardenShape`): la plaza empedrada pasó a ser pasto con un
  sendero de arena en anillo, cinco senderos hacia el centro y un claro alrededor del sagrado.
  Cada estanque es una hoya de barro de orilla ondulada (`WorldZones.pondEdge`), con una
  franja de barro alrededor.
- **Piezas** (paquete nuevo `tools/estanques/`): en todos, nenúfares con lotos, rocas medio
  hundidas, juncos con totoras, flores y un espíritu de luz sobre un loto grande en el centro
  (antes, cristal sobre pedestal de mármol). Y un tema por estanque: 1 Prado (margaritas y una
  rana), 2 Juncos (juncal y muellecito), 3 Lirios (lirios azules, hortensia y piedras para
  cruzar), 4 Bambú (bosquecito y farol de piedra), 5 Hongos (hongos gigantes que brillan),
  6 Cerezo (cerezo y pétalos en el agua), 7 Arce (arces rojos y luciérnagas), 8 Cascada
  (montículo con agua que cae y farolillos de papel), 9 Dorado (lotos de oro y kois),
  10 Celestial (rocas que flotan con cristales) y el Sagrado (islote con el pez dorado
  saltando, lotos celestes, kois, faroles y dos árboles sagrados). Alrededor, setos con
  flores, faroles de piedra junto al sendero y árboles y macizos en el prado. La isla bajó
  de 8060 a 6944 partes.
- **Vida** (`Training/PondLife`): los kois nadan en círculo, las rocas celestiales flotan y
  la cascada suelta bruma. `PondFx` anima ahora al espíritu y a las luciérnagas.
- **Carteles** (`Training/PondSignView`): nombre del estanque, ícono de poder con «x3» en el
  color del nivel y una cápsula con los requisitos con íconos (calavera «6» o cristal
  «150K»), «Pase sagrado» con el ícono de Robux o «¡Abierto! Entrenar» en verde. El del
  estanque en el que uno entrena se esconde. Nombres y colores en `UIConfig/Ponds`.

**Probado en Studio (Play):** capturas de día y de noche de todos los estanques
(`docs/capturas/2026-10-18-jardin-entrenamiento.jpg`, `...-estanque-cascada.jpg`); entrenar
con E en el estanque 1 (estado `training`, el poder sube cada tick); kois y rocas se mueven;
el cartel se esconde al entrenar y vuelve al parar. Consola sin errores del juego.

**Qué se rompió:** nada visto. Las vitrinas de trajes siguen de mármol y oro (son de la
tienda, no del jardín).

**Qué sigue:** probar varios jugadores en el mismo estanque natural (la tapa invisible cubre
el radio más grande de la orilla).

---

## 2026-10-18 (3) — El puente al volcán se rehace y el sagrado se queda sin pez

**Qué se hizo:**

- **Puente** (módulo nuevo `tools/puente.py`): la superficie por donde se camina no cambió
  (`bridgeEnds`, `isOnBridge`, la corriente y la cara de los monstruos siguen iguales). Ahora
  tiene un **portal** de entrada en la isla (columnas de basalto con vetas de lava, braseros
  con fuego y el cartel «AL CRÁTER DEL ABISMO» en el dintel), una **calzada** de basalto con
  camino central de losas y dos canales de lava que van del naranja al rojo, una **baranda**
  con filo de oro, 26 pilares (braseros con fuego cada tres) y estandartes rojos, y **arcos**
  de piedra entre cuatro pilas que bajan hasta el fondo del mar, con vetas de lava.
- **Estanque sagrado:** sin el pez dorado (pedido del usuario). En el islote hay un loto
  celeste y encima flota el espíritu del sagrado, como en los demás estanques (se enciende
  con el pase). El cartel bajó a 18 studs.

**Probado en Studio (Play):** capturas del puente de costado y desde la entrada
(`docs/capturas/2026-10-18-puente-volcan.jpg`, `...-puente-portal.jpg`) y del sagrado.

**Qué se rompió:** en Studio hay ~50 módulos y las piezas nuevas del mapa **duplicados**: con
un solo `rojo serve`, el plugin aplica cada cambio dos veces (parece conectado dos veces).
Las copias son idénticas y el juego funciona, pero hay que desconectar y reconectar Rojo en
Studio para limpiarlo. No se borró nada a mano. **Resuelto el mismo día:** el usuario
reconectó Rojo; quedaron 0 scripts duplicados y la zona (2573 partes) y el puente (315)
iguales al archivo.

**Qué sigue:** nada pendiente de esta tarea.

---

## 2026-10-18 (4) — Jardín despejado y más grande; arco del volcán en Blender

**Qué se hizo:**

- **Estanques sin decoración en la orilla** (pedido del usuario: estaba mal resuelta y los
  jugadores chocaban o se atoraban): fuera rocas, juncos, flores, árboles, bambú, hongos,
  faroles, cascada, muelle y rocas flotantes, y también el prado y los faroles del borde.
  Queda el agua con nenúfares y lotos (color propio por estanque), el espíritu de luz, los
  kois (7 a 11), los senderos y el seto. Se borraron `tierra.py`, `especiales.py` y
  `temas_altos.py`; los temas son una tabla en `tools/estanques/temas.py`. Los estanques se
  llaman ahora por una piedra de su color (Jade, Turquesa, Zafiro... Dorado, Celestial).
- **Zona más grande:** `plazaRadius` 108 → 122, anillo de estanques 80 → 90, estanques de
  12.5 → 14 (sagrado 18 → 20), sendero en anillo 102 → 116. La aparición, la tienda y el
  campamento se corrieron 14 studs hacia afuera y las lomas también. El prompt de entrenar
  llega a 22 studs (antes 18) para alcanzar la orilla.
- **Puerta del cráter:** arco volcánico de bloques hecho en Blender
  (`tools/blender/arco_volcan.py`, referencia del usuario): pilares de basalto en hiladas,
  ríos de lava por los bordes que siguen por el arco, grietas, tres picos con cráter de lava,
  cuernos, zócalos y brasas. Dos mallas con la misma caja (`ArcoVolcan` 4488 triángulos,
  `ArcoVolcanLava` 2916) en `assets/blender/ArcoVolcan.fbx`. En el juego (`tools/puerta.py`)
  las ponen dos anclas con ajuste "caja"; la lava va en Neon naranja por el atributo nuevo
  `Brillo` de `PropDresser`. Fuego y humo en los tres picos, cartel colgado bajo la clave con
  letras blancas de borde negro y franja de lava en el umbral. Mientras el modelo no esté en
  `PropsMapa` se ve un respaldo de basalto.

**Probado en Studio (Play):** vista general del jardín (`docs/capturas/2026-10-18-jardin-despejado.jpg`)
y la puerta con el respaldo, el cartel y el fuego; vista previa del arco en
`assets/blender/render/ArcoVolcan.png`.

**Qué se rompió:** nada visto.

**Qué sigue:** importar `ArcoVolcan.fbx` en Studio (Importar 3D) y dejar `ArcoVolcan` y
`ArcoVolcanLava` en `ServerStorage.PropsMapa`; registrar sus IDs en `Assets/Textures.luau`.

**Después (mismo día):** el usuario importó el FBX; las dos mallas quedaron en
`ServerStorage.PropsMapa` (malla 111989690973334 con textura 85903901993794, y la lava
127615265814733) y la textura se registró en `Assets/Textures.luau`. Probado en Play: PropDresser
pone el arco y la lava en Neon (ahora 255, 84, 20: más claro se veía amarillo) y borra el
respaldo. La lava importada mide 0.24 más de alto (unas brasas bajan de la base): su ancla
lleva su propia caja y `arco_volcan.py` ya la iguala para la próxima exportación.
**Duplicados de Rojo, causa:** hay dos plugins de Rojo en Studio (`RojoManagedPlugin.rbxm` en
Plugins y el de la Creator Store, 13916111004); conectados los dos, cada cambio se aplica dos
veces. Hay que dejar uno solo y reconectar. **Resuelto:** quedó un solo plugin de Rojo activo;
en Edit la puerta tiene sus 25 piezas, la zona 1008 y el puente 315 (igual que el archivo) y
no hay scripts duplicados.

---

## 2026-10-18 (5) — Estanques solo con monstruos llenados

**Qué se hizo:** los estanques ya no se abren con poder, solo llenando monstruos (o con
Robux). `Perks.pondOpen` mira solo las kills y la compra; `FishingPower.pondRequirement` dice
«15 monstruos llenados»; la siguiente meta del HUD dice cuántos monstruos faltan; el cartel
muestra la calavera con «4/15 monstruos». Se quitó `requiredPower` de la configuración y
`FishingPower.bestPondMultiplier`, que no usaba nadie.

**Qué se rompió:** nada visto. `rojo build` y `selene` sin errores nuevos.

**Qué sigue:** revisar la curva de kills de `Config/Progression` si los estanques altos se
sienten lejos sin el atajo del poder.


---

## 2026-10-18 (6) — Eventos que se ven en el cielo y HUD sin palabras

**Qué se hizo:**

- **Cielo de evento** (`Ambient/EventSky`, mezclado por `SkyCycle` encima de todo): cada
  evento pinta el cielo entero con hora, luz, color, bruma (`Haze`) y resplandor propios.
  Pesca dorada: atardecer dorado y naranja; Frenesí: tarde turquesa eléctrica; Lluvia de
  monedas: amanecer rosado; Poder doble: noche violeta. Entra y sale en 2.5 s; en el cráter
  pesa algo menos para que se siga viendo el hábitat.
- **Efectos en el mundo** (`Ambient/EventFx` y `EventShapes`, solo en el cliente):
  destellos dorados que caen, lluvia celeste con relámpagos y trueno, monedas de oro que
  llueven girando y una aurora de rayos celestes y violetas que ondula. En modo rápido, menos
  partículas y monedas y sin aurora.
- **Anuncio grande** al empezar (`Menus/EventIntro`): ícono del evento sobre rayos que giran,
  el nombre enorme en su color y qué da. La placa del evento lleva su ícono y late mientras
  dura; el aviso chico de `Notices` se quitó para no repetir. Ícono por evento en
  `Config/Events`.
- **HUD sin palabras:** las estadísticas son ícono, número grande y multiplicador (fuera
  «monstruos llenados», «peces en la canasta» y la velocidad); el cartel de los estanques
  dice «4/15».

**Probado en Studio (Play):** los cuatro eventos con el comando de admin `event`, con
capturas en `docs/capturas/2026-10-18-evento-*.jpg`; el anuncio y la placa con su ícono.

**Qué se rompió:** nada visto. La aurora pasó por tres intentos (bloques, cintas, rayos
verticales); quedó la de rayos.

**Qué sigue:** probar los eventos en un teléfono (rendimiento de la lluvia y la aurora).

---

## 2026-10-18 (7) — Flecha guía del tutorial, como en los simuladores

**Qué se hizo:** el marcador dorado que flotaba sobre el destino se cambió por una flecha
verde gruesa que flota junto al jugador, a la altura del pecho, lo sigue y apunta hacia
donde tiene que ir (`Menus/GuideArrow`), y una fila de chevrones verdes en el piso que corren
hacia adelante por el camino de verdad, calculado con PathfindingService
(`Menus/GuidePath`: al volcán va por el puente). Se recalcula si se sale del camino; al
llegar al destino desaparece. Todo es local: nada queda puesto en el mapa (pedido del
usuario, con el video de referencia de «Construye la Pirámide»).

**Probado en Studio (Play):** misión 1 desde la aparición, caminando hacia la flecha hasta
el muelle (`docs/capturas/2026-10-18-flecha-guia.jpg`).

**Qué se rompió:** nada visto. La flecha y los chevrones van 1.3 y 1.4 studs más arriba de lo
pensado porque el pasto alto del terreno los tapaba.

**Qué sigue:** el video tutorial (tomas en Studio con el minotauro).

---

## 2026-10-18 (8) — Velocidad inicial 22 y flechas guía flotando

**Qué se hizo:**

- **Velocidad:** se empieza a 22 (antes 16, la de Roblox); las botas van de 22 a 52
  (24, 26, 29, 32, 35, 38, 40, 42, 44, 46, 48, 50, 52), con los mismos precios. El puente sube
  a 56 y nunca frena a nadie (`math.max` con la velocidad de las botas: antes las Botas de
  Hermes, 46, iban más lento sobre el puente de 44). `StarterPlayer.CharacterWalkSpeed` = 22.
- **Flechas guía:** fuera los chevrones del piso. Ahora es una fila de 5 flechas amarillas
  flotando a la altura del pecho por el camino (`GuidePath`), más la del jugador
  (`GuideArrow`), todas con un solo contorno negro. Cada flecha del camino está clavada en
  una marca fija del camino (cada 8 studs) y mira hacia donde sigue: al caminar no giran ni
  se corren (antes se calculaban desde la posición del jugador y se torcían). La del jugador
  gira suave hacia la dirección nueva.

**Probado en Studio (Play):** velocidad 22 al aparecer; los ángulos de las flechas del
camino no cambian mientras el jugador camina; flechas amarillas camino al muelle.

**Qué se rompió:** nada visto.

---

## 2026-10-18 (9) — Flechas guía que fluyen

**Qué se hizo:** sin la flecha del jugador (pedido del usuario). Las flechas del camino ahora
son una cinta: avanzan deslizándose sin parar por el camino (9 studs/s), aparecen y se
desvanecen suave en las puntas de la fila y son planas como las de los simuladores. El
camino de PathfindingService se redondea (Chaikin, 3 pasadas) para que no giren en seco en
las esquinas. Siguen saliendo solo del camino, no del jugador: no se tuercen al caminar.

**Probado en Studio (Play):** siguiendo cada flecha cuadro a cuadro durante 90 cuadros, el
paso máximo fue 0.18 studs y el giro máximo 0.4° por cuadro (antes saltaban 8 studs al
aparecer y desaparecer).

**Qué se rompió:** nada visto.

**Después (mismo día):** las flechas se quedaban en el camino viejo mientras el jugador
caminaba fuera de él y solo se ponían al día al detenerse (el camino se recalculaba a los
16 studs y cada 1.5 s). Ahora la cinta sale del jugador en cada cuadro y se une al camino
10 studs más adelante; el camino se recalcula a los 10 studs y cada 0.6 s. Probado: moviendo
al jugador 33.6 studs de lado a 22 studs/s, la flecha más cercana nunca quedó a más de
11.9 studs (la separación normal de la cinta).

---

## 2026-10-18 (10) — Flechas guía en línea recta

**Qué se hizo (pedido del usuario: «que sea recta la línea, que no se curve ni
desaparezcan»):** `GuidePath` ya no usa PathfindingService. Es una fila recta de 6 flechas
amarillas que sale del jugador y apunta al destino de la misión, en tramos rectos (al volcán:
primero a la entrada del puente, después por el puente; lo decide `TutorialGuide`). Siempre
se ven todas y opacas; una onda suave las recorre hacia adelante. Al cambiar de tramo la fila
gira suave. Si el destino está más cerca que la fila, solo se ven las que caben.

**Probado en Studio (Play):** desvío de la recta 0.00 studs y las 6 visibles y opacas, quieto
y caminando de lado a 22 studs/s (`docs/capturas/2026-10-18-flecha-guia.jpg`).

**Qué se rompió:** nada visto. La primera partida de la prueba corrió con el código viejo
(Studio ya estaba en Play cuando Rojo sincronizó): hubo que detenerla y volver a empezar.

---

## 2026-10-18 (11) — Marinero v2: el traje de todos, sin piezas sueltas ni texturas rotas

**Qué se hizo (pedido del usuario: un avatar sin tirones ni piezas sueltas; el de antes se veía
raro de texturas):** el Marinero se rehízo desde cero en Blender por script
(`tools/blender/marinero_v2*.py`), con la misma identidad (gorra blanca con banda marino,
barba, chaleco abierto, pañuelo rojo, mangas a rayas, botas). El usuario eligió estilo de
bloques Roblox, piel fija y cara dibujada.

- **Una sola malla cerrada:** cada parte es un tubo de anillos redondeados; cabeza, gorra,
  brazos y piernas se unen al torso con un puente corto justo en su pivote.
- **Texturas nítidas:** colores planos de una paleta, y cara, pecho y espalda dibujados con
  PIL (`marinero_v2_textura.py`). Nada de horneado.
- **Mismos 16 huesos:** el juego lo mueve sin cambiar código. 5,332 triángulos (el de Meshy
  rondaba 15,000).
- En Studio: `ServerStorage.TrajeMarinero` es el nuevo; el de Meshy quedó en
  `ServerStorage.Respaldos.TrajeMarinero_meshy`. IDs nuevos en `Assets` (malla 140300273939135,
  textura 133730397975971).

**Qué se rompió (y se arregló antes de importar):** en los renders de poses extremas
(`renders/marinero_v2/`) aparecieron tres cosas: un pliegue negro detrás de la rodilla a 90°
(los anillos se cruzaban), un pedazo de manga que asomaba junto al torso al levantar el brazo
(pivote del hombro bajo) y caras de área cero en el tobillo (dos anillos iguales a la misma
altura). Ver `docs/decisiones.md`.

**Probado en Studio (Play):** el jugador lleva el traje nuevo con sus 16 huesos, el rig mueve
15 (la Raiz no se anima), la caña sale de la mano y la consola no muestra errores nuestros.

**Qué sigue:** guardar el lugar en Studio (el modelo vive en el `.rbxl`). Si gusta, el mismo
método para el Rey del Mar y el Dios del Volcán.
