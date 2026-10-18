--!strict
--[[
	Zorro/Cara/Parpadeo

	El parpadeo solo, sacado de la hora del servidor y de Zorro/Azar (sin estado:
	todos los clientes lo ven parpadear en el mismo instante). El tiempo se parte
	en celdas de CELL s y en cada una parpadea una vez, en un instante al azar de
	sus primeros SPREAD s: entre un parpadeo y el siguiente pasan de 2 a 6 s
	(~15 por minuto). Cada parpadeo se cierra en CLOSE s, queda cerrado HOLD s y
	se abre en OPEN s; a veces (DOUBLE) parpadea dos veces seguidas.
		at(now, chance?, pace?)  0 abierto .. 1 cerrado
			chance  probabilidad de que el parpadeo de la celda ocurra (1 = siempre;
			        la sorpresa casi no parpadea, Zorro/Cara/Gestos)
			pace    estira la duración (con sueño parpadea lento)
]]

local Azar = require(script.Parent.Parent.Azar)

local CELL = 4 -- s
local SPREAD = 2 -- s: el parpadeo cae en [k * CELL, k * CELL + SPREAD]
local CLOSE, HOLD, OPEN = 0.06, 0.05, 0.12 -- s
local DOUBLE = 0.2 -- probabilidad de un parpadeo doble
local GAP = 0.3 -- s entre el primero y el segundo del doble

local Parpadeo = {}

Parpadeo.CELL = CELL

local function ease(u: number): number
	u = math.clamp(u, 0, 1)
	return u * u * (3 - 2 * u)
end

-- Un parpadeo: s segundos desde que empieza a cerrarse.
local function shape(s: number, pace: number): number
	local close, hold, open = CLOSE * pace, HOLD * pace, OPEN * pace
	if s < 0 or s >= close + hold + open then
		return 0
	elseif s < close then
		return ease(s / close)
	elseif s < close + hold then
		return 1
	end
	return 1 - ease((s - close - hold) / open)
end

function Parpadeo.at(now: number, chance: number?, pace: number?): number
	local k = math.floor(now / CELL)
	if Azar.unit(k, 103) >= (chance or 1) then
		return 0
	end
	local slow = math.max(pace or 1, 0.2)
	local s = now - (k * CELL + SPREAD * Azar.unit(k, 101))
	local value = shape(s, slow)
	if Azar.unit(k, 102) < DOUBLE then
		value = math.max(value, shape(s - GAP * slow, slow))
	end
	return value
end

return table.freeze(Parpadeo)
