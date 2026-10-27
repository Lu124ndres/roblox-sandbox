# Pruebas del guardado y las compras (experiencia privada publicada)

En Studio sin publicar no hay DataStore (`SaveStore` usa memoria y avisa "DataStore no
disponible"). Estas pruebas se hacen en la experiencia **publicada y privada**. Cómo funciona
el guardado: `docs/resumen_proyecto.md`, sección 4; código en `src/server/Save/` y
`src/server/Monetization/Receipts.luau`.

## Antes de empezar

- [ ] Publicar la última versión desde Studio con Rojo sincronizado (Alt+P).
- [ ] Configuración del juego → Seguridad → **Permitir que Studio acceda a los servicios de
      API** activado (para las pruebas 6 y 7).
- [ ] Una segunda cuenta de prueba (o un amigo) para las pruebas de regalo y de cambio de
      servidor.
- [ ] La consola del desarrollador (F9) abierta en el juego: pestaña **Server** para ver los
      `warn` de `SaveStore` y `Receipts`.
- [ ] Anotar el estado inicial de la cuenta de prueba: monedas, poder, kills, renacimientos,
      mejoras y especies de la colección.

## 1. Guardar y volver a cargar

- [ ] Entrar, pescar unos peces, comprar una mejora, entrenar un poco. Anotar los valores.
- [ ] Esperar más de 60 s (un autoguardado) y salir.
- [ ] Volver a entrar: todo igual que al salir (monedas, poder, canasta, colección, mejoras).
- [ ] En la consola no aparece "SaveStore: DataStore no disponible".

## 2. Entrar y salir rápido

- [ ] Entrar y salir antes de que termine de cargar (antes de que aparezcan las monedas en el
      HUD). Repetir 3 veces seguidas.
- [ ] Entrar de nuevo y esperar: **carga normal, sin la expulsión "Tus datos siguen abiertos en
      otro servidor"** y sin perder nada. (Antes del arreglo, el bloqueo podía quedar vivo
      3 minutos.)
- [ ] Pescar algo y salir **enseguida** (antes del autoguardado). Volver a entrar: lo pescado
      está.

## 3. Cambiar de servidor

- [ ] Con dos servidores abiertos (en el menú de servidores o con un amigo en otro), entrar en
      el A, pescar, y saltar al B (Unirse desde el perfil del amigo).
- [ ] En el B carga con los datos de A (puede tardar unos segundos si A todavía tenía el
      bloqueo: reintenta cada 5 s).
- [ ] Si alguna vez sale "Tus datos siguen abiertos en otro servidor", anotar cuánto tardó y
      volver a entrar al minuto: tiene que cargar sin pérdidas.

## 4. Cerrar el servidor

- [ ] Con 2+ jugadores dentro, pescar y comprar mejoras con los dos.
- [ ] Creator Hub → la experiencia → **Servidores → Cerrar todos** (o "Reiniciar servidores
      para la actualización" tras publicar).
- [ ] Volver a entrar con los dos: los datos de ambos están (lo de los últimos segundos
      incluido).
- [ ] Repetir justo después de un renacimiento: el renacimiento quedó guardado (renacer
      guarda en el momento).

## 5. Compras con Robux (productos de prueba)

Requiere que los productos ya tengan su ID en `Assets/Products.luau`. En la experiencia
privada las compras del dueño son reales; usar productos baratos (por ejemplo, un giro de
ruleta) o una cuenta de prueba.

- [ ] Comprar un producto: llega el aviso, se entrega, y al salir y volver a entrar sigue
      entregado (y no se cobra ni se entrega dos veces).
- [ ] Comprar y **salir enseguida** (en los 2-3 s después de confirmar): al volver a entrar el
      producto está, una sola vez. Si Roblox dejó la compra pendiente, se confirma al entrar.
- [ ] **Regalo:** con la segunda cuenta en el servidor, regalarle un producto o un pase.
      Los dos ven el aviso; la otra cuenta sale y vuelve: lo tiene. El que pagó no lo recibe.
- [ ] Comprar durante la carga (apenas se entra, antes de que aparezca el HUD): la compra
      queda pendiente y se entrega cuando terminan de cargar los datos.

## 6. Compra con guardado fallido (simulado)

Para ver que una compra no se confirma si no se pudo guardar.

En **Play en Studio** el servidor corre en tu PC, así que cortar la red de la PC hace fallar
de verdad las llamadas al DataStore. Las compras en Studio son de prueba (no cobran).

- [ ] En Studio, con el lugar publicado y el acceso a la API activo, entrar en **Play** y
      esperar a que carguen los datos.
- [ ] Abrir la compra de un producto, **desconectar la red de la PC** (Wi-Fi o cable) y
      confirmar la compra de prueba.
- [ ] Esperado en la salida del servidor: `SaveStore: intento 1 falló…` hasta el 5 y **ningún
      "¡… para siempre!"** confirmado como compra: `ProcessReceipt` devuelve
      `NotProcessedYet`.
- [ ] Reconectar la red. Studio vuelve a llamar a `ProcessReceipt` (puede tardar o hacer falta
      volver a abrir Play): el producto **no se entrega dos veces** y esta vez se confirma.
- [ ] En el juego publicado, revisar después de cada compra real que no haya avisos
      `Receipts: no se pudo entregar` en la consola del servidor.

## 7. Migración desde versiones viejas del esquema

`SaveSchema.VERSION` es 18 (al 2026-10-26; el número vigente se lee en `src/server/Save/SaveSchema.luau`). Un guardado viejo tiene que cargar con todo lo que tenía y los
campos nuevos en cero. Hacerlo con **la cuenta de prueba**, nunca con una cuenta con datos
reales que importen.

- [ ] En Studio (lugar publicado, acceso a la API activo), barra de comandos en Edit,
      escribir un guardado de versión 6 (canasta como lista) para la cuenta de prueba
      (`<UserId>` = su número):
      ```lua
      local store = game:GetService("DataStoreService"):GetDataStore("Jugadores_v1")
      store:SetAsync("jugador_<UserId>", { data = {
          version = 6, coins = 1234, power = 567, kills = 3,
          carried = { "Sardina", "Sardina", "Atun" },
          species = { Sardina = 2, Atun = 1 },
          upgrades = { Rod = 3, Basket = 2, Boots = 2 },
      } })
      ```
- [ ] Entrar con la cuenta de prueba: 1234 monedas, 567 de poder, 3 kills, la canasta con
      2 sardinas y 1 atún, las mejoras en 3/2/2, y renacimientos, giros y misiones en cero.
- [ ] Salir y volver a entrar: ahora el guardado es de la versión 18 y sigue igual (con
      `playMinutes` sumando).
- [ ] **Versión más nueva:** escribir lo mismo con `version = 99` y entrar: tiene que salir el
      aviso "El juego se actualizó. Vuelve a entrar para jugar la versión nueva." **sin
      tocar los datos** (comprobarlo con `store:GetAsync("jugador_<UserId>")`: sigue con
      `version = 99` y sin `lock`).
- [ ] **Corrupto:** escribir `{ data = "basura" }` y entrar: aviso "No pudimos cargar tus
      datos" y el registro queda igual (sin `lock`).
- [ ] Al terminar, borrar la llave de prueba: `store:RemoveAsync("jugador_<UserId>")`.

## 8. Rankings e insignias

- [ ] Tras unos minutos de juego, los tableros del ranking muestran a la cuenta de prueba
      (poder, kills, renacimientos).
- [ ] Las insignias de primer pez y primer raro se entregan (requieren que existan en el
      Creator Hub).

## Qué anotar

Cualquier pérdida, duplicado o expulsión, con la hora, el servidor y lo que había en la
consola del servidor (F9 → Server). Va a `docs/devlog.md` y, si hay que cambiar el código,
al backlog.
