--!strict
--[[
	BlockIsland

	La isla de bloques: el suelo de la isla en mallas de Blender en lugar del terreno de
	Roblox (tools/blender/isla_bloques*.py; pedido del usuario, docs/decisiones.md). Las
	mallas viven en ServerStorage.IslaBloques (en el .rbxl, ya en su lugar) y al arrancar
	se copian a Workspace.IslaBloques:
		IslaSector_*      suelo (se choca)
		RampaSendero_*    rampas de los senderos elevados (se choca)
		AroEstanque_*     aro de piedras de cada estanque (se choca)
		Lamina_<n>        agua del estanque n: del color del estanque, sin chocar; el cliente
		                  la muestra viva o pálida según si lo tiene abierto (Training/PondFx)
		MatasMonticulos   matas sobre los montículos (sin chocar)
	Sin ServerStorage.IslaBloques el mapa queda como antes: el terreno pone la isla.
		present() -> boolean
		place()
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)

local SOURCE = Protocol.Map.BlockIsland -- en ServerStorage, y la copia en Workspace
local SOLID = { "IslaSector_", "RampaSendero_", "AroEstanque_" }
local WATER_PREFIX = Protocol.Map.PondWaterPrefix
local POND_REFLECTANCE = 0.3

local BlockIsland = {}

function BlockIsland.present(): boolean
	return ServerStorage:FindFirstChild(SOURCE) ~= nil
end

local function startsWithAny(name: string, prefixes: { string }): boolean
	for _, prefix in prefixes do
		if string.sub(name, 1, #prefix) == prefix then
			return true
		end
	end
	return false
end

-- El agua de un estanque: color plano del estanque (sin la textura), el cliente la anima.
-- Vidrio con reflejo: en plástico liso se veía como una lámina de plástico, no como agua.
local function water(part: MeshPart, index: number)
	part.TextureID = ""
	part.Color = UIConfig.PondColors[index] or part.Color
	part.Material = Enum.Material.Glass
	part.Reflectance = POND_REFLECTANCE
	part.CastShadow = false
	part:SetAttribute(Protocol.Map.PondIndexAttribute, index)
end

function BlockIsland.place()
	local source = ServerStorage:FindFirstChild(SOURCE)
	if not source then
		return
	end
	local model = Instance.new("Model")
	model.Name = SOURCE
	-- Siempre cargada aunque el lugar use streaming: la isla se ve entera desde cualquier lado.
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	local count = 0
	for _, item in source:GetDescendants() do
		if not item:IsA("MeshPart") then
			continue
		end
		local part = item:Clone()
		part.Anchored = true
		local solid = startsWithAny(part.Name, SOLID)
		part.CanCollide = solid
		part.CanQuery = solid
		part.CanTouch = false
		if string.sub(part.Name, 1, #WATER_PREFIX) == WATER_PREFIX then
			water(part, tonumber(string.sub(part.Name, #WATER_PREFIX + 1)) or 0)
		end
		part.Parent = model
		count += 1
	end
	model.Parent = Workspace
	print(`BlockIsland: isla de bloques con {count} mallas`)
end

return table.freeze(BlockIsland)
