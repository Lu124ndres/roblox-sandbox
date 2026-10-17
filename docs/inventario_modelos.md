# Inventario de modelos de gigantes

Estado de los modelos **actuales** antes de rehacerlos con sufijo `_v2`. Este documento
solo describe lo que hay: no se modifica ningún modelo actual.

Fuentes leídas (2026-10-16): `src/shared/Minotauro/`, `src/shared/Config/Giants.luau`,
`src/shared/Assets/init.luau`, `src/shared/Assets/Textures.luau`,
`src/client/Giant/MinoStand.luau`, `tools/blender/minotauro*.py`,
`tools/blender/rig_minotauro*.py`, `assets/blender/render/log_Minotauro*.json`,
`docs/tareas_claude_code.md` y el historial de git.

Lo marcado **por confirmar** no aparece en esas fuentes: vive solo en el `.rbxl`
(`ServerStorage`) o en los `.blend` que no están en el repositorio. Se confirma por MCP
de Studio o de Blender en el paso 0 del plan (`docs/plan_minotauro_v2.md`).

---

## Minotauro

### Etapas y tamaños en el juego

`Config/Giants.luau`: `playerHeightStuds = 5.5`, `stageHeightsInPlayers = { 3, 8, 15, 30 }`,
`stageThresholds = { 0, 0.25, 0.5, 0.75 }`. `GiantBody` escala cada modelo con
`Model:ScaleTo` al alto que pide la etapa, así que el tamaño real del modelo importado no
importa.

| Etapa | Modelo en `ServerStorage` | Qué es | Empieza en | Alto en juego |
|---|---|---|---|---|
| E1 | `MinotauroE1` | becerro chibi | 0 % de la barra | 3 jugadores = 16.5 studs |
| E2 | `MinotauroE2` | joven, tirante de cuero | 25 % | 8 jugadores = 44 studs |
| E3 | `MinotauroE3` | adulto, hombrera con púas, puntas de oro | 50 % | 15 jugadores = 82.5 studs |
| E4 | `MinotauroE4` | forma final, pelaje negro con grietas de lava | 75 % | 30 jugadores = 165 studs |

Otros datos del gigante en `Config/Giants.luau`: `id = "Minotauro"`, `modelBase = "Minotauro"`,
`multiplier = 4`, `food = 600` (mínimo), `targetMinutes = 10`, `rouletteWeight = 30`,
`released = true`, `inRoulette = true`.

> Nota: el comentario de `inRoulette` dice "sin modelo de Meshy aún: usa la orca teñida".
> Está desactualizado: los cuatro modelos existen.

Alto del modelo en Blender (unidades = studs antes de escalar):

| Etapa | Alto en Blender | Fuente |
|---|---|---|
| E1 | ~3.1 | docstring de `minotauro_e1.py` ("parado en z = 0, ~3.1 de alto") |
| E2 | **por confirmar** | `minotauro_etapas.py` lo deforma (piernas x1.3, tronco x1.2); no anota el alto final |
| E3 | **por confirmar** | ídem (piernas x1.42, tronco x1.3) |
| E4 | **por confirmar** | ídem (piernas x1.5, tronco x1.36) |

### Huesos (contrato vigente)

Definidos en `tools/blender/rig_minotauro_e1.py` y `rig_minotauro.py` (diccionario `B`),
repetidos en `src/shared/Minotauro/Rig.luau` y en "Contrato de huesos del minotauro" de
`docs/tareas_claude_code.md`. Los cuatro modelos usan **los mismos nombres**.

```
Raiz                      (sin pesos)
└── Cadera
    ├── Columna
    │   └── Pecho
    │       ├── Cuello
    │       │   └── Cabeza
    │       │       ├── Mandibula
    │       │       ├── Boca          (punto, sin pesos)
    │       │       ├── OrejaIzq
    │       │       └── OrejaDer
    │       ├── BrazoIzq
    │       │   └── AntebrazoIzq
    │       │       └── ManoIzq
    │       └── BrazoDer
    │           └── AntebrazoDer
    │               └── ManoDer
    ├── MusloIzq
    │   └── PiernaIzq
    │       └── PieIzq
    ├── MusloDer
    │   └── PiernaDer
    │       └── PieDer
    └── Cola1
        └── Cola2
            └── Cola3
```

25 huesos: 23 deforman, `Raiz` y `Boca` no (`NODEFORM`). `Izq` = izquierda del personaje
(+X en Blender, -X en Roblox). Modelo parado, mirando a -Y en Blender / -Z en Roblox,
pivote en la base.

Articulaciones del becerro (`PUNTOS` en `minotauro_e1.py`, lado izquierdo, Blender):

| Punto | Coordenada | Usado por |
|---|---|---|
| cadera | (0, 0.02, 0.98) | cabeza de `Cadera` |
| columna | (0, 0.0, 1.32) | `Columna` |
| pecho | (0, -0.02, 1.66) | `Pecho` |
| cuello | (0, -0.03, 1.88) | `Cuello` |
| cabeza | (0, -0.06, 2.06)* | `Cabeza` |
| bisagra / mentón | (0, -0.16, 2.02)* / (0, -0.58, 1.93)* | `Mandibula` |
| boca | (0, -0.66, 2.02)* | `Boca` |
| hombro → codo → muñeca → mano | (0.45, 0, 1.76) → (0.63, 0.03, 1.4) → (0.69, -0.04, 1.1) → (0.71, -0.08, 0.86) | brazo |
| muslo → rodilla → tobillo → punta del pie | (0.27, 0, 0.98) → (0.29, -0.06, 0.54) → (0.29, 0.02, 0.17) → (0.29, -0.16, 0.04) | pierna |
| cola0..3 | (0, 0.38, 1.02) … (0, 0.71, 0.47) | `Cola1..3` |
| oreja → punta | (0.43, -0.02, 2.48)* → (0.78, 0, 2.36)* | `OrejaIzq` |

\* Antes de agrandar la cabeza: `H()` las escala x1.16 (E1) desde `(0, -0.04, 1.96)`.
En E2..E4 las articulaciones salen deformadas y se guardan en `scene["puntos"]` del
`.blend`; sus valores finales están **por confirmar** (el `.blend` no está en el repo).

Roll de todos los huesos: 0. Exportación FBX: `primary_bone_axis="Y"`,
`secondary_bone_axis="X"`, `axis_forward="-Z"`, `axis_up="Y"`, `add_leaf_bones=False`.

### Qué exige el código de cada hueso

| Requisito | Dónde |
|---|---|
| `Raiz`, `Cadera`, `Cabeza`, `BrazoIzq`, `BrazoDer` deben existir o el rig no se enlaza | `Minotauro/Rig.luau` (`Rig.bind`) |
| `OrejaIzq` y `BrazoIzq`, sin alas, para que `MinoStand` lo tome como minotauro | `client/Giant/MinoStand.luau` |
| `Boca` y `Cabeza` como puntos para los peces y el ícono de arriba | `Minotauro/init.luau` (`mouth`, `top`) |
| Todos los demás se giran por `Bone.Transform` cada cuadro | `Minotauro/Pose.luau` (`Pose.apply`) |
| La etapa sale del nombre: patrón `E(%d)$` | `Minotauro/Etapas.luau` (`forModel`) |

Los ejes de cada hueso se miden al enlazar (no importa cómo los orientó el importador).

### Mallas e IDs (`src/shared/Assets/`)

| Etapa | MeshId | Color | Normal | Triángulos según `Assets` | Triángulos según log |
|---|---|---|---|---|---|
| E1 | `rbxassetid://138675592345337` | `100759657454248` | `109198970088136` | 18k | 9,504 |
| E2 | `rbxassetid://91533993938693` | `85752100448730` | `126704727757248` | 18.6k | 9,506 |
| E3 | `rbxassetid://84011204972654` | `90468027558818` | `82219820175391` | 19.4k | 9,506 |
| E4 | `rbxassetid://105475430016255` | `108740223585461` | `96009656170909` | 19.9k | 9,506 |

Solo color y normal: sin rugosidad ni metal en la `SurfaceAppearance`.

> **Discrepancia por confirmar:** los `log_Minotauro*.json` (9.5k) probablemente son de la
> versión anterior sin huesos (`minotauro.py` + `exportar_todos.py`); los comentarios de
> `Assets` (18–20k) son de la versión con huesos. `blender-pipeline.md` fija un máximo de
> 10,000 triángulos por MeshPart, que los modelos actuales ya superan. El conteo real se
> confirma en Studio (`MeshPart` en `ServerStorage.MinotauroE<n>`).

### Archivos fuente

| Archivo | Qué hace | ¿Vigente? |
|---|---|---|
| `tools/blender/criaturas.py` | Bloques comunes (Skin, vóxeles, color por vértice) | sí |
| `tools/blender/minotauro_e1.py` | Becerro detallado: cuerpo por vóxeles + piezas rígidas; `PUNTOS` | sí |
| `tools/blender/minotauro_etapas.py` | E2..E4 deformando el becerro; guarda `scene["puntos"]` | sí |
| `tools/blender/rig_minotauro_e1.py` | E1: reduce, UVs (Smart Project 60°), hornea color y normal a 1024, esqueleto, pesos por calor, FBX | sí (E1) |
| `tools/blender/rig_minotauro.py` | Lo mismo para cualquier etapa (lee `scene["nombre"]` y `scene["puntos"]`) | sí (E2..E4) |
| `tools/blender/minotauro.py` | Versión anterior de 4 etapas, sin huesos | **probablemente obsoleta, por confirmar** |
| `assets/blender/MinotauroE1..E4.fbx` (+ `.fbm`) | FBX importados | sí |
| `assets/textures/MinotauroE1..E4_{color,normal}.png` | Texturas horneadas | sí |
| `alto.blend` y `*_rig.blend` | Modelo detallado y modelo con rig | **no están en el repo, por confirmar dónde viven** |

Commits: `757aa29` (E1), `04ac213` (E2), `238ab13` (E3 y E4).

### Cómo se hace hoy (y qué limita la calidad)

- **Malla:** bloques fusionados por vóxeles y decimate. Topología triangulada sin bucles de
  aristas en las articulaciones: al doblar codos y rodillas la malla se aplasta.
- **Piezas rígidas:** ojos, cuernos, aros, cinturón, faldón, pezuñas y borla van enteros a
  un hueso; el faldón no se mueve con las piernas.
- **Pesos:** calor automático de Blender, respaldo al segmento más cercano, máximo 4.
  Nadie los revisó en poses extremas.
- **UVs:** Smart Project automático con margen 0.003 (costuras visibles y texels desparejos).
- **Animación:** 100 % procedimental por código (`Pose.luau`, `Trucos.luau`,
  `Caminar.luau`), sumando giros a `Bone.Transform`. Sin keyframes.
- **Efectos:** `MinoStand` convierte eventos (`stomp`, `roar`, `land`, `step`, `flex`,
  `happy`) en sonido, salpicaduras, temblor, destellos y corazones.

### En Studio (por confirmar por MCP)

- Nombre exacto de la MeshPart dentro de cada Model (se espera `MinotauroE<n>`, como
  `NAME` en el script).
- Pivote del Model, atributos (`GiroY` u otros) y si la `Raiz` llegó al importar.
- Que `ServerStorage.Respaldos` tenga los modelos previos a W1 (dato de `tareas_claude_code.md`).
- Conteo real de triángulos y tamaño del FBX importado.

---

## Otros gigantes (para las fases siguientes)

Fuera del alcance de este piloto. Datos de referencia rápida:

| Gigante | Modelos | Huesos | Fuente |
|---|---|---|---|
| Orca | `OrcaE1..E4` | 17 (con `Boca`, `Espiraculo`, `Pecho`, aletas dobles) | `rig_orca.py`, `orcas.json` |
| Orca fantasma | `OrcaFantasmaE1..E4` | los de la orca | `tools/orca_fantasma.py` |
| Dragón marino | `DragonMarinoE1..E4` | 32 | `rig_dragon.py`, `dragon_E<n>_huesos.json` |
| Zorro de agua | `ZorroDeAguaE4_code` (prueba C7) | 63 | `rig_zorro_e4_code.py` |

Cada uno tendrá su sección aquí cuando le toque.
