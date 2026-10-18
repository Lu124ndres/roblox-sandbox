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
		-- Ruleta: la rueda de 8 casillas (gris claro/oscuro, aro azul noche con remaches;
		-- la casilla 1 arriba) y la flecha roja que marca el premio (assets/ui/).
		RuedaRuleta = "rbxassetid://73843801719045",
		PunteroRuleta = "rbxassetid://104047378525377",
		-- Ícono de Roblox Premium que trae Roblox instalado.
		PremiumIcon = "rbxasset://textures/ui/PlayerList/PremiumIcon@3x.png",
		-- Íconos del HUD: imágenes estilo 3D generadas con IA (Canva), recortadas a fondo
		-- transparente y juntadas en una hoja de 4x4 (256 px cada uno), subida con el
		-- Gestor de recursos. Fuentes y hoja en assets/ui/iconos/ (iconos_hud_v3.png).
		-- Orden por filas: moneda, poder, canasta, kills / tienda, robux, premio, ajustes /
		-- pez, códigos, amigos, grupo / colmillo.
		IconSheet = "rbxassetid://134398496257992",
		-- Hoja 2 (assets/ui/iconos/iconos_hoja2.png), por filas: caña, botas, corona,
		-- estanque / rayo, orca, minotauro, dragón / zorro, regalo rosa, flecha,
		-- carne / rayos de fondo (sunburst), brillo redondo.
		IconSheet2 = "rbxassetid://97933580602007",
		-- Hoja 3 (assets/ui/iconos/iconos_hoja3.png): monstruo panzón (monstruos llenados).
		IconSheet3 = "rbxassetid://99850577116916",
		-- Equipo de la tienda (Canva, recortado): un ícono por nivel, 5 columnas de 200 px,
		-- celda = nivel - 1 por filas. Fuentes en assets/ui/iconos/equipo_*.png.
		EquipoRod = "rbxassetid://79873240212746", -- 20 cañas
		EquipoBasket = "rbxassetid://125162908853974", -- 14 canastas
		EquipoBoots = "rbxassetid://122825125598846", -- 14 botas
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
		-- Trajes del personaje (rig_traje.py + suavizar_traje.py: piel continua, no se abren) y dragón (rig_dragon.py, en pose
		-- de vuelo): texturas horneadas con hornear.py. Fuente: assets/blender/*.fbx. Los Model
		-- están en ServerStorage (Traje<clave>, DragonMarinoE1..E4) y viven en el .rbxl.
		TrajeMarinero = "rbxassetid://75806050701803",
		TrajeDiosDelVolcan = "rbxassetid://137998127570612",
		TrajeReyDelMar = "rbxassetid://137608233485403",
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
		VIP = 0, -- R$ 299
		ReyDelMar = 0, -- R$ 149
		DiosDelVolcan = 0, -- R$ 399
	},
	Products = Products, -- productos de Robux: ver Products.luau
}

return table.freeze(Assets)
