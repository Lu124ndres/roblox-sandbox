--!strict
--[[
	OrcaMotion/Tricks/Saltitos

	Saltitos seguidos (porpoising), como los delfines y las orcas cuando van
	apuradas: arcos bajos y largos, la nariz siguiendo la trayectoria, y entra
	limpia de cabeza (casi sin salpicar). Fuera del agua el centro sigue la
	parábola de la gravedad de su tamaño; bajo el agua hace media onda con la
	misma velocidad con que entró, así sale al siguiente sin frenar. Con
	`clumsy` (la cría) se bambolea en el aire y entra salpicando.
	Marcas (avance u): salida<n> y entrada<n>.
]]

local Tramos = require(script.Parent.Tramos)
local Tricks = require(script.Parent)

local bell, lerp, hermite = Tricks.bell, Tricks.lerp, Tricks.hermite

export type Style = {
	talla: Tricks.Talla?, -- sin talla, la física se ajusta a `seconds`
	clumsy: number?, -- 0..1: torpe (se bambolea y salpica)
}

local DIP = 0.3 -- hondo entre saltito y saltito (altos)
local ANGLE = 0.7 -- rad (~40°): sale y entra en ángulo bajo, como en las fotos
local FOLLOW = 0.85 -- cuánto sigue la nariz a la trayectoria
local SPEED = 1.9 -- va rápida
local CLEAN = 0.35 -- salpicadura al entrar limpia
local WOBBLE = 0.25 -- bamboleo de la torpe en el aire (rad)
local COMPAT = 0.75 -- sin talla: la física ocupa el 75 % del truco
local SPLIT = 0.5 -- el tiempo que sobra: mitad para tomar impulso, mitad para volver

local Saltitos = {}

local function timing(height: number, g: number): (number, number, number)
	local vUp = math.sqrt(2 * g * height)
	local tAir, tUnder = 2 * vUp / g, math.pi * DIP / vUp -- media onda con la velocidad de entrada
	return vUp, tAir, tUnder
end

function Saltitos.hops(height: number, count: number, seconds: number, style: Style?): Tricks.Trick
	local s: Style = style or {}
	local clumsy = s.clumsy or 0
	local g = if s.talla then s.talla.gravity else 1
	if not s.talla then -- la gravedad que hace entrar los saltitos en el 75 % del truco
		local _, air, under = timing(height, 1)
		g = ((count * air + count * under) / (COMPAT * seconds)) ^ 2
	end
	local vUp, tAir, tUnder = timing(height, g)
	local vx = vUp / math.tan(ANGLE)
	local rest = math.max(0.4, seconds - count * (tAir + tUnder))
	local lead, tail = rest * SPLIT, rest * (1 - SPLIT)

	-- Bajo el agua: media onda de hondo DIP (empalma con la velocidad del aire).
	local function under(t: number, seed: number, k: number): Tricks.Pose
		local w = math.pi / tUnder
		return {
			depth = -DIP * math.sin(w * t),
			pitch = FOLLOW * math.atan2(-DIP * w * math.cos(w * t), vx),
			roll = clumsy * 0.08 * math.sin(w * t + seed * 6 + k),
			effort = 1.9,
			speed = SPEED,
			fins = 0.3,
			air = true, -- toda la serie sigue la curva exacta
		}
	end
	local list: { Tramos.Tramo } = {}
	local moments: { Tramos.Moment } = {}
	local marks: { [string]: number } = {}
	table.insert(list, {
		seconds = lead,
		pose = function(t: number, from: number, _seed: number): Tricks.Pose
			local a = t / lead
			return {
				depth = hermite(a, from, 0, -DIP, 0),
				pitch = -0.2 * bell(a),
				effort = lerp(1, 1.8, a),
				speed = lerp(1.1, SPEED, a),
				fins = 0.25,
			}
		end,
	})
	table.insert(list, { -- media subida hasta la primera salida
		seconds = tUnder / 2,
		pose = function(t: number, _from: number, seed: number): Tricks.Pose
			return under(t + tUnder / 2, seed, 0)
		end,
	})
	for hop = 1, count do
		marks[`salida{hop}`] = Tramos.total(list)
		table.insert(list, {
			seconds = tAir,
			pose = function(t: number, _from: number, seed: number): Tricks.Pose
				local dir = if (hop + math.floor(seed * 2)) % 2 == 0 then 1 else -1
				return {
					depth = vUp * t - 0.5 * g * t * t, -- la parábola
					pitch = FOLLOW * math.atan2(vUp - g * t, vx), -- la nariz adelante
					roll = dir * clumsy * WOBBLE * math.sin(math.pi * t / tAir),
					flukes = 0.1,
					fins = 0.35,
					effort = 0.2,
					speed = SPEED,
					splash = CLEAN + clumsy,
					air = true,
				}
			end,
		})
		marks[`entrada{hop}`] = Tramos.total(list)
		if clumsy > 0 then
			table.insert(moments, { time = Tramos.total(list), kind = "splash", size = clumsy })
		end
		table.insert(list, {
			seconds = if hop < count then tUnder else tUnder / 2,
			pose = function(t: number, _from: number, seed: number): Tricks.Pose
				return under(t, seed, hop)
			end,
		})
	end
	table.insert(list, {
		seconds = tail,
		pose = function(t: number, from: number, _seed: number): Tricks.Pose
			local a = t / tail
			return {
				depth = hermite(a, -DIP, 0, from, 0),
				pitch = 0.15 * bell(a),
				effort = lerp(1.5, 1, a),
				speed = lerp(SPEED, 1, a),
			}
		end,
	})
	local middle = math.ceil(count / 2)
	local show = (marks[`salida{middle}`] + marks[`entrada{middle}`]) / 2
	return Tramos.build("saltitos", list, moments, marks, { show = show, vary = 0 })
end

return table.freeze(Saltitos)
