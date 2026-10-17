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
