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
