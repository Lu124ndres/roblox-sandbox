# Feed the Giants / Alimenta a los Gigantes: contexto completo del juego

Documento para darle contexto a Claude (u otro asistente) sobre qué es el juego, cómo
funciona, qué modelos tiene y dónde vive cada cosa en el código. Los números salen del
código actual (`src/shared/Config/*`), revisado el 2026-10-17. Si un documento viejo de
`docs/` dice otra cosa (por ejemplo `alcance.md` o `roadmap.md`), **manda el código**.

---

## 1. Resumen en una frase

Simulador cooperativo de Roblox: pescas en una isla tropical, llevas los peces al cráter
de un volcán y **todo el servidor alimenta a un monstruo gigante** que crece en 4 etapas.
Cuando se llena, todos los que ayudaron ganan una **kill**. Después hay un descanso con
bonus y una ruleta elige el siguiente monstruo.

- **Nombre público:** Feed the Giants (inglés) / Alimenta a los Gigantes (español).
- **Experiencia en Roblox:** id 10770885547, lugar inicial 129133484868369. Todavía es privada.
- **Dueño:** lu124ndres (UserId 147364237, también es el admin del juego).
- **Género:** Simulación / simulador incremental. Va para PC, teléfono, tablet y consola.

---

## 2. Stack y reglas de trabajo (resumen de `CLAUDE.md`)

- **Lenguaje:** Luau puro con `--!strict` en todos los archivos. Sin roblox-ts.
- **Sincronización:** Rojo 7.7.1 lleva `src/` a Studio (el plugin de Rojo debe estar conectado).
- **Archivo del lugar:** `PescaYAlimentaGigantes.rbxl`. Los modelos 3D viven en ese archivo
  (en `ServerStorage`), no en Rojo.
- **Herramientas** (con Rokit): selene (linter), StyLua (formato) y Wally.
- **MCP de Roblox Studio:** sirve para probar en vivo (`execute_luau`, `start_stop_play`,
  `screen_capture`, `get_console_output`).
- **Blender 5.x:** modelos, rigs y texturas. Scripts en `tools/blender/` y salidas en
  `assets/blender/` y `assets/textures/`.

**Reglas no negociables:**
1. **Servidor autoritativo.** El cliente solo pide; el servidor decide dinero, progreso e
   inventario.
2. **Todo RemoteEvent valida** tipo, rango y permiso de cada argumento.
3. **Nada de `while true` sin espera.**
4. **Nunca se edita en Studio lo que vive en `src/` o `world/`** (Rojo lo pisa).
5. **Módulos de 200 líneas como máximo.** Si pasa, se divide.
6. **Todo `rbxassetid` vive en `src/shared/Assets/`** (`init.luau` para mallas y UI,
   `Textures.luau`, `Products.luau`).
7. **Todo número de balance vive en `src/shared/Config/`.**
8. **Commits en español**, uno por tarea. Cada tarea va en `docs/devlog.md` y las
   decisiones en `docs/decisiones.md`.

**Antes de dar algo por terminado:** `rojo build` compila, `selene src` sin avisos,
`stylua src` aplicado y probado en Studio por MCP.

**Trabajo en paralelo:** `docs/tareas_claude_code.md` es el tablero. Ahí se reparten las
tareas entre Claude Code (código en `src/`) y Cowork (Blender, assets, Studio). Cada uno
hace commit solo de sus archivos.

---

## 3. Bucle de juego

```
pescar (orilla/muelles) -> minijuego de recoger -> canasta
        ^                                            |
        |                                            v
   entrenar poder (estanques AFK)         cruzar el puente -> cráter
        ^                                            |
        |                       alimentar (mantener E): monedas = pez x multiplicador
        |                                            |
   tienda / renacer  <-  kill + descanso  <-  barra llena (4 etapas de crecimiento)
                                   |
                         ruleta -> siguiente monstruo
```

### 3.1 Pesca
- Se pesca desde la orilla o desde los 4 muelles con el botón PESCAR, E o F.
- El corcho cae y el pez pica después de una espera. Esa espera se divide por la velocidad
  que da el poder, y nunca baja de 0.4 s.
- **Minijuego de recoger** (`Config/Reel.luau`, estilo Fish It):
  - Una barra arranca en `startProgress`. Cada toque la sube y el pez la baja con el tiempo.
  - Los peces raros pelean más.
  - El servidor cuenta los toques y tiene un límite por segundo, con margen por ping.
  - Cada nivel de caña suma fuerza, y los pases con traje la multiplican.
- Desde Legendario, todo el servidor ve un cartel con quién lo sacó.
- Nunca se pierde nada: si el pez se escapa, se vuelve a intentar.
- Cada pez se ve en 3D: salta, da coletazos y entra a la canasta. Tiene efectos según su rareza.

### 3.2 Peces: 36 especies en 6 rarezas
Están en `Config/Fish.luau` (12) y `Config/FishMore.luau` (24). Cada pez tiene un `weight`
(peso relativo en la tirada), `food` (cuánto llena la barra) y `coins` (monedas base).

| Rareza | Prob. aprox. | Especies |
|---|---|---|
| Común | 62 % | Sardina, Anchoa, Caballa, Arenque, Lenguado, Boquerón, Pez gato |
| Poco común | 23 % | Pez payaso, Pargo rojo, Pez cirujano, Pez loro, Pez mariposa, Pez ángel |
| Raro | 12 % | Pez globo, Atún, Pez león, Barracuda, Mantarraya, Morena, Pez napoleón |
| Épico | 2.5 % | Pez espada, Rape abisal, Tiburón martillo, Pez vela, Tiburón blanco, Pez remo |
| Legendario | 0.6 % | Pez luna, Pez dorado, Celacanto, Pez de cristal, Pez dragón, Pez fénix |
| Mítico | 0.06 % | Pez arcoíris, Pez galaxia, Pez estelar, Pez celestial |

- **Colección (FishDex):** descubrir cada especie paga según su rareza: Común 25, Poco
  común 75, Raro 250, Épico 1K, Legendario 5K y Mítico 25K.
- Hay un premio cada 6 especies, y 250K monedas al completar las 36.

### 3.3 Poder (la "fuerza") y estanques de entrenamiento
- **Qué es el poder:** la estadística principal. Sale de `Config/Progression.luau` con las
  fórmulas de `shared/FishingPower.luau`.
- **Qué da el poder:**
  - Capacidad de la canasta: `(base + 2·√poder) × canasta`.
  - Peces por pique.
  - Velocidad de pesca: `1 + √poder/40`.
- **Cómo se gana:** entrenando AFK en los estanques de la plaza central. Cada tick suma
  `1 × multiplicador del estanque × caña × bonos`.

Hay 11 estanques. Cada uno se abre con **kills** (para siempre) **o** con **poder** (se
reinicia al renacer):

| # | x | Kills | o poder |
|---|---|---|---|
| 1 | 1 | 0 | 0 |
| 2 | 1.5 | 1 | 3K |
| 3 | 2 | 3 | 15K |
| 4 | 3 | 6 | 150K |
| 5 | 4 | 9 | 1M |
| 6 | 6 | 15 | 20M |
| 7 | 8 | 22 | 500M |
| 8 | 12 | 40 | 50B |
| 9 | 16 | 62 | 1T |
| 10 | 25 | 95 | 20T |
| 11 (sagrado, centro) | 50 | — | solo con Robux |

### 3.4 Alimentar al monstruo (`Config/Giants.luau`, `server/FeedingService` y `server/Feeding/`)
- **Dónde:** desde la orilla del cráter (la línea coral brillante) o desde los muelles del
  lago, manteniendo E.
- **Velocidad:** se entregan 6 peces/s sin renacer (×1.35 por cada renacimiento), o la
  canasta entera en 5 s, lo que sea más rápido.
- **Pago:** `monedas = monedas base del pez × multiplicador del monstruo × bonos`.
- **Tope por persona:** como mucho 1/180 de la barra por segundo. Así una sola persona
  tarda al menos 3 min en llenar un monstruo.
- **Tamaño de la barra:** la comida para llenarla se calcula cuando llega cada monstruo,
  según quiénes están en el servidor (`Feeding/GiantFood`). Así tarda lo mismo con 1
  novato que con 40 jugadores fuertes: Orca ~6 min, Minotauro ~10, Orca fantasma ~10,
  Dragón ~15 y Zorro ~25.
- **Si no se llena en 20 min:** el monstruo se va y la kill se paga igual a todos los que
  aportaron. Con un pez basta (`Feeding/Contributions`).
- **Animación al comer:** los peces vuelan en arco a la boca y el monstruo muerde cada uno.
  Además gira o se acerca hacia quien le da de comer.

### 3.5 Enojo
- Si nadie le da de comer en 45 s (150 s si hay 3 jugadores o menos), se enoja poco a
  poco: llega de 0 a 1 en 60 s.
- Desde el 50 % de enojo, la barra baja sola, pero nunca por debajo del inicio de la etapa
  actual.
- Furioso, cada 9 s lanza un **Salpicón**: aviso con un círculo rojo de 18 studs durante
  3 s y después empuja. Nunca se pierde nada.
- Un solo bocado lo calma.

### 3.6 Ciclo del monstruo
El atributo `Phase` de `EstadoGigante` pasa por `feeding → farewell → rest → arriving`
(`server/GiantCycle`).

1. **Comiendo.** Cada 25 % de la barra el monstruo **evoluciona** a la etapa siguiente
   (3 s, no come). Hay rugido, temblor y olas.
2. **Despedida (7 s).** Todos los que aportaron ganan +1 kill, o ×2 / ×4 con los pases.
3. **Descanso (60–120 s, según los jugadores).**
   - El agua del cráter se vacía en 3 s y del fondo sube la **guarida del descanso**
     (`ServerStorage.GuaridaDescanso`).
   - Quien esté parado en ella gana poder solo: su mejor estanque × el multiplicador del
     monstruo que se llenó.
4. **Ruleta (6 s, la ven todos).** Sale el monstruo que alguien compró (producto
   Choose<Id>). Si nadie compró, sale uno al azar según su peso.
5. **Llega el siguiente (6 s).** El cráter se llena en 2 s (con agua, o con lava para el
   dragón).

### 3.7 Tienda de la cabaña (`Config/Shop.luau`)
Tiene tres mejoras que se compran en orden. El nivel 1 es gratis.

| Mejora | Niveles | Qué da | Rango de precios |
|---|---|---|---|
| Cañas | 20 (bambú → Poseidón) | Multiplicador de poder ×1 → ×6500, más suerte +0 → +300 % | 150 → 16B |
| Canastas | 14 (mimbre → bóveda infinita) | Capacidad ×1 → ×160 | 300 → 1.6B |
| Botas | 14 (sandalias → Hermes) | Velocidad al caminar 16 → 46 | 200 → 800M |

Las cañas, canastas y botas se ven en el personaje con modelos 3D (`client/Fishing/RodBuilder`,
`BasketBuilder` y `BootBuilder`).

### 3.8 Renacer (`Config/Rebirth.luau`)
- **Costo:** pide monedas **y** poder.
  - Monedas: `40K × 2.8^n`.
  - Poder: `3K × 3^n`.
- **Se gana para siempre:**
  - Velocidad de alimentar ×1.35 por renacimiento.
  - Monedas y poder ×1.25 por renacimiento (es compuesto).
- **Se pierde:** monedas, poder, mejoras de la tienda y la canasta.
- **Se queda:** kills (y los estanques que abren), colección, pases, compras con Robux,
  códigos, insignias y misiones.

### 3.9 Retención
- **Tutorial:** 4 pasos. Pescar 5, alimentar a la Orca, entrenar y comprar una mejora.
  Paga un bonus al final.
- **Premio diario:** racha de 7 días. Da monedas (escalan con el avance), giros de ruleta
  y un bonus de racha de +10 % por día, hasta +100 %.
- **Regalos por tiempo jugado:** 8 regalos entre 5 min y 2 h de la sesión.
- **Misiones diarias:** 3 por día, las mismas para todos, más 1 extra de llenar monstruos
  y un cofre por completarlas.
  - Tipos: `catch` (piques), `feed`, `rare`, `kill`, `train`, `eventCatch` y `food`.
- **Ruleta** (`Config/Spin.luau`):
  - 8 casillas: monedas, cofre, JACKPOT, x2 poder, x2 monedas, llenar 5 % del monstruo y +1 giro.
  - Un giro gratis cada 6 h y 1 giro cada 15 min jugados (máximo 4 por sesión).
- **Eventos del servidor** (`Config/Events.luau`): cada 12 min empieza uno de 3 min.
  - Pesca dorada (suerte), Frenesí (pica más rápido), Lluvia de monedas y Poder doble.
- **Insignias:** primer pez, primer raro, legendario, mítico, primera kill, 10 kills,
  colección completa, tutorial y estanque máximo.
- **Rankings globales** (OrderedDataStore): poder, kills y renacimientos.
- **Títulos sobre la cabeza** según las kills: 24 títulos, de Novato (0) a "Más Allá del
  Infinito" (5000). Las kills no se pierden, así que el título nunca baja.
- **Bonos sociales:**
  - Amigos: +10 % por cada amigo en el servidor, hasta 5.
  - Premium: ×1.2.
  - Grupo: premio por unirse. `groupId` en `Config/Social`; está pendiente de poner.
  - Invitaciones (referral): premio para quien entra y para quien lo invitó.
- **Códigos** (`server/Social/CodeList.luau`):
  - GIGANTES (alias en inglés: GIANTS).
  - ORCA.
  - LANZAMIENTO (alias en inglés: LAUNCH).
  - HALLOWEEN (vence el 2026-11-03).

### 3.10 Monetización (`Config/Monetization.luau`)
Los IDs reales van en `Assets.GamePasses` y `Assets.Products`. Hay que crearlos en el
Creator Hub cuando el juego esté publicado.

**Pases:**

| Pase | R$ | Qué da |
|---|---|---|
| VIP | 299 | Etiqueta dorada, +20 % de suerte y diario ×2 |
| Rey del Mar | 149 | Traje de rey. Pesca ×2 (pica antes y recoge con fuerza ×2), alimenta ×2 y ×2 kills |
| Dios del Volcán | 399 | Traje de fuego con aura. Pesca ultrarrápida de un toque, alimenta ×4 y ×4 kills |

**Productos:**
- **Niveles de Poder y de Monedas** (×2^n, para siempre): 3 → 999 R$.
- **x2 de entrenamiento para todo el servidor:** 15 min, se acumula hasta ×64.
- **Llenar la barra** 25 / 50 / 75 %: 49 / 89 / 129 R$.
- **Elegir el siguiente monstruo:** Orca 25, Minotauro 99, Dragón 265, Zorro 408, Orca fantasma 149.
- **+1 min de descanso:** 25 R$.
- **Estanques:** 2–10 por Robux (25 → 999) y el sagrado (11) por 799.
- **Mejoras de la tienda por Robux.**
- **Giros de ruleta:** 1 por 24 R$ o 5 por 80 R$.
- **Pack de inicio:** 19 R$, una sola vez. Trae 15K monedas, 60 min de impulso, caña 4,
  canasta 3 y botas 4.
- **Regalos:** los pases y varios productos se pueden comprar para otro jugador del servidor.

**Admin (UserId 147364237):** tiene un panel en el juego (`server/Admin`, `client/Menus/Admin*`).
- Órdenes por jugador: `maxUpgrades`, `fish`, `emptyBasket`, `speed`, `pass`, `playtime`,
  `tp`, `visit`, `bring` y `reset`.
- Órdenes del servidor: `giant` (por ejemplo `"Minotauro:3"` = ese monstruo en esa etapa),
  `fill`, `skipRest`, `restTime` y `event`.
- En pruebas se usa `Remotes.AdminCommand:FireServer('giant','Orca:4')`.

---

## 4. Monstruos (gigantes)

Los define `Config/Giants.luau`.
- **Tamaño por etapa:** el monstruo mide `stageHeightsInPlayers × 5.5 studs`. Las etapas
  son **3×, 8×, 15× y 30×** el alto de un jugador: 16.5, 44, 82.5 y 165 studs.
- **Cuándo cambia de etapa:** la barra la dispara al llegar a 0 %, 25 %, 50 % y 75 %.
- **Dónde están los modelos:** en `ServerStorage.<modelBase>E1..E4` (malla con huesos y
  SurfaceAppearance). Se publican a los clientes con `GiantTemplates`.

| Id | Nombre | Multiplicador | Comida mínima | Minutos objetivo | Peso en la ruleta | Estado |
|---|---|---|---|---|---|---|
| Orca | Orca | ×2 | 400 | 6 | 50 | Activo |
| Minotauro | Minotauro | ×4 | 600 | 10 | 30 | Activo |
| DragonMarino | Dragón marino | ×10 | 900 | 15 | 15 | Activo, el cráter se llena de **lava** |
| ZorroDeAgua | Zorro de agua | ×20 | 1500 | 25 | 5 | `released = false`, todavía en prueba |
| OrcaFantasma | Orca fantasma | ×6 | 600 | 10 | 35 | Evento de Halloween, 17-oct → 3-nov-2026 |

### 4.1 Orca
- **Modelos:** `OrcaE1..E4` (bebé, joven, adulta, anciana). Tienen 17 huesos: Raiz, Pecho,
  Cabeza, Mandibula, Boca, Espiraculo, AletaIzq/Der (y 2), Dorsal, Cola1-4 y AletaColaIzq/Der.
- **Código:** `shared/Orca/OrcaMotion` (nado, salir a respirar, ir hacia quien le da de
  comer), `Orca/Etapas` (un perfil por etapa) y `OrcaMotion/Tricks`.
  - Saltos, saltitos, zambullida, coletazo, aletazo, giro, persecución de cola, asomarse,
    rugido y emerger.
- **Efectos:** `Orca/OrcaFx` en el cliente (`client/Giant/OrcaSwim`).

### 4.2 Minotauro
- **Modelos:** `MinotauroE1..E4`, modelados en Blender por código.
  - **E1, becerro:** con faldón.
  - **E2, joven.**
  - **E3, adulto:** con hombreras.
  - **E4, forma final:** grietas de lava, collar de oro, faldón rojo.
- **Huesos (25):** Raiz > Cadera > Columna > Pecho > Cuello > Cabeza > Mandibula, Boca,
  Orejas; brazos, piernas y Cola1-3.
- **Comportamiento:** está de pie en el agua, en el centro. Respira, mira alrededor, se da
  vuelta con pasitos y camina hacia la orilla para comer.
- **Código:** `shared/Minotauro` (Rig, Pose, Trucos y Etapas) y `client/Giant/MinoStand`.
  - Trucos: pisotón, rugido, músculo, baile, rascarse y salto.
  - El becerro baila y salta; la etapa 4 ruge y pisa más fuerte. La voz se hace más grave
    con cada etapa.
- **Efectos:** golpe de agua, ola, temblor, destellos y corazones.

### 4.3 Dragón marino
- **Modelos:** `DragonMarinoE1..E4` (cría → anciano). Tienen 32 huesos: alas de 3 huesos,
  brazos, piernas, cuello de 2, cola de 6 y mandíbula.
- **Comportamiento:** vuela en vueltas sobre la lava, sube y baja, se ladea y planea. Para
  comer se queda frente a quien lo alimenta, aleteando.
- **Código:** `shared/Dragon` (Vuelo, Cuerpo, Pose, Rig, Etapas, Trucos y Estelas) y
  `client/Giant/DragonFly`.
  - Trucos: rugido, fuego, picada, voltereta y planeo.

### 4.4 Zorro de agua
- **Modelo:** zorro de nueve colas azul y blanco, en prueba. Hay dos versiones:
  - La de Claude Code está en `ServerStorage.ZorroDeAguaE4_code`, con 63 huesos y colas de
    4 huesos cada una.
  - La que gane la prueba quedará como `ZorroDeAguaE4`. Faltan E1–E3.
- **Comportamiento:** está parado sobre el agua y sus colas ondulan.
- **Código:** `shared/Zorro` y `client/Giant/ZorroStand` + `ZorroFx`.
  - Trucos: aullido, abanico, salto, sacudida, reverencia y fuegos fatuos.

### 4.5 Orca fantasma (Halloween)
- **Modelos:** `OrcaFantasmaE1..E4`. Son copias de la orca con textura fantasma (violeta,
  marcas cian, oro naranja calabaza) y 12 % de transparencia.
- **Animación:** la misma de la orca.

### 4.6 Cómo se animan
- **Todo es procedural por código** (`Bone.Transform`), sin keyframes.
- **Sincronización:** todos los clientes ven lo mismo porque el recorrido y los trucos
  salen de la hora del servidor (`Workspace:GetServerTimeNow()`).
- **Selección del controlador:** `client/Giant/GiantBody` elige el controlador según los
  huesos del modelo: OrcaSwim, DragonFly, MinoStand o ZorroStand.

---

## 5. Mundo

- **Isla principal** (`world/Isla.model.json`, generada con `tools/generar_isla.py`;
  terreno en `server/World/IslandShape` y `TerrainBuilder`).
  - En el centro: la plaza de entrenamiento con los 11 estanques y una estatua dorada.
  - Además: 4 muelles de madera, la cabaña de la tienda, un campamento, palmeras, rocas y
    un **faro** 3D en un promontorio, con su haz de luz.
- **Puente de piedra con "corriente":** se camina mucho más rápido sobre él. Lleva al
  **Cráter del Abismo**.
- **Cráter del Abismo** (medidas en `shared/WorldLayoutData.json`; terreno en
  `server/World/CraterShape`; centro en `WorldZones.craterCenter` = (0, 0, 520)).
  - **Lago:** radio 190, con agua al nivel 2 y fondo a -150.
  - **Acantilado:** radio 205.
  - **Camino de los jugadores:** en el borde, radio 205–235, a una altura de 30.6.
  - **Muelles:** 8 muelles con calderos entran al lago.
- **Hábitats** (`Config/Habitats.luau`, `server/World/HabitatService` y `HabitatPlacer`,
  efectos en `client/Ambient/HabitatFx`).
  - Cada monstruo tiene su zona decorada, que aparece al cambiar de monstruo. Los props
    son modelos de Blender y viven en `ServerStorage.Habitats.<GiantId>`.

| Monstruo | Hábitat | Props |
|---|---|---|
| Minotauro | Laberinto en ruinas | Columnas, muros con greca, arco, braseros con fuego, cráneo de toro y estandartes |
| Orca | Arrecife | Corales rama, cerebro y abanico, algas, almeja con perla brillante y rocas con percebes |
| Dragón | Nido volcánico | Agujas de obsidiana con lava, cristales, nido con huevos, costillar y fumarolas |
| Orca fantasma | Cementerio marino | Calabazas que brillan, lápidas, barco hundido, faroles fantasma, árboles secos y ataúd |

- **Ambiente** (`client/Ambient/*`):
  - Ciclo de día y noche de 16 min.
  - El cráter tiene su propia hora de sol.
  - Olas, gaviotas, peces que saltan, boyas, nubes y lava en el cráter.
  - Amanecer durante el descanso.
  - El mar se extiende hasta ±1536 studs.

---

## 6. Personaje y trajes

- **Trajes de los pases** (`shared/Trajes` y `server/Social/Outfits`):
  - Rey del Mar: armadura turquesa con corona y tridente.
  - Dios del Volcán: armadura de roca y lava, con aura.
  - Marinero.
- Los trajes son mallas con huesos que siguen al avatar.
- El equipo (caña, canasta y botas) se ve en el personaje.
- Encima de la cabeza (`client/Interface/Overhead*`): título por kills, insignias y
  etiqueta VIP.

---

## 7. Interfaz (`client/Interface`, `client/Menus`)

- **HUD:**
  - Monedas, poder, peces en la canasta y kills.
  - Barra de hambre del monstruo con retrato, etapa y enojo.
  - Botones grandes: PESCAR, TIRA y ALIMENTAR.
  - Siguiente meta, temporizador de eventos y de impulsos.
- **Ventanas:**
  - Tienda: Mejoras y Robux.
  - Pases y regalos.
  - Colección de peces (FishDex), misiones, diario y regalos por tiempo.
  - Ruleta, renacer, códigos, grupo, trajes, ajustes, rankings y panel de admin.
- **Plataformas:**
  - Móvil primero, con ventanas que se adaptan al teléfono (`WindowLayout`).
  - Mando de Xbox y PlayStation: navegación con el mando, y Select saca el ratón virtual.
- **Estilo:**
  - Lenguaje de color: turquesa = pescar, coral = alimentar, dorado = monedas.
  - Fuente de los íconos y logos: Luckiest Guy.
  - Íconos de productos en `assets/ui/productos/`.

---

## 8. Guardado

- **Código:** `server/Save/*` (SaveService, SaveStore, SaveSchema y SaveExtra), con DataStore.
- **Sin publicar:** el juego usa datos en memoria (aviso "SaveStore: DataStore no disponible").
- **Qué se guarda:** monedas, poder, kills, renacimientos, mejoras, colección, misiones,
  racha, giros, pases y compras, códigos, insignias y ajustes.

---

## 9. Mapa del código

```
src/server/        lógica autoritativa (ServerScriptService.Server)
  Main.server.luau, Remotes, RateLimit, PlayerData
  FishingService, ShoreCast, ReelFight, FishLanding      pesca
  FeedingService + Feeding/ (Basket, Contributions, GiantFood, GiantAnger, ...)
  GiantService, GiantCycle, GiantMood, GiantRewards, GiantTemplates, RestArena
  TrainingService, ShopService
  Monetization/ (Passes, Receipts, Gifts, GiantFill, GiantChoice, ServerBoost, RestTime)
  Retention/ (Tutorial, DailyReward, Quests, SpinWheel, Rebirth, Badges, Leaderboards...)
  Social/ (Codes, CodeList, Outfits, FriendBoost, GroupReward, Referrals, EventScheduler)
  Save/, Admin/, World/ (TerrainBuilder, IslandShape, CraterShape, PropDresser, Habitat*)
src/client/        presentación (StarterPlayerScripts.Client)
  Fishing/ (FishingController, Rod*, Bobber, ReelBar, CatchShow...)
  Giant/ (GiantView, GiantBody, OrcaSwim, DragonFly, MinoStand, ZorroStand, FeedThrow...)
  Interface/ (Hud, HungerPanel, Overhead, Icons...), Menus/ (ventanas), Effects/, Ambient/
  Audio/, Shop/, Training/, Settings/, Trajes/
src/shared/        ReplicatedStorage.Shared
  Config/ (todos los números), Assets/ (todos los IDs), UIConfig/ (colores, fuentes)
  Orca/, Minotauro/, Dragon/, Zorro/, Trajes/        animación de monstruos y trajes
  Protocol (atributos y fases), WorldLayout(+Data.json), WorldZones, Perks, FishingPower,
  RebirthMath, RewardScale, GiantStages, NumberFormat, Titles...
tools/blender/     scripts de modelos (minotauro_*.py, rig_*.py, habitats*.py, faro.py, zorro*.py)
assets/            FBX, texturas, UI y productos
docs/              devlog, decisiones, balance, tareas_claude_code, blender-pipeline, productos...
publicar/tienda/   arte de la página del juego (ícono, miniaturas EN/ES, logo, textos)
```

---

## 10. Pipeline de modelos (resumen de `docs/blender-pipeline.md`)

- **Construcción:** los modelos se hacen por código en Blender, como en
  `tools/blender/minotauro_e1.py`.
  - Bloques fusionados por vóxeles.
  - Bake de color y normal a 1024.
  - Rig con pesos automáticos.
- **Exportación FBX:**
  - Ejes: `axis_forward -Z`, `axis_up Y`.
  - `add_leaf_bones=False`.
  - Límite de unos 20K triángulos por malla.
- **Importación en Studio:**
  - Usar Importar 3D con "**Mantener huesos de influencia cero**" marcado (si no, se
    pierden `Boca` y otros huesos de referencia).
  - Mover el modelo a `ServerStorage` con el nombre `<Base>E<n>`. Los viejos van a
    `ServerStorage.Respaldos`.
- **IDs:** las mallas van en `Assets` y las texturas en `Assets/Textures`.

---

## 11. Estado y pendientes (2026-10-17)

**Hecho y probado:**
- Pesca, alimentar, enojo, ciclo con descanso y ruleta.
- Orca, Minotauro, Dragón y Orca fantasma con sus 4 etapas y su hábitat.
- Tienda, renacer, retención completa, monetización (sin IDs reales), trajes y soporte para
  mando y móvil.
- Página del juego en Roblox: nombre, descripciones EN/ES, ícono y 9 miniaturas, en
  revisión de moderación.

**Pendiente:**
- **Zorro de agua:** elegir cuál versión gana y modelar E1–E3. Después, `released = true`.
- **Publicar:** subir la última versión desde Studio y hacer público el juego.
- **Monetización:** crear pases y productos en el Creator Hub y poner los IDs en `Assets`.
- **Grupo:** crear la comunidad "Giant Feeders" y poner el `groupId` en `Config/Social`.
- **Detalles visuales:** el oro de los minotauros se ve verde limón y su boca parece triste.
- **Ideas para después** (no están en el código): mascotas que sean crías de los gigantes
  (huevos), una segunda isla al renacer, intercambio entre jugadores y ganancias mientras
  no juegas.
