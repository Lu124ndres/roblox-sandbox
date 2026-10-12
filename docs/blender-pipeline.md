# Pipeline de Blender a Roblox

> **Este pipeline NO se usa hasta que la fase 1 esté terminada.** Durante la fase 1
> todo se construye con partes primitivas. Ver `CLAUDE.md`, sección "Visuales y fases".

## Reglas de exportación

- **Máximo 10,000 triángulos por MeshPart.**
- **Aplicar transformaciones antes de exportar** (`Ctrl+A` → All Transforms).
- **Origen en el punto de anclaje lógico** del objeto (la base de un árbol, la bisagra
  de una puerta), no en el centro geométrico por defecto.
- **UVs desplegados** y sin solapamientos en la textura principal.
- **Texturas de 1024x1024** con albedo plano: sin sombras ni iluminación horneada.
  La iluminación la pone el motor.
- **Escala en metros** en la configuración de la escena.
- **Formato `.fbx` o `.glb`**, exportado a `assets/blender/`.
- **Nombres en PascalCase que coincidan con el MeshPart en código.**
  Si el código busca `CoinGenerator`, el archivo es `CoinGenerator.fbx`.

## Texturas: ForgeGUI o Blender

Las texturas **tileables** (piso, pasto, ladrillo) pueden venir de ForgeGUI.
Las texturas de **objeto específico** se pintan en Blender sobre los UVs reales, porque
un generador de imágenes no conoce el unwrap del modelo.

## Checklist previa a cada exportación

- [ ] Conteo de triángulos ≤ 10,000 (Overlay → Statistics).
- [ ] Transformaciones aplicadas (rotación 0, escala 1).
- [ ] Origen en el punto de anclaje lógico.
- [ ] UVs desplegados y revisados.
- [ ] Textura 1024x1024, albedo plano, sin luz horneada.
- [ ] Escala de escena en metros.
- [ ] Nombre del objeto y del archivo en PascalCase, igual al MeshPart en código.
- [ ] Exportado a `assets/blender/` como `.fbx` o `.glb`.
- [ ] Al subirlo, ID registrado en `src/shared/Assets.luau` y reemplazo anotado en
      `docs/devlog.md`.
