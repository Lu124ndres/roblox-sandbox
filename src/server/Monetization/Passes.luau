--!strict
--[[
	Passes

	Pases de Robux (Config.Monetization.passes, IDs en Assets.GamePasses).
	Al entrar se pregunta a Roblox cuáles tiene (con reintentos) y se marca
	Pase_<clave> en el jugador; Perks lee esos atributos. Si compra uno durante la partida, se
	marca al momento. Los pases con ID 0 todavía no existen y se ignoran.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Remotes = require(script.Parent.Parent.Remotes)

local PASSES = Config.Monetization.passes
local PREFIX = Protocol.PlayerAttributes.PassPrefix
local ATTEMPTS = 3
local BACKOFF_SECONDS = 1 -- espera tras el 1.er fallo; se duplica en cada reintento

local Passes = {}

local function keyFor(passId: number): string?
	for key, id in Assets.GamePasses do
		if id ~= 0 and id == passId then
			return key
		end
	end
	return nil
end

-- Marca el pase (también lo usa la prueba de Studio).
function Passes.grant(player: Player, key: string)
	player:SetAttribute(`{PREFIX}{key}`, true)
end

-- Pregunta a Roblox con reintentos: un fallo pasajero no debe dejar a nadie sin su pase.
local function owns(player: Player, passId: number): boolean
	for attempt = 1, ATTEMPTS do
		local ok, result = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)
		if ok then
			return result == true
		end
		if attempt == ATTEMPTS or not player.Parent then
			warn(`Passes: no se pudo consultar el pase {passId} de {player.UserId}: {result}`)
			return false
		end
		task.wait(BACKOFF_SECONDS * 2 ^ (attempt - 1))
	end
	return false
end

local function check(player: Player)
	for key, id in Assets.GamePasses do
		if id ~= 0 and owns(player, id) and player.Parent then
			Passes.grant(player, key)
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
				Passes.grant(player, key)
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
