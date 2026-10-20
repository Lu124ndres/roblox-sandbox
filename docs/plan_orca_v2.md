# Plan: Orca v2 (orca monstruo de bloques)

Estado: **geometría de las 4 etapas aprobada (2026-10-20)**. Falta el rig, el FBX, la
importación y adaptar su movimiento (`Shared/Orca`, `OrcaSwim`).

Es la v2 de la Orca de siempre (`OrcaE1..E4_v2`), en el mismo estilo de bloques que el
Minotauro, el Dragón y el Zorro. Sale de una referencia del usuario (fuera del repo): se toma la
forma general.

## Rasgos (en orden)

1. Torpedo largo de anillos negro azulados que se escalonan hacia la cola.
2. Aleta dorsal alta, azul marino, echada hacia atrás con el borde de salida cóncavo.
3. Boca abierta: dos filas de dientes, interior rojo oscuro, mandíbula y garganta blancas.
4. Ojos: cuenca oscura con la pupila roja de Neon que pone el código (`GiantEyes`), cejas de
   enojo y la mancha de orca en cian que brilla.
5. Púas grises por todo el lomo, de la cabeza a la cola.
6. Pectorales largas que bajan hacia afuera, en dos tramos.
7. Cola en V, horizontal (de orca, no vertical de tiburón como en la referencia).
8. Detalles: branquias, puntos cian, cicatrices rojas, percebes y algas.

## Etapas

| | E1 cría | E2 joven | E3 adulta (maestra) | E4 anciana |
|---|---|---|---|---|
| Celda (BU) | 0.1 | 0.3 | 0.5 | 1.0 |
| Alto (módulos / studs) | 31 / 16.5 | 28 / 44.7 | 31 / 82.5 | 31 / 165 |
| Largo (módulos) | 50 | 54 | 64 | 63 (335 studs; el lago mide 380) |
| Triángulos (tope) | 3,856 (8k) | 3,996 (10k) | 4,676 (12k) | 10,988 (15k) |
| Cabeza (% del largo) | 34 % | 28 % | 23 % | 22 % |

- **E1 cría:** cabeza más grande que el cuerpo, ojos grandes, cuerpo corto con chaflán doble,
  panza blanca grande, dorsal baja y redondeada, dientes chicos y bultitos en vez de púas.
- **E2 joven:** la adulta más corta y clara; dorsal más baja, menos dientes, púas chicas, una
  cicatriz, un percebe y una alga.
- **E3 adulta:** la maestra (descrita arriba).
- **E4 anciana, la más terrorífica:**
  - acorazada, con grietas cian en las juntas de las placas;
  - colmillos largos en dos filas, uno roto;
  - dorsal desgarrada;
  - púas en hilera doble y en la cola, y garras en las pectorales;
  - tres arpones viejos con cabos rotos;
  - una herida con costillas, más percebes y algas largas.

Proporción alto:largo ≈ 1:2. La referencia es más larga (~1:2.5): se acortó para que la E4
entre en el lago del cráter.

## Paleta (sRGB)

| Uso | E1 | E2 | E3 | E4 |
|---|---|---|---|---|
| Cuerpo | `#2E3748` | `#232A38` | `#1B202B` | `#13171F` |
| Placas | `#3C4659` | `#323B4E` | `#2A3242` | `#232A36` |
| Dorsal y cola | `#2C4374` | `#243A66` | `#1E3054` | `#182746` |
| Cuenca del ojo | `#0A0C10` | `#0A0C10` | `#0A0C10` | `#0A0C10` |
| Brillo cian (Neon) | `#45E3FF` | `#45E3FF` | `#45E3FF` | `#5CF0FF` |

Comunes: mandíbula `#E4E8EE`, boca `#4E1520`, dientes `#EEE9DD`, cicatrices `#C0343C`,
percebes `#CFC2A8` y algas `#3E8040`. Además, en la E4: hueso `#D9D2BF`, arpón `#7C838E`,
óxido `#7A4A30` y cabo `#9C8460`.

## Archivos

- Geometría: `tools/blender/orca_v2_e<n>_geometria.py`, con `_cabeza.py` y `_cuerpo.py`; la E4,
  además, `_detalles.py`.
- Armado: `minotauro_v2_bloques.py -- --criatura orca --etapa <n>`, que guarda
  `assets/blender/orca_v2/e<n>_bloques.blend` y `renders/orca_v2_e<n>/`. Con
  `ENCUADRE_CAJA = True`, la cámara toma la caja entera porque la orca es el doble de larga que
  de alta.
- Alineación: `minotauro_v2_alineacion.py -- --criatura orca`, en `renders/orca_v2_alineacion/`.
  La fila sale de perfil.

## Piezas y huesos

Los mismos nombres que la Orca actual (`rig_orca.py`):
- con pesos: Cabeza, Mandibula, Pecho, Cola1..Cola5, Dorsal, Aleta{l}, Aleta{l}2 y
  AletaCola{l};
- sin pesos: Raiz, Boca, Espiraculo y `Ojo{l}Mira`.

`Ojo{l}Mira` va en el centro de la cara de la cuenca, con la cola a lo largo de su normal.
Mientras el modelo no tenga ese hueso, `GiantEyes` no le pone pupilas (`requiresBone` en
`UIConfig/GiantEyesData`). Con el rig hecho, hay que volver a correr `tools/blender/ojos_medir.py`
para que mida la malla exportada.

## Pasos que quedan

1. Rig, poses extremas (meta ≥ 19 de 24 limpias) y FBX de las 4 etapas.
2. El usuario importa los FBX (con "Mantener huesos de influencia cero"); se revisan, se pasan a
   `ServerStorage.OrcaE<n>_v2`, se cargan los IDs y se pone `modelSuffix = "_v2"`.
3. Adaptar `Shared/Orca` y `OrcaSwim` a los huesos nuevos (Cola1..Cola5, Aleta{l}2).
4. Volver a medir los ojos y probar las pupilas en Play.
