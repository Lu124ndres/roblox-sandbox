# Plan: Dragón marino v2 (bloques)

Rehacer el Dragón marino E1..E4 en el estilo de bloques del Minotauro v2
(`docs/plan_minotauro_v2.md`, `docs/estilo_modelos.md`): bloques, placas y cuñas sobre la
cuadrícula, bisel de 0.12 módulos, una pieza rígida por hueso, animación solo por código.

**Estado: E1 rediseñada para que se lea como dragón (2026-10-17), esperando que apruebes los
renders.** Después, E2..E4 en paralelo copiando la E1 (paso 3).

Decisiones del usuario: identidad de **mar y fuego** (dragón marino verde-azul que en las
etapas grandes se oscurece y se agrieta con fuego), guarida volcánica de lava, llega en pose de
**planeo** (como espera `Dragon/Rig`) y presupuesto de triángulos de 8k / 10k / 12k / 15k.

## Escala y módulo

El dragón **se mide por su dimensión más larga**: `GiantTemplates` escala a los gigantes con
alas para que su lado más largo mida `Dragon.LENGTH` (0.6) veces el alto de la etapa. En la E1
el largo (hocico a punta de la cola) y la envergadura miden lo mismo: 36 módulos.

| Etapa | Módulo (BU) | Largo en módulos | Largo (BU) | Largo en el juego (studs) | Studs por módulo |
|---|---|---|---|---|---|
| E1 cría | 0.1 | 36 | 3.6 | 9.9 (0.6 × 16.5) | 0.275 |
| E2 joven | 0.3 | 32 | 9.6 | 26.4 (0.6 × 44) | 0.825 |
| E3 adulto | 0.5 | 36 | 18.0 | 49.5 (0.6 × 82.5) | 1.375 |
| E4 anciano | 1.0 | 36 | 36.0 | 99 (0.6 × 165) | 2.75 |

- **Escala de exportación: 2.75 studs por BU**, la misma para las cuatro etapas (9.9 / 3.6).
  Con los 5.32 del Minotauro la E1 mediría 1.86 BU, 18 celdas: no alcanzan para ojos grandes,
  aletas y alas de tres segmentos. Como en el Minotauro, el juego igual reescala cada etapa;
  la escala sirve para que el FBX llegue a Studio con su tamaño real.
- La E2 tiene 32 módulos en lugar de 36 (como el Minotauro E2, 28 en lugar de 31): con módulos
  de 0.3 el largo exacto es 8/3 × 3.6 = 9.6 BU. Las cuatro etapas quedan exactas en studs.
- El dragón E1 es más chico que el Minotauro E1 en el juego (9.9 studs de largo contra 16.5 de
  alto) con casi los mismos módulos: sus bloques miden la mitad en studs.

## Paleta (sRGB)

Mar en el cuerpo, fuego en los acentos. Cada etapa más oscura que la anterior y con más fuego,
sin negro ni blanco puros en superficies grandes (como el Minotauro). Coincide con los colores de
`EvolveLook` (acento verde agua `#46FFA0`, núcleo naranja `#FF963C`).

| Uso | E1 cría | E2 joven | E3 adulto | E4 anciano |
|---|---|---|---|---|
| Cuerpo | `#2FB9A2` turquesa | `#1F9A93` | `#16696E` verde azulado | `#0F2F35` casi negro |
| Cuerpo oscuro (rayas, nariz) | `#1C8C86` | `#136E72` | `#0E4A52` | `#0A1E24` |
| Panza, pecho, mandíbula | `#C9F2D4` menta | `#A9DCC0` | `#6FA595` | `#3E5E58` |
| Aletas y membrana | `#62D8E6` agua clara | `#3FB8D0` | `#2A8FA8` | `#1C5F73` |
| Rayos de las aletas | `#2E9FC0` | `#1F7FA6` | `#176A86` | `#103F4F` |
| Fuego | garganta `#FF8A3D` | garganta y brasas en las puntas `#FF8A3D` | grietas `#FF7A2E` | lava `#FF9938` y `#FFE2A0` |
| Ojos | blanco `#F4FAF7`, pupila `#16222E` | ámbar `#FFC14D` | fuego `#FFB347` | lava `#FF9938` |

Comunes: boca `#B83A50`, dientes `#F6EFDC`, garras `#EDE3C6`; mejillas `#F59FAE` solo en E1-E2.
El brillo del fuego en Roblox sale del color más Neon o `PointLight` (no hay canal de emisión).

## Qué tiene cada etapa

| Etapa | Piezas propias |
|---|---|
| **E1 cría** (rediseñada) | Cabeza de dragón: cráneo de 8 de ancho, hocico más angosto (6, la punta en cuña) que sale 4 celdas por delante de los ojos, narinas oscuras arriba en la punta, sonrisa roja con colmillitos, ojos de 3×3 a los costados con pupila y brillo, ceja en cuña sobre cada ojo, **dos cuernos marfil que suben y se curvan hacia atrás** (la punta más fina y hacia afuera), púa en la nuca y aletitas en las mejillas detrás de la mandíbula. Cuello en arco (la cabeza queda 4 celdas arriba del lomo) con placas menta en franjas por delante; pecho y panza con placas transversales. Púas en sierra de la nuca a la cola, más chicas hacia la punta. Alas de murciélago de 3 segmentos en tejas: brazo por el borde de adelante hasta la muñeca (nudo con la garrita del pulgar), tres dedos en abanico (afuera hasta la punta del ala, atrás y afuera, derecho atrás), membrana llena entre los dedos con el festón cóncavo, más oscura junto al cuerpo. Cola de 6 segmentos que termina en pala en rombo. Patas gruesas recogidas con garras marfil. Fuego: la garganta (se ve al abrir la boca y una franja desde abajo). Ver `dragon_v2_e1_geometria.py` y `dragon_v2_e1_alas.py`. |
| **E2 joven** | Más largo de cuerpo y cola (la cabeza, proporcionalmente más chica), cuernos más largos, púas del lomo más altas, alas más grandes, ojos ámbar, brasas naranjas en las puntas de las púas y de la pala de la cola. |
| **E3 adulto** | Cuernos largos hacia atrás con un segundo par, colmillos, placas más grandes en el pecho, púas del lomo grandes, alas grandes con borde grueso, grietas de fuego en pecho, lomo y cola (que asoman o van metidas entre placas, como el Minotauro E4), la pala de la cola con borde de fuego. |
| **E4 anciano** | Corona de cuernos, barba de aletas, cuerpo casi negro con grietas de lava por todo el cuerpo, alas enormes con la membrana en escalones (desgarrada) y bordes de lava, ojos de lava, aleta de la cola grande. Enorme y lento. |

## Contrato de huesos (32) y articulaciones

El de `tools/blender/rig_dragon.py`, el que usan `Dragon/Rig` y `Dragon/Pose`:

    Raiz > Cadera > Pecho > Cuello1 > Cuello2 > Cabeza > Mandibula, Boca
                    Cadera > Cola1 > … > Cola6
                    Pecho > Ala{Izq,Der}1 > 2 > 3
                    Pecho > Brazo > Antebrazo > Mano (Izq, Der)
                    Cadera > Muslo > Pierna > Pie (Izq, Der)

`Raiz` y `Boca` sin pesos. Cada pieza rígida va entera a su hueso. Articulaciones de la E1 en
celdas (x = izquierda del dragón, −y = hocico, z arriba; lado izquierdo):

| Hueso | Articulación | Por qué ahí |
|---|---|---|
| Raiz | (0, −2, 8) | centro del cuerpo: el modelo gira alrededor de ella (volteretas) |
| Cadera, Pecho | (0, 1, 15), (0, −1, 9) | la Cadera, a la altura de la Cabeza (5 celdas por encima del lomo): ver abajo |
| Cuello1, Cuello2, Cabeza | (0, −6, 10), (0, −8, 13), (0, −10, 15) | el cuello sube en arco; la Cabeza gira por la base del cráneo |
| Mandibula, Boca | (0, −11, 17), (0, −18, 17) | borde de atrás y arriba de la mandíbula; la boca en la punta del hocico (de ahí sale el fuego) |
| Cola1..Cola6 | (0, 4, 7), (0, 6, 7.5), (0, 8, 7.5), (0, 10, 7), (0, 12, 7), (0, 14, 7) | cada 2 celdas |
| AlaIzq1, 2, 3 | (4, −2, 11), (10.5, 0, 11), (14.5, 0, 12) | hombro en el brazo del ala, en el borde de arriba del pecho; bisagras en la cara de contacto de las tejas, a la mitad del ala de adelante hacia atrás |
| Brazo, Antebrazo, Mano | (3, −5, 5), (3, −3, 2.5), (3, 0, 1.5) | |
| Muslo, Pierna, Pie | (3, 2, 6), (3, 5, 3.5), (3, 8, 2.5) | |

**Adelante con la cabeza alzada.** `Rig.bind` toma "adelante" de la Cadera a la Cabeza: con la
cabeza arriba del lomo, una Cadera a la altura del cuerpo daba adelante inclinado ~25° hacia
arriba. Por eso la Cadera gira por (0, 1, 15), a la misma altura que la Cabeza y encima del lomo:
es la raíz de todo el cuerpo y en el juego solo cabecea un poco al subir y bajar
(`−0.04 × climb` en `Pose.apply`), así que dónde gira no se nota. Con estas articulaciones
`Rig.bind` da adelante = −y exacto, derecha = −x (en Blender) y arriba = z, y `neutral` = −0.0067
rad: el diedro modelado (0.093 rad, una celda más arriba por segmento) es casi el 0.1 que pide el
código, así el planeo del juego es el del modelo (lo mide `dragon_v2_poses.py`, en `poses.json`).
Ojo: `DragonEmbers` (cliente, E3 y E4) suelta brasas en el hueso Cadera; si las E2..E4 copian
esta Cadera alta, las brasas saldrían por encima del lomo (conviene Pecho o Cola1).

El cuello ya no es horizontal: `Rig.bind` gira cada hueso del cuello alrededor de derecha × (del
hueso a su hijo), y `dragon_v2_poses.py` ahora hace lo mismo (`EJE_GIRO`).

### Juntas (lo aprendido en la E1)

- **Alas en tejas:** cada segmento empieza una celda adentro del anterior y una celda más
  arriba; la bisagra va en la cara de contacto. Al aletear siempre queda uno sobre el otro (no se
  abre rendija) y de paso dan el diedro. Los huesos de cada segmento (brazo, nudo, dedos) no
  pasan del borde donde empieza el siguiente: dos piezas a la misma altura que se solapan dejan
  caras en el mismo plano (parpadean).
- **Alas detrás de la cabeza:** con la muñeca más adelante que y −8, al subir el ala (aletazo
  arriba) el nudo y el pulgar, que en el ala vertical apuntan hacia adentro, entraban en las
  mejillas. La muñeca va en y −6..−3, detrás de las aletitas.
- **Bisagras del ala a la mitad:** el ala de murciélago es profunda (del borde de adelante al
  festón, hasta 17 celdas); girando por el borde de adelante, el látigo del aleteo barría el Ala3
  sobre el Ala1. Las bisagras de Ala2 y Ala3 van a la mitad (y 0); el hombro queda en el brazo
  (más atrás, el brazo se separaba del pecho al plegar).
- **Cola:** cada segmento mete una cuña 1:2 dentro del anterior (de la misma sección hacia
  adentro): tapa la V que se abre al girar. Una caja metida no sirve si comparte una cara con el
  padre (caras coplanares).
- **Membrana llena:** una lámina por segmento (no tiras), partida en piezas convexas
  (`trocear` de `dragon_v2_formas.py`) con las costuras bajo los dedos o bajo la teja siguiente;
  los dedos del medio van encima en relieve y el borde de atrás es un festón cóncavo: entre punta y
  punta se mete hacia la muñeca y las puntas quedan en las puntas de los dedos.
- **Cuello:** la base (Cuello1, 6 de ancho) es más ancha que la punta (Cuello2, 4): la punta se
  mete en la base sin que sus costados queden en el mismo plano.
- **Mandíbula:** termina una celda antes del cuello y la esquina de atrás y abajo va en cuña 1:1:
  al abrir (gira por arriba) y al girar la cabeza no toca el cuello. Girando por la esquina de
  abajo se separaba de la cabeza al abrir.
- **Púas apoyadas encima** del lomo, no metidas: la cola mide 2 de ancho como la púa, y una base
  metida dejaba sus costados en el mismo plano que los de la cola.
- **Patas adentro de x = 4 y muslo bajo (z 4..7):** el ala gira por el hombro (x = 4); al bajar, la
  cara de abajo de la membrana barre hacia adentro por encima del muslo sin tocarlo.
- **Pecho corto (hasta y = −1):** el muslo, al colgar (quieto en el aire), gira hacia adelante y
  entraba en el pecho.
- Las piezas que se solapan son siempre más chicas en todos los lados que la que las tapa.

## Herramientas

| Script | Qué hace |
|---|---|
| `minotauro_v2_bloques.py --criatura dragon` | El armador común: carga `dragon_v2_e<n>_geometria.py`, toma su contrato (`CONTRATO`), se mide por el largo (`LARGO_JUEGO`) y suma las vistas de arriba y de abajo. Sin `--criatura`, el Minotauro igual que antes. |
| `dragon_v2_e<n>_geometria.py` | Lo propio de la etapa: módulo, paleta, piezas, articulaciones. La E1 tiene las alas aparte, en `dragon_v2_e1_alas.py`. |
| `dragon_v2_formas.py` | Formas que no salen de un bloque con recorte, comunes a las etapas: prismas de cualquier polígono convexo de la cuadrícula (cuernos, cejas, dedos, pala), láminas de contorno cóncavo partidas en convexas (membranas con festón) y púas en sierra. |
| `dragon_v2_poses.py --etapa <n>` | Poses extremas con la cuenta de `Dragon/Rig.bind` y `Dragon/Pose.apply`; barre una vuelta del aleteo al máximo del juego. |
| `rig_dragon_v2.py --etapa <n>` | Rig de 32 huesos, paleta y FBX (usa las funciones de `rig_minotauro_v2.py`). |

## Poses extremas

`dragon_v2_poses.py` prueba: aletazo abajo y arriba al máximo del juego (amplitud × 1.7:
comiendo y enojado) y del rugido enojado (× 2.24), alas plegadas en picada, cola enroscada, en S,
arriba y abajo, cuello a los lados (30° y 60°), arriba y abajo (45°), boca abierta al máximo, patas
colgando, apoyadas y recogidas aleteando, y el pico de los trucos (rugido, fuego, voltereta,
comer, curva cerrada). Resultado de la E1 en `renders/dragon_v2_e1/poses/poses.json`; resumen en
la sección de abajo. Se compara contra el planeo del juego (umbrales: atraviesa 0.3 celdas, junta
1.0, hueco 0.2).

**E1 rediseñada (2026-10-17):**

- **Ninguna pieza se separa en ninguna pose** (alas incluidas: las tejas siguen una sobre otra).
- **Limpias (19 de 24; el borrador tenía 16):** el aleteo entero al máximo del juego (1.36 rad, 24
  fases), aletazo arriba y abajo, los cinco trucos (rugido, fuego, voltereta, comer, curva
  cerrada), boca abierta, patas colgando, apoyadas y recogidas, cola arriba y abajo, y ahora
  también el cuello a 30° y a 60° a cada lado, mirando arriba y abajo 45° (cuello en arco y
  cabeza por encima de los hombros).
- **Rugido enojado (2.24 × la amplitud, 1.79 rad, 103°):** igual que antes, las alas pasan la
  vertical y se cruzan entre ellas y con el cuerpo, el cuello y las patas, arriba y abajo. Ningún
  modelo rígido lo aguanta: conviene que `Dragon/Cuerpo` limite la amplitud a ~1.4 rad (pedido a
  la sesión de comportamiento).
- **Picada:** al plegar las alas hacia atrás (1.6 rad sumados en la punta), el Ala3 queda 0.49
  celdas dentro del Ala1: se ve como el ala doblada sobre sí misma.
- **Cola enroscada (0.6 rad por segmento) y en S (±0.45/0.6):** el Cola1 y el Cola2 entran en el
  muslo (0.6-1.0) y la pala lo toca (0.5). Son 3-6 veces lo que dobla la cola en el juego (curva
  cerrada, limpia).

## Pasos

1. **Herramientas** (hecho): `--criatura` en el armador común, poses y rig del dragón. El
   Minotauro E1 sale idéntico (`estadisticas.json`, `poses.json` y `rig.json`).
2. **Bloqueo de la E1** (hecho): `dragon_v2_e1_geometria.py`, renders en
   `renders/dragon_v2_e1/` (frente, perfil, tres cuartos, atrás, arriba, abajo y diagnóstico) y
   poses en borrador. **Rediseño "más dragón"** (hecho, 2026-10-17): el borrador se leía como
   pájaro o lagartija (alas de plumas, cabeza de rana, sin cuernos, cuello corto); ahora cabeza con
   hocico, cuernos y cejas, cuello alzado, alas de murciélago, púas y cola en pala. 5,107
   triángulos. **Aprobación de los renders.**
3. **E2, E3 y E4 en paralelo:** una sesión por etapa copia la E1 a `dragon_v2_e<n>_geometria.py`
   con su módulo, paleta y piezas propias; bloqueo con renders, alineación de las cuatro lado a
   lado (adaptar `minotauro_v2_alineacion.py` a `--criatura`), poses extremas.
4. **Rig y FBX** de las cuatro (`rig_dragon_v2.py --etapa <n>` → `assets/blender/DragonMarinoE<n>_v2.fbx`).
   E1 hecho: `assets/blender/DragonMarinoE1_v2.fbx`, `assets/textures/DragonMarinoE1_v2_color.png`
   y `assets/blender/dragon_v2/e1_rig.blend` (`renders/dragon_v2_e1/rig/rig.json`): 32 huesos (30
   que deforman), un hueso por vértice, la malla movida por los huesos coincide con las piezas
   rígidas en las 24 poses (error máximo 0.000008 celdas) y mide 9.89 × 9.9 × 7.43 studs (con
   el rediseño: cabeza y cuernos más altos).
5. **Studio:** importar a mano con "Mantener huesos de influencia cero" a
   `ServerStorage.DragonMarinoE<n>_v2`, IDs en `Assets` y `modelSuffix = "_v2"` en el Dragón
   (`Config/Giants.luau`): `GiantTemplates` lo publica con el nombre de siempre.
6. **Documentación:** `import_dragon_v2.md`, devlog, guía de estilo.
