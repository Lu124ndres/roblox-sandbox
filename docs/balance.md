# Balance: dónde se cambia cada número

Todos los números del juego viven en `src/shared/Config/` (y lo visual en
`src/shared/UIConfig/`). Se cambia el número, Rojo lo sincroniza y se prueba en
Studio. Aquí está cada perilla, su valor actual y qué mueve.

## Monstruos (`Config/Giants.luau`)

| Perilla | Valor | Qué hace |
|---|---|---|
| `food` de cada monstruo | Orca 300, Minotauro 2,000, Dragón 10,000, Zorro 40,000 | **Mínimo** de comida (con pocos jugadores). |
| `loadsPerPlayer` | 1.5 / 3 / 5 / 8 | Cuántas canastas llenas pide por jugador activo. La comida real = `loadsPerPlayer × 2.75 × suma de capacidades de los activos`. Así 50 jugadores no lo llenan en segundos. |
| `scaling.activeSeconds` | 180 | Cuenta como activo quien pescó en los últimos 3 min o lleva peces. |
| `scaling.maxFoodFactor` | 100 | Tope: la comida nunca pasa de 100 × el mínimo. |
| `scaling.minKillShare` | 0.005 | Hay que dar al menos el 0.5 % de la barra para ganar la kill. |
| `multiplier` | 1 / 3 / 8 / 20 | Multiplica las monedas que da cada pez. |
| `delivery.maxDeliverySeconds` | 4 | Una canasta, por grande que sea, se entrega en 4 s. |
| `stageThresholds` / `stageHeightsInPlayers` | 0/25/50/75 % · 3/8/15/30 | Cuándo crece y cuánto mide. |
| `cycle.restSeconds` (máx.), `restBaseSeconds`, `restPerPlayerSeconds` | 120 · 60 · 1.2 | Descanso = 60 s + 1.2 s por jugador, máximo 120. |
| `anger.*` | — | Cuánto tarda en enojarse y cada cuánto ataca. |

**Probado en Studio:** 1 jugador con canasta de 160 peces → la Orca pidió 660 (1.5 × 2.75 × 160) y la canasta se entregó en ~4 s.

## Estanques (`Config/Progression.luau`)

| Estanque | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Multiplicador | x1 | x2 | x3 | x5 | x8 | x12 | x20 | x35 | x60 | x100 |
| Poder requerido | 0 | 150 | 600 | 2K | 6K | **30K** | **150K** | **600K** | **2.5M** | **10M** |

En negrita lo que se subió hoy: antes se abrían todos en ~2 h, mucho antes que las cañas.

## Tienda de monedas — MEJORAS (`Config/Shop.luau`)

Cañas (precio → poder): 0 → x1, 150 → x1.5, 750 → x2, 3K → x3, 12K → x5, 45K → x8,
150K → x12, **300K** → x20, **800K** → x35, **2M** → x60 (las tres últimas bajaron:
con solo la Orca en la ruleta tardaban 20–40 h). Canastas y botas en el mismo archivo.

## Peces (`Config/Fish.luau`)

Rareza, peso (probabilidad), comida y monedas de cada pez. Promedio actual: 2.75 de
comida y ~4.6 monedas por pez.

## Premios y social

- Premio diario, logros y misiones del tutorial: `Config/Retention.luau`.
- Impulso de amigos (+10 % cada uno, máx. 5), regalo del grupo, títulos: `Config/Social.luau`.
- Códigos: `src/server/Social/CodeList.luau` (solo servidor, para que nadie los lea).

## Robux (`Config/Monetization.luau` + IDs en `Assets/Products.luau`)

| Producto | Precios actuales (R$) |
|---|---|
| Poder / Monedas x2 → x1024 (10 niveles) | 3, 7, 15, 29, 59, 99, 199, 349, 599, 999 |
| VIP (pase) / regalar VIP | 299 / 299 |
| Entrenamiento del servidor 15 min, x2 → x64 | 15, 29, 59, 99, 199, 349 |
| Llenar 25 / 50 / 75 % | 49 / 89 / 129 |
| Elegir siguiente monstruo | Orca 25, Minotauro 49, Dragón 79, Zorro 99 (se oculta con un solo monstruo) |
| Estanques 2–10 | 25 … 999 |
| MEJORAS en Robux | cañas 5 … 999, canastas 9 … 299, botas 5 … 199 |

**⚠️ Para decidir:** Poder x1024 × servidor x64 × impulso personal x2 × amigos x1.5 se
multiplican (≈ x196,000). Un jugador que pague mucho puede llenar cualquier monstruo
solo. Opciones: menos niveles (p. ej. hasta x64), precios más altos arriba, o un tope
total. Si cambias precios, cambia también los comentarios de `Products.luau` y crea los
productos en el Creator Hub con esos precios.
