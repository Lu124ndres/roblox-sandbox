# Assets visuales

Seguimiento de cada imagen generada para el juego: de dónde salió, dónde se usa y
en qué estado está.

## Flujo

1. Producir el PNG (Canva, PIL o Blender, según la pieza; ForgeGUI nunca se usó) con el prompt o el script registrado en la tabla.
2. Guardar el archivo fuente en `assets/textures/`.
3. Subirlo en Studio: **Asset Manager** → **Images** → **Import**.
4. Copiar el ID resultante a `src/shared/Assets/` (`init.luau` sección `UI`, o `Textures.luau`).
5. Actualizar el estado en la tabla.

Mientras un asset no exista, su entrada en `Assets.luau` queda como
`"rbxassetid://0"` y la fila aquí queda como `pendiente`.

## Reglas de generación

- Fondo transparente siempre.
- 9-slice para todo lo que se estira (paneles, botones, barras).
- Nada de texto dentro de la imagen. Los textos van en TextLabels.
- Máximo 1024x1024.
- Generar kits completos de una pasada en lugar de piezas sueltas, para mantener
  consistencia de estilo.
- Las piezas son imagen estática. Cualquier movimiento se hace por código.

## Estados

`pendiente` → `subido` → `moderado` → `listo`

## Tabla

| Nombre | Tipo | Dónde se usa | Prompt usado | Estado |
|---|---|---|---|---|
| PanelBackground *(ejemplo)* | ui | Fondo de paneles de menú | "flat rounded panel, dark slate, subtle border, transparent background, 9-slice friendly" | pendiente |

## Kit "piedra" de la interfaz

Pedido del usuario (2026-10-17): rehacer la interfaz con piedra oscura tallada, texto dorado,
marco de lava para lo importante y gemas azules. **No sale de ForgeGUI:** lo dibuja
`tools/ui/generar_kit_piedra.py` (PIL y numpy). Las imágenes van a `assets/ui/kit_piedra/`
(`_muestra.png` es solo para revisar) y se subieron por el MCP de Studio (`upload_image`).
Son 9-slice; los cortes están en `Interface/Kit`.

| Nombre | Archivo | Uso | `Assets.UI` | Estado |
|---|---|---|---|---|
| PiedraPanel | panel.png | Ventanas, placas del HUD | 96013070309197 | subido |
| PiedraHondo | panel_hondo.png | Huecos: barras, listas, casillas | 132510118089766 | subido |
| PiedraBoton | boton.png | Botones (casi blanco, se tiñe) | 134425626904491 | subido |
| PiedraLava | lava.png | TIENDA y botones estrella | 91067841385407 | subido |
| PiedraGema | gema.png | Gemas de adorno | 96530857668285 | subido |

## Kit "lava" de la interfaz (Canva)

Reemplaza las piezas del kit "piedra" (2026-10-17): el usuario pasó una captura de la tienda
MEJORAS en piedra volcánica con grietas de lava y los botones MEJORAS (piedra gris con canto
dorado) y TIENDA (marco de lava), y pidió hacerlo "en Canva para mayor exactitud".

**Cómo se hizo:**
1. Las dos referencias se subieron a Canva. Cada pieza se generó con la IA de Canva usando la
   referencia, con el prompt "Game UI asset in exactly the same hand-painted style as the
   reference…, no text, even borders for 9-slice, isolated on white".
2. Se quitó el fondo en Canva.
3. Se colocó cada pieza en una página de un diseño auxiliar y se exportó como PNG transparente:
   `assets/ui/kit_canva/crudo/`.
4. `tools/ui/recortar_kit_canva.py` las recorta y las achica para que el canto mida lo mismo
   que en el kit anterior: los `SliceScale` de cada pantalla siguen valiendo. Los cortes quedan
   en `cortes.json`.
5. Se subieron por el MCP de Studio.

Las referencias no se suben al repo.

| Nombre | Archivo | Uso | `Assets.UI` |
|---|---|---|---|
| PiedraPanel | panel.png | Ventanas y placas del HUD | 137296723636788 |
| PiedraHondo | hueco.png | Huecos tallados | 120432474669335 |
| PiedraBoton | boton.png | Botones (piedra gris con canto dorado; se tiñe) | 130492460203337 |
| PiedraLava | lava.png | TIENDA y botones estrella | 80491001045798 |
| PiedraCasilla | casilla.png | Casillas de MEJORAS y arte del detalle | 103089949967085 |
| PiedraCristales | cristales.png | Cristales junto a los títulos | 71352910897295 |
| PiedraPedestal | pedestal.png | Pedestal del detalle de MEJORAS | 76404155830524 |

La gema azul (`PiedraGema`) sigue siendo la del kit anterior: va en el panel del monstruo.

## Ruleta v2 (piedra volcánica)

Pedido del usuario (2026-10-17): "la ruleta no está con la temática". La rueda y el puntero
los dibuja `tools/ui/generar_ruleta.py` (PIL y numpy) con la geometría exacta de la rueda
anterior (1024 px, centro 512, 8 casillas de 45° con la 1 arriba, casillas hasta r = 446 y aro
hasta r = 508; puntero de 256 px con la punta en (128, 240)), porque `SpinWheelView` pone los
premios encima con esas medidas. Archivos en `assets/ui/ruleta_v2/` (`_muestra.png` lleva los
íconos de los premios donde van, solo para revisar). Subidos por el MCP de Studio.

| Nombre | Archivo | Uso | `Assets.UI` |
|---|---|---|---|
| RuedaRuleta | rueda.png | Rueda de la ventana Ruleta y de la ruleta del mundo (9 casillas desde el 2026-10-21; la 9, violeta, es la caña suprema) | 103590278651247 (antes 86382670718617, de 8) |
| PunteroRuleta | puntero.png | Gema de lava que marca el premio | 71593213487154 |

## Modelos y texturas de mesh

No salen de ForgeGUI: el modelo viene de Meshy (generado desde el concept art) y las
texturas se hornean en Blender (ver `blender-pipeline.md`). Se suben juntos con
**File → Import** en Studio, que crea el `MeshPart` y su `SurfaceAppearance`.

"Subido" significa que el asset existe en Roblox a nombre de la cuenta (comprobado con
`MarketplaceService:GetProductInfo`). El estado de moderación no se puede consultar
desde Studio; pasa a `moderado` cuando se confirme a mano en Creator Hub.

| Nombre | Tipo | Archivo fuente | ID | Estado |
|---|---|---|---|---|
| OrcaE1 | mesh | `assets/blender/OrcaE1.fbx` | `116864238392648` | subido |
| OrcaE1Color | textura (color) | `assets/textures/OrcaE1_color.png` | `78747470199717` | subido |
| OrcaE1Normal | textura (normal) | `assets/textures/OrcaE1_normal.png` | `79662647526007` | subido |
| OrcaE1Roughness | textura (rugosidad) | `assets/textures/OrcaE1_roughness.png` | `86419609055550` | subido |

## Íconos v4 (pintados a mano, Canva)

Reemplazan a las hojas 1 y 2 (2026-10-17). El usuario dijo que los anteriores "se ven muy IA",
pidió mantener el formato y eligió el estilo **pintado a mano**: pinceladas visibles, tonos
terrosos, contorno marrón y nada de brillo plástico.

**Cómo se hicieron:**
1. Primero un ícono maestro, la moneda (Canva media `MAHYVFfkyU0`).
2. Cada ícono se generó con la IA de Canva usando la moneda y la referencia volcánica como
   guía de estilo.
3. Se quitó el fondo en Canva y se exportó en PNG transparente de 1024 px.
4. Cada uno se encajó en 236 px dentro de una celda de 256.

Los archivos están en `assets/ui/iconos/v4/`: hojas, íconos sueltos, `crudo/` y `crudo2/`. Las
tablas de media de Canva de cada ícono quedan en el devlog del 2026-10-17 (17).

| Hoja | Archivo | `Assets.UI` | Celdas (por filas) |
|---|---|---|---|
| 1 (HUD) | `v4/iconos_v4_hud.png` | IconSheet = 110280301406648 (código `Assets/init.luau`, 2026-10-26) | moneda, poder, canasta con peces, **monstruo alimentado** (reemplaza la calavera de "monstruos llenados"), canasta, cofre, regalo, engranaje, pez, boleto, amigos, grupo, colmillo, cuenco de peces (insignia `fed`) |
| 2 | `v4/iconos_v4_hoja2.png` | IconSheet2 = 97933580602007 → 89496859008486 | caña, botas, corona, estanque, rayo, orca, minotauro, dragón (el nuevo), zorro, regalo rosa, flecha, carne, rayos y brillo (copiados de la hoja anterior) |

**Hoja 3** (2026-10-21): `v4/iconos_v4_hoja3.png`, `Assets.UI.IconSheet3 = 101327392927525`
(reemplaza a la hoja 3 vieja del monstruo panzón). Celdas: 0 calendario (premio diario, media
`MAHYrGtj_3Y`, sin fondo; con fondo `MAHYrCptBMc`), 1 caña suprema de la ruleta (`MAHYrJQ3VAE`;
con fondo `MAHYrC4E5bU`), 2 Dios del Volcán, 3 Rey del Mar. El calendario y la caña se generaron
con la moneda maestra como guía; están en 200 px (`v4/crudo2/`) porque el conector no da más:
para mejorarlos, bajar la versión de 1024 desde Canva, volver a armar la hoja y subirla.

**Hoja 4, Índice de peces** (2026-10-21): `v4/iconos_v4_indice.png`, `Assets.UI.IconSheet4 =
119150930462543`. Una sola generación de 3x3 en Canva (media `MAHYsz8cTOc`, con la moneda maestra
y la caña suprema como guía de estilo), exportada a 1080 px desde `DAHYr01q5ww`
(`v4/indice/crudo/hoja_indice.png`) y cortada con `tools/ui/armar_hoja_indice.py`. Celdas: 0 libro
(`dex`, sección Todos), 1-6 medallones de Común, Poco común, Raro, Épico, Legendario y Mítico
(`dexComun` ... `dexMitico`), 7 trébol (`luck`, suerte de las secciones), 8 candado (`lock`, peces
sin descubrir).

**Caras de los trajes de pase** (2026-10-20; desde el 2026-10-21 en la hoja 3): `v4/volcanoGod.png` (Dios del Volcán) y `v4/seaKing.png` (Rey del Mar), en celda de
256 como los demás. Se generaron en Canva con la moneda maestra y el minotauro v4 como guía de
estilo y una captura de cada traje en Studio como guía de diseño; fondo quitado en Canva.
Media de Canva: Dios `MAHYj4m_JoE`, Rey `MAHYj8u8m8w` (con fondo: `MAHYj5mH0GA`,
`MAHYj86ZLA8`). El conector solo dio la vista previa de 200 px (`v4/crudo2/`); para una versión
de 1024 px, descargarlos desde Canva. Caben en las celdas libres 14 y 15 de la hoja 2.

## Íconos del HUD (v3, reemplazados por los v4)

Imágenes estilo 3D generadas con IA (Canva, mismo prompt base: "Game UI icon for a Roblox
simulator, glossy 3D cartoon render style, thick dark outline... on a plain white
background"), recortadas a fondo transparente y juntadas en una hoja de 3x3 de 256 px
(`assets/ui/iconos/iconos_hud.png`, subida con el Gestor de recursos de Studio;
`Assets.UI.IconSheet = 106022589512367`). `Interface/Icons` recorta cada una con
ImageRectOffset. Si la hoja faltara, se usa el modelo 3D de `Icon3D` como reserva.

| Lugar en la hoja | Archivo | Uso |
|---|---|---|
| 0 | moneda.png | Monedas, atajo x Monedas |
| 1 | poder.png | Poder, atajo x Poder |
| 2 | canasta.png | Peces en la canasta |
| 3 | kills.png | Kills |
| 4 | tienda.png | Tienda |
| 5 | robux.png | Tienda de Robux |
| 6 | premio.png | Premio diario |
| 7 | ajustes.png | Ajustes |
| 8 | pez.png | Colección de peces |

Para agregar un ícono: generarlo con el mismo prompt base, recortarlo, armar otra hoja
(o una fila más) y subirla; poner el ID en `Assets.UI`.

### Hoja 2 (tiendas)

`assets/ui/iconos/iconos_hoja2.png` (4x4 de 256 px), `Assets.UI.IconSheet2 =
97933580602007`. Mismo prompt base. (Se probó una orca y un dragón iguales a los modelos 3D,
`orca_modelo.png` y `dragon_modelo.png`, hoja 127258628735083; se volvió a los de antes.) Las celdas 12 y 13 no son íconos: son los rayos
blancos (sunburst) que `ShopParts.sunburst` tiñe y hace girar detrás de las tarjetas, y
un brillo redondo; se dibujaron con Python (PIL), no con IA.

| Lugar | Tipo en `Icons` | Archivo | Uso |
|---|---|---|---|
| 0 | rod | cana.png | MEJORAS (botón y pestaña Cañas) |
| 1 | boots | botas.png | Pestaña y filas de Botas |
| 2 | crown | corona.png | Tarjeta VIP |
| 3 | pond | estanque.png | Tarjetas de estanques |
| 4 | bolt | rayo.png | Banner del entrenamiento del servidor |
| 5–8 | orca, minotaur, dragon, fox | orca/minotauro/dragon/zorro.png | Retrato del panel de hambre y elegir el siguiente monstruo |
| 9 | giftPink | regalo.png | Botón rosa de regalar |
| 10 | arrow | flecha.png | (libre: subir de nivel) |
| 11 | meat | carne.png | Llenar al monstruo |

### Hoja 3

`assets/ui/iconos/iconos_hoja3.png` (4x4 de 256 px), `Assets.UI.IconSheet3 =
99850577116916`. Canva (IA) con fondo quitado en Canva.

| Lugar | Tipo en `Icons` | Archivo | Uso |
|---|---|---|---|
| 0 | fed | monstruo_lleno.png | Monstruos llenados en el cartel de la cabeza (OverheadBadges) |
| 12 | sunburst | (dibujado) | Rayos de fondo |
| 13 | glow | (dibujado) | Brillo |

### Equipo de MEJORAS (un ícono por nivel)

Canva (IA, "icono 3D estilo juego") por cada caña, canasta y botas, fondo quitado en
Canva y juntados en hojas de 5 columnas con celdas de 200 px; la celda es nivel - 1 por
filas. Los usa `Interface/GearIcons` (MEJORAS, pestañas, pack de inicio).

| Hoja | Archivo | Niveles | `Assets.UI` |
|---|---|---|---|
| Cañas | `assets/ui/iconos/equipo_rod.png` (1000x800) | 20 | EquipoRod = 79873240212746 |
| Canastas | `assets/ui/iconos/equipo_basket.png` (1000x600) | 14 | EquipoBasket = 125162908853974 |
| Botas | `assets/ui/iconos/equipo_boots.png` (1000x600) | 14 | EquipoBoots = 122825125598846 |

El ícono de Roblox Premium del cartel de la cabeza es el que trae Roblox
(`rbxasset://textures/ui/PlayerList/PremiumIcon@3x.png`, `Assets.UI.PremiumIcon`).

## Pantalla de carga (Canva)

Pedido del usuario (2026-10-20): pantalla de carga con la temática del juego y "los monstruos,
que son cubos". Los gigantes v2 de bloques (minotauro, dragón y zorro de agua, etapa 4) se
renderizaron con Blender en modo consola desde `assets/blender/*_v2/e4_rig.blend` y se subieron a
Canva como referencia; la IA de Canva pintó la isla al atardecer con los tres gigantes de bloques,
sin texto (el usuario la eligió entre cuatro opciones). Se exportó a 1920×1080 desde la página
"Carga isla" del lienzo auxiliar de la interfaz, se achicó a 1024×576 y se subió por el MCP de
Studio. El título, la barra, el pez y las chispas no son imágenes: los dibuja el código.

| Nombre | Archivo | Uso | `Assets.Loading` |
|---|---|---|---|
| Background | `assets/ui/carga/fondo.png` (fuente: `fondo_crudo.png`) | Fondo de la pantalla de carga | 107415033029925 |

## Sonidos

Audio público de la Tienda de creadores (se buscó en Studio y se copió el ID) o sonidos
que trae Roblox instalados (`rbxasset://sounds/...`, no hay que subirlos). Volumen y tono
en `UIConfig.Sounds`. Todos verificados con `IsLoaded` en Studio el 2026-10-12.

| Clave | Uso | ID / ruta | Búsqueda en la tienda |
|---|---|---|---|
| OceanWaves | Ambiente en bucle | `137826155053556` | ocean waves |
| Seagull | Graznido de gaviota | `111686121161530` | seagull |
| Cast | Latigazo al lanzar | `135315310485417` | whoosh swing |
| Bite | Pica el pez | `137273815815490` | bubble pop |
| Reel | Recoger el sedal | `79404754846319` | fishing reel |
| Chomp | La Orca come | `99444504938110` | eating chomp |
| OrcaCall | Llamado de la Orca adulta | `9126210261` "Whale Vocal Underwater Talk With Sea Creature 1" (ProSoundEffects, 2026-10-22) | whale vocal |
| StageUp | La barra cambia de estado | `3454671965` | victory fanfare |
| Coins | Cobrar monedas | `135483737426662` | coin collect |
| Click | Botones | `139719503904449` | ui click |
| Roar | Rugido genérico (furia de la orca adulta, gigantes sin receta) | `9113985604` "Creature Roar Mix Of Animals Gate Creaks 1" (ProSoundEffects, 2026-10-22) | creature roar |
| HorrorAmbience | Ambiente del cráter | `138890398994853` | dark ambience |
| Thunder | Relámpagos del cráter | `139319051979882` | thunder |
| PowerTick | Tick de entrenamiento | `137273815815490` (Bite, más agudo) | bubble pop |
| RodOut, Plop, Catch, Escape, Spout, BigSplash | Agua y caña | `rbxasset://sounds/impact_water.mp3`, `action_swim.mp3`, `action_jump.mp3` | instalados |
| FishFlop | Coletazos del pez sobre la cabeza | `9114447775` | fish flop |
| CatchPop | Captura común y poco común | `109359226723492` | cartoon pop |
| RareCatch | Captura rara | `108936817882815` | rare item drop |
| EpicCatch | Captura épica | `112485797063762` | level up |
| LegendaryCatch | Captura legendaria y mítica | `134821092416328` | level up |
| Whoosh | Peces lanzados al gigante | `123796710194563` | whoosh |
| CoinPop | Cada moneda que llega al contador | `135483737426662` (Coins, más agudo) | coin collect |
| MusicIsland | Música de la isla | `128770946473000` "The Fisherman's Small Boat" (DistroKid) | tropical island |
| MusicCrater | Música del cráter | `1843867314` "Tension Repeat Drones 29" (APM) | epic boss battle |
| MusicRest | Música del descanso (monstruo vencido) | `9042798478` "Defender Of Men" (APM, 2026-10-22) | epic victory orchestral |

### Voces de cría y momentos de los gigantes (2026-10-22)

Todas de ProSoundEffects (la librería con licencia de Roblox), verificadas con
`PreloadAsync` en Studio. Donde PSE no tiene el animal real se usa el más parecido, con el
tono ajustado (anotado como "sustituto").

| Clave | Uso | ID | Nombre en PSE |
|---|---|---|---|
| OrcaCalfSqueak | Llamado de la orca cría | `9114124037` | Dolphins Water Movement 7 |
| OrcaCallDeep | Canto hondo de la anciana | `9126210358` | Whale Vocal Underwater Talk With Sea Creature 3 |
| OrcaBlow | Resoplido del espiráculo (sustituto) | `9120560453` | Water Hose Gun 3 |
| OrcaHungry | Hambre de la orca adulta (sustituto: elefante grave) | `9113173813` | Asian Elephant Squeaks Grunts Blows 1 |
| OrcaFull | Se calma, saluda con la aleta | `9114123688` | Dolphins Water Movement 2 |
| MinoCalf | Balido del becerro (sustituto: bramido agudo; no hay terneros) | `9113628549` | Bull Bellows 22 |
| MinoHungry | Hambre del minotauro adulto | `9125470318` | Creature Growls Lion Deep Guttural Rumbling 8 |
| MinoHappy | Festejo del baile, se calma | `9113636328` | Bull Grunts Snorts Constant 6 |
| MinoScratch | Se rasca la cabeza (sustituto) | `9125408272` | Brush Scrub Rubbing On Leather Seat Cushion 1 |
| DragonHatchling | Trinos de la cría (sustituto: periquito grave) | `9117236949` | Parakeet Chirps 7 |
| DragonBabyRoar | Rugido de cría | `9114166971` | Dragon Wailing 1 |
| DragonHungry | Hambre del dragón adulto | `9116309717` | Lions Beastly 2 |
| DragonJoy | Festejo al comer, se calma | `9117236763` | Parakeet Chirps 3 |
| ZorroScream | Chillido del zorro adulto (sustituto: coyote) | `9113951583` | Coyote Cu Whimpering Yelping Crying 3 |
| ZorroGekker | Cacareo de zorro (sustituto: ratón grave) | `9117009021` | Mouse Vocal 30 |
| ZorroHungry | Hambre del zorro adulto | `9113951479` | Coyote Cu Whimpering Yelping Crying 1 |
| ZorroFull | Se calma: jadeo contento (sustituto: tigre) | `9120038042` | Tiger Breathing 9 |

### Capas de la pesca y del entrenamiento (2026-10-22)

ProSoundEffects, verificadas con `PreloadAsync`. Las usan `client/Audio/FishingSounds` y
`TrainingSounds`.

| Clave | Uso | ID | Nombre en PSE |
|---|---|---|---|
| FishReelClick | Cada toque del carrete (sube de tono con la barra) | `9126261241` | Wooden Ratchet Clicking Bursts Squeaking Wheel 5 |
| FishReelZip | El sedal sale zumbando / el carrete al clavar | `9114451733` | Fishing Reel 5 |
| FishRodSwish | Latigazo de la caña | `9119711846` | Swish Thin 1 |
| FishBloop | Bloop del corcho, del pique y del escape | `9112751536` | Bubble Bloop High Pitched Cute 1 |
| FishLineTug | Tirón del sedal al picar | `9125406760` | Bow Stretches Wood Creaking Ripping Tearing 5 |
| FishLineSnap | Se corta el sedal | `9113612424` | Buggy Whip Quick Swish Crack 2 |
| FishSplash | El pez rompe el agua | `9119481909` | Splash Thunking Impact 1 |
| FishBasket | El pez entra a la canasta (sustituto: bolsa) | `9113246398` | Bag Dull Sprinkling Impact 3 |
| FishTing | El pez llega a la mano | `9119937112` | Tea Cup Impacts 14 |
| PowerTing | Notas de la escala del entrenamiento | `9116223604` | Large Metal Triangle Single Ringing Hits 1 |
| PowerWhoosh | Cada 10 ticks: el "fiu" que sube | `9125805579` | Rising Whoosh Hissing Build Up Ascending Swoosh 2 |
| PowerReward | Cada 10 ticks: acorde de premio | `9116394545` | Magic Glows Soft Clusters Of Chiming Hits 1 |

La música es de catálogo con licencia de Roblox (APMOfficial / DistrokidOfficial), así
que funciona en cualquier juego. Verificada con `IsLoaded` el 2026-10-13. Se silencia con
el ajuste Música (SoundGroup `Musica`); los demás sonidos van a `Efectos`.

## Íconos v4 del equipo de la tienda (2026-10-21)

Un ícono por nivel: 40 cañas, 40 canastas y 40 botas, pintados a mano en Canva con la moneda
maestra (`MAHYVFfkyU0`) y la caña suprema (`MAHYrJQ3VAE`) como guía de estilo. Prompts en
`tools/ui/equipo_v4.json`; `tools/ui/armar_hojas_equipo.py` quita el fondo, encaja cada ícono en
200 px y arma hojas de 5x4 (niveles 1-20 y 21-40).

| Hoja | Archivo | `Assets.UI` |
|---|---|---|
| Cañas 1-20 | `v4/equipo/equipo_rod_1.png` | EquipoRod1 = 81312902149564 |
| Cañas 21-40 | `v4/equipo/equipo_rod_2.png` | EquipoRod2 = 139047610937566 |
| Canastas 1-20 | `v4/equipo/equipo_basket_1.png` | EquipoBasket1 = 103473328998101 |
| Canastas 21-40 | `v4/equipo/equipo_basket_2.png` | EquipoBasket2 = 134760141920327 |
| Botas 1-20 | `v4/equipo/equipo_boots_1.png` | EquipoBoots1 = 132274235368393 |
| Botas 21-40 | `v4/equipo/equipo_boots_2.png` | EquipoBoots2 = 78348750552780 |

Las cañas 1-21 se generaron de a una (200 px, el máximo del conector). Las demás salieron de hojas
de 3x3 exportadas a 1080 px desde el diseño de Canva `DAHYr01q5ww` (unos 360 px por ícono y 9 por
generación: la cuota de Canva deja ~1 imagen cada 5 min). Media de cada hoja en `media.json`.
Subidas con `upload_image` del MCP de Studio, sirviendo la carpeta con `py -m http.server`.
