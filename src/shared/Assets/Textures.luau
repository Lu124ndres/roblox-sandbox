--!strict
--[[
	Assets/Textures

	Texturas de la SurfaceAppearance de cada modelo con malla: color, normales,
	rugosidad y metal (en ese orden). Las suben con el modelo "Importar 3D" de
	Studio; las de los trajes y el dragón salen horneadas (tools/blender/hornear.py).
	Comprobadas contra los modelos de ServerStorage (SurfaceAppearance de cada uno).
]]

local Textures: { [string]: { string } } = {
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
		"rbxassetid://89146246907117",
		"rbxassetid://113491738122780",
		"rbxassetid://108677452943936",
		"rbxassetid://95878087325184",
	},
	TrajeDiosDelVolcan = {
		"rbxassetid://77759288531529",
		"rbxassetid://130245906074386",
		"rbxassetid://122231055952195",
		"rbxassetid://74275957368535",
	},
	TrajeReyDelMar = {
		"rbxassetid://106717356246032",
		"rbxassetid://96199206755173",
		"rbxassetid://132643107983072",
		"rbxassetid://96859161440502",
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
