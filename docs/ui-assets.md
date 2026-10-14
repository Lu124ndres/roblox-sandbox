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

## Íconos del HUD

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
97933580602007`. Mismo prompt base. Las celdas 12 y 13 no son íconos: son los rayos
blancos (sunburst) que `ShopParts.sunburst` tiñe y hace girar detrás de las tarjetas, y
un brillo redondo; se dibujaron con Python (PIL), no con IA.

| Lugar | Tipo en `Icons` | Archivo | Uso |
|---|---|---|---|
| 0 | rod | cana.png | MEJORAS (botón y pestaña Cañas) |
| 1 | boots | botas.png | Pestaña y filas de Botas |
| 2 | crown | corona.png | Tarjeta VIP |
| 3 | pond | estanque.png | Tarjetas de estanques |
| 4 | bolt | rayo.png | Banner del entrenamiento del servidor |
| 5–8 | orca, minotaur, dragon, fox | orca/minotauro/dragon/zorro.png | Elegir el siguiente monstruo |
| 9 | giftPink | regalo.png | Botón rosa de regalar |
| 10 | arrow | flecha.png | (libre: subir de nivel) |
| 11 | meat | carne.png | Llenar al monstruo |
| 12 | sunburst | (dibujado) | Rayos de fondo |
| 13 | glow | (dibujado) | Brillo |

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
