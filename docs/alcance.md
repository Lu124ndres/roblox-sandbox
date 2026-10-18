# Alcance

Qué es el juego, qué entra en la primera versión y con qué números. Lo que no está
aquí no se construye: va a `ideas.md`.

## Concepto

Juego cooperativo por servidor. Los jugadores pescan en una playa y alimentan a una
cadena de gigantes marinos. Cada gigante crece mientras come; cuando su barra de hambre
se llena, se despide con una animación espectacular y llega el siguiente, que paga
más. Al completar la cadena, todos los que participaron reciben una recompensa
permanente y el ciclo vuelve a empezar.

## Principios

1. **Móvil primero, con ping alto.** Botones grandes, avisos grandes y ventanas de
   tiempo generosas. El servidor siempre da un margen extra por latencia.
2. **Nunca se pierden objetos.** Ni por un ataque ni por fallar la pesca. Lo peor que
   pasa es que se escape un pez que todavía no era tuyo o que te empujen unos studs.
3. **Cooperación, no competencia.** La barra es compartida y la recompensa del ciclo
   es para todos los que aportaron.
4. **Lenguaje de color.** Turquesa = pescar, coral = alimentar, dorado = monedas. Se
   usa igual en el mapa y en la interfaz.

## Bucle principal

```
pescar  ->  canasta (20+ peces)  ->  alimentar al gigante
   ^                                         |
   |        monedas = pez x multiplicador    |
   +---- la barra sube, el gigante crece <---+
                     |
              barra llena -> despedida -> siguiente gigante
                     |
          cadena completa -> recompensa permanente -> reinicia
```

**Pesca.** Se pesca desde cualquier punto de la orilla o de los muelles: al acercarse al
agua aparece el botón Pescar (o la tecla F). El personaje saca la caña, lanza con un
latigazo y el corcho cae al mar. Tras 2–5 s pica (el corcho se hunde, sale un "!" sobre
la cabeza) y aparece un botón enorme de TIRA durante 2.5 s; el servidor acepta hasta
0.75 s más por ping. Si llega a tiempo, el pez salta del agua hasta sobre la cabeza del
jugador, da coletazos y se mete en la canasta de su espalda (que se ve llenarse y brilla
coral cuando está llena). Si no, se escapa y se vuelve a intentar sin costo. Todos ven la
pesca de todos.

**12 peces en 6 rarezas** (`Config/Fish.luau`). Cada especie tiene su modelo propio
(rayas, púas, espada, farolito, brillo...). Cuanto más raro, más grande el momento:
desde poco común sale un cartel con la rareza sobre la cabeza; desde raro el pez gira en
el aire y el jugador lo muestra en alto dentro de un haz de luz de su color; legendario y
mítico suman onda y temblor de cámara. Cada rareza tiene su sonido. El jugador ve además
una tarjeta abajo con el pez en 3D girando.

| Pez | Rareza | Probabilidad | Comida | Monedas base |
|---|---|---|---|---|
| Sardina | Común | 29 % | 1 | 1 |
| Anchoa | Común | 23 % | 1 | 1 |
| Caballa | Común | 17 % | 2 | 3 |
| Pez payaso | Poco común | 11 % | 3 | 5 |
| Pargo rojo | Poco común | 8.7 % | 4 | 6 |
| Pez globo | Raro | 4.4 % | 6 | 10 |
| Atún | Raro | 3.4 % | 8 | 14 |
| Pez espada | Épico | 1.4 % | 15 | 30 |
| Rape abisal | Épico | 1 % | 18 | 36 |
| Pez luna | Legendario | 0.39 % | 35 | 80 |
| Pez dorado | Legendario | 0.24 % | 45 | 120 |
| Pez arcoíris | Mítico | 0.05 % (1 en ~2,000) | 100 | 400 |
| **Media por pez** | | | **2.75** | **4.57** |

**Alimentar.** El gigante vive en el Cráter del Abismo, una isla volcánica unida a la
principal por un puente de piedra con "corriente": sobre él se camina casi tres veces
más rápido (44 en vez de 16), así ir a entregar y volver toma segundos. Ocho muelles de madera negra entran al lago del
cráter desde todos lados, cada uno con un caldero para alimentarlo. El jugador
entrega todo lo que carga y cobra `monedas base x multiplicador del gigante`. **Se alimenta
desde cualquier punto de la orilla del volcán** (el borde del cráter, marcado con una
línea coral brillante, y los muelles): con peces encima aparece el botón Alimentar (F).
Los calderos de los muelles y de la puerta siguen sirviendo con E. Los peces vuelan en
arco hasta la boca del gigante y muerde cuando llegan. El gigante gira
hacia quien le dio de comer, rebota, salpica y suelta corazones.

**Enojo.** Si nadie le da de comer en 45 s, el gigante se enoja poco a poco (furioso a
los 105 s). Molesto (≥ 50 %), la barra baja sola, pero nunca por debajo del inicio de la
etapa actual: no encoge. Furioso, cada 9 s lanza un **Salpicón** contra un jugador cerca
del cráter: círculo rojo de 18 studs durante 3 s y luego un empujón, sin perder nada. Un
solo bocado lo calma. Valores en `Config/Giants.luau` (`anger`).

**Entrenamiento.** En el centro de la isla hay 10 estanques (12.5 studs de radio, llenos
hasta el borde) donde caben todos los del servidor (40-50): cada uno pesca frente a sí.
Con E el jugador se
pone a pescar sin hacer nada (AFK) y gana 1 de poder de pesca por segundo multiplicado
por el estanque (x1 a x100). Los estanques se abren **solo llenando monstruos** (kills; el
poder no los abre desde el 2026-10-18), o comprándolos con Robux. El poder
hace **pescar más y más rápido** (`Shared/FishingPower.luau`):

| Poder | Velocidad (`1 + raíz/40`) | Peces por pique (`1 + piso(raíz/60)`) | Capacidad (20 x peces) |
|---|---|---|---|
| 0 | x1 | 1 | 20 |
| 2,000 | x2.1 | 1 | 20 |
| 3,600 | x2.5 | 2 | 40 |
| 40,000 | x6 | 4 | 80 |
| 600,000 | x20 | 13 | 260 |

La espera hasta el pique se divide por la velocidad y nunca baja de 0.4 s. Valores
propuestos en `Config/Progression.luau`, para ajustar.

**La isla.** Isla grande con zona de entrenamiento central, plaza de piedra, caminos a cuatro muelles,
cabaña de la tienda, campamento con fogata y hamaca, y un faro en un promontorio. Agua
de terreno con olas, espuma en la orilla, boyas, peces que saltan, gaviotas, destellos
del sol y un ciclo de día y noche de 16 minutos (la noche tiene estrellas, antorchas y
el haz del faro).

**Tienda.** En la cabaña (E en el mostrador) o con el botón Tienda del HUD. Tres mejoras
que se compran en orden (`Config/Shop.luau`):

| Mejora | Niveles | Qué da | Precios |
|---|---|---|---|
| Cañas | 10 (bambú → leviatán) | x1 → x60 poder al entrenar; +5 % → +100 % suerte de peces no comunes | 150 → 5 M |
| Canastas | 6 (mimbre → bodega del abismo) | x1 → x8 capacidad | 300 → 350 K |
| Velocidad (botas) | 6 (sandalias → botas del rayo) | caminar a 16 → 30 | 200 → 150 K |

## Gigantes

Cuatro, en cadena por servidor. Un solo modelo por gigante que **crece por etapas**
según su barra: etapa 1 desde 0 %, etapa 2 desde 25 %, etapa 3 desde 50 % y etapa 4
desde 75 %. Mide **3, 8, 15 y 25 veces el alto de un jugador** (16.5, 44, 82.5 y 137.5
studs). Cada cambio de etapa es un momento: rugido, temblor de cámara, pirueta y olas.

| # | Gigante | Multiplicador | Comida para llenarlo | Dificultad | Ataque | Versión |
|---|---|---|---|---|---|---|
| 1 | Orca | x1 | 2,500 | la más fácil | Salpicón | **v1** |
| 2 | Minotauro | x3 | 15,000 (x6) | pide jugadores con poder | Embestida | **v1** |
| 3 | Dragón marino | x8 (provisional) | 75,000 (x5) | difícil | Marejada | Evento 1 |
| 4 | Zorro de agua | x20 (provisional) | 300,000 (x4) | la más difícil | Fuegos fatuos | Evento 2 |

Los multiplicadores de partida eran x1, x3, x10 y x30. La sección
[Calibración](#calibración) explica por qué la v1 los mantiene y por qué los eventos
arrancan en x8 y x20.

### Barra de hambre

- **Progreso compartido** de 0 a 100 %. Todos los jugadores la ven arriba al centro.
- **Cuatro etapas**: empiezan en 0, 25, 50 y 75 %. Cada una tiene su color y su marca en
  la barra; al pasar de etapa y al llenarse sale un aviso grande.
- **Comida fija por gigante**: no sube ni baja con los jugadores conectados ni con su
  poder. La dificultad la pone cada gigante (tabla de arriba): con más jugadores o más
  poder se llena antes, y eso es lo que se busca.

### Al llenarse: despedida, descanso del volcán y ruleta

0. **Kill.** Todo jugador que le dio de comer a ese monstruo (al menos un pez) suma
   **+1 kill**, aunque haya llegado tarde.
1. **Despedida (7 s).** El gigante deja de comer, ruge, salta girando y se zambulle en el
   lago con una ola enorme. Cartel "¡La Orca se llenó!".
2. **Descanso del volcán (2 min).** Donde estaba el monstruo emerge la **guarida del
   descanso**: una plataforma en el centro del lago con rampas desde la punta de cada
   muelle. Solo quien está **abajo, sobre la guarida**, gana poder sin apretar nada:
   **x2 de su mejor estanque desbloqueado** cada segundo (con el x12: +24 poder/s). Suben
   destellos; el panel de hambre muestra la cuenta regresiva y el poder por segundo. A
   los 10 s del final avisa; al terminar, quien siga abajo sube a la punta de un muelle y
   la guarida se hunde. Nadie pierde los peces que lleva.
3. **Ruleta.** Elige al siguiente monstruo entre los que tienen `inRoulette` (Orca,
   Minotauro, Dragón marino, Zorro de agua). **Por ahora solo la Orca**, hasta que existan
   los demás modelos; la animación de la ruleta llega con ellos.
4. **Llegada (6 s).** Sale del fondo del lago con su tamaño de etapa 1, ruge y levanta
   olas. La barra vuelve a cero y se le puede dar de comer otra vez.

Tiempos en `Config/Giants.luau` (`cycle`).

### Recompensa del ciclo y estadísticas

Llenar a un monstruo da **+1 kill** a quien le dio de comer y el descanso en la guarida
(más poder). Las estadísticas de la tabla de jugadores son **Poder** (de pesca) y
**Kills** (monstruos llenados); las monedas se ven en el HUD. La Escama del ciclo (bono permanente de monedas) queda en `ideas.md`
por si hace falta otra recompensa más adelante.

## Retención

- **Tutorial:** 4 misiones (pescar 5 peces, alimentar, entrenar, comprar) con flecha
  sobre el destino; 25–100 monedas cada una y 200 al terminar.
- **Colección:** 12 especies; descubrir una da monedas según su rareza (25 a 25,000) y
  completarla da 100,000.
- **Premio diario:** racha de 7 días (100, 200, 350, 500, 800, 1,200, 2,500); si se
  salta un día vuelve al 1.
- **Insignias:** primer pez, primer raro, legendario y mítico, primera kill, 10 kills,
  colección completa, tutorial, estanque x100.
- **Ranking:** Poder y Kills, top 10 global en los tableros de la entrada.
- **Ajustes:** música, sonidos, temblor de cámara, efectos reducidos (se guardan).

## Social

- **Sobre la cabeza:** pirámide con las kills, VIP, título por poder (Novato 0, Aprendiz
  100, Pescador 1K, Marinero 5K, Capitán 25K, Almirante 100K, Domador de Bestias 500K,
  Señor del Abismo 5M, Rey de los Océanos 100M, Dios del Mar 10B) y nombre.
- **Impulso de amigos:** +10 % de poder y monedas por amigo en el servidor (máx. +50 %).
- **Códigos:** monedas y/o minutos de x2 poder; cada uno una vez por jugador.
- **Grupo:** unirse + 15 min jugando = 1,500 monedas + 15 min de x2 poder (una vez).

## Monetización

| Compra | Tipo | Efecto | R$ |
|---|---|---|---|
| Poder x2^n | Producto (10 niveles) | Todo el poder, para siempre; cada compra duplica | 3, 7, 15, 29, 59, 99, 199, 349, 599, 999 |
| Monedas x2^n | Producto (10 niveles) | Monedas por entregar y descubrir | igual que Poder |
| VIP | Pase | Etiqueta, +20 % suerte, diario x2 | 299 |
| Entrenamiento para todos | Producto (6 niveles) | 15 min; otra compra reinicia el tiempo y duplica (x2 → x64); al vencer vuelve a x1 | 15, 29, 59, 99, 199, 349 |
| Llenar 25 / 50 / 75 % | Producto | Barra del monstruo actual | 49 / 89 / 129 |
| Elegir el siguiente monstruo | Producto por monstruo | Sale después del descanso (fila si ya hay uno elegido) | Orca 25, Minotauro 49, Dragón 79, Zorro 99 |
| Estanque 2–10 | Producto | Abierto para siempre | 25 a 999 |

Roblox no deja cambiar el precio de un producto según quién compra, así que cada nivel es
un producto distinto. Los monstruos sin modelo salen como "Pronto".

## Ataques

Reglas para todos los gigantes:

- **Aviso grande**: zona marcada en el suelo, banner con el nombre del ataque y cuenta
  regresiva. Nunca menos de 3 s entre el aviso y el impacto.
- **Resuelve el servidor**, al final del aviso, con 2 studs de margen a favor del
  jugador (ping alto: si estabas saliendo, te salvas).
- **Nunca hace perder objetos.** Lo máximo es un empujón o unos segundos sin poder
  moverse. Si había un pez picando, ese pez se escapa; la carga se conserva.
- La dificultad crece en **forma y cantidad** de zonas, no en velocidad del aviso.

| Gigante | Ataque | Aviso | Zona | Si te alcanza | Qué enseña | Frecuencia |
|---|---|---|---|---|---|---|
| Orca | **Salpicón**: golpea el agua con la cola | 3.5 s | Un círculo de radio 14 en la plataforma o un punto de pesca | Empujón de ~12 studs hacia la orilla. Sin daño ni aturdimiento | Leer un aviso y salir de una zona | 45–60 s |
| Minotauro | **Embestida**: carga a lo largo del muelle o de la orilla | 3 s, con flecha de dirección | Franja recta de 10 de ancho | Derribado 1.5 s | Zonas largas: salir de lado, no hacia atrás | 40–50 s |
| Dragón marino | **Marejada**: una ola cruza la playa | 4 s | Toda la playa baja; las zonas seguras (rocas altas y plataformas) brillan | Arrastrado a la orilla y aturdido 2 s | Buscar la zona segura en vez de huir de la peligrosa | 35–45 s, con un Salpicón entre olas |
| Zorro de agua | **Fuegos fatuos**: caen esferas de agua en secuencia | 3 s por cada esfera | 3 oleadas de 5–7 círculos, separadas 1.2 s | Encerrado en una burbuja 2 s (flota, sin perder nada) | Patrones y movimiento continuo | 30–40 s |

## Calibración

Los números salen de un modelo de ritmo de juego. Son la base para la v1; cuando haya
telemetría real (ver backlog H4) se reemplazan en `src/shared/Config.luau`.

### Supuestos

| Dato | Valor | De dónde sale |
|---|---|---|
Jugador sin poder (con canasta de 20 y el puente rápido):

| Dato | Valor | De dónde sale |
|---|---|---|
| Intento de pesca | ~6 s | espera media 3.5 s + reacción, relanzar y su parte del viaje ~2.5 s |
| Capturas exitosas | ~90 % | ventana de 2.5 s + 0.75 s de margen |
| Viaje al volcán | ~25 s por carga | orilla de la isla → puente (16 studs/s) → puente (44 studs/s) → orilla del volcán, ida y vuelta |
| Ritmo efectivo | **8 peces/min** | 20 peces en ~110 s + viaje, ~90 % |
| Comida por jugador | **22 /min** | 8 x 2.75 |
| Monedas base | **36.6 /min** | 8 x 4.57 |

El poder multiplica ese ritmo (más peces por pique y piques más rápidos): con 40,000 de
poder, ~x7; con 600,000, ~x22.

**Cuánto tarda cada gigante** (comida fija / comida por minuto del servidor):

| Servidor | Comida/min | Orca (2,500) | Minotauro (15,000) | Dragón (75,000) | Zorro (300,000) |
|---|---|---|---|---|---|
| 10 jugadores nuevos | 220 | 11 min | 68 min | — | — |
| 40 jugadores nuevos | 880 | 3 min | 17 min | 85 min | — |
| 40 jugadores, poder medio (x7) | 6,160 | 25 s | 2.5 min | 12 min | 49 min |
| 40 jugadores fuertes (x22) | 19,360 | 8 s | 47 s | 4 min | 15 min |

La Orca se llena rápido en un servidor lleno aunque nadie haya entrenado; los
siguientes piden que el servidor entrene. Valores propuestos en `Config/Giants.luau`.

### Multiplicadores

Monedas por jugador en cada etapa = 13.8 x multiplicador x minutos.

| | Orca | Minotauro | Dragón | Zorro | Ciclo completo |
|---|---|---|---|---|---|
| **Partida (x1, x3, x10, x30)** — monedas/min | 14 | 41 | 138 | 414 | |
| monedas por etapa | 69 | 331 | 1,380 | 4,968 | 6,748 |
| % del ciclo | 1 % | 5 % | 20 % | **74 %** | |
| cada etapa vs. la anterior | | x4.8 | x4.2 | x3.6 | |
| **Calibrado (x1, x3, x8, x20)** — monedas/min | 14 | 41 | 110 | 276 | |
| monedas por etapa | 69 | 331 | 1,104 | 3,312 | 4,816 |
| % del ciclo | 1 % | 7 % | 23 % | 69 % | |
| cada etapa vs. la anterior | | x4.8 | x3.3 | x3.0 | |

Lectura:

- **v1 (Orca x1, Minotauro x3): se mantiene.** La Orca es el tutorial: corta y barata.
  El Minotauro paga 4.8 veces más en total, que es el salto que hace que valga la pena
  quedarse. Un ciclo v1 da ~400 monedas en ~13 minutos.
- **Eventos: x8 y x20 en lugar de x10 y x30.** Como cada gigante también dura más, el
  multiplicador se compone con el tiempo. Con x10/x30 el Zorro concentra el 74 % de las
  monedas del ciclo y quien llega solo a esa etapa se lleva casi todo. Con x8/x20 cada
  etapa paga ~3 veces la anterior, un escalón constante.
- **Inflación por evento.** Cada evento sube el ingreso por ciclo: 400 → 1,504 (x3.8) →
  4,816 (x3.2). Con x10/x30 sería 400 → 1,780 → 6,748. Los precios de lo que se agregue
  con cada evento deben escalar en la misma proporción.
- **x8 y x20 son provisionales.** Se fijan antes del Evento 1 con los datos reales de la
  v1: peces por minuto, minutos reales por gigante y cuántos jugadores siguen
  conectados al llegar al Minotauro.

## Fuera de alcance de la v1

- Dragón marino y Zorro de agua (son los eventos 1 y 2, ver `roadmap.md`).
- Comercio entre jugadores, cañas con estadísticas, mascotas, pases de juego.
- Modelos de arte para todo lo que no sea un gigante (fase 2, ver `CLAUDE.md`).
