--!strict
--[[
	Assets

	Registro central de todos los rbxassetid del juego. Ningún otro módulo
	escribe un ID inline: siempre se referencian como Assets.UI.NombreDelAsset.

	Ventajas: un solo lugar para auditar qué assets usa el juego, reemplazar
	uno no exige buscar en todo el código, y los IDs faltantes son visibles.

	Si un asset todavía no existe, se deja como MISSING ("rbxassetid://0")
	y se anota en docs/ui-assets.md con su estado.

	Secciones:
		UI          Imágenes 2D de interfaz (paneles, botones, íconos). Origen: ForgeGUI.
		Meshes      MeshId de modelos importados desde Blender. La clave es también el
					nombre del Model en ServerStorage (GiantModel valida que coincidan).
		Textures    Texturas tileables (ForgeGUI) y texturas de mesh (Blender, fase 2).
					Las de mesh van con sufijo de canal: Color, Normal, Roughness.
		Sounds      Efectos y ambiente. Los "rbxasset://sounds/..." vienen instalados con
					Roblox (no hay que subirlos). Las claves en MISSING no suenan.
		Particles   Texturas de partículas: las que trae Roblox y las propias (assets/particulas).
		Animations  Reservado. Este proyecto anima por código (TweenService/CFrame);
					solo se usaría si una decisión en docs/decisiones.md lo cambia.

	Nomenclatura: claves en PascalCase, descriptivas (PanelBackground, no Img1).
]]

local Products = require(script.Products)
local Sounds = require(script.Sounds)
local Textures = require(script.Textures)

export type AssetMap = { [string]: string }

export type Assets = {
	MISSING: string,
	UI: AssetMap,
	Meshes: AssetMap,
	Textures: { [string]: { string } }, -- por modelo: color, normales, rugosidad, metal
	Sounds: AssetMap,
	Particles: AssetMap,
	Animations: AssetMap,
	Badges: { [string]: number },
	GamePasses: { [string]: number },
	Products: { [string]: number },
}

local Assets: Assets = {
	-- Marcador para assets pendientes. Buscar "MISSING" lista lo que falta subir.
	MISSING = "rbxassetid://0",

	UI = {
		-- Ícono de Robux que trae Roblox instalado (no hay que subirlo).
		RobuxIcon = "rbxasset://textures/ui/common/robux.png",
		-- Viñeta blanca (bordes opacos, centro transparente) que se tiñe con ImageColor3:
		-- el brillo azul de los bordes al entrenar (assets/ui/Vineta.png).
		Vineta = "rbxassetid://94536198570437",
		-- Ruleta con la temática de la interfaz: rueda de 8 casillas (piedra volcánica y
		-- roja de lava, separadores dorados, aro de piedra con grietas de lava y remaches
		-- dorados; la casilla 1 arriba) y la gema de lava que marca el premio. Las dibuja
		-- tools/ui/generar_ruleta.py con la geometría de la rueda anterior (assets/ui/ruleta_v2/).
		RuedaRuleta = "rbxassetid://103590278651247", -- 9 casillas: la 9 (violeta) es la caña suprema
		PunteroRuleta = "rbxassetid://71593213487154",
		-- Ícono de Roblox Premium que trae Roblox instalado.
		PremiumIcon = "rbxasset://textures/ui/PlayerList/PremiumIcon@3x.png",
		-- Íconos pintados a mano, hechos con la IA de Canva sobre un ícono maestro (la moneda)
		-- y la referencia volcánica del usuario (assets/ui/iconos/v4/, docs/ui-assets.md).
		-- Hojas de 4x4 de 256 px. HUD, por filas: moneda, poder, canasta con peces, monstruo
		-- alimentado / canasta, cofre, regalo, engranaje / pez, boleto, amigos, grupo /
		-- colmillo, cuenco de peces (sin uso), ruleta, pack de inicio.
		IconSheet = "rbxassetid://110280301406648",
		-- Hoja 2, por filas: caña, botas, corona, estanque / rayo, orca, minotauro, dragón /
		-- zorro, regalo rosa, flecha, carne / rayos de fondo (sunburst), brillo redondo.
		IconSheet2 = "rbxassetid://89496859008486",
		-- Hoja 3 (v4/iconos_v4_hoja3.png): calendario del diario, caña suprema, Dios del Volcán,
		-- Rey del Mar.
		IconSheet3 = "rbxassetid://101327392927525",
		-- Equipo de la tienda (v4, Canva): un ícono por nivel en hojas de 5x4 celdas de 200 px;
		-- la hoja 1 tiene los niveles 1-20 y la 2 los 21-40 (Interface/GearIcons).
		-- Fuentes en assets/ui/iconos/v4/equipo/ (tools/ui/armar_hojas_equipo.py).
		EquipoRod1 = "rbxassetid://81312902149564", -- cañas 1-20
		EquipoRod2 = "rbxassetid://139047610937566", -- cañas 21-40
		EquipoBasket1 = "rbxassetid://103473328998101", -- canastas 1-20
		EquipoBasket2 = "rbxassetid://88975165692196", -- canastas 21-34
		EquipoBoots1 = "rbxassetid://132274235368393", -- botas 1-20
		EquipoBoots2 = "rbxassetid://73284489356357", -- botas 21-34
		-- Kit de la interfaz: piedra volcánica con grietas de lava, hecho con la IA de Canva sobre
		-- las referencias del usuario (tools/ui/recortar_kit_canva.py → assets/ui/kit_canva/).
		-- 9-slice; los cortes están en Interface/Kit.
		PiedraPanel = "rbxassetid://137296723636788", -- panel con grietas de lava
		PiedraHondo = "rbxassetid://120432474669335", -- hueco tallado (barras, contadores)
		PiedraBoton = "rbxassetid://130492460203337", -- botón de piedra gris con canto dorado (MEJORAS)
		PiedraLava = "rbxassetid://80491001045798", -- botón rojo con marco de lava (TIENDA)
		PiedraCasilla = "rbxassetid://103089949967085", -- casilla de objeto de piedra con lava
		PiedraCristales = "rbxassetid://71352910897295", -- cristales oscuros junto a los títulos
		PiedraPedestal = "rbxassetid://76404155830524", -- pedestal volcánico (detalle de MEJORAS)
		-- Gema azul del kit anterior (tools/ui/generar_kit_piedra.py): panel del monstruo.
		PiedraGema = "rbxassetid://96530857668285",
	},

	Meshes = {
		-- Orca en 4 etapas (modelos de Meshy reducidos y con huesos para nadar y abrir la
		-- boca: tools/blender/procesar_meshy.py y rig_orca.py). Fuente: assets/blender/OrcaE*.fbx.
		-- Los Model están en ServerStorage.OrcaE1..E4 (viven en el .rbxl).
		OrcaE1 = "rbxassetid://76881950583956", -- bebé (7,840 triángulos)
		OrcaE2 = "rbxassetid://82096879151924", -- joven (11,760)
		OrcaE3 = "rbxassetid://92524573839860", -- adulta (15,680)
		OrcaE4 = "rbxassetid://130326642022252", -- anciana (19,110)
		-- Minotauro bebé con huesos (tools/blender/minotauro_e1.py + rig_minotauro_e1.py, 18k
		-- triángulos). Model en ServerStorage.MinotauroE1; se anima con Shared.Minotauro.
		MinotauroE1 = "rbxassetid://138675592345337",
		MinotauroE2 = "rbxassetid://91533993938693", -- joven (minotauro_etapas.py, 18.6k)
		MinotauroE3 = "rbxassetid://84011204972654", -- adulto (19.4k)
		MinotauroE4 = "rbxassetid://105475430016255", -- forma final con lava (19.9k)
		-- Minotauro v2 de bloques (rig_minotauro_v2.py, 28 huesos). Models en
		-- ServerStorage.MinotauroE<n>_v2; se usan en lugar de MinotauroE<n> (modelSuffix en Config).
		MinotauroE1_v2 = "rbxassetid://122555252081745", -- becerro (3,966 triángulos)
		MinotauroE2_v2 = "rbxassetid://105048502299348", -- joven (4,946)
		MinotauroE3_v2 = "rbxassetid://112201493043935", -- adulto (4,276)
		MinotauroE4_v2 = "rbxassetid://123237644499937", -- forma final (5,916)
		-- Dragón marino v2 de bloques (rig_dragon_v2.py, 32 huesos; docs/plan_dragon_v2.md).
		-- Models en ServerStorage.DragonMarinoE<n>_v2; se usan en lugar de DragonMarinoE<n>.
		DragonMarinoE1_v2 = "rbxassetid://130204213631093", -- cría (6,796 triángulos)
		DragonMarinoE2_v2 = "rbxassetid://120863289975810", -- joven (6,814)
		DragonMarinoE3_v2 = "rbxassetid://135154957159749", -- adulto (7,282)
		DragonMarinoE4_v2 = "rbxassetid://129375458738404", -- anciano (10,908)
		-- Zorro de agua v2 de bloques (rig_zorro_v2.py; docs/plan_zorro_v2.md). Models en
		-- ServerStorage.ZorroDeAguaE<n>_v2; se usan en lugar de ZorroDeAguaE<n>.
		ZorroDeAguaE1_v2 = "rbxassetid://136623198338034", -- cría, 1 cola (3,940 triángulos, 36 huesos)
		ZorroDeAguaE2_v2 = "rbxassetid://121650889617604", -- joven, 3 colas (4,604, 46)
		ZorroDeAguaE3_v2 = "rbxassetid://84846756727124", -- adulto, 6 colas (7,604, 61)
		ZorroDeAguaE4_v2 = "rbxassetid://101856396424858", -- forma final, 9 colas (10,332, 76)
		-- Orca v2 de bloques (rig_orca_v2.py; docs/plan_orca_v2.md). Models en
		-- ServerStorage.OrcaE<n>_v2; se usan en lugar de OrcaE<n>. 20 huesos (OjoIzqMira y
		-- OjoDerMira: las pupilas de GiantEyes).
		OrcaE1_v2 = "rbxassetid://72414859955031", -- cría (4,340 triángulos)
		OrcaE2_v2 = "rbxassetid://132231555278043", -- joven (4,128)
		OrcaE3_v2 = "rbxassetid://82287267274223", -- adulta (4,742)
		OrcaE4_v2 = "rbxassetid://103685738191709", -- anciana (11,230)
		-- Trajes del personaje (rig_traje.py + suavizar_traje.py: piel continua, no se abren) y dragón (rig_dragon.py, en pose
		-- de vuelo): texturas horneadas con hornear.py. Fuente: assets/blender/*.fbx. Los Model
		-- están en ServerStorage (Traje<clave>, DragonMarinoE1..E4) y viven en el .rbxl.
		-- Marinero v2 de bloques (tools/blender/marinero_v2.py): una sola malla cerrada, paleta
		-- plana y cara, pecho y espalda dibujados (5,332 triángulos, 16 huesos). El de Meshy
		-- quedó en ServerStorage.Respaldos.TrajeMarinero_meshy.
		TrajeMarinero = "rbxassetid://140300273939135",
		-- Rey del Mar y Dios del Volcán v2 (tools/blender/traje_v2.py): bloques con mucho detalle,
		-- textura dibujada y máscara de brillo (EmissiveMask). Los de Meshy quedaron en
		-- ServerStorage.Respaldos.Traje*_meshy.
		TrajeDiosDelVolcan = "rbxassetid://140208758172851", -- 15,812 triángulos, 16 huesos
		TrajeReyDelMar = "rbxassetid://77866847879162", -- 14,784 triángulos, 18 huesos (capa)
		DragonMarinoE1 = "rbxassetid://122661699655092", -- cría (15,679 triángulos)
		DragonMarinoE2 = "rbxassetid://110887980669740", -- joven (17,639)
		DragonMarinoE3 = "rbxassetid://115962400260493", -- adulto (18,619)
		DragonMarinoE4 = "rbxassetid://79052568964105", -- anciano (19,109)
	},

	-- SurfaceAppearance (color, normales, rugosidad, metal) de cada modelo: ver Textures.luau.
	Textures = Textures,

	Sounds = Sounds,

	Particles = {
		Sparkle = "rbxasset://textures/particles/sparkles_main.dds",
		Mist = "rbxasset://textures/particles/smoke_main.dds",
		Spark = "rbxasset://textures/particles/fire_sparks_main.dds",
		-- Propias (tools/particulas/gen.py → assets/particulas, subidas con la cola de
		-- importación; IDs comprobados por nombre con GetProductInfo). Flip = hoja 4x4.
		FuegoFlip = "rbxassetid://127083091944283", -- lengua de fuego que sube y se rompe
		AguaFlip = "rbxassetid://72827308650589", -- medialuna de agua que gira
		Brasa = "rbxassetid://80818306008631", -- punto brillante
		Halo = "rbxassetid://137612863537144", -- brillo suave
		Anillo = "rbxassetid://117172895853116", -- aro de onda expansiva
		Chispa = "rbxassetid://107302182061265", -- estrella de 4 puntas
		Burbuja = "rbxassetid://79211346188373",
	},

	Animations = {},

	-- Insignias: se crean en el Creator Hub (juego publicado) y su ID (número) va aquí.
	-- Mientras estén en 0, el logro se ve en el juego pero no se entrega la insignia.
	Badges = {
		PrimerPez = 0,
		PrimerRaro = 0,
		PrimerLegendario = 0,
		PrimerMitico = 0,
		PrimeraKill = 0,
		DiezKills = 0,
		Coleccion = 0,
		Tutorial = 0,
		EstanqueMaximo = 0,
	},

	-- Pases de Robux (Config.Monetization.passes): se crean en el Creator Hub con
	-- el juego publicado y su ID va aquí. En 0 la tienda lo muestra sin vender.
	GamePasses = {
		VIP = 2036600514, -- R$ 299
		ReyDelMar = 2037994956, -- R$ 149
		DiosDelVolcan = 2036326912, -- R$ 858
	},
	Products = Products, -- productos de Robux: ver Products.luau
}

return table.freeze(Assets)
