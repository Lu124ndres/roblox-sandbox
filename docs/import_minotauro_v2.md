# Importación del Minotauro v2

Registro de la escala y las opciones con que cada etapa `_v2` sale de Blender y entra a
Studio. Reglas en `docs/estilo_modelos.md` (sección 3, "Escala").

## Escala

**Escala única: 5.32 studs por BU**, la misma para E1..E4, aplicada una sola vez al
exportar, con escala y rotación aplicadas en todos los objetos.

| Etapa | Alto del modelo (BU) | Alto esperado (studs) | Alto con 5.32 (studs) | Estado |
|---|---|---|---|---|
| E1 | 3.1 (medido por el script) | 16.5 | 16.5 (FBX) | en `ServerStorage.MinotauroE1_v2`; **el juego lo usa** (`modelSuffix`) |
| E2 | 8.4 (28 módulos de 0.3) | 44 | 44.71 (FBX) | en `ServerStorage.MinotauroE2_v2`; **el juego lo usa** |
| E3 | 15.5 (31 módulos de 0.5) | 82.5 | 82.5 (FBX) | en `ServerStorage.MinotauroE3_v2`; **el juego lo usa** |
| E4 | 31 (31 módulos de 1.0) | 165 | 165 (FBX) | en `ServerStorage.MinotauroE4_v2`; **el juego lo usa** |

El juego igual escala cada etapa al alto de `Config/Giants.luau` (`GiantBody` con
`Model:ScaleTo`); la escala de exportación sirve para que el modelo llegue a Studio con su
tamaño real y las cuatro etapas sean comparables.

## E1

- Fuente: `tools/blender/minotauro_v2_e1_geometria.py` (con `minotauro_v2_bloques.py --etapa 1`) → `assets/blender/minotauro_v2/e1_bloques.blend`.
- Renders de revisión: `renders/minotauro_v2_e1/` (frente, perfil, tres cuartos, atrás y
  `estadisticas.json`).
- Rig y FBX: `tools/blender/rig_minotauro_v2.py --etapa 1` → `assets/blender/MinotauroE1_v2.fbx`
  (rig en `assets/blender/minotauro_v2/e1_rig.blend`, revisión en
  `renders/minotauro_v2_e1/rig/`).
  - Una malla `MinotauroE1_v2` de 3,966 triángulos; cada pieza entera a su hueso (peso 1).
  - 28 huesos: los 25 del contrato más `FaldonFrente/Izq/Der` (hijos de `Cadera`); `Raiz` y
    `Boca` sin pesos. Cabeza de cada hueso en su articulación (`inventario_modelos.md`), roll 0.
  - Color: `assets/textures/MinotauroE1_v2_color.png` (256 px, un cuadro de 64 px por color de
    la paleta; las UVs de cada cara van al centro de su cuadro). Embebida en el FBX.
  - Escala 5.3226 aplicada a los vértices y a los huesos: el FBX mide 16.5 studs de alto, con
    la base en 0 y el frente hacia −Y de Blender.
  - Opciones: `apply_scale_options="FBX_SCALE_UNITS"`, `axis_forward="-Z"`, `axis_up="Y"`,
    `bake_space_transform=False`, `primary_bone_axis="Y"`, `secondary_bone_axis="X"`,
    `add_leaf_bones=False` (las mismas que `rig_minotauro_e1.py`).
  - Revisión: en las 20 poses de `minotauro_v2_poses.py` la malla deformada por los huesos
    coincide con las piezas rígidas (error máximo 0.00001 celdas). Reimportado en Blender:
    28 huesos, 26 grupos, la textura y 16.5 de alto.
- Importado a Studio el 2026-10-17 (a mano: el MCP de Studio no importa FBX) con Importar 3D →
  **"Mantener huesos de influencia cero"** (si no, se pierden `Raiz` y `Boca`), y movido a
  `ServerStorage.MinotauroE1_v2`. No reemplaza a `MinotauroE1`. Revisado por el MCP:
  - Model con la MeshPart `MinotauroE1_v2` (13.84 × 16.5 × 10.65 studs), 28 huesos, parado
    (arriba +Y), mirando a −Z, con el pivote en `Raiz` (la base); `BrazoIzq` en −X y `Boca`
    adelante.
  - MeshId `rbxassetid://122555252081745`, TextureID `rbxassetid://99845921194303` (la paleta;
    sin SurfaceAppearance), en `Assets.Meshes.MinotauroE1_v2` y `Assets.Textures.MinotauroE1_v2`.
- En el juego: `modelSuffix = "_v2"` en el Minotauro de `Config/Giants.luau`. El servidor
  (`GiantTemplates`) publica `MinotauroE1_v2` con el nombre `MinotauroE1`; las etapas sin v2
  (E2..E4) siguen con el modelo actual. Quitando esa línea vuelve todo al modelo actual.
  Probado en Play (2026-10-17): 28 huesos publicados, alto base 16.5, el faldón se levanta en
  el pisotón y la consola sin errores.
  - Mismas propiedades de la pieza que `MinotauroE1` (sin anclar y con colisión: el código lo
    ancla y se la quita al copiarlo); no tiene `AnimationController` y el código no lo usa.

## E2, E3 y E4

Modeladas a la vez el 2026-10-17 (una sesión por etapa, con las herramientas comunes; ver
`docs/devlog.md`). Fuente: `tools/blender/minotauro_v2_e<n>_geometria.py`; mismos scripts y
opciones de exportación que la E1 (`rig_minotauro_v2.py --etapa <n>`).

| Etapa | Bloques | Triángulos (tope) | Colores | FBX | Error del rig | Faldón: pisotón / 90° / caminata |
|---|---|---|---|---|---|---|
| E2 joven | 121 | 4,946 (10k) | 14 | `assets/blender/MinotauroE2_v2.fbx` | 0.00001 | 55° / 90° / 3° |
| E3 adulto | 107 | 4,276 (12k) | 14 | `assets/blender/MinotauroE3_v2.fbx` | 0.00002 | 58° / 91° / 0° |
| E4 forma final | 142 | 5,916 (15k) | 12 | `assets/blender/MinotauroE4_v2.fbx` | 0.00001 | 3° / 91° / 4° |

- Las tres: 28 huesos (26 que deforman), un hueso por vértice, sin caras coplanares ni normales
  al revés, ninguna pieza se separa en las 20 poses de `minotauro_v2_poses.py`.
- Medidas para el código en `src/shared/Minotauro/Medidas.luau` (de `medidas.json`).
- Las cuatro lado a lado: `renders/minotauro_v2_alineacion/` (`minotauro_v2_alineacion.py`).
- Importados a Studio el 2026-10-17 (a mano, con "Mantener huesos de influencia cero") y movidos
  a `ServerStorage.MinotauroE<n>_v2`. Revisados por el MCP: 28 huesos, parados, mirando a −Z,
  pivote en `Raiz`, `BrazoIzq` en −X y `Boca` adelante; IDs en `Assets.Meshes` y
  `Assets.Textures` (`MinotauroE<n>_v2`).
  | Etapa | MeshId | TextureID |
  |---|---|---|
  | E2 | `105048502299348` | `137284523253350` |
  | E3 | `112201493043935` | `97172953101798` |
  | E4 | `123237644499937` | `86563923351119` |
- Probado en Play: el servidor publica las cuatro v2 (alto base 16.5 / 44.7 / 82.5 / 165) y cada
  etapa anima a ~60 cuadros por segundo con sus trucos; la E3 hizo el pisotón con el faldón a
  67°; consola sin errores.
