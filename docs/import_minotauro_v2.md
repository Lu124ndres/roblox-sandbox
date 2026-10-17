# Importación del Minotauro v2

Registro de la escala y las opciones con que cada etapa `_v2` sale de Blender y entra a
Studio. Reglas en `docs/estilo_modelos.md` (sección 3, "Escala").

## Escala

**Escala única: 5.32 studs por BU**, la misma para E1..E4, aplicada una sola vez al
exportar, con escala y rotación aplicadas en todos los objetos.

| Etapa | Alto del modelo (BU) | Alto esperado (studs) | Alto con 5.32 (studs) | Estado |
|---|---|---|---|---|
| E1 | 3.1 (medido por el script) | 16.5 | 16.49 | modelo de bloques hecho; sin exportar |
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
- Exportación (FBX, opciones, nombre en `ServerStorage`): pendiente. Se anota aquí al hacerla.
