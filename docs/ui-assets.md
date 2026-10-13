# Assets visuales (ForgeGUI)

Seguimiento de cada imagen generada para el juego: de dónde salió, dónde se usa y
en qué estado está.

## Flujo

1. Generar el PNG en ForgeGUI con el prompt registrado en la tabla.
2. Guardar el archivo fuente en `assets/textures/`.
3. Subirlo en Studio: **Asset Manager** → **Images** → **Import**.
4. Copiar el ID resultante a `src/shared/Assets.luau` (sección `UI` o `Textures`).
5. Actualizar el estado en la tabla.

Mientras un asset no exista, su entrada en `Assets.luau` queda como
`"rbxassetid://0"` y la fila aquí queda como `pendiente`.

## Reglas de generación

- Fondo transparente siempre.
- 9-slice para todo lo que se estira (paneles, botones, barras).
- Nada de texto dentro de la imagen. Los textos van en TextLabels.
- Máximo 1024x1024.
- Generar kits completos de una pasada en lugar de piezas sueltas, para mantener
  consistencia de estilo.
- ForgeGUI produce imagen estática. Cualquier movimiento se hace por código.

## Estados

`pendiente` → `subido` → `moderado` → `listo`

## Tabla

| Nombre | Tipo | Dónde se usa | Prompt usado | Estado |
|---|---|---|---|---|
| PanelBackground *(ejemplo)* | ui | Fondo de paneles de menú | "flat rounded panel, dark slate, subtle border, transparent background, 9-slice friendly" | pendiente |

## Modelos y texturas de mesh

No salen de ForgeGUI: el modelo viene de Meshy (generado desde el concept art) y las
texturas se hornean en Blender (ver `blender-pipeline.md`). Se suben juntos con
**File → Import** en Studio, que crea el `MeshPart` y su `SurfaceAppearance`.

"Subido" significa que el asset existe en Roblox a nombre de la cuenta (comprobado con
`MarketplaceService:GetProductInfo`). El estado de moderación no se puede consultar
desde Studio; pasa a `moderado` cuando se confirme a mano en Creator Hub.

| Nombre | Tipo | Archivo fuente | ID | Estado |
|---|---|---|---|---|
| OrcaE1 | mesh | `assets/blender/OrcaE1.fbx` | `116864238392648` | subido |
| OrcaE1Color | textura (color) | `assets/textures/OrcaE1_color.png` | `78747470199717` | subido |
| OrcaE1Normal | textura (normal) | `assets/textures/OrcaE1_normal.png` | `79662647526007` | subido |
| OrcaE1Roughness | textura (rugosidad) | `assets/textures/OrcaE1_roughness.png` | `86419609055550` | subido |
