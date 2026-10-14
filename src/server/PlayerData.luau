--!strict
--[[
	PlayerData

	Estado de cada jugador mientras está en el servidor: monedas, poder de
	pesca, kills, peces en la canasta, colección de especies y estadísticas. Es la
	única puerta para cambiar ese estado.

	Los datos llegan del guardado (Save/SaveService llama a attach cuando
	termina de cargarlos) y se guardan con snapshot. Mientras un jugador no
	tenga datos cargados, todas las funciones lo ignoran: no puede pescar ni
	ganar nada que después se pierda. Poder y kills se muestran en
	leaderstats; monedas, peces, poder y kills también van en atributos del
	jugador para que el cliente los pinte.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishingPower = require(ReplicatedStorage.Shared.FishingPower)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local ProfilePublish = require(script.Parent.ProfilePublish)
local SaveSchema = require(script.Parent.Save.SaveSchema)

type Data = { save: SaveSchema.SaveData }

local ATTR = Protocol.PlayerAttributes

local PlayerData = {}

local dataByPlayer: { [Player]: Data } = {}

local function publish(player: Player, data: Data)
	ProfilePublish.all(player, data.save)
end

-- Leaderstats en cero apenas entra (la tabla de jugadores no espera al guardado).
function PlayerData.prepare(player: Player)
	ProfilePublish.prepare(player)
end

-- Datos cargados: desde ahora el jugador puede jugar.
function PlayerData.attach(player: Player, save: SaveSchema.SaveData)
	ProfilePublish.prepare(player)
	dataByPlayer[player] = { save = save }
	publish(player, dataByPlayer[player])
	player:SetAttribute(ATTR.DataLoaded, true)
end

-- Para módulos dueños de su parte de los datos (tutorial, diario, ajustes,
-- insignias): cambian lo suyo dentro de fn y se publica al cliente. Devuelve
-- false si el jugador no tiene datos cargados.
function PlayerData.edit(player: Player, fn: (save: SaveSchema.SaveData) -> ()): boolean
	local data = dataByPlayer[player]
	if not data then
		return false
	end
	fn(data.save)
	publish(player, data)
	return true
end

-- Lectura (no cambiar lo que devuelve: para eso está edit).
function PlayerData.read(player: Player): SaveSchema.SaveData?
	local data = dataByPlayer[player]
	return if data then data.save else nil
end

-- Copia para guardar (nil si el jugador nunca terminó de cargar).
function PlayerData.snapshot(player: Player): SaveSchema.SaveData?
	local data = dataByPlayer[player]
	return if data then SaveSchema.copy(data.save) else nil
end

function PlayerData.detach(player: Player)
	dataByPlayer[player] = nil
end

function PlayerData.isLoaded(player: Player): boolean
	return dataByPlayer[player] ~= nil
end

function PlayerData.addCoins(player: Player, amount: number)
	local data = dataByPlayer[player]
	if not data or amount <= 0 then
		return
	end
	data.save.coins += math.floor(amount)
	publish(player, data)
end

function PlayerData.addPower(player: Player, amount: number)
	local data = dataByPlayer[player]
	if not data or amount <= 0 then
		return
	end
	data.save.power += math.floor(amount)
	publish(player, data)
end

-- Cobra monedas si le alcanzan; devuelve false si no.
function PlayerData.spendCoins(player: Player, amount: number): boolean
	local data = dataByPlayer[player]
	if not data or amount < 0 or data.save.coins < amount then
		return false
	end
	data.save.coins -= math.floor(amount)
	publish(player, data)
	return true
end

-- Sube una mejora de la tienda a `level` (el que compra valida precio y orden).
function PlayerData.setUpgrade(player: Player, category: Upgrades.Category, level: number)
	local data = dataByPlayer[player]
	if data then
		data.save.upgrades[category] = level
		publish(player, data)
	end
end

-- +1 kill: el jugador ayudó a llenar a este monstruo.
function PlayerData.addKill(player: Player, giantId: string)
	local data = dataByPlayer[player]
	if not data then
		return
	end
	data.save.kills += 1
	data.save.killsByGiant[giantId] = (data.save.killsByGiant[giantId] or 0) + 1
	publish(player, data)
end

function PlayerData.getPower(player: Player): number
	local data = dataByPlayer[player]
	return if data then data.save.power else 0
end

function PlayerData.getCarriedCount(player: Player): number
	local data = dataByPlayer[player]
	return if data then #data.save.carried else 0
end

-- La capacidad crece con el poder (ver Shared/FishingPower).
function PlayerData.getCapacity(player: Player): number
	return FishingPower.playerCapacity(player)
end

function PlayerData.hasRoom(player: Player): boolean
	return PlayerData.getCarriedCount(player) < PlayerData.getCapacity(player)
end

-- Guarda hasta `count` peces de la misma especie; devuelve cuántos entraron
-- (0 si ya no había espacio).
function PlayerData.addFish(player: Player, fishId: string, count: number): number
	local data = dataByPlayer[player]
	if not data then
		return 0
	end
	local save = data.save
	local room = PlayerData.getCapacity(player) - #save.carried
	local added = math.clamp(math.floor(count), 0, math.max(0, room))
	for _ = 1, added do
		table.insert(save.carried, fishId)
	end
	if added > 0 then
		save.species[fishId] = (save.species[fishId] or 0) + added
		save.stats.fishCaught += added
		publish(player, data)
	end
	return added
end

-- Saca el primer pez de la canasta (nil si está vacía): se entregan de 1 en 1.
function PlayerData.takeFish(player: Player): string?
	local data = dataByPlayer[player]
	if not data or #data.save.carried == 0 then
		return nil
	end
	local fishId = table.remove(data.save.carried, 1)
	data.save.stats.fishDelivered += 1
	publish(player, data)
	return fishId
end

return PlayerData
