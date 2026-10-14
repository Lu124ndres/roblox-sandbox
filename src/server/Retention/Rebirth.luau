--!strict
--[[
	Rebirth

	Renacer (Config/Rebirth, cuentas en Shared/RebirthMath): con monedas
	suficientes, el remote Rebirth reinicia monedas, poder, mejoras de la
	tienda y canasta, y suma un renacimiento (multiplica monedas y poder
	para siempre, ver Perks). Se avisa a todo el servidor.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RebirthMath = require(ReplicatedStorage.Shared.RebirthMath)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local PlayerData = require(script.Parent.Parent.PlayerData)
local RateLimit = require(script.Parent.Parent.RateLimit)
local Remotes = require(script.Parent.Parent.Remotes)

local Rebirth = {}

local function rebirth(player: Player)
	local save = PlayerData.read(player)
	if not save or save.coins < RebirthMath.cost(save.rebirths) then
		return
	end
	local count = save.rebirths + 1
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
end

function Rebirth.init()
	Remotes.Rebirth.OnServerEvent:Connect(RateLimit.wrap("Rebirth", 0.5, 1, rebirth))
end

return Rebirth
