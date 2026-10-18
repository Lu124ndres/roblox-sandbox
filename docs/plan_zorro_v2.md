# Plan: Zorro de agua v2

Rehacer el Zorro de agua en bloques, en cuatro etapas, siguiendo `docs/guia_crear_monstruo.md`.
Es el primer monstruo hecho con **olas de agentes paralelos** (guía, sección 12).

**Estado (2026-10-18):** terminado salvo la ola 4 (arreglos). Las cuatro etapas están en el
juego con su movimiento completo (ola 3), probadas en Play.

## Identidad

- Referencia del usuario: un zorro de agua de bloques con un abanico de colas como olas que
  rompen en espuma. Se toma la forma general, no un personaje con marca.
- Decisiones del usuario: **colores de la referencia** (azul y cian de agua, espuma blanca,
  ojos que brillan), **colas que crecen con la etapa** (1, 3, 6 y 9), hábitat de **agua con
  hielo** con **atardecer**, y las cascadas de lava de la isla siguen a la vista.
- Pedido especial: **"animaciones perfectas para la cola"**. Cada cola tiene 5 tramos y su propio
  sistema de animación (`Zorro/Colas`).

## Paleta (sRGB)

| Uso | E1 | E2 | E3 | E4 |
|---|---|---|---|---|
| Cuerpo | `#5CC8F2` | `#3DB4EC` | `#2A9BE0` | `#1F7FCF` |
| Claro (vetas) | `#8FE3F7` | `#6AD8F2` | `#4CCBEA` | `#3BB8E6` |
| Verde agua | `#6FE6D6` | `#55DDCF` | `#3FD6C6` | `#2FC8BC` |
| Pata / pata oscura | `#3D8FE0` / `#2F6FCC` | `#2A7FDA` / `#2460BE` | `#1E6FD0` / `#1A4FAE` | `#1858BC` / `#143E96` |
| Raíz de la cola | `#3F98E4` | `#2C88DC` | `#1F78D6` | `#1864C4` |
| Espuma | `#E6F7FF` | `#E6F7FF` | `#E6F7FF` | `#E6F7FF` |
| Hielo | — | — | `#BFF3FF` | `#BFF3FF` |

## Etapas

| | E1 cría | E2 joven | E3 adulto | E4 forma final |
|---|---|---|---|---|
| Celda (BU) | 0.1 | 0.3 | 0.5 | 1.0 |
| Alto (módulos / studs) | 31 / 16.5 | 28 / 44.7 | 31 / 82.5 | 31 / 165 |
| Colas | 1 | 3 | 6 | 9 |
| Triángulos (máx.) | 8k | 10k | 12k | 15k |
| Huesos | 36 | 46 | 61 | 76 |
| Triángulos reales | 3,940 | 4,604 | 7,604 | 10,332 |
| Poses limpias (`zorro_v2_poses.py`) | 20 de 29 | 19 de 29 | 24 de 29 | 23 de 29 |
| Estado | **aprobada** | **aprobada** | **aprobada** | **aprobada** |

Escala única de exportación: **5.32 studs por BU** (la del minotauro).

## Contrato de huesos

Los nombres que ya usa `src/shared/Zorro/`, así el código mueve la v2 sin cambios:
`Raiz` (sin pesos) > `Cadera` > `Columna` > `Pecho` > `Cuello1` > `Cuello2` > `Cabeza` >
`Mandibula`, `Boca` (sin pesos), `Oreja{l}` > `OrejaPunta{l}`, `Parpado{l}`;
`Pecho` > `Hombro{l}` > `Brazo{l}` > `Antebrazo{l}` > `Mano{l}`;
`Cadera` > `Muslo{l}` > `Pierna{l}` > `Tobillo{l}` > `Pie{l}`;
`Cadera` > `Cola<n>_1` > … > `_5`.
La E4 queda en 76 huesos, 6 más que el tope de la guía: excepción aceptada por las colas.

## E3 (maestra, aprobada el 2026-10-18)

- Archivos: `tools/blender/zorro_v2_e3_geometria.py`, `_cuerpo.py` y `_colas.py` sobre el armador
  común (`minotauro_v2_bloques.py -- --criatura zorro --etapa 3`); vistas con cámara abierta en
  `zorro_v2_vistas.py` (el encuadre del armador corta el abanico) y prueba de juntas en
  `zorro_v2_prueba_colas.py`.
- **Colas:** seis cadenas curvas. Cada tramo toma su dirección de la cuadrícula (A: vertical a
  1:2 a 1:1; B: 1:2 a 1:1 a 2:1 y la punta sube; C: 1:1 a 2:1 a horizontal y la punta se
  levanta), mide 4 o 6 de ancho (dos seguidos nunca iguales) y nace un paso adentro del
  anterior, también donde cambia la dirección. El paso hacia atrás crece de arriba hacia abajo (2,
  3, 4 celdas), así de perfil se abre como abanico. Veta clara a lo largo de cada tramo y, en la
  punta, una cresta con un labio que se enrula hacia arriba y afuera, con hielo.
- **Cara:** ojos de 2 celdas rasgados, marca en la frente, hocico en cuña con la parte de abajo
  blanca, mejillas simples. El párpado abierto es una ceja al ras; cerrado (bisagra en y −14,
  z 20) tapa el ojo.
- **Números:** 31 módulos, 7,258 triángulos, 0 caras coplanares, 0 normales invertidas. Prueba de
  juntas a 45°: 0 rendijas (peor despegue 0.81 celdas).
- **Lo que difiere de la referencia** (el usuario la aprobó así): el abanico es más bajo
  respecto del cuerpo (sube ~2.2 veces el lomo; la referencia, ~3), la cara se lee más dura y la
  cola de abajo remata en un rectángulo.

## Segunda vuelta: juntas y colas que no se cruzan (2026-10-18)

Con la E3 aprobada a la vista, `zorro_v2_poses.py` (la cuenta de `Zorro/Rig`, `Pose` y una
traducción de `Zorro/Colas` en `zorro_v2_colas_sim.py`) dio solo 7 de 29 poses limpias: las
colas vecinas compartían profundidad y se cruzaban hasta en reposo, y el muslo, el brazo y el
cuello chocaban con el torso. Reglas que salieron (están en el docstring de cada `_colas.py`):

- **Cada cola en su capa de profundidad:** si dos tramos de colas distintas se solapan en x-z,
  entre sus franjas en y queda al menos 1 celda. Lo mismo para dos tramos no seguidos de una
  misma cola (paso ≥ la mitad del hondo + media celda). Hondo de 3 o menos. Una cola y su espejo
  necesitan ≥ 2 celdas en x y 0.45 rad de hueco de reposo.
- **Colas gruesas (E1):** cada tramo nace 2 celdas por debajo de la punta del anterior y ningún
  tramo con hijo pasa de 8 de ancho.
- **Cuerpo:** junta Cadera/Columna adelante, cuña en el muslo, pata delantera con espiga de 1×1
  y cuñas, cuello bajo el cráneo, babero sin pasar el lomo, párpado de 3 celdas, oreja con cuñas.
- **Código** (commit 1d527e8): tope a la suma de pliegues (`FOLD_MAX` 1.2), hueco mínimo del 70 %
  del de reposo, una cola sola que baja por su costado al enroscarse, y los límites saben cuánto
  baja el cuerpo al sentarse.
- La E2 se exporta a 44 studs exactos (`rig_zorro_v2.py` escala por el alto de la etapa), no a
  los 44.7 de la escala única: en el juego no cambia nada.
- Pendiente en las tres: rascarse la oreja (la pata de la cría no llega) y las juntas de cola
  dobladas 45° todas a la vez.

## E4 (forma final, aprobada el 2026-10-18)

Nueve colas de cinco tramos: Cola1 central vertical, A (1:2), B (1:1), C (2:1) y D tendida a cada
lado, cada una en su capa de profundidad, que calcula `zorro_v2_e4_capas.py` a partir de los pares
de tramos cercanos en x-z. Con nueve colas las reglas se endurecen: una celda de aire hasta 2.5
celdas de distancia (tres en las puntas), y la cola cuya punta tapa a otra va detrás. Capas, de
adelante hacia atrás: A en el lomo, B en la grupa, y la central, C y D sobre una base de colas de
la Cadera hasta y 28. Cabeza de 5 × 10 y corona de tres cristales de hielo. Lo que el usuario
aprobó sabiendo: el abanico es hondo hacia atrás (en tres cuartos se lee como cola de pavo real) y
la losa de la base se ve de perfil. La cola D baja del piso al sentarse o dormir (conviene topar
su plegado en `Estados`). `zorro_v2_vistas.py` tiene fijo el centro de la cara de la E3: la E1, la
E2 y la E4 rehacen esa vista con su propio script.

Alineación de las cuatro: `renders/zorro_v2_alineacion/` (`minotauro_v2_alineacion.py -- --criatura
zorro`).

## Código y hábitat (ola 1, en el juego desde el 2026-10-17)

- `Zorro/Colas/`: resortes por junta, onda de la raíz a la punta sin bucles, reacción al cuerpo,
  estados con mezcla suave y límites. Único dueño de los huesos `Cola*_*` (decisiones.md).
- `Zorro/Etapas` (reconoce `_v2`), `Zorro/Guarida` (lugares del hábitat, de frente a la rampa).
- Hábitat: modo `"ice"` de `CraterMode` (`Ambient/Ice*`), atardecer de nieve (`SkyMoods.ice`).
- Sonidos (`Assets/Sounds`, `Audio/ZorroRecetas`) y VFX (`Effects/ZorroAgua` y sus partes),
  enganchados por `Giant/ZorroEventos`.

## Studio (2026-10-18)

Los cuatro FBX llegaron con 36, 46, 61 y 76 huesos (con `Raiz` y `Boca`), del tamaño del FBX, la
boca hacia −Z y sin anclar. En Play, `ModelosGigantes.ZorroDeAguaE<n>` publica el v2 con
`BaseHeight` 16.5, 44, 82.5 y 165; las cuatro etapas se ven en el cráter con sus colas, los
cubitos de agua y el contorno de enojo, comen sin errores y la consola queda limpia. La E4 ocupa
~287 × 287 studs y entra en el lago (380 de diámetro). El E4 anterior (`ZorroDeAguaE4_code`)
queda en ServerStorage sin uso.

## Movimiento (ola 3, 2026-10-18)

Un dueño por hueso (decisiones.md) y la pose como bus de números; contratos en `Zorro/Tipos`.

| Sistema | Módulos | Qué hace |
|---|---|---|
| Cuerpo | `Pose/` (`init`, `Tronco`) | Tronco, cuello y cabeza; `Pose.drop(pose, etapa)` = cuánto baja la base. |
| Patas | `Patas/` (`init`, `Plano`, `Ajustes`) | IK de dos huesos por pata, el paso de cuatro patas (`walk`, `walkPhase`), `sit`, `lie`, `curl`, `scratch`, `paw*`, `stretch`, `spine`, `pounce`; números medidos por etapa en `Ajustes`. |
| Mirada | `Mirada/` | Mira al jugador de este cliente (cono, inercia, episodios de mirar el agua, el cielo o su cola); `lookHold` la apaga. |
| Cara | `Cara/` (`Gestos`, `Parpadeo`, `Puntas`) | Parpadeo sincronizado, cinco gestos (`emo*`), puntas de las orejas con resorte. Solo con la cámara cerca. |
| Conductas | `Conductas/` | 16: rascarse, lamerse, sacudida, salto en picada, reverencia, bostezo, ladear, orejas, dormir, perseguir la cola, olfatear, centinela, abanico, aullido, probar el hielo y fuegos fatuos, con pesos por etapa. |
| Rutina | `init`, `Rumbo`, `Habitos`, `Rutina/` | Ciclos por etapa entre los lugares de `Guarida`, rutas en zigzag de cara a la puerta, conductas sin repetir, comer manda, evolución quieta. `Rutina.medir` y el modo de prueba `workspace:SetAttribute("ZorroConducta", "<nombre>")`. |
| Comer y evolución | `Comer/`, `Evolucion` | Bocados por etapa (la cría torpe, la forma final con calma y majestad), gestos y colas por gusto; evolución: se agacha, se sacude y aúlla con el abanico (`OWN_POSE`). |

Medido: poses en Blender E1 33/42, E2-E4 38/42 limpias (fallan solo las colas con todas las
juntas a 45° a la vez); de frente a la puerta 83/92/92/100 % con el tramo de espaldas más largo
en 1.5 s. Límites que no se pudieron: el rascado no llega a la oreja (rasca el cuello) y, al
enroscarse, la nariz no llega a la cola.

## Pasos que faltan

1. **Ola 4 (en curso):** témpanos menos regulares (`Ambient/IceParts`, `IceFloes`) y párpados de la
   E1 y la E2 que tapen el ojo cerrado (hoy queda ~28 % visible de frente): FBX nuevos que el
   usuario reimporta.
2. Guardar el lugar (Ctrl+S) y publicar (Alt+P).
