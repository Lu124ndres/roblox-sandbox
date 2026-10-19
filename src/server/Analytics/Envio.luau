--!strict
--[[
	Analytics/Envio

	El único que llama a AnalyticsService. Cada llamada va con pcall: si Roblox
	rechaza un evento (límite por minuto, Studio sin publicar) la partida sigue
	igual y se avisa una sola vez en la salida.

	Los campos propios (customFields) son a lo sumo 3 por evento y van como texto
	en CustomField01..03, en el orden de la lista. Tienen que ser de pocos valores
	posibles (un id de monstruo, una zona), nunca un nombre ni un número suelto:
	Roblox limita cuántos valores distintos guarda.
]]

local AnalyticsService = game:GetService("AnalyticsService")

export type Flow = "source" | "sink"

local KEYS = {
	Enum.AnalyticsCustomFieldKeys.CustomField01.Name,
	Enum.AnalyticsCustomFieldKeys.CustomField02.Name,
	Enum.AnalyticsCustomFieldKeys.CustomField03.Name,
}

local Envio = {}

local warned = false

local function send(what: string, call: () -> ())
	local ok, err = pcall(call)
	if not ok and not warned then
		warned = true
		warn(`Analytics: no se pudo enviar {what} ({err}); se siguen intentando sin avisar`)
	end
end

local function fields(list: { string }?): { [string]: string }?
	if not list or #list == 0 then
		return nil
	end
	local out = {}
	for index, value in list do
		if index > #KEYS then
			break
		end
		out[KEYS[index]] = value
	end
	return out
end

function Envio.custom(player: Player, name: string, value: number?, list: { string }?)
	send(name, function()
		AnalyticsService:LogCustomEvent(player, name, value or 1, fields(list))
	end)
end

-- Embudo del primer minuto: cada paso se manda una sola vez por jugador (lo cuida Analytics).
function Envio.funnel(player: Player, step: number, stepName: string)
	send(`embudo {step}`, function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, stepName)
	end)
end

-- Monedas que entran (source) o salen (sink). balance: monedas después del movimiento.
function Envio.economy(
	player: Player,
	flow: Flow,
	currency: string,
	amount: number,
	balance: number,
	transaction: string,
	sku: string
)
	send(`economía {sku}`, function()
		AnalyticsService:LogEconomyEvent(
			player,
			if flow == "source"
				then Enum.AnalyticsEconomyFlowType.Source
				else Enum.AnalyticsEconomyFlowType.Sink,
			currency,
			math.floor(amount),
			math.floor(balance),
			transaction,
			sku
		)
	end)
end

function Envio.progression(player: Player, path: string, level: number, list: { string }?)
	send(`progresión {path}`, function()
		AnalyticsService:LogProgressionCompleteEvent(player, path, level, nil, fields(list))
	end)
end

return Envio
