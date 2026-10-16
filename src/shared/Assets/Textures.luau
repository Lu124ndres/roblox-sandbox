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
	TrajeMarinero = {
		"rbxassetid://113460336252700",
		"rbxassetid://102842851756367",
		"rbxassetid://97686605758520",
		"rbxassetid://72251172173704",
	},
	TrajeDiosDelVolcan = {
		"rbxassetid://125619571040084",
		"rbxassetid://77768817509140",
		"rbxassetid://102605187441214",
		"rbxassetid://81441919313686",
	},
	TrajeReyDelMar = {
		"rbxassetid://132536745289693",
		"rbxassetid://91907974716896",
		"rbxassetid://97665118692211",
		"rbxassetid://128489403904139",
	},
	-- Paleta de los props del mapa (palmeras, arbustos, rocas, crestas, bordes de estanque):
	-- ServerStorage.PropsMapa, de tools/blender/props_mapa.py. Solo color.
	PropsMapa = {
		"rbxassetid://89441442365011",
	},
	-- Faro (tools/blender/faro.py): ServerStorage.PropsMapa.Faro, malla 93817126470443.
	Faro = {
		"rbxassetid://87535138846026",
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
