--!strict
--[[
	SpinWheel

	Ruleta (Config/Spin), como la de los simuladores. ClaimSpin usa el giro
	GRATIS si ya toca (save.spinAt, unix: uno cada cooldownHours horas); si
	no, gasta un giro guardado (save.spins); si no tiene ninguno, no hace
	nada. Sortea la casilla por su peso, da el premio y avisa con Notice
	"spin" (casilla, texto) para que la ventana gire hasta ella.
	El cliente ve los atributos RuletaListaEn (próximo gratis), GirosGuardados
	y GiroPorTiempoEn (próximo giro por jugar, ver SpinTimer).
	Los giros guardados llegan por jugar (SpinTimer), con el diario
	(DailyReward), en la propia ruleta y con Robux (Monetization/Grants).
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
local SpinTimer = require(script.Parent.SpinTimer)
local Analytics = require(script.Parent.Parent.Analytics)

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
	local minutes = prize.minutes or 0
	if prize.kind == "boost" then
		Rewards.give(player, { boostMinutes = minutes }, "ruleta")
		return `{minutes} min de x{Config.Social.personalBoostMultiplier} poder`
	elseif prize.kind == "coinBoost" then
		PlayerData.edit(player, function(save)
			save.coinBoostUntil = math.max(save.coinBoostUntil, os.time())
				+ math.floor(minutes * 60)
		end)
		return `{minutes} min de x{SPIN.coinBoostMultiplier} monedas`
	elseif prize.kind == "spins" then
		local spins = prize.spins or 1
		PlayerData.edit(player, function(save)
			save.spins += spins
		end)
		return if spins == 1 then "¡+1 giro de ruleta!" else `¡+{spins} giros de ruleta!`
	end
	if prize.kind == "fill" and GiantService.fill(prize.fraction or 0, player) then
		local percent = math.round((prize.fraction or 0) * 100)
		Remotes.Notice:FireAllClients("fill", player.DisplayName, percent)
		return `¡Llenaste {percent}% del monstruo para todos!`
	end
	local coins = SpinWheel.coins(player, prize) -- "fill" sin monstruo comiendo: monedas
	Rewards.give(player, { coins = coins }, "ruleta")
	return `+{NumberFormat.short(coins)} monedas`
end

local function claim(player: Player)
	local save = PlayerData.read(player)
	if not save then
		return -- no cargó
	end
	local free = os.time() >= save.spinAt
	if not free and save.spins <= 0 then
		return -- no toca el gratis y no tiene giros guardados
	end
	local index = roll()
	PlayerData.edit(player, function(data)
		if free then
			data.spinAt = os.time() + math.floor(SPIN.cooldownHours * 3600)
		else
			data.spins -= 1
		end
	end)
	local text = give(player, SPIN.prizes[index])
	Remotes.Notice:FireClient(player, "spin", index, text)
	Analytics.spin(player, index, free)
end

function SpinWheel.init()
	Remotes.ClaimSpin.OnServerEvent:Connect(RateLimit.wrap("ClaimSpin", 1, 2, claim))
	SpinTimer.init()
end

return SpinWheel
