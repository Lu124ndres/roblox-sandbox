# Plan: Dragón marino v2 (bloques)

Rehacer el Dragón marino E1..E4 en el estilo de bloques del Minotauro v2
(`docs/plan_minotauro_v2.md`, `docs/estilo_modelos.md`): bloques, placas y cuñas sobre la
cuadrícula, bisel de 0.12 módulos, una pieza rígida por hueso, animación solo por código.

**Estado: bloqueo de la E1 hecho, esperando que apruebes el estilo.** Después, E2..E4 en
paralelo copiando la E1 (paso 3).

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
| **E1 cría** (hecha) | Cabeza grande (10 de ancho, más que el pecho), ojos de 4×4 con pupila y brillo, mejillas, colmillitos, cuello corto, aletas de abanico a los lados de la cabeza y cresta arriba, aletas bajas en el lomo, alas de 3 segmentos en tejas con una costilla oscura y garra en la punta, cola de 6 segmentos con aleta en horquilla, patitas recogidas. Fuego: solo la garganta (se ve al abrir la boca y un poco desde abajo). |
| **E2 joven** | Más largo de cuerpo y cola (la cabeza, proporcionalmente más chica), cuernitos detrás de las aletas de la cabeza, aletas del lomo más altas, alas con dos costillas y garra en el pulgar, ojos ámbar, brasas naranjas en las puntas de las aletas. |
| **E3 adulto** | Cuernos largos hacia atrás, colmillos, placas en el pecho, aletas del lomo en sierra, alas grandes con borde grueso, grietas de fuego en pecho, lomo y cola (que asoman o van metidas entre placas, como el Minotauro E4), la aleta de la cola con borde de fuego. |
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
| Cadera, Pecho | (0, 1, 9), (0, −1, 9) | |
| Cuello1, Cuello2, Cabeza | (0, −6, 9), (0, −8, 9), (0, −9, 9) | Cadera y Cabeza a la misma altura: `Rig.bind` toma "adelante" de la cadera a la cabeza y queda −y exacto |
| Mandibula, Boca | (0, −11, 6), (0, −18, 6) | borde de atrás de la mandíbula; la boca en la punta del hocico (de ahí sale el fuego) |
| Cola1..Cola6 | (0, 4, 7.5) … (0, 15, 7) | cada 2 celdas |
| AlaIzq1, 2, 3 | (4, −5, 11), (9.5, −4, 11), (14.5, −3, 12) | hombro en el borde de arriba del pecho; bisagras en la cara de contacto de las tejas |
| Brazo, Antebrazo, Mano | (2.5, −3.5, 5), (3, −2, 3), (3, 1, 2.5) | |
| Muslo, Pierna, Pie | (3, 3, 7), (3, 5, 4), (3, 7, 3.5) | |

Con estas articulaciones `Rig.bind` da adelante = −y, derecha = −x (en Blender) y arriba = z, y
`neutral` = −0.007 rad: el diedro modelado (0.093 rad, una celda más arriba por segmento) es
casi el 0.1 que pide el código, así el planeo del juego es el del modelo.

### Juntas (lo aprendido en la E1)

- **Alas en tejas:** cada segmento empieza una celda adentro del anterior y una celda más
  arriba; la bisagra va en la cara de contacto. Al aletear siempre queda uno sobre el otro (no se
  abre rendija) y de paso dan el diedro.
- **Cola:** cada segmento mete una cuña 1:2 dentro del anterior (de la misma sección hacia
  adentro): tapa la V que se abre al girar. Una caja metida no sirve si comparte una cara con el
  padre (caras coplanares).
- **Patas adentro de x = 4:** el ala gira por el hombro (x = 4) y al bajar no las toca.
- **Pecho corto (hasta y = −1):** el muslo, al colgar (quieto en el aire), gira hacia adelante y
  entraba en el pecho.
- Las piezas que se solapan son siempre más chicas en todos los lados que la que las tapa.

## Herramientas

| Script | Qué hace |
|---|---|
| `minotauro_v2_bloques.py --criatura dragon` | El armador común: carga `dragon_v2_e<n>_geometria.py`, toma su contrato (`CONTRATO`), se mide por el largo (`LARGO_JUEGO`) y suma las vistas de arriba y de abajo. Sin `--criatura`, el Minotauro igual que antes. |
| `dragon_v2_e<n>_geometria.py` | Lo propio de la etapa: módulo, paleta, piezas, articulaciones. |
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

**E1 (borrador, 2026-10-17):**

- **Ninguna pieza se separa en ninguna pose** (alas incluidas: las tejas siguen una sobre otra).
- **Limpias (16 de 24):** el aleteo entero al máximo del juego (1.36 rad, 24 fases), aletazo arriba
  y abajo, los cinco trucos (rugido, fuego, voltereta, comer, curva cerrada), boca abierta, patas
  colgando, apoyadas y recogidas, cola arriba y abajo, cuello a 30° y mirando abajo 45°.
- **Rugido enojado (2.24 × la amplitud, 1.79 rad, 103°):** las alas pasan la vertical y se cruzan
  entre ellas y con el cuerpo, arriba y abajo. Ningún modelo rígido lo aguanta: conviene que
  `Dragon/Cuerpo` limite la amplitud a ~1.4 rad (pedido a la sesión de comportamiento).
- **Picada:** el Ala1 roza la cadera 0.31 celdas al plegarse hacia atrás (se ve como el ala
  apoyada en el lomo).
- **Cola enroscada (0.6 rad por segmento) y en S (±0.45/0.6):** la aleta de la punta llega a la
  cadera y el Cola1 toca el muslo. Son 3-6 veces lo que dobla la cola en el juego (curva cerrada,
  limpia).
- **Cuello a 60°:** la cabeza (10 de ancho, cuello corto) entra en el hombro y el pecho; a 30°
  está limpia. El juego hoy gira la cabeza ~10°. **Mirar arriba 45°:** la nuca roza el Cuello1
  (0.44).

## Pasos

1. **Herramientas** (hecho): `--criatura` en el armador común, poses y rig del dragón. El
   Minotauro E1 sale idéntico (`estadisticas.json`, `poses.json` y `rig.json`).
2. **Bloqueo de la E1** (hecho): `dragon_v2_e1_geometria.py`, renders en
   `renders/dragon_v2_e1/` (frente, perfil, tres cuartos, atrás, arriba, abajo y diagnóstico) y
   poses en borrador. **Aprobación del estilo.**
3. **E2, E3 y E4 en paralelo:** una sesión por etapa copia la E1 a `dragon_v2_e<n>_geometria.py`
   con su módulo, paleta y piezas propias; bloqueo con renders, alineación de las cuatro lado a
   lado (adaptar `minotauro_v2_alineacion.py` a `--criatura`), poses extremas.
4. **Rig y FBX** de las cuatro (`rig_dragon_v2.py --etapa <n>` → `assets/blender/DragonMarinoE<n>_v2.fbx`).
   Probado con la E1 (`renders/dragon_v2_e1/rig/rig.json`): 32 huesos (30 que deforman), un hueso
   por vértice, la malla movida por los huesos coincide con las piezas rígidas en las 24 poses
   (error máximo 0.000007 celdas) y el FBX mide 9.9 × 9.9 × 3.85 studs. El FBX, la textura y el
   `.blend` del rig no se guardan hasta que apruebes el estilo.
5. **Studio:** importar a mano con "Mantener huesos de influencia cero" a
   `ServerStorage.DragonMarinoE<n>_v2`, IDs en `Assets` y `modelSuffix = "_v2"` en el Dragón
   (`Config/Giants.luau`): `GiantTemplates` lo publica con el nombre de siempre.
6. **Documentación:** `import_dragon_v2.md`, devlog, guía de estilo.
