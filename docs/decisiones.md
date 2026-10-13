# Registro de decisiones técnicas

Cada decisión no obvia queda documentada con su contexto, para que cualquier
persona que lea el código entienda por qué está construido así y no de otra forma.

Formato:

```
## AAAA-MM-DD — Título de la decisión
**Decisión:** qué se eligió.
**Contexto:** qué problema o situación la motivó.
**Alternativas consideradas:** qué más se evaluó.
**Por qué:** razones de la elección y costos aceptados.
```

---

## 2026-10-11 — Luau puro sobre roblox-ts

**Decisión:** escribir todo el código en Luau con `--!strict`.

**Contexto:** se necesita tipado estático para que el código sea mantenible y legible
por otros desarrolladores de Roblox.

**Alternativas consideradas:** roblox-ts (TypeScript transpilado a Luau).

**Por qué:** Luau estricto ya ofrece inferencia y chequeo de tipos suficientes. Evita una
capa de compilación, un `node_modules` y un segundo sistema de tipos. El código que corre
es el mismo que se lee, los stack traces apuntan a líneas reales y cualquier
desarrollador de Roblox puede leerlo sin conocer TypeScript. Costo aceptado: un
ecosistema de tipos y herramientas menos maduro que el de TypeScript.

## 2026-10-11 — Rojo sobre editar directo en Studio

**Decisión:** todo el código vive en `src/` y se sincroniza a Studio con Rojo.
Studio solo se usa para construir el nivel.

**Contexto:** el proyecto es público y debe tener historial de cambios revisable.

**Alternativas consideradas:** escribir scripts directamente en Studio con Team Create.

**Por qué:** con Rojo el código está en git: diffs reales, commits atómicos, revisión de
código, linting (selene) y formateo (stylua) automatizables. El editor de Studio no
ofrece nada de eso. Costo aceptado: hay que levantar `rojo serve` y conectar el plugin
cada sesión, y nunca editar en Studio lo que existe en `src/`.

## 2026-10-11 — Rokit sobre Aftman

**Decisión:** gestionar rojo, selene, stylua y wally con Rokit (`rokit.toml`).

**Contexto:** las versiones de las herramientas deben ser fijas y reproducibles en
cualquier máquina.

**Alternativas consideradas:** Aftman, Foreman, instalación manual de binarios.

**Por qué:** Rokit es el sucesor mantenido activamente dentro del ecosistema de Rojo,
lee los formatos de Aftman y Foreman, y es más rápido. Aftman está en modo de
mantenimiento. Un solo `rokit install` deja el entorno idéntico al del autor.

## 2026-10-11 — Primitivas antes que assets (fase 1 / fase 2)

**Decisión:** la fase 1 se construye solo con partes primitivas y colores planos. Los
modelos de Blender entran en la fase 2, uno por uno, cuando el juego esté completo.

**Contexto:** el riesgo principal de un proyecto en solitario es no terminarlo. El
trabajo visual es el más fácil de expandir sin límite.

**Alternativas consideradas:** desarrollar arte y mecánicas en paralelo.

**Por qué:** validar que el juego funciona y es divertido antes de invertir en arte evita
modelar cosas que luego se descartan. Como todos los IDs están centralizados en
`Assets.luau` y los modelos se nombran igual que en código, reemplazar primitivas por
meshes no requiere tocar la lógica. Las ideas visuales que surjan antes se registran en
`docs/ideas.md`.

## 2026-10-11 — TweenService en lugar de animación con rigs

**Decisión:** toda animación se hace por código con TweenService y CFrame (girar, flotar,
deslizar paneles). No se usan rigs ni keyframes.

**Contexto:** el alcance del proyecto no requiere personajes animados propios.

**Alternativas consideradas:** rigs con Animation Editor o Moon Animator; animaciones
exportadas desde Blender.

**Por qué:** las animaciones por código viven en git, se ajustan cambiando un número en
`UIConfig.luau`, no requieren subir ni moderar assets y no dependen de IDs externos.
Los rigs añadirían un pipeline completo (rigging, subida, permisos) sin beneficio para
este tipo de juego.

## 2026-10-12 — Reducir modelos de IA horneando texturas, no solo con decimate

**Decisión:** los modelos generados con IA (Meshy) se reducen en dos zonas (cara con
ratio 0.30, cuerpo con 0.19) y luego se hornea la apariencia del original sobre la malla
reducida con UVs nuevas a 1024×1024: color, normal (tangente, OpenGL) y rugosidad. La
textura original de Meshy no se reutiliza.

**Contexto:** la orca de Meshy tenía 46,748 triángulos y texturas de 2048. Con solo
decimate, los bordes pintados (parche del ojo, mancha celeste) quedaban dentados porque
la textura estaba pintada para la malla original y las UVs se deforman al colapsar
aristas.

**Alternativas consideradas:** decimate uniforme (deforma ojos y sonrisa); decimate con
grupo de vértices (protege la cara pero deja el cuerpo con ~200 triángulos); reutilizar
las UVs de Meshy reduciendo la textura a 1024 (bordes dentados).

**Por qué:** el horneado separa la geometría de la apariencia: la malla puede ser tan
simple como pida el límite y la textura sigue viéndose como el original. Costos: hay que
verificar que las UVs nuevas no se solapen (Smart UV Project con 66° solapaba las aletas;
con 35° no) y que la distancia de proyección no tome superficies vecinas.
