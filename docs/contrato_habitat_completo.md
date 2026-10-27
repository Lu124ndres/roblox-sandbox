# Contrato: hábitat completo por monstruo (Blender)

Pedido del usuario (2026-10-23): cada monstruo tiene **un hábitat completo modelado en
Blender**, que reemplaza a los props sueltos que hoy reparte `HabitatPlacer`
(`Config.Habitats.byGiant`). Un agente hace cada hábitat; la sesión principal lo integra en
el juego (`HabitatService`), lo prueba en Studio y hace el commit.

## Coordenadas

- 1 unidad de Blender = 1 stud.
- **Origen = centro del cráter**, a la altura Y = 0 del mundo (el agua está en Y = 2).
- Blender Z = Y del mundo (altura **absoluta**, no relativa al fondo).
- Un punto del mundo relativo al centro del cráter `(dx, y, dz)` es en Blender `(dx, -dz, y)`
  (el FBX se exporta con `axis_forward="-Z", axis_up="Y"`, como `arco_volcan.py`).
- Ángulos de `Config.Habitats` (grados desde +X del cráter, `x = cos`, `z = sin`): en Blender,
  `(r·cos a, -r·sin a)`.
- El puente llega por el ángulo 270 del cráter (la puerta, `bridgeAngle + 180`): en Blender, +Y.
  Los jugadores miran desde el paseo de arriba (radio 205 a 235, Y = 30) y desde la puerta.

## Forma del fondo

`r` = distancia horizontal al centro del cráter.

**Lago de cuenco** (Minotauro, DragonMarino, ZorroDeAgua, OrcaFantasma), igual a
`WorldZones.lakeFloor` y `CraterShape.height`:

```
r < 75:            Y = -150
75 <= r < 150:     t = (r - 75) / 75;  Y = -150 + 142 * (1 - cos(pi * t)) / 2   (llega a -8)
150 <= r < 190:    t = (r - 150) / 40; Y = -8 + 7 * t                            (repisa, llega a -1)
190 <= r < 205:    t = (r - 190) / 15; Y = -1 + 31 * t ** 0.6                    (acantilado, llega a 30)
205 <= r:          Y = 30 (paseo de los jugadores)
```

**Lago de la Orca** (nuevo, pedido del usuario: «toda el agua con la misma profundidad, 250»):

```
r < 184:           Y = -250 (fondo plano)
184 <= r < 190:    pared casi vertical de -250 a -1 (lineal)
190 <= r:          igual que el cuenco (acantilado y paseo)
```

Cada monstruo llena el cráter a su modo (lo hace cada cliente, `Ambient/CraterDrain`): agua
(Orca, OrcaFantasma), arena (Minotauro, `sand`), lava (DragonMarino, `lava`) y agua con hielo
(ZorroDeAgua, `ice`). Cada agente revisa el relleno y el «lair» de su monstruo (abajo).

## Zonas prohibidas

1. **El paseo y más allá** (`r >= 205`): nada. El acantilado (190–205) se puede vestir, pero sin
   pasar por encima de Y = 30 ni hacia adentro del paseo.
2. **El gigante** (`r < 95`, `Config.Habitats.giantClearRadius`): solo cosas pegadas al fondo,
   de 15 studs de alto como máximo. La E4 mide unos 165 de alto y 80 de ancho.
3. **El santuario del descanso** (sube del fondo a la mitad del lago vacío; el techo de su piso
   queda en Y = -20): nada dentro de
   - `r < 100` con `Y > -136` (su cono de roca), ni
   - `r < 124` con `Y > -84` (cadenas y piedras que flotan alrededor).
4. **Los contratos del monstruo** (dónde se posa, anida o duerme): `src/shared/Dragon/Guarida.luau`,
   `src/shared/Zorro/Guarida.luau` y los que encuentres para tu monstruo. El hábitat los respeta o
   los viste; si algo tiene que moverse, se propone en el informe, no se cambia.

## Mallas y archivos

Script: `tools/blender/habitat_<id>.py` (`<id>` en minúsculas: `orca`, `minotauro`, `dragonmarino`,
`zorrodeagua`, `orcafantasma`), con el mismo encabezado y estilo que `tools/blender/arco_volcan.py`
y `tools/blender/guarida_santuario.py`. Se corre sin ventana:

```
"/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup --python tools/blender/habitat_<id>.py -- exportar render
```

- Low-poly con **textura de paleta** (cada cara toma un cuadrito de color, `Closest`), como
  `tools/blender/habitats.py`. Se pueden reusar los generadores de props de
  `tools/blender/habitats_<monstruo>.py` dentro de la escena.
- **Varias mallas, cada una de 9.800 triángulos o menos**, que comparten **la misma caja**: un
  cubito mínimo en cada esquina de la caja común, que es simétrica en X e Y alrededor del origen.
  Así el juego pone cada MeshPart con `Size` = la caja y su centro sobre el eje del cráter, sin
  desfasarse.
- Nombres: `<Id>Habitat1`, `<Id>Habitat2`… (con la paleta) y `<Id>HabitatBrillo1`… (lo que en el
  juego va en **Neon** de un color: lava, cristales, perlas, ojos de agua). Una malla Neon por color.
- Total: **8 mallas como máximo**. Pensar en el rendimiento del teléfono.
- Las mallas **no chocan** (salvo que el informe pida lo contrario con una razón).
- Exporta `assets/blender/habitat_<id>/<Id>Habitat.fbx` (textura embebida),
  `assets/textures/<Id>Habitat_color.png` y `assets/blender/habitat_<id>/<Id>Habitat.json`:

```json
{
  "ancho": 380.0,          // lado de la caja en X y en Z del mundo
  "alto": 260.0,           // alto de la caja
  "centroY": -120.0,       // Y absoluta del centro de la caja
  "mallas": [
    {"nombre": "OrcaHabitat1", "brillo": null},
    {"nombre": "OrcaHabitatBrillo1", "brillo": [120, 230, 255]}
  ],
  "luces": [{"pos": [dx, y, dz], "color": [r, g, b], "rango": 30}],
  "fuegos": [{"pos": [dx, y, dz], "tam": 6}]
}
```

  `luces` y `fuegos` van en coordenadas del **mundo** relativas al centro del cráter; el juego pone
  PointLight o Fire ahí. Pocas: 12 luces como máximo.
- Renders en `renders/habitat_<id>/`: al menos una vista desde el paseo (radio 220, Y = 34, mirando
  al centro), una aérea y una con el agua o el relleno insinuado. Dibuja también el fondo del lago
  (la fórmula de arriba) como malla gris aparte, **solo para el render**, para ver que todo apoya y
  nada flota ni se entierra.

## Reglas

- Trabajas en tu worktree. **Lo primero es `git merge --ff-only main`.** No haces commit.
- Archivos propios: los de arriba, con tu `<id>`. **No tocas** `src/`, `world/`, `docs/`,
  `default.project.json` ni scripts de otros monstruos. Si hace falta un cambio en el juego (por
  ejemplo, quitar del lair las piezas de primitivas que tu hábitat reemplaza), lo describes en el
  informe con rutas y nombres exactos.
- Studio es compartido: solo consultas de solo lectura por MCP, nada de Play. El MCP de Blender
  (la ventana) no se usa: solo Blender en segundo plano (`-b`).
- Las decisiones de diseño son del usuario: sigue el tema del monstruo y lo que ya existe; si algo
  es dudoso, elige lo más fiel al hábitat actual y anótalo en el informe.

## Informe que devuelves

1. Archivos creados (rutas).
2. Triángulos por malla, la caja (`ancho`, `alto`, `centroY`) y los colores de brillo.
3. Rutas de los renders y qué muestra cada uno.
4. Qué piezas del juego actual reemplaza (props de `Config.Habitats.byGiant.<Id>`, piezas del lair
  de primitivas) y qué cambios en `src/` hacen falta, con rutas exactas.
5. Qué quedó flojo o dudoso.
6. Un párrafo para el devlog.
