# Lista para crear los productos en el Creator Hub

Creator Hub → Creaciones → tu juego → Monetización → Productos de desarrollador → Crear.
Crea cada uno con el **precio** de la tabla, copia su ID (⋯ → Copiar ID del recurso) y
pégalo en la columna "ID" (o mándamelo y yo lo pongo en `src/shared/Assets/Products.luau`).

## Crea primero estos 18 (lo que más se ve y más vende)

1. `PackInicio` (19) — oferta de bienvenida, se abre sola a los 2.5 min.
2. Pases `VIP` (299), `ReyDelMar` (149), `DiosDelVolcan` (399) — sección Pases abajo.
3. `Fill25` (49), `Fill50` (89), `Fill75` (129) — botones bajo la barra del monstruo.
4. `ChooseOrca` (25), `ChooseMinotauro` (99), `ChooseDragonMarino` (265), `ChooseZorroDeAgua` (408) — botones del descanso. Para Halloween: `ChooseOrcaFantasma` (149).
5. `ServerBoost1` (60), `ServerBoost2` (129), `ServerBoost3` (239) — banner de la tienda.
6. `Power2` (7), `Coins1` (3), `Coins2` (7) — atajos de la columna derecha (Power1 ya existe).
7. `Pond11` (799) — **Estanque sagrado x250** del centro de la isla; solo se abre con este producto (también sale en la TIENDA, sección Para siempre).

Los estanques `Pond2`…`Pond10` **no hacen falta**: ya no se venden (se abren con kills;
`sellPonds = false` en `Config/Monetization.luau`). El resto, cuando puedas.

| `PackInicio` | Pack de inicio | 19 | Una sola vez: 15K monedas, caña 4, canasta 3, botas 4, x2 poder 60 min | |

| Clave (no cambiar) | Nombre sugerido | Precio R$ | Grupo | ID |
|---|---|---|---|---|
| `Power1` | Poder 1 (x2) | 3 | Poder x2^n (para siempre) | 2037380432 |
| `Power2` | Poder 2 (x4) | 7 | Poder x2^n (para siempre) | |
| `Power3` | Poder 3 (x8) | 15 | Poder x2^n (para siempre) | |
| `Power4` | Poder 4 (x16) | 32 | Poder x2^n (para siempre) | |
| `Power5` | Poder 5 (x32) | 76 | Poder x2^n (para siempre) | |
| `Power6` | Poder 6 (x64) | 128 | Poder x2^n (para siempre) | |
| `Power7` | Poder 7 (x128) | 229 | Poder x2^n (para siempre) | |
| `Power8` | Poder 8 (x256) | 599 | Poder x2^n (para siempre) | |
| `Power9` | Poder 9 (x512) | 999 | Poder x2^n (para siempre) | |
| `Power10` | Poder 10 (x1024) | 999 | Poder x2^n (para siempre) | |
| `Coins1` | Monedas 1 (x2) | 3 | Monedas x2^n (para siempre) | |
| `Coins2` | Monedas 2 (x4) | 7 | Monedas x2^n (para siempre) | |
| `Coins3` | Monedas 3 (x8) | 15 | Monedas x2^n (para siempre) | |
| `Coins4` | Monedas 4 (x16) | 32 | Monedas x2^n (para siempre) | |
| `Coins5` | Monedas 5 (x32) | 76 | Monedas x2^n (para siempre) | |
| `Coins6` | Monedas 6 (x64) | 128 | Monedas x2^n (para siempre) | |
| `Coins7` | Monedas 7 (x128) | 229 | Monedas x2^n (para siempre) | |
| `Coins8` | Monedas 8 (x256) | 599 | Monedas x2^n (para siempre) | |
| `Coins9` | Monedas 9 (x512) | 999 | Monedas x2^n (para siempre) | |
| `Coins10` | Monedas 10 (x1024) | 999 | Monedas x2^n (para siempre) | |
| `ServerBoost1` | Entrenamiento del servidor 1 (x2) | 60 | Entrenamiento para todo el servidor, 15 min | |
| `ServerBoost2` | Entrenamiento del servidor 2 (x4) | 129 | Entrenamiento para todo el servidor, 15 min | |
| `ServerBoost3` | Entrenamiento del servidor 3 (x8) | 239 | Entrenamiento para todo el servidor, 15 min | |
| `ServerBoost4` | Entrenamiento del servidor 4 (x16) | 416 | Entrenamiento para todo el servidor, 15 min | |
| `ServerBoost5` | Entrenamiento del servidor 5 (x32) | 678 | Entrenamiento para todo el servidor, 15 min | |
| `ServerBoost6` | Entrenamiento del servidor 6 (x64) | 880 | Entrenamiento para todo el servidor, 15 min | |
| `Fill25` | Llenar 25 | 49 | Llenar al monstruo actual | |
| `Fill50` | Llenar 50 | 89 | Llenar al monstruo actual | |
| `Fill75` | Llenar 75 | 129 | Llenar al monstruo actual | |
| `ChooseOrca` | Elegir Orca | 25 | Elegir el siguiente monstruo | |
| `ChooseMinotauro` | Elegir Minotauro | 99 | Elegir el siguiente monstruo | |
| `ChooseDragonMarino` | Elegir DragonMarino | 265 | Elegir el siguiente monstruo | |
| `ChooseZorroDeAgua` | Elegir ZorroDeAgua | 408 | Elegir el siguiente monstruo | |
| `Pond2` | Estanque 2 | 25 | Estanques para siempre | |
| `Pond3` | Estanque 3 | 49 | Estanques para siempre | |
| `Pond4` | Estanque 4 | 79 | Estanques para siempre | |
| `Pond5` | Estanque 5 | 129 | Estanques para siempre | |
| `Pond6` | Estanque 6 | 199 | Estanques para siempre | |
| `Pond7` | Estanque 7 | 299 | Estanques para siempre | |
| `Pond8` | Estanque 8 | 449 | Estanques para siempre | |
| `Pond9` | Estanque 9 | 649 | Estanques para siempre | |
| `Pond10` | Estanque 10 | 999 | Estanques para siempre | |
| `Pond11` | Estanque sagrado x250 | 799 | Solo con Robux (centro de la isla) | |
| `Spin1` | 1 giro de ruleta | 24 | Giros de la ruleta (se guardan; no se regalan) | |
| `Spin5` | 5 giros de ruleta | 80 | Giros de la ruleta (se guardan; no se regalan) | |
| `GiftVIP` | Regalar VIP | 299 | Regalar el pase VIP a otro jugador | |
| `GiftReyDelMar` | Regalar Rey del Mar | 149 | Regalar el traje Rey del Mar a otro jugador | |
| `GiftDiosDelVolcan` | Regalar Dios del Volcán | 399 | Regalar el traje Dios del Volcán a otro jugador | |
| `Rod2` | Caña nivel 2 | 5 | MEJORAS en Robux (el nivel 1 es gratis): cañas | |
| `Rod3` | Caña nivel 3 | 15 | MEJORAS en Robux (el nivel 1 es gratis): cañas | |
| `Rod4` | Caña nivel 4 | 29 | MEJORAS en Robux (el nivel 1 es gratis): cañas | |
| `Rod5` | Caña nivel 5 | 59 | MEJORAS en Robux (el nivel 1 es gratis): cañas | |
| `Rod6` | Caña nivel 6 | 99 | MEJORAS en Robux (el nivel 1 es gratis): cañas | |
| `Rod7` | Caña nivel 7 | 199 | MEJORAS en Robux (el nivel 1 es gratis): cañas | |
| `Rod8` | Caña nivel 8 | 349 | MEJORAS en Robux (el nivel 1 es gratis): cañas | |
| `Rod9` | Caña nivel 9 | 599 | MEJORAS en Robux (el nivel 1 es gratis): cañas | |
| `Rod10` | Caña nivel 10 | 999 | MEJORAS en Robux (el nivel 1 es gratis): cañas | |
| `Basket2` | Canasta nivel 2 | 9 | canastas | |
| `Basket3` | Canasta nivel 3 | 25 | canastas | |
| `Basket4` | Canasta nivel 4 | 49 | canastas | |
| `Basket5` | Canasta nivel 5 | 129 | canastas | |
| `Basket6` | Canasta nivel 6 | 299 | canastas | |
| `Boots2` | Botas nivel 2 | 5 | botas | |
| `Boots3` | Botas nivel 3 | 19 | botas | |
| `Boots4` | Botas nivel 4 | 39 | botas | |
| `Boots5` | Botas nivel 5 | 79 | botas | |
| `Boots6` | Botas nivel 6 | 199 | botas | |

## Pases

| Clave | Nombre | Precio R$ | ID |
|---|---|---|---|
| `VIP` | VIP | 299 | |
| `DiosDelVolcan` | Dios del Volcán | 399 | |
| `ReyDelMar` | Rey del Mar | 149 | |

Descripciones para el Creator Hub:
- **Rey del Mar:** Traje de rey con corona y capa. Los peces pican 2 veces más rápido, recoges con el doble de fuerza y ganas x2 kills.
- **Dios del Volcán:** Traje de fuego con corona ardiente. Los peces pican 3 veces más rápido, sacas cualquier pez de un toque y ganas x2 kills.

Creator Hub → tu juego → Monetización → Pases → Crear pase. Después, en el pase → **Ventas**: activar "Artículo a la venta" y poner el precio.
