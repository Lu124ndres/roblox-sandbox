# Importación del Minotauro v2

Registro de la escala y las opciones con que cada etapa `_v2` sale de Blender y entra a
Studio. Reglas en `docs/estilo_modelos.md` (sección 3, "Escala").

## Escala

**Escala única: 5.32 studs por BU**, la misma para E1..E4, aplicada una sola vez al
exportar, con escala y rotación aplicadas en todos los objetos.

| Etapa | Alto del modelo (BU) | Alto esperado (studs) | Alto con 5.32 (studs) | Estado |
|---|---|---|---|---|
| E1 | 3.1 (medido por el script) | 16.5 | 16.5 (FBX) | rig y FBX hechos; sin importar a Studio |
| E2 | — | 44 | — | sin modelar |
| E3 | — | 82.5 | — | sin modelar |
| E4 | — | 165 | — | sin modelar |

El juego igual escala cada etapa al alto de `Config/Giants.luau` (`GiantBody` con
`Model:ScaleTo`); la escala de exportación sirve para que el modelo llegue a Studio con su
tamaño real y las cuatro etapas sean comparables.

## E1

- Fuente: `tools/blender/minotauro_v2_e1_bloques.py` → `assets/blender/minotauro_v2/e1_bloques.blend`.
- Renders de revisión: `renders/minotauro_v2_e1/` (frente, perfil, tres cuartos, atrás y
  `estadisticas.json`).
- Rig y FBX: `tools/blender/rig_minotauro_v2_e1.py` → `assets/blender/MinotauroE1_v2.fbx`
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
  - Revisión: en las 20 poses de `minotauro_v2_e1_poses.py` la malla deformada por los huesos
    coincide con las piezas rígidas (error máximo 0.00001 celdas). Reimportado en Blender:
    28 huesos, 26 grupos, la textura y 16.5 de alto.
- Importar a Studio (pendiente, a mano: el MCP de Studio no importa FBX): Importar 3D →
  **"Mantener huesos de influencia cero"** (si no, se pierden `Raiz` y `Boca`), revisar en la
  vista previa que esté parado y mirando al frente, y dejar el Model en
  `ServerStorage.MinotauroE1_v2`. No reemplaza a `MinotauroE1`.
