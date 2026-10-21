--!strict
--[[
	OrcaMotion/Tricks/Salto/Despues

	Lo que pasa después de caer de un salto: se hunde de verdad (entra con la
	velocidad de la caída y el agua la frena de a poco, exponencial) mientras
	se endereza, planea abajo unos segundos, sube y sopla al llegar.
	Y lo que comparten los tramos del salto: el lado del giro y la fuerza que
	salen del azar del truco.
]]

local Fisica = require(script.Parent.Fisica)
local Respirar = require(script.Parent.Parent.Respirar)
local Tramos = require(script.Parent.Parent.Tramos)
local Tricks = require(script.Parent.Parent)

local smooth, span, bell, lerp, hermite =
	Tricks.smooth, Tricks.span, Tricks.bell, Tricks.lerp, Tricks.hermite

local JITTER = 0.12 -- la fuerza cambia ±6 % con el azar (sin cambiar los tiempos)
local GLIDE_PITCH = -0.25 -- nariz algo abajo mientras se hunde

local Despues = {}

-- Hacia qué lado gira sobre su eje (+1 o -1).
function Despues.side(seed: number): number
	return if seed < 0.5 then 1 else -1
end

-- Multiplica las alturas: el mismo salto más o menos fuerte.
function Despues.strength(seed: number): number
	return 1 + JITTER * (seed - 0.5)
end

-- Agrega los tramos de después de la última caída. Devuelve el momento del soplo (s).
function Despues.add(list: { Tramos.Tramo }, p: Fisica.Plan): number
	local spun = (p.times - 1) * p.upright + p.turn -- el giro con que cayó
	local done = (p.times - 1) * p.upright + p.upright -- y derecha otra vez
	local reach = 1 - math.exp(-Fisica.SINK_TAUS)
	table.insert(list, {
		seconds = p.tSink,
		pose = function(t: number, _from: number, seed: number): Tricks.Pose
			local k, a = Despues.strength(seed), t / p.tSink
			local roll = if p.flop then 0 else lerp(spun, done, smooth(span(a, 0.1, 1)))
			return {
				-- Entra con la velocidad de la caída y el agua la frena.
				depth = k * (p.land - (p.land + p.sink) * (1 - math.exp(-t / p.tau))),
				pitch = lerp(p.landPitch, GLIDE_PITCH, smooth(span(a, 0, 0.5))),
				roll = Despues.side(seed) * roll,
				arch = 0.15 * bell(span(a, 0, 0.6)), -- amortigua el golpe
				fins = 0.1,
				effort = 0.3,
				speed = lerp(1.2, 0.6, a),
				splash = p.size,
			}
		end,
	})
	table.insert(list, {
		seconds = p.tHold,
		pose = function(t: number, _from: number, seed: number): Tricks.Pose
			local k, a = Despues.strength(seed), t / p.tHold
			local after = p.land - (p.land + p.sink) * reach
			return {
				depth = hermite(a, k * after, 0, -k * p.sink, 0),
				pitch = lerp(GLIDE_PITCH, 0, smooth(a)),
				roll = Despues.side(seed) * done,
				effort = 0.5,
				speed = 0.7,
			}
		end,
	})
	table.insert(list, {
		seconds = p.tRise,
		pose = function(t: number, from: number, seed: number): Tricks.Pose
			local a = t / p.tRise
			return {
				depth = hermite(a, -Despues.strength(seed) * p.sink, 0, from, 0),
				pitch = 0.35 * bell(a),
				roll = Despues.side(seed) * done,
				effort = lerp(0.9, 0.7, a),
				speed = 0.9,
			}
		end,
	})
	local blowAt = Tramos.total(list) + p.blowAt
	table.insert(list, {
		seconds = p.tBlow,
		pose = function(t: number, from: number, seed: number): Tricks.Pose
			local pose: Tricks.Pose =
				{ depth = from, roll = Despues.side(seed) * done, effort = 0.6, speed = 1 }
			return Respirar.add(pose, t - p.blowAt, p.pace)
		end,
	})
	return blowAt
end

return table.freeze(Despues)
