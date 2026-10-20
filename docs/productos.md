# Productos y pases en el Creator Hub

**Estado 2026-10-19:** los 70 productos y los 3 pases ya existen con estos IDs (también en
`src/shared/Assets/Products.luau` y `Assets.GamePasses`). Lo de abajo queda como referencia.

Creator Hub → Creaciones → tu juego → Monetización → Productos de desarrollador → Crear.
Crea cada uno con el **precio** de la tabla, copia su ID (⋯ → Copiar ID del recurso) y
pégalo en la columna "ID" (o mándamelo y yo lo pongo en `src/shared/Assets/Products.luau`).

## Íconos (512x512)

Cada producto y pase tiene su ícono listo en `assets/ui/productos/<Clave>.png`
(los pases: `Pase_VIP.png`, `Pase_ReyDelMar.png`, `Pase_DiosDelVolcan.png`).
Al crear el producto, en **Ícono** sube el archivo con el mismo nombre que la clave.
Para los que ya existen: ⋯ → Editar → cambia la imagen. Vista de todos: `assets/ui/productos/_hoja.png`.
Se regeneran con `tools/productos/build.py` (fuentes en `assets/ui/iconos/`, fuente LuckiestGuy de @fontsource).

## Crea primero estos 18 (lo que más se ve y más vende)

1. `PackInicio` (19) — oferta de bienvenida, se abre sola a los 2.5 min.
2. Pases `VIP` (299), `ReyDelMar` (149), `DiosDelVolcan` (399) — sección Pases abajo.
3. `Fill25` (49), `Fill50` (89), `Fill75` (129) — botones bajo la barra del monstruo.
4. `ChooseOrca` (25), `ChooseMinotauro` (99), `ChooseDragonMarino` (265), `ChooseZorroDeAgua` (408) — botones del descanso. Para Halloween: `ChooseOrcaFantasma` (149).
5. `ServerBoost1` (60), `ServerBoost2` (129), `ServerBoost3` (239) — banner de la tienda.
6. `Power2` (7), `Coins1` (3), `Coins2` (7) — atajos de la columna derecha (Power1 ya existe).
7. `Pond11` (799) — **Estanque sagrado x50** del centro de la isla; solo se abre con este producto (también sale en la TIENDA, sección Para siempre).

Los estanques `Pond2`…`Pond10` **no hacen falta**: ya no se venden (se abren con kills;
`sellPonds = false` en `Config/Monetization.luau`). El resto, cuando puedas.

| `PackInicio` | Pack de inicio | 19 | Una sola vez: 15K monedas, caña 4, canasta 3, botas 4, x2 poder 60 min | 3720099575 |

| Clave (no cambiar) | Nombre sugerido | Precio R$ | Grupo | ID |
|---|---|---|---|---|
| `Power1` | Poder 1 (x2) | 3 | Poder x2^n (para siempre) | 3718588679 |
| `Power2` | Poder 2 (x4) | 7 | Poder x2^n (para siempre) | 3718588802 |
| `Power3` | Poder 3 (x8) | 15 | Poder x2^n (para siempre) | 3718589090 |
| `Power4` | Poder 4 (x16) | 32 | Poder x2^n (para siempre) | 3718589478 |
| `Power5` | Poder 5 (x32) | 76 | Poder x2^n (para siempre) | 3718589622 |
| `Power6` | Poder 6 (x64) | 128 | Poder x2^n (para siempre) | 3718589864 |
| `Power7` | Poder 7 (x128) | 229 | Poder x2^n (para siempre) | 3718590185 |
| `Power8` | Poder 8 (x256) | 599 | Poder x2^n (para siempre) | 3718640196 |
| `Power9` | Poder 9 (x512) | 999 | Poder x2^n (para siempre) | 3718640353 |
| `Power10` | Poder 10 (x1024) | 999 | Poder x2^n (para siempre) | 3720099091 |
| `Coins1` | Monedas 1 (x2) | 3 | Monedas x2^n (para siempre) | 3718640414 |
| `Coins2` | Monedas 2 (x4) | 7 | Monedas x2^n (para siempre) | 3718640488 |
| `Coins3` | Monedas 3 (x8) | 15 | Monedas x2^n (para siempre) | 3718640898 |
| `Coins4` | Monedas 4 (x16) | 32 | Monedas x2^n (para siempre) | 3718640974 |
| `Coins5` | Monedas 5 (x32) | 76 | Monedas x2^n (para siempre) | 3718641084 |
| `Coins6` | Monedas 6 (x64) | 128 | Monedas x2^n (para siempre) | 3718641162 |
| `Coins7` | Monedas 7 (x128) | 229 | Monedas x2^n (para siempre) | 3718641221 |
| `Coins8` | Monedas 8 (x256) | 599 | Monedas x2^n (para siempre) | 3718641364 |
| `Coins9` | Monedas 9 (x512) | 999 | Monedas x2^n (para siempre) | 3718641436 |
| `Coins10` | Monedas 10 (x1024) | 999 | Monedas x2^n (para siempre) | 3720099352 |
| `ServerBoost1` | Entrenamiento del servidor 1 (x2) | 60 | Entrenamiento para todo el servidor, 15 min | 3718641640 |
| `ServerBoost2` | Entrenamiento del servidor 2 (x4) | 129 | Entrenamiento para todo el servidor, 15 min | 3718641697 |
| `ServerBoost3` | Entrenamiento del servidor 3 (x8) | 239 | Entrenamiento para todo el servidor, 15 min | 3718641786 |
| `ServerBoost4` | Entrenamiento del servidor 4 (x16) | 416 | Entrenamiento para todo el servidor, 15 min | 3718641927 |
| `ServerBoost5` | Entrenamiento del servidor 5 (x32) | 678 | Entrenamiento para todo el servidor, 15 min | 3718642036 |
| `ServerBoost6` | Entrenamiento del servidor 6 (x64) | 880 | Entrenamiento para todo el servidor, 15 min | 3718642096 |
| `Fill25` | Llenar 25 | 49 | Llenar al monstruo actual | 3720099484 |
| `Fill50` | Llenar 50 | 89 | Llenar al monstruo actual | 3720099519 |
| `Fill75` | Llenar 75 | 129 | Llenar al monstruo actual | 3720099544 |
| `ChooseOrca` | Elegir Orca | 25 | Elegir el siguiente monstruo | 3718642216 |
| `ChooseMinotauro` | Elegir Minotauro | 99 | Elegir el siguiente monstruo | 3718642266 |
| `ChooseDragonMarino` | Elegir DragonMarino | 265 | Elegir el siguiente monstruo | 3718642325 |
| `ChooseZorroDeAgua` | Elegir ZorroDeAgua | 408 | Elegir el siguiente monstruo | 3718642377 |
| `Pond2` | Estanque 2 | 25 | Estanques para siempre | 3720100313 |
| `Pond3` | Estanque 3 | 49 | Estanques para siempre | 3720100398 |
| `Pond4` | Estanque 4 | 79 | Estanques para siempre | 3720102255 |
| `Pond5` | Estanque 5 | 129 | Estanques para siempre | 3720102649 |
| `Pond6` | Estanque 6 | 199 | Estanques para siempre | 3720102696 |
| `Pond7` | Estanque 7 | 299 | Estanques para siempre | 3720102741 |
| `Pond8` | Estanque 8 | 449 | Estanques para siempre | 3720102805 |
| `Pond9` | Estanque 9 | 649 | Estanques para siempre | 3720102892 |
| `Pond10` | Estanque 10 | 999 | Estanques para siempre | 3720102941 |
| `Pond11` | Estanque sagrado x50 | 799 | Solo con Robux (centro de la isla) | 3718642542 |
| `Spin1` | 1 giro de ruleta | 24 | Giros de la ruleta (se guardan; no se regalan) | 3720102974 |
| `Spin5` | 5 giros de ruleta | 80 | Giros de la ruleta (se guardan; no se regalan) | 3720103018 |
| `GiftVIP` | Regalar VIP | 299 | Regalar el pase VIP a otro jugador | 3720103057 |
| `GiftReyDelMar` | Regalar Rey del Mar | 149 | Regalar el traje Rey del Mar a otro jugador | 3720103257 |
| `GiftDiosDelVolcan` | Regalar Dios del Volcán | 399 | Regalar el traje Dios del Volcán a otro jugador | 3720103306 |
| `Rod2` | Caña nivel 2 | 5 | MEJORAS en Robux (el nivel 1 es gratis): cañas | 3720103346 |
| `Rod3` | Caña nivel 3 | 15 | MEJORAS en Robux (el nivel 1 es gratis): cañas | 3720103386 |
| `Rod4` | Caña nivel 4 | 29 | MEJORAS en Robux (el nivel 1 es gratis): cañas | 3720103425 |
| `Rod5` | Caña nivel 5 | 59 | MEJORAS en Robux (el nivel 1 es gratis): cañas | 3720103460 |
| `Rod6` | Caña nivel 6 | 99 | MEJORAS en Robux (el nivel 1 es gratis): cañas | 3720103651 |
| `Rod7` | Caña nivel 7 | 199 | MEJORAS en Robux (el nivel 1 es gratis): cañas | 3720103684 |
| `Rod8` | Caña nivel 8 | 349 | MEJORAS en Robux (el nivel 1 es gratis): cañas | 3720103728 |
| `Rod9` | Caña nivel 9 | 599 | MEJORAS en Robux (el nivel 1 es gratis): cañas | 3720103769 |
| `Rod10` | Caña nivel 10 | 999 | MEJORAS en Robux (el nivel 1 es gratis): cañas | 3720103796 |
| `Basket2` | Canasta nivel 2 | 9 | canastas | 3720103835 |
| `Basket3` | Canasta nivel 3 | 25 | canastas | 3720104011 |
| `Basket4` | Canasta nivel 4 | 49 | canastas | 3720104056 |
| `Basket5` | Canasta nivel 5 | 129 | canastas | 3720104096 |
| `Basket6` | Canasta nivel 6 | 299 | canastas | 3720104141 |
| `Boots2` | Botas nivel 2 | 5 | botas | 3720104189 |
| `Boots3` | Botas nivel 3 | 19 | botas | 3720104237 |
| `Boots4` | Botas nivel 4 | 39 | botas | 3720104375 |
| `Boots5` | Botas nivel 5 | 79 | botas | 3720104441 |
| `Boots6` | Botas nivel 6 | 199 | botas | 3720104467 |

## Pases

| Clave | Nombre | Precio R$ | ID |
|---|---|---|---|
| `VIP` | VIP | 299 | 2036600514 |
| `DiosDelVolcan` | Dios del Volcán | 399 | 2036326912 |
| `ReyDelMar` | Rey del Mar | 149 | 2037994956 |

Descripciones para el Creator Hub:
- **Rey del Mar:** Traje de rey con corona y capa. Pescas x2 más rápido (y recoges con el doble de fuerza), alimentas al monstruo x2 más rápido y ganas x2 kills.
- **Dios del Volcán:** Traje de fuego con corona ardiente. Pesca ultrarrápida (pican x5 y sacas cualquier pez de un toque), alimentas al monstruo x4 más rápido y ganas x4 kills.

Creator Hub → tu juego → Monetización → Pases → Crear pase. Después, en el pase → **Ventas**: activar "Artículo a la venta" y poner el precio.
