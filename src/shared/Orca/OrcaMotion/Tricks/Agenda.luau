--!strict
--[[
	OrcaMotion/Tricks/Agenda

	Qué truco toca y cuándo, con la hora del servidor y azar sin estado (igual
	en todos los clientes, sin red). El tiempo se corta en tramos de
	`trickEvery` segundos; en cada uno hay o no un truco (`trickChance`), con
	pausas de al menos `rest` segundos antes y después.
		- Nunca dos veces seguidas el mismo truco: si el del tramo es el mismo
		  que el último hecho, se elige otro (mirando hasta LOOKBACK tramos
		  atrás, sin guardar nada).
		- La duración cambia con el azar (`vary` del truco) y la fuerza y el
		  lado salen de `seed`.
		- Los de lucirse (`show`) eligen el comienzo dentro del tramo para que,
		  en su momento fuerte, no le den la espalda a la rampa: `aim(t)` da
		  cuánto tendría que girar en ese momento para mirarla (rad).
		- Los que bajan hondo (`deep`) lo eligen donde haya fondo: `floor(t)`
		  da el fondo bajo su recorrido a esa hora (altos, negativo).
]]

local Perfil = require(script.Parent.Parent.Parent.Etapas.Perfil)
local Tricks = require(script.Parent)

local hash = Tricks.hash

local LOOKBACK = 16 -- tramos que mira atrás para no repetir (con 8 se repetía en 48 h simuladas)
local CANDIDATES = 8 -- comienzos que prueba para lucirse
local GOLDEN = 0.618034 -- reparte los comienzos de prueba en el tramo
local BACK = 1.9 -- rad (~110°): más que esto es darle la espalda a la rampa
local SHALLOW = 4 -- cuánto pesa la falta de fondo (por alto) contra el giro (rad)

export type Plan = {
	index: number, -- en profile.tricks
	slot: number,
	start: number, -- hora del servidor en que empieza
	seconds: number,
	seed: number, -- 0..1
}

local Agenda = {}

local function weighted(entries: { Perfil.Entry }, r: number, skip: string?): number
	local total = 0
	for _, entry in entries do
		if entry.trick.name ~= skip then
			total += entry.weight
		end
	end
	if total <= 0 then
		return 0
	end
	local pick, found = r * total, 0
	for k, entry in entries do
		if entry.trick.name ~= skip then
			found = k
			pick -= entry.weight
			if pick <= 0 then
				return k
			end
		end
	end
	return found
end

-- El truco del tramo antes de mirar el anterior (0 = ninguno).
local function raw(slot: number, profile: Perfil.Profile): number
	if hash(slot * 1.37 + 0.11) > profile.trickChance then
		return 0
	end
	return weighted(profile.tricks, hash(slot + 0.25), nil)
end

-- El truco del tramo sin repetir el último hecho (0 = ninguno).
function Agenda.choose(slot: number, profile: Perfil.Profile): number
	local last: string? = nil
	local index = 0
	for k = slot - LOOKBACK, slot do
		index = raw(k, profile)
		if index > 0 and profile.tricks[index].trick.name == last then
			index = weighted(profile.tricks, hash(k + 0.75), last)
		end
		if index > 0 then
			last = profile.tricks[index].trick.name
		end
	end
	return index
end

-- El plan del tramo: qué truco, cuándo empieza y cuánto dura (nil = descansa).
function Agenda.plan(
	slot: number,
	profile: Perfil.Profile,
	aim: ((t: number) -> number)?,
	floor: ((t: number) -> number)?
): Plan?
	local index = Agenda.choose(slot, profile)
	if index == 0 then
		return nil
	end
	local trick = profile.tricks[index].trick
	local every, rest = profile.trickEvery, profile.rest
	local seconds = trick.seconds * (1 + (trick.vary or 0) * (2 * hash(slot + 0.6) - 1))
	local slack = math.max(0, every - seconds - 2 * rest)
	local base = slot * every + rest
	local first = hash(slot + 0.5)
	local offset = first * slack
	local show, deep = trick.show, trick.deep
	if slack > 0 and ((show and aim) or (deep and floor)) then
		local best = math.huge
		for k = 0, CANDIDATES - 1 do
			local try = ((first + k * GOLDEN) % 1) * slack
			local at = base + try + (show or 0.5) * seconds
			local turn = if show and aim then math.abs(aim(at)) else 0
			-- Lo que le falta de fondo (altos).
			local short = if deep and floor then math.max(0, floor(at) + deep) else 0
			local score = turn + (if turn > BACK then BACK else 0) + short * SHALLOW
			if score < best then
				best, offset = score, try
			end
			if turn < BACK and short <= 0 then
				break
			end
		end
	end
	return {
		index = index,
		slot = slot,
		start = base + offset,
		seconds = seconds,
		seed = hash(slot + 0.9),
	}
end

return table.freeze(Agenda)
