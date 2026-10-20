# Assets visuales (ForgeGUI)

Seguimiento de cada imagen generada para el juego: de dónde salió, dónde se usa y
en qué estado está.

## Flujo

1. Generar el PNG en ForgeGUI con el prompt registrado en la tabla.
2. Guardar el archivo fuente en `assets/textures/`.
3. Subirlo en Studio: **Asset Manager** → **Images** → **Import**.
4. Copiar el ID resultante a `src/shared/Assets.luau` (sección `UI` o `Textures`).
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
- ForgeGUI produce imagen estática. Cualquier movimiento se hace por código.

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
| RuedaRuleta | rueda.png | Rueda de la ventana Ruleta y de la ruleta del mundo | 86382670718617 |
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
| 1 (HUD) | `v4/iconos_v4_hud.png` | IconSheet = 135004623117532 | moneda, poder, canasta con peces, **monstruo alimentado** (reemplaza la calavera de "monstruos llenados"), canasta, cofre, regalo, engranaje, pez, boleto, amigos, grupo, colmillo, cuenco de peces (insignia `fed`) |
| 2 | `v4/iconos_v4_hoja2.png` | IconSheet2 = 97933580602007 → 89496859008486 | caña, botas, corona, estanque, rayo, orca, minotauro, dragón (el nuevo), zorro, regalo rosa, flecha, carne, rayos y brillo (copiados de la hoja anterior) |

**Caras de los trajes de pase** (2026-10-20, sueltos, todavía no están en ninguna hoja ni
subidos): `v4/volcanoGod.png` (Dios del Volcán) y `v4/seaKing.png` (Rey del Mar), en celda de
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
| OrcaCall | Llamado de la Orca | `5696958591` | orca |
| StageUp | La barra cambia de estado | `3454671965` | victory fanfare |
| Coins | Cobrar monedas | `135483737426662` | coin collect |
| Click | Botones | `139719503904449` | ui click |
| Roar | Rugido del gigante | `133651202885353` | monster roar |
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
| MusicRest | Música del descanso | `9046678292` "Work Like A Champion" (APM) | epic boss battle |

La música es de catálogo con licencia de Roblox (APMOfficial / DistrokidOfficial), así
que funciona en cualquier juego. Verificada con `IsLoaded` el 2026-10-13. Se silencia con
el ajuste Música (SoundGroup `Musica`); los demás sonidos van a `Efectos`.
