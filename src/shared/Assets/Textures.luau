--!strict
--[[
	Assets/Textures

	Texturas de la SurfaceAppearance de cada modelo con malla: color, normales,
	rugosidad y metal (en ese orden). Las suben con el modelo "Importar 3D" de
	Studio; las de los trajes y el dragón salen horneadas (tools/blender/hornear.py).
	Comprobadas contra los modelos de ServerStorage (SurfaceAppearance de cada uno).
]]

local Textures: { [string]: { string } } = {
	MinotauroE1 = { -- color y normales (rig_minotauro_e1.py)
		"rbxassetid://100759657454248",
		"rbxassetid://109198970088136",
	},
	MinotauroE2 = { "rbxassetid://85752100448730", "rbxassetid://126704727757248" },
	-- v2 de bloques: solo color de la paleta, en el TextureID de la MeshPart (sin SurfaceAppearance).
	MinotauroE1_v2 = { "rbxassetid://99845921194303" },
	MinotauroE2_v2 = { "rbxassetid://137284523253350" },
	MinotauroE3_v2 = { "rbxassetid://97172953101798" },
	MinotauroE4_v2 = { "rbxassetid://86563923351119" },
	DragonMarinoE1_v2 = { "rbxassetid://139489082085068" },
	DragonMarinoE2_v2 = { "rbxassetid://135997385881259" },
	DragonMarinoE3_v2 = { "rbxassetid://116412228033154" },
	DragonMarinoE4_v2 = { "rbxassetid://111449396829545" },
	ZorroDeAguaE1_v2 = { "rbxassetid://73907487780182" },
	ZorroDeAguaE2_v2 = { "rbxassetid://91864111945766" },
	ZorroDeAguaE3_v2 = { "rbxassetid://93954367297825" },
	ZorroDeAguaE4_v2 = { "rbxassetid://76231564789175" },
	OrcaE1_v2 = { "rbxassetid://94710639147439" },
	OrcaE2_v2 = { "rbxassetid://74957147767148" },
	OrcaE3_v2 = { "rbxassetid://115537014242239" },
	OrcaE4_v2 = { "rbxassetid://87538103794612" },
	MinotauroE3 = { "rbxassetid://90468027558818", "rbxassetid://82219820175391" },
	MinotauroE4 = { "rbxassetid://108740223585461", "rbxassetid://96009656170909" },
	OrcaE1 = {
		"rbxassetid://71957072265867",
		"rbxassetid://96425004406950",
		"rbxassetid://136742021496638",
		"rbxassetid://124811014431361",
	},
	OrcaE2 = {
		"rbxassetid://115410241013048",
		"rbxassetid://77696394182660",
		"rbxassetid://79855472680358",
		"rbxassetid://138965288650521",
	},
	OrcaE3 = {
		"rbxassetid://128239156725457",
		"rbxassetid://111345670740047",
		"rbxassetid://106258607441741",
		"rbxassetid://81140731876410",
	},
	OrcaE4 = {
		"rbxassetid://94834853518339",
		"rbxassetid://116198259641181",
		"rbxassetid://85563111169953",
		"rbxassetid://87177939844055",
	},
	TrajeMarinero = { "rbxassetid://133730397975971" }, -- v2: paleta y dibujos, en el TextureID
	-- v2: color y máscara de brillo (EmissiveMaskContent de la SurfaceAppearance).
	TrajeDiosDelVolcan = { "rbxassetid://130580727380840", "rbxassetid://77506412592128" },
	TrajeReyDelMar = { "rbxassetid://97009037020054", "rbxassetid://114700820982396" },
	-- Paleta de los props del mapa (palmeras, arbustos, rocas, crestas, bordes de estanque):
	-- ServerStorage.PropsMapa, de tools/blender/props_mapa.py. Solo color.
	PropsMapa = {
		"rbxassetid://89441442365011",
	},
	-- Paleta de los hábitats del volcán (tools/blender/habitats.py): todas las MeshPart de
	-- ServerStorage.Habitats la usan como TextureID.
	Habitats = {
		"rbxassetid://134456250874584",
	},
	-- Faro (tools/blender/faro.py): ServerStorage.PropsMapa.Faro, malla 93817126470443.
	Faro = {
		"rbxassetid://87535138846026",
	},
	-- Arco del volcán (tools/blender/arco_volcan.py): ServerStorage.PropsMapa.ArcoVolcan,
	-- malla 111989690973334. La lava (ArcoVolcanLava, malla 127615265814733) no lleva
	-- textura: PropDresser la pone en Neon.
	ArcoVolcan = {
		"rbxassetid://85903901993794",
	},
	-- Santuario flotante de la guarida (tools/blender/guarida_santuario.py):
	-- ServerStorage.PropsMapa.GuaridaPiso, GuaridaRoca y GuaridaBorde. La lava
	-- (GuaridaLava) no lleva textura: PropDresser la pone en Neon.
	GuaridaSantuario = {
		"rbxassetid://76682386384168",
	},
	DragonMarinoE1 = {
		"rbxassetid://84201486554941",
		"rbxassetid://121296317760278",
		"rbxassetid://80832762420905",
		"rbxassetid://107568385677657",
	},
	DragonMarinoE2 = {
		"rbxassetid://107874757779456",
		"rbxassetid://132270997387496",
		"rbxassetid://77141390193472",
		"rbxassetid://98598000199212",
	},
	DragonMarinoE3 = {
		"rbxassetid://123730641859677",
		"rbxassetid://77580817067008",
		"rbxassetid://86788418021584",
		"rbxassetid://86450712525844",
	},
	DragonMarinoE4 = {
		"rbxassetid://122533919588983",
		"rbxassetid://81005606137867",
		"rbxassetid://116214908013708",
		"rbxassetid://86206988775411",
	},
}

return table.freeze(Textures)
