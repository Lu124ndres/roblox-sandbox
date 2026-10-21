--!strict
--[[
	OrcaMotion/Tricks/Salto

	El salto completo (breach) de una orca o una ballena de verdad:
		1. toma velocidad desde abajo: se hunde con la nariz abajo y gira hacia
		   arriba hasta quedar inclinada para salir (anticipación);
		2. acelera aleteando fuerte y sale casi vertical (~70°);
		3. en el aire el centro sigue la parábola de la gravedad de su tamaño
		   (Fisica); el giro sobre su eje empieza antes del pico, arquea la panza
		   y abre las pectorales; cae de costado (twist 0.25) o de espalda (0.5)
		   y, como pega con el flanco más arriba de donde salió, la caída es más
		   corta y rápida que la subida;
		4. se hunde de verdad, se endereza, sube y sopla (Despues).
	Con `times` > 1 son saltos seguidos: rebota bajo el agua y vuelve a salir.
	Con `flop` cae de panza, torpe, como una cría.
	El azar (seed) elige hacia qué lado gira, la fuerza (±6 %, sin cambiar los
	tiempos) y cuál pectoral se abre más.
	Marcas (avance u): salida<n>, cima<n>, caida<n> (n = número de salto) y soplo.
]]

local Despues = require(script.Despues)
local Fisica = require(script.Fisica)
local Tramos = require(script.Parent.Tramos)
local Tricks = require(script.Parent)

local smooth, span, bell, lerp, hermite =
	Tricks.smooth, Tricks.span, Tricks.bell, Tricks.lerp, Tricks.hermite

export type Style = Fisica.Style

local DIP = -0.45 -- nariz abajo al hundirse para tomar impulso (rad)
-- Abajo ya mira hacia arriba (esta parte del ángulo de salida) y termina de girar al acelerar.
local TURN_UP = 0.5
local ASYM = 0.3 -- una pectoral se abre más que la otra
local WOBBLE = 0.3 -- la torpe se bambolea en el aire (rad)
local BELLY = 0.3 -- la panza queda esto más abajo que el centro (altos)

local Salto = {}

-- Pectorales abiertas en el aire, una más que la otra.
local function fins(amount: number, seed: number): { izq: number, der: number }
	local a = ASYM * (seed - 0.5)
	return { izq = amount * (1 + a), der = amount * (1 - a) }
end

-- Baja con la nariz abajo y gira hacia arriba, sin pararse en lo más hondo.
local function dipPitch(a: number, start: number, exit: number): number
	return Tricks.curve(a, { 0, start, 0.45, DIP, 1, exit * TURN_UP })
end

local function launch(p: Fisica.Plan, base: number): Tramos.Tramo
	return {
		seconds = p.tL,
		pose = function(t: number, _from: number, seed: number): Tricks.Pose
			local k = Despues.strength(seed)
			return {
				depth = k * (-p.low + 0.5 * (p.vUp / p.tL) * t * t), -- aceleración constante
				pitch = lerp(p.exit * TURN_UP, p.exit, smooth(t / p.tL)), -- sigue a la velocidad
				roll = Despues.side(seed) * base,
				arch = -0.1 * t / p.tL,
				effort = 2,
				speed = 1.7,
				fins = 0.3,
				splash = 1,
				air = true, -- sigue la curva exacta: sale con la velocidad justa
			}
		end,
	}
end

local function flight(p: Fisica.Plan, base: number): Tramos.Tramo
	return {
		seconds = p.tAir,
		pose = function(t: number, _from: number, seed: number): Tricks.Pose
			local k, a, side = Despues.strength(seed), t / p.tAir, Despues.side(seed)
			local roll = if p.flop
				then side * WOBBLE * math.sin(math.pi * a) -- torpe: se bambolea y cae plana
				else side * (base + p.turn * smooth(span(a, 0.08, 0.92))) -- empieza antes del pico
			return {
				depth = k * (p.vUp * t - 0.5 * p.g * t * t), -- la parábola
				pitch = lerp(p.exit, p.landPitch, smooth(a)),
				roll = roll,
				arch = -0.1 * (1 - a) + (if p.flop then -0.12 else -0.32) * bell(a),
				fin = fins(-0.6 * bell(span(a, 0, 0.9)), seed),
				fins = -0.4 * bell(a),
				jaw = 0.3 * bell(a),
				flukes = 0.15 * bell(a),
				tail = -0.1 * bell(a),
				effort = 0.12,
				speed = 1.5,
				splash = if a < 0.5 then 1 else p.size,
				air = true,
			}
		end,
	}
end

-- Entre saltos seguidos: entra con la velocidad de la caída y vuelve a tomar impulso.
local function rebound(p: Fisica.Plan, base: number): Tramos.Tramo
	return {
		seconds = p.tRe,
		pose = function(t: number, _from: number, seed: number): Tricks.Pose
			local k, a = Despues.strength(seed), t / p.tRe
			return {
				depth = hermite(a, k * p.land, -k * p.vDown * p.tRe, -k * p.low, 0),
				pitch = dipPitch(a, p.landPitch, p.exit),
				roll = Despues.side(seed) * lerp(base + p.turn, base + p.upright, smooth(a)),
				effort = 1.9,
				speed = 1.6,
				fins = 0.2,
				splash = p.size,
				air = true,
			}
		end,
	}
end

function Salto.breach(apex: number, twist: number, seconds: number, style: Style?): Tricks.Trick
	local p = Fisica.solve(apex, twist, seconds, style)
	local list: { Tramos.Tramo } = {}
	local moments: { Tramos.Moment } = {}
	local marks: { [string]: number } = {}
	table.insert(list, {
		seconds = p.tApp,
		pose = function(t: number, from: number, seed: number): Tricks.Pose
			local a = t / p.tApp
			return {
				depth = hermite(a, from, 0, -p.low * Despues.strength(seed), 0),
				pitch = dipPitch(a, 0, p.exit),
				arch = 0.12 * bell(span(a, 0.1, 0.7)), -- se enrosca para girar abajo
				effort = lerp(1, 1.8, a),
				speed = lerp(1.1, 1.6, a),
				fins = 0.2,
			}
		end,
	})
	for jump = 1, p.times do
		local base = (jump - 1) * p.upright
		table.insert(list, launch(p, base))
		local exitAt = Tramos.total(list)
		marks[`salida{jump}`] = exitAt
		marks[`cima{jump}`] = exitAt + p.vUp / p.g
		table.insert(list, flight(p, base))
		local hit = Tramos.total(list)
		marks[`caida{jump}`] = hit
		table.insert(moments, { time = hit, kind = "cascade", size = p.size })
		if p.flop then -- el panzazo suena
			table.insert(moments, { time = hit, kind = "splash", size = p.size })
		end
		if p.size >= 2 then -- la cola enorme pega después del cuerpo: la ola
			table.insert(
				moments,
				{ time = hit + 0.25 * p.pace, kind = "slap", where = "tail", size = p.size }
			)
		end
		if jump < p.times then
			table.insert(list, rebound(p, base))
		end
	end
	marks.soplo = Despues.add(list, p) -- se hunde, sube y sopla
	table.insert(moments, { time = marks.soplo, kind = "spout" })
	local name = if p.flop then "panzazo" elseif p.times > 1 then "saltos" else "salto"
	local deep = math.max(p.low, p.sink) * Despues.strength(1) + BELLY
	return Tramos.build(name, list, moments, marks, { show = marks.caida1, vary = 0, deep = deep })
end

return table.freeze(Salto)
