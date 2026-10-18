--!strict
--[[
	Zorro/Rutina/Agenda

	Qué hace en un lugar, de `start` a `finish` (segundos del ciclo c), igual en
	todos los clientes (Azar con el número de ciclo):
		- entre una cosa y otra se queda quieto respirando (pausa de Habitos);
		- cada vez hace una conducta de la lista (Zorro/Conductas) con su peso por
		  etapa, o, a veces (Habitos.mirar), solo mira alrededor;
		- el orden es una mezcla con pesos de la lista: en un ciclo no repite
		  ninguna, y si la lista se acaba, sigue con otra mezcla que no empiece por
		  la última;
		- entre dos ciclos tampoco repite: la lista se parte en dos mitades (A y B,
		  por su lugar en la lista) y cada ciclo empieza con una de A y termina con
		  una de B (las de A que sobran al final no se hacen: mira alrededor);
		- la duración y el azar de cada una (r) salen de Azar; los trucos
		  (tipo "truco") se hacen de frente a la puerta (yaw `door`).
	build devuelve los turnos en orden (from/to en segundos del ciclo).
	Lo que hace mientras camina: Rutina/Paseo.
]]

local Azar = require(script.Parent.Parent.Azar)
local Habitos = require(script.Parent.Parent.Habitos)
local Tipos = require(script.Parent.Parent.Tipos)

export type Turno = {
	conducta: Tipos.Conducta?, -- nil: solo mira alrededor
	from: number,
	to: number,
	r: number,
	key: number, -- única por turno (para los eventos)
	facing: number,
}

local SLOTS = 64 -- turnos por ciclo como mucho (para las claves)
local MIN_SECONDS, MAX_SECONDS = 0.5, 40

local Agenda = {}

Agenda.SLOTS = SLOTS

local function between(range: { number }, a: number, b: number): number
	return range[1] + (range[2] - range[1]) * Azar.unit(a, b)
end

-- Mezcla con pesos (Efraimidis-Spirakis): menor -ln(u)/w primero.
local function shuffle(weights: { number }, c: number, salt: number): { number }
	local keys, order = {}, {}
	for i, w in weights do
		keys[i] = -math.log(math.max(Azar.unit(c, salt + i), 1e-9)) / w
		order[i] = i
	end
	table.sort(order, function(a: number, b: number): boolean
		return keys[a] < keys[b]
	end)
	return order
end

-- El orden del ciclo (índices de `eligible`): empieza por una de A (impar).
local function sequence(weights: { number }, c: number): { number }
	local n = #weights
	if n == 1 then
		return if c % 2 == 0 then { 1 } else {}
	end
	local first = shuffle(weights, c, 200)
	for k, i in first do
		if i % 2 == 1 then
			table.remove(first, k)
			table.insert(first, 1, i)
			break
		end
	end
	local again = shuffle(weights, c, 400)
	if again[1] == first[#first] then
		table.remove(again, 1)
	end
	table.move(again, 1, #again, #first + 1, first)
	return first
end

function Agenda.build(
	c: number,
	etapa: number,
	start: number,
	finish: number,
	facing: number,
	door: number,
	lista: { Tipos.Conducta }
): { Turno }
	local habito = Habitos.de(etapa)
	local eligible, weights = {}, {}
	for _, conducta in lista do
		local w = conducta.pesos[etapa] or 0
		if w > 0 then
			table.insert(eligible, conducta)
			table.insert(weights, w)
		end
	end
	local turnos: { Turno } = {}
	local order = sequence(weights, c)
	local t, k, j = start, 1, 0
	while j < SLOTS - 1 do
		j += 1
		local seed = c * SLOTS + j
		t += between(habito.pausa, seed, 20)
		local idle = Azar.unit(seed, 21) < habito.mirar or k > #order
		local conducta = if idle then nil else eligible[order[k]]
		local r = Azar.unit(seed, 22)
		local seconds = if conducta
			then math.clamp(conducta.duracion(etapa, r), MIN_SECONDS, MAX_SECONDS)
			else between(habito.mirada, seed, 23)
		if t + seconds + habito.pausa[1] > finish then
			break
		end
		if conducta then
			k += 1
		end
		table.insert(turnos, {
			conducta = conducta,
			from = t,
			to = t + seconds,
			r = r,
			key = seed,
			facing = if conducta and conducta.tipo == "truco" then door else facing,
		})
		t += seconds
	end
	-- Termina con una de B: las de A del final se cambian por mirar alrededor.
	if #eligible > 1 then
		for i = #turnos, 1, -1 do
			local conducta = turnos[i].conducta
			if conducta then
				local index = table.find(eligible, conducta) or 0
				if index % 2 == 0 then
					break
				end
				turnos[i].conducta = nil
				turnos[i].facing = facing
			end
		end
	end
	return turnos
end

return table.freeze(Agenda)
