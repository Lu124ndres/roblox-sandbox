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

