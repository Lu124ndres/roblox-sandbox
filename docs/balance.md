# Balance: dónde se cambia cada número

Todos los números del juego viven en `src/shared/Config/` (y lo visual en
`src/shared/UIConfig/`). Se cambia el número, Rojo lo sincroniza y se prueba en
Studio. Aquí está cada perilla, su valor actual y qué mueve.

## Monstruos (`Config/Giants.luau`)

| Perilla | Valor | Qué hace |
|---|---|---|
| `food` de cada monstruo | Orca 500K · Minotauro 2.5M · Orca fantasma 5M · Dragón 12M · Zorro 50M | Comida **fija y escalonada** como las pirámides de «Construye la Pirámide». Un novato lleva ~1–4K de comida por viaje; alguien con 1B de poder ~1.4M (una canasta llena). La Orca es difícil solo con novatos; el Zorro pide un servidor fuerte. |
| `rouletteWeight` | 50 / 30 / 15 / 5 | Probabilidad en la ruleta al final del descanso (si nadie compró uno). Sin modelo propio usan la Orca teñida. |
| Ritmo de un jugador | novato ~0.45 comida/s · pro ~1.9 · tope ~5 | Calculado con el ciclo de pesca (pique, minijuego, viaje al volcán) al ~80 % del tiempo. Con menos jugadores tarda más: 10 novatos ~35 min la Orca. |
| Kill | — | Para **todos los que le dieron algo** (con un pez basta; `Feeding/Contributions`). Debajo del panel: tu aporte y el top 3. |
| `multiplier` | 2 / 4 / 10 / 20 (Orca fantasma x6) | Multiplica las monedas que da cada pez y el entrenamiento de la guarida en el descanso que sigue a ese monstruo. |
| `delivery.maxDeliverySeconds` | 4 | Una canasta, por grande que sea, se entrega en 4 s. |
| `stageThresholds` / `stageHeightsInPlayers` | 0/25/50/75 % · 3/8/15/30 | Cuándo crece y cuánto mide. |
| `cycle.restSeconds` (máx.), `restBaseSeconds`, `restPerPlayerSeconds` | 120 · 60 · 1.2 | Descanso = 60 s + 1.2 s por jugador, máximo 120. |
| `anger.*` | — | Cuánto tarda en enojarse y cada cuánto ataca. Con 3 jugadores o menos espera 150 s (`smallServerGraceSeconds`) en vez de 45. |


## Poder de pesca (`Config/Progression.luau` + `Shared/FishingPower.luau`)

El poder es la **fuerza**, como en «Construye la Pirámide» (`Shared/FishingPower.luau`):

- Capacidad = (20 + 2 × √poder) × canasta: 1K → 83, 100K → 652, 1M → 2,020, 1B → 63K, 5B → 141K, 60T → 15.5M.
- Peces por pique = capacidad / tiros para llenarla (`castsToFill`: 16 con la caña 1, −0.5 por caña, mínimo 6).
- Monedas: cada pez paga × `coinScale`, así **una canasta llena paga lo mismo que con la fórmula vieja** y
  los precios de la tienda siguen sirviendo. La comida sí crece (barras grandes).
- Misiones de pescar y entregar cuentan **piques y viajes**, no peces.
- El destello azul sale en hitos de peces por pique: 2, 5, 10, 20, 50, 100…

## Estanques (`Config/Progression.luau`)

| Estanque | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Multiplicador | x1 | x2 | x4 | x10 | x15 | x25 | x40 | x75 | x100 | x200 |
| Monstruos llenados (`requiredKills`) | 0 | 1 | 2 | 4 | 7 | 12 | 20 | 35 | 60 | 100 |

Desde el 2026-10-14 los estanques se abren con **monstruos llenados** (kills), no con
poder. Un monstruo dura ~5–10 min más el descanso: el estanque 10 llega en ~15–20 h de
juego. También se pueden abrir con Robux (`pondRobux`).

## Tienda de monedas — MEJORAS (`Config/Shop.luau`)

Cañas (precio → poder): 0 → x1, 150 → x1.5, 750 → x2, 3K → x3, 12K → x5, 45K → x8,
150K → x12, **300K** → x20, **800K** → x35, **2M** → x60 (las tres últimas bajaron:
con solo la Orca en la ruleta tardaban 20–40 h). Canastas y botas en el mismo archivo.

## Peces (`Config/Fish.luau`)

Rareza, peso (probabilidad), comida y monedas de cada pez. Promedio actual: 2.75 de
comida y ~4.6 monedas por pez.

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
- Regalos por tiempo jugado (`Retention.playtime`): 5, 10, 20, 30, 45, 60, 90 y 120 min; monedas y minutos de x2 poder. Se reinician al volver a entrar.
- **Los premios crecen con el jugador** (`shared/RewardScale.luau`): el diario y los regalos
  por tiempo pagan lo mayor entre sus monedas fijas y una fracción (`share`, `dailyShare`)
  del precio de la **siguiente caña** (regalo de 2 h = 3 cañas, día 7 = 0.6). Las misiones
  se multiplican por precio de la siguiente caña / 3,000. Así siguen valiendo la pena al final.
- **Títulos** (`Config/Social.luau`): 26, de Novato (0) a Más Allá del Infinito (1e21 de poder).
  Se calculan con el **poder máximo** (`bestPower` en el guardado): al renacer no bajan. Desde
  Dios del Mar el brillo recorre el texto. Al subir, aviso grande "¡Nuevo título!".
- **Siguiente meta** (`client/Menus/NextGoal.luau`): al terminar el tutorial, un panel muestra
  siempre la meta más cercana (estanque, caña, título o renacer) con su barra.
- Impulso de amigos (+10 % cada uno, máx. 5), regalo del grupo, títulos: `Config/Social.luau`.
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
