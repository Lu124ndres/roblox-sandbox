# OrcaE1 — Orca juvenil (etapa 1): ficha completa del modelo

Todo lo que tiene que tener el modelo 3D de la primera etapa de la Orca, desde el
concepto hasta el archivo que entra al juego. Flujo: imagen en **Nano Banana** → vistas
extra → **Meshy** (Multi-image to 3D) → Blender (`docs/blender-pipeline.md`) → Studio.

---

## 1. Concepto

Una **orca joven de verdad**, no una caricatura: un depredador pequeño, ágil y
musculoso. Tiene que leerse al instante como "la cría de algo peligroso". Nada de
ojos gigantes, sonrisas, rubor, lengua afuera ni proporciones de peluche.

- **Lo que transmite:** alerta, rápida, segura de sí, ya con instinto de cazadora.
- **Lo que la hace "etapa 1":** el tamaño en el juego, una aleta dorsal todavía corta,
  piel lisa con pocas marcas de pelea y los acentos turquesa apenas encendidos. Las
  etapas siguientes suman armadura, cicatrices, runas y tamaño.
- **Estilo:** realismo estilizado de juego de calidad: anatomía correcta, formas
  limpias y algo exageradas para que se lean de lejos, superficie trabajada (no plástico
  liso), textura pintada a mano sobre base realista.

---

## 2. Escala en el juego

| Dato | Valor |
|---|---|
| Alto en el juego (panza → punta de la aleta dorsal) | **16.5 studs** (3 jugadores de 5.5) |
| Largo esperado | **~28 a 30 studs** (alto : largo ≈ 1 : 1.7) |
| Desde dónde se ve | Desde la orilla del cráter: ~150 studs de distancia y **más arriba** que ella (el borde está a 30 de alto) |

`GiantBody` escala el modelo por su **alto**, así que el tamaño real del archivo no
importa, pero **la proporción sí**: si la orca sale más larga, en el juego será más larga.

**Consecuencia de diseño:** el jugador la ve sobre todo **desde arriba y de lado**. Lo
más trabajado tiene que estar en el **lomo, la cabeza vista desde arriba, la aleta
dorsal y los flancos**. La panza casi no se ve en esta etapa.

---

## 3. Anatomía y proporciones

Proporciones de orca juvenil real, apenas exageradas para leerse de lejos.

| Parte | Cómo debe ser |
|---|---|
| **Cuerpo** | Torpedo robusto e hidrodinámico, sección casi redonda, el punto más grueso a un tercio desde la cabeza. Se afina hacia la cola con un pedúnculo (base de la cola) fuerte y musculoso. Sin barriga de bebé. |
| **Cabeza** | ~20 % del largo. Frente redondeada (melón) que baja a un hocico **corto y romo**, sin pico. Mandíbula inferior ancha y fuerte. |
| **Boca** | **Cerrada o apenas entreabierta**, línea de boca larga y recta que sube un poco hacia el ojo. Si se abre: dientes cónicos blancos, separados, que encajan entre sí; encías rosa oscuro. Nada de sonrisa. |
| **Ojos** | **Pequeños y realistas**, oscuros, con un brillo frío turquesa muy sutil (firma del juego). Mirada al frente, atenta. Párpado inferior marcado. |
| **Espiráculo** | Uno solo, arriba de la cabeza detrás del melón, en forma de media luna. Se ve desde arriba: tiene que estar. |
| **Aleta dorsal** | Juvenil: **triangular, firme, de altura media** (~25 % del alto total), con la punta levemente curvada hacia atrás. Borde de ataque grueso, borde de salida fino. |
| **Aletas pectorales** | Grandes, **anchas y redondeadas en forma de remo** (rasgo típico de la orca), separadas del cuerpo unos 30°, con leve curvatura. |
| **Cola (aleta caudal)** | Dos lóbulos anchos con punta afilada, muesca central marcada, borde de salida fino con una ligera curva. Horizontal. |

---

## 4. Patrón de color (lo más importante para que se lea como orca)

| Zona | Color | Detalle |
|---|---|---|
| Lomo y flancos | Negro azulado `#14181F` | Brillo húmedo, no negro plano. Leve degradado a `#1E2633` en los flancos. |
| Mancha del ojo | Blanco `#EEF2F5` | **Óvalo alargado detrás y arriba del ojo**, borde nítido. Bien visible desde arriba y de lado. |
| Garganta y panza | Blanco `#EEF2F5` | Desde la punta de la mandíbula inferior hasta la cola. Detrás de la dorsal sube por los flancos en **forma de tridente** (tres puntas). |
| Silla de montar | Gris `#7E8896` | Detrás de la dorsal, borde suave y difuminado, en forma de silla. |
| Parte de abajo de la cola | Blanco `#EEF2F5` | Con borde negro fino. |
| Dientes | Marfil `#F2EEE4` | Solo si la boca está entreabierta. |
| Acento del juego | Turquesa `#3FE0D0` | Ver sección 5. |

Los bordes entre negro y blanco son **nítidos pero no de vector**: una transición de 1 a
2 % para que no parezca calcomanía.

---

## 5. Detalles que la hacen "bien hecha"

Estos detalles son los que separan un buen modelo de uno genérico. Todos tienen que
existir en la **forma** (normal map) o en la **textura**, sin geometría suelta.

**Piel**
- Superficie húmeda con brillo especular suave (rugosidad baja en el lomo, algo mayor en
  la panza).
- Pliegues finos alrededor de la base de las aletas pectorales y en la garganta.
- Músculo marcado sutilmente sobre los flancos y el pedúnculo de la cola.
- 3 o 4 **rayones claros finos** (marcas de dientes de otras orcas) en el lomo y detrás
  de la dorsal. Pocos: es joven.
- Pequeñas imperfecciones en el borde de la dorsal y de la cola (no perfectamente lisos).

**Cabeza**
- Comisura de la boca bien definida con un pliegue.
- Leve relieve sobre la mandíbula y el melón.
- El brillo del ojo turquesa muy contenido (no un foco de luz).

**Acento turquesa (firma de los monstruos del juego)**
- En la E1: **una línea fina y discontinua** a lo largo de la línea lateral de cada
  flanco (desde detrás del ojo hasta el pedúnculo) y **3 o 4 puntos** pequeños en el lomo
  a cada lado de la dorsal.
- Apenas encendido: **pintado en la textura**, no geometría. El brillo real lo pongo en el
  juego. En la E2 a E4 este patrón crece hasta ser runas brillantes.

---

## 6. Pose

- **Nadando en horizontal**, cuerpo con una **curva en S muy leve** (cabeza un poco hacia
  un lado, cola hacia el otro), cola levemente hacia abajo.
- Aletas pectorales **separadas del cuerpo** (Meshy las funde con el cuerpo si están
  pegadas).
- Boca cerrada o apenas entreabierta.
- Mirando hacia el frente.

---

## 7. Lo que NO debe tener

- Ojos grandes, pupilas de dibujo, brillos de caricatura, pestañas.
- Sonrisa, lengua afuera, rubor, expresión tierna.
- Proporciones de bebé: cabeza enorme, cuerpo corto y redondo.
- Armadura, corales, conchas, cicatrices grandes (eso es de la E2 en adelante).
- Agua, salpicaduras, burbujas, sombras, fondo, texto o logos en la imagen.
- Piezas transparentes o brillantes en la geometría.

---

## 8. Requisitos técnicos del archivo

| Requisito | Valor |
|---|---|
| Malla | **Una sola pieza cerrada**, sin partes sueltas ni caras duplicadas |
| Triángulos | **≤ 10,000** (Meshy puede dar más; yo lo reduzco en Blender) |
| Simetría | Sí (izquierda = derecha, salvo la curva leve de la pose) |
| Orientación | Mira hacia **−Z**, arriba es **+Y** |
| Origen | En la base, centrado bajo el cuerpo |
| Rig / animación | **No**: el juego la mueve por código (nado, respiración, saltos) |
| Texturas | Color + normal + rugosidad, **1024 × 1024** (límite de Roblox), embebidas en el FBX |
| UVs | Sin solapes (cada lado de las aletas en su propia isla) |
| Nombre | `OrcaE1.fbx`, en `assets/blender/` |

---

## 9. Prompts

### 9.1 Imagen principal (Nano Banana)

```
A young juvenile orca (killer whale), realistic anatomy with a stylized high-quality
game creature finish, sleek athletic torpedo-shaped body, strong muscular tail stock,
short blunt snout with a rounded melon forehead, small realistic dark eyes with a very
subtle cold turquoise glint, mouth closed with a long straight mouth line, single
crescent blowhole on top of the head, medium-height firm triangular dorsal fin slightly
curved back, large broad paddle-shaped pectoral fins held away from the body, wide tail
flukes with a sharp central notch.

Classic orca markings with crisp edges: glossy blue-black back and flanks (#14181F),
elongated white eye patch above and behind each eye, white throat and belly that sweeps
up the flanks behind the dorsal fin in a trident shape, soft grey saddle patch behind
the dorsal fin, white underside of the flukes.

Fine details: wet skin with soft specular highlights, subtle muscle definition along
the flanks, fine skin creases at the base of the pectoral fins and on the throat, a few
thin pale rake scratches on the back, slightly imperfect edges on the dorsal fin and
flukes, a thin faint dashed turquoise line along the lateral line of each flank and a
few small faint turquoise dots on the back beside the dorsal fin.

Pose: swimming horizontally with a very slight S-curve, tail slightly lowered, three-
quarter front view from slightly above, full body visible and centered.

Plain pure white background, soft even studio lighting, no cast shadows, no ground,
no water, no splash, no bubbles, no particles, no text, no logo, single creature only,
all parts solid and opaque, highly detailed, square image.
```

### 9.2 Prompt negativo (si la herramienta lo acepta)

```
cute, chibi, cartoon, baby proportions, big head, big eyes, smile, tongue, blush,
eyelashes, toy, plush, plastic look, armor, coral, shells, big scars, open roaring mouth,
water, splash, bubbles, background, shadow, ground, text, watermark, cropped, extra fins,
extra eyes, asymmetrical markings, transparent parts
```

### 9.3 Vistas extra (en el mismo chat, después de la imagen buena)

```
Same exact creature, same design, same markings, same colors, now in a strict side view
(left side), same pure white background, same lighting, full body visible.
```
```
Same exact creature, same design, same markings, same colors, now seen from directly
above (top view), same pure white background, same lighting, full body visible.
```
```
Same exact creature, same design, same markings, same colors, now seen from the back,
same pure white background, same lighting, full body visible.
```

> La vista **desde arriba** es la más importante después de la principal: es como la ve
> el jugador desde la orilla.

### 9.4 Meshy

- **Multi-image to 3D** con: principal (3/4), lado, arriba y espalda.
- Simetría: **activada**.
- Polígonos: **10,000 triángulos** (o el máximo, y lo reduzco yo).
- Textura: **activada**; si ofrece PBR, mejor (aprovecho normal y rugosidad).
- En la vista previa revisa: manchas blancas en su lugar, aletas pectorales separadas,
  cola horizontal y sin agujeros.
- Descarga en **FBX** con texturas, nómbralo `OrcaE1.fbx` y ponlo en `assets/blender/`.

---

## 10. Lista para aceptar el modelo

- [ ] Se reconoce como orca desde arriba (mancha del ojo, silla gris, dorsal).
- [ ] Se ve joven por su forma (dorsal corta, sin cicatrices grandes), **no** tierna.
- [ ] Proporción alto : largo entre 1 : 1.6 y 1 : 1.8.
- [ ] Bordes del patrón nítidos y simétricos.
- [ ] Ojos pequeños y realistas, boca cerrada o entreabierta, sin sonrisa.
- [ ] Turquesa sutil en la línea lateral y el lomo.
- [ ] Una sola malla cerrada, ≤ 10,000 triángulos, sin solapes en las UVs.
- [ ] Mira a −Z, arriba +Y, origen en la base.
- [ ] Texturas 1024 embebidas: color, normal y rugosidad.

---

## 11. Continuidad con las otras etapas

Mantener **el mismo cuerpo, el mismo patrón y la misma paleta**; cada etapa suma:

| Etapa | Alto | Qué agrega |
|---|---|---|
| E1 (esta) | 16.5 studs | Base limpia, dorsal corta, turquesa apenas encendido |
| E2 | 44 studs | Dorsal más alta, primeras placas de conchas y percebes en frente y lomo, líneas turquesa más marcadas, boca entreabierta con dientes |
| E3 | 82.5 studs | Armadura de coral y perla, cicatrices de batalla, runas turquesa, boca abierta rugiendo, anillos de oro en las pectorales |
| E4 | 165 studs | Corona de coral, dorsal de cristal, armadura de oro grabada, formas grandes y claras (la textura se estira mucho), largo ≤ 1.6 veces el alto para caber en el lago |
