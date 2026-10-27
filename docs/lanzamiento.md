# Lista para lanzar "Pesca y Alimenta Gigantes"

Estado al 2026-10-26: el juego está publicado (placeId 129133484868369).

Estado al 16/10/2026. Marcar con [x] lo que se vaya haciendo.

## 1. Bloqueantes (sin esto no se puede abrir al público)

- [ ] **Publicar el lugar correcto.** Studio quedó abierto en una recuperación automática
      (`respaldo_lugar_2026-10-16.rbxl`). Abrirla y usar Archivo → Publicar en Roblox como →
      el juego "Pesca y Alimenta Gigantes". Ahí viven los trajes nuevos, `PropsMapa`,
      `ModelosEquipo` y los respaldos; si no se publica, se pierden.
- [ ] **Probar el guardado en el juego publicado** (en Studio sin publicar no hay DataStore):
      entrar, ganar monedas, salir, volver. Probar la migración de guardados viejos (versión 10).
- [x] **Crear los productos** en Creator Hub → Monetización → Productos y poner los IDs en
      `src/shared/Assets/Products.luau` (precio en el comentario de cada uno). Hecho el
      2026-10-19: los 70 tienen ID (lista en `docs/productos.md`).
- [x] **Crear los 3 pases** (VIP 299, ReyDelMar 149, DiosDelVolcan 858) y poner sus IDs en
      `Assets.GamePasses`.
- [ ] **Recibos de compra:** comprar cada producto en un servidor de prueba (Roblox da compras
      de prueba en Studio) y comprobar que llega lo prometido una sola vez.
- [ ] **Cuestionario de madurez** (Experience Questionnaire) y clasificación de edad.
- [ ] **Acceso a API / DataStore** activado en Configuración del juego → Seguridad.
- [ ] **Ícono y miniaturas** (512x512 y 1920x1080) y descripción en español (hay textos en
      `publicar/`).

## 2. Muy importantes (afectan cuánto se queda la gente)

- [ ] **Insignias:** crear las 9 (PrimerPez, PrimerRaro, PrimerLegendario, PrimerMitico,
      PrimeraKill, DiezKills, Coleccion, Tutorial, EstanqueMaximo) y poner sus IDs en
      `Assets.Badges`. Las insignias suben la retención y salen en el perfil.
- [x] **Grupo:** creado, con `groupId` 486234765 en `Config/Social.luau`. El regalo es +10 % de
      suerte y x1.1 de poder para siempre. Falta el "me gusta" con un premio (la meta de likes
      la pone el admin desde el panel).
- [x] **Zorro de agua:** modelo v2 de bloques con sus 4 etapas, en la ruleta (5 %) y en
      "elegir siguiente" desde el 2026-10-19. La Orca fantasma quedó fuera de los dos.
- [ ] **Probar con 5-10 personas reales** (amigos): comida según jugadores, kills compartidas,
      ruleta de monstruos, descanso, que nadie se quede trabado en el volcán.
- [ ] **Probar en teléfono real y con mando** (el simulador de Studio no cambia el modo de
      entrada). Revisar botones táctiles y que nada tape al personaje.
- [ ] **Rendimiento en un teléfono real de gama baja** (Android de 3-4 GB de RAM, tipo
      Galaxy A0x). El emulador de Studio no emula el procesador ni la GPU: ver
      `docs/rendimiento.md` (4,748 piezas, 2.3 M de celdas de terreno, 83 luces). En el
      juego publicado, con el monstruo comiendo y con 3+ jugadores:
      - FPS con `Shift+F5` (o la consola F9 → Memory): ¿se mantiene en 30 o más en la playa,
        el muelle y el cráter? Anotar el peor lugar.
      - Memoria del cliente (F9 → Memory → Total) a los 2 y a los 15 minutos: no debe crecer
        sin parar (fugas) ni pasar de ~1.5 GB.
      - Con el modo rápido encendido y apagado: ¿cuánto cambia?
      - Que no se cierre la app al abrir la tienda, la colección o al empezar el descanso.
      - Anotar los números en `docs/rendimiento.md` y elegir las mejoras de su tabla.
- [ ] **Equilibrio con datos reales:** con mucho poder y varios renacimientos se ganan
      ~259K monedas/min. Si se siente roto, bajar `Progression.coinScale.exponent` a 0.4.

## 3. Mejoras recomendadas (para crecer después del lanzamiento)

- **Anuncios cada actualización** (Ads Manager): miniaturas y video nuevos cada vez,
  sobre todo fines de semana. Es lo que más trae jugadores nuevos.
- **Precios para Latinoamérica:** si la mayoría juega desde México/LatAm, probar precios
  más bajos (el pack a 19 R$ va en esa línea) y dejar los precios administrados de Roblox.
- **Comunidad:** Discord + grupo, encuestas de qué monstruo sigue, códigos en redes.
- **TikTok/clips:** momentos grabables (el monstruo gigante comiendo, la ruleta de monstruos,
  el jackpot de la ruleta). Un botón "Compartir" o código por invitar amigos.
- **Algo nuevo cada vez que entras:** eventos del servidor (ya hay), "admin abuse" los fines
  de semana, monstruo de temporada (Orca fantasma en Halloween), misiones semanales.
- **Contenido a mediano plazo:** mascotas de pez (bonos), segunda isla/zona que se compra con
  monedas, más especies para la colección, tabla de récords semanal.
- **Calidad visual propia:** el mapa ya usa modelos 3D propios; seguir reemplazando
  primitivas (faro, cabaña, muelles) y revisar que la UI no se vea "hecha por IA".

## 4. Ya hecho en esta etapa

Tutorial, misiones diarias jugables solo, premio diario con racha (+10%/día), regalos por
tiempo, ruleta (gratis cada 6 h, por jugar, por racha, con Robux), renacer con bono
permanente, colección con premios cada 6 especies, comida del monstruo según jugadores,
estanques por kills o poder, tienda MEJORAS con íconos, pack de inicio, VIP y trajes,
mando y teléfono, panel de administrador.
