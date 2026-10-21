--!strict
--[[
	ProtocolMap: nombres de las piezas del mapa (world/Isla.model.json) que el
	código busca. Protocol lo expone como Protocol.Map.
]]

-- Piezas de world/Isla.model.json que el código busca por nombre.
return table.freeze({
	Root = "Isla",
	ShopCounter = "Mostrador", -- mostrador de la cabaña: ahí se abre la tienda (E)
	Lighthouse = "Faro",
	LighthouseBeam = "Haz",
	TrainingPond = "Estanque", -- pieza del estanque; atributo "Indice" = 1..N
	PondIndexAttribute = "Indice",
	GiantAnchor = "GuaridaGigante",
	RestArena = "GuaridaDescanso", -- modelo en ServerStorage: la plataforma del descanso
	Buoys = "Boyas",
	Foam = "Espuma",
	Habitat = "Habitat", -- Workspace.Habitat: los props del hábitat del gigante actual (HabitatService)
	BlockIsland = "IslaBloques", -- Workspace.IslaBloques: el suelo de la isla en mallas (BlockIsland)
	PondWaterPrefix = "Lamina_", -- Lamina_<n>: el agua de color del estanque n, dentro de IslaBloques
})
