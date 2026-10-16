# Balance: dónde se cambia cada número

Todos los números del juego viven en `src/shared/Config/` (y lo visual en
`src/shared/UIConfig/`). Se cambia el número, Rojo lo sincroniza y se prueba en
Studio. Aquí está cada perilla, su valor actual y qué mueve.

## Monstruos (`Config/Giants.luau`)

| Perilla | Valor | Qué hace |
|---|---|---|
| `food` / `targetMinutes` | mínimo Orca 400 · Minotauro 600 · Orca fantasma 600 · Dragón 900 · Zorro 1,500; objetivo 6 / 10 / 10 / 15 / 25 min | La comida **se calcula al llegar cada monstruo** (`server/Feeding/GiantFood`): lo que el servidor puede darle por segundo (cada jugador según canasta, poder y renacimientos, con las fórmulas de la pesca) × `sizing.activeShare` (0.6) × `targetMinutes`. Tarda lo mismo con 1 novato que con 40 fuertes; `food` es el mínimo (servidor vacío). |
| `cycle.maxFeedMinutes` | 20 | Si no se llena en 20 min (contando solo con gente en el servidor) **se cansa y se va**: despedida, descanso y ruleta normales, y la kill para todos los que le dieron algo (aviso `giantLeft`). |
| `rouletteWeight` | 50 / 30 / 15 / 5 (Orca fantasma 35 en Halloween) | Probabilidad en la ruleta al final del descanso (si nadie compró uno). Todos están en la ruleta, también el Zorro. |
| Kill | — | Para **todos los que le dieron algo** (con un pez basta; `Feeding/Contributions`). Debajo del panel: tu aporte y el top 3. |
| `multiplier` | 2 / 4 / 10 / 20 (Orca fantasma x6) | Multiplica las monedas que da cada pez y el entrenamiento de la guarida en el descanso que sigue a ese monstruo. |
| `delivery.fishPerSecond` / `basketSeconds` | 3 / 8 s | Se alimenta **manteniendo E**: 3 peces/s × 1.35 por renacimiento o, si es más rápido, **la canasta llena en 8 s** (`RebirthMath.deliveryPerSecond`). Así el poder y la canasta sí aceleran al monstruo. |
| `delivery.minSoloSeconds` | 300 | Tope por persona: nunca más de 1/300 de la barra por segundo: una persona sola tarda al menos 5 min. |
| Renacer (`Config/Rebirth.luau`) | monedas 40K x 2.4^n · poder 3K x 2.6^n | Pide monedas **y** poder: 40K/3K, 96K/7.8K, 230K/20K, 550K/53K, 1.3M/140K… (dos cifras). Da, para siempre, alimentar x1.35 y **monedas y poder x1.25** por renacimiento (`bonusGrowth`, se multiplica). |
| `stageThresholds` / `stageHeightsInPlayers` | 0/25/50/75 % · 3/8/15/30 | Cuándo crece y cuánto mide. |
| `cycle.evolveSeconds` | 3 s | Al llenar cada cuarto de barra evoluciona: no come esos segundos (la entrega espera y sigue). |
| `cycle.restSeconds` (máx.), `restBaseSeconds`, `restPerPlayerSeconds` | 120 · 60 · 1.2 | Descanso = 60 s + 1.2 s por jugador, máximo 120. |
| `anger.*` | — | Cuánto tarda en enojarse y cada cuánto ataca. Con 3 jugadores o menos espera 150 s (`smallServerGraceSeconds`) en vez de 45. |


## Poder de pesca (`Config/Progression.luau` + `Shared/FishingPower.luau`)

El poder es la **fuerza**, como en «Construye la Pirámide» (`Shared/FishingPower.luau`):

- Capacidad = (20 + 2 × √poder) × canasta: 1K → 83, 100K → 652, 1M → 2,020, 1B → 63K, 5B → 141K, 60T → 15.5M.
- Peces por pique = capacidad / tiros para llenarla (`castsToFill`: 16 con la caña 1, −0.5 por caña, mínimo 6).
- Monedas: cada pez paga × `coinScale`: una canasta llena paga como 20 × (1 + √(poder / 1000)) peces
  (`Progression.coinScale`, exponente 0.5), × canasta. Pescar con más poder **sí paga más**
  (antes la raíz cuarta y la entrega fija hacían que pagara menos). La comida crece entera.
- Misiones de pescar y entregar cuentan **piques y viajes**, no peces.
- El destello azul sale en hitos de peces por pique: 2, 5, 10, 20, 50, 100…

## Estanques (`Config/Progression.luau`)

| Estanque | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Multiplicador | x1 | x2 | x3 | x5 | x8 | x12 | x20 | x35 | x60 | x100 |
| Monstruos llenados (`requiredKills`) | 0 | 1 | 2 | 3 | 5 | 8 | 12 | 18 | 25 | 35 |
| **o** poder (`requiredPower`) | 0 | 2K | 8K | 25K | 75K | 200K | 600K | 2M | 6M | 20M |

Cada estanque se abre con **monstruos llenados o con poder**, lo que llegue primero (las kills
no se pierden al renacer; el poder sí). Con un monstruo cada ~7–12 min, el estanque 5 llega
en ~35–60 min y el 9 en ~3 h de juego. El sagrado (x250) solo con Robux (`pondRobux`).

## Tienda de monedas — MEJORAS (`Config/Shop.luau`)

Cañas (precio → poder): 0 → x1, 150 → x1.5, 750 → x2, 3K → x3, 12K → x5, 45K → x8,
150K → x12, 300K → x20, 800K → x35, 2M → x60 … hasta 16B → x6,500 (20 niveles).
Canastas (14) y botas (14) en el mismo archivo. Monedas por minuto pescando con la Orca
(simulación del 2026-10-16): novato ~200, poder 1K ~550, 10K con 1 renacer
~2.5K, 50K con 2 renacimientos ~10K.

## Peces (`Config/Fish.luau`)

Rareza, peso (probabilidad), comida y monedas de cada pez (36 especies con `FishMore`).
Promedio actual: ~3.4 de comida y ~6.1 monedas por pez.

## Recoger el pez — minijuego (`Config/Reel.luau`)

Al picar se decide el pez; la barra empieza en 25 %, cada toque suma `gain` y el pez
la baja `drain` por segundo. A 7 toques/s con la caña 1: Común ~0.8 s, Raro ~1.8 s,
Legendario ~3.8 s, Mítico ~5.5 s. Cada nivel de caña da +10 % de fuerza. Pases con
traje: Rey del Mar (x2 fuerza, pique x2) y Dios del Volcán (un toque, pique x3).
Desde Legendario se anuncia a todo el servidor (`announceFromRarity`).

## Entrenamiento (`Config/init.luau` → `Gameplay.training`)

Cada **0.6 s** (`tickSeconds`) se gana `powerPerTick` x estanque x caña x multiplicadores,
en los estanques y en la guarida del descanso.

## Premios y social

- Premio diario, logros y misiones del tutorial: `Config/Retention.luau`.
- **Colección** (`Retention.collectionMilestone`, `shared/Collection`): cada 6 especies, lo mayor entre
  1,500 × hito y 0.4 de la siguiente caña; con las 36, `collectionBonus` (250K). La ventana Peces
  muestra el siguiente premio.
- **Ruleta gratis** (`Config/Spin.luau`, `Retention/SpinWheel`): un giro cada 4 h (guardado). Casillas:
  monedas (lo mayor entre 300–5K y 10–120 % de la siguiente caña), 10 o 30 min de x2 poder, o
  llenar 5 % del monstruo para todos. Botón "Ruleta" arriba con punto rojo cuando toca.
- **Misiones** (`Config/Quests.luau`): 3 del día + 1 EXTRA (llenar monstruos) que paga pero no hace
  falta para el cofre (3K × escala). Tipo `food`: aportar un % de la barra. No las multiplica la
  mejora de Monedas de Robux.
- Regalos por tiempo jugado (`Retention.playtime`): 5, 10, 20, 30, 45, 60, 90 y 120 min; monedas y minutos de x2 poder. Se reinician al volver a entrar.
- **Los premios crecen con el jugador** (`shared/RewardScale.luau`): el diario y los regalos
  por tiempo pagan lo mayor entre sus monedas fijas y una fracción (`share`, `dailyShare`)
  del precio de la **siguiente caña** (regalo de 2 h = 1.5 cañas, día 7 = 0.4). Las misiones
  se multiplican por precio de la siguiente caña / 3,000. Así siguen valiendo la pena al final.
- **Títulos** (`Config/Social.luau`): 25, por **monstruos llenados** (kills): Aprendiz 1, Capitán 10,
  Dios del Mar 100, Coloso Abisal 650, Más Allá del Infinito 5,000. Las kills no se pierden al
  renacer: el título nunca baja. Desde Dios del Mar el brillo recorre el texto. Al subir, aviso
  grande "¡Nuevo título!".
- **Siguiente meta** (`client/Menus/NextGoal.luau`): al terminar el tutorial, un panel muestra
  siempre la meta más cercana (estanque, caña, título o renacer) con su barra.
- Impulso de amigos (+10 % cada uno, máx. 5), regalo del grupo, títulos: `Config/Social.luau`.
- Roblox Premium (`premiumMultiplier` en `Config/Social.luau`): x1.2 al poder y a las monedas,
  con su ícono sobre la cabeza (Overhead) y aviso al entrar.
- Códigos: `src/server/Social/CodeList.luau` (solo servidor, para que nadie los lea).

## Robux (`Config/Monetization.luau` + IDs en `Assets/Products.luau`)

| Producto | Precios actuales (R$) |
|---|---|
| Poder / Monedas x2 → x1024 (10 niveles) | 3, 7, 15, 32, 76, 128, 229, 599, 999, (10: por definir) |
| VIP (pase) / regalar VIP | 299 / 299 |
| Entrenamiento del servidor 15 min, x2 → x64 | 60, 129, 239, 416, 678, 880 |
| Llenar 25 / 50 / 75 % | 49 / 89 / 129 |
| Elegir siguiente monstruo | Orca 25, Minotauro 99, Dragón 265, Zorro 408 (se oculta con un solo monstruo) |
| Estanques 2–10 | 25 … 999 |
| MEJORAS en Robux | cañas 5 … 999, canastas 9 … 299, botas 5 … 199 |

**⚠️ Para decidir:** Poder x1024 × servidor x64 × impulso personal x2 × amigos x1.5 se
multiplican (≈ x196,000). Un jugador que pague mucho puede llenar cualquier monstruo
solo. Opciones: menos niveles (p. ej. hasta x64), precios más altos arriba, o un tope
total. Si cambias precios, cambia también los comentarios de `Products.luau` y crea los
productos en el Creator Hub con esos precios.
