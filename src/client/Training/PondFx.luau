--!strict
--[[
	PondFx

	El contorno de luz de cada estanque de entrenamiento (las piezas
	BrilloOrilla vienen del mapa, tools/estanques):
		- se asienta en el suelo: el agua del terreno va en bloques de 4 studs y
		  no sigue la curva de la orilla, así que cada tramo baja con un rayo
		  hasta el barro (si no, quedaba flotando). El terreno lo arma el
		  servidor al arrancar: se reintenta hasta encontrarlo;
		- brilla siempre del color del estanque: fuerte si el jugador lo tiene
		  abierto y más tenue (semitransparente) si todavía no, así de un
		  vistazo se sabe a cuáles puede entrar sin que ninguno quede apagado.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Perks = require(ReplicatedStorage.Shared.Perks)
local Protocol = require(ReplicatedStorage.Shared.Protocol)

local LIFT = 0.12 -- sobre el suelo, para que no parpadee con el terreno
local PROBE = 12 -- studs arriba y abajo del tramo donde se busca el suelo
local RETRY_SECONDS = 1
local MAX_TRIES = 40
local LOCKED_SEE_THROUGH = 0.55 -- cerrado: el mismo color, más tenue

type Rim = { index: number, parts: { BasePart }, color: Color3, open: boolean? }

local PondFx = {}

local function collect(map: Instance): { Rim }
	local rims = {}
	for _, descendant in map:GetDescendants() do
		local index = descendant:GetAttribute(Protocol.Map.PondIndexAttribute)
		if descendant.Name == "BrilloOrilla" and type(index) == "number" then
			local parts = {}
			for _, child in descendant:GetChildren() do
				if child:IsA("BasePart") then
					table.insert(parts, child)
				end
			end
			if #parts > 0 then
				table.insert(
					rims,
					{ index = index, parts = parts, color = parts[1].Color, open = nil }
				)
			end
		end
	end
	return rims
end

-- Baja cada tramo hasta el suelo del terreno. Devuelve cuántos no encontraron suelo.
local function settle(rims: { Rim }): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { Workspace.Terrain }
	params.IgnoreWater = true
	local missing = 0
	for _, rim in rims do
		for _, part in rim.parts do
			if part:GetAttribute("Asentado") then
				continue
			end
			local hit = Workspace:Raycast(
				part.Position + Vector3.new(0, PROBE, 0),
				Vector3.new(0, -2 * PROBE, 0),
				params
			)
			if hit then
				part.CFrame = part.CFrame.Rotation
					+ hit.Position
					+ Vector3.new(0, LIFT + part.Size.Y / 2, 0)
				part:SetAttribute("Asentado", true)
			else
				missing += 1
			end
		end
	end
	return missing
end

local function paint(rim: Rim, open: boolean)
	if rim.open == open then
		return
	end
	rim.open = open
	for _, part in rim.parts do
		part.Material = Enum.Material.Neon
		part.Color = rim.color
		part.Transparency = if open then 0 else LOCKED_SEE_THROUGH
	end
end

function PondFx.start()
	local player = Players.LocalPlayer
	local map = Workspace:WaitForChild(Protocol.Map.Root)
	local rims = collect(map)

	local function refresh()
		for _, rim in rims do
			paint(rim, Perks.pondOpen(player, rim.index))
		end
	end
	player.AttributeChanged:Connect(function(name: string)
		if Perks.affectsPonds(name) then
			refresh()
		end
	end)
	refresh()

	task.spawn(function()
		for _ = 1, MAX_TRIES do
			if settle(rims) == 0 then
				return
			end
			task.wait(RETRY_SECONDS)
		end
	end)
end

return PondFx
