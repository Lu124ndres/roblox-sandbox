--!strict
--[[
	ProfilePublish

	Lo que el cliente ve de los datos de un jugador: leaderstats (Poder y
	Kills) y atributos del jugador (monedas, peces, mejoras, colección,
	tutorial, recompensa diaria y ajustes). SetAttribute con el mismo valor
	no se vuelve a enviar.

	all publica todo (al cargar y tras PlayerData.edit); el resto publica un
	solo campo, para que pescar, cobrar o entrenar no reescriban ~35 atributos.
	El leaderstat de Poder se actualiza a lo sumo cada POWER_STAT_SECONDS por
	jugador (cada IntValue replica a todos los jugadores del servidor); el
	atributo Power sí cambia al instante.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Basket = require(script.Parent.Feeding.Basket)
local SaveSchema = require(script.Parent.Save.SaveSchema)
local Titles = require(ReplicatedStorage.Shared.Titles)

local ATTR = Protocol.PlayerAttributes
local POWER_STAT_SECONDS = 3

local ProfilePublish = {}

-- Último leaderstat de Poder publicado y el pendiente (claves débiles: se van con el jugador).
local powerStatAt: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any
local powerStatPending: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any

-- Leaderstats en cero apenas entra (la tabla de jugadores no espera al guardado).
function ProfilePublish.prepare(player: Player)
	if player:FindFirstChild("leaderstats") then
		return
	end
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local stats = Protocol.Leaderstats
	for _, name in { stats.Power, stats.Coins, stats.Kills, stats.Rebirths } do
		local value = Instance.new("IntValue")
		value.Name = name
		value.Parent = leaderstats
	end
	leaderstats.Parent = player
	for _, attribute in { ATTR.Power, ATTR.CarriedFish, ATTR.Coins, ATTR.Kills } do
		player:SetAttribute(attribute, 0)
	end
end

local function stat(player: Player, name: string, value: number)
	local leaderstats = player:FindFirstChild("leaderstats")
	local holder = leaderstats and leaderstats:FindFirstChild(name)
	if holder and holder:IsA("IntValue") then
		holder.Value = value
	end
end

-- Leaderstat de Poder: al instante si pasó POWER_STAT_SECONDS; si no, queda
-- pendiente y se publica el último valor cuando se cumpla el plazo.
local function powerStat(player: Player, value: number, now: boolean)
	local remaining = POWER_STAT_SECONDS - (os.clock() - (powerStatAt[player] or -math.huge))
	if now or remaining <= 0 then
		powerStatAt[player] = os.clock()
		powerStatPending[player] = nil
		stat(player, Protocol.Leaderstats.Power, value)
		return
	end
	local scheduled = powerStatPending[player] ~= nil
	powerStatPending[player] = value
	if not scheduled then
		task.delay(remaining, function()
			local latest = powerStatPending[player]
			if latest and player.Parent then
				powerStat(player, latest, true)
			end
		end)
	end
end

function ProfilePublish.coins(player: Player, save: SaveSchema.SaveData)
	player:SetAttribute(ATTR.Coins, save.coins)
	stat(player, Protocol.Leaderstats.Coins, save.coins)
end

-- Título por los monstruos llenados (no baja al renacer); solo se replica si cambia.
local function title(player: Player, save: SaveSchema.SaveData)
	player:SetAttribute(ATTR.Title, Titles.index(save.kills))
end

function ProfilePublish.power(player: Player, save: SaveSchema.SaveData)
	player:SetAttribute(ATTR.Power, save.power)
	powerStat(player, save.power, false)
end

function ProfilePublish.kills(player: Player, save: SaveSchema.SaveData)
	stat(player, Protocol.Leaderstats.Kills, save.kills)
	player:SetAttribute(ATTR.Kills, save.kills)
	title(player, save)
end

function ProfilePublish.carried(player: Player, save: SaveSchema.SaveData)
	player:SetAttribute(ATTR.CarriedFish, Basket.total(save.carried))
end

-- Colección: cuántos de esa especie ha pescado (Pez_<id>), para la ventana de peces.
function ProfilePublish.species(player: Player, save: SaveSchema.SaveData, fishId: string)
	player:SetAttribute(`{ATTR.FishPrefix}{fishId}`, save.species[fishId] or 0)
end

function ProfilePublish.upgrade(player: Player, save: SaveSchema.SaveData, category: string)
	player:SetAttribute(category, save.upgrades[category])
end

function ProfilePublish.all(player: Player, save: SaveSchema.SaveData)
	powerStat(player, save.power, true)
	ProfilePublish.kills(player, save)
	ProfilePublish.coins(player, save)
	player:SetAttribute(ATTR.Power, save.power)
	title(player, save)
	ProfilePublish.carried(player, save)
	for category in save.upgrades do
		ProfilePublish.upgrade(player, save, category)
	end
	for _, fish in Config.Economy.fish do
		ProfilePublish.species(player, save, fish.id)
	end
	player:SetAttribute(ATTR.Tutorial, save.tutorial)
	player:SetAttribute(ATTR.DailyStreak, save.daily.streak)
	player:SetAttribute(ATTR.DailyDay, save.daily.lastDay)
	player:SetAttribute(ATTR.Settings, HttpService:JSONEncode(save.settings))
	player:SetAttribute(ATTR.BoostUntil, save.boostUntil)
	player:SetAttribute(ATTR.GroupClaimed, save.groupClaimed)
	player:SetAttribute(ATTR.Rebirths, save.rebirths)
	stat(player, Protocol.Leaderstats.Rebirths, save.rebirths)
	player:SetAttribute(ATTR.StarterPack, save.starterPack)
	player:SetAttribute(ATTR.SpinAt, save.spinAt)
	player:SetAttribute(ATTR.Spins, save.spins)
	player:SetAttribute(ATTR.CoinBoostUntil, save.coinBoostUntil)
	for key, level in save.levels do
		player:SetAttribute(`{ATTR.LevelPrefix}{key}`, level)
	end
	for key in save.gifts do
		player:SetAttribute(`{ATTR.PassPrefix}{key}`, true) -- pase regalado
	end
	for index in Config.Progression.ponds do
		if save.ponds[tostring(index)] then
			player:SetAttribute(`{ATTR.PondPrefix}{index}`, true)
		end
	end
end

return ProfilePublish
