# Plan: Dragón marino v2 (bloques)

Rehacer el Dragón marino E1..E4 en el estilo de bloques del Minotauro v2
(`docs/plan_minotauro_v2.md`, `docs/estilo_modelos.md`): bloques, placas y cuñas sobre la
cuadrícula, bisel de 0.12 módulos, una pieza rígida por hueso, animación solo por código.

**Estado: las cuatro etapas hechas y aprobadas (2026-10-17), rediseño "referencia".** Falta
importarlas a Studio (paso 5).

Decisiones del usuario: guarida volcánica de lava, llega en pose de **planeo** (como espera
`Dragon/Rig`) y presupuesto de triángulos de 8k / 10k / 12k / 15k. El primer diseño era de **mar y
fuego** (turquesa que se oscurece); el usuario lo cambió por una **referencia propia** (un dragón
oscuro estilo wyvern de alas enormes, con brillo de brasa) **con toques marinos** (ojos, aletitas y
la aleta de la cola en turquesa). La referencia no se sube al repositorio. Las cuatro etapas se
hicieron en paralelo con una guía común (paleta, proporciones y rig; resumida abajo). Se dejaron
así a propósito, aunque las alas no dominan tanto como en la referencia (el juego escala al dragón
por su lado más largo: alas más anchas achicarían el cuerpo).

## Escala y módulo

El dragón **se mide por su dimensión más larga**: `GiantTemplates` escala a los gigantes con
alas para que su lado más largo mida `Dragon.LENGTH` (0.6) veces el alto de la etapa. En el
rediseño la dimensión más larga es la **envergadura** (36 módulos; 32 en la E2) y el largo queda
igual o un poco menor.

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

Casi negro / marrón oscuro con brillo de brasa abajo (vientre, membrana, puntas de las púas), más
oscuro en cada etapa; ~15% de turquesa marino. Sin negro ni blanco puros en superficies grandes.

| Uso | E1 cría | E2 joven | E3 adulto | E4 anciano |
|---|---|---|---|---|
| Cuerpo | `#5A3C30` | `#43302A` | `#2E211D` | `#1A1314` |
| Lomo, escamas | `#462E25` | `#33241F` | `#221816` | `#110C0D` |
| Vientre y pecho (placas) | `#D9864C` | `#C8693A` | `#B4502C` | `#8E3A22` |
| Membrana | `#6E3A2C` | `#5A2E24` | `#47231C` | `#2E1714` |
| Borde de membrana y venas | `#C8643A` | `#D2602E` | `#E0622A` | lava `#FF9938` |
| Púas (base / punta) | `#3A2620` / `#FF9A4A` | `#2E1F1A` / `#FF8A3D` | `#221714` / `#FF7A2E` | `#150F0F` / `#FFB050` |
| Cuernos, garras, dientes | `#E8DCC0` | `#DCCDAE` | `#CDBB98` | `#BFA982` |
| Ojos | `#3FE6D2` | `#3FE6D2` | `#3FE6D2` | `#7FFFE8` |
| Turquesa (aletas, franjas) | `#2FB9A2` | `#1F9A93` | `#16808A` | `#1C6A73` |
| Grietas de lava | — | — | pecho `#FF7A2E` | vetas continuas `#FF9938` / `#FFE2A0` |

El brillo del fuego en Roblox sale del color más Neon o `PointLight` (no hay canal de emisión).

## Qué tiene cada etapa

| Etapa | Piezas propias |
|---|---|
| **E1 cría** | La referencia en chiquito: cabeza en cuña de 8 (hocico que baja y termina en punta, narinas, sonrisa con colmillitos, garganta de brasa), ojos turquesa de 3×3 con pupila en rendija, ceja en cornisa, cuernitos marfil hacia atrás, aletitas turquesa. Cuello en Γ con placas de borde turquesa, pecho hondo, cadera angosta, púas romas de punta encendida, cola de látigo con abanico de tres púas sobre aleta turquesa, delanteras finas y traseras de muslo grueso. Alas: brazo grueso, pulgar marfil, dedo 1 con gancho, tres festones cóncavos y franja de brasa en el borde. 6,796 triángulos; 9.9 × 9.32 × 6.33 studs. `dragon_v2_e1_geometria.py`, `_cabeza.py`, `_alas.py`. |
| **E2 joven** | Cabeza en cuña con cráneo de 4, ceja marcada, ojos turquesa, colmillos, cuernos medianos hacia atrás, aletitas turquesa. Cuello en arco con placas de brasa y franja turquesa, púas filosas con la mitad de brasa. Alas en tejas con tres arcos cóncavos hondos, puntas en gancho y franja de brasa en todo el borde (`feston()`). Cola de látigo con abanico y aleta turquesa. 6,814 triángulos; 26.4 × 25.6 × 15.7 studs. `dragon_v2_e2_geometria.py`, `_alas.py`. |
| **E3 adulto** | La referencia tal cual: cabeza en cuña de 6, cuernos pegados hacia atrás, corona de púas, ojos turquesa chicos, mandíbula de brasa. Cuello en S de 7, pecho hondo con placas y grietas metidas, cadera angosta, púas densas encendidas. Alas barridas: muñeca alta con pulgar en gancho, dedos en relieve de brasa, festones hondos con ganchos y borde de brasa (`borde()`), membrana hasta la cadera. Cola de 14 con abanico encendido y aleta turquesa. 7,282 triángulos; 49.5 × 48.1 × 21.9 studs. `dragon_v2_e3_geometria.py`, `_alas.py`. |
| **E4 anciano** | Acorazado: cada parte es un núcleo de lava envuelto en placas de una celda y las grietas son vetas continuas en las juntas (`acorazado()` en `dragon_v2_e4_formas.py`); una veta va de la garganta a la punta de la cola. Corona de cuernos, ojos `#7FFFE8`, boca con costura de lava, aletitas turquesa. Alas con la membrana en celdas (festones en escalones, borde de lava, ganchos marfil). Cola con abanico de cinco púas y aleta `#124A52`. 10,908 triángulos; 99 × 96 × 52.1 studs. `dragon_v2_e4_geometria.py`, `_cabeza.py`, `_alas.py`, `_formas.py`. |

## Contrato de huesos (32) y articulaciones

El de `tools/blender/rig_dragon.py`, el que usan `Dragon/Rig` y `Dragon/Pose`:

    Raiz > Cadera > Pecho > Cuello1 > Cuello2 > Cabeza > Mandibula, Boca
                    Cadera > Cola1 > … > Cola6
                    Pecho > Ala{Izq,Der}1 > 2 > 3
                    Pecho > Brazo > Antebrazo > Mano (Izq, Der)
                    Cadera > Muslo > Pierna > Pie (Izq, Der)

Cada etapa tiene sus articulaciones en su `dragon_v2_e<n>_geometria.py` (y medidas en
`renders/dragon_v2_e<n>/rig/rig.json`); la tabla de abajo es la de la primera E1 y sirve de
ejemplo. En todas, la Cadera va a la altura de la Cabeza (adelante = −y exacto).

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

**Rediseño "referencia" (2026-10-17):** en las cuatro, adelante = −y exacto y `neutral` ≈ 0
(diedro modelado ~0.1); ninguna pieza se separa; el aleteo entero al máximo del juego sale
limpio. Limpias: E1 19/24, E2 20/24, E3 20/24, E4 20/24. Fallan solo las conocidas: rugido enojado
(el juego ahora limita el aleteo a 1.4 rad en `Dragon/Alas`), picada (alas plegadas que se cruzan
sobre el lomo, ≤ 0.7 celdas) y cola enroscada o en S (contra el muslo o la cadera). Juntas nuevas:
el muslo gira detrás del pecho (al colgar no entra), el pulgar corto (con el cuello a 60° el hocico
no toca la muñeca), la cadera una celda más baja que el hombro (la membrana pasa por encima al
bajar el ala), y en la E4 las piezas acorazadas se tocan cara con cara (si se solapan, las caras
internas de la cáscara quedan en el mismo plano).

## Pasos

1. **Herramientas** (hecho): `--criatura` en el armador común, poses y rig del dragón. El
   Minotauro E1 sale idéntico (`estadisticas.json`, `poses.json` y `rig.json`).
2. **Bloqueo de la E1** (hecho) y rediseño "más dragón" (hecho): rechazados luego por el usuario.
3. **Rediseño "referencia" de las cuatro etapas en paralelo** (hecho, 2026-10-17): una sesión por
   etapa con una guía común; alineación con `minotauro_v2_alineacion.py --criatura dragon`
   (`renders/dragon_v2_alineacion/`).
4. **Rig y FBX** de las cuatro (hecho): `rig_dragon_v2.py --etapa <n>` →
   `assets/blender/DragonMarinoE<n>_v2.fbx` y `assets/textures/DragonMarinoE<n>_v2_color.png`;
   32 huesos (30 que deforman), un hueso por vértice, error máximo ≤ 0.00002 celdas.
5. **Studio:** importar a mano con "Mantener huesos de influencia cero" a
   `ServerStorage.DragonMarinoE<n>_v2`, IDs en `Assets` y `modelSuffix = "_v2"` en el Dragón
   (`Config/Giants.luau`): `GiantTemplates` lo publica con el nombre de siempre.
6. **Documentación:** `import_dragon_v2.md`, devlog, guía de estilo.
