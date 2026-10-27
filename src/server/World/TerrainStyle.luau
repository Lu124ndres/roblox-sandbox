--!strict
--[[
	TerrainStyle

	Los colores del agua y de cada material del terreno, y las nubes (los aplica
	TerrainBuilder en cada arranque: no cambian la versión del terreno guardado).
		apply(terrain)
]]

local MATERIAL = Enum.Material

local TerrainStyle = {}

function TerrainStyle.apply(terrain: Terrain)
	-- Colores saturados y cálidos, como las fotos del juego (2026-10-20). Agua desde el
	-- 2026-10-21 (más realismo, pedido del usuario): azul verdoso de mar tropical, menos
	-- reflejo (con más el agua copiaba el cielo claro y se veía lechosa) y olas más chicas y
	-- lentas (las de antes se veían de juguete).
	terrain.WaterColor = Color3.fromRGB(0, 112, 140)
	terrain.WaterTransparency = 0.4
	terrain.WaterReflectance = 0.45
	terrain.WaterWaveSize = 0.15
	terrain.WaterWaveSpeed = 10
	terrain:SetMaterialColor(MATERIAL.Grass, Color3.fromRGB(94, 182, 60))
	terrain:SetMaterialColor(MATERIAL.Sand, Color3.fromRGB(238, 206, 140))
	terrain:SetMaterialColor(MATERIAL.Cobblestone, Color3.fromRGB(126, 118, 108))
	terrain:SetMaterialColor(MATERIAL.Rock, Color3.fromRGB(128, 120, 112))
	terrain:SetMaterialColor(MATERIAL.Basalt, Color3.fromRGB(42, 38, 46))
	terrain:SetMaterialColor(MATERIAL.CrackedLava, Color3.fromRGB(255, 96, 40))
	terrain:SetMaterialColor(MATERIAL.Slate, Color3.fromRGB(150, 150, 156))
	terrain:SetMaterialColor(MATERIAL.Mud, Color3.fromRGB(96, 78, 54)) -- orillas de los estanques
	-- Pasto corto del jardín de entrenamiento (sin el pasto alto de Grass, que tapaba el agua).
	terrain:SetMaterialColor(MATERIAL.LeafyGrass, Color3.fromRGB(90, 176, 56))
	-- Fondo claro del lago del cráter: bajo el agua se ve turquesa (y el gigante resalta).
	terrain:SetMaterialColor(MATERIAL.Limestone, Color3.fromRGB(52, 92, 92))
	terrain:SetMaterialColor(MATERIAL.Asphalt, Color3.fromRGB(58, 46, 48)) -- cumbres del volcán
	-- Rocas del desierto del minotauro (las escribe el cliente: Ambient/SandTerrain).
	terrain:SetMaterialColor(MATERIAL.Sandstone, Color3.fromRGB(186, 128, 84))
	if not terrain:FindFirstChildOfClass("Clouds") then
		local clouds = Instance.new("Clouds")
		clouds.Cover = 0.55
		clouds.Density = 0.6
		clouds.Parent = terrain
	end
end

return table.freeze(TerrainStyle)
