--!strict
--[[
	FoodResize

	La comida que pide el monstruo sale de quiénes están en el servidor
	(Feeding/GiantFood). Si se calculara una sola vez al llegar, un jugador
	fuerte que entra a mitad de camino la llenaría de un golpe (lo vio el
	usuario). Así que se recalcula (GiantService.resize) cuando:
		- termina de cargar los datos alguien que entra;
		- sale alguien;
		- cada RESIZE_SECONDS, por si alguien subió mucho de poder o de canasta.
	Lo ya llenado (la fracción de la barra) no baja: lo que falta crece o se
	achica a la medida de los que están ahora.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)

local RESIZE_SECONDS = 15

export type Giant = { resize: () -> () }

local FoodResize = {}

function FoodResize.start(giant: Giant)
	local function watch(player: Player)
		player:GetAttributeChangedSignal(Protocol.PlayerAttributes.DataLoaded):Connect(function()
			if player:GetAttribute(Protocol.PlayerAttributes.DataLoaded) == true then
				giant.resize()
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function()
		task.delay(1, giant.resize) -- cuando ya salió de la lista y de PlayerData
	end)
	task.spawn(function()
		while true do
			task.wait(RESIZE_SECONDS)
			giant.resize()
		end
	end)
end

return FoodResize
