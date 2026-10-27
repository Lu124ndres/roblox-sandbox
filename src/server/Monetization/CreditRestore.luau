--!strict
--[[
	CreditRestore

	Compras para todo el servidor que el jugador pagó y no se llegaron a aplicar
	(el servidor cerró o él salió antes): al cargar sus datos (DataLoaded) vuelven
	a la fila (Monetization/ServerCredits y Grants.restore). Lo arranca Receipts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Remotes = require(script.Parent.Parent.Remotes)
local Grants = require(script.Parent.Grants)
local ServerCredits = require(script.Parent.ServerCredits)

local CreditRestore = {}

-- Lo que pagó para el servidor y no se aplicó (cerró el servidor o salió antes): a la fila.
local function restoreCredits(player: Player)
	local pending = ServerCredits.pending(player)
	local restored = 0
	for _, key in pending do
		if Grants.restore(player, key) then
			restored += 1
		else -- por ejemplo, un monstruo de temporada fuera de fecha: queda para otra vez
			warn(
				`Receipts: crédito {key} de {player.Name} ({player.UserId}) no se puede aplicar hoy`
			)
		end
	end
	if restored > 0 then
		Remotes.Notice:FireClient(
			player,
			"purchase",
			"Tu compra pendiente para el servidor se aplica aquí"
		)
	end
end

function CreditRestore.init()
	local function watch(player: Player)
		local attribute = Protocol.PlayerAttributes.DataLoaded
		if player:GetAttribute(attribute) == true then
			restoreCredits(player)
			return
		end
		local connection: RBXScriptConnection
		connection = player:GetAttributeChangedSignal(attribute):Connect(function()
			if player:GetAttribute(attribute) == true then
				connection:Disconnect()
				restoreCredits(player)
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		task.spawn(watch, player)
	end
end

return CreditRestore
