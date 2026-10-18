--!strict
--[[
	Zorro/Colas/Mezcla

	Pasa el Intent y el BodyInfo del cuadro a la Mezcla suavizada que usan los
	estados (Tipos.Mezcla): cada valor sigue al pedido con un resorte sin rebote,
	así ningún estado entra ni sale de golpe (al 90 % en ~0.6 s; la sacudida y el
	meneo, que ya vienen con sus curvas, en ~0.3 s). También lleva la cuenta de la
	velocidad vertical suavizada y su aceleración (el frenazo al caer de un salto).
		new()                       el estado inicial (reposo)
		step(s, intent, body, dt)   devuelve la Mezcla del cuadro (la misma tabla)
		vertical(s)                 subida (altos/s) y aceleración (altos/s², con tope)
]]

local Resorte = require(script.Parent.Parent.Parent.Resorte)
local Tipos = require(script.Parent.Tipos)

local SLOW_HZ, FAST_HZ = 0.9, 1.9
local RUN_FULL = 1.2 -- altos por segundo: corre del todo
local ACCEL_MAX = 8 -- altos/s²: el frenazo más fuerte que se toma en cuenta

export type State = {
	mix: Tipos.Mezcla,
	springs: { [string]: Resorte.Resorte },
	rise: number,
	accel: number,
}

local FAST: { [string]: boolean } = { sacudida = true, meneo = true }

local Mezcla = {}

function Mezcla.new(): State
	return {
		mix = {
			calma = 1,
			alto = 0,
			alerta = 0,
			meneo = 0,
			gusto = 0,
			envolver = 0,
			enroscar = 0,
			lado = 1,
			correr = 0,
			sacudida = 0,
			latigazo = nil,
		},
		springs = {},
		rise = 0,
		accel = 0,
	}
end

local function follow(s: State, key: string, target: number, dt: number): number
	local spring = Resorte.get(s.springs, key, target)
	return Resorte.step(spring, target, dt, if FAST[key] then FAST_HZ else SLOW_HZ, 1)
end

function Mezcla.step(s: State, intent: Tipos.Intent, body: Tipos.BodyInfo, dt: number): Tipos.Mezcla
	local m = s.mix
	m.calma = math.max(0, follow(s, "calma", math.clamp(intent.calma or 1, 0, 2.5), dt))
	m.alto = follow(s, "alto", math.clamp(intent.alto or 0, -1, 1), dt)
	m.alerta = math.clamp(follow(s, "alerta", math.clamp(intent.alerta or 0, 0, 1), dt), 0, 1)
	m.meneo = math.max(0, follow(s, "meneo", math.clamp(intent.meneo or 0, 0, 1.6), dt))
	m.gusto = math.clamp(follow(s, "gusto", intent.gusto or 0, dt), 0, 1)
	m.envolver = math.clamp(follow(s, "envolver", intent.envolver or 0, dt), 0, 1)
	m.enroscar = math.clamp(follow(s, "enroscar", intent.enroscar or 0, dt), 0, 1)
	m.lado = math.clamp(follow(s, "lado", if (intent.lado or 1) < 0 then -1 else 1, dt), -1, 1)
	local run = math.clamp(body.avance / RUN_FULL, 0, 1)
	m.correr = math.clamp(follow(s, "correr", run, dt), 0, 1)
	m.sacudida = math.clamp(follow(s, "sacudida", math.clamp(body.sacudida, 0, 1), dt), 0, 1)
	m.latigazo = intent.latigazo
	-- Vertical: la velocidad suavizada y su cambio (un salto sube, cae y frena de golpe).
	local before = s.rise
	s.rise += (body.subida - s.rise) * (1 - math.exp(-dt * 12))
	local accel = math.clamp((s.rise - before) / dt, -ACCEL_MAX, ACCEL_MAX)
	s.accel += (accel - s.accel) * (1 - math.exp(-dt * 10))
	return m
end

function Mezcla.vertical(s: State): (number, number)
	return s.rise, s.accel
end

return table.freeze(Mezcla)
