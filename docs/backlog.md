# Backlog

Tareas en orden de ejecución. Una tarea se marca cuando cumple el checklist de
`CLAUDE.md` (build, selene, stylua y prueba en Studio). Diseño y números: `alcance.md`.
Versiones públicas: `roadmap.md`.

---

## H1 — Vertical slice: pescar, alimentar a la Orca, ganar monedas

**Criterio de terminado:** un jugador pesca, lleva el pez a la Orca, gana monedas y la
barra de hambre sube. La Orca crece mientras come.

- [x] Playa mínima: arena, agua, muelle con 4 puntos de pesca (turquesa), plataforma con
      cubeta (coral), isla de la guarida, palmeras, rocas y luz de tarde.
      `world/Playa.model.json`, generado por `tools/generar_playa.py`. Reemplazada por la
      isla de H1.5.
- [x] Números de peces, pesca y gigantes en `Config.luau`; nombres compartidos en
      `Protocol.luau`.
- [x] Pesca autoritativa (`FishingService`): espera aleatoria, ventana de 2.5 s + 0.75 s
      de margen por ping, tabla de peces con pesos.
- [x] Carga de hasta 5 peces y monedas en memoria (`PlayerData`, leaderstats).
- [x] Alimentar (`FeedingService`): entrega toda la carga, monedas x multiplicador.
- [x] Gigante (`GiantService`, `GiantModel`): la Orca sale de `ServerStorage.OrcaE1`,
      validada contra `Assets.Meshes.OrcaE1`, y crece de 15 a 38 studs según la barra.
      Si el modelo falta, usa un marcador de primitivas.
- [x] Interfaz: barra de hambre con 4 estados, monedas y carga, botón TIRA grande,
      avisos (`src/client/`).
- [x] Prueba en Studio (1 jugador): pescar 3 peces, alimentar → +12 monedas, barra al 14 %,
      la Orca crece sobre la isla y mira al muelle. Ver devlog 2026-10-12.
- [x] Paredes invisibles en todo el borde del muelle: sin ellas un avatar bajo pasaba por
      debajo de los pasamanos y caía al mar.
- [ ] Prueba con 2 jugadores (Test → Local Server, 2 clientes): la barra se comparte.
- [ ] Prueba con ping simulado (Studio → Network → Incoming Replication Lag 0.3 s):
      la ventana de TIRA sigue siendo cómoda.
- [x] Reiniciar `rojo serve` con el proyecto nuevo.
- [ ] Guardar el lugar en Studio (sin `Baseplate` ni el `SpawnLocation` viejo).
- [ ] Probar con el emulador de móvil de Studio: tamaño del botón TIRA y del HUD.

## H1.5 — Isla, efectos y sonido (pedido del 2026-10-12)

- [x] Isla grande generada por código: terreno por vóxeles (`TerrainBuilder`,
      `IslandShape`) y piezas (`tools/generar_isla.py`), con la misma geometría
      (`WorldLayoutData.json`).
- [x] Laguna central con la Orca y 8 cubetas alrededor: se alimenta desde cualquier lado.
- [x] Pesca desde cualquier punto de la orilla y de los muelles (`ShoreCast`).
- [x] Caña de primitivas, brazo animado por código (lanzar, esperar, temblar, tirar),
      corcho con estela, ondas, pez que salta.
- [x] Orca animada en el cliente: crece, respira, mira alrededor, gira hacia quien la
      alimenta, rebota, salta en cada estado, chorro por el espiráculo.
- [x] Ambiente: ciclo de día y noche, faro, espuma, boyas, gaviotas, peces que saltan,
      destellos, fogata.
- [x] Sonidos de la Tienda de creadores registrados en `Assets.luau` (cargan en Studio).
- [ ] Revisar volúmenes con audífonos y cambiar los que no convenzan.
- [ ] Rendimiento en móvil: la isla tiene ~2,000 piezas y el terreno ~2 M de vóxeles.

## H1.6 — Zona de entrenamiento y Cráter del Abismo (pedido del 2026-10-13)

- [x] Zona de entrenamiento en el centro de la isla: 10 estanques de terreno con borde
      de piedra, cristales del color de su nivel, carteles flotantes (x1 a x100 y
      requisito) y estatua de un pez dorado.
- [x] `TrainingService`: E para entrenar AFK, 1 de poder por segundo x multiplicador,
      requisito de poder por estanque, se corta al alejarse. "+N poder" flotando.
- [x] Poder de pesca en leaderstats y HUD; bonus por pez al alimentar.
- [x] Gigante por etapas de 3, 8, 15 y 25 veces el alto de un jugador, con rugido,
      temblor de cámara y olas al crecer; contorno rojo.
- [x] Cráter del Abismo: isla volcánica con lago profundo, anillo con grietas de lava,
      30 agujas de basalto, esqueletos de peces, cristales morados, 8 muelles con
      calderos y antorchas de fuego azul, puerta con calaveras de ojos rojos y puente
      desde la isla.
- [x] Ambiente del cráter: niebla rojiza, colores apagados, bruma sobre el lago, brillo
      rojo desde el abismo, relámpagos, murciélagos, ambiente de terror, gruñidos.
- [x] Quien cae al lago del cráter vuelve a la puerta (no hay forma de salir nadando).
- [ ] Definir los multiplicadores y requisitos finales de los 10 estanques.
- [x] Rework de la zona (pedido del 2026-10-18): jardín de pasto con senderos de arena y
      estanques naturales de orilla irregular, cada uno con su tema (prado, juncos, lirios,
      bambú, hongos, cerezo, arce, cascada, dorado, celestial y el sagrado), espíritu de
      luz sobre un loto y carteles con nombre, multiplicador y requisitos con íconos.
- [x] Orillas sin decoración (no se choca ni se atora nadie) y zona más grande (radio 122).
- [x] Puerta del cráter: arco volcánico de Blender (`arco_volcan.py`) con lava en Neon.
- [x] Importar `assets/blender/ArcoVolcan.fbx` a `ServerStorage.PropsMapa` y registrar IDs.

## H1.7 — Ritmo para servidores de 40-50 (pedido del 2026-10-13)

- [x] Puente al volcán fácil de caminar: una sola rampa lisa con bordillos y paredes
      invisibles; corriente que sube la velocidad a 44 y abre la cámara; flechas que
      se encienden en onda.
- [x] Calderos junto a la puerta del cráter para entregar sin bajar a los muelles.
- [x] Zona de entrenamiento más grande, estanques de 12.5 studs llenos hasta el borde;
      cada jugador lanza el corcho frente a sí (caben todos en el mismo).
- [x] Luz menos fuerte: brillo de día 2.2, bloom suave, sin resplandor, piedra más oscura.
- [x] El poder hace pescar más rápido y más peces por pique; capacidad 20 x peces por pique.
- [x] Hambre escalada hasta 50 jugadores.
- [x] Enojo del gigante: medidor en el panel de hambre, la barra baja (sin encoger),
      Salpicón con aviso de 3 s y empujón cuando está furioso; un bocado lo calma.
- [ ] Probar con 2+ jugadores: varios en el mismo estanque y el Salpicón a otro jugador.
- [x] Comida fija por gigante (2,500 / 15,000 / 75,000 / 300,000): no escala con los
      jugadores ni con el poder; la Orca es la más fácil.
- [x] Alimentar desde cualquier punto de la orilla del volcán: botón Alimentar (F),
      línea coral en el borde, peces que vuelan hasta la boca.
- [x] Probar en Studio alimentar desde el borde del cráter lejos de la puerta.

## H1.8 — Peces, animaciones, efectos y sonidos (pedido del 2026-10-13)

- [x] 12 peces en 6 rarezas (común a mítico) con modelo propio por especie.
- [x] Captura por rareza: cartel, trofeo con aura de luz, onda y temblor; sonido por rareza.
- [x] Canasta en la espalda que se llena (todos la ven) y brilla llena.
- [x] Tarjeta de captura con el pez en 3D; monedas que vuelan al contador.
- [x] Peces lanzados al gigante con giro, whoosh y destellos.
- [x] Animaciones de cuerpo entero por código (2026-10-22): lanzado, picada, clavar el anzuelo
      con hitstop, festejo y trofeo; entrenar bombeando la caña; alimentar lanzando como un
      cuidador de orcas; peces que se estiran y aplastan (`client/Body/`, `Effects/Squash`).
- [x] Voces de cría y de adulto por gigante, y momentos del ciclo con su voz (2026-10-22):
      llegada, despedida, hambre, furia, calma, evolución y trucos mudos (`Audio/GiantMoments`).
- [ ] Colección de peces (qué especies ya pescó cada jugador), con H4 (guardado).
- [ ] Probar los sonidos nuevos en un servidor publicado (permisos de audio).
- [ ] Alimentar desde un muelle del cráter con 2 jugadores y revisar el ritmo.
- [ ] Rendimiento: ~3,300 piezas y ~2.8 M de vóxeles de terreno; probar en móvil.

# Camino a publicar la v1.0 (revisión del 2026-10-13)

Siete etapas en orden. Cada una termina con una prueba en Studio y la revisión del
diseñador antes de pasar a la siguiente. Las etapas 1 a 4 y 6 a 7 son obligatorias para
publicar; la 5 es muy recomendada (retención del primer día).

## Etapa 1 — Guardado de datos

**Terminado cuando:** salir y volver a entrar conserva monedas, poder y peces en la
canasta; dos servidores nunca pisan los mismos datos.

- [x] `Save/SaveStore`: DataStore con reintentos (espera creciente) y bloqueo de sesión.
- [x] Guardar monedas, poder, peces en la canasta, especies atrapadas y estadísticas.
- [x] Autoguardado cada 60 s, guardado al salir y al cerrar el servidor (`BindToClose`).
- [x] Datos con versión (`Save/SaveSchema`) y lectura que descarta lo inválido.
- [x] En Studio sin acceso a la API: aviso y modo en memoria, sin romper el juego.
- [x] Nadie pesca ni entrena hasta que sus datos cargan.
- [ ] Publicar el lugar y activar "Acceso de Studio a servicios de API".
- [ ] Prueba con DataStore real: entrar, pescar, entrenar, salir, volver a entrar;
      cambiar de servidor rápido (bloqueo). Lista completa: `docs/pruebas_guardado.md`.
- [x] Protecciones: salir durante la carga, cierre con muchos jugadores, datos corruptos o
      de una versión más nueva (no se pisan) y recibos que solo se confirman guardados.

## Etapa 2 — Ciclo de gigantes

**Terminado cuando:** la Orca se llena, se despide, hay un descanso de 2 min con
entrenamiento x2 en la guarida del volcán y la ruleta trae al siguiente (por ahora la Orca).

- [x] `GiantCycle`: fases despedida → descanso → ruleta → llegada → comer.
- [x] Despedida: rugido, salto con giro, zambullida y ola (`GiantCycleFx`).
- [x] Descanso: dentro del volcán, +poder cada segundo = x2 del mejor estanque desbloqueado.
- [x] Panel de hambre con la cuenta regresiva y el poder por segundo; lago que brilla;
      carteles y avisos al entrar o salir del volcán (`CycleView`).
- [x] Llegada: sale del lago con su tamaño de etapa 1, ola y rugido.
- [x] El botón Alimentar se esconde fuera de la fase de comer; los peces se conservan.
- [x] La recompensa solo abajo: guarida del descanso que emerge en el centro del lago,
      rampas desde los muelles, aviso a los 10 s y subida a un muelle al terminar.
- [x] Guarida del descanso como santuario flotante de Blender, a -20 (antes -60).
- [ ] Lago de la orca plano a -250 (el terreno del lago cambia según el gigante).
- [ ] Hábitat completo de la orca en Blender, sobre ese fondo (reemplaza los props sueltos).
- [x] Kills: +1 a quien le dio de comer al monstruo; estadísticas Poder y Kills (las
      monedas pasan al HUD); kills guardadas (`SaveSchema` v2).
- [ ] Ruleta con animación (Orca, Minotauro, Dragón, Zorro) cuando existan sus modelos
      (`inRoulette` en `Config/Giants.luau`).
- [ ] Modelo del Minotauro (pipeline de Blender) y marcarlo `inRoulette`.
- [ ] Probar el ciclo completo con los tiempos reales (2,500 de comida, 2 min) y 2+ jugadores.

## Etapa 3 — Tienda y economía

**Terminado cuando:** las monedas sirven para algo que el jugador quiere.

- [x] Qué se compra (`Config/Shop.luau`): 10 cañas (x poder al entrenar y suerte), 6
      canastas (x capacidad) y 6 botas (velocidad al caminar 16 → 30). En orden; el
      nivel 1 es gratis.
- [x] `ShopService`: compra validada en el servidor (siguiente nivel, precio, monedas),
      guardada (`SaveSchema` v3); E en el mostrador de la cabaña abre la tienda.
- [x] Ventana de la tienda con pestañas y botón "Tienda" en el HUD (`client/Shop`).
- [x] Efectos: la caña multiplica el poder de estanques y del descanso y sube los peces
      raros; la canasta, la capacidad; las botas, la velocidad.
- [x] La caña equipada se ve distinta (color y brillo por nivel, `UIConfig.RodLooks`).
- [x] La canasta de la espalda cambia de aspecto según el nivel comprado (6 estilos).
- [ ] Revisar precios con datos reales de monedas por minuto (telemetría, etapa 7).

## Pedido del 2026-10-13 — Controles, entrega y rediseños

- [x] E para lanzar, tirar y alimentar en PC; botones con la tecla para móvil.
- [x] Alimentar de 1 en 1.
- [x] Estanques y cañas rediseñados; caña en 3D en la tienda.
- [x] Terreno a la altura del diseño.
- [x] Revisar el mapa con el terreno corregido (plaza, muelle, cráter, puente vistos en Studio).

## Etapa 4 — Ataques, equidad y seguridad

**Terminado cuando:** los ataques de la v1 avisan bien y ningún remote se puede abusar.

- [x] Cartel y cuenta regresiva grande para el jugador que está dentro del círculo.
- [ ] Embestida (Minotauro): franja con flecha, derribo de 1.5 s (cuando exista su modelo).
- [x] Un ataque que alcanza a alguien que pesca hace escapar al pez, nunca la carga.
- [x] Límite de frecuencia en todos los remotes (`RateLimit`); el servidor ya valida todo.
- [x] Inactividad de 20 min: no se esquiva; aviso desde los 14 min para que se mueva.
- [x] Sin la advertencia de `EstadoGigante` al arrancar (el terreno se arma al final).
- [x] No se puede pescar desde el puente.

## Etapa 5 — Primer minuto y retención

- [x] Tutorial de 4 misiones (pescar 3, alimentar, entrenar, comprar desde MEJORAS) con
      anuncio grande, línea de objetivo, chevrones en el suelo y aro en el destino; monedas por
      misión y bono al final (`Tutorial`, `TutorialGuide`). Rehecho el 2026-10-21.
- [x] Menú de ajustes: música, sonidos, temblor de cámara, efectos reducidos; se guardan
      con la partida (`ClientSettings`, `SettingsWindow`, `FxQuality`).
- [x] Música de fondo por zona: isla, cráter y descanso, con fundido (`Music`).
- [x] Colección de peces: 12 tarjetas, silueta si falta, monedas por descubrir y 100K al
      completarla (`FishDex`, `Milestones`).
- [x] Índice por secciones de rareza con medallones de Canva, suerte por cada sección completa
      y pesca (barra, tarjeta y cartel de captura) en piedra volcánica (`FishDex*`,
      `CollectionLuck`, `ReelBar`, `CatchCard`, `CatchLabels`).
- [x] Insignias (primer pez, primer raro/legendario/mítico, primera kill, 10 kills,
      colección, tutorial, estanque máximo): aviso en partida ya; **falta crearlas en el
      Creator Hub y poner los IDs en `Assets.Badges`**.
- [x] Ranking global de Poder y Kills en los tableros de la entrada (`Leaderboards`,
      `RankingBoards`); sin publicar muestra a los jugadores del servidor.
- [x] Premio diario de 7 días con racha (`DailyReward`, `DailyWindow`).
- [x] Ícono de calendario v4 para el premio diario (botón de arriba y título de la ventana).
- [x] Caña suprema: premio de la ruleta (0.01 %, rueda de 9 casillas) que da x3 el poder y la
      suerte de la mejor caña; solo sale una vez (guardado v15).
- [ ] Caña suprema: cambiar los íconos de 200 px por la versión de 1024 de Canva y que la
      caña se vea distinta en la mano.
- [ ] Con el lugar publicado: comprobar insignias reales y el ranking global.
- [x] Títulos y kills sobre la cabeza, impulso de amigos, códigos, regalo del grupo.
- [ ] Crear el grupo de Roblox del juego y poner su número en `Config.Social.group.groupId`.

## Etapa 6 — Pruebas y rendimiento

**Terminado cuando:** el juego se siente bien en móvil y con el servidor lleno.

- [ ] 2+ jugadores (Test → Local Server): barra compartida, varios en un estanque,
      Salpicón a otro jugador, entregas a la vez, desconectarse pescando o entrenando.
- [ ] Ping simulado (0.3 s): la ventana de TIRA y el aviso de los ataques son justos.
- [x] Emulador de móvil: botones, HUD, tarjeta de captura sin tapar Pescar (2026-10-20:
      columnas sobre el joystick y Saltar, ver `docs/decisiones.md`).
- [x] Medición en el emulador de gama baja (`docs/rendimiento.md`: 4,748 piezas, 2.3 M de
      celdas de terreno, 83 luces; propuestas sin implementar, las elige el usuario).
- [ ] Teléfono real de gama baja: FPS y memoria (pasos en `docs/lanzamiento.md`).
- [ ] Servidor lleno (8+ clientes locales, luego prueba pública cerrada).
- [ ] Mando de consola.
- [ ] Avatares R6 y R15 (brazo con la caña, canasta).

## Etapa 7 — Publicación

- [x] Telemetría (AnalyticsService, `server/Analytics/`): embudo de inicio, fin de sesión,
      monstruo lleno o ido, renacer, economía de monedas, mejoras, estanques, Robux, diario y
      ruleta. Falta verla con datos del juego publicado.
- [x] Monetización: Poder y Monedas que se acumulan (x2, x4, x8... desde R$ 3, cada
      nivel más caro), pase VIP, entrenamiento para todo el servidor (15 min; otra compra
      reinicia el tiempo y lo duplica), llenar al monstruo 25/50/75 %, elegir el siguiente
      monstruo y estanques 2–10. `ProcessReceipt` anota cada PurchaseId en el guardado y
      solo confirma si se guardó (`Monetization/`, `Perks`, `RobuxShop`).
- [ ] Crear el pase VIP y los 63 productos en el Creator Hub con los precios de
      `Assets/Products.luau` y poner los IDs ahí y en `Assets.GamePasses` (los 21 nuevos:
      GiftVIP, Rod2–10, Basket2–6, Boots2–6).
- [x] Rediseño estilo simulador: TIENDA (Robux) con banner y tarjetas con rayos, MEJORAS
      de madera con precio en monedas y en Robux, regalos a otro jugador y premio diario.
- [ ] Probar un regalo real con 2 jugadores cuando existan los IDs (Studio: Prueba →
      Clientes y servidores, 2 jugadores).
- [ ] Con el lugar publicado: comprar de prueba cada uno (Studio cobra en modo prueba).
- [ ] Revisar el balance de x1024 de poder/monedas con telemetría (¿tope más bajo?).
- [x] Marinero v2: el traje de todos rehecho en Blender por script, una sola malla sin
      piezas sueltas y con texturas nítidas (`tools/blender/marinero_v2*.py`).
- [x] Rey del Mar y Dios del Volcán v2 desde cero (generador `traje_v2`, brillo real, capa,
      pisadas) y vitrinas nuevas con pedestal, aura y cartel (`Social/Showcase*`).
- [ ] Página del juego: icono 512×512, 3+ miniaturas o video, nombre, descripción, género.
- [ ] Cuestionario de madurez y cumplimiento (el cráter tiene calaveras y terror suave).
- [ ] Ajustes del lugar: 50 jugadores, dispositivos, tipo de avatar, acceso a la API.
- [ ] Publicar desde Studio con Rojo sincronizado; comprobar los sonidos en el juego
      publicado.
- [ ] Prueba cerrada con amigos; luego pública. Link y capturas en el README.

---

## Evento 1 — Dragón marino (v1.1)

- [ ] Fijar su multiplicador con la telemetría de H4 (provisional x8).
- [ ] Modelo del Dragón marino (pipeline de Blender) y entrada en `Assets.luau`.
- [ ] Marejada y zonas seguras en el mapa.
- [ ] Anuncio previo del evento.

## Evento 2 — Zorro de agua (v1.2)

- [ ] Fijar su multiplicador (provisional x20).
- [x] Modelo del Zorro de agua (v2 de bloques, 4 etapas, en el juego).
- [x] Colas con animación propia (`Zorro/Colas`).
- [x] Hábitat de agua con hielo (modo `ice`) y contrato `Zorro/Guarida`.
- [x] Sonidos y VFX del zorro (voces por etapa, cubitos de agua, espuma, hielo).
- [x] Rutina, conductas y mirar al público con el modelo v2 (ola 3).
- [x] Lanzado: en la ruleta (5 %) y en "elegir" desde el 2026-10-19 (`released = true`).
- [x] Témpanos menos regulares y párpados de la cría y el joven (ola 4).
- [ ] Fuegos fatuos (oleadas de esferas).
- [ ] Ambiente nocturno y anuncio previo.

## Arreglos del 2026-10-20 (pedido del usuario)

- [x] El guardado al salir no llegaba cuando el servidor se cerraba (`BindToClose`).
- [x] Pesca y alimentación más lentas para los gratis, para que los pases se noten (piso del pique
      1.6 s, caña hasta x1.5, canasta en 12 s).
- [x] Aura de partículas en vez del cilindro de neón al pescar raros o mejores y en el destino del
      tutorial; sin pilar ni cartel en el destino.
- [x] RT (R2) en los botones y avisos de pescar y alimentar con mando.
- [x] Aura sin círculos en el suelo; sin aros a los pies del Dios del Volcán.
- [x] Rayos de las vitrinas siempre detrás del traje, desde cualquier ángulo.
- [x] Íconos de las caras del Rey del Mar y del Dios del Volcán (estilo v4).
- [x] IDs de los 70 productos y los 3 pases en el juego (revisados contra el Creator Hub).
- [x] VIP: +50% monedas, +50% entrenamiento y placa dorada con cinta VIP.
- [x] Precios iguales al Creator Hub (Dios del Volcán y su regalo a 858 R$).
- [x] VIP más llamativo: destello, cinta con corona, nombre dorado y [VIP] [TÍTULO] en el chat.
- [x] Sin "Espera a que pique" ni el "+1 Kill" falso al entrar.
- [x] Estanques: tabla nueva (x2 a x100, sagrado x250), sin el Dorado ni el Celestial; carteles
      con solo el requisito; vitrinas junto a los estanques para principiantes.
- [x] El traje elegido se guarda (se quitaba y al volver lo tenía puesto).
- [x] Los pases que el admin quita o pone se guardan (el creador siempre los tiene en Roblox).
- [x] Estanques repartidos en un anillo parejo; vitrinas más cerca del centro.
- [x] Pantalla de carga con los gigantes de bloques y barra que sigue la carga real del mapa.
- [x] Luz y color del mapa como las fotos del juego (opción 1).
- [x] Modelos de bloques aprobados: decoración, isla y volcán (`tools/blender/`, fotos en
      `docs/capturas/mapa_antes_despues/`).
- [x] Incorporar la decoración de bloques (`PropsMapaBloques.fbx` en `ServerStorage.PropsMapa`;
      los de antes en `PropsMapaRespaldo`).
- [x] Incorporar la isla de bloques (`ServerStorage.IslaBloques`, `World/BlockIsland`).
- [ ] Incorporar el volcán (craterCenter 520 → 722, montaña y cueva, luz de la cueva, corriente
      en el túnel, lago/desierto/guarida/hielo, colisiones, streaming).
- [ ] Estanque sagrado: ponerlo a la venta a 1200 R$ en el Creator Hub (está fuera de oferta).
      Subir el pase Dios del Volcán a 858 R$ (Roblox dice 496).

## Orca v2 de bloques (2026-10-20)

- [x] Geometría de las 4 etapas (cría, joven, adulta y anciana), aprobada (`docs/plan_orca_v2.md`).
- [x] Pupilas por código que siguen al jugador (`Giant/GiantEyes`): Minotauro, Dragón y Zorro
      encima de su ojo; la orca con cuenca en el modelo.
- [x] Rig, poses y FBX de las 4 etapas (huesos `Ojo{l}Mira` en la cuenca).
- [x] Importar en Studio, IDs en `Assets` y `modelSuffix = "_v2"`.
- [x] Nado natural: recorrido aleatorio, onda de cetáceo, saltos que se hunden y comer asomada
      con la boca abierta; probado en Play con las pupilas.
- [ ] Ver los trucos en Play y ajustar sus números (`Etapas/*`, `Comer/Estilo`).
- [ ] Pupila del Minotauro E1 (ojo todo negro) y del Dragón E2 (ojo de 1×1): a decidir.

## Tutorial de los primeros 30 segundos (2026-10-21, pedido del usuario)

- [x] El novato aparece en la playa y pesca 3 peces. En los pasos de ir lejos camina más rápido.
- [x] Anuncio grande por paso, línea de objetivo chica, chevrones verdes en el suelo y aro de neón.
- [x] Ruta al volcán por puente, arco y puerta (dentro del túnel ya no apunta para atrás).
- [x] Comprar desde el ícono MEJORAS con el velo con hueco y la mano.
- [x] El diario y los carteles de pez nuevo y logro esperan a que termine el tutorial.
- [x] Durante el tutorial solo se ve el tutorial; en el paso de comprar, solo MEJORAS.
- [x] Cielo fijo a mediodía y la guía del tutorial arriba en grande.
- [ ] Probar el tutorial en el simulador de teléfono.

## Actualizaciones semanales (plan del 2026-10-26)

Una por sábado a las 9:00 (UTC-6). Fases y calendario en `roadmap.md`.

### Sábado 31 oct — Cierre de Halloween (se publica el viernes 30)

- [ ] Orca fantasma en la ruleta hasta el 3 de noviembre.
- [ ] Pez de Halloween limitado (diseño a confirmar con el usuario).
- [ ] Primera meta de likes con el código `HALLOWEEN` (meta a confirmar).
- [ ] Admin abuse de 9:00 a 10:00 con el panel actual (solo en el servidor donde se esté).
- [ ] Miniatura, título y anuncio de jueves a domingo.

### Sábado 7 nov — Base de la fase 1 + monstruo limitado nº 1

- [ ] Candado de fecha genérico: el `season` de los gigantes también para peces, trajes y
      eventos, con la hora del servidor.
- [ ] Admin abuse global: las órdenes de `Admin/AdminWorld` a todos los servidores con
      `MessagingService`, y un evento «Admin abuse» x10 en `Config/Events`.
- [ ] Cartel de la meta de likes en la plaza (meta y código en `Config/Social`).
- [ ] Contador «Actualización en…» y «¡Admin abuse!» en `Interface/EventCountdown`.
- [ ] Sección «Limitados» del índice.
- [ ] Monstruo limitado nº 1 (variante a elegir por el usuario).

### Sábados 14, 21 y 28 nov

- [ ] Monstruo limitado nº 2, 3 y 4, con un objeto raro limitado cada semana.
- [ ] Mascotas de pez en paralelo desde el 14 (sale cuando se cruce el umbral de la fase 2).
- [ ] 28 nov: oferta de Black Friday en el pack de inicio.
