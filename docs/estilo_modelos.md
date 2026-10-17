# Guía de estilo de los modelos de gigantes (v2)

Qué tiene que cumplir un gigante `_v2` para darse por bueno. Se aplica primero al
Minotauro (piloto, ver `docs/plan_minotauro_v2.md`) y después al resto.

## 1. Referencias

Base: las tres capturas de `referencias/` (2026-10-16), de un simulador de Roblox con
gigantes en corrales.

| Captura | Qué se toma |
|---|---|
| `184249` | Mamut lanudo con cristales de hielo; dinosaurio gris con placas de armadura y grietas naranjas; tiburón azul con aletas blancas. |
| `184315` | Tigre de pie con dientes de sable; dragón negro con cresta de fuego; gigante dorado con rayos. |
| `184323` | Paladín alado blanco y oro con lanza que brilla; dragón verde con aura de espirales y humo; camello. |

**Lo que comparten:**

1. **Silueta que se lee de lejos.** Formas grandes y exageradas (hombros, cabezas, cuernos,
   placas) que se reconocen a 100 studs y en un teléfono.
2. **Masas facetadas.** Bloques biselados y planos grandes, no superficies lisas de
   escultura realista. El detalle va en la textura (el patrón de "studs" de Roblox), no en
   la geometría.
3. **Dos o tres colores por bicho, con un acento que brilla.** Cuerpo en un tono medio,
   panza o placas en un tono claro y un acento emisivo (hielo cian, lava naranja, oro, verde
   tóxico).
4. **VFX que hacen la mitad del trabajo.** Auras, rayos, chispas, humo y espirales alrededor
   del modelo; brillo Neon en ojos, grietas y armas.
5. **Proporciones de juguete.** Cabeza y manos grandes, patas gruesas, poses abiertas.

> **Estilo decidido (2026-10-16): bloques.** Como en las capturas: bloques, placas y cuñas,
> no formas orgánicas. Cada parte del cuerpo es una pieza rígida (ver sección 3).

> Las capturas son de otro juego. `referencias/` no está en git y conviene que siga así:
> el repositorio es público.

## 2. Paleta del Minotauro

Valores en sRGB, sacados de los colores lineales de `minotauro_e1.py` y
`minotauro_etapas.py` (la v2 parte de ellos para no cambiar la identidad).

| Uso | E1 becerro | E2 joven | E3 adulto | E4 forma final |
|---|---|---|---|---|
| Pelaje | `#8B5230` | `#7C462B` | `#5D3521` | `#381F19` |
| Pelaje oscuro (mechón, pezuñas) | `#522F1D` | — | — | — |
| Panza y hocico | `#E5BC8E` / `#EDBCA6` | `#D7AA7C` | `#BC8E65` | `#6F4535` |
| Acento emisivo | — | ojos ámbar | ojos ámbar | lava `#FF9938` (ojos y grietas) |

Comunes a todas las etapas:

| Uso | Color |
|---|---|
| Oro (aros, hebillas, puntas de cuerno, hombreras) | `#FFCE61` |
| Marfil (cuernos) | `#EFE2C5` |
| Cuero / cuero rojo (cinturón, tirante, faldón) | `#613C27` / `#7C2C27` |
| Nariz y orejas por dentro | `#EA999B` |
| Boca / lengua | `#893038` / `#ED8995` |

Reglas:

- **Progresión de valor:** cada etapa más oscura que la anterior y con más acento. E4 es
  casi negro para que la lava contraste.
- **Saturación alta, sin negro puro ni blanco puro** en superficies grandes (la luz de
  Roblox los aplana).
- **Albedo sin luz horneada** (`blender-pipeline.md`). Sí se permite oclusión ambiental
  suave multiplicada en los pliegues (máx. 25 % de oscurecimiento): en Roblox los modelos
  actuales se veían planos y oscuros.
- El acento emisivo sale del **color** de la textura más un efecto en Roblox (Neon o
  `PointLight`); la `SurfaceAppearance` no tiene canal de emisión.

## 3. Criterios de calidad del modelo

Valores aprobados el 2026-10-16. Esta sección es la única referencia de topología y tamaño.

### Cuadrícula

- **Celda de 0.1 BU** (unidades de Blender). Todo bloque mide un número entero de celdas
  en cada eje, y sus caras caen sobre la cuadrícula.
- **Cuñas** con pendiente 1:1, 1:2 o 2:1 (en celdas). Nada de ángulos libres.
- **Bisel de 0.012 BU, un solo segmento**, en las aristas exteriores. Sin redondeo orgánico.

### Escala

Alto por etapa en veces el alto del jugador (5.5 studs; `stageHeightsInPlayers` y
`playerHeightStuds` de `Config/Giants.luau`, comprobado el 2026-10-16). **Es global:**
la misma tabla vale para los cinco gigantes (Orca, Minotauro, Dragón marino, Zorro de agua y
Orca fantasma), no por monstruo:

| Etapa | Jugadores | Studs | BU |
|---|---|---|---|
| E1 | 3 | 16.5 | 3.1 |
| E2 | 8 | 44 | 8.3 |
| E3 | 15 | 82.5 | 15.5 |
| E4 | 30 | 165 | 31.0 |

- **Escala única de exportación: 5.32 studs por BU**, la misma para las cuatro etapas,
  aplicada una sola vez y con las transformaciones aplicadas (escala y rotación).
- La escala usada se registra en `docs/import_minotauro_v2.md`.

### Topología

- **Cada parte del cuerpo es una pieza rígida** (cabeza, mandíbula, torso, brazos,
  piernas, cola, orejas, faldón…), formada por bloques, placas y cuñas.
- **Juntas:** las piezas se solapan, o una **placa de unión** tapa la junta en hombros,
  codos, cadera y rodillas. No se exigen bucles de aristas por articulación.
- **Simetría en X** exacta (se modela medio cuerpo y se espeja).
- **Presupuesto de triángulos:** E1 hasta **8,000**. E2, E3 y E4: **por definir**
  (se pregunta antes de modelar cada una; no se asume ningún valor).
- **Sin vértices sueltos ni normales invertidas.** Las caras internas entre bloques
  solapados se permiten dentro de una pieza si no se ven.

### UVs

- **Unwrap por costuras**, no Smart Project. Costuras escondidas: por dentro de brazos y
  piernas, debajo de la panza, detrás de los cuernos, en la línea del cinturón.
- **Densidad de texels pareja:** la cabeza puede tener hasta 1.5x la del cuerpo (se ve más);
  nada por debajo de 0.7x.
- **Margen mínimo de 8 px a 1024** entre islas (evita sangrado al reducir mipmaps).
- **Sin solapamientos**, salvo el lado derecho espejado sobre el izquierdo si la textura
  no tiene asimetrías (decidir por pieza; las letras y marcas no se espejan).
- Aprovechamiento del atlas ≥ 70 %.

### Bake a 1024

- Mapas: **color, normal (tangente, OpenGL, que es lo que usa Roblox) y rugosidad**.
  Metal solo si hay oro (máscara binaria). Los cuatro a **1024×1024**.
- Del modelo de alto detalle (mismo volumen) a la malla final, con **jaula** (cage) para
  que la proyección no tome superficies vecinas (dedos, cuernos, entrepierna).
- **Sin artefactos**: costuras invisibles a 3 m en el render de revisión, sin manchas en
  los bordes de las islas (relleno de 16 px), sin normales "cortadas" en las costuras.
- Comprobación en Studio: la textura se ve igual que en Blender con la luz del cráter
  (de día y con la hora propia del volcán).

### Poses extremas

Cada etapa se prueba en estas poses antes de exportar (render de cada una). Se revisa
que **las piezas no se separen ni se atraviesen de forma visible**; ya no se revisa la
deformación de la malla.

| Pose | Qué no puede pasar |
|---|---|
| Brazos arriba (músculo, 150°) | hueco visible en el hombro; brazo que atraviesa la cabeza |
| Brazos adelante y cruzados | antebrazo que atraviesa el pecho |
| Codo doblado 140° | hueco en el codo que la placa de unión no tapa |
| Rodilla doblada 120° (salto agachado) | hueco en la rodilla; muslo que atraviesa la pierna |
| Pierna arriba 90° (pisotón) | pierna que atraviesa el faldón o se separa de la cadera |
| Cuello: mira arriba, abajo y 60° a cada lado | cabeza que se separa del torso o lo atraviesa |
| Mandíbula abierta al máximo (rugido) | hueco entre mandíbula y cabeza visible desde el costado |
| Cola en S y levantada | segmentos separados o metidos uno en otro |
| Torso echado atrás (rugido) y adelante (comer) | torso que se separa de la cadera |

Reglas de pesos:

- **100 % por pieza: un solo hueso por vértice**, sin mezcla en las articulaciones.
  Reemplaza al límite de 4 influencias.
- Las piezas chicas (cuernos, aros, ojos, pezuñas) van al hueso de la pieza que las lleva.

### Por confirmar (no afectan a E1)

- Alto final y articulaciones de E2..E4 en Blender (viven en `.blend` fuera del repo). En
  Studio, las MeshPart importadas miden 3.34, 3.91, 4.19 y 4.42 studs de alto (E1..E4),
  pero eso no da las articulaciones.
- Datos que viven solo en Studio y no se revisaron aún: pivote y atributos de cada Model.
- Discrepancia de triángulos de los modelos actuales: Studio confirma 17,998 / 18,638 /
  19,376 / 19,874 (E1..E4); queda por confirmar de dónde salen los 9.5k de los logs.
- Si `tools/blender/minotauro.py` (sin huesos) está obsoleto.
- Squash y stretch escalando huesos en Roblox (por eso se hace con la pose, sección 4).
- Cómo se importan en Studio los clips de huesos desde FBX.

## Estado del Minotauro en Studio

Revisado el 2026-10-16 por el MCP de Studio (`PescaYAlimentaGigantes.rbxl`, modo Edit, solo
lectura: `search_game_tree`, `script_grep`, `inspect_instance` y un conteo de caras en
memoria con `EditableMesh`, sin cambiar nada del lugar).

- **El juego usa el Minotauro real, no la orca teñida.** `ServerStorage` tiene
  `MinotauroE1..E4` (Model con una MeshPart del mismo nombre, `SurfaceAppearance` y 25
  huesos desde `Raiz`). El servidor (`Server.GiantTemplates`) copia `<modelBase>E<n>` a
  `ReplicatedStorage.ModelosGigantes` y solo avisa "el cliente usará la orca teñida" si no
  encuentra ninguno; el cliente (`Client.Giant.GiantTemplates.templateFor`) usa la orca con
  `STAND_IN_TINTS.Minotauro` solo si no hay modelo propio de ninguna etapa.
- El comentario de `inRoulette` en `Config/Giants.luau` ("usa la orca teñida") está
  desactualizado.
- Los MeshId coinciden con `Assets.Meshes`:

| Etapa | MeshId | Triángulos | Huesos | Tamaño de la MeshPart (studs) |
|---|---|---|---|---|
| E1 | `138675592345337` | 17,998 | 25 | 1.80 × 3.34 × 1.66 |
| E2 | `91533993938693` | 18,638 | 25 | 1.90 × 3.91 × 1.65 |
| E3 | `84011204972654` | 19,376 | 25 | 2.06 × 4.19 × 1.66 |
| E4 | `105475430016255` | 19,874 | 25 | 2.22 × 4.42 × 1.67 |

- `ServerStorage.Respaldos` guarda versiones anteriores: `MinotauroE1_suelto`,
  `MinotauroE1_v1` y `MinotauroE2_viejo`..`MinotauroE4_viejo`.

## 4. Criterios de animación

Las animaciones con keyframes cubren las **acciones principales**. Lo continuo
(respirar, mirar, la cola) sigue siendo por código y se suma encima.

### Principios (todos obligatorios)

| Principio | Cómo se aplica al Minotauro |
|---|---|
| **Anticipación** | Antes de cada acción, un movimiento contrario: se agacha antes del salto, levanta la pata y se echa atrás antes del pisotón, toma aire (pecho arriba, cabeza atrás) antes del rugido. Mínimo 20 % de la duración. |
| **Squash y stretch** | Con huesos no se escala la malla (Roblox no escala huesos de forma fiable: **por confirmar**); se simula con la pose: aplastarse = rodillas dobladas + columna curvada + cabeza hundida; estirarse = todo extendido, brazos arriba, cola recta. Al caer del salto: aplastado 2-3 cuadros, luego rebote. |
| **Acción secundaria** | Orejas, cola, mechón y borla siguen al cuerpo con retraso (follow-through y overlap): 2-4 cuadros por hueso de la cadena. La mandíbula se sacude al aterrizar. |
| **Arcos** | Manos, cabeza y punta de la cola trazan curvas, no líneas rectas. Se revisa con el trazado de movimiento de Blender. |
| **Lento al entrar y al salir** | Curvas Bézier, nada lineal salvo los impactos (el cuadro del golpe va sin suavizar). |
| **Peso por etapa** | El becerro es rápido y rebota; la E4 tarda más, con anticipación más larga y casi sin rebote. Mismo clip, distinto tiempo, o un clip por etapa si el resultado lo pide (ver plan). |
| **Pose clara** | La silueta de cada pose clave se lee en negro sobre blanco. |

### Acciones con keyframes (Minotauro)

Son las que hoy hacen `Trucos.luau`, `Caminar.luau` y `Pose.feeding`:

| Clip | Duración (E1 → E4) | Bucle | Evento al que se engancha el VFX |
|---|---|---|---|
| `Caminar` | 0.9 → 1.6 s por ciclo | sí | `step` en cada pisada |
| `Comer` (inclinarse, estirar los brazos, masticar) | 1.2 s, bucle de mordida | sí | `bite` |
| `Pisoton` | 2.4 s | no | `stomp` |
| `Rugido` | ~2.5 s | no | `roar` |
| `Musculo` | ~2.4 s | no | `flex` |
| `Baile` (E1-E2) | ~3 s | no | `happy` |
| `Rascarse` | ~2.5 s | no | — |
| `Salto` (E1-E3) | ~2 s | no | `land` |
| `Reposo` (respirar y mecerse) | 4 s | sí | — (opcional: puede seguir por código) |

Los tiempos exactos de cada evento se anotan en el clip como marcadores con el mismo
nombre del evento, y el código los lee (`GetMarkerReachedSignal`) en lugar de los `at`
fijos de `Trucos.luau`.

## 5. VFX en Roblox

Lo que acompaña a los clips (todo respeta el modo rápido y los gráficos bajos):

- **Acento permanente:** ojos (todas las etapas) y grietas de lava (E4) con brillo; E4 con
  brasas que suben y una luz naranja tenue.
- **Por evento:** `stomp` (onda en el agua, polvo, grieta en el suelo y temblor), `roar`
  (onda de aire, vaho, temblor), `land` (salpicadura grande), `step` (salpicadura chica),
  `flex` (destellos dorados y brillo en el oro), `happy` (corazones).
- **Al evolucionar:** columna de luz y partículas al pasar de etapa.
- Texturas de partículas propias (`tools/particulas/`) y colores de la paleta de arriba.
