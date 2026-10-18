--!strict
--[[
	Zorro/Rutina/Paseo

	Lo que hace mientras camina de un lugar a otro: a veces (PASEO), una conducta
	que se puede hacer andando (quieto = false: olfatear el rastro, mover las
	orejas), elegida con su peso por etapa, que no sea la última del ciclo
	anterior ni la primera de este (así tampoco repite). Ocupa como mucho
	PASEO_FIT del viaje entre `from` y `to` (segundos del ciclo).
		edge(turnos, last)  la primera o la última conducta de unos turnos
		choose(...)         el turno del paseo, o nil
]]

local Azar = require(script.Parent.Parent.Azar)
local Agenda = require(script.Parent.Agenda)
local Tipos = require(script.Parent.Parent.Tipos)

local PASEO = 0.6 -- probabilidad de hacer algo mientras camina
local PASEO_FIT = 0.85 -- la conducta ocupa como mucho esto del viaje
local MIN_SECONDS, MAX_SECONDS = 0.5, 40

local Paseo = {}

-- La primera o la última conducta de unos turnos.
function Paseo.edge(turnos: { Agenda.Turno }, last: boolean): Tipos.Conducta?
	local from, to, step = 1, #turnos, 1
	if last then
		from, to, step = #turnos, 1, -1
	end
	for i = from, to, step do
		local conducta = turnos[i].conducta
		if conducta then
			return conducta
		end
	end
	return nil
end

function Paseo.choose(
	c: number,
	etapa: number,
	from: number,
	to: number,
	lista: { Tipos.Conducta },
	avoid: { Tipos.Conducta? }
): Agenda.Turno?
	if Azar.unit(c, 30) >= PASEO then
		return nil
	end
	local options, weights, total = {}, {}, 0
	for _, conducta in lista do
		local w = conducta.pesos[etapa] or 0
		if w > 0 and conducta.quieto == false and not table.find(avoid, conducta) then
			table.insert(options, conducta)
			table.insert(weights, w)
			total += w
		end
	end
	local roll = Azar.unit(c, 31) * total
	for i, conducta in options do
		roll -= weights[i]
		if roll < 0 then
			local r = Azar.unit(c, 32)
			local seconds = math.clamp(conducta.duracion(etapa, r), MIN_SECONDS, MAX_SECONDS)
			if seconds > (to - from) * PASEO_FIT then
				return nil
			end
			local start = from + (to - from - seconds) * Azar.unit(c, 33)
			return {
				conducta = conducta,
				from = start,
				to = start + seconds,
				r = r,
				key = c * Agenda.SLOTS,
				facing = 0,
			}
		end
	end
	return nil
end

return table.freeze(Paseo)
