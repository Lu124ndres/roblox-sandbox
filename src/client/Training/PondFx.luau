--!strict
--[[
	PondFx

	El agua de color de cada estanque de entrenamiento (las mallas Lamina_<n> de la isla
	de bloques, Workspace.IslaBloques; las pone el servidor, World/BlockIsland) muestra si
	el jugador lo tiene abierto: viva y casi opaca si puede entrar, pálida y más
	transparente si todavía no. Así de un vistazo se sabe a cuáles puede entrar (pedido
	del usuario: lo muestra el agua, no un borde de luz).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Perks = require(ReplicatedStorage.Shared.Perks)
local Protocol = require(ReplicatedStorage.Shared.Protocol)

local OPEN_SEE_THROUGH = 0.15
local LOCKED_SEE_THROUGH = 0.55
local LOCKED_FADE = 0.45 -- cerrado: el color se acerca al blanco (pálido)
local PALE = Color3.new(1, 1, 1)

type Pond = { index: number, part: BasePart, color: Color3, open: boolean? }

local PondFx = {}

local function collect(island: Instance): { Pond }
	local ponds = {}
	for _, part in island:GetChildren() do
		local index = part:GetAttribute(Protocol.Map.PondIndexAttribute)
		local prefix = Protocol.Map.PondWaterPrefix
		if
			part:IsA("BasePart")
			and string.sub(part.Name, 1, #prefix) == prefix
			and type(index) == "number"
		then
			table.insert(ponds, { index = index, part = part, color = part.Color, open = nil })
		end
	end
	return ponds
end

local function paint(pond: Pond, open: boolean)
	if pond.open == open then
		return
	end
	pond.open = open
	pond.part.Color = if open then pond.color else pond.color:Lerp(PALE, LOCKED_FADE)
	pond.part.Transparency = if open then OPEN_SEE_THROUGH else LOCKED_SEE_THROUGH
end

function PondFx.start()
	local player = Players.LocalPlayer
	task.spawn(function()
		-- La isla de bloques llega cuando el servidor termina de armar el mundo; sin ella
		-- (lugar sin ServerStorage.IslaBloques) no hay nada que pintar.
		local island = Workspace:WaitForChild(Protocol.Map.BlockIsland, 120)
		if not island then
			return
		end
		local ponds = collect(island)
		local function refresh()
			for _, pond in ponds do
				paint(pond, Perks.pondOpen(player, pond.index))
			end
		end
		player.AttributeChanged:Connect(function(name: string)
			if Perks.affectsPonds(name) then
				refresh()
			end
		end)
		refresh()
	end)
end

return PondFx
