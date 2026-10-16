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
	},

	Meshes = {
		-- Orca en 4 etapas (modelos de Meshy reducidos y con huesos para nadar y abrir la
		-- boca: tools/blender/procesar_meshy.py y rig_orca.py). Fuente: assets/blender/OrcaE*.fbx.
		-- Los Model están en ServerStorage.OrcaE1..E4 (viven en el .rbxl).
		OrcaE1 = "rbxassetid://129807151713126", -- bebé (7,840 triángulos)
		OrcaE2 = "rbxassetid://110833679153524", -- joven (11,760)
		OrcaE3 = "rbxassetid://119056308763073", -- adulta (15,680)
		OrcaE4 = "rbxassetid://131514620036527", -- anciana (19,110)
		-- Pendiente de modelar. Mientras falte, el juego usa un marcador de primitivas.
		MinotauroE1 = "rbxassetid://0",
		-- Trajes del personaje (rig_traje.py, piezas rígidas) y dragón (rig_dragon.py, en pose
		-- de vuelo): texturas horneadas con hornear.py. Fuente: assets/blender/*.fbx. Los Model
		-- están en ServerStorage (Traje<clave>, DragonMarinoE1..E4) y viven en el .rbxl.
		TrajeMarinero = "rbxassetid://83830844529752",
		TrajeDiosDelVolcan = "rbxassetid://95937648548247",
		TrajeReyDelMar = "rbxassetid://87925923644162",
		DragonMarinoE1 = "rbxassetid://93227317182170", -- cría (15,679 triángulos)
		DragonMarinoE2 = "rbxassetid://127430445743010", -- joven (17,639)
		DragonMarinoE3 = "rbxassetid://111211189301600", -- adulto (18,619)
		DragonMarinoE4 = "rbxassetid://124386917827503", -- anciano (19,109)
	},

	-- SurfaceAppearance (color, normales, rugosidad, metal) de cada modelo: ver Textures.luau.
	Textures = Textures,

	Sounds = {
		-- Ambiente
		OceanWaves = "rbxassetid://137826155053556", -- "Ocean waves" (3:03)
		Seagull = "rbxassetid://111686121161530", -- graznido corto (0:05)
		-- Pesca
		RodOut = "rbxasset://sounds/action_jump.mp3",
		Cast = "rbxassetid://135315310485417", -- latigazo (sword swing)
		Plop = "rbxasset://sounds/impact_water.mp3",
		Bite = "rbxassetid://137273815815490", -- burbuja (bubble pop)
		Reel = "rbxassetid://79404754846319", -- carrete (fishing reel)
		Catch = "rbxasset://sounds/impact_water.mp3",
		Escape = "rbxasset://sounds/impact_water.mp3",
		FishFlop = "rbxassetid://9114447775", -- "Fish Flop Gooshy 5"
		CatchPop = "rbxassetid://109359226723492", -- "cartoon bubble pop" (común y poco común)
		RareCatch = "rbxassetid://108936817882815", -- "item drop 3 rare"
		EpicCatch = "rbxassetid://112485797063762", -- "UI - Level Up"
		LegendaryCatch = "rbxassetid://134821092416328", -- "Rewards Level Up Next Tier"
		Whoosh = "rbxassetid://123796710194563", -- "Whoosh" (peces lanzados al gigante)
		-- Gigante
		Chomp = "rbxassetid://99444504938110", -- mordida (eating sound)
		OrcaCall = "rbxassetid://5696958591", -- "Orca sounds"
		Spout = "rbxasset://sounds/action_swim.mp3",
		BigSplash = "rbxasset://sounds/impact_water.mp3",
		StageUp = "rbxassetid://3454671965", -- fanfarria (badge fanfare)
		Roar = "rbxassetid://133651202885353", -- "Monster Roar"
		-- Música (con licencia de Roblox: APM y DistroKid, se pueden usar en cualquier juego)
		MusicIsland = "rbxassetid://128770946473000", -- "The Fisherman's Small Boat" (2:39)
		MusicCrater = "rbxassetid://1843867314", -- "Tension Repeat Drones 29" (2:04)
		MusicRest = "rbxassetid://9046678292", -- "Work Like A Champion" (2:25)
		-- Cráter
		HorrorAmbience = "rbxassetid://138890398994853", -- ambiente de terror (3:20)
		Thunder = "rbxassetid://139319051979882", -- "Thunder"
		-- Interfaz
		Coins = "rbxassetid://135483737426662", -- "Coin Collect"
		CoinPop = "rbxassetid://135483737426662", -- la misma, aguda y bajita: cada moneda que llega
		Click = "rbxassetid://139719503904449", -- clic de interfaz
		PowerTick = "rbxassetid://137273815815490", -- la misma burbuja de Bite, más aguda
	},

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
