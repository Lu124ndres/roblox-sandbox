--!strict
--[[
	RandomPolicy

	Política de Roblox sobre objetos al azar pagados: a algunos jugadores (por
	su país o edad) no se les puede vender nada con premio al azar. Al entrar
	se le pregunta a PolicyService y se publica el atributo
	AzarPagadoRestringido; el cliente esconde la compra de giros de la ruleta
	(Menus/SpinWindow, Menus/Purchases) a quien lo tenga en true. Si la
	consulta falla, se trata como restringido: nunca se le ofrece a quien no
	se le puede vender. La ruleta gratis y los giros ganados jugando no cambian.
]]

local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)

local ATTR = Protocol.PlayerAttributes.PaidRandomRestricted
local TRIES = 3
local RETRY_SECONDS = 2

local RandomPolicy = {}

local function check(player: Player)
	player:SetAttribute(ATTR, true) -- mientras no se sepa, restringido
	for _ = 1, TRIES do
		local ok, info = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, player)
		if ok and type(info) == "table" then
			if player.Parent then
				player:SetAttribute(ATTR, info.ArePaidRandomItemsRestricted ~= false)
			end
			return
		end
		task.wait(RETRY_SECONDS)
	end
end

function RandomPolicy.init()
	Players.PlayerAdded:Connect(check)
	for _, player in Players:GetPlayers() do
		task.spawn(check, player)
	end
end

return RandomPolicy
