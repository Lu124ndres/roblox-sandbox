# Resumen del proyecto: Alimenta a los Gigantes / Feed the Giants

Documento para que otro asistente entienda el proyecto sin haberlo visto nunca. Revisado el
2026-10-19 contra el código, `CLAUDE.md`, `docs/` y el historial de git (353 commits del
2026-10-11 al 2026-10-19). **Si algo de aquí o de un documento viejo de `docs/` choca con el
código, manda el código**: los números de balance viven en `src/shared/Config/`.

Para empezar a trabajar: lee `CLAUDE.md` (reglas que no se negocian), este documento, y el
`docs/devlog.md` de los últimos días (está en orden cronológico, lo más nuevo al final).

---

## 1. El juego

### 1.1 Qué es

Simulador cooperativo e incremental de Roblox. Pescas en la playa de una isla tropical, llevas
los peces al **Cráter del Abismo** (un volcán) y **todo el servidor alimenta a un monstruo
gigante** que crece en 4 etapas. Cuando la barra se llena, cada jugador que aportó gana una
**kill**. Sigue un descanso con bonus y una ruleta elige el próximo monstruo.

- Nombre público: **Feed the Giants** (inglés) / **Alimenta a los Gigantes** (español).
- Experiencia en Roblox: id 10770885547, lugar 129133484868369. **Todavía privada.**
- Archivo del lugar: `PescaYAlimentaGigantes.rbxl` (fuera de git; los modelos 3D viven ahí).
- Plataformas: PC, teléfono (diseño "móvil primero"), tablet y consola (mando).

### 1.2 Loop principal

```
pescar en la playa -> minijuego de recoger -> canasta
        ^                                       |
        |                                       v
 entrenar poder en los estanques     cruzar el puente -> Cráter del Abismo
        ^                                       |
        |                 alimentar (mantener E): monedas = pez x multiplicador
        |                                       |
  tienda / renacer  <-  kill + descanso  <-  barra llena (crece y evoluciona 4 veces)
                              |
                       ruleta -> siguiente monstruo
```

### 1.3 Mecánicas

**Pesca** (`server/FishingService`, `ShoreCast`, `ReelFight`, `FishLanding`;
`client/Fishing/*`; números en `Config/Reel.luau`):
- Se pesca desde cualquier punto de la playa (los muelles se quitaron el 2026-10-18) con el
  botón PESCAR, E o F.
- El pez pica tras una espera que se divide por la velocidad que da el poder (mínimo 0.4 s).
- Minijuego de recoger: una barra que cada toque sube y el pez baja; los raros pelean más. El
  servidor cuenta los toques con un tope por segundo y margen por ping.
- Nunca se pierde nada: si el pez escapa, se vuelve a intentar.
- 36 especies en 6 rarezas (`Config/Fish.luau` 12 + `Config/FishMore.luau` 24; catálogo en
  `shared/FishCatalog.luau`). Cada pez tiene `weight` (probabilidad), `food` (cuánto llena) y
  `coins`. Rarezas aproximadas: Común 62 %, Poco común 23 %, Raro 12 %, Épico 2.5 %,
  Legendario 0.6 %, Mítico 0.06 %. Desde Legendario sale un cartel para todo el servidor.

**Poder** (`Config/Progression.luau`, fórmulas en `shared/FishingPower.luau`): la estadística
principal. Da capacidad de canasta (`(base + 2·√poder) × canasta`), peces por pique y
velocidad de pesca (`1 + √poder/40`). Se gana entrenando AFK.

**Estanques de entrenamiento** (`server/TrainingService`, `client/Training/*`): un jardín con
11 estanques de orilla natural (rehecho el 2026-10-18). Cada tick del servidor suma
`1 × multiplicador del estanque × caña × bonos`. Se abren **solo con kills** (o con Robux), y
como las kills nunca se pierden, quedan abiertos para siempre:

| # | ×  | Kills | | # | × | Kills |
|---|---|---|---|---|---|---|
| 1 | 1 | 0 | | 7 | 8 | 22 |
| 2 | 1.5 | 1 | | 8 | 12 | 40 |
| 3 | 2 | 3 | | 9 | 16 | 62 |
| 4 | 3 | 6 | | 10 | 25 | 95 |
| 5 | 4 | 9 | | 11 (sagrado) | 50 | solo Robux |
| 6 | 6 | 15 | | | | |

**Alimentar** (`server/FeedingService` + `server/Feeding/*`):
- Desde la orilla del cráter manteniendo E. El servidor valida que el jugador esté en la
  orilla (`server/Proximity`) y que el monstruo esté en fase de comer.
- Entrega: 6 peces/s (×1.35 por renacimiento) o la canasta entera en 5 s, lo que sea más
  rápido. Paga `monedas base del pez × multiplicador del monstruo × bonos`.
- **Sin tope por persona** (se quitó el 2026-10-18). El equilibrio lo da el tamaño de la barra:
  `Feeding/GiantFood` calcula cuánta comida pide el monstruo a partir de lo que el servidor
  puede pescar y entregar por su `targetMinutes`, y `Feeding/FoodResize` la recalcula al
  entrar o salir alguien y cada 15 s (la barra guarda una fracción, así que no se pierde lo
  comido).
- Si no se llena en 20 min (`Feeding/GiantTimeout`), el monstruo se va y la kill se paga igual
  a todos los que aportaron; con un pez basta (`Feeding/Contributions`).

**Enojo** (`Feeding/GiantAnger`, `server/GiantMood`): sin comida 45 s (150 s con ≤ 3
jugadores) se enoja de 0 a 1 en 60 s. Desde el 50 % la barra baja sola, pero nunca debajo del
inicio de la etapa. Furioso lanza un **Salpicón** cada 9 s (aviso de 3 s con un círculo rojo,
después empuja; `GiantAttack`/`GiantHit`). Un bocado lo calma. Nunca se pierde nada.

**Ciclo del monstruo** (`server/GiantCycle`, atributo `Phase`):
`feeding → farewell → rest → arriving`.
1. **Comiendo.** El monstruo **crece con cada pez** (`shared/GiantStages.heightAt`, hasta el
   85 % del camino a la etapa siguiente) y **evoluciona** al 25, 50 y 75 % (3 s; atributo
   `EvolucionHasta`).
2. **Despedida (7 s).** +1 kill a quien aportó (×2 / ×4 con los pases).
3. **Descanso (60–120 s).** El cráter se vacía y sube la guarida del descanso
   (`ServerStorage.GuaridaDescanso`); quien se pare ahí gana poder (`server/RestArena`).
4. **Ruleta (6 s).** Sale el monstruo comprado (`Choose<Id>`) o uno al azar por
   `rouletteWeight`.
5. **Llegada (6 s).** El cráter se llena (agua, lava, arena o hielo) y llega el siguiente.

**Tienda** (`Config/Shop.luau`, `server/ShopService`, `client/Shop/*`): tres mejoras que se
compran en orden: Cañas (20 niveles, ×1 → ×6500 de poder y hasta +300 % de suerte), Canastas
(14, capacidad ×1 → ×160) y Botas (14, velocidad al caminar de 22 a 52; el puente da 56).
Se ven en el personaje (`client/Fishing/RodBuilder`, `client/Effects/BasketBuilder`,
`BootBuilder`).

**Renacer** (`Config/Rebirth.luau`, `server/Retention/Rebirth`, `shared/RebirthMath`):
cuesta monedas (`40K × 2.8^n`) y poder (`3K × 3^n`). Da para siempre alimentar ×1.35 y
monedas/poder ×1.25 por renacimiento (compuesto). Se pierden monedas, poder, mejoras y
canasta; se quedan kills, colección, pases, compras, códigos, insignias y misiones.

### 1.4 Retención

`server/Retention/*` y `Config/Retention.luau`, `Config/Quests.luau`, `Config/Spin.luau`,
`Config/Events.luau`:
- **Tutorial** de 4 pasos (pescar 5, alimentar, entrenar, comprar) con flechas guía hasta el
  destino (`client/Menus/GuideArrow`, `GuidePath`, `GuideMarker`).
- **Premio diario** (racha de 7 días), **regalos por tiempo jugado** (8, de 5 min a 2 h),
  **misiones diarias** (3 + 1 de monstruos + cofre).
- **Ruleta** de 8 casillas: un giro gratis cada 6 h y uno cada 15 min jugados (máx. 4 por
  sesión).
- **Eventos del servidor** (`server/Social/EventScheduler`): cada 12 min uno de 3 min (Pesca
  dorada, Frenesí, Lluvia de monedas, Poder doble). Cambian el cielo (`client/Ambient/EventSky`).
- **Insignias** (9), **rankings globales** (OrderedDataStore: poder, kills, renacimientos),
  **títulos** sobre la cabeza por kills (24, `shared/Titles.luau`).
- **Social:** +10 % por amigo en el servidor (hasta 5), Premium ×1.2, regalo del grupo
  (`groupId` pendiente), invitaciones, códigos (`server/Social/CodeList.luau`).
- **Colección (FishDex):** pagos por descubrir cada especie, premio cada 6 y al completar las 36.

### 1.5 Monetización

`Config/Monetization.luau`; IDs en `Assets/init.luau` (`GamePasses`) y `Assets/Products.luau`;
cobro en `server/Monetization/Receipts` (ProcessReceipt idempotente: guarda los últimos
`PurchaseId` en `receipts`).

- **Pases:** VIP (299 R$: etiqueta, +20 % suerte, diario ×2), Rey del Mar (149 R$: traje,
  pesca ×2, alimenta ×2, kills ×2), Dios del Volcán (399 R$: traje con aura, pesca de un toque,
  alimenta ×4, kills ×4).
- **Productos:** niveles de Poder y Monedas (×2^n), ×2 de entrenamiento para todo el servidor
  (15 min, acumulable hasta ×64), llenar la barra 25/50/75 %, elegir el próximo monstruo,
  +1 min de descanso, estanques, mejoras, giros, pack de inicio (19 R$, una vez).
- **Regalos:** pases y varios productos se compran para otro jugador (`Monetization/Gifts`).
- **Los IDs reales todavía no existen** (están en 0); se crean en el Creator Hub al publicar.

---

## 2. Estado actual (2026-10-19)

**Terminado y probado en Studio:**
- Pesca, alimentar, enojo, ciclo completo con descanso y ruleta, crecimiento con la barra.
- Cinco monstruos con 4 etapas, animación por código, hábitat, sonidos y efectos (sección 5.1).
  El Zorro de agua v2 está en la ruleta desde el 2026-10-19 (con párpados en la E1/E2 y
  témpanos irregulares); la Orca fantasma quedó fuera de la ruleta y de "elegir".
- Tienda, renacer, retención completa, monetización (sin IDs reales), trajes de los pases con
  vitrinas, soporte de móvil y mando.
- Interfaz rehecha en estilo de **piedra volcánica** (2026-10-17, piezas e íconos de Canva).
- Mundo rehecho el 2026-10-18: jardín de estanques, puente al volcán con portal y braseros,
  arco de la puerta del cráter (modelo de Blender), pesca desde toda la playa.
- Página del juego en Roblox (nombre, descripciones EN/ES, ícono, miniaturas) en revisión.

**A medias:**
- Guardado (esquema v11) y telemetría: implementados, pero **nunca probados con un DataStore
  ni AnalyticsService reales** (en Studio el guardado corre en memoria). Lista de pruebas:
  `docs/pruebas_guardado.md`.

**Planeado (ver `docs/backlog.md`, `docs/lanzamiento.md`, `docs/roadmap.md`):**
- Publicar: activar acceso a API, crear pases, ~41 productos y 9 insignias en el Creator Hub,
  poner los IDs en `Assets`, cuestionario de madurez, grupo "Giant Feeders".
- Pruebas con 5–10 personas, en teléfono real de gama baja y con mando.
- Ajustar el balance con los datos de la telemetría (`server/Analytics/`).
- Elegir mejoras de rendimiento de `docs/rendimiento.md`.
- Eventos por versión: Dragón marino (v1.1), Zorro de agua (v1.2).
- Ideas fuera de alcance en `docs/ideas.md` (no se implementan).

---

## 3. Arquitectura

### 3.1 Carpetas y destino en Studio (Rojo, `default.project.json`)

| Ruta | Destino | Qué va |
|---|---|---|
| `src/server/` | `ServerScriptService.Server` | Lógica autoritativa |
| `src/client/` | `StarterPlayer.StarterPlayerScripts.Client` | Input, UI, efectos, animación de los monstruos |
| `src/shared/` | `ReplicatedStorage.Shared` | Config, Assets, protocolo, cálculos compartidos, animación de monstruos |
| `world/Isla.model.json` | `Workspace.Isla` | Piezas de la isla (generadas por `tools/generar_isla.py`; no se editan a mano) |
| `world/GuaridaDescanso.model.json` | `ServerStorage.GuaridaDescanso` | La plataforma del descanso |
| `tools/` | — | Scripts de desarrollo (isla, Blender, UI). No corren en el juego |
| `assets/` | — | FBX, `.blend`, texturas y UI fuente |
| `renders/` | — | Renders de revisión de los modelos v2 (en git) |
| `docs/` | — | Documentación (ver sección 7.3) |

Lo que **no** está en Rojo y vive solo en el `.rbxl`: los modelos de los monstruos
(`ServerStorage.<Base>E<n>` y `<Base>E<n>_v2`), los props de hábitats
(`ServerStorage.Habitats.<GiantId>`), los trajes (`ServerStorage.Traje*`) y los respaldos
(`ServerStorage.Respaldos`). Por eso hay que guardar el lugar (Ctrl+S) tras importar.

Tamaño: 587 archivos `.luau`, ~67K líneas.

### 3.2 Servidor (`src/server/`)

Arranque en `Main.server.luau` (orden: `SaveService.init`, `GiantService.init`,
`GiantMood.init`, `GiantCycle.init`, `FishingService.init`, `FeedingService.init`,
`TrainingService.init`, y los de retención, social, monetización y mundo).

| Módulo | Responsabilidad |
|---|---|
| `Remotes` | Crea la carpeta `ReplicatedStorage.Remotes` con los RemoteEvents (nombres de `shared/Protocol`) |
| `RateLimit` | Cubeta de fichas por jugador y remote (`RateLimit.wrap(nombre, porSegundo, ráfaga, handler)`); ignora el exceso, nunca expulsa |
| `PlayerData` | Estado en memoria de cada jugador; `PlayerData.edit` |
| `ProfilePublish` | Publica al cliente leaderstats (Poder, Kills) y atributos del jugador |
| `Proximity` | Valida distancias (el servidor no confía en el ProximityPrompt) |
| `FishingService`, `ShoreCast`, `ReelFight`, `FishLanding` | Pesca |
| `FeedingService` + `Feeding/` | `Basket`, `Contributions`, `FedBroadcast`, `FoodResize`, `GiantAnger`, `GiantFood`, `GiantPhase`, `GiantPublish`, `GiantTimeout` |
| `GiantService`, `GiantCycle`, `GiantMood`, `GiantRewards`, `GiantTemplates`, `RestArena` | El monstruo: estado, fases, enojo, kills, modelos publicados, descanso |
| `TrainingService`, `ShopService` | Estanques y tienda |
| `Monetization/` | `Passes`, `Receipts`, `Gifts`, `Grants`, `GiantFill`, `GiantChoice`, `ServerBoost`, `RestTime` |
| `Retention/` | `Tutorial`, `DailyReward`, `PlaytimeGifts`, `Quests`, `SpinWheel`, `SpinTimer`, `Rebirth`, `Badges`, `Leaderboards`, `Milestones`, `SettingsService` |
| `Social/` | `Codes`, `CodeList`, `EventScheduler`, `FriendBoost`, `GroupReward`, `Referrals`, `Rewards`, `Outfits` y piezas de trajes, `Showcase*` (vitrinas) |
| `Save/` | `SaveService`, `SaveStore`, `SaveSchema`, `SaveExtra` |
| `Admin/` | Panel de pruebas (`AdminService`, `AdminCommands`, `AdminWorld`, `AdminPlayer`, `AdminReset`) |
| `World/` | `TerrainBuilder`, `IslandShape`, `CraterShape`, `GardenShape`, `PropDresser`, `HabitatService`, `HabitatPlacer`, `PlayerCollision` |

### 3.3 Cliente (`src/client/`)

`Main.client.luau` arranca todo. Carpetas: `Fishing/` (controlador, caña, corcho, barra de
recoger, tarjeta de captura), `Feeding/FeedController`, `Giant/` (dibujar y animar el
monstruo: `GiantView`, `GiantBody`, `GiantTemplates`, `GiantGrowth`, `GiantEvolution`,
`EvolveFx`, `EvolveLook`, `GiantOutline`, `FeedThrow` y un "stand" por tipo: `OrcaSwim`,
`DragonFly`, `MinoStand`, `ZorroStand`), `Interface/` (HUD, kit de piedra `Kit`/`StoneSkin`,
íconos, cartel sobre la cabeza), `Menus/` (52 ventanas y piezas: tienda de Robux, colección,
misiones, diario, ruleta, renacer, admin, tutorial, navegación con mando), `Ambient/` (cielo,
hora del día, agua, cráter y sus modos, hábitats), `Audio/` (`Sounds`, `Music`, voces por
monstruo), `Effects/` (partículas, peces 3D, equipo, temblor de cámara), `Settings/`
(`ClientSettings`, `FxQuality`, `FpsWatchdog`), `Shop/`, `Training/`, `Trajes/`.

### 3.4 Compartido (`src/shared/`)

- `Config/` (carpeta con `init.luau` y secciones: `Fish`, `FishMore`, `Giants`, `GiantTypes`,
  `Habitats`, `Monetization`, `Progression`, `Quests`, `Rebirth`, `Reel`, `Retention`, `Shop`,
  `Social`, `Spin`, `Events`, `Types`). Se usa siempre como `require(Shared.Config)`.
- `Assets/` (`init` mallas, UI y pases; `Textures`; `Products`; `Sounds`). Todo `rbxassetid`.
- `UIConfig/` (colores, fuentes, rendimiento, estanques, looks de cañas, sonidos de UI).
- `Protocol` (nombres de remotes, carpetas y atributos), `ProtocolMap`.
- Cálculos puros: `FishingPower`, `RebirthMath`, `RewardScale`, `GiantStages`, `GiantPool`,
  `Perks`, `Upgrades`, `Collection`, `Titles`, `RetentionBonus`, `NumberFormat`, `TextCase`,
  `Resorte` (resorte amortiguado), `ServerEvents`.
- Mundo: `WorldLayout` + `WorldLayoutData.json` (medidas), `WorldZones` (centro del cráter
  (0, 0, 520), puente `bridgeEnds()`, zonas).
- Animación de cada monstruo: `Orca/`, `Minotauro/`, `Dragon/`, `Zorro/`; trajes: `Trajes/`.

### 3.5 Comunicación

**Remotes** (todos RemoteEvent; no hay RemoteFunction). Cliente → servidor, con su límite:

| Remote | Handler | Límite (por s / ráfaga) |
|---|---|---|
| `CastRequest`, `ReelIn` | `FishingService` | 4/6, 30/30 |
| `FeedRequest` | `FeedingService` | 4/6 |
| `BuyUpgrade` | `ShopService` | 4/6 |
| `ClaimDaily`, `ClaimPlaytime`, `ClaimSpin` | `Retention/*` | 1/2, 2/4, 1/2 |
| `Rebirth` | `Retention/Rebirth` | 0.5/1 |
| `SaveSettings` | `Retention/SettingsService` | 2/4 |
| `RedeemCode`, `ClaimGroup` | `Social/Codes`, `Social/GroupReward` | 0.5/3, 0.5/2 |
| `SetGift` | `Monetization/Gifts` | 2/4 |
| `ElegirTraje` (`ChooseOutfit`) | `Social/OutfitChoice` | 1/2 |
| `RestEnter` | `GiantCycle` | 1/2 |
| `AdminCommand` | `Admin/AdminService` (solo UserIds de `ADMINS`) | 10/20 |

Servidor → cliente: `FishingUpdate`, `FeedResult`, `GiantFed` (lista de quién dio qué pez,
para la animación de comer), `TrainingTick`, `TrainingDenied`, `ShopResult`, `OpenShop`,
`Notice` (avisos, el más usado), `GiantAttack`, `GiantHit`.

**Estado compartido por atributos** (nombres en `shared/Protocol`), sin remotes:
- `ReplicatedStorage.EstadoGigante` (`GiantAttributes`): `Id`, `Multiplier`, `Progress`
  (0..1), `Anger`, `Phase`, `PhaseEndsAt`, `Food`, `EvolucionHasta`, `RuletaResultado`,
  `TopAportes` (JSON), `VolcanVacio`, `VolcanLlenando`, etc.
- `ReplicatedStorage.Impulsos` (`BoostAttributes`): impulso de entrenamiento del servidor,
  monstruo elegido con Robux, evento activo y sus horas.
- Atributos de cada `Player` (`PlayerAttributes`): `Coins`, `Power`, `Kills`, `CarriedFish`,
  estado de pesca, `Rod`/`Basket`/`Boots`, `Pez_<id>` (colección), tutorial, diario, ajustes,
  `DataLoaded`. Más `leaderstats` (Poder, Kills).
- `ReplicatedStorage.ModelosGigantes`: los modelos que publica `GiantTemplates`, con
  `BaseHeight`.

**Sincronía sin red:** la hora del día, las rutinas de los monstruos y sus trucos salen de
`Workspace:GetServerTimeNow()` y de hashes sin estado (`Azar`), así todos los clientes ven lo
mismo sin mandar nada.

---

## 4. Datos y guardado

- **Dónde:** DataStore `Jugadores_v1` (`Config.Saving.storeName`), una llave por jugador.
  Cambiar el nombre empieza de cero para todos.
- **Registro:** `{ data, lock = { jobId, time } }`. **Bloqueo de sesión propio**
  (`Save/SaveStore`): un servidor no abre datos bloqueados por otro; el bloqueo vence a los
  180 s sin renovar (servidor caído). Todo por `UpdateAsync` con reintentos y espera creciente.
- **Ciclo** (`Save/SaveService`): carga en segundo plano al entrar (si está bloqueado reintenta
  y, si no se libera, expulsa con un mensaje antes que arriesgar datos); autoguardado cada 60 s
  repartido entre jugadores; guarda y suelta al salir; `BindToClose` guarda a todos con 25 s
  de margen.
- **Esquema** (`Save/SaveSchema`, `VERSION = 10`; campos de v8–v10 en `SaveExtra`):
  `coins`, `power`, `carried` (canasta por especie), `species` (colección), `stats`,
  `kills`, `killsByGiant`, `upgrades`, `tutorial`, `daily`, `settings`, `badges`, `ponds`,
  `receipts`, `levels` (mejoras de Robux), `codes`, `groupClaimed`, `boostUntil`, `gifts`,
  `rebirths`, `quests`, `starterPack`, `spinAt`, `spins`, `coinBoostUntil`.
- **Validación:** `SaveSchema.read(raw)` trata todo lo que viene del DataStore como
  desconocido: valida tipos, descarta peces que ya no existen y migra desde versiones viejas
  con valores por defecto. Para agregar un campo: subir `VERSION`, agregarlo al tipo, a
  `default()` y a `read()`.
- **Compras:** `receipts` guarda los últimos `PurchaseId` para no entregar dos veces.
- **Rankings:** OrderedDataStore (`RankingPoder` y los de kills y renacimientos) en
  `Retention/Leaderboards`.
- **Sin publicar** (Studio): `SaveStore` usa un almacén en memoria y avisa
  "SaveStore: DataStore no disponible".
- **Validación de entrada en general:** cada handler comprueba `typeof` de cada argumento,
  rangos, posesión y distancia (`Proximity`). El cliente nunca decide monedas, poder ni
  inventario (`CLAUDE.md`, reglas 1 y 2). Hay un subagente `remote-auditor` para revisarlo.

---

## 5. Sistemas principales

### 5.1 Monstruos (gigantes)

Definidos en `Config/Giants.luau` (`chain`). Tamaño por etapa: `stageHeightsInPlayers`
{3, 8, 15, 30} × 5.5 studs = **16.5, 44, 82.5 y 165 studs**.

| Id | Mult. | Comida mín. | Min. objetivo | Ruleta | Hábitat | Modelos |
|---|---|---|---|---|---|---|
| `Orca` | ×2 | 400 | 6 | 50 | agua, arrecife | `OrcaE1..E4` (17 huesos, de Meshy) |
| `Minotauro` | ×4 | 600 | 10 | 30 | desierto (`sand`) | `MinotauroE1..E4_v2` (bloques) |
| `DragonMarino` | ×10 | 900 | 15 | 15 | guarida de lava (`lava`) | `DragonMarinoE1..E4_v2` (32 huesos, vuela) |
| `ZorroDeAgua` | ×20 | 1500 | 25 | 5 | agua con hielo (`ice`) | `ZorroDeAguaE1..E4_v2` (36–76 huesos) |
| `OrcaFantasma` | ×6 | 600 | 10 | — (`inRoulette = false`) | cementerio marino | `OrcaFantasmaE1..E4`, solo con la orden de admin |

**Cómo llega un modelo al juego:** `server/GiantTemplates.publish()` copia
`ServerStorage.<modelBase>E<n>` (o `<modelBase>E<n><modelSuffix>` si existe) a
`ReplicatedStorage.ModelosGigantes` con el nombre normal, anclado, sin colisión y con
`BaseHeight`. Sacar la línea `modelSuffix` vuelve al modelo anterior.

**Cómo se anima:** todo en el cliente y por código (`Bone.Transform`), sin keyframes ni
Animator. `client/Giant/GiantBody` elige el "stand" según los huesos del modelo
(`OrcaSwim`, `DragonFly`, `ZorroStand`, `MinoStand`); el stand llama al módulo compartido del
monstruo cada cuadro y convierte sus eventos (`state.events`) en sonido y efectos.

Patrón común de los monstruos v2 (Minotauro, Dragón, Zorro), con el Zorro como el más
completo (`shared/Zorro/`):
- `Rig.bind`: encuentra los huesos y mide sus ejes en la pose de reposo; `Rig.turn(rig,
  hueso, cabeceo, giro, alabeo)`.
- La **pose es un bus de números** (`{[string]: number}`) que suman todas las capas; cada
  hueso tiene **un solo módulo dueño** que escribe su `Transform`: `Pose/` (tronco, cuello,
  cabeza), `Patas/` (IK de dos huesos por pata, paso de cuadrúpedo), `Cara/` (parpadeo,
  gestos, puntas de orejas; solo con la cámara cerca), `Colas/` (cadena de resortes, onda,
  estados, límites). Contratos en `Zorro/Tipos.luau`.
- `Rutina/` + `Habitos`: qué hace cuando nadie le da de comer (ciclos por etapa, lugares del
  hábitat de `Guarida.luau`, rutas de cara a la puerta del cráter, conductas sin repetir);
  `Rutina.medir(etapa, s)` mide el tiempo de frente al público (meta ≥ 70 %).
- `Conductas/` (zorro) o `Posturas/` + `Trucos/` (minotauro, dragón): una conducta por
  archivo con `pose(u, etapa, r)`, pesos por etapa y eventos.
- `Comer/`: la reacción a cada pez (`FedInfo`: rareza, racha, si es el jugador local).
- `Evolucion`: pose propia al evolucionar (los ids en `OWN_POSE` de `client/Giant/GiantEvolution`).
- Modo de prueba del zorro: `workspace:SetAttribute("ZorroConducta", "<nombre>")`.

**Crecimiento:** `GiantStages.heightAt` interpola el alto con la barra hasta el 85 % del camino
a la etapa siguiente; el cliente (`GiantBody.grow`, `GiantGrowth`) lo suaviza con un resorte y
nunca encoge. Quien deduzca la etapa del alto toma la **alcanzada**, no la más cercana.

### 5.2 Cráter y hábitats

- Terreno del cráter: `server/World/CraterShape`; medidas en `WorldLayoutData.json`
  (lago radio 190, acantilado 205, borde exterior 265, camino a 30.6 de alto).
- **Qué llena el cráter**, por monstruo, lo decide cada cliente: `client/Ambient/CraterDrain`
  elige el modo y `CraterMode` lo guarda (`water`, `ice`, `lava`, `sand`, `empty`) con sus
  mezclas de luz (`lavaBlend`, `sandBlend`, `iceBlend`). Rellenos: `CraterWater`, `CraterLava`,
  `CraterSand`; el hielo conserva el agua (`isWet()`).
- **Lo que acompaña a cada modo:** lava → `LavaLair` (rocas de obsidiana, nido, cascadas,
  géiseres; `Lair*`); arena → `DesertAir`, `DustDevils`; hielo → `IceLair` (`IceFloes`
  témpanos, `IceRocks`, `IceCrystals`, `IceShore`, `IceAir`, subidos y hundidos por `IceLift`).
- `CraterGuard`: con streaming, el agua del servidor puede volver encima del relleno; cada 2 s
  la vuelve a sacar.
- **Props del servidor:** `server/World/HabitatService` y `HabitatPlacer` colocan los modelos de
  `ServerStorage.Habitats.<GiantId>` según `Config/Habitats.luau` (arrecife de la orca,
  laberinto/ruinas del minotauro, cementerio de la fantasma…). La luz va en el servidor; el
  fuego y las partículas, en el cliente (`client/Ambient/HabitatFx`).
- **Contrato monstruo ↔ hábitat:** `shared/Dragon/Guarida` y `shared/Zorro/Guarida` definen
  los lugares donde se posa o duerme el monstruo; el hábitat los construye ahí y el monstruo
  los usa. Las perchas se orientan hacia la rampa (`WorldZones.bridgeEnds()`).
- **Ambiente** (`client/Ambient/*`): día y noche de 16 min calculado en cada cliente con la
  hora del servidor; el cráter tiene su propia hora (`SkyMoods.craterHour`, y por hábitat
  `lairHour`, `desertHour`, `iceHour` = atardecer de nieve); eventos con cielo propio.

### 5.3 Economía y progresión

Números en `Config/Progression.luau`, `Shop.luau`, `Rebirth.luau`, `Monetization.luau`;
fórmulas compartidas en `FishingPower`, `RebirthMath`, `RewardScale`, `Perks` (bonos de pases,
amigos, eventos, impulsos). Detalle y tablas en `docs/balance.md` y `docs/productos.md`.
Riesgo conocido: con muchos renacimientos y compras se llega a ×1024 de poder/monedas (sin
telemetría todavía para ajustar).

### 5.4 Mundo e isla

- `tools/generar_isla.py` → `world/Isla.model.json` (piezas); terreno por vóxeles en
  `server/World/TerrainBuilder` con `IslandShape`, `CraterShape` y `GardenShape`.
  Las medidas comunes en `shared/WorldLayoutData.json`.
- Jardín de entrenamiento con 11 estanques de orilla natural, puente al volcán con "corriente"
  (`client/Ambient/BridgeBoost`) y arco de entrada al cráter (modelo de Blender,
  `tools/puerta.py`), faro, cabaña de la tienda, tableros de ranking, vitrinas de trajes.

### 5.5 Personaje y trajes

`shared/Trajes/` (estilos `ReyDelMar`, `DiosDelVolcan`, `Marinero`; `Aura`, `Huellas`,
`Particulas`), `server/Social/Outfits*`, `client/Trajes/` (rig, efectos, vitrinas). Son mallas
con huesos que siguen al avatar. El equipo (caña, canasta, botas) se arma con piezas.

### 5.6 Interfaz

`client/Interface` y `client/Menus`. Estilo de piedra volcánica (kit en `Interface/Kit`,
`StoneSkin`, `CardParts`), íconos pintados en Canva (seguimiento en `docs/ui-assets.md`),
fuente Luckiest Guy. Móvil primero (`Interface/Layout`, `Device`), navegación con mando
(`Menus/GamepadNav`). Colores: turquesa = pescar, coral = alimentar, dorado = monedas.

### 5.7 Admin (pruebas)

Solo UserIds de `ADMINS` en `server/Admin/AdminService` (el dueño). Panel en
`client/Menus/Admin*`. Órdenes útiles en pruebas:
`ReplicatedStorage.Remotes.AdminCommand:FireServer("giant", "ZorroDeAgua:3", LocalPlayer.UserId)`
(monstruo y etapa), `"fill"` (llenar la barra, dispara evolución real), `skipRest`,
`restTime`, `event`, y por jugador `maxUpgrades`, `fish`, `speed`, `pass`, `tp`, `reset`.

---

## 6. Pipeline de assets

### 6.1 Monstruos v2 en bloques (el método actual)

Todo por código Python en Blender 5.2, sin ventana:
`"/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup --python <script> -- <args>`.

1. **Biblia de diseño** (paleta sRGB por etapa, proporciones en módulos, conductas, contrato
   de huesos) a partir de la referencia del usuario. La referencia no entra al repo
   (`referencias/` está fuera de git).
2. **Geometría:** `tools/blender/<c>_v2_e<n>_geometria.py` (+ `_cuerpo.py`, `_colas.py`…)
   define `CELDA` (0.1, 0.3, 0.5, 1.0 BU según la etapa), `ALTO_JUEGO`, `COLORES`,
   `construir()`, `CONTRATO`, `ARTICULACIONES`, `COLAS`, `PUNTOS`. El armador común
   `minotauro_v2_bloques.py -- --criatura <c> --etapa <n>` arma bloques convexos
   (`bmesh.ops.convex_hull`, bisel de un segmento), cuñas solo 1:1, 1:2 o 2:1, y prismas
   (`dragon_v2_formas.py`). Revisa (`minotauro_v2_revision.py`) caras coplanares
   (z-fighting), normales, bisel y cuadrícula, y renderiza con Cycles.
3. **Poses extremas** (`<c>_v2_poses.py`): reproducen en Python la cuenta del código del
   juego (`Rig`, `Pose`, `Patas`, `Colas`) y miden piezas que se atraviesan, juntas que se
   abren y huecos. Meta ≥ 19/24 limpias **antes** de mostrar al usuario.
4. **Rig** (`rig_<c>_v2.py`): un hueso por pieza con peso 1, huesos sin pesos `Raiz` y `Boca`,
   textura de paleta de 256 px, FBX con `axis_forward="-Z"`, `axis_up="Y"`,
   `apply_scale_options="FBX_SCALE_UNITS"`, `add_leaf_bones=False`. Escala 5.32 studs/BU.
   Salidas: `assets/blender/<Modelo>E<n>_v2.fbx`, `assets/textures/<Modelo>E<n>_v2_color.png`,
   `renders/<c>_v2_e<n>/`.
5. **Alineación** de las 4 etapas: `minotauro_v2_alineacion.py -- --criatura <c>`.
6. **Studio:** el usuario importa con Importar 3D y **"Mantener huesos de influencia cero"**
   (si no, se pierden `Raiz` y `Boca`). Por MCP se revisan huesos, tamaño, orientación (boca a
   −Z) y que no esté anclado; se pasa a `ServerStorage.<Modelo>E<n>_v2` dentro de un
   `ChangeHistoryService`; los IDs van a `Assets/init.luau` y `Assets/Textures.luau`;
   `modelSuffix = "_v2"` en `Config/Giants.luau`. Luego Ctrl+S.

Guía completa: `docs/guia_crear_monstruo.md`; estándares: `docs/estilo_modelos.md`; planes:
`docs/plan_minotauro_v2.md`, `plan_dragon_v2.md`, `plan_zorro_v2.md`.

### 6.2 Otros modelos

Orca y Orca fantasma (modelos de Meshy reducidos con `tools/blender/procesar_meshy.py` y
horneado de texturas `hornear.py`), props de hábitats (`habitats*.py`), trajes
(`rig_traje.py`, `suavizar_traje.py`), faro (`faro.py`), arco del volcán (`tools/puerta.py`).
Reglas generales en `docs/blender-pipeline.md` e inventario en `docs/inventario_modelos.md`.

### 6.3 Sonidos

Solo audio de **ProSoundEffects** o cuentas oficiales de Roblox (el repo es público), buscados
con el MCP de Studio (`search_asset`). IDs en `Assets/Sounds.luau` (bloque por monstruo);
volumen y alcance con `Sounds.define`; recetas por evento y etapa en capas
(`client/Audio/<Criatura>Voces`, `ZorroRecetas`, `DragonRecetas`). La voz baja de tono por
etapa y los golpes suben de volumen. `Sounds` corta por alcance y limita copias.

### 6.4 VFX

Primitivas Neon, `PointLight` y `ParticleEmitter` (texturas en `Assets.Particles`). Los
emisores continuos pasan por `client/Settings/FxQuality` (en modo rápido no salen) y las
ráfagas se escalan con `ClientSettings.fxScale()`. Golpes en el suelo según el relleno:
`Effects/GroundFx`. Evolución común a todos (`EvolveFx`, `EvolveBurst`, `EvolveCharge`) con
los colores de `Giant/EvolveLook`. `FpsWatchdog` activa el modo rápido si el FPS cae.

### 6.5 UI

Piezas e íconos hechos en Canva (MCP de Canva) con la temática de piedra volcánica, subidos a
Roblox y anotados en `docs/ui-assets.md`; fuentes en `assets/ui/`.

---

## 7. Flujo de trabajo con Claude

### 7.1 Reglas (`CLAUDE.md`)

Luau con `--!strict` en todo; servidor autoritativo; todo remote valida tipo, rango, posesión
y distancia; nada de `while true` sin espera; nunca editar en Studio lo que gestiona Rojo;
≤ 200 líneas por archivo; IDs en `Assets/`; números en `Config/`; solo `task.*`; servicios con
`GetService`; desconectar conexiones al irse. Por MCP: en **Edit** nada persistente sobre
instancias de Rojo; en **Play** todo vale (se descarta). Las decisiones de diseño son del
usuario: se proponen opciones. Respuestas directas, sin saludos ni resúmenes.

**Checklist antes de dar algo por terminado:** `rojo build --output build/test.rbxl`,
`selene src`, `stylua --check src` y **probado en Studio por MCP**.

**Commits:** en español, imperativos, uno por tarea, con entrada en `docs/devlog.md`, la tarea
marcada en `docs/backlog.md` y lo no obvio en `docs/decisiones.md`. Firma
`Co-Authored-By: Claude …` según la sesión.

### 7.2 Skills, subagentes y olas

- **Skill local `/crear-monstruo`** (`.claude/skills/crear-monstruo/`, fuera de git): sigue
  `docs/guia_crear_monstruo.md` paso a paso, con puntos de aprobación del usuario.
- **Subagentes del proyecto** (`.claude/agents/`): `infra` (build, selene, stylua, búsquedas
  largas; no diseña ni escribe lógica) y `remote-auditor` (revisa la seguridad de remotes al
  cerrar un sistema de red).
- **Olas de agentes paralelos** (guía, sección 12): cada tarea en un agente con
  `isolation: "worktree"` (copia aislada del repo; primero `git merge --ff-only main`). La
  sesión principal escribe los contratos, reparte, integra, prueba en Play y hace los commits;
  los agentes no hacen commit ni usan Play. Olas típicas de un monstruo: (1) geometría maestra
  + código base + hábitat + sonidos; (2) las otras etapas + poses y rig; (3) un agente por
  sistema de movimiento; (4) arreglos. Antes de la ola de movimiento se dejan en main los
  módulos vacíos ya conectados y un documento de contrato con las claves de la pose.
- **Tablero de tareas** entre Claude Code y Cowork: `docs/tareas_claude_code.md`.

### 7.3 Documentación en `docs/`

`setup.md` (herramientas), `decisiones.md`, `devlog.md` (bitácora; lo nuevo al final),
`backlog.md` (tareas por hito), `roadmap.md`, `alcance.md` (calibración de la v1; partes
desactualizadas), `balance.md`, `productos.md`, `lanzamiento.md` (checklist de publicación),
`ideas.md` (fuera de alcance), `ui-assets.md`, `blender-pipeline.md`, `estilo_modelos.md`,
`inventario_modelos.md`, `guia_crear_monstruo.md`, `plan_*_v2.md`, `import_minotauro_v2.md`,
`prompts-monstruos.md`, `modelo-orca-e1.md`. En la raíz, `CONTEXTO_JUEGO.md` (sin commitear,
del 2026-10-17; útil pero en parte desactualizado).

### 7.4 Varias sesiones a la vez

Suelen trabajar varias sesiones de Claude en el mismo directorio (UI, mundo, trajes,
monstruos). Comparten:
- **Studio:** uno solo. Antes de usar Play se avisa a las otras sesiones (`SendMessage`) y se
  avisa al soltarlo. El MCP no publica ni importa FBX: eso lo hace el usuario.
- **El índice de git:** commitear siempre con rutas, `git commit -m "…" -- <rutas>`; un
  `git commit` a secas se lleva lo que otra sesión dejó preparado.
- **Rojo:** sincroniza al instante lo que cambia en `src/`; si hay una grabación o prueba de
  otra sesión en curso, no conviene integrar cambios visuales.

---

## 8. Herramientas y versiones

| Herramienta | Versión | Uso |
|---|---|---|
| Rokit | — | Gestiona las herramientas de `rokit.toml` |
| Rojo | 7.7.1 | Sincroniza `src/` y `world/` con Studio (`rojo serve`, plugin conectado) |
| selene | 0.32.0 | Linter (`selene.toml`: `std = "roblox"`) |
| StyLua | 2.6.0 | Formato (`stylua.toml`: tabs, columna 100) |
| Wally | 0.3.2 | Configurado (`wally.toml`), **sin dependencias**: todo el código es propio |
| Blender | 5.2.2 LTS | Modelos, rigs, FBX y renders, por scripts en `tools/blender/` |
| Python | 3.13 (con PIL, numpy) | `tools/generar_isla.py`, imágenes de revisión |
| MCP de Roblox Studio | — | `execute_luau`, `start_stop_play`, `screen_capture`, `get_console_output`, `search_asset`, `inspect_instance` |
| MCP de Blender | — | Inspección y scripts en la ventana de Blender (el pipeline usa Blender sin ventana) |
| MCP de Canva | — | Piezas e íconos de la interfaz |

No hay tests automáticos; las pruebas son en Studio por MCP (y simulaciones puras como
`Zorro/Colas/Prueba`, `Zorro/Rutina.medir`).

---

## 9. Problemas conocidos, límites y deuda técnica

- **Sin publicar:** el guardado, las compras, la telemetría, las insignias, el grupo y los
  rankings nunca se probaron de verdad (pasos en `docs/pruebas_guardado.md`); todos los IDs de
  pases y productos están en 0 (`docs/lanzamiento.md`).
- **Sin pruebas multijugador ni en hardware real:** faltan pruebas con 2+ jugadores, ping
  simulado, teléfono real de gama baja, mando real y avatares R6/R15. En el emulador: 4,748
  piezas, 2.3 M de celdas de terreno y 83 luces; la guarida del descanso (905 piezas) vive
  enterrada en Workspace todo el tiempo (`docs/rendimiento.md`, propuestas sin elegir).
- **Balance sin datos:** la telemetría existe pero todavía sin datos; el escalado con
  renacimientos (hasta ×1024) puede romper la economía.
- **Zorro de agua:** límites de piezas rígidas: el
  rascado no llega a la oreja, al enroscarse la nariz no llega a la cola, y el abanico de la E4
  es largo hacia atrás.
- **Modelos fuera de git:** viven en el `.rbxl`; si no se guarda el lugar tras importar, se
  pierden. Respaldos en `ServerStorage.Respaldos` y copias fechadas del `.rbxl` fuera del repo
  con `tools/respaldo_rbxl.sh` (guarda las últimas 20).
- **Servidores viejos tras actualizar:** con el esquema v11, un servidor con código viejo
  expulsa a quien ya tiene datos v11 ("El juego se actualizó") en vez de pisarlos; al
  publicar conviene reiniciar los servidores.
- **Rojo:** una vez duplicó ~80 scripts en Studio (se arregló reconectando el plugin);
  conviene revisar duplicados si algo carga código viejo.
- **`alcance.md` y `roadmap.md`** tienen números viejos.
- **Rendimiento de animación:** cada hueso escrito por cuadro cuesta CPU, pero poco: la E4 del
  zorro (76 huesos) tarda 0.30 ms por cuadro en la PC y el Dragón E4, 0.12 ms; los detalles de
  la cara solo corren con la cámara cerca y sin modo rápido.

---

## 10. Decisiones de diseño importantes (y por qué)

Todas con detalle en `docs/decisiones.md`.

| Decisión | Por qué |
|---|---|
| Luau puro sobre roblox-ts; Rojo; Rokit | Sin transpilador ni capa extra; el código vive en git y Studio solo refleja |
| El mapa se genera por script (`generar_isla.py` → `.model.json`) | Reproducible y revisable en git; nunca se edita a mano en Studio |
| Fase 1 con primitivas, fase 2 con Blender; **excepción: los gigantes** usan su modelo final | El juego tenía que estar completo antes de pulir; los gigantes son el corazón visual |
| El gigante se dibuja y anima en cada cliente | 60 fps sin depender de la red; el servidor solo publica estado |
| Animación por código (`Bone.Transform`, resortes), sin keyframes | Sin assets de animación que subir; todo sincronizado con la hora del servidor |
| Sincronía con `GetServerTimeNow()` + hash sin estado | Todos ven lo mismo sin mandar nada por red |
| El gigante vive en un cráter aparte | Separa la pesca del alimentar y le da un lugar propio a cada hábitat |
| Crecimiento por etapas en múltiplos del alto de un jugador, y continuo con la barra | Escala legible (3×, 8×, 15×, 30×); se ve crecer con cada pez |
| La barra se dimensiona con los jugadores presentes (`GiantFood`, `FoodResize`) y sin tope por persona | Tarda lo mismo con 1 novato que con 40 jugadores fuertes, sin frenar los peces |
| Guardado con bloqueo de sesión propio | Evita duplicar o pisar datos al cambiar de servidor |
| Estanques solo con kills (o Robux) | Las kills no se pierden al renacer: un estanque abierto queda abierto |
| Hábitats: la luz en el servidor, el fuego en el cliente; relleno del cráter por modo en el cliente | Menos réplica de partes; cada cliente mezcla luz y relleno suave |
| Modelos v2 por sufijo (`modelSuffix`) con el nombre de siempre | Se activan o se vuelven atrás con una línea, sin tocar el resto del código |
| Un dueño por hueso y la pose como bus de números | Varios sistemas (y varios agentes) suman movimiento sin pisarse |
| La rutina se mide (`Rutina.medir`) | La meta de mirar al público ≥ 70 % se comprueba con números, no a ojo |
| Monedas y poder por pescar con ventana generosa, sin castigo | Juego casual para teléfono; nunca se pierde nada |
| Sonidos solo de ProSoundEffects o cuentas oficiales | El repositorio es público: nada con licencia dudosa |
