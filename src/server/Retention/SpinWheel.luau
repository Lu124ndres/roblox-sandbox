--!strict
--[[
	SpinWheel

	Ruleta gratis (Config/Spin): un giro cada cooldownHours horas. Con el
	remote ClaimSpin el servidor mira si ya toca (save.spinAt, unix), sortea
	la casilla por su peso, da el premio, guarda la próxima hora y avisa con
	Notice "spin" (casilla, texto) para que la ventana gire hasta ella.
	El cliente ve cuándo vuelve a tocar en el atributo RuletaListaEn.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local RewardScale = require(ReplicatedStorage.Shared.RewardScale)
local SPIN = require(ReplicatedStorage.Shared.Config.Spin)
local GiantService = require(script.Parent.Parent.GiantService)
local PlayerData = require(script.Parent.Parent.PlayerData)
local RateLimit = require(script.Parent.Parent.RateLimit)
local Remotes = require(script.Parent.Parent.Remotes)
local Rewards = require(script.Parent.Parent.Social.Rewards)

local SpinWheel = {}

local rng = Random.new()

local function roll(): number
	local total = 0
	for _, prize in SPIN.prizes do
		total += prize.weight
	end
	local value = rng:NextNumber(0, total)
	for index, prize in SPIN.prizes do
		value -= prize.weight
		if value <= 0 then
			return index
		end
	end
	return 1
end

-- Monedas de una casilla para este jugador (también las muestra la ventana).
function SpinWheel.coins(player: Player, prize: SPIN.Prize): number
	return RewardScale.share(player, prize.coins or 0, prize.share)
end

-- Da el premio de la casilla y devuelve el texto del aviso.
local function give(player: Player, prize: SPIN.Prize): string
	if prize.kind == "boost" then
		local minutes = prize.minutes or 0
		Rewards.give(player, { boostMinutes = minutes })
		return `{minutes} min de x{Config.Social.personalBoostMultiplier} poder`
	end
	if prize.kind == "fill" and GiantService.fill(prize.fraction or 0, player) then
		local percent = math.round((prize.fraction or 0) * 100)
		Remotes.Notice:FireAllClients("fill", player.DisplayName, percent)
		return `¡Llenaste {percent}% del monstruo para todos!`
	end
	local coins = SpinWheel.coins(player, prize) -- "fill" sin monstruo comiendo: monedas
	Rewards.give(player, { coins = coins })
	return `+{NumberFormat.short(coins)} monedas`
end

local function claim(player: Player)
	local save = PlayerData.read(player)
	if not save or os.time() < save.spinAt then
		return -- todavía no toca (o no cargó)
	end
	local index = roll()
	PlayerData.edit(player, function(data)
		data.spinAt = os.time() + math.floor(SPIN.cooldownHours * 3600)
	end)
	local text = give(player, SPIN.prizes[index])
	Remotes.Notice:FireClient(player, "spin", index, text)
end

function SpinWheel.init()
	Remotes.ClaimSpin.OnServerEvent:Connect(RateLimit.wrap("ClaimSpin", 1, 2, claim))
end

return SpinWheel
