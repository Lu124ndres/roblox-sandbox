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
	jugador para que el cliente los pinte. Cada función publica solo lo que
	cambia (ProfilePublish); attach y edit publican todo.

	La canasta es un conteo por especie (Feeding/Basket). lastCatchAt (no se
	guarda) dice si está activo para GiantFood: pescó hace poco o lleva peces.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishingPower = require(ReplicatedStorage.Shared.FishingPower)
local Perks = require(ReplicatedStorage.Shared.Perks)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Basket = require(script.Parent.Feeding.Basket)
local ProfilePublish = require(script.Parent.ProfilePublish)
local SaveSchema = require(script.Parent.Save.SaveSchema)

type Data = { save: SaveSchema.SaveData, lastCatchAt: number }

local ATTR = Protocol.PlayerAttributes

local PlayerData = {}

local dataByPlayer: { [Player]: Data } = {}

-- Leaderstats en cero apenas entra (la tabla de jugadores no espera al guardado).
function PlayerData.prepare(player: Player)
	ProfilePublish.prepare(player)
end

-- Datos cargados: desde ahora el jugador puede jugar.
function PlayerData.attach(player: Player, save: SaveSchema.SaveData)
	ProfilePublish.prepare(player)
	dataByPlayer[player] = { save = save, lastCatchAt = -math.huge }
	ProfilePublish.all(player, save)
	player:SetAttribute(ATTR.DataLoaded, true)
end

-- Para módulos dueños de su parte de los datos (tutorial, diario, ajustes, insignias):
-- cambian lo suyo dentro de fn y se publica. false si no tiene datos cargados.
function PlayerData.edit(player: Player, fn: (save: SaveSchema.SaveData) -> ()): boolean
	local data = dataByPlayer[player]
	if not data then
		return false
	end
	fn(data.save)
	ProfilePublish.all(player, data.save)
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
	ProfilePublish.coins(player, data.save)
end

function PlayerData.addPower(player: Player, amount: number)
	local data = dataByPlayer[player]
	if not data or amount <= 0 then
		return
	end
	data.save.power += math.floor(amount)
	ProfilePublish.power(player, data.save)
end

-- Cobra monedas si le alcanzan; devuelve false si no.
function PlayerData.spendCoins(player: Player, amount: number): boolean
	local data = dataByPlayer[player]
	if not data or amount < 0 or data.save.coins < amount then
		return false
	end
	data.save.coins -= math.floor(amount)
	ProfilePublish.coins(player, data.save)
	return true
end

-- Sube una mejora de la tienda a `level` (el que compra valida precio y orden).
function PlayerData.setUpgrade(player: Player, category: Upgrades.Category, level: number)
	local data = dataByPlayer[player]
	if data then
		data.save.upgrades[category] = level
		ProfilePublish.upgrade(player, data.save, category)
	end
end

-- Kills por ayudar a llenar a este monstruo: 1, o más con un pase con traje.
function PlayerData.addKill(player: Player, giantId: string)
	local data = dataByPlayer[player]
	if not data then
		return
	end
	local amount = Perks.killMultiplier(player)
	data.save.kills += amount
	data.save.killsByGiant[giantId] = (data.save.killsByGiant[giantId] or 0) + amount
	ProfilePublish.kills(player, data.save)
end

function PlayerData.getPower(player: Player): number
	local data = dataByPlayer[player]
	return if data then data.save.power else 0
end

function PlayerData.getCarriedCount(player: Player): number
	local data = dataByPlayer[player]
	return if data then Basket.total(data.save.carried) else 0
end

-- Activo: pescó hace poco (x3 de margen si lleva peces). Un AFK con la canasta llena no cuenta.
function PlayerData.isActive(player: Player, withinSeconds: number): boolean
	local data = dataByPlayer[player]
	local carrying = data ~= nil and next(data.save.carried) ~= nil
	return data ~= nil
		and os.clock() - data.lastCatchAt <= withinSeconds * (if carrying then 3 else 1)
end

-- La capacidad crece con el poder (ver Shared/FishingPower).
function PlayerData.getCapacity(player: Player): number
	return FishingPower.playerCapacity(player)
end

function PlayerData.hasRoom(player: Player): boolean
	return PlayerData.getCarriedCount(player) < PlayerData.getCapacity(player)
end

-- Guarda hasta `count` peces de una especie; devuelve cuántos entraron (0 = sin espacio).
function PlayerData.addFish(player: Player, fishId: string, count: number): number
	local data = dataByPlayer[player]
	if not data then
		return 0
	end
	local save = data.save
	local room = PlayerData.getCapacity(player) - Basket.total(save.carried)
	local added = math.clamp(math.floor(count), 0, math.max(0, room))
	if added > 0 then
		Basket.add(save.carried, fishId, added)
		save.species[fishId] = (save.species[fishId] or 0) + added
		save.stats.fishCaught += added
		data.lastCatchAt = os.clock()
		ProfilePublish.carried(player, save)
		ProfilePublish.species(player, save, fishId)
	end
	return added
end

-- Lote para el gigante: hasta maxCount peces o maxFood de comida. Devuelve lo
-- sacado por especie, cuántos, su comida y sus monedas base (Basket.take).
function PlayerData.takeFishBatch(
	player: Player,
	maxCount: number,
	maxFood: number
): (Basket.Counts, number, number, number)
	local data = dataByPlayer[player]
	if not data or maxCount < 1 or maxFood <= 0 then
		return {}, 0, 0, 0
	end
	local taken, count, food, coins = Basket.take(data.save.carried, math.floor(maxCount), maxFood)
	if count > 0 then
		data.save.stats.fishDelivered += count
		ProfilePublish.carried(player, data.save)
	end
	return taken, count, food, coins
end

return PlayerData
