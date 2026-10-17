# Plan: Minotauro v2 (piloto)

Rehacer el Minotauro E1..E4 desde cero: malla con buena topología, rig con pesos
revisados, animación con keyframes de las acciones principales, bake de color y normal a
1024 y VFX en Roblox. Es el piloto: lo que salga de aquí se vuelve el método para la orca,
el dragón y el zorro.

Documentos de base: `docs/inventario_modelos.md` (lo que hay) y `docs/estilo_modelos.md`
(lo que se exige).

**Estado: esperando aprobación.** No se modela nada hasta que se respondan las preguntas
de abajo.

## Reglas del piloto

- **Los modelos actuales no se tocan.** Ni los `.fbx`, ni los PNG, ni los scripts
  `minotauro*.py` / `rig_minotauro*.py`, ni `ServerStorage.MinotauroE1..E4`, ni sus IDs en
  `Assets`.
- **Todo lo nuevo lleva `_v2`:** `tools/blender/minotauro_v2*.py`,
  `assets/blender/MinotauroE<n>_v2.fbx`, `assets/textures/MinotauroE<n>_v2_*.png`,
  `ServerStorage.MinotauroE<n>_v2`.
- **Un commit por paso**, en español. Devlog y `tareas_claude_code.md` al cerrar cada etapa.
- **Código en `src/`** solo por Rojo, nunca en Studio. El código nuevo convive con el
  actual: la v2 se activa con un interruptor, no reemplazando.

## Antes de empezar: decisiones que necesito

1. **Estilo: ¿orgánico o facetado?** El pedido dice "orgánico"; las referencias son
   bloques facetados con textura de studs. Propuesta: la mezcla de `estilo_modelos.md`
   (malla continua que deforma bien, planos marcados, textura de estilo Roblox).
2. **Keyframes contra `CLAUDE.md`.** `CLAUDE.md` dice "Nada de rigs ni keyframes en este
   proyecto" y `decisiones.md` (2026-10-11) lo justifica. Los rigs ya se usan de hecho;
   los keyframes serían nuevos. Si se aprueba, en el primer commit de código actualizo
   `CLAUDE.md` y agrego la decisión con el motivo (calidad de las acciones principales) y
   el costo (clips subidos a Roblox, ver riesgo R2).
3. **Presupuesto de triángulos.** `blender-pipeline.md` dice 10k; los actuales tienen 18-20k;
   Roblox admite 20k por MeshPart. Propuesta: E1 8k, E2 10k, E3 12k, E4 15k.
4. **Quién toca qué.** `tools/blender/`, `assets/` y `src/shared/Assets/` son de Cowork
   según `tareas_claude_code.md`. Propuesta: lo mismo que la C5 (pedido directo del
   usuario): abro la tarea **C9** en ese archivo, Claude Code hace los archivos `_v2` y
   Cowork importa a Studio y anota los IDs (o lo hago yo si lo autorizas).
5. **¿Huesos nuevos?** El contrato tiene 25 huesos. La calidad pide algunos más, **todos
   opcionales** para el código actual: `Mechon`, `Faldon1..3` (delante, atrás, a los
   lados), `Borla` (punta de la cola), `Cola4`, `Ceja<lado>`. Los 25 actuales se mantienen
   con el mismo nombre y jerarquía, así `Rig.bind` y `Pose.apply` siguen sirviendo.
6. **Un juego de clips o uno por etapa.** Propuesta: un juego compartido (mismos huesos)
   con velocidad por etapa en `Minotauro/Etapas`; clips propios solo donde no alcance
   (probable: `Caminar` y `Pisoton` de la E4).

## Herramientas

| Herramienta | Para qué |
|---|---|
| Blender 5.2 + MCP de Blender | modelado, UVs, rig, pesos, animación, bake, renders de revisión |
| Scripts Python en `tools/blender/minotauro_v2*.py` | todo reproducible: cada paso se puede rehacer desde git |
| Cycles (CPU) | bake de normal, color y AO; renders de las poses extremas |
| Studio + MCP de Studio | importar (con "Mantener huesos de influencia cero"), Animation Editor, pruebas en play |
| Rojo, selene, stylua, luau-lsp | código del VFX y del reproductor de clips |

**Límite honesto:** modelo por código (Python), no a mano con pincel. Escultura fina con
brochas no es práctica por la API; el detalle de alta resolución sale de subdivisión +
desplazamiento procedural + formas modeladas (pliegues, músculos, pelaje en mechones) y se
hornea. Los pesos "pintados" se ajustan por zonas con funciones de caída y se revisan con
las poses de prueba, no con brocha. Si en algún punto el resultado no llega a la
calidad pedida, lo digo con renders en vez de forzarlo.

## Pasos

### Paso 0: confirmar lo que falta del inventario (½ h)

Por MCP de Studio (solo lectura): nombre de la MeshPart, pivote, atributos y triángulos de
`MinotauroE1..E4`; por MCP de Blender: alto de E2..E4 y sus articulaciones. Completar los
"por confirmar" de `inventario_modelos.md`.

**Aceptación:** ningún "por confirmar" que afecte al plan (los que no afecten quedan anotados).

### Paso 1: hoja de modelo y bloqueo (E1) (3-4 h)

`minotauro_v2_bloqueo.py`: volúmenes simples con las proporciones de la guía; renders de
frente, perfil, ¾ y silueta en negro, junto a las referencias y al E1 actual.

**Aceptación:** apruebas la silueta y proporciones en los renders. Sin esto no sigo.

### Paso 2: malla base con topología (E1) (6-8 h)

`minotauro_v2_malla.py`: malla de quads construida por código (anillos por segmento con
los bucles de las articulaciones en su lugar), medio cuerpo espejado. Piezas duras
aparte (cuernos, aros, pezuñas, cinturón).

**Aceptación:** checklist de topología de la guía (quads, bucles por articulación,
simetría, sin errores de malla) y presupuesto de triángulos cumplido. Render en alambre.

### Paso 3: alto detalle y UVs (E1) (5-6 h)

Copia subdividida con músculo, pliegues y mechones de pelaje (desplazamiento y formas).
UVs por costuras sobre la malla final.

**Aceptación:** criterios de UVs de la guía (costuras escondidas, densidad pareja, margen
de 8 px, ≥ 70 % de aprovechamiento). Render del damero sobre el modelo.

### Paso 4: bake (E1) (3-4 h)

Color, normal, rugosidad (y metal del oro) a 1024 con jaula; AO suave multiplicada al
color. PNG en `assets/textures/MinotauroE1_v2_*.png`.

**Aceptación:** sin costuras ni manchas a 3 m; comparado con el alto detalle, la malla
final se ve igual de frente y de perfil.

### Paso 5: rig y pesos (E1) (6-8 h)

`rig_minotauro_v2.py`: los 25 huesos del contrato (mismos nombres, mismo padre) más los
opcionales aprobados. Pesos por calor y luego corregidos por zona. Las 9 poses extremas de
la guía en renders.

**Aceptación:** las 9 poses sin los fallos de la tabla; máximo 4 influencias; `Raiz` y
`Boca` sin pesos; `Rig.bind` del código actual enlaza (prueba en Studio en el paso 7).

### Paso 6: animación con keyframes (E1) (10-14 h)

Los 8 clips de la guía (más `Reposo` si se decide) en Blender, con marcadores por evento.
Render en video corto de cada uno para revisar.

**Aceptación:** cada clip cumple anticipación, squash y stretch con pose, acción secundaria
en orejas, cola y faldón, arcos y salidas suaves; los bucles no saltan; apruebas los
videos.

### Paso 7: exportar e importar (E1) (2-3 h)

FBX `MinotauroE1_v2.fbx` (mismas opciones de exportación que hoy). Importar a
`ServerStorage.MinotauroE1_v2`. Clips a `KeyframeSequence` / `Animation` (ver R2).

**Aceptación:** llega parado, mirando a -Z, con los huesos opcionales y `Boca`; la
SurfaceAppearance con las 4 texturas; el modelo actual sigue intacto.

### Paso 8: código y VFX (E1) (8-10 h)

En `src/` (Rojo), sin quitar nada de lo actual:

- `Minotauro/Clips.luau`: reproduce clips con un `Animator` y `AnimationController`;
  el movimiento continuo (`Pose.idle`, mirar, enojo) se suma encima después del Animator,
  como `ArmPose` (decisión del 2026-10-12).
- `Trucos` y `Caminar` usan el clip si existe y su pose por código si no; los eventos salen
  de los marcadores del clip.
- `Etapas.forModel`: hoy el patrón `E(%d)$` **no reconoce** `MinotauroE1_v2` (cae en E1
  por defecto). Se cambia a `E(%d)` con sufijo opcional.
- `GiantTemplates` busca `<modelBase>E<n>`: interruptor (atributo o `Config`) para usar
  `_v2` cuando exista. `Assets` necesita los IDs nuevos para que `GiantModel` no lo
  rechace.
- VFX de la guía en `MinoStand` / un módulo nuevo `MinoFx`.
- Archivos ≤ 200 líneas, `--!strict`, selene y stylua.

**Aceptación:** checklist de `CLAUDE.md` (build, selene, stylua, probado por MCP); con
`Minotauro:1` y GiantFed simulado: camina, come, muerde, hace los 6 trucos con sus
efectos y sin errores en la consola; modo rápido sin partículas pesadas; apagando el
interruptor vuelve el modelo actual.

**Fin del piloto E1: revisión contigo antes de seguir.**

### Paso 9: E2, E3 y E4 (por etapa: 8-12 h)

Misma malla base deformada o retocada por etapa (como hoy, pero con la topología nueva),
piezas propias (tirante, hombreras, collar, grietas de lava), bake, pesos revisados en las
poses extremas, clips reutilizados con tiempo por etapa (y propios donde no alcance) y
VFX de etapa (lava de la E4).

**Aceptación por etapa:** los mismos criterios de los pasos 2 a 8, más: la silueta de las
4 etapas lado a lado se lee como el mismo personaje creciendo.

### Paso 10: cambio final (1-2 h)

Cuando apruebes las 4 etapas: el interruptor pasa a v2 por defecto. Los actuales siguen en
`ServerStorage` (o en `Respaldos`, sin borrar). Documentación: `blender-pipeline.md` (pedido
a Cowork), devlog, decisiones, README si cambia.

## Estimación

| Tramo | Horas de trabajo |
|---|---|
| Pasos 0-8 (E1 completo, piloto) | 44-58 h |
| Paso 9 (E2, E3, E4) | 24-36 h |
| Paso 10 | 1-2 h |
| **Total** | **~70-95 h** |

Son horas de trabajo con revisiones tuyas en el medio (paso 1, paso 6 y fin del piloto).
Los bakes y exportaciones corren en temporizador de Blender (~5-10 min cada uno). La
estimación más incierta es la animación: depende de cuántas vueltas pidan los videos.

## Riesgos

| # | Riesgo | Qué hago |
|---|---|---|
| R1 | Modelar por código no llega a la calidad "profesional" pedida. | El paso 1 y el 2 lo muestran pronto con renders; si no llega, lo aviso y propongo alternativas antes de seguir. |
| R2 | Los clips de animación son assets de Roblox: hay que **subirlos** con la cuenta o grupo dueño de la experiencia, y eso no se puede hacer desde `rojo build`. Cómo importar clips de huesos desde FBX en Studio: **por confirmar** en el paso 7. | Interruptor: sin clips, el código usa la animación actual. IDs de los clips en `Assets`. |
| R3 | `Animator` y la pose por código pelean por `Bone.Transform`. | Sumar la pose por código después del Animator (`PreSimulation`), como `ArmPose`. Probar temprano (paso 8). |
| R4 | Escalar huesos en Roblox para squash y stretch. | No depender de eso: se hace con la pose (ver guía). |
| R5 | Cowork trabajando en los mismos archivos. | Tarea C9 con aviso "no tocar" y solo archivos `_v2`. |
| R6 | El nombre `_v2` rompe la detección de etapa y el chequeo de `MeshId`. | Cambios del paso 8 (patrón de `Etapas`, IDs en `Assets`). |
