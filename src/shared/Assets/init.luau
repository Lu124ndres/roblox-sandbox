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
		Particles   Texturas de partículas que trae Roblox (rbxasset://textures/particles).
		Animations  Reservado. Este proyecto anima por código (TweenService/CFrame);
					solo se usaría si una decisión en docs/decisiones.md lo cambia.

	Nomenclatura: claves en PascalCase, descriptivas (PanelBackground, no Img1).
]]

local Products = require(script.Products)

export type AssetMap = { [string]: string }

export type Assets = {
	MISSING: string,
	UI: AssetMap,
	Meshes: AssetMap,
	Textures: AssetMap,
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
	},

	Meshes = {
		-- Orca etapa 1 (modelo de Meshy reducido, 9,600 triángulos, con huesos para
		-- nadar y abrir la boca: tools/blender/rig_orca.py). Fuente:
		-- assets/blender/OrcaE1.fbx. Model en ServerStorage.OrcaE1 (vive en el .rbxl).
		OrcaE1 = "rbxassetid://107562062733485",
		-- Pendiente de modelar. Mientras falte, el juego usa un marcador de primitivas.
		MinotauroE1 = "rbxassetid://0",
	},

	Textures = {
		-- SurfaceAppearance de la orca etapa 1. Fuente: assets/textures/OrcaE1_*.png.
		OrcaE1Color = "rbxassetid://127128851587935",
		OrcaE1Normal = "rbxassetid://117533377898225",
		OrcaE1Roughness = "rbxassetid://75086159412197",
		OrcaE1Metalness = "rbxassetid://77816773195561",
	},

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
