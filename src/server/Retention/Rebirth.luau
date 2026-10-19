--!strict
--[[
	Rebirth

	Renacer (Config/Rebirth, cuentas en Shared/RebirthMath): con monedas y
	poder suficientes, el remote Rebirth reinicia monedas, poder, mejoras de la
	tienda y canasta, y suma un renacimiento (alimenta x1.35 más rápido para
	siempre, ver RebirthMath). Se avisa a todo el servidor.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RebirthMath = require(ReplicatedStorage.Shared.RebirthMath)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local PlayerData = require(script.Parent.Parent.PlayerData)
local RateLimit = require(script.Parent.Parent.RateLimit)
local Remotes = require(script.Parent.Parent.Remotes)
local SaveService = require(script.Parent.Parent.Save.SaveService)
local Analytics = require(script.Parent.Parent.Analytics)

local Rebirth = {}

local function rebirth(player: Player)
	local save = PlayerData.read(player)
	if not save or not RebirthMath.canRebirth(save.coins, save.power, save.rebirths) then
		return
	end
	local count = save.rebirths + 1
	Analytics.rebirth(player, count, save) -- antes de reiniciar: lo que pierde
	PlayerData.edit(player, function(data)
		data.coins = 0
		data.power = 0
		data.carried = {}
		for category in data.upgrades do
			data.upgrades[category] = 1
		end
		data.rebirths = count
	end)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = Upgrades.list("Boots")[1].value
	end
	Remotes.Notice:FireAllClients("rebirth", player.DisplayName, count)
	-- Renacer cambia mucho de golpe: se guarda ya, sin esperar al autoguardado.
	task.spawn(SaveService.saveNow, player)
end

function Rebirth.init()
	Remotes.Rebirth.OnServerEvent:Connect(RateLimit.wrap("Rebirth", 0.5, 1, rebirth))
end

return Rebirth
