--!strict
--[[
	Analytics/Economia

	Las monedas que entran y salen, sumadas por jugador y por origen o destino,
	y mandadas juntas (Analytics/Sesion las vacía cada flushMinutes y al salir).
	Mandar cada pez entregado gastaría el límite de eventos por minuto de Roblox.

	Orígenes: alimentar, diario, regalos, ruleta, misiones, coleccion, tutorial,
	codigos, grupo, invitaciones, pack. Destinos: tienda:<categoría>, renacer.
	Cada uno se manda con su tipo de transacción de Roblox (TRANSACTIONS).
]]

local Envio = require(script.Parent.Envio)

local CURRENCY = "Monedas"
local GAMEPLAY = Enum.AnalyticsEconomyTransactionType.Gameplay.Name
local TIMED = Enum.AnalyticsEconomyTransactionType.TimedReward.Name
local TRANSACTIONS: { [string]: string } = {
	diario = TIMED,
	regalos = TIMED,
	ruleta = TIMED,
	tutorial = Enum.AnalyticsEconomyTransactionType.Onboarding.Name,
	pack = Enum.AnalyticsEconomyTransactionType.IAP.Name,
}
local SHOP = Enum.AnalyticsEconomyTransactionType.Shop.Name

type Totals = { sources: { [string]: number }, sinks: { [string]: number } }

local Economia = {}

local totals: { [Player]: Totals } = {}

local function get(player: Player): Totals
	local entry = totals[player]
	if not entry then
		entry = { sources = {}, sinks = {} }
		totals[player] = entry
	end
	return entry
end

function Economia.source(player: Player, amount: number, source: string)
	local sources = get(player).sources
	sources[source] = (sources[source] or 0) + amount
end

function Economia.sink(player: Player, amount: number, sink: string)
	local sinks = get(player).sinks
	sinks[sink] = (sinks[sink] or 0) + amount
end

-- Manda lo sumado y empieza de cero. balance: las monedas que tiene ahora.
function Economia.flush(player: Player, balance: number)
	local entry = totals[player]
	if not entry then
		return
	end
	totals[player] = nil
	for source, amount in entry.sources do
		if amount > 0 then
			local transaction = TRANSACTIONS[source] or GAMEPLAY
			Envio.economy(player, "source", CURRENCY, amount, balance, transaction, source)
		end
	end
	for sink, amount in entry.sinks do
		if amount > 0 then
			local transaction = if string.sub(sink, 1, 7) == "tienda:" then SHOP else GAMEPLAY
			Envio.economy(player, "sink", CURRENCY, amount, balance, transaction, sink)
		end
	end
end

-- Una compra con Robux: va como gasto de la moneda "Robux" con la clave del producto.
function Economia.robux(player: Player, key: string, robux: number)
	if robux > 0 then
		Envio.economy(player, "sink", "Robux", robux, 0, TRANSACTIONS.pack, key)
	end
end

function Economia.forget(player: Player)
	totals[player] = nil
end

return Economia
