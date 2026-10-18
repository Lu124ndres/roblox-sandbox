# Registro de decisiones técnicas

Cada decisión no obvia queda documentada con su contexto, para que cualquier
persona que lea el código entienda por qué está construido así y no de otra forma.

Formato:

```
## AAAA-MM-DD — Título de la decisión
**Decisión:** qué se eligió.
**Contexto:** qué problema o situación la motivó.
**Alternativas consideradas:** qué más se evaluó.
**Por qué:** razones de la elección y costos aceptados.
```

---

## 2026-10-11 — Luau puro sobre roblox-ts

**Decisión:** escribir todo el código en Luau con `--!strict`.

**Contexto:** se necesita tipado estático para que el código sea mantenible y legible
por otros desarrolladores de Roblox.

**Alternativas consideradas:** roblox-ts (TypeScript transpilado a Luau).

**Por qué:** Luau estricto ya ofrece inferencia y chequeo de tipos suficientes. Evita una
capa de compilación, un `node_modules` y un segundo sistema de tipos. El código que corre
es el mismo que se lee, los stack traces apuntan a líneas reales y cualquier
desarrollador de Roblox puede leerlo sin conocer TypeScript. Costo aceptado: un
ecosistema de tipos y herramientas menos maduro que el de TypeScript.

## 2026-10-11 — Rojo sobre editar directo en Studio

**Decisión:** todo el código vive en `src/` y se sincroniza a Studio con Rojo.
Studio solo se usa para construir el nivel.

**Contexto:** el proyecto es público y debe tener historial de cambios revisable.

**Alternativas consideradas:** escribir scripts directamente en Studio con Team Create.

**Por qué:** con Rojo el código está en git: diffs reales, commits atómicos, revisión de
código, linting (selene) y formateo (stylua) automatizables. El editor de Studio no
ofrece nada de eso. Costo aceptado: hay que levantar `rojo serve` y conectar el plugin
cada sesión, y nunca editar en Studio lo que existe en `src/`.

## 2026-10-11 — Rokit sobre Aftman

**Decisión:** gestionar rojo, selene, stylua y wally con Rokit (`rokit.toml`).

**Contexto:** las versiones de las herramientas deben ser fijas y reproducibles en
cualquier máquina.

**Alternativas consideradas:** Aftman, Foreman, instalación manual de binarios.

**Por qué:** Rokit es el sucesor mantenido activamente dentro del ecosistema de Rojo,
lee los formatos de Aftman y Foreman, y es más rápido. Aftman está en modo de
mantenimiento. Un solo `rokit install` deja el entorno idéntico al del autor.

## 2026-10-11 — Primitivas antes que assets (fase 1 / fase 2)

**Decisión:** la fase 1 se construye solo con partes primitivas y colores planos. Los
modelos de Blender entran en la fase 2, uno por uno, cuando el juego esté completo.

**Contexto:** el riesgo principal de un proyecto en solitario es no terminarlo. El
trabajo visual es el más fácil de expandir sin límite.

**Alternativas consideradas:** desarrollar arte y mecánicas en paralelo.

**Por qué:** validar que el juego funciona y es divertido antes de invertir en arte evita
modelar cosas que luego se descartan. Como todos los IDs están centralizados en
`Assets.luau` y los modelos se nombran igual que en código, reemplazar primitivas por
meshes no requiere tocar la lógica. Las ideas visuales que surjan antes se registran en
`docs/ideas.md`.

## 2026-10-11 — TweenService en lugar de animación con rigs

**Decisión:** toda animación se hace por código con TweenService y CFrame (girar, flotar,
deslizar paneles). No se usan rigs ni keyframes.

**Contexto:** el alcance del proyecto no requiere personajes animados propios.

**Alternativas consideradas:** rigs con Animation Editor o Moon Animator; animaciones
exportadas desde Blender.

**Por qué:** las animaciones por código viven en git, se ajustan cambiando un número en
`UIConfig.luau`, no requieren subir ni moderar assets y no dependen de IDs externos.
Los rigs añadirían un pipeline completo (rigging, subida, permisos) sin beneficio para
este tipo de juego.

## 2026-10-12 — Reducir modelos de IA horneando texturas, no solo con decimate

**Decisión:** los modelos generados con IA (Meshy) se reducen en dos zonas (cara con
ratio 0.30, cuerpo con 0.19) y luego se hornea la apariencia del original sobre la malla
reducida con UVs nuevas a 1024×1024: color, normal (tangente, OpenGL) y rugosidad. La
textura original de Meshy no se reutiliza.

**Contexto:** la orca de Meshy tenía 46,748 triángulos y texturas de 2048. Con solo
decimate, los bordes pintados (parche del ojo, mancha celeste) quedaban dentados porque
la textura estaba pintada para la malla original y las UVs se deforman al colapsar
aristas.

**Alternativas consideradas:** decimate uniforme (deforma ojos y sonrisa); decimate con
grupo de vértices (protege la cara pero deja el cuerpo con ~200 triángulos); reutilizar
las UVs de Meshy reduciendo la textura a 1024 (bordes dentados).

**Por qué:** el horneado separa la geometría de la apariencia: la malla puede ser tan
simple como pida el límite y la textura sigue viéndose como el original. Costos: hay que
verificar que las UVs nuevas no se solapen (Smart UV Project con 66° solapaba las aletas;
con 35° no) y que la distancia de proyección no tome superficies vecinas.

## 2026-10-12 — El mapa vive en git como modelo de Rojo generado por script

**Decisión:** la playa es `world/Playa.model.json`, mapeado a `Workspace.Playa` en
`default.project.json` y generado por `tools/generar_playa.py`. La iluminación también
se declara en el proyecto (`Lighting`, `Atmosphere`, efectos).

**Contexto:** `CLAUDE.md` reservaba Studio para construir el nivel, pero el nivel así
vive solo en el `.rbxl`, que no está en el repositorio: un clon no tiene mapa y
`rojo build` genera un lugar vacío.

**Alternativas consideradas:** construir en Studio y exportar un `.rbxm` binario
(no se puede revisar en un diff); construir el mapa por código al arrancar el servidor
(no se ve en modo Edit).

**Por qué:** el mapa aparece en Studio y en `rojo build`, cada cambio es un diff legible
del script, y la semilla fija hace que el resultado sea idéntico en cada corrida. Costos:
el mapa no se edita a mano en Studio (Rojo lo sobrescribe) y hace falta Python para
regenerarlo. El JSON generado se versiona igual, para que el proyecto compile sin Python.

## 2026-10-12 — Los gigantes usan su modelo final desde la fase 1

**Decisión:** la Orca usa `ServerStorage.OrcaE1` ya en el vertical slice, como excepción
explícita a la regla de primitivas de la fase 1. El resto del mapa sigue siendo de
primitivas.

**Contexto:** pedido explícito: el gigante es el centro del juego y su lectura (tamaño,
cara, crecimiento) no se puede validar con un cubo.

**Alternativas consideradas:** marcador de primitivas hasta la fase 2.

**Por qué:** el modelo ya existía y estaba importado. `GiantModel` lo busca por nombre,
valida su `MeshId` contra `Assets.Meshes` y, si falta (por ejemplo en un lugar de
`rojo build`), usa un marcador de primitivas: el juego nunca depende del `.rbxl`.

## 2026-10-12 — Crecimiento continuo con Model:ScaleTo y alto objetivo en Config

**Decisión:** un solo modelo por gigante, escalado con `Model:ScaleTo` hacia un alto en
studs que interpola entre `heightMinStuds` y `heightMaxStuds` según la barra, con
acercamiento exponencial (~1.2 s). El pivote se coloca en la base del MeshPart.

**Contexto:** la Orca importada medía 4.2 studs en lugar de 15 (devlog del 2026-10-12).

**Alternativas consideradas:** reimportar con otra unidad; un modelo por etapa.

**Por qué:** el código ya tiene que escalar para crecer, así que el alto real del modelo
importado deja de importar: se mide al clonar y se escala al alto que pide `Config`.
Esto cierra la decisión pendiente de la escala sin reimportar.

## 2026-10-12 — Hambre como progreso relativo, escalado por jugadores conectados

**Decisión:** el estado del gigante es un progreso 0..1. Cada bocado suma
`comida / (comidaPorJugador x jugadores)`, con los jugadores acotados entre 1 y 12.

**Contexto:** con un total fijo, un servidor lleno vacía la cadena en minutos y uno con
dos jugadores no la termina nunca.

**Alternativas consideradas:** total fijo; total fijado al aparecer el gigante (si el
servidor arranca vacío, el total queda en 1 jugador para siempre).

**Por qué:** la duración por gigante queda cerca del objetivo con cualquier población y
la barra nunca retrocede cuando alguien entra o sale. Costo: el valor de un pez en
porcentaje cambia con la población, cosa que el jugador no ve.

## 2026-10-12 — Multiplicadores: x1 y x3 en la v1, x8 y x20 provisionales para eventos

**Decisión:** ver `docs/alcance.md`, sección "Calibración".

**Contexto:** los valores de partida eran x1, x3, x10 y x30.

**Por qué:** cada gigante también dura más que el anterior, así que el multiplicador se
compone con el tiempo. Con x10/x30 la última etapa concentra el 74 % de las monedas del
ciclo; con x8/x20 cada etapa paga ~3 veces la anterior. Los de la v1 no cambian.

## 2026-10-12 — Pesca con ventana generosa y sin castigo por tirar antes

**Decisión:** ventana de 2.5 s que ve el cliente más 0.75 s de margen en el servidor. Un
`ReelIn` antes de que pique se ignora en lugar de espantar al pez.

**Contexto:** la mayoría juega en móvil y con ping alto.

**Por qué:** el servidor mide la ventana desde que manda la picada, así que el ping de
ida ya se come parte del tiempo; el margen lo devuelve. Ignorar los toques tempranos
evita castigar dedos nerviosos en pantallas táctiles. Probado con la latencia del
control remoto de la sesión de prueba (2–3 s por acción): el bucle sigue siendo jugable.

## 2026-10-12 — Isla generada: terreno por vóxeles y piezas desde una geometría común

**Decisión:** la isla tiene dos fuentes generadas que leen `src/shared/WorldLayoutData.json`:
el terreno (`server/World/TerrainBuilder` + `IslandShape`, al arrancar el servidor) y las
piezas (`tools/generar_isla.py` → `world/Isla.model.json`).

**Contexto:** el agua de Terrain (olas, reflejos, nado) y los materiales de terreno se ven
mucho mejor que partes; pero el terreno no cabe en un archivo de Rojo.

**Alternativas consideradas:** `FillCylinder`/`FillBall`. Se probaron y redondean a la
cuadrícula de 4 studs: el suelo quedó 4 studs más alto que las piezas y tapó el anillo de
madera. `WriteVoxels` con la ocupación calculada deja cada superficie a la altura exacta.

**Por qué:** una sola tabla de medidas evita que terreno, piezas y validaciones se
desfasen. Costos: el terreno solo existe al darle Play (o al llamarlo desde la barra de
comandos) y tarda unos segundos en generarse.

## 2026-10-12 — El gigante se dibuja y anima en el cliente

**Decisión:** el servidor solo publica el estado (id, progreso) y un evento GiantFed. Las
plantillas se copian a `ReplicatedStorage.ModelosGigantes` y cada cliente clona y anima
su propio gigante (`client/Giant`).

**Por qué:** mover un modelo anclado desde el servidor se replica a saltos; en el cliente
la animación va a 60 fps y no gasta red. El gigante no colisiona, así que no hay estado
físico que sincronizar.

## 2026-10-12 — Brazo por Transform después del Animator; caña orientada con el cuerpo

**Decisión:** `ArmPose` suma la pose al `Transform` del hombro en `PreSimulation`, y la
caña se coloca cada cuadro desde la mano con la orientación del `HumanoidRootPart`.

**Contexto:** el avatar de prueba usa las articulaciones nuevas (`AnimationConstraint`,
no `Motor6D`): cambiar `C0` o el attachment no movía el brazo porque el Animator lo pisa,
y la orientación de la mano cambia entre avatares (la caña salía de costado).

**Por qué:** modificar `Transform` justo después del Animator funciona igual con
`AnimationConstraint`, `Motor6D` R15 y R6, y la animación de caminar sigue debajo. Orientar
la caña con el cuerpo la hace independiente de cómo cada avatar orienta la mano.

## 2026-10-12 — Pesca desde cualquier punto de la orilla

**Decisión:** el cliente pide `CastRequest` sin argumentos; `ShoreCast` acepta si el jugador
está a partir de `fishingBandInner` del centro, de pie y fuera del agua, y calcula dónde
cae el corcho (hacia donde mira si mira al mar; si no, hacia afuera; nunca en la arena).

**Por qué:** pedido de diseño: los muelles dejan de ser obligatorios. El cliente no manda
posiciones: el servidor usa la posición real del personaje.

## 2026-10-12 — Hora del día calculada en cada cliente con el reloj del servidor

**Decisión:** `SkyCycle` calcula la hora con `Workspace:GetServerTimeNow()` y ajusta luz,
bruma y tono cada cuadro.

**Por qué:** cambiar `ClockTime` desde el servidor se replica a saltos y mueve las sombras
a tirones. Con el reloj compartido todos ven el mismo cielo sin tráfico de red.

## 2026-10-12 — Sonidos de la Tienda de creadores y del cliente de Roblox

**Decisión:** los efectos salen de audio público de la Tienda de creadores (IDs en
`Assets.Sounds`) y de los sonidos que trae Roblox instalados (`rbxasset://sounds/...`).

**Por qué:** subir audio propio exige verificación y cuota; los públicos sirven para el
vertical slice. Se verificó en Studio que todos cargan (`IsLoaded`). Si alguno se retira
de la tienda, la clave queda en `MISSING` y el juego sigue sin ese sonido.

## 2026-10-13 — El gigante vive en un cráter aparte, no en el centro de la isla

**Decisión:** el gigante se mudó al Cráter del Abismo, una isla volcánica unida por un
puente. El centro de la isla principal pasó a ser la zona de entrenamiento.

**Contexto:** en la etapa 4 el gigante mide 25 jugadores (137.5 studs de alto y ~230 de
largo con la Orca). No cabía en la laguna central de 26 studs y además se pidió una zona
"mucho más increíble y aterradora".

**Por qué:** un lago de 136 studs de radio rodeado de acantilados le da espacio a la etapa
4, y una zona separada permite cambiar todo el ambiente al cruzar el puente (ZoneMood)
sin afectar a la isla.

## 2026-10-13 — Crecimiento por etapas en múltiplos del alto de un jugador

**Decisión:** `Config.Giants.stageHeightsInPlayers = { 3, 8, 15, 25 }` con un jugador de
referencia de 5.5 studs; las etapas empiezan en 0, 25, 50 y 75 % de la barra. Se dejó el
crecimiento continuo dentro de cada etapa.

**Por qué:** el tamaño en "jugadores" es como lo piensa el diseño y se ajusta en un solo
lugar. Crecer de golpe en cada etapa (con animación) se lee mejor que un crecimiento
imperceptible, y cada etapa se vuelve un momento.

## 2026-10-13 — Entrenamiento AFK con ticks en el servidor

**Decisión:** un bucle de 1 s en `TrainingService` suma poder a cada jugador que está en un
estanque. La sesión se corta si el jugador se aleja más de 7 studs de donde empezó.

**Por qué:** el servidor decide todo el poder; el cliente solo pide empezar (con el
ProximityPrompt) y muestra los números. El bucle único escala bien con 50 jugadores.

## 2026-10-13 — Config y UIConfig como carpetas

**Decisión:** `Config` y `UIConfig` son carpetas con `init.luau` y secciones (`Types`,
`Giants`, `Progression`, `Sounds`). El resto del código sigue haciendo
`require(Shared.Config)`.

**Por qué:** los dos pasaban de 200 líneas (regla 5 de CLAUDE.md). Los tipos viven en
`Types.luau` para que las secciones los usen sin requerir a quien las junta.

## 2026-10-13 — El poder de pesca da velocidad y cantidad, no valor por pez

**Decisión:** el poder ya no multiplica lo que rinde cada pez al alimentar. Ahora acorta la
espera hasta el pique (`1 + raíz(poder)/40`, mínimo 0.4 s), da más peces por pique
(`1 + piso(raíz(poder)/60)`) y sube la capacidad en la misma proporción. Las fórmulas viven en
`Shared/FishingPower.luau`, que usan el servidor y el HUD.

**Por qué:** lo pidió el diseño ("que pesques más peces más rápido"). Además se ve: el
jugador fuerte llena su carga en pocos lanzamientos y va al volcán menos veces. Que la
capacidad crezca con los peces por pique evita que un jugador fuerte tenga que ir a
entregar cada dos lanzamientos.

## 2026-10-13 — Puente con corriente en vez de portales

**Decisión:** para que entregar sea rápido, el puente al volcán sube la velocidad de
caminar a 44 mientras se está encima (`client/Ambient/BridgeBoost`). No hay portales.

**Por qué:** el diseño no quiere portales. Cambiar la velocidad del propio personaje es
del cliente (Roblox ya le da la física de su personaje) y no da ninguna ventaja que el
servidor tenga que validar.

## 2026-10-13 — Enojo del gigante por tiempo sin comer

**Decisión:** `server/GiantMood` calcula el enojo con los segundos desde el último bocado
(gracia 45 s, rampa 60 s) y lo publica en `EstadoGigante.Anger`. Molesto, la barra baja
pero nunca por debajo del inicio de la etapa; furioso, Salpicones cada 9 s con 3 s de
aviso. Un solo bocado lo calma del todo.

**Por qué:** que el gigante "se enoje si no es alimentado" sin castigar de más: no encoge
(no se pierde una etapa ganada), el ataque solo empuja y nunca quita peces, y con 40-50
jugadores basta que uno entregue para calmarlo.

## 2026-10-13 — El hambre sigue al ritmo de pesca del servidor

**Decisión:** la comida total = `comida por jugador x jugadores (1 a 50) x ritmo medio`,
donde el ritmo de cada jugador es `FishingPower.rateFactor(poder)` (nunca menos de 1).
`foodPerPlayer` se recalibró para un jugador sin poder con carga de 20 y el puente rápido.

**Por qué:** con el poder nuevo un jugador fuerte trae hasta ~22 veces más comida por
minuto; sin esto el gigante se llenaría en segundos. Igual que con la cantidad de
jugadores, el total se recalcula en cada bocado y la barra no salta hacia atrás.

## 2026-10-13 — Alimentar desde cualquier punto de la orilla del volcán

**Decisión:** remote `FeedRequest` sin argumentos; el servidor valida con
`WorldZones.isOnCraterShore` (dentro del anillo exterior del cráter y a la altura del
borde o de los muelles) y con una espera de 0.5 s entre pedidos. El cliente muestra el
botón Alimentar en el mismo lugar que Pescar (en el volcán no se pesca) y F hace la acción
que toca según dónde se está. Los calderos con E se quedan.

**Por qué:** con 40-50 jugadores, unos pocos calderos hacían fila y obligaban a caminar
hasta un punto exacto. La orilla entera reparte a la gente y acorta la entrega.

## 2026-10-13 — Comida fija por gigante (reemplaza "el hambre sigue al ritmo de pesca")

**Decisión:** cada gigante pide una cantidad fija de comida (`Config/Giants.luau`,
`food`): Orca 2,500, Minotauro 15,000, Dragón 75,000, Zorro 300,000. Ya no escala con
los jugadores conectados ni con su poder.

**Por qué:** lo pidió el diseño: habrá monstruos más difíciles y la Orca debe ser la más
fácil. Con comida fija, más jugadores y más poder llenan antes, que es la recompensa de
entrenar; la dificultad crece de gigante en gigante.

## 2026-10-13 — Rarezas de peces y modelos de primitivas por especie

**Decisión:** 12 peces en 6 rarezas (`Config/Fish.luau`, `Shared/FishCatalog`). Los
modelos se arman en el cliente con primitivas (`Effects/FishShapes` + `FishFeatures`),
sin mallas importadas. El momento de la captura crece con la rareza (`CatchShow`).

**Por qué:** variedad y "suerte" sin depender de modelos de Blender todavía; con
primitivas cada pez se ve distinto, pesa poco y se dibuja igual en la tarjeta 3D, en la
mano del jugador y volando al gigante.

## 2026-10-13 — Guardado con bloqueo de sesión propio

**Decisión:** `Save/SaveStore` guarda `{ data, lock = { jobId, time } }` con `UpdateAsync`.
Un servidor solo abre o escribe un registro si el bloqueo es suyo, no existe o venció
(300 s sin renovar; el autoguardado lo renueva cada 60 s). Al entrar, si otro servidor
aún lo tiene, se espera hasta 30 s y luego se expulsa con un mensaje amable. Se guardan
también los peces de la canasta (nunca se pierden al salir). Sin DataStore disponible,
una tabla en memoria con el mismo comportamiento.

**Por qué:** es la causa más común de pérdida o duplicación de datos en Roblox (cambiar
de servidor mientras el anterior todavía guarda). Escrito a mano en vez de usar
ProfileService/ProfileStore para no sumar dependencias (Wally) por ahora; si crece la
complejidad (comercio entre jugadores, compras), conviene migrar a ProfileStore.

## 2026-10-13 — Al llenar al gigante: descanso del volcán y ruleta

**Decisión:** al llenarse, el gigante se despide y empieza un descanso de 2 min: dentro
del volcán todos ganan poder solo, x2 de su mejor estanque desbloqueado. Después una
ruleta elige al siguiente entre los gigantes con `inRoulette`; por ahora solo la Orca.
Reemplaza a la cadena fija Orca → Minotauro y a la Escama del ciclo.

**Por qué:** lo definió el diseño. Llenar al gigante premia a todo el servidor de
inmediato y lleva a todos al volcán (momento social); la ruleta da variedad sin obligar a
tener todos los modelos el día del lanzamiento. El servidor reparte el poder (bucle de
1 s en `GiantCycle`), igual que los estanques.

## 2026-10-13 — Guarida del descanso, kills y estadísticas Poder/Kills

**Decisión:** el x2 del descanso solo se gana abajo, sobre una plataforma que emerge en
el centro del lago (`GuaridaDescanso` en el mapa, `RestArena` en el servidor), con rampas
desde la punta de los 8 muelles (la pared de la punta se abre en el descanso). Llenar a un
monstruo da +1 kill a todos los que le dieron de comer. La tabla de jugadores muestra
Poder y Kills; las monedas quedan en el HUD (atributo `Coins`).

**Por qué:** lo pidió el diseño: bajar a la guarida es un momento de todo el servidor
juntos donde estaba el monstruo, y las kills reemplazan a las escamas como medida de
cuántos monstruos llenó cada uno. La guarida vive en `ServerStorage`
(`world/GuaridaDescanso.model.json`) y solo existe en el mundo durante el descanso: emerge
del lago al derrotar al monstruo y se hunde al terminar.

## 2026-10-13 — Tienda: mejoras en orden, sin elegir equipo

**Decisión:** tres categorías (cañas, canastas, velocidad) con niveles que se compran uno
tras otro; siempre está equipado el mejor nivel comprado. La caña multiplica el poder que
se gana entrenando (estanques y descanso) y la suerte; no cambia la velocidad de pesca
(eso lo da el poder). El servidor guarda solo el nivel de cada categoría.

**Por qué:** es lo que pidió el diseño (cañas, canastas y velocidad) y es lo más simple de
entender y de equilibrar: un número por categoría, sin inventario. Las cañas alimentan al
poder, que a su vez da más peces y más rápido: un solo eje de progreso.

## 2026-10-13 — E para todo en PC y entrega de 1 en 1

**Decisión:** en PC, E lanza, tira y alimenta (ContextActionService; F y X siguen). Los
ProximityPrompts de los calderos se quitaron para que E no haga dos cosas. Alimentar
entrega los peces de 1 en 1 desde el servidor, repartidos en ~4 s.

**Por qué:** lo pidió el diseño (no hacer clic en PC, y ver los peces irse uno por uno).
La entrega por pez la decide el servidor, así que se puede cortar con justicia si el
jugador se va o el gigante se llena, sin perder lo que queda en la canasta.

## 2026-10-13 — Corrección de la altura del terreno

**Decisión:** las ocupaciones de `WriteVoxels` se calculan restando medio vóxel para el
suelo; el agua queda igual. Medido: con la fórmula anterior el suelo quedaba 2 studs más
alto que `WorldLayout`.

**Por qué:** todo lo que se pone sobre el suelo (bordes de estanques, bancos, faroles)
usa las alturas del diseño; con el terreno corrido quedaban enterrados y los estanques
hundidos.


## 2026-10-13 — Retención: sin DataStore extra por jugador

Todo lo de retención (especies, tutorial, racha, ajustes, insignias) va dentro del mismo
guardado del jugador (v4), no en stores aparte: una sola escritura con bloqueo de sesión.
Solo el ranking usa OrderedDataStore (RankingPoder, RankingKills), refrescado cada 120 s
para no gastar el presupuesto de escrituras con servidores de 40–50 jugadores.
Los ajustes se aplican en el cliente al momento y el servidor solo guarda booleanos de
claves conocidas. La música es solo de catálogo con licencia de Roblox (APM/DistroKid),
que cualquier juego puede usar sin subirla.

## 2026-10-13 — Monetización: qué se vende y cómo se entrega

Pedido del usuario: pases x2 Poder, x2 Monedas y VIP; productos para comprar cada
estanque, x2 de entrenamiento para todo el servidor y llenar al monstruo (25, 50, 75 % o
entero). Se aceptó que acortar el reto cooperativo es parte del producto: el que paga
llena para todos y todos los que le dieron de comer se llevan la kill.

- Los efectos se leen de atributos que solo pone el servidor (`Perks`), así cliente y
  servidor calculan igual y el cliente nunca decide.
- Un llenado comprado mientras el monstruo descansa no se pierde: queda en fila y se
  aplica cuando vuelve a comer (uno por vez).
- Recibos: el PurchaseId se anota en el guardado y se guarda en el momento; si el guardado
  falla se devuelve NotProcessedYet y Roblox reintenta (en el mismo servidor no se
  entrega dos veces porque el id ya está anotado en memoria).
- Los precios en Robux son sugeridos (`Config.Monetization`); la tienda muestra el precio
  real de Roblox cuando el ID existe.

## 2026-10-13 — Mejoras de Robux por niveles

Pedido del usuario: Poder y Monedas x2 → x4 → x8 comprables sin límite fijo, empezando en
R$ 3 y cada vez más caros; el x2 del servidor también sube con cada compra y reinicia sus
15 min. Como un producto de Roblox tiene un solo precio, cada nivel es un producto aparte
(10 de Poder, 10 de Monedas, 6 del servidor). Se puso tope en el nivel 10 (x1024) y x64
para el servidor: más allá los números rompen el balance; se revisará con telemetría.
Si dos personas compran el mismo nivel del servidor a la vez, la segunda queda un nivel
más arriba (pagó el precio del nivel anterior); se acepta por simple.

## 2026-10-13 — HUD estilo simulador con íconos 3D

Se eligieron íconos 3D hechos con piezas en ViewportFrames en vez de imágenes subidas:
no dependen de assets externos ni de moderación, combinan con los peces de la colección y
se ven igual en todos los dispositivos. El HUD vive en dos columnas con UIScale según el
alto de la pantalla para que en teléfonos acostados no tape Pescar, Saltar ni el joystick.

## 2026-10-13 — Códigos en el servidor e impulsos que se multiplican

La lista de códigos vive en `server/Social/CodeList` (no en Config, que se replica al
cliente y cualquiera podría leerla). El impulso de amigos, el personal, las mejoras de
Robux y el entrenamiento del servidor se multiplican entre sí en `Perks`; las monedas
con decimales (x1.1 de amigos) se redondean hacia abajo al darlas.

## 2026-10-14 — Regalos con productos normales y un aviso previo

Roblox no deja comprar un producto "para otro" ni regalar pases. En vez de duplicar cada
producto como "regalo", el cliente avisa antes de abrir la compra (`SetGift`: producto y
jugador) y el servidor lo recuerda 2 minutos; si cancela, se borra. El riesgo (comprar
para uno y que llegue a otro) se evita porque el aviso es del mismo producto y se consume
con el primer recibo. Solo VIP necesita un producto aparte (`GiftVIP`). Lo que es de todo
el servidor (entrenamiento, llenar, elegir monstruo) no tiene botón de regalo.

## 2026-10-14 — La comida del monstruo vuelve a escalar con los jugadores activos

Con comida fija, en un servidor lleno lo que todos guardan durante el descanso basta
para llenar al monstruo apenas llega. La comida se calcula al llegar con la capacidad de
canasta de los jugadores **activos** (pescaron en 3 min o llevan peces) y solo puede
subir mientras come; `food` queda como mínimo. Así un monstruo dura más o menos lo mismo
con 1 o con 50 jugadores.

## 2026-10-14 — Modelos desde Blender: deben llegar parados

El importador 3D de Studio no aplica el cambio de ejes de un FBX de Blender (Z arriba):
el Minotauro llegó acostado. `exportar.py` ahora usa `bake_space_transform`. Con Meshy,
revisar en la vista previa del importador que el modelo esté parado antes de importar.

## 2026-10-14 — Los estanques se abren con monstruos llenados

Pedido del usuario: el progreso de estanques sigue a los monstruos que ayudaste a
llenar (kills, con al menos 0.5 % de la barra), no al poder. Premia jugar en equipo y
evita que entrenar solo en un estanque abra el siguiente. Umbrales en
`Config/Progression.luau` (`requiredKills`).

## 2026-10-16 — El dragón descansa con las alas en planeo

**Contexto:** el rig anterior dejaba de reposo las alas arriba (arriba del aleteo). Al planear,
que es lo que más hace, el ala estaba en su pose más forzada y la membrana se estiraba.
**Decisión:** `rig_dragon.py` posa las alas horizontales (con un poco de diedro) y hornea esa
pose como reposo; el aleteo sube y baja simétrico alrededor. El código no guarda un ángulo por
etapa: `Dragon/Rig` mide al enlazar cuánto hay que bajar el ala (`neutral`), así funciona con
modelos viejos y nuevos.

## 2026-10-16 — Un monstruo con una sola etapa modelada la usa en todas

**Contexto:** el zorro de agua solo tiene E4. `GiantBody` elige la animación con el modelo de
la etapa 1: con la orca teñida de reemplazo, al crecer le habría puesto la animación de orca.
**Decisión:** `GiantTemplates.ownTemplate` busca la etapa pedida, las anteriores y después las
siguientes; la orca teñida solo aparece si el monstruo no tiene ningún modelo propio.

## 2026-10-16 — Hábitats: la luz en el servidor, el fuego en el cliente

**Contexto:** el modo rápido (`lowFx`) es de cada jugador, y `FxQuality` solo apaga los Fire
que ya existen al cambiar el ajuste; un Fire que el servidor crea después (al cambiar de
gigante) quedaría prendido. **Decisión:** la PointLight la pone `HabitatPlacer` (se ve igual
para todos y es barata); el Fire y el latido del Neon los crea `Ambient/HabitatFx` en el
cliente, que no crea fuego en modo rápido y lo quita al activarlo. Cada prop va con
`ModelStreamingMode = Atomic`: con streaming, el cliente lo recibe entero (con `Llama` y
`Brillo`) o no lo recibe.

## 2026-10-16 — El volcán tiene su propia hora de sol

**Contexto:** el cráter mezclaba su luz de lava con la del ciclo de día y noche, pero
`ClockTime` seguía la hora de la isla. De noche el sol está abajo: solo quedaba la luz ambiente
y la bruma, y no se veía al monstruo. **Decisión:** `SkyCycle` lleva el reloj hacia
`SkyMoods.craterHour` (por el camino corto) según `ZoneMood.blend()`, igual que el amanecer del
descanso lo lleva a la mañana. La isla conserva su noche; el volcán siempre se juega con luz.

## 2026-10-16 — El pisotón del minotauro se queda en 57°

**Contexto:** con el faldón v2 E1, el pisotón del juego (`Minotauro/Trucos.luau`, muslo
1.0 rad = 57.3°) obliga a levantar `FaldonFrente` 55° para que el muslo no lo atraviese. Se
propuso bajar el muslo a 55° para que pidiera menos. **Decisión:** no se cambia. La curva de
`tools/blender/minotauro_v2_e1_pisoton.py` (`curva_muslo_faldon` en
`renders/minotauro_v2_e1/pisoton.json`) no baja con el muslo: tiene su pico en 52° (71°) y a
55° pide 64°, más que a 57°. El único choque es la esquina de arriba y adelante del muslo
contra la raíz de las tiras, que entre 52° y 66° se aleja de ellas al subir. Si algún día se
quiere un faldón más quieto, el pisotón tendría que subir (63–66° piden 16–34°), no bajar.

## 2026-10-17 — La hombrera del minotauro v2 va partida entre el pecho y el brazo

**Contexto:** en el v2 E1 el pecho es angosto (x ±5) y el brazo cuelga lejos (x 9..12); la
hombrera (x 4..12) era lo único que los unía y era del brazo. Cualquier pivote del hombro
falla con una pieza tan ancha: en x = 10.5 la hombrera se separa del pecho al abrir el brazo
y se mete en el torso; en x = 5 (borde del pecho) no se separa, pero el brazo entra en la
cabeza en el músculo, el rugido y el baile. **Decisión:** la mitad de adentro de la hombrera
pasa a `Pecho` (yugo fijo) y el brazo se queda con la tapa, girando por su borde de adentro
(x = 8). Además, las dos mitades bajan una celda para dejar libre la cabeza. Se compararon las
opciones con `tools/blender/minotauro_v2_e1_poses.py` en los picos de los trucos del juego.

## 2026-10-17 — El minotauro se anima por código, con resortes, no con keyframes

**Contexto:** el plan del v2 proponía clips con keyframes para las acciones principales, contra
la regla de `CLAUDE.md` (2026-10-11). Los clips son assets que hay que subir a mano con la cuenta
dueña del juego y pelean con la pose por código por `Bone.Transform`. **Decisión (del usuario):**
seguir por código. Los trucos se rehacen con los principios de la guía (anticipación, aplastarse
y estirarse con la pose, arcos, rebote) en `Minotauro/Trucos/`; la acción secundaria sale de
resortes (`Minotauro/Resortes`: orejas, cola, mandíbula y faldón persiguen su pose con retraso y
los empuja la inercia del cuerpo) y los pies se apoyan solos (`Minotauro/Cuerpo.plant`). Todo
vive en git y sirve igual para el modelo actual y el v2 (los huesos del faldón son opcionales).
Peso por etapa: `pace` (más lento) y `bounce` (menos rebote) en `Minotauro/Etapas`.

## 2026-10-17 — Los modelos v2 entran por un sufijo, con el nombre de siempre

**Contexto:** el Minotauro v2 solo tiene E1 y tiene que convivir con el actual (plan del v2:
interruptor, no reemplazo). **Decisión:** campo opcional `modelSuffix` en el gigante
(`Config/Giants.luau`). Si `ServerStorage` tiene `<modelBase>E<n><sufijo>`, `GiantTemplates`
lo publica con el nombre de siempre (`MinotauroE1`), así el cliente, `Etapas.forModel` y la
animación no cambian; si no, usa el actual. Volver atrás es borrar una línea. Mientras solo
exista E1, al crecer pasa del becerro de bloques al joven actual.

## 2026-10-17 — El desierto del minotauro es del cliente, como la lava

**Contexto:** el usuario pidió que el hábitat del minotauro sea un desierto en vez de agua. El cráter
ya cambiaba de relleno por gigante en el cliente (agua o lava, `CraterDrain`). **Decisión:** un
tercer modo, "sand" (`GiantDef.sand`): el cliente escribe el terreno de arena (una cáscara de ~10
filas de vóxeles, por cuartos, un cuarto por cuadro), mientras sube o baja es un solo disco, y los
props del hábitat los sube el cliente sobre la arena (el servidor los sigue apoyando en la repisa).
`CraterMode` dice qué hay en el cráter a quien cambia según el relleno (luz, polvo, rescate).

## 2026-10-17 — La rutina del minotauro y la evolución se sincronizan con la hora del servidor

**Contexto:** el minotauro se anima en cada cliente. **Decisión:** la rutina (adónde camina, qué
postura toca, a qué jugador mira) sale de `GetServerTimeNow()` con un hash sin estado
(`Minotauro/Azar`), y la evolución usa `EvolucionHasta`: el estallido es a los 1.3 s del inicio,
tanto para los efectos (`EvolveFx`) como para la pose (`Minotauro/Evolucion`), y el cambio de
modelo pasa ahí, tapado por el destello, en vez de apenas llega la etapa.

## 2026-10-17 — El hielo del zorro es un modo del cráter que conserva el agua

**Contexto:** el usuario eligió "agua con hielo" para el zorro de agua. **Decisión:** un modo
nuevo `"ice"` en `CraterMode` (bandera `ice` en el `GiantDef`) en vez de agua más un adorno
suelto: así la mezcla de luz (`iceBlend`) sale como en la lava y la arena. Para el resto del
juego sigue siendo agua (`CraterMode.isWet()`): salpicaduras, peces y pisadas no cambian, y
`CraterGuard` no necesita nada porque el agua se queda. Las piezas de hielo son locales.
Con el hielo, el cráter tiene un **atardecer** (`SkyMoods.iceHour = 17.9`, sol tibio y sombras
azules), pedido del usuario; las cascadas de lava de la isla se siguen viendo, también a pedido.

## 2026-10-17 — Las colas del zorro tienen 5 tramos y un solo dueño

**Contexto:** el usuario pidió animaciones perfectas para la cola. **Decisión:** el v2 lleva 5
tramos por cola (el actual, 4), aunque la forma final quede en 76 huesos (6 más que el tope de
la guía). Solo `Zorro/Colas` escribe los huesos `Cola*_*`: los trucos, comer y las conductas
piden un estado y unas intensidades (`Colas/Tipos`, `Intent`), y los valores viejos
(`tailCalm`, `tailFan`, `tailLift`, `tailWag`) se traducen en `Colas/Traduccion`. Así ninguna
capa pisa a otra en la cola.

## 2026-10-18 — La zona de entrenamiento es un jardín de estanques naturales

**Contexto:** el usuario pidió que los estanques dejaran de parecer fuentes (círculos de
mármol con oro sobre una plaza empedrada) y fueran naturales, cada uno con algo que lo
distinga. **Decisión:**

- **La orilla ondula con una fórmula compartida** (`WorldZones.pondEdge`, tres senos con
  fase por estanque, amplitudes en `pondWobble` de `WorldLayoutData.json`) que copia
  `tools/estanques/forma.py`. El terreno (`server/World/GardenShape`) y las piezas (rocas,
  juncos) usan la misma curva, así nada queda flotando ni dentro del pasto.
- **Senderos de arena, no de `Ground`:** el color de un material de terreno es global y la
  guarida de lava (`LairGround`) le cambia el de `Ground` a ceniza. La arena y el barro
  (`Mud`, orillas) no los toca nadie más.
- **Las piezas viven en el paquete `tools/estanques/`** y no en `generar_isla.py` (que ya
  pasaba de 1300 líneas). Importa `generar_isla` para reusar sus utilidades; cada estanque
  tiene su semilla, así cambiar uno no mueve los demás ni el resto de la isla.
- **Todo sigue siendo primitivas** (fase 1): esferas estiradas con `SpecialMesh` para
  pétalos, hojas y rocas redondas. El borde de Blender `BordeEstanque`/`BordeSagrado` queda
  sin uso en `PropsMapa` (las rocas de orilla sí usan `Roca1..3`).
- **El cartel del estanque en el que uno entrena se esconde:** medido en studs, de cerca
  tapaba el nombre y el título del jugador.
- Los multiplicadores y requisitos **no cambiaron** (`Config/Progression`); solo cómo se ven.

## 2026-10-18 — El puente al volcán cambia de piel, no de forma

**Contexto:** el usuario pidió rehacer la rampa al volcán («muy simple»). **Decisión:** solo
cambia lo que la rodea (portal, calzada, baranda, arcos, en `tools/puente.py`); la superficie
y sus extremos siguen siendo los de `WorldZones.bridgeEnds`, porque de ellos dependen la
corriente rápida (`isOnBridge`), las paredes invisibles y hacia dónde miran los monstruos y
la guarida del zorro. No se volvieron a poner flechas en el piso (se habían quitado el
2026-10-15). El fuego de los braseros es la instancia `Fire` de Roblox: no necesita asset.

## 2026-10-18 — El arco del volcán es de Blender aunque sigamos en fase 1

**Contexto:** el usuario pidió una puerta del cráter más grande con una referencia de un arco
volcánico de bloques y dijo «usa blender para el marco». **Decisión:** excepción a la fase 1,
como el faro y los props del mapa: el arco sale de `tools/blender/arco_volcan.py` y entra por
`PropDresser`, con un respaldo de primitivas si falta. En Roblox una malla tiene un solo
material, así que la lava es una **segunda malla** con la misma caja que la piedra (cubitos
mínimos en las esquinas de la caja común) y las dos se ponen con ajuste `"caja"` sin
desfasarse; el atributo `Brillo` del ancla la pone en Neon. Fuego y humo son instancias
`Fire`/`Smoke` (sin assets). La decoración de la orilla de los estanques se quitó entera:
estorbaba al caminar y el usuario la vio mal resuelta.

## 2026-10-18 — Los estanques se abren solo con monstruos llenados

**Contexto:** cada estanque se abría con kills **o** con poder (lo que llegara primero).
**Decisión (pedido del usuario):** solo con kills (`requiredKills`) o comprándolo con Robux;
se borró `requiredPower` de `Config/Progression` y del tipo `PondDef`. Las kills no se pierden
al renacer, así que un estanque abierto queda abierto. De paso, `Perks.affectsPonds` ya no
reacciona al poder (que sube cada tick), y el cartel muestra el avance («4/15 monstruos»).

## 2026-10-18 — Los eventos se anuncian con el cielo

**Contexto:** el usuario no notaba cuándo había evento ni cuál era. **Decisión:** el cielo
entero cambia con cada evento (`EventSky`, la última capa que mezcla `SkyCycle`), con efectos
propios en el mundo (`EventFx`/`EventShapes`) y un anuncio grande (`EventIntro`). Para teñir
el cielo hace falta `Atmosphere.Haze` (con solo `Color` apenas cambia): como `SkyCycle` no lo
toca, `EventSky` guarda el valor de antes y lo devuelve al terminar. Los relámpagos usan su
propio `ColorCorrectionEffect` para no pelear con el de `SkyCycle`. La aurora son rayos
verticales (`Beam` con transparencia que se apaga arriba y abajo): las piezas planas y las
cintas horizontales se veían como bloques.

