--!strict
--[[
	Passes

	Pases de Robux (Config.Monetization.passes, IDs en Assets.GamePasses).
	Al entrar se pregunta a Roblox cuáles tiene (con reintentos) y se marca
	Pase_<clave> en el jugador; Perks lee esos atributos. Si Roblox no contesta, se vuelve a
	preguntar cada RETRY_SECONDS mientras siga en el servidor: nadie se queda toda la partida
	sin un pase que pagó. Si compra uno durante la partida, se marca al momento. Los pases
	con ID 0 todavía no existen y se ignoran.
	Un pase que un admin se quitó para probar (save.passTests = false) no se marca aunque
	Roblox diga que lo tiene: el creador del juego siempre tiene todos sus pases. Solo cuenta
	para admins (Admin/Admins), así que un jugador normal nunca pierde uno que pagó.
	Comprarlo o recibirlo de regalo borra esa prueba (acquire).
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Remotes = require(script.Parent.Parent.Remotes)
local Analytics = require(script.Parent.Parent.Analytics)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Admins = require(script.Parent.Parent.Admin.Admins)

local PASSES = Config.Monetization.passes
local PREFIX = Protocol.PlayerAttributes.PassPrefix
local ATTEMPTS = 3
local BACKOFF_SECONDS = 1 -- espera tras el 1.er fallo; se duplica en cada reintento
local RETRY_SECONDS = 60 -- espera entre rondas para los pases que Roblox no contestó

local Passes = {}

local function keyFor(passId: number): string?
	for key, id in Assets.GamePasses do
		if id ~= 0 and id == passId then
			return key
		end
	end
	return nil
end

-- Marca el pase que Roblox dice que tiene, salvo que un admin se lo haya quitado para probar
-- (si sus datos aún no cargan, ProfilePublish aplica la prueba al cargarlos).
function Passes.grant(player: Player, key: string)
	local save = PlayerData.read(player)
	if save and save.passTests[key] == false and Admins.is(player) then
		return
	end
	player:SetAttribute(`{PREFIX}{key}`, true)
end

-- Lo compró o se lo regalaron: vale aunque un admin se lo hubiera quitado para probar.
function Passes.acquire(player: Player, key: string)
	PlayerData.edit(player, function(save)
		save.passTests[key] = nil
	end)
	player:SetAttribute(`{PREFIX}{key}`, true)
end

-- Pregunta a Roblox con reintentos: un fallo pasajero no debe dejar a nadie sin su pase.
-- nil si no contestó (o el jugador se fue): no se sabe si lo tiene.
local function owns(player: Player, passId: number): (boolean?, any)
	local result: any
	for attempt = 1, ATTEMPTS do
		local ok
		ok, result = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)
		if ok then
			return result == true, nil
		end
		if attempt == ATTEMPTS or not player.Parent then
			break
		end
		task.wait(BACKOFF_SECONDS * 2 ^ (attempt - 1))
	end
	return nil, result
end

local function check(player: Player)
	local pending: { [string]: number } = {}
	for key, id in Assets.GamePasses do
		if id ~= 0 then
			pending[key] = id
		end
	end
	local warned = false
	while next(pending) and player.Parent do
		for key, id in pending do
			local has, problem = owns(player, id)
			if has ~= nil then
				pending[key] = nil
				if has and player.Parent then
					Passes.grant(player, key)
				end
			elseif not warned and player.Parent then
				warned = true -- un aviso por jugador, no uno por ronda
				warn(
					`Passes: Roblox no contestó por los pases de {player.UserId} ({problem}); se reintenta`
				)
			end
		end
		if next(pending) then
			task.wait(RETRY_SECONDS)
		end
	end
end

function Passes.init()
	Players.PlayerAdded:Connect(check)
	for _, player in Players:GetPlayers() do
		task.spawn(check, player)
	end
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(
		function(player: Player, passId: number, purchased: boolean)
			local key = keyFor(passId)
			if purchased and key then
				Passes.acquire(player, key)
				Analytics.robux(player, `Pase{key}`, PASSES[key].robux, false)
				Remotes.Notice:FireClient(
					player,
					"purchase",
					`¡Gracias! Ya tienes {PASSES[key].name}`
				)
			end
		end
	)
end

return Passes
