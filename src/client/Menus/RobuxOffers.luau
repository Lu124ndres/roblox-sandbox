--!strict
--[[
	RobuxOffers

	Qué muestra y vende ahora cada tarjeta de la TIENDA: el siguiente nivel
	de Poder y Monedas, VIP, el entrenamiento del servidor (nivel y tiempo),
	llenar al monstruo, elegir el siguiente y los estanques. Las que son
	del jugador traen `gift`: qué se le compraría a otro jugador (su propio
	siguiente nivel, su VIP, su estanque).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Perks = require(ReplicatedStorage.Shared.Perks)
local Protocol = require(ReplicatedStorage.Shared.Protocol)

local MONETIZATION = Config.Monetization
local BOOST = MONETIZATION.serverBoost
local BOOST_ATTR = Protocol.BoostAttributes

-- Lo que se le compraría a `target` al regalar (o por qué no se puede).
export type GiftOffer = { key: string, robux: number, blocked: string? }

-- Lo que muestra y vende una tarjeta en este momento (cambia con el nivel).
export type Offer = {
	title: string,
	description: string,
	key: string, -- clave de Assets.GamePasses / Assets.Products
	isPass: boolean,
	robux: number, -- precio sugerido (Config) hasta que exista el ID
	blocked: string?, -- texto del botón si no se puede comprar ("¡Tuyo!", "Máximo")
	gift: ((target: Player) -> GiftOffer)?,
}

local RobuxOffers = {}

RobuxOffers.GIANT_ICONS = {
	Orca = "orca",
	Minotauro = "minotaur",
	DragonMarino = "dragon",
	ZorroDeAgua = "fox",
} :: { [string]: string }

-- "4 minutos 05 segundos"
function RobuxOffers.clock(seconds: number): string
	local total = math.max(0, math.ceil(seconds))
	return string.format("%d minutos %02d segundos", total // 60, total % 60)
end

local function giantName(giantId: unknown): string?
	for _, def in Config.Giants.chain do
		if def.id == giantId then
			return def.displayName
		end
	end
	return nil
end

function RobuxOffers.level(player: Player, key: string): () -> Offer
	local def = MONETIZATION.levels[key]
	local function nextFor(who: Player): (number, boolean)
		local nextLevel = Perks.level(who, key) + 1
		return nextLevel, nextLevel > #def.robux
	end
	return function()
		local level = Perks.level(player, key)
		local nextLevel, maxed = nextFor(player)
		return {
			title = `{def.name} x{2 ^ (if maxed then level else nextLevel)}`,
			description = if level > 0
				then `Tienes x{2 ^ level}. Cada compra lo duplica.`
				else def.description,
			key = `{key}{nextLevel}`,
			isPass = false,
			robux = def.robux[nextLevel] or 0,
			blocked = if maxed then "Máximo" else nil,
			gift = function(target: Player): GiftOffer
				local n, full = nextFor(target)
				return {
					key = `{key}{n}`,
					robux = def.robux[n] or 0,
					blocked = if full then "Máximo" else nil,
				}
			end,
		}
	end
end

function RobuxOffers.pass(player: Player, key: string): () -> Offer
	local pass = MONETIZATION.passes[key]
	return function()
		return {
			title = pass.name,
			description = pass.description,
			key = key,
			isPass = true,
			robux = pass.robux,
			blocked = if Perks.hasPass(player, key) then "¡Tuyo!" else nil,
			gift = if MONETIZATION.passGifts[key]
				then function(target: Player): GiftOffer
					return {
						key = `Gift{key}`,
						robux = MONETIZATION.passGifts[key],
						blocked = if Perks.hasPass(target, key) then "Ya lo tiene" else nil,
					}
				end
				else nil,
		}
	end
end

-- Banner del entrenamiento del servidor.
function RobuxOffers.boost(): Offer
	local level = Perks.serverBoostLevel()
	local nextLevel = level + 1
	local maxed = nextLevel > #BOOST.robux
	return {
		title = `x{2 ^ level} → x{2 ^ (if maxed then level else nextLevel)}`,
		description = if level > 0
			then `Termina en: {RobuxOffers.clock(Perks.serverBoostSeconds())}`
			else `Todo el servidor entrena x2 por {BOOST.minutes} minutos`,
		key = `ServerBoost{nextLevel}`,
		isPass = false,
		robux = BOOST.robux[nextLevel] or 0,
		blocked = if maxed then "Máximo" else nil,
	}
end

function RobuxOffers.fill(key: string): () -> Offer
	local fill = MONETIZATION.fills[key]
	return function()
		return {
			title = fill.name,
			description = `Llena {math.round(fill.fraction * 100)}% del monstruo al momento, para todos`,
			key = key,
			isPass = false,
			robux = fill.robux,
		}
	end
end

function RobuxOffers.choose(def: Config.GiantDef): () -> Offer
	return function()
		local folder = ReplicatedStorage:FindFirstChild(Protocol.BoostFolder)
		local queued = folder and giantName(folder:GetAttribute(BOOST_ATTR.NextGiant))
		local by = folder and folder:GetAttribute(BOOST_ATTR.NextGiantBy)
		return {
			title = def.displayName,
			description = if not def.inRoulette
				then "Próximamente"
				elseif queued then `Ya eligió {by}: {queued}. El tuyo sale después`
				else "Sale después del próximo descanso",
			key = `Choose{def.id}`,
			isPass = false,
			robux = MONETIZATION.chooseGiant[def.id] or 0,
			blocked = if def.inRoulette then nil else "Pronto",
		}
	end
end

function RobuxOffers.pond(player: Player, index: number): () -> Offer
	local pond = Config.Progression.ponds[index]
	local robux = MONETIZATION.pondRobux[index] or 0
	return function()
		return {
			title = `Estanque x{pond.multiplier}`,
			description = `Entrena aquí sin juntar {NumberFormat.short(pond.requiredPower)} de poder`,
			key = `Pond{index}`,
			isPass = false,
			robux = robux,
			blocked = if Perks.pondOpen(player, index) then "Desbloqueado" else nil,
			gift = function(target: Player): GiftOffer
				local open = Perks.pondOpen(target, index)
				return {
					key = `Pond{index}`,
					robux = robux,
					blocked = if open then "Ya lo tiene" else nil,
				}
			end,
		}
	end
end

return RobuxOffers
