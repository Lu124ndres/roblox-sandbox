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

	El servidor también lo revisa al entregar (Grants, con `restricted`): esconder
	el botón no alcanza contra un cliente modificado.
		restricted(player)  true si no se le puede vender azar, false si sí, nil si
		                    todavía no se sabe. Espera hasta WAIT_SECONDS a que
		                    termine la consulta (al volver a entrar, Roblox reentrega
		                    las compras pendientes antes) y, si falló, la repite.
]]

local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)

local ATTR = Protocol.PlayerAttributes.PaidRandomRestricted
local TRIES = 3
local RETRY_SECONDS = 2
local WAIT_SECONDS = 10

local RandomPolicy = {}

-- Resultado de la consulta por jugador (nil = todavía no se sabe) y consultas en curso.
local known: { [Player]: boolean } = {}
local checking: { [Player]: boolean } = {}

local function check(player: Player)
	if checking[player] then
		return
	end
	checking[player] = true
	player:SetAttribute(ATTR, true) -- mientras no se sepa, restringido
	for _ = 1, TRIES do
		local ok, info = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, player)
		if ok and type(info) == "table" then
			if player.Parent then
				local restricted = info.ArePaidRandomItemsRestricted ~= false
				known[player] = restricted
				player:SetAttribute(ATTR, restricted)
			end
			checking[player] = nil
			return
		end
		task.wait(RETRY_SECONDS)
	end
	checking[player] = nil -- falló: el atributo sigue en true y la próxima consulta lo reintenta
end

function RandomPolicy.restricted(player: Player): boolean?
	if known[player] == nil and not checking[player] then
		task.spawn(check, player)
	end
	local deadline = os.clock() + WAIT_SECONDS
	while known[player] == nil and player.Parent and os.clock() < deadline do
		task.wait(0.25)
	end
	return known[player]
end

function RandomPolicy.init()
	Players.PlayerAdded:Connect(check)
	Players.PlayerRemoving:Connect(function(player: Player)
		known[player] = nil
		checking[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(check, player)
	end
end

return RandomPolicy
