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

> **Atención: las referencias no son "orgánicas".** El pedido habla de "modelado orgánico";
> las capturas muestran estilo **facetado / de bloques**. Hay que elegir una de dos (o la
> mezcla) antes de modelar. Ver la pregunta 1 en `docs/plan_minotauro_v2.md`. Esta guía
> propone la **mezcla**: anatomía continua que se deforma bien (orgánica en la malla) con
> planos marcados en músculos, cuernos y armadura (facetado en la lectura), y textura con
> relieve de estilo Roblox.

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

### Topología

- **Quads en todo el cuerpo** que deforma; triángulos solo en piezas rígidas y en zonas
  planas que no se doblan.
- **Bucles de aristas en cada articulación:** mínimo 3 bucles en hombros, codos, muñecas,
  cadera, rodillas, tobillos y cuello; 2 en cada segmento de la cola y en la base de las
  orejas. El bucle del medio queda **en** el eje de giro del hueso.
- **Bucles de la cara:** anillos alrededor de los ojos y de la boca, para que la mandíbula
  abra sin estirar el hocico.
- **Densidad pareja:** sin polos de 5+ aristas en zonas que se doblan; los polos van en
  zonas planas (espalda, pecho).
- **Simetría en X** exacta (se modela medio cuerpo y se espeja).
- **Presupuesto de triángulos por etapa: por decidir** (ver pregunta 3 del plan). El
  máximo de Roblox por MeshPart es 20,000; `blender-pipeline.md` dice 10,000. Propuesta:
  E1 8k, E2 10k, E3 12k, E4 15k (la E4 se ve de cerca y es la más grande).
- **Sin caras internas, vértices sueltos ni normales invertidas** (Mesh Analysis y
  "Select All by Trait" en cero).

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

### Deformación en poses extremas

Cada etapa se prueba en estas poses antes de exportar (render de cada una):

| Pose | Qué no puede pasar |
|---|---|
| Brazos arriba (músculo, 150°) | hombro que colapsa o atraviesa el cuello |
| Brazos adelante y cruzados | antebrazo que atraviesa el pecho |
| Codo doblado 140° | codo que se aplasta como una manguera (pérdida de volumen > 20 %) |
| Rodilla doblada 120° (salto agachado) | rodilla puntiaguda o muslo que atraviesa la pantorrilla |
| Pierna arriba 90° (pisotón) | ingle que se estira o faldón que atraviesa la pierna |
| Cuello: mira arriba, abajo y 60° a cada lado | papada que se hunde, cuernos que se deforman |
| Mandíbula abierta al máximo (rugido) | hocico que se estira, dientes que se doblan |
| Cola en S y levantada | segmentos que se pliegan sobre sí mismos |
| Torso echado atrás (rugido) y adelante (comer) | panza que atraviesa la cadera |

Reglas de pesos:

- **Pintados y revisados zona por zona**, partiendo del calor automático. Máximo 4
  influencias por vértice (límite de Roblox), normalizados.
- **Piezas duras** (cuernos, aros, hebillas, pezuñas, hombreras) al 100 % de un hueso,
  pero **pegadas** a la piel (sin huecos al moverse).
- **Faldón y tirantes** con pesos repartidos entre `Cadera` y los muslos, o huesos propios
  si se aprueban (ver plan).
- Corrector de volumen en codos y rodillas si hace falta: un bucle extra o forma de
  "codo de goma" con pesos 50/50 en el bucle central.

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
