# Guía: crear un monstruo nuevo de principio a fin

Cómo se hace un gigante completo en este juego, desde las imágenes de referencia hasta que
vuela, camina o nada en el cráter con su hábitat, sus sonidos y sus efectos. Resume lo aprendido
con el **Minotauro v2** (`docs/plan_minotauro_v2.md`) y el **Dragón marino v2**
(`docs/plan_dragon_v2.md`). Úsala junto con `docs/estilo_modelos.md`, que manda en la topología
y el tamaño de los modelos.

La skill local `/crear-monstruo` (`.claude/skills/crear-monstruo/`) sigue esta guía paso a paso.

---

## 0. Reglas que no se negocian

1. **El usuario aprueba los renders antes de cualquier commit de geometría nueva.** Se le
   muestran imágenes y se espera su respuesta. Lo mismo con los cambios grandes de aspecto del
   hábitat.
2. **Animación solo por código** (`Bone.Transform`, TweenService, CFrame). Nada de keyframes ni
   `AnimationController`.
3. **Audio solo de ProSoundEffects o de cuentas oficiales de Roblox.** Nada copiado de juegos ni
   de películas: el repositorio es público.
4. **Las referencias del usuario no se suben al repo** (`referencias/` está fuera de git). Se toma
   la *forma general*; nunca se replica un personaje con marca, ni se escribe su nombre en
   código, docs o commits ("la referencia del usuario").
5. El cliente solo presenta. El servidor decide la comida, la etapa y la evolución.
6. Todo lo de `CLAUDE.md`: `--!strict`, ≤ 200 líneas por archivo, IDs en `Assets`, números en
   `Config`, y el checklist (build, selene, stylua y prueba en Studio por MCP).

---

## 1. Fases y puntos de aprobación

| Fase | Qué sale | Aprobación del usuario |
|---|---|---|
| A. Referencia y biblia | Lectura de las imágenes, biblia de diseño (sección 2) | Sí: paleta, hábitat y estilo |
| B. Etapa maestra | Una etapa (la adulta, E3) modelada, renders lado a lado con la referencia | **Sí** |
| C. Las otras tres etapas | E1, E2 y E4 en paralelo a partir de la maestra, más alineación a escala | **Sí** |
| D. Rig y FBX | 4 FBX con su textura, poses extremas limpias | — (va con C) |
| E. Studio | El usuario importa; se revisa, se pasa a ServerStorage, IDs y `modelSuffix` | El usuario importa |
| F. Movimiento | Rutina, trucos, comer, evolución (código) | Sí, viéndolo en Play |
| G. Hábitat | Relleno del cráter, decoraciones, aire, luz | Sí, con capturas |
| H. Sonidos y VFX | Voces por etapa, golpes, partículas | Sí, en Play |
| I. Cierre | Docs, devlog, decisiones, backlog, guardar y publicar | El usuario guarda y publica |

**Lección del dragón:** las cuatro etapas hechas en paralelo desde cero salieron dispares entre
sí aunque compartían una biblia. Primero se hace y aprueba **una** etapa maestra, y después se
sacan las demás de ella (crecer o achicar, cambiar paleta y detalles). Las etapas en paralelo
sirven cuando ya existe la maestra.

---

## 2. La biblia de diseño (fase A)

Antes de modelar se escribe una biblia corta, que es lo que mantiene a varias sesiones haciendo
la misma criatura. Va en el scratchpad mientras se trabaja. Al aprobarse, su resumen pasa a
`docs/plan_<criatura>_v2.md`. Tiene:

1. **Qué se lee en la referencia:** de 5 a 8 rasgos que definen la silueta, en orden de
   importancia. Por ejemplo, en el dragón: "alas enormes de murciélago con festón hondo y ganchos;
   cuello largo en S; cola de látigo con abanico; púas encendidas".
2. **Toques propios del juego:** qué se le suma para que encaje. Por ejemplo, "marino": ojos,
   aletitas y aleta de la cola turquesa, ~15 % del color.
3. **Paleta por etapa (sRGB):** una tabla con cuerpo, sombra, panza o placas, acento emisivo,
   cuernos y garras, ojos y boca. Cada etapa es más oscura que la anterior y lleva más acento.
   Nada de negro ni blanco puros en superficies grandes.
4. **Proporciones por etapa, en módulos:** largo de cabeza, cuello, cuerpo, cola y patas, y la
   medida que manda (alto o envergadura). La cría tiene cabeza y ojos grandes; la forma final es
   masiva, de cabeza chica en proporción y épica.
5. **Escala** (sección 3) y **contrato de huesos** (sección 4).
6. **Archivos y reglas de trabajo:** qué archivo es de cada sesión y cuáles son compartidos y no
   se tocan.

Ante una decisión de identidad que cambia el resultado, se pregunta al usuario con opciones. Por
ejemplo: ¿colores de la referencia o los del juego? ¿Qué hábitat?

---

## 3. Escala y módulo

El juego escala cada etapa a `stageHeightsInPlayers` × `playerHeightStuds` (`Config/Giants`):
**3, 8, 15 y 30 jugadores × 5.5 = 16.5, 44, 82.5 y 165 studs.** `GiantTemplates` mide el
modelo y guarda `BaseHeight`:

- **Los que caminan o nadan** se miden por el **alto**.
- **Los que vuelan** (tienen `AlaIzq1`) se miden por su **lado más largo**, que debe medir
  `Dragon.LENGTH` (0.6) × el alto de la etapa: 9.9, 26.4, 49.5 y 99 studs. Ojo: si las alas son
  lo más largo, alas más anchas achican el cuerpo en pantalla.

En Blender, cada etapa usa un **módulo** (la celda) distinto, para que los bloques crezcan con el
cuerpo:

| Etapa | Celda (BU) | Módulos típicos | Triángulos máx. |
|---|---|---|---|
| E1 cría | 0.1 | ~31-36 | 8k |
| E2 joven | 0.3 | ~28-32 | 10k |
| E3 adulto | 0.5 | ~31-36 | 12k |
| E4 forma final | 1.0 | ~31-36 | 15k |

- **Una sola escala de exportación** (studs por BU) para las cuatro etapas. Así el FBX llega con
  su tamaño real y las etapas se comparan entre sí. El Minotauro usa 5.32 y el Dragón 2.75.
- La medida que manda tiene que dar **exacta**: la E2 lleva menos módulos (28 o 32) para que
  cuadre con 0.3. Si el bisel le quita algo a una punta en cuña, esa punta termina en cara plana.

---

## 4. El modelo de bloques (fases B y C)

### Herramientas (`tools/blender/`)

| Script | Qué hace |
|---|---|
| `minotauro_v2_bloques.py -- --criatura <c> --etapa <n>` | Armador común. Carga `<c>_v2_e<n>_geometria.py`, arma las piezas, revisa (caras coplanares, normales, bisel, pendientes) y hace los renders (frente, perfil, tres cuartos, atrás y diagnóstico). Guarda `assets/blender/<c>_v2/e<n>_bloques.blend` y `renders/<c>_v2_e<n>/` (con `estadisticas.json`). Sin `--criatura`, hace el minotauro. |
| `<c>_v2_e<n>_geometria.py` | Lo propio de la etapa: `CELDA`, `ALTO_JUEGO` (o `LARGO_JUEGO` si vuela), `COLORES`, `construir()`, `ARTICULACIONES`, `COLAS` y `PUNTOS`. Opcionales: `MODELO`, `PREFIJO`, `CONTRATO`, `VISTAS_EXTRA` y `PISO_BAJO`. Si pasa de 200 líneas, se parte en `_cabeza.py`, `_alas.py`, etc. |
| `dragon_v2_formas.py` | Formas comunes: `prisma` y `par_prisma` (polígono convexo extruido), `lamina` (contorno cóncavo partido en piezas convexas: membranas), `espinas`. |
| `<c>_v2_poses.py --etapa <n>` | Poses extremas con la misma cuenta que el código del juego (`Rig.bind` y `Pose.apply`). Barre el aleteo o el paso entero y deja `poses/poses.json` y los PNG. |
| `rig_<c>_v2.py --etapa <n>` | Rig (un hueso por pieza, peso 1), textura de paleta y FBX: `assets/blender/<Modelo>E<n>_v2.fbx` y `assets/textures/<Modelo>E<n>_v2_color.png`. Verifica que la malla con los huesos coincida con las piezas rígidas. |
| `minotauro_v2_alineacion.py [-- --criatura <c>]` | Las cuatro etapas lado a lado a tamaño real, igualadas en proporción, en silueta y, si vuela, desde arriba: `renders/<c>_v2_alineacion/`. |

Comando: `"/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup --python <script> -- <args>`.

Para una criatura nueva, la regla es copiar lo del dragón (`--criatura`, `CONTRATO`) y no
editar el armador común salvo que haga falta. Si se edita, el minotauro tiene que seguir saliendo
idéntico (comparar `estadisticas.json`).

### Construcción

- Ejes: x = izquierda del personaje, −y = frente, z arriba. Todo en celdas de la etapa.
- `bloque(parte, colección, color, (x0,x1), (y0,y1), (z0,z1), eje, fin, recorte)` y `par(...)`
  (espejado). `parte` es el **hueso** que mueve la pieza.
- Cuñas solo 1:1, 1:2 o 2:1. Bisel de 0.12 módulo. Las piezas que se solapan son siempre más
  chicas en todos los lados que la que las tapa: si no, quedan caras en el mismo plano que
  parpadean.
- Ojos y acentos grandes y legibles a 100 studs y en un teléfono. Si "no se distinguen", se
  agrandan, se les da brillo y se los saca de la sombra (pasó con el minotauro E2 a E4).

### Juntas (lo aprendido)

- **Cola o cuello en segmentos:** cada segmento mete una cuña 1:2 dentro del anterior y tapa la V
  que se abre al girar. Una caja metida que comparte una cara con el padre deja caras coplanares.
- **Alas en tejas:** cada segmento empieza una celda adentro del anterior y una celda más arriba.
  La bisagra va en la cara de contacto y las bisagras de Ala2 y Ala3 a la mitad del hondo del ala.
  Así no se abre rendija al aletear y de paso dan el diedro.
- **Membrana llena** (el usuario pidió "more solid membrane"): una lámina por segmento, partida
  en piezas convexas con las costuras bajo los dedos. El festón es cóncavo y las puntas quedan en
  las puntas de los dedos.
- **Muñeca del ala detrás de la cabeza;** si no, al subir el ala entra en las mejillas.
- **Mandíbula:** termina una celda antes del cuello, con la esquina de atrás y abajo en cuña 1:1.
- **Patas que cuelgan:** el muslo gira detrás del pecho, porque al colgar gira hacia adelante.
- **Placas acorazadas con grietas de lava (E4):** las vetas son continuas, de una celda, y siguen
  las juntas de las placas. Nada de puntitos sueltos: el usuario lo notó. Las piezas acorazadas
  se tocan cara con cara.

### Revisión de la etapa

1. Renders: tres cuartos, perfil, frente, atrás y arriba (y abajo si vuela), más una imagen
   **lado a lado con la referencia**.
2. Para un monstruo de alas: un panel con **las alas arriba** (la pose de aleteo), porque en
   planeo se ven de canto.
3. `estadisticas.json`: medida exacta, triángulos dentro del presupuesto, 0 caras coplanares y 0
   normales invertidas.
4. Poses extremas: la meta es ≥ 19 de 24 limpias y el ciclo entero de aleteo o paso, limpio.
   Umbrales: atraviesa 0.3 celdas, junta 1.0, hueco 0.2.
5. **Mostrar al usuario y esperar.** Si dice "no me gusta", se vuelve a la biblia, no a los
   detalles.

---

## 5. Huesos y rig (fase D)

Los primeros contratos (Minotauro con 25 huesos más 3 de faldón, Dragón con 32) alcanzan para
moverse, pero no para **actuar**: no parpadean, no cierran las manos ni hacen gestos. A partir de
ahora cada monstruo lleva un **rig detallado** en dos capas:

- **Huesos base, obligatorios:** los que ya usa el código para moverse, posarse y comer. Sin
  ellos el monstruo no funciona.
- **Huesos de detalle, opcionales:** cara, manos, pies, columna y cola más finas, púas y
  accesorios. El código los anima **solo si el modelo los tiene**: `Rig.turn` ya ignora un hueso
  que no existe, así que los modelos viejos siguen andando igual.

### 5.1 Nombres

- En castellano, PascalCase y sin tildes. El lado va al final (`Izq` = izquierda del personaje,
  +x en Blender) y las cadenas se numeran de la raíz a la punta (`Cola1..Cola8`, `DedoIzq1_1`
  es el primer dedo y su primera falange).
- Los mismos nombres en las cuatro etapas. Si una etapa no tiene una pieza (la cría sin barba),
  ese hueso no existe y el código lo salta.
- Los **puntos sin pesos** (sockets) también se nombran: `Raiz`, `Boca`, `Ojo{l}Mira` (de donde
  sale la mirada), `Grieta*` (efectos), `Pie{l}Apoyo` (el punto de contacto con el suelo).

### 5.2 Contrato detallado

Árbol de referencia. Los marcados **(base)** son obligatorios; el resto, de detalle. Hay que
adaptarlo al tipo de criatura (sección 5.3).

```
Raiz (base, sin pesos)
└── Cadera (base)
    ├── Lomo1 > Lomo2                  columna en 2-3 tramos: torcer, encorvarse, respirar
    │   └── Pecho (base)
    │       ├── Panza                  se infla al respirar (se mueve, no se escala)
    │       ├── Cuello1 (base) > Cuello2 > Cuello3     el cuello reparte el giro de la cabeza
    │       │   └── Cabeza (base)
    │       │       ├── Mandibula (base) > Lengua1 > Lengua2
    │       │       ├── Boca (base, sin pesos)
    │       │       ├── Labio{l}        comisura: sonrisa, gruñido (muestra los colmillos)
    │       │       ├── Nariz           resoplar, olfatear
    │       │       ├── Ceja{l}         enojo, sorpresa, tristeza
    │       │       ├── Parpado{l}      parpadear, entrecerrar, dormir
    │       │       ├── Ojo{l}          la pupila mira (ver 5.4)
    │       │       ├── Oreja{l} > OrejaPunta{l}       orejas con dos tramos
    │       │       ├── Aleta{l}        aletitas, volantes, papada
    │       │       └── Melena1..3 / Barba1..2         pelo y barbas con inercia
    │       ├── Clavicula{l}            subir y bajar el hombro
    │       │   └── Brazo{l} (base) > Antebrazo{l} (base) > Mano{l} (base)
    │       │       ├── Dedo{l}1_1 > Dedo{l}1_2       2-3 dedos de 2 falanges
    │       │       └── Pulgar{l}
    │       └── Ala{l}1..3 (base, si vuela)
    │           └── AlaDedo{l}1..3      los dedos del ala: abrir y cerrar la membrana
    ├── Muslo{l} (base) > Pierna{l} (base) > Pie{l} (base)
    │   └── Garra{l}1..3 / PieDedos{l}   los dedos del pie se doblan al pisar y al empujar
    ├── Cola1..Cola8 (base: al menos Cola1..Cola3)    más tramos = curva más suave
    │   └── ColaPunta                   la pala, el abanico o el mechón de la punta
    └── Puas1..N                        grupos de púas o placas del lomo que se erizan
```

**Presupuesto:** de 40 a 70 huesos por modelo. Más que eso cuesta CPU (cada `Bone.Transform`
se escribe por cuadro) y casi no se nota. Cada hueso es una pieza rígida más, así que también
suma triángulos: se cuenta dentro del presupuesto de la etapa.

### 5.3 Qué agrega cada tipo de criatura

| Tipo | Además de la base, lo que más rinde |
|---|---|
| Bípedo (minotauro) | Párpados, cejas, labios, dedos de las manos (agarrar el pez, puño al rugir), clavículas, Lomo1-2, orejas de 2 tramos, faldón en 3 piezas. |
| Volador (dragón) | `AlaDedo` (la membrana se abre y se cierra), Cuello1-3, Cola1-8, ColaPunta, párpados, cejas, lengua, púas que se erizan, garras del pie que se cierran al posarse. |
| Cuadrúpedo | Lomo1-2, las cuatro patas con dedos, orejas de 2 tramos, cola larga con punta, nariz. |
| Nadador (orca, tiburón) | Columna en 4-6 tramos (la onda del nado), aletas pectorales de 2 tramos, aleta dorsal que se dobla, cola de 2 tramos, párpados, mandíbula y lengua. |

### 5.4 Cómo se modelan las piezas de detalle (bloques rígidos)

Cada hueso nuevo es una pieza más, cortada en su articulación con las reglas de juntas de la
sección 4. Las de la cara tienen trucos propios, porque `Rig.turn` solo **gira**, no traslada:

- **Párpado:** una placa de una celda delante del ojo, con la bisagra en el borde de arriba del
  ojo. Abierto, gira hacia arriba y queda escondido dentro de la ceja o el cráneo. Al parpadear
  baja y tapa el ojo. Va media celda por delante de la cara del ojo para no quedar en el mismo
  plano.
- **Pupila:** una pieza aparte con su pivote **detrás del ojo**, en el centro del globo. Girar
  ese hueso unos pocos grados la desplaza sobre la cara del ojo, así que mira sin trasladar.
- **Ceja:** una cuña sobre el ojo con el pivote en su punta de adentro. Girada hacia abajo es
  enojo; hacia arriba, sorpresa o tristeza.
- **Labio o comisura:** una pieza chica en la esquina de la boca que gira hacia arriba (sonrisa)
  o hacia afuera y arriba (gruñido: deja ver el colmillo, que va pegado a la Mandibula).
- **Lengua:** dos tramos dentro de la boca, que asoman cuando la mandíbula se abre del todo.
- **Dedos:** un bloque por falange de al menos 1 celda de ancho; la uña o garra va pegada a la
  última. En la E1 (celda de 0.1) caben 2 falanges; en la E4, 3.
- **Púas que se erizan:** se agrupan de a 2-4 por hueso, con el pivote en la base, para que un
  hueso no mueva púas de dos tramos del lomo.
- **Puntos de contacto** (`Pie{l}Apoyo`): un hueso sin pesos en la planta, para que el código
  apoye el pie sin adivinar la geometría.

### 5.5 Del modelo al juego

- **Ejes medidos al enlazar** (`<Criatura>/Rig.bind`): adelante, derecha y arriba salen de los
  huesos en la pose de bind, así no importa cómo los orientó el exportador. Los ejes de cada
  hueso de detalle se miden igual. En los que vuelan, adelante va de la Cadera a la Cabeza: con
  la cabeza alzada, **la Cadera gira a la altura de la Cabeza** para que adelante = −y exacto.
- `ARTICULACIONES`, `COLAS` y `PUNTOS` de la geometría de cada etapa llevan **todos** los huesos.
  `CONTRATO` (la lista que revisa el rig) separa los base de los de detalle: si falta un hueso
  base es un error; si falta uno de detalle es un aviso. **Pendiente:** hoy
  `minotauro_v2_revision.py` y `rig_*_v2.py` tratan todo `CONTRATO` como obligatorio. Con el
  primer monstruo de rig detallado se agrega `CONTRATO_DETALLE` a la geometría y se ajustan los
  dos, comprobando que el Minotauro y el Dragón salgan idénticos. También quedan por escribir
  `Gestos.luau` y la capa de cara: el primer monstruo que los use los deja como ejemplo.
- **Poses extremas nuevas** en `<c>_v2_poses.py`:
  - ojos cerrados;
  - pupilas en las 4 esquinas;
  - cejas arriba y abajo;
  - gruñido;
  - lengua afuera con la boca al máximo;
  - manos en puño y abiertas;
  - dedos del ala cerrados;
  - púas erizadas;
  - cola de 8 tramos enroscada;
  - garras cerradas.

  Se exige lo mismo que al resto: nada atraviesa ni se separa, y el párpado cerrado no queda en
  el mismo plano que el ojo.
- **FBX:** `apply_scale_options="FBX_SCALE_UNITS"`, `axis_forward="-Z"`, `axis_up="Y"`,
  `primary_bone_axis="Y"`, `secondary_bone_axis="X"` y `add_leaf_bones=False`. Una malla, un
  hueso por vértice y la textura de paleta (256 px, un cuadro por color) embebida.
- En Studio se revisa que llegue la cantidad de huesos esperada, contando los sin pesos
  ("Mantener huesos de influencia cero").

---

## 6. Studio (fase E)

El MCP de Studio **no importa FBX**: lo hace el usuario.

1. El usuario usa Importar 3D con **"Mantener huesos de influencia cero"** (si no, se pierden
   `Raiz` y `Boca`) y deja los modelos en Workspace.
2. Por MCP, en Edit, se revisa cada uno:
   - la cantidad de huesos y el tamaño de la MeshPart (tiene que coincidir con el FBX);
   - la orientación: la boca hacia −Z y el lado izquierdo en −X;
   - que no esté anclado.
3. Se pasan a `ServerStorage.<Modelo>E<n>_v2`, dentro de un `ChangeHistoryService` para que se
   pueda deshacer.
4. Los IDs van a `Assets.Meshes.<Modelo>E<n>_v2` y `Assets/Textures.luau`, con un comentario
   (etapa y triángulos).
5. Se pone `modelSuffix = "_v2"` en su `GiantDef` (`Config/Giants.luau`). `GiantTemplates` publica
   `<Modelo>E<n>_v2` con el nombre `<Modelo>E<n>`, así que el resto del código no cambia. Borrar
   esa línea vuelve al modelo anterior.
6. En Play, en el servidor, se revisa `ReplicatedStorage.ModelosGigantes.<Modelo>E<n>`: MeshId y
   `BaseHeight` (16.5, 44, 82.5 y 165).
7. Se le recuerda al usuario: **Ctrl+S** (los modelos viven en el `.rbxl`) y **Alt+P** para
   publicar.

Registro de la importación: `docs/import_<criatura>_v2.md` o el paso 5 del plan.

---

## 7. Movimiento por código (fase F)

### Estructura

```
src/shared/<Criatura>/          lo que calcula la pose (puro, sin efectos)
    init.luau      new(center) → { step(dt, info) → pivote, state }; state.events
    Rig.luau       bind(model): huesos, ejes medidos, turn(rig, hueso, cabeceo, giro, alabeo)
    Pose.luau      la pose base de cada cuadro: respirar, mecerse, cola y orejas, mirar
    Etapas.luau    perfil por etapa (forModel(nombre): "…E(%d)$"): ritmo, fuerza, voz, rutina
    Medidas.luau   lo que se mide del modelo (patas, contactos, largos)
    Rutina.luau / Habitos.luau / Conducta.luau   qué hace cuando nadie le da de comer
    Posturas/      sentarse, estirarse, olfatear, mirar… (una por archivo)
    Trucos/        rugido, salto, baile… (una por archivo, con Curvas.luau)
    Comer/         la reacción a cada pez (ver abajo)
    Evolucion.luau la pose de evolución
    Azar.luau      hash sin estado: mismo resultado en todos los clientes
src/client/Giant/<Criatura>Stand.luau   (o DragonFly, OrcaSwim): el "Swim" del cuerpo
src/client/Audio/<Criatura>Voces.luau   recetas de sonido por evento y etapa
src/client/Effects/<Criatura>*.luau     partículas y efectos propios
```

- **El stand** implementa el tipo `OrcaSwim.Swim`: `step`, `top`, `mouth`, `water`, `bite`,
  `fed` (obligatorio) y `destroy`. Se registra en la cadena de `GiantBody`
  (`OrcaSwim.attach(...) or DragonFly.attach(...) or ...`). Cada `attach` devuelve `nil` si el
  modelo no tiene sus huesos característicos; por eso el orden importa.
- **Sincronía:** todo sale de `Workspace:GetServerTimeNow()` y de un hash sin estado (`Azar`),
  así todos los clientes ven lo mismo sin mandar nada por red.
- **Resortes** para lo que sigue con retraso (cola, orejas, mandíbula, faldón). Hay que cuidar la
  resonancia con el ritmo de un truco: a la cola del minotauro hubo que endurecerla y limitarla
  (`TAIL_MAX`).
- **Límites** donde el modelo rígido no aguanta. Por ejemplo, el aleteo del dragón está limitado
  a 1.4 rad (`Dragon/Alas`, `MAX_AMP`).
- **Eventos:** `state.events` (`step`, `stomp`, `roar`, `land`, `sit`, `evolve`, ...). El stand
  los convierte en sonido (`<Criatura>Voces`) y efectos.

### Capas de animación detallada

Cada cuadro, la pose se arma **sumando capas** en este orden. Cada capa solo toca sus huesos y
salta los que el modelo no tiene.

| Capa | Huesos | Qué hace |
|---|---|---|
| 1. Base | Cadera, Lomo, Pecho, Panza | Respirar (el pecho cabecea y la panza baja y sube; más lento y hondo en la forma final) y mecerse. |
| 2. Locomoción | patas, Garra, Pie{l}Apoyo | Paso o aleteo de la etapa. Los pies se apoyan con IK de dos huesos (Muslo y Pierna) sobre el suelo real; los dedos se doblan al apoyar y empujan al despegar. |
| 3. Mirada | Cuello1..3, Cabeza, Ojo{l} | Mirar a un jugador, al pez o al cielo. El giro se reparte: ojos ~20 % (llegan primero), cabeza ~50 %, cuello ~30 % (llega último). Los ojos tienen tope. |
| 4. Cara | Parpado, Ceja, Labio, Nariz, Oreja | Un gesto por emoción (tabla abajo), más el parpadeo y los gestos sueltos (resoplar, mover una oreja). |
| 5. Acción | lo que pida el truco, la postura, comer o evolucionar | Sus curvas (`Trucos/Curvas`) con anticipación (se carga al revés), golpe y recuperación; se mezclan por peso y nunca cortan de golpe. |
| 6. Secundaria | Oreja, Cola, Lengua, Melena, Barba, Aleta, Puas, AlaDedo | Resortes que siguen al padre con retraso. La rigidez baja hacia la punta de cada cadena (la punta llega más tarde) y cada cadena tiene su tope de giro, para que no entre en resonancia con el ritmo de un truco. |

**Gestos** (`<Criatura>/Gestos.luau`): una tabla de emociones (`calma`, `feliz`, `enojado`,
`sorpresa`, `sueño`, `asco`) con el valor de cada hueso de la cara. La capa 4 pasa de un gesto
a otro en ~0.2 s. De dónde sale el gesto:

- el enojo del servidor;
- `FedInfo`: un raro da sorpresa y luego alegría, una racha da festejo;
- la rutina: dormitar da sueño.

**Parpadeo:** cada 2-6 s, con el instante sacado de `Azar` (el mismo en todos los clientes). Se
cierra en ~0.06 s, queda cerrado ~0.05 s y se abre en ~0.12 s; a veces parpadea dos veces. Con
el gesto `sueño` los párpados quedan a medias, y cerrados cuando dormita.

**Manos:** se cierran en puño al rugir o al hacer fuerza, agarran el pez al comer (los dedos se
cierran al llegar el bocado) y se abren al festejar. En el ala, los `AlaDedo` cierran la
membrana al plegarla y la abren en el aletazo.

**Rendimiento:**

- Las capas 4 y 6 de detalle (cara, dedos, pelo) solo corren si la cámara está cerca
  (`Effects/Distance`) y no está el modo rápido (`FxQuality`). Lejos, el monstruo se mueve
  igual, pero sin gestos.
- Se escribe `Bone.Transform` solo si el valor cambió más que un umbral.
- Todos los ejes de los huesos se miden una sola vez, en `Rig.bind`.

**Prueba:** en Play, la cámara cerca de la cabeza (sección 11). Se revisa:
- que parpadee, mire al jugador y se enoje;
- que cierre la mano al comer;
- que, lejos, no cambie nada salvo los detalles.

### Movimientos naturales (lo que lo hace parecer vivo)

El monstruo no "ejecuta animaciones": **se comporta como un animal**. Para cada uno se escribe un
**catálogo de conductas** sacado de 1 o 2 animales reales parecidos (en la biblia, fase A). Se
mira cómo lo hace el animal de verdad y se pasa a sus huesos. El minotauro salió bien así (toro:
resopla, escarba, se sienta pesado); el dragón quedó más mecánico, porque vuela en vueltas y en
la percha hace poco.

**Catálogo de ejemplo por tipo** (se eligen 10-15 por monstruo):

| Tipo | Animal guía | Conductas |
|---|---|---|
| Zorro | zorro, gato | Se rasca la oreja con la pata de atrás; se agarra o se lame la pata; se sacude de la cabeza a la cola; salta en picada sobre algo (como cazando un ratón en la nieve); se estira en reverencia (patas adelante, cola arriba); bosteza; ladea la cabeza curioso; mueve cada oreja por su lado; se enrosca a dormir con la cola en la nariz; persigue su cola; olfatea el suelo y sigue un rastro. |
| Toro, minotauro | toro, gorila | Resopla; escarba con la pezuña; sacude la cabeza y los cuernos; se rasca el lomo contra una roca; se sienta pesado y apoya los brazos; se golpea el pecho; mira de reojo; patea el suelo antes de cargar; se estira de brazos; dormita cabeceando. |
| Dragón, volador | ave rapaz, murciélago, lagarto | Se acicala el ala con el hocico; estira un ala y después la otra; sacude las alas al posarse; abre las alas al sol; se rasca el cuello con la pata de atrás; saca la lengua y prueba el aire; ladea la cabeza siguiendo algo; camina sobre la percha apoyado en las muñecas; frena el aterrizaje con un aletazo y pliega las alas; bosteza mostrando el fuego; dormita con la cabeza bajo el ala; se sacuda la lava o el agua como un perro; persigue una brasa con la mirada. |
| Nadador | orca, delfín | Asoma la cabeza a mirar (como espiando); sopla por el espiráculo; da un coletazo en la superficie; se pone de espaldas y aplaude con las aletas; rueda; salta y cae de costado; nada en círculos cerca de quien le da de comer. |

**Reglas de naturalidad:**

1. **Peso y anticipación.** Antes de un salto se agacha; antes de rugir, toma aire (pecho
   arriba). El cuerpo carga el peso en un lado antes de levantar una pata.
2. **Asimetría.** Una oreja, una pata o un ala a la vez. Nada se mueve en espejo perfecto salvo el
   aleteo.
3. **Mira lo que hace.** Al rascarse la oreja, la cabeza se inclina hacia la pata. Al acicalarse,
   el hocico va al ala. Los ojos llegan antes que la cabeza.
4. **Contacto con su propio cuerpo.** La pata que rasca llega de verdad a la oreja y el hocico
   toca el ala. Se resuelve con IK hacia un punto del cuerpo (un hueso sin pesos como
   `Oreja{l}Rascar`). En Blender se verifica que llegue sin atravesar: es una pose extrema más.
5. **Pausas.** No moverse todo el tiempo. Entre conductas queda quieto respirando 1-4 s y a veces
   solo mira.
6. **Sin bucles perfectos.** Duración, cantidad de repeticiones (rascarse 3 a 6 veces) e
   intensidad salen de `Azar`. Nunca hace dos veces seguidas la misma conducta.
7. **Por etapa.** La cría juega (persigue la cola, salta, se cae y se levanta); el joven es
   inquieto; el adulto es seguro; la forma final se mueve poco, lento y con peso.
8. **Transiciones.** Cada conducta entra y sale por la pose de reposo con curvas suaves
   (`Trucos/Curvas`); nunca corta de golpe.

**Cómo se hace:** una conducta por archivo (`Posturas/` si es de quieto, `Trucos/` si es de
lucirse) con sus curvas por hueso, y una entrada en `Habitos` con su peso por etapa. Antes de
darla por buena:

- se ven en Blender los cuadros clave con los huesos reales, como hace
  `minotauro_v2_e1_animacion.py`;
- después se ve en Play con la cámara cerca.

### Mirar al público (no darle la espalda)

Los jugadores llegan por el **puente** hasta la puerta del cráter (`WorldZones.bridgeEnds()`,
el punto final) y alimentan desde la orilla. **El monstruo se muestra hacia ahí:**

- **Rumbo en reposo:** al llegar a cada lugar de su rutina, gira para quedar de frente al sector
  de la rampa (±60° de la dirección a la puerta). La meta es ≥ 70 % del tiempo de rutina con la
  cara hacia ese sector.
- **Rutas:** los paseos se eligen para que, al caminar o volar, se le vea de costado o de frente,
  no la cola. Los tramos de espaldas a la rampa son cortos: nunca más de ~3 s seguidos.
- **Perchas y lugares fijos** (rocas, nido, dunas): se orientan para que, posado, mire hacia la
  rampa o al centro del cráter con la rampa a la vista.
- **Mirada a cada jugador:** la cabeza y los ojos (capa 3) miran al jugador de **ese** cliente
  cuando está cerca de la orilla. Es solo cosmético: cada uno ve que lo mira a él. El rumbo del
  cuerpo sí es el mismo para todos (sale de la hora del servidor).
- **Al comer:** gira hacia quien le da de comer; ya lo hacen todos.
- **Trucos de lucirse** (rugido, salto, fuego): siempre de frente o de costado a la rampa.

**Prueba:** en Play, la cámara en la puerta del cráter durante 60-120 s. Se mide qué parte del
tiempo `adelante · (puerta − monstruo) > 0.5` (de frente a la rampa) y cuál fue el tramo más
largo de espaldas. Se repite en las cuatro etapas.

### Rutina (cuando nadie le da de comer)

Pasea por su hábitat, se sienta, se rasca, bosteza, olfatea, mira a un jugador o al cielo y hace
sus trucos. Cambia por etapa: la cría es inquieta y la forma final se mueve poco y pesada.
**Comer manda:** deja lo que hacía, va a la orilla de quien le da de comer y después vuelve a la
rutina. Si vuela: rutas por el cráter y perchas del hábitat (`Dragon/Guarida`, sección 8).

### Animación especial al comer

`FeedThrow` → `GiantView.onFed` arma un `FedInfo` (`from`, `fishId`, `rarity`, `isLocal`,
`streak`) → `body.fed(info)` → `stand.fed`. En `<Criatura>/Comer/`:

- `Elegir`: qué reacción le toca (rareza, racha, azar);
- `Mezcla`: cómo se suma a la pose;
- `Bocados`: el mordisco;
- `Gustos`: le encanta o no;
- `Festejos`: para rachas y raros;
- `Acentos`: sonidos y efectos.

FeedThrow manda como mucho un pez cada 0.45 s.

### Evolución

- El servidor publica `EvolucionHasta`. `GiantEvolution` y `EvolveFx` hacen la carga (0 a 1.3 s),
  el estallido (`BURST_SECONDS`, que es cuando cambia el modelo, escondido por el destello) y la
  calma.
- `EvolveLook` necesita el color de **acento** y de **núcleo** del monstruo y su **suelo** (agua,
  arena o lava).
- Con pose propia (agacharse y explotar, envolverse en las alas), el id va en `OWN_POSE` de
  `GiantEvolution`. Si no, salta y gira como los demás.

---

## 8. Hábitat y decoraciones (fase G)

El cráter es uno solo; lo que cambia es **con qué se llena**, en cada cliente:

1. Una bandera en el `GiantDef` (`lava = true`, `sand = true`, o una nueva en `GiantTypes`).
2. `CraterDrain` elige el modo y `CraterMode` lo guarda (`water`, `ice`, `lava`, `sand`, `empty`; `ice` conserva el agua: `isWet()`). Para
   un hábitat nuevo se agrega un modo, su relleno (`Crater<X>`) y sus mezclas de luz
   (`<x>Blend()`).
3. Lo que acompaña: un módulo que arma todo una vez (como `LavaLair`) y lo sube o hunde con el
   relleno (`LairLift`). El aire, la luz y la niebla (`LairAir`, `DesertAir`) y el suelo
   (`LairGround`, `SandTerrain`).
4. **`CraterGuard`:** con streaming, el agua del servidor puede volver encima del relleno. Cada 2 s
   revisa y la vuelve a sacar. Cualquier relleno nuevo tiene que entrar en su lista.
5. **Contrato monstruo ↔ hábitat** (como `Dragon/Guarida`): un módulo compartido con los lugares
   donde se posa, duerme o anida. El hábitat los construye ahí y el monstruo los usa. Si algo se
   mueve, se mueve en el contrato.

**Decoraciones con primitivas** (fase 1), por código:

- Nada de cilindros apilados: parecen tambores. Una roca natural (`LairCrag` y `LairRocks`) se
  arma así:
  - **Cima:** lajas giradas en escalones, con la primera justo a la altura del contrato.
  - **Corona:** bloques bajados con `under()` para que nada sobresalga de la cima.
  - **Laderas:** hileras de bloques torcidos que se abren hacia abajo.
  - **Contorno:** con bultos, pero nunca más adentro del radio que pisa el monstruo.
  - **Pie:** taludes en cuña, bloques sueltos y costra de discos corridos (no un círculo).
- Materiales: basalto y pizarra. **El Glass de Roblox refleja el cielo y se ve azul;** para
  obsidiana se usa SmoothPlastic sin reflejo.
- Hay que revisarlo de día y al atardecer: la luz cálida y la de la lava tiñen todo.
- Todo anclado y local; solo chocan las piezas que se pisan.

---

## 9. Sonidos (fase H)

- **Fuente:** solo ProSoundEffects o cuentas oficiales de Roblox. Hay que anotar el nombre del
  asset; si la licencia es dudosa, se reemplaza.
- `src/shared/Assets/Sounds.luau`: un bloque por monstruo (`-- <Criatura>`, y otro `-- Comer:
  <Criatura>`). Las claves sin ID quedan en `MISSING` y no suenan; el juego no depende de ellas.
- `src/client/Audio/<Criatura>Voces.luau`: recetas por evento, como **capas** (clave, en la
  cabeza o en el suelo, solo en algunas etapas o suelos, retraso, tono que sigue a la voz o al
  peso). El volumen, tono y alcance de esas claves se registran con `Sounds.define`.
- Por etapa, la voz baja de tono y los golpes suben de volumen; desde el adulto se suma un
  retumbo grave. El suelo cambia los golpes (agua, arena o lava).
- El rendimiento lo cuida `Sounds`: corta por alcance y tiene un tope de copias por clave.

## 10. VFX (fase H)

- Primitivas Neon, `PointLight` y `ParticleEmitter`, con texturas en `Assets.Particles`.
- Los emisores continuos pasan por `FxQuality` (en modo rápido no sale ninguno) y las ráfagas se
  escalan con `ClientSettings.fxScale()`.
- Los efectos que siguen la animación van en huesos hijos (por ejemplo `Grieta` en
  `DragonEmbers`). Las partículas quedan en el mundo y dejan rastro.
- El golpe en el suelo según el relleno pasa por `GroundFx` (salpica en agua, levanta polvo en
  arena).
- **La evolución** (aura, energía, estallido y columna de luz) es común a todos y toma los colores
  de `EvolveLook`.

---

## 11. Probar en Studio por MCP

Más trucos en la memoria del proyecto (`studio-mcp-testing`).

- **Cambiar de monstruo o etapa** (cliente):
  `ReplicatedStorage.Remotes.AdminCommand:FireServer("giant", "<Id>:<etapa>", LocalPlayer.UserId)`.
- **Darle de comer** (servidor):
  `Remotes.GiantFed:FireAllClients({{userId=…, count=1, fishId="Sardina"}})`, en un bucle de
  0.5 s con algún raro (`PezEspada`, `PezLuna`).
- **Juntar errores:** `LogService.MessageOut` en una tabla `_G`, filtrando `CorePackages`,
  `Assistant` y `203785492`.
- **Cámara:** con `RunService:BindToRenderStep(…, Last, …)` y las ScreenGui apagadas; después,
  `screen_capture`. Al terminar, detener Play (no hace falta restaurar a mano).
- **Código cambiado:** en Play no se recarga, hay que detener y volver a empezar. En Edit,
  `require` guarda la copia vieja: se clona la carpeta del módulo.
- **Un modelo que todavía no publica el juego** (por ejemplo `_code` o de prueba): en el
  servidor se clona en ServerStorage con el nombre normal, se vuelve a publicar `GiantTemplates`
  y se borra el clon. Así no se cambia ningún archivo.

---

## 12. Reparto en agentes paralelos (la forma normal de trabajar)

Pedido del usuario (2026-10-17): **las tareas de un monstruo se reparten en agentes que
trabajan en paralelo.** La sesión principal no modela ni programa todo en serie: reparte,
integra, prueba en Studio y habla con el usuario. Lo que no depende de otra cosa se lanza a la
vez, en una sola tanda de llamadas.

### Olas de trabajo

| Ola | Cuándo | Agentes en paralelo | La sesión principal |
|---|---|---|---|
| 1 | Biblia escrita | **Geometría E3** (Blender: geometría, bloques, renders). **Código base** (`<Criatura>/Rig`, `Etapas`, `Medidas` y el stand vacío, contra el contrato de huesos de la biblia). **Hábitat** (relleno, decoraciones, aire y luz). **Sonidos y VFX** (busca los assets y arma `Sounds` y las recetas). | Prepara los contratos compartidos y revisa los renders de la E3 con el usuario. |
| 2 | E3 aprobada | **E1**, **E2** y **E4** (una por agente). **Poses y rig de la E3** (`<c>_v2_poses.py`, `rig_<c>_v2.py`, FBX). Siguen los de la ola 1 si no terminaron. | Alinea las cuatro etapas y las muestra. |
| 3 | FBX en Studio | Uno por sistema de movimiento: **locomoción e IK**, **mirada y cara** (gestos, parpadeo), **secundaria** (colas, orejas, resortes), **conductas y rutina** (`Habitos`, `Posturas/`, `Trucos/`), **comer** (`Comer/`) y **evolución**. | Importa con el usuario, prueba en Play, integra y hace los commits. |
| 4 | Sistemas unidos | Agentes de **arreglos** con la lista de lo visto en Play, uno por área. | Prueba final, docs y cierre. |

Lo que sí espera: la geometría de E1, E2 y E4 espera la aprobación de la E3 (lección del
dragón, sección 1), y la prueba en Play espera la importación del usuario. El código base, el
hábitat y los sonidos **no esperan** la aprobación de la geometría: dependen del contrato de
huesos y del hábitat elegido, que se fijan en la biblia.

### Reglas para cada agente

- `isolation: "worktree"`. **Lo primero que hace es `git merge --ff-only main`**, porque el
  worktree puede nacer de un commit viejo.
- El encargo trae todo lo que necesita, porque el agente empieza sin contexto: rutas absolutas a
  la biblia, la referencia y esta guía (con las secciones que le tocan), **archivos propios**,
  la lista de **compartidos que no toca**, el contrato que tiene que cumplir (huesos, tipos o
  funciones de otro agente) y el **informe** que devuelve (archivos, medidas, renders, qué probó,
  qué queda flojo y un párrafo para el plan).
- **Contratos antes de lanzar:** si dos agentes se tocan (por ejemplo, la secundaria y las
  conductas escriben huesos de la cola), la sesión principal escribe primero el contrato (un
  tipo en `<Criatura>/Tipos.luau`, quién escribe cada hueso y en qué capa) y se lo da a los dos.
- Si hace falta un cambio en un archivo compartido, el agente lo explica en su informe y lo
  aplica la sesión principal.
- **Blender:** varios agentes pueden correr Blender en segundo plano (`-b`) a la vez, cada uno con
  sus archivos. El MCP de Blender (la ventana abierta) es uno solo: no se reparte.
- **Studio:** es uno solo y compartido. Los agentes no usan Play ni cambian el lugar; como mucho,
  consultas de solo lectura (`script_grep`, `search_asset`, `inspect_instance`). Las pruebas en
  Play las hace la sesión principal, una por vez.
- **Commits:** los agentes no hacen commit. La sesión principal copia o une sus archivos a main,
  pasa el checklist y hace un commit por tarea. Si hay geometría sin aprobar, no hay commit.
- De 3 a 5 agentes por ola. Más que eso cuesta integrarlos y probarlos.
- Al terminar: borrar los worktrees y ramas ya unidos (`git worktree remove`, `git branch -d`).
- Si el usuario detiene un agente por error, no se puede reanudar: se lanza uno nuevo y se le
  indica dónde quedó el avance a medias.

---

## 13. Cierre (fase I)

- Un commit por tarea, en español e imperativo (`agrega …`, `rehace …`), con la línea
  `Co-Authored-By` que pida la sesión.
- `docs/devlog.md`: qué se hizo, qué se probó, qué se rompió y qué sigue.
  `docs/decisiones.md`: lo no obvio. `docs/backlog.md`: marcar la tarea.
- El plan de la criatura (`docs/plan_<criatura>_v2.md`): estado, paleta, filas por etapa,
  articulaciones, resultado de las poses y pasos.
- `docs/ui-assets.md` si faltan íconos o retratos. El README, si deja de describir el juego.
- Recordar al usuario **guardar (Ctrl+S) y publicar (Alt+P)**.
