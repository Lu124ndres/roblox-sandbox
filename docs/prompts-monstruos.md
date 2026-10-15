# Prompts de los monstruos (Nano Banana → Meshy)

Flujo: genera la imagen en **Nano Banana** → (opcional) pídele las vistas de lado y de
espalda → súbelas a **Meshy** (Image to 3D) → descarga el FBX → yo lo reduzco en Blender
y lo meto al juego (`docs/blender-pipeline.md`).

Cada monstruo tiene **4 etapas** (crece con la barra). En el juego se llaman
`<Monstruo>E1` … `E4` (`OrcaE1`, `OrcaE2`…). E1 es la cría y E4 la versión legendaria.

Los prompts van en **inglés** (Nano Banana los sigue mejor). A cada prompt pégale al final
el **bloque de estilo**.

## Bloque de estilo (pegar al final de cada prompt)

```
Stylized 3D game character, Roblox-friendly chunky proportions, bold readable silhouette,
hand-painted stylized textures, vibrant saturated colors, full body visible and centered,
three-quarter front view, neutral pose with fins and limbs slightly away from the body,
plain pure white background, soft even studio lighting, no cast shadows, no ground,
no water, no splash, no particles, no smoke, no text, no logo, single character only,
all parts solid and opaque, high detail, square image.
```

> Por qué: Meshy reconstruye mejor un solo personaje centrado, en vista 3/4, sobre fondo
> blanco liso, sin sombras ni efectos. El agua, el humo, las partículas y la transparencia
> no se pueden modelar: los efectos los pongo yo en el juego (brillos, burbujas, fuego).

## Orca (x2) — la estrella del juego

**E1 — Orca cría (tierna pero cool)**
```
A young baby orca whale with a big round head, huge sparkling expressive eyes, a cheeky
confident smile showing tiny white teeth, glossy black and white skin with soft turquoise
glowing spots along its sides, small rounded fins, chubby cute body, floating horizontally
with its body slightly curved.
```

**E2 — Orca guardiana**
```
A muscular young orca warrior, glossy black and white skin, armor plates made of
barnacles and seashells on its forehead and back, small pink coral growing on its dorsal
fin, glowing turquoise tribal stripes along its body, sharp white teeth, determined
fierce eyes, floating horizontally with its body slightly curved.
```

**E3 — Orca tirana**
```
A huge battle-scarred orca beast, heavily armored with polished coral and pearl plates
on its head and back, a tall jagged dorsal fin edged with big crystal shards, bright cyan
bioluminescent runes glowing along its body and fins, open roaring mouth with big sharp
teeth, angry glowing cyan eyes, golden rings on its pectoral fins, floating horizontally
with its body slightly curved.
```

**E4 — Orca titán, reina del abismo (legendaria)**
```
A colossal legendary orca titan, majestic and terrifying, a royal crown of giant coral
spikes and pearls on its head, a huge glowing crystal dorsal fin, ancient golden armor
plates engraved with glowing ocean runes along its body, turquoise and gold
bioluminescent patterns, massive open jaw with gleaming teeth, glowing turquoise eyes,
fins edged with gold, epic boss creature, floating horizontally with its body slightly
curved.
```

## Orca fantasma (x6, Halloween)

```
A spooky ghost orca for a Halloween event, pale lavender glowing skin with dark purple
stripes, ghostly bones pattern painted on its sides, tattered spectral fins shaped like
torn cloth, glowing green eyes, a pumpkin-orange glow inside its open mouth, small rusty
chains hanging from its fins, cute-creepy style, floating horizontally with its body
slightly curved.
```
(La transparencia de fantasma la pongo yo en el juego; en la imagen tiene que ser opaca.)

## Minotauro (x4) — Minotauro de magma

```
A massive fantasy minotaur bull titan made of dark volcanic rock, huge curved golden
horns, glowing orange lava cracks across its muscular body, a molten gold nose ring,
spiked stone shoulder armor, heavy broken chains on its wrists, cloven hooves, fierce
glowing orange eyes, standing upright in a powerful stance, arms slightly away from the
body, no weapon.
```

## Dragón marino (x10)

```
A majestic sea dragon, long serpentine body with turquoise and deep blue scales, shiny
pearl-white belly, big fin-shaped wings like a manta ray, a glowing coral crest and
horns on its head, bioluminescent cyan spots along its body, crystal claws on four short
legs, golden eyes, elegant and powerful, body coiled in an S shape, wings open.
```

## Zorro de agua (x20) — el más raro

```
A mythical giant water fox spirit (kitsune) with nine big tails shaped like sculpted
ocean waves (solid and opaque, stylized), sleek aqua and white fur, glowing cyan markings
on its face and paws, a crystal gem on its forehead, golden ornaments on its ears and
neck, elegant and mystical, standing on four legs, tails spread behind it like a fan.
```

## Cómo hacer las 4 etapas de los otros monstruos

Usa el prompt de arriba como **E4** y para las otras etapas cambia el principio:

- **E1:** `A cute baby version of …` + `small horns/fins, no armor, big eyes, chubby body`
- **E2:** `A young version of …` + `some armor pieces, small glowing markings`
- **E3:** `An adult battle version of …` + `more armor, scars, glowing markings`
- **E4:** el prompt completo (versión legendaria).

Para que las 4 se parezcan, genera primero la E4 y luego, **en el mismo chat de Nano
Banana**, pide: `Same exact character and colors, but as a baby / young / adult version`.

## Vistas extra para Meshy (recomendado)

En el mismo chat, después de la imagen buena:

```
Same exact character, same design, same colors, now in a strict side view, same white
background, same lighting.
```
```
Same exact character, same design, same colors, now seen from the back, same white
background, same lighting.
```

En Meshy usa **Multi-image to 3D** con frente, lado y espalda: sale mucho mejor.

## Ajustes en Meshy

- **Image to 3D** (o Multi-image si tienes las vistas).
- Simetría: **activada** (los animales son simétricos).
- Polígonos: **10,000 triángulos** (o más, y yo los reduzco en Blender).
- Textura: **activada**, sin PBR está bien (el juego usa color + normales).
- Revisa en la vista previa que esté **derecho y mirando al frente**.
- Descarga en **FBX** con texturas y nómbralo como la etapa: `OrcaE2.fbx`,
  `MinotauroE4.fbx`, etc. Ponlo en `assets/blender/` y avísame.
