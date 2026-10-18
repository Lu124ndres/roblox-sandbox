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
- **Texturas embebidas en el FBX**: Path Mode en **Copy**, **Embed Textures** activado y
  Apply Scalings en **FBX Unit Scale**. Si la textura solo se referencia por ruta, Studio
  importa el modelo sin color.
- **PNG finales de textura en `assets/textures/`** (`Nombre_color.png`, `_normal`,
  `_roughness`). Los archivos de origen pesados (exportaciones de Meshy) no van al repo.
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
- [ ] Exportado a `assets/blender/` como `.fbx` o `.glb`, con texturas embebidas.
- [ ] Al subirlo, ID registrado en `src/shared/Assets.luau` y reemplazo anotado en
      `docs/devlog.md`.

## Monstruos por código (`tools/blender/`)

Los monstruos se modelan con scripts de Python que corren en Blender 5.2 (por el MCP o
pegándolos en la consola de Python de Blender):

| Archivo | Qué hace |
|---|---|
| `criaturas.py` | Bloques comunes: cadenas de piel (Skin), masas, fusionar (remesh por vóxeles + suavizado), pintar colores por vértice, materiales de pelaje/escamas/cuerno, estudio y render. |
| `minotauro.py`, `dragon.py`, `zorro.py` | Un monstruo en 4 etapas: `construir_<monstruo>(etapa, voxel)` devuelve sus objetos. |
| `vista_etapas.py` | `vista_etapas(construir, alto, ruta, voxel, angulo=8)`: las 4 etapas lado a lado (cámara ortográfica que encuadra todo) para revisar el diseño. Renders en `assets/blender/render/`. |
| `exportar.py` | `exportar_monstruo(nombre, objetos, proyecto)`: una malla ≤ 9,800 triángulos, UVs automáticas, color + brillo + normales horneados a 1024 y FBX con texturas embebidas. |
| `exportar_todos.py` | `exportar_cola([("Minotauro", 2), ...])`: exporta varios en cola, cada uno en su temporizador (Blender no se congela) y deja `log_<Nombre>.json` y `cola.json`. Cada uno tarda ~5 min. |

Los llamados largos por el MCP se cortan a los 60 s aunque Blender siga trabajando: para
renders y exportaciones se usa `bpy.app.timers.register` y se espera el archivo.

En el juego, cada etapa es un Model `<modelBase>E<n>` en ServerStorage (ver
`GiantTemplates`); su tamaño real no importa: `GiantBody` lo escala a 3, 8, 15 y 30
veces el alto de un jugador.

**Orientación:** el modelo tiene que llegar a Studio parado (Y hacia arriba). Desde
Blender, exportar con `bake_space_transform=True` (ya está en `exportar.py`). Con Meshy,
confirmar en la vista previa de "Importar 3D" que esté parado y mirando al frente.

## Monstruos de Meshy con huesos (orca)

1. `blender -b --python tools/blender/procesar_meshy.py -- <fbx de Meshy> <salida.blend> OrcaE<n> <triángulos>`:
   una malla, simetría en X, origen en la base, nariz hacia -Y, texturas de 1024.
2. Medir la boca y las aletas (renders laterales con cuadrícula) y anotarlas en
   `tools/blender/orcas.json` (bisagra, línea entre los labios, franja de las aletas).
3. `blender -b --python tools/blender/rig_orca.py -- <modelo.blend> <salida.fbx> tools/blender/orcas.json OrcaE<n>`:
   huesos Raiz, Cabeza, Mandibula, Cola1..Cola4, AletaIzq/Der y los puntos Boca,
   Espiraculo y Dorsal, con pesos suaves.
4. Studio → Importar 3D → marcar **"Mantener huesos de influencia cero"** (si no, se
   pierden Boca, Espiraculo y Dorsal). Mover el Model a `ServerStorage.OrcaE<n>` y anotar
   los IDs en `Assets`.
5. Cómo se mueve cada etapa: `src/shared/Orca/Etapas/` (un script por etapa).

## Trajes del personaje con huesos (Marinero, Dios del Volcán, Rey del Mar)

1. Texturas nuevas: el atlas de Meshy viene en cientos de pedacitos y al reducir la malla
   se rompe (manchas y costuras). `python3 -I tools/blender/hornear.py -- <fbx de Meshy> <salida.blend> <Nombre> <triángulos> <tamaño>`
   reduce, hace UVs nuevas (smart project) y hornea desde el modelo original color,
   rugosidad, metal (como emisión) y normales a 1024; deja `tex/<Nombre>_*.png` y el
   material con las 4 texturas para que Studio las tome.
2. Medir hombros, codos, muñecas, cadera, rodillas, tobillos, cuello y cintura en renders de
   frente con cuadrícula y anotarlos en `tools/blender/trajes.json` (más el objeto en la mano,
   como el tridente: segmento `prop`, y el faldón: `skirt`).
3. `python3 -I tools/blender/rig_traje.py -- <modelo.blend> <salida.fbx> tools/blender/trajes.json <Nombre>`:
   huesos Raiz, Cadera, Pecho, Cabeza, Brazo/Codo/Mano y Pierna/Rodilla/Pie (Izq/Der).
   **Sin estirarse:** cada pedazo es rígido (peso 1 a un solo hueso). La malla se corta con
   planos en las articulaciones (`bisect_plane`, solo en esa zona para no sumar
   triángulos), se separa en los bordes entre huesos y se tapan solo los huecos nuevos
   (tapa con el color promedio del borde). Probar posando los huesos antes de exportar.
   **Problema visto en juego:** con piezas rígidas, al doblar codos y rodillas se abre un
   hueco y se ve la tapa ("el traje se corta al caminar"). Por eso, después:
3b. `tools/blender/suavizar_traje.py` (por el MCP de Blender, sobre el FBX de rig_traje):
   sobre el FBX **rígido** de rig_traje: cose solo los cortes de codos, muñecas, rodillas y
   tobillos (borra esas tapas, une, pesos mitad y mitad y una transición angosta). Hombros,
   cadera, cintura y cuello quedan como piezas separadas, como un avatar R15: coserlos
   estiraba la ropa al mover brazos y piernas. El tridente sigue rígido en la mano. Mismo esqueleto y mismas opciones de exportación.
4. Studio → Importar 3D → "Mantener huesos de influencia cero" (la Raiz no tiene pesos),
   tipo de rig "Personalizar". Mover el Model a `ServerStorage.Traje<clave>` (Marinero,
   DiosDelVolcan, ReyDelMar) y anotar los IDs en `Assets`. El tamaño no importa: el juego lo
   escala para que la cadera coincida con la del cuerpo.
5. Cómo se mueve y brilla cada uno: `src/shared/Trajes/Estilos/<clave>.luau`.
6. El aura de los trajes de pase: `src/shared/Trajes/Aura.luau` (lenguas de fuego o agua,
   motas, destellos, halo, onda en el piso y contorno) con texturas propias (abajo).

### Trajes v2 de bloques (Marinero, Rey del Mar, Dios del Volcán)

Los tres trajes ya no salen de Meshy ni de los pasos de arriba: se arman enteros por script con
un generador común y una **ficha** por traje (`tools/blender/traje_v2_<clave>.py`, claves
`marinero`, `rey_del_mar`, `dios_del_volcan`):

- `traje_v2_base.py`: esqueleto (los 16 huesos), articulaciones, pesos y las líneas de malla
  donde se cortan los puentes; lo comparten los tres.
- `traje_v2_tubos.py` / `traje_v2_cuerpo.py`: cada parte es un tubo de anillos redondeados; las
  partes se unen con puentes en sus pivotes (una sola malla cerrada). Los accesorios (corona,
  capa, cuernos, púas, placas) son tubos aparte, metidos un poco en lo que los lleva y pegados a
  un hueso. `traje_v2_formas.py`: placas biseladas y púas en cualquier dirección.
- `traje_v2_regiones.py`: dónde cae cada cara en la textura (paleta, región plana o "caja",
  que envuelve todo el cuerpo con un mismo dibujo).
- Ficha: medidas por tramo, colores, regiones y color de cada cara; `..._piezas.py` sus
  accesorios, `..._dibujo.py` sus dibujos (PIL) y `..._cara.py` las caras elegibles
  (variable `TRAJE_CARA`; la elegida por el usuario es la de por defecto).

Pasos:

1. `python tools/blender/traje_v2_textura.py --traje <clave>`: textura de color y, si algo
   brilla, máscara de brillo (`assets/blender/<carpeta>/<Archivo>_color.png` y `_brillo.png`).
   Las grietas y el magma del volcán salen de `traje_v2_grietas.py` (Voronoi con numpy).
2. `blender -b --factory-startup --python tools/blender/traje_v2.py -- --traje <clave>`: malla,
   pesos, huesos (más los extra de la ficha, como la capa) y `assets/blender/Traje<Archivo>_v2.fbx`.
   Imprime `aristas_abiertas` y `caras_degeneradas`: las dos tienen que dar 0.
3. `blender -b --factory-startup --python tools/blender/traje_v2_vistas.py -- --traje <clave>`:
   renders en reposo, poses extremas y la cara de cerca (`renders/<carpeta>/`). Las poses giran
   los huesos con la misma cuenta que el juego. `--solo` y `--sufijo` para comparar caras.
4. Importar como los otros trajes (paso 4 de arriba). Si la ficha tiene brillo: subir la
   máscara (`_brillo.png`) y ponerla en `SurfaceAppearance.EmissiveMaskContent` (la que crea el
   importador no sirve: toma la textura de color).

## Dragón marino (4 etapas que vuelan)

1. `hornear.py` como los trajes (E1..E4 entre 15,600 y 19,100 triángulos).
2. `tools/blender/dragon_E<n>.json`: puntas de cada miembro (alas, patas, cola, cuello).
   `dragon_centro.py` saca la línea central de cada miembro (Dijkstra desde la punta, los
   vértices por distancia, el centro de cada tramo) y pone las articulaciones a lo largo.
   Lo que no sale bien (el cuello, la pelvis) se corrige a mano en `dragon_E<n>_huesos.json`.
3. `rig_dragon.py`: huesos Raiz, Cadera, Pecho, Cuello1-2, Cabeza, Mandibula, Boca (punto),
   Cola1..6 y por lado Ala1-3, Brazo/Antebrazo/Mano, Muslo/Pierna/Pie. Pesos por calor
   (Blender) con respaldo al segmento más cercano, 4 influencias como máximo. Deja las alas
   abiertas en pose de vuelo como reposo y exporta.
4. Studio igual que la orca. Cómo vuela: `src/shared/Dragon/` (Vuelo = recorrido,
   Rumbo = giros con resorte, Trucos = rugido/fuego/picada/voltereta/planeo, Cuerpo = aleteo,
   Pose = huesos; perfiles por etapa en `Etapas.luau`).

## Texturas de partículas propias

`python3 tools/particulas/gen.py assets/particulas` genera FuegoFlip y AguaFlip (hojas 4x4
animadas, colores horneados), Brasa, Halo, Anillo, Chispa y Burbuja (blancas, se tiñen con
Color). Se suben con la cola de importación de Studio (Importar 3D acepta PNG) y sus IDs
van en `Assets.Particles`; comprobarlos con `MarketplaceService:GetProductInfo(id).Name`.

## Props del mapa (palmeras, arbustos, rocas, crestas, bordes de estanque)

`tools/blender/props_mapa.py` (por el MCP de Blender, con `RAIZ` y `EXPORTAR = True`) arma todo
por código, low-poly con una textura de paleta (cada cara toma un cuadrito de color de
`assets/textures/PropsMapa_color.png`) y exporta `assets/blender/PropsMapa.fbx` con los
objetos Palmera1-3, Arbusto1-2, Roca1-3, Cresta1-2, BordeEstanque y BordeSagrado, cada uno con
el origen en el centro de su base.

1. Studio → Importar 3D → el Model `PropsMapa` (pivote en el origen = la base) va a
   `ServerStorage.PropsMapa`. Si cambia la textura, subir el PNG con la cola de importación y
   poner su ID en `TextureID` de cada MeshPart (`Assets.Textures.PropsMapa`).
2. `tools/generar_isla.py` deja una pieza invisible `Ancla` (atributos Prop, Ajuste,
   Reemplaza) en cada palmera, arbusto, cresta y estanque; las rocas llevan Prop en la pieza.
3. `server/World/PropDresser` cambia cada ancla por el modelo y borra las primitivas que
   reemplaza. Sin `PropsMapa` el mapa queda con las primitivas.

## Piezas 3D del equipo (caña y canasta)

`tools/blender/equipo_base.py` exporta `assets/blender/EquipoBase.fbx`: MangoCorcho,
CarreteBobina, CarretePlato, Anilla y CajaRedondeada, de 1 x 1 x 1 con el eje largo en X (como
los cilindros de Roblox) y sin textura. En Studio van a `ReplicatedStorage.ModelosEquipo`;
`client/Effects/MeshKit.swap` cambia la pieza de primitivas por la 3D con el mismo tamaño,
lugar, color y material (RodBuilder: mango, carrete y anillas; BasketBuilder: cuerpo y borde).


## Minotauro etapa 1 (modelado por código, con huesos)

1. `tools/blender/minotauro_e1.py` (con `criaturas.py`): becerro chibi al estilo de la orca y
   el dragón. Bloques fusionados por vóxeles para el cuerpo y piezas aparte (ojos, cuernos,
   orejas, mechón, mandíbula, aros, cinturón, faldón, pezuñas, borla). Cada pieza guarda en
   `obj["hueso"]` el hueso al que sigue entera ("" = el cuerpo, pesos por calor). `PUNTOS`
   tiene las articulaciones. Se arma con Blender 5.2 como módulo (`pip install bpy`, sin
   ventana) o por el MCP; tarda ~9 min con vóxel 0.016 y se guarda como `alto.blend`.
2. `python3 -I tools/blender/rig_minotauro_e1.py -- alto.blend <salida.fbx> <carpeta tex>`:
   copia reducida (~18k triángulos), UVs nuevas, color y normales horneados a 1024 (el
   color con más luz y calidez: en Roblox se veía oscuro), esqueleto (Raiz, Cadera, Columna,
   Pecho, Cuello, Cabeza, Mandibula, Boca, Oreja, Brazo/Antebrazo/Mano, Muslo/Pierna/Pie,
   Cola1..3) y FBX.
3. Studio → Importar 3D → "Mantener huesos de influencia cero". Llega mirando a -Z (sin GiroY).
   Mover el Model a `ServerStorage.MinotauroE1` y anotar los IDs en `Assets`.
4. Se anima por código: `src/shared/Minotauro` (Rig, Pose, Trucos) y `client/Giant/MinoStand`.


## Hábitats del volcán (props por monstruo)

1. `tools/blender/habitats.py`: biblioteca común. Paleta compartida de 512x512 (celdas de 32 px,
   `COLORES`) en `assets/textures/Habitats_color.png`, clase `Malla` (torno, tubo, caja, esfera,
   roca, placa) y salida. 1 unidad = 1 stud, frente a +Y de Blender, origen en la base.
2. Un archivo por hábitat (`habitats_minotauro.py`, `habitats_orca.py`, `habitats_dragon.py`,
   `habitats_orcafantasma.py`) con `PROPS` (nombre → función que devuelve la malla, la malla
   `Brillo` opcional y efecto/llama/colores) y `SUGERIDO` (distribución en el cráter).
3. `python3 tools/blender/habitats_construir.py <Habitat> [render]` (Blender 5.2 como módulo,
   o `blender -b -P ... -- <Habitat>`): exporta `assets/blender/habitats/<Habitat>.fbx` (props
   en fila + cubo `Ancla`), `.json` y la vista previa `.png`.
4. Studio → Importar 3D (cada FBX llega a Workspace). Ojo: el FBX llega girado 180° (+X de
   Blender = -X de Roblox y +Y de Blender = +Z de Roblox); el armado lo corrige con el `Ancla`:
   origen = ancla + (-dx, dz, dy) y pivote girado 180° para que el frente quede en -Z.
   Un script por MCP arma `ServerStorage.Habitats.<GiantId>` (Model por prop, `Brillo` en Neon,
   Attachment `Llama`, atributos y `Sugerido`) y pone la paleta (`Assets.Textures.Habitats`).
